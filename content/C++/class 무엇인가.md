# class 무엇인가

### struct와 class의 차이는?

- struct의 기본 지정 접근자가 public이고, class는 private입니다.
- struct는 변수만을 멤버로 삼을 수 있지만, class는 함수와 변수를 멤버로 삼을 수 있습니다.
- class는 상속이 가능하지만, struct는 상속이 불가능합니다.

### class란

객체 지향 프로그래밍에서 특정 객체를 생성하기 위해 변수와 함수를 정의하는 일종의 틀이다. class를 객체를 생성하기 위한 틀이라고 생각하면 좋습니다.

### class 특징

캡슐화: 클래스가 갖고 있는 멤버의 일부를 감추는 것입니다

상속: 기존의 클래스 멤버를 이어받아 새로운 클래스를 정의하는 것입니다

다형성: 동일한 메시지에 대해 복수의 다른 응답을 하는 것입니다.

### class 기능

### 접근 지정자

class 내부의 메소드, 변수를 접근할 수 있는 범위를 지정할 수 있다. 이 기능으로 불필요한 정보를 제공하지 않을 수 있다.

|  접근 지정자 | 접근 범위 |
| --- | --- |
| public | 접근에 제한이 없음 |
| protected | 동일 패키지와 상속 받은 클래스에서 접근 가능 |
| private | 동일 클래스 내에서만 가능함 |

default 상태는 private 상태입니다.

### 인스턴스(instance)

일종의 타입으로, 클래스 타입의 객체를 선언할 때 생성되는 객체를 의미한다.

인스턴스는 여러 개 생성할 수 있다. 각 인스턴스는 독립된 메모리 공간에 저장된 자신만의 멤버 변수를 가지지만, 멤버 함수는 모든 인스턴스가 공유한다.

### 상속(오버로딩, 오버라이딩)

| 구분 | 오버로딩 | 오버라이딩 |
| --- | --- | --- |
| 기능 | 같은 이름의 메소드를 매개변수의 유형과 개수를 다르게 한 것 | 부모 클래스가 가지고 있는 메소드를 하위 클래스에서 재정의 해서 사용하는 것 |
| 메소드 이름 | 동일 | 동일 |
| 매개변수, 타입 | 다름 | 동일 |
| return 타입 | 상관없음 | 동일 |

### class 사용

```cpp
// main
#include "class.h"

int main()
{
    Car car;
    int click;

    while (1)
    {
        cout << "차량의 상태: " << car.SetState() << endl;
        cout << "차량의 핸들 상태: " << car.SetHandle() << endl;
        cout << "크략션을 몇 번 눌렀는가: " << car.SetKraction() << "\n" << endl;

        cout << "1) 멈추기 " << endl;
        cout << "2) 이동 " << endl;
        cout << "3) 왼쪽으로 핸들 꺽기" << endl;
        cout << "4) 오른쪽으로 핸들 꺽기" << endl;
        cout << "5) 크략션 울리기 " << endl;
        cout << "6) 종료\n" << endl;

        cin >> click;

        switch (click)
        {
            case 1: {
                car.Stop();
                break;
            }
            case 2: {
                car.Move();
                break;
            }
            case 3:{
                car.Left();
                break;
            }
            case 4: {
                car.Right();
                break;
            }
            case 5: {
                car.UseKraction();
                break;
            }
            case 6: {
                return 0;
                break;
            }
            default: {
                return 0;
                break;
            }
        }
    }
    return 0;
}
```

```cpp
// class.h
#include <Windows.h>
#include <iostream>

using std::string;
using std::cout;
using std::cin;
using std::endl;

class Car {
   public:
       Car() {
           this->state = "멈춤";
           this->handle = "직선";
           this->kraction = 0;
       }
       void Move() {
           this->state = "이동";
       }
       void Stop() {
           this->state = "멈춤";
       }
       void Left() {
           this->handle = "왼쪽";
       }
       void Right() {
           this->handle = "오른쪽";
       }
       void UseKraction() {
           OutputDebugString(L"빵빵\n");
           this->kraction++;
       }
       string SetState() {
           return this->state;
       }
       string SetHandle() {
           return this->handle;
       }
       int SetKraction() {
           return this->kraction;
       }
   private:
       string state;
       string handle;
       int kraction;
};
```