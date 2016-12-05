import Foundation
import SchemaParser

enum GeneratorError: Error {
    case missingTypes(Set<QualifiedName>)
    case messageNotFound(QualifiedName)
}

typealias Writer = (String) -> ()
typealias Registry = [QualifiedName: Type]

public func generate(_ print: Writer, wsdl: WSDL, service: Service, binding: Binding) throws {
    var registry: Registry = baseTypes

    print("import Foundation")
    print("import LarkRuntime")
    print("")

    try generateTypes(print, wsdl: wsdl, binding: binding, registry: &registry)
    generateClient(print, wsdl: wsdl, service: service, binding: binding, registry: registry)
}

func generateTypes(_ print: Writer, wsdl: WSDL, binding: Binding, registry: inout Registry) throws {
    let port = wsdl.portTypes.first(where: { $0.name == binding.type })!

    let operationTypes = try Set(port.operations
        .flatMap { [$0.inputMessage, $0.outputMessage] }
        .map { name -> Message in
            guard let message = wsdl.messages.first(where: { $0.name == name }) else {
                throw GeneratorError.messageNotFound(name)
            }
            return message
        }
        .flatMap { $0.parts }
        .map { $0.element }
    )
    var usedTypes = operationTypes
    var availableTypes = Set<QualifiedName>()

    func register(simple: SimpleType) {
        if let name = simple.name {
            registry[name] = .base(name.localName)
            availableTypes.insert(name)
        }
        switch simple.content {
        case let .restriction(base: base): usedTypes.insert(base)
        case let .list(itemType: itemType): usedTypes.insert(itemType)
        case let .listWrapped(wrapped): register(simple: wrapped)
        }
    }

    func register(complex: ComplexType) {
        if let name = complex.name {
            registry[name] = .base(name.localName)
            availableTypes.insert(name)
        }
        switch complex.content {
        case let .sequence(sequence):
            for element in sequence.elements {
                register(element: element)
            }
        case .empty: break
        }
    }

    func register(element: Element) {
        switch element.content {
        case let .base(base):
            usedTypes.insert(base)
        case let .complex(complex):
            registry[element.name] = .base(element.name.localName)
            register(complex: complex)
            availableTypes.insert(element.name)
        }
    }

    for node in wsdl.schema {
        switch node {
        case .import: break
        case let .simpleType(simple): register(simple: simple)
        case let .complexType(complex): register(complex: complex)
        case let .element(element): register(element: element)
        }
    }

    let customTypes = usedTypes.subtracting(baseTypes.keys)
    let missingTypes = customTypes.subtracting(availableTypes)
    guard missingTypes.count == 0 else {
        throw GeneratorError.missingTypes(missingTypes)
    }

    for node in wsdl.schema {
        switch node {
        case let .simpleType(simple) where usedTypes.contains(simple.name!):
            fatalError("not implemented")
        case let .complexType(complex) where usedTypes.contains(complex.name!):
            generateComplex(print, complex: complex, registry: registry)
        case let .element(element) where usedTypes.contains(element.name):
            switch element.content {
            case .base: break
            case .complex: fatalError("not implemented")
            }
        default:
            break
        }
    }
}

func generateComplex(_ print: Writer, complex: ComplexType, registry: Registry) {
    guard let name = complex.name else { abort() }

    print("struct \(name.localName): XMLSerializable, XMLDeserializable {")

    switch complex.content {
    case let .sequence(sequence):
        let elements = sequence.elements.map {
            (element: $0, type: typeForElement($0, registry: registry))
        }

        // properties
        for (element, type) in elements {
            print("    let \(element.name.localName): \(type.signature)")
        }
        print("")

        // initialization
        let initSignature = elements.map({ "\($0.name.localName): \($1.signature)" }).joined(separator: ", ")
        print("    init(\(initSignature)) {")
        for (element, _) in elements {
            print("        self.\(element.name.localName) = \(element.name.localName)")
        }
        print("    }")
        print("")

        // deserialization
        print("    init(deserialize node: XMLElement) throws {")
        for (element, type) in elements {
            let name = element.name.localName

            switch type {
            case let .base(type):
                print("        guard let \(name) = node.elements(forLocalName: \"\(name)\", uri: \"\(element.name.uri)\").first else {")
                print("            throw XMLDeserializationError.noElementWithName(\"\(name)\")")
                print("        }")
                print("        self.\(name) = try \(type)(deserialize: \(name))")

            case let .optional(type):
                guard case let .base(wrappedType) = type else {
                    fatalError("Optional wrapped type \(type) not supported")
                }
                print("        self.\(name) = try node.elements(forLocalName: \"\(name)\", uri: \"\(element.name.uri)\").first.flatMap(\(wrappedType).init(deserialize:))")

            case let .array(type):
                guard case let .base(elementType) = type else {
                    fatalError("Array element type \(type) not supported")
                }
                print("        self.\(name) = try node.elements(forLocalName: \"\(name)\", uri: \"\(element.name.uri)\").map(\(elementType).init(deserialize:))")
            }
        }
        print("    }")
        print("")

        // serialization
        print("    func serialize(_ element: XMLElement) throws {")
        for (element, type) in elements {
            let name = element.name.localName
            switch type {
            case .base:
                print("        let \(name)Node = try element.createElement(localName: \"\(name)\", uri: \"\(element.name.uri)\")")
                print("        try self.\(name).serialize(\(name)Node)")
                print("        element.addChild(\(name)Node)")

            case .optional:
                print("        if let \(name) = self.\(name) {")
                print("            let \(name)Node = try element.createElement(localName: \"\(name)\", uri: \"\(element.name.uri)\")")
                print("            try \(name).serialize(\(name)Node)")
                print("            element.addChild(\(name)Node)")
                print("        }")

            case .array:
                print("        for item in self.\(name) {")
                print("            let \(name)Node = try element.createElement(localName: \"\(name)\", uri: \"\(element.name.uri)\")")
                print("            try item.serialize(\(name)Node)")
                print("            element.addChild(\(name)Node)")
                print("        }")
            }
        }
        print("    }")

    case .empty:
        print("    init() { }")
        print("    init(deserialize node: XMLElement) throws { }")
        print("    func serialize(_ element: XMLElement) throws { }")
    }

    print("}")
    print("")
}

public indirect enum Type {
    case base(String)
    case array(Type)
    case optional(Type)

    var signature: String {
        switch self {
        case let .base(name): return name
        case let .array(type): return "[\(type.signature)]"
        case let .optional(type): return "\(type.signature)?"
        }
    }
}

let baseTypes: [QualifiedName: Type] = [
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

func typeForElement(_ element: Element, registry: [QualifiedName: Type]) -> Type {
    switch element.content {
    case let .base(base):
        guard let type = registry[base] else { abort() }
        switch (element.occurs?.startIndex, element.occurs?.endIndex) {
        case (0?, 1?): return .optional(type)
        case (nil, nil), (1?, 1?): return type
        default: return .array(type)
        }
    case .complex:
        abort()
    }
}

func generateClient(_ print: Writer, wsdl: WSDL, service: Service, binding: Binding, registry: Registry) {
    let port = wsdl.portTypes.first(where: { $0.name == binding.type })!

    print("class \(service.name.localName)Client: Client {")

    for operation in binding.operations {
        let operation2 = port.operations.first(where: { $0.name == operation.name })!

        // No need to guard these calls, the types have been verified before.
        let input = wsdl.messages.first(where: { $0.name == operation2.inputMessage })!.parts.first!
        let output = wsdl.messages.first(where: { $0.name == operation2.outputMessage })!.parts.first!

        let inputType = registry[input.element]!
        let outputType = registry[output.element]!

        print("    func \(operation.name.localName)(input: \(inputType.signature), output: (\(outputType.signature)) -> ()) throws {")
        print("        let parameter = XMLElement(prefix: \"ns0\", localName: \"\(input.name.localName)\", uri: \"\(input.name.uri)\")")
        print("        parameter.addNamespace(XMLNode.namespace(withName: \"ns0\", stringValue: \"\(input.name.uri)\") as! XMLNode)")
        print("        try input.serialize(parameter)")
        print("        try send(parameters: [parameter], output: { body in")
        print("            let element = body.elements(forLocalName: \"\(output.name.localName)\", uri: \"\(output.name.uri)\").first!")
        print("            output(try \(outputType.signature)(deserialize: element))")
        print("        })")
        print("    }")
        print("")
    }

    print("}")
}
