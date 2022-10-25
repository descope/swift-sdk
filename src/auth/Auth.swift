
import Foundation

class Auth: DescopeAuth {
    let client: DescopeClient
    var accessKey: DescopeAccessKey
    var otp: DescopeOTP
    var totp: DescopeTOTP

    convenience init(config: DescopeConfig) {
        self.init(client: DescopeClient(config: config))
    }
    
    init(client: DescopeClient) {
        self.client = client
        self.accessKey = AccessKey(client: client)
        self.otp = OTP(client: client)
        self.totp = TOTP(client: client)
    }
    
    func me(token: String) async throws -> MeResponse {
        return try await client.me(token).convert()
    }
}

private extension DescopeClient.UserResponse {
    func convert() -> MeResponse {
        var me = MeResponse(userId: userId, externalIds: externalIds, name: name)
        if let value = email {
            me.email = (value: value, isVerified: verifiedEmail)
        }
        if let value = phone {
            me.phone = (value: value, isVerified: verifiedPhone)
        }
        return me
    }
}
