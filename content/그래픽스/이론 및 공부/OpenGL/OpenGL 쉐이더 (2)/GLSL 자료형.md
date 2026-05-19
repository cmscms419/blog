# GLSL 자료형

### **벡터 행렬에 대한 자료형을 가지고 있다.**

- **2/3/4 차원 벡터**
- **2/3/4 차원 행렬**
- **샘플러 sampler**
- 연산 vec3 = vec4 * mat4

### 자료형

- c type

int, uint, float, double, bool

- vectors

float vec2, vec3, vec4

- matrices

float mat2 mat3 mat4

주의 : column major을 먼저 저장한다.

- c++ style 생성자

**vec3 a = vec3(1.0,2.0,3.0)**

### vector = Register in GPU

a register = 4 x float

- 1,2,3,4의 float를 사용한다.
- member 접근은 C-style selection 연산 “**.**”

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(2)/GLSL%20자료형/Untitled.png)

### vector의 다양한 해석

- vec4 a = vec4(0.1, 0.2, 0.3, 1.0);
- vec4 b = vec4(a[0], a[1], a[2], a[3]); → array element 4개
- vec4 b = vec4(a.x, a.y, a.z, a.w); → 좌표 (x, y, z, w)
- vec4 b = vec4(a.s, a.t, a.p, a.q); → 텍스처 texture 좌표 (s, t, p, q)
- vec4 b = vec4(a.r, a.g, a.b, a.a); → RGBA 색상 (r, g, b, a)

### 스위즐링 연산

register-level 병렬 처리

register member들의 효과적 선택/분리

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(2)/GLSL%20자료형/Untitled%201.png)

## Matrix

- 행렬식에는 float 형만 있음  (주의 : column major을 먼저 저장한다. Fortran 저장 방식에서 유래)
- 행렬은 vector의 집합

### Registers in GPU

**행렬 관리**

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(2)/GLSL%20자료형/Untitled%202.png)

**mat4 → 4*4 matrix → 4개의 register를 사용한다.**

**mat3 → 3*3 matrix → 3개의 register를 사용한다.**

### Matrix-Vector 곱

GLSL에서는 행렬은 열 우선 계산이다.

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(2)/GLSL%20자료형/Untitled%203.png)