# surface

![Untitled](attachments/Untitled_17.png)

### Core: surface

엔진에서 사용하는 서페이스 관리 방식과 시스템에서 지원하는 서페이스 관리 방식을 연결합니다.

### GLESsurface

랜더링 결과가 기록되는 공간
surface_identifier_는 생성한 framebuffer 객체
texture_identifier_는 texture로 framebuffer로 연결
stencil_identifier_은 renderbuffer로 framebuffer로 연결

GLES 라이브러리를 통해 렌더링 결과가 저장될 서페이스를 관리합니다.

### GLESTextSurface

Text 랜더링 결과를 기록되는 공간입니다.
Textrenderer에서 따로 랜더링 합니다.
GLESsurface를 상속 받습니다.