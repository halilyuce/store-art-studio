// usage: swift edgekey.swift in.png out.png [--min 205] [--spread 28] [--crop]
// Keys out a light, near-neutral background (white, off-white, pale grey) that touches the image
// border, for generated art where the model ignored the key colour you asked for. chromakey.swift
// cannot separate white from a white subject; this can, because it only removes background that is
// connected to the edge (a flood fill from every border pixel). Interior whites survive, so a white
// glyph on a coloured tile stays white.
//   --min     a background pixel's darkest channel is above this (0 to 255). Lower it for a grey backdrop.
//   --spread  and its channels differ by less than this, so pale colours in the subject are kept.
//   --crop    trims the output to the opaque bounding box.
// The boundary ring gets a soft 60% alpha so edges are not jagged. It does not despill: a subject that
// has a light rim baked into it keeps that rim. If the background is a frame or a vignette (not flat),
// regenerate instead.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count >= 3 else { fatalError("usage: swift edgekey.swift in.png out.png [--min 205] [--spread 28] [--crop]") }
func option(_ name: String) -> String? { args.firstIndex(of: name).flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } }
let minimum = Int(option("--min") ?? "205")!, spread = Int(option("--spread") ?? "28")!
let crop = args.contains("--crop")

guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: args[1]) as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fatalError("cannot read \(args[1])") }
let w = image.width, h = image.height
var px = [UInt8](repeating: 0, count: w * h * 4)
let context = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))

func isBackground(_ i: Int) -> Bool {
    let r = Int(px[i * 4]), g = Int(px[i * 4 + 1]), b = Int(px[i * 4 + 2])
    return min(r, g, b) > minimum && max(r, g, b) - min(r, g, b) < spread
}

// Flood fill from the border: 1 = background.
var mask = [UInt8](repeating: 0, count: w * h)
var stack = [Int]()
for x in 0..<w { stack.append(x); stack.append((h - 1) * w + x) }
for y in 0..<h { stack.append(y * w); stack.append(y * w + w - 1) }
while let i = stack.popLast() {
    if mask[i] == 1 || !isBackground(i) { continue }
    mask[i] = 1
    let x = i % w, y = i / w
    if x > 0 { stack.append(i - 1) }
    if x < w - 1 { stack.append(i + 1) }
    if y > 0 { stack.append(i - w) }
    if y < h - 1 { stack.append(i + w) }
}

var minX = w, minY = h, maxX = -1, maxY = -1, removed = 0
for y in 0..<h {
    for x in 0..<w {
        let i = y * w + x
        if mask[i] == 1 {
            for c in 0..<4 { px[i * 4 + c] = 0 }
            removed += 1
            continue
        }
        // Boundary ring: premultiplied pixels scaled to 60% where a background neighbour exists.
        let edge = (x > 0 && mask[i - 1] == 1) || (x < w - 1 && mask[i + 1] == 1)
            || (y > 0 && mask[i - w] == 1) || (y < h - 1 && mask[i + w] == 1)
        if edge { for c in 0..<4 { px[i * 4 + c] = UInt8(Int(px[i * 4 + c]) * 6 / 10) } }
        minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
    }
}
guard maxX >= 0 else { fatalError("everything matched the background; raise --min or lower --spread") }
if removed == 0 { print("warning: no light background touches the border; nothing was keyed") }

var out = context.makeImage()!
if crop { out = out.cropping(to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1))! }
let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, out, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("cannot write \(args[2])") }
print("wrote \(args[2]) \(out.width)x\(out.height), removed \(removed) background px")
