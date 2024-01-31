// ported from ReShade HDR analysis shader
// for license see here: https://github.com/EndlesslyFlowering/ReShade_HDR_shaders/blob/master/LICENSE

// Custom effects using pixel shaders should use HLSL helper functions defined in
// d2d1effecthelpers.hlsli to make use of effect shader linking.
#define D2D_INPUT_COUNT 1           // The pixel shader takes exactly 1 input.

// Note that the custom build step must provide the correct path to find d2d1effecthelpers.hlsli when calling fxc.exe.
#include "d2d1effecthelpers.hlsli"


cbuffer constants : register(b0)
{
  float dpi : packoffset(c0.x); // Ignored - there is no position-dependent behavior in the shader.
};


static const float3x3 Bt709ToDciP3 = float3x3(
  0.82246196269989013671875f,    0.17753803730010986328125f,   0.f,
  0.03319419920444488525390625f, 0.96680581569671630859375f,   0.f,
  0.017082631587982177734375f,   0.0723974406719207763671875f, 0.91051995754241943359375f);

static const float3x3 Bt709ToBt2020 = float3x3(
  0.627403914928436279296875f,      0.3292830288410186767578125f,  0.0433130674064159393310546875f,
  0.069097287952899932861328125f,   0.9195404052734375f,           0.011362315155565738677978515625f,
  0.01639143936336040496826171875f, 0.08801330626010894775390625f, 0.895595252513885498046875f);

static const float3x3 Bt709ToAp0D65 = float3x3(
  0.4339316189289093017578125f,   0.3762523829936981201171875f,   0.1898159682750701904296875f,
  0.088618390262126922607421875f, 0.809275329113006591796875f,    0.10210628807544708251953125f,
  0.01775003969669342041015625f,  0.109447620809078216552734375f, 0.872802317142486572265625f);

namespace Bt709To
{
  float3 DciP3(precise float3 Colour)
  {
    return mul(Bt709ToDciP3, Colour);
  }

  float3 Bt2020(precise float3 Colour)
  {
    return mul(Bt709ToBt2020, Colour);
  }

  float3 Ap0D65(precise float3 Colour)
  {
    return mul(Bt709ToAp0D65, Colour);
  }
}

bool IsCsp(precise float3 Rgb)
{
  if (all(Rgb >= 0.f))
  {
    return true;
  }
  return false;
}

D2D_PS_ENTRY(main)
{
  precise const float3 pixel = D2DGetInput(0).rgb;

  precise const float pixelNits =
    dot(float3(0.2126390039920806884765625f, 0.715168654918670654296875f, 0.072192318737506866455078125f), pixel);

  float4 output;

  output.a = 1.f;

  if (IsCsp(pixel))
  {
    // shades of grey
    float clamped = pixelNits * 0.25f;
    output.rgb = float3(clamped,
                        clamped,
                        clamped);
  }
  else if (IsCsp(Bt709To::DciP3(pixel)))
  {
    // yellow
    output.rgb = float3(pixelNits,
                        pixelNits,
                        0.f);
  }
  else if (IsCsp(Bt709To::Bt2020(pixel)))
  {
    // blue
    output.rgb = float3(0.f,
                        0.f,
                        pixelNits);
  }
  else if (IsCsp(Bt709To::Ap0D65(pixel)))
  {
    // red
    output.rgb = float3(pixelNits,
                        0.f,
                        0.f);
  }
  else // invalid
  {
    // pink
    output.rgb = float3(pixelNits,
                        0.f,
                        pixelNits);
  }

  return output;
}
