import XCTest
import Foundation
import Lark

class _Client: Client {
    func _method() {
        try! self.send(action: URL(string: "")!, parameters: [], completionHandler: { (result: Result<XMLElement>) in
        })
    }
}

class ExampleTests: XCTestCase {

}
