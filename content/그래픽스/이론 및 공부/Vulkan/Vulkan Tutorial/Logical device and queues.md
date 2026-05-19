# Logical device and queues

# Introduction

![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Logical device and queues/image.png]]

physical device를 연결하는 인터페이스로 logical device를 설정해야 한다.

logical device를 생성 프로세스는 instance를 만드는 방법과 유사하다. 추가로 어떤 queue Family(명령어 모음집)를 사용할 것인지 정해야 한다. 요구 사항이 다양하다면 동일한 물리적 장치에서 여러 논리적 장치를 생성할 수도 있습니다. 

논리적 장치 핸들을 저장할 새 클래스 멤버를 추가하여 시작합니다.

```c
VkDevice device;
```

다음으로 `initVulkan`에서 호출되는 `createLogicalDevice` 함수를 추가합니다.

```c
void initVulkan() {
    createInstance();
    setupDebugMessenger();
    pickPhysicalDevice();
    createLogicalDevice();
}

void createLogicalDevice() {

}
```

# Specifying the queues to be created(생성할 큐 지정)

논리적 장치를 생성하려면 구조체에 여러 세부 정보를 지정해야 하는데, 그 중 첫 번째는 `VkDeviceQueueCreateInfo`입니다. 이 구조는 단일 queuefamily에 필요한 큐의 수를 설명합니다. 그래픽 그래픽 기능만 있는 큐에 집중한다.

```cpp
QueueFamilyIndices indices = findQueueFamilies(physicalDevice);

VkDeviceQueueCreateInfo queueCreateInfo{};
queueCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
queueCreateInfo.queueFamilyIndex = indices.graphicsFamily.value();
queueCreateInfo.queueCount = 1;
```

현재 사용 가능한 드라이버는 각 queuefamily에 대해 적은 수의 큐만 생성할 수 있으며, 실제로는 그 이상의 큐가 필요하지 않습니다. 

여러 스레드에 모든 명령 버퍼를 만든 다음 오버헤드가 적은 호출 한 번으로 메인 스레드에서 한 번에 모두 제출할 수 있기 때문입니다.

Vulkan을 사용하면 `0.0`~`1.0` 사이의 부동 소수점 숫자를 사용하여 큐에 우선 순위를 지정하여 명령 버퍼 실행 스케줄링에 영향을 미칠 수 있습니다.

큐가 1개여도 필요합니다.

```c
float queuePriority = 1.0f;
queueCreateInfo.pQueuePriorities = &queuePriority;
```

# Specifying used device features(사용된 장치 기능 지정)

다음으로 지정할 정보는 우리가 사용할 디바이스 기능 세트입니다. 

이는 지오메트리 셰이더와 같이 이전 장에서 `vkGetPhysicalDeviceFeatures`로 지원을 요청한 기능입니다. 

지금은 특별한 것이 필요하지 않으므로 간단히 정의하고 모든 것을 `VK_FALSE`에 맡기면 됩니다. 벌칸으로 더 흥미로운 작업을 시작하게 되면 이 구조로 다시 돌아올 것입니다.

```c
VkPhysicalDeviceFeatures deviceFeatures{};
```

# Creating the logical device(논리적 장치 만들기)

이전 두 structures가 제자리에 있으면 `VkDeviceCreateInfo`주요 구조를 채우기 시작할 수 있습니다.

```c
VkDeviceCreateInfo createInfo{};
createInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
```

먼저 큐 생성 정보 및 장치 기능 구조체에 대한 포인터를 추가합니다.

```c
createInfo.pQueueCreateInfos = &queueCreateInfo;
createInfo.queueCreateInfoCount = 1;
createInfo.pEnabledFeatures = &deviceFeatures;
```

나머지 정보는 `VkInstanceCreateInfo`구조체와 유사하며 확장 및 유효성 검사 계층을 지정해야 합니다. 차이점은 이번에는 장치별로 다르다는 것입니다.

디바이스별 확장 기능의 예로는 해당 디바이스에서 렌더링된 이미지를 창에 표시할 수 있는 `VK_KHR_swapchain`이 있습니다. 예를 들어 컴퓨팅 연산만 지원하기 때문에 이 기능이 없는 Vulkan 디바이스가 시스템에 있을 수 있습니다. 스왑 체인 챕터에서 이 확장 기능에 대해 다시 살펴보겠습니다.

이전 버전의 vulkan 구현에서는 인스턴스와 디바이스별 유효성 검사 레이어를 구분했지만 [더 이상 그렇지 않습니다.](https://www.khronos.org/registry/vulkan/specs/1.3-extensions/html/chap40.html#extendingvulkan-layers-devicelayerdeprecation) 즉, 최신 구현에서는 `VkDeviceCreateInfo`의 `enabledLayerCount` 및 `ppEnabledLayerNames`필드가 무시됩니다. 그러나 이전 구현과 호환되도록 어쨌든 설정하는 것이 좋습니다:

```c
createInfo.enabledExtensionCount = 0;

if (enableValidationLayers) {
    createInfo.enabledLayerCount = static_cast<uint32_t>(validationLayers.size());
    createInfo.ppEnabledLayerNames = validationLayers.data();
} else {
    createInfo.enabledLayerCount = 0;
}

```

지금은 장치 별 확장이 필요하지 않습니다.

이제 적절하게 명명된 `vkCreateDevice`함수를 호출하여 논리적 장치를 인스턴스화할 준비가 되었습니다.

```c
if (vkCreateDevice(physicalDevice, &createInfo, nullptr, &device) != VK_SUCCESS) {
    throw std::runtime_error("failed to create logical device!");
}

```

매개변수는 인터페이스할 물리적 장치, 방금 지정한 큐 및 사용 정보, 선택적 할당 콜백 포인터, 논리적 장치 핸들을 저장할 변수에 대한 포인터입니다. 

인스턴스 생성 함수와 마찬가지로 이 호출은 존재하지 않는 확장을 활성화하거나 지원되지 않는 기능의 원하는 사용을 지정하는 것에 따라 오류를 반환할 수 있습니다.

`vkDestroyDevice`함수를 사용하여 정리할 때 장치를 파괴해야 합니다.

```c
void cleanup() {
    vkDestroyDevice(device, nullptr);
    ...
}

```

# Retrieving queue handles(큐 핸들 검색)

큐는 논리적 장치와 함께 자동으로 생성되지만 아직 인터페이스 할 핸들이 없습니다. 먼저 그래픽 큐에 핸들을 저장할 클래스 멤버를 추가합니다.

```cpp
VkQueue graphicsQueue;
```

장치가 파괴되면 장치 큐가 암묵적으로 정리되므로 `cleanup`할 필요가 없습니다.

`vkGetDeviceQueue` 함수를 사용하여 각 queuefamily에 대한 큐 핸들을 검색할 수 있습니다. 매개변수는 논리적 장치, queuefamily, 큐 인덱스 및 큐 핸들을 저장할 변수에 대한 포인터입니다. 이 패밀리에서 단일 큐만 생성하므로 인덱스 0을 사용합니다.

```c
vkGetDeviceQueue(device, indices.graphicsFamily.value(), 0, &graphicsQueue);
```

논리적 장치와 큐 핸들을 사용하면 이제 그래픽 카드를 사용하여 작업을 시작할 수 있습니다! 다음 몇 장에서는 결과를 창 시스템에 표시하기 위한 리소스를 설정합니다.