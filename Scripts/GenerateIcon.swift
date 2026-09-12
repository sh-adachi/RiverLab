import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Code-native identity: a spade crossed by a rising probability curve.
// Run from the project root:
// swift -module-cache-path .build/icon-module-cache Scripts/GenerateIcon.swift
let size = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [red, green, blue, 1])!
}

let background = CGGradient(colorsSpace: colorSpace, colors: [
    color(0.040, 0.125, 0.111),
    color(0.080, 0.223, 0.183)
] as CFArray, locations: [0, 1])!
context.drawLinearGradient(background, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 1024, y: 1024), options: [])

// Subtle contour rings evoke the felt table without introducing fine detail.
context.setStrokeColor(color(0.125, 0.290, 0.235))
context.setLineWidth(2)
for inset in [92.0, 134.0] {
    context.strokeEllipse(in: CGRect(x: inset, y: inset, width: 1024 - 2 * inset, height: 1024 - 2 * inset))
}

let spade = CGMutablePath()
spade.move(to: CGPoint(x: 512, y: 806))
spade.addCurve(to: CGPoint(x: 271, y: 569), control1: CGPoint(x: 469, y: 735), control2: CGPoint(x: 335, y: 649))
spade.addCurve(to: CGPoint(x: 344, y: 323), control1: CGPoint(x: 175, y: 448), control2: CGPoint(x: 233, y: 320))
spade.addCurve(to: CGPoint(x: 482, y: 382), control1: CGPoint(x: 402, y: 323), control2: CGPoint(x: 443, y: 347))
spade.addCurve(to: CGPoint(x: 428, y: 235), control1: CGPoint(x: 478, y: 319), control2: CGPoint(x: 462, y: 274))
spade.addLine(to: CGPoint(x: 596, y: 235))
spade.addCurve(to: CGPoint(x: 542, y: 382), control1: CGPoint(x: 562, y: 274), control2: CGPoint(x: 546, y: 319))
spade.addCurve(to: CGPoint(x: 680, y: 323), control1: CGPoint(x: 581, y: 347), control2: CGPoint(x: 622, y: 323))
spade.addCurve(to: CGPoint(x: 753, y: 569), control1: CGPoint(x: 791, y: 320), control2: CGPoint(x: 849, y: 448))
spade.addCurve(to: CGPoint(x: 512, y: 806), control1: CGPoint(x: 689, y: 649), control2: CGPoint(x: 555, y: 735))
spade.closeSubpath()
context.setFillColor(color(0.793, 0.889, 0.719))
context.addPath(spade)
context.fillPath()

let curve = CGMutablePath()
curve.move(to: CGPoint(x: 276, y: 410))
curve.addCurve(to: CGPoint(x: 481, y: 486), control1: CGPoint(x: 353, y: 414), control2: CGPoint(x: 409, y: 443))
curve.addCurve(to: CGPoint(x: 728, y: 654), control1: CGPoint(x: 568, y: 536), control2: CGPoint(x: 641, y: 627))
context.setStrokeColor(color(0.044, 0.158, 0.126))
context.setLineCap(.round)
context.setLineJoin(.round)
context.setLineWidth(34)
context.addPath(curve)
context.strokePath()
for point in [CGPoint(x: 350, y: 423), CGPoint(x: 512, y: 506), CGPoint(x: 683, y: 630)] {
    context.setFillColor(color(0.044, 0.158, 0.126))
    context.fillEllipse(in: CGRect(x: point.x - 27, y: point.y - 27, width: 54, height: 54))
    context.setFillColor(color(0.793, 0.889, 0.719))
    context.fillEllipse(in: CGRect(x: point.x - 10, y: point.y - 10, width: 20, height: 20))
}

let output = URL(fileURLWithPath: "App/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination), "Failed to save app icon")
print(output.path)
