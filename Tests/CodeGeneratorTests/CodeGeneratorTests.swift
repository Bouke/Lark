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
                        .init(name: qname("b"), content: .base(STRING), occurs: 0..<1),
                        .init(name: qname("c"), content: .base(STRING), occurs: 1..<1),
                        .init(name: qname("d"), content: .base(STRING), occurs: 1..<2),
                        .init(name: qname("e"), content: .base(STRING), occurs: 1..<Int.max),
                    ]
                ))
            ))
        ])
        XCTAssertEqual(try schema.generateCode().joined(separator: "\n"), [
            "class MyType: XMLDeserializable {",
            "    let a: String",
            "    let b: String?",
            "    let c: String",
            "    let d: [String]",
            "    let e: [String]",
            "    init(a: String, b: String?, c: String, d: [String], e: [String]) {",
            "        self.a = a",
            "        self.b = b",
            "        self.c = c",
            "        self.d = d",
            "        self.e = e",
            "    }",
            "    required init(deserialize element: XMLElement) throws {",
            "        self.a = try String(deserialize: element.elements(forLocalName: \"a\", uri: \"http://tempuri.org/\").first!)",
            "        self.b = try element.elements(forLocalName: \"b\", uri: \"http://tempuri.org/\").first.map(String.init(deserialize:))",
            "        self.c = try String(deserialize: element.elements(forLocalName: \"c\", uri: \"http://tempuri.org/\").first!)",
            "        self.d = try element.elements(forLocalName: \"d\", uri: \"http://tempuri.org/\").map(String.init(deserialize:))",
            "        self.e = try element.elements(forLocalName: \"e\", uri: \"http://tempuri.org/\").map(String.init(deserialize:))",
            "    }",
            "    func serialize(_ element: XMLElement) throws {",
            "        let aNode = try element.createElement(localName: \"a\", uri: \"http://tempuri.org/\")",
            "        element.addChild(aNode)",
            "        try a.serialize(aNode)",
            "        if let b = b {",
            "            let bNode = try element.createElement(localName: \"b\", uri: \"http://tempuri.org/\")",
            "            element.addChild(bNode)",
            "            try b.serialize(bNode)",
            "        }",
            "        let cNode = try element.createElement(localName: \"c\", uri: \"http://tempuri.org/\")",
            "        element.addChild(cNode)",
            "        try c.serialize(cNode)",
            "        for item in d {",
            "            let itemNode = try element.createElement(localName: \"d\", uri: \"http://tempuri.org/\")",
            "            element.addChild(itemNode)",
            "            try item.serialize(itemNode)",
            "        }",
            "        for item in e {",
            "            let itemNode = try element.createElement(localName: \"e\", uri: \"http://tempuri.org/\")",
            "            element.addChild(itemNode)",
            "            try item.serialize(itemNode)",
            "        }",
            "    }",
            "}",
        ].joined(separator: "\n"))
    }

    func testElementWithComplexBase() throws {
        let schema = XSD(nodes: [
            .complexType(.init(
                name: qname("my-type"),
                content: .sequence(.init(
                    elements: [
                        .init(name: qname("a"), content: .base(STRING), occurs: nil),
                        .init(name: qname("b"), content: .base(STRING), occurs: 0..<1),
                        .init(name: qname("c"), content: .base(STRING), occurs: 1..<1),
                        .init(name: qname("d"), content: .base(STRING), occurs: 1..<2),
                        .init(name: qname("e"), content: .base(STRING), occurs: 1..<Int.max),
                        ]
                    ))
                )),
            .element(.init(
                name: qname("my-element"),
                content: .base(qname("my-type")),
                occurs: nil
                ))
            ])
        XCTAssertEqual(try schema.generateCode().joined(separator: "\n"), [
            "class MyType: XMLDeserializable {",
            "    let a: String",
            "    let b: String?",
            "    let c: String",
            "    let d: [String]",
            "    let e: [String]",
            "    init(a: String, b: String?, c: String, d: [String], e: [String]) {",
            "        self.a = a",
            "        self.b = b",
            "        self.c = c",
            "        self.d = d",
            "        self.e = e",
            "    }",
            "    required init(deserialize element: XMLElement) throws {",
            "        self.a = try String(deserialize: element.elements(forLocalName: \"a\", uri: \"http://tempuri.org/\").first!)",
            "        self.b = try element.elements(forLocalName: \"b\", uri: \"http://tempuri.org/\").first.map(String.init(deserialize:))",
            "        self.c = try String(deserialize: element.elements(forLocalName: \"c\", uri: \"http://tempuri.org/\").first!)",
            "        self.d = try element.elements(forLocalName: \"d\", uri: \"http://tempuri.org/\").map(String.init(deserialize:))",
            "        self.e = try element.elements(forLocalName: \"e\", uri: \"http://tempuri.org/\").map(String.init(deserialize:))",
            "    }",
            "    func serialize(_ element: XMLElement) throws {",
            "        let aNode = try element.createElement(localName: \"a\", uri: \"http://tempuri.org/\")",
            "        element.addChild(aNode)",
            "        try a.serialize(aNode)",
            "        if let b = b {",
            "            let bNode = try element.createElement(localName: \"b\", uri: \"http://tempuri.org/\")",
            "            element.addChild(bNode)",
            "            try b.serialize(bNode)",
            "        }",
            "        let cNode = try element.createElement(localName: \"c\", uri: \"http://tempuri.org/\")",
            "        element.addChild(cNode)",
            "        try c.serialize(cNode)",
            "        for item in d {",
            "            let itemNode = try element.createElement(localName: \"d\", uri: \"http://tempuri.org/\")",
            "            element.addChild(itemNode)",
            "            try item.serialize(itemNode)",
            "        }",
            "        for item in e {",
            "            let itemNode = try element.createElement(localName: \"e\", uri: \"http://tempuri.org/\")",
            "            element.addChild(itemNode)",
            "            try item.serialize(itemNode)",
            "        }",
            "    }",
            "}",
            "class MyElement: MyType {",
            "    override init(a: String, b: String?, c: String, d: [String], e: [String]) {",
            "        super.init(a: a, b: b, c: c, d: d, e: e)",
            "    }",
            "    required init(deserialize element: XMLElement) throws {",
            "        try super.init(deserialize: element)",
            "    }",
            "    override func serialize(_ element: XMLElement) throws {",
            "        try super.serialize(element)",
            "    }",
            "}",
            ].joined(separator: "\n"))
    }

}
