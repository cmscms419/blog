# rendering and presentation

This is the chapter where everything is going to come together. We're going to write the `drawFrame` function that will be called from the main loop to put the triangle on the screen. Let's start by creating the function and call it from `mainLoop`:

이것은 모든 것이 하나로 합쳐질 장입니다. 우리는 메인 루프에서 호출될 screen 삼각형 `drawFrame` 함수를 작성할 것 입니. 

함수를 만들고 다음에서 `mainLoop`호출하는 것으로 시작하겠습니다

```c
void mainLoop() {
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();
        drawFrame();
    }
}

...

void drawFrame() {

}
```

# Outline of a frame

대략적으로 Vulkan에서 프레임을 렌더링하는 것은 일반적인 단계로 구성됩니다.

- 이전 프레임이 끝날 때까지 기다립니다.
- 스왑 체인에서 이미지 가져오기
- 해당 이미지에 장면을 그리는 명령 버퍼를 기록합니다.
- 기록된 명령 버퍼를 제출합니다.
- 스왑 체인 이미지 표시

이후 장에서 그리기 기능을 확장하겠지만 지금은 렌더 루프의 핵심.

# Synchronization

- Acquire an image from the swap chain
- Execute commands that draw onto the acquired image
- Present that image to the screen for presentation, returning it to the swapchain

Vulkan의 핵심 설계 철학은 GPU에서 실행 동기화가 명확하다는 것입니다. 연산 순서는 드라이버에게 실행할 순서를 알려주는 다양한 동기화 프리미티브를 사용하여 정의하는 것에 달려 있습니다.  즉, GPU에서 작업을 실행하기 시작하는 많은 Vulkan API 호출이 비동기적이며, 연산이 완료되기 전에 함수가 반환 됩니다.

이 장에서는 GPU에서 발생하기 때문에 다음과 같이 명시적으로 주문해야 하는 여러 이벤트가 있습니다:

- 스왑 체인에서 이미지 획득
- 획득한 이미지에 draw 명령어 실행
- 해당 이미지를 화면에 표시하여 프레젠테이션하고 swapchain으로 되돌립니다

이러한 각 이벤트는 단일 함수 호출을 사용하여 설정되지만 모두 비동기식으로 실행됩니다. 함수 호출은 실제로 작업이 완료되기 전에 반환 되며 실행 순서도 정의되지 않습니다. 안타깝게도 각 작업은 이전 완료에 따라 달라지기 때문입니다. 따라서 원하는 순서를 달성하기 위해 어떤 프리미티브를 사용할 수 있는지 살펴봐야 합니다.

# Semaphores

A semaphore is used to add order between queue operations. Queue operations refer to the work we submit to a queue, either in a command buffer or from within a function as we will see later. Examples of queues are the graphics queue and the presentation queue. Semaphores are used both to order work inside the same queue and between different queues.

There happens to be two kinds of semaphores in Vulkan, binary and timeline. Because only binary semaphores will be used in this tutorial, we will not discuss timeline semaphores. Further mention of the term semaphore exclusively refers to binary semaphores.

A semaphore is either unsignaled or signaled. It begins life as unsignaled. The way we use a semaphore to order queue operations is by providing the same semaphore as a 'signal' semaphore in one queue operation and as a 'wait' semaphore in another queue operation.

For example, lets say we have semaphore S and queue operations A and B that we want to execute in order. What we tell Vulkan is that operation A will 'signal' semaphore S when it finishes executing, and operation B will 'wait' on semaphore S before it begins executing. When operation A finishes, semaphore S will be signaled, while operation B wont start until S is signaled. After operation B begins executing, semaphore S is automatically reset back to being unsignaled, allowing it to be used again.

semaphore는 큐 작업 간에 순서를 추가하는 데 사용됩니다. 큐 작업은 나중에 보게 될 명령어 버퍼 또는 함수 내에서 큐에 제출하는 작업을 의미합니다. 큐의 예로는 그래픽 큐과 프레젠테이션 큐이 있습니다. semaphore는 동일한 큐 내부와 다른 큐 간에 작업을 순서화하는 데 모두 사용됩니다.

vulkan에는 binary and timeline이라는 두 가지 종류의 semaphore가 있습니다. 이 튜토리얼에서는 이진 semaphore만 사용되므로 타임라인 semaphore에 대해서는 설명하지 않겠습니다. semaphore라는 용어에 대한 추가 언급은 이진 semaphore만을 지칭합니다.

semaphore는 unsignaled과 signaled이 있습니다. semaphore는 unsignaled과로 시작합니다. semaphore를 사용하여 큐 작업을 정렬하는 방법은 한 큐 작업에서 'signal' semaphore와 동일한 semaphore를 제공하고 다른 큐 작업에서 'wait' semaphore로 제공하는 것입니다. 

예를 들어, semaphore S와 순서대로 실행하려는 큐 작업 A와 B가 있다고 가정해 보겠습니다. vulkan에게 알리면 작업 A는 실행을 완료하면 semaphore S에 대해 'signal'를 보내고, 작업 B는 실행을 시작하기 전에 semaphore S에 대해 'wait'를 한다는 것입니다. 

작업 A가 완료되면 semaphore S는 신호를 받고, 작업 B는 S가 신호를 받을 때까지 시작하지 않습니다. 작업 B가 실행을 시작한 후 semaphore S는 자동으로 신호를 받지 않은 상태로 재설정되어 다시 사용할 수 있습니다.

Pseudo-code of what was just described:

```cpp
VkCommandBuffer A, B = ... // record command buffers
VkSemaphore S = ... // create a semaphore

// enqueue A, signal S when done - starts executing immediately
vkQueueSubmit(work: A, signal: S, wait: None)

// enqueue B, wait on S to start
vkQueueSubmit(work: B, signal: None, wait: S)

```

Note that in this code snippet, both calls to `vkQueueSubmit()` return immediately - the waiting only happens on the GPU. The CPU continues running without blocking. To make the CPU wait, we need a different synchronization primitive, which we will now describe.

이 코드 스니펫에서는 `vkQueueSubmit()`에 대한 두 호출이 즉시 반환되며, 대기는 GPU에서만 발생합니다. CPU는 차단 없이 계속 실행됩니다. CPU를 대기시키기 위해서는 이제 설명할 다른 동기화 프리미티브가 필요합니다.

# Fences

A fence has a similar purpose, in that it is used to synchronize execution, but it is for ordering the execution on the CPU, otherwise known as the host. Simply put, if the host needs to know when the GPU has finished something, we use a fence.

Similar to semaphores, fences are either in a signaled or unsignaled state. Whenever we submit work to execute, we can attach a fence to that work. When the work is finished, the fence will be signaled. Then we can make the host wait for the fence to be signaled, guaranteeing that the work has finished before the host continues.

A concrete example is taking a screenshot. Say we have already done the necessary work on the GPU. Now need to transfer the image from the GPU over to the host and then save the memory to a file. We have command buffer A which executes the transfer and fence F. We submit command buffer A with fence F, then immediately tell the host to wait for F to signal. This causes the host to block until command buffer A finishes execution. Thus we are safe to let the host save the file to disk, as the memory transfer has completed.

Pseudo-code for what was described:

fence는 실행을 동기화하는 데 사용된다는 점에서 비슷한 목적을 가지고 있지만, 호스트라고도 알려진 CPU에서 실행을 명령하기 위한 것입니다. 간단히 말해 호스트가 GPU에서 어떤 일이 완료되었는지 알아야 하는 경우 fence를 사용합니다.

semaphore와 마찬가지로 fence는 signaled이거나 unsignaled입니다. 작업을 수행하기 위해 작업을 제출할 때마다 해당 작업에 fence를 부착할 수 있습니다. 작업이 완료되면 fence에 signaled이 표시됩니다. 그런 다음 호스트가 fence에 신호가 올 때까지 기다리도록 하여 호스트가 계속 진행하기 전에 작업이 완료되었는지 확인할 수 있습니다.

구체적인 예로는 스크린샷을 찍는 것이 있습니다. GPU에서 이미 필요한 작업을 완료했다고 가정해 보겠습니다. 이제 GPU에서 호스트로 이미지를 전송한 다음 메모리를 파일에 저장해야 합니다. 우리는 명령 버퍼 A에 fence F를 제출한 후, 즉시 호스트에게 F가 신호를 보낼 때까지 기다리라고 지시합니다. 이로 인해 호스트는 명령 버퍼 A가 실행을 완료할 때까지 차단됩니다. 따라서 메모리 전송이 완료되었으므로 호스트가 파일을 디스크에 저장하도록 해도 안전합니다.

설명된 내용에 대한 의사 코드:

```cpp
VkCommandBuffer A = ... // record command buffer with the transfer
VkFence F = ... // create the fence

// enqueue A, start work immediately, signal F when done
vkQueueSubmit(work: A, fence: F)

vkWaitForFence(F) // blocks execution until A has finished executing

save_screenshot_to_disk() // can't run until the transfer has finished

```

Unlike the semaphore example, this example *does* block host execution. This means the host won't do anything except wait until execution has finished. For this case, we had to make sure the transfer was complete before we could save the screenshot to disk.

In general, it is preferable to not block the host unless necessary. We want to feed the GPU and the host with useful work to do. Waiting on fences to signal is not useful work. Thus we prefer semaphores, or other synchronization primitives not yet covered, to synchronize our work.

Fences must be reset manually to put them back into the unsignaled state. This is because fences are used to control the execution of the host, and so the host gets to decide when to reset the fence. Contrast this to semaphores which are used to order work on the GPU without the host being involved.

In summary, semaphores are used to specify the execution order of operations on the GPU while fences are used to keep the CPU and GPU in sync with each-other.

semaphore 예제와 달리 이 예제는 호스트 실행을 *하는 것*을 차단합니다. 즉, 호스트는 실행이 완료될 때까지 기다리는 것 외에는 아무것도 하지 않습니다. 이 경우 스크린샷을 디스크에 저장하기 전에 전송이 완료되었는지 확인해야 했습니다.

일반적으로 필요한 경우가 아니면 호스트를 차단하지 않는 것이 좋습니다. GPU와 호스트에게 유용한 작업을 제공하고자 합니다. 신호를 보내기 위해 fence에서 기다리는 것은 유용한 작업이 아닙니다. 따라서 작업을 동기화하기 위해 semaphore 또는 아직 다루지 않은 다른 동기화 프리미티브를 선호합니다.

fence를 신호가 없는 상태로 되돌리려면 수동으로 fence를 재설정해야 합니다. 이는 fence가 호스트의 실행을 제어하는 데 사용되므로 호스트가 fence를 재설정할 시기를 결정할 수 있기 때문입니다. 이를 호스트가 관여하지 않고 GPU에서 작업을 명령하는 데 사용되는 semaphore와 대조해 보세요.

요약하자면, semaphore는 GPU에서 작업의 실행 순서를 지정하는 데 사용되며, fence는 CPU와 GPU가 서로 동기화되도록 유지하는 데 사용됩니다.

# What to choose?

We have two synchronization primitives to use and conveniently two places to apply synchronization: Swapchain operations and waiting for the previous frame to finish. We want to use semaphores for swapchain operations because they happen on the GPU, thus we don't want to make the host wait around if we can help it.

For waiting on the previous frame to finish, we want to use fences for the opposite reason, because we need the host to wait. This is so we don't draw more than one frame at a time. Because we re-record the command buffer every frame, we cannot record the next frame's work to the command buffer until the current frame has finished executing, as we don't want to overwrite the current contents of the command buffer while the GPU is using it.

우리는 두 가지 동기화 기본 요소를 사용할 수 있으며, 동기화를 적용할 수 있는 편리한 두 사용 방법이 있습니다: 스왑체인 작업과 이전 프레임이 완료될 때까지 대기하는 것입니다.
스왑체인 작업은 GPU에서 발생하기 때문에 semaphore를 사용하고 싶습니다. 이전 프레임이 끝나기를 기다리기 위해, 호스트가 기다려야 하기 때문에 반대 이유로 Fence를 사용하고 싶습니다. 이는 한 번에 두 개 이상의 프레임을 그리지 않기 위해서입니다. 명령 버퍼를 매 프레임마다 다시 기록하기 때문에 현재 프레임이 실행을 완료할 때까지 다음 프레임의 작업을 명령 버퍼에 기록할 수 없습니다. GPU가 명령 버퍼를 사용하는 동안 명령 버퍼의 현재 내용을 덮어 쓰고 싶지 않기 때문입니다.

# Creating the synchronization objects

We'll need one semaphore to signal that an image has been acquired from the swapchain and is ready for rendering, another one to signal that rendering has finished and presentation can happen, and a fence to make sure only one frame is rendering at a time.

Create three class members to store these semaphore objects and fence object:

스왑 체인에서 이미지가 획득되어 렌더링 준비가 되었음을 알리는 semaphore 하나, 렌더링이 완료되어 프레젠테이션이 가능함을 알리는 semaphore 하나, 한 번에 하나의 프레임만 렌더링되도록 하는 fence가 필요합니다.

세 명의 클래스 멤버를 만들어 이 semaphore 객체와 fence 객체를 저장하세요:

```c
VkSemaphore imageAvailableSemaphore;
VkSemaphore renderFinishedSemaphore;
VkFence inFlightFence;

```

To create the semaphores, we'll add the last `create` function for this part of the tutorial: `createSyncObjects`:

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
    createSyncObjects();
}

...

void createSyncObjects() {

}

```

Creating semaphores requires filling in the[`VkSemaphoreCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkSemaphoreCreateInfo.html), but in the current version of the API it doesn't actually have any required fields besides `sType`:

세마포어를 만들려면 [`VkSemaphoreCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkSemaphoreCreateInfo.html)를 입력해야 하지만, 현재 버전의 API에서는 `sType`외에 실제로 필요한 필드가 없습니다:

```c
void createSyncObjects() {
    VkSemaphoreCreateInfo semaphoreInfo{};
    semaphoreInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
}

```

Future versions of the Vulkan API or extensions may add functionality for the `flags` and `pNext` parameters like it does for the other structures.

Creating a fence requires filling in the [`VkFenceCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkFenceCreateInfo.html):

향후 버전의 Vulkan API 또는 확장 프로그램은 다른 구조와 마찬가지로 `flags` 및 `pNext` 매개변수에 대한 기능을 추가할 수 있습니다.

울타리를 만들려면 [`VkFenceCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkFenceCreateInfo.html) 를 작성해야 합니다:

```c
VkFenceCreateInfo fenceInfo{};
fenceInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
```

Creating the semaphores and fence follows the familiar pattern with [`vkCreateSemaphore`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCreateSemaphore.html) & [`vkCreateFence`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCreateFence.html):

```c
if (vkCreateSemaphore(device, &semaphoreInfo, nullptr, &imageAvailableSemaphore) != VK_SUCCESS ||
    vkCreateSemaphore(device, &semaphoreInfo, nullptr, &renderFinishedSemaphore) != VK_SUCCESS ||
    vkCreateFence(device, &fenceInfo, nullptr, &inFlightFence) != VK_SUCCESS) {
    throw std::runtime_error("failed to create semaphores!");
}

```

The semaphores and fence should be cleaned up at the end of the program, when all commands have finished and no more synchronization is necessary:

```c
void cleanup() {
    vkDestroySemaphore(device, imageAvailableSemaphore, nullptr);
    vkDestroySemaphore(device, renderFinishedSemaphore, nullptr);
    vkDestroyFence(device, inFlightFence, nullptr);

```

Onto the main drawing function!

# Waiting for the previous frame

At the start of the frame, we want to wait until the previous frame has finished, so that the command buffer and semaphores are available to use. To do that, we call [`vkWaitForFences`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkWaitForFences.html):

프레임이 시작될 때, 이전 프레임이 완료될 때까지 기다렸다가 명령 버퍼와 세마포어를 사용할 수 있도록 하고 싶습니다. 이를 위해 [`vkWaitForFences`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkWaitForFences.html)를 호출합니다:

```c
void drawFrame() {
    vkWaitForFences(device, 1, &inFlightFence, VK_TRUE, UINT64_MAX);
}

```

The [`vkWaitForFences`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkWaitForFences.html) function takes an array of fences and waits on the host for either any or all of the fences to be signaled before returning. The `VK_TRUE` we pass here indicates that we want to wait for all fences, but in the case of a single one it doesn't matter. This function also has a timeout parameter that we set to the maximum value of a 64 bit unsigned integer, `UINT64_MAX`, which effectively disables the timeout.

After waiting, we need to manually reset the fence to the unsignaled state with the [`vkResetFences`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkResetFences.html) call:

[`vkWaitForFence`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkWaitForFences.html) 함수는 여러 개의 fences를 가져와서 호스트에서 신호를 받은 후 반환할 때까지 기다립니다. 여기서 전달하는 `VK_TRUE`는 모든 fences를 기다리고 싶지만 단일 fence의 경우 상관없다는 것을 나타냅니다. 이 함수에는 타임아웃 매개변수를 설정하여 64비트 부호 없는 정수 `UINT64_MAX`의 최대값으로 설정하여 타임아웃을 효과적으로 비활성화합니다.

기다린 후 [`vkResetFence`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkResetFences.html) 호출을 통해 펜스를 수동으로 비신호 상태로 재설정해야 합니다:

```c
    vkResetFences(device, 1, &inFlightFence);

```

Before we can proceed, there is a slight hiccup in our design. On the first frame we call `drawFrame()`, which immediately waits on `inFlightFence` to be signaled. `inFlightFence` is only signaled after a frame has finished rendering, yet since this is the first frame, there are no previous frames in which to signal the fence! Thus `vkWaitForFences()` blocks indefinitely, waiting on something which will never happen.

Of the many solutions to this dilemma, there is a clever workaround built into the API. Create the fence in the signaled state, so that the first call to `vkWaitForFences()` returns immediately since the fence is already signaled.

진행하기 전에 디자인에 약간의 문제가 있습니다. 첫 번째 프레임에서는 `drawFrame()` 부르며, 이 프레임은 즉시 '`inFlightFence`'가 신호를 받기를 기다립니다. '`inFlightFence`'는 프레임 렌더링이 완료된 후에만 신호를 보내지만, 이 프레임이 첫 번째 프레임이기 때문에 펜스에 신호를 보낼 이전 프레임은 없습니다! 따라서 `vkWaitForFence()`는 무기한 차단되어 절대 일어나지 않을 일을 기다립니다.

이 딜레마에 대한 많은 해결책 중 하나는 API에 내장된 영리한 해결책이 있습니다. 

신호 된 상태로 fence를 다시 작성하여, fence가 이미 신호를 받았기 때문에 `vkWaitForFence()`에 대한 첫 번째 호출이 즉시 반환되도록 합니다.

To do this, we add the `VK_FENCE_CREATE_SIGNALED_BIT` flag to the [`VkFenceCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkFenceCreateInfo.html):

```c
void createSyncObjects() {
    ...

    VkFenceCreateInfo fenceInfo{};
    fenceInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
    fenceInfo.flags = VK_FENCE_CREATE_SIGNALED_BIT;

    ...
}

```

# Acquiring an image from the swap chain

The next thing we need to do in the `drawFrame` function is acquire an image from the swap chain. Recall that the swap chain is an extension feature, so we must use a function with the `vk*KHR` naming convention:

```c
void drawFrame() {
    uint32_t imageIndex;
    vkAcquireNextImageKHR(device, swapChain, UINT64_MAX, imageAvailableSemaphore, VK_NULL_HANDLE, &imageIndex);
}

```

`vkAcquireNextImageKHR`의 처음 두 매개변수는 논리 장치와 이미지를 획득하려는 스왑 체인입니다. 세 번째 매개변수는 이미지를 사용할 수 있는 시간 제한을 나노초 단위로 지정합니다. 64비트의 부호 없는 정수의 최대값을 사용하면 시간 제한을 효과적으로 비활성화할 수 있습니다.

다음 두 매개변수는 이미지를 사용하여 프레젠테이션 엔진이 완료되면 신호를 보낼 동기화 개체를 지정합니다. 이 시점에서 그림을 그리기 시작할 수 있습니다. semaphore, fence 또는 둘 다 지정할 수 있습니다. 이를 위해 여기서는 `imageAvailableSemaphore`를 사용하겠습니다.

마지막 매개변수는 사용 가능해진 스왑 체인 이미지의 인덱스를 출력할 변수를 지정합니다. 이 인덱스는 `swapChainImages` 배열에서 [`VkImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImage.html)를 참조합니다. 이 인덱스를 사용하여 [`VkFrameBuffer`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkFrameBuffer.html)를 선택합니다.

# Recording the command buffer

With the imageIndex specifying the swap chain image to use in hand, we can now record the command buffer. First, we call [`vkResetCommandBuffer`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkResetCommandBuffer.html) on the command buffer to make sure it is able to be recorded.

imageIndex에서 사용할 스왑 체인 이미지를 지정하면 이제 명령 버퍼를 기록할 수 있습니다. 먼저 명령 버퍼에서 `vkResetCommandBuffer`를 호출하여 기록할 수 있는지 확인합니다.

```c
vkResetCommandBuffer(commandBuffer, 0);
```

The second parameter of [`vkResetCommandBuffer`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkResetCommandBuffer.html) is a [`VkCommandBufferResetFlagBits`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkCommandBufferResetFlagBits.html) flag. Since we don't want to do anything special, we leave it as 0.

`vkResetCommandBuffer`의 두 번째 매개변수는 `VkCommandBufferResetFlagBits`플래그입니다. 특별한 작업을 하고 싶지 않으므로 0으로 설정합니다.

Now call the function `recordCommandBuffer` to record the commands we want.

```c
recordCommandBuffer(commandBuffer, imageIndex);
```

With a fully recorded command buffer, we can now submit it.

# Submitting the command buffer

Queue submission and synchronization is configured through parameters in the [`VkSubmitInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkSubmitInfo.html) structure.

```c
VkSubmitInfo submitInfo{};
submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;

VkSemaphore waitSemaphores[] = {imageAvailableSemaphore};
VkPipelineStageFlags waitStages[] = {VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT};
submitInfo.waitSemaphoreCount = 1;
submitInfo.pWaitSemaphores = waitSemaphores;
submitInfo.pWaitDstStageMask = waitStages;

```

처음 세 가지 매개변수는 실행이 시작되기 전에 대기할 semaphore와 파이프라인의 어느 단계에서 대기할지를 지정합니다. 

우리는 이미지가 사용 가능할 때까지 색상을 쓰고 대기하고 싶어서 색상 첨부 파일에 쓰는 그래픽 파이프라인의 단계를 지정하고 있습니다. 

즉, 이론적으로 이미지가 아직 사용 가능하지 않은 동안 구현은 이미 정점 셰이더 등을 실행하기 시작할 수 있습니다.

 `waitStage` 배열의 각 항목은 `pWaitSemaphores`에서 동일한 인덱스를 가진 semaphore에 해당합니다.

```c
submitInfo.commandBufferCount = 1;
submitInfo.pCommandBuffers = &commandBuffer;
```

The next two parameters specify which command buffers to actually submit for execution. We simply submit the single command buffer we have.

다음 두 매개변수는 실제로 실행을 위해 제출할 명령 버퍼를 지정합니다. 우리는 단순히 단일 명령 버퍼를 제출하기만 하면 됩니다.

```c
VkSemaphore signalSemaphores[] = {renderFinishedSemaphore};
submitInfo.signalSemaphoreCount = 1;
submitInfo.pSignalSemaphores = signalSemaphores;

```

The `signalSemaphoreCount` and `pSignalSemaphores` parameters specify which semaphores to signal once the command buffer(s) have finished execution. In our case we're using the `renderFinishedSemaphore` for that purpose.

`signalSemaphoreCount`및 `pSignalSemaphore` 매개변수는 명령 버퍼가 실행을 완료한 후 신호를 보낼 세마포어를 지정합니다. 우리의 경우, 이 목적을 위해 `renderFinishedSemaphore`를 사용하고 있습니다.

```c
if (vkQueueSubmit(graphicsQueue, 1, &submitInfo, inFlightFence) != VK_SUCCESS) {
    throw std::runtime_error("failed to submit draw command buffer!");
}

```

We can now submit the command buffer to the graphics queue using [`vkQueueSubmit`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkQueueSubmit.html). 

The function takes an array of [`VkSubmitInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkSubmitInfo.html) structures as argument for efficiency when the workload is much larger. 

The last parameter references an optional fence that will be signaled when the command buffers finish execution. 

This allows us to know when it is safe for the command buffer to be reused, thus we want to give it `inFlightFence`. 

Now on the next frame, the CPU will wait for this command buffer to finish executing before it records new commands into it.

이제 [`vkQueueSubmit`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkQueueSubmit.html)을 사용하여 명령 버퍼를 그래픽 큐에 제출할 수 있습니다.

이 함수는 작업 부하가 훨씬 클 때 효율성을 위해 여러 [`VkSubmitInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkSubmitInfo.html) 구조 배열을 인수로 사용합니다. 

마지막 매개변수는 명령 버퍼가 실행을 완료할 때 신호를 보낼 선택적 펜스를 참조합니다. 

이를 통해 명령 버퍼가 언제 재사용되는 것이 안전한지 알 수 있으므로 `inFlightFence`를 제공하고자 합니다. 

이제 다음 프레임에서 CPU는 이 명령 버퍼가 실행을 완료할 때까지 기다렸다가 새로운 명령을 기록합니다.

# Subpass dependencies

렌더 패스의 서브패스는 이미지 레이아웃 전환을 자동으로 처리한다는 점을 기억하세요. 이러한 전환은 서브패스 간의 메모리 및 실행 종속성을 지정하는 *subpass dependencies*에 의해 제어됩니다. 현재 서브패스는 하나뿐이지만, 이 서브패스 직전과 직후의 작업도 암묵적인 'subpasses'로 간주됩니다.

렌더 패스가 시작될 때와 끝날 때 transition를 처리하는 두 가지 기본 종속성이 있지만, 전자는 적절한 시간 때에 발생하지 않습니다. 

이는 파이프라인이 시작될 때 transition가 발생한다고 가정하지만, 그 시점에서 아직 이미지를 획득하지 못했습니다! 이 문제를 해결하는 두 가지 방법이 있습니다. 

이미지 `AvailableSemapore`의 `waitStage`를 `VK_PIPELINE_STE_TOP_OF_PIPE_BIT`로 변경하여 이미지가 사용 가능할 때까지 렌더 패스가 시작되지 않도록 하거나, 

렌더 패스가 `VK_PIPLINE_STE_COLOR_ATCH_ATCH_OUT_BIT`단계를 기다리도록 할 수 있습니다. 서브패스 종속성과 작동 방식을 살펴보는 것이 좋은 핑계이기 때문에 여기서 두 번째 옵션을 선택했습니다.

Subpass dependencies are specified in [`VkSubpassDependency`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkSubpassDependency.html) structs. Go to the `createRenderPass` function and add one:

```c
VkSubpassDependency dependency{};
dependency.srcSubpass = VK_SUBPASS_EXTERNAL;
dependency.dstSubpass = 0;
```

The first two fields specify the indices of the dependency and the dependent subpass.

The special value `VK_SUBPASS_EXTERNAL` refers to the implicit subpass before or after the render pass depending on whether it is specified in `srcSubpass` or `dstSubpass`.

The index `0` refers to our subpass, which is the first and only one. The `dstSubpass` must always be higher than `srcSubpass` to prevent cycles in the dependency graph (unless one of the subpasses is `VK_SUBPASS_EXTERNAL`).

처음 두 필드는 종속성 및 종속 하위 패스의 인덱스를 지정합니다.

`VK_SUBSPASS_EXTERNAL`은 `srcSubpass` 또는 `dstSubpass`에 지정되어 있는 지에 따라 렌더링 패스 전후의 **암시적 서브패스**를 의미합니다. 

인덱스 `0`은 첫 번째이자 유일한 서브패스인 자신의 서브패스를 의미합니다. 

종속성 그래프에서 사이클을 방지하려면 `dstSubpass`가 항상 `srcSubpass`보다 높아야 합니다(서브패스 중 하나가 `VK_SUBSPASS_EXTAL`이 아닌 경우).

```c
dependency.srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
dependency.srcAccessMask = 0;
```

The next two fields specify the operations to wait on and the stages in which these operations occur. We need to wait for the swap chain to finish reading from the image before we can access it. This can be accomplished by waiting on the color attachment output stage itself.

다음 두 필드에는 **대기할 작업**과 **이러한 작업이 발생하는 단계**가 지정되어 있습니다. 

스왑 체인이 이미지에서 읽기를 완료할 때까지 기다려야 액세스할 수 있습니다.

이는 색상 첨부 출력 단계 자체에서 대기하면 달성할 수 있습니다.

```c
dependency.dstStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
dependency.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
```

The operations that should wait on this are in the color attachment stage and involve the writing of the color attachment. These settings will prevent the transition from happening until it's actually necessary (and allowed): when we want to start writing colors to it.

이 작업을 기다려야 하는 것은 **색상 첨부 단계**에 있으며 **색상 첨부를 작성**하는 것을 포함합니다.

이러한 설정은 실제로 필요할 때(그리고 허용될 때)까지 전환이 이루어지지 않도록 방지합니다: 색상을 작성하기 시작할 때입니다.

```c
renderPassInfo.dependencyCount = 1;
renderPassInfo.pDependencies = &dependency;
```

The [`VkRenderPassCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkRenderPassCreateInfo.html) struct has two fields to specify an array of dependencies.

# Presentation

The last step of drawing a frame is submitting the result back to the swap chain to have it eventually show up on the screen. Presentation is configured through a `VkPresentInfoKHR` structure at the end of the `drawFrame` function.

```c
VkPresentInfoKHR presentInfo{};
presentInfo.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;

presentInfo.waitSemaphoreCount = 1;
presentInfo.pWaitSemaphores = signalSemaphores;

```

The first two parameters specify which semaphores to wait on before presentation can happen, just like [`VkSubmitInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkSubmitInfo.html). Since we want to wait on the command buffer to finish execution, thus our triangle being drawn, we take the semaphores which will be signalled and wait on them, thus we use `signalSemaphores`.

처음 두 매개변수는 [`VkSubmitInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkSubmitInfo.html)와 마찬가지로 프레젠테이션이 실행되기 전에 대기할 세마포어를 지정합니다. 명령어 버퍼가 실행을 완료할 때까지 기다렸다가 삼각형이 그려지기 때문에 신호를 보낼 세마포어를 가져와서 신호 세마포어를 대기하므로 `signalSemaphores`를 사용합니다.

```c
VkSwapchainKHR swapChains[] = {swapChain};
presentInfo.swapchainCount = 1;
presentInfo.pSwapchains = swapChains;
presentInfo.pImageIndices = &imageIndex;

```

The next two parameters specify the swap chains to present images to and the index of the image for each swap chain. This will almost always be a single one.

```c
presentInfo.pResults = nullptr; // Optional
```

There is one last optional parameter called `pResults`. It allows you to specify an array of [`VkResult`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkResult.html) values to check for every individual swap chain if presentation was successful. It's not necessary if you're only using a single swap chain, because you can simply use the return value of the present function.

마지막으로 `pResults`라는 옵션 매개변수가 하나 있습니다. 프레젠테이션이 성공했는지 여부를 확인하기 위해 [`VkResult`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkResult.html) 값의 배열을 지정할 수 있습니다. 단일 스왑 체인만 사용하는 경우 현재 함수의 반환 값을 간단히 사용할 수 있으므로 필요하지 않습니다.

```c
vkQueuePresentKHR(presentQueue, &presentInfo);
```

The `vkQueuePresentKHR` function submits the request to present an image to the swap chain. We'll add error handling for both `vkAcquireNextImageKHR` and `vkQueuePresentKHR` in the next chapter, because their failure does not necessarily mean that the program should terminate, unlike the functions we've seen so far.

If you did everything correctly up to this point, then you should now see something resembling the following when you run your program:

`vkQueuePresentKHR` 함수는 스왑 체인에 이미지를 제시하라는 요청을 제출합니다. `vkAcquireNextImageKHR`와`vkQuePresentKHR`의 오류 처리는 지금까지 살펴본 기능과 달리 프로그램이 반드시 종료되어야 하는 것은 아니기 때문에 다음 장에서 추가하겠습니다.

지금까지 모든 것을 올바르게 수행했다면, 이제 프로그램을 실행할 때 다음과 같은 것을 볼 수 있을 것입니다:

![](attachments/triangle.png)

> This colored triangle may look a bit different from the one you're used to seeing in graphics tutorials. That's because this tutorial lets the shader interpolate in linear color space and converts to sRGB color space afterwards. See this blog post for a discussion of the difference.
> 

Yay! Unfortunately, you'll see that when validation layers are enabled, the program crashes as soon as you close it. The messages printed to the terminal from `debugCallback` tell us why:

![](attachments/semaphore_in_use.png)

Remember that all of the operations in `drawFrame` are asynchronous. That means that when we exit the loop in `mainLoop`, drawing and presentation operations may still be going on. Cleaning up resources while that is happening is a bad idea.

To fix that problem, we should wait for the logical device to finish operations before exiting `mainLoop` and destroying the window:

안타깝게도 검증 레이어를 활성화하면 프로그램을 닫자마자 프로그램이 충돌하는 것을 볼 수 있습니다. debugCallback에서 터미널로 출력된 메시지가 그 이유를 알려줍니다:

`drawFrame`의 모든 작업이 비동기식이라는 점을 기억하세요. 즉, '메인루프'에서 루프를 종료할 때에도 그리기 및 프레젠테이션 작업이 계속 진행 중일 수 있습니다. 그런 일이 발생하는 동안 리소스를 정리하는 것은 나쁜 생각입니다.

이 문제를 해결하려면 논리 장치가 작업을 완료할 때까지 기다렸다가 '메인루프'를 종료하고 창을 파괴해야 합니다:

```c
void mainLoop() {
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();
        drawFrame();
    }

    vkDeviceWaitIdle(device);
}

```

You can also wait for operations in a specific command queue to be finished with [`vkQueueWaitIdle`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkQueueWaitIdle.html). These functions can be used as a very rudimentary way to perform synchronization. You'll see that the program now exits without problems when closing the window.

특정 명령 대기열에서 `vkQueueWaitIdle`로 작업이 완료될 때까지 기다릴 수도 있습니다. 이러한 기능은 동기화를 수행하는 매우 기본적인 방법으로 사용할 수 있습니다. 이제 창을 닫을 때 프로그램이 문제 없이 종료되는 것을 볼 수 있습니다.

# Conclusion

A little over 900 lines of code later, we've finally gotten to the stage of seeing something pop up on the screen! Bootstrapping a Vulkan program is definitely a lot of work, but the take-away message is that Vulkan gives you an immense amount of control through its explicitness. I recommend you to take some time now to reread the code and build a mental model of the purpose of all of the Vulkan objects in the program and how they relate to each other. We'll be building on top of that knowledge to extend the functionality of the program from this point on.

The next chapter will expand the render loop to handle multiple frames in flight.

## ++ **Gemini 2.0 Pro Experimental 02-05 결과 ++**

Vulkan Render Pass에서 Subpass Dependencies는 렌더링 과정의 핵심 요소인 subpass들 간의 실행 순서와 동기화를 제어하는 메커니즘입니다. 이를 통해 렌더링 파이프라인을 최적화하고, 불필요한 동기화 오버헤드를 줄이며, 데이터의 정확성을 보장할 수 있습니다.

**Subpass Dependency의 역할:**

1. **실행 순서 보장:** Subpass들은 정의된 순서대로 실행되어야 합니다. 예를 들어, 지오메트리 패스(geometry pass)에서 G-buffer를 생성하고, 라이팅 패스(lighting pass)에서 G-buffer를 읽어 조명을 계산하는 deferred rendering에서, 라이팅 패스는 반드시 지오메트리 패스 *이후에* 실행되어야 합니다. Subpass Dependency는 이러한 실행 순서를 명시적으로 정의합니다.
2. **동기화 (Synchronization):** Subpass 간에 데이터가 공유되는 경우 (예: 이전 subpass의 출력을 다음 subpass의 입력으로 사용), 데이터가 올바르게 생성되고 접근될 수 있도록 동기화가 필요합니다. Subpass Dependency는 이러한 동기화를 자동으로 처리합니다. 개발자가 명시적으로 semaphore나 barrier를 사용하지 않아도 됩니다.
3. **메모리 접근 제어:** Subpass Dependency는 어떤 subpass가 어떤 리소스(attachments)에 어떤 방식으로 접근하는지(읽기, 쓰기)를 지정합니다. 이를 통해 메모리 접근 충돌을 방지하고 데이터 일관성을 유지합니다.
4. **레이아웃 전환 (Layout Transitions):** Subpass Dependency는 attachment의 이미지 레이아웃 전환을 자동으로 처리합니다. 예를 들어, 컬러 버퍼로 사용되던 이미지가 다음 subpass에서 셰이더의 입력으로 사용될 때, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL에서 VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL로 자동으로 전환됩니다.

**Subpass Dependency 정의:**

VkSubpassDependency 구조체를 사용하여 Subpass Dependency를 정의합니다.

```cpp
typedef struct VkSubpassDependency {
    uint32_t    srcSubpass;
    uint32_t    dstSubpass;
    VkPipelineStageFlags    srcStageMask;
    VkPipelineStageFlags    dstStageMask;
    VkAccessFlags           srcAccessMask;
    VkAccessFlags           dstAccessMask;
    VkDependencyFlags       dependencyFlags;
} VkSubpassDependency;
```

content_copy  download  Use code [with caution](https://support.google.com/legal/answer/13505487).C++

- **srcSubpass:** 의존성의 소스 subpass 인덱스. 이 subpass의 작업이 완료되어야 dstSubpass가 시작될 수 있습니다. 특수 값 VK_SUBPASS_EXTERNAL은 Render Pass 외부(이전 Render Pass 또는 다른 작업)를 나타냅니다.
- **dstSubpass:** 의존성의 대상 subpass 인덱스. srcSubpass의 작업이 완료될 때까지 이 subpass는 시작되지 않습니다. 특수 값 VK_SUBPASS_EXTERNAL은 Render Pass 외부(다음 Render Pass 또는 다른 작업)를 나타냅니다.
- **srcStageMask:** srcSubpass에서 어떤 파이프라인 단계(pipeline stages)가 완료되어야 하는지를 나타내는 플래그 (예: VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT).
- **dstStageMask:** dstSubpass에서 어떤 파이프라인 단계가 srcSubpass의 완료를 기다려야 하는지를 나타내는 플래그.
- **srcAccessMask:** srcSubpass에서 리소스에 어떤 방식으로 접근하는지를 나타내는 플래그 (예: VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, VK_ACCESS_SHADER_READ_BIT).
- **dstAccessMask:** dstSubpass에서 리소스에 어떤 방식으로 접근하는지를 나타내는 플래그.
- **dependencyFlags:** 추가적인 의존성 플래그 (예: VK_DEPENDENCY_BY_REGION_BIT - 영역별 동기화).

**Subpass Dependency 예시 (Deferred Rendering):**

Deferred Rendering에서 지오메트리 패스(G-buffer 생성)와 라이팅 패스(G-buffer 사용) 간의 Subpass Dependency는 다음과 같이 설정할 수 있습니다.

```cpp
VkSubpassDependency dependency = {};
dependency.srcSubpass = 0; // Geometry Pass (Subpass 0)
dependency.dstSubpass = 1; // Lighting Pass (Subpass 1)
dependency.srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT; // Geometry Pass에서 컬러 버퍼 출력 완료
dependency.dstStageMask = VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT; // Lighting Pass에서 프래그먼트 셰이더 실행 전에
dependency.srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT; // Geometry Pass에서 컬러 버퍼 쓰기
dependency.dstAccessMask = VK_ACCESS_SHADER_READ_BIT; // Lighting Pass에서 셰이더 읽기 (input attachment)
dependency.dependencyFlags = 0;
```

content_copy  download  Use code [with caution](https://support.google.com/legal/answer/13505487).C++

**VK_SUBPASS_EXTERNAL 사용 예시:**

- **Render Pass 시작:** srcSubpass = VK_SUBPASS_EXTERNAL, dstSubpass = 0 (첫 번째 subpass)
    - Render Pass 외부(예: 이전 Render Pass, 이미지 획득)에서 첫 번째 subpass로의 의존성을 나타냅니다.
    - 주로 이미지 레이아웃 전환에 사용됩니다. (예: VK_IMAGE_LAYOUT_PRESENT_SRC_KHR → VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
- **Render Pass 종료:** srcSubpass = (마지막 subpass 인덱스), dstSubpass = VK_SUBPASS_EXTERNAL
    - 마지막 subpass에서 Render Pass 외부(예: 다음 Render Pass, 이미지 프레젠테이션)로의 의존성을 나타냅니다.
    - 주로 이미지 레이아웃 전환에 사용됩니다. (예: VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL → VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)

**Subpass Dependencies 설정 위치:**

VkRenderPassCreateInfo 구조체의 dependencyCount 및 pDependencies 멤버를 사용하여 Render Pass 생성 시 Subpass Dependencies를 설정합니다.

```cpp
      VkRenderPassCreateInfo renderPassInfo = {
    // ... (attachments, subpasses 설정)
    .dependencyCount = 1, // 의존성 개수
    .pDependencies = &dependency // VkSubpassDependency 배열
};

vkCreateRenderPass(device, &renderPassInfo, nullptr, &renderPass);
```

content_copy  download  Use code [with caution](https://support.google.com/legal/answer/13505487).C++

**핵심 정리:**

- Subpass Dependencies는 Render Pass 내 subpass 간의 실행 순서, 동기화, 메모리 접근, 레이아웃 전환을 제어합니다.
- VkSubpassDependency 구조체를 사용하여 의존성을 정의합니다.
- srcSubpass, dstSubpass, srcStageMask, dstStageMask, srcAccessMask, dstAccessMask를 사용하여 의존성의 세부 사항을 지정합니다.
- VK_SUBPASS_EXTERNAL을 사용하여 Render Pass 외부와의 의존성을 표현할 수 있습니다.
- Render Pass 생성 시 VkRenderPassCreateInfo를 통해 Subpass Dependencies를 설정합니다.

Subpass Dependencies는 Vulkan Render Pass의 핵심 기능 중 하나이며, 렌더링 파이프라인을 효율적으로 구성하고 최적화하는 데 필수적입니다. 처음에는 복잡해 보일 수 있지만, 각 멤버의 의미를 이해하고 예제를 통해 연습하면 Vulkan 렌더링의 강력함을 활용할 수 있습니다.