/// Copyright (c) 2022 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

@testable import DogPatch
import Foundation
import XCTest

class DogPatchClientTests: XCTestCase {
  var sut: DogPatchClient!
  var baseURL: URL!
  var mockSession: MockURLSession!
  var getDogsURL: URL {
    return URL(string: "dogs", relativeTo: baseURL)!
  }
  
  override func setUp() {
    super.setUp()
    baseURL = URL(string: "https://example.com/api/v1/")!
    mockSession = MockURLSession()
    sut = DogPatchClient(baseURL: baseURL, session: mockSession)
  }
  
  override func tearDown() {
    baseURL = nil
    mockSession = nil
    sut = nil
    super.tearDown()
  }
  
  func whenGetDogs(
    data: Data? = nil,
    statusCode: Int = 200,
    error: Error? = nil) ->
    (calledCompletion: Bool, dogs: [Dog]?, error: Error?) {
      let response = HTTPURLResponse(url: getDogsURL,
                                     statusCode: statusCode,
                                     httpVersion: nil,
                                     headerFields: nil)
      var calledCompletion = false
      var receivedDogs: [Dog]? = nil
      var receivedError: Error? = nil
      let mockTask = sut.getDogs() { dogs, error in
        calledCompletion = true
        receivedDogs = dogs
        receivedError = error as NSError?
        } as! MockURLSessionTask
      mockTask.completionHandler(data, response, error)
      return (calledCompletion, receivedDogs, receivedError)
  }
  
  func test_init_sets_baseURL() {
    XCTAssertEqual(sut.baseURL, baseURL)
  }
  
  func test_init_sets_session() {
    XCTAssertTrue(sut.session === mockSession)
  }
  
  func test_getDogs_callsExpectedURL() {
    // when
    let mockTask = sut.getDogs() { _, _ in }
      as! MockURLSessionTask
    // then
    XCTAssertEqual(mockTask.url, getDogsURL)
  }
  
  func test_getDogs_callsResumeOnTask() {
    // when
    let mockTask = sut.getDogs() { _, _ in }
      as! MockURLSessionTask
    // then
    XCTAssertTrue(mockTask.calledResume)
  }
  
  func test_getDogs_givenResponseStatusCode500_callsCompletion() {
    // when
    let result = whenGetDogs(statusCode: 500)
    
    // then
    XCTAssertTrue(result.calledCompletion)
    XCTAssertNil(result.dogs)
    XCTAssertNil(result.error)
  }
  
  func test_getDogs_givenError_callsCompletionWithError() throws {
    // given
    let expectedError = NSError(domain: "com.DogPatchTests",
                                code: 42)
    // when
    let result = whenGetDogs(error: expectedError)
  
    // then
    XCTAssertTrue(result.calledCompletion)
    XCTAssertNil(result.dogs)
    let actualError = try XCTUnwrap(result.error as NSError?)
    XCTAssertEqual(actualError, expectedError)
  }
  
  func test_getDogs_givenValidJSON_callsCompletionWithDogs()
    throws {
      // given
      // First, JSON filename으로 Data.fromJSON 호출하여 데이터를 만든다.
      let data = try Data.fromJSON(fileName: "GET_Dogs_Response")
      
      // 새로운 JSONDecoder를 만들고, data를 decode한다.
      // Dog는 이미 Decodable을 채택하고 있고, DogTest.swift 에서 테스트를 통과했기 때문에 문제가 없다.
      let decoder = JSONDecoder()
      let dogs = try decoder.decode([Dog].self, from: data)
      
      // when
      // 그리고 다른 테스트들처럼 whenGetDogs를 호출한다.
      // 하지만 이번에는 데이터를 집어넣는다.
      let result = whenGetDogs(data: data)
      
      // then
      // 마지막으로
      // `calledCompletion이 불렸음`
      // `dogs는 result.dogs와 같음`
      // `error가 nill임`
      // 을 확인한다.
      XCTAssertTrue(result.calledCompletion)
      XCTAssertEqual(result.dogs, dogs)
      XCTAssertNil(result.error)
  }
  
  func test_getDogs_givenInvalidJSON_callsCompletionWithError()
    throws {
    // given
      // GET_Dogs_MissingValuesResponse 를 통해 데이터를 셋업
      // JSON array에는 맞으나, deserialize에 필요한 id가 없는 상태.
    let data = try Data.fromJSON(
      fileName: "GET_Dogs_MissingValuesResponse")
    
      // deserialize 시도! -> 에러 발생
    var expectedError: NSError!
    let decoder = JSONDecoder()
    do {
      _ = try decoder.decode([Dog].self, from: data)
    } catch {
      expectedError = error as NSError
    }
    
    // when
      // whenGetDogs 를 부르고
    let result = whenGetDogs(data: data)
    
    // then
      // `calledCompletion`
      // `result.dogs 이 비었는지`
      // `expectedError` 가 같은 도메인인지,
      // `expectedError` 가 같은 코드인지
      // 테스트한다.
    XCTAssertTrue(result.calledCompletion)
    XCTAssertNil(result.dogs)
    let actualError = try XCTUnwrap(result.error as NSError?)
      // NSError로 변환해야하는데, Error는 directly comparable하지 않기 때문이다.
      // NSError로 변환함으로써, domain과 code를 다른 Error와 같은 에러인지 `아주 충분히` 비교 가능해진다.
    XCTAssertEqual(actualError.domain, expectedError.domain)
    XCTAssertEqual(actualError.code, expectedError.code)
  }
}
