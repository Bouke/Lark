import Foundation
import SchemaParser

enum GeneratorError: Error {
    case missingTypes(Set<QualifiedName>)
    case messageNotFound(QualifiedName)
    case missingNodes(Set<Graph.Node>)
}

typealias Writer = (String) -> ()

public func generate(wsdl: WSDL, service: Service, binding: Binding) throws -> String {
    let _ = try Graph(wsdl: wsdl)

    var types = [SwiftMetaType]()

    for case let .complexType(complex) in wsdl.schema {
        types.append(complex.toSwift())
    }

    for case let .simpleType(simple) in wsdl.schema {
        types.append(simple.toSwift())
    }

    return SwiftCodeGenerator.generateCode(for: types)
}

// todo: cleanup
enum _Type { case base(String) }

let baseTypes: [QualifiedName: _Type] = [
    QualifiedName(uri: NS_XSD, localName: "byte"): .base("Int8"),
    QualifiedName(uri: NS_XSD, localName: "unsignedByte"): .base("UInt8"),
    QualifiedName(uri: NS_XSD, localName: "short"): .base("Int16"),
    QualifiedName(uri: NS_XSD, localName: "unsignedShort"): .base("UInt16"),
    QualifiedName(uri: NS_XSD, localName: "int"): .base("Int32"),
    QualifiedName(uri: NS_XSD, localName: "unsignedInt"): .base("UInt32"),
    QualifiedName(uri: NS_XSD, localName: "long"): .base("Int64"),
    QualifiedName(uri: NS_XSD, localName: "unsignedLong"): .base("UInt64"),

    QualifiedName(uri: NS_XSD, localName: "boolean"): .base("Bool"),
    QualifiedName(uri: NS_XSD, localName: "float"): .base("Float"),
    QualifiedName(uri: NS_XSD, localName: "double"): .base("Double"),
    QualifiedName(uri: NS_XSD, localName: "integer"): .base("Int"), // undefined size
    QualifiedName(uri: NS_XSD, localName: "decimal"): .base("Decimal"),

    QualifiedName(uri: NS_XSD, localName: "string"): .base("String"),
    QualifiedName(uri: NS_XSD, localName: "anyURI"): .base("URL"),
    QualifiedName(uri: NS_XSD, localName: "base64Binary"): .base("Data"),
    QualifiedName(uri: NS_XSD, localName: "dateTime"): .base("Date"),
    QualifiedName(uri: NS_XSD, localName: "duration"): .base("TimeInterval"),
    QualifiedName(uri: NS_XSD, localName: "QName"): .base("QualifiedName"),
    QualifiedName(uri: NS_XSD, localName: "anyType"): .base("Any"),
]
