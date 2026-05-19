![chapter-overview-1.webp](attachments/chapter-overview-1.webp)

## 데이터 구조

- instruction: 모델에게 주어지는 지시사항 ("What is an antonym of 'complicated'?")
- input: 추가 입력 데이터 (이 경우 비어있음)
- output: 모델이 생성해야 하는 정답 ("An antonym of 'complicated' is 'simple'.")

- 지시 사항 파인튜닝은 종종 "지도 학습 지시 사항 파인튜닝"이라고 불리는데, 이는 input-output 쌍이 명시적으로 제공되는 데이터셋에서 모델을 훈련시키는 것을 포함하기 때문입니다
- 항목들을 LLM에 대한 입력으로 포맷하는 다양한 방법들이 있습니다; 아래 그림은 각각 Alpaca (https://crfm.stanford.edu/2023/03/13/alpaca.html)와 Phi-3 (https://arxiv.org/abs/2404.14219) LLM의 훈련에 사용된 두 가지 예제 포맷을 보여줍니다

![prompt-style.webp](attachments/prompt-style.webp)
## 훈련 배치로 데이터 구성하기
![chapter-overview-2.webp](attachments/chapter-overview-2.webp)
아래 그림에 요약된 것처럼 여러 단계로 이 데이터셋 배치 처리를 다룹니다.

![detailed-batching.webp](attachments/detailed-batching.webp)

모든 입력을 사전 토큰화하는 `InstructionDataset` 클래스를 구현합니다
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch07_compressed/pretokenizing.webp)
- 여기서는 더 정교한 접근법을 취하고 데이터 로더에 전달할 수 있는 사용자 정의 "collate" 함수를 개발합니다
- 이 사용자 정의 collate 함수는 각 배치의 훈련 예제들이 같은 길이를 갖도록 패딩합니다 (하지만 다른 배치들은 다른 길이를 가질 수 있습니다)

![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch07_compressed/padding.webp)
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch07_compressed/batching-step-4.webp?1)
- 위에서는 LLM에 대한 입력만 반환했습니다; 그러나 LLM 훈련을 위해서는 타겟 값도 필요합니다
- LLM을 사전 훈련시키는 것과 유사하게, 타겟은 1 위치만큼 오른쪽으로 이동된 입력이므로 LLM이 다음 토큰을 예측하는 것을 학습합니다
![inputs-targets.webp](attachments/inputs-targets.webp)

- 다음으로, 모든 패딩 토큰을 새로운 값으로 대체하기 위해 `ignore_index` 값을 도입합니다; 이 `ignore_index`의 목적은 손실 함수에서 패딩 값을 무시할 수 있다는 것입니다 (나중에 자세히 설명)
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch07_compressed/batching-step-5.webp?1)
- 구체적으로, 이는 아래에 설명된 것처럼 `50256`에 해당하는 토큰 ID를 `-100`으로 대체한다는 의미입니다
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch07_compressed/ignore-index.webp?1)
- (또한, 샘플의 길이를 제한하고 싶은 경우를 위해 `allowed_max_length`도 도입합니다; 이는 GPT-2 모델이 지원하는 1024 토큰 컨텍스트 크기보다 긴 자신만의 데이터셋으로 작업할 계획이라면 유용할 것입니다)
-  cross-entropy 손실 함수는 -100 레이블을 가진 훈련 예제를 무시했다는 의미입니다
- 기본적으로 PyTorch는 -100 레이블에 해당하는 예제를 무시하도록 `cross_entropy(..., ignore_index=-100)` 설정을 가지고 있습니다
- 이 -100 `ignore_index`를 사용하여, 훈련 예제들을 동일한 길이로 패딩하기 위해 사용한 배치의 추가적인 end-of-text (패딩) 토큰들을 무시할 수 있습니다
- 그러나 end-of-text (패딩) 토큰(50256)의 첫 번째 인스턴스는 무시하고 싶지 않습니다. 왜냐하면 이것이 LLM에게 응답이 완료되었을 때를 신호하는 데 도움이 될 수 있기 때문입니다

- 실제로는 아래 그림에서 설명된 것처럼 지시 사항에 해당하는 타겟 토큰 ID들을 마스킹하는 것도 일반적입니다 (이는 장을 완료한 후 권장되는 독자 연습입니다)
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch07_compressed/mask-instructions.webp?1)
## 지시 사항 데이터셋을 위한 데이터 로더 생성
- 이 섹션에서는 `InstructionDataset` 클래스와 `custom_collate_fn` 함수를 사용하여 훈련, 검증, 테스트 데이터 로더를 인스턴스화합니다
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch07_compressed/chapter-overview-3.webp?1)
- 이전 `custom_collate_fn` 함수의 또 다른 추가 세부 사항은 이제 주 훈련 루프에서 수행하는 대신 데이터를 타겟 장치(예: GPU)로 직접 이동시킨다는 것입니다. 이는 데이터 로더의 일부로 `custom_collate_fn`을 사용할 때 백그라운드 프로세스로 수행될 수 있기 때문에 효율성을 향상시킵니다
- Python의 `functools` 표준 라이브러리에서 `partial` 함수를 사용하여, 원래 함수의 `device` 인수가 미리 채워진 새로운 함수를 생성합니다
## 사전 훈련된 LLM 로딩
```python
# from gpt_download import download_and_load_gpt2
# from previous_chapters import GPTModel, load_weights_into_gpt
# If the `previous_chapters.py` file is not available locally,
# you can import it from the `llms-from-scratch` PyPI package.
# For details, see: https://github.com/rasbt/LLMs-from-scratch/tree/main/pkg
# E.g.,
from ch04 import GPTModel
from ch05 import download_and_load_gpt2, load_weights_into_gpt

BASE_CONFIG = {
    "vocab_size": 50257,     # Vocabulary size
    "context_length": 1024,  # Context length
    "drop_rate": 0.0,        # Dropout rate
    "qkv_bias": True         # Query-key-value bias
}

model_configs = {
    "gpt2-small (124M)": {"emb_dim": 768, "n_layers": 12, "n_heads": 12},
    "gpt2-medium (355M)": {"emb_dim": 1024, "n_layers": 24, "n_heads": 16},
    "gpt2-large (774M)": {"emb_dim": 1280, "n_layers": 36, "n_heads": 20},
    "gpt2-xl (1558M)": {"emb_dim": 1600, "n_layers": 48, "n_heads": 25},
}

CHOOSE_MODEL = "gpt2-small (124M)"

BASE_CONFIG.update(model_configs[CHOOSE_MODEL])

model_size = CHOOSE_MODEL.split(" ")[-1].lstrip("(").rstrip(")")

settings, params = download_and_load_gpt2(
    model_size=model_size,
    models_dir="gpt2"
)

model = GPTModel(BASE_CONFIG)
load_weights_into_gpt(model, params)
model.eval();

```

## 지시 사항 데이터에서 LLM 파인튜닝

- 이 섹션에서는 모델을 파인튜닝합니다
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch07_compressed/chapter-overview-5.webp?1)
- 이전 장에서 사용했던 모든 손실 계산 및 훈련 함수를 재사용할 수 있다는 점에 주목하세요
## 응답 추출 및 저장
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch07_compressed/chapter-overview-6.webp?1)
- 이 섹션에서는 다음 섹션에서 채점하기 위해 테스트 세트 응답을 저장합니다
- 또한 향후 사용을 위해 모델의 사본을 저장합니다
- 하지만 먼저, 파인튜닝된 모델이 생성한 응답을 간략히 살펴봅시다

- 테스트 세트 지시 사항, 주어진 응답, 모델의 응답을 바탕으로 보면, 모델이 상대적으로 잘 수행됩니다
- 첫 번째와 마지막 지시 사항에 대한 답변은 명확히 정확합니다
- 두 번째 답변은 근접합니다; 모델이 "cumulonimbus" 대신 "cumulus cloud"로 답변했습니다 (하지만 cumulus 구름이 뇌우를 생성할 수 있는 cumulonimbus 구름으로 발전할 수 있다는 점에 주목하세요)
- 가장 중요한 것은, 올바른 스팸/비스팸 클래스 레이블의 백분율을 계산하여 분류 정확도를 얻기만 하면 되었던 이전 장에서와 같이 모델 평가가 그렇게 간단하지 않다는 것을 볼 수 있습니다
- 실제로 chatbot과 같은 지시 사항 파인튜닝된 LLM들은 여러 접근법을 통해 평가됩니다
  - 모델의 지식을 테스트하는 MMLU ("Measuring Massive Multitask Language Understanding", [https://arxiv.org/abs/2009.03300](https://arxiv.org/abs/2009.03300))와 같은 단답형 및 객관식 벤치마크
  - LMSYS chatbot arena ([https://arena.lmsys.org](https://arena.lmsys.org))와 같은 다른 LLM에 대한 인간 선호도 비교
  - AlpacaEval ([https://tatsu-lab.github.io/alpaca_eval/](https://tatsu-lab.github.io/alpaca_eval/))과 같이 GPT-4와 같은 다른 LLM을 사용하여 응답을 평가하는 자동화된 대화 벤치마크

- 다음 섹션에서는 AlpacaEval과 유사한 접근법을 사용하고 다른 LLM을 사용하여 우리 모델의 응답을 평가할 것입니다; 그러나 공개적으로 사용 가능한 벤치마크 데이터셋을 사용하는 대신 우리만의 테스트 세트를 사용할 것입니다
- 이를 위해, 모델 응답을 `test_data` 딕셔너리에 추가하고 필요한 경우 별도의 Python 세션에서 로드하고 분석할 수 있도록 기록 보관을 위해 `"instruction-data-with-response.json"` 파일로 저장합니다
## 파인튜닝된 LLM 평가
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch07_compressed/chapter-overview-7.webp?1)
![](https://sebastianraschka.com/images/LLMs-from-scratch-images/ch07_compressed/ollama-run.webp?1)

