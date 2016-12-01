import Foundation

public struct QualifiedName {
    public let uri: String
    public let localName: String

    public init(uri: String, localName: String) {
        self.uri = uri
        self.localName = localName
    }

    public init(type: String, inTree tree: XMLElement) throws {
        guard type.contains(":"), let namespace = tree.resolveNamespace(forName: type) else {
            throw ParseError.invalidNamespacePrefix
        }
        uri = namespace.stringValue!
        localName = XMLElement(name: type).localName!
    }
}

extension QualifiedName: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "(\(uri))\(localName)"
    }
}

extension QualifiedName: Equatable {
    public static func ==(lhs: QualifiedName, rhs: QualifiedName) -> Bool {
        return lhs.uri == rhs.uri && lhs.localName == rhs.localName
    }
}

extension QualifiedName: Hashable {
    public var hashValue: Int {
        return uri.hashValue % 17 + localName.hashValue
    }
}
