# struct buffer

간단하게 요약하면 구조체를 사용하는 버퍼를 GPU에 사용할 수 있다.

cpu와 gpu에 구조체를 쓸 수 있게 할 수 있다.

```cpp
m_particles.m_cpu.resize(25600); // 실제 데이터를 값이다.
...
// Vertex Shader
const vector<D3D11_INPUT_ELEMENT_DESC> inputElements = {
    {"POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0,
     D3D11_INPUT_PER_VERTEX_DATA, 0}}; 
// Dummy -> 렌더링을 한다. 실제로 사용하지 않는다. 
// 이 부분은 그래픽스 파이프라인을 정의하려고 만든 것이다. 실제는 m_particles에 있다.
D3D11Utils::CreateVertexShaderAndInputLayout(
    m_device, L"Ex1404_StructuredBufferVS.hlsl", inputElements,
    m_vertexShader, m_inputLayout);
```

### Rendering

```cpp
void Ex1404_StructuredBuffer::Render() {

    // Timer timer(m_device);
    // timer.Start(m_context, true);

    // Compute Shader에서 Particle 위치 변경
    // 컴퓨터 쉐이더를 사용해서 파티클 위치를 애니메이션 시켜준다.
    // struct 배열은 1차원 배열처럼 사용가능하다.
    // 전체 사이즈로 나눠서 컴퓨터 쉐이더가 사용할 수 있게 만드는 것이다.
    // 파티클의 그룹 개수가 현재는 100개이다. 25600이라서
    m_context->CSSetUnorderedAccessViews(0, 1, m_particles.GetAddressOfUAV(),
                                         NULL);
    m_context->CSSetShader(m_computeShader.Get(), 0, 0);
    m_context->Dispatch(UINT(ceil(m_particles.m_cpu.size() / 256.0f)), 1, 1);
    AppBase::ComputeShaderBarrier();

    // timer.End(m_context); // GPU: 0.00672, CPU: 15.6909

    // Vertex/Particle shader에서 Rendering

    // 주의: m_context->IASetInputLayout(.) 미사용
    // 주의: m_context->IASetVertexBuffers(.) 미사용

    AppBase::SetMainViewport();
    const float clearColor[4] = {0.0f, 0.0f, 0.0f, 1.0f};
    m_context->ClearRenderTargetView(m_backBufferRTV.Get(), clearColor);
    m_context->OMSetRenderTargets(1, m_backBufferRTV.GetAddressOf(), NULL);
    m_context->VSSetShader(m_vertexShader.Get(), 0, 0);
    m_context->PSSetShader(m_pixelShader.Get(), 0, 0);
    m_context->CSSetShader(NULL, 0, 0);

    m_context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_POINTLIST);

    // StructuredBuffer<Particle> particles : register(t0);
    m_context->VSSetShaderResources(0, 1, m_particles.GetAddressOfSRV());
    // vertex shader한테, 버텍스의 개수만 알려준다.
    m_context->Draw(UINT(m_particles.m_cpu.size()), 0);
}
```

위 렌더링 부분의 특징

- 버텍스 쉐이더, 픽셀 쉐이더, 컴퓨터 쉐이더를 사용한다.
- 컴퓨터 쉐이더가 벡버퍼를 직접 사용하지 않는다.
    - 렌더링에 필요한 데이터를 업데이트하는 상황이다.
    - 꼭 float가 아니여도 된다.
- CS → VS → PS 순서로 생각하면 된다.

### Vertex Shader

```cpp
struct PSInput // GS가 있다면 GSInput으로 사용됨
{
    float4 position : SV_POSITION;
    float3 color : COLOR;
};

// struct가 있다.
// CPU와 대응된다.
// 내부적으로 배열처럼 연이어서 사용할 수 있다.
// 25600개가 반복되는 일차원 배열처럼 사용할 수 있는 파티클들이 들어오게된다. register 0번 자라에 들어오게 된다.
struct Particle
{
    float3 position;
    float3 color;
};

StructuredBuffer<Particle> particles : register(t0);

// VSInput이 없이 vertexID만 사용
// Draw를 할 때, 0 ~ m_cpu size까지 다 들어오게 된다.
// GPU내부에서는 순서 상관없이 들어온다.
 
PSInput main(uint vertexID : SV_VertexID)
{
    // vertexID : index
    // particles : cpu에서 가져온 구조체 배열
    // StructuredBuffer를 구조체 배열처럼 사용할 수 있다.
    // 정보를 가져올 수 있다.
    // 임의의 index 값으로 가져올 수 있다.
    // ID는 참고, 어디서는 StructuredBuffer를 통해서 가져올 수 있다.
    // 최적화 관점에서 제약을 가야하는 편이 최적화 면에서 좋다.
    Particle p = particles[vertexID];
    
    PSInput output;
    
    output.position = float4(p.position.xyz, 1.0);
    
    output.color = p.color;

    return output;
}
```

단순히 CS에서 계산한 결과를 넘겨주는 역할을 한다.

### Compute Shader

```cpp
struct Particle
{
    float3 pos;
    float3 color;
};

static float dt = 1 / 60.0; // ConstBuffer로 받아올 수 있음

// 버텍스 버퍼가 했던 거처럼  StructuredBuffer를 받아올 수 있다.
// 하지만 이것은 읽을 수 만 있다.
// 버텍스 쉐이더는 u0로 받아 올 수 없다.
// 필요한 정보를 보내는 역할을 수행한다.
// 지오메트릭 픽셀 쉐이더 한테 필요한 데이터를 보내주는 역할을 한다.
// StructuredBuffer<Particle> inputParticles : register(t0); // SRV로 사용 가능

// 읽기. 쓰기도 가능하다.
RWStructuredBuffer<Particle> outputParticles : register(u0);

[numthreads(256, 1, 1)]
void main(int3 gID : SV_GroupID, int3 gtID : SV_GroupThreadID,
          uint3 dtID : SV_DispatchThreadID)
{
    Particle p = outputParticles[dtID.x]; // Read
    
    float3 velocity = normalize(float3(-p.pos.y, p.pos.x, 0.0));
    p.pos += velocity * dt;
    
    //읽고, 바꾼 위치를 저장한다.
    outputParticles[dtID.x].pos = p.pos; // Write
}
```

픽셀 쉐이더에서는 단순히 픽셀에 대해서 색깔을 입혀주는 역할을 한다.

### 쉐이더 의미

- 컴퓨터 쉐이더에서는 애니메이션 효과까지 계산해서 넘겨준다.

![[Untitled]]

![[Untitled]]

컴퓨터 쉐이더를 통해서, 애니메이션 효과를 줄 수 있다.