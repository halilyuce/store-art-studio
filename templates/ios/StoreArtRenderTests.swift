//
//  StoreArtRenderTests.swift
//  StoreArt
//
//  Renders store creative to StoreArt/Output (or $STOREART_OUT).
//
//  Run it through scripts/screenshots/render.sh on a dedicated simulator that never has your app installed.
//  Tests are named `testXxx` because render.sh selects one with `test$1`.
//

import SwiftUI
import XCTest

@MainActor
final class StoreArtRenderTests: XCTestCase {
    override func setUp() async throws {
        guard TimeZone.current.identifier == StoreArt.timeZone.identifier else {
            throw StoreArtError.timeZoneMismatch(TimeZone.current.identifier)
        }
        StoreArt.registerFonts()
        try StoreArtFace.verifyRegistered()
        // Only when app or widget sources are compiled into this target:
        // StoreArt.forwardMainBundle()
    }

    override func tearDown() async throws {
        // A market slot may switch the process time zone; put the scheme's back.
        StoreArt.useTimeZone(StoreArt.timeZone)
    }

    /// The sample slot, to prove the pipeline end to end before any real slot exists.
    func testSample() throws {
        let url = try StoreArt.render(SampleSlot(), name: "default_en-US_iphone_01")
        print("[storeart] wrote \(url.path)")
    }

    /// Fails when a headline line is wider than the room beside the art, at the FULL type size.
    /// The cure for a failure is a shorter wording, never smaller type.
    func testHeadlineWidths() throws {
        let limit: CGFloat = 1110
        let copy = SampleSlotCopy()
        for line in [copy.first, copy.word] {
            let width = HeadlineText.widthPx(line, px: 195)
            print("[widths] \(Int(width)) \(line)")
            XCTAssertLessThanOrEqual(width, limit, "\"\(line)\" is too wide at 195px: shorten the wording")
        }
    }
}
