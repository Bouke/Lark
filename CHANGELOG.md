## 0.8.0 - 2018-10-21
### Changes
- Swift 4.2

## 0.7.1 - 2017-09-16
### Changes
- Renamed `validateSOAP` to match it’s usage

## 0.7.0 - 2017-09-16
### Changes
- Added few “integration” tests, however disabled by default

## 0.6.0 - 2017-04-16
### Highlights of this release:

- Make type variables mutable
- Improved test coverage (wsdl imports + binding in other namespace)
- Support WSDL imports
- Improved operation name matching (compare by `localName` only)
- Support Float/Double serializations NaN, INF etc.
- Improved message deserializing error handling
- Slightly faster qname compares
