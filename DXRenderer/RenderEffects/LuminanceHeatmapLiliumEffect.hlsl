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

// Custom effects using pixel shaders should use HLSL helper functions defined in
// d2d1effecthelpers.hlsli to make use of effect shader linking.
#define D2D_INPUT_COUNT 1           // The pixel shader takes exactly 1 input.

// Note that the custom build step must provide the correct path to find d2d1effecthelpers.hlsli when calling fxc.exe.
#include "d2d1effecthelpers.hlsli"


#define STOP0_NITS 0.f
#define STOP1_NITS 100.f
#define STOP2_NITS 203.f
#define STOP3_NITS 400.f
#define STOP4_NITS 1000.f
#define STOP5_NITS 4000.f
#define STOP6_NITS 10000.f

#define SCALE_GREYSCALE 0.25f

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// colours fade linearly into each other above 100 nits as the nits increase
//    0-  100 nits is kept in greyscale and scaled down by 25% so it doesn't overshadow the other parts of the heatmap
//  100-  203 nits is   cyan into green
//  203-  400 nits is  green into yellow
//  400- 1000 nits is yellow into red
// 1000- 4000 nits is    red into pink
// 4000-10000 nits is   pink into blue
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

cbuffer constants : register(b0)
{
    float dpi : packoffset(c0.x); // Ignored - there is no position-dependent behavior in the shader.
};

float heatmap_fade_in(float Y, float currentStop, float normaliseTo)
{
    return (Y - currentStop) / (normaliseTo - currentStop);
}

float heatmap_fade_out(float Y, float currentStop, float normaliseTo)
{
    return 1.f - heatmap_fade_in(Y, currentStop, normaliseTo);
}

D2D_PS_ENTRY(main)
{
    float4 input = D2DGetInput(0);

    // Implement the heatmap with a piecewise linear gradient that maps [0, 10000] nits to scRGB colors.
    // This shader is optimized for readability, not performance.

    // 1: Calculate luminance in nits.
    // Input is in scRGB. First convert to Y from CIEXYZ, then scale by whitepoint of 80 nits.
    float Y = dot(float3(0.2126390039920806884765625f, 0.715168654918670654296875f, 0.072192318737506866455078125f), input.rgb) * 80.f;

    float4 output;

    if (Y < STOP0_NITS) // < 0 nits
    {
        output.rgb = 0.f;
    }
    else if (Y <= STOP1_NITS) // <= 100 nits
    {
        //shades of grey
        const float currentGreyscale = Y / STOP1_NITS * SCALE_GREYSCALE;
        output.rgb = currentGreyscale;
    }
    else if (Y <= STOP2_NITS) // <= 203 nits
    {
        //cyan to green
        output.r = 0.f;
        output.g = 1.f;
        output.b = heatmap_fade_out(Y, STOP1_NITS, STOP2_NITS);
    }
    else if (Y <= STOP3_NITS) // <= 400 nits
    {
        //green to yellow
        output.r = heatmap_fade_in(Y, STOP2_NITS, STOP3_NITS);
        output.g = 1.f;
        output.b = 0.f;
    }
    else if (Y <= STOP4_NITS) // <= 1000 nits
    {
        //yellow to red
        output.r = 1.f;
        output.g = heatmap_fade_out(Y, STOP3_NITS, STOP4_NITS);
        output.b = 0.f;
    }
    else if (Y <= STOP5_NITS) // <= 4000 nits
    {
        //red to pink
        output.r = 1.f;
        output.g = 0.f;
        output.b = heatmap_fade_in(Y, STOP4_NITS, STOP5_NITS);
    }
    else if (Y <= STOP6_NITS) // <= 10000 nits
    {
        //pink to blue
        output.r = heatmap_fade_out(Y, STOP5_NITS, STOP6_NITS);
        output.g = 0.f;
        output.b = 1.f;
    }
    else // > 10000 nits
    {
        output.r = 6.25f;
        output.g = 0.f;
        output.b = 0.f;
    }

    output.a = 1.f;

    return output;
}
