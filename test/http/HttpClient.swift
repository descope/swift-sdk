
import XCTest
@testable import DescopeKit

class TestHttpMethods: XCTestCase {
    let client = HttpClient(baseURL: "http://example", session: MockHTTP.session)
    
    func testGet() async throws {
        MockHTTP.push(json: MockResponse.json) { request in
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
        MockHTTP.push(json: MockResponse.json) { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "http://example/route")
            guard let data = request.httpBody, let body = String(bytes: data, encoding: .utf8) else { return XCTFail("Invalid body") }
            XCTAssertEqual(body, #"{"foo":4}"#)
            XCTAssertEqual(request.allHTTPHeaderFields?["Content-Length"], String(body.count))
            XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "application/json")
        }
        let resp: MockResponse = try await client.post("route", body: ["foo": 4])
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

        MockHTTP.push(json: MockResponse.json) { request in
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
        } catch DescopeError.clientError {
            // ok
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        do {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
            MockHTTP.push(error: error)
            try await client.get("route")
            XCTFail("No error thrown")
        } catch DescopeError.networkError {
            // ok
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

struct MockResponse: Decodable, Equatable {
    var id: Int
    var st: String
    
    static let instance = MockResponse(id: 7, st: "foo")
    static let json: [String: Any] = ["id": instance.id, "st": instance.st]
}
