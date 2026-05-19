# Attention Mechanism

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/01.webp)
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/02.webp)

---

## 3.1 RNN(긴 시퀀스 모델링)의 문제점

- 소스 언어와 대상 언어 간의 문법 구조 차이로 인해 텍스트를 단어별로 번역하는 것은 불가능합니다 → 단어 하나하나 번역하는 것은 안 된다
- 긴 시퀀스의 모든 정보를 하나의 고정된 크기 벡터로 압축 → 시퀀스가 길수록 초기 정보가 손실됨

![03 1.webp](attachments/03%201.webp)

- Transformer 이전에는 **RNN(Recurrent Neural Network)** 기반 모델이 주로 사용되었습니다
- Encoder는 소스 언어의 토큰 시퀀스를 처리하여 hidden state를 사용해 전체 입력 시퀀스의 압축된 표현을 생성합니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/04.webp)

- **Encoder**: 전체 입력 시퀀스 → 하나의 압축된 표현
- **Decoder**: 압축된 표현 → 출력 시퀀스 생성
- **문제**: 압축 과정에서 중요한 정보 손실

---

## 3.2 Attention Mechanism으로 데이터 종속성 포착하기

- Attention mechanism을 통해 decoder는 모든 입력 토큰에 선택적으로 접근할 수 있으며, 특정 출력 토큰을 생성할 때 특정 입력 토큰이 더 중요하다는 것을 의미합니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/05.webp)

- Transformer의 Self-attention은 시퀀스 내의 각 위치가 동일한 시퀀스 내의 다른 모든 위치와 상호작용하고 관련성을 결정할 수 있도록 하여 입력 표현을 향상시키기 위해 설계된 기법입니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/06.webp)

---

## 3.3 Self-attention 이해를 위한 예시

### 3.3.1 훈련 가능한 가중치가 없는 간단한 Self-attention

- 훈련 가능한 가중치가 포함되지 않은 단순화된 self-attention 변형을 설명합니다
- 입력 시퀀스 $x^{(1)}$부터 $x^{(T)}$가 주어졌을 때, 각 입력 요소 $x^{(i)}$에 대한 **context vector** $z^{(i)}$를 계산하는 것이 목표입니다

**정의:**

$$
z^{(i)} = \sum_{j=1}^{T} \alpha_{ij} \, x^{(j)}
$$

- $\alpha_{ij}$: attention weight (합이 1이 되도록 정규화된 값)
- $z^{(i)}$는 입력 $x^{(1)}$부터 $x^{(T)}$에 대한 **가중 합**입니다
- context vector는 특정 입력에 대한 특징을 나타내는 벡터입니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/07.webp)

> 그림의 숫자는 시각적 혼란을 줄이기 위해 소수점 이하 한 자리로 잘렸습니다.

- 정규화되지 않은 attention weight → **attention score** ($\omega$)
- 합이 1이 되도록 정규화된 attention score → **attention weight** ($\alpha$)

---

### **1단계:** 정규화되지 않은 attention score $\omega$ 계산

두 번째 입력 토큰을 query로 사용한다고 가정합니다 ($q^{(2)} = x^{(2)}$).
Dot product를 통해 정규화되지 않은 attention score를 계산합니다:

$$
\omega_{2j} = x^{(j)} \cdot {q^{(2)}}^\top, \quad j = 1, \ldots, T
$$

즉:

$$
\omega_{21} = x^{(1)} \cdot {q^{(2)}}^\top, \quad
\omega_{22} = x^{(2)} \cdot {q^{(2)}}^\top, \quad
\omega_{23} = x^{(3)} \cdot {q^{(2)}}^\top, \quad \ldots
$$

- $\omega$는 정규화되지 않은 attention score를 나타내는 그리스 문자 "오메가"입니다
- $\omega_{21}$의 아래첨자 "21"은 입력 요소 2가 입력 요소 1에 대한 query로 사용되었음을 의미합니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/08.webp)

---

### **2단계:** Attention score를 합이 1이 되도록 정규화 (Softmax)

$$
\alpha_{2j} = \frac{\exp(\omega_{2j})}{\sum_{k=1}^{T} \exp(\omega_{2k})}
$$

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/09.webp)

---

### **3단계:** Context vector $z^{(2)}$ 계산

임베딩된 입력 토큰 $x^{(i)}$에 attention weight $\alpha_{2j}$를 곱하고 결과 벡터들을 합산합니다:

$$
z^{(2)} = \sum_{j=1}^{T} \alpha_{2j} \, x^{(j)}
$$

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/10.webp)

---

### 3.3.2 모든 입력 토큰에 대한 attention weight 계산하기

위에서는 입력 2에 대한 attention weight와 context vector를 계산했습니다. 이를 일반화하여 모든 attention weight와 context vector를 계산합니다.

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/11.webp)

> 그림의 숫자는 소수점 이하 두 자리로 잘렸습니다. 각 행의 값들의 합은 1.0 (100%)이어야 합니다.

- Self-attention 과정: attention score 계산 → softmax 정규화 → context vector 생성

$$
\text{Attention}(X) = \text{softmax}\!\left(\frac{X X^\top}{\sqrt{d}}\right) X
$$

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/12.webp)

---

## 3.4 훈련 가능한 가중치로 Self-attention 구현하기

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/13.webp)

### 3.4.1 Attention weight를 단계별로 계산하기

- 원래 Transformer 아키텍처, GPT 모델 및 대부분의 LLM에서 사용되는 self-attention mechanism을 구현합니다
- 이를 **"Scaled Dot-Product Attention"** 이라고도 합니다
- 기본 아이디어: 특정 입력 요소에 특정한 입력 벡터들에 대한 가중 합으로 context vector를 계산

앞서 소개한 기본 attention과의 차이점:
- 훈련 중에 업데이트되는 **weight 행렬** $W_q$, $W_k$, $W_v$ 도입
- 이 weight 행렬이 모델이 "좋은" context vector를 생성하도록 학습을 가능하게 함

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/14.webp)

**1단계 — Query / Key / Value 벡터 계산:**

세 개의 훈련 weight 행렬 $W_q$, $W_k$, $W_v$를 사용하여 임베딩된 입력 토큰 $x^{(i)}$를 투영합니다:

$$
q^{(i)} = x^{(i)} W_q \qquad \text{(Query: "무엇을 찾고 있는가?")}
$$

$$
k^{(i)} = x^{(i)} W_k \qquad \text{(Key: "나는 무엇인가?")}
$$

$$
v^{(i)} = x^{(i)} W_v \qquad \text{(Value: "실제 정보는 무엇인가?")}
$$

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/15.webp)

**2단계 — 정규화되지 않은 attention score 계산:**

Query $q^{(2)}$와 각 key 벡터 $k^{(j)}$ 간의 dot product를 계산합니다:

$$
\omega_{2j} = q^{(2)} \cdot {k^{(j)}}^\top
$$

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/16.webp)

**3단계 — Attention weight 계산 (Softmax + Scaling):**

$$
\alpha_{2j} = \frac{\exp\!\left(\omega_{2j} / \sqrt{d_k}\right)}{\sum_{m=1}^{T} \exp\!\left(\omega_{2m} / \sqrt{d_k}\right)}
$$

여기서 $d_k$는 key 벡터의 차원입니다 (수치 안정성을 위한 스케일링).

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/17.webp)

**4단계 — Context vector 계산:**

$$
z^{(2)} = \sum_{j=1}^{T} \alpha_{2j} \, v^{(j)}
$$

---

### 3.4.2 컴팩트한 SelfAttention 클래스 구현하기

행렬 형태로 표현하면:

$$
\text{Attention}(Q, K, V) = \text{softmax}\!\left(\frac{Q K^\top}{\sqrt{d_k}}\right) V
$$

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/18.webp)

---

## 3.5 Causal Attention으로 미래 단어 숨기기

- Causal attention에서는 대각선 위의 attention weight가 마스킹되어, LLM이 context vector를 계산하는 동안 **미래 토큰을 사용할 수 없도록** 합니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/19.webp)

### 3.5.1 Causal attention mask 적용하기

- 각 다음 단어 예측이 이전 단어들에만 의존하도록 보장합니다
- 미래 토큰들을 마스킹하여 이를 달성합니다

$$
\text{mask}_{ij} = \begin{cases} 0 & \text{if } j \leq i \\ -\infty & \text{if } j > i \end{cases}
$$

$$
\text{CausalAttention}(Q, K, V) = \text{softmax}\!\left(\frac{Q K^\top + \text{mask}}{\sqrt{d_k}}\right) V
$$

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/20.webp)

- 대각선 위의 attention weight를 0으로 만들고 재정규화하는 대신, softmax 이전에 대각선 위의 score를 $-\infty$로 마스킹하는 것이 더 효율적입니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/21.webp)

---

### 3.5.2 Dropout으로 추가 attention weight 마스킹하기

- 훈련 중 과적합을 줄이기 위해 dropout을 적용합니다
- Dropout 적용 위치: attention weight 계산 후 (더 일반적)

$$
\alpha' = \text{Dropout}(\alpha, p)
$$

- dropout rate $p = 0.5$이면 attention weight의 절반을 무작위로 마스킹
- 드롭되지 않은 값들은 $\dfrac{1}{1 - p}$ 인수로 스케일링됩니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/22.webp)

> Dropout은 추론 중이 아닌 **훈련 중에만** 적용됩니다.

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/23.webp)

---

## 3.6 Single-head Attention을 Multi-head Attention으로 확장하기

### 3.6.1 여러 Single-head Attention Layer 스택하기

Single-head attention (causal mask, dropout 생략):

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/24.webp)

Multi-head attention — 여러 single-head attention 모듈을 스택합니다:

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch03_compressed/25.webp)

- 서로 다른 학습된 선형 투영으로 attention mechanism을 여러 번 병렬로 실행합니다
- 모델이 다른 위치에서 다른 표현 부공간의 정보에 공동으로 주의를 기울일 수 있게 합니다

$$
\text{MultiHead}(Q, K, V) = \text{Concat}(\text{head}_1, \ldots, \text{head}_h) \, W^O
$$

$$
\text{head}_i = \text{Attention}(Q W_i^Q,\; K W_i^K,\; V W_i^V)
$$

---

### 3.6.2 Weight Split으로 Multi-head Attention 구현하기

- 앞서의 `CausalAttention`을 래핑하는 방식 대신, 독립적인 `MultiHeadAttention` 클래스를 작성합니다
- 단일 $W_Q$, $W_K$, $W_V$ weight 행렬을 생성한 후 각 attention head에 대한 개별 행렬로 분할합니다

나머지는 코드 참고
