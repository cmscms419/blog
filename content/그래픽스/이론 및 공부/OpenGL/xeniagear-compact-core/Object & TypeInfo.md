# Object & TypeInfo

![Untitled](attachments/Untitled_17.png)

### Object

엔진의 interfaces::Context 객체, 로그 메시지, 그리고, 스마트 포인터의 생명
주기 등을 관리합니다.
연결된 display_context에 접근할 수 있습니다.
Intrusive_ptr의 reference count를 조절과 삭제할 수 있습니다.

### TypeInfo

엔진에서 제공하는 RTTI(Real-Time Type Information)를 정의합니다.
Event, toolObject, context가 상속 받습니다.

## 이 두개를 상속받는 객체

### Event

시스템 또는 엔진에서 특정 목적으로 생성된 신호인 이벤트를 관리합니다.

### ToolObject

표시 화면을 구성하기 위해 사용되는 객체들의 연결과 상태를 관리합니다.
자기 위에 부모 ToolObject에 접근할 수 있습니다.
해당 객체의 타입을 통해 hash ID를 알 수 있습니다.

## Typeinfo만 상속하는 객체

### Context

사용자 접근이 제한된 엔진의 전역 정보를 관리합니다.