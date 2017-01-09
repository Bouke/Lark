import Foundation
import XCTest

@testable import CodeGenerator
@testable import SchemaParser

class WSDLVerifyTests: XCTestCase {
    func deserialize(_ input: String) throws -> WSDL {
        let url = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Inputs").appendingPathComponent(input)
        return try parseWSDL(contentsOf: url)
    }

    func testComplete() throws {
        let wsdl = try deserialize("numberconversion.wsdl")
        do {
            try wsdl.verify()
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    func testMissingBinding() throws {
        let wsdl = try deserialize("missing_binding.wsdl")
        do {
            try wsdl.verify()
        } catch GeneratorError.missingNodes(let nodes) {
            XCTAssertEqual(nodes, [.binding(QualifiedName(uri: "http://tempuri.org/", localName: "ImportSoapBinding"))])
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    func testMissingPort() throws {
        let wsdl = try deserialize("missing_port.wsdl")
        do {
            try wsdl.verify()
        } catch GeneratorError.missingNodes(let nodes) {
            XCTAssertEqual(nodes, [.port(QualifiedName(uri: "http://tempuri.org/", localName: "ImportSoapType"))])
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
}
