# stay & Layer

![Untitled](attachments/Untitled_17.png)

### Stage

표시되는 모든 영역과 엔진 전역에 정보에 대한 접근을 관리합니다.
Display_context에 접근합니다.

### Layer

캔바스 정보의 명시적 사용을 위해 Scene list를 가지고 있습니다.
연결된 Scene list를 가지고 있습니다.

### Scene

캔버스에서 랜더링 하는데 사용되는 유클리드 공간의 객체들을 관리합니다.
Surface, stencil background_texture, sprirte에 대한 정보가 들어 있습니다.

### Sprite(DisplayObject)

유클리드 공간을 구성하는 표시 객체의 기본 정보를 관리합니다.
표시 화면의 충돌 여부를 확인 할 수 있습니다.
clip_bounds_, stencil_ 를 통해서 랜더링 영역과 표시할 지 말지를 결정할 수 있습니다.