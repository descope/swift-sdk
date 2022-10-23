
import Foundation

private let sdkName = "DescopeKit"
private let sdkVersion = "1.0.0"

#if os(iOS)
private let osName = "iOS"
private let osSysctl = "hw.machine"
#else
private let osName = "macOS"
private let osSysctl = "hw.model"
#endif

/// Creates a user agent string with details about the system, operating system,
/// host application, and the SDK itself.
func makeUserAgent() -> String {
    var string = "\(sdkName)/\(sdkVersion)"
    if case let info = collectInfo().map(escape), !info.isEmpty {
        string += " ("
        string += info.joined(separator: "; ")
        string += ")"
    }
    return string
}

/// Ensures user agent string doesn't have any unexpected characters
private func escape(_ str: String) -> String {
    return str.replacingOccurrences(of: "[^0-9a-zA-Z .,_-]", with: "_", options: .regularExpression)
}

private func collectInfo() -> [String] {
    return [appInfo(), osInfo(), systemInfo()].compactMap { $0 }
}

/// Returns details about the host application that uses the SDK
private func appInfo() -> String? {
    guard let appName = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String else { return nil }
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    let appBuild = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "0"
    return "\(appName) \(appVersion).\(appBuild)"
}

/// Returns the name and version of the operating system
private func osInfo() -> String? {
    let ver = ProcessInfo.processInfo.operatingSystemVersion
    return "\(osName) \(ver.majorVersion).\(ver.minorVersion).\(ver.patchVersion)"
}

/// Returns the system model, for example, "MacBookPro18,4" or "iPhone13,4"
private func systemInfo() -> String? {
    #if targetEnvironment(simulator)
    return "Simulator"
    #else
    // get the size of the value first
    var size = 0
    guard sysctlbyname(osSysctl, nil, &size, nil, 0) == 0, size > 0 else { return nil }
    
    // create an appropriately sized array and call again to retrieve the value
    var chars = [CChar](repeating: 0, count: size)
    guard sysctlbyname(osSysctl, &chars, &size, nil, 0) == 0 else { return nil }
    
    return String(cString: chars)
    #endif
}
