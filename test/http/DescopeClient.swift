import XCTest
@testable import DescopeKit

class TestResponses: XCTestCase {
    func testUserResponse() throws {
        let jsonString = """
        {
            "userId": "userId",
            "loginIds": ["loginId"],
            "name": "name",
            "picture": "picture",
            "email": "email",
            "verifiedEmail": true,
            "phone": "phone",
            "createdTime": 123,
            "middleName": "middleName",
            "familyName": "familyName",
            "customAttributes": {
                "a": "yes",
                "b": true,
                "c": 1,
                "d": null,
                "unnecessaryArray": [
                    "yes",
                    true,
                    null,
                    1,
                    {
                        "a": "yes",
                        "b": true,
                        "c": 1,
                        "d": null
                    }
                ]
            }
        }
        """
        guard let data = jsonString.data(using: .utf8) else { return XCTFail("Couldn't get data from json string")}
        guard let userResponse = try? JSONDecoder().decode(DescopeClient.UserResponse.self, from: data) else { return XCTFail("Couldn't decode") }
        XCTAssertEqual("userId", userResponse.userId)
        XCTAssertFalse(userResponse.verifiedPhone)
        XCTAssertNil(userResponse.givenName)
        
        // customAttributes
        try checkDictionary(userResponse.customAttributes)
        
        // customAttributes.unnecessaryArray
        guard let array = userResponse.customAttributes["unnecessaryArray"] as? Array<Any> else { return XCTFail("Couldn't get custom attirubte value as array") }
        XCTAssertEqual(4, array.count) // null value omitted
        try checkArray(array)
        
        // customAttributes.unnecessaryArray[3]
        guard let dict = array[3] as? [String: Any] else { return XCTFail("Couldn't get custom attirubte value as array") }
        try checkDictionary(dict)
        
        // convert to DescopeUser and check again
        let user = userResponse.convert()
        XCTAssertEqual("userId", user.userId)
        XCTAssertFalse(user.isVerifiedPhone)
        XCTAssertNil(user.givenName)
        
        // customAttributes
        try checkDictionary(user.customAttributes)
        
        // customAttributes.unnecessaryArray
        guard let array = user.customAttributes["unnecessaryArray"] as? Array<Any> else { return XCTFail("Couldn't get custom attirubte value as array") }
        XCTAssertEqual(4, array.count) // null value omitted
        try checkArray(array)
        
        // customAttributes.unnecessaryArray[3]
        guard let dict = array[3] as? [String: Any] else { return XCTFail("Couldn't get custom attirubte value as array") }
        try checkDictionary(dict)
    }
    
    func checkDictionary(_ dict: [String:Any]) throws {
        guard let aValue = dict["a"] as? String else { return XCTFail("Couldn't get custom attirubte value as String") }
        XCTAssertEqual("yes", aValue)
        guard let bValue = dict["b"] as? Bool else { return XCTFail("Couldn't get custom attirubte value as Bool") }
        XCTAssertTrue(bValue)
        guard let cValue = dict["c"] as? Int else { return XCTFail("Couldn't get custom attirubte value as Int") }
        XCTAssertEqual(1, cValue)
        XCTAssertNil(dict["d"])
    }
    
    func checkArray(_ array: [Any]) throws {
        guard let aValue = array[0] as? String else { return XCTFail("Couldn't get custom attirubte value as string") }
        XCTAssertEqual("yes", aValue)
        guard let bValue = array[1] as? Bool else { return XCTFail("Couldn't get custom attirubte value as bool") }
        XCTAssertTrue(bValue)
        guard let cValue = array[2] as? Int else { return XCTFail("Couldn't get custom attirubte value as int") }
        XCTAssertEqual(1, cValue)
    }
}
