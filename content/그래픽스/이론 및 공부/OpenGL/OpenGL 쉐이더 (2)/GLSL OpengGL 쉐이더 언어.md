# GLSL: OpengGL 쉐이더 언어

OpenGL 2.0 이상에서는 사용할 수 있다.

### 자료형 도입 + 연산 추가

- 2/3/4차원 벡터 추가
- 2/3/4차원 행렬 추가
- 샘플러 sampler
- 연산 벡터 * 행렬.

## GPU 내부 구조

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(2)/GLSL%20OpengGL%20쉐이더%20언어/Untitled.png)

vertex shader, fragment shader는 Processor나 CPU처럼 작동한다.

데이터를 저장을 register를 가지고 있다.

### Register 이름

**attribute** : primitive의 attribute 속성, 성질

**varying :** 바뀌는 변화하는 값이 변한다.

**uniform** : 일정한 변하지 않음 → global constant

### Register in GPU

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(2)/GLSL%20OpengGL%20쉐이더%20언어/Untitled%201.png)

a register = 4 X float

최대 4개를 사용한다.

# Vertex Shader

사용자가 주는 vertex를 가지고 → new vertex data로 만든다.

이것이 주 업무이다.

## **input vertex(attribute registers)**

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(2)/GLSL%20OpengGL%20쉐이더%20언어/Untitled%202.png)

**uniform registers**

vertex, fragment에서도 사용된다. → 여러곳에서 사용할 수 있다.

**pre-defined output registers는 (미리 register에 지정되는 경우가 있다.)**

포인트 사이즈(점의 크기), vertex position 같은 데이터를 저장한다.

# Primitive Assembly & Rasterization

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(2)/GLSL%20OpengGL%20쉐이더%20언어/Untitled%203.png)

### Primitive Assembly

vertex를 연결해서, primitive를 결합한다.(삼각형을 만들어낸다.)

### Rasterization

연결된 도형의 내부에 픽셀을 만든다.

위 두 부분은 fixed hardware로 되어 있어서 건드릴 수 없다.

위 단계를 거치면, 많은 fragments가 생긴다.

fixed hardware는 여러 일 중 하나를 수행한다.

## Processing Varying Variables

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(2)/GLSL%20OpengGL%20쉐이더%20언어/Untitled%204.png)

각각 색깔의 비례에 해당하는 색깔을 지정해준다.

## Fragment Shader

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(2)/GLSL%20OpengGL%20쉐이더%20언어/Untitled%205.png)

pixel 하나하나 마다 프로그램을 돌려서 결과 만들어 낸다.

입력이 되는 것이 varying registers라고 한다. 하지만 vertex의 varying registers하고는 다르다.

vertex의 output은 바로 받는 것이 아니라, Primitive Assembly와 Rasterization 단계를 거치고 난 이후에 오는 여러 개의 픽셀값을 받게 된다.

그 값을 shader가 받아서 마지막에 프레임 버퍼에 출력하면 나오게 된다.

uniform, sample 존재

**pre-defined output registers가 존재한다.**

픽셀의 좌표 값, 포인트 코디네이트(점의 좌표값) 같은 것이 있다.