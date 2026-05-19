# Warp 개념

compute shader가 블록처럼 작동한다.

병렬로 일을 한다.

직렬로도 일을 할 수 있다.

GPU의 코어를 병렬 처리로 구현하는 것이 멀티스레드를 할 수 있다.

속도를 높여야한다.

→ core와 cache가 용량이 많아야 한다.

그러면, 비싸다.

GPU가 관리자가 여러 코어를 제어할 수 있다.

단순작업을 병렬적으로 하기 때문에, GPU가 빠르다.

스케줄링 이나 관리할 때는 CPU

GPU를 잘 관리하는 쪽으로 가고 있다.

예전에는 CPU는 물리, 랜더링 GPU

물리 연산도 GPU에 넘기는 경우도 있다.

GPU 안에 있는 연산 장치 streaming Multiprocessors이다.

- CPU 기술하고 차이가 있다.
- process가 여러개다.
- 멀티쓰레딩을 사용한다.

### SIMT

Single-Instruction, Multiple-Thread

여러 개의 스레드들이 같은 일을 한다.

### Warp

단위

간단하게 말하면, 쓰레드 묶음

엔비디아는 32의 묶음

GPU에서 효율적으로 한다. → 같은 일을 많이 한다.

한 warp안에 있는 쓰레드들이 같은 일을 한다.

n개의 스레드 그룹을 만든다. 그리고 하드웨어에서 warps 단위로 쪼갠다.

예) 1024개의 스레드 그룹을 만들면, 32개의 warps를 만들고

32개의 스레드 그룹은 8개의 warps를 만든다.

SIMD32를 사용한다.

멀티프로세스 하나가 warp 하나를 관리한다.

![[https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html](https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html)](Warp%20%E1%84%80%E1%85%A2%E1%84%82%E1%85%A7%E1%86%B7%20cfe45c49aaa74a3ebfaa43f7b9aa43c1/automatic-scalability.png)

[https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html](https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html)

## Grid

격자라는 뜻

thread block

![[/grid-of-thread-blocks.png]]

여러 개의 스레드들이 블록 단위로 같은 일을 한다.

블록단위로 관리한다

블록 사이들은 통신 x

블록 안에서는 통신 0

모든 블록이 끝나도록 기다릴 수 있다.

장벽을 만들 수 있다.