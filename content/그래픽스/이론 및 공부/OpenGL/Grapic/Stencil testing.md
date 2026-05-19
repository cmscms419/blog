# Stencil testing

정의 및 수행되는 순서

1. Fragment shader가 fragment를 처리하고 나면 stencil test 수행됩니다. 
2. fragment가 폐기될지 안될지 테스트하는 것입니다. 
3. 그런 후 남아있는 fragment는 dpeth test로 보내져 폐기될지 안될지를 또 한번 테스트됩니다. 

stencil test는 stencil buffer라고 불리는 buffer를 기반으로 수행됩니다. 

이 buffer는  렌더링 동안에 수정할 수 있습니다.

Stencil buffer는 (일반적으로) `8` 비트의 stencil value를 가지고 있고 이 값은 pixel/fragment마다 `256`개의 값으로 나타내어집니다. 

stencil 값을 임의로 설정하여 특정한 stencil 값을 가지고 있는 특정 fragment를 폐기할지 유지할지를 정할 수 있습니다.

각 window 라이브러리들은 stencil buffer를 세팅해야만 작동합니다. GLFW는 이를 자동적으로 해주기때문에 우리는 GLFW에게 생성하라고 지시할 필요가 없습니다. 하지만 다른 window 라이브러리들은 기본값으로 stencil을 생성하지 않을수도 있으므로 라이브러리 문서를 확인해야합니다.

### Stencil buffer의 작동하는 순서

Stencil buffer의 간단한 예제는 다음과 같습니다.

![](attachments/stencil_buffer.png)

이 stencil buffer는 먼저 `0`으로 채워지고나서 속이 비어있는 사각형 모양의 `1`을 설정합니다. 그러면 이 scene의 fragment들 중에서 stencil 값이 `1`인 fragment들만 렌더링됩니다(다른 것들은 폐기됩니다).

Stencil buffer는 우리가 fragment를 렌더링해야할 곳에 특정 값을 설정할 수 있도록 합니다. 

렌더링하는 도중에 stencil buffer를 수정함으로써 우리는 stencil buffer를 작성합니다. 

동일한 렌더링 루프에서 우리는 특정 fragment들을 폐기하거나 유지하기위해서 이 값들을 읽을 수 있습니다.

stencil buffer를 여러분 마음대로 사용할 수 있지만 다음과 같은 규칙들이 있습니다.

- stencil buffer 작성 활성화
- 오브젝트 렌더링, stencil buffer 수정
- stencil buffer 작성 비활성화
- stencil buffer를 기반으로 특정 fragment를 폐기하여 오브젝트 렌더링

Stencil buffer를 사용함으로써 scene에 그려진 다른 오브젝트의 fragment들을 기반으로하여 특정 fragment를 폐기시킬 수 있습니다.

### Stencil testing 사용

GL_STENCIL_TEST를 활성화하여 stencil testing을 활성화시킬 수 있습니다. 이 시점부터 호출되는 모든 렌더링 명령은 stencil buffer의 영향을 받습니다.

```
glEnable(GL_STENCIL_TEST);

```

또한 color, depth buffer와 마찬가지로 매 렌더링 루프마다 stencil buffer를 비워주어야 한다는 것을 알아두세요.

```
glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

```

### glStencilMask 함수

glStencilMask 함수는 곧 buffer에 작성될 stencil 값에 `AND` 연산을 시킬 bitmask를 설정할 수 있도록 해줍니다. 

기본값으로 bitmask는 모두 `1`로 설정되어 출력에 아무런 영향을 주지않습니다. 

이것을 `0x00`으로 설정하면 buffer에 작성되는 모든 stencil 값들은 `0`이 됩니다. 이는 dpeth testing의 glDepthMask(GL_FALSE) 함수와 비슷합니다.

Stencil buffer의

```cpp
glStencilMask(0xFF);// 각 비트들은 stencil buffer 그대로 작성됩니다.
glStencilMask(0x00);// 각 비트들은 stencil buffer에 0으로 작성됩니다(작성 비활성화).
```

보통 stencil mask를 `0x00`나 `0xFF`로 설정합니다. 하지만 임의의 bitmask들을 설정할 수 있는 옵션들도 존재합니다.

## Stencil 함수

Depth testing과 마찬가지로 stencil test를 통과시킬지 말지에 대한 기준을 설정할 수 있습니다. stencil testing을 설정할 수 있는 총 2개의 함수가 있습니다. 

- glStencilFunc 함수
- glStencilOp 함수

### glStencilFunc

오직 OpenGL이 stencil buffer의 내용으로 무엇을 해야하는지에 대해서만 제어할 수 있습니다.

glStencilFunc(GLenum `func`, GLint `ref`, GLuint `mask`) 함수는 3개의 파라미터를 가지고 있습니다.

- `func`: stencil test 함수를 설정합니다. 이 test 함수는 저장된 stencil 값과 glStencilFunc 함수의 `ref` 값에 적용됩니다. 가능한 옵션은 GL_NEVER , GL_LESS , GL_LEQUAL , GL_GREATER
, GL_GEQUAL, GL_EQUAL, GL_NOTEQUAL, GL_ALWAYS 가 있습니다. 이 것들의 의미는 depth buffer의 함수들과 비슷합니다.
- `ref`: stencil test에 대한 레퍼런스 값을 지정합니다. stencil buffer의 내용은 이 값과 비교됩니다.
- `mask`: 테스트가 완료될 때 저장된 stencil 값과 `ref`를 모두 AND(논리합)로 지정하는 `mask` 를 지정합니다. 초기 값은 모두 1입니다

예제)

```cpp
glStencilFunc(GL_EQUAL, 1, 0xFF)

```

 OpenGL에게 fragment의 stencil 값이`ref` 값 `1`과 동일하다면 test를 통과시킨 후 렌더링하고 그렇지 않으면 폐기하라고 지시합니다.

### glStencilOp

buffer를 수정할 수 있습니다.

glStencilOp(GLenum `sfail`, GLenum `dpfail`, GLenum `dppass`) 함수는 3개의 옵션을 가지고 있고 각 옵션들에 대해 취해질 액션들을 설정할 수 있습니다.

- `sfail`: stencil test가 실패하였을 때 취할 행동
- `dpfail`: stencil test가 통과했지만 depth test는 실패했을 때 취할 행동
- `dppass`: stencil, depth test 모두 통과했을 때 취할 행동

각 옵션들에 대해 다음과 같은 행동들을 설정할 수 있습니다.

| 행동 | 설명 |
| --- | --- |
| `GL_KEEP` | 현재 저장된 stencil 값을 유지 |
| `GL_ZERO` | stencil 값을 `0`으로 설정 |
| `GL_REPLACE` | stencil 값을 glStencilFunc 함수에서 지정한 레퍼런스 값으로 설정 |
| `GL_INCR` | 최댓값보다 작다면 stencil 값을 `1`만큼 증가시킴 |
| `GL_INCR_WRAP` | GL_INCR와 같지만 최댓값을 초과하면 `0`로 돌아옴 |
| `GL_DECR` | 최솟값보다 크다면 stencil 값을 `1`만큼 감소시킴 |
| `GL_DECR_WRAP` | GL_DECR와 같지만 `0`보다 작다면 최댓값으로 설정함 |
| `GL_INVERT` | 현재 stencil buffer 값의 비트를 뒤집음 |

glStencilOp 함수의 기본값은 `(GL_KEEP, GL_KEEP, GL_KEEP)`이므로 test의 결과가 어떻든 stencil buffer의 값은 유지됩니다.

그래서 glStencilFunc 함수와 glStencilOp 함수를 사용하면 언제 그리고 어떻게 stencil buffer를 수정해야 하는지를 정확히 지정할 수 있고 또한 언제 stencil test가 통과하거나 실패할지도 지정할 수 있습니다.