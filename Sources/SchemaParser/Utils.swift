import Foundation
import Lark

/// SOAP Namespace URI
public let NS_SOAP = "http://schemas.xmlsoap.org/wsdl/soap/"

/// WSDL Namespace URI
public let NS_WSDL = "http://schemas.xmlsoap.org/wsdl/"

/// XML Schema (XSD) Namespace URI
public let NS_XS = "http://www.w3.org/2001/XMLSchema"

/// SOAP 1.2 Namespace URI
public let NS_SOAP12 = "http://schemas.xmlsoap.org/wsdl/soap12/"


extension Sequence {
    public func dictionary<Key, Value>(_ pair: (Iterator.Element) -> (Key, Value)) -> [Key: Value] where Key: Hashable {
        var result: [Key: Value] = [:]
        for (key, value) in self.map(pair) {
            result[key] = value
        }
        return result
    }

    public func dictionary<Key, Value>(key: (Iterator.Element) -> Key, value: (Iterator.Element) -> Value) -> [Key: Value] where Key: Hashable {
        var result: [Key: Value] = [:]
        for element in self {
            result[key(element)] = value(element)
        }
        return result
    }

    public func single(_ `where`: (Self.Iterator.Element) throws -> Bool) throws -> Self.Iterator.Element {
        let matches = try filter(`where`)
        guard matches.count == 1 else {
            fatalError("more than 1 matching element")
        }
        return matches.first!
    }
}

func importSchema(url: URL) throws -> XMLElement {
    return try XMLDocument(contentsOf: url, options: 0).rootElement()!
}
