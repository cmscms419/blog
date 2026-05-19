# Frames in flight

현재 렌더 루프에는 한 가지 눈에 띄는 결함이 있습니다. 다음 프레임 렌더링을 시작하기 전에 이전 프레임이 완료될 때까지 기다려야 하므로 호스트가 불필요하게 유휴 상태가 됩니다.

이 문제를 해결하는 방법은 한 번에 여러 프레임을 *in-flight(프레임으로 부터 자유롭다?)*할 수 있도록 허용하는 것입니다. 

즉, 한 프레임의 렌더링이 다음 프레임의 recording을 방해하지 않도록 허용하는 것입니다.

렌더링 중에 액세스하고 수정하는 모든 리소스는 복제되어야 합니다. 

따라서 여러 개의 `command buffers, semaphores, fences`가 필요합니다. 이후 챕터에서는 다른 리소스의 여러 인스턴스도 추가할 예정이므로 이 개념이 다시 등장할 것입니다.

프로그램 상단에 동시에 처리할 프레임 수를 정의하는 상수를 추가하는 것으로 시작하세요:

```c
const int MAX_FRAMES_IN_FLIGHT = 2;
```

2를 선택한 이유는 CPU가 GPU보다 *너무* 앞서지 않기를 원하기 때문입니다. 

2프레임을 사용하면 CPU와 GPU가 동시에 각자의 작업을 수행할 수 있습니다. CPU가 일찍 완료되면 GPU가 렌더링을 완료할 때까지 기다렸다가 더 많은 작업을 제출합니다. 

3프레임 이상 진행 중이면 CPU가 GPU보다 지연 시간이 추가될 수 있습니다. 

일반적으로 추가적인 지연 시간은 바람직하지 않습니다. 그러나 애플리케이션이 in flight 중인 프레임 수를 제어할 수 있도록 하는 것은 vulkan이 명시적인 또 다른 예입니다.

각 프레임에는  own command buffer, set of semaphores, and fence가 있어야 합니다. 이름을 바꾼 다음 객체의 `std::vector`로 변경합니다:

```c
std::vector<VkCommandBuffer> commandBuffers;

...

std::vector<VkSemaphore> imageAvailableSemaphores;
std::vector<VkSemaphore> renderFinishedSemaphores;
std::vector<VkFence> inFlightFences;
```

그런 다음 여러 개의 명령 버퍼를 만들어야 합니다. `createCommandBuffer`의 이름을 `createCommandBuffers`로 변경합니다. 다음으로 명령 버퍼 벡터의 크기를 `MAX_FRAMES_IN_FLIGHT` 크기로 조정하고, 해당 수의 명령 버퍼를 포함하도록 `VkCommandBufferAllocateInfo`를 변경한 다음, 대상을 명령 버퍼 벡터로 변경해야 합니다:

```c
void createCommandBuffers() {
    commandBuffers.resize(MAX_FRAMES_IN_FLIGHT);
    ...
    allocInfo.commandBufferCount = (uint32_t) commandBuffers.size();

    if (vkAllocateCommandBuffers(device, &allocInfo, commandBuffers.data()) != VK_SUCCESS) {
        throw std::runtime_error("failed to allocate command buffers!");
    }
}
```

The `createSyncObjects` function should be changed to create all of the objects:

```c
void createSyncObjects() {
    imageAvailableSemaphores.resize(MAX_FRAMES_IN_FLIGHT);
    renderFinishedSemaphores.resize(MAX_FRAMES_IN_FLIGHT);
    inFlightFences.resize(MAX_FRAMES_IN_FLIGHT);

    VkSemaphoreCreateInfo semaphoreInfo{};
    semaphoreInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;

    VkFenceCreateInfo fenceInfo{};
    fenceInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
    fenceInfo.flags = VK_FENCE_CREATE_SIGNALED_BIT;

    for (size_t i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
        if (vkCreateSemaphore(device, &semaphoreInfo, nullptr, &imageAvailableSemaphores[i]) != VK_SUCCESS ||
            vkCreateSemaphore(device, &semaphoreInfo, nullptr, &renderFinishedSemaphores[i]) != VK_SUCCESS ||
            vkCreateFence(device, &fenceInfo, nullptr, &inFlightFences[i]) != VK_SUCCESS) {

            throw std::runtime_error("failed to create synchronization objects for a frame!");
        }
    }
}
```

Similarly, they should also all be cleaned up:

```c
void cleanup() {
    for (size_t i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
        vkDestroySemaphore(device, renderFinishedSemaphores[i], nullptr);
        vkDestroySemaphore(device, imageAvailableSemaphores[i], nullptr);
        vkDestroyFence(device, inFlightFences[i], nullptr);
    }

    ...
}
```

Remember, because command buffers are freed for us when we free the command pool, there is nothing extra to do for command buffer cleanup.

명령어 풀을 해제하면 명령어 버퍼가 해제되므로 명령어 버퍼 정리를 위해 추가로 수행할 작업이 없다는 점을 기억하세요.

To use the right objects every frame, we need to keep track of the current frame. We will use a frame index for that purpose:

매 프레임마다 올바른 오브젝트를 사용하려면 현재 프레임을 추적해야 합니다. 이를 위해 프레임 인덱스를 사용합니다:

```c
uint32_t currentFrame = 0;
```

The `drawFrame` function can now be modified to use the right objects:

```c
void drawFrame() {
    vkWaitForFences(device, 1, &inFlightFences[currentFrame], VK_TRUE, UINT64_MAX);
    vkResetFences(device, 1, &inFlightFences[currentFrame]);

    vkAcquireNextImageKHR(device, swapChain, UINT64_MAX, imageAvailableSemaphores[currentFrame], VK_NULL_HANDLE, &imageIndex);

    ...

    vkResetCommandBuffer(commandBuffers[currentFrame],  0);
    recordCommandBuffer(commandBuffers[currentFrame], imageIndex);

    ...

    submitInfo.pCommandBuffers = &commandBuffers[currentFrame];

    ...

    VkSemaphore waitSemaphores[] = {imageAvailableSemaphores[currentFrame]};

    ...

    VkSemaphore signalSemaphores[] = {renderFinishedSemaphores[currentFrame]};

    ...

    if (vkQueueSubmit(graphicsQueue, 1, &submitInfo, inFlightFences[currentFrame]) != VK_SUCCESS) {
}
```

Of course, we shouldn’t forget to advance to the next frame every time:

```c
void drawFrame() {
    ...

    currentFrame = (currentFrame + 1) % MAX_FRAMES_IN_FLIGHT;
}
```

By using the modulo (%) operator, we ensure that the frame index loops around after every `MAX_FRAMES_IN_FLIGHT` enqueued frames.

We’ve now implemented all the needed synchronization to ensure that there are no more than `MAX_FRAMES_IN_FLIGHT` frames of work enqueued and that these frames are not stepping over eachother. Note that it is fine for other parts of the code, like the final cleanup, to rely on more rough synchronization like `vkDeviceWaitIdle`. You should decide on which approach to use based on performance requirements.

To learn more about synchronization through examples, have a look at [this extensive overview](https://github.com/KhronosGroup/Vulkan-Docs/wiki/Synchronization-Examples#swapchain-image-acquire-and-present) by Khronos.

In the [next chapter](https://docs.vulkan.org/tutorial/latest/03_Drawing_a_triangle/04_Swap_chain_recreation.html) we’ll deal with one more small thing that is required for a well-behaved Vulkan program.

modulo (%) 연산자를 사용하여 `MAX_FRAMES_IN_FLIGHT` 대기열에 있는 모든 프레임 뒤에 프레임 인덱스가 반복되도록 합니다.

이제 필요한 모든 동기화를 구현하여 대기열에 `MAX_FRAMES_IN_FLIGHT` 작업 프레임이 초과되지 않도록 하고 이러한 프레임이 서로 겹치지 않도록 했습니다. 최종 정리와 같은 코드의 다른 부분에서는 `vkDeviceWaitIdle`과 같은 보다 대략적인 동기화에 의존해도 괜찮다는 점에 유의하세요. 성능 요구 사항에 따라 어떤 접근 방식을 사용할지 결정해야 합니다.

예제를 통해 동기화에 대해 자세히 알아보려면 크로노스의 [이 광범위한 개요](https://github.com/KhronosGroup/Vulkan-Docs/wiki/Synchronization-Examples#swapchain-image-acquire-and-present)를 참조하세요.

[다음 장](https://docs.vulkan.org/tutorial/latest/03_Drawing_a_triangle/04_Swap_chain_recreation.html)에서는 잘 동작하는 Vulkan 프로그램을 위해 필요한 작은 사항을 하나 더 다루겠습니다.