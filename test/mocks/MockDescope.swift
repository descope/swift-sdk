import Foundation
@testable import DescopeKit

extension DescopeSDK {
    static func mock(projectId: String = "projId") -> DescopeSDK {
        return DescopeSDK(projectId: projectId) { config in
            config.logger = DescopeLogger()
            config.networkClient = MockHTTP.networkClient
        }
    }
}
