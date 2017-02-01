import Foundation

public protocol XMLDeserializable {
    init(deserialize: XMLElement) throws
}

public protocol XMLSerializable {
    func serialize(_ element: XMLElement) throws
}

public enum XMLDeserializationError: Error {
    case noElementWithName(QualifiedName)
    case cannotDeserialize
}

public enum XMLSerializationError: Error {
    case invalidNamespace(String)
}

public protocol StringDeserializable {
    init(string: String) throws
}

public protocol StringSerializable {
    func serialize() throws -> String
}

// MARK: - Base type serialization
// MARK: Signed integers

extension Int8: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = Int8(node.stringValue ?? "") else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}
extension Int16: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = Int16(node.stringValue ?? "") else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

extension Int32: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = Int32(node.stringValue ?? "") else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

extension Int64: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = Int64(node.stringValue ?? "") else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

// MARK: Unsigned integers

extension UInt8: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = UInt8(node.stringValue ?? "") else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}
extension UInt16: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = UInt16(node.stringValue ?? "") else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

extension UInt32: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = UInt32(node.stringValue ?? "") else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

extension UInt64: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = UInt64(node.stringValue ?? "") else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

// MARK: Numeric types

extension Bool: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        switch node.stringValue {
        case "1"?, "true"?: self = true
        case "0"?, "false"?: self = false
        default: throw XMLDeserializationError.cannotDeserialize
        }
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

extension Float: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = Float(node.stringValue ?? "") else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

extension Double: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = Double(node.stringValue ?? "") else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

extension Int: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = Int(node.stringValue ?? "") else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

extension Decimal: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = Decimal(string: node.stringValue ?? "") else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

// MARK: Other types

extension String: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = node.stringValue else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = self
    }
}

extension URL: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = URL(string: node.stringValue ?? "") else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = self.absoluteString
    }
}

extension Data: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        guard let value = Data(base64Encoded: node.stringValue ?? "") else {
            throw XMLDeserializationError.cannotDeserialize
        }
        self = value
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = base64EncodedString()
    }
}

extension Date: XMLDeserializable, XMLSerializable {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")!
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()

    static let fallbackDateFormatters: [DateFormatter] = [ {
            // formatter with milliseconds
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")!
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            return formatter
        }(), {
            // formatter without timezone identifier
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")!
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return formatter
        }(), {
            // formatter with milliseconds and without timezone identifier
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")!
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            return formatter
        }()
    ]

    public init(deserialize node: XMLElement) throws {
        guard let stringValue = node.stringValue else {
            throw XMLDeserializationError.cannotDeserialize
        }
        if let value = Date.dateFormatter.date(from: stringValue) {
            self = value
            return
        }
        for fallback in Date.fallbackDateFormatters {
            guard let value = fallback.date(from: stringValue) else {
                continue
            }
            self = value
            return
        }
        throw XMLDeserializationError.cannotDeserialize
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = Date.dateFormatter.string(from: self)
    }
}

// TODO: implement TimeInterval extension

extension QualifiedName: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        try self.init(type: node.stringValue ?? "", inTree: node)
    }
    public func serialize(_ element: XMLElement) throws {
        switch element.targetNamespace {
        case uri?:
            element.stringValue = localName
        default:
            let prefix = element.resolveOrAddPrefix(forNamespaceURI: uri)
            element.stringValue = "\(prefix):\(localName)"
        }
    }
}

// Ugh required convenience designated final initializer. Swift is drunk.
public final class AnyType: XMLElement, XMLDeserializable, XMLSerializable {
    public convenience init(deserialize node: XMLElement) throws {
        try self.init(xmlString: node.canonicalXMLStringPreservingComments(true))
    }
    public func serialize(_ element: XMLElement) throws {
        for namespace in namespaces ?? [] {
            element.addNamespace(namespace.copy() as! XMLNode)
        }
        for attribute in attributes ?? [] {
            element.addAttribute(attribute.copy() as! XMLNode)
        }
        for child in children ?? [] {
            element.addChild(child.copy() as! XMLNode)
        }
    }
}
