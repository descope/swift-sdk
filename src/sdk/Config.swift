
import Foundation

/// The configuration of the Descope SDK.
public struct DescopeConfig {
    /// The id of the Descope project.
    public var projectId: String
    
    /// The base URL of the Descope server.
    public var baseURL: String = "https://api.descope.com"
    
    /// An optional object to handle logging in the Descope SDK.
    ///
    /// The default value of this property is `nil` and thus logging will be completely
    /// disabled. During development if you encounter any issues you can create an
    /// instance of the `Logger` class to enable logging.
    ///
    ///     Descope.config = DescopeConfig(projectId: "...", logger: DescopeConfig.Logger())
    ///
    /// If your application uses some logging framework or third party service you can forward
    /// the Descope SDK log messages to it by creating a new subclass of `Logger` and
    /// overriding the `output` method.
    public var logger: Logger?

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
    public init(projectId: String, baseURL: String? = nil, logger: Logger? = nil) {
        self.projectId = projectId
        self.baseURL = baseURL ?? self.baseURL
        self.logger = logger
    }
}

/// Optional features primarily for testing and debugging.
extension DescopeConfig {
    /// The `Logger` class can be used to customize logging functionality in the Descope SDK.
    ///
    /// The default behavior is for log messages to be written to the standard output using
    /// the `print()` function.
    ///
    /// To customize how logging functions in the Descope SDK create a subclass of `Logger`
    /// and override the ``output(level:message:debug:)`` method. See the documentation
    /// for that method for more details.
    open class Logger {
        /// The severity of a log message.
        public enum Level: Int {
            case error, info, debug
        }
        
        /// The maximum log level that should be printed.
        public let level: Level
        
        /// Creates a new `Logger` object.
        public init(level: Level = .debug) {
            self.level = level
        }

        /// Formats the log message and prints it.
        ///
        /// Override this method to customize how to handle log messages from the Descope SDK.
        ///
        /// - Parameters:
        ///   - message: This parameter is guaranteed to be a constant compile-time string, so
        ///     you can assume it doesn't contain private user data or secrets and that it can
        ///     be sent to whatever logging target or service you use.
        ///   - debug: This array has runtime values that might be useful when debugging
        ///     issues with the Descope SDK. Since it might contain sensitive information
        ///     its contents are only provided in `debug` builds. In `release` builds it
        ///     is always an empty array.
        open func output(level: Level, message: StaticString, debug: [Any]) {
            var text = "[\(DescopeSDK.name)] \(message)"
            if !debug.isEmpty {
                text += " (" + debug.map { String(describing: $0) }.joined(separator: ", ") + ")"
            }
            print(text)
        }
        
        /// Called by other code in the Descope SDK to output log messages.
        public func log(_ level: Level, _ message: StaticString, _ values: Any?...) {
            guard level.rawValue <= self.level.rawValue else { return }
            #if DEBUG
            output(level: level, message: message, debug: values.compactMap { $0 })
            #else
            output(level: level, message: message, debug: [])
            #endif
        }
    }
    
    /// The `Networking` abstract class can be used to override how HTTP requests
    /// are performed by the SDK when calling the Descope server.
    ///
    /// Create a new subclass of `Networking` and override the ``call(request:)``
    /// method and either return the appropriate HTTP response values or throw an error.
    ///
    /// For example, when testing code that uses the Descope SDK we might want to make
    /// sure no network requests are actually made. A simple `Networking` subclass
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
    ///     config.networking = AppNetworking(session: appSession)
    ///     let descopeSDK = DescopeSDK(config: config)
    ///
    ///     // ... elsewhere
    ///
    ///     class AppNetworking: DescopeConfig.Networking {
    ///         let session: URLSession
    ///
    ///         init(_ session: URLSession) {
    ///             self.session = session
    ///         }
    ///
    ///         override func call(request: URLRequest) async throws -> (Data, URLResponse) {
    ///             return try await session.data(for: request)
    ///         }
    ///     }
    open class Networking {
        /// Creates a new `Networking` object.
        public init() {
        }

        /// Loads data using a `URLRequest` and returns the `data` and `response`.
        ///
        /// - Note: The code that calls this function expects the response object to be an
        ///     instance of the `HTTPURLResponse` class and will throw an error if it's not.
        ///     This isn't reflected here to keep this simple to use and aligned with the
        ///     types in the `data(for:)` method in `URLSession`.
        open func call(request: URLRequest) async throws -> (Data, URLResponse) {
            throw DescopeError.networkError.with(message: "Custom implementations must override the call(request:) method")
        }
    }
}
