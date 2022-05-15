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
}
