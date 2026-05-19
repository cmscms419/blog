# Display & adapter

![Untitled](attachments/Untitled_17.png)

### Display

Display는 엔진을 직접 사용하지 않습니다.
엔진의 생명 주기를 관리합니다.
Builder 패턴을 이용해서 display 객체를 생성합니다.
이렇게 만든 객체를 이용해서, display_context를 초기화 합니다.

### Display_context

엔진을 접근하는 객체입니다.
Adapter를 사용해서, 앱과 엔진을 연동합니다.
Stage,layer 같이 랜더링에 관여하는 객체를 가지고 있습니다.
Adapter와 통신하면서, 필요한 정보를 얻을 수 있습니다.

### Adapter

엔진과 시스템 사이를 연결해주는 역할을 해줍니다.
Bridge에 대한 클래스도 들어있어서,
Bridge를 통해서 필요한 정보를 제공할 수 있습니다.
Windows와 EGL에 접근할 수 있습니다.
Windows에 접근해서 다시 draw()함수를 호출합니다.
EGL은 swap함수를 사용해서, 랜더링 결과가 화면에 보일 수 있게 해줍니다.