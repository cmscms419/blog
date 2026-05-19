# Consume/Append Buffers

**Consume/Append Buffers → struct buffer + count**

위 처럼 생각하면 된다.

그리는 개수를 저장하는 count 

Append를 만들 때

buffer.Flags에 appendBuffer로 사용한다.

**Consume/Append Buffers는 거의 비슷하다.**

**Consume/Append Buffers 역할을 바꿔가면서 사용할 수 있다.**

countstaging 버퍼 : 내부적으로 가지고 있는 count를 읽어올 때 사용한다.

```cpp
Particle p = inputParticles.Consume(); // Read Consum에서 읽고
    
float3 velocity = float3(-p.pos.y, p.pos.x, 0.0) * 0.1;
p.pos += velocity * dt;
    
outputParticles.Append(p); // Write append struct에 저장
// 맨 끝에 저장
```

append struct에 몇개가 들어가 있는지는 모르지만 저장

멀티쓰레딩에서는 어디에 가져오고, 어디에 저장하는 것이 중요하다.

충돌은 없다. → 왜냐하면 내부적으로 알아서 처리해 준다.

간단하게 생각하면, Consume에서 사용하고, 비어있는 append struct에 넣어준다.

실제는 메모리 관점은 동적으로 변하는 것이 아니다. 처음에 초기화 해준대로 고정

다만 count만 변한다.