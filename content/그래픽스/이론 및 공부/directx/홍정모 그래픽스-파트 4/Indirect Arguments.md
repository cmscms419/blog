# Indirect Arguments

엔진에서 D3D12로 최적화할 때, 기본으로 많이 사용된다.

기본 사용 방법

**DrawIndexed**

→ 똑같은 것을 그릴 때, 예로 위치를 조금 바꿔서 그릴 때

그냥 draw버전은 없다.

```cpp
void DrawInstanced(
  [in] UINT VertexCountPerInstance, // 하나당 vertex가 몇 개
  [in] UINT InstanceCount,          // 그런 인스턴스가 몇 개
  [in] UINT StartVertexLocation, // 보통 0
  [in] UINT StartInstanceLocation// 보통 0
);
```

draw 숫자를 넣을 때 cpu에 넣어주었다.

이것은 호출 할 때 데이터를 미리 gpu에 넘겨주고, 포인터 처럼 간접적으로 주소값을 넘겨주는 것으로 생각하면 된다.

→ vertex를 몇 개 그릴 지를 GPU에서 정할 수 있다.

진정한 의미

그때그때 GPU에서 업데이트를 할 수 있다.

몇 개를 그릴지를 컴퓨터 쉐이더를 사용해서 고려해서 사용할 수 있다.

## Frustum Culling

시야 안에 객체가 있다.

![Untitled](attachments/Untitled_17.png)

눈에 안 보이는 것은 안 그리는 방법을 통해서 랜더링 속도를 높일 수 있다

그릴, 안그릴 객체가 수시로 변한다.

걸쳐있는 것까지 그려야 한다.

그럴 때마다 GPU에 데이터를 넘기는 것은 낭비이다.

그릴 물체만 찾아서, Draw하는 경우도 많다.

이것은 CPU에서 판단하는 경우도 있다.

이 Frustom culling을 GPU에서 수행 할 수 있다.

몇개를 그릴지도 GPU에서 처리 할 수 있다.

이것을 구현하는 방법은 **Indirect Arguments**를 사용하는 것이 좋을 수 있다.

**BoundingFrustum**

cpu에서 계산할 때

→ 충돌 체크 할 수 있다.

→ 물체 단위로 진행한다.

→ 물체를 감싸는 도형을 체크를 한다.

![Untitled](attachments/Untitled%201.png)

이 네모난 부분은 bounding box 라고 한다.