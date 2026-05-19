# MVP (Model, View, Projection)

vertex shader에서 model → view → projection 순서대로 행렬을 곱해준다.

```cpp
pos = mul(pos, model);
pos = mul(pos, view);
pos = mul(pos, projection);
```

# model

```cpp
m_constantBufferData.model =
    Matrix::CreateScale(m_modelScaling) * Matrix::CreateRotationY(m_modelRotation.y) *
    Matrix::CreateRotationX(m_modelRotation.x) * Matrix::CreateRotationZ(m_modelRotation.z) *
    Matrix::CreateTranslation(m_modelTranslation);
m_constantBufferData.model = m_constantBufferData.model.Transpose();
```

# view

```cpp
// m_constantBufferData.view = XMMatrixLookAtLH(m_viewEye, m_viewFocus, m_viewUp);
// 어떤 방향을 보는지를 설정해서 만든다.
m_constantBufferData.view = XMMatrixLookToLH(m_viewEyePos, m_viewEyeDir, m_viewUp);
m_constantBufferData.view = m_constantBufferData.view.Transpose();
```

`m_viewEyePos` ****

- 바라보고 있는 위치
- 값이 변하면 바라보고 있는 위치가 변한다.

`m_viewEyeDir` 

- 바라보고 있는 방향
- 값이 변하면 고개를 돌릴듯한 변화를 줄 수 있다.

`m_viewUp` 

- 보고 있는 방향의 윗쪽 방향
- 값이 변하면 보는 방향 자체가 회전하게 된다.

# projection

```cpp
if (m_usePerspectiveProjection) {
    m_constantBufferData.projection = XMMatrixPerspectiveFovLH(
        XMConvertToRadians(m_projFovAngleY), m_aspect, m_nearZ, m_farZ);
} else {
    m_constantBufferData.projection =
        XMMatrixOrthographicOffCenterLH(-m_aspect, m_aspect, -1.0f, 1.0f, m_nearZ, m_farZ);
}
m_constantBufferData.projection = m_constantBufferData.projection.Transpose();
```

`XMMatrixOrthographicOffCenterLH(-m_aspect, m_aspect, -1.0f, 1.0f, m_nearZ, m_farZ)`

```cpp
XMMATRIX XM_CALLCONV XMMatrixOrthographicOffCenterLH(
  [in] float ViewLeft,
  [in] float ViewRight,
  [in] float ViewBottom,
  [in] float ViewTop,
  [in] float NearZ,
  [in] float FarZ
) noexcept;
```

원근감을 고려하지 않고, 있는 그대로를 투영한다.

![[그래픽스/이론 및 공부/directx/홍정모 그래픽스-파트 2/랜더링 파이프 라인/MVP (Model, View, Projection)/Untitled.png]]

![[그래픽스/이론 및 공부/directx/홍정모 그래픽스-파트 2/랜더링 파이프 라인/MVP (Model, View, Projection)/ViewFrustum2.png]] 

[XMMatrixOrthographicOffCenterLH 함수(directxmath.h) - Win32 apps](https://learn.microsoft.com/ko-kr/windows/win32/api/directxmath/nf-directxmath-xmmatrixorthographicoffcenterlh)

`XMMatrixPerspectiveFovLH(XMConvertToRadians(m_projFovAngleY), m_aspect, m_nearZ, m_farZ)`

```cpp
XMMATRIX XM_CALLCONV XMMatrixPerspectiveFovLH(
  [in] float FovAngleY,
  [in] float AspectRatio,
  [in] float NearZ,
  [in] float FarZ
) noexcept;
```

기본 *AspectRatio* 축은 가로이지만 *AspectRatio*를 사용하여 *FovAngleY*를 다시 계산하면 뷰 배율 방향인 2.0 * atan(tan(FovAngleY * 0.5) / AspectRatio)이 제어됩니다.

원근감을 고려해서 투영한다

![[그래픽스/이론 및 공부/directx/홍정모 그래픽스-파트 2/랜더링 파이프 라인/MVP (Model, View, Projection)/Untitled 1.png]]

![[그래픽스/이론 및 공부/directx/홍정모 그래픽스-파트 2/랜더링 파이프 라인/MVP (Model, View, Projection)/ViewFrustum1.png]]

[XMMatrixPerspectiveFovLH 함수(directxmath.h) - Win32 apps](https://learn.microsoft.com/ko-kr/windows/win32/api/directxmath/nf-directxmath-xmmatrixperspectivefovlh)