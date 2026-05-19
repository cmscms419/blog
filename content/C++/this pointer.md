# this pointer

# 1. 정의

**할당된 객체의 시작 포인터**

객체의 시작 주소는 객체 포인터로 참조한다.

this는 객체 포인터이지만, 실행 시간(run-time)에 자동으로 계산되는 객체의 시작 주소이다.

→ 즉 어떤 객체가 만들어지면, 만들어진 객체의 시작 주소가 this로 설정되어, 멤버 함수를 호출할 때마다, this 포인터는 묵시적으로 멤버 함수에 자동으로 전달된다.

# 2. 메모리와 this pointer 관계

객체가 메모리에 할당 될 때, 멤버 변수가 할당된다.

멤버 함수는 모든 코드에 할당되는 것이 아니라, 객체를 통한 멤버 함수의 호출은 적절한 함수 호출로 변환된다.

→ 객체를 위해 단순히 멤버 변수만이 할당 된다.

stack 메모리에 들어가는 것은 block 안에 선언된 멤버 변수로, 지역 객체이다.

# 3. this를 꼭 사용해야 하는 경우

## 지역 변수와 멤버 변수 구분

```cpp
CTest::i == this->i
// 같은 의미이다.
```

하지만, 전자는 정적 변수를 사용한다는 느낌이 있어서, 후자를 사용하는 것이 바람직 하다.

### 함수의 파라미터로 객체 자신을 전달하는 경우

![Untitled](attachments/Untitled_17.png)

this는 객체의 시작 주소를 가리키는 포인터를 반환한다.

## 멤버 함수가 객체 자신을 리턴하는 경우

```cpp
#include <iostream>

class Position {
 public:
  Position();

  void show() { std::cout << this << std::endl; }
  void show2() { std::cout << x << std::endl; }
  void Func() const {}
  Position Self();

 private:
  int x;
  int y;
};

Position::Position() {
  x = 100;
  y = 0;
}

Position Position::Self() {
  ++x;
  return *this;
}

void main() {
  Position a;
  a.show();
  a.show2();

  a.Self().show2();

  return;
}
```

```cpp
// 출력 결과
000000CD64EFFAF8
100
101
```

# 4. const function

### 함수 뒤에 있을 때(void Func() const)

클래스 멤버변수를 바꾸지 않겠다는 의미이다.

Reader 함수라고 한다. → 객체의 속성 값을 읽기만 해야 하는 함수

```cpp
class Test
{
	int k;
    void NonConstFunc()
    {
    	k=3;
    }
	void Func() const
	{
		//k=3 -> 에러발생
    //NonConstFunc() -> 에러발생
	};
};
```

### 함수 앞에 있을 때(const void Func())

함수의 리턴값을 상수화 시키겠다는 의미이다.

```cpp
class Test
{
	int k;
public:
	Test();
	const int Func()
	{
		k = 3;
		return k;

	};
	const int& RefFunc(int a)
	{
		int& A = a;
		return A;
	}
};
```

# 5. mutable keyword

mutable : 변이 가능한

멤버 변수를 mutable로 선언했다면, const 함수에서도 값을 바꿀 수 있다.

### 왜 필요한가?

1. 멤버 함수를 const로 선언하는 의미는 이 함수는 “객체의 내부 상태에 영향을 주지 않는다.”를 표현하는 방법이다. 읽기 작업을 수행하는 함수
2. mutable  변수의 용도를 쉽게 파악할 수 있다.