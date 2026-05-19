# BRDF

# 이론

크게 2개로 나눈다.

- Ambient lighting 주변광 → image light으로 구현
- direct Lighting 직접광 → point, spot light으로 구현

PBR은 물리 기반 랜더링 기술이기 때문에, 빛을 구현하기 위해서,

빛의 특징인 “파동, 입자”의 특징을 이해할 필요가 있다.

## Scattering

빛이 어떤 분자를 만나서, 흩어지는 것을 의미한다.

![[그래픽스/이론 및 공부/directx/BRDF/image.png]]

오른쪽으로 갈 수록 빛을 흩어지게 만들어서, 뿌옇게 만든다.

위로 올라가면, 빛을 흡수하기 때문에 색이 변하게 된다.

## Material

크게 3개로 나눌 수 있다.

- metals
- Non-metals

어떤 물체 표면에 빛을 때리면 크게 2개로 나눈다.

- 물체의 표면에서 반사되는 빛
- 물체에 들어가는 빛

아주 작은 표면에서 보면, 빛이 물체에 들어가서 산란되고, 반사된다.

metals은 안으로 들어가는 빛을 모두 흡수한다. 바로 반사되는 것들만 빛이 반사되어서, 표면이 반짝거린다.

Non-metals은 내부적으로 빛이 들어와, 분자들을 만나서 산란된다.

사방으로 난반사 되는 것을 하나로 모아서 diffuse로 만들었다.

일부는 빛이 반사된다. —> specular로 만들었다.

specular와 diffuse의 비율을 적절하게 해서 재질을 묘사했다.

specular 값을 키우고 diffuse를 줄이면 → 금속에 가까워지고, 반대로 하면 나무같은 비금속에 가까워진다.

반사가 되는 위치가 다를 수 있다.

![[그래픽스/이론 및 공부/directx/BRDF/image 1.png]]

들어오는 것과 나오는 위치가 다를 수 있다.

산란 되어서, 나오는 위치가 한 픽셀보다 작으면 굳이 고려해야 할 이유가 없다.

![[그래픽스/이론 및 공부/directx/BRDF/image 2.png]]

간단하게 diffuse와 specular가 같은 곳에서 나오는 것으로 구현한다.

# 수학적인 정의

- Radiance → 빛이 얼마나 들어오는가 → 조명이 빛을 얼마나 쐈는가
- Single Ray → 한 픽셀에서 들어오는 빛의 강도
- Spectral/RGB → 빛의 색 → 다양한 주파수의 빛이 혼합하는 것에 따라 실제 어떻게 보이는 것에 대해서 고려한 값 RGB

BRDF

- Bidirectional
- Reflectance
- Distribution
- Function

$f(l,v)$

빛이 들어오는 방향이 달라지거나, 빛을 보고 있는 방향이 달라지면 값이 변한다.

### Spherical Coordinates

구 좌표계

![[그래픽스/이론 및 공부/directx/BRDF/image 3.png]]

데카르트 좌표계를 사용하지 않는다.

2개의 자유도를 가지고 있다. 벡터의 크기가 1이기 때문에, 각도 2개만 가지고 표현이 가능하다.(자유도 $\theta, \phi$  각도를 가지고 구현할 수 있다.)

적분식이 나온다.

![[그래픽스/이론 및 공부/directx/BRDF/image 4.png]]

위 사진에서 파랑색 네모에서 빛이 나와서 한 점에 빛을 쏘고 있다.

 → 한 위치에서 들어오는 모든 빛을 계산하기 위해서 적분을 이용한 것이다.

![[그래픽스/이론 및 공부/directx/BRDF/image 5.png]]

파란색 부분의 각도를 solid  angle

해당 각도에서 빛이 얼마나 들어오는 지를 반구에 대해서 적분하면 한 지점의 빛이 들어오는 정도를 계산할 수 있다.

이 때, BRDF를 정의할 수 있다.

$BRDF = \frac{L_o}{E_i}$ → 비율

$L_o$ : 특정 방향으로 빛을 반사하는 것

$E_i$ : 들어온 빛

BRDF는 2가지 조건을 만족해야한다.

![[그래픽스/이론 및 공부/directx/BRDF/image 6.png]]

상호 법칙을 만족해야 한다.

나가는 방향과 들어오는 방향의 값이 서로 바뀌어도, BRDF의 값은 같아야 한다. 같은 비율이기 때문이다.

![[그래픽스/이론 및 공부/directx/BRDF/image 7.png]]

나가는 벡터와 들어오는 벡터의 위치를 바꿔도 값은 같다

2번째는 에너지 보존 법칙을 준수해야 한다.

$spec + diff ≤ InputEnergy$ 이어야 한다.

랜더링하는 것은 랜더링 하는 지점에서 눈 방향으로 들어오는 빛을 계산하는 방법

이 계산할 때, 한 지점 들어오는 모든 빛에 대해서, 눈으로 들어오는 빛이 얼마인지 계산하는 것이다.

BRDF는 특정 지점에서 들어오는 빛이 눈 방향으로 얼마 만큼의 빛으로 들어오는 지를 계산하는 것이다.

BRDF 함수를 어떤 계산을 통해서 만드는 것인지 중요하다. 수학적인 형식이다.

## The Reflectance Equation

$L_o(\mathbf{v}) = \int_{\Omega} f(\mathbf{l}, \mathbf{v}) \otimes L_i(\mathbf{l}) (\mathbf{n} \cdot \mathbf{l}) d\omega_i$

- $L_o(\mathbf{v})$ : 보는 방향, 픽셀 쉐이더에서 계산해야하는 색깔
- $L_i(\mathbf{l})$ : “l” 방향으로 들어오는 빛의 양을 의미한다.
- $(\mathbf{n} \cdot \mathbf{l})$ : “l” 방향으로 들어오는 빛의 방향하고, “n”(표면의 nomal 벡터) dot 계산

$L_i(\mathbf{l}) (\mathbf{n} \cdot \mathbf{l}) d\omega_i$ : 어떤 빛으로 부터 표면에 빛을 쏘았을 때, 들어갈 수 있는 빛의 양

$f(\mathbf{l}, \mathbf{v})$ : $L_i(\mathbf{l}) (\mathbf{n} \cdot \mathbf{l}) d\omega_i$ 이 만큼 다시 반사한 양을 의미한다.
위 2개의 값을 적분을 통해서, 눈으로 들어오는 빛의 색깔을 계산할 수 있다.

이 때, 빛이 여러 방향으로 들어오기 때문에, 적분을 한다. 빛이 들어오는 모든 경로에 대해서 합해야 한다. 그러면 한 지점에 들어오는 빛의 양을 계산할 수 있다. 이 더하는 과정을 적분으로 표현한다.

$d\omega_i$ : 파란색 네모 영역의 각도

$\otimes$ : Component-wise multiplication (벡터 외적 곱)

HLSL 쉐이더에서 float3 사이의 * 연산자

## Microfacet **Specular** BRDF

**Specular를 계산하는데, 고려해야 하는 점과 그 안에 들어있는 함수 정리**

### MicroFacet Theory(작은표면의 각도)

![[그래픽스/이론 및 공부/directx/BRDF/image 8.png]]

미세하게 보면, 다양한 각도로 되어있다.

이 다양한 각도로 되어있는 표면들을 미세한 거울들의 집합으로 되어 있다고 가정한다.

### The Half Vector

![[그래픽스/이론 및 공부/directx/BRDF/image 9.png]]

l 방향으로 빛이 들어왔을 때, 특정 v벡터 방향으로 반사시키는 NormalVector h가 얼마나 많은지에 비례한다.

BRDF를 계산할 때, h벡터를 사용한다.

cook-torrance BRDF를 참고해서, 아래와 같은 식으로 표현됨

![[그래픽스/이론 및 공부/directx/BRDF/image 10.png]]

$f(\mathbf{l}, \mathbf{v}) = \frac{F(\mathbf{l},\mathbf{h})G(\mathbf{l},\mathbf{v},\mathbf{h})D(\mathbf{h})}{4(\mathbf{n} \cdot \mathbf{l})(\mathbf{n} \cdot \mathbf{v})}$

이 수식은 Cook-Torrance BRDF 모델을 나타냅니다. 여기서:

- F(l,h)는 프레넬 항
- G(l,v,h)는 기하학적 감쇠 항
- D(h)는 법선 분포 함수
- n, l, v, h는 각각 표면 법선, 입사광 방향, 시선 방향, 하프 벡터를 나타냅니다.

### Fresnel Reflectance(프레넬 반사율)

- F(l,h)

보는 각도에 따라서 색이나 밝기가 달라진다.

빛을 반사해 주는 비율이 달라진다.

**금속**

![[그래픽스/이론 및 공부/directx/BRDF/image 11.png]]

비금속

![[그래픽스/이론 및 공부/directx/BRDF/image 12.png]]

반도체 (거의 사용하지 않는다)

![[그래픽스/이론 및 공부/directx/BRDF/image 13.png]]

아주 정밀하게 사용하기 어려워서 적당하게 계산해서 사용한다.

![[그래픽스/이론 및 공부/directx/BRDF/image 14.png]]

계산에 따라서, 다르게 사용한다.

### Normal Distribution Function

- D(h)는 법선 분포 함수

눈으로 반사해주는 미세표면들의 normal 벡터의 비율을 계산하는 함수이다.

Specular에서 HighLight를 결정한다.

구현에 따라 여러가지 식을 사용한다.

![[그래픽스/이론 및 공부/directx/BRDF/image 15.png]]

### Geometry Function

- G(l,v,h)는 기하학적 감쇠항

미세 표면이 울퉁불퉁하면 빛이 반사되어도 나가지 못하고 어두워지거나, 빛이 들어오지 못하고 어두운 부분이 있을 수도 있다.

두 가지를 표현한 기하학 형태를 표현한 함수이다.

![[그래픽스/이론 및 공부/directx/BRDF/image 16.png]]

Smith Function는 수학적으로 유효하고, 물리적으로도 사실적이다.

## Subsurface Reflection(Diffuse Term)

빛이 들어가서 여기저기 난반사 되어 나간다.

![[그래픽스/이론 및 공부/directx/BRDF/image 17.png]]

![[그래픽스/이론 및 공부/directx/BRDF/image 18.png]]

N•L이 정의되어 있기 때문에, constant value처럼 보인다.

## Image-Based Lighting

환경맵을 조명처럼 사용한다.  → 이미지를 조명처럼 사용하는 것이다.

![[그래픽스/이론 및 공부/directx/BRDF/image 19.png]]

오른쪽 항으로 변환이 가능하다.

오른쪽 식을 사용하는 것은 힘들다.

왜냐하면 실시간 렌더링을 하는 데, 모든 지점의 조명을 계산하는 방법은 아주 느리다. 그래서 Unreal에서는 이미지에서 조명값을 가져와서 사용한다.

![[그래픽스/이론 및 공부/directx/BRDF/image 20.png]]

위 식은 해당 계산을 하려면, GPU의 부담이 많다는 것을 보여주기 위한 식이다.

![[그래픽스/이론 및 공부/directx/BRDF/image 21.png]]

식에서 더 나누어서, 계산할 수 있다. 그리고 위와 같이 성립하기 위해서는 하나의 조건을 만족해야한다.

$L_i(l)$의 값이 모두 같다는 것을 만족해야 한다. 하지만, 약간의 오차가 있어도 괜찮다.

### Environment BRDF
