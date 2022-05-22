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

// 1
// Updating the mocks
class MockURLSession: URLSessionProtocol {
  
  // 1. 새로운 프로퍼티 추가
  var queue: DispatchQueue? = nil
  
  // 2. 새로운 함수 추가
  //    ㄴ 기존 테스트들은 이 큐가 필요가 없다. 따라서 새로운 테스트들에서만 사용할 것이다.
  func givenDispatchQueue() {
    queue = DispatchQueue(label: "com.DogPatchTests.MockSession")
  }
  
  func makeDataTask(
    with url: URL,
    completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTaskProtocol {
      return MockURLSessionTask(
        completionHandler: completionHandler,
        url: url,
        queue: queue)
  }
}

// 2
class MockURLSessionTask: URLSessionTaskProtocol {
  var completionHandler: (Data?, URLResponse?, Error?) -> Void
  var url: URL
  var calledResume = false
  
  // 3. MockURLSessionTask update
  // queue가 들어오면 completionHandler에 'queue에 dispatch asynchronously'를 담아 넣어준다. completionHandler가 불리기 전에.
  // 이 방식은 dispatch queue에 대한 `진짜 URLDataTask Dispatches` 방식과 매우 흡사하다.
  init(completionHandler:
       @escaping (Data?, URLResponse?, Error?) -> Void,
       url: URL,
       queue: DispatchQueue?) {
    if let queue = queue {
      self.completionHandler = { data, response, error in
        queue.async() {
          completionHandler(data, response, error)
        }
      }
    } else {
      self.completionHandler = completionHandler
    }
    self.url = url
  }
  
  // 3
  func resume() {    
    calledResume = true
  }
}
