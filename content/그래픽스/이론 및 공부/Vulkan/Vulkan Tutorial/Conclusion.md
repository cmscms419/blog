# Conclusion

전에 만든 객체와 구조체를 결합해서, graphics pipeline 완성 시킨다.

- Shader stages: 그래픽 파이프라인의 프로그래밍 함수화 단계의 기능을 정의하는 셰이더 모듈
- Fixed-function state: 파이프 라인의 fixed-function에 정의된 모든 구조체(input assembly, rasterizer, viewport and color blending )
- Pipeline layout: draw time에 업데이트 되는 쉐이더에서 uniform과 참조되는 값
- Render pass: 파이프라인 단계에서 참조하는 attachments 파일 및 그 용도

All of these combined fully define the functionality of the graphics pipeline, so we can now begin filling in the [`VkGraphicsPipelineCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkGraphicsPipelineCreateInfo.html) structure at the end of the `createGraphicsPipeline` function. But before the calls to [`vkDestroyShaderModule`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkDestroyShaderModule.html) because these are still to be used during the creation.

graphics pipeline에서 모두 함수화로 정의해야 한다. `createGraphicsPipeline` 함수 끝에서 [`VkGraphicsPipelineCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkGraphicsPipelineCreateInfo.html) 를 채워야 한다. creation 것이 사용 중일 수 도 있어서 [`vkDestroyShaderModule`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkDestroyShaderModule.html) 전에 만들어야 한다.

```c
VkGraphicsPipelineCreateInfo pipelineInfo{};
pipelineInfo.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
pipelineInfo.stageCount = 2;
pipelineInfo.pStages = shaderStages;
```

We start by referencing the array of [`VkPipelineShaderStageCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineShaderStageCreateInfo.html) structs.

```c
pipelineInfo.pVertexInputState = &vertexInputInfo;
pipelineInfo.pInputAssemblyState = &inputAssembly;
pipelineInfo.pViewportState = &viewportState;
pipelineInfo.pRasterizationState = &rasterizer;
pipelineInfo.pMultisampleState = &multisampling;
pipelineInfo.pDepthStencilState = nullptr; // Optional
pipelineInfo.pColorBlendState = &colorBlending;
pipelineInfo.pDynamicState = &dynamicState;
```

Then we reference all of the structures describing the fixed-function stage.

fixed-function stage에서 만든 구조체를 참조시킨다.

```c
pipelineInfo.layout = pipelineLayout;
```

After that comes the pipeline layout, which is a Vulkan handle rather than a struct pointer.

그 후 pipeline layout이 나오는데, 이는 struct 포인터가 아닌 Vulkan handle입니다.

```c
pipelineInfo.renderPass = renderPass;
pipelineInfo.subpass = 0;
```

마지막으로 이 그래픽 파이프라인이 사용될 렌더 패스와 서브 패스의 인덱스에 대한 참조가 있습니다. 이 특정 인스턴스 대신 이 파이프라인에서 다른 렌더 패스를 사용할 수도 있지만, `renderPass`와 호환되어야 합니다. 호환성에 대한 요구 사항은 [here](https://www.khronos.org/registry/vulkan/specs/1.3-extensions/html/chap8.html#renderpass-compatibility)에 설명되어 있지만, 이 튜토리얼에서는 해당 기능을 사용하지 않겠습니다.

```c
pipelineInfo.basePipelineHandle = VK_NULL_HANDLE; // Optional
pipelineInfo.basePipelineIndex = -1; // Optional
```

There are actually two more parameters: `basePipelineHandle` and `basePipelineIndex`. Vulkan allows you to create a new graphics pipeline by deriving from an existing pipeline. The idea of pipeline derivatives is that it is less expensive to set up pipelines when they have much functionality in common with an existing pipeline and switching between pipelines from the same parent can also be done quicker. You can either specify the handle of an existing pipeline with `basePipelineHandle` or reference another pipeline that is about to be created by index with `basePipelineIndex`. Right now there is only a single pipeline, so we'll simply specify a null handle and an invalid index. These values are only used if the `VK_PIPELINE_CREATE_DERIVATIVE_BIT` flag is also specified in the `flags` field of [`VkGraphicsPipelineCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkGraphicsPipelineCreateInfo.html).

실제로 두 가지 매개변수가 더 있습니다: `basePipelineHandle`과 `basePipelineIndex`. 

Vulkan을 사용하면 기존 파이프라인에서 파생하여 새로운 그래픽 파이프라인을 만들 수 있습니다. 파이프라인 existing의 아이디어는 기존 파이프라인과 많은 기능을 공통으로 가지고 있을 때 파이프라인을 설정하는 비용이 저렴하며, 동일한 상위 파이프라인에서 파이프라인 간 전환도 더 빠르게 할 수 있다는 것입니다. 

`basePipelineHandle`을 사용하여 기존 파이프라인의 핸들을 지정하거나, 

`basePipelineIndex`를 사용하여 인덱스별로 생성될 다른 파이프라인을 참조할 수 있습니다. 

현재는 단일 파이프라인만 있으므로 `null handle`과 잘못된 `index`를 지정하기만 하면 됩니다. 이 값은 `VKGraphicsPipelineCreateInfo`의 플래그 필드에 `VK_PIPLINE_CREATE_DERIVATIVAL_BIT` 플래그가 지정된 경우에만 사용됩니다.

Now prepare for the final step by creating a class member to hold the [`VkPipeline`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipeline.html) object:

```c
VkPipeline graphicsPipeline;
```

And finally create the graphics pipeline:

```c
if (vkCreateGraphicsPipelines(device, VK_NULL_HANDLE, 1, &pipelineInfo, nullptr, &graphicsPipeline) != VK_SUCCESS) {
    throw std::runtime_error("failed to create graphics pipeline!");
}

```

The [`vkCreateGraphicsPipelines`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCreateGraphicsPipelines.html) function actually has more parameters than the usual object creation functions in Vulkan. It is designed to take multiple [`VkGraphicsPipelineCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkGraphicsPipelineCreateInfo.html) objects and create multiple [`VkPipeline`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipeline.html) objects in a single call.

The second parameter, for which we've passed the `VK_NULL_HANDLE` argument, references an optional [`VkPipelineCache`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineCache.html) object. A pipeline cache can be used to store and reuse data relevant to pipeline creation across multiple calls to [`vkCreateGraphicsPipelines`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCreateGraphicsPipelines.html) and even across program executions if the cache is stored to a file. This makes it possible to significantly speed up pipeline creation at a later time. We'll get into this in the pipeline cache chapter.

The graphics pipeline is required for all common drawing operations, so it should also only be destroyed at the end of the program:

[`vkCreateGraphicsPipeline`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCreateGraphicsPipelines.html)함수는 실제로 vulkan의 일반적인 객체 생성 함수보다 더 많은 매개변수를 가지고 있습니다. 이 함수는 여러 개의 [`vkGraphicsPipelineCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkGraphicsPipelineCreateInfo.html)객체를 한 번의 호출로 여러 개의[`vkPipeline`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipeline.html)객체를 생성하도록 설계되었습니다.

`VK_NULL_HANDLE`인수를 통과한 두 번째 매개변수는 선택적인 [`VkPipelineCache`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineCache.html)객체를 참조합니다. 파이프라인 캐시는 [`vkCreateGraphicsPipeline`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCreateGraphicsPipelines.html)에 여러 번 호출하여 파이프라인 생성과 관련된 데이터를 저장하고 재사용하는 데 사용할 수 있으며, 캐시가 파일에 저장되어 있는 경우 프로그램 실행에서도 사용할 수 있습니다. 이를 통해 나중에 파이프라인 생성 속도를 크게 높일 수 있습니다. 이에 대해서는 파이프라인 캐시 장에서 다룰 것입니다.

그래픽 파이프라인은 모든 일반적인 도면 작업에 필요하므로 프로그램이 끝날 때만 파기해야 합니다:

```c
void cleanup() {
    vkDestroyPipeline(device, graphicsPipeline, nullptr);
    vkDestroyPipelineLayout(device, pipelineLayout, nullptr);
    ...
}

```

Now run your program to confirm that all this hard work has resulted in a successful pipeline creation! We are already getting quite close to seeing something pop up on the screen. In the next couple of chapters we'll set up the actual framebuffers from the swap chain images and prepare the drawing commands.