/// Copyright (c) 2021 Razeware LLC
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
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

@testable import DogPatch
import XCTest

class ListingsViewControllerTests: XCTestCase {
  
  // MARK: - Instance Properties
  var sut: ListingsViewController!
  var mockNetworkClient: MockDogPatchService!
  
  var partialMock: PartialMockListingsViewController {
    return sut as! PartialMockListingsViewController
  }
  
  // sut.networkClient와 DogPatchClient.shared 비교
  func test_networkClient_setToDogPatchClient() {
    XCTAssertTrue((sut.networkClient as? DogPatchClient) === DogPatchClient.shared)
  }
  
  // MARK: - Test Lifecycle
  override func setUp() {
    super.setUp()
    sut = ListingsViewController.instanceFromStoryboard()
    sut.loadViewIfNeeded()
  }
  
  // 테스트 실행이 완료된 후 mockNetworkClient에 nil 설정.
  override func tearDown() {
    sut = nil
    mockNetworkClient = nil
    super.tearDown()
  }
  
  // MARK: - Given
  func givenPartialMock() {
    sut = PartialMockListingsViewController()
    sut.loadViewIfNeeded()
  }
  
  func givenViewModels(count: Int = 3) {
    guard count > 0 else {
      sut.viewModels = []
      return
    }
    sut.viewModels = givenDogs(count: count).map { DogViewModel(dog: $0) }
  }
  
  func givenMockViewModels(count: Int = 3) {
    guard count > 0 else {
      sut.viewModels = []
      return
    }
    sut.viewModels = givenDogs(count: count).map { MockDogViewModel(dog: $0) }
  }
  
  func givenDogs(count: Int = 3) -> [Dog] {
    return (1 ... count).map { i in
      let dog = Dog(
        id: "id_\(i)",
        sellerID: "sellderID_\(i)",
        about: "about_\(i)",
        birthday: Date(timeIntervalSinceNow: -1 * Double(i).years),
        breed: "breed_\(i)",
        breederRating: Double(i % 5),
        cost: Decimal(i * 100),
        created: Date(timeIntervalSinceNow: -1 * Double(i).hours),
        imageURL: URL(string: "http://example.com/\(i)")!,
        name: "name_\(i)")
      return dog
    }
  }
  
  func givenMockNetworkClient() {
    mockNetworkClient = MockDogPatchService()
    sut.networkClient = mockNetworkClient
  }
  
  // MARK: - When
  func whenDequeueTableViewCells() -> [UITableViewCell] {
    return (0 ..< sut.viewModels.count).map { i in
      let indexPath = IndexPath(row: i, section: 0)
      return sut.tableView(sut.tableView, cellForRowAt: indexPath)
    }
  }
  
  // MARK: - Outlets - Tests
  func test_tableView_onSet_registersErrorTableViewCell() {
    // when
    let cell = sut.tableView.dequeueReusableCell(
      withIdentifier: ErrorTableViewCell.identifier)
    
    // then
    XCTAssertTrue(cell is ErrorTableViewCell)
  }
  
  // MARK: - Instance Properties - Tests
  func test_viewModels_setToEmptyArray() {
    XCTAssertEqual(sut.viewModels.count, 0)
  }
  
  // MARK: - View Life Cycle - Tests
  func test_viewDidLoad_setsRefreshControlAttributedTitle() throws {
    // when
    sut.viewDidLoad()
    
    // then
    let refreshControl = try XCTUnwrap(sut.tableView.refreshControl)
    XCTAssertEqual(refreshControl.attributedTitle, NSAttributedString(string: "Loading..."))
  }
  
  func test_viewDidLoad_setsRefreshControlTarget() throws {
    // when
    sut.viewDidLoad()
    
    // then
    let refreshControl = try XCTUnwrap(sut.tableView.refreshControl)
    
    XCTAssertEqual(refreshControl.allTargets.count, 1)
    let target = try XCTUnwrap(refreshControl.allTargets.first as? ListingsViewController)
    XCTAssertTrue(sut === target)
  }
  
  func test_viewDidLoad_setsRefreshControlAction() throws {
    // when
    sut.viewDidLoad()
    
    // then
    let refreshControl = try XCTUnwrap(sut.tableView.refreshControl)
    let target = try XCTUnwrap(refreshControl.allTargets.first as? ListingsViewController)
    let actions = refreshControl.actions(forTarget: target, forControlEvent: .valueChanged)
    let selector = try XCTUnwrap(actions?.first)
    XCTAssertEqual(actions?.count, 1)
    XCTAssertEqual(Selector(selector), #selector(ListingsViewController.refreshData))
  }
  
  func test_viewWillAppear_calls_refreshData() {
    // given
    givenPartialMock()
    let expectation = self.expectation(description: "Expected refreshData to be called")
    partialMock.onRefreshData = {
      expectation.fulfill()
    }
    
    // when
    sut.viewWillAppear(true)
    
    // then
    waitForExpectations(timeout: 0.0)
  }
  
  // 뷰 컨트롤러가 반환된 데이터 작업을 유지하는지 테스트.
  func test_refreshData_setsRequest() {
    // given
    givenMockNetworkClient()
    
    // when
    // 1. sut.refreshData()를 호출한 후
    sut.refreshData()

    // then
    // 2. sut.dataTask가 mockNetworkClient.getDogsDataTask로 설정되어 있는지 확인
    XCTAssertTrue(sut.dataTask === mockNetworkClient.getDogsDataTask)
  }
  
  // 네트워크 진행 중에 '밑으로 당기기'로 네트워크를 중복 요청할 수 있음
  // refreshData가 빠르게 연속적으로 호출되더라도 getDogs를 한 번만 호출 할 수 있도록 테스트
  func test_refreshData_ifAlreadyRefreshing_doesntCallAgain() {
    // given
    givenMockNetworkClient()
    
    // when
    sut.refreshData()
    sut.refreshData()
    
    // then
    XCTAssertEqual(mockNetworkClient.getDogsCallCount, 1)
  }
  
  // test_refreshData_completionNilsDataTask와 test_refreshData_givenDogsResponse_setsViewModels는
  // 언듯보기에는 비슷해보여서 리팩토링이 가능할 것 같지만, 막상 하고 나면 읽기 더 어려워짐.
  // 잘 모르겠으면 일단 해봐~! 롤백하면 그만이야 🤗
  func test_refreshData_completionNilsDataTask() {
    // given
    givenMockNetworkClient()
    let dogs = givenDogs()
    
    // when
    // 1. sut.refreshData() -> dataTask설정
    // 2. mockNetworkCient의 getDogsCompletion에 dogs전달.
    //    ㄴ ListingsViewController에서 클로져 실행 -> dataTask를 nil로 설정
    sut.refreshData()
    mockNetworkClient.getDogsCompletion(dogs, nil)
    
    // then
    XCTAssertNil(sut.dataTask)
  }
  
  func test_refreshData_givenDogsResponse_setsViewModels() {
    // given
    givenMockNetworkClient()
    let dogs = givenDogs()
    let viewModels = dogs.map { DogViewModel(dog: $0) }
    
    // when
    sut.refreshData()
    mockNetworkClient.getDogsCompletion(dogs, nil)
    
    // then
    XCTAssertEqual(sut.viewModels, viewModels)
  }
  
  // MARK: - UITableViewDataSource Tests
  func test_tableView_numberOfRowsInSection_givenIsRefreshing_returns0() {
    // given
    let expected = 0
    sut.tableView.refreshControl!.beginRefreshing()
    
    // when
    let actual = sut.tableView(sut.tableView, numberOfRowsInSection: 0)
    
    // then
    XCTAssertEqual(actual, expected)
  }

  func test_tableView_numberOfRowsInSection_givenHasViewModels_returnsViewModelsCount() {
    // given
    let expected = 3
    givenViewModels(count: expected)
    
    // when
    let actual = sut.tableView(sut.tableView, numberOfRowsInSection: 0)
    
    // then
    XCTAssertEqual(actual, expected)
  }

  func test_tableView_numberOfRowsInSection_givenNoViewModels_returns1() {
    // given
    let expected = 1
    
    // when
    let actual = sut.tableView(sut.tableView, numberOfRowsInSection: 0)
    
    // then
    XCTAssertEqual(actual, expected)
  }
  
  func test_tableViewCellForRowAt_givenNoViewModelsSet_returns_ErrorTableViewCell() {
    // given
    givenViewModels(count: 0)
    
    // when
    let indexPath = IndexPath(row: 0, section: 0)
    let cell = sut.tableView(sut.tableView, cellForRowAt: indexPath)
    
    // then
    XCTAssertTrue(cell is ErrorTableViewCell)
  }
  
  func test_tableViewCellForRowAt_givenViewModelsSet_returnsListingTableViewCells() {
    // given
    givenViewModels()
    
    // when
    let cells = whenDequeueTableViewCells()
    
    // then
    for cell in cells {
      XCTAssertTrue(cell is ListingTableViewCell)
    }
  }
  
  func test_tableViewCellForRowAt_givenViewModelsSet_configuresTableViewCells() throws {
    // given
    givenMockViewModels()
    
    // when
    let cells = try XCTUnwrap(whenDequeueTableViewCells() as? [ListingTableViewCell])
    
    // then
    for i in 0 ..< sut.viewModels.count {
      let cell = cells[i]
      let viewModel = sut.viewModels[i] as! MockDogViewModel
      XCTAssertTrue(viewModel.configuredCell === cell) // pointer equality
    }
  }
}

// MARK: - Mocks
extension ListingsViewControllerTests {
  
  class MockDogViewModel: DogViewModel {
    var configuredCell: ListingTableViewCell?
    override func configure(_ cell: ListingTableViewCell) {
      self.configuredCell = cell
    }
  }
  
  class PartialMockListingsViewController: ListingsViewController {
    
    override func loadView() {
      super.loadView()
      tableView = UITableView()
    }
    
    var onRefreshData: (()->Void)? = nil
    override func refreshData() {
      guard let onRefreshData = onRefreshData else {
        super.refreshData()
        return
      }
      onRefreshData()
    }
  }
}
