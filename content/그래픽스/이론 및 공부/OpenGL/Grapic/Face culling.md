# Face culling

# Face culling

OpenGL은 모든 면들을 확인하여 viewer의 관점에서 앞면은 렌더링하고 뒤면의 모든 면들은 폐기하여 fragment shader 호출(이는 비용이 많이 듭니다)을 많이 줄여줍니다. 우리는 OpenGL에게 우리가 우리가 사용하는 면들이 실제로 앞쪽 면인지 뒷쪽 면인지 알려주어야 합니다. 

## Winding 순서

우리가 삼각형 vertex들을 정의할 때 시계 방향 혹은 반시계 방향으로 특정 순서로 정의합니다. 각 삼각형은 3개의 vertex를 가지고 있고 우리는 이 3개의 vertex들을 삼각형의 중앙을 바라보았을 때의 winding 순서로 지정합니다.

![](attachments/faceculling_windingorder.png)

이미지에서 볼 수 있듯이 먼저 vertex `1`을 정의한 후 vertex `2`나 `3`을 정의할 수 있습니다. 이 선택은 삼각형의 winding 순서를 정의합니다. 다음의 코드가 이것을 설명해줍니다.

```cpp
float vertices[] = {
		// 시계 방향
    vertices[0],// vertex 1
    vertices[1],// vertex 2
    vertices[2],// vertex 3

		// 반시계 방향
    vertices[0],// vertex 1
    vertices[2],// vertex 3
    vertices[1]// vertex 2
};

```

각 삼각형을 이루고 있는 3개의 vertex들은 winding 순서를 가지고 있습니다. 

OpenGL은 렌더링할 때 이 정보를 사용하여 삼각형이 front-facing인지 back-facing인지를 결정합니다. 

기본값으로는 반시계 방향 → front-facing(앞면) 삼각형으로 처리됩니다.

vertex 순서를 정의할 때 해당 삼각형을 여러분을 대면하고 있는지 상상해보세요. 그리고 여러분이 지정하고 있는 삼각형이 반시계 방향이어야 합니다. 

모든 vertex들을 이처럼 지정하는 것에 대해 좋은 점은 실제 winding 순서는 vertex shader가 이미 실행되고 난 후의 rasterization 단계에서 계산된다는 것입니다. 그런 다음 vertex들은 **viewer의 관점**에서 보이게 됩니다.

viewer가 대면하고 있는 모든 삼각형 vertex들은 확실히 정확한 winding 순서로 이루어져 있습니다. 큐브의 다른 면의 삼각형 vertex들은 winding 순서가 반대로 된채로 렌더링됩니다. 그

 결과 우리가 대면하고 있는 삼각형들은 front-facing 삼각형으로 보이게 되고 뒤에 있는 삼각형들은 back-facing 삼각형으로 보이게 됩니다. 다음 이미지가 이 효과를 보여줍니다.

![](attachments/faceculling_frontback.png)

vertex 데이터에서 우리는 두 삼각형을 viewer의 시점에서 반시계 방향으로 정의했을 것입니다. 하지만 viewer의 방향으로부터 뒤에 있는 삼각형은 시계 방향으로 렌더링됩니다. 뒤에 있는 삼각형도 반시계 방향으로 지정하였음에도 불구하고 지금은 시계방향으로 렌더링됩니다. 이는 정확히 우리가 보이지 않은 면들을 폐기하는 것입니다!

## Face culling

활성화

```cpp
glEnable(GL_CULL_FACE);
```

이 시점부터 앞쪽면이 아닌 모든 면들은 폐기됩니다(큐브의 내부로 들어가서 내부에 있는 면들이 정확히 폐기되었음을 확인해보세요). 현재 우리는 fragment를 렌더링하는 데에 50% 이상의 성능을 절약했습니다. 하지만 이는 오직 큐브처럼 닫힌 도형에서만 동작한다는 것을 알아두세요. 우리는 이전 강좌의 잔디를 그릴때에는 face culling을 비활성화해야 합니다. 이들은 앞쪽면 **그리고** 뒷쪽면 모두 보여야 하기 때문입니다.

OpenGL은 우리가 폐기하고 싶은 면의 유형을 바꿀수 있도록 해줍니다. 후면이 아니라 전면을 폐기하고 싶다면 어떨까요? 우리는 glCullFace 함수를 통해 이를 정의할 수 있습니다.

```
glCullFace(GL_FRONT);
```

glCullFace 함수는 3개의 가능한 옵션들을 가지고 있습니다.

- `GL_BACK`: 후면만을 폐기합니다.
- `GL_FRONT`: 전면만을 폐기합니다.
- `GL_FRONT_AND_BACK`: 전면 후면 모두 폐기합니다.

glCullFace 함수의 기본값은 GL_BACK입니다. 

OpenGL에게 시계 방향의 면들이 후면이 아니라 전면이라고 말해줄 수도 있습니다. glFrontFace 함수를 통해 이를 정의할 수 있습니다.

```
glFrontFace(GL_CCW);
```

기본값은 GL_CCW이므로 반시계 방향을 나타냅니다. 다른 옵션은 GL_CW로 시계 방향을 나타냅니다.

간단한 실험으로서 OpenGL에게 이제 전면은 반시계 방향이 아니라 시계 방향이라고 말해줌으로써 winding 순서를 반대로 할 수 있습니다.

```
glEnable(GL_CULL_FACE);
glCullFace(GL_BACK);
glFrontFace(GL_CW);

```

결과는 후면들만 렌더링됩니다.

![](attachments/faceculling_reverse.png)

반시계 방향의 winding 순서로 유지하고 전면을 폐기함으로써 동일한 효과를 얻을 수 있습니다.

```
glEnable(GL_CULL_FACE);
glCullFace(GL_FRONT);

```

보시다시피 face culling은 적은 비용으로 OpenGL 응용 프로그램의 성능을 증가시킬 수 있는 좋은 도구입니다. 여러분은 어떠한 오브젝트가 face culling을 이점을 누릴 수 있고 어떠한 오브젝트가 face culling을 하면 안되는지 알고 있어야 합니다.

```cpp
glEnable(GL_CULL_FACE);
glCullFace(GL_BACK);
glFrontFace(GL_CW);
```

`glCullFace(GL_BACK)`

뒤면을 지우겠다

`glFrontFace(GL_CW)`

시계 방향으로 그려지는 정점의 데이터를 앞면으로 인식하겠다.

→ 시계 방향으로 그려지는 정점의 데이터는 그리지 않겠다고 하는데, `glFrontFace(GL_CW)` 에서 앞면을 인식하는 방법을 시계 방향으로 바꾸었다. 정점의 데이터를 보면, 뒤면은 시계 방향으로 그려지기 떄문에, 시계 방향으로 그려지는 뒤면을 앞면으로 인식하고, 시계 반대 방향으로 그려지는 앞면은 폐기합니다.

# 요약

![Untitled](attachments/Untitled_17.png)