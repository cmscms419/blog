# state pattern

정의 : **객체의 내부 상태가 바뀜에 따라서 객체의 행동을 바꿀 수 있다. 마치 객체의 클래스가 바뀌는 것과 같은 결과를 얻을 수 있다.**

![Untitled](attachments/Untitled_17.png)

Context 와 State는 집합관계를 나타내는 것이다. (Context안에 State 객체가 있다)

→ Context가 중요하지 않고, State가 어떤 상태인가에 따라서 변화하게 된다.

내부에서 상태에 따라 변화한다.

### 쓰는 이유

if 문이나 switch문으로 조건을 만족하는 문으로 이동해서 원하는 상태로 만들 수 있다. 하지만 이런 방식은 유지보수나 추가적인 기능을 넣기가 어렵다. 코드가 직관적이지 않고, 유지보수하기가 어렵다.

### 장점

1. Context의 State가 바뀌는 것을 분명하게 알 수 있다.
2. 각 상태 클래스를 수정하는 데에서는 닫쳐있고, 새로운 상태 클래스를 추가하는 확장에는 열려 있다.
3. if, switch문 같은 조건문을 없앨 수 있다.

![Untitled](attachments/Untitled%201.png)

## CODE

```cpp
// main.cc

#pragma once

#include "./class.h"

int main() {
  Character *me = new Character();
  
  me->OnState();
  me->OnState();
  me->OnState();
  me->OnState();
  me->OnState();

  int n;
  std::cin >> n;

  return 0;
}
```

```cpp
// class.cc

#include "class.h"

void Character::setState(State* state) { this->state = state; }

int Character::Damege(int damege) {
  this->hp -= damege;
  return this->hp;
}

void Character::Reset() { this->hp = 100; }

void Character::OnState() { this->state->Action(this); }

Character::Character() {
  this->state = new Normal();
  this->hp = 100;
}

void Die::Action(Character* me) {
  cout << this->mental << " 상태입니다. 재시작 해야합니다." << endl;
  me->setState(&me->normal);
}

Die::Die() { this->mental = "죽음"; }

void Faint::Action(Character* me) {
  cout << this->mental << " 2초간 지속됩니다." << endl;
  Sleep(2000);
  me->setState(&me->normal);
}

Faint::Faint() { this->mental = "정신을 잃음"; }

void Attack::Action(Character* me) {
  cout << this->mental << " 당했다." << endl;
  if (me->Damege(50) <= 0) {
    me->setState(&me->die);
  }
}

Attack::Attack() { this->mental = "공격"; }

void Normal::Action(Character* me) {
  cout << this->mental << " 상태입니다." << endl;
  me->Reset();
  me->setState(&me->attack);
}

Normal::Normal() { this->mental = "정상"; }
```

```cpp
// class.h

#pragma once

#ifndef STATE_PATTERN_CLASS_H_
#define STATE_PATTERN_CLASS_H_

#include <Windows.h>
#include <iostream>

using std::cout;
using std::endl;
using std::string;

class State;
class Die;
class Faint;
class Attack;
class Normal;
class Character;

class State {
 public:
  virtual void Action(Character* me) {}

 protected:
  string mental;
};

class Die : public State {
 public:
  virtual void Action(Character* me);
  Die();

 private:
  State state;
};

class Faint : public State {
 public:
  virtual void Action(Character* me);
  Faint();

 private:
  State state;
};

class Attack : public State {
 public:
  virtual void Action(Character* me);
  Attack();

 private:
  State state;
};

class Normal : public State {
 public:
  virtual void Action(Character* me);
  Normal();

 private:
  State state;
};

class Character {
 public:
  void setState(State *state);
  int Damege(int damege);
  void Reset();
  void OnState();
  Character();

  Die die;
  Normal normal;
  Attack attack;
  Faint faint;

 private:
  int hp;
  State *state;
};

#endif  // !STATE_PATTERN_CLASS_H_
```