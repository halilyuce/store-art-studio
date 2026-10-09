//
//  StoreArtPage.swift
//  StoreArt
//
//  The page around the device: the background field, headlines with an inline icon pill, and body
//  copy, all placed by BASELINE in slot pixels so a render can be checked against a reference line
//  for line (scripts/compare.swift, scripts/probe.swift).
//
//  The numbers below are the ones that were tuned against a reference board. They are a starting
//  point for a house style, not a law: replace the palette, keep the discipline (one accent per
//  slot, ink never pure black, text at fixed pixel sizes, tracking in the headline).
//

import SwiftUI
import UIKit

// MARK: - Palette

enum StoreArtColor {
    /// Headline and body ink. Never pure black on a pastel page.
    static let ink = Color(hex: 0x37373F)

    /// One accent per slot, the hue of its pill tile (top, bottom).
    static let yellow = (Color(hex: 0xFDCB2C), Color(hex: 0xF6BA32))
    static let cyan = (Color(hex: 0x3FE4F2), Color(hex: 0x1BDAEB))
    static let blue = (Color(hex: 0x5A87FB), Color(hex: 0x3C6FF9))

    /// The flat colour every device screen sits on when the app view has no backdrop of its own.
    static let screenTop = Color(hex: 0x3121FD)
    static let screenBottom = Color(hex: 0x3E3FF9)
}

/// A 3x3 mesh field, cool lilac at the top left warming to peach at the bottom right. Midpoints are
/// the averages of their neighbours. Needs iOS 18.
struct PastelBackground: View {
    private static let tl = SIMD3<Float>(0xDA, 0xE3, 0xFF), tr = SIMD3<Float>(0xE7, 0xE3, 0xF0)
    private static let center = SIMD3<Float>(0xE5, 0xE2, 0xF3)
    private static let bl = SIMD3<Float>(0xF1, 0xE2, 0xE6), br = SIMD3<Float>(0xFD, 0xE1, 0xD6)

    private static func color(_ v: SIMD3<Float>) -> Color {
        Color(.sRGB, red: Double(v.x / 255), green: Double(v.y / 255), blue: Double(v.z / 255))
    }

    var body: some View {
        let mid = { (a: SIMD3<Float>, b: SIMD3<Float>) in (a + b) / 2 }
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ],
            colors: [
                Self.tl, mid(Self.tl, Self.tr), Self.tr,
                mid(Self.tl, Self.bl), Self.center, mid(Self.tr, Self.br),
                Self.bl, mid(Self.bl, Self.br), Self.br,
            ].map(Self.color)
        )
    }
}

// MARK: - Headline

/// One headline line, lowercase by convention, with tight tracking.
struct HeadlineText: View {
    let text: String
    var px: CGFloat = 195
    var face: StoreArtFace = .headline
    var color: Color = StoreArtColor.ink

    /// -2% of the size. A reference's spacing usually reads between -2% and -3%.
    static func tracking(px: CGFloat) -> CGFloat { -0.02 * StoreArt.pt(px) }

    var body: some View {
        Text(verbatim: text)
            .font(.storeArt(face, px: px, for: text))
            .tracking(Self.tracking(px: px))
            .foregroundStyle(color)
            .lineLimit(1)
    }

    /// The text's width in pixels at `px`, so a wording is checked against its limit in a test
    /// instead of by eye. Never shrink the type to fit: shorten the wording.
    static func widthPx(_ text: String, px: CGFloat, face: StoreArtFace = .headline) -> CGFloat {
        let font = UIFont(name: face.postScriptName, size: StoreArt.pt(px)) ?? .systemFont(ofSize: StoreArt.pt(px), weight: .heavy)
        let width = (text as NSString).size(withAttributes: [.font: font, .kern: tracking(px: px)]).width
        return width * StoreArt.scale
    }

    /// The font's x-height in points, for sitting a tile on it.
    static func xHeight(px: CGFloat, face: StoreArtFace = .headline) -> CGFloat {
        UIFont(name: face.postScriptName, size: StoreArt.pt(px))?.xHeight ?? StoreArt.pt(px) * 0.55
    }
}

/// The rounded tile inside a headline pill: a hue gradient, a soft top highlight, a rim, and a
/// glyph (generated 3D art on a transparent background, see references/higgsfield-art.md).
struct GlyphTile: View {
    let glyph: UIImage?
    let hue: (Color, Color)
    var sizePx: CGFloat = 153
    var radiusPx: CGFloat = 38
    /// The glyph's height as a fraction of the tile.
    var glyphScale: CGFloat = 0.95

    var body: some View {
        let side = StoreArt.pt(sizePx)
        let shape = RoundedRectangle(cornerRadius: StoreArt.pt(radiusPx), style: .continuous)
        ZStack {
            shape.fill(LinearGradient(colors: [hue.0, hue.1], startPoint: .top, endPoint: .bottom))
            shape.fill(LinearGradient(colors: [.white.opacity(0.38), .white.opacity(0)], startPoint: .top, endPoint: .center))
            shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            if let glyph {
                Image(uiImage: glyph)
                    .resizable()
                    .scaledToFit()
                    .frame(height: side * glyphScale)
                    .shadow(color: hue.1.opacity(0.55), radius: 1.5, y: 1)
            }
        }
        .frame(width: side, height: side)
    }
}

/// A headline line that carries a pill: the word, then 35px later the tile, sitting on the x-height,
/// all inside a frosted pill 234px tall that starts 55px before the word. Placed by its baseline like
/// any other line.
struct PillHeadline: View {
    let word: String
    let glyph: UIImage?
    let hue: (Color, Color)
    var px: CGFloat = 195
    var color: Color = StoreArtColor.ink

    static let pillHeightPx: CGFloat = 234
    static let pillTopAboveBaselinePx: CGFloat = 162
    static let leadPx: CGFloat = 55
    static let trailPx: CGFloat = 40
    static let gapPx: CGFloat = 35
    static let tilePx: CGFloat = 153

    var body: some View {
        let xHeight = HeadlineText.xHeight(px: px)
        HStack(alignment: .firstTextBaseline, spacing: StoreArt.pt(Self.gapPx)) {
            HeadlineText(text: word, px: px, color: color)
            GlyphTile(glyph: glyph, hue: hue, sizePx: Self.tilePx)
                // Centre the tile on the x-height band: its middle sits xHeight/2 above the baseline.
                .alignmentGuide(.firstTextBaseline) { d in d.height / 2 + xHeight / 2 }
        }
        .padding(.leading, StoreArt.pt(Self.leadPx))
        .padding(.trailing, StoreArt.pt(Self.trailPx))
        // The pill is the padded line's background, aligned on the text baseline.
        .background(alignment: Alignment(horizontal: .leading, vertical: .firstTextBaseline)) {
            PillShape(hue: hue.1, tileCenterFromTrailing: StoreArt.pt(Self.trailPx + Self.tilePx / 2))
                .frame(height: StoreArt.pt(Self.pillHeightPx))
                .alignmentGuide(.firstTextBaseline) { _ in StoreArt.pt(Self.pillTopAboveBaselinePx) }
        }
        // Back out the padding so the WORD, not the pill, is what `placed(x:)` lines up.
        .padding(.leading, -StoreArt.pt(Self.leadPx))
        .padding(.trailing, -StoreArt.pt(Self.trailPx))
    }
}

/// The frosted pill: white 40% with a radial wash of the tile's hue behind the tile, and a 2px white
/// rim strongest at the top and bottom edges. No shadow.
struct PillShape: View {
    let hue: Color
    /// How far the tile's centre is from the pill's trailing edge; the hue wash centres there.
    let tileCenterFromTrailing: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: StoreArt.pt(60), style: .continuous)
        GeometryReader { geo in
            ZStack {
                shape.fill(Color.white.opacity(0.40))
                shape.fill(RadialGradient(
                    colors: [hue.opacity(0.25), hue.opacity(0)],
                    center: UnitPoint(x: (geo.size.width - tileCenterFromTrailing) / max(geo.size.width, 1), y: 0.5),
                    startRadius: 0, endRadius: StoreArt.pt(200)))
                shape.strokeBorder(LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.95), location: 0),
                        .init(color: .white.opacity(0.35), location: 0.5),
                        .init(color: .white.opacity(0.85), location: 1),
                    ], startPoint: .top, endPoint: .bottom), lineWidth: StoreArt.pt(2))
            }
        }
    }
}

// MARK: - Body copy

/// Body copy, one explicit line per entry, each placed on its own baseline `pitch` pixels apart.
/// Break lines yourself: a paragraph that reflows differently per language cannot be checked.
struct BodyLines: View {
    let lines: [String]
    let x: CGFloat
    let firstBaseline: CGFloat
    var px: CGFloat = 56
    var pitch: CGFloat = 80
    var color: Color = StoreArtColor.ink

    var body: some View {
        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
            Text(verbatim: line)
                .font(.storeArt(.bodyMedium, px: px, for: line, fallback: .medium))
                .foregroundStyle(color)
                .lineLimit(1)
                .placed(x: x, baseline: firstBaseline + CGFloat(index) * pitch)
        }
    }
}
