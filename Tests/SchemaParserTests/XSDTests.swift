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
}
