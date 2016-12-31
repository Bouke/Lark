import Foundation
import SchemaParser

enum GeneratorError: Error {
    case missingTypes(Set<QualifiedName>)
    case messageNotFound(QualifiedName)
    case missingNodes(Set<Graph.Node>)
}

typealias TypeMapping = [Graph.Node: Identifier]

public func generate(wsdl: WSDL, service: Service, binding: Binding) throws -> String {
    let graph = try Graph(wsdl: wsdl)
    let connectedNodes = graph.connectedNodes

    var mapping = baseTypes.dictionary { (Graph.Node.type($0), $1) }
    var scope = Set<String>()

    // Assign unique names to all nodes. First, elements are given a name. Sometimes 
    // elements have the same name as their implementing types, and we give give preference
    // to elements.

    // Note that we could collapse elements having only a base type. At the moment we handle
    // this using inheritance.
    for case let .element(node) in connectedNodes {
        let className = node.localName.toSwiftTypeName()

        guard !scope.contains(className) else {
            fatalError("Element name must be unique")
        }

        mapping[.element(node)] = className
        scope.insert(className)
    }

    for case let .type(node) in connectedNodes {
        let className: String
        let baseName = node.localName.toSwiftTypeName()
        if !scope.contains(baseName) {
            className = baseName
        } else if !scope.contains("\(baseName)Type") {
            className = "\(baseName)Type"
        } else {
            className = (2...Int.max).lazy.map { "\(baseName)Type\($0)" }.first { !scope.contains($0) }!
        }

        mapping[.type(node)] = className
        scope.insert(className)
    }

    var types = [SwiftMetaType]()
    for case let .element(element) in wsdl.schema {
        types.append(element.toSwift(mapping: mapping))
    }

    for case let .complexType(complex) in wsdl.schema {
        types.append(complex.toSwift(mapping: mapping))
    }

    for case let .simpleType(simple) in wsdl.schema {
        types.append(simple.toSwift(mapping: mapping))
    }

    var clients = [SwiftClientClass]()
    for service in wsdl.services {
        clients.append(service.toSwift(wsdl: wsdl))
    }

    return SwiftCodeGenerator.generateCode(for: types, clients)
}

// todo: cleanup
let baseTypes: [QualifiedName: Identifier] = [
    QualifiedName(uri: NS_XSD, localName: "byte"): "Int8",
    QualifiedName(uri: NS_XSD, localName: "unsignedByte"): "UInt8",
    QualifiedName(uri: NS_XSD, localName: "short"): "Int16",
    QualifiedName(uri: NS_XSD, localName: "unsignedShort"): "UInt16",
    QualifiedName(uri: NS_XSD, localName: "int"): "Int32",
    QualifiedName(uri: NS_XSD, localName: "unsignedInt"): "UInt32",
    QualifiedName(uri: NS_XSD, localName: "long"): "Int64",
    QualifiedName(uri: NS_XSD, localName: "unsignedLong"): "UInt64",

    QualifiedName(uri: NS_XSD, localName: "boolean"): "Bool",
    QualifiedName(uri: NS_XSD, localName: "float"): "Float",
    QualifiedName(uri: NS_XSD, localName: "double"): "Double",
    QualifiedName(uri: NS_XSD, localName: "integer"): "Int", // undefined size
    QualifiedName(uri: NS_XSD, localName: "decimal"): "Decimal",

    QualifiedName(uri: NS_XSD, localName: "string"): "String",
    QualifiedName(uri: NS_XSD, localName: "anyURI"): "URL",
    QualifiedName(uri: NS_XSD, localName: "base64Binary"): "Data",
    QualifiedName(uri: NS_XSD, localName: "dateTime"): "Date",
    QualifiedName(uri: NS_XSD, localName: "duration"): "TimeInterval",
    QualifiedName(uri: NS_XSD, localName: "QName"): "QualifiedName",
    QualifiedName(uri: NS_XSD, localName: "anyType"): "Any",
]
