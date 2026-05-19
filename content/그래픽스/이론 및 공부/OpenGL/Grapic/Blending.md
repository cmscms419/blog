# Blending

우리는 여러 오브젝트들의 여러가지 컬러들을 하나의 컬러로 blend(섞다)하기 때문에 이를 blending이라고 부릅니다. 따라서 투명도는 다음과 같은 결과를 보여줍니다.

![](attachments/blending_transparency.png)

## Fragments 폐기

일부분의 fragment를 쓰지 않습니다.

완전히 불투명(alpha 값이 `1.0`)하거나 완전히 투명(alpha 값이 `0.0`)한 텍스처 입니다.

![](attachments/grass.png)

평범하게 텍스처를 붙이면, 이렇게 보입니다.

![](attachments/blending_no_discard.png)

GLSL은 (호출한 후부터) 더이상 fragment가 처리되지 않고 color buffer에 저장하지 않게 해주는 `discard` 명령이 있습니다. 이 명령 덕분에 우리는 fragment shader가 alpha 값을 가지고 있는지 확인할 수 있고 가지고 있다면 fragment를 폐기하도록 할 수 있습니다.

```glsl
#version 330 coreout vec4 FragColor;

in vec2 TexCoords;

uniform sampler2D texture1;

void main()
{
    vec4 texColor = texture(texture1, TexCoords);
    if(texColor.a < 0.1)
        discard;
    FragColor = texColor;
}
```

샘플링된 텍스처 컬러가 `0.1`보다 작은 alpha 값을 가지고 있는지 확인하고 그렇다면 fragment를 폐기합니다. 이 fragment shader는 완전히 투명하지 않은 fragment만 렌더링합니다. 이제 다음과 같은 결과를 볼 수 있을 것입니다.

![](attachments/blending_discard.png)

텍스처의 모서리를 샘플링 할 때 OpenGL은 모서리를 텍스처가 반복되는 다음 텍스처의 모서리로 보간합니다

→ 투명한 값을 사용하기 있기때문에 텍스처 이미지의 윗부분에 텍스처 이미지의 바닥 컬러와 보간된 값이 보여지게 됩니다.

이 결과는 여러분의 텍스처 사각형 주위를 감싸는 모서리가 완전히 투명하지 않게 만들 수 있습니다. 이를 방지하기 위해 alpha 텍스처를 사용할때마다 텍스처 wrapping 방법을

GL_CLAMP_TO_EDGE

로 설정하세요.

```
glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
```

## Blending

```cpp
// Blending 활성화
glEnable(GL_BLEND);
```

blending을 활성화했으므로 OpenGL에게 실제로 **어떻게** 섞어야할지를 말해주어야합니다.

OpenGL에서 blending은 다음의 방정식을 사용하여 수행됩니다.

$C_{result} = C_{source} * F_{result} + C_{destination} * F_{destination}$

- $C_{source}$:        원본 컬러 벡터. 이 것은 텍스처의 원본 컬러 벡터입니다.
- $C_{destination}$: 목적 컬러 벡터. 이 것은 컬러 버퍼에 현재 저장된 컬러 벡터입니다.
- $F_{result}$:         원본 지수 값. 원본 컬러 alpha 값의 영향력을 설정합니다.
- $F_{destination}$: 목적 지수 값. 목적 컬러 alpha 값의 영향력을 설정합니다.

### 그리는 방법

![](attachments/blending_equation.png)

1. 녹색 사각형에 alpha 값을 곱하기 원하므로 $F_{src}$값을 원본 컬러 벡터의 alpha 값인 `0.6`으로 설정합니다.
2. 녹색 사각형이 60%의 영향력을 가지고 있다면 빨간 사각형은 40%(`1.0 - 0.6`)의 영향력을 가지기를 원합니다. 그래서 우리는 $F_{destination}$ 값을 1 - (원본 컬러 벡터의 alpha 값 `0.6`)으로 설정합니다. 따라서 이 방정식은 다음과 같습니다.

![Untitled](attachments/Untitled_17.png)

이 결과는 60%의 녹색과 40%의 빨간색을 포함하고 있는 혼합된 사각형 fragment들입니다.

![](attachments/blending_equation_mixed.png)

최종 컬러는 컬러 버퍼에 저장되어 이전의 컬러를 대체합니다.

### Code

**glBlendFunc** 함수는 픽셀 산술 연산을 지정합니다

```cpp
void glBlendFunc(
	GLenum sfactor,
 	GLenum dfactor);
```

glBlendFunc(GLenum sfactor, GLenum dfactor) 함수는 두개의 파라미터로 원본 지수와 목적 지수에 대한 옵션을 설정합니다. 상수 컬러 벡터 $C_{constant}$는 glBlendColor 함수를 통해 별도로 설정할 수 있습니다.

GL_ZERO						지수를 0으로 설정합니다.
GL_ONE						지수를 1로 설정합니다.
GL_SRC_COLOR				지수를 원본 컬러 벡터 C¯source
GL_ONE_MINUS_SRC_COLOR		지수를 1 - (원본 컬러 벡터 C¯source)로 설정합니다.
GL_DST_COLOR				지수를 목적 컬러 벡터 C¯destination로 설정합니다.
GL_ONE_MINUS_DST_COLOR		지수를 1 - (목적 컬러 벡터 C¯destination)로 설정합니다.
GL_SRC_ALPHA				지수를 원본 컬러 벡터 C¯source의 alpha 요소로 설정합니다.
GL_ONE_MINUS_SRC_ALPHA		지수를 1- (원본 컬러 벡터 C¯source의 alpha 요소)로 설정합니다.
GL_DST_ALPHA				지수를 목적 컬러 벡터 C¯destination의 alpha 요소로 설정합니다.
GL_ONE_MINUS_DST_ALPHA		지수를 1 - (목적 컬러 벡터 C¯destination의 alpha 요소)로 설정합니다.
GL_CONSTANT_COLOR			지수를 상수 컬러 벡터 C¯constant로 설정합니다.
GL_ONE_MINUS_CONSTANT_COLOR	지수를 1 - (상수 컬러 벡터 C¯constant)로 설정합니다.
GL_CONSTANT_ALPHA			지수를 상수 컬러 벡터 C¯constant의 alpha 요소로 설정합니다.
GL_ONE_MINUS_CONSTANT_ALPHA	지수를 1 - (상수 컬러 벡터 C¯constant의 alpha 요소)로 설정합니다.

**glBlendFunc** 예시)

방금 전 두개의 사각형에 대한 blending 효과를 얻기 위해 원본 지수로 원본 컬러 벡터의 **alpha** 값을 취하고 목적 지수로 **1 - alpha**를 취합니다. 이를 glBlendFunc 함수로 나타내면 다음과 같습니다.

```cpp
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
```

RGB와 alpha 채널을 다른 옵션으로 따로 설정하는 것도 가능합니다. glBlendFuncSeparate 함수를 사용하면 됩니다.

![Untitled](attachments/Untitled%201.png)

```cpp
glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ZERO);
```

이 함수는 결과 alpha 요소를 원본 alpha 값에 영향을 받게 하는 것 뿐만 아니라 RGB 요소들에 대해서도 설정합니다.

심지어 OpenGL은 방정식의 원본과 목적 부분 사이의 연산자를 바꿀 수 있도록 해줍니다. 지금 당장은 원본 요소와 목적 요소가 서로 더해집니다. 하지만 원한다면 뺄셈을 할 수도 있습니다. glBlendEquation(GLenum mode) 함수는 이 연산자를 3가지 옵션을 통해 설정할 수 있게 해줍니다.

- `GL_FUNC_ADD`: 기본값으로서 두 개의 요소를 서로 더합니다: Source + Destination
- `GL_FUNC_SUBTRACT`: 두 개의 요소를 서로 뺍니다: Source - Destination
- `GL_FUNC_REVERSE_SUBTRACT`: 순서를 반대로 하여 두 개의 요소를 서로 뺍니다: Destination - Source

일반적으로 glBlendEquation 함수는 사용하지 않습니다. GL_FUNC_ADD가 대부분의 연산에 필요한 방정식이기 때문이죠 하지만 여러분이 원래의 방식을 깨트리고 싶다면 다른 방정식이 여러분에게 맞을 것입니다.

## 반투명 텍스처 렌더링

OpenGL이 blending을 어떻게 수행하는지 알았으므로 여러 반투명 창문을 추가하여 테스트해 볼 시간입니다. 이 강좌의 시작에서 사용했던 scene을 사용할 것입니다. 하지만 잔디 테스처를 렌더링하는 대신 [반투명 창문](https://learnopengl.com/img/advanced/blending_transparent_window.png) 텍스처를 사용할 것입니다.

먼저, blending을 활성화하고 적절한 blending 함수를 설정하여 초기화합니다.

```cpp
glEnable(GL_BLEND);
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
```

blending을 활성화했기 때문에 fragment를 폐기할 필요 없으므로 fragment shader를 원래의 버전으로 수정합니다.

```glsl
#version 330 coreout vec4 FragColor;

in vec2 TexCoords;

uniform sampler2D texture1;

void main()
{
    FragColor = texture(texture1, TexCoords);
}

```

이번에는(OpenGL이 fragment를 렌더링할때마다) alpha 값을 기반으로 하여 현재 fragment의 컬러와 color buffer에 저장되어 있는 fragment 컬러를 혼합합니다. 창문 텍스처의 유리 부분이 반투명이기 때문에 창문의 뒷 배경을 볼 수 있어야 합니다.

![](attachments/blending_incorrect_order.png)

### 제대로 투명이 안됩니다.

이 이유는 depth testing이 blending과 함께 사용되기 곤란하기 때문입니다. depth buffer를 작성할 때 이 fragment가 투명한지 투명하지 않은지를 생각하지 않고 작성됩니다. 이 결과 창문의 전체 사각형은 투명도에 아무 관계없이 depth testing이 수행됩니다. 투명한 부분이 창문 뒤의 배경을 보일 수 있도록 해야함에도 불구하고 depth test는 그들을 폐기해버립니다.

그래서 우리는 창문들을 간단하게 렌더링할 수 없지만 이를 해결하고 싶습니다. 창문 뒤가 보일 수 있게 하기위해서는 뒤에 있는 창문들을 먼저 그려야합니다. 이는 우리가 직접 가까운 창문에서 먼 창문까지 정렬하여 그려야한다는 것을 의미합니다.

완전히 투명한 오브젝트와는 그들을 혼합하는 것이 아닌 간단히 fragment를 폐기하는 방법이 있었습니다. 이는 depth 문제에 대해서 생각하지 않아도 됩니다.

## 순서를 어기지 마세요

→ 그리는 순서에 따라서, depth test 통과 여부가 달라집니다.

그리는 순서에 따라서, 저장되는 값이 달라집니다.

여러 오브젝트들로 blending 작업을 하기 위해 우리는 멀리 있는 오브젝트를 먼저 그리고 가까이에 있는 오브젝트를 나중에 그려야 합니다. 일반적인 blend 되지 않은 오브젝트들은 depth buffer를 사용하여 평소대로 그려지게 되므로 그들은 정렬할 필요가 없습니다. (정렬된) 투명한 오브젝트들을 그리기 전에 먼저 그려주어야 합니다. 투명하지 않은 오브젝트와 투명한 오브젝트들이 공존하는 scene을 그릴 때의 일반적인 과정은 다음과 같습니다.

1. 모든 불투명한 오브젝트들을 먼저 그립니다.
2. 모든 투명한 오브젝트들을 정렬합니다.
3. 모든 투명한 오브젝트들을 정렬한 순서대로 그립니다.

투명한 오브젝트들을 정렬하는 방법 중 하나는 시점으로부터 오브젝트까지의 거리를 얻는 것입니다. 이는 카메라의 위치 벡터와 오브젝트의 위치 벡터 사이의 거리를 취하여 얻을 수 있습니다. 그런 다음 이 거리 값을 위치 벡터와 함께 STL 라이브러리의 map 자료 구조에 저장합니다. map은 key 값을 기반으로 자동으로 정렬해줍니다. 그래서 거리 값을 key 값으로 삽입하고 그에 해당하는 모든 위치 값을 삽입한다면 자동적으로 거리에 따라 정렬이 됩니다.

```cpp
std::map<float, glm::vec3> sorted;
for (unsigned int i = 0; i < windows.size(); i++)
{
    float distance = glm::length(camera.Position - windows[i]);
    sorted[distance] = windows[i];
}

```

결과는 distance key 값을 기반으로 짧은 거리부터 먼 거리까지 정렬된 순서의 창문 위치가 저장된 객체입니다.

그런 다음 이번에는 렌더링 할 때 map의 값을 반대 순서(먼 창문에서 가까운 창문으로)로 취하고 해당 창문들을 그립니다.

```cpp
for(std::map<float,glm::vec3>::reverse_iterator it = sorted.rbegin(); it != sorted.rend(); ++it)
{
    model = glm::mat4();
    model = glm::translate(model, it->second);
    shader.setMat4("model", model);
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

```

우리는 map으로부터 reverse iterator를 얻어 요소들을 반대 순서로 얻고 각 창문 사각형들을 해당 창문 위치로 이동시킵니다. 이는 방금 언급한 문제를 해결하기 위해 투명한 오브젝트들을 정렬하는 비교적 간단한 방법입니다. 이제 scene은 다음과 같이 보일 것입니다.

![](attachments/blending_sorted.png)
