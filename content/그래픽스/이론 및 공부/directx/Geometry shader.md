# Geometry shader

[기하 도형 셰이더 개체 - Win32 apps](https://learn.microsoft.com/ko-kr/windows/win32/direct3dhlsl/dx-graphics-hlsl-geometry-shader)

지오메트리 셰이더는 버텍스 셰이더에서는 할 수 없는 점이나, 선, 삼각형 등의 도형을 생성할 수 있는 기능이 있다.

SV_VertexID : 버텍스 쉐이더에서 사용할 수 있는 vertex index 같은 것이다.

SV_PrimitiveID  : 버텍스에서 계산한 꼭지점 중에서 점,선,삼각형을 이루는 점들에 접근할 수 있는 index이다.

임의로 기하적 쉐이딩을 할 수 있다

기하 쉐이더에서 사용할 수 있다

[Stream-Output](https://learn.microsoft.com/ko-kr/windows/win32/direct3dhlsl/dx-graphics-hlsl-so-type) 

[**Append(DirectX HLSL 스트림 출력 개체)**](https://learn.microsoft.com/ko-kr/windows/win32/direct3dhlsl/dx-graphics-hlsl-so-append)

[RestartStrip(DirectX HLSL Stream-Output 개체)](https://learn.microsoft.com/ko-kr/windows/win32/direct3dhlsl/dx-graphics-hlsl-so-restartstrip)


![[기타/resourse/d3d11-gsinputs1.png]]

지오메트릭을 이해하는데 추가 자료

[System-Generated 값 사용 - Win32 apps](https://learn.microsoft.com/ko-kr/windows/win32/direct3d11/d3d10-graphics-programming-guide-input-assembler-stage-using)

위 사이트 요약하면,

다음 그림에서는 시스템 값이 IA 단계에서 인스턴스화된 삼각형 스트립에 연결되는 방법을 보여 줍니다.

![[그래픽스/이론 및 공부/directx/Geometry shader/d3d10-ia-example.png]]

다음 표는 동일한 삼각형 스트립의 두 인스턴스에 대해 생성되는 시스템 값을 보여줍니다.

- 1번째 파란 삼각형 (인스턴스 U)
- 2번째 녹색 삼각형 (인스턴스 V)

실선은 기본 형식의 꼭짓점을 연결하고 점선은 인접한 꼭짓점을 연결합니다.

다음 표는 **인스턴스 U**에 대해 시스템에서 생성한 값을 보여줍니다.

| 꼭짓점 데이터 | C,U | D,U | E,U | F,U | G,U | H,U | I,U | J,U | K,U | L,U |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| VertexID | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
| InstanceID | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

|  | value | value | value |
| --- | --- | --- | --- |
| PrimitiveID | 0 | 1 | 2 |
| InstanceID | 0 | 0 | 0 |

다음 표는 **인스턴스 V**에 대해 시스템에서 생성한 값을 보여줍니다.

| 꼭짓점 데이터 | C,U | D,U | E,U | F,U | G,U | H,U | I,U | J,U | K,U | L,U |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| VertexID | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
| InstanceID | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |

|  | value | value | value |
| --- | --- | --- | --- |
| PrimitiveID | 0 | 1 | 2 |
| InstanceID | 1 | 1 | 1 |

입력 어셈블러는 ID(꼭짓점, 기본 형식 및 instance)를 생성합니다. 또한 각 instance에 고유한 instance ID가 부여됩니다. 데이터는 삼각형 스트립의 각 instance를 구분하는 스트립 컷으로 끝납니다.