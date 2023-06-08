
import Foundation
#if os(iOS)
import UIKit
#endif

class TOTP: DescopeTOTP {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }

    func signUp(loginId: String, details: SignUpDetails?) async throws -> TOTPResponse {
        return try await client.totpSignUp(loginId: loginId, details: details).convert()
    }
    
    func verify(loginId: String, code: String) async throws -> AuthenticationResponse {
        return try await client.totpVerify(loginId: loginId, code: code).convert()
    }
    
    func update(loginId: String, refreshJwt: String) async throws -> TOTPResponse {
        return try await client.totpUpdate(loginId: loginId, refreshJwt: refreshJwt).convert()
    }
}

private extension DescopeClient.TOTPResponse {
    func convert() throws -> TOTPResponse {
        guard let image = Data(base64Encoded: image) else { throw DescopeError.decodeError.with(message: "Invalid image value") }
        #if os(iOS)
        guard let image = UIImage(data: image) else { throw DescopeError.decodeError.with(message: "Invalid image data") }
        #endif
        guard let url = URL(string: provisioningURL) else { throw DescopeError.decodeError.with(message: "Invalid provisioning URL") }
        return TOTPResponse(provisioningURL: url, image: image, key: key)
    }
}