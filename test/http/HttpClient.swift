
import XCTest
@testable import DescopeKit

class TestHttpMethods: XCTestCase {
    let client = HttpClient(baseURL: "http://example", session: MockHTTP.session)
    
    func testGet() async throws {
        MockHTTP.push(json: MockResponse.json) { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.allHTTPHeaderFields?["User-Agent"], makeUserAgent())
        }
        let resp: MockResponse = try await client.get("route")
        XCTAssertEqual(resp, MockResponse.instance)
    }
    
    func testPost() async throws {
        MockHTTP.push(json: MockResponse.json) { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.allHTTPHeaderFields?["Content-Length"], "9")
            XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "application/json")
        }
        let resp: MockResponse = try await client.post("route", body: ["foo": 4, "bar": nil])
        XCTAssertEqual(resp, MockResponse.instance)
    }

    func testFailure() async throws {
        do {
            MockHTTP.push(statusCode: 400, json: [:])
            try await client.get("route")
            XCTFail("No error thrown")
        } catch {
            guard case DescopeError.clientError = error else { return XCTFail("Unexpected error: \(error)") }
        }
        
        do {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
            MockHTTP.push(error: error)
            try await client.get("route")
            XCTFail("No error thrown")
        } catch {
            guard case DescopeError.networkError = error else { return XCTFail("Unexpected error: \(error)") }
        }
    }
}

class TestHttpUtils: XCTestCase {
    func testUserAgent() throws {
        let userAgent = makeUserAgent()
        XCTAssertTrue(userAgent.hasPrefix("DescopeKit"))
        XCTAssertTrue(userAgent.contains("xctest"))
    }
    
    func testCompacted() throws {
        let dict: [String: Any?] = [
            "a": "b",
            "c": nil,
            "d": ["e", "f"],
            "g": ["h": nil, "i": [:]],
        ]
        XCTAssertNotNil(dict["c"] as Any?)

        let jsonDict = dict.compacted()
        XCTAssertNil(jsonDict["c"])
        
        let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .sortedKeys)
        guard let jsonString = String(bytes: jsonData, encoding: .utf8) else { return XCTFail() }
        XCTAssertEqual(jsonString, #"{"a":"b","d":["e","f"],"g":{"i":{}}}"#)
    }
}
