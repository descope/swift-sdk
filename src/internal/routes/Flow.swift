
import AuthenticationServices
import CryptoKit

private let redirectScheme = "descopeauth"
private let redirectURL = "\(redirectScheme)://flow"

class Flow: DescopeFlow {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    var current: DescopeFlowRunner?
    
    @MainActor
    func start(runner: DescopeFlowRunner) async throws -> AuthenticationResponse {
        // adds some required query parameters to the flow URL to facilitate PKCE and
        // redirection at the end of the flow
        let (initialURL, codeVerifier) = try prepareInitialRequest(for: runner)
        
        // sets the flow we're about to present as the current flow
        current = runner
        
        // ensure that whatever the result of this method is we remove the reference
        // to the runner from the current property
        defer {
            if current === runner {
                current = nil
            }
        }
        
        // we wrap the callback based work with ASWebAuthenticationSession so it fits
        // an async/await code style as any other action the SDK performs. The onCancel
        // closure ensures that we handle task cancellation properly by calling `cancel()`
        // on the runner, which is then handled internally by the `run` function.
        return try await withTaskCancellationHandler {
            // flows are presenteed using AuthenticationServices which only supports callbacks
            // based methods, so we wrap the entire flow running in a continuation that returns
            // either an error or an authorization code
            let authorizationCode = try await withCheckedThrowingContinuation { continuation in
                // opens the URL in sandboxed browser via ASWebAuthenticationSession
                run(runner, url: initialURL, codeVerifier: codeVerifier, sessions: []) { result in
                    continuation.resume(with: result)
                }
            }
            // if the above call didn't throw we can exchange the authorization code for
            // an authenticated user session
            return try await exchange(runner, authorizationCode: authorizationCode, codeVerifier: codeVerifier)
        } onCancel: {
            // the task that called `start(runner:)` was cancelled, so we treat it as if
            // `cancel()` was called on the runner itself
            Task { @MainActor in
                runner.cancel()
            }
        }
    }
    
    @MainActor
    private func run(_ runner: DescopeFlowRunner, url: URL, codeVerifier: String, sessions: [ASWebAuthenticationSession], completion: @escaping (Result<String, Error>) -> Void) {
        // tracks whether this call to `run` still needs to call its completion handler
        var completed = false
        
        // opens the URL in a sandboxed browser, when the flow completes it will know
        // to redirect to a URL that starts with `descopeauth://flow` and that contains
        // the authorization code we need. At that point the session will catch this
        // and call our completion handler.
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: redirectScheme) { callbackURL, error in
            Task {
                // protects against the completion handler being called multiple times, e.g.,
                // in case the session is cancelled or another call to `run` in recursion
                // will be responsible to call it
                guard !completed else { return }
                completed = true
                
                // parse the URL we got from the flow to get the authorization code
                let result = Result {
                    try parseAuthorizationCode(callbackURL, error)
                }

                // if this is a recursive call to `run` we close any previous sessions,
                // otherwise we might have lingering browser windows
                for session in sessions {
                    session.cancel()
                }
                
                // hands back control to the initial `start` method call
                completion(result)
            }
        }
        
        if !sessions.isEmpty {
            session.prefersEphemeralWebBrowserSession = true
        }
        session.presentationContextProvider = runner.presentationContextProvider
        session.start()
        
        Task {
            do {
                while !completed {
                    guard !runner.isCancelled else { throw DescopeError.flowCancelled }
                    
                    if let pendingURL = runner.pendingURL {
                        runner.pendingURL = nil
                        guard let nextURL = prepareRedirectRequest(for: runner, redirectURL: pendingURL) else { continue }
                        completed = true
                        return run(runner, url: nextURL, codeVerifier: codeVerifier, sessions: sessions+[session], completion: completion)
                    }
                    
                    try await Task.sleep(nanoseconds: 100 * NSEC_PER_MSEC)
                }
            } catch {
                completed = true
                for session in sessions {
                    session.cancel()
                }
                session.cancel()
                completion(.failure(DescopeError.flowCancelled))
            }
        }
    }
    
    @MainActor
    private func exchange(_ runner: DescopeFlowRunner, authorizationCode: String, codeVerifier: String) async throws -> AuthenticationResponse {
        guard !runner.isCancelled else { throw DescopeError.flowCancelled }
        let jwtResponse = try await client.flowExchange(authorizationCode: authorizationCode, codeVerifier: codeVerifier)
        guard !runner.isCancelled else { throw DescopeError.flowCancelled }
        return try jwtResponse.convert()
    }
}

// Internal

private extension Data {
    init?(randomBytesCount count: Int) {
        var bytes = [Int8](repeating: 0, count: count)
        guard SecRandomCopyBytes(kSecRandomDefault, count, &bytes) == errSecSuccess else { return nil }
        self = Data(bytes: bytes, count: count)
    }
    
    func base64URLEncodedString(options: Data.Base64EncodingOptions = []) -> String {
        return base64EncodedString(options: options)
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private func prepareInitialRequest(for runner: DescopeFlowRunner) throws -> (url: URL, codeVerifier: String) {
    guard let randomBytes = Data(randomBytesCount: 32) else { throw DescopeError.flowFailed.with(message: "Error generating random bytes") }
    let hashedBytes = Data(SHA256.hash(data: randomBytes))
    
    let codeVerifier = randomBytes.base64URLEncodedString()
    let codeChallenge = hashedBytes.base64URLEncodedString()

    guard let url = URL(string: runner.flowURL) else { throw DescopeError.flowFailed.with(message: "Invalid flow URL") }
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw DescopeError.flowFailed.with(message: "Malformed flow URL") }
    components.queryItems = components.queryItems ?? []
    components.queryItems?.append(URLQueryItem(name: "ra-callback", value: redirectURL))
    components.queryItems?.append(URLQueryItem(name: "ra-challenge", value: codeChallenge))
    #if os(macOS)
    components.queryItems?.append(URLQueryItem(name: "ra-initiator", value: "macos"))
    #else
    components.queryItems?.append(URLQueryItem(name: "ra-initiator", value: "ios"))
    #endif

    guard let initialURL = components.url else { throw DescopeError.flowFailed.with(message: "Failed to create flow URL") }
    
    return (initialURL, codeVerifier)
}

private func prepareRedirectRequest(for runner: DescopeFlowRunner, redirectURL: URL) -> URL? {
    guard let pendingComponents = URLComponents(url: redirectURL, resolvingAgainstBaseURL: false) else { return nil }
    guard let url = URL(string: runner.flowURL), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
    components.queryItems = components.queryItems ?? []
    for item in pendingComponents.queryItems ?? [] {
        components.queryItems?.append(item)
    }
    return components.url
}

private func parseAuthorizationCode(_ callbackURL: URL?, _ error: Error?) throws -> String {
    if let error {
        // TODO logger
        switch error {
        case ASWebAuthenticationSessionError.canceledLogin:
            throw DescopeError.flowCancelled
        case ASWebAuthenticationSessionError.presentationContextInvalid:
            print("Invalid presentation context: \(error)")
        case ASWebAuthenticationSessionError.presentationContextNotProvided:
            print("No presentation context: \(error)")
        default:
            print("Unknown error: \(error)")
        }
        throw DescopeError.flowFailed.with(cause: error)
    }

    guard let callbackURL else { throw DescopeError.flowFailed.with(message: "Authentication session finished without callback") }
    guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else { throw DescopeError.flowFailed.with(message: "Authentication session finished with invalid callback") }
    guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else { throw DescopeError.flowFailed.with(message: "Authentication session finished without authorization code") }
    
    return code
}
