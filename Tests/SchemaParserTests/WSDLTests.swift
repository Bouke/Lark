import XCTest

@testable import SchemaParser

class SchemaParserTests: XCTestCase {
    func deserialize(_ input: String) throws -> WSDL {
        let url = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Inputs").appendingPathComponent(input)
        return try parseWSDL(contentsOf: url)
    }

    func testNumberConversion() throws {
        let wsdl = try deserialize("numberconversion.wsdl")
        XCTAssertEqual(wsdl.bindings.count, 2)
        XCTAssertEqual(wsdl.bindings.first?.name, QualifiedName(uri: "http://www.dataaccess.com/webservicesserver/", localName: "NumberConversionSoapBinding"))
        XCTAssertEqual(wsdl.bindings.map({ $0.operations }).count, 2)

        XCTAssertEqual(wsdl.messages.count, 4)
        XCTAssertEqual(wsdl.messages.first?.name, QualifiedName(uri: "http://www.dataaccess.com/webservicesserver/", localName: "NumberToWordsSoapRequest"))
        XCTAssertEqual(wsdl.messages.flatMap({ $0.parts }).count, 4)

        XCTAssertEqual(wsdl.portTypes.count, 1)
        XCTAssertEqual(wsdl.portTypes.first?.name, QualifiedName(uri: "http://www.dataaccess.com/webservicesserver/", localName: "NumberConversionSoapType"))
        XCTAssertEqual(wsdl.portTypes.flatMap({ $0.operations }).count, 2)

        XCTAssertEqual(wsdl.schema.count, 4)
        XCTAssertEqual(wsdl.schema.first?.element?.name, QualifiedName(uri: "http://www.dataaccess.com/webservicesserver/", localName: "NumberToWords"))

        XCTAssertEqual(wsdl.services.count, 1)
        XCTAssertEqual(wsdl.services.first?.name, QualifiedName(uri: "http://www.dataaccess.com/webservicesserver/", localName: "NumberConversion"))
        XCTAssertEqual(wsdl.services.flatMap({ $0.ports }).count, 2)
    }

    func testImport() throws {
        // this test is failing as import.wsdl doesn't resolve relative file paths
        do {
            let wsdl = try deserialize("import.wsdl")
        }
    }

    func testFileNotFound() throws {
        do {
            _ = try deserialize("file_not_found.wsdl")
        } catch let error as NSError where error.code == 260 {
        }
    }

    func testBrokenImport() throws {
        do {
            _ = try deserialize("broken_import.wsdl")
            XCTFail("Parsing WSDL with broken import should fail")
        } catch let error as NSError where error.code == 260 {
        } catch let error as NSError where error.code == -1014 {
            XCTFail("Should have thrown error code 260 (file not found), not -1014 (zero byte resource). Possible cause is that a relative path was not resolved correctly.")
        }
    }
}
