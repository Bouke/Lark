import XCTest

@testable import SchemaParser
@testable import CodeGenerator

class CodeGeneratorTests: XCTestCase {
    func testEnum() throws {
        let ns = "http://tempuri.org/"
        let schema = XSD(nodes: [
            .simpleType(.init(
                name: QualifiedName(uri: ns, localName: "my-type"),
                content: .restriction(.init(
                    base: QualifiedName(uri: NS_XSD, localName: "string"),
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
}
