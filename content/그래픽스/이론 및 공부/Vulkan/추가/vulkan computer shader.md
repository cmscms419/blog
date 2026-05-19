---
title: "컴퓨트 셰이더 - Vulkan 튜토리얼"
source: "https://vulkan-tutorial.com/Compute_Shader"
author:
  - "[[Alexander Overvoorde]]"
published:
created: 2025-07-14
description: "A tutorial that teaches you everything it takes to render 3D graphics with the Vulkan API. It covers everything from Windows/Linux setup to rendering and debugging."
tags:
  - "clippings"
---

## 소개

이 보너스 챕터에서는 컴퓨트 셰이더에 대해 살펴보겠습니다. 지금까지 모든 챕터에서는 Vulkan 파이프라인의 기존 그래픽 부분을 다루었습니다. 하지만 OpenGL과 같은 기존 API와 달리 Vulkan에서는 컴퓨트 셰이더 지원이 필수적입니다. 즉, 고성능 데스크톱 GPU든 저전력 임베디드 기기든 사용 가능한 모든 Vulkan 구현에서 컴퓨트 셰이더를 사용할 수 있습니다.

이를 통해 애플리케이션이 어디에서 실행되든 그래픽 프로세서 유닛(GPGPU)에서 범용 컴퓨팅의 세계가 열립니다. GPGPU는 기존에는 CPU의 영역이었던 일반 연산을 GPU에서 수행할 수 있음을 의미합니다. 하지만 GPU가 점점 더 강력해지고 유연해짐에 따라, CPU의 범용 기능을 필요로 하는 많은 워크로드를 이제 GPU에서 실시간으로 처리할 수 있습니다.

GPU의 컴퓨팅 기능을 활용할 수 있는 몇 가지 예로는 이미지 조작, 가시성 테스트, 후처리, 고급 조명 계산, 애니메이션, 물리 연산(예: 파티클 시스템) 등이 있습니다. 그래픽 출력이 필요 없는 비시각적 컴퓨팅 전용 작업(예: 수치 처리 또는 AI 관련 작업)에도 컴퓨팅을 사용할 수 있습니다. 이를 "헤드리스 컴퓨팅"이라고 합니다.

## 장점

GPU에서 계산량이 많은 계산을 수행하면 여러 가지 장점이 있습니다. 가장 분명한 장점은 CPU의 작업 부담을 덜어준다는 것입니다. 또 다른 장점은 CPU의 메인 메모리와 GPU 메모리 간에 데이터를 이동할 필요가 없다는 것입니다. 모든 데이터는 메인 메모리에서 느린 전송을 기다릴 필요 없이 GPU에 저장될 수 있습니다.

이 외에도 GPU는 고도로 병렬화되어 있으며, 그중 일부는 수만 개의 작은 연산 유닛을 가지고 있습니다. 따라서 GPU는 몇 개의 대형 연산 유닛을 가진 CPU보다 고도로 병렬화된 워크플로에 더 적합합니다.

## Vulkan 파이프라인

파이프라인의 그래픽 부분과 컴퓨팅 부분이 완전히 분리되어 있다는 점을 아는 것이 중요합니다. 이는 공식 사양에 나와 있는 Vulkan 파이프라인의 다음 블록 다이어그램에서 확인할 수 있습니다.

![](attachments/vulkan_pipeline_block_diagram.png)

이 다이어그램에서 왼쪽에는 파이프라인의 기존 그래픽 부분이, 오른쪽에는 이 그래픽 파이프라인에 포함되지 않은 여러 단계(컴퓨트 셰이더(스테이지) 포함)가 표시됩니다. 컴퓨트 셰이더 스테이지가 그래픽 파이프라인에서 분리됨에 따라 원하는 곳 어디에서나 사용할 수 있습니다. 이는 버텍스 셰이더의 변환된 출력에 항상 적용되는 프래그먼트 셰이더와는 매우 다릅니다.

다이어그램의 중앙은 설명자 집합이 컴퓨팅에서도 사용된다는 것을 보여줍니다. 따라서 설명자 레이아웃, 설명자 집합 및 설명자에 대해 배운 모든 내용이 여기에도 적용됩니다.

## 예를 들어

이 장에서 구현할 이해하기 쉬운 예로 GPU 기반 파티클 시스템을 들 수 있습니다. 이러한 시스템은 많은 게임에서 사용되며, 상호작용하는 프레임 속도로 업데이트되어야 하는 수천 개의 파티클로 구성되는 경우가 많습니다. 이러한 시스템을 렌더링하려면 두 가지 주요 구성 요소가 필요합니다. 정점 버퍼로 전달되는 정점과 특정 방정식을 기반으로 정점을 업데이트하는 방법입니다.

"고전적인" CPU 기반 파티클 시스템은 파티클 데이터를 시스템의 주 메모리에 저장한 다음 CPU를 사용하여 업데이트합니다. 업데이트 후에는 정점을 다시 GPU 메모리로 전송하여 다음 프레임에 업데이트된 파티클을 표시해야 합니다. 가장 간단한 방법은 각 프레임마다 새로운 데이터로 정점 버퍼를 재생성하는 것입니다. 이는 당연히 비용이 많이 듭니다. 구현 방식에 따라 CPU에서 쓸 수 있도록 GPU 메모리를 매핑하는 방법(데스크톱 시스템에서는 "크기 조정 가능한 BAR", 통합 GPU에서는 통합 메모리라고 함)이나 호스트 로컬 버퍼를 사용하는 방법(PCI-E 대역폭으로 인해 가장 느린 방법) 등 다른 옵션도 있습니다. 하지만 어떤 버퍼 업데이트 방법을 선택하든 파티클을 업데이트하려면 항상 CPU와의 "왕복"이 필요합니다.

GPU 기반 파티클 시스템에서는 이러한 왕복 작업이 더 이상 필요하지 않습니다. 정점은 시작 시에만 GPU에 업로드되며, 모든 업데이트는 컴퓨트 셰이더를 사용하여 GPU 메모리에서 수행됩니다. 이 방식이 더 빠른 주요 이유 중 하나는 GPU와 로컬 메모리 간의 대역폭이 훨씬 더 높기 때문입니다. CPU 기반 시나리오에서는 메인 메모리와 PCI-Express 대역폭의 제약을 받는데, 이는 종종 GPU 메모리 대역폭의 극히 일부에 불과합니다.

전용 컴퓨트 큐가 있는 GPU에서 이 작업을 수행하면 그래픽 파이프라인의 렌더링 부분과 병렬로 파티클을 업데이트할 수 있습니다. 이를 "비동기 컴퓨트"라고 하며, 이 튜토리얼에서는 다루지 않는 고급 주제입니다.

이 장의 코드 스크린샷은 다음과 같습니다. 여기에 표시된 파티클은 CPU와의 상호 작용 없이 GPU에서 직접 컴퓨트 셰이더에 의해 업데이트됩니다.

![](attachments/compute_shader_particles.png)

## 데이터 조작

이 튜토리얼에서는 프리미티브를 전달하는 데 사용되는 버텍스 및 인덱스 버퍼와 셰이더에 데이터를 전달하는 유니폼 버퍼 등 다양한 버퍼 유형에 대해 이미 알아보았습니다. 또한 이미지를 사용하여 텍스처 매핑을 수행했습니다. 하지만 지금까지는 항상 CPU를 사용하여 데이터를 쓰고 GPU에서는 읽기만 수행했습니다.

**컴퓨트 셰이더에서 도입된 중요한 개념 중 하나는 버퍼 를 임의로 읽고 쓸** 수 있는 기능입니다 . 이를 위해 Vulkan은 두 가지 전용 스토리지 유형을 제공합니다.

### 셰이더 저장 버퍼 객체(SSBO)

셰이더 저장 버퍼(SSBO)를 사용하면 셰이더가 버퍼를 읽고 쓸 수 있습니다. SSBO를 사용하는 것은 균일 버퍼 객체를 사용하는 것과 유사합니다. 가장 큰 차이점은 다른 버퍼 유형을 SSBO로 별칭 지정할 수 있고, SSBO의 크기를 임의로 지정할 수 있다는 것입니다.

GPU 기반 파티클 시스템으로 돌아가면, 컴퓨트 셰이더가 정점을 업데이트(쓰기)하고 정점 셰이더가 정점을 읽(그리기)하는 방식을 어떻게 처리해야 할지 궁금할 것입니다. 두 가지 사용 방식 모두 서로 다른 버퍼 유형을 필요로 하기 때문입니다.

하지만 그렇지 않습니다. Vulkan에서는 버퍼와 이미지에 대해 여러 가지 용도를 지정할 수 있습니다. 따라서 파티클 버텍스 버퍼를 버텍스 버퍼(그래픽 패스)와 스토리지 버퍼(컴퓨트 패스)로 사용하려면 다음 두 가지 용도 플래그를 사용하여 버퍼를 생성하기만 하면 됩니다.

```cpp
VkBufferCreateInfo bufferInfo{};
...
bufferInfo.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
...

if (vkCreateBuffer(device, &bufferInfo, nullptr, &shaderStorageBuffers[i]) != VK_SUCCESS) {
    throw std::runtime_error("failed to create vertex buffer!");
}
```

두 플래그 `VK_BUFFER_USAGE_VERTEX_BUFFER_BIT` 와 `VK_BUFFER_USAGE_STORAGE_BUFFER_BIT` set은 `bufferInfo.usage` 이 버퍼를 두 가지 다른 시나리오, 즉 버텍스 셰이더의 **버텍스 버퍼와 스토어 버퍼**로 사용하고자 한다는 것을 구현에 알려줍니다. 
`VK_BUFFER_USAGE_TRANSFER_DST_BIT` 호스트에서 GPU로 데이터를 전송할 수 있도록 플래그도 추가했습니다. 셰이더 스토리지 버퍼는 GPU 메모리에만 유지되어야 하므로( `VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT`) 호스트에서 이 버퍼로 데이터를 전송해야 하므로 이 플래그가 매우 중요합니다.

도우미 함수를 사용한 동일한 코드는 다음과 같습니다 `createBuffer`.

```cpp
createBuffer(bufferSize, VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, shaderStorageBuffers[i], shaderStorageBuffersMemory[i]);
```

이러한 버퍼에 접근하기 위한 GLSL 셰이더 선언은 다음과 같습니다.

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

이 예제에서는 각 파티클에 위치와 속도 값이 있는 타입화된 SSBO가 있습니다(구조체 참조 `Particle`). SSBO는 로 표시된 대로 제한되지 않은 개수의 파티클을 포함합니다 `[]`. SSBO에서 요소 수를 지정할 필요가 없다는 것은 예를 들어 균일 버퍼에 비해 장점 중 하나입니다. `std140` 는 셰이더 저장 버퍼의 멤버 요소가 메모리에서 어떻게 정렬되는지를 결정하는 메모리 레이아웃 한정자입니다. 이를 통해 호스트와 GPU 간에 버퍼를 매핑하는 데 필요한 특정 보장을 얻을 수 있습니다.

컴퓨트 셰이더에서 이러한 저장 버퍼 객체에 쓰는 것은 간단하고 C++ 측에서 버퍼에 쓰는 방법과 비슷합니다.

```glsl
particlesOut[index].position = particlesIn[index].position + particlesIn[index].velocity.xy * ubo.deltaTime;
```

### 저장 이미지

*이 장에서는 이미지 조작은 다루지 않습니다. 이 단락은 컴퓨트 셰이더를 이미지 조작에도 사용할 수 있다는 점을 독자들에게 알리기 위해 작성되었습니다.*

저장 이미지를 사용하면 이미지를 읽고 쓸 수 있습니다. 일반적인 사용 사례로는 텍스처에 이미지 효과를 적용하거나, 후처리(매우 유사)를 수행하거나, 밉맵을 생성하는 것이 있습니다.

이는 이미지에도 유사합니다.

```cpp
VkImageCreateInfo imageInfo {};
...
imageInfo.usage = VK_IMAGE_USAGE_SAMPLED_BIT | VK_IMAGE_USAGE_STORAGE_BIT;
...

if (vkCreateImage(device, &imageInfo, nullptr, &textureImage) != VK_SUCCESS) {
    throw std::runtime_error("failed to create image!");
}
```

두 플래그 `VK_IMAGE_USAGE_SAMPLED_BIT` 와 `VK_IMAGE_USAGE_STORAGE_BIT` set은 `imageInfo.usage` 구현에서 이 이미지를 두 가지 다른 시나리오, 
즉 프래그먼트 셰이더에서 샘플링된 이미지와 컴퓨터 셰이더의 저장 이미지로 사용하고자 한다는 것을 알려줍니다.

저장 이미지에 대한 GLSL 셰이더 선언은 예를 들어 프래그먼트 셰이더에서 사용되는 샘플링된 이미지와 유사합니다.

```glsl
layout (binding = 0, rgba8) uniform readonly image2D inputImage;
layout (binding = 1, rgba8) uniform writeonly image2D outputImage;
```

여기서 몇 가지 차이점은 `rgba8` 이미지 형식과 관련된 추가 속성, `readonly` 그리고 `writeonly` 한정자입니다. 이는 구현 시 입력 이미지에서 읽기만 하고 출력 이미지에는 쓰기만 하도록 지정합니다. 마지막으로, `image2D` 저장 이미지를 선언하기 위해 type을 사용해야 합니다.

그런 다음 컴퓨트 셰이더에서 저장 이미지를 읽고 쓰는 작업은 `imageLoad` 및 를 사용하여 수행됩니다 `imageStore`.

```glsl
vec3 pixel = imageLoad(inputImage, ivec2(gl_GlobalInvocationID.xy)).rgb;
imageStore(outputImage, ivec2(gl_GlobalInvocationID.xy), pixel);
```

## 큐 패밀리 계산

[물리적 장치 및 대기열 패밀리 장](https://vulkan-tutorial.com/Drawing_a_triangle/Setup/Physical_devices_and_queue_families#page_Queue-families) 에서 대기열 패밀리와 그래픽 대기열 패밀리를 선택하는 방법에 대해 이미 알아보았습니다. 컴퓨트는 대기열 패밀리 속성 플래그 비트를 사용합니다 `VK_QUEUE_COMPUTE_BIT`. 따라서 컴퓨트 작업을 수행하려면 컴퓨트를 지원하는 대기열 패밀리에서 대기열을 가져와야 합니다.

Vulkan은 그래픽 작업을 지원하는 구현체에 그래픽 작업과 컴퓨팅 작업을 모두 지원하는 큐 패밀리가 최소 하나 이상 있어야 한다는 점에 유의해야 합니다. 하지만 구현체에서 전용 컴퓨팅 큐를 제공할 수도 있습니다. 이 전용 컴퓨팅 큐(그래픽 관련 내용은 없음)는 비동기 컴퓨팅 큐를 암시합니다. 하지만 이 튜토리얼에서는 초보자도 쉽게 이해할 수 있도록 그래픽 작업과 컴퓨팅 작업을 모두 수행할 수 있는 큐를 사용하겠습니다. 이렇게 하면 여러 고급 동기화 메커니즘을 다루지 않아도 됩니다.

우리의 컴퓨팅 샘플에서는 장치 생성 코드를 약간 변경해야 합니다.

```cpp
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

변경된 대기열 패밀리 인덱스 선택 코드는 이제 그래픽과 컴퓨팅을 모두 지원하는 대기열 패밀리를 찾으려고 시도합니다.

그러면 다음에서 이 대기열 패밀리로부터 컴퓨팅 대기열을 얻을 수 있습니다 `createLogicalDevice`.

```cpp
vkGetDeviceQueue(device, indices.graphicsAndComputeFamily.value(), 0, &computeQueue);
```

## 컴퓨트 셰이더 단계

그래픽 샘플에서는 셰이더를 로드하고 디스크립터에 접근하기 위해 다양한 파이프라인 단계를 사용했습니다. 컴퓨트 셰이더는 `VK_SHADER_STAGE_COMPUTE_BIT` 파이프라인을 통해 유사한 방식으로 접근합니다. 따라서 컴퓨트 셰이더를 로드하는 것은 정점 셰이더를 로드하는 것과 동일하지만, 셰이더 단계가 다릅니다. 다음 단락에서 이에 대해 자세히 설명하겠습니다. 또한 컴퓨트는 디스크립터와 파이프라인에 대한 새로운 바인딩 포인트 유형을 도입하는데, `VK_PIPELINE_BIND_POINT_COMPUTE` 이는 나중에 사용해야 합니다.

애플리케이션에 컴퓨트 셰이더를 로드하는 것은 다른 셰이더를 로드하는 것과 동일합니다. 유일한 차이점은 `VK_SHADER_STAGE_COMPUTE_BIT` 위에서 언급한 셰이더를 사용해야 한다는 것입니다.

```cpp
auto computeShaderCode = readFile("shaders/compute.spv");

VkShaderModule computeShaderModule = createShaderModule(computeShaderCode);

VkPipelineShaderStageCreateInfo computeShaderStageInfo{};
computeShaderStageInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
computeShaderStageInfo.stage = VK_SHADER_STAGE_COMPUTE_BIT;
computeShaderStageInfo.module = computeShaderModule;
computeShaderStageInfo.pName = "main";
...
```

## 셰이더 저장 버퍼 준비

앞서 셰이더 저장 버퍼를 사용하여 임의의 데이터를 컴퓨트 셰이더에 전달할 수 있다는 것을 배웠습니다. 이 예제에서는 GPU에 파티클 배열을 업로드하여 GPU 메모리에서 직접 조작할 수 있도록 하겠습니다.

[프레임 실행](https://vulkan-tutorial.com/Drawing_a_triangle/Drawing/Frames_in_flight) 챕터 에서 CPU와 GPU를 계속 사용할 수 있도록 프레임마다 리소스를 복제하는 방법에 대해 설명했습니다. 먼저 버퍼 객체와 이를 백업하는 장치 메모리 벡터를 선언합니다.

```cpp
std::vector<VkBuffer> shaderStorageBuffers;
std::vector<VkDeviceMemory> shaderStorageBuffersMemory;
```

그런 `createShaderStorageBuffers` 다음 비행 중 최대 프레임 수에 맞게 벡터 크기를 조정합니다.

```cpp
shaderStorageBuffers.resize(MAX_FRAMES_IN_FLIGHT);
shaderStorageBuffersMemory.resize(MAX_FRAMES_IN_FLIGHT);
```

이 설정을 완료하면 초기 파티클 정보를 GPU로 옮길 수 있습니다. 먼저 호스트 측에서 파티클 벡터를 초기화합니다.

```cpp
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

그런 다음 호스트의 메모리에 [스테이징 버퍼를](https://vulkan-tutorial.com/Vertex_buffers/Staging_buffer) 생성하여 초기 입자 속성을 보관합니다.

```cpp
VkDeviceSize bufferSize = sizeof(Particle) * PARTICLE_COUNT;

    VkBuffer stagingBuffer;
    VkDeviceMemory stagingBufferMemory;
    createBuffer(bufferSize, VK_BUFFER_USAGE_TRANSFER_SRC_BIT, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, stagingBuffer, stagingBufferMemory);

    void* data;
    vkMapMemory(device, stagingBufferMemory, 0, bufferSize, 0, &data);
    memcpy(data, particles.data(), (size_t)bufferSize);
    vkUnmapMemory(device, stagingBufferMemory);
```

이 스테이징 버퍼를 소스로 사용하여 프레임당 셰이더 저장 버퍼를 생성하고 스테이징 버퍼에서 다음 각각으로 입자 속성을 복사합니다.

```cpp
for (size_t i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
        createBuffer(bufferSize, VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, shaderStorageBuffers[i], shaderStorageBuffersMemory[i]);
        // Copy data from the staging buffer (host) to the shader storage buffer (GPU)
        copyBuffer(stagingBuffer, shaderStorageBuffers[i], bufferSize);
    }
}
```

## 설명자

`VK_SHADER_STAGE_COMPUTE_BIT` 컴퓨팅을 위한 설명자 설정은 그래픽 설정과 거의 동일합니다. 유일한 차이점은 컴퓨팅 단계에서 설명자에 접근할 수 있도록 설정해야 한다는 것입니다.

```cpp
std::array<VkDescriptorSetLayoutBinding, 3> layoutBindings{};
layoutBindings[0].binding = 0;
layoutBindings[0].descriptorCount = 1;
layoutBindings[0].descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
layoutBindings[0].pImmutableSamplers = nullptr;
layoutBindings[0].stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;
...
```

여기서는 셰이더 단계를 결합할 수 있습니다. 즉, 정점과 계산 단계에서 설명자에 액세스할 수 있도록 하려는 경우(예: 매개변수가 두 단계에서 공유되는 균일 버퍼의 경우) 두 단계에 대한 비트를 설정하기만 하면 됩니다.

```cpp
layoutBindings[0].stageFlags = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_COMPUTE_BIT;
```

샘플의 설명자 설정은 다음과 같습니다. 레이아웃은 다음과 같습니다.

```cpp
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

이 설정을 보면, 하나의 파티클 시스템만 렌더링하는데도 셰이더 저장 버퍼 객체에 레이아웃 바인딩을 두 개 사용하는 이유가 궁금할 수 있습니다. 파티클 위치가 델타 시간을 기준으로 프레임별로 업데이트되기 때문입니다. 즉, 각 프레임은 마지막 프레임의 파티클 위치를 알아야 하므로, 새로운 델타 시간으로 업데이트하고 자체 SSBO에 기록할 수 있습니다.

![](attachments/compute_ssbo_read_write.svg)

이를 위해 컴퓨트 셰이더는 마지막 프레임과 현재 프레임의 SSBO에 접근할 수 있어야 합니다. 이는 디스크립터 설정에서 두 프레임을 모두 컴퓨트 셰이더에 전달하여 수행됩니다. 및 를 참조 `storageBufferInfoLastFrame` 하세요 `storageBufferInfoCurrentFrame`.

```cpp
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
    descriptorWrites[1].pBufferInfo = & ;

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

SSBO에 대한 설명자 유형도 설명자 풀에서 요청해야 한다는 점을 기억하세요.

```cpp
std::array<VkDescriptorPoolSize, 2> poolSizes{};
...

poolSizes[1].type = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
poolSizes[1].descriptorCount = static_cast<uint32_t>(MAX_FRAMES_IN_FLIGHT) * 2;
```

`VK_DESCRIPTOR_TYPE_STORAGE_BUFFER` 마지막 프레임과 현재 프레임의 SSBO를 참조하는 세트이기 때문에 풀에서 요청하는 유형 의 수를 두 배로 늘려야 합니다.

## 파이프라인을 계산합니다

컴퓨트는 그래픽 파이프라인의 일부가 아니므로 를 사용할 수 없습니다 [`vkCreateGraphicsPipelines`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCreateGraphicsPipelines.html). 대신 컴퓨트 명령을 실행하기 위한 전용 컴퓨트 파이프라인을 만들어야 합니다 [`vkCreateComputePipelines`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCreateComputePipelines.html). 컴퓨트 파이프라인은 래스터화 상태에 영향을 미치지 않으므로 그래픽 파이프라인보다 상태가 훨씬 적습니다.

```cpp
VkComputePipelineCreateInfo pipelineInfo{};
pipelineInfo.sType = VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO;
pipelineInfo.layout = computePipelineLayout;
pipelineInfo.stage = computeShaderStageInfo;

if (vkCreateComputePipelines(device, VK_NULL_HANDLE, 1, &pipelineInfo, nullptr, &computePipeline) != VK_SUCCESS) {
    throw std::runtime_error("failed to create compute pipeline!");
}
```

셰이더 스테이지 하나와 파이프라인 레이아웃만 필요하므로 설정이 훨씬 간단합니다. 파이프라인 레이아웃은 그래픽 파이프라인과 동일하게 작동합니다.

```cpp
VkPipelineLayoutCreateInfo pipelineLayoutInfo{};
pipelineLayoutInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
pipelineLayoutInfo.setLayoutCount = 1;
pipelineLayoutInfo.pSetLayouts = &computeDescriptorSetLayout;

if (vkCreatePipelineLayout(device, &pipelineLayoutInfo, nullptr, &computePipelineLayout) != VK_SUCCESS) {
    throw std::runtime_error("failed to create compute pipeline layout!");
}
```

## 컴퓨팅 공간

컴퓨트 셰이더의 작동 방식과 GPU에 컴퓨트 워크로드를 제출하는 방법을 살펴보기 전에, 두 가지 중요한 컴퓨트 개념인 **작업 그룹** 과 **호출** 에 대해 알아보겠습니다. 이 두 개념은 GPU의 컴퓨트 하드웨어가 3차원(x, y, z)에서 컴퓨트 워크로드를 처리하는 방식에 대한 추상적인 실행 모델을 정의합니다.

**작업 그룹은** GPU의 컴퓨팅 하드웨어에서 컴퓨팅 워크로드가 어떻게 구성되고 처리되는지를 정의합니다. 작업 그룹은 GPU가 처리해야 하는 작업 항목이라고 생각하면 됩니다. 작업 그룹의 차원은 애플리케이션이 명령 버퍼링 시점에 디스패치 명령을 사용하여 설정합니다.

각 작업 그룹은 동일한 컴퓨트 셰이더를 실행하는 **호출** 들의 집합입니다. 호출들은 잠재적으로 병렬로 실행될 수 있으며, 크기는 컴퓨트 셰이더에 설정됩니다. 단일 작업 그룹 내의 호출들은 공유 메모리에 접근할 수 있습니다.

이 이미지는 이 두 가지 사이의 관계를 3차원에서 보여줍니다.

![](attachments/compute_space.svg)

작업 그룹( 로 정의됨)과 호출의 차원 수는 [`vkCmdDispatch`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdDispatch.html) (컴퓨트 셰이더의 로컬 크기로 정의됨) 입력 데이터의 구조에 따라 달라집니다. 예를 들어 이 장에서처럼 1차원 배열을 작업하는 경우, 두 가지 모두에 대해 x 차원만 지정하면 됩니다.

예를 들어, \[32, 32,,1\]의 컴퓨트 셰이더 로컬 크기를 사용하여 \[64, 1, 1\]의 작업 그룹 수를 전송하는 경우 컴퓨트 셰이더는 64 x 32 x 32 = 65,536번 호출됩니다.

작업 그룹과 로컬 크기 에 대한 최대 개수는 구현마다 다르므로 항상 컴퓨팅 관련 및 제한을 확인 `maxComputeWorkGroupCount` 해야 합니다 .`maxComputeWorkGroupInvocations` `maxComputeWorkGroupSize` [`VkPhysicalDeviceLimits`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPhysicalDeviceLimits.html)

## 컴퓨트 셰이더

컴퓨트 셰이더 파이프라인 설정에 필요한 모든 부분을 살펴보았으니, 이제 컴퓨트 셰이더를 살펴보겠습니다. GLSL 셰이더 사용 방법(예: 버텍스 및 프래그먼트 셰이더)에 대해 배운 모든 내용은 컴퓨트 셰이더에도 적용됩니다. 구문은 동일하며, 애플리케이션과 셰이더 간 데이터 전달과 같은 여러 개념이 동일합니다. 하지만 몇 가지 중요한 차이점이 있습니다.

입자의 선형 배열을 업데이트하기 위한 매우 기본적인 컴퓨트 셰이더는 다음과 같습니다.

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

셰이더의 윗부분에는 셰이더 입력에 대한 선언이 들어 있습니다. 첫 번째는 바인딩 0에 있는 균일 버퍼 객체인데, 이는 이 튜토리얼에서 이미 배웠던 내용입니다. 아래에서는 C++ 코드의 선언과 일치하는 파티클 구조체를 선언합니다. 바인딩 1은 마지막 프레임의 파티클 데이터가 있는 셰이더 저장 버퍼 객체를 참조하고(설명자 설정 참조), 바인딩 2는 현재 프레임의 SSBO(이 셰이더로 업데이트할 프레임)를 가리킵니다.

흥미로운 점은 컴퓨팅 공간과 관련된 이 컴퓨팅 전용 선언입니다.

```glsl
layout (local_size_x = 256, local_size_y = 1, local_size_z = 1) in;
```

이는 현재 작업 그룹에서 이 컴퓨트 셰이더의 호출 횟수를 정의합니다. 앞서 언급했듯이 이는 컴퓨트 공간의 로컬 부분입니다. 따라서 `local_` 접두사가 붙습니다. 선형 1차원 파티클 배열에서 작업할 때는 x 차원에 대한 숫자만 지정하면 됩니다 `local_size_x`.

그런 다음 함수 `main` 는 마지막 프레임의 SSBO에서 읽어 현재 프레임의 SSBO에 업데이트된 파티클 위치를 씁니다. 다른 셰이더 유형과 마찬가지로 컴퓨트 셰이더는 자체 내장 입력 변수 세트를 갖습니다. 내장 변수는 항상 접두사로 붙습니다 `gl_`. 이러한 내장 변수 중 하나는 `gl_GlobalInvocationID` 현재 디스패치에서 현재 컴퓨트 셰이더 호출을 고유하게 식별하는 변수입니다. 이 변수를 사용하여 파티클 배열의 인덱스를 생성합니다.

## 컴퓨트 명령 실행

### 보내다

이제 GPU에 실제로 연산을 수행하도록 지시할 차례입니다. 이는 [`vkCmdDispatch`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdDispatch.html) 명령 버퍼 내부에서 호출하여 수행됩니다. 완벽하게 사실이라고 할 수는 없지만, 디스패치는 [`vkCmdDraw`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdDraw.html) 그래픽에서처럼 그리기 호출과 같은 연산을 위한 것입니다. 디스패치는 최대 3차원에서 주어진 개수의 연산 작업 항목을 디스패치합니다.

```cpp
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

로컬 작업 그룹을 x 차원에서 디스패치 [`vkCmdDispatch`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdDispatch.html) 합니다 `PARTICLE_COUNT / 256`. 파티클 배열이 선형이므로 다른 두 차원을 1로 두어 1차원 디스패치를 생성합니다. 그런데 배열의 파티클 수를 256으로 나누는 이유는 무엇일까요? 이전 단락에서 작업 그룹의 모든 컴퓨트 셰이더가 256번의 호출을 수행한다고 정의했기 때문입니다. 따라서 파티클이 4096개라면 16개의 작업 그룹을 디스패치하고 각 작업 그룹은 256번의 컴퓨트 셰이더 호출을 실행합니다. 두 숫자를 정확하게 구하려면 일반적으로 작업 부하와 실행 중인 하드웨어에 따라 약간의 조정과 프로파일링이 필요합니다. 파티클 크기가 동적이어서 항상 256으로 나눌 수 없는 경우 `gl_GlobalInvocationID` 컴퓨트 셰이더 시작 부분에서 를 사용하고 전역 호출 인덱스가 파티클 수보다 크면 반환할 수 있습니다.

컴퓨트 파이프라인의 경우와 마찬가지로, 컴퓨트 명령 버퍼는 그래픽 명령 버퍼보다 훨씬 적은 상태를 포함합니다. 렌더 패스를 시작하거나 뷰포트를 설정할 필요가 없습니다.

### 작업 제출

샘플에서는 컴퓨팅과 그래픽 작업을 모두 수행하므로 프레임당 그래픽 및 컴퓨팅 대기열에 두 번씩 제출합니다( `drawFrame` 함수 참조).

```cpp
...
if (vkQueueSubmit(computeQueue, 1, &submitInfo, nullptr) != VK_SUCCESS) {
    throw std::runtime_error("failed to submit compute command buffer!");
};
...
if (vkQueueSubmit(graphicsQueue, 1, &submitInfo, inFlightFences[currentFrame]) != VK_SUCCESS) {
    throw std::runtime_error("failed to submit draw command buffer!");
}
```

첫 번째 컴퓨트 큐에 제출하면 컴퓨트 셰이더를 사용하여 입자 위치가 업데이트되고, 두 번째 제출하면 업데이트된 데이터를 사용하여 입자 시스템을 그립니다.

### 그래픽과 컴퓨팅 동기화

동기화는 Vulkan의 중요한 부분이며, 특히 그래픽과 연계된 컴퓨팅 작업을 수행할 때 더욱 중요합니다. 동기화가 잘못되었거나 동기화가 부족하면 컴퓨팅 셰이더가 파티클을 업데이트(쓰기)하지 않은 상태에서 버텍스 스테이지가 파티클을 그리기(읽기) 시작하거나(쓰기 후 읽기 위험), 컴퓨팅 셰이더가 파이프라인의 버텍스 단계에서 아직 사용 중인 파티클을 업데이트하기 시작할 수 있습니다(읽기 후 쓰기 위험).

따라서 그래픽과 컴퓨팅 부하를 적절히 동기화하여 이러한 문제가 발생하지 않도록 해야 합니다. 컴퓨팅 워크로드를 제출하는 방식에 따라 여러 가지 방법이 있지만, 두 개의 별도 제출을 사용하는 이 경우에는 [세마포어](https://vulkan-tutorial.com/Drawing_a_triangle/Drawing/Rendering_and_presentation#page_Semaphores) 와 [펜스를](https://vulkan-tutorial.com/Drawing_a_triangle/Drawing/Rendering_and_presentation#page_Fences) 사용하여 컴퓨팅 셰이더가 정점 업데이트를 완료할 때까지 정점 가져오기를 시작하지 않도록 합니다.

두 제출이 차례로 정렬되어 있더라도 GPU에서 이 순서대로 실행된다는 보장은 없기 때문에 이 과정이 필요합니다. 대기 및 신호 세마포어를 추가하면 이 실행 순서가 보장됩니다.

따라서 먼저 에서 컴퓨팅 작업을 위한 새로운 동기화 기본 요소 집합을 추가합니다 `createSyncObjects`. 그래픽 펜스와 마찬가지로 컴퓨팅 펜스는 신호가 전송된 상태에서 생성됩니다. 그렇지 않으면 펜스가 신호될 때까지 기다리는 동안 첫 번째 그리기가 시간 초과되기 때문입니다. 자세한 내용은 [다음과 같습니다](https://vulkan-tutorial.com/Drawing_a_triangle/Drawing/Rendering_and_presentation#page_Waiting-for-the-previous-frame).

```cpp
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

그런 다음 이를 사용하여 컴퓨팅 버퍼 제출을 그래픽 제출과 동기화합니다.

```cpp
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

[세마포어 챕터](https://vulkan-tutorial.com/Drawing_a_triangle/Drawing/Rendering_and_presentation#page_Semaphores) 의 샘플과 유사하게 , 이 설정은 대기 세마포어를 지정하지 않았으므로 컴퓨트 셰이더를 즉시 실행합니다. 명령을 컴퓨트에 제출하기 전에 현재 프레임의 컴퓨트 명령 버퍼 실행이 완료될 때까지 기다리고 있으므로 이는 문제가 되지 않습니다 [`vkWaitForFences`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkWaitForFences.html).

반면, 그래픽 제출은 컴퓨팅 작업이 완료될 때까지 기다려야 합니다. 그래야 컴퓨팅 버퍼가 정점을 업데이트하는 동안 정점을 가져오지 않습니다. 따라서 `computeFinishedSemaphores` 현재 프레임을 대기하고, 그래픽 제출은 `VK_PIPELINE_STAGE_VERTEX_INPUT_BIT` 정점이 사용되는 스테이지에서 대기합니다.

하지만 이미지가 표시될 때까지 프래그먼트 셰이더가 색상 첨부 파일에 출력하지 않도록 표시될 때까지 기다려야 합니다. 따라서 `imageAvailableSemaphores` 스테이지의 현재 프레임 에서도 대기합니다 `VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT`.

## 입자 시스템 그리기

앞서 Vulkan의 버퍼는 여러 용도로 사용할 수 있다는 것을 배웠습니다. 그래서 셰이더 저장 버퍼 비트와 버텍스 버퍼 비트를 모두 사용하여 파티클을 저장하는 셰이더 저장 버퍼를 만들었습니다. 즉, 이전 장에서 "순수" 버텍스 버퍼를 사용했던 것처럼 셰이더 저장 버퍼를 드로잉에 사용할 수 있습니다.

먼저 입자 구조와 일치하도록 정점 입력 상태를 설정합니다.

```cpp
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

`velocity` 정점 입력 속성에는 추가하지 않는다는 점에 유의하세요. 이는 컴퓨트 셰이더에서만 사용되기 때문입니다.

그런 다음 모든 정점 버퍼와 마찬가지로 바인딩하고 그립니다.

```cpp
vkCmdBindVertexBuffers(commandBuffer, 0, 1, &shaderStorageBuffer[currentFrame], offsets);

vkCmdDraw(commandBuffer, PARTICLE_COUNT, 1, 0, 0);
```

## 결론

이 장에서는 컴퓨트 셰이더를 사용하여 CPU에서 GPU로 작업을 오프로드하는 방법을 알아보았습니다. 컴퓨트 셰이더가 없었다면 현대 게임과 애플리케이션에서 많은 효과를 구현할 수 없었거나 실행 속도가 훨씬 느렸을 것입니다. 하지만 그래픽 외에도 컴퓨트는 다양한 용도로 활용될 수 있으며, 이 장에서는 그 중 일부만 간략하게 소개합니다. 이제 컴퓨트 셰이더 사용법을 알았으니, 다음과 같은 고급 컴퓨트 관련 주제를 살펴보는 것이 좋습니다.

- 공유 메모리
- [비동기 컴퓨팅](https://github.com/KhronosGroup/Vulkan-Samples/tree/master/samples/performance/async_compute)
- 원자 연산
- [하위 그룹](https://www.khronos.org/blog/vulkan-subgroup-tutorial)

[일부 고급 컴퓨팅 샘플은 공식 Khronos Vulkan 샘플 저장소](https://github.com/KhronosGroup/Vulkan-Samples/tree/master/samples/api) 에서 찾을 수 있습니다 .

[C++ 코드](https://vulkan-tutorial.com/code/31_compute_shader.cpp) / [정점 셰이더](https://vulkan-tutorial.com/code/31_shader_compute.vert) / [조각 셰이더](https://vulkan-tutorial.com/code/31_shader_compute.frag) / [계산 셰이더](https://vulkan-tutorial.com/code/31_shader_compute.comp)