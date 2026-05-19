# Window surface

![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Window surface/image.png]]

vulkan 많은 os에서 surface를 만들 수 있다. render target 또는 off-screen buffer에 만들기도 한다.

wsl은 vulkan과 윈도우 시스템 간의 상호 작용을 의미한다.

Vulkan은 플랫폼 독립적인 API이므로 자체적으로 창 시스템과 직접 인터페이스할 수 없습니다. 

이 장에서는 첫 번째 확장인 `VK_KHR_surface`에 대해 설명합니다. 

렌더링된 이미지를 표시할 추상 유형의 표면을 나타내는 `VkSurfaceKHR`객체를 노출합니다. 

`VK_KHR_surface` 확장은 인스턴스 수준 확장이며 `glfwGetRequiredInstanceExtensions`에서 반환된 목록에 포함되어 있으므로 실제로 이미 활성화했습니다. 이 목록에는 다음 몇 장에서 사용할 다른 WSI 확장도 포함되어 있습니다.

windows surface은 인스턴스 생성 직후에 만들어야 합니다. 왜냐하면 windows surface은 실제로 물리적 장치 선택에 영향을 미칠 수 있기 때문입니다. 

나중에 설명한 이유는 windows surface는 “렌더 대상과 present”이라는 더 큰 주제의 일부이기 때문인데, 이에 대한 설명은 기본 설정을 복잡하게 만들었을 것입니다. 

![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Window surface/image 1.png]]

windows surface은 Vulkan에서 완전히 선택적인 구성 요소라는 점에 유의해야 합니다.  off-screen 렌더링만 필요한 경우입니다. Vulkan에서는 off-screen(OpenGL에 필요)을 만드는 것과 같은 해킹 없이도 그렇게 할 수 있습니다.

# Window surface creation

Start by adding a `surface` class member right below the debug callback.

```cpp
VkSurfaceKHR surface;
```

`VkSurfaceKHR`객체와 그 사용법은 플랫폼에 구애 받지 않지만, 창 시스템 세부 정보에 따라 달라지기 때문에 생성은 그렇지 않습니다. 예를 들어, Windows에서는 `HWND`및 `HMODULE`들이 필요합니다. 따라서 확장 기능에 플랫폼 별로 추가되는 것이 있는데, Windows에서는 `VK_KHR_win32_surface`라고 하며 `glfwGetRequiredInstanceExtensions`의 목록에도 자동으로 포함됩니다.

이 플랫폼별 확장 기능을 사용하여 Windows에서 surface를 만드는 방법을 보여드리겠지만 이 튜토리얼에서는 실제로 사용하지 않을 것입니다. GLFW와 같은 라이브러리를 사용한 다음 플랫폼별 코드를 사용하는 것은 의미가 없기 때문입니다. GLFW에는 실제로 플랫폼 차이를 처리하는 `glfwCreateWindowSurface`가 있습니다. 하지만 이 함수를 사용하기 전에 이 함수가 백그라운드에서 어떤 일을 하는지 알아두는 것이 좋습니다.

```cpp
#define VK_USE_PLATFORM_WIN32_KHR
#define GLFW_INCLUDE_VULKAN
#include <GLFW/glfw3.h>
#define GLFW_EXPOSE_NATIVE_WIN32
#include <GLFW/glfw3native.h>
```

window surface은 Vulkan 객체이므로 채워야 하는 `VkWin32SurfaceCreateInfoKHR`구조체가 함께 제공됩니다. 여기에는 두 가지 중요한 매개변수, 즉 `hwnd`와 `hinstance`가 있습니다. 이는 창과 프로세스에 대한 핸들입니다.

```cpp
VkWin32SurfaceCreateInfoKHR createInfo{};
createInfo.sType = VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
createInfo.hwnd = glfwGetWin32Window(window);
createInfo.hinstance = GetModuleHandle(nullptr);
```

`glfwGetWin32Window`함수는 GLFW 창 객체에서 원시 `HWND`를 가져오는 데 사용됩니다. `GetModuleHandle`호출은 현재 프로세스의 힌스턴스 핸들을 반환합니다.

그 후 인스턴스 파라미터, 서피스 생성 세부 정보, 사용자 정의 할당자 및 서피스 핸들을 저장할 변수를 포함하는 `vkCreateWin32SurfaceKHR`을 사용하여 surface를 생성할 수 있습니다. 엄밀히 말하면 이 함수는 WSI 확장 함수이지만 표준 Vulkan 로더에 포함될 정도로 일반적으로 사용되므로 다른 확장 함수와 달리 명시적으로 로드할 필요가 없습니다.

```c
if (vkCreateWin32SurfaceKHR(instance, &createInfo, nullptr, &surface) != VK_SUCCESS) {
    throw std::runtime_error("failed to create window surface!");
}

```

위 과정과 비슷하게 리눅스 환경에서 x11을 `vkCreateXcbSurfaceKHR` 으로 만들 수 있다.

`glfwCreateWindowSurface` 함수는 각 플랫폼마다 다른 구현으로 이 작업을 정확히 수행합니다. 이제 이 함수를 프로그램에 통합하겠습니다. 인스턴스 생성 직후에 `initVulkan`에서 호출할 `createSurface` 함수와 `setupDebugMessenger`를 추가합니다.

```c
void initVulkan() {
    createInstance();
    setupDebugMessenger();
    createSurface();
    pickPhysicalDevice();
    createLogicalDevice();
}

void createSurface() {

}

```

GLFW 호출은 구조체 대신 간단한 매개변수를 사용하므로 함수를 매우 간단하게 구현할 수 있습니다:

```c
void createSurface() {
    if (glfwCreateWindowSurface(instance, window, nullptr, &surface) != VK_SUCCESS) {
        throw std::runtime_error("failed to create window surface!");
    }
}

```

매개 변수는 [`VkInstance`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkInstance.html), GLFW 창 포인터, 사용자 정의 할당자 및 `VkSurfaceKHR`변수에 대한 포인터입니다. 관련 플랫폼 호출에서 [`VkResult`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkResult.html)를 전달하기만 하면 됩니다. GLFW는 표면을 파괴하는 특별한 함수를 제공하지 않지만, 이는 원래 API를 통해 쉽게 수행할 수 있습니다:

```c
void cleanup() {
        ...
        vkDestroySurfaceKHR(instance, surface, nullptr);
        vkDestroyInstance(instance, nullptr);
        ...
    }

```

인스턴스 전에 표면이 파괴되었는지 확인하세요.

# Querying for presentation support

Vulkan 구현이 window 시스템 통합을 지원할 수는 있지만, 그렇다고 해서 시스템의 모든 디바이스가 이를 지원하는 것은 아닙니다. 따라서 기기가 우리가 만든 surface에 이미지를 표시할 수 있도록 `isDeviceSuitable`을 확장해야 합니다. present은 큐별 기능이기 때문에 실제로 문제는 우리가 만든 surface에 present을 지원하는 queuefamily를 찾는 것입니다.

실제로 그리기 명령을 지원하는 queuefamily와 presentation을 지원하는 queuefamily는 겹치지 않을 수 있습니다. 따라서 `QueueFamilyIndices`구조를 수정하여 별도의 present 큐가 있을 수 있다는 점을 고려해야 합니다:

```c
struct QueueFamilyIndices {
    std::optional<uint32_t> graphicsFamily;
    std::optional<uint32_t> presentFamily;

    bool isComplete() {
        return graphicsFamily.has_value() && presentFamily.has_value();
    }
};

```

다음으로 window surface에 표시할 수 있는 기능이 있는 queuefamily를 찾도록 `findQueueFamilies`함수를 수정하겠습니다. 이를 확인하는 함수는 physical device, queuefamily index 및 surface를 매개변수로 받는 `vkGetPhysicalDeviceSurfaceSupportKHR`입니다. 

`VK_QUEUE_GRAPHICS_BIT`와 동일한 루프에서 호출을 추가합니다:

```c
VkBool32 presentSupport = false;
vkGetPhysicalDeviceSurfaceSupportKHR(device, i, surface, &presentSupport);
```

그런 다음 bool 값을 확인하고 present 패밀리 큐 index를 저장하기만 하면 됩니다:

```c
if (presentSupport) {
    indices.presentFamily = i;
}
```

결국 같은 queuefamily가 될 가능성이 매우 높지만 프로그램 전체에서 일관된 접근 방식을 위해 별도의 큐인 것처럼 취급할 것입니다. 그럼에도 불구하고 성능 향상을 위해 동일한 큐에서 draw와 present을 지원하는 물리적 장치를 명시적으로 선호하는 로직을 추가할 수 있습니다.

# Creating the presentation queue

남은 한 가지는 논리 장치 생성 절차를 수정하여 present 큐를 생성하고 [`VkQueue`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkQueue.html) 핸들을 검색하는 것입니다. 핸들에 대한 멤버 변수를 추가합니다:

```c
VkQueue presentQueue;
```

다음으로, 두 패밀리의 큐를 생성하려면 여러 개의 `VkDeviceQueueCreateInfo`구조체가 필요합니다. 이를 위한 우아한 방법은 필요한 큐에 필요한 모든 고유한 queuefamily의 집합을 만드는 것입니다:

```c
#include <set>

...

QueueFamilyIndices indices = findQueueFamilies(physicalDevice);

std::vector<VkDeviceQueueCreateInfo> queueCreateInfos;
std::set<uint32_t> uniqueQueueFamilies = {indices.graphicsFamily.value(), indices.presentFamily.value()};

float queuePriority = 1.0f;
for (uint32_t queueFamily : uniqueQueueFamilies) {
    VkDeviceQueueCreateInfo queueCreateInfo{};
    queueCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    queueCreateInfo.queueFamilyIndex = queueFamily;
    queueCreateInfo.queueCount = 1;
    queueCreateInfo.pQueuePriorities = &queuePriority;
    queueCreateInfos.push_back(queueCreateInfo);
}

```

And modify [`VkDeviceCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkDeviceCreateInfo.html) to point to the vector:

```c
createInfo.queueCreateInfoCount = static_cast<uint32_t>(queueCreateInfos.size());
createInfo.pQueueCreateInfos = queueCreateInfos.data();
```

queuefamily가 동일한 경우 해당 index를 한 번만 전달하면 됩니다. 마지막으로 큐 핸들을 검색하는 호출을 추가합니다:

```c
vkGetDeviceQueue(device, indices.presentFamily.value(), 0, &presentQueue);
```

queuefamily가 동일한 경우, 두 핸들은 이제 같은 값을 가질 가능성이 높습니다. 다음 장에서는 스왑 체인과 이를 통해 이미지를 표면에 표시하는 방법에 대해 살펴보겠습니다.