# Cloud

구름이 왜 생기는가?? → 차가운 공기와 따뜻한 공기가 만나서 생긴다.

3가지 노이즈 텍스처를 사용한다. 3차원을 사용한다.

밀도가 없는 곳은 빨리 계산 그리고 step해서 렌더링 한다.

구름이 밀도가 높으면, 빛이 통과가 안된다 → 보이지 않는다 → 랜더링을 안하게 할 수 있다.

## 조명을 결정하는 방법

![Untitled](attachments/Untitled_17.png)

카메라 depth가 구름을 만나면, 구름과 만난 지점에서 또다시 조명을 쏜다.

쉐이더 웨이와 비슷한 원리이다.

구름 자체에서 조명을 쏘면, 중간에 빛이 어느정도 흡수 되는 것을 확인하기 위해서 사용한다.

약간 느리지만, 빠르게 하는 방법이 있다.

## 예제에서 만든 구름

![Untitled](attachments/Untitled%201.png)

원래 구름은 빛을 받으면, 빛이 구름 속에서 산란이 된다.

스케터링이라고 한다.

## 페이즈 펑션

![Untitled](attachments/Untitled%202.png)

빛을 맞으면, 모든 방향으로 고르게 산란이 되지 않는다. 여러개의 광선을 쏜다.

실시간 랜더링에서는 보는 방향에 의해서, 조명이 전달되는 양을 조절한다.

화살표 김: 산란될 확률이 높음

화살표 짧음: 산란될 확률이 낮음

라이트 맵을 만들기 도 한다.

단순 텍스처 링으로 하는 것은 한계가 있다.

모든 광선들이 모두 수평하다 → 디렉셔널 라이트

디렉션은 전부 수평이다.

구름은 연기하고 비슷하다

### 구름의 예시

![Untitled](attachments/Untitled%203.png)

구름은 고체가 아니라, 기체이다.

공기 중에 수증기가 랜덤하게 퍼져있다.

지나가면서, 얼마나 밝은지 확인할 수 있다. 

보는 영역에서 랜더링에 되는 영역에서 그림자를 만들어 낸다.

빛이 많이 흡수하면, 다음에 빛을 맞는 구름은 빛을 적게 받는다.

덴시티 업셉션 : 구름이 빛을 얼마나 흡수하는 것인가.

→ 0이면, 구름이 빛을 전혀 흡수하지 않아서, 보이지 않는다.

라이트 스케일 : 조명이 세기를 조절한다.

Aniso(비등방성) : 빛은 반사될 때, 진행 방향으로 나아가려는 성질이 있다.

## 라이트맵

```cpp
// Depth -- 3차원 공간에 대한 값이 들어있다.
// 조명에 대한 라이트맵을 가지고 있다.
// 해상도가 낮아도 괜찮다. 숫자가 크면 속도가 느릴 수 도 있다.
int m_volumeWidth = 128;
int m_volumeHeight = 128;
int m_volumeDepth = 128;
int m_lightWidth = 128 / 4; // 라이트맵은 낮은 해상도
int m_lightHeight = 128 / 4;
int m_lightDepth = 128 / 4;
```

![[/스크린샷 2024-02-20 111541.png]]

step을 통해서 구름의 볼륨을 계산한다.

이것을 의료에서 많이 쓴다.

![Untitled](attachments/Untitled%204.png)

볼륨 슬라이스를 겹치는 방법으로 사용하는 경우도 있다.

반투명한 단면들을 겹쳐서, 랜더링한 방식을 사용했다.

왼쪽그림은 보고 있는 방향으로 계산해서, 랜더링 하는 방법이다.

속도가 중요한 상황에서는 쓰인다.

이 떄, 반투명한 단면을 랜더링 하는 순서는 맨 뒤에서 부터 해야 한다.

단면들을 sort해서 정렬하고 뒤에서 부터 랜더링을 해줘야한다.

스캔데이터를 정확하게 보는 것이 중요하다. → 조명이 중요하지 않다.

## 코드

**Ex1603_Cloud.cpp**

```cpp
shared_ptr<Model> m_volumeModel;

// 실시간 랜더링에는 조명에 대해서 고려해야 한다.
ComPtr<ID3D11ComputeShader> m_cloudDensityCS;
ComPtr<ID3D11ComputeShader> m_cloudLightingCS;
```

```cpp
// 모델에 대한 텍스처 초기화

// 3차원 공간에서 어떤 영역에 수증기 밀도가 높/낮은가를 의미한다.
// 해상도를 3개를 준다.
// 16비트 float 하나의 3차원 배열
// 쉐이더에서 사용된다
m_volumeModel->m_meshes.front()->densityTex.Initialize(
    m_device, m_volumeWidth, m_volumeHeight, m_volumeDepth,
    DXGI_FORMAT_R16_FLOAT, {});

// 빛에대한 텍스처 이다.
m_volumeModel->m_meshes.front()->lightingTex.Initialize(
    m_device, m_lightWidth, m_lightHeight, m_lightDepth,
    DXGI_FORMAT_R16_FLOAT, {});
```

볼륨 모델안에 density, lighting 텍스처가 들어있다

텍스처를 만들 때는 꼭 필요한 것이 있다.

**D3D11Utils.cpp**

```cpp
D3D11_TEXTURE3D_DESC txtDesc;
 ZeroMemory(&txtDesc, sizeof(txtDesc));
 txtDesc.Width = width;
 txtDesc.Height = height;
 txtDesc.Depth = depth; // 이 정보가 필수 적이다.
 txtDesc.MipLevels = 1;
 txtDesc.Format = pixelFormat;
 txtDesc.Usage = D3D11_USAGE_DEFAULT;
 txtDesc.BindFlags = D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET |
                     D3D11_BIND_UNORDERED_ACCESS;
 txtDesc.MiscFlags = 0;
 txtDesc.CPUAccessFlags = 0;

if (initData.size() > 0) {
    size_t pixelSize = GetPixelSize(pixelFormat);
    D3D11_SUBRESOURCE_DATA bufferData;
    ZeroMemory(&bufferData, sizeof(bufferData));
    bufferData.pSysMem = initData.data();
    bufferData.SysMemPitch = UINT(width * pixelSize);
    bufferData.SysMemSlicePitch = UINT(width * height * pixelSize);
    ThrowIfFailed(device->CreateTexture3D(&txtDesc, &bufferData,
                                          texture.GetAddressOf())); // 3차원 배열 데이타가 들어가 있다.
} else {
    ThrowIfFailed(
        device->CreateTexture3D(&txtDesc, NULL, texture.GetAddressOf()));
}
```

3d 텍스처를 만들 때는 위의 코드를 참고하면 된다.

**Ex1603_Cloud.cpp**

```cpp
// 쉐이더 프로그램을 적용
D3D11Utils::CreateComputeShader(m_device, L"CloudDensityCS.hlsl",
                                    m_cloudDensityCS);
D3D11Utils::CreateComputeShader(m_device, L"CloudLightingCS.hlsl",
																		m_cloudLightingCS);
```

```cpp
// 디스패치를 하고 있다.

// m_cloudDensityCS
m_context->CSSetConstantBuffers(0, 1, m_volumeConstsGpu.GetAddressOf());
m_context->CSSetUnorderedAccessViews(
     0, 1, m_volumeModel->m_meshes.front()->densityTex.GetAddressOfUAV(),
     NULL);
m_context->CSSetShader(m_cloudDensityCS.Get(), 0, 0);
m_context->Dispatch(UINT(ceil(m_volumeWidth / 16.0f)),
                     UINT(ceil(m_volumeHeight / 16.0f)),
                     UINT(ceil(m_volumeDepth / 4.0f)));
AppBase::ComputeShaderBarrier();

m_context->CSSetShaderResources(
    0, 1, m_volumeModel->m_meshes.front()->densityTex.GetAddressOfSRV());
m_context->CSSetUnorderedAccessViews(
    0, 1, m_volumeModel->m_meshes.front()->lightingTex.GetAddressOfUAV(),
    NULL);
m_context->CSSetShader(m_cloudLightingCS.Get(), 0, 0);
m_context->Dispatch(UINT(ceil(m_lightWidth / 16.0f)),
                    UINT(ceil(m_lightHeight / 16.0f)),
                    UINT(ceil(m_lightDepth / 4.0f)));
AppBase::ComputeShaderBarrier();
```

**CloudDensityCS.hlsl**

```cpp
[numthreads(16, 16, 4)]
void main(uint3 dtID : SV_DispatchThreadID)
{
    uint width, height, depth;
    densityTex.GetDimensions(width, height, depth);
    
		// 3차원 배열로써 사용되고 있다.
    float3 uvw = dtID / float3(width, height, depth) + uvwOffset; // 노이즈 생성을 위해 uvwOffset 사용
		
		// uvw : 3차원 텍스처 좌표
		// cloudDensity를 uvw로 셈플링 하고 있다.
    densityTex[dtID] = cloudDensity(uvw);
}
```

의문??

어차피 함수 호출해서 사용할 거면, 텍스처에 저장할 필요가 있나??

→ 텍스처 샘플링할 때는 인터폴레이션을 사용한다. 이 의미는 텍스처 샘플링을 한번할 때, 픽셀값 여러개를 사용한다. 2차원은 주변값은 4개 사용한다. 3차원은 8개가  필요하다. 3차원에서는 중복과 느려진다. 여기서는 값을 한번 계산해서 사용하는 의미로 3차원 텍스처에 저장하고 사용한다.

CloudLightingCS.hlsl

```cpp
[numthreads(16, 16, 4)]
void main(uint3 dtID : SV_DispatchThreadID)
{
    // float3 lightDir = float3(0, 1, 0);
    
    uint width, height, depth;
    lightingTex.GetDimensions(width, height, depth);
    
    float3 uvw = dtID / float3(width, height, depth); //+ uvwOffset; 라이트맵은 주어진 밀도장에 대해 계산하는 것이라서 uvwOffset 미사용

    // uvw는 [0, 1]x[0,1]x[0,1]
    // 모델 좌표계는 [-1,1]x[-1,1]x[-1,1]
		// 3차원 좌표 위치에서 빛을 얼마나 받을 수 있는 지, 값을 가져온다.
    lightingTex[dtID] = LightRay((uvw - 0.5) * 2.0, lightDir);
}
```

![[/cloud.png]]

안쪽이 noise로 가득차서, 밀도가 어느 정도인지 미리 계산할 수 없다.

![[/cloud2.png]]

step을 통해서 단계적으로 계산한다.

![[/cloud3.png]]

![Untitled](attachments/Untitled%205.png)

이렇게 계산할 수 있다.

그 뒤에 조명을 계산할 수 있다.

![[/cloud4.png]]

초록 부분에서 조명을 계산해야 한다.

근데 빨간 점도 구름에 있다. 연산이 느려진다.

그래서 연산을 빠르게 하기 위해, 빨간점을 미리 계산했다.

초록 시점에서 빛을 쐈을 떄 빛을 얼마나 받을 수 있는, 구름에 의해서 빛이 얼마나 가려지는지를 모든 곳에 대해서 계산되어 있다. → 초록 지점에서 빛을 쏠 필요가 없어졌다.

### 주의할 점

만약, 애니메이션, 움직이면

density가 바뀌면, light도 변해야 한다.

# VDB, 공간 분할

최적화는 자료구조, 알고리즘 해야 한다.

정밀도를 높이려면, 데이터를 많이 저장해야 한다.

![Untitled](attachments/Untitled%206.png)

기존에 해던 것은 왼쪽이다. 이것에는 단점이 있다.

랜더링을 안해도 되는 부분이 있다.

오른쪽은 모든 부분을 랜더링 하지 않는다.

3d 텍스처를 여러개 사용 한다.

전체를 쪼개서, 사각형을 분해해서 랜더링한다.

공간을 분활해서 랜더링 하는 것이다. → 이것이 공간 분할이다.

트리 구조로 만들 수 있다.

OpenVDB가 사용된다.

NanoVDB는 엔비디아에서 사용된다.

게임은 언리얼을 보면 좋다.

# SDF

가상의 구가 있다고 생각하고,

구에서 멀어질 수록, density가 줄어드는 것으로 구현할 수 있다.

볼룸의 가중치를 주어서 할 수 있다. 원하는 물체에만 할 수 있다.

### 이론

직접적으로 원을 사용하는 방식은 거의 없다.

![Untitled](attachments/Untitled%207.png)

거의 함수를 사용해서 만든다.

예를 들어 원의 방정식을 이용해서, 원을 그린다. (Implicit surface)

[Signed distance function](https://en.wikipedia.org/wiki/Signed_distance_function)

안쪽과 바깥쪽의 부호를 다르게 해서 표현한다.