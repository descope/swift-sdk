
protocol LoggingProvider {
    func log(_ level: DescopeLogger.Level, _ message: StaticString, _ values: Any?...)
}

protocol LoggerProvider: LoggingProvider {
    var logger: DescopeLogger? { get }
}

extension LoggerProvider {
    func log(_ level: DescopeLogger.Level, _ message: StaticString, _ values: Any?...) {
        logger?.log(level, message, values)
    }
}
