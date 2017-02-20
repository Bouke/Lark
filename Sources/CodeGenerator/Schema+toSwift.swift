import Foundation
import SchemaParser
import Lark

// MARK: - SOAP Types

extension ComplexType {
    public func toSwift(name: String? = nil, mapping: TypeMapping, types: Types) -> SwiftTypeClass {
        precondition(name != nil || self.name != nil, "No name specified for complexType")

        let name = name ?? mapping[.type(self.name!)]!
        let base: SwiftTypeClass?
        let properties: [SwiftProperty]
        let nestedTypes: [SwiftMetaType]
        switch self.content {
        case let .sequence(sequence):
            base = nil
            (properties, nestedTypes) = sequenceToSwift(name: name, sequence: sequence, mapping: mapping, types: types)
        case let .complex(complex):
            base = (types[.type(complex.base)]! as! SwiftTypeClass)
            let content: Content.ComplexContent.Content.Content
            switch complex.content {
            case let .restriction(restriction): content = restriction
            case let .extension(`extension`): content = `extension`
            }
            switch content {
            case .empty:
                (properties, nestedTypes) = ([], [])
            case let .sequence(sequence):
                (properties, nestedTypes) = sequenceToSwift(name: name, sequence: sequence, mapping: mapping, types: types)
            }
        case .empty:
            (base, properties, nestedTypes) = (nil, [], [])
        }

        return SwiftTypeClass(name: name, base: base, properties: properties, nestedTypes: nestedTypes)
    }

    func sequenceToSwift(
        name: Identifier,
        sequence: Content.Sequence,
        mapping: TypeMapping,
        types: Types)
        -> (properties: [SwiftProperty], nested: [SwiftMetaType])
    {
        var properties: [SwiftProperty] = []
        var nestedTypes: [SwiftMetaType] = []
        for element in sequence.elements {
            switch element.content {
            case let .base(base):
                properties.append(SwiftProperty(
                    name: element.name.localName.toSwiftPropertyName(),
                    type: .init(type: mapping[.type(base)]!, element: element),
                    element: element))
            case let .complex(complex):
                // @todo don't generate type name here, but delegate to something 
                // like a `Scope` type that handles inherited scope as well.
                let type = element.name.localName.toSwiftTypeName()
                nestedTypes.append(complex.toSwift(name: type, mapping: mapping, types: types))
                properties.append(SwiftProperty(
                    name: element.name.localName.toSwiftPropertyName(),
                    type: .init(type: type, element: element),
                    element: element))
            }
        }
        return (properties, nestedTypes)
    }
}

extension SimpleType {
    public func toSwift(name: String? = nil, mapping: TypeMapping, types: Types) throws -> SwiftMetaType {
        let name = name ?? mapping[.type(self.name!)]!
        switch self.content {
        case let .list(itemType):
            let itemName = mapping[.type(itemType)]!
            return SwiftList(name: name, element: .identifier(itemName), nestedTypes: [])
        case let .listWrapped(wrapped):
            let nested = try wrapped.toSwift(name: "Element", mapping: mapping, types: types)
            return SwiftList(name: name, element: .identifier(nested.name), nestedTypes: [nested])
        case let .restriction(restriction):
            if restriction.enumeration.count == 0 {
                // TODO: what to do with the pattern?
                let baseType = mapping[.type(restriction.base)]!
                return SwiftTypealias(name: name, type: .identifier(baseType))
            } else {
                let cases = restriction.enumeration.dictionary({ ($0.toSwiftPropertyName(), $0) })
                return SwiftEnum(name: name, rawType: .identifier("String"), cases: cases)
            }
        }
    }
}

extension Element {
    public func toSwift(mapping: TypeMapping, types: Types) -> SwiftMetaType {
        let name = mapping[.element(self.name)]!
        switch self.content {
        case let .base(base):
            let baseType = types[.type(base)]!
            return SwiftTypealias(name: name, type: .init(type: baseType.name, element: self))
        case let .complex(complex):
            return complex.toSwift(name: name, mapping: mapping, types: types)
        }
    }
}

// MARK: - SOAP Client

extension Service {
    public func toSwift(webService: WebServiceDescription, types: Types) -> SwiftClientClass {
        // SOAP 1.1 port
        let port = ports.first { if case .soap11 = $0.address { return true } else { return false } }!
        let binding = webService.bindings.first { $0.name == port.binding }!
        let portType = webService.portTypes.first { $0.name == binding.type }!

        let name = "\(self.name.localName.toSwiftTypeName())Client"

        // returns the message's {input,output} type and corresponding type identifier
        let message = { (messageName: QualifiedName) -> (QualifiedName, Identifier) in
            let message = webService.messages.first { $0.name == messageName }!
            if let element = message.parts.first!.element {
                return (element, types[.element(element)]!.name)
            } else if let type = message.parts.first!.type {
                return (type, types[.type(type)]!.name)
            } else {
                fatalError("Unsupported element message type")
            }
        }

        //TODO: zip operations first; combinding port.operation and binding.operation
        //TODO: compare operation signature instead (and resolve nmtoken correctly)
        let methods = portType.operations
            .map { operation in
                (port: operation, binding: binding.operations.first(where: { $0.name.localName == operation.name.localName })!)
            }
            .map { operation -> ServiceMethod in
                let input = message(operation.port.inputMessage)
                let output = message(operation.port.outputMessage)
                return ServiceMethod(operation: operation.port,
                                     input: input,
                                     output: output,
                                     action: operation.binding.action)
            }

        return SwiftClientClass(name: name, methods: methods, port: port)
    }
}
