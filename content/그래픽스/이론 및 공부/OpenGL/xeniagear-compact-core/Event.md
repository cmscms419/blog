# Event

![Untitled](attachments/Untitled_17.png)

### Event

시스템 또는 엔진에서 특정 목적으로 생성된 신호인 이벤트를 관리합니다.
엔진 활성화, 비활성화, 화면 출력, 엔진 갱신 이벤트를 일으킬 수 있습니다.
이벤트 흐름을 중단해야 하는지를 확인할 수 있습니다.
UserEvent와 MouseEvent를 상속합니다.

### UserEvent

확장된 이벤트를 관리합니다.

### mouseEvent

마우스 이벤트의 정보를 가지고 있으며 마우스 이벤트를 관리합니다.

### EventPoster

UserEvent 객체를 엔진의 이벤트 스택에 넣을 수 있습니다.

### EventDispatcher

Event와 EventListener를 관리합니다.
Stage, Layer, Scene이 이 class를 상속 받습니다.
EventDispatcher는 부모 EventDispatcher에 접근할 수 있습니다.
EventListener map을 가지고 있습니다.

### EventListener

전달된 이벤트를 처리하는 함수 객체를 관리합니다.
Operator를 통해서, 이벤트에 대응되는 행동을 처리할 수 있습니다.