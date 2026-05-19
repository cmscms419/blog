# 가상(virutal)에 관하여

## 1. 가상의 의미

### 사전에서 찾아본 가상(virutal)의 단어의 의미

사실이 아니거나 사실 여부가 분명하지 않은 것을 사실이라고 가정하여 생각함.

### 객체 지향 프로그래밍에서 가상(가상함수)의 의미

부모 클래스에서 상속받은 클래스에서 재정의 할 것으로 기대하고 정의한 함수이다.

## 2. 순수 가상함수란

선언만 있고, 구현이 없는 함수를 의미한다.

```cpp
// 예)
virtual void func() = 0;
```

이와 동시에 순수 가상함수를 포함한 클래스를 추상 클래스라고 한다.

## 3. 가상 베이스 클래스

가상 + 베이스 클래스로 따로 보면,

베이스 클래스 : 상속관계에서 상속되어지는, 즉 이미 재정의 하려고 하는 클래스이다.

가상(virtual) : 오버라이딩을 하기 바라는 키워드

→ 자식 클래스에서 재정의 하기 바라는 베이스 클래스이다.

## 4. 가상 소멸자

```cpp
#include <iostream>

using namespace std;

class A
{
public:
	A(const char* str) {
		strA = new char[strlen(str) + 1];
	}

	~A() { // 중요
		cout << "~A" << endl;
		delete []strA;
	}

private:
	char* strA;
};

class B : public A
{
public:
	B(const char* str1, const char* str2) : A(str1)
	{
		strB = new char[strlen(str2) + 1];
	}

	~B() // 중요
	{
		cout << "~B" << endl;
		delete []strB;
	}

private:
	char* strB;
};

int main() {
	A* ptr = new B("one", "two");
	delete ptr;

	return 0;
}
```

A* ptr = new B("one", "two");

코드를 실행 시킬 때, A와 B의 생성자 모두 실행된다.

하지만, 소멸자는 A만 실행된다. 왜냐하면 A형의 포인터로 선언을 해서, A의 소멸자만 호출하게 된다. strB가 남아서 메모리 누수가 발생한다.

![[Untitled]]%E1%84%8B%E1%85%A6%20%E1%84%80%E1%85%AA%E1%86%AB%E1%84%92%E1%85%A1%E1%84%8B%E1%85%A7%2027e25bfe32394dd5ad0e354f880bc571/Untitled.png)

→ 객체의 소멸 과정에서 포인터 변수의 자료형에 상관없이 모든 소멸자가 호출되려면, 필요한 것이 **가상 소멸자**이다.

```cpp
...
virtual ~A() {
		cout << "~A" << endl;
		delete []strA;
	}
...
```

가상 소멸자가 호출되면, 상속 구조의 맨 아래에 있는 유도 클래스의 소멸자가 대신 호출되면서, 베이스 클래스의 소멸자가 순서대로 호출된다.

![[Untitled]]%E1%84%8B%E1%85%A6%20%E1%84%80%E1%85%AA%E1%86%AB%E1%84%92%E1%85%A1%E1%84%8B%E1%85%A7%2027e25bfe32394dd5ad0e354f880bc571/Untitled%201.png)

## 5. 메시지 맵

Windows 프로그램을 만들 때, 메시지가 오고가는 것을 제어하고 싶을 때, MFC에서 사용하는 MFC API이다.

### MFC 메시지 전달 순서

CView -> CDocument -> CDocTemplate ->CFrameWnd -> CWinApp

### MFC 메시지 맵이 필요한 이유

참고) [http://hyacinth.byus.net/moniwiki/wiki.php/C%2B%2B/MFC 메시지 맵에 대해](http://hyacinth.byus.net/moniwiki/wiki.php/C%2B%2B/MFC%20%EB%A9%94%EC%8B%9C%EC%A7%80%20%EB%A7%B5%EC%97%90%20%EB%8C%80%ED%95%B4)

MFC 클래스는 메시지 핸들러 함수가 가상 함수로 정의되어 있지 않다. 동적 바인딩을 하기 위해선 클래스에 4바이트(32비트 윈도우의 경우) 메모리 주소를 저장할 공간이 더 필요하다(동적 바인딩 참조). 그런데 만약 모든 메시지 핸들러 함수가 가상 함수로 되어 있다면 메시지 핸들러가 대략 200여개 있으니 윈도우 클래스마다 대략 800바이트 이상이 더 필요하게 된다.

메시지 맵은 매크로를 이용해 message map entry macro에 등록한 함수만 가상 함수처럼 동적 바인딩을 해준다.

## 6. 가상 함수 테이블

### 가상 함수 테이블(Virtual Function Table Pointer)

가상 함수의 주소들이 들어가 있다고 생각하면 된다.

![[Untitled]]%E1%84%8B%E1%85%A6%20%E1%84%80%E1%85%AA%E1%86%AB%E1%84%92%E1%85%A1%E1%84%8B%E1%85%A7%2027e25bfe32394dd5ad0e354f880bc571/Untitled%202.png)

이런 식으로 vfptr은 가상함수의 주소를 저장하고, 다른 주소를 이동할 때는, 4바이트씩 움직여서 다른 가상함수에 접속할 수 있다.

vfptr 덕분에 하나의 클래스에서 여러개의 객체가 나왔을 때, 하나의 vfptr을 공유하며, 객체마다 존재하는 vfptr을 통해서 가상함수 테이블에 접속할 수 있다.

→ vfptr은 클래스 마다 하나씩 존재한다.

### 생성되는 시기

컴파일러가 컴파일 시점에 소스 코드에 정의된 모든 클래스에 대해서 가상 함수가 하나라도 있을 경우 vfptr을 만든다.

## 7. 다중 상속에서 가상함수 테이블

다중 상속을 이해하기 위해 간단하게 코드를 짜보았습니다.

다중 상속을 사용할 때, virtual이 어떻게 작동하는 지 디버그를 통해서 알 수 있습니다.

![[Untitled]]%E1%84%8B%E1%85%A6%20%E1%84%80%E1%85%AA%E1%86%AB%E1%84%92%E1%85%A1%E1%84%8B%E1%85%A7%2027e25bfe32394dd5ad0e354f880bc571/Untitled%203.png)

```cpp
class Test
{
public:
	int mode123;

	void Func1() {};
	void Func2() {};
	virtual void vFunc1() {};
	virtual void vFunc2() {};
};

class Ctest : public Test
{
public:
	virtual void vFunc1() {};
	virtual void vFunc2() {};

private:

};

class Btest : public Test
{
public:
	virtual void vFunc1() {};
	virtual void vFunc2() {};

private:

};

class final : public Btest, public Ctest
{
public:
	virtual void vFunc1() {};
	virtual void vFunc2() {};
private:
};
```

![[Untitled]]%E1%84%8B%E1%85%A6%20%E1%84%80%E1%85%AA%E1%86%AB%E1%84%92%E1%85%A1%E1%84%8B%E1%85%A7%2027e25bfe32394dd5ad0e354f880bc571/Untitled%204.png)

![[Untitled]]%E1%84%8B%E1%85%A6%20%E1%84%80%E1%85%AA%E1%86%AB%E1%84%92%E1%85%A1%E1%84%8B%E1%85%A7%2027e25bfe32394dd5ad0e354f880bc571/Untitled%205.png)

다중 상속의 모호성을 virtual을 통해서 해결할 수 있다.

위 코드를 보면  final은 Btest, Ctest를 상속 받는다. Btest와 Ctest는 test 클래스를 상속받는다.