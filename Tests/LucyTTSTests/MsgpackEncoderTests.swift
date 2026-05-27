import XCTest
@testable import LiveFishTTS

final class MsgpackEncoderTests: XCTestCase {
    func testEncodesPositiveFixintAsSingleByte() {
        XCTAssertEqual(MsgpackEncoder.encode(.int(0)), Data([0x00]))
        XCTAssertEqual(MsgpackEncoder.encode(.int(1)), Data([0x01]))
        XCTAssertEqual(MsgpackEncoder.encode(.int(127)), Data([0x7f]))
    }

    func testEncodesUint8RangeWithCcPrefix() {
        XCTAssertEqual(MsgpackEncoder.encode(.int(128)), Data([0xcc, 0x80]))
        XCTAssertEqual(MsgpackEncoder.encode(.int(255)), Data([0xcc, 0xff]))
    }

    func testEncodesUint16RangeWithCdPrefix() {
        XCTAssertEqual(MsgpackEncoder.encode(.int(256)), Data([0xcd, 0x01, 0x00]))
        XCTAssertEqual(MsgpackEncoder.encode(.int(0xFFFF)), Data([0xcd, 0xff, 0xff]))
    }

    func testEncodesNegativeIntAsInt64BigEndian() {
        let encoded = MsgpackEncoder.encode(.int(-1))
        XCTAssertEqual(encoded.first, 0xd3)
        XCTAssertEqual(encoded.count, 9)
        // -1 as Int64 big-endian is eight bytes of 0xff
        XCTAssertEqual(Array(encoded.dropFirst()), Array(repeating: 0xff, count: 8))
    }

    func testEncodesBools() {
        XCTAssertEqual(MsgpackEncoder.encode(.bool(true)), Data([0xc3]))
        XCTAssertEqual(MsgpackEncoder.encode(.bool(false)), Data([0xc2]))
    }

    func testEncodesShortStringAsFixstr() {
        // "hi" is two UTF-8 bytes, fits fixstr (0xa0 | length)
        XCTAssertEqual(MsgpackEncoder.encode(.string("hi")), Data([0xa2, 0x68, 0x69]))
    }

    func testEncodesLongerStringAsStr8() {
        let value = String(repeating: "a", count: 33)
        let encoded = MsgpackEncoder.encode(.string(value))
        XCTAssertEqual(encoded.first, 0xd9)
        XCTAssertEqual(encoded[1], 33)
        XCTAssertEqual(encoded.count, 2 + 33)
        XCTAssertEqual(Array(encoded.dropFirst(2)), Array(repeating: UInt8(ascii: "a"), count: 33))
    }

    func testEncodesMapWithSortedKeysForDeterminism() {
        // Insertion order is b, a, c — output must encode keys in sorted order a, b, c
        let encoded = MsgpackEncoder.encode(.map([
            "b": .int(2),
            "a": .int(1),
            "c": .int(3)
        ]))
        XCTAssertEqual(encoded, Data([
            0x83,                    // fixmap, 3 entries
            0xa1, 0x61, 0x01,        // "a": 1
            0xa1, 0x62, 0x02,        // "b": 2
            0xa1, 0x63, 0x03         // "c": 3
        ]))
    }

    func testEncodesDoubleAsFloat64BigEndian() {
        let encoded = MsgpackEncoder.encode(.double(1.0))
        XCTAssertEqual(encoded.first, 0xcb)
        XCTAssertEqual(encoded.count, 9)
        // 1.0 as IEEE-754 double big-endian
        XCTAssertEqual(Array(encoded.dropFirst()), [0x3f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    }

    func testNestedMapRoundTripsThroughEncoder() {
        let encoded = MsgpackEncoder.encode(.map([
            "prosody": .map([
                "speed": .double(1.0),
                "volume": .double(0.0)
            ])
        ]))
        // 1 entry fixmap + "prosody" string + nested 2-entry fixmap with two doubles
        XCTAssertEqual(encoded.first, 0x81)
        XCTAssertGreaterThan(encoded.count, 1)
    }
}
