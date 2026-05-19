# Framebuffer

지금까지 우리가 수행했던 렌더링 작업들은 모두 기본 framebuffer에 있는 렌더 buffer의 위에서 동작되었습니다.

렌더링 작업들은 모두 기본 framebuffer에 있는 렌더 buffer의 위에서 동작되었습니다. 

기본 framebuffer는 여러분이 윈도우 창을 생성할 때 생성됩니다(GLFW가 자동으로 해줍니다).

**Buffer란 OpenGL이 관리하는 memory 영역**을 말한다.

framebuffer를 임의로 생성 할 수 있습니다. 

→ **framebuffer object(FBO)라고 합니다.**

FBO는 하나 또는 **다수의 buffer들이 attach되어 있는 형태**로 존재한다.

(**color, depth, stencil buffer**)

엄밀히 말하면,  **aggregator**에 ****가깝습니다

## Framebuffer 생성

OpenGL의 다른 객체들과 마찬가지로 glGenFramebuffers 라고 불리는 함수를 사용하여 framebuffer 객체(FBO)를 생성할 수 있습니다.

```cpp
unsigned int fbo;
glGenFramebuffers(1, &fbo);

```

이러한 객체 생성과 사용법은 다른 객체들과 비슷합니다. 

1. framebuffer 객체를 생성
2. 바인딩하여 framebuffer를 활성화시킵니다. 
3. 그 후에 조작
4. framebuffer를 언바인딩합니다. framebuffer를 바인딩하기 위해 glBindFramebuffer 함수를 사용합니다.

```cpp
glBindFramebuffer(GL_FRAMEBUFFER, fbo);
```

GL_FRAMEBUFFER 타겟에 바인딩함으로써 이후에 나오는 모든 framebuffer *읽기*, *작성* 명령이 현재 바인딩된 framebuffer에 영향을 미칩니다. 

또한 framebuffer를 각각 GL_READ_FRAMEBUFFER 또 GL_DRAW_FRAMEBUFFER에 바인딩하여  읽기 또는 쓰기 대상에 framebuffer를 바인딩하는 것도 가능합니다

- GL_READ_FRAMEBUFFER에 바인딩된 framebuffer는 glReadPixels 과 같은 모든 읽기 명령에 사용됩니다.
- GL_DRAW_FRAMEBUFFER에 바인딩된 framebuffer는 렌더링, 비우기, 다른 작성 연산에 대한 목적지로서 사용됩니다.

대부분의 경우에 여러분의 이렇게 분리할 필요가 없고 일반적으로 GL_FRAMEBUFFER에 바인딩합니다.

framebuffer를 사용하기 위해서는 아래의 요구사항을 만족해야합니다.

- 최소한 하나의 buffer(color, depth 혹은 stencil buffer)를 첨부해야 합니다.
- 최소한 하나의 color 첨부가 존재해야 합니다.
- 모든 첨부 buffer들은 완전해야 합니다(메모리가 할당).
- 각 buffer들은 sample의 갯수가 같아야 합니다.

요구사항에 따르면 framebuffer에 대한 첨부할 것들을 생성하고 첨부해야 합니다. 

모든 첨부들을 완료한 후에 glCheckFramebufferStatus 함수에 GL_FRAMEBUFFER를 인자로 넘겨주어 호출하여 실제로 완성되었는지 확인할 수 있습니다.

```cpp
// 제대로 만들었는지 확인한다.
if(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE)
```

이후의 모든 렌더링 작업들은 이제 현재 바인딩된 framebuffer에 첨부된 것들에 렌더링하게 됩니다. FBO는 기본 framebuffer가 아니기 때문에 렌더링 명령들이 여러분의 윈도우창의 출력에 아무런 영향을 주지 않습니다. 이러한 이유에서 다른 framebuffer에 렌더링하는 것을 off-screen 렌더링이라고 부릅니다. 모든 렌더링 작업들을 메인 윈도우창에 나타내기 위해 `0`을 바인딩하여 다시 기본 framebuffer를 활성화 시켜야 합니다.

```cpp
glBindFramebuffer(GL_FRAMEBUFFER, 0);
```

모든 framebuffer 작업을 완료하면 framebuffer를 제거하는 작업

```cpp
glDeleteFramebuffers(1, &fbo);
```

완전히 생성되었는지를 확인하기전에 우리는 하나 이상의 것들을 framebuffer에 첨부해야 합니다. 첨부물들은 framebuffer에서 buffer처럼 행동하는 메모리 위치입니다. 

텍스처 또는 renderbuffer 객체를 참조합니다.

## **texture object**

Texture는 1D, 2D, 3D 등의 형태로 사용이 가능하며, shader 내에서 값을 읽어서 사용하는 것이 가능하다.

Texture는 GPU memory 상에 독립적으로 동적 할당되어 자유롭게 사용이 가능합니

→ gpu에서 여러 데이터를 저장하는 용도로 사용할 수 있습니다.

color, depth, stencil 같은 데이터를 저장할 수 있습니다.

```cpp
glFramebufferTexture2D(target, attachment, textarget, texture, level);
target: 텍스처를 첨부할 타겟 framebuffer(draw, read 혹은 둘다)
attachment: 첨부할 첨부물의 유형. 지금 우리는 color 첨부물을 첨부하고 있습니다. 마지막에 붙은 0은 우리가 하나 이상의 color 첨부물을 첨부할 수 있다는 것을 암시합니다. 이는 나중에 다루도록 하겠습니다.
textarget: 첨부하기 원하는 텍스처의 유형
texture: 첨부할 실제 텍스처
level: Mipmap 레벨. 우리는 0으로 유지할것입니다.
```

- depth, stencil 텍스처를 framebuffer 객체에 넣을 수 있습니다.
    - depth : attachment (GL_DEPTH_ATTACHMENT),
    - stencil : attachment (GL_STENCIL_ATTACHMENT),
    - depth, stencil : GL_DEPTH_STENCIL_ATTACHMENT
    

## **renderbuffer object**

RBO는 반드시 FBO에 attach되어 사용되어야 한다.

RBO는 texture와는 달리 반드시 2D 형태로만 사용되어야 하고, 단 한 개의 image 만을 가질 수 있다.

RBO가 render target으로 설정되어 rendering 작업이 수행되는 것을 **offscreen rendering**이라고 한다.

기본적으로 RBO에 rendering 작업이 완료되었다고 해도 GPU memory 상에만 존재할 뿐 화면에는 보여지지 않기 때문이다.

RBO에 저장된 rendering 결과는 glReadPixels(), glDrawPixels(), glCopyPixels()와 같은 함수들을 이용해서 읽고 쓰는 것이 가능하긴 하지만, shader 내에서는 값을 읽어오는 것이 불가능하므로 texture source 등의 용도로 사용할 수 없다.

rbo가 texture rendering 보다 빠릅니다.

# Post-processing

이제 하나의 텍스처에 전체 scene에 렌더링 되었으므로 텍스처 데이터를 조작하여 흥미로운 효과들을 생성할 수 있습니다. 이번 섹션에서 우리는 가장 많이 쓰이는 post-processing 효과들을 보여줄 것입니다.

가장 간단한 post-processing 효과들부터 시작해봅시다.

### Inversion(반전)

Fragment shader에서 렌더링 출력의 각 컬러들에 대해 접근하여 이 컬러들을 반전시키는 것은 어렵지 않습니다. 우리는 screen 텍스처의 컬러를 얻어와 `1.0`에서 이 값을 빼서 반전시킵니다.

```
void main()
{
    FragColor = vec4(vec3(1.0 - texture(screenTexture, TexCoords)), 1.0);
}

```

Inversion은 비교적 간단한 post-processing 효과이지만 펑키한 결과를 만듭니다.

![](attachments/framebuffers_inverse.png)

이제 전체 scene이 모두 반전된 컬러를 가지고 있습니다. fragment shader의 한줄에 의해서 말이죠. 아주 멋지죠?

### Grayscale

또다른 흥미로운 효과는 scene의 모든 컬러에서 흰색, 회색, 검정색을 제외한 모든 색을 제거하여 전체 이미지를 graysacle 하는 것입니다. 이를 수행하는 쉬운 방법은 모든 컬러 컴포넌트를 얻어서 평균을 내는 것입니다.

```
void main()
{
    FragColor = texture(screenTexture, TexCoords);
    float average = (FragColor.r + FragColor.g + FragColor.b) / 3.0;
    FragColor = vec4(average, average, average, 1.0);
}

```

이 것은 꽤 좋은 결과를 생성합니다. 하지만 인간의 눈은 녹색에 예민하고 파란색에 덜 예민하므로 물리적으로 가장 정확한 결과는 weighted 채널을 사용해야 합니다.

```
void main()
{
    FragColor = texture(screenTexture, TexCoords);
    float average = 0.2126 * FragColor.r + 0.7152 * FragColor.g + 0.0722 * FragColor.b;
    FragColor = vec4(average, average, average, 1.0);
}

```

![](attachments/framebuffers_grayscale.png)

여러분은 아마도 차이를 알아차리지 못했을 것입니다. 하지만 더 복잡한 scene에서는 이러한 weighted grayscaling 효과가 더욱 현실적인 효과를 냅니다.

## Kernel 효과들

하나의 텍스처 이미지에 post-processing 하는 것에 대한 또다른 이점은 텍스처의 다른 부분으로부터 실제로 컬러 값을 샘플할 수 있다는 것입니다. 예를 들어 현재 텍스처 좌표 주변의 작은 영역을 가져올 수 있고 여러 텍스처 값들을 가져올 수도 있습니다. 그런 다음 이를 창의적인 방법으로 결합하여 흥미로운 효과를 낼 수 있습니다.

Kernel(혹은 나선형 행렬)은 주변 픽셀 값에 커널 값을 곱한 후 현재 값을 모두 더하여 하나의 값을 형성하는 현재 픽셀을 중심으로하는 값의 작은 행렬입니다(?). 그래서 기본적으로 우리는 현재 픽셀의 주변 방향으로 텍스처 좌표의 작의 offset을 추가하고 kernel을 기반으로 결과를 결합합니다. kernel의 예는 다음과 같습니다.

이 나옵니다. 그들의 합산이 1 이 나오지 않는다면 이는 결과 텍스처 컬러가 원래의 텍스처 값보다 밝아지던지 어두워지던지 하는 것입니다.

Kernel들은 post-processing에 대해 아주 유용한 도구입니다. 사용하거나 실험하기 쉽고 많은 예제들을 온라인에서 찾아볼 수 있기 때문입니다. kernel을 지원하기 위해 우리는 frament shader를 약간 수정해야 합니다. 우리가 사용할 각 kernel은 3x3 kernel이라고 가정합니다(대부분이 kernel이 그렇습니다).

```glsl
const float offset = 1.0 / 300.0;

void main()
{
    vec2 offsets[9] = vec2[](
        vec2(-offset,  offset),// 좌측 상단vec2( 0.0f,    offset),// 중앙 상단vec2( offset,  offset),// 우측 상단vec2(-offset,  0.0f),// 좌측 중앙vec2( 0.0f,    0.0f),// 정중앙vec2( offset,  0.0f),// 우측 중앙vec2(-offset, -offset),// 좌측 하단vec2( 0.0f,   -offset),// 중앙 하단vec2( offset, -offset)// 우측 하단
    );

    float kernel[9] = float[](
        -1, -1, -1,
        -1,  9, -1,
        -1, -1, -1
    );

    vec3 sampleTex[9];
    for(int i = 0; i < 9; i++)
    {
        sampleTex[i] = vec3(texture(screenTexture, TexCoords.st + offsets[i]));
    }
    vec3 col = vec3(0.0);
    for(int i = 0; i < 9; i++)
        col += sampleTex[i] * kernel[i];

    FragColor = vec4(col, 1.0);
}

```

Fragment shader에서 우리는 먼저 주변의 각 텍스처 좌표에 대한 9개의 `vec2` offset의 배열을 생성합니다. 이 offset은 간단히 여러분이 원하는대로 정할 수 있는 상수 값입니다. 드런 다음 kernel을 정의 합니다. 이 경우에 이 kernel은 sharpen(날카롭게) kernel입니다. 이는 흥미로운 방법으로 주변의 픽셀들을 샘플링함으로써 각 컬러를 날카롭게 만듭니다. 마지막으로 각 offset을 현재 텍스처 좌표에 더한 후 이 텍스처 값들을 weighted kernel 값들과 곱하여 합산합니다.

이 sharpen kernel은 다음과 같은 효과를 냅니다.

![](attachments/framebuffers_sharpen.png)

이 것은 약에 취해있는 것처럼 흥미로운 효과를 냅니다.

### Blur

Blur 효과를 내는 kernel은 다음과 같이 정의됩니다.

모든 값의 합산이 16이기 때문에 간단히 샘플링된 컬러들을 결합하면 매우 밝아지므로 kernel의 각 값들을 `16`으로 나눕니다. 최종 kernel 배열은 다음과 같습니다.

```
float kernel[9] = float[](
    1.0 / 16, 2.0 / 16, 1.0 / 16,
    2.0 / 16, 4.0 / 16, 2.0 / 16,
    1.0 / 16, 2.0 / 16, 1.0 / 16
);

```

Fragment shader에서 kernel float 배열만 수정했는데 완전히 다른 post-processing 효과를 생성했습니다. 이제 다음과 같이 보일 것입니다.

![](attachments/framebuffers_blur.png)

이러한 blur 효과는 흥미로운 가능성을 만듭니다. 예를 들어 술에 취한 효과를 내기 위해 시간이 지남에 따라 blur 정도를 바꿀 수 있습니다. 또는 메인 캐릭터가 안경을 쓰지 않았을 경우 blur 효과를 높일 수 있습니다. Blur는 우리가 나중에 강좌에서 사용할 컬러 값을 부드럽게 하는데에 유용한 도구가 될 수 있습니다.

우리는 이러한 작은 kernel을 구현함으로써 손쉽게 멋진 post-processing 효과를 낼 수 있었습니다. 마지막으로 효과 하나를 더 보여주고 마치도록 하겠습니다.

### Edge detection

아래에서 edge-detection kernel을 확인할 수 있습니다. sharpen kernel과 매우 유사합니다.

이 kernel은 모든 모서리를 하이라이트하고 나머지들은 어둡게 만듭니다. 우리가 이미지의 모서리를 신경써야 할때 유용하게 사용할 수 있습니다.

![](attachments/framebuffers_edge_detection.png)

이러한 kerenl들이 Photoshop과 같은 도구에서 이미지 조작 도구/필터로 사용된다는 것은 놀랄 일이 아닙니다. 병렬 기능으로 fragment들을 처리하는 그래픽 카드들의 능력 때문에 우리는 실시간으로 픽셀 마다 이미지를 조작할 수 있습니다. 그러므로 이미지 편집 도구들은 이미지 처리에 대해서 그래픽 카드를 더 자주 사용하는 경향이 있습니다.