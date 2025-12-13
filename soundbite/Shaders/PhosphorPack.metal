//
//  PhosphorPack.metal
//  soundbite
//
//  Created by Malachi Frazier on 12/13/25.
//

#include <metal_stdlib>
using namespace metal;
#include "ShaderHelpers.h"

// Rotation helper - rotates vector v around axis defined by angle i
inline float3 rotateAxis(float3 v, float i, float time) {
    float e = time * 0.4;
    float3 a = normalize(cos(float3(2.0 * i, 2.0, 0.0) + e - time * 0.05));
    return a * dot(a, v) - cross(a, v);
}

half4 _phosphorTunnelReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    int count = int(fftCount);
    float2 uv = normalizeUV(pos, size);

    // Initialize ray direction
    float3 r = normalize(float3(uv, 1.0));

    // Constant rotation speed
    r = rotateAxis(r, 2.0, time);

    float4 O = float4(0.0);
    float t = 0.0;

    // Raymarching loop
    for (int iter = 0; iter < 30; iter++) {
        float3 p = t * r;
        p.z += 3.0;
        p = rotateAxis(p, 1.0, time);

        // Cylindrical coordinates
        float cylRadius = length(p.xy);
        float cylAngle = 6.0 * atan2(p.y, p.x);
        p.xy = float2(cylRadius, cylAngle);

        // Distortions from triangle waves
        for (float s = 1.0; s <= 4.0; s += 1.0) {
            p.yz += asin(sin(p.zy * s)) / s;
        }

        // Grid pattern
        float e = time * 0.4;
        float sx = fmod(p.x + e, 4.0) - 2.0;
        float v = min(
            length(float2(sx, fmod(p.z + e, 0.8) - 0.4)),
            2.0 * length(float2(sx, fmod(p.y, 0.2) - 0.1))
        );

        // Get FFT value based on angle (like VoidPack)
        float angle = atan2(abs(uv.y), uv.x);
        float normalizedAngle = angle / 3.14159;
        int fftIndex = int(normalizedAngle * float(count));
        fftIndex = clamp(fftIndex, 0, count - 1);

        float rawSignal = fft[fftIndex] * 1.3;
        float intensity = pow(max(0.0, rawSignal), 2.0);

        // Color mixing like VoidPack
        half3 primaryColor = half3(primary);
        half3 midColor = half3((primary + secondary) / 2.0);
        half3 secondaryColor = half3(secondary);

        float t1 = smoothstep(0.6, 0.6, intensity);
        half3 currentBase = mix(primaryColor, midColor, t1);

        float t2 = smoothstep(0.6, 1.2, intensity);
        half3 finalColor = mix(currentBase, secondaryColor, t2);

        // Boost brightness and add glow based on intensity
        finalColor *= (1.0 + intensity * 2.0);

        // Accumulate color (divide by distance for glow effect)
        O += float4(float3(finalColor) / max(v, 0.01), 1.0);

        t += v * 0.4;
    }

    // Brighter tone mapping
    O = tanh(O / 150.0);

    // Ensure minimum brightness
    O.rgb = max(O.rgb, float3(0.02));

    return half4(half3(O.rgb), 1.0);
}

[[ stitchable ]] half4 phosphorTunnelReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    return _phosphorTunnelReactive(pos, color, primary, secondary, time, size, fft, fftCount);
}

[[ kernel ]] void exportablePhosphorTunnelReactive(
    texture2d<half, access::write> outTexture [[texture(0)]],
    constant float3 &primary [[buffer(0)]],
    constant float3 &secondary [[buffer(1)]],
    constant float &time [[buffer(2)]],
    constant float2 &size [[buffer(3)]],
    device const float *fft [[buffer(4)]],
    constant int &fftCount [[buffer(5)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    float2 pos = float2(gid);
    half4 color = _phosphorTunnelReactive(pos, half4(0), primary, secondary, time, size, fft, fftCount);
    outTexture.write(color, gid);
}
