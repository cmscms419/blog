# Legacy OpenGL 프로그램

GLSL 변수

- register를 사용

어느 register를 사용할 것인가?

- GLSL 컴파일러가 할당
- 프로그래머가 강제로 할당 가능

## Layout 설정

vertex shader : attribute register index 설정 가능

- layout (location = n) in vec3 vertexPos;

fragment shader : framebuffer output index 설정 가능

- layout (location = n) out vec4 FragColor;

### vertex shader

- in : attribute register
- out : varying register
- gl_Position : pre-defined out
    - vertex position을 저장

### fragment shader

- in : varying registers
- out : framebuffer update