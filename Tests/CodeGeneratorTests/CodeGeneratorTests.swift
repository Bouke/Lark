import XCTest

@testable import CodeGenerator
@testable import Lark
@testable import SchemaParser

class CodeGeneratorTests: XCTestCase {
    let NS = "http://tempuri.org/"
    let STRING = QualifiedName(uri: NS_XS, localName: "string")

    func qname(_ name: String) -> QualifiedName {
        return QualifiedName(uri: NS, localName: name)
    }

    func testEnum() throws {
        let schema = Schema(nodes: [
            .simpleType(.init(
                name: qname("my-type"),
                content: .restriction(.init(
                    base: STRING,
                    enumeration: ["A", "B", "C"],
                    pattern: nil
                ))
            ))
        ])
        XCTAssertCode(actual: try schema.generateCode(), expected: try readlines("enum.txt"))
    }

    func testList() throws {
        let schema = Schema(nodes: [
            .simpleType(.init(
                name: qname("FooBar"),
                content: .restriction(.init(
                    base: STRING,
                    enumeration: ["foo", "bar"],
                    pattern: nil
                ))
            )),
            .simpleType(.init(
                name: qname("FooBarList"),
                content: .list(itemType: qname("FooBar"))
            ))
        ])
        XCTAssertCode(actual: try schema.generateCode(), expected: try readlines("list.txt"))
    }

    func testListWrapped() throws {
        let schema = Schema(nodes: [
            .simpleType(.init(
                name: qname("FooBar"),
                content: .listWrapped(.init(
                    name: nil,
                    content: .restriction(.init(
                        base: STRING,
                        enumeration: ["foo", "bar"],
                        pattern: nil
                        ))
                    ))
                ))
            ])
        XCTAssertCode(actual: try schema.generateCode(), expected: try readlines("list_wrapped.txt"))
    }

    func testPattern() throws {
        let schema = Schema(nodes: [
            .simpleType(.init(
                name: qname("guid"),
                content: .restriction(.init(
                    base: STRING,
                    enumeration: [],
                    pattern: "[\\da-fA-F]{8}-[\\da-fA-F]{4}-[\\da-fA-F]{4}-[\\da-fA-F]{4}-[\\da-fA-F]{12}"
                    ))
                ))
            ])
        XCTAssertCode(actual: try schema.generateCode(), expected: [
            "typealias Guid = String"
            ])
    }

    func testComplexEmpty() throws {
        let schema = Schema(nodes: [
            .complexType(.init(
                name: qname("my-type"),
                content: .empty
            ))
        ])
        XCTAssertCode(actual: try schema.generateCode(), expected: try readlines("complex_empty.txt"))
    }

    func testComplexSequence() throws {
        let schema = Schema(nodes: [
            .complexType(.init(
                name: qname("my-type"),
                content: .sequence(.init(
                    elements: [
                        .init(name: qname("a"), content: .base(STRING), occurs: nil, nillable: false),
                        .init(name: qname("b"), content: .base(STRING), occurs: 0..<1, nillable: false),
                        .init(name: qname("c"), content: .base(STRING), occurs: 1..<1, nillable: false),
                        .init(name: qname("d"), content: .base(STRING), occurs: 1..<2, nillable: false),
                        .init(name: qname("e"), content: .base(STRING), occurs: 1..<Int.max, nillable: false),
                    ]
                ))
            ))
        ])
        XCTAssertCode(actual: try schema.generateCode(), expected: try readlines("complex_sequence.txt"))
    }

    func testElementWithComplexBase() throws {
        let schema = Schema(nodes: [
            .complexType(.init(
                name: qname("my-type"),
                content: .sequence(.init(
                    elements: [
                        .init(name: qname("a"), content: .base(STRING), occurs: nil, nillable: false),
                        .init(name: qname("b"), content: .base(STRING), occurs: 0..<1, nillable: false),
                        .init(name: qname("c"), content: .base(STRING), occurs: 1..<1, nillable: false),
                        .init(name: qname("d"), content: .base(STRING), occurs: 1..<2, nillable: false),
                        .init(name: qname("e"), content: .base(STRING), occurs: 1..<Int.max, nillable: false),
                        ]
                    ))
                )),
            .element(.init(
                name: qname("my-element"),
                content: .base(qname("my-type")),
                occurs: nil,
                nillable: false
                ))
            ])
        XCTAssertCode(actual: try schema.generateCode(), expected: try readlines("element_with_complex_base.txt"))
    }

    func testComplexWithComplexBase() throws {
        let schema = Schema(nodes: [
            .complexType(.init(
                name: qname("my-type"),
                content: .sequence(.init(
                    elements: [
                        .init(name: qname("a"), content: .base(STRING), occurs: nil, nillable: false),
                        ]
                    ))
                )),
            .element(.init(
                name: qname("my-element"),
                content: .base(qname("my-type")),
                occurs: nil,
                nillable: false
                ))
            ])
        XCTAssertCode(actual: try schema.generateCode(), expected: try readlines("complex_with_complex_base.txt"))
    }

    func testComplexExtension() throws {
        let schema = try deserialize("complex_extension.xsd")
        XCTAssertCode(actual: try schema.generateCode(), expected: try readlines("complex_extension.txt"))
    }

    func testNillableIdentifier() throws {
        let schema = try deserialize("nillable_identifier.xsd")
        let expected = try readlines("nillable_identifier.txt")
        XCTAssertCode(actual: try schema.generateCode(), expected: expected)
    }

    func testNillableOptional() throws {
        let schema = try deserialize("nillable_optional.xsd")
        let expected = try readlines("nillable_optional.txt")
        XCTAssertCode(actual: try schema.generateCode(), expected: expected)
    }

    func testNillableArray() throws {
        let schema = try deserialize("nillable_array.xsd")
        let expected = try readlines("nillable_array.txt")
        XCTAssertCode(actual: try schema.generateCode(), expected: expected)
    }

    func testMessageWithType() throws {
        let webService = try deserializeWebServiceDescription("message_with_type.wsdl")
        let expected = try readlines("message_with_type.txt")
        XCTAssertCode(actual: try generate(webService: webService, service: webService.services.first!).components(separatedBy: "\n"),
                      expected: expected)
    }
}
