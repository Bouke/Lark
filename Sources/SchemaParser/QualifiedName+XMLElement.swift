import Foundation
import LarkRuntime

extension QualifiedName {
    public init(type: String, inTree tree: XMLElement) throws {
        if type.contains(":") {
            guard let namespace = tree.resolveNamespace(forName: type) else {
                throw Error.invalidNamespacePrefix
            }
            uri = namespace.stringValue!
        } else {
            uri = try targetNamespace(ofNode: tree)
        }
        localName = XMLElement(name: type).localName!
    }

    public static func name(ofElement node: XMLElement) throws -> QualifiedName? {
        guard let localName = node.attribute(forLocalName: "name", uri: nil)?.stringValue else {
            return nil
        }
        return try QualifiedName(uri: targetNamespace(ofNode: node), localName: localName)
    }
}
