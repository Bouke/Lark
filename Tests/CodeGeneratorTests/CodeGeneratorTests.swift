import XCTest

@testable import SchemaParser
@testable import CodeGenerator

class CodeGeneratorTests: XCTestCase {
    let NS = "http://tempuri.org/"
    let STRING = QualifiedName(uri: NS_XSD, localName: "string")

    func qname(_ name: String) -> QualifiedName {
        return QualifiedName(uri: NS, localName: name)
    }

    func testEnum() throws {
        let schema = XSD(nodes: [
            .simpleType(.init(
                name: qname("my-type"),
                content: .restriction(.init(
                    base: STRING,
                    enumeration: ["A", "B", "C"]
                ))
            ))
        ])
        XCTAssertEqual(try schema.generateCode().joined(separator: "\n"), [
            "enum MyType: String, XMLSerializable, XMLDeserializable {",
            "    case a = \"A\"",
            "    case b = \"B\"",
            "    case c = \"C\"",
            "    init(deserialize element: XMLElement) throws {",
            "        self.init(rawValue: element.stringValue!)!",
            "    }",
            "    func serialize(_ element: XMLElement) throws {",
            "        element.stringValue = self.rawValue",
            "    }",
            "}"
        ].joined(separator: "\n"))
    }

    func testList() throws {
        let schema = XSD(nodes: [
            .simpleType(.init(
                name: qname("my-type"),
                content: .list(itemType: STRING)
                ))
            ])
        XCTAssertEqual(try schema.generateCode().joined(separator: "\n"), [
        ].joined(separator: "\n"))
    }

    func testComplexEmpty() throws {
        let schema = XSD(nodes: [
            .complexType(.init(
                name: qname("my-type"),
                content: .empty
            ))
        ])
        XCTAssertEqual(try schema.generateCode().joined(separator: "\n"), [
            "class MyType: XMLDeserializable {",
            "    init() {",
            "    }",
            "    required init(deserialize element: XMLElement) throws {",
            "    }",
            "    func serialize(_ element: XMLElement) throws {",
            "    }",
            "}"
        ].joined(separator: "\n"))
    }

    func testComplexSequence() throws {
        let schema = XSD(nodes: [
            .complexType(.init(
                name: qname("my-type"),
                content: .sequence(.init(
                    elements: [
                        .init(name: qname("a"), content: .base(STRING), occurs: nil),
                    ]
                ))
            ))
        ])
        XCTAssertEqual(try schema.generateCode().joined(separator: "\n"), [
            "class MyType: XMLDeserializable {",
            "    let a: String",
            "    init(a: String) {",
            "        self.a = a",
            "    }",
            "    required init(deserialize element: XMLElement) throws {",
            "        self.a = try String(deserialize: element.elements(forLocalName: \"a\", uri: \"http://tempuri.org/\").first!)",
            "    }",
            "    func serialize(_ element: XMLElement) throws {",
            "        let aNode = try element.createElement(localName: \"a\", uri: \"http://tempuri.org/\")",
            "        element.addChild(aNode)",
            "        try a.serialize(aNode)",
            "    }",
            "}"
        ].joined(separator: "\n"))
    }
}
