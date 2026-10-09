//
//  StoreArtKit.swift
//  StoreArt
//
//  The renderer. Everything is laid out in points on a phone-sized canvas and rendered at 3x, so a
//  spec written in pixels becomes points by dividing by `StoreArt.scale`. 440 x 956 pt at 3x is
//  1320 x 2868 px, the App Store's 6.9" slot.
//
//  This runs in a HOST-LESS unit test bundle: no app is installed or launched, which is the point.
//  A test that renders your real views from sample data can never touch a real account, keychain or
//  App Group. The cost is a short list of silent failures, all handled below or documented in
//  references/ios-swiftui-renderer.md:
//    * `Bundle.main` is the xctest runner, so asset catalogs, named colours and strings resolve to
//      nothing. `forwardMainBundle()` fixes it when you compile app or widget sources into the target.
//    * Materials do not blur (`.blur` does). `onAppear`, `.task` and remote images never run.
//

import CoreText
import ImageIO
import ObjectiveC
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Canvas, paths, fonts

enum StoreArt {
    /// One screenshot slot, in points. Rendered at `scale` to 1320 x 2868 pixels.
    static let canvas = CGSize(width: 440, height: 956)
    static let scale: CGFloat = 3

    /// The time zone every slot is set in. Pin the test scheme's `TZ` environment variable to the
    /// same zone; `setUp` should fail when they disagree so a Lock Screen clock cannot drift.
    static let timeZone = TimeZone(identifier: "America/Chicago")!

    /// The StoreArt folder in the checkout. The tests run in the simulator, which shares the Mac's
    /// file system, so fonts, bezels and artwork are read straight from here by path.
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

    /// The repository root, for assets that live outside this folder (the app icon, widget art).
    static let repo = root.deletingLastPathComponent()

    static var outputDirectory: URL {
        if let custom = ProcessInfo.processInfo.environment["STOREART_OUT"], !custom.isEmpty {
            return URL(fileURLWithPath: custom, isDirectory: true)
        }
        return root.appendingPathComponent("Output", isDirectory: true)
    }

    /// Pixels to points.
    static func pt(_ px: CGFloat) -> CGFloat { px / scale }

    /// Registers every .ttf and .otf under StoreArt/Fonts (one folder per family beside its licence).
    static func registerFonts() {
        let folder = root.appendingPathComponent("Fonts", isDirectory: true)
        let files = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL } ?? []
        for url in files where ["ttf", "otf"].contains(url.pathExtension.lowercased()) {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    /// An image from the StoreArt folder, by path. `UIImage(named:)` would look in the xctest
    /// runner and find nothing.
    static func art(_ path: String) -> UIImage? {
        UIImage(contentsOfFile: root.appendingPathComponent("Art/\(path)").path)
    }

    /// The bundle the target's resources (Localizable.strings, asset catalogs) were copied into.
    static let resources = Bundle(for: StoreArtBundleToken.self)

    /// Points `Bundle.main` at the test bundle. Needed only when app or widget sources are compiled
    /// into this target. Overriding `localizedString(forKey:value:table:)` alone fixes
    /// `"key".localized` but NOT SwiftUI's `Text("key")` or `Image("name")`, which then print raw
    /// keys or nothing, so the class method itself is exchanged.
    static func forwardMainBundle() {
        guard Bundle.main != resources,
              let original = class_getClassMethod(Bundle.self, #selector(getter: Bundle.main)),
              let replacement = class_getClassMethod(StoreArtMainBundle.self, #selector(StoreArtMainBundle.storeArtMainBundle))
        else { return }
        method_exchangeImplementations(original, replacement)
    }

    /// Switches the whole process to `zone`. Date formatting follows the system zone (TZ), not only
    /// `NSTimeZone.default`, so a market in another time zone has to move the process.
    static func useTimeZone(_ zone: TimeZone) {
        setenv("TZ", zone.identifier, 1)
        tzset()
        NSTimeZone.resetSystemTimeZone()
        NSTimeZone.default = zone
    }

    /// Renders `view` at `size` and writes an opaque PNG (both stores reject alpha).
    @MainActor
    static func render<V: View>(_ view: V, name: String, size: CGSize = canvas, timeZone: TimeZone = timeZone, locale: Locale = Locale(identifier: "en_US")) throws -> URL {
        // Top-leading: a slot whose device bleeds off the bottom is taller than the canvas, and a
        // centred frame would shift every baseline up by half the overhang.
        let content = view
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .clipped()
            .environment(\.locale, locale)
            .environment(\.timeZone, timeZone)

        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        renderer.isOpaque = true
        renderer.proposedSize = ProposedViewSize(size)
        guard let image = renderer.cgImage else { throw StoreArtError.renderFailed(name) }

        let url = outputDirectory.appendingPathComponent("\(name).png")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw StoreArtError.writeFailed(url.path)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw StoreArtError.writeFailed(url.path) }
        return url
    }
}

private final class StoreArtBundleToken {}

/// Answers `+[NSBundle mainBundle]` with the test bundle.
private final class StoreArtMainBundle: NSObject {
    @objc class func storeArtMainBundle() -> Bundle { StoreArt.resources }
}

enum StoreArtError: Error, CustomStringConvertible {
    case renderFailed(String)
    case writeFailed(String)
    case missingData(String)
    case missingFont(String)
    case timeZoneMismatch(String)

    var description: String {
        switch self {
        case .renderFailed(let name): return "ImageRenderer produced no image for \(name)"
        case .writeFailed(let path): return "Could not write \(path)"
        case .missingData(let name): return "Sample data \(name) is missing or did not decode"
        case .missingFont(let name): return "Font \(name) did not register; text would fall back to the system face"
        case .timeZoneMismatch(let zone): return "The process runs in \(zone) but StoreArt.timeZone is \(StoreArt.timeZone.identifier); set TZ in the scheme"
        }
    }
}

// MARK: - Colour

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Type

/// A face by PostScript name. Add one per static font you ship under StoreArt/Fonts.
struct StoreArtFace: Hashable {
    let postScriptName: String

    static let headline = StoreArtFace(postScriptName: "InterTight-Bold")
    static let headlineHeavy = StoreArtFace(postScriptName: "InterTight-ExtraBold")
    static let body = StoreArtFace(postScriptName: "Inter-Regular")
    static let bodyMedium = StoreArtFace(postScriptName: "Inter-Medium")

    static let all = [headline, headlineHeavy, body, bodyMedium]

    /// Throws when a face is missing, so a slot never silently falls back to SF Pro.
    static func verifyRegistered() throws {
        for face in all where UIFont(name: face.postScriptName, size: 12) == nil {
            throw StoreArtError.missingFont(face.postScriptName)
        }
    }
}

extension Font {
    /// A StoreArt face at a pixel size from the spec. Fixed size: Dynamic Type must not move it.
    static func storeArt(_ face: StoreArtFace, px: CGFloat) -> Font {
        .custom(face.postScriptName, fixedSize: StoreArt.pt(px))
    }

    /// The face for `text`: the StoreArt face when it has the glyphs (Latin, Greek, Cyrillic), the
    /// system face at `fallback` weight otherwise. Falling back through the font cascade picks the
    /// regular weight and leaves CJK and Arabic headlines hairline thin.
    static func storeArt(_ face: StoreArtFace, px: CGFloat, for text: String, fallback: Font.Weight = .heavy) -> Font {
        let needsFallback = text.unicodeScalars.contains { $0.value > 0x058F }
        return needsFallback ? .system(size: StoreArt.pt(px), weight: fallback) : storeArt(face, px: px)
    }
}

// MARK: - Placement in slot pixels

extension View {
    /// Leading edge at `x`, first text baseline at `baseline`, both in slot PIXELS, inside a
    /// top-leading ZStack. Baselines are how a reference is matched line for line.
    func placed(x: CGFloat, baseline: CGFloat) -> some View {
        fixedSize()
            .alignmentGuide(.leading) { _ in -StoreArt.pt(x) }
            .alignmentGuide(.top) { d in d[.firstTextBaseline] - StoreArt.pt(baseline) }
    }

    /// Top-leading corner at (`x`, `y`) in slot pixels.
    func placed(x: CGFloat, y: CGFloat) -> some View {
        fixedSize()
            .alignmentGuide(.leading) { _ in -StoreArt.pt(x) }
            .alignmentGuide(.top) { _ in -StoreArt.pt(y) }
    }

    /// Moves a view in slot pixels without changing the size of the ZStack it sits in. Use it
    /// (on top of `.placed(x: 0, y: 0)`) for anything that starts off the canvas: a negative or
    /// oversize `placed` widens the whole ZStack and shifts every other layer.
    func offsetPx(x: CGFloat, y: CGFloat) -> some View {
        offset(x: StoreArt.pt(x), y: StoreArt.pt(y))
    }
}
