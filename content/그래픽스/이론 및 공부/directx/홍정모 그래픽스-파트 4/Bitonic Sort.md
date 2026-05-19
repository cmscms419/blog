# Bitonic Sort

정렬이 중요하다.

반투명한 물체를 만들 때, 정렬이 필요하다.

GPU에서 정렬 할 수 있다.

GPU Gems → 거의 업계 평균이다.

GPU를 sorting 할 때는 이것을 보면 좋다.

### **Bitonic Sort**

퀵 소트보다는 느리다. 하지만, 데이터가 많으면 효율이 좋다.

위키피디아를 기준으로 

→ 병렬에서 처리할 때, 좋다

→ 네트워크라는 개념으로 설명한다.

입력이 16개 일 때

가로줄이 16개 있다.

전기회로 같은 느낌이다.

화살표 있는 부분에 있는 숫자를 비교해서 큰거를 화살표 쪽으로 보낸다.

사다리타기와 비슷하다.

![Untitled](attachments/Untitled_17.png)

세로 줄을 스레드에 할당해서, 병렬로 실행할 수 있다.

```cpp
[numthreads(1024, 1, 1)] -> 제일 중요
void main(int3 gID : SV_GroupID, int3 gtID : SV_GroupThreadID,
          uint3 dtID : SV_DispatchThreadID)
{
    // 힌트: (value 말고) key로 정렬하시면 됩니다.
    uint i = dtID.x;
    uint l = i ^ j;
    
    if (l > i)
    {
        if (((i & k) == 0) && (arr[i].key > arr[l].key) ||
                ((i & k) != 0) && (arr[i].key < arr[l].key))
        {
            Element temp = arr[i];
            arr[i] = arr[l];
            arr[l] = temp;
        }
    }
}
```

numthreads → 이것은 스레드 개수이다.

compute shader를 잘 이해하고 있어야 한다.