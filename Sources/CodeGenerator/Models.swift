import Foundation
import SchemaParser

indirect enum SwiftType {
    case identifier(String)
    case optional(SwiftType)
    case array(SwiftType)

    init(type: String, element: Element) {
        switch (element.occurs?.startIndex, element.occurs?.endIndex) {
        case (0?, 1?): self = .optional(.identifier(type))
        case (nil, nil), (1?, 1?): self = .identifier(type)
        default: self = .array(.identifier(type))
        }
    }
}

struct SwiftProperty {
    let name: String
    let type: SwiftType
}

protocol SwiftMetaType {
    var name: String { get }

    func toSwiftCode(indentedBy indentChars: String) -> SwiftCode
    func toLinesOfCode(at indentation: Indentation) -> [LineOfCode]
}

struct SwiftClass: SwiftMetaType {
    let name: String
    let properties: [SwiftProperty]
    let nestedTypes: [SwiftMetaType]
}

struct SwiftEnum: SwiftMetaType {
    let name: String
    let rawType: SwiftType
    let cases: [String: String]
}

extension ComplexType {
    func toSwift() -> SwiftClass {
        let name = self.name!.localName.toSwiftTypeName()
        var properties = [SwiftProperty]()
        var nestedTypes = [SwiftMetaType]()
        switch self.content {
        case let .sequence(sequence):
            for element in sequence.elements {
                switch element.content {
                case let .base(base):
                    properties.append(SwiftProperty(name: element.name.localName.toSwiftPropertyName(), type: .init(type: base.localName.toSwiftTypeName(), element: element)))
                case let .complex(complex):
                    nestedTypes.append(complex.toSwift())
                    properties.append(SwiftProperty(name: element.name.localName.toSwiftPropertyName(), type: .init(type: "UNNAMED", element: element)))
                }
            }
        case .empty: break
        }

        return SwiftClass(name: name, properties: properties, nestedTypes: nestedTypes)
    }
}

extension SimpleType {
    func toSwift(name: String? = nil) -> SwiftMetaType {
        print(self)
        switch self.content {
        case .list: fatalError()
        case let .listWrapped(wrapped):

            print(wrapped)
            fatalError()
        case let .restriction(restriction):
            let name = name ?? self.name!.localName.toSwiftTypeName()
            let cases = restriction.enumeration.dictionary({ ($0.toSwiftPropertyName(), $0) })
            return SwiftEnum(name: name, rawType: .identifier("String"), cases: cases)
        }
    }
}
