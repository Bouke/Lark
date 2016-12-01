import Foundation

public protocol XMLDeserializable {
    init(deserialize: XMLElement) throws
}

public protocol XMLSerializable {
    func serialize(_ element: XMLElement)
}

public enum XMLDeserializationError: Error {
    case noElementWithName(String)
}

extension String: XMLDeserializable {
    public init(deserialize node: XMLElement) throws {
        self.init(node.stringValue ?? "")!
    }
}
