//********************************************************* 
// 
// Copyright (c) Microsoft. All rights reserved. 
// This code is licensed under the MIT License (MIT). 
// THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF 
// ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY 
// IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR 
// PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT. 
// 
//*********************************************************

// Special demo version that renders all SDR colors [0 to 80 nits] as grayscale and optimizes
// the luminance heatmap colors for [80 to 1000 nits] range.

// Custom effects using pixel shaders should use HLSL helper functions defined in
// d2d1effecthelpers.hlsli to make use of effect shader linking.
#define D2D_INPUT_COUNT 1           // The pixel shader takes exactly 1 input.

// Note that the custom build step must provide the correct path to find d2d1effecthelpers.hlsli when calling fxc.exe.
#include "d2d1effecthelpers.hlsli"

// Nits to color mappings:
//     0.00 Black
//     3.16 Blue
//    10.0  Cyan
//    31.6  Green
//   100.0  Yellow
//   316.0  Orange
//  1000.0  Red
//  3160.0  Magenta
// 10000.0  White
// This approximates a logarithmic plot where two colors represent one order of magnitude in nits.

// Define constants based on above behavior: 9 "stops" for a piecewise linear gradient in scRGB space.
#define STOP0_NITS 0.00f
#define STOP1_NITS 100.f // Max SDR. HDR400/600/1000. Max PQ.
#define STOP2_NITS 400.f
#define STOP3_NITS 600.f
#define STOP4_NITS 1000.f
#define STOP5_NITS 10000.f

#define STOP0_COLOR float4(0.0f, 0.0f, 0.0f, 1.0f) // Black
#define STOP1_COLOR float4(0.0f, 0.0f, 1.0f, 1.0f) // Blue
#define STOP2_COLOR float4(0.0f, 1.0f, 0.0f, 1.0f) // Green
#define STOP3_COLOR float4(1.0f, 1.0f, 0.0f, 1.0f) // Yellow
#define STOP4_COLOR float4(1.0f, 0.0f, 0.0f, 1.0f) // Red
#define STOP5_COLOR float4(1.0f, 1.0f, 1.0f, 1.0f) // White

cbuffer constants : register(b0)
{
    float dpi : packoffset(c0.x); // Ignored - there is no position-dependent behavior in the shader.
};

D2D_PS_ENTRY(main)
{
    float4 input = D2DGetInput(0);

    // Detect if any color component is outside of [0, 1] SDR numeric range.
    float4 isOutsideSdrVec = abs(sign(input - saturate(input)));
    float isOutsideSdr = max(max(isOutsideSdrVec.r, isOutsideSdrVec.g), isOutsideSdrVec.b); // 1 = out, 0 = in
    float isInsideSdr = 1 - isOutsideSdr;                                                   // 0 = out, 1 = in

    // Convert all sRGB/SDR colors to grayscale.
    float lum = dot(float3(0.3f, 0.59f, 0.11f), input.rgb);
    float4 insideSdrColor = float4(lum, lum, lum, 1.0f);

    // Implement the heatmap with a piecewise linear gradient that maps [0, 10000] nits to scRGB colors.
    // This shader is optimized for readability, not performance.

    // 1: Calculate luminance in nits.
    // Input is in scRGB. First convert to Y from CIEXYZ, then scale by whitepoint of 80 nits.
    float nits = dot(float3(0.2126f, 0.7152f, 0.0722f), input.rgb) * 80.0f;

    // 2: Determine which gradient segment will be used.
    // Only one of useSegmentN will be 1 (true) for a given nits value.
    float useSegment0 = sign(nits - STOP0_NITS) - sign(nits - STOP1_NITS);
    float useSegment1 = sign(nits - STOP1_NITS) - sign(nits - STOP2_NITS);
    float useSegment2 = sign(nits - STOP2_NITS) - sign(nits - STOP3_NITS);
    float useSegment3 = sign(nits - STOP3_NITS) - sign(nits - STOP4_NITS);
    float useSegment4 = sign(nits - STOP4_NITS) - sign(nits - STOP5_NITS);

    // 3: Calculate the interpolated color.
    float lerpSegment0 = (nits - STOP0_NITS) / (STOP1_NITS - STOP0_NITS);
    float lerpSegment1 = (nits - STOP1_NITS) / (STOP2_NITS - STOP1_NITS);
    float lerpSegment2 = (nits - STOP2_NITS) / (STOP3_NITS - STOP2_NITS);
    float lerpSegment3 = (nits - STOP3_NITS) / (STOP4_NITS - STOP3_NITS);
    float lerpSegment4 = (nits - STOP4_NITS) / (STOP5_NITS - STOP4_NITS);

    //  Only the "active" gradient segment contributes to the output color.
    float4 outsideSdrColor =
        lerp(STOP0_COLOR, STOP1_COLOR, lerpSegment0) * useSegment0 +
        lerp(STOP1_COLOR, STOP2_COLOR, lerpSegment1) * useSegment1 +
        lerp(STOP2_COLOR, STOP3_COLOR, lerpSegment2) * useSegment2 +
        lerp(STOP3_COLOR, STOP4_COLOR, lerpSegment3) * useSegment3 +
        lerp(STOP4_COLOR, STOP5_COLOR, lerpSegment4) * useSegment4;

    return insideSdrColor * isInsideSdr + outsideSdrColor * isOutsideSdr;
}