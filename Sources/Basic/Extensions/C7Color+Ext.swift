//
//  C7Color+Ext.swift
//  Harbeth
//
//  Created by Condy on 2022/10/10.
//

import Foundation
import CoreImage

extension C7Color: HarbethCompatible {
    /// Empty color, Dooo default. cannot get rgba.
    public static let zero = C7Color.init(white: 0, alpha: 0)
    /// Random color
    public static let random = {
        C7Color(hue: CGFloat(arc4random() % 256 / 256),
                saturation: CGFloat(arc4random() % 128 / 256) + 0.5,
                brightness: CGFloat(arc4random() % 128 / 256) + 0.5,
                alpha: 1.0)
    }()
    
    public convenience init(hex: Int) {
        let components = PixelColor(hex: hex).components
        self.init(red: components[0], green: components[1], blue: components[2], alpha: components[3])
    }
    
    public convenience init(hex: String) {
        let components = PixelColor(hex: hex).components
        self.init(red: components[0], green: components[1], blue: components[2], alpha: components[3])
    }
}

extension HarbethWrapper where Base: C7Color {
    
    /// Convert pixel color value
    public func toPixelColor() -> PixelColor {
        PixelColor(color: base)
    }
    
    public func toCIColor() -> CIColor {
        let (r, g, b, a) = base.c7.toRGBA()
        return CIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
    }
    
    public func toRGBA() -> (red: Float, green: Float, blue: Float, alpha: Float) {
        if base == C7Color.zero { return (0,0,0,0) }
        let color = base.c7.usingColorSpace_sRGB()
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Float(r), Float(g), Float(b), Float(a))
    }
    
    /// Convert RGBA value, transparent color does not do processing
    public func toRGBA(red: inout Float, green: inout Float, blue: inout Float, alpha: inout Float) {
        if base == C7Color.zero { return }
        (red, green, blue, alpha) = base.c7.toRGBA()
    }
    
    /// RGB to YUV.
    /// - See: https://en.wikipedia.org/wiki/YUV
    public var yuv: (y: Float, u: Float, v: Float) {
        if base == C7Color.zero { return (0,0,0) }
        let (r, g, b, _) = base.c7.toRGBA()
        let y = 0.212600 * r + 0.71520 * g + 0.07220 * b
        let u = -0.09991 * r - 0.33609 * g + 0.43600 * b
        let v = 0.615000 * r - 0.55861 * g - 0.05639 * b
        return (Float(y), Float(u), Float(v))
    }
    
    public func linearInterpolation(directionColor: C7Color, rate: Float) -> C7Color {
        let rate = min(1, max(0, rate))
        let (fR, fG, fB, fA) = base.c7.toRGBA()
        let (tR, tG, tB, tA) = directionColor.c7.toRGBA()
        let dR = CGFloat((tR-fR) * rate + fR) / 255.0
        let dG = CGFloat((tG-fG) * rate + fR) / 255.0
        let dB = CGFloat((tB-fB) * rate + fR) / 255.0
        let dA = CGFloat((tA-fA) * rate + fA)
        return C7Color.init(red: dR, green: dG, blue: dB, alpha: dA)
    }
    
    /// Fixed `*** -getRed:green:blue:alpha: not valid for the NSColor Generic Gray Gamma 2.2 Profile colorspace 1 1;
    /// Need to first convert colorspace.
    /// See: https://stackoverflow.com/questions/67314642/color-not-valid-for-the-nscolor-generic-gray-gamma-when-creating-sktexture-fro
    /// - Returns: Color.
    func usingColorSpace_sRGB() -> C7Color {
        #if os(macOS)
        return base.usingColorSpace(.sRGB) ?? base
        #else
        return base
        #endif
    }
    
    /// Solid color image.
    /// - Parameter size: Image size.
    /// - Returns: C7Image.
    public func colorImage(with size: CGSize = .onePixel) -> C7Image? {
        #if HARBETH_COMPUTE_LIBRARY_IN_BUNDLE
        let texture = try? TextureLoader.emptyTexture(at: size)
        let filter = C7SolidColor(color: base)
        let dest = BoxxIO(element: texture, filter: filter)
        let image = (try? dest.output())?.c7.toImage()
        return image
        #else
        return nil
        #endif
    }
}
