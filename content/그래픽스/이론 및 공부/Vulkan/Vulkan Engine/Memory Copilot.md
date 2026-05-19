# Vulkan 메모리 관리 예제

이 문서는 Vulkan에서 GPU와 HOST 간의 메모리 관리를 위한 **간단한 예제**와 그 흐름을 설명합니다. 실제 애플리케이션에서는 인스턴스 생성, 물리 디바이스 선택, 논리 디바이스 생성 등 여러 초기화 작업이 선행되어야 함을 참고하세요.

## 1. 전체 흐름 개요

1. **버퍼 생성**
    
    - `vkCreateBuffer()`를 사용해 GPU 상에 데이터를 저장할 버퍼 객체를 생성합니다.
        
2. **메모리 요구사항 확인**
    
    - `vkGetBufferMemoryRequirements()`로 버퍼가 필요로 하는 메모리 크기, 정렬(alignment), 그리고 메모리 타입 비트플래그를 조회합니다.
        
3. **적합한 메모리 타입 선택**
    
    - 조회한 `memoryTypeBits`와 필요한 메모리 속성(예: `VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT`, `VK_MEMORY_PROPERTY_HOST_COHERENT_BIT`)을 만족하는 메모리 타입 인덱스를 선택합니다.
        
4. **메모리 할당 및 바인딩**
    
    - `vkAllocateMemory()`로 메모리를 할당한 후, `vkBindBufferMemory()`로 버퍼와 할당한 메모리를 바인딩합니다.
        
5. **메모리 매핑 및 데이터 전송**
    
    - `vkMapMemory()`를 통해 할당한 메모리를 CPU 주소 공간에 매핑한 뒤, `memcpy()` 등을 사용해 데이터를 전송합니다.
        
    - 작업 후 `vkUnmapMemory()`로 매핑을 해제합니다.
        

## 2. 코드 예제


```cpp
// 외부에서 정의된 변수:
// VkDevice         device;           // 논리 디바이스
// VkPhysicalDevice physicalDevice;   // 물리 디바이스
// VkDeviceSize     bufferSize;       // 버퍼 크기 (예: 1024 bytes)
// void*            srcData;          // CPU에 있는 원본 데이터

// 1. 버퍼 생성
VkBufferCreateInfo bufferInfo{};
bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
bufferInfo.size = bufferSize;  
bufferInfo.usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT;  // 예시: 데이터 전송 용도
bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

VkBuffer buffer;
if (vkCreateBuffer(device, &bufferInfo, nullptr, &buffer) != VK_SUCCESS) {
    throw std::runtime_error("버퍼 생성에 실패했습니다!");
}

// 2. 버퍼의 메모리 요구사항 가져오기
VkMemoryRequirements memRequirements;
vkGetBufferMemoryRequirements(device, buffer, &memRequirements);

// 3. 메모리 타입 찾기  
// 요구사항에 맞는 메모리 타입 인덱스를 찾기 위한 람다 함수
auto findMemoryType = [&](uint32_t typeFilter, VkMemoryPropertyFlags properties) -> uint32_t {
    VkPhysicalDeviceMemoryProperties memProperties;
    vkGetPhysicalDeviceMemoryProperties(physicalDevice, &memProperties);
    for (uint32_t i = 0; i < memProperties.memoryTypeCount; i++) {
        if ((typeFilter & (1 << i)) &&
            (memProperties.memoryTypes[i].propertyFlags & properties) == properties) {
            return i;
        }
    }
    throw std::runtime_error("적절한 메모리 타입을 찾을 수 없습니다!");
};

uint32_t memoryTypeIndex = findMemoryType(
    memRequirements.memoryTypeBits,
    VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
);

// 4. 메모리 할당
VkMemoryAllocateInfo allocInfo{};
allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
allocInfo.allocationSize = memRequirements.size;
allocInfo.memoryTypeIndex = memoryTypeIndex;

VkDeviceMemory bufferMemory;
if (vkAllocateMemory(device, &allocInfo, nullptr, &bufferMemory) != VK_SUCCESS) {
    throw std::runtime_error("버퍼 메모리 할당에 실패했습니다!");
}

// 5. 버퍼에 메모리 바인딩
vkBindBufferMemory(device, buffer, bufferMemory, 0);

// 6. 메모리 매핑 및 데이터 복사
void* data;
if (vkMapMemory(device, bufferMemory, 0, bufferSize, 0, &data) != VK_SUCCESS) {
    throw std::runtime_error("메모리 매핑에 실패했습니다!");
}
memcpy(data, srcData, static_cast<size_t>(bufferSize));
vkUnmapMemory(device, bufferMemory);
```

## 3. 예제 설명과 흐름

### 버퍼 생성 및 메모리 요구사항

- **버퍼 생성:** `VkBufferCreateInfo` 구조체를 설정한 후 `vkCreateBuffer()`를 호출하여 버퍼 객체를 생성합니다. 이 단계에서는 아직 실제 메모리가 할당되지 않고, 이후 필요한 메모리 크기 및 정렬 정보 등을 확인할 수 있습니다.
    
- **메모리 요구사항 확인:** `vkGetBufferMemoryRequirements()`를 호출하여 버퍼에 필요한 메모리 크기, 정렬, 그리고 호환 가능한 메모리 타입을 나타내는 비트 정보를 받아옵니다.
    

### 메모리 타입 선택과 할당

- **메모리 타입 선택:** `memoryTypeBits`와 원하는 속성(`HOST_VISIBLE` 및 `HOST_COHERENT`)을 만족하는 메모리 타입 인덱스를 검색합니다.
    
- **메모리 할당:** `vkAllocateMemory()`로 검색한 메모리 타입 인덱스로 메모리를 할당합니다.
    
- **바인딩:** `vkBindBufferMemory()`를 호출하여 버퍼와 할당된 메모리를 연결합니다.
    

### 메모리 매핑 및 데이터 전송

- **메모리 매핑:** `vkMapMemory()`를 통해 GPU 메모리를 CPU가 접근 가능한 주소 공간에 매핑합니다.
    
- **데이터 전송:** 매핑된 포인터(`data`)를 사용하여, `memcpy()` 등으로 데이터를 복사합니다.
    
- **매핑 해제:** 데이터 복사 후 `vkUnmapMemory()`를 호출하여 매핑을 해제합니다. _(만약_ `VK_MEMORY_PROPERTY_HOST_COHERENT_BIT`_가 없는 경우, 추가적인 flush 작업이 필요할 수 있습니다.)_
    

## 4. 메모리 관리 전체 흐름 ASCII 다이어그램

```plaintext
+----------------------------------+
|         애플리케이션 (CPU)       |
+----------------------------------+
             │
             │  vkCreateBuffer() → 버퍼 객체 생성
             │  vkGetBufferMemoryRequirements()
             │
             ↓
+----------------------------------+
| 요구되는 메모리 크기 및 속성 정보 |
+----------------------------------+
             │
             │  findMemoryType() → 적합한 메모리 타입 결정
             │
             ↓
+----------------------------------+
|  vkAllocateMemory() → 메모리 할당  |
+----------------------------------+
             │
             │  vkBindBufferMemory() → 버퍼에 메모리 바인딩
             │
             ↓
+----------------------------------+
|       버퍼 객체와 메모리 연결       |
+----------------------------------+
             │
             │  vkMapMemory() → CPU가 접근 가능한 주소 매핑
             │     memcpy()로 데이터 전송
             │  vkUnmapMemory() → 매핑 해제
             ↓
+----------------------------------+
| 호스트에서 GPU로 데이터 전송 완료  |
+----------------------------------+
```

## 5. 추가 정보

- **스테이징 버퍼 사용:** GPU의 device-local 메모리는 성능상 유리하지만 HOST 접근이 불가능할 수 있습니다. 이 경우, **호스트 가시성이 있는 스테이징(staging) 버퍼**를 사용하여 데이터를 먼저 업로드하고, 커맨드 버퍼를 통해 device-local 버퍼로 데이터를 복사합니다.
    
- **메모리 동기화:** `VK_MEMORY_PROPERTY_HOST_COHERENT_BIT`를 사용하지 않으면, 데이터를 매핑한 후 `vkFlushMappedMemoryRanges()`를 호출해 CPU의 변경사항을 GPU에 반영하거나, GPU 작업 후 `vkInvalidateMappedMemoryRanges()`를 호출해 최신 데이터를 CPU가 볼 수 있도록 해야 합니다.
    
- **자원 해제:** 사용이 끝난 후에는 `vkDestroyBuffer()`와 `vkFreeMemory()`를 호출하여 할당된 자원을 적절히 해제합니다.