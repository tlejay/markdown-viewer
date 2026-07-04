#!/usr/bin/env swift
// Generates an .iconset folder of PNGs for the app icon, drawn entirely in
// code (no image assets to ship). build.sh turns the folder into AppIcon.icns
// via `iconutil`.
//
// Style: madebytle.com — a near-black rounded tile with a soft emerald glow and
// a single emerald "M" glyph (the site's signature accent #34D399). The letter
// is taken from the real system-font glyph outline so it is optically centered
// and filled with a subtle emerald gradient.
import AppKit
import CoreText

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <output.iconset dir>\n".utf8))
    exit(1)
}
let outDir = args[1]
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

// madebytle.com palette.
let emerald = NSColor(srgbRed: 0.204, green: 0.827, blue: 0.600, alpha: 1) // #34D399
let emeraldDeep = NSColor(srgbRed: 0.063, green: 0.725, blue: 0.506, alpha: 1) // #10B981
let tileTop = NSColor(srgbRed: 0.075, green: 0.098, blue: 0.090, alpha: 1) // faint green-black
let tileBottom = NSColor(srgbRed: 0.020, green: 0.020, blue: 0.020, alpha: 1) // #050505

/// Tight outline of the "M" glyph from a heavy system font.
func mGlyphPath(pointSize: CGFloat) -> (path: CGPath, bounds: CGRect)? {
    let font = CTFontCreateWithName("SFPro-Heavy" as CFString, pointSize, nil)
        .glyphFallback(system: pointSize)
    var chars: [UniChar] = Array("M".utf16)
    var glyphs = [CGGlyph](repeating: 0, count: chars.count)
    guard CTFontGetGlyphsForCharacters(font, &chars, &glyphs, chars.count),
          let path = CTFontCreatePathForGlyph(font, glyphs[0], nil)
    else { return nil }
    return (path, path.boundingBoxOfPath)
}

extension CTFont {
    // If a named face is unavailable, fall back to the heavy system font.
    func glyphFallback(system pointSize: CGFloat) -> CTFont {
        let count = CTFontGetGlyphCount(self)
        if count > 0 { return self }
        return NSFont.systemFont(ofSize: pointSize, weight: .black) as CTFont
    }
}

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { image.unlockFocus(); return image }

    let inset = size * 0.06
    let rect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = size * 0.2237 // macOS squircle-ish corner
    let tile = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    ctx.saveGState()
    tile.addClip()

    // Dark tile gradient.
    NSGradient(colors: [tileTop, tileBottom])?.draw(in: rect, angle: -90)

    // Soft emerald glow behind the letter.
    let glow = NSGradient(colors: [
        emerald.withAlphaComponent(0.22),
        emerald.withAlphaComponent(0.0),
    ])
    glow?.draw(fromCenter: CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.04),
               radius: 0,
               toCenter: CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.04),
               radius: rect.width * 0.55,
               options: [])

    // The "M" glyph, gradient-filled and centered on its own tight bounds.
    if let (glyph, gBounds) = mGlyphPath(pointSize: rect.height * 0.86), gBounds.width > 0 {
        let targetH = rect.height * 0.52
        let scale = targetH / gBounds.height
        let scaledW = gBounds.width * scale
        let tx = rect.midX - (gBounds.midX * scale)
        let ty = rect.midY - (gBounds.midY * scale)

        ctx.saveGState()
        ctx.translateBy(x: tx, y: ty)
        ctx.scaleBy(x: scale, y: scale)
        ctx.addPath(glyph)
        ctx.clip()
        // Draw the emerald gradient within the glyph's (unscaled) bounds.
        let fillRect = gBounds.insetBy(dx: -gBounds.width, dy: -gBounds.height)
        NSGradient(colors: [emerald, emeraldDeep])?.draw(in: fillRect, angle: -90)
        ctx.restoreGState()
        _ = scaledW
    }

    ctx.restoreGState()
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
