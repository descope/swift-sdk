
import XCTest
@testable import DescopeKit

class TestHttpMethods: XCTestCase {
    let client = HTTPClient(baseURL: "http://example", networking: MockHTTP.networking)
    
    func testGet() async throws {
        MockHTTP.push(json: MockResponse.json, headers: MockResponse.headers) { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.absoluteString, "http://example/route?param=spaced%20value")
            XCTAssertEqual(request.allHTTPHeaderFields?["User-Agent"], makeUserAgent())
            XCTAssertNil(request.httpBody)
            XCTAssertNil(request.httpBodyStream)
        }
        let resp: MockResponse = try await client.get("route", params: ["param": "spaced value"])
        XCTAssertEqual(resp, MockResponse.instance)
    }
    
    func testPost() async throws {
        MockHTTP.push(json: MockResponse.json, headers: MockResponse.headers) { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "http://example/route")
            XCTAssertEqual(request.allHTTPHeaderFields?["Content-Length"], String(mockBodyString.count))
            XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "application/json")
            guard let data = request.httpBody, let body = String(bytes: data, encoding: .utf8) else { return XCTFail("Invalid body") }
            XCTAssertEqual(body, mockBodyString)
        }
        let resp: MockResponse = try await client.post("route", body: mockBodyJSON)
        XCTAssertEqual(resp, MockResponse.instance)
    }
    
    func testCompacting() async throws {
        let params: [String: String?] = [
            "a": "b",
            "c": nil,
        ]
        
        let body: [String: Any?] = [
            "a": "b",
            "c": nil,
            "d": ["e", "f"],
            "g": ["h": nil, "i": [:]],
        ]

        MockHTTP.push(json: MockResponse.json, headers: MockResponse.headers) { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "http://example/route?a=b")
            guard let data = request.httpBody, let json = try? JSONSerialization.jsonObject(with: data) else { return XCTFail("Invalid body") }
            guard let sorted = try? JSONSerialization.data(withJSONObject: json, options: .sortedKeys), let sortedBody = String(bytes: sorted, encoding: .utf8) else { return XCTFail("Conversion failed") }
            XCTAssertEqual(sortedBody, #"{"a":"b","d":["e","f"],"g":{"i":{}}}"#)
        }
        
        let resp: MockResponse = try await client.post("route", params: params, body: body)
        XCTAssertEqual(resp, MockResponse.instance)
    }

    func testUserAgent() throws {
        let userAgent = makeUserAgent()
        XCTAssertTrue(userAgent.hasPrefix("DescopeKit"))
        XCTAssertTrue(userAgent.contains("xctest"))
    }
    
    func testFailure() async throws {
        do {
            MockHTTP.push(statusCode: 400, json: [:])
            try await client.get("route")
            XCTFail("No error thrown")
        } catch DescopeError.httpError {
            // ok
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        do {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
            MockHTTP.push(error: error)
            try await client.get("route")
            XCTFail("No error thrown")
        } catch let err as DescopeError where err == .networkError {
            // ok
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private let mockBodyJSON: [String: Any?] = ["foo": 4]
private let mockBodyString = #"{"foo":4}"#

private struct MockResponse: JSONResponse, Equatable {
    var id: Int
    var st: String
    var hd: String?

    static let instance = MockResponse(id: 7, st: "foo", hd: "bar")
    static let json: [String: Any] = ["id": instance.id, "st": instance.st]
    static let headers: [String: String] = ["hd": instance.hd!]
    
    mutating func setValues(from response: HTTPURLResponse) {
        guard let headers = response.allHeaderFields as? [String: String] else { return }
        for (name, value) in headers where name == "hd" {
            hd = value
        }
    }
}
