#!/usr/bin/env swift
// Generates an .iconset folder of PNGs for the app icon, drawn entirely in
// code (no image assets to ship). build.sh turns the folder into AppIcon.icns
// via `iconutil`. Style: a rounded slate tile with the classic Markdown
// "M▼" mark in white.
import AppKit

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <output.iconset dir>\n".utf8))
    exit(1)
}
let outDir = args[1]
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { image.unlockFocus(); return image }

    let inset = size * 0.06
    let rect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = size * 0.22
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    // Background gradient (slate → indigo).
    path.addClip()
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.13, green: 0.15, blue: 0.22, alpha: 1),
        NSColor(calibratedRed: 0.20, green: 0.24, blue: 0.42, alpha: 1)
    ])
    gradient?.draw(in: rect, angle: -90)

    // Markdown mark: "M" with a downward triangle, drawn as a bordered badge.
    let badgeInset = size * 0.20
    let badge = CGRect(x: rect.minX + badgeInset,
                       y: rect.minY + badgeInset * 1.15,
                       width: rect.width - badgeInset * 2,
                       height: rect.height - badgeInset * 2.3)
    let stroke = size * 0.05
    let badgePath = NSBezierPath(roundedRect: badge, xRadius: size * 0.06, yRadius: size * 0.06)
    badgePath.lineWidth = stroke
    NSColor.white.setStroke()
    badgePath.stroke()

    ctx.setFillColor(NSColor.white.cgColor)

    // Two "M" legs.
    let legW = badge.width * 0.13
    let gap = badge.width * 0.14
    let mTop = badge.maxY - badge.height * 0.24
    let mBottom = badge.minY + badge.height * 0.30
    let leftX = badge.minX + badge.width * 0.16

    // Left leg
    ctx.fill(CGRect(x: leftX, y: mBottom, width: legW, height: mTop - mBottom))
    // Middle valley leg
    ctx.fill(CGRect(x: leftX + legW + gap, y: mBottom, width: legW, height: mTop - mBottom))
    // Top connector between the two legs
    ctx.fill(CGRect(x: leftX, y: mTop - legW, width: legW * 2 + gap, height: legW))

    // Down arrow on the right.
    let arrowX = badge.maxX - badge.width * 0.26
    let arrowW = badge.width * 0.20
    let shaftW = arrowW * 0.34
    let arrowTop = mTop
    let headH = badge.height * 0.20
    let shaftBottom = mBottom + headH
    // shaft
    ctx.fill(CGRect(x: arrowX + (arrowW - shaftW) / 2, y: shaftBottom, width: shaftW, height: arrowTop - shaftBottom))
    // head (triangle)
    ctx.move(to: CGPoint(x: arrowX, y: shaftBottom + headH * 0.1))
    ctx.addLine(to: CGPoint(x: arrowX + arrowW, y: shaftBottom + headH * 0.1))
    ctx.addLine(to: CGPoint(x: arrowX + arrowW / 2, y: mBottom))
    ctx.closePath()
    ctx.fillPath()

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, pixels: Int, to path: String) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    if let data = rep.representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: path))
    }
}

// iconutil expects these exact filenames.
let specs: [(name: String, px: Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]

for spec in specs {
    let img = drawIcon(size: CGFloat(spec.px))
    writePNG(img, pixels: spec.px, to: "\(outDir)/\(spec.name)")
}
print("Wrote \(specs.count) icon PNGs to \(outDir)")
