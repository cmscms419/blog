# Fixed functions

Vulkan에서는 대부분의 pipeline state에 대해 다음과 같이 명시해야 합니다. 

Fixed pipeline state 개체로 구워집니다. 

모든 구조체에서 이러한 Fixed functions operation을 구성할 수 있습니다.

# Dynamic state

*대부분의* pipeline state는 pipeline state에 굽게 되어야 하지만, 제한된 state는 실제로 다시 만들지 않고도 변경할 *수 있습니다*. 

그릴 때 파이프라인. 예를 들어 뷰포트의 크기, 선 너비가 있습니다. 및 블렌드 상수. 동적 상태를 사용하고 이러한 속성을 유지하려면 그런 다음 다음과 같이 [`VkPipelineDynamicStateCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineDynamicStateCreateInfo.html) 구조를 채워야 합니다.

```c
std::vector<VkDynamicState> dynamicStates = {
    VK_DYNAMIC_STATE_VIEWPORT,
    VK_DYNAMIC_STATE_SCISSOR
};

VkPipelineDynamicStateCreateInfo dynamicState{};
dynamicState.sType = VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
dynamicState.dynamicStateCount = static_cast<uint32_t>(dynamicStates.size());
dynamicState.pDynamicStates = dynamicStates.data();
```

이렇게 하면 이러한 값의 구성이 무시되고 그리기 시점(그리고 지정해야 합니다)에 데이터를 지정할 수 있습니다. 그 결과 더 유연해집니다. 

setup 및 뷰포트 및 시저 상태와 같은 것들에 대해 매우 일반적입니다. pipeline state로 베이크될 때 설정이 더 복잡해집니다.

# Vertex input

[`VkPipelineVertexInputStateCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineVertexInputStateCreateInfo.html) 구조체는 vertex shader에 전달할 vertex data의 format을 설명합니다.

- Bindings: 데이터 간의 간격과 데이터가 버텍스별인지 인스턴스별인지를 나타냅니다.
- Attribute descriptions: 버텍스 셰이더로 전달될 속성의 유형, 어느 바인딩에서 로드할 것인지, 그리고 어느 오프셋에서 로드할 것인지를 설명합니다.

현재는 버텍스 데이터를 직접 버텍스 셰이더에 하드코딩하고 있기 때문에, 이 구조체를 채워서 로드할 버텍스 데이터가 없음을 지정합니다. 나중에 버텍스 버퍼 챕터에서 다시 다룰 예정입니다.

```c
VkPipelineVertexInputStateCreateInfo vertexInputInfo{};
vertexInputInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
vertexInputInfo.vertexBindingDescriptionCount = 0;
vertexInputInfo.pVertexBindingDescriptions = nullptr; // Optional
vertexInputInfo.vertexAttributeDescriptionCount = 0;
vertexInputInfo.pVertexAttributeDescriptions = nullptr; // Optional

```

`pVertexBindingDescriptions`와 `pVertexAttributeDescriptions` 멤버는 버텍스 데이터를 로드하기 위한 세부 사항을 설명하는 구조체 배열을 가리킵니다. 이 구조체를 `createGraphicsPipeline` 함수에 `shaderStages` 배열 바로 뒤에 추가합니다.

# Input assembly

버텍스 데이터를 어떤 형태로 조립할지 결정하는 단계입니다. 이 단계에서는 주로 두 가지를 설정합니다:

[`VkPipelineInputAssemblyStateCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineInputAssemblyStateCreateInfo.html) 구조체는 2가지를 설명합니다. 

1. 버텍스 데이터를 어떤 형태로 그릴지를 결정합니다. 예를 들어, 점, 선, 삼각형 등 다양한 형태가 있습니다.
2. 특정 조건에서 기하학적 형태를 다시 시작할지 여부를 설정합니다.
- `VK_PRIMITIVE_TOPOLOGY_POINT_LIST`: 버텍스으로 부터 점
- `VK_PRIMITIVE_TOPOLOGY_LINE_LIST`: 재사용하지 않고 모든 정점 2개를 선으로
- `VK_PRIMITIVE_TOPOLOGY_LINE_STRIP`: 각 버텍스가 이전 버텍스와 연결되어 연속적인 선을 형성
- `VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST`: 각 세 개의 버텍스가 하나의 삼각형을 형성
- `VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP`: 첫 번째 삼각형을 그린 후, 이후의 삼각형들은 이전 삼각형의 두 개의 버텍스를 재사용하여 그려집니다.

일반적으로 정점 버퍼에서 인덱스 순서대로 정점을 로드하지만, 요소 버퍼를 사용하면 직접 사용할 인덱스를 지정할 수 있습니다. 이를 통해 정점 재사용과 같은 최적화를 수행할 수 있습니다. `primitiveRestartEnable` 멤버를 `VK_TRUE`로 설정하면 `0xFFFFF` 또는 `0xFFFFFFF`의 특수 인덱스를 사용하여 `_STIP` 토폴로지 모드에서 선과 삼각형을 분리할 수 있습니다.

이 튜토리얼 전반에 걸쳐 삼각형을 그릴 예정이므로 구조에 대한 다음 데이터를 고수하겠습니다:

```c
VkPipelineInputAssemblyStateCreateInfo inputAssembly{};
inputAssembly.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
inputAssembly.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
inputAssembly.primitiveRestartEnable = VK_FALSE;
```

# Viewports and scissors

뷰포트는 기본적으로 출력이 렌더링될 프레임 버퍼의 영역을 설명합니다. 이는 거의 항상 `(0, 0)`에서 `(width, height)`까지이며, 이 튜토리얼에서도 마찬가지입니다.

```c
VkViewport viewport{};
viewport.x = 0.0f;
viewport.y = 0.0f;
viewport.width = (float) swapChainExtent.width;
viewport.height = (float) swapChainExtent.height;
viewport.minDepth = 0.0f;
viewport.maxDepth = 1.0f;
```

스왑 체인과 이미지의 크기는 창의 `WIDTH` 및 `HEIGHT`와 다를 수 있다는 점을 기억하세요. 스왑 체인 이미지는 나중에 프레임 버퍼로 사용될 예정이므로 크기를 유지해야 합니다.

`minDepth` 및 `maxDepth` 값은 프레임 버퍼에 사용할 깊이 값의 범위를 지정합니다. 이러한 값은 `[0.0f, 1.0f]` 범위 내에 있어야 하지만 `minDepth`가 `maxDepth`보다 높을 수 있습니다. 특별한 작업을 하지 않는다면 표준 값인 `0.0f`및 `1.0f`를 유지해야 합니다.

`viewports`는 이미지에서 프레임 버퍼로의 변환을 정의하는 반면, `scissor rectangles`은 픽셀이 실제로 저장될 영역을 정의합니다. `scissor rectangles` 외부의 픽셀은 래스터라이저에 의해 폐기됩니다. 픽셀은 변환이 아닌 필터처럼 작동합니다. 차이점은 아래에 설명되어 있습니다. 왼쪽 `scissor rectangles`은 뷰포트보다 큰 경우 해당 이미지를 생성할 수 있는 여러 가지 가능성 중 하나에 불과합니다.

![](attachments/viewports_scissors.png)

그래서 우리가 전체 프레임 버퍼에 그림을 그리고 싶다면, 그것을 완전히 덮는 `scissor rectangle`을 지정할 것입니다:

```c
VkRect2D scissor{};
scissor.offset = {0, 0};
scissor.extent = swapChainExtent;

```

`Viewport`와 `scissor rectangle`은 파이프라인의 **정적 부분**으로 지정하거나 **명령 버퍼**에 [dynamic state](https://vulkan-tutorial.com/Drawing_a_triangle/Graphics_pipeline_basics/Fixed_functions#dynamic-state) **세트로 지정**할 수 있습니다.

전자는 다른 상태와 더 일치하지만, `Viewport`와 `scissor rectangle`를 동적으로 만드는 것이 훨씬 더 유연하기 때문에 종종 편리합니다. 이는 매우 일반적이며 모든 구현이 성능 저하 없이 이 동적 상태를 처리할 수 있습니다.

When opting for dynamic viewport(s) and scissor rectangle(s) you need to enable the respective dynamic states for the pipeline:

```c
std::vector<VkDynamicState> dynamicStates = {
    VK_DYNAMIC_STATE_VIEWPORT,
    VK_DYNAMIC_STATE_SCISSOR
};

VkPipelineDynamicStateCreateInfo dynamicState{};
dynamicState.sType = VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
dynamicState.dynamicStateCount = static_cast<uint32_t>(dynamicStates.size());
dynamicState.pDynamicStates = dynamicStates.data();

```

그런 다음 파이프라인 생성 시 그 수를 지정하기만 하면 됩니다:

```c
VkPipelineViewportStateCreateInfo viewportState{};
viewportState.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
viewportState.viewportCount = 1;
viewportState.scissorCount = 1;

```

Drawing time에 `viewport`와 `scissor rectangle` 세트를 만들어야 한다.

동적 상태에서는 단일 명령 버퍼 내에서 다양한 뷰포트 및 가위 직사각형을 지정할 수도 있습니다.

동적 상태가 없으면 `vikPipelineViewportStateCreateInfo` 구조를 사용하여 파이프라인에서 `viewport`와 `scissor rectangle`을 설정해야 합니다. 이렇게 하면 이 파이프라인의 `viewport`와 `scissor rectangle`을 불변으로 만들 수 있습니다. 이러한 값을 변경하려면 새 값으로 새로운 파이프라인을 만들어야 합니다.

```c
VkPipelineViewportStateCreateInfo viewportState{};
viewportState.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
viewportState.viewportCount = 1;
viewportState.pViewports = &viewport;
viewportState.scissorCount = 1;
viewportState.pScissors = &scissor;

```

설정 방법에 관계없이 일부 그래픽 카드에서 여러 뷰포트와 가위 직사각형을 사용할 수 있으므로 구조 구성원은 이들의 배열을 참조합니다. 여러 개를 사용하려면 GPU 기능을 활성화해야 합니다(논리 장치 생성 참조).

# Rasterizer

rasterizer는  vertex shader에서 vertex에 의해 형성된 geometry을 fragments으로 변환하여 fragment shader에 의해 색칠됩니다. 또한  [depth testing](https://en.wikipedia.org/wiki/Z-buffering), [face culling](https://en.wikipedia.org/wiki/Back-face_culling) 및 `scissor test`를 수행하며, 전체 다각형을 채우거나 가장자리만 채우는 fragments을 출력하도록 구성할 수 있습니다. (와이어프레임 렌더링). 이 모든 것은 [`VkPipelineRasterizationStateCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineRasterizationStateCreateInfo.html)구조를 사용하여 구성됩니다.

```c
VkPipelineRasterizationStateCreateInfo rasterizer{};
rasterizer.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
rasterizer.depthClampEnable = VK_FALSE;
```

If `depthClampEnable` is set to `VK_TRUE`, 

근거리 및 원거리 평면을 벗어난 fragments는 버리는 것이 아니라 클램핑됩니다.

섀도우맵과 같은 특수한 경우에 유용합니다. 이 기능을 사용하려면 GPU 기능을 활성화해야 합니다.

```c
rasterizer.rasterizerDiscardEnable = VK_FALSE;
```

If `rasterizerDiscardEnable` is set to `VK_TRUE`, 

그러면 geometry은 래스터라이저 단계를 통과하지 못합니다. 이렇게 하면 기본적으로 프레임 버퍼로의 출력이 비활성화됩니다.

```c
rasterizer.polygonMode = VK_POLYGON_MODE_FILL;
```

`polygonMode`는 geometry에서 조각이 생성되는 방식을 결정합니다. 다음 모드를 사용할 수 있습니다:

- `VK_POLYGON_MODE_FILL`: 다각형의 영역을 fragments으로 채웁니다
- `VK_POLYGON_MODE_LINE`: 다각형 가장자리가 선으로 그려져 있습니다
- `VK_POLYGON_MODE_POINT`: 다각형 꼭짓점이 점으로 그려져 있습니다

Using any mode other than fill requires enabling a GPU feature.

```c
rasterizer.lineWidth = 1.0f;
```

`lineWidth` 멤버는 간단하며, 선의 두께를 fragments 수로 설명합니다. 지원되는 최대 선 폭은 하드웨어에 따라 다르며, `1.0f`보다 두꺼운 선은 `wideLines` GPU 기능을 활성화해야 합니다.

```c
rasterizer.cullMode = VK_CULL_MODE_BACK_BIT;
rasterizer.frontFace = VK_FRONT_FACE_CLOCKWISE;

```

`cullMode`변수는 사용할 `face culling` 유형을 결정합니다. `cull`를 비활성화 하거나, `front face`, `back face`또는 둘 다 할 수 있습니다. `front face`는 앞면을 향한 것으로 간주할 faces의 꼭짓점 순서를 지정하며 시계 방향 또는 반시계 방향일 수 있습니다.

```c
rasterizer.depthBiasEnable = VK_FALSE;
rasterizer.depthBiasConstantFactor = 0.0f; // Optional
rasterizer.depthBiasClamp = 0.0f; // Optional
rasterizer.depthBiasSlopeFactor = 0.0f; // Optional

```

The rasterizer can alter the depth values by adding a constant value or biasing them based on a fragment's slope. This is sometimes used for shadow mapping, but we won't be using it. Just set `depthBiasEnable` to `VK_FALSE`.

래스터라이저는 fragment의 기울기에 따라 일정한 값을 추가하거나 편향시켜 깊이 값을 변경할 수 있습니다. 이는 때때로 그림자 매핑에 사용되지만 사용하지는 않습니다. `depthBiasEnable`을 `VK_FALSE`로 설정하기만 하면 됩니다.

# Multisampling

[`VkPipelineMultisampleStateCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineMultisampleStateCreateInfo.html)구조체는 다중 샘플링을 구성하며, 이는 [anti-aliasing](https://en.wikipedia.org/wiki/Multisample_anti-aliasing)을 수행하는 방법 중 하나입니다. 

이는 동일한 픽셀에 래스터화되는 multiple polygons의 fragment shader 결과를 결합하여 작동합니다. 

이는 주로 가장자리를 따라 발생하며, 가장 눈에 띄는 aliasing artifacts가 발생하는 곳이기도 합니다. **하나의 다각형만 픽셀에 매핑하는 경우 fragment shader를 여러 번 실행할 필요가 없기 때문에 단순히 더 높은 해상도로 렌더링한 다음 다운스케일링하는 것보다 훨씬 저렴**합니다. GPU 기능을 활성화하려면 GPU 기능을 활성화해야 합니다.

```c
VkPipelineMultisampleStateCreateInfo multisampling{};
multisampling.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
multisampling.sampleShadingEnable = VK_FALSE;
multisampling.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT;
multisampling.minSampleShading = 1.0f; // Optional
multisampling.pSampleMask = nullptr; // Optional
multisampling.alphaToCoverageEnable = VK_FALSE; // Optional
multisampling.alphaToOneEnable = VK_FALSE; // Optional

```

We'll revisit multisampling in later chapter, for now let's keep it disabled.

# Depth and stencil testing

If you are using a depth and/or stencil buffer, then you also need to configure the depth and stencil tests using [`VkPipelineDepthStencilStateCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineDepthStencilStateCreateInfo.html). We don't have one right now, so we can simply pass a `nullptr` instead of a pointer to such a struct. We'll get back to it in the depth buffering chapter.

깊이/스텐실 버퍼를 사용하는 경우 [`VkPipelineDepthStencilStateCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineDepthStencilStateCreateInfo.html)를 사용하여 깊이 및 스텐실 테스트를 구성해야 합니다. 

현재는 그런 구조에 포인터 대신 `nullptr` 를 전달할 수 있습니다. 깊이 버퍼링 장에서 다시 살펴보겠습니다.

# Color blending

 fragment shader가 색상을 반환한 후에는 framebuffer에 이미 있는 색상과 결합해야 합니다. 이 변환을 Color blending이라고 하며 두 가지 방법이 있습니다:

- 이전 값과 새로운 값을 혼합하여 만든 최종 색상
- 비트 단위 연산을 사용하여 기존 값과 새 값을 결합하세요

색상 블렌딩을 구성하는 구조에는 두 가지 유형이 있습니다. 

1.  [`VkPipelineColorBlendAttachmentState`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineColorBlendAttachmentState.html)에는 첨부된 framebuffer별 구성이 포함되어 있으며, 
2. [`VkPipelineColorBlendStateCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineColorBlendStateCreateInfo.html)에는 *global* 색상 블렌딩 설정이 포함되어 있습니다. 우리의 경우 프레임 버퍼는 하나뿐입니다:

```c
VkPipelineColorBlendAttachmentState colorBlendAttachment{};
colorBlendAttachment.colorWriteMask = VK_COLOR_COMPONENT_R_BIT | VK_COLOR_COMPONENT_G_BIT | VK_COLOR_COMPONENT_B_BIT | VK_COLOR_COMPONENT_A_BIT;
colorBlendAttachment.blendEnable = VK_FALSE;
colorBlendAttachment.srcColorBlendFactor = VK_BLEND_FACTOR_ONE; // Optional
colorBlendAttachment.dstColorBlendFactor = VK_BLEND_FACTOR_ZERO; // Optional
colorBlendAttachment.colorBlendOp = VK_BLEND_OP_ADD; // Optional
colorBlendAttachment.srcAlphaBlendFactor = VK_BLEND_FACTOR_ONE; // Optional
colorBlendAttachment.dstAlphaBlendFactor = VK_BLEND_FACTOR_ZERO; // Optional
colorBlendAttachment.alphaBlendOp = VK_BLEND_OP_ADD; // Optional

```

이 프레임별 버퍼 구조를 사용하면 색상 블렌딩의 첫 번째 방법을 구성할 수 있습니다. 

수행할 작업은 다음 의사 코드를 사용하여 가장 잘 설명할 수 있습니다:

```c
if (blendEnable) {
    finalColor.rgb = (srcColorBlendFactor * newColor.rgb) <colorBlendOp> (dstColorBlendFactor * oldColor.rgb);
    finalColor.a = (srcAlphaBlendFactor * newColor.a) <alphaBlendOp> (dstAlphaBlendFactor * oldColor.a);
} else {
    finalColor = newColor;
}

finalColor = finalColor & colorWriteMask;

```

fragment shader의 새 색상이 수정되지 않고 통과됩니다. 그렇지 않으면 두 가지 혼합 작업을 수행하여 새 색상을 계산합니다. 

결과적으로 생성된 색상은 실제로 통과되는 채널을 결정하기 위해 `colorWriteMask`로 AND 처리됩니다.

Color blending을 가장 일반적으로 사용하는 방법은 Alpha blending을 구현하는 것으로, 불투명도에 따라 새로운 색상을 기존 색상과 블렌딩하기를 원합니다. 그런 다음 `finalColor`을 다음과 같이 계산해야 합니다:

```c
finalColor.rgb = newAlpha * newColor + (1 - newAlpha) * oldColor;
finalColor.a = newAlpha.a;
```

이 작업은 다음 매개변수를 사용하여 수행할 수 있습니다:

```c
colorBlendAttachment.blendEnable = VK_TRUE;
colorBlendAttachment.srcColorBlendFactor = VK_BLEND_FACTOR_SRC_ALPHA;
colorBlendAttachment.dstColorBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
colorBlendAttachment.colorBlendOp = VK_BLEND_OP_ADD;
colorBlendAttachment.srcAlphaBlendFactor = VK_BLEND_FACTOR_ONE;
colorBlendAttachment.dstAlphaBlendFactor = VK_BLEND_FACTOR_ZERO;
colorBlendAttachment.alphaBlendOp = VK_BLEND_OP_ADD;
```

사양의 [`VkBlendFactor`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkBlendFactor.html)및[`VkBlendOp`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkBlendOp.html) 에서 가능한 모든 연산을 찾을 수 있습니다.

두 번째 구조는 모든 프레임 버퍼의 구조 배열을 참조하며, 앞서 언급한 계산에서 블렌드 인자로 사용할 수 있는 블렌드 상수를 설정할 수 있게 해줍니다.

```c
VkPipelineColorBlendStateCreateInfo colorBlending{};
colorBlending.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
colorBlending.logicOpEnable = VK_FALSE;
colorBlending.logicOp = VK_LOGIC_OP_COPY; // Optional
colorBlending.attachmentCount = 1;
colorBlending.pAttachments = &colorBlendAttachment;
colorBlending.blendConstants[0] = 0.0f; // Optional
colorBlending.blendConstants[1] = 0.0f; // Optional
colorBlending.blendConstants[2] = 0.0f; // Optional
colorBlending.blendConstants[3] = 0.0f; // Optional

```

두 번째 블렌딩 방법(비트와이즈 조합)을 사용하려면 `logicOpEnable`을 `VK_TRUE`로 설정해야 합니다. 그런 다음 `logicOp` 필드에 비트와이즈 연산을 지정할 수 있습니다. 

이렇게 하면 마치 모든 연결된 프레임 버퍼에 대해 `blendEnable`을 `VK_FALSE`로 설정한 것처럼 첫 번째 메서드가 자동으로 비활성화됩니다! 

이 모드에서는 프레임 버퍼의 어떤 채널이 실제로 영향을 받을지 결정하기 위해 `colorWriteMask`도 사용됩니다. 

여기서 설명한 것처럼 두 가지 모드를 모두 비 활성화할 수도 있으며, 이 경우 조각 색상이 수정되지 않은 채 프레임 버퍼에 기록됩니다.

# Pipeline layout

You can use `uniform` values in shaders, which are globals similar to dynamic state variables that can be changed at drawing time to alter the behavior of your shaders without having to recreate them. They are commonly used to pass the transformation matrix to the vertex shader, or to create texture samplers in the fragment shader.

쉐이더에서 `uniform` 을 사용할 수 있습니다. 이는 동적 상태 변수와 유사한 전역 변수로, 이 변수는 렌더링 중에 변경되지 습니다. 카메라 변환, 조명 정보, 재질 속성 등과 같은 데이터를 전달하는 데 사용됩니다.

These uniform values need to be specified during pipeline creation by creating a [`VkPipelineLayout`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineLayout.html) object. Even though we won't be using them until a future chapter, we are still required to create an empty pipeline layout.

Create a class member to hold this object, because we'll refer to it from other functions at a later point in time:

파이프라인을 생성할 때[`VkPipelineLayout`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineLayout.html)객체를 생성하여 이러한 균일한 값을 지정해야 합니다. 비록 다음 장까지는 이러한 값을 사용하지 않겠지만, 여전히 빈 파이프라인 레이아웃을 만들어야 합니다.

이 객체를 보관할 클래스 멤버를 만드세요. 나중에 다른 함수에서 참조할 것입니다:

```c
VkPipelineLayout pipelineLayout;
```

And then create the object in the `createGraphicsPipeline` function:

```c
VkPipelineLayoutCreateInfo pipelineLayoutInfo{};
pipelineLayoutInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
pipelineLayoutInfo.setLayoutCount = 0; // Optional
pipelineLayoutInfo.pSetLayouts = nullptr; // Optional
pipelineLayoutInfo.pushConstantRangeCount = 0; // Optional
pipelineLayoutInfo.pPushConstantRanges = nullptr; // Optional

if (vkCreatePipelineLayout(device, &pipelineLayoutInfo, nullptr, &pipelineLayout) != VK_SUCCESS) {
    throw std::runtime_error("failed to create pipeline layout!");
}

```

The structure also specifies *push constants*, which are another way of passing dynamic values to shaders that we may get into in a future chapter. The pipeline layout will be referenced throughout the program's lifetime, so it should be destroyed at the end:

```c
void cleanup() {
    vkDestroyPipelineLayout(device, pipelineLayout, nullptr);
    ...
}

```

# Conclusion

That's it for all of the fixed-function state! It's a lot of work to set all of this up from scratch, but the advantage is that we're now nearly fully aware of everything that is going on in the graphics pipeline! This reduces the chance of running into unexpected behavior because the default state of certain components is not what you expect.

There is however one more object to create before we can finally create the graphics pipeline and that is a [render pass](https://vulkan-tutorial.com/Drawing_a_triangle/Graphics_pipeline_basics/Render_passes).