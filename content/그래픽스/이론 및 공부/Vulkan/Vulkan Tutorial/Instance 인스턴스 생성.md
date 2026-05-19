# Instance  인스턴스 생성

1. vulkan 라이브러리를 초기화 시키는 것이다.

하위 시스템이다. 운영 체제별로 전담 API가 아닌 인스턴스를 사용하는 단일 API가 있다.

인스턴스에는 vulkan state를 전체를 알 수 없다. 인스턴스에는 생성되는 추가 객체가 있다. 이 객체가 고유의 상태를 가지고, 다른 객체를 만든다.

![[https://www.youtube.com/watch?v=vZcoW989I3I&t=162s](https://www.youtube.com/watch?v=vZcoW989I3I&t=162s)](Instance%20%E1%84%8B%E1%85%B5%E1%86%AB%E1%84%89%E1%85%B3%E1%84%90%E1%85%A5%E1%86%AB%E1%84%89%E1%85%B3%20%E1%84%89%E1%85%A2%E1%86%BC%E1%84%89%E1%85%A5%E1%86%BC%2018118a41dc6f80f38ad3ecbfa5f63d0a/image.png)

[https://www.youtube.com/watch?v=vZcoW989I3I&t=162s](https://www.youtube.com/watch?v=vZcoW989I3I&t=162s)

그래서 아래처럼 서로 다른 프로그램을 만들 수 있다

![[/image.png]]

인스턴스의 주요 작업은 physical device를 생성하는 것이다.

# **인스턴스**

Vulkan 라이브러리를 초기화하려면 인스턴스를 생성해야 합니다. 인스턴스는 애플리케이션과 Vulkan 라이브러리 간의 연결을 담당합니다. `createInstance` 함수를 추가하고 `initVulkan` 함수에서 호출합니다.

```cpp
void initVulkan() {
	createInstance();
}

private:
	VkInstance instance;
```

1. **VkApplicationInfo 구조체**: 애플리케이션에 대한 정보를 드라이버에 제공하기 위해 `VkApplicationInfo` 구조체를 채웁니다.

Vulkan 애플리케이션에 대한 정보를 포함하며, 애플리케이션 이름, 버전, 엔진 이름 및 버전, API 버전을 정의합니다.

```cpp
void createInstance() {
    VkApplicationInfo appInfo{};
    appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    appInfo.pApplicationName = "Hello Triangle";
    appInfo.applicationVersion = VK_MAKE_VERSION(1, 0, 0);
    appInfo.pEngineName = "No Engine";
    appInfo.engineVersion = VK_MAKE_VERSION(1, 0, 0);
    appInfo.apiVersion = VK_API_VERSION_1_0;
}
```

 `appInfo.apiVersion` 는 해당 애플리케이션이 지원을 원하는 vulkan version이다.

장치는 최소한 `apiVersion` 버전 이상의 vulkan 버전을 지원해야 한다. 

`VkInstanceCreateInfo`구조체는 Vulkan 인스턴스를 생성하기 위한 설정 정보를 포함하는 구조체입니다.

```cpp
VkInstanceCreateInfo createInfo{};
createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
createInfo.pApplicationInfo = &appInfo;

uint32_t glfwExtensionCount = 0;
const char** glfwExtensions;
glfwExtensions = glfwGetRequiredInstanceExtensions(&glfwExtensionCount);

createInfo.enabledExtensionCount = glfwExtensionCount;
createInfo.ppEnabledExtensionNames = glfwExtensions;
createInfo.enabledLayerCount = 0;
```

`vkCreateInstance` 함수를 호출하여 인스턴스를 생성합니다. 이 함수는 Vulkan 애플리케이션의 시작점으로, Vulkan 라이브러리와의 상호작용을 설정합니다.

```cpp
VkResult result = vkCreateInstance(&createInfo, nullptr, &instance);
if (result != VK_SUCCESS) {
    throw std::runtime_error("failed to create instance!");
}
```

`vkEnumerateInstanceExtensionProperties` 함수를 사용하여 지원되는 확장 목록을 가져올 수 있습니다.

```cpp
uint32_t extensionCount = 0;
vkEnumerateInstanceExtensionProperties(nullptr, &extensionCount, nullptr);

std::vector<VkExtensionProperties> extensions(extensionCount);
vkEnumerateInstanceExtensionProperties(nullptr, &extensionCount, extensions.data());

std::cout << "available extensions:\n";
for (const auto& extension : extensions) {
    std::cout << '\t' << extension.extensionName << '\n';
}

```

`vkCreateInstance` 호출 시 `VK_ERROR_INCOMPATIBLE_DRIVER` 오류가 발생할 수 있습니다. 이 경우 `VK_KHR_PORTABILITY_subset` 확장을 추가하여 문제를 해결할 수 있습니다.

```cpp
std::vector<const char*> requiredExtensions;
for (uint32_t i = 0; i < glfwExtensionCount; i++) {
    requiredExtensions.emplace_back(glfwExtensions[i]);
}
requiredExtensions.emplace_back(VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME);

createInfo.flags |= VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR;
createInfo.enabledExtensionCount = static_cast<uint32_t>(requiredExtensions.size());
createInfo.ppEnabledExtensionNames = requiredExtensions.data();

if (vkCreateInstance(&createInfo, nullptr, &instance) != VK_SUCCESS) {
    throw std::runtime_error("failed to create instance!");
}
```

1. **정리 작업**: 프로그램 종료 시 `vkDestroyInstance` 함수를 호출하여 인스턴스를 정리합니다.

```cpp
void cleanup() {
    vkDestroyInstance(instance, nullptr);
    glfwDestroyWindow(window);
    glfwTerminate();
}
```