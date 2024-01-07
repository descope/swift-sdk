import Foundation
@testable import DescopeKit

extension DescopeSDK {
    static func mock(projectId: String = "projId") -> DescopeSDK {
        var config = DescopeConfig(projectId: projectId, logger: DescopeLogger())
        config.networkClient = MockHTTP.networkClient
        return DescopeSDK(config: config)
    }
}
