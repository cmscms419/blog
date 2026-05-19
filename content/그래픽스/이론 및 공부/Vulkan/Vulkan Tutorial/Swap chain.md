# Swap chain

![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Swap chain/image.png]]
.
Vulkan에는 "default framebuffer"라는 개념이 없으므로 화면에 시각화하기 전에 렌더링할 버퍼를 소유하는 infrastructure(인프라)가 필요합니다. 

![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Swap chain/image 1.png]]
:
이 infrastructure(인프라)는 `Swap chain`이라고 하며 Vulkan에서 명시적으로 만들어야 합니다. `Swap chain`은 본질적으로 화면에 표시되기를 기다리는 이미지의 큐입니다. 

애플리케이션은 이러한 이미지를 가져와서 그린 다음 큐로 반환합니다. 큐이 정확히 어떻게 작동하는지와 큐에서 이미지를 표시하기 위한 조건은 `Swapchain`이 설정된 방식에 따라 달라지지만 Swap chain의 일반적인 목적은 이미지 표시를 화면의 새로 고침 빈도와 동기화하는 것입니다.

# Checking for swap chain support

모든 그래픽 카드가 다양한 이유로 화면에 직접 이미지를 표시할 수 있는 것은 아닙니다. 

예를 들어, 서버용으로 설계되어 디스플레이 출력이 없기 때문입니다. 

둘째, 이미지 표시는 창 시스템과 창과 관련된 표면에 크게 연결되어 있기 때문에 실제로 Vulkan 코어의 일부가 아닙니다. `VK_KHR_swapchain` 지원 여부를 쿼리(요청)한 후 장치 확장을 활성화해야 합니다.

`isDeviceSuitable`그 목적을 위해 먼저 이 확장이 지원되는지 확인하는 함수를 확장합니다 . 이전에 에서 지원하는 확장을 나열하는 방법을 살펴보았으므로, 그렇게 하는 것은 꽤 간단할 것입니다.

Vulkan 헤더 파일에 로 정의된 [`VkPhysicalDevice`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPhysicalDevice.html)멋진 매크로가 제공된다는 점에 유의하세요 . 이 매크로를 사용하는 이점은 컴파일러가 철자 오류를 잡아낸다는 것입니다.`VK_KHR_SWAPCHAIN_EXTENSION_NAMEVK_KHR_swapchain`

먼저, 활성화할 검증 계층 목록과 비슷한 필수 장치 확장 목록을 선언합니다.

```c
const std::vector<const char*> deviceExtensions = {
    VK_KHR_SWAPCHAIN_EXTENSION_NAME
};
```

그런 다음 `isDeviceSuitable`에서 추가 검사로 호출되는 `checkDeviceExtensionSupport`함수를 새로 만듭니다:

```cpp
**bool isDeviceSuitable(VkPhysicalDevice device) {
    QueueFamilyIndices indices = findQueueFamilies(device);

    bool extensionsSupported = checkDeviceExtensionSupport(device);

    return indices.isComplete() && extensionsSupported;
}

bool checkDeviceExtensionSupport(VkPhysicalDevice device) {
    return true;
}**
```

함수 본문을 수정하여 확장 기능을 열거하고 필요한 모든 확장 기능이 포함되어 있는지 확인합니다.

```cpp
bool checkDeviceExtensionSupport(VkPhysicalDevice device) {
    uint32_t extensionCount;
    vkEnumerateDeviceExtensionProperties(device, nullptr, &extensionCount, nullptr);

    std::vector<VkExtensionProperties> availableExtensions(extensionCount);
    vkEnumerateDeviceExtensionProperties(device, nullptr, &extensionCount, availableExtensions.data());

    std::set<std::string> requiredExtensions(deviceExtensions.begin(), deviceExtensions.end());

    for (const auto& extension : availableExtensions) {
        requiredExtensions.erase(extension.extensionName);
    }

    return requiredExtensions.empty();
}
```

여기 서는 확인되지 않은 필수 확장자를 나타내기 위해 문자열 집합을 사용하기로 했습니다. 이렇게 하면 사용 가능한 확장의 순서를 열거하면서 쉽게 체크할 수 있습니다. 

물론 `checkValidationLayerSupport`에서 와 같이 중첩 루프를 사용할 수도 있습니다. 

성능 차이는 상관없습니다.

이제 코드를 실행하고 그래픽 카드가 실제로 스왑 체인을 생성할 수 있는지 확인합니다. 

이전 장에서 확인 했듯이 프레젠테이션 대기열을 사용할 수 있다는 것은 스왑 체인 확장이 지원되어야 함을 의미한다는 점에 유의해야 합니다.

그러나 여전히 명시적으로 사용하는 것이 좋으며, 확장은 명시적으로 사용하도록 설정해야 합니다.

# Enabling device extensions

swapchain을 사용하려면 `VK_KHR_swapchain`먼저 확장을 활성화해야 합니다.

확장을 활성화하려면 논리적 장치 생성 구조에 약간의 변경만 필요합니다.

```c
createInfo.enabledExtensionCount = static_cast<uint32_t>(deviceExtensions.size());
createInfo.ppEnabledExtensionNames = deviceExtensions.data();
```

`createInfo.enabledExtensionCount = 0;` 그럴 때는 기존 회선을 교체해야 합니다.

# Querying details of swap chain support

swapchain이 사용 가능한지 확인하는 것 만으로는 충분하지 않습니다. 

실제로 window surface과 호환되지 않을 수 있기 때문입니다. swapchain을 만드는 데는 instance 및 createDevice 보다 훨씬 더 많은 설정이 필요하므로 진행하기 전에 몇 가지 세부 정보를 요청해야 합니다.

기본적으로 확인해야 할 속성에는 세 가지 종류가 있습니다.

- 기본 surface 기능(swapchain의 최소/최대 이미지 수, 이미지의 최소/최대 너비 및 높이)
- surface format(픽셀 형식, 색 공간)
- 사용 가능한 프레젠테이션 모드

와 유사하게 `findQueueFamilies`, 우리는 이러한 세부 정보가 쿼리된 후 전달되기 위해 구조체를 사용할 것입니다. 앞서 언급한 세 가지 유형의 속성은 다음 구조체와 구조체 목록의 형태로 제공됩니다.

```c
struct SwapChainSupportDetails {
    VkSurfaceCapabilitiesKHR capabilities;
    std::vector<VkSurfaceFormatKHR> formats;
    std::vector<VkPresentModeKHR> presentModes;
};
```

`querySwapChainSupport`이제 이 구조체를 채울 새로운 함수를 만들어 보겠습니다 .

```c
SwapChainSupportDetails querySwapChainSupport(VkPhysicalDevice device) {
    SwapChainSupportDetails details;
    return details;
}
```

이 섹션에서는 이 정보를 포함하는 구조체를 쿼리하는 방법을 다룹니다. 

이러한 구조체의 의미와 정확히 어떤 데이터가 포함되어 있는지는 다음 섹션에서 논의합니다.

기본적인 표면 기능부터 시작해 보겠습니다. 이러한 속성은 쿼리하기 쉽고 단일 `VkSurfaceCapabilitiesKHR`구조체로 반환됩니다.

```c
vkGetPhysicalDeviceSurfaceCapabilitiesKHR(device, surface, &details.capabilities);
```

이 기능은 지원되는 기능을 결정할 때 지정된 [`VkPhysicalDevice`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPhysicalDevice.html)및 `VkSurfaceKHR`창 표면을 고려합니다. 모든 지원 쿼리 기능은 swapchain의 핵심 구성 요소이기 때문에 이 두 가지를 첫 번째 매개변수로 사용합니다.

다음 단계는 지원되는 surface format을 쿼리하는 것입니다. 

이는 구조체 목록이므로 익숙한 2개의 함수 호출 절차를 따릅니다.

```cpp
uint32_t formatCount;
vkGetPhysicalDeviceSurfaceFormatsKHR(device, surface, &formatCount, nullptr);

if (formatCount != 0) {
    details.formats.resize(formatCount);
    vkGetPhysicalDeviceSurfaceFormatsKHR(device, surface, &formatCount, details.formats.data());
}
```

벡터가 사용 가능한 모든 형식을 보관하도록 크기가 조정되었는지 확인하세요. 

마지막으로, 지원되는 프레젠테이션 모드를 쿼리하는 것은 다음과 정확히 같은 방식으로 작동합니다 `vkGetPhysicalDeviceSurfacePresentModesKHR`.

```c
uint32_t presentModeCount;
vkGetPhysicalDeviceSurfacePresentModesKHR(device, surface, &presentModeCount, nullptr);

if (presentModeCount != 0) {
    details.presentModes.resize(presentModeCount);
    vkGetPhysicalDeviceSurfacePresentModesKHR(device, surface, &presentModeCount, details.presentModes.data());
}
```

모든 세부 사항은 이제 구조체에 있으므로, `isDeviceSuitable` 이 함수를 사용하여 스왑 체인 지원이 적절한지 확인하기 위해 한 번 더 확장해 보겠습니다.

 이 튜토리얼에서는 적어도 하나의 지원되는 이미지 형식과 하나의 지원되는 프레젠테이션 모드가 있는 경우, 우리가 가진 windows surface 을 감안하여 swap chain 지원이 충분합니다.

```cpp
bool swapChainAdequate = false;
if (extensionsSupported) {
    SwapChainSupportDetails swapChainSupport = querySwapChainSupport(device);
    swapChainAdequate = !swapChainSupport.formats.empty() && !swapChainSupport.presentModes.empty();
}
```

확장 기능을 사용할 수 있는지 확인한 후에만 스왑 체인 지원을 쿼리하는 것이 중요합니다. 함수의 마지막 줄은 다음과 같이 변경됩니다.

```cpp
return indices.isComplete() && extensionsSupported && swapChainAdequate;
```

# **Choosing the right settings for the swap chain**

조건이 충족 되면 `swapChainAdequate`지원은 확실히 충분하지만, 여전히 다양한 최적성의 모드가 많이 있을 수 있습니다.

이제 최상의 스왑 체인에 대한 올바른 설정을 찾기 위한 몇 가지 함수를 작성하겠습니다. 결정해야 할 설정에는 세 가지 유형이 있습니다.

- 표면 형식(색상 깊이)
- 프레젠테이션 모드(화면에 이미지를 "교환"하기 위한 조건)
- 스왑 범위(스왑 체인의 이미지 해상도)

이러한 각 설정에 대해 우리는 가능하다면 사용할 이상적인 값을 염두에 두고, 그렇지 않으면 다음으로 좋은 값을 찾기 위한 논리를 만들 것입니다.

# **Surface format**

이 설정에 대한 함수는 이렇게 시작합니다. 나중에 구조체 `formats`의 멤버를 `SwapChainSupportDetails`인수로 전달합니다.

```cpp
VkSurfaceFormatKHR chooseSwapSurfaceFormat(const std::vector<VkSurfaceFormatKHR>& availableFormats) {

}
```

각 `VkSurfaceFormatKHR`항목에는 a `format`와 `colorSpace`멤버가 포함됩니다.

- `format`멤버는 색상 채널과 유형을 지정합니다. 예를 들어, `VK_FORMAT_B8G8R8A8_SRGB`는 B, G, R 및 알파 채널을 8비트 부호 없는 정수로 순서대로 저장하여 픽셀당 총 32비트를 저장한다는 것을 의미합니다.
- `colorSpace`멤버는 플래그를 사용하여 SRGB 색상 공간이 지원되는지 여부를 나타냅니다 . 이 플래그는 이전 버전의 사양에서 `VK_COLOR_SPACE_SRGB_NONLINEAR_KHR`호출되었음에 유의하세요

`VK_COLORSPACE_SRGB_NONLINEAR_KHR` 주의

색상 공간의 경우 SRGB가 사용 가능하다면 SRGB를 사용하겠습니다. 왜냐하면 [더 정확하게 인식되는 색상이 나오기](http://stackoverflow.com/questions/12524623/) 때문입니다. 

또한 나중에 사용할 텍스처와 같이 이미지의 표준 색상 공간이기도 합니다. 그렇기 때문에 SRGB 색상 형식도 사용해야 하는데,`VK_FORMAT_B8G8R8A8_SRGB`가장 일반적인 형식 중 하나는 입니다.

목록을 살펴보고 선호하는 조합이 있는지 확인해 보겠습니다.

```c
for (const auto& availableFormat : availableFormats) {
    if (availableFormat.format == VK_FORMAT_B8G8R8A8_SRGB && availableFormat.colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
        return availableFormat;
    }
}
```

이 방법도 실패하면 사용 가능한 형식을 얼마나 "좋은지"를 기준으로 순위를 매길 수 있지만, 대부분의 경우 지정된 첫 번째 형식으로 만족해도 됩니다.

```c
VkSurfaceFormatKHR chooseSwapSurfaceFormat(const std::vector<VkSurfaceFormatKHR>& availableFormats) {
    for (const auto& availableFormat : availableFormats) {
        if (availableFormat.format == VK_FORMAT_B8G8R8A8_SRGB && availableFormat.colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
            return availableFormat;
        }
    }return availableFormats[0];
}
```

# **Presentation mode**

![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Swap chain/image 2.png]]

프레젠테이션 모드는 이미지를 화면에 표시하기 위한 실제 조건을 나타내기 때문에 swapchain에서 가장 중요한 설정이라고 할 수 있습니다.

 Vulkan에는 네 가지 모드가 있습니다.

- `VK_PRESENT_MODE_IMMEDIATE_KHR`

![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Swap chain/image 3.png]]

애플리케이션에서 제출한 이미지가 바로 화면으로 전송

이미지가 즉시 화면에 표시됩니다

찢어짐 현상이 발생할 수 있습니다.

- `VK_PRESENT_MODE_FIFO_KHR`

![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Swap chain/image 4.png]]

queue를 생각하면 좋다. FIFO


![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Swap chain/image 5.png]]



![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Swap chain/image 6.png]]

swap chain은 디스플레이가 새로 고쳐질 때 디스플레이가 큐의 앞쪽에서 이미지를 가져오고 프로그램이 렌더링된 이미지를 큐의 뒤쪽에 삽입하는 큐입니다. 

큐가 가득 차면 프로그램은 대기해야 합니다. 이는 최신 게임에서 볼 수 있는 수직 동기화와 가장 유사합니다. 

디스플레이가 새로 고쳐지는 순간을 "vertical blank"이라고 합니다.

- `VK_PRESENT_MODE_FIFO_RELAXED_KHR`


![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Swap chain/image 7.png]]

이 모드는 응용 프로그램이 늦고 마지막  vertical blank에서 큐가 비어 있는 경우에만 이전 모드와 다릅니다. 다음 vertical blank 기다리는 대신 이미지가 도착하면 바로 전송됩니다. 이로 인해 눈에 띄는 찢어짐이 발생할 수 있습니다.

- `VK_PRESENT_MODE_MAILBOX_KHR`

![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Swap chain/image 8.png]]




![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Swap chain/image 9.png]]


![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Swap chain/image 10.png]]]

### **요약**
1. VK_PRESENT_MODE_IMMEDIATE_KHR
•	특성: 즉시 제시 모드
•	동작: 프레임을 즉시 화면에 출력
•	장점: 최소 지연 시간
•	단점: 화면 찢어짐(Screen Tearing) 발생 가능
•	사용 용도: 최소 지연시간이 중요한 경쟁 게임

2. VK_PRESENT_MODE_MAILBOX_KHR
•	특성: 메일박스(Triple Buffering) 모드
•	동작: 3개의 이미지를 사용, 새로운 이미지로 큐의 이미지를 교체
•	장점: 낮은 지연시간 + 화면 찢어짐 방지
•	단점: 높은 전력 소모, 3개 이미지 필요
•	사용 용도: 고성능 게이밍에서 선호

3. VK_PRESENT_MODE_FIFO_KHR
•	특성: FIFO(First-In-First-Out) 모드
•	동작: V-Sync와 유사, 수직 동기화에 맞춰 제시
•	장점: 화면 찢어짐 방지, 전력 효율적
•	단점: 지연 시간 증가 가능
•	사용 용도: 기본 모드 (모든 구현체에서 지원 보장)

4. VK_PRESENT_MODE_FIFO_RELAXED_KHR
•	특성: 완화된 FIFO 모드
•	동작: FIFO + 지연 시 즉시 제시
•	장점: FIFO의 안정성 + 성능 향상
•	단점: 가끔 화면 찢어짐 발생 가능
•	사용 용도: FIFO와 IMMEDIATE의 절충안

5. VK_PRESENT_MODE_SHARED_DEMAND_REFRESH_KHR
•	특성: 공유 수요 새로 고침 모드
•	동작: 필요시에만 화면 업데이트
•	장점: 극도로 낮은 전력 소모
•	단점: 제한된 지원, 특수 용도
•	사용 용도: 모바일, 임베디드 시스템

6. VK_PRESENT_MODE_SHARED_CONTINUOUS_REFRESH_KHR
•	특성: 공유 지속 새로 고침 모드
•	동작: 지속적 화면 업데이트 (공유 환경)
•	장점: 공유 디스플레이에서 안정적
•	단점: 제한된 지원
•	사용 용도: 특수 디스플레이 환경

7. VK_PRESENT_MODE_FIFO_LATEST_READY_EXT
•	특성: 최신 준비된 FIFO 모드 (확장)
•	동작: FIFO + 최신 준비된 이미지 우선 제시
•	장점: FIFO 안정성 + 지연 시간 개선
•	단점: 확장 기능으로 제한된 지원
•	사용 용도: 지연 시간에 민감한 애플리케이션


이것은 두 번째 모드의 또 다른 변형입니다. 큐가 가득 찼을 때 애플리케이션을 차단하는 대신, 이미 대기 중인 이미지는 단순히 새 이미지로 대체됩니다.

이 모드는 찢어짐을 피하면서도 가능한 한 빨리 프레임을 렌더링하는 데 사용할 수 있어 표준 수직 동기화보다 지연 문제가 적습니다. 이것은 일반적으로 "triple buffering"으로 알려져 있지만, 버퍼가 세 개만 있다고 해서 반드시 프레임 속도가 빨라지는 것은 아니다.

사용 가능한 모드 만 `VK_PRESENT_MODE_FIFO_KHR`보장되므로 사용 가능한 최상의 모드를 찾는 함수를 다시 작성해야 합니다.

```c
VkPresentModeKHR chooseSwapPresentMode(const std::vector<VkPresentModeKHR>& availablePresentModes) {
    return VK_PRESENT_MODE_FIFO_KHR;
}
```

개인적으로 `VK_PRESENT_MODE_MAILBOX_KHR`에너지 사용량이 문제가 되지 않는다면 매우 좋은 타협이라고 생각합니다. 수직 공백까지 가능한 한 최신의 새 이미지를 렌더링하여 상당히 낮은 지연 시간을 유지하면서도 찢어짐을 피할 수 있습니다. 에너지 사용량이 더 중요한 모바일 디바이스에서는 `VK_PRESENT_MODE_FIFO_KHR`을 대신 사용하는 것이 좋습니다. 이제 목록을 살펴보고 `VK_PRESENT_MODE_MAILBOX_KHR`을 사용할 수 있는지 확인해 보겠습니다

```c
VkPresentModeKHR chooseSwapPresentMode(const std::vector<VkPresentModeKHR>& availablePresentModes) {
    for (const auto& availablePresentMode : availablePresentModes) {
        if (availablePresentMode == VK_PRESENT_MODE_MAILBOX_KHR) {
            return availablePresentMode;
        }
    }return VK_PRESENT_MODE_FIFO_KHR;
}
```

# **Swap extent**

이제 하나의 주요 속성만 남았습니다. 이에 대해 마지막 함수를 하나 추가하겠습니다.

```c
VkExtent2D chooseSwapExtent(const VkSurfaceCapabilitiesKHR& capabilities) {
}
```

The `swap extent`는 `swap chain images`의 해상도이며, 거의 항상 픽셀 단위로 그리는 창의 해상도와 정확히 일치합니다. 

가능한 해상도 범위는 `VkSurfaceCapabilitiesKHR`구조체에 정의되어 있습니다. 

vulkan은 `currentExtent` 멤버에서 width and height를 설정하여 창의 해상도를 일치 시키도록 지시합니다. 그러나 일부 창 관리자는 여기서 차이를 허용하며, 이는 `currentExtent`의 너비와 높이를 특수 값인 `uint32_t`의 최대값으로 설정하는 것으로 표시됩니다. 이 경우 최소 이미지 범위와 최대 이미지 범위 내에서 창에 가장 잘 맞는 해상도를 선택합니다. 하지만 해상도를 올바른 단위로 지정해야 합니다.

[GLFW는 크기를 측정할 때 픽셀과 화면 좌표라는](https://www.glfw.org/docs/latest/intro_guide.html#coordinate_systems) 두 가지 단위를 사용합니다 . 예를 들어, `{WIDTH, HEIGHT}`창을 만들 때 이전에 지정한 해상도는 **화면 좌표**로 측정됩니다. 

하지만 Vulkan은 픽셀로 작동하므로 스왑 체인 범위도 픽셀로 지정해야 합니다. 안타깝게도 높은 DPI 디스플레이(예: Apple의 Retina 디스플레이)를 사용하는 경우 화면 좌표는 픽셀과 일치하지 않습니다. 대신 픽셀 밀도가 더 높기 때문에 픽셀 단위의 창 해상도가 화면 좌표의 해상도보다 커집니다. 따라서 따라서 Vulkan이 스왑 범위를 수정하지 않으면 원래 `{WIDTH, HEIGHT}`를 그냥 사용할 수 없습니다. 대신 `glfwGetFramebufferSize`를 사용하여 창의 해상도를 픽셀 단위로 쿼리한 후 최소 및 최대 이미지 범위와 일치시켜야 합니다.

```cpp
#include <cstdint> // Necessary for uint32_t
#include <limits> // Necessary for std::numeric_limits
#include <algorithm> // Necessary for std::clamp

VkExtent2D chooseSwapExtent(const VkSurfaceCapabilitiesKHR& capabilities) {
    if (capabilities.currentExtent.width != std::numeric_limits<uint32_t>::max()) {
        return capabilities.currentExtent;
    } else {
        int width, height;
        glfwGetFramebufferSize(window, &width, &height);

        VkExtent2D actualExtent = {
            static_cast<uint32_t>(width),
            static_cast<uint32_t>(height)
        };

        actualExtent.width = std::clamp(actualExtent.width, capabilities.minImageExtent.width, capabilities.maxImageExtent.width);
        actualExtent.height = std::clamp(actualExtent.height, capabilities.minImageExtent.height, capabilities.maxImageExtent.height);

        return actualExtent;
    }
}
```

이 함수는 구현에서 지원하는 허용된 최소 및 최대 범위 사이 의 `clamp`값을 제한하는 데 사용됩니다 .`widthheight`

# **Creating the swap chain**

이제 런타임에 선택해야 할 사항에 도움을 주는 모든 도우미 함수가 있으므로, 마침내 작동하는 스왑 체인을 만드는 데 필요한 모든 정보를 갖게 되었습니다.

이러한 호출의 결과로 시작하는 함수를 만들고 논리적 장치가 생성된 후에 `createSwapChain`호출해야 합니다 `initVulkan`.

```cpp
void initVulkan() {
    createInstance();
    setupDebugMessenger();
    createSurface();
    pickPhysicalDevice();
    createLogicalDevice();
    create
();
}

void createSwapChain() {
    SwapChainSupportDetails swapChainSupport = querySwapChainSupport(physicalDevice);
    VkSurfaceFormatKHR surfaceFormat = chooseSwapSurfaceFormat(swapChainSupport.formats);
    VkPresentModeKHR presentMode = chooseSwapPresentMode(swapChainSupport.presentModes);
    VkExtent2D extent = chooseSwapExtent(swapChainSupport.capabilities);
}
```

이러한 속성 외에도 SwapChain에 얼마나 많은 이미지를 넣을 것인지도 결정해야 합니다. 

구현은 작동하는 데 필요한 최소 개수를 지정합니다.

```c
uint32_t imageCount = swapChainSupport.capabilities.minImageCount;
```

그러나 이 최소값을 고수하면 렌더링 할 다른 이미지를 확보하기 전에 드라이버가 내부 작업을 완료할 때까지 기다려야 하는 경우가 있습니다.

따라서 최소 이미지보다 하나 이상의 이미지를 요청하는 것이 좋습니다 

→ 미리 이미지를 여러 장 그려서 신속하게 그려지는 것처럼 보이게 하는 것이라고 이해함

```c
uint32_t imageCount = swapChainSupport.capabilities.minImageCount + 1;
```

또한 이 작업을 수행하는 동안 최대 이미지 수를 초과하지 않도록 해야 하는데, 여기서 `0`은 최대값이 없음을 의미하는 특수 값입니다:

```c
if (swapChainSupport.capabilities.maxImageCount > 0 && imageCount > swapChainSupport.capabilities.maxImageCount) 
{
    imageCount = swapChainSupport.capabilities.maxImageCount;
}
```

Vulkan 객체의 전통과 마찬가지로 스왑 체인 객체를 만들려면 큰 구조를 채워야 합니다. 매우 친숙하게 시작합니다.

```c
VkSwapchainCreateInfoKHR createInfo{};
createInfo.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
createInfo.surface = surface;
```

스왑 체인을 연결할 표면을 지정한 후 스왑 체인 이미지의 세부 정보를 지정합니다.

```c
createInfo.minImageCount = imageCount;
createInfo.imageFormat = surfaceFormat.format;
createInfo.imageColorSpace = surfaceFormat.colorSpace;
createInfo.imageExtent = extent;
createInfo.imageArrayLayers = 1;
createInfo.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;

```

`imageArrayLayers` 는 각 이미지가 구성하는 레이어의 양을 지정합니다.  stereoscopic 3D application을 개발하지 않는 한 이 값은 항상 `1`입니다. 

`imageUsage`  비트 필드는 스왑 체인에서 이미지를 어떤 종류의 작업에 사용할지 지정합니다. 

이 튜토리얼에서는 이미지를 직접 렌더링할 예정이므로 색상 첨부 파일로 사용됩니다. 

후처리와 같은 작업을 수행하기 위해 먼저 이미지를 별도의 이미지로 렌더링할 수도 있습니다. 이 경우 대신 `VK_IMAGE_USAGE_TRANSFER_DST_BIT`와 같은 값을 사용하고 메모리 작업을 사용하여 렌더링된 이미지를 스왑 체인 이미지로 전송할 수 있습니다.

```cpp
QueueFamilyIndices indices = findQueueFamilies(physicalDevice);
uint32_t queueFamilyIndices[] = {indices.graphicsFamily.value(), indices.presentFamily.value()};

if (indices.graphicsFamily != indices.presentFamily) {
    createInfo.imageSharingMode = VK_SHARING_MODE_CONCURRENT;
    createInfo.queueFamilyIndexCount = 2;
    createInfo.pQueueFamilyIndices = queueFamilyIndices;
} else {
    createInfo.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
    createInfo.queueFamilyIndexCount = 0; // Optional
    createInfo.pQueueFamilyIndices = nullptr; // Optional
}
```

다음으로 여러 큐 패밀리에 걸쳐 사용될 스왑 체인 이미지를 처리하는 방법을 지정해야 합니다. 우리 애플리케이션의 경우 그래픽 큐 패밀리가 프레젠테이션 큐와 다른 경우에 해당됩니다. 

그래픽 큐 스왑 체인에 있는 이미지를 그린 다음 프레젠테이션 큐에 제출할 것입니다. 여러 큐에서 액세스하는 이미지를 처리하는 방법에는 두 가지가 있습니다:

- `VK_SHARING_MODE_EXCLUSIVE`

이미지는 한 번에 하나의 대기열 패밀리가 소유하며 다른 대기열 패밀리에 사용하기 전에 소유권을 명시적으로 이전해야 합니다. 이 옵션이 가장 좋은 성능을 제공합니다.

- `VK_SHARING_MODE_CONCURRENT`

이미지는 명시적인 소유권 이전 없이 여러 큐 families에서 사용할 수 있습니다.

큐 패밀리가 다른 경우, 소유권 장을 하지 않아도 되도록 이 튜토리얼에서 동시 모드를 사용합니다. 이 장은 나중에 더 잘 설명될 몇 가지 개념을 포함하기 때문입니다. 

동시 모드를 사용하려면 `queueFamilyIndexCount`및 `pQueueFamilyIndices`매개변수를 사용하여 소유권을 공유할 큐 패밀리를 미리 지정해야 합니다. 

그래픽 큐 패밀리와 프레젠테이션 큐 패밀리가 동일한 경우(대부분의 하드웨어에 해당), 동시 모드를 사용하려면 적어도 두 개의 다른 큐 패밀리를 지정해야 하므로 독점 모드를 사용하는 것이 좋습니다. 

```cpp
createInfo.preTransform = swapChainSupport.capabilities.currentTransform;
```

시계 방향 90도 회전이나 수평 뒤집기와 같은 특정 변형이 지원되는 경우(기능의 `supportedTransforms`) 스왑 체인의 이미지에 적용되도록 지정할 수 있습니다. 어떤 변환도 원하지 않도록 지정하려면 현재 변환을 지정하기만 하면 됩니다.

```cpp
createInfo.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
```

`compositeAlpha`필드는 창 시스템에서 다른 창과 블렌딩할 때 알파 채널을 사용할지 여부를 지정합니다. 거의 항상 알파 채널을 무시하고 싶을 것이므로 `VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR`을 사용합니다.

```c
createInfo.presentMode = presentMode;
createInfo.clipped = VK_TRUE;
```

`presentMode`멤버는 그 자체로 말합니다. `clipped`  멤버가 `VK_TRUE`로 설정되어 있으면 예를 들어 **다른 창이 앞에 있기 때문에 가려진 픽셀의 색상을 신경 쓰지 않는다는 의미**입니다. 이러한 픽셀을 다시 읽을 수 있고 예측 가능한 결과를 얻을 수 있어야 하는 경우가 아니라면 클리핑을 활성화하는 것이 최상의 성능을 얻을 수 있습니다.

```c
createInfo.oldSwapchain = VK_NULL_HANDLE;
```

마지막 필드인 oldSwapChain이 남습니다. 

Vulkan에서는 창 크기가 조정되는 등 애플리케이션이 실행되는 동안 스왑 체인이 유효하지 않거나 최적화되지 않을 수 있습니다. 이 경우 스왑 체인을 실제로 처음부터 다시 만들어야 하며 이 필드에 이전 체인에 대한 참조를 지정해야 합니다. 이는 복잡한 주제이므로 다음 장에서 자세히 알아보겠습니다. 지금은 하나의 스왑 체인만 생성한다고 가정하겠습니다.

이제 `VkSwapchainKHR`객체를 저장할 클래스 멤버를 추가합니다 .

```c
VkSwapchainKHR swapChain;
```

이제 스왑 체인을 생성하는 것은 `vkCreateSwapchainKHR`를 호출하는 것만큼 간단합니다 .

```c
if (vkCreateSwapchainKHR(device, &createInfo, nullptr, &swapChain) != VK_SUCCESS) {
    throw std::runtime_error("failed to create swap chain!");
}
```

매개변수는 논리적 장치, 스왑 체인 생성 정보, 선택적 사용자 정의 할당자 및 핸들을 저장할 변수에 대한 포인터입니다. 놀랄 일은 없습니다. `vkDestroySwapchainKHR`장치 전에 다음을 사용하여 정리해야 합니다.

```c
void cleanup() {
    vkDestroySwapchainKHR(device, swapChain, nullptr);
    ...
}
```

이제 애플리케이션을 실행하여 스왑 체인이 성공적으로 생성되었는지 확인합니다! 

이 시점에서 `vkCreateSwapchainKHR`에서 액세스 위반 오류가 발생하거나 `SteamOverlayVulkanLayer.dll` 레이어에서 '`vkGetInstanceProcAddress`' 찾기 실패와 같은 메시지가 표시되면 Steam 오버레이 레이어에 대한 FAQ 항목을 참조하세요. 

검증 레이어가 활성화된 상태에서 `createInfo.imageExtent = extent`라인을 제거해 보시기 바랍니다. 유효성 검사 레이어 중 하나가 즉시 실수를 포착하고 유용한 메시지가 인쇄되는 것을 확인할 수 있습니다:

![](attachments/swap_chain_validation_layer.png)

# Retrieving the swap chain images

이제 스왑 체인이 생성되었으므로 남은 것은 그 안에 있는 [`VkImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImage.html)의 핸들을 검색하는 것입니다. 이후 챕터에서 렌더링 작업 중에 이를 참조하겠습니다. 핸들을 저장할 클래스 멤버를 추가합니다.

```c
std::vector<VkImage> swapChainImages;
```

Image는 스왑 체인에 대한 구현에 의해 생성되었으며 스왑 체인이 파괴되면 자동으로 정리되므로 정리 코드를 추가할 필요가 없습니다.

저는 핸들을 검색하는 코드를 `vkCreateSwapchainKHR` 호출 직후, `createSwapChain` 함수 끝에 추가하고 있습니다. 

핸들을 검색하는 것은 다른 때 vulkan에서 객체 배열을 검색할 때와 매우 유사합니다.

스왑 체인에 최소한의 이미지 수만 지정했으므로 구현에서 더 많은 이미지로 swapchain을 만들 수 있다는 점을 기억하세요. 그렇기 때문에 먼저 `vkGetSwapchainImagesKHR`로 최종 이미지 수를 쿼리한 다음 컨테이너의 크기를 조정하고 마지막으로 다시 호출하여 핸들을 검색합니다.

```c
vkGetSwapchainImagesKHR(device, swapChain, &imageCount, nullptr);
swapChainImages.resize(imageCount);
vkGetSwapchainImagesKHR(device, swapChain, &imageCount, swapChainImages.data());

```

마지막으로, 스왑 체인 이미지에 대해 선택한 형식과 범위를 멤버 변수에 저장합니다. 이는 향후 장에서 필요합니다.

```c
VkSwapchainKHR swapChain;
std::vector<VkImage> swapChainImages;
VkFormat swapChainImageFormat;
VkExtent2D swapChainExtent;
...
swapChainImageFormat = surfaceFormat.format;
swapChainExtent = extent;
```

이제 우리는 그릴 수 있고 창에 표시할 수 있는 이미지 세트를 가지고 있습니다. 다음 장에서는 이미지를 렌더 대상으로 설정하는 방법을 다루고 실제 그래픽 파이프라인과 그리기 명령을 살펴보기 시작합니다!