---
title: "[ Vulkan 연구 ] Memory Management Basic"
source: https://lifeisforu.tistory.com/408
author:
  - "[[그냥 그런 블로그]]"
published: 2018-11-13
created: 2025-03-11
tags:
  - Vulkan
  - 연구
---
## [\[ Vulkan 연구 \] Memory Management Basic](https://lifeisforu.tistory.com/408)

2018\. 11. 13. 09:32

주의 : 이 문서는 초심자 튜토리얼이 아닙니다. 기본 개념 정도는 안다고 가정합니다. 초심자는 \[ [Vulkan Tutorial](https://vulkan-tutorial.com/) \] 이나 \[ [Vulkan Samples Tutorial](https://vulkan.lunarg.com/doc/sdk/1.1.85.0/windows/tutorial/html/index.html) \] 을 보면서 같이 보시기 바랍니다.

주의 : 완전히 이해하고 작성한 글이 아니므로 잘못된 내용이 포함되어 있을 수 있습니다.

주의 : 이상하면 참고자료를 확인하세요.

정보 : 본문의 소스 코드는 [Vulkan C++ exmaples and demos](https://github.com/SaschaWillems/Vulkan) 를 기반으로 하고 있습니다. 

---

  

Vulkan 이나 D3D 12 로 오면서 가장 큰 변화는 저수준( low-level ) API 를 제공한다는 점에 있다고 할 수 있습니다. 앞서 살펴 봤던 커맨드 큐도 그렇고 메모리마저 응용프로그램이 관리할 수 있도록 하고 있습니다.

  

다음과 같은 이유들 때문에 커스텀 메모리 관리를 사용하게 됩니다\[ 2 \]:

  

- 메모리 할당은 종종 다소 무거운 운영체제의 동작을 포함합니다.
- 이미 할당한 메모리를 재사용하는 것이 그것을 해제하고 새로운 메모리를 재할당하는 것보다 빠릅니다.
- 연속된 청크의 메모리에 있는 오브젝트는 캐시 활용도를 높일 수 있습니다.
- 하드웨어에 대해 잘 정렬된 데이터는 더 빠르게 처리될 수 있습니다.

  

오늘은 이러한 메모리 관리에 대해서 알아 보고자 합니다.

  

## **Device & Host**

  

Vulkan 에서 "메모리 관리" 라는 개념에 친숙해지기 위해서는 디바이스와 호스트라는 관리 영역에 대해서 익숙해질 필요가 있습니다. 디바이스는 그래픽 카드를 의미하는 것이며 호스트는 디바이스를 이용하는 응용프로그램이 실행되는 시스템을 의미합니다.

  

일반적으로 디바이스와 호스트는 개별 메모리를 가지고 있습니다. SoC( System On Chip )을 사용하는 일부 머신을 제외하면 대부분의 데스크탑은 그래픽스 카드를 따로 가지고 있습니다. 물론 최신의 범용 프로세서들이 그 내부에 그래픽스 카드를 내장하고 있기는 하지만, 게이밍 그래픽스 하드웨어로서 그것을 사용하는 경우는 많지 않으므로 신경쓰지는 않겠습니다.

  

PS4 나 Xbox One 과 같은 게이밍 콘솔들도 SoC 에 GPU 를 내장하고 있습니다.

  

> 전통적인 PC 들은 고사양 GPU 와 같은 특정 작업을 위한 가속기들을 추가하는 옵션을 가진 일반화된 시스템으로서 설계되었습니다. 콘솔의 경우에는 적은 공간을 필요로 하고 게임을 위해서 목적성있게 만들어졌기 때문에, 많은 컴포넌트들을 통합하는 것이 유리합니다. 스마트폰, 게임 콘솔, PC 는 모두 SoC 혹은 System-on-Chip 이라 알려진 상당히 통합되어 있는 프로세서를 사용합니다. SoC 는 실제 CPU 코어와 CPU L1, L2 캐시, 그래픽 프로세서, 다양한 연결성( USB 포트, 하드 드라이브 ), 그리고 다른 기능블락들 및 메인 시스템 RAM 사이의 인터페이스 역할을 하는 메모리 컨트롤러 등을 포함합니다. 예전에는 이런 기능들이 보통 마더보드상에 다중의 칩으로 나뉘어 있었지만, 요새는 하나의 기능 블락으로 통합됩니다.
> 
>   
> 
> 출처 : \[ 3 \]

  

이런 SoC 같은 경우에는 모든 컴포넌트들이 RAM 을 공유하게 됩니다. 예를 들어 RAM 중에서 GPU 를 위해 사용되는 메모리를 할당/해제/전송하기 위해 사용하는 버스를 갈릭 버스( Garlic Bus )라 부르고, CPU 를 위해 사용되는 메모리를 할당/해제/전송하기 위해 사용하는 버스를 어니언 버스( Onion Bus )라고 부릅니다. 예전에 콘솔쪽 작업을 할 때 이것이 PS4 전용 용어인줄 알았는데, XBox 문서에서도 그렇게 구분하고 있더군요. 그런데 이 버스들이 사용할 수 있는 메모리의 총량을 미리 정할 수 있도록 하고 있습니다. 예를 들어 "갈릭 버스를 위해서 4 GB 를 할당한다"고 정할 수 있습니다. 그러면 소위 말하는 그래픽스 메모리는 4 GB 인 것입니다. 하나의 램을 사용하는데 굳이 이렇게 하는 이유는 모르겠습니다. 아마도 성능을 위해 메모리 지역성( locality )을 유지하려고 하는게 아닌가 싶습니다.

  

아래 그림을 보면 GPU 를 제외한 다른 장치들은 노스브릿지를 통해서 DRAM 과 통신합니다. 이때 사용하는 버스를 어니언 버스라고 부릅니다. 그리고 GPU 는 전용 메모리 컨트롤러를 통해서 DRAM 과 통신합니다. 이 때 사용하는 버스를 갈릭 버스라 부릅니다. 그런데 갈릭 버스의 대역폭이 어니언 버스의 대역폭보다 크다는 것을 알 수 있습니다. 이는 노스브릿지의 한계 때문이라고 합니다\[ 4 \]. Xbox one 의 구조에 대해서 더 자세하게 알고자 한다면 \[ 4 \] 를 참고하세요.

  

![](https://t1.daumcdn.net/cfile/tistory/999BE0335BEA14B935)

출처 : \[ 4 \].

  

어쨌든 이러한 SoC 가 아닌 이상에는 디바이스 메모리와 호스트( 시스템 ) 메모리는 구분될 수밖에 없습니다.

  

## **Heap Memory**

  

힙이라는 것은 디바이스나 호스트에 있는 RAM 에 할당된 메모리 블락을 의미합니다. 

  

이것을 관리하는 것은 OS 마다 다릅니다. 일단 윈도우즈에 국한해 설명드리자면 다음과 같이 메모리를 계층적으로 관리합니다( 아래 그림은 Win32 시절에 작성된 것이지만 Win64 에서도 유사합니다. ).

  

![](https://t1.daumcdn.net/cfile/tistory/991723345BEF6C1B03)

출처 : \[ 9 \].

  

물리 메모리는 페이지 단위로 관리됩니다. 일반적으로 4 KB 를 사용하는 것으로 알고 있습니다. 예를 들어 4 KB 의 페이지를 사용하는 OS 에서 응용프로그램이 1 B 의 메모리를 할당하고 싶다고 하더라도 최소 4 KB 의 메모리가 할당된다는 것입니다. 1 B 를 위해서 4 KB 를 할당하면 낭비가 심해질 것입니다. 그러므로 페이지에서 다중의 오브젝트를 위한 메모리가 할당될 수 있습니다.

  

그런데 여기에는 몇 가지 문제가 있습니다.

  

- OS 에는 여러 개의 프로그램이 있을 수 있는데, 그것들의 메모리 사용량을 합치면 물리 메모리의 양을 넘어설 수 있습니다. 이를 위해서는 메모리 상태를 관리하면서 필요한  메모리를 물리 메모리에 올리거나 불필요한 메모리를 물리 메모리에서 내려서 백업하는 등의 복잡한 작업이 필요합니다.
- 페이지 내부에서 메모리 할당/해제하는 기능을 구현해야 합니다.

  

그래서 OS 들은 가상 메모리( virtual memory )라는 개념을 중심으로 응용프로그램의 메모리를 관리하고 위에서 언급했던 여러 가지 이슈들은 OS 에서 알아서 처리합니다. 그래서 어떤 메모리 할당 함수든 최종적으로는 VirtualAlloc/VirtualFree 같은 함수들을 호출하게 됩니다. new/delete, malloc/free 도 모두 최종적으로는 앞의 함수들을 호출합니다.

  

그런데 VirtualAlloc/VirtualFree 도 메모리 상태( Reserved, Committed, Free )관리를 할 필요가 있습니다. 그래서 이것보다는 좀 더 쉽게 메모리 블락을 사용할 수 있는 레이어로서 힙이 만들어졌습니다. 일단 따로 OS 의 메모리 할당함수를 사용하지 않는다면 new/delete, malloc/free 류의 연산자/함수들은 이 힙과 연결됩니다. 이 힙은 최소한 4 KB 의 크기를 가집니다. 위에서 말한 물리 메모리 크기와 같죠. 이렇게 해야 페이지 단위로 물리 메모리에 올렸다가 다시 내렸다가 하는 것이 가능해집니다.

  

이야기가 좀 길어졌는데요, 더욱 자세한 내용에 대해 알고자 하신다면 \[ 9 \], \[ 10 \] 의 MSDN 문서를 참고하시기 바랍니다.

  

어쨌든, 이제 상상을 좀 해 보죠. 앞서 응용프로그램은 가상 메모리를 사용한다고 했습니다. 그러면 그 메모리들은 물리 메모리에 매핑되어 올라갔다 내려갔다 합니다. 실제 물리 메모리에서 그 주소가 어떻게 될지는 아무도 모르죠. 하지만 적어도 응용프로그램에서의 가상메모리는 4 KB 단위로 선형적입니다.

  

예를 들어 2 GB 의 물리메모리( RAM )를 가지고 있다고 가정하고, 이상적인 환경에서 응용프로그램이 그 물리메모리를 온전히 사용할 수 있다고 가정해 봅시다. 그리고 힙 하나의 크기를 64 KB 라고 가저합시다. 그러면 응용프로그램이 8 GB / 64 KB = 32768 개 만큼의 힙을 가지고 있게 됩니다. 물론 OS 마다 기본 힙 크기와 물리 메모리 크기는 다를 수 있으므로 단순한 예일 뿐입니다.

  

그러면 응용프로그램 입장에서는 다음과 같이 선형적으로 메모리를 관리할 수 있겠죠.

  

![](https://t1.daumcdn.net/cfile/tistory/990376435BEF733A09)

  

"그래서 뭐?" 라는 의문이 들 겁니다. 이렇게 선형적으로 관리하게 되면 할당된 가상 메모리 주소를 64 K 로 나누는 것만으로 힙의 인덱스( offset )을 알아낼 수 있다는 것입니다. 이것보다는 복잡하기는 하지만, 일반적인 페이지 기반 메모리 풀들은 이런 식으로 메모리 풀을 관리합니다. 여기서 이야기하고자 하는 핵심은 대부분의 커스텀 메모리 관리자들이, 메모리를 관리할 때, 특정 크기의 힙 블락이나 가상 메모리 블락을 사용한다는 것입니다.

  

뜬금없이 여기에서 힙에 대해서 이야기한 이유는, 아래에서 메모리 타입을 이야기할 때, 힙에 대해서 언급하기 때문입니다.

  

## **Object Creation & Memory Allocation**

  

모든 Vulkan 오브젝트들은 **"vkCreate"** 라는 접두어를 가진 함수들을 통해서 생성됩니다. 그런데 이런 함수에는 항상 pAllocator 라는 인자를 넘기게 되어 있습니다. 예를 들어 **vkCreateInstance**() 의 원형은 다음과 같습니다.

  

  

만약 pAllocator 에 nullptr 를 넣으면 커스텀 할당이 없이 그냥 OS 기본동작에 의해 메모리 할당이 이루어집니다. VkAllocationCallbacks의 정의는 다음과 같습니다.

  

  

이 구조체의 필드에는 여러 개의 함수 포인터들이 존재합니다. 기본적으로 malloc(), free(), realloc() 과 관련한 호출에 매핑되는 콜백 함수들이 있고, 통지( nofitication )와 관련한 콜백 함수들이 있습니다. 이런 콜백들을 잘 이용하면 메모리 프로우파일러들을 만들 수도 있습니다. 할당하는 예를 들어 보면 다음과 같습니다\[ 8 \].

  

  

이 글의 주제는 커스텀 메모리 관리자 구현과 관련해서 이야기하는 것이 아니므로 더 깊게 파고들지는 않겠습니다.

  

Vulkan 에서는 오브젝트 생성과 메모리 할당을 분리해서 생각하고 있습니다. 대표적으로 그런 형태를 띄고 있는 오브젝트를 리소스라 부릅니다. 리소스는 크게 두 가지로 나뉩니다; 버퍼( buffer )와 이미지( image ).

  

버퍼는 단순한 선형 메모리를 의미합니다. 그리고 이미지는 구조화되고 타입 및 포맷 정보를 가진 메모리입니다. 이러한 리소스들은 오브젝트 생성과 메모리 할당이 분리되어 있습니다. 그래서 이런 개념을 모르는 상태라면, 리소스를 생성했지만 실제로는 아무런 메모리도 할당되어 있지 않아 당황하게 되는 상황에 부딪힐 수 있습니다.

  

리소스를 온전히 생성하기 위해서는 다음과 같은 과정을 거쳐야 합니다.

  

- vkCreateBuffer() 나 vkCreateImage() 를 호출해서 오브젝트를 생성합니다.
- vkAllocateMemory() 를 호출해서 메모리를 할당합니다.
- vkBindBufferMemory() 나 vkBindImageMemroy() 를 호출해서 할당된 메모리를 오브젝트와 연관시킵니다.

  

굳이 이렇게 복잡한 과정을 거치는 이유는 메모리 관리를 유연하게 만들기 위한 것으로 보입니다. 이런 구조를 가지게 되면 호스트측에서 오브젝트를 파괴하지 않고 메모리를 재할당하는 것이 가능해집니다. 그리고 서로 다른 오브젝트가 같은 메모리를 공유할 수 있도록 해 줍니다. 심지어는 ( 서로 다른 디바이스에서 ) 같은 메모리를 공유하도록 만들수도 있다고 합니다.

  

## **Memory Properties**

  

앞에서 vkAllocateMemory() 에 대해서 언급했습니다. 이 함수의 원형은 다음과 같습니다.

  

  

pAllocator 에 대해서는 앞에서 살펴 봤었죠. pAllocateInfo 에 대해서 살펴 보도록 하겠습니다. VkMemoryAllocateInfo 라는 것은 다음과 같이 정의됩니다.

  

  

여기에서 allocationSize 는 바이트 단위 할당 크기므로 별건 없고, memoryTypeIndex 라는 녀석이 중요합니다. 이 memoryTypeIndex 라는 것은 VkPhysicalDeviceMemoryProperties 구조체로부터 가지고 온 인덱스입니다. 이 구조체는 vkGetPhysicalDevicememoryProperties() 함수 호출을 통해서 얻어 올 수 있는 것이며, 다음과 같이 정의되어 있습니다.

  

  

이제 슬슬 짜증나기 시작하실텐데요... 곧 정리가 될 겁니다. 새롭게 두 가지 종류의 필드가 존재합니다. 메모리 타입과 힙입니다. 이 메모리 타입과 힙 타입을 잘 골라야 자신이 원하는 형태의 메모리를 할당받을 수 있습니다.

  

## **Memory Type**

  

메모리 타입은 다음과 같이 정의됩니다.

  

  

heapIndex 는 이 메모리가 연관되어 있는 힙이 무엇인지 지정하는 것입니다. 이건 VkPhysicalDeviceMemoryProperties::memoryHeapCount 보다는 작아야 합니다. 그리고 propertyFlags 는 접근성이나 할당 방식과 관련한 속성들의 비트 플래그입니다. 이는 다음과 같이 정의되어 있습니다.

  

  

이 플래그값이 0 이라면 호스트 메모리를 의미합니다. 기본적으로 응용프로그램이 시스템 메모리에 접근하는 것은 ( 응용프로그램이 할당한 메모리라는 가정하에서 ) 제약이 없기 때문에, 디바이스에서 할당되는 메모리에만 이러한 플래그가 조합되는 것으로 보입니다.

  

그 의미는 다음과 같습니다.

  

- VK\_MEMORY\_PROPERTY\_DEVICE\_LOCAL\_BIT : 디바이스 전용 메모리입니다. 호스트에서 접근할 수가 없습니다.
- VK\_MEMORY\_PROPERTY\_HOST\_VISIBLE\_BIT : 호스트에서 vkMapMemory() 커맨드를 통해서 접근할 수 있는 디바이스 메모리입니다.
- VK\_MEMORY\_PROPERTY\_HOST\_COHERENT\_BIT : 코우히어런트( coherent )는 일관성이라는 뜻이죠. 이것과 관련해서는 언급해야 할 내용이 좀 많아서 아래에서 따로 설명하도록 하겠습니다.
- VK\_MEMORY\_PROPERTY\_HOST\_CACHED\_BIT : 호스트에 캐싱된 메모리라는 의미입니다. 캐싱되지 않은 메모리에 호스트가 접근하는 것은 캐싱된 메모리에 접근하는 것 보다 느립니다. 캐싱되지 않은 메모리는 항상 HOST\_COHERENT 합니다.
- VK\_MEMORY\_PROPERTY\_LAZILY\_ALLOCATED\_BIT : 즉시 할당되는 것이 아니라 필요할 때 할당될 수 있는 디바이스 전용 메모리입니다. VK\_MEMORY\_PROPERTY\_HOST\_VISIBLE\_BIT 와 같이 설정되어서는 안 됩니다.

  

CPU 나 GPU 는 위의 플래그들에 따라서 메모리에 접근하는 것이 가능합니다. 여기에서 약간 혼란스러운 점이 있을 수 있는데, 물리적으로 호스트에 존재하는 메모리라고 할지라도 디바이스용으로 할당되면 디바이스 메모리입니다. 여기에서 제가 "물리 디바이스 메모리" 가 아니라 "디바이스 메모리" 라고 하고 있다는 데 주의하시기 바랍니다. SoC 가 아니더라도 디바이스가 호스트 메모리의 일부를 공유할 수 있습니다. 순수하게 물리 디바이스 메모리에 할당하기 위해서는 DEVICE\_LOCAL 로 만드시면 됩니다.

  

![](https://t1.daumcdn.net/cfile/tistory/99F7E2415BECBEC603)

출처 : \[ 8 \].

  

Vulkan spec 에 따르면 호스트 메모리와 디바이스 메모리는 다음과 같이 정의되어 있습니다.

  

> Host memory is memory needed by the Vulkan implementation for non-device-visible storage.
> 
>   
> 
> Device memory is memory that is visible to the device — for example the contents of the image or buffer objects, which can be natively used by the device.

  

## **Coherent Memory Access**

  

다중의 코어가 동일한 메모리에 접근하고 있다고 가정해 봅시다. 한 코어는 쓰고 있고 다른 코어는 읽고 있다고 가정해 보죠( 전자를 라이터라 하고 후자를 리더라 하겠습니다 ). 라이터가 메모리에다가 데이터를 쓸 때 그것은 데이터를 메모리에 직접 쓰지 않습니다. 일단 자신의 캐시에다가 쓴 다음에 그것을 메모리로 옮기게 됩니다. 리더는 동일한 메모리에 접근을 해야 하죠. 마찬가지로 리더도 메모리를 바로 읽는 것이 아니라 캐시에서 읽게 됩니다. 

  

동시에 메모리에 접근을 하는 상황에서 캐시를 공유하고 있다면 별 문제가 없겠죠. 하지만 코어마다 캐시를 따로 유지하는 경우가 많기 때문에 동일한 내용을 획득할 수 있는 방법이 필요합니다. 이것을 캐시 일관성이라고 하죠. 캐시 일관성에 대해 더 알고자 한다면 \[ [7](http://ypangtrouble.tistory.com/entry/%EC%BA%90%EC%8B%9C-%EC%9D%BC%EA%B4%80%EC%84%B1%EA%B3%BC-%EA%B1%B0%EC%A7%93-%EA%B3%B5%EC%9C%A0) \] 의 문서를 참조하세요. 그림을 통해서 쉽게 설명하고 있습니다.

  

![](https://t1.daumcdn.net/cfile/tistory/9910314A5BEC0C4B20)

출처 : \[ 6 \].

  

SoC 를 사용하지 않는 대부분의 머신에서는 CPU 와 GPU 가 다른 디바이스에 존재합니다. 그리고 서로 다른 캐시를 가지고 있습니다. 그래서 GPU 가 CPU 의 캐시에 접근할 수가 없습니다. 같은 프로세서 내의 코어들은 어떻게든 서로의 캐시에 접근해 일관성을 보장할 수 있지만, 장치가 아예 달라지면 그게 불가능합니다. 언제 캐시에 있는 데이터가 메모리에 복사되는지 알 방법이 없습니다.

  

그래서 GPU 는 메모리 일관성이라는 개념을 제공합니다. 그것이 바로 VK\_MEMORY\_PROPERTY\_HOST\_COHERENT\_BIT 입니다. 이런 종류의 메모리에 대한 읽기/쓰기 작업은 일관성이 보장된다는 의미입니다.

  

예를 들어 보겠습니다. vkMapMemeory() 함수는 응용프로그램의 메모리 주소로 오브젝트의 메모리를 매핑합니다. Vulkan 에서는 이를 "호스트에 매핑되었다" 고 표현합니다. 응용프로그램이 그 메모리에 대한 쓰기 작업을 하고 나면 vkFlushMappedMemoryRanges() 를 호출합니다. 그래야 완전히 작업이 끝난 메모리에 GPU 가 접근할 수 있죠. 

  

  

코드에서 볼 수 있듯이 VK\_MEMORY\_PROPERTY\_HOST\_COHERENT\_BIT 가 지정되어 있으면 vkFlushMappedMemoryRange() 호출이 필요하지 않습니다. 일관성이 보장되기 때문입니다.

  

## **Memory Heap**

  

메모리 힙은 다음과 같이 정의됩니다.

  

  

위에서 제가 64 KB 단위로 전체 메모리를 쪼개서 관리하는 예를 들어 드렸죠? 하지만 그 힙의 크기는 다양할 수 있습니다. 적어도 VkMemoryAllcoateInfo::allocationSize 보다는 큰 힙을 골라야겠죠. 

  

그런데 여기에 조금 애매한 점이 존재합니다. 메모리 단편화라는 것을 고려해야 하기 때문에 적절한 크기의 힙을 골라야 합니다. 여기에서부터는 응용프로그램마다 다른 최적화 영역이 되는 겁니다.

  

**정리**

  

메모리는 호스트 메모리와 디바이스 메모리로 나뉩니다. 호스트 메모리는 호스트측에 할당된 메모리이고 디바이스 메모리는 디바이스측에 할당된 메모리입니다. 물론 서로 VISIBLE 관계에 존재할 수는 있습니다. 호스트에 물리적으로 장착되어 있는 메모리라 할지라도 디바이스가 사용하게 되면 그것은 디바이스 메모리라 불립니다.

  

모든 Vulkan 오브젝트는 별도의 메모리 풀을 통해서 관리될 수 있습니다. 특히 리소스( 이미지, 버퍼 )의 경우에는 오브젝트 생성과 메모리 할당/바인딩이 분리되어 있습니다. 이는 재사용성을 높일 수 있고 원하는 형태로 메모리를 관리할 수 있도록 해 줍니다.

  

여기까지는 기본적인 메모리 관리라고 할 수 있는데요, 사실 리소스 메모리 관리를 위해서는 좀 더 특별한 기법들이 있습니다; staging, alignment, aliasing, offset 등\[ 2, 5 \]. 그러한 특별한 기법들에 대해서는 다음에 다루도록 하겠습니다.

  

**참고 자료**
\[ 1 \] [Vulkan 1.1 Specification](https://www.khronos.org/registry/vulkan/specs/1.1-extensions/html/vkspec.html), Khronos.
\[ 2 \] [Vulkan Memory Management](https://developer.nvidia.com/vulkan-memory-management), NVidia.
\[ 3 \] [Here's How the Inside of Your Gaming Console Really Works](https://www.extremetech.com/gaming/268066-heres-how-the-inside-of-your-gaming-console-really-works), extreamtech.
\[ 4 \] [Xbox One SDK & Hardware Leak Analysis CPU, GPU, RAM & More Part One - Tech Tribunal](http://www.redgamingtech.com/xbox-one-sdk-hardware-leak-analysis-cpu-gpu-ram-more-part-one-tech-tribunal/), redgamingtech.
\[ 5 \]. [Memory management in Vulkan](https://www.khronos.org/assets/uploads/developers/library/2018-vulkan-devday/03-Memory.pdf), Vulkan DEVELOPER DAY.
\[ 6 \] [캐시 일관성](https://ko.wikipedia.org/wiki/%EC%BA%90%EC%8B%9C_%EC%9D%BC%EA%B4%80%EC%84%B1), 위키백과.
\[ 7 \] [캐시 일관성과 거짓 공유](http://ypangtrouble.tistory.com/entry/%EC%BA%90%EC%8B%9C-%EC%9D%BC%EA%B4%80%EC%84%B1%EA%B3%BC-%EA%B1%B0%EC%A7%93-%EA%B3%B5%EC%9C%A0), 끄적끄적 소소한 일상.
\[ 8 \] [Vulkan Programming Guide : The Official Guide to Learning Vulkan](http://www.informit.com/articles/article.aspx?p=2756465&seqNum=3), informIT. 
\[ 9 \] [Managing Virtual Memory](https://msdn.microsoft.com/en-us/library/ms810627.aspx), MSDN.
\[ 10 \] [Managing Heap Memory](https://msdn.microsoft.com/en-us/library/ms810603.aspx), MSDN.

[저작자표시 비영리 변경금지](https://creativecommons.org/licenses/by-nc-nd/4.0/deed.ko)

[Note](https://lifeisforu.tistory.com/408)