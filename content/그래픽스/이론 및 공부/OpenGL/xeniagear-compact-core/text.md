# text

![Untitled](attachments/Untitled_17.png)

### textField

텍스트와 textFormat 객체를 통해 정의된 surface 객체를 관리합니다.

### TextFormat

텍스트 형식을 관리합니다. 텍스트의 행간 간격(leading), 글자 간격(kerning), 색상(text_color)텍스트 정렬 유형, 텍스트가 그려지는 방향 대한 정보를 가지고 있습니다.

### Font

Font가 그려지는데 사용되는 정보들을 관리합니다.
실제 구현은 application에 win32에서 이루어 집니다.
Win32에서 font를 그리기 위한 정보를 가져옵니다.
FontBridge가 가져오는 역할을 합니다.

### TextAlign

텍스트 정렬 유형
상수 값

### TextDirection

텍스트가 그려지는 방향 유형
왼쪽 -> 오른쪽으로 텍스트 그리기
오른쪽 -> 왼쪽으로 텍스트 그리기
상수 값