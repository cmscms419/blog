# Density Field

![Untitled](attachments/Untitled_17.png)

이런 것을 만들 수 있다.

Compute shader를 2개를 사용한다.

지오메트릭을 사용한다. 텍스처이다.

가지고 있는 예제를 수정없이 실행하면, 아래처럼 나온다.

![Untitled](attachments/Untitled%201.png)

## CPU Code

```cpp
// 1. 데이터 초기화
m_particles.m_cpu.resize(256);

std::vector<Vector3> rainbow = {
    {1.0f, 0.0f, 0.0f},  // Red
    {1.0f, 0.65f, 0.0f}, // Orange
    {1.0f, 1.0f, 0.0f},  // Yellow
    {0.0f, 1.0f, 0.0f},  // Green
    {0.0f, 0.0f, 1.0f},  // Blue
    {0.3f, 0.0f, 0.5f},  // Indigo
    {0.5f, 0.0f, 1.0f}   // Violet/Purple
};

// 색깔 결정
std::mt19937 gen(0);
std::uniform_real_distribution<float> dp(-1.0f, 1.0f);
std::uniform_int_distribution<size_t> dc(0, rainbow.size() - 1);
for (auto &p : m_particles.m_cpu) {
    p.position = Vector3(dp(gen), dp(gen), 1.0f);
    p.color = rainbow[dc(gen)];
}
```

랜덤으로 m_particles.m_cpu에 저장된 값만큼 색깔이 정해진다.

```cpp
// Sprite : 게임제작, 2D 이미지를 Sprite라고 한다.
// VS는 이전 예제와 동일
const vector<D3D11_INPUT_ELEMENT_DESC> inputElements = {
    {"POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0,
     D3D11_INPUT_PER_VERTEX_DATA, 0}}; // Dummy
D3D11Utils::CreateVertexShaderAndInputLayout(
    m_device, L"Ex1404_StructuredBufferVS.hlsl", inputElements,
    m_vertexShader, m_inputLayout);
// 어떤 이미지가 덧 씌어지는 것을 의미한다.
D3D11Utils::CreatePixelShader(m_device, L"Ex1406_SpritePS.hlsl",
                              m_pixelShader);
// Density : 밀도
// RGB 값을 결정, 알파값을 결정한다.
// 어떤 색깔 성분(RGB)이 강하다. -> 그 색깔의 밀도가 높다 라고 표현할 수 있다.
// DensitySourcing : Density를 뿌려준다. 어떤 부분의 픽셀에 픽셀값을 키워준다.
D3D11Utils::CreateComputeShader(m_device, L"Ex1406_DensitySourcingCS.hlsl",
                                m_densitySourcingCS);
// Dissipation : 사라지다.
// 수증기 같은 부분이 사라진다 → 전반적으로 밀도가 낮아진다.
D3D11Utils::CreateComputeShader(
    m_device, L"Ex1406_DensityDissipationCS.hlsl", m_densityDissipationCS);

// 화면에 보여주는 이미지 RGB의 밀도장
m_densityTex.Initialize(m_device, m_screenWidth, m_screenHeight,
                        DXGI_FORMAT_R16G16B16A16_FLOAT);

D3D11Utils::CreateGeometryShader(m_device, L"Ex1406_SpriteGS.hlsl", m_spriteGS);
```

위 코드는 CS,VS,PS,GS를 GPU에 보내는 역할을 한다.

### SpritePS

```cpp
D3D11Utils::CreatePixelShader(m_device, L"Ex1406_SpritePS.hlsl", m_pixelShader);
```

여기서 Sprites는 2D 이미지를 의미한다.

### DensitySourcing

```cpp
D3D11Utils::CreateComputeShader(m_device, L"Ex1406_DensitySourcingCS.hlsl",m_densitySourcingCS);
```

Density : 밀도

RGB 값을 결정하고, 알파값을 결정해서, 색깔의 밀도를 결정한다. 

어떤 색깔 성분(RGB)이 강하다. -> 그 색깔의 밀도가 높다 라고 표현할 수 있다.

DensitySourcing : Density를 뿌려준다. 어떤 부분의 픽셀에 픽셀값을 키워준다.

### DensityDissipation

```cpp
D3D11Utils::CreateComputeShader(m_device, L"Ex1406_DensityDissipationCS.hlsl", m_densityDissipationCS);
```

Dissipation : 사라지다.

수증기 같은 부분이 사라진다 → 전반적으로 밀도가 낮아진다.

### m_densityTex.Initialize

```cpp
m_densityTex.Initialize(m_device, m_screenWidth, m_screenHeight, DXGI_FORMAT_R16G16B16A16_FLOAT);
```

화면에 보여주는 이미지 RGB의 밀도장을 의미한다.

가운데는 밀도가 높고, 멀면 밀도가 낮다.

smoothstep, smootherstep

![[https://upload.wikimedia.org/wikipedia/commons/5/57/Smoothstep_and_Smootherstep.svg](attachments/Smoothstep_and_Smootherstep.svg)](Density%20Field%20c08eaa3ef0cc4656ad2714b48c9f900b/Untitled%202.png)

[https://upload.wikimedia.org/wikipedia/commons/5/57/Smoothstep_and_Smootherstep.svg](https://upload.wikimedia.org/wikipedia/commons/5/57/Smoothstep_and_Smootherstep.svg)

```cpp
// 일반적으로 Sprite는 텍스춰를 많이 사용합니다.
// 이 예제처럼 수식으로 패턴을 만들 수도 있습니다.
float4 main(PixelShaderInput input) : SV_TARGET
{
	float dist = length(float2(0.5, 0.5) - input.texCoord) * 2;
	float scale = smootherstep(1 - dist);
	return float4(input.color.rgb * scale, 1);
}
```

난수가 들어간 함수도 많이 들어간다.

컴퓨터 쉐이더로 그릴 수 있다. 하지만 이것은 권장하지 않는다.

![Untitled](attachments/Untitled%203.png)

겹치는 구간에 동시에 그릴 경우, 누가 먼저 또는 나중에 그릴지는 모른다.

LOCK을 걸 수 있다. 하지만 이것은 느려진다.

픽셀은 안생기는 이유

→ 그릴 곳이 정해저 있다. 내부적으로 GPU가 순서를 정렬하기 때문에 안정적이다.

컴퓨터 쉐이더는  자유, 안정성 다운

픽셀 쉐이더는 고정, 안정성 상승

꼬리가 가늘어 진다. → 수학적인 표현

```cpp
// 일반적으로 Sprite는 텍스춰를 많이 사용합니다.
// 이 예제처럼 수식으로 패턴을 만들 수도 있습니다.
float4 main(PixelShaderInput input) : SV_TARGET
{
    float dist = length(float2(0.5, 0.5) - input.texCoord) * 2;
    float scale = smootherstep(1 - dist);
    return float4(input.color.rgb * scale, 1);
}
```

X는 스프라이트 사각형의 범위

V값이 높으면 밀도가 높다고 생각할 수 있다.

![Untitled](attachments/Untitled%204.png)

곡선이 똑같은 값을 빼준다.

![Untitled](attachments/Untitled%205.png)

```cpp
float3 color = densityField[dtID.xy].rgb - dissipation;
```

이 부분 이다.

그리고 max로 짜른다.

![Untitled](attachments/Untitled%206.png)

그리고 시간이 지날 수록 아래 그래프처럼 만들 수 있다.

![Untitled](attachments/Untitled%207.png)