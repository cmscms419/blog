# renderer

![Untitled](attachments/Untitled_17.png)

### Rederer

Object를 상속받습니다.
Sprite, bitmap, TextField  랜더링을 할 수 있습니다.

### GLESrenderer

GLES 라이브러리를 통하여 화면에 그려질 수 있도록 데이터들을 처리합니다.
랜더링 되는 순서가 sprite -> bitmap -> TextField 순으로 랜더링 됩니다.

### rendererSprite()

Sprite 랜더링 시작
Stencil, Scissor, Blend 랜더링이 이루어 집니다.

### Rendererbitmap()

Sprite에 저장된 texture 랜더링이 이루어 집니다.

### Renderertextfield()

Sprite에 저장된 텍스처 랜더링이 이루어 집니다.