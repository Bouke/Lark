import XCTest

@testable import CodeGenerator
@testable import Lark
@testable import SchemaParser

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
                    enumeration: ["A", "B", "C"],
                    pattern: nil
                ))
            ))
        ])
        XCTAssertCode(actual: try schema.generateCode(), expected: [
            "enum MyType: String, XMLSerializable, XMLDeserializable, StringSerializable, StringDeserializable {",
            "    case a = \"A\"",
            "    case b = \"B\"",
            "    case c = \"C\"",
            "    init(deserialize element: XMLElement) throws {",
            "        self.init(rawValue: element.stringValue!)!",
            "    }",
            "    func serialize(_ element: XMLElement) throws {",
            "        element.stringValue = self.rawValue",
            "    }",
            "    init(string: String) throws {",
            "        self.init(rawValue: string)!",
            "    }",
            "    func serialize() throws -> String {",
            "        return self.rawValue",
            "    }",
            "}"
        ])
    }

    func testList() throws {
        let schema = XSD(nodes: [
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
        XCTAssertCode(actual: try schema.generateCode(), expected: [
            "struct FooBarList: StringSerializableList {",
            "    var _contents: [FooBar] = []",
            "    init(_ contents: [FooBar]) {",
            "        _contents = contents",
            "    }",
            "}",
            "enum FooBar: String, XMLSerializable, XMLDeserializable, StringSerializable, StringDeserializable {",
            "    case bar = \"bar\"",
            "    case foo = \"foo\"",
            "    init(deserialize element: XMLElement) throws {",
            "        self.init(rawValue: element.stringValue!)!",
            "    }",
            "    func serialize(_ element: XMLElement) throws {",
            "        element.stringValue = self.rawValue",
            "    }",
            "    init(string: String) throws {",
            "        self.init(rawValue: string)!",
            "    }",
            "    func serialize() throws -> String {",
            "        return self.rawValue",
            "    }",
            "}",
            ])
    }

    func testListWrapped() throws {
        let schema = XSD(nodes: [
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
        XCTAssertCode(actual: try schema.generateCode(), expected: [
            "struct FooBar: StringSerializableList {",
            "    enum Element: String, XMLSerializable, XMLDeserializable, StringSerializable, StringDeserializable {",
            "        case bar = \"bar\"",
            "        case foo = \"foo\"",
            "        init(deserialize element: XMLElement) throws {",
            "            self.init(rawValue: element.stringValue!)!",
            "        }",
            "        func serialize(_ element: XMLElement) throws {",
            "            element.stringValue = self.rawValue",
            "        }",
            "        init(string: String) throws {",
            "            self.init(rawValue: string)!",
            "        }",
            "        func serialize() throws -> String {",
            "            return self.rawValue",
            "        }",
            "    }",
            "    var _contents: [Element] = []",
            "    init(_ contents: [Element]) {",
            "        _contents = contents",
            "    }",
            "}",
            ])
    }

    func testPattern() throws {
        let schema = XSD(nodes: [
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
        let schema = XSD(nodes: [
            .complexType(.init(
                name: qname("my-type"),
                content: .empty
            ))
        ])
        XCTAssertCode(actual: try schema.generateCode(), expected: [
            "class MyType: XMLDeserializable {",
            "    init() {",
            "    }",
            "    required init(deserialize element: XMLElement) throws {",
            "    }",
            "    func serialize(_ element: XMLElement) throws {",
            "    }",
            "}"
        ])
    }

    func testComplexSequence() throws {
        let schema = XSD(nodes: [
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
        XCTAssertCode(actual: try schema.generateCode(), expected: [
            "class MyType: XMLDeserializable {",
            "    let a: String",
            "    let b: String?",
            "    let c: String",
            "    let d: [String]",
            "    let e: [String]",
            "    init(a: String, b: String? = nil, c: String, d: [String], e: [String]) {",
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
        ])
    }

    func testElementWithComplexBase() throws {
        let schema = XSD(nodes: [
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
        XCTAssertCode(actual: try schema.generateCode(), expected: [
            "typealias MyElement = MyType",
            "class MyType: XMLDeserializable {",
            "    let a: String",
            "    let b: String?",
            "    let c: String",
            "    let d: [String]",
            "    let e: [String]",
            "    init(a: String, b: String? = nil, c: String, d: [String], e: [String]) {",
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
            ])
    }

    func testComplexWithComplexBase() throws {
        let schema = XSD(nodes: [
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
        XCTAssertCode(actual: try schema.generateCode(), expected: [
            "typealias MyElement = MyType",
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
            "}",
            ])
    }

    func testComplexExtension() throws {
        let schema = try deserialize("complex_extension.xsd")
        XCTAssertCode(actual: try schema.generateCode(), expected: [
            "typealias Employee = Fullpersoninfo",
            "class Fullpersoninfo: Personinfo {",
            "    let address: String",
            "    let city: String",
            "    let country: String",
            "    init(firstname: String, lastname: String, address: String, city: String, country: String) {",
            "        self.address = address",
            "        self.city = city",
            "        self.country = country",
            "        super.init(firstname: firstname, lastname: lastname)",
            "    }",
            "    required init(deserialize element: XMLElement) throws {",
            "        self.address = try String(deserialize: element.elements(forLocalName: \"address\", uri: \"http://tempuri.org/tns\").first!)",
            "        self.city = try String(deserialize: element.elements(forLocalName: \"city\", uri: \"http://tempuri.org/tns\").first!)",
            "        self.country = try String(deserialize: element.elements(forLocalName: \"country\", uri: \"http://tempuri.org/tns\").first!)",
            "        try super.init(deserialize: element)",
            "    }",
            "    override func serialize(_ element: XMLElement) throws {",
            "        let addressNode = try element.createElement(localName: \"address\", uri: \"http://tempuri.org/tns\")",
            "        element.addChild(addressNode)",
            "        try address.serialize(addressNode)",
            "        let cityNode = try element.createElement(localName: \"city\", uri: \"http://tempuri.org/tns\")",
            "        element.addChild(cityNode)",
            "        try city.serialize(cityNode)",
            "        let countryNode = try element.createElement(localName: \"country\", uri: \"http://tempuri.org/tns\")",
            "        element.addChild(countryNode)",
            "        try country.serialize(countryNode)",
            "        try super.serialize(element)",
            "    }",
            "}",
            "class Personinfo: XMLDeserializable {",
            "    let firstname: String",
            "    let lastname: String",
            "    init(firstname: String, lastname: String) {",
            "        self.firstname = firstname",
            "        self.lastname = lastname",
            "    }",
            "    required init(deserialize element: XMLElement) throws {",
            "        self.firstname = try String(deserialize: element.elements(forLocalName: \"firstname\", uri: \"http://tempuri.org/tns\").first!)",
            "        self.lastname = try String(deserialize: element.elements(forLocalName: \"lastname\", uri: \"http://tempuri.org/tns\").first!)",
            "    }",
            "    func serialize(_ element: XMLElement) throws {",
            "        let firstnameNode = try element.createElement(localName: \"firstname\", uri: \"http://tempuri.org/tns\")",
            "        element.addChild(firstnameNode)",
            "        try firstname.serialize(firstnameNode)",
            "        let lastnameNode = try element.createElement(localName: \"lastname\", uri: \"http://tempuri.org/tns\")",
            "        element.addChild(lastnameNode)",
            "        try lastname.serialize(lastnameNode)",
            "    }",
            "}",
            ])
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
}
