import Foundation

public let NS_WSDL = "http://schemas.xmlsoap.org/wsdl/"
public let NS_XSD = "http://www.w3.org/2001/XMLSchema"
public let NS_SOAP = "http://schemas.xmlsoap.org/wsdl/soap/"
public let NS_SOAP12 = "http://schemas.xmlsoap.org/wsdl/soap12/"

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
