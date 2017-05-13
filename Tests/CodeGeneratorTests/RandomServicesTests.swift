import XCTest

@testable import CodeGenerator
@testable import Lark
@testable import SchemaParser

class RandomServicesTests: XCTestCase {
    func test() {
        guard ProcessInfo.processInfo.environment["INTEGRATION"] != nil else {
            return NSLog("Skipped integration test at \(#file):\(#line)")
        }
        _test(url: URL(string: "https://www.paradox.com/Services.asmx?WSDL")!)
        _test(url: URL(string: "http://skyserver.sdss.org/casjobs/services/users.asmx?WSDL")!)
        _test(url: URL(string: "https://www.landmarkworldwide.com/Components/WebService/Service.asmx?WSDL")!)
        _test(url: URL(string: "http://www.vasttrafik.se/External_Services/TravelPlanner.asmx?WSDL")!)
        _test(url: URL(string: "http://europe.figlo.com/services/hawanedoservice.asmx?WSDL")!)
        _test(url: URL(string: "https://onlinetoets.nhg.nl/nhgtoets/NhgToets.asmx?WSDL")!)
        _test(url: URL(string: "https://api.billing.inter8.co/V1_3_1.svc?wsdl")!)
    }
    func _test(url: URL, file: StaticString = #file, line: UInt = #line) {
        do {
            let webService = try parseWebServiceDescription(contentsOf: url)
            _ = try generate(webService: webService, service: webService.services.first!).components(separatedBy: "\n")
        } catch {
            XCTFail("\(error)", file: file, line: line)
        }
    }
}
