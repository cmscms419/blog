![01.webp](attachments/01.webp)


- LLM은 고차원 공간(즉, 수천 차원)의 임베딩으로 작업합니다

![02.webp](attachments/02.webp)
- 고차원 공간(3차원 이상의 축을 가진 공간)을 시각화할 수 없기 때문에(아래 그림은 2차원 임베딩 공간을 보여줍니다)
![03 1.webp](attachments/03%201.webp)
## 텍스트 토큰화
- 우리가 작업할 원시 텍스트를 로드합니다
- [The Verdict by Edith Wharton](https://en.wikisource.org/wiki/The_Verdict)은 퍼블릭 도메인 단편 소설입니다

- 이것은 꽤 좋고, 이제 이 토큰화를 원시 텍스트에 적용할 준비가 되었습니다
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch02_compressed/05.webp)
## 2.3 토큰을 토큰 ID로 변환하기
- 다음으로, 나중에 임베딩 레이어를 통해 처리할 수 있는 토큰 ID로 텍스트 토큰을 변환합니다
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch02_compressed/06.webp)
- 이러한 토큰으로부터 모든 고유한 토큰으로 구성된 어휘를 구축할 수 있습니다
- 아래에서는 작은 어휘를 사용하여 짧은 샘플 텍스트의 토큰화를 설명합니다:
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch02_compressed/07.webp?123)
- 이제 모든 것을 토크나이저 클래스로 합쳐 봅시다
- `encode` 함수는 텍스트를 토큰 ID로 변환합니다
- `decode` 함수는 토큰 ID를 다시 텍스트로 변환합니다
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch02_compressed/08.webp?123)
- 우리는 토크나이저를 사용하여 텍스트를 정수로 인코딩(즉, 토큰화)할 수 있습니다
- 이러한 정수는 나중에 LLM의 입력으로 임베딩될 수 있습니다
## 2.4 특수 컨텍스트 토큰 추가하기
- 알려지지 않은 단어와 텍스트의 끝을 나타내기 위해 일부 "특수" 토큰을 추가하는 것이 유용합니다
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch02_compressed/09.webp?123)
- 일부 토크나이저는 LLM에 추가 컨텍스트를 제공하기 위해 특수 토큰을 사용합니다
- 이러한 특수 토큰 중 일부는
  - `[BOS]` (sequence의 시작) 텍스트의 시작을 표시합니다
  - `[EOS]` (sequence의 끝) 텍스트가 끝나는 곳을 표시합니다 (이는 보통 서로 관련이 없는 여러 텍스트를 연결할 때 사용됩니다. 예: 두 개의 다른 위키피디아 기사나 두 개의 다른 책 등)
  - `[PAD]` (패딩) LLM을 1보다 큰 배치 크기로 훈련할 때 (길이가 다른 여러 텍스트를 포함할 수 있습니다; 패딩 토큰으로 더 짧은 텍스트를 가장 긴 길이까지 패딩하여 모든 텍스트가 동일한 길이를 갖도록 합니다)
- `[UNK]`는 어휘에 포함되지 않은 단어를 나타냅니다

- GPT-2는 위에서 언급한 이러한 토큰들이 필요하지 않고 복잡성을 줄이기 위해 `<|endoftext|>` 토큰만 사용한다는 점에 주목하세요
- `<|endoftext|>`는 위에서 언급한 `[EOS]` 토큰과 유사합니다
- GPT는 또한 패딩을 위해 `<|endoftext|>`를 사용합니다 (배치된 입력에서 훈련할 때 일반적으로 마스크를 사용하므로, 패딩된 토큰에는 어차피 주의를 기울이지 않으므로 이러한 토큰이 무엇인지는 중요하지 않습니다)
- GPT-2는 어휘에 없는 단어에 대해 `<UNK>` 토큰을 사용하지 않습니다; 대신 GPT-2는 단어를 하위 단어 단위로 분해하는 바이트 페어 인코딩(BPE) 토크나이저를 사용합니다. 이에 대해서는 이후 섹션에서 논의하겠습니다


- 우리는 두 개의 독립적인 텍스트 소스 사이에 `<|endoftext|>` 토큰을 사용합니다:
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch02_compressed/10.webp)
- 다음 텍스트를 토큰화하면 어떻게 되는지 봅시다:

- 위의 코드는 "Hello"라는 단어가 어휘에 포함되어 있지 않기 때문에 오류를 발생시킵니다
- 이러한 경우를 처리하기 위해, 알려지지 않은 단어를 나타내는 `"<|unk|>"`와 같은 특수 토큰을 어휘에 추가할 수 있습니다
- 이미 어휘를 확장하고 있으므로, GPT-2 훈련에서 텍스트의 끝을 나타내는 데 사용되는 `"<|endoftext|>"`라는 또 다른 토큰을 추가해 봅시다 (그리고 이것은 연결된 텍스트 사이에도 사용됩니다. 예를 들어 우리의 훈련 데이터셋이 여러 기사, 책 등으로 구성되어 있다면)

- 또한 새로운 `<unk>` 토큰을 언제 어떻게 사용할지 알 수 있도록 토크나이저를 그에 맞게 조정해야 합니다

## 2.5 바이트페어 인코딩
- GPT-2는 토크나이저로 바이트페어 인코딩(BPE)을 사용했습니다
- 이를 통해 모델은 미리 정의된 어휘에 없는 단어를 더 작은 하위 단어 단위 또는 개별 문자로 분해하여 어휘에 없는 단어를 처리할 수 있습니다
- 예를 들어, GPT-2의 어휘에 "unfamiliarword"라는 단어가 없다면, 훈련된 BPE 병합에 따라 ["unfam", "iliar", "word"] 또는 다른 하위 단어 분해로 토큰화할 수 있습니다
- 원래 BPE 토크나이저는 여기에서 찾을 수 있습니다: [https://github.com/openai/gpt-2/blob/master/src/encoder.py](https://github.com/openai/gpt-2/blob/master/src/encoder.py)
- 이 장에서는 계산 성능을 향상시키기 위해 핵심 알고리즘을 Rust로 구현한 OpenAI의 오픈 소스 [tiktoken](https://github.com/openai/tiktoken) 라이브러리의 BPE 토크나이저를 사용합니다
- [./bytepair_encoder](../02_bonus_bytepair-encoder)에서 이 두 구현을 나란히 비교하는 노트북을 만들었습니다 (tiktoken은 샘플 텍스트에서 약 5배 빨랐습니다)

- BPE 토크나이저는 알려지지 않은 단어를 하위 단어와 개별 문자로 분해합니다:
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch02_compressed/11.webp)
## 2.6 슬라이딩 윈도우로 데이터 샘플링
- 우리는 LLM이 한 번에 하나의 단어를 생성하도록 훈련시키므로, 시퀀스의 다음 단어가 예측할 대상을 나타내도록 훈련 데이터를 그에 맞게 준비하고 싶습니다:
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch02_compressed/12.webp)

- 각 텍스트 청크에 대해 입력과 대상을 원합니다
- 모델이 다음 단어를 예측하기를 원하므로, 대상은 입력을 한 위치 오른쪽으로 이동시킨 것입니다
- 이렇게 하는 이유는 LLM이 현재 단어 시퀀스를 보고 다음에 올 단어를 예측하도록 훈련시키기 위해서입니다. 즉, 입력 시퀀스의 각 위치에서 다음 토큰이 무엇인지 학습하게 됩니다.
- 우리는 어텐션 메커니즘을 다룬 후의 장에서 다음 단어 예측을 처리할 것입니다
- 지금은 입력 데이터셋을 반복하고 하나씩 이동된 입력과 대상을 반환하는 간단한 데이터 로더를 구현합니다
- PyTorch를 설치하고 가져옵니다 (설치 팁은 부록 A를 참조하세요)
- 우리는 위치를 +1씩 변경하는 슬라이딩 윈도우 접근법을 사용합니다:

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch02_compressed/13.webp?123)
- 입력 텍스트 데이터셋에서 청크를 추출하는 데이터셋과 데이터로더를 생성합니다
## 2.7 토큰 임베딩 생성하기
- 데이터는 이미 LLM을 위해 거의 준비되었습니다
- 하지만 마지막으로 임베딩 레이어를 사용하여 토큰을 연속적인 벡터 표현으로 임베딩해 봅시다
- 보통 이러한 임베딩 레이어는 LLM 자체의 일부이며 모델 훈련 중에 업데이트(훈련)됩니다

Embedding : 텍스트나 단어를 컴퓨터가 이해할 수 있는 숫자 벡터로 변환하는 기법입니다.

# 단어를 고정 크기의 벡터로 변환
"사과" → [0.2, -0.1, 0.8, 0.3]  # 4차원 벡터
"바나나" → [0.1, -0.2, 0.7, 0.4]  # 4차원 벡터
"자동차" → [-0.5, 0.8, 0.1, -0.3]  # 4차원 벡터
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch02_compressed/15.webp)
- 토큰화 후 입력 id가 2, 3, 5, 1인 다음 네 개의 입력 예제가 있다고 가정해 봅시다:
- 단순화를 위해, **6개의 단어만 있는 작은 어휘**가 있고 크기 3의 임베딩을 만들고 싶다고 가정해 봅시다:
vocab_size = 6  # 어휘 크기: 6개 단어
output_dim = 3  # 임베딩 차원: 3차원 벡터
embedding_layer = torch.nn.Embedding(vocab_size, output_dim)
- 이는 6x3 가중치 행렬을 만들 것입니다:
- 원-핫 인코딩에 익숙한 분들을 위해, 위의 임베딩 레이어 접근법은 본질적으로 원-핫 인코딩 후 완전 연결 레이어에서 행렬 곱셈을 수행하는 더 효율적인 방법일 뿐입니다. 이는 [./embedding_vs_matmul](../03_bonus_embedding-vs-matmul)의 보충 코드에서 설명됩니다
- 임베딩 레이어는 원-핫 인코딩과 행렬 곱셈 접근법과 동등한 더 효율적인 구현일 뿐이므로 역전파를 통해 최적화할 수 있는 신경망 레이어로 볼 수 있습니다
- 위의 네 개의 `input_ids` 값을 모두 임베딩하려면 다음과 같이 합니다
- 임베딩 레이어는 본질적으로 룩업 연산입니다:
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch02_compressed/16.webp?123)
- **임베딩 레이어와 일반 선형 레이어를 비교하는 보너스 콘텐츠에 관심이 있으실 수 있습니다: [../03_bonus_embedding-vs-matmul](../03_bonus_embedding-vs-matmul)**
## 2.8 단어 위치 인코딩
- 임베딩 레이어는 입력 시퀀스에서 위치에 관계없이 ID를 동일한 벡터 표현으로 변환합니다:
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch02_compressed/17.webp)
- 위치 임베딩은 토큰 임베딩 벡터와 결합되어 대형 언어 모델의 입력 임베딩을 형성합니다:
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch02_compressed/18.webp)
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch02_compressed/19.webp)