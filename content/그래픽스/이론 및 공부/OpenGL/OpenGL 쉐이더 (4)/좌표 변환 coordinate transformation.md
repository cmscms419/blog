# 좌표 변환 coordinate transformation

# 2D transformation

### transformation(transform)

- **mapping function** : point/vector → another point/vector

### **Affine transformation**

- Affine transformation을 linear functions(1차 함수)라고 한다.
- homogeneous coordinate representation 가능
- 물리 시뮬레이션의 기초

## **Affine transformation**

### line preserving property(직선을 유지 시켜주는 성질)

- 변환 전 : 선분 → 변환 후 : 선분
    - 선분 / 다각형으로 구성된 모든 물체에 적용 가능하다.

선분 전체의 변환

1. 선분의 꼭지점만 변환
2. 꼭지점을 다시 연결하면
3. 선분 전체가 변환된 것과 동일하다

→ 꼭지점만 집중하면 된다.

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(4)/좌표%20변환%20coordinate%20transformation/Untitled.png)

### 물리 시뮬레이션의 기초 연산

**rigid body (강체)**

- (물리학 용어) 형태가 고정된 물체
-

    ![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(4)/좌표%20변환%20coordinate%20transformation/Untitled%201.png)


**rigid-body transformation**

**non-rigid-body transformation**

- rotation
- translation

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(4)/좌표%20변환%20coordinate%20transformation/Untitled%202.png)

- 물체의 크기/모양 변화 있음
- scaling
- shear

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(4)/좌표%20변환%20coordinate%20transformation/Untitled%203.png)

## 2D Scaling(스케일링)

2D 스케일에는 scaling factors가 사용된다.($S_x, S_y$)

- 모든 점/꼭지점들에 동일한 caling matrix 적용

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(4)/좌표%20변환%20coordinate%20transformation/Untitled%204.png)

## 2D Shearing(쉬어링)

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(4)/좌표%20변환%20coordinate%20transformation/Untitled%205.png)

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(4)/좌표%20변환%20coordinate%20transformation/Untitled%206.png)

- non-rigid body transformation
    - image processing 분야에서 자주 사용
    - 그래픽스 분야에서는 **중요도가 낮음**

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(4)/좌표%20변환%20coordinate%20transformation/Untitled%207.png)

## 2D Rotation(회전)

2차원 좌표 기준

- 원점을 기준으로 각도 θ 회전
- 반지름 $r$

    ![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(4)/좌표%20변환%20coordinate%20transformation/Untitled%208.png)

- 기준 방향은 CCW = counter-clockwise(반시계방향)
- 반대 방향 : 각도 θ, CW (시계 방향) rotation
    - 각도 -θ, CCW 반시계 방향 rotation = 각도 2π - θ, CCW 반시계 방향 rotation

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(4)/좌표%20변환%20coordinate%20transformation/Untitled%209.png)

## 2D Translation(평행이동)

- 회전과 스케일링과 달리, 벡터끼리의 덧셈같이 변환으로 표현된다.

→ $(x', y') = (x, y) + (d_x ,d_y ) = (x + d_x , y + d_y )$

- 3D homogeneous coordinate를 도입하면,
    - 2D translation = 2D vector addition → 3D matrix multiplication

## 3D homogeneous coordinates

3D에서의 point = 4D homogeneous 좌표계에서는 point이다.

- $(x, y, z) → (x, y, z, 1) = (wx, wy, wz, w)$, with non-zero w's

2D에서의 point = 3D homogeneous 좌표계에서는 point이다.

- $(x, y) → (x, y, 1) = (wx, wy, w)$, with non-zero w's

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(4)/좌표%20변환%20coordinate%20transformation/Untitled%2010.png)

### 2D 아핀 변환 = 3D 행렬 곱

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(4)/좌표%20변환%20coordinate%20transformation/Untitled%2011.png)

more 2D transformation

orbit 프로그램

3D transformation

3D scaling 프로그램

Euler Angles

3D transform composition

rotating the pyramid

rotating with GLM
