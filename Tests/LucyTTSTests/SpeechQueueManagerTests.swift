import XCTest
@testable import LiveFishTTS

/// Smoke tests for input validation on SpeechQueueManager.
/// Full state-machine coverage (queued -> generating -> playing -> done/error
/// transitions, stopCurrent during synthesis, replay after success) requires
/// fakes for FishAudioClient and AudioPlaybackService and is intentionally
/// out of scope for this initial test suite.
@MainActor
final class SpeechQueueManagerTests: XCTestCase {
    func testEnqueueRejectsEmptyString() {
        let manager = SpeechQueueManager()
        manager.enqueue("")
        XCTAssertTrue(manager.items.isEmpty)
        XCTAssertEqual(manager.queuedCount, 0)
    }

    func testEnqueueRejectsWhitespaceOnlyString() {
        let manager = SpeechQueueManager()
        manager.enqueue("   \n\t  ")
        XCTAssertTrue(manager.items.isEmpty)
    }

    func testEnqueueTrimsAndStoresText() {
        let manager = SpeechQueueManager()
        manager.enqueue("  hello world  \n")
        XCTAssertEqual(manager.items.count, 1)
        XCTAssertEqual(manager.items.first?.text, "hello world")
    }

    func testReplayLastSpokenIsNoOpWithoutHistory() {
        let manager = SpeechQueueManager()
        manager.replayLastSpoken()
        XCTAssertTrue(manager.items.isEmpty)
    }

    func testClearQueueOnlyRemovesQueuedItems() async {
        // After enqueue, the processing task runs and, because no services
        // were configured, immediately marks the item as .error. Wait briefly
        // for that transition so we can verify clearQueue does NOT remove it.
        let manager = SpeechQueueManager()
        manager.enqueue("first")
        manager.enqueue("second")
        XCTAssertEqual(manager.items.count, 2)

        // Allow the processing task to drain.
        try? await Task.sleep(nanoseconds: 50_000_000)

        // All items should have moved out of .queued.
        XCTAssertEqual(manager.queuedCount, 0)
        let countBeforeClear = manager.items.count
        manager.clearQueue()
        XCTAssertEqual(manager.items.count, countBeforeClear, "clearQueue must not remove items that already left the queued state")
    }
}
