
import Foundation

public protocol DescopeSessionLifecycle: AnyObject {
    var session: DescopeSession? { get set }
    func refreshSessionIfNeeded() async throws
}

public class SessionLifecycle: DescopeSessionLifecycle {
    public let auth: DescopeAuth

    public init(auth: DescopeAuth) {
        self.auth = auth
    }
    
    public var stalenessAllowedInterval: TimeInterval = 60
    
    public var stalenessCheckFrequency: TimeInterval = 30
    
    public var session: DescopeSession? {
        didSet {
            guard session !== oldValue else { return }
            if session == nil {
                stopTimer()
            } else {
                startTimer()
            }
        }
    }
    
    public func refreshSessionIfNeeded() async throws {
        guard let session, shouldRefresh(session) else { return }
        let response = try await auth.refreshSession(refreshJwt: session.refreshJwt) // TODO check for refresh failure to not try again and again after expiry
        session.update(with: response)
    }
    
    // Internal
    
    private func shouldRefresh(_ session: DescopeSession) -> Bool {
        guard let expiresAt = session.sessionToken.expiresAt else { return false }
        return expiresAt.timeIntervalSinceNow <= stalenessAllowedInterval
    }
    
    // Timer
    
    private var timer: Timer?
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: stalenessCheckFrequency, repeats: true) { [weak self] _ in
            self?.refreshSessionAsync()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func refreshSessionAsync() {
        guard let session, shouldRefresh(session) else { return }
        auth.refreshSession(refreshJwt: session.refreshJwt) { result in
            guard case .success(let response) = result else { return }
            DispatchQueue.main.async {
                session.update(with: response)
            }
        }
    }
}
