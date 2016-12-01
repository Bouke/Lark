public protocol XMLDeserializable {
    init(deserialize: XMLElement)
}

public protocol XMLSerializable {
    func serialize(_ element: XMLElement)
}
