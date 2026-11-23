import XCTest
@testable import Search

/// Buttons at the top, with Settings › Buttons that go up: the doors asked
/// for go up beside back, forward and reload when they all fit there, the
/// pinned extensions counted; with too little room, the next choice that
/// takes fewer, down to the puzzle and bookmarks alone; with less still,
/// none, all at the foot. A pinned extension is never left out of both rows.
@MainActor
final class DoorsUpLevelTests: XCTestCase {
    private var restore: (() -> Void)?

    override class func setUp() {
        TestWorld.enter()
        super.setUp()
    }

    override func tearDown() {
        restore?()
        restore = nil
        super.tearDown()
    }

    private func prefs(_ set: DoorsUpSet) -> Preferences {
        let prefs = Shared.prefs
        let before = (prefs.sidebar, prefs.sideIcons, prefs.doorsUp, prefs.doorsUpSet, prefs.foldButton,
                      prefs.hidesExtensionsDoor, prefs.hidesBookmarksDoor, prefs.hidesProfileDoor)
        restore = {
            (prefs.sidebar, prefs.sideIcons, prefs.doorsUp, prefs.doorsUpSet, prefs.foldButton,
             prefs.hidesExtensionsDoor, prefs.hidesBookmarksDoor, prefs.hidesProfileDoor) = before
        }
        prefs.sidebar = true
        prefs.sideIcons = false
        prefs.doorsUp = true
        prefs.doorsUpSet = set
        prefs.foldButton = false
        prefs.hidesExtensionsDoor = false
        prefs.hidesBookmarksDoor = false
        prefs.hidesProfileDoor = true
        return prefs
    }

    /// The narrowest column whose lights' row has `room` right of the helm.
    private func width(for room: CGFloat, _ prefs: Preferences) -> CGFloat {
        var width: CGFloat = 100
        while SideBar.beyondHelm(width, fullScreen: false, fold: false, prefs: prefs) < room { width += 1 }
        return width
    }

    private func level(_ prefs: Preferences, room: CGFloat, pinned: Int) -> DoorsUpSet? {
        SideBar.doorsUpLevel(prefs, width: width(for: room, prefs), fullScreen: false, pinned: pinned)
    }

    func testEachChoiceTakesItsOwnDoors() {
        let prefs = prefs(.all)
        let door: CGFloat = 28
        XCTAssertEqual(SideFoot.keptWidth(prefs, set: .extensionsAndBookmarks, pinned: 3), 2 * door - 2,
                       "the puzzle and bookmarks; the pinned ones stay at the foot")
        XCTAssertEqual(SideFoot.keptWidth(prefs, set: .pinnedAndBookmarks, pinned: 3), 5 * door - 2,
                       "the pinned ones beside the puzzle")
        XCTAssertGreaterThan(SideFoot.keptWidth(prefs, set: .all, pinned: 3),
                             SideFoot.keptWidth(prefs, set: .pinnedAndBookmarks, pinned: 3), "and downloads too")
    }

    func testWhatIsAskedForGoesUpWhenItFits() {
        let prefs = prefs(.pinnedAndBookmarks)
        XCTAssertEqual(level(prefs, room: SideFoot.keptWidth(prefs, set: .pinnedAndBookmarks, pinned: 3), pinned: 3),
                       .pinnedAndBookmarks)
    }

    func testPinnedExtensionsWithoutRoomStayAtTheFoot() {
        let prefs = prefs(.pinnedAndBookmarks)
        let room = SideFoot.keptWidth(prefs, set: .pinnedAndBookmarks, pinned: 3) - 1
        XCTAssertEqual(level(prefs, room: room, pinned: 3), .extensionsAndBookmarks,
                       "the puzzle and bookmarks up, the pinned ones back at the foot, not gone")
    }

    func testEveryDoorFallsBackOneChoiceAtATime() {
        let prefs = prefs(.all)
        let all = SideFoot.keptWidth(prefs, set: .all, pinned: 2)
        let pinned = SideFoot.keptWidth(prefs, set: .pinnedAndBookmarks, pinned: 2)
        XCTAssertEqual(level(prefs, room: all, pinned: 2), .all)
        XCTAssertEqual(level(prefs, room: all - 1, pinned: 2), .pinnedAndBookmarks)
        XCTAssertEqual(level(prefs, room: pinned - 1, pinned: 2), .extensionsAndBookmarks)
    }

    func testTooLittleRoomForEvenTheFewestKeepsThemAllAtTheFoot() {
        let prefs = prefs(.all)
        let fewest = SideFoot.keptWidth(prefs, set: .extensionsAndBookmarks, pinned: 2)
        XCTAssertNil(level(prefs, room: fewest - 1, pinned: 2))
        XCTAssertFalse(SideBar.doorsUp(prefs, width: width(for: fewest - 1, prefs), fullScreen: false))
    }

    func testAChoiceNeverGoesUpToMoreThanAskedFor() {
        let prefs = prefs(.extensionsAndBookmarks)
        XCTAssertEqual(level(prefs, room: 2_000, pinned: 2), .extensionsAndBookmarks)
    }
}
