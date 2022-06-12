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

// 1
@testable import DogPatch
import XCTest

class ImageClientTests: XCTestCase {
    
  // 2
  var mockSession: MockURLSession!
  var sut: ImageClient!
  var service: ImageService {
    return sut as ImageService
  }
  var url: URL!
  var receivedTask: MockURLSessionTask?
  var receivedError: Error?
  var receivedImage: UIImage?
  
  // MARK: - Test Lifecycle
  // 3
  override func setUp() {
    super.setUp()
    mockSession = MockURLSession()
    sut = ImageClient(responseQueue: nil,
                      session: mockSession)
    url = URL(string: "https://example.com/image")!
  }
  
  override func tearDown() {
    mockSession = nil
    sut = nil
    url = nil
    receivedTask = nil
    receivedError = nil
    receivedImage = nil
    super.tearDown()
  }
  
  // MARK: - Static Properties - Tests
  // 4
  func test_shared_setsResponseQueue() {
    XCTAssertEqual(ImageClient.shared.responseQueue, .main)
  }
  
  func test_shared_setsSession() {
    XCTAssertTrue(ImageClient.shared.session === URLSession.shared)
  }
  
  // MARK: - Object Lifecycle - Tests
  // 5
  func test_init_setsCachedImageForURL() {
    XCTAssertTrue(sut.cachedImageForURL.isEmpty)
  }
  
  func test_init_setsCachedTaskForImageView() {
    XCTAssertTrue(sut.cachedTaskForImageView.isEmpty)
  }
    
  func test_init_setsResponseQueue() {
    XCTAssertTrue(sut.responseQueue === nil)
  }
  
  func test_init_setsSession() {
    XCTAssertTrue(sut.session === mockSession)
  }
  
  /*
   As always, you first need to write a failing test. Add the following to ImageClientTests, right after the last test method
   */
  // MARK: - ImageService - Tests
  func test_conformsTo_ImageService() {
    XCTAssertTrue((sut as AnyObject) is ImageService)
  }
  
  /*
   아래의 downloadImage를 구현하지 않았기 때문에 컴파일 오류 발생
   */
  func test_imageService_declaresDownloadImage() {
    // given
    
    // then
    _ = service.downloadImage(fromURL: url) { _, _ in }
  }
  
  func test_imageService_declaresSetImageOnImageView() {
    // given
    let imageView = UIImageView()
    let placeholder = UIImage(named: "image_placeholder")!
    
    // then
    service.setImage(on: imageView,
                     fromURL: url,
                     withPlaceholder: placeholder)
  }
  
  func test_downloadImage_createsExpectedTask() {
    // when
    whenDownloadImage()
    
    // then
    XCTAssertEqual(receivedTask?.url, url)
  }
  
  func test_downloadImage_callsResumeOnTask() {
    // when
    whenDownloadImage()
    
    // then
    // receivedTask가 nil일 경우를 대비하여 기본값을 false로 한다.
    XCTAssertTrue(receivedTask?.calledResume ?? false)
  }
  
  // Handling the happy path
  func test_downloadImage_givenImage_callsCompletionWithImage() {
    // given
    let expectedImage = UIImage(named: "happy_dog")!
    
    // when
    whenDownloadImage(image: expectedImage)
    
    // then
    XCTAssertEqual(expectedImage.pngData(),
                   receivedImage?.pngData())
  }
  
  // Handling the error path
  func test_downloadImage_givenError_callsCompletionWithError() {
    // given
    let expectedError = NSError(domain: "com.example",
                                code: 42,
                                userInfo: nil)

    // when
    whenDownloadImage(error: expectedError)

    // then
    XCTAssertEqual(expectedError, receivedError as NSError?)
  }
  
  // MARK: - When
  // 1
  func whenDownloadImage(image: UIImage? = nil, error: Error? = nil) {
    
    // 2
    receivedTask = sut.downloadImage(
      fromURL: url) { image, error in
        
        // 3
        self.receivedImage = image
        self.receivedError = error
      } as? MockURLSessionTask
    
    // 4
    guard let receivedTask = receivedTask else {
      return
    }
    if let image = image {
      receivedTask.completionHandler(
        image.pngData(), nil, nil)
      
    } else if let error = error {
      receivedTask.completionHandler(nil, nil, error)
    }
  }
}
