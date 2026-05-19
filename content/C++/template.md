# template

# 1. 정의

## 메타 언어(meta language)

언어를 기술하는 언어

## 메타 언어를 왜 설명하는 가

C++의 **template**은 메타 클래스로, 이것을 설명하기 위해서는 어디서 유래되었는지 알 필요가 있다.

→ 메타 클래스 : 클래스를 기술하기 위한 클래스

명시적 인스턴스화는 **템플릿의 선언과 정의를 같은 파일에 작성한다.**

## 종류

- 일반화된 클래스(generic class)
- 파라미터를 받는 클래스(parameterized class)
- 템플릿 클래스(template class)

## 명시적 지정(explicit specification)

**인스턴스화를 개발자가 코드 생성 시점을 결정하는 방식이다.**

→ 효율적인 코드 컴파일과 링크 시간을 얻을 수 있다.

```cpp
// Stack.h

#ifndef STACK_H
#define STACK_H

template <typename T>
class Stack {
 private:
  std::vector<T> mStack;

 public:
  void Push(T val);
  T Pop();
  bool IsEmpty() const;
};

// 어떠한 타입들이 명시적으로 인스턴스화되는지 알려주기 위한 타입데프들
typedef Stack<short> ShortStack;
typedef Stack<int> IntStack;
typedef Stack<float> FloatStack;
typedef Stack<double> DoubleStack;

#endif
```

```cpp
// Stack.cpp
 
#include "stack.h"
 
template <typename T>
void Stack<T>::Push(T val)
{
    mStack.push_back(val);
}
 
template <typename T>
T Stack<T>::Pop()
{
    if (IsEmpty())
        return T();
 
    T val = mStack.back();
    mStack.pop_back();
    return val;
}
 
template <typename T>
bool Stack<T>::IsEmpty() const
{
    return mStack.empty();
}
 
// 명시적 템플릿 인스턴스화 선언
template class Stack<short>;
template class Stack <int>;
template class Stack<float>;
template class Stack<double>;
```

```cpp
// main.cc
int main() {
  Stack<int> a;
  Stack<char> b;

  a.Push(2);
  b.Push('2');

  return 0;
}
```

![Untitled](attachments/Untitled_17.png)

이 템플릿 클래스는 short, int, float, double 타입에 대해 명시적으로 인스턴스화된다. char가 인스턴스화되는 이유는 이 템플릿이 모호하지 않은 템플릿으로 컴파일러에서 자동으로 인스턴스화해 주기 때문이다.

# 2. template class

간단하게 말하면, 템플릿 개념이 클래스에 적용되는 의미이다. 

```cpp
template <class T>
class cStack {
 public:
  cStack(int n) {
    data = new T[size = s];
    sp = 0;
  }
  ~cStack() { delete[] data; }
  void Push(T d);
  T Pop();

 private:
  T *data;
  int size, sp;
};

template <class T>
void cStack<T>::Push(T d) {
  data[sp] = d;
  ++sp;
}

template <class T>
T cStack<T>::Pop() {
  --sp;
  return data[sp];
}
```

```cpp
int main() {
  cStack<char> s(10);
  cStack<int> t(10);
  
  s.Push('A');
  s.Push('a');
  t.Push(100);
  t.Push(1);
  
  printf("%c\n", s.Pop());
  printf("%c\n", t.Pop());

  return 0;
}
```

위 코드처럼 클래스를 템플릿으로 만들면, 여러 방식으로 응용할 수 있습니다.

# 3. template function

여러 다른 자료형에 대하여 같은 역할을 하는 하나의 함수 계열을 하나의 템플릿으로 표현할 수 있다.

```cpp
template <typename Type>
Type max(Type a, Type b) {
    return a > b ? a : b;
}
```

```cpp
int main()
{
  // This will call max <int> (by argument deduction)
  std::cout << max(3, 7) << std::endl;
  // This will call max<double> (by argument deduction)
  std::cout << max(3.0, 7.0) << std::endl;
  return 0;
}
```

```cpp
// 출력결과
7
7
```

컴파일러는 들어오는 자료 형태를 각각 int와 double로 추론한다.

하지만

```cpp
std::cout << max<double>(3, 7.0) << std::endl;
```

이런 형태는 실패한다. 왜냐하면 인자로 넘어오는 두 가지 자료형이 정확하게 같아야 한다고 정의되어 있기 때문이다.

# 4. stl 조사

## STL(Standard Template Library)

C++ 표준 라이브러리의 하나로, 컨테이너, 알고리즘, 반복자 등을 포함하는 템플릿 기반 라이브러리입니다. STL은 프로그래머가 개발하기 쉬운, 재사용 가능하고 효율적인 코드를 작성할 수 있도록 돕는 기능을 제공한다.

## STL의 역사

1994년 휴렛 패커드에 근무한 P. J. Plauger가 설계한 템플릿 라이브러리이다. 그는 템플릿을 이용하여 몇 가지 자료구조와 알고리즘을 설계하여, 소스를 공개했다. 1997년 C++ 표준을 정할 때, C++의 표준 라이브러리에 추가되었다.

## STL

이것은 복잡하게 설계된 템플릿 덩어리(mass of template)이다. STL에서 사용하는 중요한 4가지 개념이 있다.

- 컨테이너(container)
- 이터레이터(iterator)
- 알고리즘(algorithm)
- 펑터(functor)

### 컨테이너

- 같은 데이터 타입의 변수는 객체를 여러 개 가질 수 있는 클래스를 말한다.
- 이것은 클래스로 구현되며, 클래스의 객체를 선언하여 사용한다.

### 이터레이터

컨테이너 클래스의 모든 데이터를 접근하는 연산자이다.

### 알고리즘

- STL에서 클래스를 제외한 일반 함수들을 말한다.

### 펑터

- 단순하게 말하면, 함수 객체(function object)

```cpp
#include <stdio.h>

struct IntGreater {
  bool operator()(int first, int second) const { return first > second; }
};

void Test(IntGreater ig) {
  if (ig(3, 2)) printf("3 is greater than 2 \n");
}

void main() { Test(IntGreater()); }
```

- 임시 개체를 만들어서, 내부에 있는 operator()()를 호출해서 사용한다.

# 5. CODE

```cpp
// template.h

#pragma once
#ifndef TEMPLATE_TEMPLATE_H_
#define TEMPLATE_TEMPLATE_H_

#include <iostream>
#include <vector>
#include <list>
#include <map>

using std::string;
using std::endl;
using std::cout;

template <class T>
class Tclass {
 public:
  Tclass(int s) {
    data = new T[size = s];
    sp = 0;
  }
  ~Tclass() { delete[] data; }
  void Push(T d);
  T Pop();

 private:
  T *data;
  int size, sp;
};

template <class T>
void Tclass<T>::Push(T d) {
  data[sp] = d;
  ++sp;
}

template <class T>
T Tclass<T>::Pop() {
  --sp;
  return data[sp];
}

template <typename Type>
Type max(Type a, Type b) {
  return a > b ? a : b;
}

#endif  // !TEMPLATE_TEMPLATE_H_
```

```cpp
// main.cc

#include "./template.h"

int main() {
  // template class
  std::cout << "Template Class" << std::endl;
  Tclass<char> s(10);
  Tclass<int> t(10);

  s.Push('A');
  s.Push('a');
  t.Push(100);
  t.Push(1);

  printf("%c\n", s.Pop());
  printf("%c\n", t.Pop());

  // template function
  std::cout << max(3, 7) << std::endl;
  std::cout << max(3.0, 7.0) << std::endl;
  std::cout << "" << std::endl;

  // Vector
  std::cout << "Vector" << std::endl;
  std::vector<int> vec;

  vec.push_back(10);
  vec.push_back(20);
  vec.push_back(30);
  vec.push_back(40);

  for (std::vector<int>::size_type i = 0; i < vec.size(); i++) {
    std::cout << "vec 의 " << i + 1 << " 번째 원소 :: " << vec[i] << std::endl;
  }

  std::vector<int>::iterator vecitr = vec.begin() + 2;
  std::cout << "3 번째 원소 :: " << *vecitr << std::endl;

  // List
  std::list<int> lst;

  // List add
  lst.push_back(1);
  lst.push_back(2);
  lst.push_back(11);
  lst.push_back(22);

  std::cout << "" << std::endl;
  std::cout << "List" << std::endl;
  std::cout << lst.size() << std::endl;
  std::cout << lst.empty() << std::endl;
  std::cout << lst.front() << std::endl;
  std::cout << lst.back() << std::endl;
  std::cout << "" << std::endl;

  // 반복자 생성
  std::list<int>::iterator lstitr = lst.begin();
  for (lstitr = lst.begin(); lstitr != lst.end(); lstitr++) {
    std::cout << *lstitr << std::endl;
  }
  std::cout << "" << std::endl;

  // Map
  std::cout << "Map" << std::endl;
  std::map<string, int> m;

  m.insert({"A", 100});
  m.insert({"B", 123});
  m.insert({"C", 456});

  if (m.find("B") != m.end()) {
    cout << "find" << endl;
  }

  std::map<string, int>::iterator mitr;

  for (mitr = m.begin(); mitr != m.end(); mitr++) {
    cout << mitr->first << " " << mitr->second << endl;
  }

  return 0;
}
```

```cpp
// 출력 결과
Template Class
a
r
7
7

Vector
vec 의 1 번째 원소 :: 10
vec 의 2 번째 원소 :: 20
vec 의 3 번째 원소 :: 30
vec 의 4 번째 원소 :: 40
3 번째 원소 :: 30

List
4
0
1
22

1
2
11
22

Map
find
A 100
B 123
C 456
```