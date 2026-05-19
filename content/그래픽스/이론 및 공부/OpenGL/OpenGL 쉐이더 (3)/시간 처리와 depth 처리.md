# 시간 처리와 depth 처리

# 부드러운 애니메이션

시간 간격을 일정하게 가져야 한다.

이상적인 경우 : 동일한 시간 간격 → 동일한 애니메이션

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(3)/시간%20처리와%20depth%20처리/Untitled.png)

실패하는 경우 : 다른 시간 간격

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(3)/시간%20처리와%20depth%20처리/Untitled%201.png)

해결책

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(3)/시간%20처리와%20depth%20처리/Untitled%202.png)

# GLFW 시간 처리

### double glfwGetTime(void)

- GLFW의 시간을 반환한다.
- 실행 초기에 0.0초로 reset
- 단위는 “초” (second)

### void glfwSetTime(double time)

- GLFW 내부 timer를 주어진 시간 time으로 set
- 단위는 “초” (second)

GLFW 내부 timer의 정밀도는 시스템에 달려있다.

시스템하고는 무관하다.

# C++ 시간 처리

C++ Chrono 크로노

시스템하고 무관하게 c++에서 시간을 측정할 수 있다.

### wall-clock time : 시간 측정의 기본

- elapsed real time
- 컴퓨터 프로그램이 실행되면서 실제로 흘러간 시간

# 렌더링 순서 문제

랜더링 할때, 순서가 중요하다.

나중에 그렸던 먼저 그렸던 부분을 지우고, 자기 색깔로 색칠한다.

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(3)/시간%20처리와%20depth%20처리/Untitled%203.png)

## 랜더링 순서와 무관한 출력

랜더링 순서와 무관하게

- object 마다 고유한 우선 순위를 주면?

### overlay in cell animation

- 고전적인 만화영화 제작에 사용

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(3)/시간%20처리와%20depth%20처리/Untitled%204.png)

위 결과가 아래처럼 나온

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(3)/시간%20처리와%20depth%20처리/Untitled%205.png)

# depth processing

- 카메라에서의 거리 →  멀어질수록 값이 커짐
- 문제점 왼손 좌표계

OpenGL canonical view volume 정규 뷰 볼륨

- x,y,z : [-1, +1] X [-1, +1] X [-1, +1]

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(3)/시간%20처리와%20depth%20처리/Untitled%206.png)

## Hidden Surface Removal

### depth value 기준

- 뒤쪽에 있는 object는 앞쪽 물체에 가려져야 함
- 앞쪽 물체는 모두 다 보여야 함

### painter’s algorithm (예전에 사용했다)

- depth 기준으로 sorting
- 뒤쪽 object 부터, 앞쪽 object 순서로 그린다.

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(3)/시간%20처리와%20depth%20처리/Untitled%207.png)

## z-buffer method

- 현재 가장 널리 쓰이는 방법
- 픽셀 단위 하드웨어 구현 : (color 값 RGBA + depth 값 Z)
    - 초기화 : current depth = + 1.0
    - object를 그릴 때 마다, pixel 마다,  depth test
        - 새로운 object가 더 가까우면, 새로운 object로 update
        - 아니면, 현 상태 유지

![[/zbuffer.png]]

장점

- object를 정렬할 필요 없음
- 하드웨어 구현으로 매우 빠름

단점

- framebuffer 크기 정도의 추가 메모리 필요
    - framebuffer  : 픽셀당 4 바이트 (R,G,B,A)
- z-buffer : 픽셀당 24bit or 32bit

# OpenGL Z-buffer 설정

### Tangled Rectangles(얽힌 사각형)

depth order sort는 해결할 수 없다.

|  | Framebuffer 설계 |  | Z-buffer 설계 |
| --- | --- | --- | --- |
| 구성 | R,G,B,A 당 8 bit씩 |  |  |
| View Volume x,y 좌표 | -1.0 ~ + 1.0 | View Volume z 좌표 | -1.0 ~ + 1.0 |
| 색상 저장 R,G,B,A | 0.0 ~ 1.0 | windows 좌표 | 0.0 ~ 1.0 |
| 실제 저장 | 0 ~ 255 integer 값 |  | 0 ~ (224 – 1) integer 값 |
|  |  |  |  |

Z-buffer 하드웨어 설계

## OpenGL functions

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(3)/시간%20처리와%20depth%20처리/Untitled%208.png)

[OpenGL Projection Matrix](https://www.songho.ca/opengl/gl_projectionmatrix.html)

계산법

# 시간에 따라 변하는 fragment