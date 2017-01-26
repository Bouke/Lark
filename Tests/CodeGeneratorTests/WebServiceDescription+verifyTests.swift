import Foundation
import XCTest

@testable import CodeGenerator
@testable import Lark
@testable import SchemaParser

class WebServiceDescriptionVerifyTests: XCTestCase {
    func deserialize(_ input: String) throws -> WebServiceDescription {
        let url = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Inputs").appendingPathComponent(input)
        return try parseWebServiceDefinition(contentsOf: url)
    }

    func testComplete() throws {
        let webService = try deserialize("numberconversion.wsdl")
        do {
            try webService.verify()
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    func testMissingBinding() throws {
        let webService = try deserialize("missing_binding.wsdl")
        do {
            try webService.verify()
            XCTFail("Should not verified")
        } catch WebServiceDescriptionVerifyError.missingNodes(let nodes) {
            XCTAssertEqual(nodes, [.binding(QualifiedName(uri: "http://tempuri.org/", localName: "ImportSoapBinding"))])
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    func testMissingPort() throws {
        let webService = try deserialize("missing_port.wsdl")
        do {
            try webService.verify()
            XCTFail("Should not verified")
        } catch WebServiceDescriptionVerifyError.missingNodes(let nodes) {
            XCTAssertEqual(nodes, [.port(QualifiedName(uri: "http://tempuri.org/", localName: "ImportSoapType"))])
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    func testMissingMessageType() throws {
        let webService = try deserialize("missing_message_type.wsdl")
        do {
            try webService.verify()
            XCTFail("Should not verified")
        } catch WebServiceDescriptionVerifyError.missingNodes(let nodes) {
            XCTAssertEqual(nodes, [.port(QualifiedName(uri: "http://tempuri.org/", localName: "ImportSoapType"))])
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
}
