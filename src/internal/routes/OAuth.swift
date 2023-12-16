
import AuthenticationServices

class OAuth: Route, DescopeOAuth {
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
        log(.info, "Starting authentication using Sign in with Apple")
        let (refreshJwt, loginOptions) = try options.convert()
        let startResponse = try await client.oauthNativeStart(provider: provider, refreshJwt: refreshJwt, options: loginOptions)
        
        if startResponse.clientId != Bundle.main.bundleIdentifier {
            log(.debug, "Sign in with Apple requires an OAuth provider that's configured with a clientId matching the application's bundle identifier", startResponse.clientId, Bundle.main.bundleIdentifier)
            throw DescopeError.oauthNativeFailed.with(message: "OAuth provider clientId doesn't match bundle identifier")
        }
        
        log(.info, "Requesting authorization for Sign in with Apple", startResponse.clientId)
        let authorization = try await performAuthorization(nonce: startResponse.nonce)
        let (authorizationCode, identityToken, user) = try parseCredential(authorization.credential, implicit: startResponse.implicit)
        
        log(.info, "Finishing authentication using Sign in with Apple")
        return try await client.oauthNativeFinish(provider: provider, stateId: startResponse.stateId, user: user, authorizationCode: authorizationCode, identityToken: identityToken).convert()
    }
    
    @MainActor
    private func performAuthorization(nonce: String) async throws -> ASAuthorization {
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
            log(.info, "OAuth authorization cancelled by user")
            throw DescopeError.oauthNativeCancelled
        case .failure(ASAuthorizationError.unknown):
            log(.info, "OAuth authorization aborted")
            throw DescopeError.oauthNativeCancelled.with(message: "The operation was aborted")
        case .failure(let error):
            log(.error, "OAuth authorization failed", error)
            throw DescopeError.oauthNativeFailed.with(cause: error)
        case .success(let authorization):
            log(.debug, "OAuth authorization succeeded", authorization)
            return authorization
        }
    }
    
    private func parseCredential(_ credential: ASAuthorizationCredential, implicit: Bool) throws -> (authorizationCode: String?, identityToken: String?, user: String?) {
        guard let credential = credential as? ASAuthorizationAppleIDCredential else { throw DescopeError.oauthNativeFailed.with(message: "Invalid oauth credential type") }
        log(.debug, "Received Apple credential", credential.realUserStatus)

        var authorizationCode: String?
        if !implicit, let data = credential.authorizationCode, let value = String(bytes: data, encoding: .utf8) {
            log(.debug, "Adding authorization code from Apple credential", value)
            authorizationCode = value
        }
        
        var identityToken: String?
        if implicit, let data = credential.identityToken, let value = String(bytes: data, encoding: .utf8) {
            log(.debug, "Adding identity token from Apple credential", value)
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
                log(.debug, "Adding user name from Apple credential", name)
                user = value
            }
        }
        
        return (authorizationCode, identityToken, user)
    }
}
