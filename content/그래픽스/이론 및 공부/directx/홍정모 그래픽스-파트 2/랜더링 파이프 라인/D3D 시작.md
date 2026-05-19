# D3D 시작

# Direct3D 개요

## Grapihics APIs

![Untitled](attachments/Untitled_17.png)

원하는 Application을 만들기 위한 도구

## DirectX

- **Direct3D**
- Direct3Draw
- DirectMusic
- DirectSound

![Untitled](attachments/Untitled%201.png)

# 초기화

```cpp
AppBase::InitDirect3D()
...

if (FAILED(D3D11CreateDevice(
        nullptr,                 // 기본 어댑터를 사용하려면 nullptr을 지정합니다.
        driverType,              // 하드웨어 그래픽 드라이버를 사용하여 장치를 만듭니다.
        0,                       // 드라이버가 D3D_DRIVER_TYPE_SOFTER인 경우를 제외하고는 0이어야 합니다.
        createDeviceFlags,       // 디버그 및 Direct2D 호환성 플래그를 설정합니다.
        featureLevels,           // 이 앱이 지원할 수 있는 기능 수준 목록입니다.
        ARRAYSIZE(featureLevels),// 위 목록의 크기입니다.
        D3D11_SDK_VERSION,       // Microsoft Store 앱의 경우 항상 D3D11_SDK_VERSION으로 설정합니다.
        &device,                 // 생성된 Direct3D 디바이스를 반환합니다.
        &featureLevel,           // 생성된 장치의 기능 수준을 반환합니다.
        &context                 // 장치의 즉각적인 컨텍스트를 반환합니다.
        ))) {
    cout << "D3D11CreateDevice() failed." << endl;
    return false;
}
```

```cpp
HRESULT D3D11CreateDevice(
  [in, optional]  IDXGIAdapter            *pAdapter,
                  D3D_DRIVER_TYPE         DriverType,
                  HMODULE                 Software,
                  UINT                    Flags,
  [in, optional]  const D3D_FEATURE_LEVEL *pFeatureLevels,
                  UINT                    FeatureLevels,
                  UINT                    SDKVersion,
  [out, optional] ID3D11Device            **ppDevice,
  [out, optional] D3D_FEATURE_LEVEL       *pFeatureLevel,
  [out, optional] ID3D11DeviceContext     **ppImmediateContext
);
```

[D3D11CreateDevice 함수(d3d11.h) - Win32 apps](https://learn.microsoft.com/ko-kr/windows/win32/api/d3d11/nf-d3d11-d3d11createdevice)

immediate Context

명령을 즉시 수행

Deferred Context

명령을  기록한 다음, 실행하라고 하면 실행

→ 멀티스레딩할 때 사용

**랜더링 기능 은 둘다 동일하다.**

## Multisample Anti-Aliasing

가장자리가 부드러워 진다.

![Untitled](attachments/Untitled%202.png)

![Untitled](attachments/Untitled%203.png)

```cpp
// 화면에 보여주는 것이다.
 DXGI_SWAP_CHAIN_DESC sd;                           // 구조체 설
 ZeroMemory(&sd, sizeof(sd));                       // 0으로 초기화 한다.
 sd.BufferDesc.Width = m_screenWidth;               // set the back buffer width
 sd.BufferDesc.Height = m_screenHeight;             // set the back buffer height
 sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM; // use 32-bit color
 sd.BufferCount = 2;                                // Double-buffering
 sd.BufferDesc.RefreshRate.Numerator = 60;          // 분모
 sd.BufferDesc.RefreshRate.Denominator = 1;         // 분자
 sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;  // how swap chain is to be used
 sd.OutputWindow = m_mainWindow;                    // the window to be used
 sd.Windowed = TRUE;                                // 태두리가 있는 창모드
 sd.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH; // allow full-screen switching
 sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;          // 윈도우 앱을 만들 때, 사용한다.
```

[DXGI_SWAP_CHAIN_DESC(dxgi.h) - Win32 apps](https://learn.microsoft.com/ko-kr/windows/win32/api/dxgi/ns-dxgi-dxgi_swap_chain_desc)

**UNORM**

unsigned normalized integer → (0~255) / 255 = (0 ~ 1) 범위를 가진다.

8bit 정도의 범위를 가지고 있다.

0 초기화하면, 내부적으로는 0.0f로 정의된다.

255 초기화하면, 내부적으로 1.0f로 정의된다.

버전이 자꾸 올라간다.

```cpp
// CreateRenderTarget
ID3D11Texture2D *pBackBuffer;
m_swapChain->GetBuffer(0, IID_PPV_ARGS(&pBackBuffer));
if (pBackBuffer) {
    m_device->CreateRenderTargetView(pBackBuffer, NULL, &m_renderTargetView);
    pBackBuffer->Release();
} else {
    cout << "CreateRenderTargetView() failed." << endl;
    return false;
}
```

swapchain을 만든 다음에는 RenderTargetView를 만들어줘야 한다.

메모리에 랜더링을 한다.

어떻게 사용할 것인지를 정의하는 것이 rendertargetView이고, 이를 통해 렌더링한다.

→ swapchain 가지고 있는 버퍼에다가 랜더링한다.

왜 나누는 것인가??

backbuffer가 renderbuffer로 사용하지 않는 경우도 있다.

ID3D11Texture2D → color 값을 2차원 배열값으로 저장

→ 다른 배열과는 좀 더 다르다

viewport

```cpp
// Set the viewport
    ZeroMemory(&m_screenViewport, sizeof(D3D11_VIEWPORT)); // 초기
    m_screenViewport.TopLeftX = 0;
    m_screenViewport.TopLeftY = 0;
    m_screenViewport.Width = float(m_screenWidth);
    m_screenViewport.Height = float(m_screenHeight);
    // m_screenViewport.Width = static_cast<float>(m_screenHeight);
    m_screenViewport.MinDepth = 0.0f;
    m_screenViewport.MaxDepth = 1.0f; // Note: important for depth buffering

		m_context->RSSetViewports(1, &m_screenViewport);
```

**RS**SetViewports

→ RS : Rasterization Stage 약자

왜 Viewports를 설정하는 것이 래스터라이제이션을 하는 것인가?

→ 왜냐하면 래스터라이제이션에서 3차원 좌표 → 화면으로 투영 → 화면 좌표계에서의 위치로 표시

 

```cpp
// Create a rasterizer state
D3D11_RASTERIZER_DESC rastDesc;
ZeroMemory(&rastDesc, sizeof(D3D11_RASTERIZER_DESC)); // Need this
rastDesc.FillMode = D3D11_FILL_MODE::D3D11_FILL_SOLID;
// rastDesc.FillMode = D3D11_FILL_MODE::D3D11_FILL_WIREFRAME;
rastDesc.CullMode = D3D11_CULL_MODE::D3D11_CULL_NONE; // backculling을 하단다.
rastDesc.FrontCounterClockwise = false; // 

m_device->CreateRasterizerState(&rastDesc, &m_rasterizerSate);
```

D3D11_FILL_WIREFRAME로 설정하게 되면,

![Untitled](attachments/Untitled%204.png)

이렇게 WIREFRAME만 만들어진다.

[D3D11_USAGE(d3d11.h)  - Win32 apps](https://learn.microsoft.com/ko-kr/windows/win32/api/d3d11/ne-d3d11-d3d11_usage)

```cpp
// Create depth buffer
D3D11_TEXTURE2D_DESC depthStencilBufferDesc;
depthStencilBufferDesc.Width = m_screenWidth;
depthStencilBufferDesc.Height = m_screenHeight;
depthStencilBufferDesc.MipLevels = 1;
depthStencilBufferDesc.ArraySize = 1;
depthStencilBufferDesc.Format = DXGI_FORMAT_D24_UNORM_S8_UINT;
if (numQualityLevels > 0) {
    depthStencilBufferDesc.SampleDesc.Count = 4; // how many multisamples
    depthStencilBufferDesc.SampleDesc.Quality = numQualityLevels - 1;
} else {
    depthStencilBufferDesc.SampleDesc.Count = 1; // how many multisamples
    depthStencilBufferDesc.SampleDesc.Quality = 0;
}
depthStencilBufferDesc.Usage = D3D11_USAGE_DEFAULT;
depthStencilBufferDesc.BindFlags = D3D11_BIND_DEPTH_STENCIL;
depthStencilBufferDesc.CPUAccessFlags = 0;
depthStencilBufferDesc.MiscFlags = 0;

if (FAILED(m_device->CreateTexture2D(&depthStencilBufferDesc, 0, m_depthStencilBuffer.GetAddressOf()))) 
{
   cout << "CreateTexture2D() failed." << endl;
}
if (FAILED(
   m_device->CreateDepthStencilView(m_depthStencilBuffer.Get(), 0, &m_depthStencilView))) {
   cout << "CreateDepthStencilView() failed." << endl;
}
```

depthbuffer

texture2D 사용

D24_UNORM_S8_UINT

→ Depth 공간은 

**stencil** + depth를 사용할 수 있다.

Usage : 메모리 공간을 어떻게 사용할 지를 정할 수 있다.

[D3D11_USAGE(d3d11.h)  - Win32 apps](https://learn.microsoft.com/ko-kr/windows/win32/api/d3d11/ne-d3d11-d3d11_usage)

BindFlags: 어떻게 사용할 것 인가를 정한다.

m_device->CreateTexture2D 

→ 그래픽 카드에 메모리를 만드는 것이다.

→ 실제로 사용하기 위해서 메모리를 만드는 것이다.

```cpp
// Create depth stencil state
D3D11_DEPTH_STENCIL_DESC depthStencilDesc;
ZeroMemory(&depthStencilDesc, sizeof(D3D11_DEPTH_STENCIL_DESC));
depthStencilDesc.DepthEnable = true; // false
depthStencilDesc.DepthWriteMask = D3D11_DEPTH_WRITE_MASK::D3D11_DEPTH_WRITE_MASK_ALL;
depthStencilDesc.DepthFunc = D3D11_COMPARISON_FUNC::D3D11_COMPARISON_LESS_EQUAL;
if (FAILED(m_device->CreateDepthStencilState(&depthStencilDesc,
                                             m_depthStencilState.GetAddressOf()))) {
    cout << "CreateDepthStencilState() failed." << endl;
}
```

DepthEnable : depth를 사용을 결정 

DepthFunc : 어떻게 depth를 결정할 것을 만들어준다.

# InitGUI

![d3d11-pipeline-stages.jpg](attachments/d3d11-pipeline-stages.jpg)

input vertex/index buffer

input assembler

→ 도형을 만든다.

기본 단위를 만든다.

결합

vertex shader

vertex의 위치를 결정한다.

tessellation

입력한 데이터를 상세하게 지형으로 만들어 준다.

geometry shader

좀 더 자세한 모델로 바꿔준다.

Rasterization

삼각형 기하 정보를 픽셀의 집합으로 만들어준다.

Fragment == pixel

색깔을 만들어 준다.

color blending == Output-merger Stage

depth buffer 등 색깔을 결정해 준다.