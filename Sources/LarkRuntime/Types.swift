import Foundation

extension String: XMLDeserializable {
    public init(deserialize node: XMLElement) throws {
        self.init(node.stringValue ?? "")!
    }
}

extension String: XMLSerializable {
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = self
    }
}

extension Int: XMLDeserializable {
    public init(deserialize node: XMLElement) throws {
        self.init(node.stringValue ?? "")!
    }
}

extension Int: XMLSerializable {
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = "\(self)"
    }
}
