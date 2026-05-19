# 좌표 시스템 - 학교 자료 기준 + learn opengl

coordinate system(좌표계)

- 물체들은 자신만의 좌표계를 가지고 있다.
- 한 씬에 여러개의 물체를 사용할 수 있다.

OpenGL은 vertext shader 실행 된 후, 각 vertex의 x, y, z 좌표가 -1.0 ~ 1.0 범위 안에 있어야 합니다. 이 범위 밖의 좌표는 보이지 않게 됩니다.

## NDC

**정규화된 장치 좌표**

사람은 모니터 화면을 통해서 컴퓨터 화면을 봅니다. 보는 화면은 2d인 2차원입니다. 투영 변환을 통해서 보는 화면, view plane 이라는 화면이 있습니다. 3D 물체가 투영 변환을 통해 2D 공간에 변환 되면서 가지는 좌표계를 NDC라고 합니다.

좌표 변환 파이프라인

- Local Space
- World space
- view space(혹은 eye)
- Clip space
- *normalized device coordinates(ndc)*
- windows space

## **Local Space**

모델을 정의하는 공간이다.

예를 들어 구를 만들 땐 구의 중심의 좌표를 (0,0,0)으로 설정하고, 반지름을 간단하게 (예를 들어, 1) 설정한다. 이 설정한 공간을 local space라고 한다.

## World space

오브젝트들이 배치되는 공간

모델을 world space에 가져와서, 어딘가에 위치할 것입니다. 월드 좌표는 말 그대로 객체들이 위치에 있는 정점 좌표입니다.

개체의 좌표는 local space에서 world space로 변환합니다.

### model matrix

`model matrix` (모델 행렬)는 객체의 위치와 방향을 world space에 위치하기 위해서, 객체를 변환(크기, 회전) 행렬입니다.

## view space

- Opengl의 카메라라고 부릅니다.
- World space 공간을 사용자 view 앞에 있는 좌표로 변환 → 카메라 시점
- 카메라 시점으로 바꿀 수 있게 변환 조합을 사용했습니다. (view matrix를 사용)

## Clip space

view space 밖에 있는 부분을 잘라 줍니다.

보이는 좌표는 -1.0 ~ 1.0 범위 내로 지정하는 것은 직관적이지 않습니다.

자체 좌표 세트를 지정 → NDC 변환

### 절두체

projection matrix가 생성하는 view place를 **절두체**라고 합니다.

> NDC → 절두체 → 2d view space 좌표
> 

위 프로세스를 ‘**투영**’이라고 합니다.

### **Orthographic projection**

orthographic projection 행렬은 정육면체와 같은 절도체 상자를 정의합니다.

![Untitled](attachments/Untitled_17.png)

이 네모난 상자 밖에 있는 vertex들을 짜르는 clipping 공간을 정의합니다.

### **Perspective projection**

![Untitled](attachments/Untitled%201.png)

원근감을 불러일으키기 위해 사용되는 효과이다.

### **projection matrix의 계산식**

[OpenGL Projection Matrix](http://www.songho.ca/opengl/gl_projectionmatrix.html)

## *normalized device coordinates(ndc)*

![[/Untitled.png]]

x, y, z 값이 모두 -1.0 ~ 1.0 사이에 있는 공간입니다. 이 영역 밖에 있는 vertex들은 모두 지워져서, 화면에 보이지 않습니다.

## windows space

앞의 ndc로 부터, 보이게 됩니다.

모니터 화면에 표시되는 부분이다.