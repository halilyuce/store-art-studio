// usage: swift screenswap.swift photo.png ui.png out.png
// photo: generated hand+phone with a flat #00FF00 screen. ui: rendered 1320x2868 screen PNG (rounded corners baked in).
import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO
import Vision

let a = CommandLine.arguments
func load(_ p: String) -> CGImage { CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(URL(fileURLWithPath: p) as CFURL, nil)!, 0, nil)! }
let src = load(a[1]); let ui = CIImage(cgImage: load(a[2]))
let w = src.width, h = src.height, cs = CGColorSpace(name: CGColorSpace.sRGB)!
var px = [UInt8](repeating: 0, count: w*h*4), mk = [UInt8](repeating: 0, count: w*h)
CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w*4, space: cs,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!.draw(src, in: CGRect(x: 0, y: 0, width: w, height: h))

// 1. Soft key mask (green dominance) + despill so fringes lose their green cast.
for i in 0..<(w*h) {
  let r = Float(px[i*4]), g = Float(px[i*4+1]), b = Float(px[i*4+2])
  let dom = (g - max(r, b)) / 255
  let m = min(max((dom - 0.25) / 0.20, 0), 1)                 // 0.25..0.45 ramp
  mk[i] = UInt8(m * 255)
  px[i*4+1] = UInt8(min(g, max(r, b)))                          // despill
}
let mkData = CFDataCreate(nil, mk, mk.count)!
let maskCG = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: w,
                     space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0),
                     provider: CGDataProvider(data: mkData)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
let pxData = CFDataCreate(nil, px, px.count)!
let cleanCG = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w*4, space: cs,
                      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                      provider: CGDataProvider(data: pxData)!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!

// 2. Screen quad from the mask (Vision: normalized, bottom-left origin = Core Image space).
let rq = VNDetectRectanglesRequest()
rq.minimumAspectRatio = 0.2; rq.maximumAspectRatio = 1.0; rq.quadratureTolerance = 45
rq.minimumSize = 0.1; rq.minimumConfidence = 0.5; rq.maximumObservations = 1
try VNImageRequestHandler(cgImage: maskCG).perform([rq])
func p(_ n: CGPoint) -> CGPoint { CGPoint(x: n.x * CGFloat(w), y: n.y * CGFloat(h)) }
struct Quad { var topLeft, topRight, bottomRight, bottomLeft: CGPoint }
var quad: Quad
if let r = rq.results?.first {
  quad = Quad(topLeft: r.topLeft, topRight: r.topRight, bottomRight: r.bottomRight, bottomLeft: r.bottomLeft); print("vision quad")
} else {
  // Fallback: extreme points of the mask (works when no finger covers a corner). Image rows: y=0 is top.
  var tl = (Int.max, 0, 0), br = (Int.min, 0, 0), tr = (Int.min, 0, 0), bl = (Int.max, 0, 0)
  for y in 0..<h { for x in 0..<w where mk[y*w+x] > 128 {
    let s = x + y, d = x - y
    if s < tl.0 { tl = (s, x, y) }; if s > br.0 { br = (s, x, y) }
    if d > tr.0 { tr = (d, x, y) }; if d < bl.0 { bl = (d, x, y) } } }
  func n(_ t: (Int, Int, Int)) -> CGPoint { CGPoint(x: CGFloat(t.1) / CGFloat(w), y: 1 - CGFloat(t.2) / CGFloat(h)) }
  quad = Quad(topLeft: n(tl), topRight: n(tr), bottomRight: n(br), bottomLeft: n(bl)); print("extreme-point quad")
}
let q = quad
print("quad TL \(p(q.topLeft)) TR \(p(q.topRight)) BR \(p(q.bottomRight)) BL \(p(q.bottomLeft))")

// 3. Warp UI onto the quad, 4. composite through the mask so occluding fingers stay on top.
let warp = CIFilter.perspectiveTransform()
warp.inputImage = ui
warp.topLeft = p(q.topLeft); warp.topRight = p(q.topRight); warp.bottomRight = p(q.bottomRight); warp.bottomLeft = p(q.bottomLeft)
let blend = CIFilter.blendWithMask()
blend.inputImage = warp.outputImage!; blend.backgroundImage = CIImage(cgImage: cleanCG); blend.maskImage = CIImage(cgImage: maskCG)
let out = blend.outputImage!.cropped(to: CGRect(x: 0, y: 0, width: w, height: h))
try CIContext().writePNGRepresentation(of: out, to: URL(fileURLWithPath: a[3]), format: .RGBA8, colorSpace: cs)
print("ok")
