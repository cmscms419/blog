# Render passes

# Setup

파이프라인 생성을 완료하기 전에 렌더링 중에 사용할 framebuffer attachments에 대해 vulkan에게 알려야 합니다.

각 버퍼에 사용할 색상과 깊이 버퍼의 수, 샘플 수, 렌더링 작업 전반에 걸쳐 그 내용을 처리하는 방법을 지정해야 합니다. 

이 모든 정보는 *render pass* object로 감싸지며, 이를 위해 새로운 `createRenderPass`함수를 생성합니다. 그래픽 파이프라인을 만들기 전에 `initVulkan`에서 이 함수를 호출합니다.

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
}

void createRenderPass() {

}
```

# Attachment description

현재 예제 일 경우 스왑 체인의 이미지 중 하나로 표시되는 단일 색상 버퍼 Attachment만 있을 것입니다.

```c
void createRenderPass() {
    VkAttachmentDescription colorAttachment{};
    colorAttachment.format = swapChainImageFormat;
    colorAttachment.samples = VK_SAMPLE_COUNT_1_BIT;
}
```

색상 Attachment의 형식은 스왑 체인 이미지의 형식과 일치해야 하며, 멀티샘플링에 대해서는 아직 아무것도 하지 않았기 때문에 1개의 샘플을 사용할 예정입니다.

```c
colorAttachment.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
colorAttachment.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
```

`loadOp`과 `storeOp`는 렌더링 전후에 Attachment의 데이터를 어떻게 처리할지 결정합니다. `loadOp`에는 다음과 같은 옵션이 있습니다

- `VK_ATTACHMENT_LOAD_OP_LOAD`: Preserve the existing contents of the attachment
- `VK_ATTACHMENT_LOAD_OP_CLEAR`: Clear the values to a constant at the start
- `VK_ATTACHMENT_LOAD_OP_DONT_CARE`: Existing contents are undefined; we don't care about them

이 경우 새 프레임을 그리기 전에 프레임 버퍼를 검은색으로 지우는 지우기 작업을 사용하겠습니다. `storeOp`에는 두 가지 가능성만 있습니다:

- `VK_ATTACHMENT_STORE_OP_STORE`: 렌더링된 컨텐츠는 메모리에 저장되며 나중에 읽을 수 있습니다.
- `VK_ATTACHMENT_STORE_OP_DONT_CARE`: Contents of the framebuffer will be undefined after the rendering operation 프레임 버퍼에 있는 컨텐츠는 렌더링 된 이후에는 아무것도 정의하지 않는다 → 나중에 렌더링 계산할 때를 위해서, 어떠한 정의를 내리지 않는다.

화면에서 렌더링된 삼각형을 보고 싶기 때문에 여기서는 스토어 작업을 진행하겠습니다.

```c
colorAttachment.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
colorAttachment.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
```

`loadOp`과 `storeOp`은 색상 및 깊이 데이터에 적용되고, `stencilLoadOp` / `stencilStoreOp` 은 스텐실 데이터에 적용됩니다.  애플리케이션은 스텐실 버퍼로 아무 작업도 하지 않으므로 로드 및 저장 결과는 관련이 없습니다.

```c
colorAttachment.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
colorAttachment.finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
```

vulkan의 텍스처와 프레임버퍼는 특정 픽셀 포맷의 [`VkImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImage.html) 객체로 표현되지만, 이미지로 무엇을 하려는지에 따라 메모리 내 픽셀 레이아웃이 변경될 수 있습니다.

Some of the most common layouts are:

- `VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL`: Images used as color attachment
- `VK_IMAGE_LAYOUT_PRESENT_SRC_KHR`: Images to be presented in the swap chain
- `VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL`: Images to be used as destination for a memory copy operation

이 주제에 대해서는 텍스처 링 장에서 자세히 설명하지만, 지금 당장 알아야 할 중요한 점은 이미지를 다음에 수행할 작업에 적합한 특정 레이아웃으로 전환해야 한다는 것입니다.

`initialLayout` 은 render pass가 시작되기 전에 이미지에 어떤 `layout`이 포함될지 지정합니다. 

`finalLayout` 은 render pass가 완료될 때 자동으로 전환할 `layout`을 지정합니다. `initialLayout` 에 `VK_IMAGE_LAYOUT_UNDEFENTED`를 사용하면 이미지가 이전에 어떤 `layout`에 있었는지 신경 쓰지 않습니다. 이 특별한 값의 주의 사항은 이미지의 내용이 보존될 것이라는 보장이 없다는 것이지만, 어차피 클리어할 것이기 때문에 이는 중요하지 않습니다. 렌더링 후 스왑 체인을 사용하여 이미지를 프레젠테이션할 준비가 되기를 원하기 때문에 `finalLayout`으로 `VK_IMAGE_LAYOUT_PRESENT_SRC_KHR`을 사용합니다.

# Subpasses and attachment references

단일 렌더 패스는 여러 개의 하위 패스로 구성될 수 있습니다. 

하위 패스는 이전 패스의 프레임 버퍼 내용에 따라 달라지는 후속 렌더링 작업으로, 예를 들어 차례로 적용되는 일련의 post-processing effects입니다.

이러한 렌더링 작업을 하나의 render pass로 그룹화하면 Vulkan은 작업을 재정렬하고 메모리 대역폭을 보존하여 더 나은 성능을 낼 수 있습니다. 그러나 첫 번째 삼각형의 경우 단일 하위 패스를 고수하겠습니다.

모든 하위 패스는 이전 sections의 구조를 사용하여 설명한 Attachment 중 하나 이상을 참조합니다. 이러한 참조 자체는 [`VkAttachmentReference`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkAttachmentReference.html)다음과 같은 구조체입니다.

```c
VkAttachmentReference colorAttachmentRef{};
colorAttachmentRef.attachment = 0;
colorAttachmentRef.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
```

`attachment` 매개 변수는 attachment descriptions array에서 인덱스로 참조할 attachment을 지정합니다. 이 배열은 단일 [`VkAttachmentDescription`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkAttachmentDescription.html) 으로 구성되므로 인덱스는 `0`입니다. `layout`은 참조를 사용하는 하위 패스 동안 Attachment에 어떤 레이아웃을 사용할지 지정합니다. Vulkan은 하위 패스가 시작될 때 Attachment을 자동으로 이 레이아웃으로 전환합니다. Attachment을 색상 버퍼로 사용하고자 하며, `VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL`이름에서 알 수 있듯이 레이아웃이 최상의 성능을 제공합니다.

The subpass is described using a [`VkSubpassDescription`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkSubpassDescription.html) structure:

```c
VkSubpassDescription subpass{};
subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
```

Vulkan은 미래에 컴퓨팅 서브패스를 지원할 수도 있으므로 그래픽 서브패스에 대해 명확히 설명해야 합니다. 다음으로 색상 Attachment에 대한 참조를 지정합니다:

```c
subpass.colorAttachmentCount = 1;
subpass.pColorAttachments = &colorAttachmentRef;
```

이 배열의 Attachment 인덱스는 `layout(location = 0) out vec4 outColor` 지시문이 있는  `fragment shader`에서 직접 참조됩니다!

The following other types of attachments can be referenced by a subpass:

- `pInputAttachments`: 셰이더에서 읽은 Attachments
- `pResolveAttachments`: 멀티샘플링 색상 Attachment에 사용되는 Attachments
- `pDepthStencilAttachment`: 깊이 및 스텐실 데이터 Attachment
- `pPreserveAttachments`: 이 서브패스에서 사용되지 않지만 데이터를 보존해야 하는 Attachments

# Render pass

Now that the attachment and a basic subpass referencing it have been described, we can create the render pass itself. Create a new class member variable to hold the [`VkRenderPass`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkRenderPass.html) object right above the `pipelineLayout` variable:

이제 Attachment과 이를 참조하는 기본 서브패스에 대해 설명했으니 렌더 패스 자체를 만들 수 있습니다. `pipelineLayout`변수 바로 위에 있는[`VkRenderPass`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkRenderPass.html)객체를 고정할 새 클래스 멤버 변수를 만듭니다:

```c
VkRenderPass renderPass;
VkPipelineLayout pipelineLayout;

```

The render pass object can then be created by filling in the [`VkRenderPassCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkRenderPassCreateInfo.html) structure with an array of attachments and subpasses. The [`VkAttachmentReference`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkAttachmentReference.html) objects reference attachments using the indices of this array.

렌더 패스 객체는 Attachment과 서브패스 배열로 [`VkRenderPassCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkRenderPassCreateInfo.html) 구조를 채워 생성할 수 있습니다.

[`VkAttachmentReference`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkAttachmentReference.html)객체는 이 배열의 인덱스를 사용하여 Attachment을 참조합니다.

```c
VkRenderPassCreateInfo renderPassInfo{};
renderPassInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
renderPassInfo.attachmentCount = 1;
renderPassInfo.pAttachments = &colorAttachment;
renderPassInfo.subpassCount = 1;
renderPassInfo.pSubpasses = &subpass;

if (vkCreateRenderPass(device, &renderPassInfo, nullptr, &renderPass) != VK_SUCCESS) {
    throw std::runtime_error("failed to create render pass!");
}

```

Just like the pipeline layout, the render pass will be referenced throughout the program, so it should only be cleaned up at the end:

```c
void cleanup() {
    vkDestroyPipelineLayout(device, pipelineLayout, nullptr);
    vkDestroyRenderPass(device, renderPass, nullptr);
    ...
}

```

That was a lot of work, but in the next chapter it all comes together to finally create the graphics pipeline object!

We can now combine all of the structures and objects from the previous chapters to create the graphics pipeline! Here's the types of objects we have now, as a quick recap:

# ++

https://vkguide.dev/docs/chapter-1/vulkan_renderpass/

VkRenderPass는 렌더링을 위한 "대상"을 설정하는 데 필요한 상태와 렌더링할 이미지의 상태를 캡슐화하는 Vulkan 객체입니다.

Renderpass는 Framebuffer로 렌더링합니다. Framebuffer는 렌더링할 이미지에 연결되며, 렌더링할 대상 이미지를 설정하는 Renderpass를 시작할 때 사용됩니다.

명령을 인코딩할 때 렌더 패스를 일반적으로 사용하는 방법은 다음과 같습니다.

```cpp
vkBeginCommandBuffer(cmd, ...);

vkCmdBeginRenderPass(cmd, ...);

//rendering commands go here

vkCmdEndRenderPass(cmd);

vkEndCommandBuffer(cmd)
```

렌더패스를 시작할 때 대상 프레임버퍼와 클리어 컬러(사용 가능한 경우)를 설정합니다. 이 첫 번째 챕터에서는 클리어 컬러를 시간이 지남에 따라 동적으로 변경합니다.

### **Subpasses**

렌더패스에는 렌더링 "단계"와 비슷한 하위 패스도 포함됩니다. 모바일 GPU에서 매우 유용할 수 있는데, 드라이버가 많은 것을 최적화할 수 있기 때문입니다. 데스크톱 GPU에서는 덜 중요하므로 사용하지 않을 것입니다. 렌더패스를 만들 때 렌더링에 필요한 최소값인 하위 패스가 하나만 있습니다.

### image layout

렌더 패스에서 매우 중요한 일 중 하나는 렌더 패스에 들어가고 나올 때 이미지 레이아웃을 변경한다는 것입니다.

GPU의 이미지는 반드시 예상하는 형식이 아닐 수 있습니다. 최적화를 위해 GPU는 이미지를 내부 불투명 형식으로 변환하고 다시 섞는 작업을 많이 수행합니다. 예를 들어, 일부 GPU는 가능한 한 텍스처를 압축하고 픽셀이 배열되는 방식을 재정렬하여 밉맵을 더 잘 구현합니다. Vulkan에서는 이를 제어할 수 없지만 이미지 레이아웃을 제어할 수 있어 드라이버가 이미지를 최적화된 내부 형식으로 변환할 수 있습니다.

이 첫 번째 장에서는 몇 가지 이미지 레이아웃만 사용할 것입니다.

- `VK_IMAGE_LAYOUT_UNDEFINED`
    
    : 레이아웃이 어떻든 상관없어요. 무엇이든 될 수 있어요.
    
- `VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL`
    
    : 이미지는 렌더링 명령으로 쓰기에 최적의 레이아웃에 있습니다.
    
- `VK_IMAGE_LAYOUT_PRESENT_SRC_KHR`
    
    : 이미지는 화면에 이미지를 표시할 수 있는 레이아웃에 있습니다.
    
- `VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL`
    
    : (나중에 사용됨) 이미지는 셰이더에서 읽히도록 최적화된 형식입니다.
    

### vkQueueSubmit 파트

```cpp
//prepare the submission to the queue.
	//we want to wait on the _presentSemaphore, as that semaphore is signaled when the swapchain is ready
	//we will signal the _renderSemaphore, to signal that rendering has finished

	VkSubmitInfo submit = {};
	submit.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
	submit.pNext = nullptr;

	VkPipelineStageFlags waitStage = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;

	submit.pWaitDstStageMask = &waitStage;

	submit.waitSemaphoreCount = 1;
	submit.pWaitSemaphores = &_presentSemaphore;

	submit.signalSemaphoreCount = 1;
	submit.pSignalSemaphores = &_renderSemaphore;

	submit.commandBufferCount = 1;
	submit.pCommandBuffers = &cmd;

	//submit command buffer to the queue and execute it.
	// _renderFence will now block until the graphic commands finish execution
	VK_CHECK(vkQueueSubmit(_graphicsQueue, 1, &submit, _renderFence));
```

`vkQueueSubmit()`을 실행하려면 info structure를 설정해야 합니다. `_presentSemaphore`에서 대기하고 `_renderSemaphore`에 신호를 보내도록 구성할 것입니다. `vkAcquireNextImageKHR`에서 신호를 보내는 `_presentSemaphore`를 기다림으로써 렌더링할 이미지가 GPU에서 완전히 준비되었는지 확인합니다.

그런 다음 전송할 명령 버퍼도 설정합니다.

`.pWaitDstStageMask`는 복잡한 매개변수입니다. 동기화에 대해 자세히 설명하기 전까지는 설명하지 않겠습니다.

명령이 제출되면 이제 이미지를 화면에 표시합니다.

```cpp
	// this will put the image we just rendered into the visible window.
	// we want to wait on the _renderSemaphore for that,
	// as it's necessary that drawing commands have finished before the image is displayed to the user
	VkPresentInfoKHR presentInfo = {};
	presentInfo.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
	presentInfo.pNext = nullptr;

	presentInfo.pSwapchains = &_swapchain;
	presentInfo.swapchainCount = 1;

	presentInfo.pWaitSemaphores = &_renderSemaphore;
	presentInfo.waitSemaphoreCount = 1;

	presentInfo.pImageIndices = &swapchainImageIndex;

	VK_CHECK(vkQueuePresentKHR(_graphicsQueue, &presentInfo));

	//increase the number of frames drawn
	_frameNumber++;
```

`vkQueuePresentKHR`함수는 이미지를 화면에 표시합니다. 

호출에 어떤 스왑체인을 사용하고 있는지, 이미지 인덱스는 무엇인지 알려줘야 합니다. 

또한 메인 렌더링의 `VkQueueSubmit`에서 신호를 보내는 `_renderSemaphore`로 `WaitSemaphore`를 올바르게 설정해야 합니다. 

이렇게 하면 메인 렌더링 작업의 실행이 완료된 후에만 이미지를 화면에 표시하도록 GPU에 지시합니다. 이제 렌더링 프레임이 완료되었으므로 `_frameNumber` 변수를 증가시켜 엔진 시간을 늘릴 수 있습니다.

# ++

구글  **Gemini 2.0 Pro Experimental 02-05에 “**Render passes에 대해서 알려줘” 질문으로 나온 답

## Vulkan Render Passes (렌더 패스)

Vulkan Render Passes는 렌더링 과정을 효율적으로 구성하고 최적화하기 위한 핵심적인 개념입니다.

렌더 패스를 사용하면 렌더링 작업을 여러 개의 하위 단계(subpasses)로 나누고, 각 단계에서 사용할 attachments(프레임버퍼 이미지 등)와 그 attachments를 어떻게 사용할지를 명확하게 정의할 수 있습니다.

**핵심 개념:**

1. **Attachments (어태치먼트):**
    - 렌더링 과정에서 사용되는 이미지들을 의미합니다.
    - 주로 컬러 버퍼, 깊이 버퍼(depth buffer), 스텐실 버퍼(stencil buffer), 멀티샘플링을 위한 resolve attachments 등이 있습니다.
    - Render Pass 생성 시 각 attachment의 형식(format), 샘플링 수(sample count), 로드/저장 동작(load/store operations) 등을 지정합니다.
2. **Subpasses (서브패스):**
    - Render Pass는 하나 이상의 subpass로 구성됩니다.
    - 각 subpass는 렌더링 파이프라인의 특정 단계를 나타냅니다 (예: 지오메트리 패스, 라이팅 패스, 후처리 패스 등).
    - Subpass는 사용할 attachments, input attachments (이전 subpass의 출력을 입력으로 사용), preserve attachments (값을 유지할 attachments) 등을 정의합니다.
    - Subpass 간의 의존성(dependencies)을 설정하여 데이터 흐름을 제어하고 동기화를 수행합니다.
3. **Render Pass Object (렌더 패스 객체):**
    - Attachments, Subpasses, Subpass Dependencies를 묶어서 하나의 객체로 정의합니다.
    - Vulkan API에서 VkRenderPass 핸들로 표현됩니다.
    - 렌더링 명령을 기록하기 전에 Render Pass를 시작(vkCmdBeginRenderPass)하고, 렌더링이 끝나면 Render Pass를 종료(vkCmdEndRenderPass)해야 합니다.

**Render Pass를 사용하는 이유 (장점):**

- **최적화:**
    - **타일 기반 렌더러(Tiled-Based Renderer) 최적화:** 모바일 GPU와 같은 타일 기반 렌더러에서 Render Pass는 매우 중요합니다. 각 subpass가 타일 메모리 내에서 처리될 수 있도록 하여 메모리 대역폭 사용을 줄이고 성능을 향상시킵니다.
    - **불필요한 로드/저장 방지:** 각 attachment의 loadOp(로드 동작)과 storeOp(저장 동작)을 정밀하게 제어하여, 불필요한 메모리 읽기/쓰기를 방지할 수 있습니다. 예를 들어, 깊이 버퍼를 한 번만 로드하고 여러 subpass에서 사용하거나, 중간 결과를 버리고 최종 결과만 저장할 수 있습니다.
    - **암시적 의존성(Implicit Dependencies):** Subpass dependencies를 통해 Vulkan 드라이버는 subpass 간의 데이터 흐름을 파악하고 최적화된 동기화 방법을 자동으로 적용할 수 있습니다. 개발자가 명시적으로 synchronization primitives(semaphores, barriers)를 사용할 필요를 줄여줍니다.
- **구조화된 렌더링:**
    - 복잡한 렌더링 과정을 여러 subpass로 나누어 관리하기 쉽게 만듭니다.
    - 각 subpass의 역할을 명확하게 정의하여 코드 가독성과 유지보수성을 높입니다.
    - Subpass 간의 데이터 흐름을 명시적으로 정의하여 렌더링 파이프라인을 이해하기 쉽게 만듭니다.

**간단한 Render Pass 예시 (개념적):**

```cpp
// Attachment 정의 (컬러 버퍼, 깊이 버퍼)
AttachmentDescription colorAttachment = {
    format = VK_FORMAT_R8G8B8A8_UNORM,
    loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR, // Render Pass 시작 시 클리어
    storeOp = VK_ATTACHMENT_STORE_OP_STORE, // Render Pass 종료 시 저장
    ...
};
AttachmentDescription depthAttachment = {
    format = VK_FORMAT_D32_SFLOAT,
    loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
    storeOp = VK_ATTACHMENT_STORE_OP_DONT_CARE, // 깊이 버퍼는 저장하지 않음
    ...
};

// Subpass 정의 (하나의 subpass만 사용)
SubpassDescription subpass = {
    colorAttachments = { colorAttachment }, // 컬러 버퍼 사용
    depthStencilAttachment = depthAttachment, // 깊이 버퍼 사용
    ...
};

// Render Pass 생성
RenderPassCreateInfo renderPassInfo = {
    attachments = { colorAttachment, depthAttachment },
    subpasses = { subpass },
    ...
};
VkRenderPass renderPass;
vkCreateRenderPass(device, &renderPassInfo, nullptr, &renderPass);
```

content_copy  download  Use code [with caution](https://support.google.com/legal/answer/13505487).

**Render Pass 사용 흐름:**

1. **Render Pass 생성:** 사용할 attachments, subpasses, subpass dependencies를 정의하여 VkRenderPass 객체를 생성합니다.
2. **Framebuffer 생성:** Render Pass와 호환되는 VkFramebuffer 객체를 생성합니다. Framebuffer는 Render Pass에서 사용할 실제 이미지 뷰(image views)를 연결합니다.
3. **렌더링 명령 기록:**
    - vkCmdBeginRenderPass: Render Pass를 시작합니다. 사용할 Framebuffer, clear values(로드 동작이 VK_ATTACHMENT_LOAD_OP_CLEAR인 경우) 등을 지정합니다.
    - vkCmdBindPipeline: 사용할 그래픽스 파이프라인(graphics pipeline)을 바인딩합니다. 파이프라인은 Render Pass와 호환되어야 합니다.
    - vkCmdDraw / vkCmdDrawIndexed: 그리기 명령을 실행합니다.
    - vkCmdNextSubpass (필요한 경우): 다음 subpass로 전환합니다.
    - vkCmdEndRenderPass: Render Pass를 종료합니다.

**더 복잡한 예시 (멀티패스 렌더링):**

- **Deferred Rendering (지연 렌더링):** 지오메트리 패스(geometry pass)에서 G-buffer(컬러, 노멀, 깊이 등)를 생성하고, 라이팅 패스(lighting pass)에서 G-buffer를 input attachments로 사용하여 조명 계산을 수행합니다.
- **Forward+ Rendering (포워드 플러스 렌더링):** 타일 별로 조명 정보를 저장하고, 최종 렌더링 패스에서 이 정보를 사용하여 조명을 적용합니다.
- **Post-Processing (후처리):** 이전 subpass의 출력을 input attachment로 사용하여 블러, 색 보정, HDR 톤 매핑 등 다양한 효과를 적용합니다.

Render Passes는 Vulkan의 강력한 기능 중 하나이며, 렌더링 파이프라인을 세밀하게 제어하고 최적화하는 데 필수적입니다. 처음에는 복잡해 보일 수 있지만, 익숙해지면 렌더링 성능을 크게 향상시킬 수 있습니다.

# ++

https://github.com/KhronosGroup/Vulkan-Docs/wiki/Synchronization-Examples

vulkan 참고하기