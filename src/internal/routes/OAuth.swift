
import AuthenticationServices

private let oauthRedirectScheme = "descopeoauth"
private let oauthRedirectURL = "\(oauthRedirectScheme)://redirect"

final class OAuth: DescopeOAuth, Route {
    let client: DescopeClient

    init(client: DescopeClient) {
        self.client = client
    }

    func web(provider: OAuthProvider, accessSharedUserData: Bool, options: [SignInOptions]) async throws -> AuthenticationResponse {
        logger(.info, "Starting OAuth web authentication")
        let url = try await webStart(provider: provider, redirectURL: oauthRedirectURL, options: options)

        logger(.info, "Showing OAuth web authentication", url)
        let code = try await OAuth.performWebAuthentication(url: url, accessSharedUserData: accessSharedUserData, logger: logger)

        logger(.info, "Finishing OAuth web authentication")
        return try await webExchange(code: code)
    }

    func webStart(provider: OAuthProvider, redirectURL: String?, options: [SignInOptions]) async throws -> URL {
        let (refreshJwt, loginOptions) = try options.convert()
        let response = try await client.oauthWebStart(provider: provider, redirectURL: redirectURL, refreshJwt: refreshJwt, options: loginOptions)
        guard let url = URL(string: response.url) else { throw DescopeError.decodeError.with(message: "Invalid redirect URL") }
        return url
    }

    func webExchange(code: String) async throws -> AuthenticationResponse {
        return try await client.oauthWebExchange(code: code).convert()
    }

    func native(provider: OAuthProvider, options: [SignInOptions]) async throws -> AuthenticationResponse {
        logger(.info, "Starting authentication using Sign in with Apple")
        let (refreshJwt, loginOptions) = try options.convert()
        let startResponse = try await client.oauthNativeStart(provider: provider, refreshJwt: refreshJwt, options: loginOptions)

        logger(.info, "Requesting authorization for Sign in with Apple", startResponse.clientId)
        let (authorizationCode, identityToken, user) = try await OAuth.performNativeAuthentication(nonce: startResponse.nonce, implicit: startResponse.implicit, logger: logger)

        logger(.info, "Finishing authentication using Sign in with Apple")
        return try await client.oauthNativeFinish(provider: provider, stateId: startResponse.stateId, user: user, authorizationCode: authorizationCode, identityToken: identityToken).convert()
    }

    @MainActor
    static func performWebAuthentication(url: URL, accessSharedUserData: Bool, logger: DescopeLogger?) async throws(DescopeError) -> String {
        let callbackURL = try await presentWebAuthentication(url: url, accessSharedUserData: accessSharedUserData, logger: logger)
        return try parseExchangeCode(from: callbackURL)
    }

    @MainActor
    static func performNativeAuthentication(nonce: String, implicit: Bool, logger: DescopeLogger?) async throws(DescopeError) -> (authorizationCode: String?, identityToken: String?, user: String?) {
        let authorization = try await presentNativeAuthentication(nonce: nonce, logger: logger)
        return try parseCredential(authorization.credential, implicit: implicit, logger: logger)
    }
}

@MainActor
private func presentWebAuthentication(url: URL, accessSharedUserData: Bool, logger: DescopeLogger?) async throws(DescopeError) -> URL? {
    let contextProvider = DefaultPresentationContextProvider()
    var cancellation: @MainActor () -> Void = {}

    let result: Result<URL?, Error> = await withTaskCancellationHandler {
        return await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: oauthRedirectScheme) { callbackURL, error in
                if let error {
                    continuation.resume(returning: .failure(error))
                } else {
                    continuation.resume(returning: .success(callbackURL))
                }
            }

            cancellation = { @MainActor [weak session] in
                logger(.info, "OAuth web authentication cancelled programmatically")
                session?.cancel()
            }

            session.presentationContextProvider = contextProvider
            session.start()
        }
    } onCancel: {
        Task { @MainActor in
            cancellation()
        }
    }

    switch result {
    case .failure(ASWebAuthenticationSessionError.canceledLogin):
        logger(.info, "OAuth web authentication cancelled by user")
        throw DescopeError.oauthWebCancelled
    case .failure(ASWebAuthenticationSessionError.presentationContextInvalid):
        logger(.error, "Invalid presentation context for OAuth web authentication")
        throw DescopeError.oauthWebFailed.with(message: "Invalid presentation context")
    case .failure(ASWebAuthenticationSessionError.presentationContextNotProvided):
        logger(.error, "No presentation context for OAuth web authentication")
        throw DescopeError.oauthWebFailed.with(message: "No presentation context")
    case .failure(let error):
        logger(.error, "Unexpected error from OAuth web authentication", error)
        throw DescopeError.oauthWebFailed.with(cause: error)
    case .success(let callbackURL):
        logger(.debug, "Processing OAuth web authentication", callbackURL)
        return callbackURL
    }
}

private func parseExchangeCode(from callbackURL: URL?) throws(DescopeError) -> String {
    guard let callbackURL, let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else { throw DescopeError.oauthWebFailed.with(message: "OAuth web authentication finished with invalid callback") }
    guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else { throw DescopeError.oauthWebFailed.with(message: "OAuth web authentication finished without authorization code") }
    return code
}

@MainActor
private func presentNativeAuthentication(nonce: String, logger: DescopeLogger?) async throws(DescopeError) -> ASAuthorization {
    let provider = ASAuthorizationAppleIDProvider()
    let request = provider.createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = nonce

    let contextProvider = DefaultPresentationContextProvider()
    let authDelegate = AuthorizationDelegate()

    let authController = ASAuthorizationController(authorizationRequests: [request])
    authController.presentationContextProvider = contextProvider
    authController.delegate = authDelegate

    // now that we have a reference to the ASAuthorizationController object we setup
    // a cancellation handler to be invoked if the async task is cancelled
    let cancellation = { @MainActor [weak authController] in
        logger(.info, "OAuth native authentication cancelled programmatically")
        guard #available(iOS 16.0, macOS 13, *) else { return }
        authController?.cancel()
    }

    // we pass a completion handler to the delegate object so we can use an async/await code
    // style even though we're waiting for a regular callback. The onCancel closure ensures
    // that we handle task cancellation properly by dismissing the authentication view.
    let result = await withTaskCancellationHandler {
        return await withCheckedContinuation { continuation in
            authDelegate.completion = { result in
                continuation.resume(returning: result)
            }
            authController.performRequests()
        }
    } onCancel: {
        Task { @MainActor in
            cancellation()
        }
    }

    switch result {
    case .failure(ASAuthorizationError.canceled):
        logger(.info, "OAuth native authentication cancelled by user")
        throw DescopeError.oauthNativeCancelled
    case .failure(ASAuthorizationError.unknown):
        logger(.info, "OAuth native authentication aborted")
        throw DescopeError.oauthNativeCancelled.with(message: "The operation was aborted")
    case .failure(let error):
        logger(.error, "OAuth native authentication failed", error)
        throw DescopeError.oauthNativeFailed.with(cause: error)
    case .success(let authorization):
        logger(.debug, "Processing OAuth native authentication", authorization)
        return authorization
    }
}

private func parseCredential(_ credential: ASAuthorizationCredential, implicit: Bool, logger: DescopeLogger?) throws(DescopeError) -> (authorizationCode: String?, identityToken: String?, user: String?) {
    guard let credential = credential as? ASAuthorizationAppleIDCredential else { throw DescopeError.oauthNativeFailed.with(message: "Invalid Apple credential type") }
    logger(.debug, "Received Apple credential", credential.realUserStatus)

    var authorizationCode: String?
    if !implicit, let data = credential.authorizationCode, let value = String(bytes: data, encoding: .utf8) {
        logger(.debug, "Adding authorization code from Apple credential", value)
        authorizationCode = value
    }

    var identityToken: String?
    if implicit, let data = credential.identityToken, let value = String(bytes: data, encoding: .utf8) {
        logger(.debug, "Adding identity token from Apple credential", value)
        identityToken = value
    }

    var user: String?
    if let names = credential.fullName, names.givenName != nil || names.middleName != nil || names.familyName != nil {
        var name: [String: Any] = [:]
        if let givenName = names.givenName {
            name["firstName"] = givenName
        }
        if let middleName = names.middleName {
            name["middleName"] = middleName
        }
        if let familyName = names.familyName {
            name["lastName"] = familyName
        }
        let object = ["name": name]
        if let data = try? JSONSerialization.data(withJSONObject: object), let value = String(bytes: data, encoding: .utf8) {
            logger(.debug, "Adding user name from Apple credential", name)
            user = value
        }
    }

    return (authorizationCode, identityToken, user)
}
