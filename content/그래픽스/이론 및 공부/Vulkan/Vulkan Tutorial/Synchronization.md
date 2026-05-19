# Synchronization

engine 프로젝트 작성 중에 동기화에 대해서 부족하다는 느낌을 받아 개인적으로 정리한 내용

- **Semaphores** - 여러 개의 큐 사이에서 리소스에 대한 접근을 제어하기 위해서 사용될 수 있습니다.
- **Events and barriers** - 명령 버퍼 또는 단일 큐에 제출된 명령 버퍼 시퀀스 내에서 동기화 작업에 사용된다.
- **Fences** - device(GPU)와 host(CPU) 사이의 동기화 작업에 사용된다.

![[그래픽스/이론 및 공부/Vulkan/Vulkan Tutorial/Synchronization/img1.daumcdn.png]]


![[Multi-Threading in Vulkan - Mobile, Graphics, and Gaming blog - Arm Community blogs - Arm Community](https://community.arm.com/arm-community-blogs/b/mobile-graphics-and-gaming-blog/posts/multi-threading-in-vulkan)](Synchronization%201a018a41dc6f80dd959fe38daff90d98/img1.daumcdn.png)

[Multi-Threading in Vulkan - Mobile, Graphics, and Gaming blog - Arm Community blogs - Arm Community](https://community.arm.com/arm-community-blogs/b/mobile-graphics-and-gaming-blog/posts/multi-threading-in-vulkan)

- 이벤트를 사용해서 커맨드 버퍼 내의 커맨드들 끼리의 동기화를 보장합니다.
- 세마포어를 사용해 큐 사이의 동기화를 보장합니다.
- 펜스를 사용해 호스트와 디바이스 사이의 동기화를 보장합니다.

출처:

https://lifeisforu.tistory.com/416