import XCTest
import TimelineCore

class CounterTests: XCTestCase {
    var time = Date(timeIntervalSinceReferenceDate: 10000)
    var counter: Counter!

    override func setUpWithError() throws {
        counter = Counter(timeDependency: {
            return self.time
        })
    }

    func testStatisticsInProgress() throws {
        counter.start(name: "hello")
        time = time.advanced(by: 50)
        counter.start(name: "come on")
        time = time.advanced(by: 10)
        XCTAssertEqual(counter.statistics, ["hello": 50, "come on": 10])
    }

    func testStatisticsPaused() throws {
        counter.start(name: "hello")
        time = time.advanced(by: 20)
        counter.pause()
        time = time.advanced(by: 10)
        XCTAssertEqual(counter.statistics, ["hello": 20])
    }

    func testStatisticsContinued() throws {
        counter.start(name: "hello")
        time = time.advanced(by: 20)
        counter.pause()
        time = time.advanced(by: 10)
        counter.start(name: "hello")
        time = time.advanced(by: 15)
        XCTAssertEqual(counter.statistics, ["hello": 35])
    }

}
