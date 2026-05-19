# LLM Architecture

이 장에서는 GPT와 같은 LLM 아키텍처를 구현합니다. 다음 장에서는 이 LLM을 훈련하는 데 집중할 것입니다.

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/01.webp)

---

## 4.1 LLM 아키텍처 코딩하기

- Chapter 1에서는 순차적으로 단어를 생성하고 원본 Transformer 아키텍처의 decoder 부분을 기반으로 하는 GPT와 Llama 같은 모델들을 논의했습니다
- 이러한 LLM들은 종종 **"decoder-like" LLM** 이라고 불립니다
- 기존 딥러닝 모델과 비교하여, LLM은 주로 방대한 수의 매개변수로 인해 더 크지만, 코드의 양 때문은 아닙니다
- LLM의 아키텍처에서 많은 요소들이 반복됩니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/02.webp)

- 이 장에서는 작은 GPT-2 모델과 유사한 embedding과 모델 크기를 고려합니다
- [Language Models are Unsupervised Multitask Learners](https://cdn.openai.com/better-language-models/language_models_are_unsupervised_multitask_learners.pdf)에서 설명된 가장 작은 GPT-2 모델 **(124M 매개변수)** 의 아키텍처를 구체적으로 코딩할 것입니다
- Chapter 6에서는 345M, 762M, 1542M 매개변수 모델 크기와 호환되는 사전훈련된 가중치를 로드하는 방법을 보여줄 것입니다

124M 매개변수 GPT-2 모델의 구성:

```python
GPT_CONFIG_124M = {
    "vocab_size": 50257,    # Vocabulary size
    "context_length": 1024, # Context length
    "emb_dim": 768,         # Embedding dimension
    "n_heads": 12,          # Number of attention heads
    "n_layers": 12,         # Number of layers
    "drop_rate": 0.1,       # Dropout rate
    "qkv_bias": False       # Query-Key-Value bias
}
```

- `"vocab_size"`: BPE tokenizer에서 지원하는 50,257개 어휘 크기 → 토큰으로 변환할 수 있는 단어 수
- `"context_length"`: positional embedding에서 가능한 모델의 최대 입력 토큰 수
- `"emb_dim"`: 각 입력 토큰을 768차원 벡터로 변환하는 embedding 크기
- `"n_heads"`: multi-head attention 메커니즘의 attention head 수
- `"n_layers"`: 모델 내의 transformer block 수
- `"drop_rate"`: 0.1은 훈련 중 hidden unit의 10%를 drop함을 의미
- `"qkv_bias"`: Q, K, V 텐서 계산 시 bias 벡터 포함 여부 (현대 LLM 표준인 비활성화 선택)

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/03.webp)

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/04.webp)

---

## 4.2 Layer Normalization으로 활성화 정규화하기

- **LayerNorm** ([Ba et al. 2016](https://arxiv.org/abs/1607.06450))은 신경망 레이어의 활성화를 평균 0, 분산 1로 정규화합니다
- 훈련을 안정화하고 효과적인 가중치로의 빠른 수렴을 가능하게 합니다
- Multi-head attention 모듈의 전후 모두에 적용되며, 최종 출력 레이어 전에도 적용됩니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/05.webp)

- 정규화는 각각의 두 입력(행)에 독립적으로 적용됩니다
- `dim=-1`을 사용하면 마지막 차원(feature 차원)에 걸쳐 계산이 적용됩니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/06.webp)

평균을 빼고 표준편차로 나누어 정규화합니다:

$$
\hat{x} = \frac{x - \mu}{\sqrt{\sigma^2 + \epsilon}}
$$

```python
out_norm = (out - mean) / torch.sqrt(var)
```

### Scale과 Shift

- 두 개의 훈련 가능한 매개변수인 `scale`과 `shift`를 추가합니다
- 초기값: `scale = 1` (곱함), `shift = 0` (더함) → 아무런 효과 없음
- 훈련 중 모델이 데이터에 가장 적합한 스케일링과 시프팅을 자동으로 학습합니다

### 편향된 분산 (Biased Variance)

- `unbiased=False` 설정 시 다음 공식으로 분산 계산합니다:

$$
\sigma^2 = \frac{\sum_i (x_i - \bar{x})^2}{n}
$$

- Bessel의 보정(`n-1` 사용)을 포함하지 않으므로 편향된 추정치를 제공합니다
- embedding 차원 `n`이 매우 큰 LLM의 경우 `n`과 `n-1`의 차이는 무시할 수 있습니다
- GPT-2는 편향된 분산으로 훈련되었으므로, 사전훈련된 가중치와의 호환성을 위해 이 설정을 채택합니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/07.webp)

---

## 4.3 GELU 활성화로 Feed Forward 네트워크 구현하기

- LLM의 transformer block의 일부로 사용되는 작은 신경망 서브모듈을 구현합니다
- LLM에서는 ReLU 대신 **GELU** (Gaussian Error Linear Unit) 와 **SwiGLU** (Swish-Gated Linear Unit) 등이 사용됩니다
- GELU와 SwiGLU는 더 복잡하고 부드러운 활성화 함수로, 딥러닝 모델에 더 나은 성능을 제공합니다

**GELU 정의** ([Hendrycks and Gimpel 2016](https://arxiv.org/abs/1606.08415)):

$$
\text{GELU}(x) = x \cdot \Phi(x)
$$

여기서 $\Phi(x)$는 표준 Gaussian 분포의 누적 분포 함수입니다.

실제로는 계산적으로 더 저렴한 **근사식**을 사용합니다 (원래 GPT-2 모델도 이 근사치로 훈련):

$$
\text{GELU}(x) \approx 0.5 \cdot x \cdot \left(1 + \tanh\!\left[\sqrt{\frac{2}{\pi}} \cdot \left(x + 0.044715 \cdot x^3\right)\right]\right)
$$

![Pasted image 20250720194807.png](attachments/Pasted%20image%2020250720194807.png)

- **ReLU**: 양수면 입력 그대로 출력, 음수면 0 출력 (조각별 선형 함수)
- **GELU**: 음수 값에 대해 0이 아닌 기울기를 가진 부드럽고 비선형적인 함수 (약 -0.75 지점 제외)

### FFN이 없으면 생기는 문제

- Attention만으로는 개별 토큰의 복잡한 변환에 한계가 있음
- 표현력 부족으로 성능 저하
- 모델의 깊이와 복잡성 부족

### 결론 — Feed Forward + GELU 조합의 핵심 가치

- **표현력**: 복잡한 언어 패턴 학습 가능
- **안정성**: 부드러운 최적화와 안정적 훈련
- **효율성**: 적절한 확장 비율로 성능-비용 균형
- **상호보완성**: Attention과 함께 완전한 정보 처리 파이프라인 구성

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/09.webp)

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/10.webp)

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/11.webp)

---

## 4.4 Shortcut Connection 추가하기

- Skip 또는 **residual connection** 이라고도 불리는 shortcut connection입니다
- 원래 vanishing gradient 문제를 완화하기 위해 컴퓨터 비전용 딥 네트워크(residual network)에서 제안되었습니다
- 한 레이어의 출력을 나중 레이어의 출력에 추가하여 기울기가 흐를 수 있는 대안적인 짧은 경로를 만듭니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/12.webp)

**Shortcut connection 없이** 기울기 값:

```python
layers.0.0.weight has gradient mean of 0.00020173587836325169
layers.1.0.weight has gradient mean of 0.0001201116101583466
layers.2.0.weight has gradient mean of 0.0007152041653171182
layers.3.0.weight has gradient mean of 0.001398873864673078
layers.4.0.weight has gradient mean of 0.005049646366387606
```

**Shortcut connection 포함한** 기울기 값:

```python
layers.0.0.weight has gradient mean of 0.22169792652130127
layers.1.0.weight has gradient mean of 0.20694106817245483
layers.2.0.weight has gradient mean of 0.32896995544433594
layers.3.0.weight has gradient mean of 0.2665732502937317
layers.4.0.weight has gradient mean of 1.3258541822433472
```

- Shortcut connection은 초기 레이어(`layer.0` 방향)에서 기울기가 사라지는 것을 방지합니다

### Shortcut Connection 사용 이유

```python
def forward(self, x):
    # Attention 블록
    shortcut = x                    # 원본 정보 저장
    x = self.norm1(x)              # 정규화 (안정화)
    x = self.att(x)                # Attention 적용
    x = x + shortcut               # 원본과 변환된 정보 결합
    # Feed Forward 블록
    shortcut = x                    # 다시 원본 저장
    x = self.norm2(x)              # 정규화 (안정화)
    x = self.ff(x)                 # GELU를 포함한 FFN
    x = x + shortcut               # 원본과 변환된 정보 결합
```

- ✅ 기울기 흐름 보장
- ✅ 원본 정보 보존
- ✅ 깊은 네트워크 훈련 가능

---

## 4.5 Transformer Block에서 Attention과 Linear 레이어 연결하기

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/13.webp)

- 각각 6개의 토큰을 가진 2개의 입력 샘플이 있고, 각 토큰이 768차원 embedding 벡터라고 가정합니다
- 이 transformer block은 self-attention에 이어 linear 레이어를 적용하여 유사한 크기의 출력을 생성합니다
- 출력은 context vector의 강화된 버전으로 생각할 수 있습니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/14.webp)

---

## 4.6 GPT 모델 코딩하기

- 이제 transformer block을 연결하여 사용 가능한 GPT 아키텍처를 얻어보겠습니다
- Transformer block은 여러 번 반복됩니다. 가장 작은 124M GPT-2 모델의 경우 12번 반복합니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/15.webp)

- 124M 구성을 사용하면 실제로는 163M 매개변수가 나옵니다. 이유는:
  - 원래 GPT-2 논문에서 **weight tying** 을 적용했기 때문입니다
  - 토큰 embedding 레이어(`tok_emb`)를 출력 레이어로 재사용: `self.out_head.weight = self.tok_emb.weight`
  - 토큰 embedding: 50,257차원 → 768차원
  - 출력 레이어: 768차원 → 50,257차원
  - Chapter 5에서 사전훈련된 가중치 로드 시 weight-tying을 다시 적용합니다

**연습** — GPT-2 논문에서 참조하는 다른 구성들:

| 모델 | emb_dim | n_layers | n_heads |
|------|---------|----------|---------|
| GPT2-small (124M) | 768 | 12 | 12 |
| GPT2-medium | 1024 | 24 | 16 |
| GPT2-large | 1280 | 36 | 20 |
| GPT2-XL | 1600 | 48 | 25 |

---

## 4.7 텍스트 생성하기

- GPT 모델은 한 번에 하나씩 단어를 생성합니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/16.webp)

- **Greedy decoding**: 각 단계에서 가장 높은 확률을 가진 단어(토큰)를 선택합니다
- 가장 높은 logit = 가장 높은 확률이므로, 기술적으로 softmax를 명시적으로 계산할 필요도 없습니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/17.webp)

```python
def generate_text_simple(model, idx, max_new_tokens, context_size):
    # idx is (batch, n_tokens) array of indices in the current context
    for _ in range(max_new_tokens):

        # Crop current context if it exceeds the supported context size
        idx_cond = idx[:, -context_size:]

        # Get the predictions
        with torch.no_grad():
            logits = model(idx_cond)

        # Focus only on the last time step
        # (batch, n_tokens, vocab_size) becomes (batch, vocab_size)
        logits = logits[:, -1, :]

        # Apply softmax to get probabilities
        probas = torch.softmax(logits, dim=-1)  # (batch, vocab_size)

        # Get the idx of the vocab entry with the highest probability value
        idx_next = torch.argmax(probas, dim=-1, keepdim=True)  # (batch, 1)

        # Append sampled index to the running sequence
        idx = torch.cat((idx, idx_next), dim=1)  # (batch, n_tokens+1)

    return idx
```

- `generate_text_simple`은 한 번에 하나씩 토큰을 생성하는 반복 과정을 구현합니다

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch04_compressed/18.webp)

---

## 요약 및 핵심 사항

- 이 장에서 구현한 GPT 모델이 포함된 자체 완결적인 스크립트: [./gpt.py](./gpt.py)
- 연습 문제 해답: [./exercise-solutions.ipynb](./exercise-solutions.ipynb)
