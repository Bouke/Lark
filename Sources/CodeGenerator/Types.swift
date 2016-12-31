import SchemaParser

// MARK:- SOAP Types

extension ComplexType {
    func toSwift(name: String? = nil, mapping: TypeMapping) -> SwiftTypeClass {
        let name = name ?? mapping[.type(self.name!)]!
        var properties = [SwiftProperty]()
        var nestedTypes = [SwiftMetaType]()
        switch self.content {
        case let .sequence(sequence):
            for element in sequence.elements {
                switch element.content {
                case let .base(base):
                    properties.append(SwiftProperty(name: element.name.localName.toSwiftPropertyName(), type: .init(type: mapping[.type(base)]!, element: element)))
                case let .complex(complex):
                    nestedTypes.append(complex.toSwift(mapping: mapping))
                    properties.append(SwiftProperty(name: element.name.localName.toSwiftPropertyName(), type: .init(type: "UNNAMED", element: element)))
                }
            }
        case .empty: break
        }

        return SwiftTypeClass(name: name, properties: properties, nestedTypes: nestedTypes)
    }
}

extension SimpleType {
    func toSwift(name: String? = nil, mapping: TypeMapping) -> SwiftMetaType {
        let name = name ?? mapping[.type(self.name!)]!
        switch self.content {
        case .list: fatalError()
        case let .listWrapped(wrapped):
            return SwiftTypeClass(
                name: "ArrayOf\(name)",
                properties: [SwiftProperty(name: "items", type: .array(.identifier(name)))],
                nestedTypes: [wrapped.toSwift(name: name, mapping: mapping)]
            )
        case let .restriction(restriction):
            let cases = restriction.enumeration.dictionary({ ($0.toSwiftPropertyName(), $0) })
            return SwiftEnum(name: name, rawType: .identifier("String"), cases: cases)
        }
    }
}

extension Element {
    func toSwift(mapping: TypeMapping) -> SwiftTypeClass {
        let name = mapping[.element(self.name)]!
        switch self.content {
        case let .base(base): return SwiftTypeClass(name: name, superName: mapping[.type(base)]!)
        case let .complex(complex): return complex.toSwift(name: name, mapping: mapping)
        }
    }
}


// MARK:- SOAP Client

extension Service {
    func toSwift(wsdl: WSDL) -> SwiftClientClass {
        // SOAP 1.1 port
        let port = ports.first { if case .soap = $0.address { return true } else { return false } }!
        let binding = wsdl.bindings.first { $0.name == port.binding }!
        let portType = wsdl.portTypes.first { $0.name == binding.type }!

        let name = "\(self.name.localName.toSwiftTypeName())Client"

        let methods = portType.operations.map { operation -> ServiceMethod in
            let input = wsdl.messages.first { $0.name == operation.inputMessage }!
            let output = wsdl.messages.first { $0.name == operation.outputMessage }!
            return ServiceMethod(operation: operation, input: input, output: output)
        }

        return SwiftClientClass(name: name, methods: methods)
    }
}
