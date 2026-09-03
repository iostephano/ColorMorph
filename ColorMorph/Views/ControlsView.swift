//
//  ControlsView.swift
//  ColorMorph
//
//  Created by Stephano Portella on 03/09/26.
//

import SwiftUI

/// Panel para ajustar el campo de color en vivo: una fila de presets y tres
/// sliders.
struct ControlsView: View {

    @Binding var parameters: ColorFieldParameters

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(ColorFieldParameters.presets, id: \.name) { preset in
                    Button(preset.name) {
                        parameters = preset.parameters
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.15), in: .capsule)
                }
            }

            slider("Velocidad", value: $parameters.speed, range: ColorFieldParameters.speedRange)
            slider("Frecuencia", value: $parameters.frequency, range: ColorFieldParameters.frequencyRange)
            slider("Brillo", value: $parameters.brightness, range: ColorFieldParameters.brightnessRange)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 24))
        .padding(16)
    }

    private func slider(_ title: String, value: Binding<Float>, range: ClosedRange<Float>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            Slider(value: value, in: range)
                .tint(.white)
        }
    }
}
