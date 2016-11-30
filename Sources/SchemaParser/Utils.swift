extension Sequence {
    func dictionary<Key, Value>(key: (Iterator.Element) -> Key, value: (Iterator.Element) -> Value) -> [Key: Value] where Key: Hashable {
        var result: [Key: Value] = [:]
        for element in self {
            result[key(element)] = value(element)
        }
        return result
    }
}
