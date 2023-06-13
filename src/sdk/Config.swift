
import Foundation

/// The configuration of the Descope SDK.
public struct DescopeConfig {
    /// The id of the Descope project.
    public var projectId: String
    
    /// The base URL of the Descope server.
    public var baseURL: String = "https://api.descope.com"

    /// An optional object to override how HTTP requests are performed.
    ///
    /// The default value of this property is always `nil`, and the SDK uses its own
    /// internal `URLSession` object to perform HTTP requests.
    ///
    /// This property can be useful to test code that uses the Descope SDK without any
    /// network requests actually taking place. In most other cases there shouldn't be
    /// any need to use it.
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
}

/// Optional features primarily for testing and debugging
extension DescopeConfig {
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
    open class Networking {
        /// Creates a new ``Networking`` object.
        public init() {
        }

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
