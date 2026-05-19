# Multidsmpling

- [Introduction](https://vulkan-tutorial.com/Multisampling#page_Introduction)
- [Getting available sample count](https://vulkan-tutorial.com/Multisampling#page_Getting-available-sample-count)
- [Setting up a render target](https://vulkan-tutorial.com/Multisampling#page_Setting-up-a-render-target)
- [Adding new attachments](https://vulkan-tutorial.com/Multisampling#page_Adding-new-attachments)
- [Quality improvements](https://vulkan-tutorial.com/Multisampling#page_Quality-improvements)
- [Conclusion](https://vulkan-tutorial.com/Multisampling#page_Conclusion)

# Introduction

Our program can now load multiple levels of detail for textures which fixes artifacts when rendering objects far away from the viewer. 

The image is now a lot smoother, however on closer inspection you will notice jagged saw-like patterns along the edges of drawn geometric shapes. This is especially visible in one of our early programs when we rendered a quad:

![](attachments/texcoord_visualization.png)

이러한 원치 않는 효과를 "aliasing"이라고 하며, 렌더링에 사용할 수 있는 픽셀 수가 제한되어 있기 때문에 발생합니다.

Since there are no displays out there with unlimited resolution, it will be always visible to some extent.

이 문제를 해결하는 방법에는 여러 가지가 있으며 이 장에서는 가장 많이 사용되는 방법 중 하나에 초점을 맞출 것입니다: [Multisample anti-aliasing](https://en.wikipedia.org/wiki/Multisample_anti-aliasing)(MSAA)입니다.

일반 렌더링에서 픽셀 색상은 대부분의 경우 화면에서 대상 픽셀의 중심인 단일 샘플 포인트를 기준으로 결정됩니다.

그려진 선의 일부가 특정 픽셀을 통과하지만 샘플 지점을 덮지 않으면 해당 픽셀이 비워져 들쭉날쭉한 'staircase(계단)' 효과가 발생합니다.

![](attachments/aliasing.png)

What MSAA does is it uses multiple sample points per pixel (hence the name) to determine its final color. As one might expect, more samples lead to better results, however it is also more computationally expensive.

![](attachments/antialiasing.png)

In our implementation, we will focus on using the maximum available sample count. 

Depending on your application this may not always be the best approach and it might be better to use less samples for the sake of higher performance if the final result meets your quality demands.

애플리케이션에 따라 이 방법이 항상 최선의 방법은 아닐 수 있으며, 최종 결과가 품질 요구 사항을 충족하는 경우 더 높은 성능을 위해 더 적은 수의 샘플을 사용하는 것이 더 나을 수도 있습니다.

# Getting available sample count

Let's start off by determining how many samples our hardware can use. 

대부분의 최신 GPU는 최소 8개의 샘플을 지원하지만 이 숫자가 모든 곳에서 동일하게 보장되는 것은 아닙니다. 새 클래스 멤버를 추가하여 계속 추적할 것입니다:

```c
...
VkSampleCountFlagBits msaaSamples = VK_SAMPLE_COUNT_1_BIT;
...
```

By default we'll be using only one sample per pixel which is equivalent to no multisampling, in which case the final image will remain unchanged.

기본적으로 멀티샘플링을 사용하지 않는 것과 동일한 픽셀당 하나의 샘플만 사용하며, 이 경우 최종 이미지는 변경되지 않습니다.

The exact maximum number of samples can be extracted from [`VkPhysicalDeviceProperties`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPhysicalDeviceProperties.html) associated with our selected physical device. 

정확한 최대 샘플 수는 선택한 물리적 장치와 연관된 [`VkPhysicalDeviceProperties`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPhysicalDeviceProperties.html)에서 추출할 수 있습니다.

We're using a depth buffer, so we have to take into account the sample count for both color and depth. 

The highest sample count that is supported by both (&) will be the maximum we can support. Add a function that will fetch this information for us:

```c
VkSampleCountFlagBits getMaxUsableSampleCount() {
    VkPhysicalDeviceProperties physicalDeviceProperties;
    vkGetPhysicalDeviceProperties(physicalDevice, &physicalDeviceProperties);

    VkSampleCountFlags counts = physicalDeviceProperties.limits.framebufferColorSampleCounts & physicalDeviceProperties.limits.framebufferDepthSampleCounts;
    if (counts & VK_SAMPLE_COUNT_64_BIT) { return VK_SAMPLE_COUNT_64_BIT; }
    if (counts & VK_SAMPLE_COUNT_32_BIT) { return VK_SAMPLE_COUNT_32_BIT; }
    if (counts & VK_SAMPLE_COUNT_16_BIT) { return VK_SAMPLE_COUNT_16_BIT; }
    if (counts & VK_SAMPLE_COUNT_8_BIT) { return VK_SAMPLE_COUNT_8_BIT; }
    if (counts & VK_SAMPLE_COUNT_4_BIT) { return VK_SAMPLE_COUNT_4_BIT; }
    if (counts & VK_SAMPLE_COUNT_2_BIT) { return VK_SAMPLE_COUNT_2_BIT; }

    return VK_SAMPLE_COUNT_1_BIT;
}

```

We will now use this function to set the `msaaSamples` variable during the physical device selection process. For this, we have to slightly modify the `pickPhysic  alDevice` function:

```c
void pickPhysicalDevice() {
    ...
    for (const auto& device : devices) {
        if (isDeviceSuitable(device)) {
            physicalDevice = device;
            msaaSamples = getMaxUsableSampleCount();
            break;
        }
    }
    ...
}

```

# Setting up a render target

In MSAA, each pixel is sampled in an offscreen buffer which is then rendered to the screen.

This new buffer is slightly different from regular images we've been rendering to - they have to be able to store more than one sample per pixel.

이 새로운 버퍼는 픽셀당 하나 이상의 샘플을 저장할 수 있어야 한다는 점에서 지금까지 렌더링해 온 일반 이미지와 약간 다릅니다.

Once a multisampled buffer is created, it has to be resolved to the default framebuffer (which stores only a single sample per pixel). 

This is why we have to create an additional render target and modify our current drawing process. 

We only need one render target since only one drawing operation is active at a time, just like with the depth buffer. Add the following class members:

```c
...
VkImage colorImage;
VkDeviceMemory colorImageMemory;
VkImageView colorImageView;
...

```

This new image will have to store the desired number of samples per pixel, so we need to pass this number to [`VkImageCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImageCreateInfo.html) during the image creation process. Modify the `createImage` function by adding a `numSamples` parameter:

이 새 이미지에는 픽셀당 원하는 샘플 수를 저장해야 하므로 이미지 생성 프로세스 중에 이 숫자를 [`VkImageCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkImageCreateInfo.html)에 전달해야 합니다. `numSamples` 매개변수를 추가하여 `createImage` 함수를 수정합니다:

```c
void createImage(uint32_t width, uint32_t height, uint32_t mipLevels, VkSampleCountFlagBits numSamples, VkFormat format, VkImageTiling tiling, VkImageUsageFlags usage, VkMemoryPropertyFlags properties, VkImage& image, VkDeviceMemory& imageMemory) {
    ...
    imageInfo.samples = numSamples;
    ...

```

현재로서는 이 함수에 대한 모든 호출을 `VK_SAMPLE_COUNT_1_BIT`을 사용하여 업데이트하고 있으며, 구현을 진행하면서 적절한 값으로 대체할 예정입니다:

```c
createImage(swapChainExtent.width, swapChainExtent.height, 1, VK_SAMPLE_COUNT_1_BIT, depthFormat, VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, depthImage, depthImageMemory);
...
createImage(texWidth, texHeight, mipLevels, VK_SAMPLE_COUNT_1_BIT, VK_FORMAT_R8G8B8A8_SRGB, VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_USAGE_TRANSFER_SRC_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, textureImage, textureImageMemory);

```

We will now create a multisampled color buffer. Add a `createColorResources` function and note that we're using `msaaSamples` here as a function parameter to `createImage`. 

We're also using only one mip level, since this is enforced by the Vulkan specification in case of images with more than one sample per pixel. 

Also, this color buffer doesn't need mipmaps since it's not going to be used as a texture:

```c
void createColorResources() {
    VkFormat colorFormat = swapChainImageFormat;

    createImage(swapChainExtent.width, swapChainExtent.height, 1, msaaSamples, colorFormat, VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT | VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, colorImage, colorImageMemory);
    colorImageView = createImageView(colorImage, colorFormat, VK_IMAGE_ASPECT_COLOR_BIT, 1);
}

```

For consistency, call the function right before `createDepthResources`:

```c
void initVulkan() {
    ...
    createColorResources();
    createDepthResources();
    ...
}

```

Now that we have a multisampled color buffer in place it's time to take care of depth. Modify `createDepthResources` and update the number of samples used by the depth buffer:

```c
void createDepthResources() {
    ...
    createImage(swapChainExtent.width, swapChainExtent.height, 1, msaaSamples, depthFormat, VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, depthImage, depthImageMemory);
    ...
}

```

We have now created a couple of new Vulkan resources, so let's not forget to release them when necessary:

```c
void cleanupSwapChain() {
    vkDestroyImageView(device, colorImageView, nullptr);
    vkDestroyImage(device, colorImage, nullptr);
    vkFreeMemory(device, colorImageMemory, nullptr);
    ...
}

```

And update the `recreateSwapChain` so that the new color image can be recreated in the correct resolution when the window is resized:

```c
void recreateSwapChain() {
    ...
    createImageViews();
    createColorResources();
    createDepthResources();
    ...
}

```

We made it past the initial MSAA setup, now we need to start using this new resource in our graphics pipeline, framebuffer, render pass and see the results!

# Adding new attachments

Let's take care of the render pass first. Modify `createRenderPass` and update color and depth attachment creation info structs:

먼저 렌더 패스를 처리해 보겠습니다. `createRenderPass`를 수정하고 색상 및 깊이 어태치먼트 생성 정보 구조체를 업데이트합니다:

```c
void createRenderPass() {
    ...
    colorAttachment.samples = msaaSamples;
    colorAttachment.finalLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
    ...
    depthAttachment.samples = msaaSamples;
    ...

```

You'll notice that we have changed the finalLayout from `VK_IMAGE_LAYOUT_PRESENT_SRC_KHR` to `VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL`. 

최종 레이아웃을 `VK_IMAGE_LAYOUT_PRESENT_SRC_KHR`에서 `VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL`로 변경한 것을 확인할 수 있습니다.

That's because multisampled images cannot be presented directly.

멀티샘플링된 이미지를 직접 표시할 수 없기 때문입니다.

We first need to resolve them to a regular image. 

먼저 일반 이미지로 해상도를 조정해야 합니다.

This requirement does not apply to the depth buffer, since it won't be presented at any point. 

깊이 버퍼는 어떤 시점에서도 표시되지 않으므로 이 요구 사항은 깊이 버퍼에는 적용되지 않습니다.

Therefore we will have to add only one new attachment for color which is a so-called resolve attachment:

따라서 소위 해결 어태치먼트라고 하는 색상에 대한 새 어태치먼트를 하나만 추가해야 합니다:

```c
    ...
    VkAttachmentDescription colorAttachmentResolve{};
    colorAttachmentResolve.format = swapChainImageFormat;
    colorAttachmentResolve.samples = VK_SAMPLE_COUNT_1_BIT;
    colorAttachmentResolve.loadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    colorAttachmentResolve.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
    colorAttachmentResolve.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    colorAttachmentResolve.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
    colorAttachmentResolve.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    colorAttachmentResolve.finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
    ...

```

The render pass now has to be instructed to resolve multisampled color image into regular attachment.

이제 렌더 패스에 멀티샘플링된 컬러 이미지를 일반 첨부 파일로 해결하도록 지시해야 합니다.

Create a new attachment reference that will point to the color buffer which will serve as the resolve target:

```c
    ...
    VkAttachmentReference colorAttachmentResolveRef{};
    colorAttachmentResolveRef.attachment = 2;
    colorAttachmentResolveRef.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
    ...

```

Set the `pResolveAttachments` subpass struct member to point to the newly created attachment reference.

새로 생성된 첨부 파일 참조를 가리키도록 `pResolveAttachments` 서브패스 구조체 멤버를 설정합니다.

This is enough to let the render pass define a multisample resolve operation which will let us render the image to screen:

이 정도면 렌더 패스가 이미지를 화면에 렌더링할 수 있는 멀티샘플 리졸브 연산을 정의할 수 있습니다:

```cpp
    ...
    subpass.pResolveAttachments = &colorAttachmentResolveRef;
    ...
```

Now update render pass info struct with the new color attachment:

```cpp
    ...
    std::array<VkAttachmentDescription, 3> attachments = {colorAttachment, depthAttachment, colorAttachmentResolve};
    ...
```

With the render pass in place, modify `createFramebuffers` and add the new image view to the list:

```c
void createFramebuffers() {
        ...
        std::array<VkImageView, 3> attachments = {
            colorImageView,
            depthImageView,
            swapChainImageViews[i]
        };
        ...
}

```

Finally, tell the newly created pipeline to use more than one sample by modifying `createGraphicsPipeline`:

```c
void createGraphicsPipeline() {
    ...
    multisampling.rasterizationSamples = msaaSamples;
    ...
}

```

Now run your program and you should see the following:

![](attachments/multisampling.png)

Just like with mipmapping, the difference may not be apparent straight away. On a closer look you'll notice that the edges are not as jagged anymore and the whole image seems a bit smoother compared to the original.

![](attachments/multisampling_comparison.png)

The difference is more noticable when looking up close at one of the edges:

![](attachments/multisampling_comparison2.png)

# Quality improvements

현재 MSAA 구현에는 세부적인 장면에서 출력 이미지 품질에 영향을 미칠 수 있는 특정 제한 사항이 있습니다.

예를 들어, 현재 셰이더 에일리어싱으로 인한 잠재적인 문제, 즉 MSAA가 지오메트리의 가장자리만 부드럽게 하고 내부를 채우지는 못하는 문제를 해결하지 못하고 있습니다.

This may lead to a situation when you get a smooth polygon rendered on screen but the applied texture will still look aliased if it contains high contrasting colors. 

이로 인해 화면에 매끄러운 폴리곤이 렌더링되지만 적용된 텍스처에 대비가 높은 색상이 포함된 경우 에일리어싱이 발생하는 상황이 발생할 수 있습니다.

One way to approach this problem is to enable [Sample Shading](https://www.khronos.org/registry/vulkan/specs/1.3-extensions/html/chap27.html#primsrast-sampleshading) which will improve the image quality even further, though at an additional performance cost:

이 문제에 접근하는 한 가지 방법은 추가 성능 비용이 발생하지만 이미지 품질을 더욱 향상시킬 수 있는 [Sample Shading](https://www.khronos.org/registry/vulkan/specs/1.3-extensions/html/chap27.html#primsrast-sampleshading)을 활성화하는 것입니다:

```c
void createLogicalDevice() {
    ...
    deviceFeatures.sampleRateShading = VK_TRUE; // enable sample shading feature for the device
    ****...
}

void createGraphicsPipeline() {
    ...
    multisampling.sampleShadingEnable = VK_TRUE; // enable sample shading in the pipeline
    multisampling.minSampleShading = .2f; // min fraction for sample shading; closer to one is smoother
    ...
}

```

In this example we'll leave sample shading disabled but in certain scenarios the quality improvement may be noticeable:

![](attachments/sample_shading.png)

# Conclusion

It has taken a lot of work to get to this point, but now you finally have a good base for a Vulkan program. The knowledge of the basic principles of Vulkan that you now possess should be sufficient to start exploring more of the features, like:

- Push constants
- Instanced rendering
- Dynamic uniforms
- Separate images and sampler descriptors
- Pipeline cache
- Multi-threaded command buffer generation
- Multiple subpasses
- Compute shaders

The current program can be extended in many ways, like adding Blinn-Phong lighting, post-processing effects and shadow mapping. You should be able to learn how these effects work from tutorials for other APIs, because despite Vulkan's explicitness, many concepts still work the same.

[C++ code](https://vulkan-tutorial.com/code/30_multisampling.cpp) / [Vertex shader](https://vulkan-tutorial.com/code/27_shader_depth.vert) / [Fragment shader](https://vulkan-tutorial.com/code/27_shader_depth.frag)