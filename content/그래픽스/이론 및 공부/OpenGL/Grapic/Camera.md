# Camera

## **View space**

view matrix은 카메라의 위치와 방향에 따라 world 좌표를 view 좌표로 변화시킵니다. 

카메라를 정의하기 위해서는 4가지가 필요합니다.

카메라의 위치, 바라보고 있는 방향, 카메라의 오른쪽을 가리키는 벡터, 카메라의 위쪽을 가리키는 벡터

![Untitled](attachments/Untitled_17.png)

## 카메라 위치

카메라의 위치는 기본적으로 world space의 벡터입니다.

이 벡터는 카메라의 위치를 가리킵니다.

```cpp
glm::vec3 cameraPos = glm::vec3(0.0f, 0.0f, 3.0f);
```

## 카메라 방향

카메라가 scene의 원점(`(0,0,0)`)을 가리키게 합니다

원점 벡터에서 카메라 위치 벡터를 빼면 방향 벡터를 얻을 수 있습니다.

카메라가 바라보는 방향은 z축 음의 방향이다.

뺄셈의 순서를 바꾼다면 우리는 카메라로부터 z 축의 양의 방향을 가리키는 벡터를 얻을 수 있습니다.

```cpp
glm::vec3 cameraTarget = glm::vec3(0.0f, 0.0f, 0.0f);
glm::vec3 cameraDirection = glm::normalize(cameraPos - cameraTarget);
```

## 오른쪽 축

카메라 space에서 x 축의 양의 방향을 나타내는 오른쪽 벡터입니다.

*오른쪽* 벡터를 얻기 위해 먼저 (world space에서) 위쪽을 가리키는 *위쪽*  벡터를 사용합니다. 위쪽 벡터와 카메라 방향 벡터를 외적합니다.

```cpp
glm::vec3 up = glm::vec3(0.0f, 1.0f, 0.0f); 
glm::vec3 cameraRight = glm::normalize(glm::cross(up, cameraDirection));
```

## 위쪽 축

오른쪽 벡터와 카메라 방향 벡터의 외적을 하면 얻을 수 있습니다.

```cpp
glm::vec3 cameraUp = glm::cross(cameraDirection, cameraRight);
```

## Look At

3개의 직각인 축을 사용하여 좌표 space를 만들면, 3개의 축과  이동 벡터와 함께 행렬을 만들 수 있고, 어떠한 벡터든지 이 행렬과 곱하여 좌표 space로 변환할 수 있다.

카메라를 정의하기 위해 사용되는 행렬은 다음과 같습니다:

LookAt=$\begin{bmatrix}
R_x & R_y & R_z & 0 \\
U_x & U_y & U_z & 0 \\
D_x & D_y & D_z & 0 \\
0 & 0 & 0 & 1 \\
\end{bmatrix}$*$\begin{bmatrix}
1 & 0 & 0 & -P_x \\
0 & 1 & 0 & -P_y \\
0 & 0 & 1 & -P_z \\
0 & 0 & 0 & 1 \\
\end{bmatrix}$ 

R은 오른쪽 벡터, U는 위쪽 벡터, D는 방향 벡터, P는 카메라의 위치 벡터입니다.

위치 벡터가 반대로 되어있습니다.

LookAt 행렬을 view 행렬로 사용하여 모든 world 좌표들을 방금 정의한 view space로 변환할 수 있습니다. 그 다음 LookAt 행렬은 정확히 주어진 타겟을 *바라보고(look)* 있는 view 행렬을 생성합니다.

```cpp
glm::mat4 view;
view = glm::lookAt(glm::vec3(0.0f, 0.0f, 3.0f),
									 glm::vec3(0.0f, 0.0f, 0.0f),
									 glm::vec3(0.0f, 1.0f, 0.0f));
```

오일러 각

3D 상에서의 모든 회전을 나타낼 수 있는 3개의 값입니다. *pitch*, *yaw*, *roll*

![Untitled](attachments/Untitled%201.png)

첫번째 이미지 : 위, 아래 (pitch)

두번째 이미지 : 왼쪽 오른쪽 (yaw)

세 번째 이미지 : 바닥이 아래로 할지 위로 바라볼지 정하는 것 (roll)

pitch와  yaw가 주어지면, 회전이 가능합니다.  이 두 값을 사용하기 위해서는 삼각법이 필요합니다.

![Untitled](attachments/Untitled%202.png)

빗변의 길이를 1이면, 삼각법에 의해 

인접한 변의 길이가 cos x/h = cos x/1 = cos x 이고

반대편 변의 길이는 sin y/h=sin y/1=sin y 임을 알 수 있습니다.

각에 의해서 x 방향과 y 방향의 길이를 구할 수 있는 공식을 알 수 있습니다.

벡터의 요소들을 계산하기 위해 이 공식을 쓸 수 있습니다.

![Untitled](attachments/Untitled%203.png)