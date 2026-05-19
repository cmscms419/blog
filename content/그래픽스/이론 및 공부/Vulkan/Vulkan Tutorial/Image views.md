# Image views


![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Image views/image.png]]
![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Image views/image 1.png]]

render pipeline에서 swap chain에 있는 것을 포함한 모든 [`VkImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImage.html)를 사용하려면 [`VkImageView`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImageView.html) 객체를 만들어야 합니다. 

image view는 말 그대로 **이미지에 대한 view**입니다. 

이미지에 액세스하는 방법과 이미지의 어느 부분에 액세스해야 하는지(예: 이미지가 밉 매핑 레벨 없이 2D 텍스처 깊이 텍스처로 처리되어야 하는 경우)를 설명합니다.

이 장에서는 나중에 색상 타깃으로 사용할 수 있도록 스왑 체인의 모든 이미지에 대한 기본 이미지 뷰를 생성하는 `createImageViews` 함수를 작성해 보겠습니다.

먼저 이미지 뷰를 저장할 클래스 멤버를 추가합니다:

```c
std::vector<VkImageView> swapChainImageViews;
```

Create the `createImageViews` function and call it right after swap chain creation.

```c
void initVulkan() {
    createInstance();
    setupDebugMessenger();
    createSurface();
    pickPhysicalDevice();
    createLogicalDevice();
    createSwapChain();
    createImageViews();
}

void createImageViews() {

}

```

```c
void createImageViews() {
    swapChainImageViews.resize(swapChainImages.size());

}

```

다음으로, 사이즈 크기 만큼 loop

```c
for (size_t i = 0; i < swapChainImages.size(); i++) {

}
```

이미지 뷰 생성을 위한 파라미터는 [`VkImageViewCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImageViewCreateInfo.html)구조에 지정됩니다. 처음 몇 개의 매개변수는 간단합니다.

```c
VkImageViewCreateInfo createInfo{};
createInfo.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
createInfo.image = swapChainImages[i];
```

`viewType`및 `format`필드는 이미지 데이터를 해석하는 방법을 지정합니다. 
`viewType`매개변수를 사용하면 이미지를 1D 텍스처, 2D 텍스처, 3D 텍스처 및 큐브 맵으로 처리할 수 있습니다.

```c
createInfo.viewType = VK_IMAGE_VIEW_TYPE_2D;
createInfo.format = swapChainImageFormat;
```

`components`필드에서는 색상 채널을 swizzle할 수 있습니다. 예를 들어 모든 채널을 빨간색 채널에 매핑하여 단색 텍스처를 만들 수 있습니다. `0`과 `1`의 상수 값을 채널에 매핑할 수도 있습니다. 여기서는 기본 매핑을 사용하겠습니다.

```c
createInfo.components.r = VK_COMPONENT_SWIZZLE_IDENTITY;
createInfo.components.g = VK_COMPONENT_SWIZZLE_IDENTITY;
createInfo.components.b = VK_COMPONENT_SWIZZLE_IDENTITY;
createInfo.components.a = VK_COMPONENT_SWIZZLE_IDENTITY;
```

`subresourceRange` 필드는 이미지의 용도와 이미지의 어느 부분에 액세스해야 하는지를 설명합니다. 이미지는 밉매핑 레벨이나 여러 레이어 없이 색상 타깃으로 사용됩니다.

```c
createInfo.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
createInfo.subresourceRange.baseMipLevel = 0;
createInfo.subresourceRange.levelCount = 1;
createInfo.subresourceRange.baseArrayLayer = 0;
createInfo.subresourceRange.layerCount = 1;
```

스테레오그래픽 3D 애플리케이션에서 작업하는 경우 여러 레이어가 있는 스왑 체인을 만들 수 있습니다.

그런 다음 서로 다른 레이어에 액세스하여 왼쪽 눈과 오른쪽 눈의 뷰를 나타내는 각 이미지에 대해 여러 이미지 뷰를 만들 수 있습니다.

```c
if (vkCreateImageView(device, &createInfo, nullptr, &swapChainImageViews[i]) != VK_SUCCESS) {
    throw std::runtime_error("failed to create image views!");
}

```

Unlike images, the image views were explicitly created by us, so we need to add a similar loop to destroy them again at the end of the program:

```c
void cleanup() {
    for (auto imageView : swapChainImageViews) {
        vkDestroyImageView(device, imageView, nullptr);
    }

    ...
}

```