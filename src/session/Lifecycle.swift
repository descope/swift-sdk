
import Foundation

/// This protocol can be used to customize how a ``DescopeSessionManager`` object
/// manages its ``DescopeSession`` while the application is running.
@MainActor
public protocol DescopeSessionLifecycle: AnyObject {
    /// Set by the session manager whenever the current active session changes.
    var session: DescopeSession? { get set }
    
    /// Called the session manager to conditionally refresh the active session.
    func refreshSessionIfNeeded() async throws
}

/// The default implementation of the ``DescopeSessionLifecycle`` protocol.
///
/// The ``SessionLifecycle`` class periodically checks if the session needs to be
/// refreshed (every 30 seconds by default). The `refreshSessionIfNeeded` function
/// will refresh the session if it's about to expire (within 60 seconds by default)
/// or if it's already expired.
public class SessionLifecycle: DescopeSessionLifecycle {
    public let auth: DescopeAuth

    public init(auth: DescopeAuth) {
        self.auth = auth
    }
    
    public var stalenessAllowedInterval: TimeInterval = 60 /* seconds */
    
    public var stalenessCheckFrequency: TimeInterval = 30 /* seconds */
    
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
        session.updateTokens(with: response)
    }
    
    // Internal
    
    private func shouldRefresh(_ session: DescopeSession) -> Bool {
        return session.sessionToken.expiresAt.timeIntervalSinceNow <= stalenessAllowedInterval
    }
    
    // Timer
    
    private var timer: Timer?
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: stalenessCheckFrequency, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.periodicRefresh()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func periodicRefresh() {
        guard let session, shouldRefresh(session) else { return }
        auth.refreshSession(refreshJwt: session.refreshJwt) { result in
            guard case .success(let response) = result else { return }
            DispatchQueue.main.async {
                session.updateTokens(with: response)
            }
        }
    }
}
