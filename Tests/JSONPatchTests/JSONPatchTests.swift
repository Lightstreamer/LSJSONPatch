//
//  JSONPatchTests.swift
//  JSONPatchTests
//
//  Created by Raymond Mccrae on 11/11/2018.
//  Copyright © 2018 Raymond McCrae. All rights reserved.
//

import XCTest
@testable import JSONPatch

class JSONPatchTests: XCTestCase {

    func runJSONTest(_ dictionary: NSDictionary) {
        guard let doc = dictionary["doc"] else {
            XCTFail("doc not found")
            return
        }

        guard let patch = dictionary["patch"] as? NSArray else {
            XCTFail("patch not found")
            return
        }

        let comment = dictionary["comment"] ?? ""

        do {
            let jsonPatch = JSONPatch(jsonArray: patch)
            let result = try jsonPatch.apply(to: doc)

            if let expected = dictionary["expected"] {
                guard (result as? NSObject)?.isEqual(expected) ?? false else {
                    XCTFail("result does not match expected: \(comment)")
                    return
                }
            }
        } catch {
            guard let _ = dictionary["error"] as? String else {
                XCTFail("Unexpected error: \(comment)")
                return
            }
        }
    }

    func runJSONTestFile(_ name: String) {
        guard
            let bundle = Bundle(identifier: "scot.raymccrae.JSONPatchTests"),
            let url = bundle.url(forResource: name, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let json = try? JSONSerialization.jsonObject(with: data, options: []),
            let array = json as? NSArray else {
            XCTFail("Unable to read file \(name)")
            return
        }

        for test in array {
            guard let testDict = test as? NSDictionary else {
                continue
            }
            runJSONTest(testDict)
        }
    }

    func evaluate(path: String, on json: JSONElement) -> JSONElement? {
        guard let ptr = try? JSONPointer(string: path) else {
            return nil
        }
        return try? json.evaluate(pointer: ptr)
    }

    // This test is based on the sample given in section 5 of RFC 6901
    // https://tools.ietf.org/html/rfc6901
    func testExample() throws {
        let sample = """
        {
        "foo": ["bar", "baz"],
        "": 0,
        "a/b": 1,
        "c%d": 2,
        "e^f": 3,
        "g|h": 4,
        "i\\\\j": 5,
        "k\\"l": 6,
        " ": 7,
        "m~n": 8
        }
        """

        let jsonObject = try JSONSerialization.jsonObject(with: Data(sample.utf8), options: [])
        let json = try JSONElement(any: jsonObject)

        XCTAssertEqual(evaluate(path: "", on: json), json)
        XCTAssertEqual(evaluate(path: "/foo", on: json), .array(value: ["bar", "baz"]))
        XCTAssertEqual(evaluate(path: "/foo/0", on: json), .string(value: "bar"))
        XCTAssertEqual(evaluate(path: "/", on: json), .number(value: NSNumber(value: 0)))
        XCTAssertEqual(evaluate(path: "/a~1b", on: json), .number(value: NSNumber(value: 1)))
        XCTAssertEqual(evaluate(path: "/c%d", on: json), .number(value: NSNumber(value: 2)))
        XCTAssertEqual(evaluate(path: "/e^f", on: json), .number(value: NSNumber(value: 3)))
        XCTAssertEqual(evaluate(path: "/g|h", on: json), .number(value: NSNumber(value: 4)))
        XCTAssertEqual(evaluate(path: "/i\\j", on: json), .number(value: NSNumber(value: 5)))
        XCTAssertEqual(evaluate(path: "/k\"l", on: json), .number(value: NSNumber(value: 6)))
        XCTAssertEqual(evaluate(path: "/ ", on: json), .number(value: NSNumber(value: 7)))
        XCTAssertEqual(evaluate(path: "/m~0n", on: json), .number(value: NSNumber(value: 8)))

        XCTAssertEqual(evaluate(path: "#", on: json), json)
        XCTAssertEqual(evaluate(path: "#/foo", on: json), .array(value: ["bar", "baz"]))
        XCTAssertEqual(evaluate(path: "#/foo/0", on: json), .string(value: "bar"))
        XCTAssertEqual(evaluate(path: "#/", on: json), .number(value: NSNumber(value: 0)))
        XCTAssertEqual(evaluate(path: "#/a~1b", on: json), .number(value: NSNumber(value: 1)))
        XCTAssertEqual(evaluate(path: "#/c%25d", on: json), .number(value: NSNumber(value: 2)))
        XCTAssertEqual(evaluate(path: "#/e%5Ef", on: json), .number(value: NSNumber(value: 3)))
        XCTAssertEqual(evaluate(path: "#/g%7Ch", on: json), .number(value: NSNumber(value: 4)))
        XCTAssertEqual(evaluate(path: "#/i%5Cj", on: json), .number(value: NSNumber(value: 5)))
        XCTAssertEqual(evaluate(path: "#/k%22l", on: json), .number(value: NSNumber(value: 6)))
        XCTAssertEqual(evaluate(path: "#/%20", on: json), .number(value: NSNumber(value: 7)))
        XCTAssertEqual(evaluate(path: "#/m~0n", on: json), .number(value: NSNumber(value: 8)))
    }

    func testJSON() {
        runJSONTestFile("tests")
    }

    func testJSONPatchSpec() {
        runJSONTestFile("spec_tests")
    }

    func testJSONPatchExtra() {
        runJSONTestFile("extra")
    }

    func testAdd() throws {
        let sample = """
        {"foo": "bar"}
        """

        let jsonObject = try JSONSerialization.jsonObject(with: Data(sample.utf8), options: [])
        var json = try JSONElement(any: jsonObject)

//        let from = try JSONPointer(string: "/foo")
        let ptr = try JSONPointer(string: "")
        try json.replace(value: .object(value: ["baz": "qux"]), to: ptr)
        print(json)
    }

}
