import Foundation

extension String: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        self.init(node.stringValue ?? "")!
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = self
    }
}

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

extension Int: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        self.init(node.stringValue ?? "")!
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

extension Int32: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        self.init(node.stringValue ?? "")!
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

extension UInt64: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        self.init(node.stringValue ?? "")!
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

extension Int64: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        self.init(node.stringValue ?? "")!
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

extension Double: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        self.init(node.stringValue ?? "")!
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

extension Decimal: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        self.init(string: node.stringValue ?? "")!
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

extension Data: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {

        self.init(base64Encoded: node.stringValue ?? "")!
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = base64EncodedString()
    }
}

