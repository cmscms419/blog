# Framebuffers

우리는 지난 몇 장에서 프레임 버퍼에 관해 많이 이야기했고 스왑 체인 이미지와 동일한 형식을 가진 단일 프레임 버퍼를 기대하도록 렌더 패스를 설정했지만, 아직 실제로 프레임 버퍼를 생성하지 않았습니다.

렌더 패스 생성 중에 지정된 첨부 파일은 [`VkFramebuffer`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkFramebuffer.html)객체로 wrapping/하여 바인딩됩니다.  [`VkImageView`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImageView.html)첨부 파일을 나타내는 모든 A framebuffer object를 참조합니다. 우리의 경우에는 단일 첨부 파일, 즉 색상 첨부 파일만 있습니다. 그러나 첨부 파일에 사용해야 하는 이미지는 프레젠테이션을 위해 이미지를 검색할 때 스왑 체인이 반환하는 이미지에 따라 달라집니다. 

즉, 스왑 체인의 모든 이미지에 대한 프레임버퍼를 만들고 drawing time에 검색된 이미지에 해당하는 프레임버퍼를 사용해야 합니다.

이를 위해 `std::vector`프레임 버퍼를 보관할 또 다른 클래스 멤버를 만듭니다.

```c
std::vector<VkFramebuffer> swapChainFramebuffers;
```

We'll create the objects for this array in a new function `createFramebuffers` that is called from `initVulkan` right after creating the graphics pipeline:

```c
void initVulkan() {
    createInstance();
    setupDebugMessenger();
    createSurface();
    pickPhysicalDevice();
    createLogicalDevice();
    createSwapChain();
    createImageViews();
    createRenderPass();
    createGraphicsPipeline();
    createFramebuffers();
}

...

void createFramebuffers() {

}

```

Start by resizing the container to hold all of the framebuffers:

```c
void createFramebuffers() {
    swapChainFramebuffers.resize(swapChainImageViews.size());
}

```

We'll then iterate through the image views and create framebuffers from them:

```c
for (size_t i = 0; i < swapChainImageViews.size(); i++) {
    VkImageView attachments[] = {
        swapChainImageViews[i]
    };

    VkFramebufferCreateInfo framebufferInfo{};
    framebufferInfo.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
    framebufferInfo.renderPass = renderPass;
    framebufferInfo.attachmentCount = 1;
    framebufferInfo.pAttachments = attachments;
    framebufferInfo.width = swapChainExtent.width;
    framebufferInfo.height = swapChainExtent.height;
    framebufferInfo.layers = 1;

    if (vkCreateFramebuffer(device, &framebufferInfo, nullptr, &swapChainFramebuffers[i]) != VK_SUCCESS) {
        throw std::runtime_error("failed to create framebuffer!");
    }
}

```

보시다시피, 프레임버퍼를 만드는 것은 매우 간단합니다. 

 프레임버퍼가 어떤 것과 호환되어야 하는 `renderPass` 지정해야 합니다. 

호환되는 `renderPass`가 있는 프레임버퍼만 사용할 수 있는데, 이는 대략 동일한 수와 유형의 attachments을 사용한다는 것을 의미합니다.

The `width` and `height` parameters are self-explanatory and `layers` refers to the number of layers in image arrays. Our swap chain images are single images, so the number of layers is `1`.

We should delete the framebuffers before the image views and render pass that they are based on, but only after we've finished rendering:

`pAttachment`와`attachmentCount` 매개변수는 `renderPass` array의 respective attachment descriptions 에 바인딩되어야 하는 객체를 `pAttachments`지정합니다 .

`attachmentCount`및 `pAttachments`매개 변수는 렌더 패스 `pAttachment`배열에서 각 respective attachment descriptions에 바인딩해야 하는 [`VkImageView`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImageView.html)객체를 지정합니다.

`width`와 `height`매개변수는 설명이 필요 없으며 레이어는 이미지 배열의 레이어 수를 나타냅니다. 스왑 체인 이미지는 단일 이미지이므로 레이어 수는 1입니다.

```c
void cleanup() {
    for (auto framebuffer : swapChainFramebuffers) {
        vkDestroyFramebuffer(device, framebuffer, nullptr);
    }

    ...
}

```

We've now reached the milestone where we have all of the objects that are required for rendering. In the next chapter we're going to write the first actual drawing commands.