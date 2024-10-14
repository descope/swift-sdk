
import AuthenticationServices

final class OAuth: DescopeOAuth, Route {
    let client: DescopeClient

    init(client: DescopeClient) {
        self.client = client
    }

    func start(provider: OAuthProvider, redirectURL: String?, options: [SignInOptions]) async throws -> URL {
        let (refreshJwt, loginOptions) = try options.convert()
        let response = try await client.oauthWebStart(provider: provider, redirectURL: redirectURL, refreshJwt: refreshJwt, options: loginOptions)
        guard let url = URL(string: response.url) else { throw DescopeError.decodeError.with(message: "Invalid redirect URL") }
        return url
    }

    func exchange(code: String) async throws -> AuthenticationResponse {
        return try await client.oauthWebExchange(code: code).convert()
    }

    @MainActor
    func native(provider: OAuthProvider, options: [SignInOptions]) async throws -> AuthenticationResponse {
        logger(.info, "Starting authentication using Sign in with Apple")
        let (refreshJwt, loginOptions) = try options.convert()
        let startResponse = try await client.oauthNativeStart(provider: provider, refreshJwt: refreshJwt, options: loginOptions)

        logger(.info, "Requesting authorization for Sign in with Apple", startResponse.clientId)
        let (authorizationCode, identityToken, user) = try await OAuth.performNativeAuthorization(nonce: startResponse.nonce, implicit: startResponse.implicit, logger: logger)

        logger(.info, "Finishing authentication using Sign in with Apple")
        return try await client.oauthNativeFinish(provider: provider, stateId: startResponse.stateId, user: user, authorizationCode: authorizationCode, identityToken: identityToken).convert()
    }

    @MainActor
    static func performNativeAuthorization(nonce: String, implicit: Bool, logger: DescopeLogger?) async throws(DescopeError) -> (authorizationCode: String?, identityToken: String?, user: String?) {
        let authorization = try await performAuthorization(nonce: nonce, logger: logger)
        return try parseCredential(authorization.credential, implicit: implicit, logger: logger)
    }
}

@MainActor
private func performAuthorization(nonce: String, logger: DescopeLogger?) async throws(DescopeError) -> ASAuthorization {
    let provider = ASAuthorizationAppleIDProvider()
    let request = provider.createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = nonce

    let contextProvider = DefaultPresentationContextProvider()

    let authDelegate = AuthorizationDelegate()
    let authController = ASAuthorizationController(authorizationRequests: [ request ] )
    authController.delegate = authDelegate
    authController.presentationContextProvider = contextProvider
    authController.performRequests()

    let result = await withCheckedContinuation { continuation in
        authDelegate.completion = { result in
            continuation.resume(returning: result)
        }
    }

    switch result {
    case .failure(ASAuthorizationError.canceled):
        logger(.info, "OAuth authorization cancelled by user")
        throw DescopeError.oauthNativeCancelled
    case .failure(ASAuthorizationError.unknown):
        logger(.info, "OAuth authorization aborted")
        throw DescopeError.oauthNativeCancelled.with(message: "The operation was aborted")
    case .failure(let error):
        logger(.error, "OAuth authorization failed", error)
        throw DescopeError.oauthNativeFailed.with(cause: error)
    case .success(let authorization):
        logger(.debug, "OAuth authorization succeeded", authorization)
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
