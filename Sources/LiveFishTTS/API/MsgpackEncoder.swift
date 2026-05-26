import Foundation

enum MsgpackValue {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case map([String: MsgpackValue])
}

enum MsgpackEncoder {
    static func encode(_ value: MsgpackValue) -> Data {
        var data = Data()
        append(value, to: &data)
        return data
    }

    private static func append(_ value: MsgpackValue, to data: inout Data) {
        switch value {
        case .string(let string):
            appendString(string, to: &data)
        case .int(let int):
            appendInt(int, to: &data)
        case .double(let double):
            data.append(0xcb)
            data.append(contentsOf: double.bitPattern.bigEndianBytes)
        case .bool(let bool):
            data.append(bool ? 0xc3 : 0xc2)
        case .map(let map):
            appendMapHeader(count: map.count, to: &data)
            for key in map.keys.sorted() {
                appendString(key, to: &data)
                if let value = map[key] {
                    append(value, to: &data)
                }
            }
        }
    }

    private static func appendString(_ string: String, to data: inout Data) {
        let bytes = Array(string.utf8)
        let count = bytes.count
        if count <= 31 {
            data.append(UInt8(0xa0 | count))
        } else if count <= UInt8.max {
            data.append(0xd9)
            data.append(UInt8(count))
        } else if count <= UInt16.max {
            data.append(0xda)
            data.append(contentsOf: UInt16(count).bigEndianBytes)
        } else {
            data.append(0xdb)
            data.append(contentsOf: UInt32(count).bigEndianBytes)
        }
        data.append(contentsOf: bytes)
    }

    private static func appendInt(_ int: Int, to data: inout Data) {
        if int >= 0 && int <= 127 {
            data.append(UInt8(int))
        } else if int >= 0 && int <= UInt8.max {
            data.append(0xcc)
            data.append(UInt8(int))
        } else if int >= 0 && int <= UInt16.max {
            data.append(0xcd)
            data.append(contentsOf: UInt16(int).bigEndianBytes)
        } else {
            data.append(0xd3)
            data.append(contentsOf: Int64(int).bigEndianBytes)
        }
    }

    private static func appendMapHeader(count: Int, to data: inout Data) {
        if count <= 15 {
            data.append(UInt8(0x80 | count))
        } else if count <= UInt16.max {
            data.append(0xde)
            data.append(contentsOf: UInt16(count).bigEndianBytes)
        } else {
            data.append(0xdf)
            data.append(contentsOf: UInt32(count).bigEndianBytes)
        }
    }
}

private extension FixedWidthInteger {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: self.bigEndian) { Array($0) }
    }
}
