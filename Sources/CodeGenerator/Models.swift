import Foundation
import SchemaParser
import Lark

// MARK: - SOAP Types

indirect enum SwiftType {
    case identifier(Identifier)
    case optional(SwiftType)
    case nillable(SwiftType)
    case array(SwiftType)

    init(type: Identifier, element: Element) {
        switch (element.nillable, element.occurs?.startIndex, element.occurs?.endIndex) {
        case (false, 0?, 1?):
            self = .optional(.identifier(type))
        case (true, 0?, 1?):
            self = .optional(.nillable(.identifier(type)))

        case (false, nil, nil), (false, 1?, 1?):
            self = .identifier(type)
        case (true, nil, nil), (true, 1?, 1?):
            self = .nillable(.identifier(type))

        case (false, _, _):
            self = .array(.identifier(type))
        case (true, _, _):
            self = .array(.nillable(.identifier(type)))
        }
    }
}

extension SwiftType: Equatable {
    static func == (lhs: SwiftType, rhs: SwiftType) -> Bool {
        switch (lhs, rhs) {
        case let (.identifier(lhs), .identifier(rhs)): return lhs == rhs
        case let (.optional(lhs), .optional(rhs)): return lhs == rhs
        case let (.nillable(lhs), .nillable(rhs)): return lhs == rhs
        case let (.array(lhs), .array(rhs)): return lhs == rhs
        default: return false
        }
    }
}

struct SwiftProperty {
    let name: String
    let type: SwiftType
    let element: Element
}

public protocol SwiftMetaType: LinesOfCodeConvertible {
    var name: Identifier { get }
}

public struct SwiftBuiltin: SwiftMetaType {
    public let name: Identifier
}

public class SwiftTypeClass: SwiftMetaType {
    public let name: Identifier
    let base: SwiftTypeClass?
    let protocols: [String]
    let properties: [SwiftProperty]
    let nestedTypes: [SwiftMetaType]
    let members: [LinesOfCodeConvertible]

    init(
        name: String,
        base: SwiftTypeClass? = nil,
        protocols: [String] = [],
        properties: [SwiftProperty] = [],
        nestedTypes: [SwiftMetaType] = [],
        members: [LinesOfCodeConvertible] = []) {
        self.name = name
        self.base = base
        self.protocols = protocols
        self.properties = properties
        self.nestedTypes = nestedTypes
        self.members = members
    }
}

public struct SwiftEnum: SwiftMetaType {
    public let name: Identifier
    let rawType: SwiftType
    let cases: [String: String]
}

public struct SwiftTypealias: SwiftMetaType {
    public let name: Identifier
    let type: SwiftType
}

public struct SwiftParameter {
    let name: Identifier
    let type: SwiftType
}

public struct SwiftList: SwiftMetaType {
    public let name: Identifier
    let element: SwiftType
    let nestedTypes: [SwiftMetaType]
}

// MARK: - SOAP Client

public struct SwiftClientClass: SwiftMetaType {
    public let name: Identifier
    let methods: [ServiceMethod]
    let port: Service.Port
}

struct ServiceMethod {
    typealias Message = (element: QualifiedName, type: SwiftTypeClass)

    let name: Identifier
    let input: Message
    let output: Message
    let action: URL?
    let documentation: String?

    init(operation: PortType.Operation, input: Message, output: Message, action: URL?, documentation: String?) {
        name = operation.name.localName.toSwiftPropertyName()
        self.input = input
        self.output = output
        self.action = action
        self.documentation = documentation
    }
}
