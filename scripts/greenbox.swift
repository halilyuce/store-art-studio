// usage: swift greenbox.swift photo.png [--min-g 180] [--max-rb 120]
// Measures a green screen face (#00FF00) in a generated photo: a watch face on a wrist, a phone
// screen in a hand. Prints the image size, the green pixels' bounding box, centre, width, height and
// pixel count, in the image's own pixels (top-left origin). Place the real render over that box
// with a mask the same shape (a circle for a round watch, about 1.035 times the diameter so no green
// fringe survives), and write the box into the asset's provenance file.
//   --min-g   a green pixel's green channel is above this (0 to 255).
//   --max-rb  and its red and blue channels are below this. Tighten both if foliage or a green
//             shirt is counted; the box should match the face you see.
// For a tilted slab with perspective, use screenswap.swift, which finds the quad and warps onto it.
import CoreGraphics
import Foundation
import ImageIO

let args = CommandLine.arguments
guard args.count >= 2 else { fatalError("usage: swift greenbox.swift photo.png [--min-g 180] [--max-rb 120]") }
func option(_ name: String) -> String? { args.firstIndex(of: name).flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } }
let minG = Int(option("--min-g") ?? "180")!, maxRB = Int(option("--max-rb") ?? "120")!

guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: args[1]) as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fatalError("cannot read \(args[1])") }
let w = image.width, h = image.height
var px = [UInt8](repeating: 0, count: w * h * 4)
CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))

var x0 = w, y0 = h, x1 = -1, y1 = -1, count = 0
for y in 0..<h {
    for x in 0..<w {
        let i = (y * w + x) * 4
        let r = Int(px[i]), g = Int(px[i + 1]), b = Int(px[i + 2])
        if g > minG && r < maxRB && b < maxRB {
            count += 1
            x0 = min(x0, x); x1 = max(x1, x); y0 = min(y0, y); y1 = max(y1, y)
        }
    }
}
guard count > 0 else { fatalError("no green pixels in \(args[1]); loosen --min-g or --max-rb") }
let bw = x1 - x0 + 1, bh = y1 - y0 + 1
print("\(args[1]) \(w)x\(h)")
print("box \(x0),\(y0)..\(x1),\(y1) centre \((x0 + x1) / 2),\((y0 + y1) / 2) w \(bw) h \(bh) px \(count)")
// A filled circle covers pi/4 of its box; far less means the box caught stray green.
let fill = Double(count) / Double(bw * bh)
print(String(format: "fill %.2f of the box (a clean circle is about 0.79, a rectangle 1.00)", fill))
