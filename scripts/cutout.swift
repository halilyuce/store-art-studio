// usage: swift cutout.swift in.png out.png [--crop]
import Foundation
import Vision
import CoreImage
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
let inURL = URL(fileURLWithPath: args[1]), outURL = URL(fileURLWithPath: args[2])
let crop = args.contains("--crop")
let handler = VNImageRequestHandler(url: inURL)
let request = VNGenerateForegroundInstanceMaskRequest()
try handler.perform([request])
guard let obs = request.results?.first else { fatalError("no foreground found") }
print("instances: \(obs.allInstances.count)")
let buffer = try obs.generateMaskedImage(ofInstances: obs.allInstances, from: handler, croppedToInstancesExtent: crop)
let ci = CIImage(cvPixelBuffer: buffer)
let ctx = CIContext()
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
try ctx.writePNGRepresentation(of: ci, to: outURL, format: .RGBA8, colorSpace: cs)
print("wrote \(outURL.path) \(Int(ci.extent.width))x\(Int(ci.extent.height))")
