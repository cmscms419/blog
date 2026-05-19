# Computer shader

- [Introduction](https://vulkan-tutorial.com/Compute_Shader#page_Introduction)
- [Advantages](https://vulkan-tutorial.com/Compute_Shader#page_Advantages)
- [The Vulkan pipeline](https://vulkan-tutorial.com/Compute_Shader#page_The-Vulkan-pipeline)
- [An example](https://vulkan-tutorial.com/Compute_Shader#page_An-example)
- [Data manipulation](https://vulkan-tutorial.com/Compute_Shader#page_Data-manipulation)
    - [Shader storage buffer objects (SSBO)](https://vulkan-tutorial.com/Compute_Shader#page_Shader-storage-buffer-objects-SSBO)
    - [Storage images](https://vulkan-tutorial.com/Compute_Shader#page_Storage-images)
- [Compute queue families](https://vulkan-tutorial.com/Compute_Shader#page_Compute-queue-families)
- [The compute shader stage](https://vulkan-tutorial.com/Compute_Shader#page_The-compute-shader-stage)
- [Loading compute shaders](https://vulkan-tutorial.com/Compute_Shader#page_Loading-compute-shaders)
- [Preparing the shader storage buffers](https://vulkan-tutorial.com/Compute_Shader#page_Preparing-the-shader-storage-buffers)
- [Descriptors](https://vulkan-tutorial.com/Compute_Shader#page_Descriptors)
- [Compute pipelines](https://vulkan-tutorial.com/Compute_Shader#page_Compute-pipelines)
- [Compute space](https://vulkan-tutorial.com/Compute_Shader#page_Compute-space)
- [Compute shaders](https://vulkan-tutorial.com/Compute_Shader#page_Compute-shaders)
- [Running compute commands](https://vulkan-tutorial.com/Compute_Shader#page_Running-compute-commands)
    - [Dispatch](https://vulkan-tutorial.com/Compute_Shader#page_Dispatch)
    - [Submitting work](https://vulkan-tutorial.com/Compute_Shader#page_Submitting-work)
    - [Synchronizing graphics and compute](https://vulkan-tutorial.com/Compute_Shader#page_Synchronizing-graphics-and-compute)
- [Drawing the particle system](https://vulkan-tutorial.com/Compute_Shader#page_Drawing-the-particle-system)
- [Conclusion](https://vulkan-tutorial.com/Compute_Shader#page_Conclusion)

# Introduction

이번 보너스 챕터에서는 컴퓨팅 셰이더에 대해 살펴보겠습니다.

지금까지 모든 이전 장에서는 Vulkan 파이프라인의 전통적인 그래픽 부분을 다루었습니다.

하지만 OpenGL과 같은 이전 API와 달리 Vulkan의 컴퓨트 셰이더 지원은 필수입니다.

즉, 하이엔드 데스크톱 GPU든 저전력 임베디드 디바이스든 상관없이 사용 가능한 모든 Vulkan 구현에서 컴퓨팅 셰이더를 사용할 수 있습니다.

이로써 애플리케이션이 실행되는 위치에 상관없이 그래픽 프로세서 장치(GPGPU)에서 범용 컴퓨팅의 세계가 열립니다.

GPGPU는 전통적으로 CPU의 영역이었던 일반 연산을 GPU에서 수행할 수 있다는 것을 의미합니다.

하지만 GPU가 점점 더 강력해지고 유연해지면서 CPU의 범용 기능이 필요한 많은 워크로드를 이제 GPU에서 실시간으로 수행할 수 있게 되었습니다.

GPU의 연산 기능을 사용할 수 있는 몇 가지 예로는 이미지 조작, 가시성 테스트, 포스트 프로세싱, 고급 조명 계산, 애니메이션, 물리학(예: 파티클 시스템) 등이 있습니다. 또한 숫자 계산이나 AI 관련 작업처럼 그래픽 출력이 필요하지 않은 비시각적 연산 전용 작업에도 컴퓨팅을 사용할 수 있습니다. 이를 "헤드리스 컴퓨팅"이라고 합니다.

# Advantages

Doing computationally expensive calculations on the GPU has several advantages. The most obvious one is offloading work from the CPU. Another one is not requiring moving data between the CPU's main memory and the GPU's memory. All of the data can stay on the GPU without having to wait for slow transfers from main memory.

Aside from these, GPUs are heavily parallelized with some of them having tens of thousands of small compute units. This often makes them a better fit for highly parallel workflows than a CPU with a few large compute units.

# The Vulkan pipeline

컴퓨팅이 파이프라인의 그래픽 부분과 완전히 분리되어 있다는 사실을 아는 것이 중요합니다. 이는 공식 사양의 다음 Vulkan  파이프라인 블록 다이어그램에서 확인할 수 있습니다:

![](attachments/vulkan_pipeline_block_diagram.png)

이 다이어그램에서 왼쪽에는 파이프라인의 기존 그래픽 부분이 있고 오른쪽에는 컴퓨팅 셰이더(스테이지)를 포함하여 이 그래픽 파이프라인에 포함되지 않은 여러 스테이지가 있습니다. 그래픽스 파이프라인에서 컴퓨팅 셰이더 스테이지를 분리하면 원하는 곳에서 사용할 수 있습니다. 이는 버텍스 셰이더의 변환된 출력에 항상 적용되는 프래그먼트 셰이더와는 매우 다릅니다.

The center of the diagram also shows that e.g. descriptor sets are also used by compute, so everything we learned about descriptors layouts, descriptor sets and descriptors also applies here.

# An example

An easy to understand example that we will implement in this chapter is a GPU based particle system. 

Such systems are used in many games and often consist of thousands of particles that need to be updated at interactive frame rates. Rendering such a system requires 2 main components: vertices, passed as vertex buffers, and a way to update them based on some equation.

이 장에서 구현할 이해하기 쉬운 예는 GPU 기반 파티클 시스템입니다.

이러한 시스템은 많은 게임에서 사용되며 인터랙티브한 프레임 속도로 업데이트해야 하는 수천 개의 파티클로 구성되는 경우가 많습니다. 이러한 시스템을 렌더링하려면 버텍스 버퍼로 전달되는 버텍스와 일부 방정식에 따라 업데이트하는 방법이라는 두 가지 주요 구성 요소가 필요합니다.

The "classical" CPU based particle system would store particle data in the system's main memory and then use the CPU to update them. After the update, the vertices need to be transferred to the GPU's memory again so it can display the updated particles in the next frame. The most straight-forward way would be recreating the vertex buffer with the new data for each frame. This is obviously very costly. Depending on your implementation, there are other options like mapping GPU memory so it can be written by the CPU (called "resizable BAR" on desktop systems, or unified memory on integrated GPUs) or just using a host local buffer (which would be the slowest method due to PCI-E bandwidth). But no matter what buffer update method you choose, you always require a "round-trip" to the CPU to update the particles.

"고전적인" CPU 기반 파티클 시스템은 파티클 데이터를 시스템의 메인 메모리에 저장한 다음 CPU를 사용하여 파티클을 업데이트합니다. 업데이트 후에는 다음 프레임에 업데이트된 파티클을 표시할 수 있도록 버텍스를 다시 GPU의 메모리로 전송해야 합니다. 가장 간단한 방법은 각 프레임마다 새로운 데이터로 버텍스 버퍼를 다시 생성하는 것입니다. 이 방법은 분명히 비용이 많이 듭니다. 구현에 따라 GPU 메모리를 매핑하여 CPU가 쓸 수 있도록 하거나(데스크톱 시스템에서는 "크기 조정 가능 BAR", 통합 GPU에서는 통합 메모리라고 함) 호스트 로컬 버퍼(PCI-E 대역폭으로 인해 가장 느린 방법)를 사용하는 등의 다른 옵션도 있습니다. 하지만 어떤 버퍼 업데이트 방법을 선택하든 파티클을 업데이트하려면 항상 CPU로 '왕복'해야 합니다.

With a GPU based particle system, this round-trip is no longer required. Vertices are only uploaded to the GPU at the start and all updates are done in the GPU's memory using compute shaders. One of the main reasons why this is faster is the much higher bandwidth between the GPU and it's local memory. In a CPU based scenario, you'd be limited by main memory and PCI-express bandwidth, which is often just a fraction of the GPU's memory bandwidth.

When doing this on a GPU with a dedicated compute queue, you can update particles in parallel to the rendering part of the graphics pipeline. This is called "async compute", and is an advanced topic not covered in this tutorial.

Here is a screenshot from this chapter's code. The particles shown here are updated by a compute shader directly on the GPU, without any CPU interaction:

![](attachments/compute_shader_particles.png)

# Data manipulation

In this tutorial we already learned about different buffer types like vertex and index buffers for passing primitives and uniform buffers for passing data to a shader. And we also used images to do texture mapping. But up until now, we always wrote data using the CPU and only did reads on the GPU.

이 튜토리얼에서는 프리미티브 전달을 위한 버텍스 및 인덱스 버퍼와 셰이더에 데이터를 전달하기 위한 유니폼 버퍼와 같은 다양한 버퍼 유형에 대해 이미 배웠습니다. 또한 이미지를 사용하여 텍스처 매핑을 수행했습니다. 하지만 지금까지는 항상 CPU를 사용하여 데이터를 쓰고 GPU에서만 읽었습니다.

An important concept introduced with compute shaders is the ability to arbitrarily read from **and write to** buffers. For this, Vulkan offers two dedicated storage types.

컴퓨팅 셰이더에 도입된 중요한 개념은 버퍼에서 임의로 읽고 쓸 수 있는 기능입니다. 이를 위해 벌칸은 두 가지 전용 스토리지 유형을 제공합니다.

# Shader storage buffer objects (SSBO)

셰이더 스토리지 버퍼(SSBO)를 사용하면 셰이더가 버퍼에서 읽고 쓸 수 있습니다. 이를 사용하는 것은 uniform buffer objects를 사용하는 것과 유사합니다. 가장 큰 차이점은 다른 버퍼 유형을 SSBO에 별칭을 붙일 수 있다는 점과 임의로 큰 크기를 지정할 수 있다는 점입니다.

GPU 기반 파티클 시스템으로 돌아가서, 이제 컴퓨팅 셰이더가 버텍스를 업데이트(쓰기)하고 버텍스 셰이더가 버텍스를 읽기(그리기)하는 경우 두 사용법이 서로 다른 버퍼 유형을 필요로 하기 때문에 어떻게 처리할지 궁금할 것입니다.

하지만 그렇지 않습니다. Vulkan에서는 버퍼와 이미지에 대해 여러 용도를 지정할 수 있습니다. 따라서 파티클 버텍스 버퍼를 버텍스 버퍼(그래픽스 패스에서)와 스토리지 버퍼(컴퓨트 패스에서)로 사용하려면 이 두 가지 사용 플래그를 사용하여 버퍼를 생성하기만 하면 됩니다:

```c
VkBufferCreateInfo bufferInfo{};
...
bufferInfo.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
...

if (vkCreateBuffer(device, &bufferInfo, nullptr, &shaderStorageBuffers[i]) != VK_SUCCESS) {
    throw std::runtime_error("failed to create vertex buffer!");
}

```

The two flags `VK_BUFFER_USAGE_VERTEX_BUFFER_BIT` and `VK_BUFFER_USAGE_STORAGE_BUFFER_BIT` set with `bufferInfo.usage` tell the implementation that we want to use this buffer for two different scenarios: as a vertex buffer in the vertex shader and as a store buffer(버텍스 셰이더의 버텍스 버퍼와 스토어 버퍼로 사용합니다.). 

Note that we also added the `VK_BUFFER_USAGE_TRANSFER_DST_BIT` flag in here so we can transfer data from the host to the GPU.

호스트(CPU)에서 GPU로 데이터를 전송할 수 있도록 여기에 `VK_BUFFER_USAGE_TRANSFER_DST_BIT` 플래그도 추가했습니다.

 This is crucial as we want the shader storage buffer to stay in GPU memory only (`VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT`) we need to to transfer data from the host to this buffer.

shader storage buffer가 GPU 메모리에만 유지되도록 하려면 호스트에서 이 버퍼로 데이터를 전송해야 하므로(`VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT`) 이는 매우 중요합니다.

Here is the same code using using the `createBuffer` helper function:

```c
createBuffer(bufferSize, VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, shaderStorageBuffers[i], shaderStorageBuffersMemory[i]);

```

The GLSL shader declaration for accessing such a buffer looks like this:

```glsl
struct Particle {
  vec2 position;
  vec2 velocity;
  vec4 color;
};

layout(std140, binding = 1) readonly buffer ParticleSSBOIn {
   Particle particlesIn[ ];
};

layout(std140, binding = 2) buffer ParticleSSBOOut {
   Particle particlesOut[ ];
};

```

이 예제에서는 각 파티클에 위치와 속도 값이 있는 유형화된 SSBO가 있습니다(`Particle` 구조체 참조).

그런 다음 SSBO에는 `[]`로 표시된 바인딩되지 않은 파티클 수가 포함됩니다.

SSBO의 요소 수를 지정할 필요가 없다는 것은 uniform 버퍼에 비해 장점 중 하나입니다.

`std140`은 셰이더 스토리지 버퍼의 멤버 요소가 메모리에서 정렬되는 방식을 결정하는 메모리 레이아웃 한정자입니다.

이는 호스트와 GPU 사이에 버퍼를 매핑하는 데 필요한 특정 보증을 제공합니다.

컴퓨팅 셰이더에서 이러한 스토리지 버퍼 오브젝트에 쓰는 것은 C++ 쪽에서 버퍼에 쓰는 방법과 유사하며 간단합니다:

```glsl
particlesOut[index].position = particlesIn[index].position + particlesIn[index].velocity.xy * ubo.deltaTime;

```

# Storage images

*Note that we won't be doing image manipulation in this chapter.*

*This paragraph is here to make readers aware that compute shaders can also be used for image manipulation.*

A storage image allows you read from and write to an image. Typical use cases are applying image effects to textures, doing post processing (which in turn is very similar) or generating mip-maps.

스토리지 이미지를 사용하면 이미지를 읽고 쓸 수 있습니다. 일반적인 사용 사례는 텍스처에 이미지 효과를 적용하거나, 포스트 프로세싱을 수행하거나(매우 유사합니다), 밉맵을 생성하는 것입니다.

This is similar for images:

```c
VkImageCreateInfo imageInfo {};
...
imageInfo.usage = VK_IMAGE_USAGE_SAMPLED_BIT | VK_IMAGE_USAGE_STORAGE_BIT;
...

if (vkCreateImage(device, &imageInfo, nullptr, &textureImage) != VK_SUCCESS) {
    throw std::runtime_error("failed to create image!");
}

```

The two flags `VK_IMAGE_USAGE_SAMPLED_BIT` and `VK_IMAGE_USAGE_STORAGE_BIT` set with `imageInfo.usage` tell the implementation that we want to use this image for two different scenarios:

`imageInfo.usage`와 함께 설정된 두 개의 플래그 `VK_IMAGE_USAGE_SAMPLED_BIT`및 `VK_IMAGE_USAGE_STORAGE_BIT`는 구현에 두 가지 시나리오에 이 이미지를 사용하도록 지시합니다.

fragment shader에서 샘플링된 이미지로, computer shader에서 저장 이미지로 사용합니다;

The GLSL shader declaration for storage image looks similar to sampled images used e.g. in the fragment shader:

```glsl
layout (binding = 0, rgba8) uniform readonly image2D inputImage;
layout (binding = 1, rgba8) uniform writeonly image2D outputImage;

```

A few differences here are additional attributes like `rgba8` for the format of the image, the `readonly` and `writeonly` qualifiers, telling the implementation that we will only read from the input image and write to the output image. And last but not least we need to use the `image2D` type to declare a storage image.

Reading from and writing to storage images in the compute shader is then done using `imageLoad` and `imageStore`:

```glsl
vec3 pixel = imageLoad(inputImage, ivec2(gl_GlobalInvocationID.xy)).rgb;
imageStore(outputImage, ivec2(gl_GlobalInvocationID.xy), pixel);

```

# Compute queue families

In the [physical device and queue families chapter](https://vulkan-tutorial.com/Drawing_a_triangle/Setup/Physical_devices_and_queue_families#page_Queue-families) we already learned about queue families and how to select a graphics queue family. 

[physical device and queue families 챕터](https://vulkan-tutorial.com/Drawing_a_triangle/Setup/Physical_devices_and_queue_families#page_Queue-families)에서 이미 queue families과 graphics queue family을 선택하는 방법에 대해 배웠습니다.

Compute uses the queue family properties flag bit `VK_QUEUE_COMPUTE_BIT`. So if we want to do compute work, we need to get a queue from a queue family that supports compute.

Note that Vulkan requires an implementation which supports graphics operations to have at least one queue family that supports both graphics and compute operations, but it's also possible that implementations offer a dedicated compute queue. 

This dedicated compute queue (that does not have the graphics bit) hints at an asynchronous compute queue. 

To keep this tutorial beginner friendly though, we'll use a queue that can do both graphics and compute operations. 

This will also save us from dealing with several advanced synchronization mechanisms.

For our compute sample we need to change the device creation code a bit:

```c
uint32_t queueFamilyCount = 0;
vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, nullptr);

std::vector<VkQueueFamilyProperties> queueFamilies(queueFamilyCount);
vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, queueFamilies.data());

int i = 0;
for (const auto& queueFamily : queueFamilies) {
    if ((queueFamily.queueFlags & VK_QUEUE_GRAPHICS_BIT) && (queueFamily.queueFlags & VK_QUEUE_COMPUTE_BIT)) {
        indices.graphicsAndComputeFamily = i;
    }

    i++;
}

```

The changed queue family index selection code will now try to find a queue family that supports both graphics and compute.

We can then get a compute queue from this queue family in `createLogicalDevice`:

```c
vkGetDeviceQueue(device, indices.graphicsAndComputeFamily.value(), 0, &computeQueue);

```

# The compute shader stage

In the graphics samples we have used different pipeline stages to load shaders and access descriptors. Compute shaders are accessed in a similar way by using the `VK_SHADER_STAGE_COMPUTE_BIT` pipeline. So loading a compute shader is just the same as loading a vertex shader, but with a different shader stage. We'll talk about this in detail in the next paragraphs. Compute also introduces a new binding point type for descriptors and pipelines named `VK_PIPELINE_BIND_POINT_COMPUTE` that we'll have to use later on.

그래픽 샘플에서는 셰이더를 로드하고 디스크립터에 액세스하기 위해 다양한 파이프라인 단계를 사용했습니다. 컴퓨트 셰이더는 `VK_SHADER_STAGE_COMPUTE_BIT` 파이프라인을 사용하여 비슷한 방식으로 액세스합니다. 따라서 컴퓨트 셰이더를 로드하는 것은 버텍스 셰이더를 로드하는 것과 동일하지만 셰이더 단계가 다릅니다. 이에 대해서는 다음 단락에서 자세히 설명하겠습니다. 또한 Compute에는 나중에 사용하게 될 `VK_PIPELINE_BIND_POINT_COMPUTE`라는 디스크립터와 파이프라인에 대한 새로운 바인딩 포인트 유형이 도입됩니다.

# Loading compute shaders

Loading compute shaders in our application is the same as loading any other other shader. The only real difference is that we'll need to use the `VK_SHADER_STAGE_COMPUTE_BIT` mentioned above.

```c
auto computeShaderCode = readFile("shaders/compute.spv");

VkShaderModule computeShaderModule = createShaderModule(computeShaderCode);

VkPipelineShaderStageCreateInfo computeShaderStageInfo{};
computeShaderStageInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
computeShaderStageInfo.stage = VK_SHADER_STAGE_COMPUTE_BIT;
computeShaderStageInfo.module = computeShaderModule;
computeShaderStageInfo.pName = "main";
...

```

# Preparing the shader storage buffers

Earlier on we learned that we can use shader storage buffers to pass arbitrary data to compute shaders. For this example we will upload an array of particles to the GPU, so we can manipulate it directly in the GPU's memory.

앞서 셰이더 스토리지 버퍼를 사용하여 임의의 데이터를 전달하여 셰이더를 계산할 수 있다는 것을 배웠습니다. 이 예제에서는 파티클 배열을 GPU에 업로드하여 GPU의 메모리에서 직접 조작할 수 있도록 하겠습니다.

In the [frames in flight](https://vulkan-tutorial.com/Drawing_a_triangle/Drawing/Frames_in_flight) chapter we talked about duplicating resources per frame in flight, so we can keep the CPU and the GPU busy. First we declare a vector for the buffer object and the device memory backing it up:

```c
std::vector<VkBuffer> shaderStorageBuffers;
std::vector<VkDeviceMemory> shaderStorageBuffersMemory;

```

In the `createShaderStorageBuffers` we then resize those vectors to match the max. number of frames in flight:

```c
shaderStorageBuffers.resize(MAX_FRAMES_IN_FLIGHT);
shaderStorageBuffersMemory.resize(MAX_FRAMES_IN_FLIGHT);
```

With this setup in place we can start to move the initial particle information to the GPU. 

We first initialize a vector of particles on the host side:

```c
    // Initialize particles
    std::default_random_engine rndEngine((unsigned)time(nullptr));
    std::uniform_real_distribution<float> rndDist(0.0f, 1.0f);

    // Initial particle positions on a circle
    std::vector<Particle> particles(PARTICLE_COUNT);
    for (auto& particle : particles) {
        float r = 0.25f * sqrt(rndDist(rndEngine));
        float theta = rndDist(rndEngine) * 2 * 3.14159265358979323846;
        float x = r * cos(theta) * HEIGHT / WIDTH;
        float y = r * sin(theta);
        particle.position = glm::vec2(x, y);
        particle.velocity = glm::normalize(glm::vec2(x,y)) * 0.00025f;
        particle.color = glm::vec4(rndDist(rndEngine), rndDist(rndEngine), rndDist(rndEngine), 1.0f);
    }

```

We then create a [staging buffer](https://vulkan-tutorial.com/Vertex_buffers/Staging_buffer) in the host's memory to hold the initial particle properties:

```c
    VkDeviceSize bufferSize = sizeof(Particle) * PARTICLE_COUNT;

    VkBuffer stagingBuffer;
    VkDeviceMemory stagingBufferMemory;
    createBuffer(bufferSize, VK_BUFFER_USAGE_TRANSFER_SRC_BIT, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, stagingBuffer, stagingBufferMemory);

    void* data;
    vkMapMemory(device, stagingBufferMemory, 0, bufferSize, 0, &data);
    memcpy(data, particles.data(), (size_t)bufferSize);
    vkUnmapMemory(device, stagingBufferMemory);

```

Using this staging buffer as a source we then create the per-frame shader storage buffers and copy the particle properties from the staging buffer to each of these:

```c
    for (size_t i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
        createBuffer(bufferSize, VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, shaderStorageBuffers[i], shaderStorageBuffersMemory[i]);
        // Copy data from the staging buffer (host) to the shader storage buffer (GPU)
        copyBuffer(stagingBuffer, shaderStorageBuffers[i], bufferSize);
    }
}

```

# Descriptors

Setting up descriptors for compute is almost identical to graphics. The only difference is that descriptors need to have the `VK_SHADER_STAGE_COMPUTE_BIT` set to make them accessible by the compute stage:

```c
std::array<VkDescriptorSetLayoutBinding, 3> layoutBindings{};
layoutBindings[0].binding = 0;
layoutBindings[0].descriptorCount = 1;
layoutBindings[0].descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
layoutBindings[0].pImmutableSamplers = nullptr;
layoutBindings[0].stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;
...
```

Note that you can combine shader stages here, so if you want the descriptor to be accessible from the vertex and compute stage, e.g. for a uniform buffer with parameters shared across them, you simply set the bits for both stages:

```c
layoutBindings[0].stageFlags = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_COMPUTE_BIT;

```

Here is the descriptor setup for our sample. The layout looks like this:

```c
std::array<VkDescriptorSetLayoutBinding, 3> layoutBindings{};
layoutBindings[0].binding = 0;
layoutBindings[0].descriptorCount = 1;
layoutBindings[0].descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
layoutBindings[0].pImmutableSamplers = nullptr;
layoutBindings[0].stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;

layoutBindings[1].binding = 1;
layoutBindings[1].descriptorCount = 1;
layoutBindings[1].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
layoutBindings[1].pImmutableSamplers = nullptr;
layoutBindings[1].stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;

layoutBindings[2].binding = 2;
layoutBindings[2].descriptorCount = 1;
layoutBindings[2].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
layoutBindings[2].pImmutableSamplers = nullptr;
layoutBindings[2].stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;

VkDescriptorSetLayoutCreateInfo layoutInfo{};
layoutInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
layoutInfo.bindingCount = 3;
layoutInfo.pBindings = layoutBindings.data();

if (vkCreateDescriptorSetLayout(device, &layoutInfo, nullptr, &computeDescriptorSetLayout) != VK_SUCCESS) {
    throw std::runtime_error("failed to create compute descriptor set layout!");
}

```

Looking at this setup, you might wonder why we have two layout bindings for shader storage buffer objects, even though we'll only render a single particle system. This is because the particle positions are updated frame by frame based on a delta time. This means that each frame needs to know about the last frames' particle positions, so it can update them with a new delta time and write them to it's own SSBO:

![](attachments/compute_ssbo_read_write.svg)

For that, the compute shader needs to have access to the last and current frame's SSBOs. This is done by passing both to the compute shader in our descriptor setup. See the `storageBufferInfoLastFrame` and `storageBufferInfoCurrentFrame`:

```c
for (size_t i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
    VkDescriptorBufferInfo uniformBufferInfo{};
    uniformBufferInfo.buffer = uniformBuffers[i];
    uniformBufferInfo.offset = 0;
    uniformBufferInfo.range = sizeof(UniformBufferObject);

    std::array<VkWriteDescriptorSet, 3> descriptorWrites{};
    ...

    VkDescriptorBufferInfo storageBufferInfoLastFrame{};
    storageBufferInfoLastFrame.buffer = shaderStorageBuffers[(i - 1) % MAX_FRAMES_IN_FLIGHT];
    storageBufferInfoLastFrame.offset = 0;
    storageBufferInfoLastFrame.range = sizeof(Particle) * PARTICLE_COUNT;

    descriptorWrites[1].sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
    descriptorWrites[1].dstSet = computeDescriptorSets[i];
    descriptorWrites[1].dstBinding = 1;
    descriptorWrites[1].dstArrayElement = 0;
    descriptorWrites[1].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
    descriptorWrites[1].descriptorCount = 1;
    descriptorWrites[1].pBufferInfo = &storageBufferInfoLastFrame;

    VkDescriptorBufferInfo storageBufferInfoCurrentFrame{};
    storageBufferInfoCurrentFrame.buffer = shaderStorageBuffers[i];
    storageBufferInfoCurrentFrame.offset = 0;
    storageBufferInfoCurrentFrame.range = sizeof(Particle) * PARTICLE_COUNT;

    descriptorWrites[2].sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
    descriptorWrites[2].dstSet = computeDescriptorSets[i];
    descriptorWrites[2].dstBinding = 2;
    descriptorWrites[2].dstArrayElement = 0;
    descriptorWrites[2].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
    descriptorWrites[2].descriptorCount = 1;
    descriptorWrites[2].pBufferInfo = &storageBufferInfoCurrentFrame;

    vkUpdateDescriptorSets(device, 3, descriptorWrites.data(), 0, nullptr);
}

```

Remember that we also have to request the descriptor types for the SSBOs from our descriptor pool:

```c
std::array<VkDescriptorPoolSize, 2> poolSizes{};
...

poolSizes[1].type = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
poolSizes[1].descriptorCount = static_cast<uint32_t>(MAX_FRAMES_IN_FLIGHT) * 2;

```

We need to double the number of `VK_DESCRIPTOR_TYPE_STORAGE_BUFFER` types requested from the pool by two because our sets reference the SSBOs of the last and current frame.

# Compute pipelines

As compute is not a part of the graphics pipeline, we can't use [`vkCreateGraphicsPipelines`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCreateGraphicsPipelines.html). Instead we need to create a dedicated compute pipeline with [`vkCreateComputePipelines`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCreateComputePipelines.html) for running our compute commands. Since a compute pipeline does not touch any of the rasterization state, it has a lot less state than a graphics pipeline:

```c
VkComputePipelineCreateInfo pipelineInfo{};
pipelineInfo.sType = VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO;
pipelineInfo.layout = computePipelineLayout;
pipelineInfo.stage = computeShaderStageInfo;

if (vkCreateComputePipelines(device, VK_NULL_HANDLE, 1, &pipelineInfo, nullptr, &computePipeline) != VK_SUCCESS) {
    throw std::runtime_error("failed to create compute pipeline!");
}

```

The setup is a lot simpler, as we only require one shader stage and a pipeline layout. The pipeline layout works the same as with the graphics pipeline:

```c
VkPipelineLayoutCreateInfo pipelineLayoutInfo{};
pipelineLayoutInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
pipelineLayoutInfo.setLayoutCount = 1;
pipelineLayoutInfo.pSetLayouts = &computeDescriptorSetLayout;

if (vkCreatePipelineLayout(device, &pipelineLayoutInfo, nullptr, &computePipelineLayout) != VK_SUCCESS) {
    throw std::runtime_error("failed to create compute pipeline layout!");
}
```

# Compute space == direct11 computer shader 부분 참고

Before we get into how a compute shader works and how we submit compute workloads to the GPU, we need to talk about two important compute concepts: **work groups** and **invocations**. They define an abstract execution model for how compute workloads are processed by the compute hardware of the GPU in three dimensions (x, y, and z).

**Work groups** define how the compute workloads are formed and processed by the the compute hardware of the GPU. You can think of them as work items the GPU has to work through. Work group dimensions are set by the application at command buffer time using a dispatch command.

And each work group then is a collection of **invocations** that execute the same compute shader. Invocations can potentially run in parallel and their dimensions are set in the compute shader. Invocations within a single workgroup have access to shared memory.

This image shows the relation between these two in three dimensions:

![](attachments/compute_space.svg)

The number of dimensions for work groups (defined by [`vkCmdDispatch`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdDispatch.html)) and invocations depends (defined by the local sizes in the compute shader) on how input data is structured. If you e.g. work on a one-dimensional array, like we do in this chapter, you only have to specify the x dimension for both.

As an example: If we dispatch a work group count of [64, 1, 1] with a compute shader local size of [32, 32, ,1], our compute shader will be invoked 64 x 32 x 32 = 65,536 times.

Note that the maximum count for work groups and local sizes differs from implementation to implementation, so you should always check the compute related `maxComputeWorkGroupCount`, `maxComputeWorkGroupInvocations` and `maxComputeWorkGroupSize` limits in [`VkPhysicalDeviceLimits`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPhysicalDeviceLimits.html).

# Compute shaders

Now that we have learned about all the parts required to setup a compute shader pipeline, it's time to take a look at compute shaders. All of the things we learned about using GLSL shaders e.g. for vertex and fragment shaders also applies to compute shaders. The syntax is the same, and many concepts like passing data between the application and the shader are the same. But there are some important differences.

A very basic compute shader for updating a linear array of particles may look like this:

```glsl
#version 450

layout (binding = 0) uniform ParameterUBO {
    float deltaTime;
} ubo;

struct Particle {
    vec2 position;
    vec2 velocity;
    vec4 color;
};

layout(std140, binding = 1) readonly buffer ParticleSSBOIn {
   Particle particlesIn[ ];
};

layout(std140, binding = 2) buffer ParticleSSBOOut {
   Particle particlesOut[ ];
};

layout (local_size_x = 256, local_size_y = 1, local_size_z = 1) in;

void main()
{
    uint index = gl_GlobalInvocationID.x;

    Particle particleIn = particlesIn[index];

    particlesOut[index].position = particleIn.position + particleIn.velocity.xy * ubo.deltaTime;
    particlesOut[index].velocity = particleIn.velocity;
    ...
}

```

The top part of the shader contains the declarations for the shader's input. First is a uniform buffer object at binding 0, something we already learned about in this tutorial. Below we declare our Particle structure that matches the declaration in the C++ code. Binding 1 then refers to the shader storage buffer object with the particle data from the last frame (see the descriptor setup), and binding 2 points to the SSBO for the current frame, which is the one we'll be updating with this shader.

An interesting thing is this compute-only declaration related to the compute space:

```glsl
layout (local_size_x = 256, local_size_y = 1, local_size_z = 1) in;

```

This defines the number invocations of this compute shader in the current work group. As noted earlier, this is the local part of the compute space. Hence the `local_` prefix. As we work on a linear 1D array of particles we only need to specify a number for x dimension in `local_size_x`.

The `main` function then reads from the last frame's SSBO and writes the updated particle position to the SSBO for the current frame. Similar to other shader types, compute shaders have their own set of builtin input variables. Built-ins are always prefixed with `gl_`. One such built-in is `gl_GlobalInvocationID`, a variable that uniquely identifies the current compute shader invocation across the current dispatch. We use this to index into our particle array.

# Running compute commands

# Dispatch

Now it's time to actually tell the GPU to do some compute. This is done by calling [`vkCmdDispatch`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdDispatch.html) inside a command buffer. While not perfectly true, a dispatch is for compute as a draw call like [`vkCmdDraw`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdDraw.html) is for graphics. This dispatches a given number of compute work items in at max. three dimensions.

```c
VkCommandBufferBeginInfo beginInfo{};
beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;

if (vkBeginCommandBuffer(commandBuffer, &beginInfo) != VK_SUCCESS) {
    throw std::runtime_error("failed to begin recording command buffer!");
}

...

vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_COMPUTE, computePipeline);
vkCmdBindDescriptorSets(commandBuffer, VK_PIPELINE_BIND_POINT_COMPUTE, computePipelineLayout, 0, 1, &computeDescriptorSets[i], 0, 0);

vkCmdDispatch(computeCommandBuffer, PARTICLE_COUNT / 256, 1, 1);

...

if (vkEndCommandBuffer(commandBuffer) != VK_SUCCESS) {
    throw std::runtime_error("failed to record command buffer!");
}

```

The [`vkCmdDispatch`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdDispatch.html) will dispatch `PARTICLE_COUNT / 256` local work groups in the x dimension. As our particles array is linear, we leave the other two dimensions at one, resulting in a one-dimensional dispatch. But why do we divide the number of particles (in our array) by 256? That's because in the previous paragraph we defined that every compute shader in a work group will do 256 invocations. So if we were to have 4096 particles, we would dispatch 16 work groups, with each work group running 256 compute shader invocations. Getting the two numbers right usually takes some tinkering and profiling, depending on your workload and the hardware you're running on. If your particle size would be dynamic and can't always be divided by e.g. 256, you can always use `gl_GlobalInvocationID` at the start of your compute shader and return from it if the global invocation index is greater than the number of your particles.

And just as was the case for the compute pipeline, a compute command buffer contains a lot less state then a graphics command buffer. There's no need to start a render pass or set a viewport.

# Submitting work

As our sample does both compute and graphics operations, we'll be doing two submits to both the graphics and compute queue per frame (see the `drawFrame` function):

```c
...
if (vkQueueSubmit(computeQueue, 1, &submitInfo, nullptr) != VK_SUCCESS) {
    throw std::runtime_error("failed to submit compute command buffer!");
};
...
if (vkQueueSubmit(graphicsQueue, 1, &submitInfo, inFlightFences[currentFrame]) != VK_SUCCESS) {
    throw std::runtime_error("failed to submit draw command buffer!");
}

```

The first submit to the compute queue updates the particle positions using the compute shader, and the second submit will then use that updated data to draw the particle system.

# Synchronizing graphics and compute

Synchronization is an important part of Vulkan, even more so when doing compute in conjunction with graphics. Wrong or lacking synchronization may result in the vertex stage starting to draw (=read) particles while the compute shader hasn't finished updating (=write) them (read-after-write hazard), or the compute shader could start updating particles that are still in use by the vertex part of the pipeline (write-after-read hazard).

So we must make sure that those cases don't happen by properly synchronizing the graphics and the compute load. There are different ways of doing so, depending on how you submit your compute workload but in our case with two separate submits, we'll be using [semaphores](https://vulkan-tutorial.com/Drawing_a_triangle/Drawing/Rendering_and_presentation#page_Semaphores) and [fences](https://vulkan-tutorial.com/Drawing_a_triangle/Drawing/Rendering_and_presentation#page_Fences) to ensure that the vertex shader won't start fetching vertices until the compute shader has finished updating them.

This is necessary as even though the two submits are ordered one-after-another, there is no guarantee that they execute on the GPU in this order. Adding in wait and signal semaphores ensures this execution order.

So we first add a new set of synchronization primitives for the compute work in `createSyncObjects`. The compute fences, just like the graphics fences, are created in the signaled state because otherwise, the first draw would time out while waiting for the fences to be signaled as detailed [here](https://vulkan-tutorial.com/Drawing_a_triangle/Drawing/Rendering_and_presentation#page_Waiting-for-the-previous-frame):

```c
std::vector<VkFence> computeInFlightFences;
std::vector<VkSemaphore> computeFinishedSemaphores;
...
computeInFlightFences.resize(MAX_FRAMES_IN_FLIGHT);
computeFinishedSemaphores.resize(MAX_FRAMES_IN_FLIGHT);

VkSemaphoreCreateInfo semaphoreInfo{};
semaphoreInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;

VkFenceCreateInfo fenceInfo{};
fenceInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
fenceInfo.flags = VK_FENCE_CREATE_SIGNALED_BIT;

for (size_t i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
    ...
    if (vkCreateSemaphore(device, &semaphoreInfo, nullptr, &computeFinishedSemaphores[i]) != VK_SUCCESS ||
        vkCreateFence(device, &fenceInfo, nullptr, &computeInFlightFences[i]) != VK_SUCCESS) {
        throw std::runtime_error("failed to create compute synchronization objects for a frame!");
    }
}

```

We then use these to synchronize the compute buffer submission with the graphics submission:

```c
// Compute submission
vkWaitForFences(device, 1, &computeInFlightFences[currentFrame], VK_TRUE, UINT64_MAX);

updateUniformBuffer(currentFrame);

vkResetFences(device, 1, &computeInFlightFences[currentFrame]);

vkResetCommandBuffer(computeCommandBuffers[currentFrame], /*VkCommandBufferResetFlagBits*/ 0);
recordComputeCommandBuffer(computeCommandBuffers[currentFrame]);

submitInfo.commandBufferCount = 1;
submitInfo.pCommandBuffers = &computeCommandBuffers[currentFrame];
submitInfo.signalSemaphoreCount = 1;
submitInfo.pSignalSemaphores = &computeFinishedSemaphores[currentFrame];

if (vkQueueSubmit(computeQueue, 1, &submitInfo, computeInFlightFences[currentFrame]) != VK_SUCCESS) {
    throw std::runtime_error("failed to submit compute command buffer!");
};

// Graphics submission
vkWaitForFences(device, 1, &inFlightFences[currentFrame], VK_TRUE, UINT64_MAX);

...

vkResetFences(device, 1, &inFlightFences[currentFrame]);

vkResetCommandBuffer(commandBuffers[currentFrame], /*VkCommandBufferResetFlagBits*/ 0);
recordCommandBuffer(commandBuffers[currentFrame], imageIndex);

VkSemaphore waitSemaphores[] = { computeFinishedSemaphores[currentFrame], imageAvailableSemaphores[currentFrame] };
VkPipelineStageFlags waitStages[] = { VK_PIPELINE_STAGE_VERTEX_INPUT_BIT, VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT };
submitInfo = {};
submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;

submitInfo.waitSemaphoreCount = 2;
submitInfo.pWaitSemaphores = waitSemaphores;
submitInfo.pWaitDstStageMask = waitStages;
submitInfo.commandBufferCount = 1;
submitInfo.pCommandBuffers = &commandBuffers[currentFrame];
submitInfo.signalSemaphoreCount = 1;
submitInfo.pSignalSemaphores = &renderFinishedSemaphores[currentFrame];

if (vkQueueSubmit(graphicsQueue, 1, &submitInfo, inFlightFences[currentFrame]) != VK_SUCCESS) {
    throw std::runtime_error("failed to submit draw command buffer!");
}

```

Similar to the sample in the [semaphores chapter](https://vulkan-tutorial.com/Drawing_a_triangle/Drawing/Rendering_and_presentation#page_Semaphores), this setup will immediately run the compute shader as we haven't specified any wait semaphores. This is fine, as we are waiting for the compute command buffer of the current frame to finish execution before the compute submission with the [`vkWaitForFences`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkWaitForFences.html) command.

The graphics submission on the other hand needs to wait for the compute work to finish so it doesn't start fetching vertices while the compute buffer is still updating them. So we wait on the `computeFinishedSemaphores` for the current frame and have the graphics submission wait on the `VK_PIPELINE_STAGE_VERTEX_INPUT_BIT` stage, where vertices are consumed.

But it also needs to wait for presentation so the fragment shader won't output to the color attachments until the image has been presented. So we also wait on the `imageAvailableSemaphores` on the current frame at the `VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT` stage.

# Drawing the particle system

Earlier on, we learned that buffers in Vulkan can have multiple use-cases and so we created the shader storage buffer that contains our particles with both the shader storage buffer bit and the vertex buffer bit. This means that we can use the shader storage buffer for drawing just as we used "pure" vertex buffers in the previous chapters.

We first setup the vertex input state to match our particle structure:

```c
struct Particle {
    ...

    static std::array<VkVertexInputAttributeDescription, 2> getAttributeDescriptions() {
        std::array<VkVertexInputAttributeDescription, 2> attributeDescriptions{};

        attributeDescriptions[0].binding = 0;
        attributeDescriptions[0].location = 0;
        attributeDescriptions[0].format = VK_FORMAT_R32G32_SFLOAT;
        attributeDescriptions[0].offset = offsetof(Particle, position);

        attributeDescriptions[1].binding = 0;
        attributeDescriptions[1].location = 1;
        attributeDescriptions[1].format = VK_FORMAT_R32G32B32A32_SFLOAT;
        attributeDescriptions[1].offset = offsetof(Particle, color);

        return attributeDescriptions;
    }
};

```

Note that we don't add `velocity` to the vertex input attributes, as this is only used by the compute shader.

We then bind and draw it like we would with any vertex buffer:

```c
vkCmdBindVertexBuffers(commandBuffer, 0, 1, &shaderStorageBuffer[currentFrame], offsets);

vkCmdDraw(commandBuffer, PARTICLE_COUNT, 1, 0, 0);

```

# Conclusion

In this chapter, we learned how to use compute shaders to offload work from the CPU to the GPU. Without compute shaders, many effects in modern games and applications would either not be possible or would run a lot slower. But even more than graphics, compute has a lot of use-cases, and this chapter only gives you a glimpse of what's possible. So now that you know how to use compute shaders, you may want to take look at some advanced compute topics like:

- Shared memory
- [Asynchronous compute](https://github.com/KhronosGroup/Vulkan-Samples/tree/master/samples/performance/async_compute)
- Atomic operations
- [Subgroups](https://www.khronos.org/blog/vulkan-subgroup-tutorial)

You can find some advanced compute samples in the [official Khronos Vulkan Samples repository](https://github.com/KhronosGroup/Vulkan-Samples/tree/master/samples/api).

[C++ code](https://vulkan-tutorial.com/code/31_compute_shader.cpp) / [Vertex shader](https://vulkan-tutorial.com/code/31_shader_compute.vert) / [Fragment shader](https://vulkan-tutorial.com/code/31_shader_compute.frag) / [Compute shader](https://vulkan-tutorial.com/code/31_shader_compute.comp)