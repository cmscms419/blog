---
title: "[논문 리뷰] 3D Gaussian Splatting (SIGGRAPH 2023) : 랜더링 속도/퀄리티 개선"
source: "https://xoft.tistory.com/51"
author:
  - "[[xoft]]"
published: 2023-09-25
created: 2025-07-02
description: "3D Gaussian Splatting for Real-Time Radiance Field Rendering, Bernhard Kerbl, SIGGRAPH 2023 NeRF분야에서 뜨거운 이슈가 된 논문입니다. NeRF에서 해결하고자 하는 Task와 동일하게, 여러 이미지와 촬영 pose 값이 주어지면 다양한 시점에서 3D Scene을 랜더링합니다. 고해상도(1920x1080)에서 랜더링 Quality가 SOTA인 Mip-NeRF360 (2022)보다 뛰어나고, Training 시간에서 SOTA인 InstantNGP (2022)보다도 시간을 단축시키게 됩니다. 이 논문이 뜨거운 이슈가 된 이유는 위 장점들에 추가적으로 획기적으로 빠른 Rendering속도(약 100FPS이상)입니다. 위 그림에서 괄호는 .."
tags:
  - "clippings"
---
3D-GS

[3D Gaussian Splatting for Real-Time Radiance Field Rendering, Bernhard Kerbl, SIGGRAPH 2023](https://github.com/graphdeco-inria/gaussian-splatting)

NeRF분야에서 뜨거운 이슈가 된 논문입니다. NeRF에서 해결하고자 하는 Task와 동일하게, 여러 이미지와 촬영 pose 값이 주어지면 다양한 시점에서 3D Scene을 랜더링합니다. 고해상도(1920x1080)에서랜더링 Quality가 SOTA인 Mip-NeRF360 (2022)보다 뛰어나고, Training 시간에서 SOTA인 InstantNGP (2022)보다도 시간을 단축시키게 됩니다.

**이 논문이 뜨거운 이슈가 된 이유는 위 장점들에 추가적으로 획기적으로 빠른 Rendering속도(**약 100FPS이상)** 입니다.**

![](https://blog.kakaocdn.net/dna/lSyyJ/btsuSknZIfV/AAAAAAAAAAAAAAAAAAAAAKlGkGtrtxk5uY6fGDdeKcPoWNVGMdHrsUGEi_-QT-oK/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=jLMfXu9EzicktK2vGOcBqCcEdy8%3D)

위 그림에서 괄호는 랜더링 속도를 의미합니다. 기존 SOTA연구들 대비 얼마나 개선 되었는지를 볼 수 있습니다. NeRF를 이용한 실시간 서비스를 볼 날이 한발 더 가까워졌습니다.(이전에도 200FPS로 랜더링하는 FastNeRF가 있었지만 학습 시간이 느리고, 퀄리티가 낮았었습니다.)

3D Gaussian Splatting 네이밍에 대한 의미를 생각해보자면, 단어 Splat은 물기를 머금은 뭔가가 부딪치는 모습에 대한 의성어로써, 3D Gaussian이 흩뿌려진다라고 생각하면 될 것 같습니다. (그림출처:[link](https://bbbpress.com/2013/11/drama-game-splat/) )

![](https://blog.kakaocdn.net/dna/clEKbH/btsuQxVsvBH/AAAAAAAAAAAAAAAAAAAAAK6dimSlk7aSaORKDdnsQk2v3ZYZ37ie-or04iULnTRL/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=V6ctNvPbs29o3AzqyzMydeSw8s0%3D)

3D Gaussian에 대해선 별도의 글로 정리해두었습니다.[\-> 3D Gaussian 개념 설명](https://xoft.tistory.com/49)

**3D 공간상에 수 많은 3D Gaussian이 모여 하나의 Scene을 구성** 하고 있다라고 생각하면 됩니다.

아래는 제가 별도로 랜더링한 결과입니다. View mode를 Ellipsoids로 지정했을 때의 모습입니다.[3D Gaussian Splatting 코드 빌드](https://xoft.tistory.com/48) 내 결과 동영상에서 확인 할 수 있습니다.

![](https://blog.kakaocdn.net/dna/bHaiJG/btsvHfsq8mQ/AAAAAAAAAAAAAAAAAAAAAEmDIaQ5zQe8UqUVH2WwtFU7BO_SvsGvZpmnyaAhPFbc/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=VAjlaYbWlOUd5Uuau6uxb%2BSbUYU%3D)

### 왜 3D Gaussian이 사용됬을까?

3D 모델을 표현하는 방법 2가지를 소개하자면,

1. 가장 일반적인 방법은 Mesh와 Point입니다. GPU/CUDA기반의 rasterization(=3D를 2D 이미지화)에 최적화 되어 있습니다.
2. 최근 NeRF 기법들에서는 Scene을 Optimization 하기에 좋은 continuous scene으로 표현하고 있습니다. 하지만 랜더링시 stochastic(=확률기반)한 sampling 때문에 연산량이 많고 noise가 형성 될 수 있습니다.

본 논문에서는위 3D 모델표현방법들의장점만을조합해, 3D Gaussian이라는 새로운방법을제시하고있습니다.

- differentiable volumetric representation(=미분가능한 볼륨 표현)을 할 수 있고
- Explicit하게 표현 할 수 있고 (<-> Neural Network는 구조가 감춰져있는 Implicit한 표현법)
- 3D모델의 2D projection과 α-blending(투명도값의 더하기 연산)을 효율적으로 할 수 있어

빠른 Rendering이 가능하였기에, 3D Gaussian으로 채택하였다고 합니다. (참고로 2D Projection과 α-blending은 rasterization을 구성하는 일부 단계에 해당합니다.)

Rendering관점에서 다르게 설명해보겠습니다.

- 기존 NeRF: 1) 이미지 각 pixel마다 ray를 그려서 여러 점을 샘플링하고 2) 샘플링한 각 점의 color와 volume density를 계산하고 3) ray위의 이 값들을 summation 하여 이미지를 Rendering합니다.
- 3D Gaussian Splatting: 1) 이미지를 14x14 pixel로 구성된 Tile들로 나누고 2) Tile마다 Gaussian들을 Depth로 정렬하고 3) 앞에서 부터 뒤로 순차적으로 Alpha blending 하여 이미지를 Rendering 합니다.

개념적으로 Rendering 연산량 관점에서 3D Gaussian Splatting이 훨씬 적은 연산량을 갖고 있습니다.

### Overview

![](https://blog.kakaocdn.net/dna/bLEGl8/btsuG3nARg8/AAAAAAAAAAAAAAAAAAAAAFu3jzEgBbq97l6SpyTwG_nBcHfMGSfWN1fdiy44n5Cd/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=YwFDRCrg%2BbaihxBRVXT%2BR94%2BzUw%3D)

먼저 전체적인 흐름을 보겠습니다. 전체 그림을 파악할 정도로만 보시기 바랍니다.

- Initialization: COLMAP과 같은 SfM알고리즘은 Camera Pose뿐만 아니라 Point Cloud 정보도 같이 얻을 수 있습니다. 이 Point Cloud들이 3D Gaussian의 초기 값으로 사용됩니다.
- Projection: 3D Gaussian이 (Camera에서 z축으로 거리가 1만큼 떨어진) Image Plane으로 Projection되어 2D Gaussian형태가 됩니다. 이 과정은 GT 입력 이미지와 비교하여 parameter를 업데이트하기 위함입니다.
- Differentiable Tile Rasterizer: 미분 가능한형태의 Tile Rasterization을 통해 2D Gaussian들을 하나의 Image로 생성합니다.
- Gradient Flow: 생성된 이미지와 GT 이미지의 Loss를 계산하고 Loss만큼 Gradient를 전파합니다.
- Adaptive Density Control: Gradient를 기반으로 Gaussian의 형태를 변화시킵니다.

이번 논문 리뷰는 수도코드 기반으로 설명하려고 합니다. 딱딱 할 수 있으나, 생소한 개념을 확실히 설명하기에 가장 좋은 방법인 것 같아 채택했습니다. 실제 논문도 글로 된 매뉴얼을 읽는듯한 느낌입니다..

![](https://blog.kakaocdn.net/dna/djrmid/btsvbGcopPE/AAAAAAAAAAAAAAAAAAAAAMajmYek3sqbtmmvP_ydW_IhQCrky5f9pPAydOw4iaJS/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=KBkvzi2ismiEXBIgoVrrIl08QKA%3D)

크게 3 가지로 구분 할 수 있습니다.

- 첫번째 부분(빨간색)은 변수 초기화 부분입니다. 코드 관점에서 간단할 수 있지만, 모델 설계에 해당되므로 중요합니다.
- 두번째 부분(파란색)은 ML분야에서 친숙한 구조이며, 입력을 받아, inference한 후 Loss를 계산하여 update하는 부분입니다.
- 세번째 부분(초록색)은 Gaussian을 직접적으로 다루게 되는데, 특정 iteration마다 Gaussian을 Clone하고 Split하고 Remove하는 부분입니다.

하나씩 세부적으로 살펴보겠습니다.

### Initialization

![](https://blog.kakaocdn.net/dna/dy06Cu/btsuSfnOPkC/AAAAAAAAAAAAAAAAAAAAAHS3N9r3vzmBTi4rB4N4SgajqEYhQ3qQcSCHUwoVD_zk/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=8PniPAT1Pu1b1sNV8zlrDBnJSPM%3D)

M,S,C,A는 학습 Parameter에 해당합니다. 각 값에 대한 의미와 초기값을 설명하겠습니다.

**M** 은 SfM으로 획득한 Point Cloud을 의미합니다. 3D Gaussian은 평균과 공분산으로 구성이 되는데, Point Cloud의 point 점들이 초기 3D Gaussian들의 평균값으로 사용됩니다. -> Point Cloud의 Point 갯수만큼 3D Gaussian이 생성됩니다.

**S** 는 3D Gaussian의 Covariance Matrix로써, 3x3의 행렬입니다. 논문 수식에서는 Scale Matrix S와 Rotation Matrix R로 구성된 Σ로 서술되어 있습니다. (수도코드와 논문에 표시된 아래 수식의 표기 기호가 다릅니다.)

![](https://blog.kakaocdn.net/dna/sZvv7/btsuRHEvtHR/AAAAAAAAAAAAAAAAAAAAAP3X6N__XiXtcoDzI0VPixx1gKpSJQmcrADI9lQ3K-8H/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=feEG1razS18okXfcQOJ%2Bwx7gUJg%3D)

- Scaling 에 관한 vector s 와 Rotation 에 관한 quaternion(=rotation 표현법 중에 하나) q 로 분리하여 2 개 factor 를 독립적으로 optimization 하도록 설계되었습니다.
- Scale은 x,y,z축에 관한 배율 정보를 갖고 있습니다.
- Quaternion 표현법 q (=shape는 4x1) 을 rotation matrix 표현법 R(=shape는 3x3) 으로 변환합니다. ([link](https://github.com/graphdeco-inria/gaussian-splatting/blob/b2ada78a779ba0455dfdc2b718bdf1726b05a1b6/utils/general_utils.py#L78))
- 소스코드를 확인해보니, S 의 초기값은 SfM 으로 만든 point cloud 의 각 점 (3x1) 에 root 를 씌우고 log 를 취한 후, 값을 복사하여 3x3 행렬로 만들고 있습니다. R 의 초기값 구성은, 점마다 4 개의 vector 로 만들고 첫번째 값을 1, 나머지 값을 0 으로 채우게 됩니다. ([link](https://github.com/graphdeco-inria/gaussian-splatting/blob/b2ada78a779ba0455dfdc2b718bdf1726b05a1b6/scene/gaussian_model.py#L134C1-L134C1))
- 이렇게 설계된 이유에 대해서 설명하자면, 랜더링을 위해 3D Gaussian이 2D Gaussian으로 Projection 되어질 때 Covariance Matrix가 Positive Definite를 만족하기 위함입니다. Positive Definite는 모든 변수가 0 초과값을 가지는 Matrix입니다([link](https://m.blog.naver.com/PostView.naver?isHttpsRedirect=true&blogId=sw4r&logNo=221495616715)). 3D Gaussian을 2D Gaussian으로 Projection하는 수식은 아래와 같으며, 해당 수식에 대한 설명은 따로 글로 설명 해두었습니다. [\-> 3D Gaussian Projection 설명](https://xoft.tistory.com/49)
![](https://blog.kakaocdn.net/dna/zmzu4/btsvjdQzbGm/AAAAAAAAAAAAAAAAAAAAAAL1qcETbMhnS1RBWlEs5RfXRBbh3I-6XirW68QQUPin/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=ODP8d%2BKctj1%2B61u3HwAZN%2FVvi18%3D)

**C** 는 3D Gaussian의 Color값을 의미하며, color는 Spherical Harmonics(SH)함수로 설계됩니다.

- 3D Guassian마다 view direction에 따른 최적의 SH coefficient를 찾도록 설계 되었습니다. Sperical Harmnoics에 대해서도 별도의 글로 소개해 두었습니다.[\-> Spherical Harmonics 설명](https://xoft.tistory.com/50)
- 초기값은 SfM으로 획득한 Point Cloud의 RGB Color값을 임의값인 (rgb값-0.5)/0.28209으로 초기화 됩니다. ([link](https://github.com/graphdeco-inria/gaussian-splatting/blob/b2ada78a779ba0455dfdc2b718bdf1726b05a1b6/scene/gaussian_model.py#L127C24-L127C24))

**A** 는 3D Gaussian의 투명도값을 의미하며 단일 실수값입니다. 초기값은 임의값인 log(0.1/(1-0.1))=-0.95 으로 지정해주고 있습니다([link](https://github.com/graphdeco-inria/gaussian-splatting/blob/b2ada78a779ba0455dfdc2b718bdf1726b05a1b6/scene/gaussian_model.py#L139C9-L139C19)). 투명도(알파)값이 음수라니 어색하네요. 최종적으로 랜더링시에 0~1범위로 바뀔 거라 생각됩니다.

위 수식들의 의미에 대해 개인적인 생각을 적어보자면,

- covariance matrix 3x3 을 곧바로 prediction 하는 모델 (9 개 변수) 로 설계하지 않고, rotation R 과 scale S 로 나누어 설계되어 있습니다. 의미적으로 linear하게 변화되도록 하려는 목적으로 보입니다.
- R\*S 는 scale 된 rotation matrix에 해당합 니다. R 은 가우시안의 회전 정도이고, S 는 가우시안의 크기입니다. 아래 그림 (출처: [link](https://en.wikipedia.org/wiki/Transformation_matrix) ) 은 2 차원에 대한 Affine Transform(rotation matrix 는 빨간,파란색 부분 2x2 크기) 을 나타내는데, No Change 에서 Scale, Rotate 을 위한 matrix 연산을 할 경우 어떻게 변환되는 것을 볼 수 있습니다. 3 차원에서도 같은 원리로 적용되게 됩니다.
![](https://blog.kakaocdn.net/dna/EmKvH/btsvaE6VHBS/AAAAAAAAAAAAAAAAAAAAAHKr29tqOYLZQuezQqdabNVlTi_gGgVImzx9plhokJXV/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=gxeFHPID3YP%2FMuZUS%2FufvzYKdSE%3D)

- R 은 3x3 matrix 이지만, 4 개의 변수로 구성된 quaternion 을 Rotation matrix 로 변환하여 사용하므로, 실제적으로 4 개 변수를 prediction 하면 됩니다. S 도 3x3 matrix 이지만, 3 개의 변수로 구성된 vector 를 copy 하는 구조라서 3 개 변수를 prediction 하면 됩니다.
- R\*S에 대해 Transpose값인 ST\*RT를 추가적으로 곱해 준 이유는, Covariance Matrix는 Symmetric한 성질을 갖기 때문에, 이러한 특성을 만들어주기 위함입니다([link](https://math.stackexchange.com/questions/158219/is-a-matrix-multiplied-with-its-transpose-something-special)). 일반적인 3D Gaussian 의 covariance matrix 는 3x3 으로구성되어있고,대각성분(principal diagonal)은각 axis 의 variance(분산)을나타내며,그외의값들은서로다른 2 개 axis 에대한 covariance(공분산)으로구성됩니다.([link](https://blog.naver.com/PostView.naver?blogId=waterforall&logNo=222789143718))

소스 코드상 정의된 Trainable Parameter는 아래와 같습니다. 보기 좋게 약간 수정 했습니다. ([link](https://github.com/graphdeco-inria/gaussian-splatting/blob/b2ada78a779ba0455dfdc2b718bdf1726b05a1b6/scene/gaussian_model.py#L141))

```python
self._xyz = nn.Parameter(fused_point_cloud) # M을 의미
self._features_dc = nn.Parameter(features[:,:,0:1].transpose(1, 2))  # C를 의미
self._features_rest = nn.Parameter(features[:,:,1:].transpose(1, 2)) # C를 의미
self._scaling = nn.Parameter(scales)        # S를 의미
self._rotation = nn.Parameter(rots)         # R를 의미
self._opacity = nn.Parameter(opacities)     # A를 의미
```

C를 의미하는 feature에서 dc, rest라고 되어 있는데, 앞서 color는 SH로 구성되어 있다고 했었습니다. dc는 direct constant로 추측되어지며, SH의 첫번째 coefficient (=first band)인 것으로 보이고, rest는 그 외의 coefficient로 보입니다. ([link1](https://www.reddit.com/r/GraphicsProgramming/comments/m19ith/explain_to_me_like_i_am_5_using_spherical/), [link2](https://community.arm.com/cfs-file/__key/telligent-evolution-components-attachments/01-2066-00-00-00-01-27-70/Simplifying_2D00_Spherical_2D00_Harmonics_2D00_for_2D00_Lighting.pdf))

### Optimization

![](https://blog.kakaocdn.net/dna/yBzJM/btsu9TwuSYn/AAAAAAAAAAAAAAAAAAAAAIIq4tVDUS_KjUpx4_Lg2Dze6IRTDRgbNQ6vHzvzOIO-/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=32D6a%2B%2BzCzMhGoGgt8EWj61rklo%3D)

여기서부터는 Train loop안에서 실행되는 연산들입니다.

**1번째 줄** 은 간단하게, 정답 이미지 I헷과 해당 이미지의 Camera Pose정보 V를 읽어옵니다.

**2번째 줄** 에서는 M(mean=xyz), S(Covariance), C(Color), A(투명도), V(카메라포즈)를 입력으로 받아 Rasterize하여 predicted된 Image를 만들고 있습니다. 설명이 길어져서 별도의 글로 정리했습니다. -> [Tile Rasterizer 설명](https://xoft.tistory.com/52)

**3번째 줄** 에서 predicted된 이미지와 GT이미지를 비교하여 Loss를 계산합니다. Loss 함수는 L1 과 D-SSIM 로 설계 되었습니다.λ는 0.2입니다. M(=mean=xyz)에 대해서만 Plenoxel과유사하게 standard exponential decay scheduling 을사용하였다고 합니다.

![](https://blog.kakaocdn.net/dna/ciTBhe/btsvl6CaS54/AAAAAAAAAAAAAAAAAAAAAH6_0WogZ4MJRZw0iYr_M8zn462uvnBoe0csCMqDu4o2/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=ehf6NTrS1czH%2F5o8GPxcbi7YFks%3D)

**4번째 줄** 에서 Adam Optimizer로 M, S, C, A값을 업데이트 하고 있습니다.

Optimization에 대한 세부 사항으로는 아래와 같습니다. (내용이 너무 detail하므로 Skip 하셔도 됩니다.)

1) 안정성을 위해, 낮은 해상도에서 연산을 warm-up 하게 됩니다. 초기에 4 배 작은 이미지 해상도로 optimization 을 진행하고 250, 500iteration 에서 2 배씩 upsampling 하였다고 합니다.

2) SH L0의 coefficient를 optimize 하면서 시작해서,매 1000itertion 후에 SH의 L1를 optimize하고 L4 까지 optimiza했습니다. 그 이유는, object 를 중심으로 반구형태로 촬영한 사진들로 구성되는 전형적인 NeRF 스타일의 촬영 scene 에서 optimization 은 잘 작동하였으나,SH coefficient optimization Augular 정보가 부족한 경우 민감했습니다. (scene의 corner 를촬영할때또는 inside-out 방식으로촬영할때) 놓친 angular 영역이 있다면,SH 의 L0에 대한 coeficient이 부적절하게 만들어 질 수 있었다고 합니다.

### Adaptive Control of Gaussians

![](https://blog.kakaocdn.net/dna/Haz45/btsvb6qfv0g/AAAAAAAAAAAAAAAAAAAAANGtKf9rttOV-nD36zscm5rk6626JoRMTyHRdFgUHQhd/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=xqFCDaD0ibLS7i1iDsZK1ecqfZU%3D)

Scene에 맞게 3D Gaussian들을 adaptive하게 변형시키는 단계입니다. 앞서 언급한 M,S,C,A paramter들은 매 iteration마다 update되지만, 초록색부분은 100iteration마다 수행됩니다. 3D Gaussian이 Remove/Split/Clone하게 되는데, 이를 densification한다라고 표현하고 있습니다. 이를 하나씩 뜯어보겠습니다.

**Remove Gaussian**: 특정 threshold(=ε) 보다 낮은 alpha값(=α=투명도)을 가진 Gaussian은 제거 됩니다. 코드상에 threshold는 0.005로 되어 있습니다.([link](https://github.com/graphdeco-inria/gaussian-splatting/blob/b2ada78a779ba0455dfdc2b718bdf1726b05a1b6/train.py#L117C41-L117C41) )

![](https://blog.kakaocdn.net/dna/EyNaM/btsvlIBxuxI/AAAAAAAAAAAAAAAAAAAAAKCn10UZ0wyqMD8UYaYtKKc12x-1paEMX8xEBaXIbvhH/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=TB45oruKh7quOMbMEAiH40kLW3g%3D)

Remove Gaussian을 단계를 거친 후, Geometric feature 를 파악하지 못한 영역 (=Under-reconstruction) 을 처리하고, 넓은 영역을 광범위하게 모델링한 Gaussian 들 (=over-reconstruction) 에 대해 처리하게 됩니다. 구체적으로 Under/Over-reconstruction영역은 공통적으로 view-space positional gradient 가 큰값을 가지기 때문에, view-space position gradient 의 평균 크기?(=average magnitude)가 특정 Thresould(=0.0002)이상이 된다 면, Gaussian 들을 Clone 또는 Split합니다.

**Clone Gaussian**: Under-Reconstruction 영역에 대해서, 작은 크기의 (=covariance가 작은) 3D Gaussian들은 같은 크기로 copy되고, positional gradient의 방향에 배치되게 됩니다.

**Split Gaussian**: Over-Reconstruction 영역에 대해서, 큰 크기의 (=covariance가 큰) 3D Gaussian 들이 작은 Gaussian 으로 분해됩니다. 1 개의 Gaussian 을 2 개의 Gaussian 으로 분리하게 되는데, scale 을 1.6(=실험적으로 결정한값) 으로 나누는 형태로 계산됩니다. 분리된 Gaussian의 위치는 초기 Gaussian의 확률밀도값에 따라 배치되어집니다.

Clone의 경우 가우시안의 갯수와 scene의 volume을 둘다 증가하게 되지만, split의 경우 전체 volume은 유지하면서 Gaussian의 갯수가 증가하게 됩니다. 다른 volumetric 기법들과 동일하게, 카메라의 가까운 영역에 floater들이 생기게 되는데, Gaussian이 무작위로 증가하는 형태로 나타납니다.

이를 위해, **3000 iteration마다 alpha값을 0으로 초기화** 해주는 전략을 사용합니다. M,S,C,A를 Optimization하는 단계에서 100iteration동안 alpha값은 0이 아닌 값으로 바뀌게 되며, 100 iteration후에 Gaussian Densification단계에서 Remove Gaussian연산을 통해 원치 않는 값들이 제거되어 집니다.

또 다른 이점으로써, 3D Gaussian들이 중첩되는 경우도 발생 될 수 있는데, 주기적으로 alpha 값이 0으로 초기화 되면서 큰 크기의 Gaussian들이 중첩되는 케이스를 제거해줍니다.

Alpha값을 주기적으로 0으로 셋팅하는 전략이 전체 Gaussian의 조절에 큰 역할을 하게 됩니다.

### Evaluation

![](https://blog.kakaocdn.net/dna/onyfP/btsvk214Lel/AAAAAAAAAAAAAAAAAAAAAKfm40wKDugMwrgqHnjMUytLsGyLauabzkBSG8_lL67J/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=0tF8rq4E0kCx1rpC18bngCSULWY%3D)

PSNR 설명: [\[평가 지표\] PSNR / SSIM / LPIPS](https://xoft.tistory.com/3)

데이터셋 특징 설명: [\[데이터셋\] NeRF Dataset 정리](https://xoft.tistory.com/44)

Mip-NeRF360은 A100 4장을 사용하였고, 나머지는 A6000을 사용했다고 합니다. FPS는 랜더링 시간을 의미합니다. 3D Gaussian Splatting을 Instant-NGP와 비교하였을 때 Train속도가 비슷하나, PSNR이 높고, 무엇보다도 랜더링 속도가 매우 빠릅니다. 랜더링 속도 관점에서 Instant NGP가 10FPS 정도면 괜찮지 않을까 싶은데, high-spec의 gpu를 사용한 속도이기 때문에, 저가형 GPU로 바뀔 경우 버벅거림이 발생할 수 있습니다. 단점으로는 이전 기법과 달리 memory가 상당히 많이 쓰이는 것을 볼 수 있습니다. 학습 과정에서 매우 큰 Scene에서는 GPU 메모리가 20GB까지 사용 되었다고 합니다. 때문에 소스코드에서는 24GB 이상 GPU램을 사용하라고 명시되어 있습니다. 작은 Scene의 경우, 더 적은 메모리를 가진 GPU를 사용 해도 됩니다.

퀄리티는 논문에서 아래 이미지로 소개되어 있으나, 공식 사이트([link](https://repo-sam.inria.fr/fungraph/3d-gaussian-splatting/)) 에서 보시길 권장드립니다.

[3D Gaussian Splatting WebGL](https://gsplat.tech/) 에서 WebGL에서 실시간 랜더링을 볼 수 있습니다.

제가 직접 코드 빌드 한 결과와 코드 셋팅법을 따로 정리해두었습니다. [\-> 3D Gaussian Splatting 코드 빌드](https://xoft.tistory.com/48)

![](https://blog.kakaocdn.net/dna/bBcedz/btsvHchnkPz/AAAAAAAAAAAAAAAAAAAAALQW8uVx0RltU90x3oPN1SzGIWYiY9o8rIJV15XY_PkH/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=%2F2UWbGVcdf7EbRneB6Ahqo%2FaVnM%3D)

### Ablation Study

**Initialization from SfM**

SfM point cloud 로 3D Gaussian 초기화에 대한 실험에 대해 다룹니다. Input camera 의 bounding box 크기의 3 배 사이즈로 cube 를 만들어 균등하게 샘플링 했을 때, SfM point 없이도 완전히 실패하는 케이스는 없이 상대적으로 잘 작동하는 것을 확인했다고 합니다. 아래 그림 을 보면, 주로 배경에서 성능이 저하되는 것을 확인 할 수 있습니다.

![](https://blog.kakaocdn.net/dna/bLY7hO/btsvPm5hhi7/AAAAAAAAAAAAAAAAAAAAAP0Vn8U4OrVh6FD42kFkbIeEfvRNdpLemkRG_JQKA8cu/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=dxN9x%2BG%2FcFFzlqxQR0R0QgwCloQ%3D)

Training view 로 부터 cover 되지 않은 영역에서 랜덤값으로 초기화한 방법은 optimization 으로도 제거 할 수 없는 floater 를 가지게 됩니다. 다른 관점으로, 합성 NeRF 데이터셋은 배경이 없고 입력 카메라 pose 값이 잘 주어졌기 때문에 이러한 현상이 발생하지 않습니다.

**Densification**

Clone 과 split 관점으로 densification 방법을 평가하였습니다.각 방법을 구분하여 disable 하고 나머지를 변형없이 optimize 하였습니다. 아래 그림에서 볼 수 있듯이, 큰 Gaussian 들을 나누는 것은 배경을 잘 reconstruction 하게 해주고, small gaussian 을 복제하는 것은 빠르게 수렴하도록 해주게 됩니다.

![](https://blog.kakaocdn.net/dna/ltfLD/btsvne2LJib/AAAAAAAAAAAAAAAAAAAAAA7m-Rt4ahqI60uGMDM9Vl_BsSSybggh3ohAQvEm0hey/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=yfElbxCB1SGKhFVL%2Fx8SfcmxVgc%3D)

Unlimited Depth Complexity of Splats with Gradients

Pulsar(2021) 연구에서 제안한 방법으로써, 카메라 가장 앞에 있는 N 번째 point부터 gradient 계산을 skipping 하는 것이 퀄리티 감소가 없으면서도 속도가 빠르게 될 수 있는지를 평가하였습니다. Pulsar 에서 언급된 N 보다 2 배 값인 N=10 으로 해서 테스트하였으나 gradient 계산에서 과도한 추정 때문에 optimization 이 불안정했다고 합니다. Truck scene 에서 PSNR 이 11 감소하였습니다.

![](https://blog.kakaocdn.net/dna/bwaqQI/btsvNt4ODrC/AAAAAAAAAAAAAAAAAAAAAJ_bba2hUJGbTE-OmlMiy9gfey1kIj6fG8cC-rXlUhbP/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=0GEbyz9mmUKhjzxqo5hh%2BddlmwY%3D)

**Anistropic Covariance**

논문에서 중요한 부분은 3D Gaussian 의 전체 covariance 를 optimization 하는 것 입니다. 3 개 모든 축에 대해 3D gaussian 의 반지름을 단일 sclar 값으로 조정 할 수 있도록 하고 optimization 하는 모델 설계를 해서, anistropy 를 제거할 수 있도록 하였고 이에 대한 실험을 진행하였습니다. 아래는 Optimization 의 결과입니다.

![](https://blog.kakaocdn.net/dna/cZTyLp/btsvQcnX2lH/AAAAAAAAAAAAAAAAAAAAAM7cpXM4x0RHOR58FG-YxzVKq7XvKcIty-Lg_rNtFrot/img.png?credential=yqXZFxpELC7KVnFOS48ylbz2pIh7yKj8&expires=1753973999&allow_ip=&allow_referer=&signature=tO6YzI40Qp0A9SpZSbLuEUQ3meA%3D)

실험결과 Anistropy 는 3D Gaussian 의 surface 에 align 하는 성능의 quality 를 상당히 향상시켰습니다. 이는 같은 point 갯수를 유지하면서 높은 rendering quality 를 보였습니다.

**Spherical Harmonics**

SH 는 View-dependent 한 효과를 보상하기 때문에, 전체 score 를 향상시켰습니다.

### Limitations

입력 이미지가 부족한 Sparse Scene 에서 artifact 가 발생하게 됩니다. Anistropic Gaussian 이 많은 이점을 가졌지만, 길어지는 artifacts 또는 얼룩이 있는 Gaussian이 만들어 질 수 있습니다. (다른 연구들도 이런 현상이 있었다고 합니다.) Optimization 을 통해 Large Gaussian 을 만들 때 artifact 가 가끔 발생하게 됩니다. Pose 에 따라 다른 apperance 를 보여주는 영역에서 주로 발생합니다.

- 이러한 artifact가 발생하는 이유중에 하나는 rasterizer단계에서 guard band를 거친 Gaussian trivial rejection입니다. 좀 더 이론적인 culling 접근법을 사용한다면 artifact를 완화 할 수 있을 것입니다.
- 두번째 이유는 depth/blending order 를 갑작스럽게 switching 하는 Gaussian 을 만들 수 있는 간단한 visibility algorithm입니다. 이것은 antialiasing 으로 해결 되어 질 수 있을 것이며, 미래 연구로 남겨두었다고 합니다.

현재 본 논문에서 제시한 알고리즘은 어떤 regularization 도 도입할 수 없다고 합니다. regularization을 도입하게 된다면 보이지 않은 지역과 artifact 발생 영역을 잘 처리 할 수 있을 것입니다.

전체 평가에 같은 hyperparameter 를 사용하지만, 초기 실험에서 position learning rate 를 줄이는 것은 매우 큰 scene(ex urban dataset) 을 수렴하는데 필요 할 수 있습니다.

이전 연구의 Point 기반 접근법과 비교해서 매우 compact 할지라도, NeRF 기반 solution 보다 상당히 높은 메모리 사용량을 가집니다. Large scene 을 학습시에 Peak GPU memory 는 20 GB 를 넘을 수 있으며, Optimization logic 의 low-level 구현하면 이러한 양상을 상당히 줄일 수 있다고 합니다. 학습된 scene 을 랜더링하는 것은 전체 모델을 저장하기 위한 충분한 GPU 를 요구하며 Scene size 와 image 에 따라서 Rasterizer 를 위해 추가적으로 30-5000MB 가 필요합니다.

### Closing..

생소한 개념이라 진입장벽이 생기는 읽기 어려운 논문입니다. 똑같은 문제만 풀었고 NeRF연구들과 실험 결과만 비교하였지, 기존 NeRF와 전혀 다르며 MLP와 volume rendering 개념 또한 사용되고 있지 않습니다. 처음 봤을 땐 속도와 퀄리티 면에서 엄청난 논문이 나왔다고 생각했지만, 서비스 적으로 활용도가 높아지기 위해서 Sparse한 입력 이미지 갯수 관점에선 아직 부족해보이고, 속도 개선도 좀 더 이뤄져야 할 것 같습니다. 이런 단점들이 곧 해결 될 것이라 생각됩니다.

[저작자표시 비영리 변경금지 (새창열림)](https://creativecommons.org/licenses/by-nc-nd/4.0/deed.ko)