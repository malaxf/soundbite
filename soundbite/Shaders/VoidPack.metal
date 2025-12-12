//
//  VoidPack.metal
//  soundbite
//
//  Created by Malachi Frazier on 11/18/25.
//

#include <metal_stdlib>
using namespace metal;
#include "ShaderHelpers.h"





// MARK: Horizontal Lines Reactive

half4 _horizontalLinesInVoidReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    int count = int(fftCount);
    float2 uv = normalizeUV(pos, size);
    
    float perspectiveX = uv.x / (abs(uv.y) + 0.15);
    int index = int(abs(perspectiveX) * float(count) * 0.5);
    index = clamp(index, 0, count - 1);
    
    float rawSignal = fft[index] * 1;
    float intensity = pow(max(0.0, rawSignal), 2.0);
    
    half3 primaryColor = half3(primary);
    half3 midColor = half3((primary + secondary) / 2.0);
    half3 secondaryColor = half3(secondary);
    
    float t1 = smoothstep(0.6, 0.6, intensity);
    half3 currentBase = mix(primaryColor, midColor, t1);
    
    float t2 = smoothstep(0.6, 1.2, intensity);
    half3 finalColor = mix(currentBase, secondaryColor, t2);
    
    float horizonFade = smoothstep(0.00, 0.33, abs(uv.y));
    finalColor *= horizonFade;
    
    float depth = 1.0 / (abs(uv.y) + 0.01);
    float wave = sin(depth * 30.0 + time * 20.0);
    float lines = step(0.3, wave);
    
    if (abs(uv.y) < 0.12) {
        lines = 0.0;
    }
    
    return half4(finalColor * lines, 1.0);
}

[[ stitchable ]] half4 horizontalLinesInVoidReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    return _horizontalLinesInVoidReactive(pos, color, primary, secondary, time, size, fft, fftCount);
}

[[ kernel ]] void exportableHorizontalLinesInVoidReactive(
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
    half4 color = _horizontalLinesInVoidReactive(pos, half4(0), primary, secondary, time, size, fft, fftCount);
    outTexture.write(color, gid);
}





// MARK: Diamonds Reactive

half4 _diamondsInVoidReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    int count = int(fftCount);
    float2 uv = normalizeUV(pos, size);
    
    float angle = atan2(abs(uv.y), uv.x);
    float normalizedAngle = angle / 3.14159;
    
    int index = int(normalizedAngle * float(count));
    index = clamp(index, 0, count - 1);
    
    float rawSignal = fft[index] * 1.3;
    float intensity = pow(max(0.0, rawSignal), 2.0);
    
    half3 primaryColor = half3(primary);
    half3 midColor = half3((primary + secondary) / 2.0);
    half3 secondaryColor = half3(secondary);
    
    float t1 = smoothstep(0.6, 0.6, intensity);
    half3 currentBase = mix(primaryColor, midColor, t1);
    
    float t2 = smoothstep(0.6, 1.2, intensity);
    half3 finalColor = mix(currentBase, secondaryColor, t2);
    
    float diamondDistance = abs(uv.y) + abs(uv.x);
    float centerFade = smoothstep(0.00, 0.20, diamondDistance);
    finalColor *= centerFade;
    
    float depth = 1.0 / (abs(uv.y) + abs(uv.x) + 0.01);
    float wave = sin(depth * 40 + time * 20);
    float pattern = step(0.0, wave);
    
    if (1.0 / (abs(uv.y) + abs(uv.x) + 0.01) > 1 / 0.16) {
        pattern = 0.0;
    }
    
    return half4(finalColor * pattern, 1.0);
}

[[ stitchable ]] half4 diamondsInVoidReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    return _diamondsInVoidReactive(pos, color, primary, secondary, time, size, fft, fftCount);
}

[[ kernel ]] void exportableDiamondsInVoidReactive(
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
    half4 color = _diamondsInVoidReactive(pos, half4(0), primary, secondary, time, size, fft, fftCount);
    outTexture.write(color, gid);
}





// MARK: Circles Reactive

half4 _circlesInVoidReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    int count = int(fftCount);
    float2 uv = normalizeUV(pos, size);
    float distanceFromCenter = length(uv);
    
    int index = int(distanceFromCenter * float(count) * 0.8);
    index = (count - 1) - clamp(index, 0, count - 1);
    
    float rawSignal = fft[index] * 1.3;
    float intensity = pow(max(0.0, rawSignal), 2.0);
    
    half3 primaryColor = half3(primary);
    half3 midColor = half3((primary + secondary) / 2.0);
    half3 secondaryColor = half3(secondary);
    
    float t1 = smoothstep(0.6, 0.6, intensity);
    half3 currentBase = mix(primaryColor, midColor, t1);
    
    float t2 = smoothstep(0.6, 1.2, intensity);
    half3 finalColor = mix(currentBase, secondaryColor, t2);
    
    float centerFade = smoothstep(0.00, 0.20, distanceFromCenter);
    finalColor *= centerFade;
    
    float depth = 1.0 / (length(uv) + 0.01);
    float wave = sin(depth * 40 + time * 20);
    float pattern = step(0.0, wave);
    
    if (1.0 / (length(uv) + 0.01) > 1 / 0.1) {
        pattern = 0.0;
    }
    
    return half4(finalColor * pattern, 1.0);
}

[[ stitchable ]] half4 circlesInVoidReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    return _circlesInVoidReactive(pos, color, primary, secondary, time, size, fft, fftCount);
}

[[ kernel ]] void exportableCirclesInVoidReactive(
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
    half4 color = _circlesInVoidReactive(pos, half4(0), primary, secondary, time, size, fft, fftCount);
    outTexture.write(color, gid);
}
