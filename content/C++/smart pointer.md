# smart pointer

# 1. 정의

포인터처럼 동작하는 클래스 템플릿으로, 사용이 끝난 메모리를 자동으로 해제해 줍니다. 

→ delete를 자동으로 수행한다.

참조하고 있는 스마트 포인터의 개수를 **reference count**라고 한다.

### **reference count**

메모리에서 객체를 가리키는 참조 또는 포인터의 수를 추적하는 방법

- 새 참조가 생성되면, reference count 증가
- 개체에 대한 참조가 삭제되면, reference count 감소
- reference count가 0 이면, 개체가 자동으로 삭제되므로 동적으로 할당된 개체가 더 이상 필요하지 않을 때 할당이 해제됩니다.

# 2. unique_ptr

객체가 가리키는 객체의 수명을 관리하는 유일한 포인터임을 의미한다.

- 개체의 소유권을 다른 unique_ptr로 이전하는 복사할 수 없고 이동만 가능합니다.

# 3. shared_ptr

하나의 특정 객체를 참조하는 스마트 포인터가 총 몇 개인지를 참조하는 스마트 포인터

- 개체에 대한 참조 수를 추적하고 개체를 관리하는 마지막 shared_ptr이 파괴될 때 자동으로 메모리 할당을 해제한다.

# 4. weak_ptr

**shared_ptr**에서 사용되는 **약한 참조**이다. **shared_ptr**이 관리하는 객체를 참조할 뿐입니다.

→ **weak_ptr은 shared_ptr의 참조자라고 생각하면 좋다.**

- **`shared_ptr`** 이 관리하는 객체가 소멸될 때까지 `weak_ptr`이 참조하는 객체가 메모리에서 유지됩니다.
- **`weak_ptr`**을 통해 객체에 접근할 때, 객체가 소멸된 경우 **`nullptr`**이 반환된다.
- **`shared_ptr`**으로 관리되는 객체에만 접근 가능하다.
- 객체의 생명주기에 영향을 미치지 않고 객체를 관찰할 수 있도록 한다.

# 5. auto_ptr

C++11 이후에 사라진 스마트 포인터 이다.

동적으로 할당된 객체에 대한 자동 메모리 관리를 제공한다. 하지만 **표준 라이브러리의 다른 부분과의 제한된 호환성, 복사 할당을 통해 관리 개체의 소유권만 auto_ptr로 전송할 수 있다는 점** 등 여러 단점이 있다.

→ **unique_ptr**는 비슷한 기능을 제공하지만, 추가적인 기능과 제한이 적다. unique_ptr을 사용하는 것이 좋다.

## 6. intrusive_ptr

intrusive_ptr은 reference count를 스마트 포인터에서 관리되는 객체에서 직접 관리한다.

사용하는 주된 이유

- 일부 기존 프레임워크 또는 OS는 참조 횟수가 포함된 개체를 제공합니다.
- intrusive_ptr의 메모리 공간은 해당 원시 포인터와 동일합니다.
- intrusive_ptr<T>는 T * 유형의 임의 원시 포인터에서 구성할 수 있습니다.

필요한 경우 → 가리키는 클래스의 멤버 함수가 다른 스마트 포인터에서 사용할 수 있도록 this를 반환해야 하는 경우

## chatgpt code

```cpp
// main.cc

#include "./head.h"

int main() {
  // std::unique_ptr
  cout << "std::unique_ptr" << endl;
  {
    std::unique_ptr<Expl> example = std::make_unique<Expl>();
    example->Print();
  }
  cout << "" << endl;

  // std::shared_ptr
  cout << "std::shared_ptr" << endl;
  {
    std::shared_ptr<Expl> example = std::make_shared<Expl>();
    std::cout << "Number of references: " << example.use_count() << std::endl;
    std::shared_ptr<Expl> example2 = example;
    std::cout << "Number of references: " << example.use_count() << std::endl;
  }
  cout << "" << endl;

  // std::weak_ptr
  cout << "std::weak_ptr" << endl;
  {
    std::shared_ptr<Expl> example = std::make_shared<Expl>();
    std::weak_ptr<Expl> weak_example = example;
    if (!weak_example.expired()) {
      std::shared_ptr<Expl> example2 = weak_example.lock();
      example2->Print();
    }
  }
  cout << "" << endl;

  // std::auto_ptr
  cout << "std::auto_ptr" << endl;
  {
    Expl *a = new Expl();
    Expl *b = new Expl();
    std::auto_ptr<Expl> example = std::auto_ptr<Expl>(a);
    example->Print();
  }
  cout << "" << endl;

  return 0;
}
```

```cpp
// head.h

#ifndef SMART_POINTER_HEAD_H_
#define SMART_POINTER_HEAD_H_

#include <iostream>
#include <memory>

using std::cout;
using std::endl;

class Expl {
 public:
  Expl();
  ~Expl();
  void Print();
};

#endif  // !SMART_POINTER_HEAD_H_
```

```cpp
#include "./head.h"

Expl::Expl() { std::cout << "object created." << std::endl; }

Expl::~Expl() { std::cout << "object destroyed." << std::endl; }

void Expl::Print() {
  std::cout << "object being used." << std::endl;
}
```