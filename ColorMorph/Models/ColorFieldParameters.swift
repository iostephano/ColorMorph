//
//  ColorFieldParameters.swift
//  ColorMorph
//
//  Created by Stephano Portella on 03/09/26.
//

import simd

/// Los ajustes que controlan el campo de color animado. Es un tipo de valor
/// puro: la UI lo edita y `MetalBackgroundView` lo pasa al fragment shader. No
/// depende de Metal ni de SwiftUI.
struct ColorFieldParameters: Equatable, Sendable {

    /// Densidad del patrón (a más frecuencia, más "franjas" de color).
    var frequency: Float

    /// Rapidez de la animación. 0 la congela.
    var speed: Float

    /// Multiplicador global de luminosidad.
    var brightness: Float

    /// Multiplicador de color por canal (RGB). `1,1,1` no tiñe.
    var tint: SIMD3<Float>

    static let frequencyRange: ClosedRange<Float> = 1...12
    static let speedRange: ClosedRange<Float> = 0...3
    static let brightnessRange: ClosedRange<Float> = 0.2...1.6
    static let tintRange: ClosedRange<Float> = 0...2

    /// Copia con todos los campos recortados a su rango válido.
    func clamped() -> ColorFieldParameters {
        ColorFieldParameters(
            frequency: frequency.clamped(to: Self.frequencyRange),
            speed: speed.clamped(to: Self.speedRange),
            brightness: brightness.clamped(to: Self.brightnessRange),
            tint: SIMD3(
                tint.x.clamped(to: Self.tintRange),
                tint.y.clamped(to: Self.tintRange),
                tint.z.clamped(to: Self.tintRange)
            )
        )
    }

    /// Interpolación lineal entre `a` y `b`. `t` se recorta a 0...1. Sirve para
    /// animar la transición entre dos presets.
    static func lerp(_ a: ColorFieldParameters, _ b: ColorFieldParameters, _ t: Float) -> ColorFieldParameters {
        let t = t.clamped(to: 0...1)
        return ColorFieldParameters(
            frequency: a.frequency + (b.frequency - a.frequency) * t,
            speed: a.speed + (b.speed - a.speed) * t,
            brightness: a.brightness + (b.brightness - a.brightness) * t,
            tint: a.tint + (b.tint - a.tint) * t
        )
    }
}

extension ColorFieldParameters {

    struct Preset: Sendable {
        let name: String
        let parameters: ColorFieldParameters
    }

    /// Presets ordenados; `presets[0]` es el que se ve al abrir la app y
    /// reproduce el aspecto original (las "llamas oscuras" del shader).
    static let presets: [Preset] = [
        Preset(name: "Llamas", parameters: ColorFieldParameters(
            frequency: 5, speed: 1, brightness: 1, tint: SIMD3(0.8, 0.4, 1.2))),
        Preset(name: "Aurora", parameters: ColorFieldParameters(
            frequency: 3, speed: 0.5, brightness: 1.15, tint: SIMD3(0.4, 1.3, 0.9))),
        Preset(name: "Océano", parameters: ColorFieldParameters(
            frequency: 4, speed: 0.7, brightness: 0.95, tint: SIMD3(0.25, 0.7, 1.4))),
        Preset(name: "Neón", parameters: ColorFieldParameters(
            frequency: 9, speed: 2.2, brightness: 1.3, tint: SIMD3(1.6, 0.3, 1.5)))
    ]

    static let `default` = presets[0].parameters

    /// Disposición plana que se envía al fragment shader; coincide campo por
    /// campo con `ColorFieldParams` en `AnimatedBackground.metal`.
    struct ShaderFields {
        var frequency: Float
        var speed: Float
        var brightness: Float
        var tintR: Float
        var tintG: Float
        var tintB: Float
    }

    var shaderFields: ShaderFields {
        ShaderFields(
            frequency: frequency,
            speed: speed,
            brightness: brightness,
            tintR: tint.x,
            tintG: tint.y,
            tintB: tint.z
        )
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
