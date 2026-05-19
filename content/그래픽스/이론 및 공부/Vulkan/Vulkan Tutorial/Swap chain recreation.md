# Swap chain recreation

# Introduction

이제 애플리케이션이 삼각형을 성공적으로 그렸지만 아직 제대로 처리하지 못하는 몇 가지 상황이 있습니다. 창 표면이 변경되어 스왑 체인이 더 이상 호환되지 않을 수 있습니다. 이런 일이 발생할 수 있는 이유 중 하나는 창 크기가 변경되기 때문입니다. 이러한 이벤트를 포착하고 스왑 체인을 다시 만들어야 합니다.

# Recreating the swap chain

Create a new `recreateSwapChain` function that calls `createSwapChain` and all of the creation functions for the objects that depend on the swap chain or the window size.

```c
void recreateSwapChain() {
    vkDeviceWaitIdle(device);

    createSwapChain();
    createImageViews();
    createFramebuffers();
}

```

We first call [`vkDeviceWaitIdle`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkDeviceWaitIdle.html), because just like in the last chapter, we shouldn't touch resources that may still be in use. Obviously, we'll have to recreate the swap chain itself. The image views need to be recreated because they are based directly on the swap chain images. Finally, the framebuffers directly depend on the swap chain images, and thus must be recreated as well.

To make sure that the old versions of these objects are cleaned up before recreating them, we should move some of the cleanup code to a separate function that we can call from the `recreateSwapChain` function. Let's call it `cleanupSwapChain`:

지난 장에서와 마찬가지로 아직 사용 중인 리소스를 건드리지 않아야 하므로 먼저 [`vkDeviceWaitIdle`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkDeviceWaitIdle.html)을 호출합니다. 당연히 스왑 체인 자체를 다시 생성해야 합니다. image views는 스왑 체인 이미지를 직접 기반으로 하기 때문에 다시 만들어야 합니다. 마지막으로 franebuffer는 스왑 체인 이미지에 직접적으로 의존하므로 이 역시 다시 만들어야 합니다.

이러한 오브젝트를 다시 생성하기 전에 이전 버전을 정리하기 위해 일부 정리 코드를 `rereateSwapChain`함수에서 호출할 수 있는 별도의 함수로 옮겨야 합니다. 이를 `cleanupSwapChain`이라고 부르겠습니다:

```c
void cleanupSwapChain() {

}

void recreateSwapChain() {
    vkDeviceWaitIdle(device);

    cleanupSwapChain();

    createSwapChain();
    createImageViews();
    createFramebuffers();
}

```

여기서는 단순화를 위해 renderpass를 다시 만들지 않습니다. 

이론 상 애플리케이션의 실행 되는 동안 스왑 체인 이미지 형식이 변경될 수 있습니다. (예 : high dynamic range monitor로 창을 이동하는 경우입니다.)

이를 위해서는 애플리케이션에서 renderpass를 다시 생성하여 dynamic ranges 간의 변경 사항이 제대로 반영되도록 해야 할 수 있습니다.

swap chain refresh의 일부로 다시 생성되는 모든 오브젝트의 정리 코드를 `cleanup`에서 `cleanupSwapChain`으로 옮깁니다:

```c
void cleanupSwapChain() {
    for (size_t i = 0; i < swapChainFramebuffers.size(); i++) {
        vkDestroyFramebuffer(device, swapChainFramebuffers[i], nullptr);
    }

    for (size_t i = 0; i < swapChainImageViews.size(); i++) {
        vkDestroyImageView(device, swapChainImageViews[i], nullptr);
    }

    vkDestroySwapchainKHR(device, swapChain, nullptr);
}

void cleanup() {
    cleanupSwapChain();

    vkDestroyPipeline(device, graphicsPipeline, nullptr);
    vkDestroyPipelineLayout(device, pipelineLayout, nullptr);

    vkDestroyRenderPass(device, renderPass, nullptr);

    for (size_t i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
        vkDestroySemaphore(device, renderFinishedSemaphores[i], nullptr);
        vkDestroySemaphore(device, imageAvailableSemaphores[i], nullptr);
        vkDestroyFence(device, inFlightFences[i], nullptr);
    }

    vkDestroyCommandPool(device, commandPool, nullptr);

    vkDestroyDevice(device, nullptr);

    if (enableValidationLayers) {
        DestroyDebugUtilsMessengerEXT(instance, debugMessenger, nullptr);
    }

    vkDestroySurfaceKHR(instance, surface, nullptr);
    vkDestroyInstance(instance, nullptr);

    glfwDestroyWindow(window);

    glfwTerminate();
}

```

`chooseSwapExtent`에서는 이미 새 창 해상도를 쿼리(요청)하여 스왑 체인 이미지가 (새로 만들어진)적절한 크기인지 확인하므로 `chooseSwapExtent`를 수정할 필요가 없습니다(스왑 체인을 만들 때 이미 `glfwGetFramebufferSize`를 사용하여 surface의 해상도를 픽셀 단위로 가져왔음을 기억하세요).

스왑 체인을 다시 만드는 데 필요한 것은 이것뿐입니다! 하지만 이 방법의 단점은 새 스왑 체인을 만들기 전에 모든 렌더링을 중지해야 한다는 것입니다. 이전 스왑 체인의 이미지에 대한 그리기 명령이 아직 실행 중인 상태에서 새 스왑 체인을 만들 수 있습니다. 이전 스왑 체인을 `VkSwapchainCreateInfoKHR`구조체의 `oldSwapChain`필드에 전달하고 사용을 마치자마자 이전 스왑 체인을 소멸시켜야 합니다.

# Suboptimal or out-of-date swap chain

이제 스왑 체인 재생성이 필요한 시점을 파악하고 새로운 `recreateSwapChain` 함수를 호출하기만 하면 됩니다. 다행히도 Vulkan은 보통 프레젠테이션 중에 스왑 체인이 더 이상 적절하지 않다고 알려줍니다. `vkAcquireNextImageKHR` 및 `vkQueuePresentKHR`함수는 이를 나타내기 위해 다음과 같은 특수 값을 반환할 수 있습니다.

- `VK_ERROR_OUT_OF_DATE_KHR`: 스왑 체인이 surface 와 호환되지 않아 더 이상 렌더링에 사용할 수 없습니다. 일반적으로 창 크기를 조정한 후에 발생합니다.
- `VK_SUBOPTIMAL_KHR`: 스왑 체인을 사용하여 surface에 성공적으로 표시할 수 있지만, surface 속성이 더 이상 정확히 일치하지 않습니다.

```c
VkResult result = vkAcquireNextImageKHR(device, swapChain, UINT64_MAX, imageAvailableSemaphores[currentFrame], VK_NULL_HANDLE, &imageIndex);

if (result == VK_ERROR_OUT_OF_DATE_KHR) {
    recreateSwapChain();
    return;
} else if (result != VK_SUCCESS && result != VK_SUBOPTIMAL_KHR) {
    throw std::runtime_error("failed to acquire swap chain image!");
}

```

이미지 획득을 시도할 때 스왑 체인이 오래된 것으로 판명되면 더 이상 이미지를 제시할 수 없습니다. 따라서 즉시 스왑 체인을 다시 생성하고 다음 `drawFrame` 호출에서 다시 시도해야 합니다.

스왑 체인이 차선책인 경우에도 그렇게 할 수 있지만, 이미 이미지를 확보한 경우에는 진행하기로 결정했습니다. `VK_SUCCESS` 와 `VK_SUBOPTIMAL_KHR`은 모두 “success” 반환 코드로 간주됩니다.

```c
result = vkQueuePresentKHR(presentQueue, &presentInfo);

if (result == VK_ERROR_OUT_OF_DATE_KHR || result == VK_SUBOPTIMAL_KHR) {
    recreateSwapChain();
} else if (result != VK_SUCCESS) {
    throw std::runtime_error("failed to present swap chain image!");
}

currentFrame = (currentFrame + 1) % MAX_FRAMES_IN_FLIGHT;

```

The `vkQueuePresentKHR` function returns the same values with the same meaning. In this case we will also recreate the swap chain if it is suboptimal, because we want the best possible result.

`vkQueuePresentKHR` 함수는 동일한 의미를 가진 동일한 값을 반환합니다. 이 경우 최상의 결과를 원하기 때문에 스왑 체인이 차선책인 경우 다시 생성합니다.

# Fixing a deadlock

지금 코드를 실행하려고 하면 deadlock 상태가 발생할 수 있습니다. 코드를 디버깅하면 애플리케이션이 `vkWaitForFences`에 도달하지만 그 이후에는 계속 진행하지 못한다는 것을 알 수 있습니다. 이는 `vkAcquireNextImageKHR`이 `VK_ERROR_OUT_OF_DATE_KHR`을 반환하면 스왑체인을 다시 생성한 다음 `drawFrame`에서 반환하기 때문입니다. 하지만 그 전에 현재 프레임의 fence가 대기하고 리셋됩니다. 즉시 반환하기 때문에 실행을 위해 제출된 작업이 없고 펜스에 신호가 전송되지 않으므로 [`vkWaitForFences`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkWaitForFences.html)가 영원히 중지됩니다.

다행히도 간단한 해결 방법이 있습니다. 

펜스로 작업을 제출할 것이 확실해질 때까지 펜스 재설정을 지연시키면 됩니다. 따라서 일찍 돌아가도 펜스는 여전히 신호를 보내고 다음에 같은 펜스 객체를 사용할 때 [`vkWaitForFences`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkWaitForFences.html)가 교착 상태에 빠지지 않습니다.

The beginning of `drawFrame` should now look like this:

```c
vkWaitForFences(device, 1, &inFlightFences[currentFrame], VK_TRUE, UINT64_MAX);

uint32_t imageIndex;
VkResult result = vkAcquireNextImageKHR(device, swapChain, UINT64_MAX, imageAvailableSemaphores[currentFrame], VK_NULL_HANDLE, &imageIndex);

if (result == VK_ERROR_OUT_OF_DATE_KHR) {
    recreateSwapChain();
    return;
} else if (result != VK_SUCCESS && result != VK_SUBOPTIMAL_KHR) {
    throw std::runtime_error("failed to acquire swap chain image!");
}

// Only reset the fence if we are submitting work
vkResetFences(device, 1, &inFlightFences[currentFrame]);

```

# Handling resizes explicitly

많은 드라이버와 플랫폼에서 창 크기를 조정한 후 `VK_ERROR_OUT_OF_DATE_KHR`이 자동으로 트리거되지만, 반드시 발생한다고 보장할 수는 없습니다. 따라서 크기 조정을 명시적으로 처리할 수 있도록 몇 가지 코드를 추가하겠습니다.

먼저 크기 조정이 발생했음을 알리는 새 멤버 변수를 추가합니다:

```c
std::vector<VkFence> inFlightFences;

bool framebufferResized = false;

```

The `drawFrame` function should then be modified to also check for this flag:

```c
if (result == VK_ERROR_OUT_OF_DATE_KHR || result == VK_SUBOPTIMAL_KHR || framebufferResized) {
    framebufferResized = false;
    recreateSwapChain();
} else if (result != VK_SUCCESS) {
    ...
}

```

세마포어가 일관된 상태에 있는지 확인하기 위해 `vkQueuePresentKHR` 이후에 이 작업을 수행하는 것이 중요합니다. 그렇지 않으면 신호된 세마포어가 제대로 대기하지 않을 수 있습니다. 이제 실제로 크기 변경을 감지하기 위해 GLFW 프레임워크의 `glfwSetFramebufferSizeCallback` 함수를 사용하여 콜백을 설정할 수 있습니다:

```c
void initWindow() {
    glfwInit();

    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);

    window = glfwCreateWindow(WIDTH, HEIGHT, "Vulkan", nullptr, nullptr);
    glfwSetFramebufferSizeCallback(window, framebufferResizeCallback);
}

static void framebufferResizeCallback(GLFWwindow* window, int width, int height) {

}

```

정적 함수를 callback으로 만드는 이유는 GLFW가 `HelloTriangleApplication` 인스턴스에 대한 오른쪽 포인터를 가진 멤버 함수를 올바르게 호출하는 방법을 모르기 때문입니다.

하지만 callback에 `GLFWwindow`에 대한 참조가 있고, 그 안에 임의의 포인터를 저장할 수 있는 또 다른 GLFW 함수인 `glfwSetWindowUserPointer`가 있습니다:

```c
window = glfwCreateWindow(WIDTH, HEIGHT, "Vulkan", nullptr, nullptr);
glfwSetWindowUserPointer(window, this);
glfwSetFramebufferSizeCallback(window, framebufferResizeCallback);

```

This value can now be retrieved from within the callback with `glfwGetWindowUserPointer` to properly set the flag:

```c
static void framebufferResizeCallback(GLFWwindow* window, int width, int height) {
    auto app = reinterpret_cast<HelloTriangleApplication*>(glfwGetWindowUserPointer(window));
    app->framebufferResized = true;
}

```

Now try to run the program and resize the window to see if the framebuffer is indeed resized properly with the window.

# Handling minimization

스왑 체인이 유효하지 않게 되는 또 다른 경우가 있는데, 바로 창 크기 조정의 특수한 종류인 창 최소화입니다. 이 경우 프레임 버퍼 크기가 `0`이 되기 때문에 특별합니다. 이 튜토리얼에서는 recreateSwapChain 함수를 확장하여 창이 다시 전경에 나타날 때까지 일시 정지하여 이 문제를 처리합니다:

```c
void recreateSwapChain() {
    int width = 0, height = 0;
    glfwGetFramebufferSize(window, &width, &height);
    while (width == 0 || height == 0) {
        glfwGetFramebufferSize(window, &width, &height);
        glfwWaitEvents();
    }

    vkDeviceWaitIdle(device);

    ...
}

```

The initial call to `glfwGetFramebufferSize` handles the case where the size is already correct and `glfwWaitEvents` would have nothing to wait on.

크기가 이미 정확하고 대기할 것이 없는 경우 `glfwGetFramebufferSize`에 대한 초기 호출은 `glfwWaitEvents`가 처리합니다.

Congratulations, you've now finished your very first well-behaved Vulkan program! In the next chapter we're going to get rid of the hardcoded vertices in the vertex shader and actually use a vertex buffer.