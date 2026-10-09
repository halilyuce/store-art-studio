//
//  SampleSlot.swift
//  StoreArt
//
//  A complete slot in the house layout: pastel page, two-line headline with a pill, two-line body,
//  a straight phone bleeding off the bottom. Copy this file per slot. Replace `SampleScreen` with
//  your REAL app view fed with sample data; everything else in this file is page, not product.
//

import SwiftUI

struct SampleSlotCopy {
    var first = "your app,"
    var word = "shown"
    var body = ["the real screens, rendered from sample data,", "on a page that sells them."]
}

struct SampleSlot: View {
    var copy = SampleSlotCopy()

    var body: some View {
        ZStack(alignment: .topLeading) {
            PastelBackground()

            HeadlineText(text: copy.first).placed(x: 104, baseline: 312)
            PillHeadline(word: copy.word, glyph: StoreArt.art("sample/glyph.png"), hue: StoreArtColor.yellow)
                .placed(x: 104, baseline: 535)
            BodyLines(lines: copy.body, x: 104, firstBaseline: 660)

            StraightPhone { SampleScreen() }
        }
        .frame(width: StoreArt.canvas.width, height: StoreArt.canvas.height, alignment: .topLeading)
    }
}

/// Stand-in for the app. A real slot renders the app's own SwiftUI view here, with sample data.
private struct SampleScreen: View {
    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [StoreArtColor.screenTop, StoreArtColor.screenBottom], startPoint: .top, endPoint: .bottom)
            IOSStatusBar()
            Text(verbatim: "Replace me with a real view")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.top, 200)
        }
    }
}
