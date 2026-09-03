//
//  MetalBackgroundView.swift
//  ColorMorph
//
//  Created by Stephano Portella on 22/07/25.
//

import SwiftUI
import MetalKit

/// Dibuja el campo de color animado con un fragment shader a pantalla completa.
/// Los `parameters` que recibe se envían al shader en cada frame.
struct MetalBackgroundView: UIViewRepresentable {

    var parameters: ColorFieldParameters

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        guard let device = MTLCreateSystemDefaultDevice() else {
            // Sin Metal no hay nada que dibujar; se devuelve la vista en negro.
            return view
        }

        view.device = device
        view.clearColor = MTLClearColorMake(0, 0, 0, 1)
        view.colorPixelFormat = .bgra8Unorm
        view.delegate = context.coordinator
        view.preferredFramesPerSecond = 60
        view.isPaused = false
        view.enableSetNeedsDisplay = false

        context.coordinator.configure(device: device)
        context.coordinator.parameters = parameters
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.parameters = parameters
    }

    final class Coordinator: NSObject, MTKViewDelegate {

        var parameters = ColorFieldParameters.default

        private var commandQueue: MTLCommandQueue?
        private var pipelineState: MTLRenderPipelineState?
        private var elapsed: Double = 0

        func configure(device: MTLDevice) {
            commandQueue = device.makeCommandQueue()

            guard let library = device.makeDefaultLibrary(),
                  let vertexFunction = library.makeFunction(name: "vertexShader"),
                  let fragmentFunction = library.makeFunction(name: "animatedBackground") else {
                assertionFailure("No se encontraron las funciones del shader")
                return
            }

            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            } catch {
                assertionFailure("No se pudo crear el pipeline de Metal: \(error)")
            }
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let pipelineState,
                  let commandQueue,
                  let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }

            elapsed += 1 / Double(view.preferredFramesPerSecond)

            encoder.setRenderPipelineState(pipelineState)

            var resolution = SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height))
            var time = Float(elapsed)
            var fields = parameters.clamped().shaderFields

            encoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.stride, index: 0)
            encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.stride, index: 1)
            encoder.setFragmentBytes(&fields, length: MemoryLayout<ColorFieldParameters.ShaderFields>.stride, index: 2)

            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            encoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
