import Evergreen
import Foundation
import LarkRuntime

getLogger("Lark").logLevel = .warning


// HelloWorld
let hwsClient = HelloWorldServiceClient()

let r0 = try hwsClient.sayHello(SayHello(name: "World", times: 2))
print(r0.sayHelloResult.string)

let r1 = try hwsClient.sayHello(SayHello(name: nil, times: 1))
print(r1.sayHelloResult.string)

let r2 = try hwsClient.sayNothing(SayNothing())
print(r2)

let r3 = try hwsClient.sayMaybeSomething(SayMaybeSomething(name: "Bouke"))
print(r3.sayMaybeSomethingResult ?? "__nil__")

let r4 = try hwsClient.sayMaybeNothing(SayMaybeNothing(name: "Bouke"))
print(r4.sayMaybeNothingResult ?? "__nil__")

let r5 = try hwsClient.greet(Greet(partOfDay: .evening))
print(r5)

let r6 = try hwsClient.greets(Greets(partOfDays: PartOfDayArrayType(partOfDay: [.morning, .night])))
print(r6.greetsResult.string)


// Shakespeare
let shakespeareClient = ShakespeareClient()
let r7 = try shakespeareClient.getSpeech(GetSpeech(request: "to be, or not to be"))
print(r7.getSpeechResult ?? "__nil__")
