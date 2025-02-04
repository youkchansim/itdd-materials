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

import Foundation

class DogPatchClient {
  let baseURL: URL
  let session: URLSessionProtocol
  var responseQueue: DispatchQueue? = nil
  
  init(baseURL: URL,
       session: URLSessionProtocol,
       responseQueue: DispatchQueue?) {
    self.baseURL = baseURL
    self.session = session
    self.responseQueue = responseQueue
  }
  
  init(baseURL: URL, session: URLSessionProtocol) {
    self.baseURL = baseURL
    self.session = session
  }
  
  // Test를 pass하기 위해
  // 1. getDogs(completion:)의 guard statement를 교체
  //      -> let data 를 guard pass 조건으로 추가
  // 2. guard closing에 json으로 디코드 하는 구문을 추가
  //      -> try! 구문이 위험해보이는가? 맞음!
  //      -> 그리고 이게 너가 또 다른 테스트를 해야하는 지표이다.
  func getDogs(completion: @escaping
    ([Dog]?, Error?) -> Void) -> URLSessionTaskProtocol {
    let url = URL(string: "dogs", relativeTo: baseURL)!
    // strong reference cycle을 피하기 위해 [weak self] 추가
    let task = session.makeDataTask(with: url) { [weak self] data, response, error in
      guard let self = self else { return }
      
      // Error가 response.statusCode랑 같은 부분에서 체크하고 있음을 확인할 수 있다.
      // 그리고 이미 Error를 보내고 있는 상태이다.
      // 그럼 이 테스트는 유용하지 않은가? -> No! 유용해!
      // 그러므로 여기는 그대로 두고, 리팩토링으로 넘어가자.
      guard let response = response as? HTTPURLResponse,
            response.statusCode == 200,
            error == nil,
            let data = data else {
        self.dispatchResult(error: error, completion: completion)
        return
      }
      let decoder = JSONDecoder()
      
      do {
        let dogs = try decoder.decode([Dog].self, from: data)
        self.dispatchResult(models: dogs, completion: completion)
        
      } catch {
        self.dispatchResult(error: error, completion: completion)
      }
    }
    task.resume()
    return task
  }
  
  // 중복 함수를 제거해주기 위해 추가한 함수
  // genericType 이기 때문에 어떤 model이든 사용 가능,
  // input 에 상관없이 항상 responseQueue와 dispatches the completion이 있는지 확인한다.
  // 만약 responseQueue가 없으면, input을 completion에 넘겨줄 것이다.
  private func dispatchResult<Type>(
    models: Type? = nil,
    error: Error? = nil,
    completion: @escaping (Type?, Error?) -> Void) {
    guard let responseQueue = responseQueue else {
      completion(models, error)
      return
    }
    responseQueue.async {
      completion(models, error)
    }
  }
}
