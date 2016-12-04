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

    func register(element: Element) {
        switch element.content {
        case let .base(base):
            usedTypes.insert(base)
        case let .complex(complex):
            registry[element.name] = .base(element.name.localName)
            register(complex: complex)
        }
    }

    func register(complex: Complex) {
        if let name = complex.name {
            registry[name] = .base(name.localName)
        }
        switch complex.content {
        case let .sequence(sequence):
            for element in sequence.elements {
                register(element: element)
            }
        case .empty: break
        }
    }

    wsdl.schemas.flatMap({ $0.elements }).forEach(register(element:))
    wsdl.schemas.flatMap({ $0.complexes }).forEach(register(complex:))

    let availableTypes = Set<QualifiedName>()
        .union(wsdl.schemas
            .flatMap({ $0.complexes })
            .flatMap { $0.name })
        .union(wsdl.schemas
            .flatMap({ $0.elements })
            .flatMap { element -> QualifiedName? in
                if case .complex = element.content { return element.name } else { return nil }
            })

    let customTypes = usedTypes.subtracting(baseTypes.keys)
    let missingTypes = customTypes.subtracting(availableTypes)
    guard missingTypes.count == 0 else {
        throw GeneratorError.missingTypes(missingTypes)
    }

    // todo: use customTypes instead
    for complex in wsdl.schemas.flatMap({ $0.complexes }) {
        generateComplex(print, complex: complex, registry: registry)
    }
}

func generateComplex(_ print: Writer, complex: Complex, registry: Registry) {
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
    QualifiedName(uri: NS_XSD, localName: "unsignedLong"): .base("UInt64"),
    QualifiedName(uri: NS_XSD, localName: "integer"): .base("Int"),
    QualifiedName(uri: NS_XSD, localName: "string"): .base("String"),
    QualifiedName(uri: NS_XSD, localName: "decimal"): .base("Decimal"),
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
