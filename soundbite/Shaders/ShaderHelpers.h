//
//  ShaderHelpers.h
//  soundbite
//
//  Created by Malachi Frazier on 12/12/25.
//

#ifndef ShaderHelpers_h
#define ShaderHelpers_h

#include <metal_stdlib>
using namespace metal;

inline float2 normalizeUV(float2 position, float2 size) {
    float2 uv = position / size;
    uv = (uv * 2) - 1;
    uv.x *= size.x/size.y;
    return uv;
}


#endif // !ShaderHelpers_h
