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

    try generateTypes(print, wsdl: wsdl, binding: binding, registry: &registry)
    try generateClientForBinding(print, wsdl: wsdl, service: service, binding: binding, registry: registry)
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
        case let .base(base): usedTypes.insert(base)
        case .complex: fatalError("Nested complex types not supported")
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
        }
    }

    wsdl.schemas.flatMap({ $0.elements }).forEach(register(element:))
    wsdl.schemas.flatMap({ $0.complexes }).forEach(register(complex:))

    let availableTypes = Set(wsdl.schemas
        .flatMap({ $0.complexes })
        .flatMap { $0.name }
    )

    let customTypes = usedTypes.subtracting(baseTypes.keys)
    let missingTypes = customTypes.subtracting(availableTypes)
    guard missingTypes.count == 0 else {
        throw GeneratorError.missingTypes(missingTypes)
    }

    for complex in wsdl.schemas.flatMap({ $0.complexes }) {
        generateComplex(print, complex: complex, registry: registry)
    }
}

func generateComplex(_ print: Writer, complex: Complex, registry: Registry) {
    guard let name = complex.name else { abort() }

    switch complex.content {
    case let .sequence(sequence):
        let elements = sequence.elements.map {
            (element: $0, type: typeForElement($0, registry: registry))
        }

        if(elements.count == 1) {
            print("typealias \(name.localName) = \(elements[0].type.signature)")
            print("")
            return
        }

        print("struct \(name.localName): XMLSerializable, XMLDeserializable {")

        for (element, type) in elements {
            print("    let \(element.name.localName): \(type.signature)")
        }
        print("")

        let initSignature = elements.map({ "\($0.name.localName): \($1.signature)" }).joined(separator: ", ")
        print("    init(\(initSignature)) {")
        for (element, _) in elements {
            print("        self.\(element.name.localName) = \(element.name.localName)")
        }
        print("")

        print("    init(deserialize node: XMLElement) throws {")
        for (element, type) in elements {
            print("     self.\(element.name.localName) = \(type.signature)(deserialize: )")
        }
        print("    }")
        print("}")
        break
    }

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

func generateClientForBinding(_ print: Writer, wsdl: WSDL, service: Service, binding: Binding, registry: Registry) {
    let port = wsdl.portTypes.first(where: { $0.name == binding.type })!

    print("class \(service.name.localName)Client {")

    for operation in binding.operations {
        let operation2 = port.operations.first(where: { $0.name == operation.name })!
        let input = wsdl.messages.first(where: { $0.name == operation2.inputMessage })!.parts.first!
        let output = wsdl.messages.first(where: { $0.name == operation2.outputMessage })!.parts.first!

        let inputType = registry[input.element]!
        let outputType = registry[output.element]!

        print("    func \(operation.name.localName)(input: \(inputType.signature), output: -> (\(outputType.signature)) -> ()){")
        print("    }")
    }

    print("}")
}
