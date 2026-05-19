# Framebuffer - post processing

[https://en.wikibooks.org/wiki/OpenGL_Programming/Post-Processing](https://en.wikibooks.org/wiki/OpenGL_Programming/Post-Processing)

![Untitled](attachments/Untitled_17.png)

랜더링된 후에 적용되는 효과 → 부분적으로 맞다

fbo의 렌더링 결과를 color texture에 저장하고, fragment shader에 color로 텍스처 값을 준다.

그 결과 shader로 넘겨준 텍스처가 입혀진 판위에 그려지게 된다.

1. 직접 랜더링대신에 GPU 메모리의 버퍼로 랜더링합니다.
2. 두가지 방법
    1. 랜더링한 결과를 텍스처에 복사 ([glCopyTexSubImage2D](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glCopyTexSubImage2D.xhtml) 함수 사용)
    2. 프레임 버퍼 개체를 통해 텍스처에 직접 렌더
3. 이 텍스처를 post-processing 하는 것입니다.

off-screen 랜더링에서만 사용가능한 기술이다

책임님, 전처리에 대한 내용을 못찾았고, **Early Fragment Test**에서 test이 가능하다고 나와있습니다.