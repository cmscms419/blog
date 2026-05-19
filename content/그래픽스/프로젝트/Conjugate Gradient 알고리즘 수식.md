# Conjugate Gradient 알고리즘 수식

초기화 단계

1. r 계산

초기 잔차 벡터 $r$는 다음과 같이 계산됩니다:

$$
r = b - A \cdot x
$$

초기 $x$는 일반적으로 0 벡터로 초기화되므로:

$$
r = b - A \cdot 0 = b
$$

따라서, $r[0]$는:

$$
r[0] = b[0]
$$

2. P와 P_Inv 계산

$P$는 사전 조건자(preconditioner) 행렬이고, $P\_Inv$는 그 역수입니다. $A$가 대각 행렬이라고 가정하면:

$$
P = \begin{pmatrix} a_{00} & 0 & 0 \\ 0 & a_{11} & 0 \\ 0 & 0 & a_{22} \end{pmatrix}
$$

따라서, $P\_Inv$는:

$$
P_{\text{Inv}} = \begin{pmatrix} \frac{1}{a_{00}} & 0 & 0 \\ 0 & \frac{1}{a_{11}} & 0 \\ 0 & 0 & \frac{1}{a_{22}} \end{pmatrix}
$$

3. c 계산

초기 방향 벡터 $c$는 다음과 같이 계산됩니다:

$$
c = P_{\text{Inv}} \cdot r
$$

따라서, $c[0]$는:

$$
c[0] = \frac{1}{a_{00}} \cdot r[0] = \frac{1}{a_{00}} \cdot b[0]
$$

4. delta_new 계산

초기 $\delta\_{\text{new}}$는 다음과 같이 계산됩니다:

$$
\delta_{\text{new}} = r^T \cdot c
$$

따라서, $\delta\_{\text{new}}$는:

$$
\delta_{\text{new}} = \sum_{i} r[i] \cdot c[i]
$$

첫 번째 반복(iteration)

5. q 계산

$q$는 다음과 같이 계산됩니다:

$$
q = A \cdot c
$$

따라서, $q[0]$는:

$$
q[0] = a_{00} \cdot c[0] = a_{00} \cdot \left(\frac{1}{a_{00}} \cdot b[0]\right) = b[0]
$$

6. alpha 계산

$\alpha$는 다음과 같이 계산됩니다:

$$
\alpha = \frac{\delta_{\text{new}}}{c^T \cdot q}
$$

따라서, $\alpha$는:

$$
\alpha = \frac{\delta_{\text{new}}}{\sum_{i} c[i] \cdot q[i]}
$$

7. x 업데이트

해 벡터 $x$는 다음과 같이 업데이트됩니다:

$$
x = x + \alpha \cdot c
$$

따라서, $x[0]$는:

$$
x[0] = x[0] + \alpha \cdot c[0]
$$

8. r 업데이트

잔차 벡터 $r$는 다음과 같이 업데이트됩니다:

$$
r = r - \alpha \cdot q
$$

따라서, $r[0]$는:

$$
r[0] = r[0] - \alpha \cdot q[0]
$$

"**Part 4. Computer Animation 챕터19. PBD 소개**"를 시청하다가, 옷 움직이는게 재미었어 보여서 만들어 보았습니다.

결과적으로는 실패이지만, 쉐이더에 대해서 더 깊게 알게 되었습니다.

**기간**: 1월에서 9월까지

변명을 하자면, 일과 병행하다 많이 지체되었습니다.

**수강한 강의:**

Introduction to Computer Graphics with DirectX 11 - (2), (3), (4). 강의 중에서(2),(4)는 수강완료이고, (3)을 아직 다 안들었습니다.

회사가 그래픽 관련된 회사라서, 같이 공부하다가, 다른 사람 따라가느라 (2) -> (4)로 강의를 들었습니다.

**참고한 사이트**:

https://www.cs.cmu.edu/~baraff/papers/sig98.pdf

"Large Steps in Cloth Simulation" 논문

GitHub - jimmyjib/cloth-simulation: Cloth Simulation Visual Studio C++ Project

**GitHub - jimmyjib/cloth-simulation: Cloth Simulation Visual Studio C++ Project**

Cloth Simulation Visual Studio C++ Project. Contribute to jimmyjib/cloth-simulation development by creating an account on GitHub.

github.com

[논문 리딩] 1. Large Steps in Cloth Simulation - David Baraff, Andrew Witkin (2) : 네이버 블로그 (naver.com)

[](https://dthumb-phinf.pstatic.net/?src=%22https://blogthumb.pstatic.net/MjAyMTAxMDhfMjk5/MDAxNjEwMDc0NDc0NjE1.5Lbe_OC6HeQ25Xw8fcFnZredCWvjBwAuA0D_RD359qog.9_ETYOWrOYXwIF8zHBwH_2F9DFi_AZ4ITVzkQBU8s0gg.PNG.ab4295/image.png?type=w2%22&type=ff120)

이미지 썸네일 삭제

**[논문 리딩] 1. Large Steps in Cloth Simulation - David Baraff, Andrew Witkin (2)**

자 이번엔 본격적으로 Implicit Integration을 알아보도록 하겠습니다. 애니메이션의 기본은 결국 그림을...

blog.naver.com

GitHub - MeghaS94/Cloth-simulator: An implementation based on the 1998 SIGGRAPH paper "Large steps in cloth simulation" by Baraff and Witkin

[](https://dthumb-phinf.pstatic.net/?src=%22https://opengraph.githubassets.com/12c1146abb72d85b5e5badede4cb632e4fd2d04650997836c6d08b4a49dc9e05/MeghaS94/Cloth-simulator%22&type=ff500_300)

이미지 썸네일 삭제

**GitHub - MeghaS94/Cloth-simulator: An implementation based on the 1998 SIGGRAPH paper "Large steps in cloth simulation" by Baraff and Witkin**

An implementation based on the 1998 SIGGRAPH paper "Large steps in cloth simulation" by Baraff and Witkin - MeghaS94/Cloth-simulator

github.com

위 사이트를 참고해서, 많은 도움을 얻었습니다.

**자료:**

**영상**

**https://www.youtube.com/watch?v=OkSBsfFEP0Q**

영상에서 보면, 약간 스프링 같이 튀어서, 뭔가 계산이 잘못됐는데, 여기서 ks나 kd 값을 수정하면 부들부들 떨리는 문제가 발생해서 이상하게 보입니다. 그리고 입자의 개수가 3x3 이상이 되면, 렉이 걸리는지 렌더링이 멈추게 됩니다.

계산과정을 설명하자면, 4가지 컴퓨터 쉐이더를 사용하고 있습니다.

- **getNeighbouringTriangles.hlsl : 한 입자가 인접하고 삼각형을 이루는 입자의 index 집합과 해당 입자가 이룰 수 있는 삼각형의 최대 개수**
- **stretchshearForce.hlsl : stretch과 shear의 힘 계산을 하고 있습니다.**
- **implicit.hlsl : 암시적 계산에 사용되는 변수들을 계산해줍니다.**
- **ConjugateGradient.hlsl : 여기서 속도 변화량을 계산해 줍니다.**

**멈추는 이유**:

이대로 가면 늘어질 것 같고, 공부에 흥미도 계속 떨어지고 강의도 보지 않을 것 같아서 여기서 멈추려고 합니다.

실패를 끝내는 것이 아니라, 다른 공부를 통해서 머리를 조금 식히려고 합니다. 다행히 지금 회사 프로젝트가 거의 끝나는 중이라서, 조금의 여유가 생겼습니다. 이 기회에 다른 공부를 하면서 머리를 식히려고 합니다.
