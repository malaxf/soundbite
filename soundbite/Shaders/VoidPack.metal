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


[[ stitchable ]] half4 horizontalLinesInVoid(float2 pos, half4 color, float3 primary, float time, float2 size) {
    
    float2 uv = normalizeUV(pos, size);
    
    float depth = 1.0 / (abs(uv.y) + 0.01);
        
    float wave = sin(depth * 30.0 + time * 20.0);
    
    float lines = step(0.3, wave);
    
    if (abs(uv.y) < 0.12) {
        lines = 0.0;
    }
    
    half3 primaryColor = half3(primary);
    return half4(primaryColor * lines, 1.0);

}

[[ stitchable ]] half4 horizontalLinesInVoidReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    
    int count = int(fftCount);
    float2 uv = normalizeUV(pos, size);
    
    float perspectiveX = uv.x / (abs(uv.y) + 0.15);
    
    int index = int(abs(perspectiveX) * float(count) * 0.5);
    index = clamp(index, 0, count - 1);
    
    float rawSignal = fft[index] * 1;
    
    float intensity = pow(max(0.0, rawSignal), 2.0);
    
    // Colors from passed-in parameters
    half3 primaryColor = half3(primary);
    half3 midColor = half3((primary + secondary) / 2.0);
    half3 secondaryColor = half3(secondary);
    
    // Stage 1: Primary to Mid
    float t1 = smoothstep(0.6, 0.6, intensity);
    half3 currentBase = mix(primaryColor, midColor, t1);
    
    // Stage 2: Mid to Secondary
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



[[ stitchable ]] half4 diamondsInVoid(float2 pos, half4 color, float3 primary, float time, float2 size) {
    
    float2 uv = normalizeUV(pos, size);
    
    float depth = 1.0 / (abs(uv.y) + abs(uv.x)+ 0.01);
        
    float circles = ((pos.x * pos.x) + (pos.y * pos.y)) * sin(depth * 40 + time * 20);
    
    if (1.0 / (abs(uv.y) + abs(uv.x) + 0.01) > 1 / 0.16) {
        circles = 0.0;
    }
    
    half3 primaryColor = half3(primary);
    return half4(primaryColor * circles, 1.0);

}

// REACTIVE VERSION: Diamonds that respond to audio
[[ stitchable ]] half4 diamondsInVoidReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    
    // Step 1: Get our FFT array size
    int count = int(fftCount);
    
    // Step 2: Normalize coordinates to center-based UV space
    float2 uv = normalizeUV(pos, size);
    
    // Step 3: Calculate angle-based position for FFT mapping
    // This makes frequency bands follow the diamond's diagonal perspective lines
    // We use atan2 to get the angle from center, then normalize it
    // Using abs(uv.y) makes it vertically symmetrical about the x-axis
    float angle = atan2(abs(uv.y), uv.x);
    // Normalize angle from 0 to PI (top half only) into 0 to 1 range
    float normalizedAngle = angle / 3.14159;
    
    // Step 4: Map angle to FFT index
    // Different angles (diagonal directions) map to different frequencies
    // This creates diagonal frequency bands that follow the diamond edges
    int index = int(normalizedAngle * float(count));
    index = clamp(index, 0, count - 1);
    
    // Step 5: Sample the FFT data at this index
    float rawSignal = fft[index] * 1.3; // Boost the signal
    
    // Step 6: Convert to intensity with power curve
    // Squaring creates more dynamic range - subtle sounds stay subtle,
    // loud sounds become very bright
    float intensity = pow(max(0.0, rawSignal), 2.0);
    
    // Step 7: Use passed-in color parameters
    half3 primaryColor = half3(primary);
    half3 midColor = half3((primary + secondary) / 2.0);
    half3 secondaryColor = half3(secondary);
    
    // Step 8: Blend colors based on intensity
    // Two-stage color transition for smooth gradient
    // Stage 1: Primary to Mid
    float t1 = smoothstep(0.6, 0.6, intensity);
    half3 currentBase = mix(primaryColor, midColor, t1);
    
    // Stage 2: Mid to Secondary at higher intensities
    float t2 = smoothstep(0.6, 1.2, intensity);
    half3 finalColor = mix(currentBase, secondaryColor, t2);
    
    // Step 9: Diamond-shaped fade near the center
    // Fades from center outward in a diamond shape
    float diamondDistance = abs(uv.y) + abs(uv.x);
    float centerFade = smoothstep(0.00, 0.20, diamondDistance);
    finalColor *= centerFade;
    
    // Step 10: Calculate the original diamond pattern
    float depth = 1.0 / (abs(uv.y) + abs(uv.x) + 0.01);
    
    // Create the wave pattern - this oscillates between -1 and 1
    float wave = sin(depth * 40 + time * 20);
    
    // Use step() to create solid shapes (like the lines shader does)
    // Only show pattern where the wave is positive (above threshold)
    // This preserves the black spaces between shapes
    float pattern = step(0.0, wave);
    
    // Step 11: Cut off pattern beyond a certain distance
    // This creates the outer boundary of the diamond effect
    if (1.0 / (abs(uv.y) + abs(uv.x) + 0.01) > 1 / 0.16) {
        pattern = 0.0;
    }
    
    // Step 12: Combine everything!
    // Multiply the dynamic reactive color by the diamond pattern
    return half4(finalColor * pattern, 1.0);
}


[[ stitchable ]] half4 circlesInVoid(float2 pos, half4 color, float3 primary, float time, float2 size) {
    
    float2 uv = normalizeUV(pos, size);
    
    float depth = 1.0 / (length(uv) + 0.01);
        
    float circles = ((pos.x * pos.x) + (pos.y * pos.y)) * sin(depth * 40 + time * 20);
    
    if (1.0 / (length(uv)+ 0.01) > 1 / 0.16) {
        circles = 0.0;
    }
    
    half3 primaryColor = half3(primary);
    return half4(primaryColor * circles, 1.0);
    

}

// REACTIVE VERSION: Circles that respond to audio
[[ stitchable ]] half4 circlesInVoidReactive(float2 pos, half4 color, float3 primary, float3 secondary, float time, float2 size, device const float *fft, int fftCount) {
    
    // Step 1: Get our FFT array size
    int count = int(fftCount);
    
    // Step 2: Normalize coordinates to center-based UV space
    float2 uv = normalizeUV(pos, size);
    
    // Step 3: Calculate distance from center (for radial/circular mapping)
    // This gives us 0.0 at center, increasing outward
    float distanceFromCenter = length(uv);
    
    // Step 4: Map distance to FFT index (INVERTED)
    // Center of screen = high frequencies (treble)
    // Edge of screen = low frequencies (bass)
    // We invert by subtracting from count-1
    int index = int(distanceFromCenter * float(count) * 0.8);
    index = (count - 1) - clamp(index, 0, count - 1);
    
    // Step 5: Sample the FFT data at this index
    float rawSignal = fft[index] * 1.3; // Multiply to boost the effect
    
    // Step 6: Convert to intensity (squared for more dramatic effect)
    // pow() makes quiet sounds quieter and loud sounds louder
    float intensity = pow(max(0.0, rawSignal), 2.0);
    
    // Step 7: Use passed-in color parameters
    half3 primaryColor = half3(primary);
    half3 midColor = half3((primary + secondary) / 2.0);
    half3 secondaryColor = half3(secondary);
    
    // Step 8: Blend colors based on intensity
    // Stage 1: Primary to Mid (starts at 0.6 intensity)
    float t1 = smoothstep(0.6, 0.6, intensity);
    half3 currentBase = mix(primaryColor, midColor, t1);
    
    // Stage 2: Mid to Secondary (starts at 0.6, peaks at 1.2)
    float t2 = smoothstep(0.6, 1.2, intensity);
    half3 finalColor = mix(currentBase, secondaryColor, t2);
    
    // Step 9: Fade out near the center for aesthetic purposes
    // This prevents the very center from being too bright
    float centerFade = smoothstep(0.00, 0.20, distanceFromCenter);
    finalColor *= centerFade;
    
    // Step 10: Calculate the original circle pattern
    float depth = 1.0 / (length(uv) + 0.01);
    
    // Create the wave pattern - this oscillates between -1 and 1
    float wave = sin(depth * 40 + time * 20);
    
    // Use step() to create solid shapes (like the lines shader does)
    // Only show pattern where the wave is positive (above threshold)
    // This preserves the black spaces between shapes
    float pattern = step(0.0, wave);
    
    // Step 11: Cut off circles beyond a certain distance
    if (1.0 / (length(uv) + 0.01) > 1 / 0.1) {
        pattern = 0.0;
    }
    
    // Step 12: Combine everything!
    // Multiply our dynamic color by the circle pattern
    return half4(finalColor * pattern, 1.0);
}
                                
                                  


