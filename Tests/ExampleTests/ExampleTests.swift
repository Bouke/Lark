import XCTest
import Foundation
import Lark

class _Client: Client {
    func _method(a: Int, b: Int) -> Request<Int> {
        return call(
            action: URL(string: "")!,
            serialize: { (envelope: Envelope) in
                return envelope
            },
            deserialize: { (envelope: Envelope) in
                return a + b
            })
    }
}

class ExampleTests: XCTestCase {
    func test() {
        let client = _Client(endpoint: URL(string: "")!)
        client._method(a: 1, b: 2).response { (response: Response<Int>) in
            let result: Result<Int> = response.result
            print(result.value!)
        }
    }
}
