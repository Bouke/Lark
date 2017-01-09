import Foundation
import XCTest

@testable import CodeGenerator
@testable import SchemaParser

class WSDLVerifyTests: XCTestCase {
    func deserialize(_ input: String) throws -> WSDL {
        let url = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Inputs").appendingPathComponent(input)
        return try parseWSDL(contentsOf: url)
    }

    func testMissingBinding() throws {
        let wsdl = try deserialize("missing_binding.wsdl")
        do {
            try wsdl.verify()
        } catch GeneratorError.missingNodes(let nodes) where nodes == [.binding(QualifiedName(uri: "http://tempuri.org/import", localName: "SoapBinding"))] {
            // expected error
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
}
