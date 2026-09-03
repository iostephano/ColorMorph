//
//  ColorFieldParametersTests.swift
//  ColorMorphTests
//
//  Created by Stephano Portella on 03/09/26.
//

import Testing
import simd
@testable import ColorMorph

struct ColorFieldParametersTests {

    private let epsilon: Float = 0.0001

    // MARK: - clamped()

    @Test("Values already within range are left untouched")
    func clampedLeavesValidValues() {
        let params = ColorFieldParameters(frequency: 5, speed: 1, brightness: 1, tint: SIMD3(0.8, 0.4, 1.2))
        #expect(params.clamped() == params)
    }

    @Test("Out-of-range values are pulled back to the nearest bound")
    func clampedPullsValuesIntoRange() {
        let params = ColorFieldParameters(
            frequency: 999, speed: -3, brightness: 10, tint: SIMD3(-1, 5, 0.5)
        )
        let clamped = params.clamped()
        #expect(clamped.frequency == ColorFieldParameters.frequencyRange.upperBound)
        #expect(clamped.speed == ColorFieldParameters.speedRange.lowerBound)
        #expect(clamped.brightness == ColorFieldParameters.brightnessRange.upperBound)
        #expect(clamped.tint.x == ColorFieldParameters.tintRange.lowerBound)
        #expect(clamped.tint.y == ColorFieldParameters.tintRange.upperBound)
        #expect(clamped.tint.z == 0.5)
    }

    // MARK: - presets

    @Test("Every preset is already within the valid ranges", arguments: ColorFieldParameters.presets.map(\.name))
    func presetsAreValid(name: String) {
        let preset = ColorFieldParameters.presets.first { $0.name == name }!
        #expect(preset.parameters.clamped() == preset.parameters)
    }

    @Test("The default is the first preset")
    func defaultIsFirstPreset() {
        #expect(ColorFieldParameters.default == ColorFieldParameters.presets[0].parameters)
    }

    @Test("Preset names are unique")
    func presetNamesAreUnique() {
        let names = ColorFieldParameters.presets.map(\.name)
        #expect(Set(names).count == names.count)
    }

    // MARK: - lerp

    private let a = ColorFieldParameters(frequency: 2, speed: 0, brightness: 0.5, tint: SIMD3(0, 0, 0))
    private let b = ColorFieldParameters(frequency: 10, speed: 2, brightness: 1.5, tint: SIMD3(1, 2, 0.5))

    @Test("Interpolating at 0 returns the start and at 1 returns the end")
    func lerpEndpoints() {
        #expect(ColorFieldParameters.lerp(a, b, 0) == a)
        #expect(ColorFieldParameters.lerp(a, b, 1) == b)
    }

    @Test("Interpolating at one half lands on the midpoint, component by component")
    func lerpMidpoint() {
        let mid = ColorFieldParameters.lerp(a, b, 0.5)
        #expect(abs(mid.frequency - 6) < epsilon)
        #expect(abs(mid.speed - 1) < epsilon)
        #expect(abs(mid.brightness - 1) < epsilon)
        #expect(abs(mid.tint.x - 0.5) < epsilon)
        #expect(abs(mid.tint.y - 1) < epsilon)
        #expect(abs(mid.tint.z - 0.25) < epsilon)
    }

    @Test("The interpolation factor is clamped to 0...1")
    func lerpClampsFactor() {
        #expect(ColorFieldParameters.lerp(a, b, -2) == a)
        #expect(ColorFieldParameters.lerp(a, b, 3) == b)
    }

    // MARK: - shaderFields

    @Test("The flat shader layout mirrors the parameters")
    func shaderFieldsMirrorParameters() {
        let params = ColorFieldParameters(frequency: 7, speed: 1.5, brightness: 0.9, tint: SIMD3(1.1, 0.2, 1.4))
        let fields = params.shaderFields
        #expect(fields.frequency == 7)
        #expect(fields.speed == 1.5)
        #expect(fields.brightness == 0.9)
        #expect(fields.tintR == 1.1)
        #expect(fields.tintG == 0.2)
        #expect(fields.tintB == 1.4)
        // Seis Float contiguos, sin relleno: lo que espera el shader.
        #expect(MemoryLayout<ColorFieldParameters.ShaderFields>.stride == MemoryLayout<Float>.stride * 6)
    }
}
