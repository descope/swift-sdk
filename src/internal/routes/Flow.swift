
import AuthenticationServices
import CryptoKit

private let redirectScheme = "authredirect"
private let redirectURL = "\(redirectScheme)://flow"

class Flow: DescopeFlow {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    var current: DescopeFlowRunner?
    
    @MainActor
    func start(runner: DescopeFlowRunner) async throws -> AuthenticationResponse {
        guard let randomBytes = Data(randomBytesCount: 32) else { throw DescopeError.flowFailed.with(message: "Error generating random bytes") }
        let hashedBytes = Data(SHA256.hash(data: randomBytes))
        
        let codeVerifier = randomBytes.base64URLEncodedString()
        let codeChallenge = hashedBytes.base64URLEncodedString()

        guard let url = URL(string: runner.flowURL) else { throw DescopeError.flowFailed.with(message: "Invalid flow URL") }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw DescopeError.flowFailed.with(message: "Malformed flow URL") }
        components.queryItems = components.queryItems ?? []
        components.queryItems?.append(URLQueryItem(name: "ra-callback", value: redirectURL))
        components.queryItems?.append(URLQueryItem(name: "ra-challenge", value: codeChallenge))
        
        guard let initialURL = components.url else { throw DescopeError.flowFailed.with(message: "Failed to create flow URL") }
        
        current = runner
        defer {
            if current === runner {
                current = nil
            }
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            run(runner, url: initialURL, codeVerifier: codeVerifier, sessions: []) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @MainActor
    private func run(_ runner: DescopeFlowRunner, url: URL, codeVerifier: String, sessions: [ASWebAuthenticationSession], completion: @escaping (Result<AuthenticationResponse, Error>) -> Void) {
        var finished = false
        
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: redirectScheme) { callbackURL, error in
            Task {
                guard !finished else { return }
                finished = true

                do {
                    guard !runner.isCancelled else { throw DescopeError.flowCancelled }
                    
                    let code = try self.parseAuthorizationCode(callbackURL, error)
                    let jwtResponse = try await self.client.flowExchange(authorizationCode: code, codeVerifier: codeVerifier)

                    guard !runner.isCancelled else { throw DescopeError.flowCancelled }
                    
                    for session in sessions {
                        session.cancel()
                    }
                    
                    completion(.success(try jwtResponse.convert()))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        
        if !sessions.isEmpty {
            session.prefersEphemeralWebBrowserSession = true
        }
        session.presentationContextProvider = runner.presentationContextProvider
        session.start()
        
        var counter = 0
        Task {
            do {
                while !finished {
                    counter += 1
                    NSLog("Counter: \(Task.isCancelled)")
                    
                    guard !runner.isCancelled else { throw DescopeError.flowCancelled }
                    
                    if let pendingURL = runner.pendingURL {
                        runner.pendingURL = nil
                        
                        guard let pendingComponents = URLComponents(url: pendingURL, resolvingAgainstBaseURL: false) else { continue }
                        guard let url = URL(string: runner.flowURL), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { continue }
                        components.queryItems = components.queryItems ?? []
                        for item in pendingComponents.queryItems ?? [] {
                            components.queryItems?.append(item)
                        }
                        guard let nextURL = components.url else { continue }
                        
                        finished = true
                        try await Task.sleep(nanoseconds: 300 * NSEC_PER_MSEC)
                        
                        return run(runner, url: nextURL, codeVerifier: codeVerifier, sessions: sessions+[session], completion: completion)
                    }
                    
                    try await Task.sleep(nanoseconds: 300 * NSEC_PER_MSEC)
                }
            } catch {
                finished = true
                for session in sessions {
                    session.cancel()
                }
                session.cancel()
                completion(.failure(DescopeError.flowCancelled))
            }
        }
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
