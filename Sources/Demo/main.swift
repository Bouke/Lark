import Evergreen
import Foundation
import LarkRuntime

getLogger("Lark").logLevel = .warning

func call<T>(_ block: @autoclosure () throws -> T, success: (T) -> ()) {
    do {
        success(try block())
    } catch let fault as LarkRuntime.Fault {
        print("Server generated a Fault: \(fault)")
    } catch {
        print("Other error was thrown: \(error)")
    }
}


// HelloWorld
let hwsClient = HelloWorldServiceClient()

call(try hwsClient.sayHello(SayHello(name: "World", times: 2))) {
    print($0.sayHelloResult.string)
}

call(try hwsClient.sayHello(SayHello(name: nil, times: 1))) {
    print($0.sayHelloResult.string)
}

call(try hwsClient.sayNothing(SayNothing())) {
    print($0)
}

call(try hwsClient.sayMaybeSomething(SayMaybeSomething(name: "Bouke"))) {
    print($0.sayMaybeSomethingResult ?? "__nil__")
}

call(try hwsClient.sayMaybeNothing(SayMaybeNothing(name: "Bouke"))) {
    print($0.sayMaybeNothingResult ?? "__nil__")
}

call(try hwsClient.greet(Greet(partOfDay: .evening))) {
    print($0)
}

call(try hwsClient.greets(Greets(partOfDays: PartOfDayArrayType(partOfDay: [.morning, .night])))) {
    print($0.greetsResult.string)
}

call(try hwsClient.fault(Demo.Fault())) {
    print($0)
}

// Shakespeare
let shakespeareClient = ShakespeareClient()

call(try shakespeareClient.getSpeech(GetSpeech(request: "to be, or not to be"))) {
    print($0.getSpeechResult ?? "__nil__")
}
