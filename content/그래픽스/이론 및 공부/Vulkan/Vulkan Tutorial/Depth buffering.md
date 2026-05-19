# Depth buffering

- [Introduction](https://vulkan-tutorial.com/Depth_buffering#page_Introduction)
- [3D geometry](https://vulkan-tutorial.com/Depth_buffering#page_3D-geometry)
- [Depth image and view](https://vulkan-tutorial.com/Depth_buffering#page_Depth-image-and-view)
    - [Explicitly transitioning the depth image](https://vulkan-tutorial.com/Depth_buffering#page_Explicitly-transitioning-the-depth-image)
- [Render pass](https://vulkan-tutorial.com/Depth_buffering#page_Render-pass)
- [Framebuffer](https://vulkan-tutorial.com/Depth_buffering#page_Framebuffer)
- [Clear values](https://vulkan-tutorial.com/Depth_buffering#page_Clear-values)
- [Depth and stencil state](https://vulkan-tutorial.com/Depth_buffering#page_Depth-and-stencil-state)
- [Handling window resize](https://vulkan-tutorial.com/Depth_buffering#page_Handling-window-resize)

# Introduction

지금까지 작업한 지오메트리는 3D로 투영되었지만 여전히 완전히 평면적입니다.

이 장에서는 3D 메시를 준비하기 위해 위치에 Z 좌표를 추가하겠습니다.

이 세 번째 좌표를 사용하여 현재 사각형 위에 사각형을 배치하여 지오메트리가 깊이별로 정렬되지 않았을 때 발생하는 문제를 살펴보겠습니다.

# 3D geometry

Change the `Vertex` struct to use a 3D vector for the position, and update the `format` in the corresponding [`VkVertexInputAttributeDescription`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkVertexInputAttributeDescription.html):

```c
struct Vertex {
    glm::vec3 pos;
    glm::vec3 color;
    glm::vec2 texCoord;

    ...

    static std::array<VkVertexInputAttributeDescription, 3> getAttributeDescriptions() {
        std::array<VkVertexInputAttributeDescription, 3> attributeDescriptions{};

        attributeDescriptions[0].binding = 0;
        attributeDescriptions[0].location = 0;
        attributeDescriptions[0].format = VK_FORMAT_R32G32B32_SFLOAT;
        attributeDescriptions[0].offset = offsetof(Vertex, pos);

        ...
    }
};

```

Next, update the vertex shader to accept and transform 3D coordinates as input. Don't forget to recompile it afterwards!

```glsl
layout(location = 0) in vec3 inPosition;

...

void main() {
    gl_Position = ubo.proj * ubo.view * ubo.model * vec4(inPosition, 1.0);
    fragColor = inColor;
    fragTexCoord = inTexCoord;
}

```

Lastly, update the `vertices` container to include Z coordinates:

```c
const std::vector<Vertex> vertices = {
    {{-0.5f, -0.5f, 0.0f}, {1.0f, 0.0f, 0.0f}, {0.0f, 0.0f}},
    {{0.5f, -0.5f, 0.0f}, {0.0f, 1.0f, 0.0f}, {1.0f, 0.0f}},
    {{0.5f, 0.5f, 0.0f}, {0.0f, 0.0f, 1.0f}, {1.0f, 1.0f}},
    {{-0.5f, 0.5f, 0.0f}, {1.0f, 1.0f, 1.0f}, {0.0f, 1.0f}}
};

```

If you run your application now, then you should see exactly the same result as before.

It's time to add some extra geometry to make the scene more interesting, and to demonstrate the problem that we're going to tackle in this chapter. 

Duplicate the vertices to define positions for a square right under the current one like this:

![](attachments/extra_square.svg)

Use Z coordinates of `-0.5f` and add the appropriate indices for the extra square:

```c
const std::vector<Vertex> vertices = {
    {{-0.5f, -0.5f, 0.0f}, {1.0f, 0.0f, 0.0f}, {0.0f, 0.0f}},
    {{0.5f, -0.5f, 0.0f}, {0.0f, 1.0f, 0.0f}, {1.0f, 0.0f}},
    {{0.5f, 0.5f, 0.0f}, {0.0f, 0.0f, 1.0f}, {1.0f, 1.0f}},
    {{-0.5f, 0.5f, 0.0f}, {1.0f, 1.0f, 1.0f}, {0.0f, 1.0f}},

    {{-0.5f, -0.5f, -0.5f}, {1.0f, 0.0f, 0.0f}, {0.0f, 0.0f}},
    {{0.5f, -0.5f, -0.5f}, {0.0f, 1.0f, 0.0f}, {1.0f, 0.0f}},
    {{0.5f, 0.5f, -0.5f}, {0.0f, 0.0f, 1.0f}, {1.0f, 1.0f}},
    {{-0.5f, 0.5f, -0.5f}, {1.0f, 1.0f, 1.0f}, {0.0f, 1.0f}}
};

const std::vector<uint16_t> indices = {
    0, 1, 2, 2, 3, 0,
    4, 5, 6, 6, 7, 4
};

```

Run your program now and you'll see something resembling an Escher illustration:

![](attachments/depth_issues.png)

The problem is that the fragments of the lower square are drawn over the fragments of the upper square, simply because it comes later in the index array.

문제는 아래쪽 사각형의 조각이 위쪽 사각형의 조각 위에 그려지는데, 이는 단순히 인덱스 배열에서 나중에 오기 때문입니다.

There are two ways to solve this:

- Sort all of the draw calls by depth from back to front
- 모든 그리기 호출을 뒤쪽에서 앞쪽으로 depth별로 Sort합니다.
- 깊이 버퍼와 함께 깊이 테스트 사용

The first approach is commonly used for drawing transparent objects, because order-independent transparency is a difficult challenge to solve.

첫 번째 접근 방식은 순서와 무관한 투명도는 해결하기 어려운 문제이므로 투명 오브젝트를 그릴 때 일반적으로 사용됩니다.

그러나 depth별로 fragments을 정렬하는 문제는 *depth buffer*를 사용하여 훨씬 더 일반적으로 해결할 수 있습니다.

depth buffer는 the color attachment가 모든 위치의 색상을 저장하는 것과 마찬가지로 모든 위치의 깊이를 저장하는 추가 attachment입니다.

rasterizer가 fragment을 생성할 때마다 depth test는 새 fragment이 이전 fragment보다 더 가까운지 확인합니다.

그렇지 않은 경우 새 fragment은 폐기됩니다.

A fragment that passes the depth test writes its own depth to the depth buffer.

depth test를 통과한 fragment은 자체 depth를 depth buffer에 기록합니다.

It is possible to manipulate this value from the fragment shader, just like you can manipulate the color output.

색상 출력을 조작하는 것과 마찬가지로 fragment shader에서 이 값을 조작할 수 있습니다.

```c
#define GLM_FORCE_RADIANS
#define GLM_FORCE_DEPTH_ZERO_TO_ONE
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
```

The perspective projection matrix generated by GLM will use the OpenGL depth range of `-1.0` to `1.0` by default. We need to configure it to use the Vulkan range of `0.0` to `1.0` using the `GLM_FORCE_DEPTH_ZERO_TO_ONE` definition.

GLM에서 생성된 투시 projection matrix은 기본적으로 `-1.0` ~ `1.0`의 OpenGL 깊이 범위를 사용합니다. `GLM_FORCE_DEPTH_ZERO_TO_ONE` 정의를 사용하여 `0.0`에서 `1.0`의 Vulkan 범위를 사용하도록 구성해야 합니다.

# Depth image and view

A depth attachment is based on an image, just like the color attachment.

차이점은 스왑 체인이 자동으로 깊이 이미지를 생성하지 않는다는 점입니다. 한 번에 하나의 드로잉 작업만 실행되기 때문에 하나의 깊이 이미지만 필요합니다.

The depth image will again require the trifecta of resources: image, memory and image view.

```c
VkImage depthImage;
VkDeviceMemory depthImageMemory;
VkImageView depthImageView;
```

Create a new function `createDepthResources` to set up these resources:

```c
void initVulkan() {
    ...
    createCommandPool();
    createDepthResources();
    createTextureImage();
    ...
}

...

void createDepthResources() {

}

```

Creating a depth image is fairly straightforward. It should have the same resolution as the color attachment, defined by the swap chain extent, an image usage appropriate for a depth attachment, optimal tiling and device local memory.

depth image를 만드는 방법은 매우 간단합니다. 

swap chain의 `extent`, depth image에 적합한 이미지 `usage`, 최적의 타일링 및 디바이스 로컬 메모리에 `optimal` 의해 정의된 색상 첨부 파일과 동일한 해상도를 가져야 합니다.

The only question is: what is the right format for a depth image? The format must contain a depth component, indicated by `_D??_` in the `VK_FORMAT_`.

유일한 질문은 심도 이미지에 적합한 형식은 무엇일까요? 형식에는 `VK_FORMAT_`에 `_D???_`로 표시된 깊이 구성 요소가 포함되어야 합니다.

texture image와 달리 프로그램에서 텍셀에 직접 액세스하지 않으므로 특정 형식이 반드시 필요한 것은 아닙니다.

It just needs to have a reasonable accuracy, at least 24 bits is common in real-world applications. 

실제 애플리케이션에서는 최소 24비트가 일반적이며, 적당한 정확도만 있으면 됩니다.There are several formats that fit this requirement:

- `VK_FORMAT_D32_SFLOAT`: 32-bit float for depth
- `VK_FORMAT_D32_SFLOAT_S8_UINT`: 32-bit signed float for depth and 8 bit stencil component
- `VK_FORMAT_D24_UNORM_S8_UINT`: 24-bit float for depth and 8 bit stencil component

The stencil component is used for [stencil tests](https://en.wikipedia.org/wiki/Stencil_buffer), which is an additional test that can be combined with depth testing. We'll look at this in a future chapter.

스텐실 구성 요소는 깊이 테스트와 결합할 수 있는 추가 테스트인 [stencil tests](https://en.wikipedia.org/wiki/Stencil_buffer)에 사용됩니다. 이에 대해서는 다음 장에서 살펴보겠습니다.

We could simply go for the `VK_FORMAT_D32_SFLOAT` format, because support for it is extremely common (see the hardware database), but it's nice to add some extra flexibility to our application where possible. 

가장 바람직한 것부터 가장 바람직하지 않은 것까지 순서대로 후보 형식 목록을 가져와 어떤 형식이 가장 먼저 지원되는지 확인하는 `findSupportedFormat`함수를 작성해 보겠습니다:

```c
VkFormat findSupportedFormat(const std::vector<VkFormat>& candidates, VkImageTiling tiling, VkFormatFeatureFlags features) {

}

```

The support of a format depends on the tiling mode and usage, so we must also include these as parameters. The support of a format can be queried using the [`vkGetPhysicalDeviceFormatProperties`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkGetPhysicalDeviceFormatProperties.html) function:

format의 여부는 tiling mode와 usage에 따라 달라지므로 이러한 사항도 매개변수로 포함해야 합니다. 형식 지원 여부는 [`vkGetPhysicalDeviceFormatProperties`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkGetPhysicalDeviceFormatProperties.html)함수를 사용하여 쿼리할 수 있습니다:

```c
for (VkFormat format : candidates) {
    VkFormatProperties props;
    vkGetPhysicalDeviceFormatProperties(physicalDevice, format, &props);
}
```

The [`VkFormatProperties`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkFormatProperties.html) struct contains three fields:

- `linearTilingFeatures`:  linear tiling으로 지원되는 사용 사례
- `optimalTilingFeatures`: optimal tiling으로 지원되는 사용 사례
- `bufferFeatures`: 버퍼에 지원되는 사용 사례

Only the first two are relevant here, and the one we check depends on the `tiling` parameter of the function:

여기서는 처음 두 개만 관련이 있으며, 함수의`tiling` 매개변수에 따라 확인해야 하는 것은 다릅니다:

```c
if (tiling == VK_IMAGE_TILING_LINEAR && (props.linearTilingFeatures & features) == features) {
    return format;
} else if (tiling == VK_IMAGE_TILING_OPTIMAL && (props.optimalTilingFeatures & features) == features) {
    return format;
}
```

후보 format 중 원하는 usage을 지원하는 format이 없는 경우 특수 값을 반환하거나 예외를 던질 수 있습니다:

```c
VkFormat findSupportedFormat(const std::vector<VkFormat>& candidates, VkImageTiling tiling, VkFormatFeatureFlags features) {
    for (VkFormat format : candidates) {
        VkFormatProperties props;
        vkGetPhysicalDeviceFormatProperties(physicalDevice, format, &props);

        if (tiling == VK_IMAGE_TILING_LINEAR && (props.linearTilingFeatures & features) == features) {
            return format;
        } else if (tiling == VK_IMAGE_TILING_OPTIMAL && (props.optimalTilingFeatures & features) == features) {
            return format;
        }
    }

    throw std::runtime_error("failed to find supported format!");
}

```

We'll use this function now to create a `findDepthFormat` helper function to select a format with a depth component that supports usage as depth attachment:

```c
VkFormat findDepthFormat() {
    return findSupportedFormat(
        {VK_FORMAT_D32_SFLOAT, VK_FORMAT_D32_SFLOAT_S8_UINT, VK_FORMAT_D24_UNORM_S8_UINT},
        VK_IMAGE_TILING_OPTIMAL,
        VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT
    );
}
```

Make sure to use the `VK_FORMAT_FEATURE_` flag instead of `VK_IMAGE_USAGE_` in this case.

이 경우 `VK_IMAGE_USAGE_` 대신 `VK_FORMAT_FEATURE_` 플래그를 사용해야 합니다.

All of these candidate formats contain a depth component, but the latter two also contain a stencil component.

이 후보 format은 모두 depth component 요소를 포함하지만, 후자의 두 format에는 스텐실 구성 요소도 포함되어 있습니다.

We won't be using that yet, but we do need to take that into account when performing layout transitions on images with these formats. 

나중을 위해서, 스텐실 있는 것을 고른다.

Add a simple helper function that tells us if the chosen depth format contains a stencil component:

```c
bool hasStencilComponent(VkFormat format) {
    return format == VK_FORMAT_D32_SFLOAT_S8_UINT || format == VK_FORMAT_D24_UNORM_S8_UINT;
}

```

Call the function to find a depth format from `createDepthResources`:

```c
VkFormat depthFormat = findDepthFormat();

```

We now have all the required information to invoke our `createImage` and `createImageView` helper functions:

```c
createImage(swapChainExtent.width, swapChainExtent.height, depthFormat, VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, depthImage, depthImageMemory);
depthImageView = createImageView(depthImage, depthFormat);

```

However, the `createImageView` function currently assumes that the subresource is always the `VK_IMAGE_ASPECT_COLOR_BIT`, so we will need to turn that field into a parameter:

그러나 `createImageView` 함수는 현재 하위 리소스가 항상 `VK_IMAGE_ASPECT_COLOR_BIT`이라고 가정하므로 해당 필드를 매개변수로 전환해야 합니다:

```c
VkImageView createImageView(VkImage image, VkFormat format, VkImageAspectFlags aspectFlags) {
    ...
    viewInfo.subresourceRange.aspectMask = aspectFlags;
    ...
}

```

Update all calls to this function to use the right aspect:

```c
swapChainImageViews[i] = createImageView(swapChainImages[i], swapChainImageFormat, VK_IMAGE_ASPECT_COLOR_BIT);
...
depthImageView = createImageView(depthImage, depthFormat, VK_IMAGE_ASPECT_DEPTH_BIT);
...
textureImageView = createImageView(textureImage, VK_FORMAT_R8G8B8A8_SRGB, VK_IMAGE_ASPECT_COLOR_BIT);

```

That's it for creating the depth image. We don't need to map it or copy another image to it, because we're going to clear it at the start of the render pass like the color attachment.

깊이 이미지 생성은 여기까지입니다. 색상 어태치먼트처럼 렌더링 패스가 시작될 때 지울 것이므로 매핑하거나 다른 이미지를 복사할 필요가 없습니다.

# Explicitly transitioning the depth image

렌더 패스에서 처리할 것이므로 layout of the image을 depth attachment로 명시적으로 전환할 필요가 없습니다.

그러나 완전성을 위해 이 섹션에서 프로세스를 계속 설명하겠습니다. 원한다면 건너뛰어도 됩니다.

Make a call to `transitionImageLayout` at the end of the `createDepthResources` function like so:

다음과 같이 `createDepthResources`함수의 마지막에 `transitionImageLayout`을 호출합니다:

```c
transitionImageLayout(depthImage, depthFormat, VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL);
```

The undefined layout can be used as initial layout, because there are no existing depth image contents that matter.

undefined layout은 기존 깊이 이미지 콘텐츠가 없으므로 initial layout으로 사용할 수 있습니다.

We need to update some of the logic in `transitionImageLayout` to use the right subresource aspect:

```c
if (newLayout == VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL) {
    barrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_DEPTH_BIT;

    if (hasStencilComponent(format)) {
        barrier.subresourceRange.aspectMask |= VK_IMAGE_ASPECT_STENCIL_BIT;
    }
} else {
    barrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
}

```

Although we're not using the stencil component, we do need to include it in the layout transitions of the depth image.

Finally, add the correct access masks and pipeline stages:

```c
if (oldLayout == VK_IMAGE_LAYOUT_UNDEFINED && newLayout == VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL) {
    barrier.srcAccessMask = 0;
    barrier.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;

    sourceStage = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
    destinationStage = VK_PIPELINE_STAGE_TRANSFER_BIT;
} else if (oldLayout == VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL && newLayout == VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL) {
    barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    barrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;

    sourceStage = VK_PIPELINE_STAGE_TRANSFER_BIT;
    destinationStage = VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT;
} else if (oldLayout == VK_IMAGE_LAYOUT_UNDEFINED && newLayout == VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL) {
    barrier.srcAccessMask = 0;
    barrier.dstAccessMask = VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT | VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;

    sourceStage = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
    destinationStage = VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT;
} else {
    throw std::invalid_argument("unsupported layout transition!");
}

```

The depth buffer will be read from to perform depth tests to see if a fragment is visible, and will be written to when a new fragment is drawn. The reading happens in the `VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT` stage and the writing in the `VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT`. 

depth buffer는 fragment가 보이는지 확인하기 위해 depth tests를 수행하기 위해 **읽혀**지고, 새 fragment가 그려질 때 **쓰여**집니다. 읽기는 `VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT` 단계에서, 쓰기는 `VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT`에서 이루어집니다.

You should pick the earliest pipeline stage that matches the specified operations, so that it is ready for usage as depth attachment when it needs to be.

지정된 작업과 일치하는 가장 빠른 파이프라인 단계를 선택하여 필요할 때 깊이 첨부 파일로 사용할 수 있도록 준비해야 합니다.

# Render pass

We're now going to modify `createRenderPass` to include a depth attachment. First specify the [`VkAttachmentDescription`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkAttachmentDescription.html):

이제 depth attachment를 포함하도록 `createRenderPass`를 수정하겠습니다. 먼저 [`VkAttachmentDescription`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkAttachmentDescription.html)을 지정합니다:

```c
VkAttachmentDescription depthAttachment{};
depthAttachment.format = findDepthFormat();
depthAttachment.samples = VK_SAMPLE_COUNT_1_BIT;
depthAttachment.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
depthAttachment.storeOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
depthAttachment.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
depthAttachment.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
depthAttachment.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
depthAttachment.finalLayout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;

```

The `format` should be the same as the depth image itself.

`format`은 깊이 이미지 자체와 동일해야 합니다.

This time we don't care about storing the depth data (`storeOp`), because it will not be used after drawing has finished.

이번에는 드로잉이 완료된 후에는 깊이 데이터를 사용하지 않으므로 깊이 데이터(`storeOp`)를 저장하는 데 신경 쓰지 않습니다.

This may allow the hardware to perform additional optimizations. Just like the color buffer, we don't care about the previous depth contents, so we can use `VK_IMAGE_LAYOUT_UNDEFINED` as `initialLayout`.

이렇게 하면 하드웨어가 추가 최적화를 수행할 수 있습니다. 컬러 버퍼와 마찬가지로 이전 깊이 콘텐츠는 신경 쓰지 않으므로 `VK_IMAGE_LAYOUT_UNDEFINED`를 `initialLayout`으로 사용할 수 있습니다.

```c
VkAttachmentReference depthAttachmentRef{};
depthAttachmentRef.attachment = 1;
depthAttachmentRef.layout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
```

Add a reference to the attachment for the first (and only) subpass:

```c
VkSubpassDescription subpass{};
subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
subpass.colorAttachmentCount = 1;
subpass.pColorAttachments = &colorAttachmentRef;
subpass.pDepthStencilAttachment = &depthAttachmentRef;
```

Unlike color attachments, a subpass can only use a single depth (+stencil) attachment. It wouldn't really make any sense to do depth tests on multiple buffers.

color attachments와 달리 subpass는 하나의 깊이(+스텐실) attachments만 사용할 수 있습니다. 여러 버퍼에서 depth tests를 수행하는 것은 의미가 없습니다.

```c
std::array<VkAttachmentDescription, 2> attachments = {colorAttachment, depthAttachment};
VkRenderPassCreateInfo renderPassInfo{};
renderPassInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
renderPassInfo.attachmentCount = static_cast<uint32_t>(attachments.size());
renderPassInfo.pAttachments = attachments.data();
renderPassInfo.subpassCount = 1;
renderPassInfo.pSubpasses = &subpass;
renderPassInfo.dependencyCount = 1;
renderPassInfo.pDependencies = &dependency;
```

Next, update the [`VkSubpassDependency`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkSubpassDependency.html) struct to refer to both attachments.

```c
dependency.srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT;
dependency.dstStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT;
dependency.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT | VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;
```

Finally, we need to extend our subpass dependencies to make sure that there is no conflict between the transitioning of the depth image and it being cleared as part of its load operation.

마지막으로 서브패스 종속성을 확장하여 깊이 이미지의 전환과 로드 작업의 일부로 지워지는 것 사이에 충돌이 없는지 확인해야 합니다.

The depth image is first accessed in the early fragment test pipeline stage and because we have a load operation that *clears*, we should specify the access mask for writes.

초기 조각 테스트 파이프라인 단계에서 깊이 이미지에 처음 액세스하고 로드 작업을 *clears이므*로 쓰기에 대한 액세스 마스크를 지정해야 합니다.

# Framebuffer

The next step is to modify the framebuffer creation to bind the depth image to the depth attachment. Go to `createFramebuffers` and specify the depth image view as second attachment:

```c
std::array<VkImageView, 2> attachments = {
    swapChainImageViews[i],
    depthImageView
};

VkFramebufferCreateInfo framebufferInfo{};
framebufferInfo.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
framebufferInfo.renderPass = renderPass;
framebufferInfo.attachmentCount = static_cast<uint32_t>(attachments.size());
framebufferInfo.pAttachments = attachments.data();
framebufferInfo.width = swapChainExtent.width;
framebufferInfo.height = swapChainExtent.height;
framebufferInfo.layers = 1;

```

The color attachment differs for every swap chain image, but the same depth image can be used by all of them because only a single subpass is running at the same time due to our semaphores.

스왑 체인 이미지마다 색상은 다르지만, 세마포어로 인해 하나의 서브패스만 동시에 실행되기 때문에 동일한 심도 이미지를 모두 사용할 수 있습니다.

You'll also need to move the call to `createFramebuffers` to make sure that it is called after the depth image view has actually been created:

또한 깊이 이미지 뷰가 실제로 생성된 후에 호출되도록 `createFramebuffers`로 호출을 이동해야 합니다:

```c
void initVulkan() {
    ...
    createDepthResources();
    createFramebuffers();
    ...
}

```

# Clear values

Because we now have multiple attachments with `VK_ATTACHMENT_LOAD_OP_CLEAR`, we also need to specify multiple clear values. Go to `recordCommandBuffer` and create an array of [`VkClearValue`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkClearValue.html) structs:

이제 `VK_ATTACHMENT_LOAD_OP_CLEAR`를 사용하는 첨부 파일이 여러 개 있으므로 여러 개의 지우기 값도 지정해야 합니다. `recordCommandBuffer`로 이동하여 [`VkClearValue`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkClearValue.html) 구조체 배열을 생성합니다:

```c
std::array<VkClearValue, 2> clearValues{};
clearValues[0].color = {{0.0f, 0.0f, 0.0f, 1.0f}};
clearValues[1].depthStencil = {1.0f, 0};

renderPassInfo.clearValueCount = static_cast<uint32_t>(clearValues.size());
renderPassInfo.pClearValues = clearValues.data();
```

vulkan에서 depth buffer의 깊이 범위는 `0.0`~`1.0`으로, `1.0`은 far view plane 에, `0.0`은 near view plane 에 위치합니다. depth buffer의 각 지점의 초기 값은 가능한 가장 먼 깊이인 `1.0`이 되어야 합니다.

`clearValues`의 순서는 attachments의 순서와 동일해야 한다는 점에 유의하세요.

# Depth and stencil state

The depth attachment is ready to be used now, but depth testing still needs to be enabled in the graphics pipeline. It is configured through the [`VkPipelineDepthStencilStateCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineDepthStencilStateCreateInfo.html) struct:

depth attachment는 이제 사용할 준비가 되었지만 graphics pipeline에서 depth testing를 활성화해야 합니다. 이는 [`VkPipelineDepthStencilStateCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineDepthStencilStateCreateInfo.html)구조체를 통해 구성됩니다:

```c
VkPipelineDepthStencilStateCreateInfo depthStencil{};
depthStencil.sType = VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO;
depthStencil.depthTestEnable = VK_TRUE;
depthStencil.depthWriteEnable = VK_TRUE;

```

`depthTestEnable`필드는 새 조각의 깊이를 깊이 버퍼와 비교하여 폐기 여부를 확인할지 여부를 지정합니다.

`depthWriteEnable` 필드는 깊이 테스트를 통과한 fragment의 새 깊이를 실제로 깊이 버퍼에 기록할지 여부를 지정합니다.

```c
depthStencil.depthCompareOp = VK_COMPARE_OP_LESS;
```

The `depthCompareOp` field specifies the comparison that is performed to keep or discard fragments.

`depthCompareOp`필드는 조각을 유지하거나 삭제하기 위해 수행되는 비교를 지정합니다.

We're sticking to the convention of lower depth = closer, so the depth of new fragments should be *less*.

우리는 깊이가 낮을수록 더 가깝다는 규칙(depth = closer)을 고수하고 있으므로 새 fragments 의 깊이는 더 작아야 합니다.

```c
depthStencil.depthBoundsTestEnable = VK_FALSE;
depthStencil.minDepthBounds = 0.0f; // Optional
depthStencil.maxDepthBounds = 1.0f; // Optional
```

The `depthBoundsTestEnable`, `minDepthBounds` and `maxDepthBounds` fields are used for the optional depth bound test. 

Basically, this allows you to only keep fragments that fall within the specified depth range. We won't be using this functionality.

기본적으로 이렇게 하면 지정된 깊이 범위 내에 있는 조각만 보관할 수 있습니다. 저희는 이 기능을 사용하지 않을 것입니다.

```c
depthStencil.stencilTestEnable = VK_FALSE;
depthStencil.front = {}; // Optional
depthStencil.back = {}; // Optional

```

The last three fields configure stencil buffer operations, which we also won't be using in this tutorial.

마지막 세 필드는 stencil buffer 작업을 구성하며, 이 자습서 에서는 사용하지 않습니다.

If you want to use these operations, then you will have to make sure that the format of the depth/stencil image contains a stencil component.

이러한 작업을 사용하려면 깊이/스텐실 이미지의 형식에 스텐실 구성 요소가 포함되어 있는지 확인해야 합니다.

```c
pipelineInfo.pDepthStencilState = &depthStencil;
```

Update the [`VkGraphicsPipelineCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkGraphicsPipelineCreateInfo.html) struct to reference the depth stencil state we just filled in. A depth stencil state must always be specified if the render pass contains a depth stencil attachment.

If you run your program now, then you should see that the fragments of the geometry are now correctly ordered:

![](attachments/depth_correct.png)

# Handling window resize

The resolution of the depth buffer should change when the window is resized to match the new color attachment resolution. Extend the `recreateSwapChain` function to recreate the depth resources in that case:

```c
void recreateSwapChain() {
    int width = 0, height = 0;
    while (width == 0 || height == 0) {
        glfwGetFramebufferSize(window, &width, &height);
        glfwWaitEvents();
    }

    vkDeviceWaitIdle(device);

    cleanupSwapChain();

    createSwapChain();
    createImageViews();
    createDepthResources();
    createFramebuffers();
}

```

The cleanup operations should happen in the swap chain cleanup function:

```c
void cleanupSwapChain() {
    vkDestroyImageView(device, depthImageView, nullptr);
    vkDestroyImage(device, depthImage, nullptr);
    vkFreeMemory(device, depthImageMemory, nullptr);

    ...
}

```

Congratulations, your application is now finally ready to render arbitrary 3D geometry and have it look right. We're going to try this out in the next chapter by drawing a textured model!

[C++ code](https://vulkan-tutorial.com/code/27_depth_buffering.cpp) / [Vertex shader](https://vulkan-tutorial.com/code/27_shader_depth.vert) / [Fragment shader](https://vulkan-tutorial.com/code/27_shader_depth.frag)