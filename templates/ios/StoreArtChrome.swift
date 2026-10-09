//
//  StoreArtChrome.swift
//  StoreArt
//
//  iOS system chrome around your real views: the status bar and the device. Not app UI, so it is
//  drawn here. Metrics are in screen pixels on a 1320 x 2868 screen so they can be re-measured
//  against a real simulator screenshot (status bar overridden to 9:41, full Wi-Fi, four bars, 100%)
//  and compared one to one with `scripts/probe.swift`.
//
//  Once a slot is approved, treat these metrics as frozen: every slot shares them, so a tweak
//  silently restyles all of them.
//

import SwiftUI
import UIKit

// MARK: - Status bar

struct IOSStatusBar: View {
    var time = "9:41"
    var tint: Color = .white

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Anchors the ZStack at the screen's origin so the placements below are absolute.
            Color.clear.frame(width: StoreArt.canvas.width, height: StoreArt.canvas.height)

            Text(verbatim: time)
                .font(.system(size: 17.5, weight: .semibold))
                .foregroundStyle(tint)
                .fixedSize()
                .frame(width: StoreArt.pt(200))
                .placed(x: 148, baseline: 117)

            // Cellular: four 11px bars 18px apart, bottoms on y 116, heights 16 / 23 / 32 / 41.
            ForEach(Array([16, 23, 32, 41].enumerated()), id: \.offset) { index, height in
                RoundedRectangle(cornerRadius: StoreArt.pt(2.5), style: .continuous)
                    .fill(tint)
                    .frame(width: StoreArt.pt(11), height: StoreArt.pt(CGFloat(height)))
                    .placed(x: 937 + CGFloat(index) * 18, y: 117 - CGFloat(height))
            }

            // Wi-Fi: ink box 57 x 41 at (1025, 76).
            Image(systemName: "wifi")
                .resizable()
                .scaledToFit()
                .fontWeight(.semibold)
                .foregroundStyle(tint)
                .frame(width: StoreArt.pt(57), height: StoreArt.pt(41))
                .placed(x: 1025, y: 76)

            // Battery: a 40% outline 85 x 37 at (1105, 75), a full fill inset 7px, a 40% cap.
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: StoreArt.pt(12), style: .continuous)
                    .strokeBorder(tint.opacity(0.4), lineWidth: StoreArt.pt(4))
                    .frame(width: StoreArt.pt(85), height: StoreArt.pt(37))
                RoundedRectangle(cornerRadius: StoreArt.pt(8), style: .continuous)
                    .fill(tint)
                    .frame(width: StoreArt.pt(71), height: StoreArt.pt(25))
                    .padding(.leading, StoreArt.pt(7))
                UnevenRoundedRectangle(bottomTrailingRadius: StoreArt.pt(4), topTrailingRadius: StoreArt.pt(4))
                    .fill(tint.opacity(0.4))
                    .frame(width: StoreArt.pt(6), height: StoreArt.pt(13))
                    .padding(.leading, StoreArt.pt(87))
            }
            .placed(x: 1105, y: 75)
        }
        .frame(width: StoreArt.canvas.width, height: StoreArt.canvas.height, alignment: .topLeading)
    }
}

// MARK: - Device

/// Geometry of one bezel PNG. The defaults are Apple's iPhone 17 Pro Max export (1470 x 3000, screen
/// hole 1320 x 2868 at (75, 66), corner radius 190 px). Measure any other file the same way: find
/// the transparent hole's bounds and its corner radius, and write them here.
struct BezelSpec {
    var name = "iPhone 17 Pro Max - Deep Blue - Portrait"
    var size = CGSize(width: 1470, height: 3000)
    var hole = CGRect(x: 75, y: 66, width: 1320, height: 2868)
    var clipRadius: CGFloat = 190
}

/// A device with a 440 x 956 pt screen inside, scaled and placed in slot pixels.
///
/// The bezel PNG comes from Apple Design Resources (developer.apple.com/design/resources). Its
/// licence does not allow redistribution, so it is never committed: drop it in `Art/bezels/`. Without
/// it this draws a plain dark frame so a layout can still be judged.
struct StraightPhone<Screen: View>: View {
    var spec = BezelSpec()
    var scale: CGFloat = 0.763
    /// The bezel's top-left corner in slot pixels.
    var origin = CGPoint(x: 93, y: 818)
    @ViewBuilder var screen: () -> Screen

    var body: some View {
        let bezel = StoreArt.art("bezels/\(spec.name).png")
        ZStack(alignment: .topLeading) {
            Color.clear.frame(width: StoreArt.canvas.width, height: StoreArt.canvas.height)
            screen()
                .frame(width: StoreArt.canvas.width, height: StoreArt.canvas.height)
                .clipShape(RoundedRectangle(cornerRadius: StoreArt.pt(spec.clipRadius), style: .continuous))
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: StoreArt.canvas.width * scale, height: StoreArt.canvas.height * scale, alignment: .topLeading)
                .placed(x: origin.x + spec.hole.minX * scale, y: origin.y + spec.hole.minY * scale)

            if let bezel {
                Image(uiImage: bezel)
                    .resizable()
                    .frame(width: StoreArt.pt(spec.size.width * scale), height: StoreArt.pt(spec.size.height * scale))
                    .placed(x: origin.x, y: origin.y)
            } else {
                RoundedRectangle(cornerRadius: StoreArt.pt((spec.clipRadius + 40) * scale), style: .continuous)
                    .strokeBorder(Color.black, lineWidth: StoreArt.pt(60 * scale))
                    .frame(width: StoreArt.pt(spec.size.width * scale), height: StoreArt.pt(spec.size.height * scale))
                    .placed(x: origin.x, y: origin.y)
            }
        }
    }
}
