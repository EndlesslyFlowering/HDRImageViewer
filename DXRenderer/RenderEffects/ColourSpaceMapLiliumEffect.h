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

DEFINE_GUID(GUID_ColourSpaceMapLiliumPixelShader, /* 8cef19fb-b3c3-44df-a600-ee83b9e7476a */
    0x8cef19fb,
    0xb3c3,
    0x44df,
    0xa6, 0x00, 0xee, 0x83, 0xb9, 0xe7, 0x47, 0x6a);
DEFINE_GUID(CLSID_CustomColourSpaceMapLiliumEffect, /* afbc0347-a279-4a66-ae40-1b8f9e194efc */
    0xafbc0347,
    0xa279,
    0x4a66,
    0xae, 0x40, 0x1b, 0x8f, 0x9e, 0x19, 0x4e, 0xfc);

// Our effect contains one transform, which is simply a wrapper around a pixel shader. As such,
// we can simply make the effect itself act as the transform.
class ColourSpaceMapLiliumEffect : public ID2D1EffectImpl, public ID2D1DrawTransform
{
public:
    // Declare effect registration methods.
    static HRESULT Register(_In_ ID2D1Factory1* pFactory);

    static HRESULT __stdcall CreateColourSpaceMapLiliumImpl(_Outptr_ IUnknown** ppEffectImpl);

    // Declare ID2D1EffectImpl implementation methods.
    IFACEMETHODIMP Initialize(
        _In_ ID2D1EffectContext* pContextInternal,
        _In_ ID2D1TransformGraph* pTransformGraph
        );

    IFACEMETHODIMP PrepareForRender(D2D1_CHANGE_TYPE changeType);

    IFACEMETHODIMP SetGraph(_In_ ID2D1TransformGraph* pGraph);

    // Declare ID2D1DrawTransform implementation methods.
    IFACEMETHODIMP SetDrawInfo(_In_ ID2D1DrawInfo* pRenderInfo);

    // Declare ID2D1Transform implementation methods.
    IFACEMETHODIMP MapOutputRectToInputRects(
        _In_ const D2D1_RECT_L* pOutputRect,
        _Out_writes_(inputRectCount) D2D1_RECT_L* pInputRects,
        UINT32 inputRectCount
        ) const;

    IFACEMETHODIMP MapInputRectsToOutputRect(
        _In_reads_(inputRectCount) CONST D2D1_RECT_L* pInputRects,
        _In_reads_(inputRectCount) CONST D2D1_RECT_L* pInputOpaqueSubRects,
        UINT32 inputRectCount,
        _Out_ D2D1_RECT_L* pOutputRect,
        _Out_ D2D1_RECT_L* pOutputOpaqueSubRect
        );

    IFACEMETHODIMP MapInvalidRect(
        UINT32 inputIndex,
        D2D1_RECT_L invalidInputRect,
        _Out_ D2D1_RECT_L* pInvalidOutputRect
        ) const;

    // Declare ID2D1TransformNode implementation methods.
    IFACEMETHODIMP_(UINT32) GetInputCount() const;

    // Declare IUnknown implementation methods.
    IFACEMETHODIMP_(ULONG) AddRef();
    IFACEMETHODIMP_(ULONG) Release();
    IFACEMETHODIMP QueryInterface(_In_ REFIID riid, _Outptr_ void** ppOutput);

    // Declare property getter/setter methods.

private:
    ColourSpaceMapLiliumEffect();
    HRESULT UpdateConstants();

    // This struct defines the constant buffer of our pixel shader.
    struct
    {
        float dpi;
    } m_constants;

    Microsoft::WRL::ComPtr<ID2D1DrawInfo>      m_drawInfo;
    Microsoft::WRL::ComPtr<ID2D1EffectContext> m_effectContext;
    LONG                                       m_refCount;
    D2D1_RECT_L                                m_inputRect;
    float                                      m_dpi;
};
