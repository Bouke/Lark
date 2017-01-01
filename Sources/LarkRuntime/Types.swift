import Foundation

extension String: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        self.init(node.stringValue ?? "")!
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = self
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

extension Decimal: XMLDeserializable, XMLSerializable {
    public init(deserialize node: XMLElement) throws {
        self.init(string: node.stringValue ?? "")!
    }
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}

