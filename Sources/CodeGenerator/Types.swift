import SchemaParser

extension ComplexType {
    func toSwift(mapping: TypeMapping) -> SwiftClass {
        let name = mapping[self.name!]!
        var properties = [SwiftProperty]()
        var nestedTypes = [SwiftMetaType]()
        switch self.content {
        case let .sequence(sequence):
            for element in sequence.elements {
                switch element.content {
                case let .base(base):
                    properties.append(SwiftProperty(name: element.name.localName.toSwiftPropertyName(), type: .init(type: mapping[base]!, element: element)))
                case let .complex(complex):
                    nestedTypes.append(complex.toSwift(mapping: mapping))
                    properties.append(SwiftProperty(name: element.name.localName.toSwiftPropertyName(), type: .init(type: "UNNAMED", element: element)))
                }
            }
        case .empty: break
        }

        return SwiftClass(name: name, properties: properties, nestedTypes: nestedTypes)
    }
}

extension SimpleType {
    func toSwift(name: String? = nil, mapping: TypeMapping) -> SwiftMetaType {
        let name = name ?? mapping[self.name!]!
        switch self.content {
        case .list: fatalError()
        case let .listWrapped(wrapped):
            return SwiftClass(
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
