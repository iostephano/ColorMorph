//
//  AnimatedBackground.metal
//  ColorMorph
//
//  Created by Stephano Portella on 22/07/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// Coincide campo por campo con `ColorFieldParameters.ShaderFields` en Swift.
struct ColorFieldParams {
    float frequency;
    float speed;
    float brightness;
    float tintR;
    float tintG;
    float tintB;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]]) {
    float2 pos[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };

    float2 uv[4] = {
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(0.0, 1.0),
        float2(1.0, 1.0)
    };

    VertexOut out;
    out.position = float4(pos[vertexID], 0.0, 1.0);
    out.uv = uv[vertexID];
    return out;
}

fragment float4 animatedBackground(VertexOut in [[stage_in]],
                                   constant float2& resolution [[buffer(0)]],
                                   constant float& time [[buffer(1)]],
                                   constant ColorFieldParams& params [[buffer(2)]]) {
    float2 p = in.uv - 0.5;
    p.x *= resolution.x / resolution.y;

    float t = time * params.speed;
    float r = 0.5 + 0.5 * sin(params.frequency * p.x + t);
    float g = 0.5 + 0.5 * cos(params.frequency * 0.8 * p.y - t * 0.75);
    float b = 0.5 + 0.5 * sin(params.frequency * 1.2 * (p.x + p.y) + t * 1.25);

    float3 color = float3(r, g * 0.5 + r * 0.3, b * 0.4 + r * 0.6);
    color *= float3(params.tintR, params.tintG, params.tintB) * params.brightness;

    return float4(clamp(color, 0.0, 1.0), 1.0);
}
