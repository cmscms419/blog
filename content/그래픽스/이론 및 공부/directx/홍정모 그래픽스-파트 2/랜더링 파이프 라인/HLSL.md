# HLSL

[HLSL(High-Level Shader Language) - Win32 apps](https://learn.microsoft.com/ko-kr/windows/win32/direct3dhlsl/dx-graphics-hlsl)

![Untitled](attachments/Untitled_17.png)

# 1. input data를 만들기

- vertex shader
- pixel shader

크게 보면 이 두 개로 볼 수 있다.

shader는 GPU에서 작동하는 프로그램이다.

vertex shader
pixel shader
반드시 만들어야 한다.
둘은 별개의 프로그램이다.

vertex, index 배열을 파이프 라인을 모아서 넣으면 == input-assembler stage

vertex shader에서 처리된 데이터가 pixel shader로 흘러 간다.
두 shader는 데이터를 양방향으로 받지 않는다.
pixel, vertex 서로 따로 컴파일 한다.

```cpp
template <typename T_VERTEX>
void CreateVertexBuffer(const vector<T_VERTEX> &vertices,
                        ComPtr<ID3D11Buffer> &vertexBuffer) {

    // D3D11_USAGE enumeration (d3d11.h)
    // https://learn.microsoft.com/en-us/windows/win32/api/d3d11/ne-d3d11-d3d11_usage

    D3D11_BUFFER_DESC bufferDesc;
    ZeroMemory(&bufferDesc, sizeof(bufferDesc));
    bufferDesc.Usage = D3D11_USAGE_IMMUTABLE; // 초기화 후 변경X
    bufferDesc.ByteWidth = UINT(sizeof(T_VERTEX) * vertices.size());
    bufferDesc.BindFlags = D3D11_BIND_VERTEX_BUFFER;
    bufferDesc.CPUAccessFlags = 0; // 0 if no CPU access is necessary.
    bufferDesc.StructureByteStride = sizeof(T_VERTEX);

    D3D11_SUBRESOURCE_DATA vertexBufferData = {0}; // MS 예제에서 초기화하는 방식
    vertexBufferData.pSysMem = vertices.data();
    vertexBufferData.SysMemPitch = 0;
    vertexBufferData.SysMemSlicePitch = 0;

    const HRESULT hr = m_device->CreateBuffer(
        &bufferDesc, &vertexBufferData, vertexBuffer.GetAddressOf());
    if (FAILED(hr)) {
        std::cout << "CreateBuffer() failed. " << std::hex << hr
                  << std::endl;
    };
}
```

여기서 vertex buffer를 

```cpp
void AppBase::CreateIndexBuffer(const std::vector<uint16_t> &indices,
                                ComPtr<ID3D11Buffer> &m_indexBuffer) {
    D3D11_BUFFER_DESC bufferDesc = {};
    bufferDesc.Usage = D3D11_USAGE_IMMUTABLE; // 초기화 후 변경X
    bufferDesc.ByteWidth = UINT(sizeof(uint16_t) * indices.size());
    bufferDesc.BindFlags = D3D11_BIND_INDEX_BUFFER;
    bufferDesc.CPUAccessFlags = 0; // 0 if no CPU access is necessary.
    bufferDesc.StructureByteStride = sizeof(uint16_t);

    D3D11_SUBRESOURCE_DATA indexBufferData = {0};
    indexBufferData.pSysMem = indices.data();
    indexBufferData.SysMemPitch = 0;
    indexBufferData.SysMemSlicePitch = 0;

    m_device->CreateBuffer(&bufferDesc, &indexBufferData,
                           m_indexBuffer.GetAddressOf());
}
```

indexbuffer를 만든다.

# 2. shader 만들기