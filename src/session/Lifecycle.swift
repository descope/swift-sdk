
import Foundation

/// This protocol can be used to customize how a ``DescopeSessionManager`` object
/// manages its ``DescopeSession`` while the application is running.
@MainActor
public protocol DescopeSessionLifecycle: AnyObject {
    /// Holds the latest session value for the session manager.
    var session: DescopeSession? { get set }
    
    /// Called by the session manager to conditionally refresh the active session.
    func refreshSessionIfNeeded() async throws -> Bool
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
    
    public var stalenessCheckFrequency: TimeInterval = 30 /* seconds */ {
        didSet {
            if stalenessCheckFrequency != oldValue {
                resetTimer()
            }
        }
    }

    public var session: DescopeSession? {
        didSet {
            if session?.refreshJwt != oldValue?.refreshJwt {
                resetTimer()
            }
        }
    }
    
    public func refreshSessionIfNeeded() async throws -> Bool {
        guard let current = session, shouldRefresh(current) else { return false }
        let response = try await auth.refreshSession(refreshJwt: current.refreshJwt)
        session?.updateTokens(with: response)
        return true
    }
    
    // Conditional refresh
    
    private func shouldRefresh(_ session: DescopeSession) -> Bool {
        return session.sessionToken.expiresAt.timeIntervalSinceNow <= stalenessAllowedInterval
    }
    
    // Periodic refresh

    private var timer: Timer?

    private func resetTimer() {
        if session != nil && stalenessCheckFrequency > 0 {
            startTimer()
        } else {
            stopTimer()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: stalenessCheckFrequency, repeats: true) { [weak self] timer in
            guard let lifecycle = self else { return timer.invalidate() }
            Task { @MainActor in
                await lifecycle.periodicRefresh()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func periodicRefresh() async {
        do {
            try await refreshSessionIfNeeded()
        } catch {
            // TODO check for refresh failure to not try again and again after expiry
        }
    }
}
