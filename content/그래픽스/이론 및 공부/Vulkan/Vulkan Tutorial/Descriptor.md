출처 : https://lifeisforu.tistory.com/540

Descriptor는 buffer, bufferview, image 같은 셰이더 리소스들을 표현하는 불투명한(opaque)데이터 구조이다. 불투명한 -> 데이터가 있는데 어떤 정의를 내렸는지는 임의로 지정해야 한다. 그 전까지는 데이터로만 존재하기 때문에 opaque라고 생각함

DescriptorSetLayout : DescriptorSet의 설계도
DescriptorPool : DescriptorSet을 포함한 모든 것
DescriptorSets : 셰이더에서 사용하는 실체



-> Layout만 관심있다. binding은 아니다.
```cpp
vector<VkDescriptorSetLayoutBinding> bindings(2);

// Binding 0: Input image (readonly storage image)
// Corresponds to: layout(set = 0, binding = 0, rgba8) uniform readonly image2D inputImage;
bindings[0].binding = 0;                                       // Matches shader binding = 0
bindings[0].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE; // Storage image type
bindings[0].descriptorCount = 1;                               // Single image
bindings[0].stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;          // Used in compute stage
bindings[0].pImmutableSamplers = nullptr;                      // No samplers needed

// Binding 1: Output image (writeonly storage image)
// Corresponds to: layout(set = 0, binding = 1, rgba32f) uniform writeonly image2D outputImage;
bindings[1].binding = 1;                                       // Matches shader binding = 1
bindings[1].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE; // Storage image type
bindings[1].descriptorCount = 1;                               // Single image
bindings[1].stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;          // Used in compute stage
bindings[1].pImmutableSamplers = nullptr;                      // No samplers needed

```