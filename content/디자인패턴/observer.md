# observer

# 정의

여러 객체에 자신이 관찰 중인 객체에 발생하는 모든 이벤트에 대하여 알리는 구독 메커니즘을 정의할 수 있도록 하는 행동 디자인 패턴입니다.

# 왜 만들어 졌나??

이벤트를 알릴 필요가 있는 객체와 알림을 받아야 하는 객체를 자유롭게 추가 또는 삭제하기 위해서 만들어졌습니다.

# observer 패턴 만들기

`subject`: 시간이 지나면 변경될 수 있는 중요한 상태를 가진 객체

- 추가 or 삭제를 할 수 있는 집합 매커니즘을 추가
- 이 `subject` 는 이벤트가 발생할 때마다 연결되어 있는 집합을 참조한 후 그 객체들에게 특정 알림 메서드를 호출합니다.
- 집합에 들어가는 객체는 같은 인터페이스를 구현하고, `subject` 는 오직 그 인터페이스를 통해서만 객체와 통신합니다. (중요)

# 구조

![[/structure-indexed.png]]

1. `subject` 그 자체로 객체를 추가 or 삭제 시킬 수 있어야 합니다.
2. 이벤트가 새로 생기면, 집합에 있는 객체들을 살펴본 뒤, 각 객체의 인터페이스에 선언된 `update` 메소드를 호출합니다.
3. 객체의 인터페이스는 알림 인터페이스를 선언하며 대부분의 경우 단일 `update` 메소드로 구성됩니다. 이 메서드는 `subject`가 업데이트와 함께 이벤트의 세부 정보들을 전달할 수 있도록 하는 여러 매개변수가 있을 수도 있습니다.
4. 인터페이스를 상속받은 객체는 `subject`가 보낸 알림에 대한 응답으로 몇 가지 작업을 수행합니다. 이러한 모든 클래스는 출판사가 구상 클래스들과 결합하지 않도록 같은 인터페이스를 구현해야 합니다.
5. **클라이언트**는 `subject` 및 객체들을 별도로 생성한 후 객체들을 `subject::subscribe(객체)` 등록합니다.

# 왜 observer 패턴을 사용하는 가???

## displayContext, event_dispatcher 관계를 보면 알 수 있습니다.

![Untitled](attachments/Untitled_17.png)

`EventDispatcher`는 `stage, Layer, Scene, DisplayObject`을 상속해줍니다.

Display_context가 `EventDispatcher` 한테 Event 신호를 주면, `display_context` 가 가지고 있는 `Layer` 에 Event를 신호를 모두 보냅니다.

그 중에서 그 신호가 들어가 있는 `Layer` 는 반응하고, 신호를 처리합니다.

## 또다른 예로 ToolObject 관계

![Untitled](attachments/Untitled%201.png)

`subject` 의 요청으로 `toolObject`의 부모를 `Notify()` 를 실행합니다. `begin() 부터 end()` 까지 실행합니다.