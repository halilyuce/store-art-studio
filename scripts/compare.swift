// usage: swift compare.swift reference.png render.png out.png [--gx 104,1240] [--gy 868,312,535] [--slot 1320x2868]
// Puts a reference crop (left) beside your render (right), each scaled to 50% of the slot, with
// the same guides drawn across both so margins, baselines and the visual top can be checked by
// eye. Guides are given in full-size slot pixels. Pass the text margin and the baselines you are
// matching, for example --gx 104 --gy 312,535,868.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count >= 4 else { fatalError("usage: swift compare.swift go.png render.png out.png [--gx a,b] [--gy a,b] [--slot WxH]") }
func list(_ name: String) -> [CGFloat] {
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return [] }
    return args[i + 1].split(separator: ",").compactMap { Double($0) }.map { CGFloat($0) }
}
let guidesX = list("--gx"), guidesY = list("--gy")

var slot = CGSize(width: 1320, height: 2868)
if let i = args.firstIndex(of: "--slot"), i + 1 < args.count {
    let parts = args[i + 1].split(separator: "x").compactMap { Double($0) }
    if parts.count == 2 { slot = CGSize(width: parts[0], height: parts[1]) }
}
let scale: CGFloat = 0.5, gap: CGFloat = 24
let panel = CGSize(width: slot.width * scale, height: slot.height * scale)
let size = CGSize(width: panel.width * 2 + gap, height: panel.height)

func load(_ path: String) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fatalError("cannot read \(path)") }
    return image
}

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setFillColor(CGColor(gray: 0.5, alpha: 1))
ctx.fill(CGRect(origin: .zero, size: size))
ctx.interpolationQuality = .high

for (index, path) in [args[1], args[2]].enumerated() {
    let image = load(path)
    let x = CGFloat(index) * (panel.width + gap)
    // Aspect fit into the panel, top aligned: a crop that is not exactly slot-shaped still lines
    // up with the render at the top, where the headline guides are.
    let fit = min(panel.width / CGFloat(image.width), panel.height / CGFloat(image.height))
    let drawn = CGSize(width: CGFloat(image.width) * fit, height: CGFloat(image.height) * fit)
    // Core Graphics is bottom-left; slot coordinates are top-left.
    ctx.draw(image, in: CGRect(x: x, y: size.height - drawn.height, width: drawn.width, height: drawn.height))

    ctx.setLineWidth(1)
    ctx.setStrokeColor(CGColor(red: 1, green: 0.1, blue: 0.4, alpha: 0.9))
    for gx in guidesX {
        ctx.move(to: CGPoint(x: x + gx * scale, y: 0)); ctx.addLine(to: CGPoint(x: x + gx * scale, y: size.height))
    }
    for gy in guidesY {
        let y = size.height - gy * scale
        ctx.move(to: CGPoint(x: x, y: y)); ctx.addLine(to: CGPoint(x: x + panel.width, y: y))
    }
    ctx.strokePath()
}

let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[3]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, ctx.makeImage()!, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("could not write \(args[3])") }
print("wrote \(args[3]) \(Int(size.width))x\(Int(size.height)) guides x \(guidesX) y \(guidesY)")
