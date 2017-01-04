import Foundation

public protocol XMLDeserializable {
    init(deserialize: XMLElement) throws
}

public protocol XMLSerializable {
    func serialize(_ element: XMLElement) throws
}

public enum XMLDeserializationError: Error {
    case noElementWithName(String)
}

public enum XMLSerializationError: Error {
    case invalidNamespace(String)
}
