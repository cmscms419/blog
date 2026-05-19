# Physical devices and queue families

![[/image.png]]

Physical device는 vulkan에서 사용할 수 있는 장치를 말한다.

# Selecting a physical device

![[/image.png]]

Vulkan 라이브러리를 [`VkInstance`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkInstance.html)를 통해 초기화한 후에는 시스템에서 우리가 필요로 하는 기능을 지원하는 그래픽 카드를 찾아 선택해야 합니다. 

사실 여러 개의 그래픽 카드를 선택하여 동시에 사용할 수도 있지만, 이 튜토리얼에서는 우리의 요구 사항에 맞는 첫 번째 그래픽 카드만 사용하도록 하겠습니다.

`initVulkan`  함수 안에 `pickPhysicalDevice` 함수를 추가

```cpp
void initVulkan() {
    createInstance();
    setupDebugMessenger();
    pickPhysicalDevice();
}

void pickPhysicalDevice() {

}
```

우리가 선택할 그래픽 카드는 새로운 클래스 멤버로 추가되는 [`VkPhysicalDevice`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPhysicalDevice.html) 핸들에 저장될 것입니다. 이 객체는 [`VkInstance`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkInstance.html)가 소멸될 때 암시적으로 함께 소멸되므로, `cleanup` 함수에서 별도의 처리를 할 필요가 없습니다.

```cpp
VkPhysicalDevice physicalDevice = VK_NULL_HANDLE;
```

그래픽 카드를 나열하는 것은 확장 기능을 나열하는 것과 매우 비슷하며 먼저 개수만 확인하는 것으로 시작합니다. →내장 그래픽 또한 감지한다.

```cpp
uint32_t deviceCount = 0;
vkEnumeratePhysicalDevices(instance, &deviceCount, nullptr);
```

```cpp
if (deviceCount == 0) { // vulkan을 지원하는 기기가 없다.
    throw std::runtime_error("failed to find GPUs with Vulkan support!");
}

```

만약, vulkan을 지원하는 기기가 있으면, 이제 모든 [`VkPhysicalDevice`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPhysicalDevice.html) 핸들을 담을 배열을 할당할 수 있습니다.

```cpp
std::vector<VkPhysicalDevice> devices(deviceCount);
vkEnumeratePhysicalDevices(instance, &deviceCount, devices.data());
```

이제 각각의 그래픽 카드들이 우리가 수행하고자 하는 작업에 적합한지 평가하고 확인해야 합니다. 모든 그래픽 카드가 동일한 성능을 가지고 있지는 않기 때문입니다. 이를 위해 새로운 함수를 도입하겠습니다:

```cpp
bool isDeviceSuitable(VkPhysicalDevice device) {
    return true;
}
```

physical devices가 요구 사항을 충족하는지 확인한다.

```c
for (const auto& device : devices) {
    if (isDeviceSuitable(device)) {
        physicalDevice = device;
        break;
    }
}

if (physicalDevice == VK_NULL_HANDLE) {
    throw std::runtime_error("failed to find a suitable GPU!");
}

```

The next section will introduce the first requirements that we'll check for in the `isDeviceSuitable` function. As we'll start using more Vulkan features in the later chapters we will also extend this function to include more checks.

# Base device suitability checks

몇 가지를 쿼리(요청사항)를 만들어야 한다.

- 세부 사항
- 기본 기기 속성 (이름, 유형, 지원되는 vulkan version)

[`vkGetPhysicalDeviceProperties`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkGetPhysicalDeviceProperties.html) 이것을 사용해서 알 수 있다.

디바이스의 적합성을 평가하기 위해 몇 가지 세부 정보를 쿼리하는 것으로 시작할 수 있습니다. 이름, 유형, 지원되는 vulkan 버전과 같은 기본 디바이스 속성은 `vkGetPhysicalDeviceProperties`를 사용하여 쿼리할 수 있습니다.

```cpp
VkPhysicalDeviceProperties deviceProperties;
vkGetPhysicalDeviceProperties(device, &deviceProperties);
```

텍스처 압축, 64비트 부동소수점, 멀티 뷰포트 렌더링(VR에 유용한)과 같은 선택적 기능들의 지원 여부는 [`vkGetPhysicalDeviceFeatures`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkGetPhysicalDeviceFeatures.html)를 사용하여 확인할 수 있습니다:

```cpp
VkPhysicalDeviceFeatures deviceFeatures;
vkGetPhysicalDeviceFeatures(device, &deviceFeatures);
```

디바이스 메모리와 큐 패밀리에 관해서는 나중에 논의할 더 많은 세부 정보를 디바이스로부터 조회할 수 있습니다 (다음 섹션 참조).

예를 들어, 우리의 애플리케이션이 지오메트리 셰이더를 지원하는 전용 그래픽 카드에서만 사용 가능하다고 가정해 봅시다. 그러면 `isDeviceSuitable` 함수는 다음과 같이 작성될 것입니다:

```cpp
bool isDeviceSuitable(VkPhysicalDevice device) {
    VkPhysicalDeviceProperties deviceProperties;
    VkPhysicalDeviceFeatures deviceFeatures;
    vkGetPhysicalDeviceProperties(device, &deviceProperties);
    vkGetPhysicalDeviceFeatures(device, &deviceFeatures);

    return deviceProperties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU &&
           deviceFeatures.geometryShader;
}

```

단순히 디바이스가 적합한지 여부를 확인하고 첫 번째 것을 선택하는 대신, 각 디바이스에 점수를 매기고 가장 높은 점수를 받은 것을 선택할 수도 있습니다. 이렇게 하면 전용 그래픽 카드에 더 높은 점수를 부여하여 우선적으로 선택하되, 전용 카드가 없는 경우 통합 GPU로 대체할 수 있습니다. 다음과 같은 방식으로 구현할 수 있습니다:

```c
#include <map>

...

void pickPhysicalDevice() {
    ...

    // Use an ordered map to automatically sort candidates by increasing score
    std::multimap<int, VkPhysicalDevice> candidates;

    for (const auto& device : devices) {
        int score = rateDeviceSuitability(device);
        candidates.insert(std::make_pair(score, device));
    }

    // Check if the best candidate is suitable at all
    if (candidates.rbegin()->first > 0) {
        physicalDevice = candidates.rbegin()->second;
    } else {
        throw std::runtime_error("failed to find a suitable GPU!");
    }
}

int rateDeviceSuitability(VkPhysicalDevice device) {
    ...

    int score = 0;

    // Discrete GPUs have a significant performance advantage
    if (deviceProperties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
        score += 1000;
    }

    // Maximum possible size of textures affects graphics quality
    score += deviceProperties.limits.maxImageDimension2D;

    // Application can't function without geometry shaders
    if (!deviceFeatures.geometryShader) {
        return 0;
    }

    return score;
}

```

이 튜토리얼에서는 이 모든 것을 구현할 필요는 없지만, 디바이스 선택 프로세스를 어떻게 설계할 수 있는지에 대한 아이디어를 제공하기 위한 것입니다. 물론 선택 가능한 디바이스들의 이름을 표시하고 사용자가 직접 선택하도록 할 수도 있습니다.

우리는 이제 시작 단계이므로 Vulkan을 지원하는 것만이 필요하기 때문에 어떤 GPU든 사용하도록 하겠습니다:

```c
bool isDeviceSuitable(VkPhysicalDevice device) {
    return true;
}

```

In the next section we'll discuss the first real required feature to check for.

# Queue families

![[/image.png]]

drawing부터 uploading textures까지 vulkan의 거의 모든 작업에는 명령어를 큐에 제출해야 한다는 사실은 앞서 간략하게 살펴본 바 있습니다.

![[/image.png]]

다양한 큐 패밀리에 따라 다양한 유형의 큐가 있으며, 각 큐 패밀리는 명령의 하위 집합만 허용합니다.

예를 들어 계산 명령 처리만 허용하는 큐 패밀리가 있거나 메모리 전송 관련 명령만 허용하는 큐 패밀리가 있을 수 있습니다.

장치에서 지원하는 큐 패밀리와 이 중 사용하려는 명령이 지원되는 큐 패밀리를 확인해야 합니다.

이를 위해 필요한 모든 큐 패밀리를 찾는 새로운 함수 `findQueueFamilies`를 추가하겠습니다. 지금은 그래픽 명령을 지원하는 큐만 찾으려고 하므로 함수는 다음과 같이 보일 수 있습니다:

```cpp
uint32_t findQueueFamilies(VkPhysicalDevice device) {
    // Logic to find graphics queue family
}
```

하지만 다음 장 중 하나에서는 또 다른 queue을 찾아볼 예정이므로 그에 대비해 인덱스를 구조체로 묶는 게 좋습니다.

```c
struct QueueFamilyIndices {
    uint32_t graphicsFamily;
};

QueueFamilyIndices findQueueFamilies(VkPhysicalDevice device) {
    QueueFamilyIndices indices;
    // Logic to find queue family indices to populate struct with
    return indices;
}

```

하지만 queuefamily를 사용할 수 없는 경우는 어떻게 할까요? `findQueueFamilies`에서 예외를 `throw`할 수 있지만, 이 함수는 실제로 장치 적합성에 대한 결정을 내리기에 적합한 곳이 아닙니다. 예를 들어, 전송  전용 queuefamily가 있는 장치를 *선호*하지만 필요하지 않을 수 있습니다. 따라서 특정 queuefamily가 발견되었는지 여부를 나타내는 방법이 필요합니다.

이론적으로 `uint32_t`의 모든 값은 `0`을 포함하여 유효한 queuefamily 인덱스가 될 수 있으므로 queuefamily가 존재하지 않음을 나타내는 마법의 값을 사용하는 것은 실제로 불가능합니다. 다행히도 C++17에서는 값이 존재하는지 여부를 구별하는 데이터 구조를 도입했습니다.

```c
#include <optional>

...

std::optional<uint32_t> graphicsFamily;

std::cout << std::boolalpha << graphicsFamily.has_value() << std::endl; // false

graphicsFamily = 0;

std::cout << std::boolalpha << graphicsFamily.has_value() << std::endl; // true

```

std::optional은 값을 할당하기 전까지는 값을 포함하지 않는 래퍼입니다. 언제든지 has_value() 멤버 함수를 호출하여 값을 포함하는지 여부를 쿼리할 수 있습니다. 즉, 로직을 다음과 같이 변경할 수 있습니다.

```c
#include <optional>

...

struct QueueFamilyIndices {
    std::optional<uint32_t> graphicsFamily;
};

QueueFamilyIndices findQueueFamilies(VkPhysicalDevice device) {
    QueueFamilyIndices indices;
    // Assign index to queue families that could be found
    return indices;
}

```

We can now begin to actually implemt `findQueueFamilies`:

이제 실제로 `findQueueFamilies`를 구현할 수 있습니다.

```c
QueueFamilyIndices findQueueFamilies(VkPhysicalDevice device) {
    QueueFamilyIndices indices;

    ...

    return indices;
}

```

queuefamily목록을 검색하는 프로세스는 예상한 대로이며 [`vkGetPhysicalDeviceQueueFamilyProperties`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkGetPhysicalDeviceQueueFamilyProperties.html)를 사용합니다.

```c
uint32_t queueFamilyCount = 0;
vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, nullptr);

std::vector<VkQueueFamilyProperties> queueFamilies(queueFamilyCount);
vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, queueFamilies.data());

```

[`VkQueueFamilyProperties`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkQueueFamilyProperties.html)구조체에는 지원되는 작업 유형과 해당 패밀리를 기반으로 생성할 수 있는 대기열 수를 포함하여 queuefamily에 대한 일부 세부 정보가 포함되어 있습니다. `VK_QUEUE_GRAPHICS_BIT`를 지원하는 queuefamily를 최소한 하나 찾아야 합니다.

```c
int i = 0;
for (const auto& queueFamily : queueFamilies) {
    if (queueFamily.queueFlags & VK_QUEUE_GRAPHICS_BIT) {
        indices.graphicsFamily = i;
    }

    i++;
}

```

이제 이러한 멋진 queuefamily 조회 함수가 있으므로 이를 `isDeviceSuitable` 함수에서 검사로 사용하여 장치가 사용하려는 명령을 처리할 수 있는지 확인할 수 있습니다.

```c
bool isDeviceSuitable(VkPhysicalDevice device) {
    QueueFamilyIndices indices = findQueueFamilies(device);

    return indices.graphicsFamily.has_value();
}

```

이를 조금 더 편리하게 하기 위해 구조체 자체에 일반적인 검사를 추가하겠습니다.

```c
struct QueueFamilyIndices {
    std::optional<uint32_t> graphicsFamily;

    bool isComplete() {
        return graphicsFamily.has_value();
    }
};

...

bool isDeviceSuitable(VkPhysicalDevice device) {
    QueueFamilyIndices indices = findQueueFamilies(device);

    return indices.isComplete();
}

```

We can now also use this for an early exit from `findQueueFamilies`:

```c
for (const auto& queueFamily : queueFamilies) {
    ...

    if (indices.isComplete()) {
        break;
    }

    i++;
}

```

c++14에서는 optional이 없어서 `QueueFamilyIndices` 따로 만듬

```cpp

struct QueueFamilyIndices {
    uint32_t graphicsFamily = 0;
    uint32_t presentFamily = 0;
    VkQueueFamilyProperties queueFamilyProperties = {};

    bool graphicsFamilyHasValue = false;
    bool presentFamilyHasValue = false;

    void setGraphicsFamily(uint32_t index) {
        graphicsFamily = index;
        graphicsFamilyHasValue = true;
    }
    void setPresentFamily(uint32_t index) {
        presentFamily = index;
        presentFamilyHasValue = true;
    }
    uint32_t getGraphicsQueueFamilyIndex() {
        uint32_t target = -1;

        if (queueFamilyProperties.queueFlags & VkQueueFlagBits::VK_QUEUE_GRAPHICS_BIT)
        {
            target = graphicsFamily;
        }

        return target;
    }
    uint32_t getPresentQueueFamilyIndex() {
        uint32_t target = -1;
        if (queueFamilyProperties.queueFlags & VkQueueFlagBits::VK_QUEUE_GRAPHICS_BIT)
        {
            target = presentFamily;
        }
        return target;
    }

    bool isComplete() {
        return this->graphicsFamilyHasValue && this->presentFamilyHasValue;
    }
    void reset() {
        this->graphicsFamily = 0;
        this->presentFamily = 0;
        this->graphicsFamilyHasValue = false;
        this->presentFamilyHasValue = false;
        this->queueFamilyProperties = {};
    }

```