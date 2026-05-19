# Depth testing

# Depth testing

- buffer의 한 종류입니다.
- fragment의 정보를 저장하고 (일반적으로) color buffer와 동일한 크기를 가지고 있습니다.

depth buffer는 window 시스템에 의해서 자동적으로 생성되고 깊이 값(depth values)들을 `16`, `24`, `32` 비트 실수형으로 저장합니다. 대부분의 시스템에서 `24` 비트의 깊이 값을 사용한다

### depth testing의 작동 방식

depth testing을 사용가능하게 설정하면 OpenGL은 depth buffer의 내용에 따라 fragment의 깊이 값을 테스트합니다.

1. Opengl이 depth test를 수행하고, test를 통과하면 depth buffer에 새로운 깊이 값이 수정됩니다.
2. 실패하면 해당 fragment 폐기

Depth testing은 fragment shader가 수행된 후, screen space에서 수행됩니다.

screen space 좌표는 OpenGL의 glViewport 함수에서 정의한 viewport와 직접적으로 관련이 있습니다. GLSL에서 gl_FragCoord 변수를 통해서 glViewport함수에서 정의한 x,y 좌표값(screen space 좌표)에 접근할 수 있습니다.

gl_FragCoord 변수는 fragment의 실제 깊이 값을 가지고 있는 z 요소도 포함하고 있습니다. 이 z 값은 depth buffer의 내용과 비교할 값입니다.

최근 대부분의 CPU들은 early depth testing이라고 불리는 기능을 지원합니다.

### **Early depth testing**

**Early depth testing**은 fragment shader를 실행하기 전에 depth test를 수행할 수 있도록 해줍니다. fragment가 보여지지 않게 될때(다른 오브젝트의 뒤에 위치할 때)마다 해당 fragment를 미리 폐기할 수 있습니다.

fragment shader가 깊이 값을 작성하려고 한다면 early depth testing은 불가능해집니다.

early depth testing을 위해서는 fragment shader에서 깊이 값을 작성하지 말아야 합니다. OpenGL이 사전에 깊이 값을 알 수 없습니다.

Fragment shader는 일반적으로 비용을 꽤 많이 차지하므로 실행하는 것을 최소한으로 피할 수 있으면 피해야 합니다.

### depth testing 사용

```cpp
// depth testing 옵션 활성화
glEnable(GL_DEPTH_TEST);
```

활성화가 되면 OpenGL은 자동으로 depth test에 통과하면 fragment의 z 값을 depth buffer에 저장하고 실패하면 fragment를 폐기합니다. 활성화 했다면, 랜더링 루프를 돌 때마다GL_COLOR_BUFFER_BIT를 사용하여 depth buffer를 비워주어야 합니다. 그러지 않으면 마지막 랜더링 루프에서 작성된 depth 값이 쌓이게 됩니다.

```cpp
// 기존의 정보를 지워준다
glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

```

모든 fragment에 대해 depth test를 수행하고 그에 따라 fragment를 폐기하지만 depth buffer를 수정하는 것을 원하지 않을 때도 있을 것입니다. 이럴 때 read-only depth buffer를 사용합니다. OpenGL은 depth mask를 `GL_FALSE`로 설정함으로써 depth buffer에 작성하는 것을 비활성화할 수 있도록 해줍니다.

```cpp
// 임의로 depth buffer를 활성화/비활성화 시킬 수 있습니다.
glDepthMask(GL_FALSE);

```

이 효과는 depth testing을 활성화했을 때에만 사용 가능하다는 것을 알아두세요.

## Depth test 함수

OpenGL은 depth test에서 사용하는 비교 연산을 조정할 수 있도록 해줍니다. 이는 fragment를 어떨 때에 통과 혹은 폐기시켜야할 지를 조정할 수 있도록 하고 또한 depth buffer를 언제 수정해야하는 지에 대해서도 조정할 수 있도록 해줍니다. 우리는 glDepthFunc 함수를 사용하여 비교 연산자(혹은 depth 함수)를 설정할 수 있습니다.

```cpp
glDepthFunc(GL_LESS);

```

이 함수는 아래 표에 있는 여러가지 비교 연산자들을 설정할 수 있습니다.

| 함수 | 설명 |
| --- | --- |
| `GL_ALWAYS` | depth test가 항상 통과됩니다. |
| `GL_NEVER` | depth test가 절대 통과되지 않습니다. |
| `GL_LESS` | fragment의 깊이 값이 저장된 깊이 값보다 작을 경우 통과시킵니다. |
| `GL_EQUAL` | fragment의 깊이 값이 저장된 깊이 값과 동일한 경우 통과시킵니다. |
| `GL_LEQUAL` | fragment의 깊이 값이 저장된 깂이 값과 동일하거나 작을 경우 통과시킵니다. |
| `GL_GREATER` | fragment의 깊이 값이 저장된 깊이 값보다 클 경우 통과시킵니다. |
| `GL_NOTEQUAL` | fragment의 깊이 값이 저장된 깊이 값과 동일하지 않을 경우 통과시킵니다. |
| `GL_GEQUAL` | fragment의 깊이 값이 저장된 깊이 값과 동일하거나 클 경우 통과시킵니다. |

기본값인 GL_LESS는 깊이 값이 현재 depth buffer의 값과 동일하거나 큰 모든 fragment들을 폐기합니다.

## 깊이 값 정확성

Depth buffer는 `0.0`와 `1.0` 사이의 깊이 값을가지고 있고 viewer의 관점에서 scene의 모든 오브젝트들의 z 값과 비교됩니다. 이 view space의 z 값들은 projection 절두체의 `near`와 `far` 사이의 어떠한 값이 될 수 있습니다. 따라서 이러한 view-space z 값들을 `[0,1]` 범위로 변환시키는 방법이 필요합니다.

### 선형

아래 방법 은 1차원 적으로 변환하는 방법입니다. 다음 (일차)방정식은 z 값을 `0.0`와 `1.0` 사이의 값으로 변환시킵니다.

$F_{depth}= \frac {z−near}{far−near}$

여기에서 near 와 far 는 절두체를 설정하기 위해 projection 행렬에 전달해왔던 *near*, *far* 값입니다. 이 방정식은 절두체 내부의 깊이 값 z를 `[0,1]` 범위의 값으로 변환시킵니다. z 값과 해당 깊이 값의 관계는 다음 그래프와 같습니다.

![](attachments/depth_linear_graph.png)

모든 방정식에서 오브젝트가 가까이 있을 때 깊이 값이

```
0.0
```

과 가까워지고 오브젝트가 far 평면에 가까이 있을 때

```
1.0
```

하지만 이와 같은 linear depth buffer는 일반적으로 사용되지 않습니다. 이 방법은 기본적으로 z 값이 작을 때 큰 정밀도를 가지고 z 값이 멀리 있을 때 정밀도가 떨어지게 합니다. 예를 들어, `1000` 단위정도로 멀리 떨어진 오브젝트가 `1` 단위 거리에 있는 매우 상세화된 오브젝트와 동일한 깊이 값을 가지지 않습니다. 이 일차방정식은 이 점을 안중에 두지 않습니다.

### 비선형

이 비선형 함수는 1/z에 비례하고 예를들어 `1.0`와 `2.0` 사이의 z 값을 `0.5`, `1.0` 사이의 깊이 값으로 변환합니다. 이는 작은 z 값에 대해 큰 정밀도를 가지도록 합니다. `50.0`과 `100.0` 사이의 z 값은 정밀도의 2%밖에 차지하지 않습니다. 이는 정확히 우리가 원하는 것입니다. near과 far 거리를 염두하는 이러한 방정식은 다음과 같습니다.

$F_{depth}= \frac
{1/z−1/near}{1/far−1/near}$

이 depth buffer 내부의 값들은 screen-space에서 비선형 입니다. (projection 행렬이 적용되기 전의 view-space에서는 선형적입니다).

![](attachments/depth_non_linear_graph.png)

보시다시피 이 깊이 값들은 작은 z 값에서 큰 정밀도를 가집니다. z 값을 변환시키는 이 방정식은 projection 행렬에 포함되어 있으므로 vertex 좌표를 view에서 clip으로 변환하여 screen-space로 이동할 때 이 비선형 방정식이 적용됩니다.

위 수식에 대한 자세한 풀이과정 : [great article](http://www.songho.ca/opengl/gl_projectionmatrix.html)

이 비선형 방적식의 효과는 depth buffer를 시각화 했을 때 쉽게 확인할 수 있습니다.

**클리핑(절두체 컬링)과 NDC 변환이 모두 GL_PROJECTION** [행렬](http://www.songho.ca/opengl/gl_matrix.html) 에 통합된다는 점

## Z-fighting

두 개의 삼각형이 아주 가깝게 나란히 위치했을 때, 두 개의 삼각형이 겹치면서 이상한 패턴이 보입니다.

depth buffer가 두 삼각형 중 어느 삼각형이 뒤에 있는지 앞에 있는지 판단하기 어려워서 이런 현상이 생깁니다. → 더 세밀하게 정밀도를 계산하지 못해서 그렇습니다.

![](attachments/depth_testing_z_fighting.png)

멀리 있는 도형에서 더 많이 발생합니다(depth buffer는 z 값이 클수록 더 작은 정밀도를 가지기 때문입니다).

예방 방법은 크게 3가지가 있습니다.

### Z-fighting 방지

1. 겹치지 않게 충분한 거리를 유지한다
2. near 평면을 멀리 설정합니다.
    1. 전체 절두체 범위에서 큰 정밀도를 가질 수 있습니다.
    2. 단점으로는 가까이 있는 물체를 보지 못할 수 도 있습니다.
3. 성능을 희생해서, depth buffer의 정밀도를 높입니다.
    1. 보통 24비트의 정밀도를 가지지만, 32비트의 depth buffer를 지원합니다.
