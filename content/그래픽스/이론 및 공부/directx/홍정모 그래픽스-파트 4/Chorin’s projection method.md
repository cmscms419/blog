# Chorin’s projection method

[Projection method (fluid dynamics)](https://en.wikipedia.org/wiki/Projection_method_(fluid_dynamics))

위의 링크를 참고해서 만들면 된다.

아래 방정식은 **나비에-스토크스 방정식**이다.

![Untitled](attachments/Untitled_17.png)

***u***: 속도 ***f***: 단위체적당 걸리는 외력 *ρ*: 밀도 *p*: 압력 *ν*: 점성 계수 이다.

비압축성 유체 흐름 문제([**나비에-스토크스 방정식**](https://ko.wikipedia.org/wiki/%EB%82%98%EB%B9%84%EC%97%90-%EC%8A%A4%ED%86%A0%ED%81%AC%EC%8A%A4_%EB%B0%A9%EC%A0%95%EC%8B%9D))를 **수치적으로** 해결하는 방법

이 투영 방법의 장점은 속도와 압력을 분리해서 계산하는 것이다.

## 비압축성의 원리

### 위의 식의 의미

![Untitled](attachments/Untitled%201.png)

해당 사각형에 속도가 들어오고, 나가는 속도가 같다면, 안에 있는 질량은 일정하다.

밀도가 일정하면, 부피도 일정하다. → 비압축성 조건을 표현할 때 다이버전스를 이용한다.

![Untitled](attachments/Untitled%202.png)

→ 컴퓨터로 미분하는 방법을 알 수 있다.

### 가정1. 압력을 무시

처음에는 압력에 대한 $-\frac{1}{p}\bigtriangledown{p}$ 무시하고 계산한다.

압력이 포함되지 않는 부분을 무시한다.

![Notes_240127_214539.jpg](attachments/Notes_240127_214539.jpg)

![Untitled](attachments/Untitled%203.png)

위 식으로 부터 $u^*$를 구할 수 있다.

### 가정2. 압력을 영향을 준다.

$u^*$를 구한 값으로 $u^{n+1}$을 구한다.

계산하게 되면, 아래와 같은 식이 도출된다

아래식은 푸아송 방적식으로 선형 방정식이다.

![Untitled](attachments/Untitled%204.png)

[라플라시안 연산자 - Google Search](https://www.google.com/search?q=라플라시안+연산자&tbm=isch&ved=2ahUKEwihqNy2sPWDAxVcevUHHW4bD08Q2-cCegQIABAA&oq=라플라시안+&gs_lcp=CgNpbWcQARgBMgQIIxAnMgQIIxAnMgUIABCABDIFCAAQgAQyBQgAEIAEMgUIABCABDIFCAAQgAQyBQgAEIAEMgUIABCABDIGCAAQBxAeUABYAGD_CmgBcAB4AIABAIgBAJIBAJgBAKoBC2d3cy13aXotaW1nwAEB&sclient=img&ei=oKuwZaHYM9z01e8P7ra8-AQ&bih=898&biw=1707)

중요함 → 기호 이해하는 중요하다

밀도 = 가상으로 두어도 괜찮은 것

# advection

![Untitled](attachments/Untitled%205.png)

사진은 막대기가 패턴이 생기면서 이동한다.

1. 속도장이 만들어 졌을 떄, 속도장을 타고 움직인다.
2. 속도장을 타고 움직인다.
3. 색깔을 주면, 색이 속도장을 타고 움직이는 것처럼 보인다.

![Untitled](attachments/Untitled%206.png)

```cpp
uint width, height;
velocity.GetDimensions(width, height);
float2 dx = float2(1.0 / width, 1.0 / height);
float2 pos = (dtID.xy + 0.5) * dx; // 이 쓰레드가 처리하는 셀의 중심

// TODO: 1. velocityTemp로부터 속도 샘플링해오기
float2 vel = velocityTemp.SampleLevel(pointWrapSS, pos, 0).xy;
// vel = float2(1.0, 0.0);

// TODO: 2. 그 속도를 이용해서 역추적 위치 계산
float2 posBack = pos - vel * dt;

// TODO: 3. 그 위치에서 샘플링 해오기
velocity[dtID.xy] = velocityTemp.SampleLevel(linearWrapSS, posBack, 0);
density[dtID.xy] = densityTemp.SampleLevel(linearWrapSS, posBack, 0);
```

밀도(density)를 색이라고 생각하면 된다

# Pressure

위 값을 구하기 전에 알아야 하는 것이 있다.

### project 부분을 푸는 부분

계산양을 줄이기 위해서 축약을 한다.

나눈기 t를 해준다. 시뮬레이션 공간 내에서는 low가 일정하다고 가정한다. t는 정해져 있다.

간단하게 말하면 위의 식을 아래쪽으로 곱하고, 나누고, 오른쪽 왼쪽으로 옮겨서 아래쪽처럼 만드는 것이다.

나중에는 그래디언트를 구할 때, 뒤집혀 진다. “1”로 두는 경우가 있다.

![Untitled](attachments/Untitled%207.png)

위의 식을 아래처럼 변

![Untitled](attachments/Untitled%208.png)

위 처럼 나온다

다음 타임 스템에서의 속도를 구할 수 있다

자코피이터레이션을 사용해야 한다.

## 연기

![Untitled](attachments/Untitled%209.png)

연기는 돌면서 움직인다. 비압축성 조건이 도는 행동에 중요한 조건이다.

### 압력 구현

한 공간에 힘을 가하면, 해당 공간의 압력은 높아진다.

그 공간는 압력을 해소 하기 위해서, 모든 방향에 압력을 준다.

압력 높은 곳 → 압력 낮은 곳

![Untitled](attachments/Untitled%2010.png)

위와 같이 이동한다.

이것을 반복하다 보면 아래와 같이 이동하게 된다.

![Untitled](attachments/Untitled%2011.png)

연기는 위와 같이 여기저기 간다.

### 자코피이터레이션(압력 구하기)

pressure(압력)을 구하는 부분이다.

![Untitled](attachments/Untitled%2012.png)

위의 값을 코드에서는 div이다.

다시 코드에서 사용하기 위해서, 변형하면

![Untitled](attachments/Untitled%2013.png)

시그마는 위의 4개의 P이다.

한 점을 0으로 정한다.

반복해서 구한다 왜냐하면, 멀리있는 곳(A)은 처음에는 0이고, 반복할 수 록 A 위치 근처의 값이 업데이트 되면서, 계산할 수 있는 상황이 된다.

# 점성 부분

![Untitled](attachments/Untitled%2014.png)

u*로 계산한다.

밀도에도 점성을 추가한다.

분산을 적용시킨다.

![Untitled](attachments/Untitled%2015.png)

위 식을 사용해서, 밀도를 구할 수 있다.

위의 식만 쓰면, 불안하다.

## 밀도와 속도의 식이 같은 이유???

비압축성에 의해서 비슷하게 쓸 수 있다.

### Explicit integration(명시적 적분)

속도를 구할 수 있다.

안정적으로 주변에 퍼져 나간다.

![[/Untitled.png]]

### Implicit Integration(묵시적 적분)

![[/Untitled.png]]

미래에 만족 시켜야 하는 것($u^n -> u^{n+1}$ 변환)을 왼쪽으로 넘기는 것

위와 같은 방정식을 해결하면, 불안정한 부분을 보안 할 수 있다.

1. 중간값 u* 구하기
2. 현재 압력 구하기

## 구현

점성을 구현하기 위해서는 먼저 구현해야 하는 것이 있다.

# **Vorticity Confinement**

Visual Simulation of Smoke 논문을 이용해서 만들 수 있다.

유체 흐름 방정식을 사용합니다.

처음에는 가스를 비점성, 비압축성, 일정한 밀도의 유체로 모델링할 수 있다고 가정합니다.

점도의 영향은 가스에서 무시할 수 있으며, 특히 수치 손실이 물리적 점도와 분자 확산을 지배하는 거친 그리드에서 그렇습니다

- Ex1601_ComputeVorticityCS
- Ex1601_ConfineVorticityCS

사용해서, 보실 수 있습니다.

## 구현 방법

![Untitled](attachments/Untitled%2018.png)

이 논문에서는 연기는 큰 속도장을 포함하고 있다고 설명한다.

위 부분을 해당 .hlsl에 구현 하면 된다.

1. 비압축성 흐름에서 회전의 소규모 구조를 제공합니다.
2. 낮은 회전값에서 높은 회전값를 가리키는 정규화된 회전 위치 벡터가 계산
3. 회전의 크기와 방향은 위 수식으로 계산

## 1. 회전의 소규모 구조를 제공

![Untitled](attachments/Untitled%2019.png)

속도를 가지고 있는 어떤한 부분의 그리드(텍스처 좌표, 픽셀)부분의 회전을 구하는 것이다.

이 회전시키는 벡터장을 **속도를 가지고 회전하는 방향을 구하는 것이다.**

왜 위 식으로 회전의 방향을 알 수 있는가?

먼저 Curl에 대해서 이해를 해야한다.

Curl계산은 벡터의 회전을 구하는 방법이다. 벡터의 회전은 어떤 의미인가?

![Untitled](attachments/Untitled%2020.png)

그림에서 나오는 것처럼 속도를 가지고 계산하면, 회전하는 벡터의 법선 벡터를 구할 수 있다.

위 화살표를 집중적으로 확인해 보면,

![Untitled](attachments/Untitled%2021.png)

주변의 속도를 가지고, 회전 벡터를 기준으로 하는 면의 법선 방향을 알 수 있습니다.

-w는 회전 방향이 반대입니다.

[회전 (벡터)](https://ko.wikipedia.org/wiki/회전_(벡터))

위 사이트에 아래와 같이 정의되어 있습니다.

![Untitled](attachments/Untitled%2022.png)

이 식을 이용해서, 벡터장에서 벡터가 어떤 기준점을 가지고 회전하는 것을 계산할 수 있다.

구현하려는 공간은 2차원 입니다.

그렇기에 i, j 부분은 제외되고 k부분만 있습니다. 왜냐하면, 3차원 구현하는 것이 아니기 때문에, 3차원에 해당하지 않는 부분은 수식에서 빠질 수 있다.

```cpp
float2 dx = float2(1.0 / width, 1.0 / height);
...
vorticity[dtID.xy] = (
(velocity[right].y - velocity[left].y) / dx.x -
(velocity[up].x - velocity[down].x) * dx.y) * 0.5;
```

$/dx.x와 /dx.y 그리고 마지막 * 0.5$

위의 계산식에 넣은 이유는 회전값을 텍스처 좌표와 같은 배열상에 넣기 위해서 사용한다.

식을 보면, /dx.x와 /dx.y 나눠진다.

이 의미는 x와 y가 어떻게 값이 변했는지를 의미한다.

그 변화량은 텍스처 좌표만큼 변하기 때문에 `float2 dx = float2(1.0 / width, 1.0 / height)`

를 사용한다.

위 식을 통해서 회전 값을 구할 수 있다.

## 2. 낮은 회전값에서 높은 회전값를 가리키는 정규화된 회전 위치 벡터가 계산

![Visual Simulation of Clouds(출처)](attachments/Untitled%2023.png)

Visual Simulation of Clouds(출처)

위 의미를 해석하면, 회전 벡터를 스칼라로 바꾼 뒤, 미분해서 벡터를 구한다. 그리고 그것을 정규화 한다. 왜 스칼라 미분을 하는 것인가?

검색과 생각한 이유는 회전 벡터가 어디로 향하는 지를 구하기 위해서 이다. 현재 상태로는 회전하는 방향 만을 알 수 있다. 하지만 위와 같이 변환하면, 회전 벡터가 공간상으로 앞으로 어떻게 변하는지를 알 수 있다.

그 다음에는 절대값에 대한 방향을 구하기 위해서 벡터를 미분해서 x,y 축에서 어떤 방향으로 나가는 지를 알 수 있다.

그 다음에 정규화를 해야지 회전 방향 벡터를 얻을 수 있다.

```cpp
float2 eta = abs(
float2(
(vorticity[right] - vorticity[left]) / dx.x,
(vorticity[up] - vorticity[down]) / dx.y)
) * 0.5;
```

위의 식을 통해서 에 **η**를 구할 수 있습니다.

```cpp
float3 psi = normalize(float3(eta, 0.0))
```

그리고 **η**를 사용해서 N(psi ,회전 방향 벡터)를 구할 수 있습니다.

## 3. 회전의 크기와 방향은 위 수식으로 계산

![Untitled](attachments/Untitled%2024.png)

회전 방향을 구했으니, 이제 크기와 방향을 가지고 회전에 대해서 정의 할 수 있다.

위 식을 구현하기 위해서는 다음과 같은 코드를 씁니다.

```cpp
// 전에 구했던, 오메가 부분이다. w 부분
float3 omega = float3(0, 0, vorticity[dtID.xy]);

// 여기 부분에서 외적부분이 나온다.
velocity[dtID.xy] += cross(psi, omega).xy * dx * 0.5;
```

`cross(psi, omega).xy` 하는 이유는 무엇인가?? → 이제까지 구한 회전에 대한 벡터의 외적으로 통해서 이 그리드(픽셀)에서 회전된 값을 구하기 위해서 이다.

![[/vector회전.png]]

**ϵ(엡실론)** > 0 : 유동 필드에 다시 추가되는 작은 스케일 세부 사항의 양을 제어하는 데 사용

h(공간 이산화에 대한 의존성) : 메쉬가 미세 조정될 때 물리적으로 올바른 솔루션을 계속 얻을 수 있도록 보장한다

이 후 값을 속도 벡터에 더하면, 연기같은 효과를 표현할 수 있다.
