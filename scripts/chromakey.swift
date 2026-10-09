// usage: swift chromakey.swift in.png out.png [--key "#FF00FF"] [--inner 0.35] [--outer 0.65] [--spill 1.0] [--crop]
// Keys out a flat colour background (generated art on #FF00FF or #00FF00) into a transparent PNG.
// Works in the YCbCr chroma plane, so any key colour behaves the same way:
//   alpha  ramps from 0 to 1 as a pixel's chroma moves from inner to outer (fractions of the key's
//          own chroma length) away from the key's chroma. A soft ramp keeps anti-aliased edges.
//   despill removes the part of each pixel's chroma that points toward the key, so edges and
//          translucent shadows lose the key's cast instead of carrying a magenta or green rim.
// --crop trims the output to the opaque bounding box.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count >= 3 else { fatalError("usage: swift chromakey.swift in.png out.png [--key #RRGGBB] [--inner f] [--outer f] [--spill f] [--crop]") }
func option(_ name: String) -> String? { args.firstIndex(of: name).flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } }
let keyHex = (option("--key") ?? "#FF00FF").replacingOccurrences(of: "#", with: "")
let inner = Float(option("--inner") ?? "0.35")!, outer = Float(option("--outer") ?? "0.65")!
let spill = Float(option("--spill") ?? "1.0")!
let crop = args.contains("--crop")

guard let keyValue = UInt32(keyHex, radix: 16) else { fatalError("bad --key \(keyHex)") }
let kr = Float((keyValue >> 16) & 0xFF) / 255, kg = Float((keyValue >> 8) & 0xFF) / 255, kb = Float(keyValue & 0xFF) / 255

func chroma(_ r: Float, _ g: Float, _ b: Float) -> (y: Float, cb: Float, cr: Float) {
    let y = 0.299 * r + 0.587 * g + 0.114 * b
    return (y, (b - y) * 0.564, (r - y) * 0.713)
}
let key = chroma(kr, kg, kb)
let keyLength = (key.cb * key.cb + key.cr * key.cr).squareRoot()
guard keyLength > 0.05 else { fatalError("key colour has no chroma; a grey key cannot be separated from grey art") }
let keyDir = (cb: key.cb / keyLength, cr: key.cr / keyLength)

let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(URL(fileURLWithPath: args[1]) as CFURL, nil)!, 0, nil)!
let w = source.width, h = source.height, cs = CGColorSpace(name: CGColorSpace.sRGB)!
var px = [UInt8](repeating: 0, count: w * h * 4)
CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: cs,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!.draw(source, in: CGRect(x: 0, y: 0, width: w, height: h))

var minX = w, minY = h, maxX = -1, maxY = -1
for i in 0..<(w * h) {
    let a0 = Float(px[i * 4 + 3]) / 255
    guard a0 > 0 else { continue }
    // Un-premultiply the source before working in chroma.
    let r = Float(px[i * 4]) / 255 / a0, g = Float(px[i * 4 + 1]) / 255 / a0, b = Float(px[i * 4 + 2]) / 255 / a0
    var c = chroma(r, g, b)

    let dcb = c.cb - key.cb, dcr = c.cr - key.cr
    let distance = (dcb * dcb + dcr * dcr).squareRoot() / keyLength
    let ramp = min(max((distance - inner) / (outer - inner), 0), 1)
    let alpha = ramp * ramp * (3 - 2 * ramp) * a0

    let toward = c.cb * keyDir.cb + c.cr * keyDir.cr
    if toward > 0 {
        c.cb -= keyDir.cb * toward * spill
        c.cr -= keyDir.cr * toward * spill
    }
    let nr = c.y + c.cr / 0.713, nb = c.y + c.cb / 0.564
    let ng = (c.y - 0.299 * nr - 0.114 * nb) / 0.587
    for (k, v) in [nr, ng, nb].enumerated() {
        px[i * 4 + k] = UInt8(min(max(v, 0), 1) * alpha * 255 + 0.5)
    }
    px[i * 4 + 3] = UInt8(alpha * 255 + 0.5)

    if alpha > 0.02 {
        let x = i % w, y = i / w
        minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
    }
}

let data = CFDataCreate(nil, px, px.count)!
var image = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4, space: cs,
                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                    provider: CGDataProvider(data: data)!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
if crop, maxX >= minX {
    image = image.cropping(to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1))!
}
let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("could not write \(args[2])") }
print("wrote \(args[2]) \(image.width)x\(image.height) key #\(keyHex) inner \(inner) outer \(outer)")
