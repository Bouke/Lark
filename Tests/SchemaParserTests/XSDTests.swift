import XCTest

@testable import SchemaParser

class XSDTests: XCTestCase {
    func deserialize(_ input: String) throws -> XSD {
        let url = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("Inputs")
            .appendingPathComponent(input)
        return try parseXSD(contentsOf: url)
    }

    func testComplexExtension() throws {
        let xsd = try deserialize("complex_extension.xsd")
        XCTAssertEqual(xsd.count, 3)

        let full = xsd.flatMap { $0.complexType }.first { $0.name?.localName == "fullpersoninfo" }!
        guard case let .complex(complex) = full.content,
              case let .extension(_extension) = complex.content,
              case let .sequence(sequence) = _extension else {
            return XCTFail("Expected complexContent -> extension -> sequence")
        }
        XCTAssertEqual(sequence.elements.count, 3)
    }

    func testNillable() throws {
        let xsd = try deserialize("nillable_identifier.xsd")
        XCTAssertEqual(xsd.count, 1)

        // unwrap into expected type
        guard case let .element(type)? = xsd.first,
            case let .complex(complex) = type.content,
            case let .sequence(sequence) = complex.content else {
                return XCTFail("Expected element with complexType with sequence.")
        }

        // assure xsd is parsed as expected
        XCTAssertEqual(sequence.elements.count, 3)
        XCTAssertEqual(sequence.elements[0].name.localName, "firstname")
        XCTAssertEqual(sequence.elements[1].name.localName, "tussenvoegsel")
        XCTAssertEqual(sequence.elements[2].name.localName, "lastname")

        // actual tests
        XCTAssertEqual(sequence.elements[0].nillable, false, "Should parse nillable=false as false")
        XCTAssertEqual(sequence.elements[1].nillable, true, "Should parse nillable=true as true")
        XCTAssertEqual(sequence.elements[2].nillable, false, "Should parse absence of nillable as false")
    }
}
