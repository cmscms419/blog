---
title: Kyle Halladay - Vulkan 셰이더에서 텍스처 배열 사용
source: https://kylehalladay.com/blog/tutorial/vulkan/2018/01/28/Textue-Arrays-Vulkan.html
author:
  - "[[Kyle Halladay]]"
published: 
created: 2025-03-13
description: I build shaders, renderers, games, and other stuff that's fun to stare at.
tags: []
---

---

2018년 1월 28일

최근에 저는 Vulkan에서 텍스처를 효과적으로 처리하는 방법을 고민하고 있습니다. 저는 개체별로 바인딩해야 하는 설명자 세트를 원하지 않습니다. 즉, 각 텍스처를 자체 세트 바인딩에 그냥 집어넣는 것은 효과가 없습니다. 대신 AMD의 [Vulkan Fast Paths](http://32ipi028l5q82yhj72224m8j-wpengine.netdna-ssl.com/wp-content/uploads/2016/03/VulkanFastPaths.pdf) 프레젠테이션 덕분에 프레임 시작 부분에서 바인딩할 수 있는 설명자 세트에 모든 텍스처를 저장하는 텍스처의 글로벌 배열을 사용하는 것을 고려하고 있습니다.

AMD 프레젠테이션은 실제로 Vulkan에서 텍스처 배열을 설정하는 방법을 다루지 않으며, 온라인에서 그 방법에 대한 좋은 설명을 찾을 수 없었습니다. 그래서 이제 알아냈으므로 다음에 막힐 사람을 위해 여기에 간단한 튜토리얼을 게시하고 싶습니다. 이 배열이 내 머티리얼 시스템에 어떻게 들어맞는지에 대해서는 다음 게시물에서 더 자세히 설명하겠지만, 지금은 텍스처 배열을 사용하도록 셰이더를 설정하는 기본 사항만 다루고 싶습니다.

시작하기 전에 알아두어야 할 사항이 하나 더 있습니다. 동일한 크기의 이미지로 작업할 방법을 찾고 있다면 Sascha Willems가 [Vulkan Examples Project](https://github.com/SaschaWillems/Vulkan) 에서 sampler2DArray를 사용하는 훌륭한 예를 보여줍니다 . sampler2DArray와 같은 것 대신 텍스처 배열을 사용하는 이점은 텍스처 배열 접근 방식이 기본적으로 동일한 배열에 여러 이미지 크기를 저장하는 것을 지원한다는 것입니다. sampler2DArray보다 텍스처 배열을 사용하는 데 얼마나 많은 성능 페널티가 발생하는지 모르겠습니다.

이 모든 것을 말하면서, 이 포스트의 목표는 이와 같은 셰이더를 사용할 수 있도록 Vulkan 앱을 설정하는 방법을 안내하는 것입니다.

```c
#version 450 core
#extension GL_ARB_separate_shader_objects : enable

layout(set = 0, binding = 0) uniform sampler samp;
layout(set = 0, binding = 1) uniform texture2D textures[8];

layout(push_constant) uniform PER_OBJECT
{
	int imgIdx;
}pc;

layout(location = 0) out vec4 outColor;
layout(location = 0) in vec2 fragUV;

void main()
{
	outColor = texture(sampler2D(textures[pc.imgIdx], samp), fragUV);
}
```

[저는 이 모든 코드를 github의 예제 프로젝트](https://github.com/khalladay/VulkanDemoProjects/tree/master/VulkanDemoProjects/TextureArrays) 에 올렸는데 , 이 프로젝트는 위의 셰이더로 전체 화면 사각형을 렌더링하고, push 상수에서 imgIdx 변수를 업데이트하여 표시되는 이미지를 변경하므로, 자유롭게 가져와서 살펴보세요. 이 게시물의 나머지 부분에서는 해당 코드의 일부를 자세히 살펴보겠습니다.

## 설명자 세트 레이아웃 설정

텍스처 배열에서 작동하도록 설명자 세트 바인딩을 설정하는 것은 단일 텍스처에서 작동하도록 설정하는 것과 매우 유사합니다. 주요 차이점은 VkDescriptorSetLayoutBinding 구조의 "decsriptorCount" 변수입니다. 단일 텍스처의 경우 이 값을 1로 설정하는 반면, 텍스처 배열의 경우 이 변수를 배열의 요소 수로 설정합니다. 위의 셰이더의 경우 텍스처 배열의 레이아웃 바인딩 구조는 다음과 같습니다.

```c
VkDescriptorSetLayoutBinding layoutBinding = {};
layoutBinding.descriptorCount = 8;
layoutBinding.binding = 1;
layoutBinding.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT;
layoutBinding.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
layoutBinding.pImmutableSamplers = 0;
```

지금 생각해보면 꽤나 당연한 일이지만, "descriptorCount"가 이 정보에 적합한 곳이라는 걸 깨닫는 데 시간이 좀 걸렸습니다.

위의 설정이 완료되면 다른 레이아웃 바인딩 유형과 마찬가지로 DescriptorSet(및 DescriptorSetLayout)을 생성하기만 하면 됩니다. 제가 게시한 데모 앱에는 이 모든 것의 작동 예가 있습니다.

## 설명자 세트 작성

위와 유사하게, 텍스처 배열을 디스크립터 세트에 쓰는 것은 처음에 보이는 것보다 훨씬 간단합니다. 핵심은 VkDescriptorImageInfo 구조체를 이미 배열에 넣는 것입니다. 결합된 이미지 샘플러를 사용하지 않는 경우 실제로 이러한 구조체에 샘플러 값을 채울 필요가 없습니다. 데모 프로젝트에서 다음과 같이 이 배열을 설정했습니다.

```c
VkDescriptorImageInfo	descriptorImageInfos[TEXTURE_ARRAY_SIZE];

for (uint32_t i = 0; i < TEXTURE_ARRAY_SIZE; ++i)
{
    demoData.descriptorImageInfos[i].sampler = nullptr;
    demoData.descriptorImageInfos[i].imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
    demoData.descriptorImageInfos[i].imageView = demoData.textures[i].view;
}
```

단순한 애플리케이션에서는 이런 깔끔한 작은 배열에 모든 imageViews가 이미 있지는 않을 것입니다. 하지만 사용하는 DescriptorImageInfo 구조체가 어떤 종류의 배열에 있는 한, 이미지 뷰가 어떻게 배치되어 있는지는 중요하지 않습니다.

해당 구조체를 설정하고 나면 텍스처 배열에 대한 WriteDescriptorSet의 나머지 부분을 설정하는 것은 매우 간단합니다.

```c
VkWriteDescriptorSet setWrites[2];

setWrites[1] = {};
setWrites[1].sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
setWrites[1].dstBinding = 1;
setWrites[1].dstArrayElement = 0;
setWrites[1].descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
setWrites[1].descriptorCount = TEXTURE_ARRAY_SIZE;
setWrites[1].pBufferInfo = 0;
setWrites[1].dstSet = demoData.descriptorSet;
setWrites[1].pImageInfo = demoData.descriptorImageInfos;
```

앞서 DescriptorSetLayoutBinding과 마찬가지로 여기서 descriptorCount 변수는 배열의 길이를 지정해야 합니다.

## GlslangValidator와 큰 배열

[glslang 프로젝트](https://github.com/KhronosGroup/glslang) 의 standable glslangvalidator 도구를 사용하는 경우 , 많은 텍스처 배열(예: 80개 이상)을 만들려고 하면 몇 가지 문제가 발생합니다. 그렇게 하면 다음과 같은 오류 메시지가 표시됩니다.

> 'binding' : 샘플러 바인딩이 gl\_MaxCombinedTextureImageUnits보다 작지 않음(배열 사용)

이것은 제게 문제가 되었는데, 주어진 프레임에서 사용된 모든 텍스처를 바인딩된 상태로 유지하고 싶었기 때문에 초기 배열 크기를 4096으로 설정했습니다(모든 이미지 뷰가 동일한 이미지로 기본 설정됨). 생성된 오류의 "gl\_" 접두사에서 짐작하셨겠지만, 이 오류는 실제로 Vulkan 셰이더에는 적용되지 않으므로 셰이더가 OpenGL에서 사용되지 않을 것이 확실하다면 컴파일러에 gl\_MaxCombinedTextureImageUnits에 대해 걱정하지 말라고 알려야 합니다.

이렇게 하려면 다음과 같이 장치 기능 구성 파일을 만들어야 합니다.

```c
 "glslangvalidator -c > myconfig.config"
 
```

파일에서 .config 확장자를 사용하는 것이 중요합니다. 이는 glslangvalidator가 인수 목록에서 대체 구성 파일이 제공되는지 알아보기 위해 이 확장자를 찾기 때문입니다.

이 구성 파일이 있으면 좋아하는 텍스트 편집기에서 파일을 열고 "MaxCombinedTextureImageUnits" 줄을 찾기만 하면 됩니다.

```c
MaxVertexAttribs 64
MaxVertexUniformComponents 4096
MaxVaryingFloats 64
MaxVertexTextureImageUnits 32
MaxCombinedTextureImageUnits 80
MaxTextureImageUnits 32
```

80을 정말 큰 숫자로 바꾸면 됩니다. 한 가지 주의할 점은 원래 이 작업을 할 때 몇 가지 문제가 발생했다는 것입니다. powershell을 사용하여 구성 파일을 생성했기 때문에 기본적으로 UCS2-LE 텍스트 인코딩을 사용하여 텍스트 파일을 작성합니다. 이런 일은 원치 않을 것입니다. cconfig 파일이 UTF-8과 같은 정상적인 인코딩으로 설정되어 있는지 확인하세요. 그렇지 않으면 검증기가 파일을 제대로 다시 읽을 수 없습니다.

제대로 인코딩하고, 구성 파일을 사용하여 많은 텍스처를 준비하면 셰이더를 다시 컴파일할 수 있습니다. 이번에는 다음과 같이 컴파일러를 호출합니다.

```c
glslangvalidator -V myfile.frag myconf.conf
```

설정 파일이 .conf 확장자를 사용하는 한, 그것만으로도 불평을 멈추고 본래의 기능을 수행할 수 있습니다.

## 모두 다 됐어요!

위의 모든 것이 완료되면, push 상수를 통해 배열 인덱스를 전달하는 것과 같은 방식으로 push 상수를 통해 전달하고 작업을 시작할 수 있습니다. 위의 내용이 불분명하다면 github의 [데모 프로젝트를](https://github.com/khalladay/VulkanDemoProjects/tree/master/VulkanDemoProjects/TextureArrays) 다시 한 번 안내해 드리겠습니다 . 여기서는 비교적 작은 작업 예제를 제공합니다.

도움이 되었으면 좋겠네요! 짧은 게시물이고 획기적인 내용은 없지만 (제 생각에는) Vulkan에 더 쉽게 소화할 수 있는 튜토리얼 콘텐츠가 필요해서 이 게시물을 올립니다. 어쨌든 인사하고 싶으시다면 [Twitter의](https://twitter.com/khalladay) @khalladay 나 [Mastodon](https://mastodon.gamedev.place/@khalladay) 으로 메시지를 보내주세요 . 읽어주셔서 감사합니다!