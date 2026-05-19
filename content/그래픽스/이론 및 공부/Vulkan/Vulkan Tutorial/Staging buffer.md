# Staging buffer

# Introduction

현재 버텍스 버퍼는 올바르게 작동하지만 CPU에서 액세스할 수 있는 메모리 유형이 그래픽 카드 자체에서 읽기에 가장 적합한 메모리 유형이 아닐 수 있습니다.

가장 최적의 메모리는 `VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT` 플래그를 가지며 일반적으로 전용 그래픽 카드의 CPU가 액세스할 수 없습니다.

이 장에서는 두 개의 버텍스 버퍼를 만들겠습니다.

버텍스 배열에서 데이터를 업로드할 CPU 액세스 가능 메모리의 *staging buffer*  1개와 디바이스 로컬 메모리의 최종 버텍스 버퍼 1개가 있습니다. 그런 다음 버퍼 복사 명령을 사용하여 staging buffer에서 실제 버텍스 버퍼로 데이터를 이동합니다.

# Transfer queue

버퍼 복사 명령에는 전송 작업을 지원하는 queue family 가 필요하며, 이 패밀리는 `VK_QUEUE_TRANSFER_BIT`을 사용하여 표시됩니다.

좋은 소식은 `VK_QUEUE_GRAPHICS_BIT` 또는 `VK_QUEUE_COMPUTE_BIT` 기능이 있는 queue family 는 이미 암시적으로 `VK_QUEUE_TRANSFER_BIT` 작업을 지원한다는 점입니다. 이러한 경우 구현에서 `queueFlags`에 명시적으로 나열할 필요는 없습니다.

도전하고 싶다면 전송 작업에 특별히 다른 대기열 제품군을 사용해 볼 수도 있습니다. 이 경우 프로그램을 다음과 같이 수정해야 합니다:

- `QueueFamilyIndices`와 `findQueueFamilies`를 수정하여 `VK_QUEUE_TRANSFER_BIT` 비트가 있는 queue family를 명시적으로 찾되, `VK_QUEUE_GRAPHICS_BIT`가 없는 큐 패밀리를 찾습니다.
- 전송 대기열에 핸들을 요청하도록 `createLogicalDevice`를 수정합니다.
- 전송 queue family에서 제출되는 command buffers에 대한 두 번째 command pool 을 만듭니다.
- Change the `sharingMode` of resources to be `VK_SHARING_MODE_CONCURRENT` and specify both the graphics and transfer queue families
- 리소스의 공유 모드를 `VK_SHARING_MODE_CONCURRENT`로 변경하고 그래픽 및 전송 대기열 제품군을 모두 지정합니다.
- 이 장에서 사용할 [`vkCmdCopyBuffer`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdCopyBuffer.html)와 같은 전송 명령은 graphics queue 대신 transfer queue에 제출합니다.

It's a bit of work, but it'll teach you a lot about how resources are shared between queue families.

# Abstracting buffer creation

이 장에서는 여러 개의 버퍼를 생성할 예정이므로 버퍼 생성을 도우미 함수로 옮기는 것이 좋습니다. `createBuffer` 함수를 새로 생성하고 `createVertexBuffer`의 코드(매핑 제외)를 이 함수로 옮깁니다.

```c
void createBuffer(VkDeviceSize size, VkBufferUsageFlags usage, VkMemoryPropertyFlags properties, VkBuffer& buffer, VkDeviceMemory& bufferMemory) {
    VkBufferCreateInfo bufferInfo{};
    bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bufferInfo.size = size;
    bufferInfo.usage = usage;
    bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

    if (vkCreateBuffer(device, &bufferInfo, nullptr, &buffer) != VK_SUCCESS) {
        throw std::runtime_error("failed to create buffer!");
    }

    VkMemoryRequirements memRequirements;
    vkGetBufferMemoryRequirements(device, buffer, &memRequirements);

    VkMemoryAllocateInfo allocInfo{};
    allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    allocInfo.allocationSize = memRequirements.size;
    allocInfo.memoryTypeIndex = findMemoryType(memRequirements.memoryTypeBits, properties);

    if (vkAllocateMemory(device, &allocInfo, nullptr, &bufferMemory) != VK_SUCCESS) {
        throw std::runtime_error("failed to allocate buffer memory!");
    }

    vkBindBufferMemory(device, buffer, bufferMemory, 0);
}

```

다양한 유형의 버퍼를 만들 수 있도록 필요한 것이 있다.

- 버퍼 크기
- 메모리 속성 및 사용량 대한 매개 변수

이 함수를 사용하여 다양한 유형의 버퍼를 만들 수 있도록 버퍼 크기, 메모리 속성 및 사용량에 대한 매개 변수를 추가해야 합니다. 

마지막 두 매개변수는 핸들을 쓸 출력 변수입니다.

**You can now remove the buffer creation and memory allocation code from `createVertexBuffer` and just call `createBuffer` instead:**

```c
void createVertexBuffer() {
    VkDeviceSize bufferSize = sizeof(vertices[0]) * vertices.size();
    createBuffer(bufferSize, VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, vertexBuffer, vertexBufferMemory);

    void* data;
    vkMapMemory(device, vertexBufferMemory, 0, bufferSize, 0, &data);
        memcpy(data, vertices.data(), (size_t) bufferSize);
    vkUnmapMemory(device, vertexBufferMemory);
}

```

Run your program to make sure that the vertex buffer still works properly.

# Using a staging buffer

이제 호스트 가시 버퍼만 임시 버퍼로 사용하고 디바이스 로컬 버퍼를 실제 버텍스 버퍼로 사용하도록 `createVertexBuffer`를 변경하겠습니다.

```c
void createVertexBuffer() {
    VkDeviceSize bufferSize = sizeof(vertices[0]) * vertices.size();

    VkBuffer stagingBuffer;
    VkDeviceMemory stagingBufferMemory;
    createBuffer(bufferSize, VK_BUFFER_USAGE_TRANSFER_SRC_BIT, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, stagingBuffer, stagingBufferMemory);

    void* data;
    vkMapMemory(device, stagingBufferMemory, 0, bufferSize, 0, &data);
        memcpy(data, vertices.data(), (size_t) bufferSize);
    vkUnmapMemory(device, stagingBufferMemory);

    createBuffer(bufferSize, VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, vertexBuffer, vertexBufferMemory);
}

```

이제 버텍스 데이터를 매핑하고 복사하기 위해 새로운 `stagingBuffer`를 `stagingBufferMemory`와 함께 사용하고 있습니다. 이 장에서는 두 가지 새로운 버퍼 사용 플래그를 사용하겠습니다:

- `VK_BUFFER_USAGE_TRANSFER_SRC_BIT`: 메모리 전송 작업에서 버퍼를 source로 사용할 수 있습니다.
- `VK_BUFFER_USAGE_TRANSFER_DST_BIT`: 메모리 전송 작업에서 버퍼를 destination(전송 받는 대상)으로 사용할 수 있습니다.

이 버텍스버퍼는 이제 device local 메모리 유형에서 할당되며, 이는 일반적으로 [`vkMapMemory`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkMapMemory.html)를 사용할 수 없음을 의미합니다.

그러나 `stagingBuffer`에서 `vertexBuffer`로 데이터를 복사할 수 있습니다. 

buffer usage flag와 함께 `stagingBuffer`의 전송 소스 플래그와 `vertexBuffer` 의 전송 대상 플래그를 지정하여 이를 수행하겠다는 의사를 표시해야 합니다.

이제 한 버퍼에서 다른 버퍼로 내용을 복사하는 `copyBuffer`함수를 작성해 보겠습니다.

```c
void copyBuffer(VkBuffer srcBuffer, VkBuffer dstBuffer, VkDeviceSize size) {

}

```

메모리 전송 작업은 그리기 명령과 마찬가지로 명령 버퍼를 사용하여 실행됩니다. 

따라서 먼저 임시 명령 버퍼를 할당해야 합니다. 

이러한 종류의 수명이 짧은 버퍼를 위해 별도의 명령 풀을 만들면 구현에서 메모리 할당 최적화를 적용할 수 있습니다. 이 경우 명령 풀을 생성하는 동안 `VK_COMMAND_POOL_CREATE_TRANSIENT_BIT`플래그를 사용해야 합니다.

```c
void copyBuffer(VkBuffer srcBuffer, VkBuffer dstBuffer, VkDeviceSize size) {
    VkCommandBufferAllocateInfo allocInfo{};
    allocInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    allocInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    allocInfo.commandPool = commandPool;
    allocInfo.commandBufferCount = 1;

    VkCommandBuffer commandBuffer;
    vkAllocateCommandBuffers(device, &allocInfo, &commandBuffer);
}

```

그리고 즉시 명령 버퍼 기록을 시작하세요:

```c
VkCommandBufferBeginInfo beginInfo{};
beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
beginInfo.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;

vkBeginCommandBuffer(commandBuffer, &beginInfo);
```

명령 버퍼를 한 번만 사용합니다.

복사 작업 실행이 완료될 때까지 함수에서 돌아올 때까지 기다리겠습니다. `VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT`를 사용하여 드라이버에게 우리의 의도를 알리는 것이 좋습니다.

```c
VkBufferCopy copyRegion{};
copyRegion.srcOffset = 0; // Optional
copyRegion.dstOffset = 0; // Optional
copyRegion.size = size;
vkCmdCopyBuffer(commandBuffer, srcBuffer, dstBuffer, 1, &copyRegion);

```

Contents of buffers are transferred using the [`vkCmdCopyBuffer`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdCopyBuffer.html) command. It takes the source and destination buffers as arguments, and an array of regions to copy. The regions are defined in [`VkBufferCopy`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkBufferCopy.html) structs and consist of a source buffer offset, destination buffer offset and size. It is not possible to specify `VK_WHOLE_SIZE` here, unlike the [`vkMapMemory`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkMapMemory.html) command.

버퍼의 내용은 [`vkCmdCopyBuffer`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdCopyBuffer.html) 명령을 사용하여 전송합니다. 이 명령은 소스 및 대상 버퍼와 복사할 영역 배열을 인수로 받습니다. 

영역은 소스 버퍼 오프셋, 대상 버퍼 오프셋 및 크기로 구성된 [`VkBufferCopy`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkBufferCopy.html) structs에 정의됩니다. [`vkMapMemory`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkMapMemory.html) 명령과 달리 여기에서는 `VK_WHOLE_SIZE`를 지정할 수 없습니다.

```c
vkEndCommandBuffer(commandBuffer);
```

이 명령 버퍼에는 복사 명령만 포함되어 있으므로 그 직후에 녹화를 중지할 수 있습니다. 이제 명령 버퍼를 실행하여 전송을 완료합니다:

```c
VkSubmitInfo submitInfo{};
submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
submitInfo.commandBufferCount = 1;
submitInfo.pCommandBuffers = &commandBuffer;

vkQueueSubmit(graphicsQueue, 1, &submitInfo, VK_NULL_HANDLE);
vkQueueWaitIdle(graphicsQueue);

```

그리기 명령과 달리 이번에는 기다릴 필요가 있는 이벤트가 없습니다. 버퍼에서 즉시 전송을 실행하기만 하면 됩니다.

이 전송이 완료될 때까지 기다릴 수 있는 방법은 다시 두 가지가 있습니다. 

- fence 를 사용하여 [`vkWaitForFences`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkWaitForFences.html)로 기다릴 수 있습니다.
- 간단하게 [`vkQueueWaitIdle`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkQueueWaitIdle.html)로 transfer queue이 유휴 상태가 될 때까지 기다릴 수 있습니다.

fence를 사용하면 한 번에 하나씩 실행하는 대신 multiple transfers simultaneously (여러 전송을 동시에) 예약하고 모든 전송이 완료될 때까지 기다릴 수 있습니다.

That may give the driver more opportunities to optimize.

```c
vkFreeCommandBuffers(device, commandPool, 1, &commandBuffer);

```

전송 작업에 사용된 명령 버퍼를 정리하는 것을 잊지 마세요.

이제 `createVertexBuffer` 함수에서 `copyBuffer`를 호출하여 버텍스 데이터를 device local buffer로 옮길 수 있습니다:

```c
createBuffer(bufferSize, VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, vertexBuffer, vertexBufferMemory);

copyBuffer(stagingBuffer, vertexBuffer, bufferSize);

```

After copying the data from the staging buffer to the device buffer, we should clean it up:

스테이징 버퍼에서 디바이스 버퍼로 데이터를 복사한 후에는 이를 정리해야 합니다:

```c
    ...

    copyBuffer(stagingBuffer, vertexBuffer, bufferSize);

    vkDestroyBuffer(device, stagingBuffer, nullptr);
    vkFreeMemory(device, stagingBufferMemory, nullptr);
}

```

프로그램을 실행하여 익숙한 삼각형이 다시 표시되는지 확인합니다. 지금은 개선 사항이 눈에 보이지 않을 수 있지만 이제 버텍스 데이터가 고성능 메모리에서 로드되고 있습니다. 이는 더 복잡한 지오메트리를 렌더링하기 시작할 때 중요해질 것입니다.

# Conclusion

실제 애플리케이션에서는 모든 개별 버퍼에 대해 실제로 [`vkAllocateMemory`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkAllocateMemory.html)를 호출해서는 안 된다는 점에 유의해야 합니다. 최대 동시 메모리 할당 수는 `maxMemoryAllocationCount` 물리적 장치 제한에 의해 제한되며, 이는 NVIDIA GTX 1080과 같은 하이엔드 하드웨어에서도 `4096`까지 낮아질 수 있습니다. 많은 수의 오브젝트에 동시에 메모리를 할당하는 올바른 방법은 많은 함수에서 보았던 `오프셋` 매개 변수를 사용하여 단일 할당을 여러 개의 다른 오브젝트로 분할하는 사용자 정의 할당자를 만드는 것입니다.

이러한 얼로케이터를 직접 구현하거나 GPUOpen 이니셔티브에서 제공하는 [VulkanMemoryAllocator](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator) 라이브러리를 사용할 수 있습니다. 그러나 이 튜토리얼에서는 현재로서는 이러한 제한에 근접하지 않을 것이므로 모든 리소스에 대해 별도의 할당을 사용해도 괜찮습니다.

[C++ code](https://vulkan-tutorial.com/code/20_staging_buffer.cpp) / [Vertex shader](https://vulkan-tutorial.com/code/18_shader_vertexbuffer.vert) / [Fragment shader](https://vulkan-tutorial.com/code/18_shader_vertexbuffer.frag)