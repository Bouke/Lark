import Evergreen
import Foundation
import LarkRuntime

let client = HelloWorldServiceClient()
//getLogger("Lark").logLevel = .warning

try client.say_hello(input: say_hello(name: nil, times: 2)) {
    print($0)
}

try client.say_nothing(input: say_nothing()) {
    print($0)
}

try client.say_maybe_something(input: say_maybe_something(name: "Bouke")) {
    print($0)
}

try client.say_maybe_nothing(input: say_maybe_nothing(name: "Bouke")) {
    print($0)
}
