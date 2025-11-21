//
//  TestShader.metal
//  soundbite
//
//  Created by Malachi Frazier on 11/18/25.
//

#include <metal_stdlib>
using namespace metal;

float2 normalizeUV(float2 position, float2 size) {
    float2 uv = position / size;
    
    uv = (uv * 2) - 1;
    
    // fix aspect ratio
    uv.x *= size.x/size.y;
    
    return uv;
}


[[ stitchable ]] half4 horizontalLinesInVoid(float2 pos, half4 color, float time, float2 size) {
    
    float2 uv = normalizeUV(pos, size);
    
    float depth = 1.0 / (abs(uv.y) + 0.01);
        
    float wave = sin(depth * 30.0 + time * 20.0);
    
    float lines = step(0.3, wave);
    
    if (abs(uv.y) < 0.12) {
        lines = 0.0;
    }
    
    return half4(0, 0, lines, 1.0);

}

[[ stitchable ]] half4 horizontalLinesInVoidReactive(float2 pos, half4 color, float time, float2 size, device const float *fft, int fftCount) {
    
    int count = int(fftCount);
    float2 uv = normalizeUV(pos, size);
    
    float perspectiveX = uv.x / (abs(uv.y) + 0.15);
    
    int index = int(abs(perspectiveX) * float(count) * 0.5);
    index = clamp(index, 0, count - 1);
    
    float rawSignal = fft[index] * 1;
    
    float intensity = pow(max(0.0, rawSignal), 2.0);
    
    // Colors
    half3 originalBlue = half3(0.0, 0.0, 1.0);
    half3 midCyan = half3(0.5, 0.2, 1.0);
    half3 peakRed = half3(1.0, 0.6, 1.0);
    

    float t1 = smoothstep(0.6, 0.6, intensity);
    half3 currentBase = mix(originalBlue, midCyan, t1);
    
    // Stage 2: Cyan to Red (starts at 0.5 intensity)
    float t2 = smoothstep(0.6, 1.2, intensity);
    half3 finalColor = mix(currentBase, peakRed, t2);
    

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



[[ stitchable ]] half4 diamondsInVoid(float2 pos, half4 color, float time, float2 size) {
    
    float2 uv = normalizeUV(pos, size);
    
    float depth = 1.0 / (abs(uv.y) + abs(uv.x)+ 0.01);
        
    float circles = ((pos.x * pos.x) + (pos.y * pos.y)) * sin(depth * 40 + time * 20);
    
    if (1.0 / (abs(uv.y) + abs(uv.x) + 0.01) > 1 / 0.16) {
        circles = 0.0;
    }
    
    return half4(0, 0, circles, 1.0);

}


[[ stitchable ]] half4 circlesInVoid(float2 pos, half4 color, float time, float2 size) {
    
    float2 uv = normalizeUV(pos, size);
    
    float depth = 1.0 / (length(uv) + 0.01);
        
    float circles = ((pos.x * pos.x) + (pos.y * pos.y)) * sin(depth * 40 + time * 20);
    
    if (1.0 / (length(uv)+ 0.01) > 1 / 0.16) {
        circles = 0.0;
    }
    
    return half4(0, 0, circles, 1.0);

}
                                
                                  


