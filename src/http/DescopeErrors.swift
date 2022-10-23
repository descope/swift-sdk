
import Foundation

class ServerError: CustomNSError {
    static var errorDomain = "com.descope.ServerError"
    var errorCode: Int
    var errorUserInfo: [String: Any]
    
    init(errorCode: Int, errorUserInfo: [String: Any]) {
        self.errorCode = errorCode
        self.errorUserInfo = errorUserInfo
    }
}
