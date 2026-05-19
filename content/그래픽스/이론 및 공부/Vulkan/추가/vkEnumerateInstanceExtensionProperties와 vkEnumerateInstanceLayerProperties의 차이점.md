	## vkEnumerateInstanceExtensionProperties

이 함수는 Vulkan 인스턴스가 지원하는 확장(Extension) 목록을 조회합니다.
확장은 Vulkan의 기본 기능을 확장하거나 플랫폼별 기능(예: 표면 생성, 디버깅 등)을 제공합니다.
반환값은 VkExtensionProperties 구조체 배열로, 각 확장의 이름과 버전 정보를 포함합니다.
## vkEnumerateInstanceLayerProperties

이 함수는 Vulkan 인스턴스에서 활성화할 수 있는 레이어(Layer) 목록을 조회합니다.
레이어는 주로 디버깅, 검증(validation), 프로파일링 등 개발 지원 기능을 제공합니다.
반환값은 VkLayerProperties 구조체 배열로, 각 레이어의 이름, 설명, 버전 정보 등을 포함합니다.

요약
•	Extension: Vulkan의 기능을 확장하는 모듈(기능 추가)
•	Layer: Vulkan 호출을 가로채서 동작을 추가/변경하는 모듈(주로 개발 지원)
•	두 함수 모두 인스턴스 생성 전에 지원 여부를 확인하고, 필요한 확장/레이어를 활성화해야 합니다.


```cpp
// 인스턴스 확장 조회
uint32_t extCount = 0;
vkEnumerateInstanceExtensionProperties(nullptr, &extCount, nullptr);

// 인스턴스 레이어 조회
uint32_t layerCount = 0;
vkEnumerateInstanceLayerProperties(&layerCount, nullptr);

```