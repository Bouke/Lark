import Foundation

public enum Element {
    case type(name: QualifiedName, base: QualifiedName, occurs: CountableRange<Int>)
    case complex(name: QualifiedName, occurs: CountableRange<Int>, members: [Element])
}

extension Element: Hashable {
    public static func ==(lhs: Element, rhs: Element) -> Bool {
        switch (lhs, rhs) {
        case let (.type(lname, lbase, _), .type(rname, rbase, _)): return lname == rname && lbase == rbase
        case let (.complex(lname, _, _), .complex(rname, _, _)): return lname == rname
        default: return false
        }
    }

    public var hashValue: Int {
        return name.uri.hashValue * 17 + name.localName.hashValue
    }

    public var name: QualifiedName {
        switch self {
        case let .type(name, _, _): return name
        case let .complex(name, _, _): return name
        }
    }
}

public typealias XSD = [Element]

func range(_ minOccurs: String?, _ maxOccurs: String?) -> CountableRange<Int> {
    switch (minOccurs, maxOccurs) {
    case (.none, .none): return 1..<1
    case (.none, "unbounded"?): return 1..<Int.max
    case (.none, let max?): return 1..<Int(max)!
    case (let min?, .none): return Int(min)!..<1
    case (let min?, "unbounded"?): return Int(min)!..<Int.max
    case (let min?, let max?): return Int(min)!..<Int(max)!
    }
}

func parseElement(node: XMLElement) throws -> Element {
    guard let localName = node.attribute(forLocalName: "name", uri: nil)?.stringValue else {
        throw ParseError.noName
    }
    let name = try QualifiedName(uri: targetNamespace(ofNode: node), localName: localName)

    let minOccurs = node.attribute(forLocalName: "minOccurs", uri: nil)?.stringValue
    let maxOccurs = node.attribute(forLocalName: "maxOccurs", uri: nil)?.stringValue
    let occurs = range(minOccurs, maxOccurs)

    if node.localName == "element" && node.uri == NS_XSD {
        if let type = node.attribute(forLocalName: "type", uri: nil)?.stringValue {
            return try Element.type(name: name, base: QualifiedName(type: type, inTree: node), occurs: range(minOccurs, maxOccurs))
        }
        if let complexType = node.elements(forLocalName: "complexType", uri: NS_XSD).first {
            return try parseComplexType(name: name, occurs: occurs, complexType: complexType)
        }
    }
    if node.localName == "complexType" && node.uri == NS_XSD {
        return try parseComplexType(name: name, occurs: occurs, complexType: node)
    }
    throw ParseError.unsupportedType
}

func parseComplexType(name: QualifiedName, occurs: CountableRange<Int>, complexType: XMLElement) throws -> Element {
    if let sequence = complexType.elements(forLocalName: "sequence", uri: NS_XSD).first {
        let members = try sequence.elements(forLocalName: "element", uri: NS_XSD)
            .map(parseElement(node:))
        return Element.complex(name: name, occurs: occurs, members: members)
    }
    throw ParseError.unsupportedType
}

//func nameForElement(element: Element) -> String {
//    let name: String
//    switch element {
//    case .type(let n, _, _): name = n
//    case .complex(let n, _, _): name = n
//    }
//
//    return name.capitalized
//}
