# Generating Mipmaps

- [Introduction](https://vulkan-tutorial.com/Generating_Mipmaps#page_Introduction)
- [Image creation](https://vulkan-tutorial.com/Generating_Mipmaps#page_Image-creation)
- [Generating Mipmaps](https://vulkan-tutorial.com/Generating_Mipmaps#page_Generating-Mipmaps)
- [Linear filtering support](https://vulkan-tutorial.com/Generating_Mipmaps#page_Linear-filtering-support)
- [Sampler](https://vulkan-tutorial.com/Generating_Mipmaps#page_Sampler)

# Introduction

Our program can now load and render 3D models. In this chapter, we will add one more feature, mipmap generation. 

Mipmaps are widely used in games and rendering software, and Vulkan gives us complete control over how they are created.

Mipmaps은 게임과 렌더링 소프트웨어에서 널리 사용되며, vulkan은 Mipmap 생성 방식을 완벽하게 제어할 수 있습니다.

Mipmaps은 미리 계산된 이미지의 축소 버전입니다.

각각의 새 이미지는 이전 이미지의 너비와 높이의 절반 크기입니다.

밉맵은 레벨 오브 디테일 또는 LOD의 한 형태로 사용됩니다.

Objects that are far away from the camera will sample their textures from the smaller mip images.

카메라에서 멀리 떨어져 있는 오브젝트는 작은 밉 이미지에서 텍스처를 샘플링합니다.

Using smaller images increases the rendering speed and avoids artifacts such as [Moiré patterns](https://en.wikipedia.org/wiki/Moir%C3%A9_pattern). An example of what mipmaps look like:

![](attachments/mipmaps_example.jpg)

# Image creation

In Vulkan, each of the mip images is stored in different *mip levels* of a [`VkImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImage.html). 

Vulkan에서 각 밉 이미지는 [`VkImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImage.html)의 서로 다른 밉 레벨에 저장됩니다.

Mip level 0 is the original image, and the mip levels after level 0 are commonly referred to as the *mip chain.*

밉 레벨 0은 원본 이미지이며, 레벨 0 이후의 밉 레벨을 일반적으로 *mip chain*이라고 합니다.

The number of mip levels is specified when the [`VkImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImage.html) is created. 

Up until now, we have always set this value to one. We need to calculate the number of mip levels from the dimensions of the image. First, add a class member to store this number:

```c
...
uint32_t mipLevels;
VkImage textureImage;
...

```

The value for `mipLevels` can be found once we've loaded the texture in `createTextureImage`:

```c
int texWidth, texHeight, texChannels;
stbi_uc* pixels = stbi_load(TEXTURE_PATH.c_str(), &texWidth, &texHeight, &texChannels, STBI_rgb_alpha);
...
mipLevels = static_cast<uint32_t>(std::floor(std::log2(std::max(texWidth, texHeight)))) + 1;

```

This calculates the number of levels in the mip chain. The `max` function selects the largest dimension.

밉 체인의 레벨 수를 계산합니다. `max` 함수는 가장 큰 차원을 선택합니다.

The `log2` function calculates how many times that dimension can be divided by 2.

`log2` 함수는 해당 차원을 2로 나눌 수 있는 횟수를 계산합니다.

`floor`함수는 가장 큰 치수가 2의 거듭제곱이 아닌 경우를 처리합니다. 

원본 이미지에 밉 레벨을 갖도록 `1`이 추가됩니다.

To use this value, we need to change the `createImage`, `createImageView`, and `transitionImageLayout` functions to allow us to specify the number of mip levels. Add a `mipLevels` parameter to the functions:

```c
void createImage(uint32_t width, uint32_t height, uint32_t mipLevels, VkFormat format, VkImageTiling tiling, VkImageUsageFlags usage, VkMemoryPropertyFlags properties, VkImage& image, VkDeviceMemory& imageMemory) {
    ...
    imageInfo.mipLevels = mipLevels;
    ...
}

```

```c
VkImageView createImageView(VkImage image, VkFormat format, VkImageAspectFlags aspectFlags, uint32_t mipLevels) {
    ...
    viewInfo.subresourceRange.levelCount = mipLevels;
    ...

```

```c
void transitionImageLayout(VkImage image, VkFormat format, VkImageLayout oldLayout, VkImageLayout newLayout, uint32_t mipLevels) {
    ...
    barrier.subresourceRange.levelCount = mipLevels;
    ...

```

Update all calls to these functions to use the right values:

```c
createImage(swapChainExtent.width, swapChainExtent.height, 1, depthFormat, VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, depthImage, depthImageMemory);
...
createImage(texWidth, texHeight, mipLevels, VK_FORMAT_R8G8B8A8_SRGB, VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, textureImage, textureImageMemory);

```

```c
swapChainImageViews[i] = createImageView(swapChainImages[i], swapChainImageFormat, VK_IMAGE_ASPECT_COLOR_BIT, 1);
...
depthImageView = createImageView(depthImage, depthFormat, VK_IMAGE_ASPECT_DEPTH_BIT, 1);
...
textureImageView = createImageView(textureImage, VK_FORMAT_R8G8B8A8_SRGB, VK_IMAGE_ASPECT_COLOR_BIT, mipLevels);

```

```c
transitionImageLayout(depthImage, depthFormat, VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL, 1);
...
transitionImageLayout(textureImage, VK_FORMAT_R8G8B8A8_SRGB, VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, mipLevels);

```

# Generating Mipmaps

Our texture image now has multiple mip levels, but the staging buffer can only be used to fill mip level 0.

The other levels are still undefined. To fill these levels we need to generate the data from the single level that we have.

We will use the [`vkCmdBlitImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdBlitImage.html) command. This command performs copying, scaling, and filtering operations. We will call this multiple times to *blit* data to each level of our texture image.

[`vkCmdBlitImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdBlitImage.html)명령을 사용하겠습니다. 

이 명령은 복사, 크기 조정 및 필터링 작업을 수행합니다. 텍스처 이미지의 각 레벨에 데이터를 블릿하기 위해 이 명령을 여러 번 호출할 것입니다.

[`vkCmdBlitImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdBlitImage.html) is considered a transfer operation, so we must inform Vulkan that we intend to use the texture image as both the source and destinatio n of a transfer.

[`vkCmdBlitImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdBlitImage.html)는 전송 작업으로 간주되므로 텍스처 이미지를 전송의 소스 및 대상으로 모두 사용하려는 것을 Vulkan에 알려야 합니다.

Add `VK_IMAGE_USAGE_TRANSFER_SRC_BIT` to the texture image's usage flags in `createTextureImage`:

```c
...
createImage(texWidth, texHeight, mipLevels, VK_FORMAT_R8G8B8A8_SRGB, VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_USAGE_TRANSFER_SRC_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, textureImage, textureImageMemory);
...
```

다른 이미지 연산과 마찬가지로 [`vkCmdBlitImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdBlitImage.html)는 작동하는 이미지의 레이아웃에 따라 달라집니다. 전체 이미지를 `VK_IMAGE_LAYOUT_GENERAL`로 전환할 수도 있지만 속도가 느려질 가능성이 높습니다.

최적의 성능을 위해 소스 이미지는 `VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL`에 있어야 하고 대상 이미지는 `VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL`에 있어야 합니다.

Vulkan 을 사용하면 이미지의 각 밉 레벨을 독립적으로 전환할 수 있습니다. 

각 블릿은 한 번에 두 개의 밉 레벨만 처리하므로 블릿 명령 사이에 각 레벨을 최적의 레이아웃으로 전환할 수 있습니다.

`transitionImageLayout` only performs layout transitions on the entire image, so we'll need to write a few more pipeline barrier commands. Remove the existing transition to `VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL` in `createTextureImage`:

`transitionImageLayout`은 전체 이미지에 대해서만 레이아웃 전환을 수행하므로 파이프라인 배리어 명령을 몇 개 더 작성해야 합니다. `createTextureImage`에서 기존 트랜지션을 `VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL`로 제거합니다:

```c
...
transitionImageLayout(textureImage, VK_FORMAT_R8G8B8A8_SRGB, VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, mipLevels);
    copyBufferToImage(stagingBuffer, textureImage, static_cast<uint32_t>(texWidth), static_cast<uint32_t>(texHeight));
//transitioned to VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL while generating mipmaps
//밉맵을 생성하는 동안 VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL로 전환되었습니다.
...

```

This will leave each level of the texture image in `VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL`. Each level will be transitioned to `VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL` after the blit command reading from it is finished.

이렇게 하면 텍스처 이미지의 각 레벨이 `VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL`에 남게 됩니다. 

각 레벨은 블릿 명령 읽기가 완료된 후 `VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL`로 전환됩니다.

We're now going to write the function that generates the mipmaps:

```c
void generateMipmaps(VkImage image, int32_t texWidth, int32_t texHeight, uint32_t mipLevels) {
    VkCommandBuffer commandBuffer = beginSingleTimeCommands();

    VkImageMemoryBarrier barrier{};
    barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
    barrier.image = image;
    barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    barrier.subresourceRange.baseArrayLayer = 0;
    barrier.subresourceRange.layerCount = 1;
    barrier.subresourceRange.levelCount = 1;

    endSingleTimeCommands(commandBuffer);
}

```

We're going to make several transitions, so we'll reuse this [`VkImageMemoryBarrier`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImageMemoryBarrier.html). The fields set above will remain the same for all barriers.

몇 가지 전환을 할 것이므로 이 [`VkImageMemoryBarrier`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImageMemoryBarrier.html)를 재사용하겠습니다. 위에서 설정한 필드는 모든 배리어에 대해 동일하게 유지됩니다.

`subresourceRange.miplevel`, `oldLayout`, `newLayout`, `srcAccessMask`, and `dstAccessMask` will be changed for each transition.

```c
int32_t mipWidth = texWidth;
int32_t mipHeight = texHeight;

for (uint32_t i = 1; i < mipLevels; i++) {

}

```

This loop will record each of the [`VkCmdBlitImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkCmdBlitImage.html) commands. Note that the loop variable starts at 1, not 0.

이 루프는 각 [`VkCmdBlitImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkCmdBlitImage.html)명령을 기록합니다. 루프 변수는 0이 아닌 1에서 시작한다는 점에 유의하세요.

```c
barrier.subresourceRange.baseMipLevel = i - 1;
barrier.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
barrier.newLayout = VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
barrier.dstAccessMask = VK_ACCESS_TRANSFER_READ_BIT;

vkCmdPipelineBarrier(commandBuffer,
    VK_PIPELINE_STAGE_TRANSFER_BIT, VK_PIPELINE_STAGE_TRANSFER_BIT, 0,
    0, nullptr,
    0, nullptr,
    1, &barrier);
```

First, we transition level `i - 1` to `VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL`. This transition will wait for level `i - 1` to be filled, either from the previous blit command, or from [`vkCmdCopyBufferToImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdCopyBufferToImage.html). 

먼저 레벨 `i - 1`을 `VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL`로 전환합니다. 이 전환은 이전 블릿 명령 또는 [`vkCmdCopyBufferToImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdCopyBufferToImage.html)에서 레벨 `i - 1`이 채워질 때까지 기다립니다.

The current blit command will wait on this transition.

```c
VkImageBlit blit{};
blit.srcOffsets[0] = { 0, 0, 0 };
blit.srcOffsets[1] = { mipWidth, mipHeight, 1 };
blit.srcSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
blit.srcSubresource.mipLevel = i - 1;
blit.srcSubresource.baseArrayLayer = 0;
blit.srcSubresource.layerCount = 1;
blit.dstOffsets[0] = { 0, 0, 0 };
blit.dstOffsets[1] = { mipWidth > 1 ? mipWidth / 2 : 1, mipHeight > 1 ? mipHeight / 2 : 1, 1 };
blit.dstSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
blit.dstSubresource.mipLevel = i;
blit.dstSubresource.baseArrayLayer = 0;
blit.dstSubresource.layerCount = 1;

```

Next, we specify the regions that will be used in the blit operation. 

The source mip level is `i - 1` and the destination mip level is `i`. 

소스 밉 레벨은 `i - 1`이고 대상 밉 레벨은 `i`입니다.

The two elements of the `srcOffsets` array determine the 3D region that data will be blitted from.

`srcOffsets` 배열의 두 요소는 데이터가 블릿될 3D 영역을 결정합니다.

`dstOffsets` determines the region that data will be blitted to. 

The X and Y dimensions of the `dstOffsets[1]` are divided by two since each mip level is half the size of the previous level. 

각 밉 레벨은 이전 레벨의 절반 크기이므로 `dstOffsets[1]`의 X 및 Y 치수는 2로 나뉩니다.

The Z dimension of `srcOffsets[1]` and `dstOffsets[1]` must be 1, since a 2D image has a depth of 1.

2D 이미지의 깊이가 1이므로 `srcOffsets[1]` 및 `dstOffsets[1]`의 Z 치수는 1이어야 합니다.

```c
vkCmdBlitImage(commandBuffer,
    image, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
    image, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    1, &blit,
    VK_FILTER_LINEAR);
```

Now, we record the blit command. Note that `textureImage` is used for both the `srcImage` and `dstImage` parameter.

이제 블릿 명령을 기록합니다. `textureImage`는 `srcImage`와 `dstImage`매개변수 모두에 사용됩니다.

This is because we're blitting between different levels of the same image. 

이는 동일한 이미지의 여러 레벨을 블릿하기 때문입니다.

The source mip level was just transitioned to `VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL` and the destination level is still in `VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL` from `createTextureImage`.

소스 밉 레벨은 방금 `VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL`로 전환되었고, 대상 레벨은 여전히 `createTextureImage`에서 `VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL`로 남아 있습니다.

Beware if you are using a dedicated transfer queue (as suggested in [Vertex buffers](https://vulkan-tutorial.com/Vertex_buffers/Staging_buffer)): [`vkCmdBlitImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdBlitImage.html) must be submitted to a queue with graphics capability.

전용 전송 큐을 사용하는 경우([Vertex buffers](https://vulkan-tutorial.com/Vertex_buffers/Staging_buffer)에서 제안한 대로) 주의: 

그래픽 기능이 있는 큐에 [`vkCmdBlitImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdBlitImage.html)를 제출해야 합니다.

The last parameter allows us to specify a [`VkFilter`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkFilter.html) to use in the blit. We have the same filtering options here that we had when making the [`VkSampler`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkSampler.html).

마지막 파라미터를 통해 블릿에 사용할 [`VkFilter`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkFilter.html)를 지정할 수 있습니다. 여기에는 [`VkSampler`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkSampler.html)를 만들 때와 동일한 필터링 옵션이 있습니다.

We use the `VK_FILTER_LINEAR` to enable interpolation.

```c
barrier.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
barrier.newLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
barrier.srcAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
barrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;

vkCmdPipelineBarrier(commandBuffer,
    VK_PIPELINE_STAGE_TRANSFER_BIT, VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0,
    0, nullptr,
    0, nullptr,
    1, &barrier);
```

This barrier transitions mip level `i - 1` to `VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL`.

barrier는 밉 레벨 `i - 1`을 `VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL`로 전환합니다.

This transition waits on the current blit command to finish. All sampling operations will wait on this transition to finish.

```c
    ...
    if (mipWidth > 1) mipWidth /= 2;
    if (mipHeight > 1) mipHeight /= 2;
}
```

At the end of the loop, we divide the current mip dimensions by two. 

We check each dimension before the division to ensure that dimension never becomes 0. 

This handles cases where the image is not square, since one of the mip dimensions would reach 1 before the other dimension. When this happens, that dimension should remain 1 for all remaining levels.

이렇게 하면 밉 치수 중 하나가 다른 치수보다 먼저 1에 도달하므로 이미지가 정사각형이 아닌 경우를 처리할 수 있습니다.

이 경우 해당 치수는 나머지 모든 레벨에서 1을 유지해야 합니다.

```c
    barrier.subresourceRange.baseMipLevel = mipLevels - 1;
    barrier.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    barrier.newLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
    barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    barrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;

    vkCmdPipelineBarrier(commandBuffer,
        VK_PIPELINE_STAGE_TRANSFER_BIT, VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0,
        0, nullptr,
        0, nullptr,
        1, &barrier);

    endSingleTimeCommands(commandBuffer);
}
```

Before we end the command buffer, we insert one more pipeline barrier. 

barrier는 마지막 mip level을 `VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL`에서 `VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL`로 전환합니다.

This wasn't handled by the loop, since the last mip level is never blitted from.

Finally, add the call to `generateMipmaps` in `createTextureImage`:

```c
transitionImageLayout(textureImage, VK_FORMAT_R8G8B8A8_SRGB, VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, mipLevels);
    copyBufferToImage(stagingBuffer, textureImage, static_cast<uint32_t>(texWidth), static_cast<uint32_t>(texHeight));
//transitioned to VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL while generating mipmaps
...
generateMipmaps(textureImage, texWidth, texHeight, mipLevels);

```

Our texture image's mipmaps are now completely filled.

# Linear filtering support

It is very convenient to use a built-in function like [`vkCmdBlitImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdBlitImage.html) to generate all the mip levels, but unfortunately it is not guaranteed to be supported on all platforms.

모든 mip levels을 생성하기 위해 [`vkCmdBlitImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdBlitImage.html)와 같은 내장 함수를 사용하는 것이 매우 편리하지만 안타깝게도 모든 플랫폼에서 지원되는 것은 아닙니다.

It requires the texture image format we use to support linear filtering, which can be checked with the [`vkGetPhysicalDeviceFormatProperties`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkGetPhysicalDeviceFormatProperties.html) function. We will add a check to the `generateMipmaps` function for this.

linear filtering을 지원하기 위해 사용하는 텍스처 이미지 형식이 필요하며, 이는 [`vkGetPhysicalDeviceFormatProperties`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkGetPhysicalDeviceFormatProperties.html) 함수를 통해 확인할 수 있습니다. 이를 위해 `generateMipmaps` 함수에 검사를 추가하겠습니다.

First add an additional parameter that specifies the image format:

```c
void createTextureImage() {
    ...

    generateMipmaps(textureImage, VK_FORMAT_R8G8B8A8_SRGB, texWidth, texHeight, mipLevels);
}

void generateMipmaps(VkImage image, VkFormat imageFormat, int32_t texWidth, int32_t texHeight, uint32_t mipLevels) {

    ...
}

```

In the `generateMipmaps` function, use [`vkGetPhysicalDeviceFormatProperties`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkGetPhysicalDeviceFormatProperties.html) to request the properties of the texture image format:

```c
void generateMipmaps(VkImage image, VkFormat imageFormat, int32_t texWidth, int32_t texHeight, uint32_t mipLevels) {

    // Check if image format supports linear blitting
    VkFormatProperties formatProperties;
    vkGetPhysicalDeviceFormatProperties(physicalDevice, imageFormat, &formatProperties);

    ...

```

The [`VkFormatProperties`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkFormatProperties.html) struct has three fields named `linearTilingFeatures`, `optimalTilingFeatures` and `bufferFeatures` that each describe how the format can be used depending on the way it is used. 

We create a texture image with the optimal tiling format, so we need to check `optimalTilingFeatures`. Support for the linear filtering feature can be checked with the `VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT`:

```c
if (!(formatProperties.optimalTilingFeatures & VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT)) {
    throw std::runtime_error("texture image format does not support linear blitting!");
}

```

There are two alternatives in this case. 

You could implement a function that searches common texture image formats for one that *does* support linear blitting, or you could implement the mipmap generation in software with a library like [stb_image_resize](https://github.com/nothings/stb/blob/master/stb_image_resize.h). 

Each mip level can then be loaded into the image in the same way that you loaded the original image.

It should be noted that it is uncommon in practice to generate the mipmap levels at runtime anyway.

실제로는 런타임에 밉맵 레벨을 생성하는 경우가 드물다는 점에 유의해야 합니다.

Usually they are pregenerated and stored in the texture file alongside the base level to improve loading speed. Implementing resizing in software and loading multiple levels from a file is left as an exercise to the reader.

일반적으로 로딩 속도를 향상시키기 위해 텍스처 파일에 기본 레벨과 함께 미리 생성되어 저장됩니다.

소프트웨어에서 크기 조정을 구현하고 파일에서 여러 레벨을 로드하는 것은 독자의 몫으로 남겨둡니다.

# Sampler

[`VkImage`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImage.html)가 밉맵 데이터를 보유하는 동안 [`VkSampler`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkSampler.html)는 렌더링 중에 해당 데이터를 읽는 방법을 제어합니다.

Vulkan에서는 `minLod`, `maxLod`, `mipLodBias`, `mipmapMode`("Lod"는 "Level of Detail"을 의미)를 지정할 수 있습니다.

When a texture is sampled, the sampler selects a mip level according to the following pseudocode:

```c
lod = getLodLevelFromScreenSize(); //smaller when the object is close, may be negative
lod = clamp(lod + mipLodBias, minLod, maxLod);

level = clamp(floor(lod), 0, texture.mipLevels - 1);  //clamped to the number of mip levels in the texture

if (mipmapMode == VK_SAMPLER_MIPMAP_MODE_NEAREST) {
    color = sample(level);
} else {
    color = blend(sample(level), sample(level + 1));
}
```

`samplerInfo.mipmapMode`가 `VK_SAMPLER_MIPMAP_MODE_NEAREST`인 경우, `lod`는 샘플링 할 밉 레벨을 선택합니다.

If the mipmap mode is `VK_SAMPLER_MIPMAP_MODE_LINEAR`, `lod` is used to select two mip levels to be sampled.

밉맵 모드가 `VK_SAMPLER_MIPMAP_MODE_LINEAR`인 경우, `lod`는 샘플링할 두 밉 레벨을 선택하는 데 사용됩니다.

Those levels are sampled and the results are linearly blended.

이러한 레벨은 샘플링되고 결과는 선형적으로 블렌딩됩니다.

The sample operation is also affected by `lod`:

```c
if (lod <= 0) {
    color = readTexture(uv, magFilter);
} else {
    color = readTexture(uv, minFilter);
}

```

물체가 카메라에 가까이 있는 경우 `magFilter`가 필터로 사용됩니다.

object가 camera에서 멀리 떨어져 있으면 `minFilter`가 사용됩니다. 일반적으로 `lod`는 음수가 아니며 카메라를 닫을 때만 0이 됩니다.

`mipLodBias`를 사용하면 Vulkan이 평소보다 낮은 `lod`와 `level`을 사용하도록 강제할 수 있습니다.

To see the results of this chapter, we need to choose values for our `textureSampler`. 

We've already set the `minFilter` and `magFilter` to use `VK_FILTER_LINEAR`. We just need to choose values for `minLod`, `maxLod`, `mipLodBias`, and `mipmapMode`.

```c
void createTextureSampler() {
    ...
    samplerInfo.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR;
    samplerInfo.minLod = 0.0f; // Optional
    samplerInfo.maxLod = static_cast<float>(mipLevels);
    samplerInfo.mipLodBias = 0.0f; // Optional
    ...
}

```

To allow the full range of mip levels to be used, we set `minLod` to 0.0f, and `maxLod` to the number of mip levels. We have no reason to change the `lod` value , so we set `mipLodBias` to 0.0f.

Now run your program and you should see the following:

![](attachments/mipmaps.png)

It's not a dramatic difference, since our scene is so simple. There are subtle differences if you look closely.

![](attachments/mipmaps_comparison.png)

The most noticeable difference is the writing on the papers. With mipmaps, the writing has been smoothed. Without mipmaps, the writing has harsh edges and gaps from Moiré artifacts.

You can play around with the sampler settings to see how they affect mipmapping. For example, by changing `minLod`, you can force the sampler to not use the lowest mip levels:

```c
samplerInfo.minLod = static_cast<float>(mipLevels / 2);

```

These settings will produce this image:

![](attachments/highmipmaps.png)

This is how higher mip levels will be used when objects are further away from the camera.

[C++ code](https://vulkan-tutorial.com/code/29_mipmapping.cpp) / [Vertex shader](https://vulkan-tutorial.com/code/27_shader_depth.vert) / [Fragment shader](https://vulkan-tutorial.com/code/27_shader_depth.frag)