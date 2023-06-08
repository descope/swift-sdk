
import Foundation

/// The configuration of the Descope SDK.
public struct DescopeConfig {
    /// The id of the Descope project.
    public var projectId: String
    
    /// The base URL of the Descope server.
    public var baseURL: String = "https://api.descope.com"

    /// An optional object to override how HTTP requests are performed.
    public var networking: Networking? = nil
    
    /// Creates a new ``DescopeConfig`` object.
    ///
    /// - Parameters:
    ///   - projectId: The id of the Descope project can be found in the project page in
    ///     the Descope console.
    ///   - baseURL: An optional override for the URL of the Descope server, in case it
    ///     needs to be accessed through a CNAME record.
    public init(projectId: String, baseURL: String? = nil) {
        self.projectId = projectId
        self.baseURL = baseURL ?? self.baseURL
    }
    
    /// The ``Networking`` abstract class can be used to override how HTTP requests
    /// are performed by the SDK when calling the Descope server.
    ///
    /// Create a new subclass of ``Networking`` and override the ``call(request:)``
    /// method and either return the appropriate HTTP response values or throw an error.
    ///
    /// For example, when testing code that uses the Descope SDK we might want to make
    /// sure no network requests are actually made. A simple ``Networking`` subclass
    /// that always throws an error might look like this:
    ///
    ///     class TestNetworking: DescopeConfig.Networking {
    ///         var error: DescopeError = .networkError
    ///
    ///         override func call(request: URLRequest) async throws -> (Data, URLResponse) {
    ///             throw error
    ///         }
    ///     }
    ///
    /// The method signature is intentionally identical to the `data(for:)` method
    /// in `URLSession`, so if for example all we want is for network requests made by
    /// the Descope SDK to use the same `URLSession` instance we use elsewhere we can
    /// use code such as this:
    ///
    ///     let config = DescopeConfig(projectId: "...")
    ///     config.networking = SessionNetworking(session: appSession)
    ///     let descopeSDK = DescopeSDK(config: config)
    ///
    ///     // ... elsewhere
    ///
    ///     class SessionNetworking: DescopeConfig.Networking {
    ///         let session: URLSession
    ///
    ///         init(session: URLSession) {
    ///             self.session = session
    ///         }
    ///
    ///         override func call(request: URLRequest) async throws -> (Data, URLResponse) {
    ///             return try await session.data(for: request)
    ///         }
    ///     }
    ///
    /// - Note: The default ``Networking`` object used by the SDK uses an internal `URLSession`
    ///     object. It is not exposed as a public symbol and unless you need to override
    ///     the SDK's networking behavior there's no need to use this class.
    open class Networking {
        /// Loads data using a `URLRequest` and returns the `data` and `response`.
        open func call(request: URLRequest) async throws -> (Data, URLResponse) {
            throw DescopeError.networkError.with(message: "Custom implementations must override the call(request:) method")
        }
    }
}

// Internal

extension DescopeConfig {
    static let initial = DescopeConfig(projectId: "")
}
