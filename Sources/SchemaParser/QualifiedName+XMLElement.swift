import Foundation
import Lark

extension QualifiedName {
    public static func name(ofElement node: XMLElement) throws -> QualifiedName? {
        guard let localName = node.attribute(forLocalName: "name", uri: nil)?.stringValue else {
            return nil
        }
        guard let tns = node.targetNamespace else {
            return nil
        }
        return try QualifiedName(uri: tns, localName: localName)
    }
}
