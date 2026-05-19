# bitmap

![Untitled](attachments/Untitled_17.png)

### bitmap

texture::Texture 객체를 통해 정의된 표시 객체를 관리합니다.

Texture, 디스플레이 영역, 색상, 안티에일리징 여부의 데이터를 가지고 있습니다.

### TextureFactory

testLayer에서 win32 texture를 만듭니다

texture::Texture 객체를 생성합니다.

Adapter를 통해서 가져옵니다.

Width, height 받는 텍스처 객체

이미지 파일을 받는 텍스처 객체

### GLESTexture

비트맵을 이용해 어떠한 표면의 색상을 정의하는 텍스처를 관리

GLESTexture를 사용해서 텍스처 관리