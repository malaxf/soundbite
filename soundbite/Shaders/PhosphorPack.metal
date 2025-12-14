//
//  PhosphorPack.metal
//  soundbite
//
//  Created by Malachi Frazier on 12/13/25.
//

#include <metal_stdlib>
using namespace metal;
#include "ShaderHelpers.h"

// Fast atan2 approximation (~5x faster than hardware atan2)
inline float fastAtan2(float y, float x) {
    float ax = abs(x), ay = abs(y);
    float mn = min(ax, ay), mx = max(ax, ay);
    float a = mn / (mx + 1e-8);
    float s = a * a;
    float r = ((-0.0464964749 * s + 0.15931422) * s - 0.327622764) * s * a + a;
    if (ay > ax) r = M_PI_2_F - r;
    if (x < 0) r = M_PI_F - r;
    if (y < 0) r = -r;
    return r;
}

// Triangle wave approximation of asin(sin(x)) - avoids expensive trig
inline float2 triWave(float2 x) {
    float2 p = x * M_1_PI_F + 0.5;
    return (abs(fract(p) - 0.5) * 4.0 - 1.0) * M_PI_2_F;
}

// Apply rotation given pre-computed axis
inline float3 applyRotation(float3 v, float3 axis) {
    return axis * dot(axis, v) - cross(axis, v);
}

// MARK: Phosphor Fabric 

half4 _phosphorFabricReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    float2 uv = normalizeUV(pos, size);
    int count = int(fftCount);

    // Pre-compute rotation axes (constant for entire frame)
    float timeOffset = time * 0.35;
    float3 axis1 = normalize(cos(float3(2.0, 2.0, 0.0) + timeOffset));
    float3 axis2 = normalize(cos(float3(4.0, 2.0, 0.0) + timeOffset));

    // Pre-compute base colors for reactivity
    half3 primaryColor = half3(primary);
    half3 secondaryColor = half3(secondary);

    // Initialize ray direction
    float3 r = normalize(float3(uv, 1.0));
    r = applyRotation(r, axis2);

    float4 O = float4(0.0);
    float marchDist = 0.0;
    float e = time * 0.4;

    // Raymarching loop
    for (int iter = 0; iter < 30; iter++) {
        float3 p = marchDist * r;
        p.z += 3.0;
        p = applyRotation(p, axis1);

        // Cylindrical coordinates (fast atan2)
        float cylRadius = length(p.xy);
        float cylAngle = 6.0 * fastAtan2(p.y, p.x);
        p.xy = float2(cylRadius, cylAngle);

        // Sample FFT based on tunnel geometry (angular position in 3D space)
        float tunnelPos = abs(fmod(cylAngle + p.z * 0.5, 2.0 * M_PI_F)) / (2.0 * M_PI_F);
        int fftIndex = clamp(int(tunnelPos * float(count)), 0, count - 1);
        float intensity = fft[fftIndex];

        // Color reacts to audio - blends primary->secondary based on intensity
        half3 localColor = mix(primaryColor, secondaryColor, half(intensity));
        localColor *= (1.0h + half(intensity) * 0.5h);

        // Distortions using triangle wave approximation
        p.yz += triWave(p.zy);
        p.yz += triWave(p.zy * 2.0) * 0.5;
        p.yz += triWave(p.zy * 3.0) * 0.333333;
        p.yz += triWave(p.zy * 4.0) * 0.25;

        // Grid pattern
        float sx = fmod(p.x + e, 4.0) - 2.0;
        float v = min(
            length(float2(sx, fmod(p.z + e, 0.8) - 0.4)),
            2.0 * length(float2(sx, fmod(p.y, 0.2) - 0.1))
        );

        // Accumulate color (divide by distance for glow effect)
        O += float4(float3(localColor) / max(v, 0.01), 1.0);

        marchDist += v * 0.4;
    }

    // Brighter tone mapping
    O = tanh(O / 150.0);

    // Ensure minimum brightness
    O.rgb = max(O.rgb, float3(0.02));

    return half4(half3(O.rgb), 1.0);
}

// MARK: Phosphor Tunnel

half4 _phosphorTunnelReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    float2 uv = normalizeUV(pos, size);

    // Pre-compute rotation axes (constant for entire frame)
    float timeOffset = time * 0.35;
    float3 axis1 = normalize(cos(float3(2.0, 2.0, 0.0) + timeOffset));
    float3 axis2 = normalize(cos(float3(4.0, 2.0, 0.0) + timeOffset));

    // Pre-compute base colors for reactivity
    half3 primaryColor = half3(primary);
    half3 secondaryColor = half3(secondary);

    // Pre-compute constants to avoid repeated calculations in loop
    float e = time * 0.4;
    float fftScale = float(fftCount) * 0.0333333; // count / 30
    int maxFftIndex = fftCount - 1;

    // Calculate bass pulse (first few FFT bins = low frequencies)
    float bassPulse = 0.0;
    int bassCount = min(8, fftCount);
    for (int i = 0; i < bassCount; i++) {
        bassPulse = max(bassPulse, fft[i]);
    }
    bassPulse = pow(bassPulse, 1.3); // Shape for punchier response

    // Initialize ray direction
    float3 r = normalize(float3(uv, 1.0));
    r = applyRotation(r, axis2);

    float4 O = float4(0.0);
    float marchDist = 0.0;

    // Raymarching loop
    for (int iter = 0; iter < 30; iter++) {
        float3 p = marchDist * r;
        p.z += 3.0;
        p = applyRotation(p, axis1);

        // Cylindrical coordinates (original atan2 for smooth curves)
        float cylRadius = length(p.xy);
        float cylAngle = 6.0 * atan2(p.y, p.x);
        p.xy = float2(cylRadius, cylAngle);

        // Distortions using original asin(sin(x)) for smooth curves
        p.yz += asin(sin(p.zy));
        p.yz += asin(sin(p.zy * 2.0)) * 0.5;
        p.yz += asin(sin(p.zy * 3.0)) * 0.333333;
        p.yz += asin(sin(p.zy * 4.0)) * 0.25;

        // Grid pattern
        float pxe = p.x + e;
        float sx = fmod(pxe, 4.0) - 2.0;
        float v = min(
            length(float2(sx, fmod(p.z + e, 0.8) - 0.4)),
            2.0 * length(float2(sx, fmod(p.y, 0.2) - 0.1))
        );

        // Combine local frequency response with global bass pulse
        int fftIndex = min(int(float(iter) * fftScale), maxFftIndex);
        float localIntensity = fft[fftIndex];
        float combinedIntensity = max(localIntensity, bassPulse * 0.6);

        // Softer brightness threshold, higher multiplier for visible reactivity
        float brightness = saturate(1.0 - v * 1.0);
        float colorShift = pow(combinedIntensity, 0.8) * brightness * 1.2;
        half3 localColor = mix(primaryColor, secondaryColor, half(colorShift));

        // Accumulate color (divide by distance for glow effect)
        float invV = 1.0 / max(v, 0.01);
        O += float4(float3(localColor) * invV, 1.0);

        marchDist += v * 0.4;

        // Early termination - distant points contribute negligibly
        if (marchDist > 20.0) break;
    }

    // Brighter tone mapping
    O *= 0.00666667; // 1/150
    O = tanh(O);

    // Ensure minimum brightness
    O.rgb = max(O.rgb, float3(0.02));

    return half4(half3(O.rgb), 1.0);
}

[[ stitchable ]] half4 phosphorTunnelReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    return _phosphorTunnelReactive(pos, color, primary, secondary, time, size, fft, fftCount);
}

[[ stitchable ]] half4 phosphorFabricReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    return _phosphorFabricReactive(pos, color, primary, secondary, time, size, fft, fftCount);
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

[[ kernel ]] void exportablePhosphorFabricReactive(
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
    half4 color = _phosphorFabricReactive(pos, half4(0), primary, secondary, time, size, fft, fftCount);
    outTexture.write(color, gid);
}
