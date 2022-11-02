
import Foundation
import Combine

class OTP: DescopeOTP {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }

    func signUp(with method: DeliveryMethod, identifier: String, user: User) async throws {
        try await client.otpSignUp(with: method, identifier: identifier, user: user)
    }
    
    func signIn(with method: DeliveryMethod, identifier: String) async throws {
        try await client.otpSignIn(with: method, identifier: identifier)
    }
    
    func signUpOrIn(with method: DeliveryMethod, identifier: String) async throws {
        try await client.otpSignUpIn(with: method, identifier: identifier)
    }
    
    func verify(with method: DeliveryMethod, identifier: String, code: String) async throws -> [DescopeToken] {
        return try await client.otpVerify(with: method, identifier: identifier, code: code).tokens()
    }
    
    func updateEmail(_ email: String, identifier: String, refreshToken: String) async throws {
        try await client.otpUpdateEmail(email, identifier: identifier, refreshToken: refreshToken)
    }
    
    func updatePhone(_ phone: String, with method: DeliveryMethod, identifier: String, refreshToken: String) async throws {
        try await client.otpUpdatePhone(phone, with: method, identifier: identifier, refreshToken: refreshToken)
    }
}

//
// TODO
//

/// Callbacks

extension OTP {
    func signIn(with method: DeliveryMethod, identifier: String, completion: @escaping (Result<Void, Error>) -> Void) {
        runAsyncTask(with: completion) {
            try await self.signIn(with: method, identifier: identifier)
        }
    }
}

/// Combine

extension OTP {
    func signIn(with method: DeliveryMethod, identifier: String) -> Future<Void, Error> {
        wrapAsyncTask {
            try await self.signIn(with: method, identifier: identifier)
        }
    }
}

private typealias AsyncTask<T> = () async throws -> T

private typealias AsyncTaskCompletion<T> = (Result<T, Error>) -> Void

private func runAsyncTask<T>(with completion: @escaping AsyncTaskCompletion<T>, _ task: @escaping AsyncTask<T>) {
    Task {
        do {
            let value = try await task()
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
}

private func wrapAsyncTask<T>(_ task: @escaping AsyncTask<T>) -> Future<T, Error> {
    Future { resolve in
        runAsyncTask(with: resolve, task)
    }
}
