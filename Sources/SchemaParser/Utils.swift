import Foundation

extension Sequence {
    func dictionary<Key, Value>(key: (Iterator.Element) -> Key, value: (Iterator.Element) -> Value) -> [Key: Value] where Key: Hashable {
        var result: [Key: Value] = [:]
        for element in self {
            result[key(element)] = value(element)
        }
        return result
    }
}

func targetNamespace(ofNode node: XMLElement) throws -> String {
    if let tns = node.attribute(forName: "targetNamespace")?.stringValue {
        return tns
    }
    guard let parent = node.parent as? XMLElement else {
        throw ParseError.noTargetNamespace
    }
    return try targetNamespace(ofNode: parent)
}
