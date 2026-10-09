// usage: swift probe.swift image.png [--at x,y ...] [--ink x0,y0,x1,y1 --bg "#RRGGBB" [--tol 24]] [--rows x0,x1 --bg "#RRGGBB" [--tol 24]]
// Measures a reference or a render without guessing.
//   --at x,y       prints the sRGB hex under that pixel (repeatable). Sample the middle of a flat area, not an edge.
//   --ink box      prints the bounding box of every pixel in the box that differs from --bg by more than --tol
//                  (sum of channel differences, 0 to 765). Use it to get a headline's left edge, right edge, cap height.
//   --rows x0,x1   prints the y ranges (top to bottom) that hold ink inside the column band x0..x1, so line tops and
//                  bottoms, and therefore baselines and line pitch, can be read off a text block.
// Pixel coordinates are top-left origin, in the image's own pixels. Pillow is not needed.
import CoreGraphics
import Foundation
import ImageIO

let args = CommandLine.arguments
guard args.count >= 2 else { fatalError("usage: swift probe.swift image.png [--at x,y] [--ink x0,y0,x1,y1 --bg #hex] [--rows x0,x1 --bg #hex]") }
func values(_ name: String) -> [String] {
    var out: [String] = []
    for (i, a) in args.enumerated() where a == name && i + 1 < args.count { out.append(args[i + 1]) }
    return out
}
func nums(_ s: String) -> [Int] { s.split(separator: ",").compactMap { Int($0) } }

guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: args[1]) as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fatalError("cannot read \(args[1])") }
let w = image.width, h = image.height
var px = [UInt8](repeating: 0, count: w * h * 4)
CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
print("\(args[1]) \(w)x\(h)")

func rgb(_ x: Int, _ y: Int) -> (Int, Int, Int) {
    let i = (y * w + x) * 4
    let a = max(Int(px[i + 3]), 1)
    // Un-premultiply so a translucent pixel reports its own colour.
    return (min(255, Int(px[i]) * 255 / a), min(255, Int(px[i + 1]) * 255 / a), min(255, Int(px[i + 2]) * 255 / a))
}
func hex(_ c: (Int, Int, Int)) -> String { String(format: "#%02X%02X%02X", c.0, c.1, c.2) }

for point in values("--at") {
    let p = nums(point)
    guard p.count == 2, p[0] >= 0, p[0] < w, p[1] >= 0, p[1] < h else { print("at \(point): outside the image"); continue }
    print("at \(p[0]),\(p[1]) = \(hex(rgb(p[0], p[1])))")
}

let tol = Int(values("--tol").first ?? "24") ?? 24
var bg = (255, 255, 255)
if let b = values("--bg").first, let v = UInt32(b.replacingOccurrences(of: "#", with: ""), radix: 16) {
    bg = (Int((v >> 16) & 0xFF), Int((v >> 8) & 0xFF), Int(v & 0xFF))
}
func isInk(_ x: Int, _ y: Int) -> Bool {
    let c = rgb(x, y)
    return abs(c.0 - bg.0) + abs(c.1 - bg.1) + abs(c.2 - bg.2) > tol
}

if let box = values("--ink").first {
    let b = nums(box)
    guard b.count == 4 else { fatalError("--ink needs x0,y0,x1,y1") }
    var minX = Int.max, minY = Int.max, maxX = -1, maxY = -1
    for y in max(b[1], 0)..<min(b[3], h) { for x in max(b[0], 0)..<min(b[2], w) where isInk(x, y) {
        minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
    } }
    print(maxX < 0 ? "ink: none inside the box" : "ink x \(minX)..\(maxX) (width \(maxX - minX + 1))  y \(minY)..\(maxY) (height \(maxY - minY + 1))")
}

if let band = values("--rows").first {
    let b = nums(band)
    guard b.count == 2 else { fatalError("--rows needs x0,x1") }
    var start: Int? = nil
    for y in 0...h {
        let hit = y < h && (max(b[0], 0)..<min(b[1], w)).contains { isInk($0, y) }
        if hit, start == nil { start = y }
        if !hit, let s = start { print("rows y \(s)..\(y - 1) (height \(y - s))"); start = nil }
    }
}
