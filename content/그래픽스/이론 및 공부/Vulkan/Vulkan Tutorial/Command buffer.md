# Command buffer

![[/image.png]]

Vulkan의 Commands은 그리기 작업 및 메모리 전송과 같이 함수 호출을 사용하여 직접 실행되지 않습니다. 수행하려는 모든 작업을 buffer objects에 기록해야 합니다. 

장점은 Vulkan에 무엇을 할 것인지 말할 준비가 되면 모든 Commands이 함께 제출되고 Vulkan이 모든 명령을 함께 사용할 수 있으므로 명령을 더 효율적으로 처리할 수 있다는 것입니다. 

또한 원하는 경우 여러 스레드에서 Commands을 수행할 수 있습니다.

# Command pools

명령 버퍼를 생성하기 전에 명령 풀을 생성해야 합니다. 명령 풀은 버퍼를 저장하는 데 사용되는 메모리를 관리하고 명령 버퍼는 여기에서 할당됩니다. [`VkCommandPool`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkCommandPool.html)을 저장할 새 클래스 멤버를 추가합니다 .

```cpp
VkCommandPool commandPool;
```

Then create a new function `createCommandPool` and call it from `initVulkan` after the framebuffers were created.

```cpp
void initVulkan() {
    createInstance();
    setupDebugMessenger();
    createSurface();
    pickPhysicalDevice();
    createLogicalDevice();
    createSwapChain();
    createImageViews();
    createRenderPass();
    createGraphicsPipeline();
    createFramebuffers();
    createCommandPool();
}

void createCommandPool() {

}

```

Command pool creation only takes two parameters:

```cpp
QueueFamilyIndices queueFamilyIndices = findQueueFamilies(physicalDevice);

VkCommandPoolCreateInfo poolInfo{};
poolInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
poolInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
poolInfo.queueFamilyIndex = queueFamilyIndices.graphicsFamily.value();
```

command pools에는 두 가지 플래그가 가능합니다.

- `VK_COMMAND_POOL_CREATE_TRANSIENT_BIT`

이 힌트는 command buffers가 새 명령으로 매우 자주 다시 기록된다(메모리 할당 동작이 변경될 수 있음)

- `VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT`

명령 버퍼를 개별적으로 다시 기록할 수 있도록 허용합니다. 이 플래그가 없으면 모든 버퍼를 함께 reset해야 한다.

우리는 매 프레임마다 명령 버퍼를 기록할 것이므로, 재설정하고 다시 기록할 수 있어야 합니다. 따라서 `VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT`명령 풀에 대한 플래그 비트를 설정해야 합니다.

Command buffers는 우리가 검색한 그래픽 및 프레젠테이션 큐와 같은 device queue 중 하나에 제출하여 실행됩니다. 각 Command pool은 단일 유형의 큐에 제출된 명령 버퍼만 할당할 수 있습니다. 우리는 그리기에 대한 명령을 기록할 것이므로 그래픽 큐 패밀리를 선택했습니다.

```cpp
if (vkCreateCommandPool(device, &poolInfo, nullptr, &commandPool) != VK_SUCCESS) {
    throw std::runtime_error("failed to create command pool!");
}
```

Finish creating the command pool using the [`vkCreateCommandPool`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCreateCommandPool.html) function. It doesn't have any special parameters. Commands will be used throughout the program to draw things on the screen, so the pool should only be destroyed at the end:

```c
void cleanup() {
    vkDestroyCommandPool(device, commandPool, nullptr);

    ...
}

```

# Command buffer allocation

We can now start allocating command buffers.

Create a [`VkCommandBuffer`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkCommandBuffer.html) object as a class member.

Command buffers will be automatically freed when their command pool is destroyed, so we don't need explicit cleanup.

클래스 멤버로 [`VkCommandBuffer`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkCommandBuffer.html)객체를 생성합니다. 

Command buffers는 command pool이 삭제될 때 자동으로 해제되므로 명시적으로 정리할 필요가 없습니다.

```c
VkCommandBuffer commandBuffer;
```

We'll now start working on a `createCommandBuffer` function to allocate a single command buffer from the command pool.

```c
void initVulkan() {
    createInstance();
    setupDebugMessenger();
    createSurface();
    pickPhysicalDevice();
    createLogicalDevice();
    createSwapChain();
    createImageViews();
    createRenderPass();
    createGraphicsPipeline();
    createFramebuffers();
    createCommandPool();
    createCommandBuffer();
}

...

void createCommandBuffer() {

}

```

Command buffers는 명령 풀과 할당할 버퍼 수를 지정하는 매개변수로 구조체를 [`vkAllocateCommandBuffers`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkAllocateCommandBuffers.html)취하는 [`VkCommandBufferAllocateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkCommandBufferAllocateInfo.html)함수 로 할당됩니다.

```c
VkCommandBufferAllocateInfo allocInfo{};
allocInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
allocInfo.commandPool = commandPool;
allocInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
allocInfo.commandBufferCount = 1;

if (vkAllocateCommandBuffers(device, &allocInfo, &commandBuffer) != VK_SUCCESS) {
    throw std::runtime_error("failed to allocate command buffers!");
}

```

`level` 매개변수는 할당된 command buffers가 primary 명령 버퍼인지 secondary 명령 버퍼인지 지정합니다. 

- `VK_COMMAND_BUFFER_LEVEL_PRIMARY`

실행을 위해 큐에 제출할 수 있지만 다른 명령 버퍼에서 호출할 수 없습니다. 

- `VK_COMMAND_BUFFER_LEVEL_SECONDARY`

직접 제출할 수 없지만 기본 명령 버퍼에서 호출할 수 있습니다.

여기 서는 보조 명령 버퍼 기능을 사용하지 않겠지만 기본 명령 버퍼에서 일반적인 작업을 재사용하는 것이 유용하다고 생각할 수 있습니다. 

command buffer는 하나만 할당하므로 `commandBufferCount`매개변수는 하나뿐입니다.

# Command buffer recording

이제 실행하고자 하는 명령을 명령 버퍼에 기록하는 `recordCommandBuffer` 함수에 대한 작업을 시작하겠습니다. 

사용되는 [`VkCommandBuffer`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkCommandBuffer.html)는 파라미터로 전달되며, 현재 쓰고자 하는 swapchain 이미지의 인덱스도 함께 전달됩니다.

```c
void recordCommandBuffer(VkCommandBuffer commandBuffer, uint32_t imageIndex) {

}

```

항상 이 특정 명령 버퍼의 사용에 대한 세부 정보를 지정하는 작은 [`VkCommandBufferBeginInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkCommandBufferBeginInfo.html) 구조를 인수로 사용하여 [`vkBeginCommandBuffer`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkBeginCommandBuffer.html)를 호출하여 명령 버퍼를 기록하기 시작합니다.

```c
VkCommandBufferBeginInfo beginInfo{};
beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
beginInfo.flags = 0; // Optional
beginInfo.pInheritanceInfo = nullptr; // Optional

if (vkBeginCommandBuffer(commandBuffer, &beginInfo) != VK_SUCCESS) {
    throw std::runtime_error("failed to begin recording command buffer!");
}

```

`flags` 매개변수는 명령어 버퍼를 어떻게 사용 할 지를 지정합니다.

- `VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT`: 명령 버퍼는 한 번 실행한 후 즉시 다시 기록됩니다.
- `VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT` 이것은 단일 렌더링 패스 내에 완전히 포함되는 보조 명령 버퍼입니다.
- `VK_COMMAND_BUFFER_USAGE_SIMOUSE_BIT`: 명령 버퍼는 이미 실행 대기 중인 상태에서도 다시 제출할 수 있습니다.

현재 이 깃발들 중 어느 것도 우리에게 해당되지 않습니다.

`pInheritanceInfo` 매개변수는 보조 명령어 버퍼에만 관련이 있습니다. 호출하는 기본 명령어 버퍼에서 상속할 상태를 지정합니다.

명령 버퍼가 이미 한 번 레코드된 경우 [`vkBeginCommandBuffer`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkBeginCommandBuffer.html)로 호출하면 암묵적으로 재설정됩니다. 나중에 버퍼에 명령을 추가할 수 없습니다.

# Starting a render pass

그리기 시작할 때, [`vkCmdBeginRenderPass`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdBeginRenderPass.html)로 렌더 패스를 시작하여 시작됩니다. render pass는 [`VkRenderPassBeginInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkRenderPassBeginInfo.html) 구조체의 일부 파라미터를 사용하여 구성됩니다.

```c
VkRenderPassBeginInfo renderPassInfo{};
renderPassInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
renderPassInfo.renderPass = renderPass;
renderPassInfo.framebuffer = swapChainFramebuffers[imageIndex];
```

The first parameters are the render pass itself and the attachments to bind. 

We created a framebuffer for each swap chain image where it is specified as a color attachment. 

Thus we need to bind the framebuffer for the swapchain image we want to draw to. Using the imageIndex parameter which was passed in, we can pick the right framebuffer for the current swapchain image.

첫 번째 매개변수는 렌더 패스 자체와 바인딩할 첨부 파일입니다.

각 스왑 체인 이미지에 대해 색상 첨부 파일로 지정된 프레임 버퍼를 만들었습니다.

따라서 우리가 그린 swapchain 이미지의 프레임 버퍼를 바인딩해야 합니다. 

전달된 imageIndex 매개변수를 사용하여 현재 swapchain 이미지에 적합한 프레임 버퍼를 선택할 수 있습니다.

```c
renderPassInfo.renderArea.offset = {0, 0};
renderPassInfo.renderArea.extent = swapChainExtent;
```

The next two parameters define the size of the render area. The render area defines where shader loads and stores will take place. The pixels outside this region will have undefined values. It should match the size of the attachments for best performance.

다음 두 매개변수는 렌더링 영역의 크기를 정의합니다. 

렌더링 영역은 셰이더 로드 및 저장소가 발생할 위치를 정의합니다. 이 영역 외부의 픽셀은 정의되지 않은 값을 갖습니다. 최고의 성능을 위해 첨부 파일의 크기와 일치해야 합니다.

```c
VkClearValue clearColor = {{{0.0f, 0.0f, 0.0f, 1.0f}}};
renderPassInfo.clearValueCount = 1;
renderPassInfo.pClearValues = &clearColor;

```

The last two parameters define the clear values to use for `VK_ATTACHMENT_LOAD_OP_CLEAR`, which we used as load operation for the color attachment. I've defined the clear color to simply be black with 100% opacity.

```c
vkCmdBeginRenderPass(commandBuffer, &renderPassInfo, VK_SUBPASS_CONTENTS_INLINE);
```

The render pass can now begin. All of the functions that record commands can be recognized by their [`vkCmd`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmd.html) prefix. They all return `void`, so there will be no error handling until we've finished recording.

The first parameter for every command is always the command buffer to record the command to. The second parameter specifies the details of the render pass we've just provided. The final parameter controls how the drawing commands within the render pass will be provided. It can have one of two values:

- `VK_SUBPASS_CONTENTS_INLINE`: The render pass commands will be embedded in the primary command buffer itself and no secondary command buffers will be executed.
- `VK_SUBPASS_CONTENTS_SECONDARY_COMMAND_BUFFERS`: The render pass commands will be executed from secondary command buffers.

We will not be using secondary command buffers, so we'll go with the first option.

이제 렌더 패스를 시작할 수 있습니다. 명령어를 기록하는 모든 기능은 [`vkCmd`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmd.html)접두사로 인식할 수 있습니다. 모두 `void`를 반환하므로 녹음이 완료될 때까지 오류 처리가 없습니다.

모든 명령에 대한 첫 번째 매개변수는 항상 명령을 기록할 명령 버퍼입니다. 

두 번째 매개변수는 방금 제공한 렌더링 패스의 세부 정보를 지정합니다. 

마지막 매개변수는 렌더링 패스 내의 그리기 명령이 어떻게 제공 되는 지를 제어합니다. 두 가지 값 중 하나를 가질 수 있습니다:

- `VK_SUBSPASS_CONTENTS_INLINE`: 렌더 패스 명령어는 기본 명령어 버퍼 자체에 내장되며 보조 명령어 버퍼는 실행되지 않습니다.
- `VK_SUBSPASS_CONTINTS_SECONDAR_COMMAND_BUFFER`: 렌더 패스 명령어는 보조 명령어 버퍼에서 실행됩니다.

우리는 보조 명령어 버퍼를 사용하지 않을 것이므로 첫 번째 옵션으로 진행하겠습니다.

# Basic drawing commands

We can now bind the graphics pipeline:

```c
vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, graphicsPipeline);
```

두 번째 매개변수는 파이프라인 객체가 그래픽인지 컴퓨팅 파이프라인인지 지정합니다. 이제 그래픽 파이프라인에서 실행할 작업과 조각 셰이더에 사용할 첨부 파일을 Vulkan에 알려드렸습니다.

[fixed functions chapter](https://vulkan-tutorial.com/en/Drawing_a_triangle/Graphics_pipeline_basics/Fixed_functions#dynamic-state)에서 언급한 바와 같이, 이 파이프라인이 동적이 되도록 뷰포트와 가위 상태를 지정했습니다. 따라서 드로우 명령을 실행하기 전에 이를 명령 버퍼에 설정해야 합니다:

```c
VkViewport viewport{};
viewport.x = 0.0f;
viewport.y = 0.0f;
viewport.width = static_cast<float>(swapChainExtent.width);
viewport.height = static_cast<float>(swapChainExtent.height);
viewport.minDepth = 0.0f;
viewport.maxDepth = 1.0f;
vkCmdSetViewport(commandBuffer, 0, 1, &viewport);

VkRect2D scissor{};
scissor.offset = {0, 0};
scissor.extent = swapChainExtent;
vkCmdSetScissor(commandBuffer, 0, 1, &scissor);

```

Now we are ready to issue the draw command for the triangle:

```c
vkCmdDraw(commandBuffer, 3, 1, 0, 0);

```

The actual [`vkCmdDraw`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdDraw.html) function is a bit anticlimactic, but it's so simple because of all the information we specified in advance. It has the following parameters, aside from the command buffer:

- `vertexCount`: Even though we don't have a vertex buffer, we technically still have 3 vertices to draw.
- `instanceCount`: Used for instanced rendering, use `1` if you're not doing that.
- `firstVertex`: Used as an offset into the vertex buffer, defines the lowest value of `gl_VertexIndex`.
- `firstInstance`: Used as an offset for instanced rendering, defines the lowest value of `gl_InstanceIndex`.
- 

실제 [`vkCmdDraw](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdDraw.html)` 함수는 약간 반 강제적이지만, 사전에 지정한 모든 정보 때문에 매우 간단합니다. 명령 버퍼 외에도 다음과 같은 매개변수가 있습니다:

- `vertexCount`: 꼭짓점 버퍼는 없지만, 기술적으로는 여전히 3개의 꼭짓점을 그려야 합니다.
- `instanceCount`: 인스턴스 렌더링에 사용되며, 그렇지 않은 경우 `1`을 사용합니다.
- `firstVertex`: 정점 버퍼의 오프셋으로 사용되며, `gl_VertexIndex`의 최저 값을 정의합니다.
- `firstInstance`: 인스턴스 렌더링을 위한 오프셋으로 사용되며, `gl_InstanceIndex`의 최저 값을 정의합니다.

# Finishing up

The render pass can now be ended:

```c
vkCmdEndRenderPass(commandBuffer);

```

And we've finished recording the command buffer:

```c
if (vkEndCommandBuffer(commandBuffer) != VK_SUCCESS) {
    throw std::runtime_error("failed to record command buffer!");
}

```

In the next chapter we'll write the code for the main loop, which will acquire an image from the swap chain, record and execute a command buffer, then return the finished image to the swap chain.