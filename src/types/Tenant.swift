
import Foundation

public struct DescopeTenant: @unchecked Sendable {

    public var tenantId: String

    public var name: String

    public var customAttributes: [String: Any]

    public init(tenantId: String, name: String, customAttributes: [String: Any] = [:]) {
        self.tenantId = tenantId
        self.name = name
        self.customAttributes = customAttributes
    }
}

extension DescopeTenant: CustomStringConvertible {
    /// Returns a textual representation of this ``DescopeTenant`` object.
    ///
    /// It returns a string with the tenant's unique id and name.
    public var description: String {
        return "DescopeTenant(id: \"\(tenantId)\", name: \"\(name)\")"
    }
}

extension DescopeTenant: Equatable {
    public static func == (lhs: DescopeTenant, rhs: DescopeTenant) -> Bool {
        let attrs = lhs.customAttributes as NSDictionary
        return lhs.tenantId == rhs.tenantId && lhs.name == rhs.name &&
            attrs.isEqual(to: rhs.customAttributes)
    }
}

// Unfortunately we can't rely on the compiler for automatic conformance
// to Codable because the customAttributes dictionary isn't serializable
extension DescopeTenant: Codable {
    enum CodingKeys: CodingKey {
        case tenantId, name, customAttributes
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        tenantId = try values.decode(String.self, forKey: .tenantId)
        name = try values.decode(String.self, forKey: .name)
        if let value = try values.decodeIfPresent(String.self, forKey: .customAttributes), let json = try? JSONSerialization.jsonObject(with: Data(value.utf8)) {
            customAttributes = json as? [String: Any] ?? [:]
        } else {
            customAttributes = [:]
        }
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(tenantId, forKey: .tenantId)
        try values.encode(name, forKey: .name)
        // check before trying to serialize to prevent a runtime exception from being triggered
        if JSONSerialization.isValidJSONObject(customAttributes), let data = try? JSONSerialization.data(withJSONObject: customAttributes), let value = String(bytes: data, encoding: .utf8) {
            try values.encode(value, forKey: .customAttributes)
        }
    }
}
