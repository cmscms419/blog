# GLSL 특징

- pointer가 없다
- vector, matrix가 기본 자료형
- C++ 구조체 사용 가능
    - in, output 사용 가능

Qualifiers 자격 표시

- const, volatile, readonly, writeonly
- highp, mediump, lowp : precision qualifier (float의 정밀도 조정)
    - precision lowp float

register에 대한 qualifier 가능

- shader 별로 input, output에 따라 사용
    - in,out
- old-syntax : register 역할을 그대로 사용
    - attribute, varying, uniform

### Attribute Registers, Varying Registers

### vertex shader

- in : attribute register
- out : varying register
- gl_Position : pre-defined out
    - vertex position을 저장

Primitive Assembly & Rasterization 단계를 통해서 3개의 정점을 가지고, 수만은 픽셀들을 만들어냅니다. → 그 output값은 fragment 값으로 된다.

### varying Registers, output Registers

**fragment shader**

- in : varying register
- out : framebuffer update

### Uniform Registers

- C/C++ 프로그램에서 미리 set 해서 넘김
- 주로 modeling, viewing, projection 행렬 설정 들에 사용한다.

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(2)/GLSL%20특징/Untitled.png)

### Function call passing values

call by value-return

- 변수를 복사해서 가져온다.
- 값을 리턴 할 때, 값을 복사해서 넘겨준다.

in, out, inout 으로 선언할 수 있다.

### 수학 함수

- sin, cos, tan
- log, exp, abs
- vector 계산용 : normalize, reflect, length

병렬 계산

- 거의 모든 함수에서 vec2, vec3, vec4 등의 병렬 처리 가능
- $vec 4 u = sin(vec4(1.0,2.0,3.0,4.0))$
