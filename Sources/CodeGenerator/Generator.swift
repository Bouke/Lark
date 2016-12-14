import Foundation
import SchemaParser

enum GeneratorError: Error {
    case missingTypes(Set<QualifiedName>)
    case messageNotFound(QualifiedName)
    case missingNodes(Set<Graph.Node>)
}

typealias TypeMapping = [QualifiedName: Identifier]

public func generate(wsdl: WSDL, service: Service, binding: Binding) throws -> String {
    let graph = try Graph(wsdl: wsdl)
    let connectedNodes = graph.connectedNodes

    var mapping = baseTypes
    for case let .type(node) in connectedNodes {
        mapping[node] = node.localName.toSwiftTypeName()
    }

    let complexElements = wsdl.schema
        .flatMap { $0.element }
        .filter { if case .complex(_) = $0.content, connectedNodes.contains(.element($0.name)) { return true } else { return false } }
    for element in complexElements {
        mapping[element.name] = element.name.localName.toSwiftTypeName()
    }

    var types = [SwiftMetaType]()
    for case let .complexType(complex) in wsdl.schema {
        types.append(complex.toSwift(mapping: mapping))
    }
    for case let .simpleType(simple) in wsdl.schema {
        types.append(simple.toSwift(mapping: mapping))
    }
    for case let .element(element) in wsdl.schema {
        types.append(element.toSwift(mapping: mapping))
    }

    var clients = [SwiftClientClass]()
    for service in wsdl.services {
        clients.append(service.toSwift(wsdl: wsdl))
    }

    return SwiftCodeGenerator.generateCode(for: types, clients)
}

// todo: cleanup
let baseTypes: TypeMapping = [
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
