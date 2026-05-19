# adapter

# adapter란 무엇인가?

한 객체의 인터페이스를 다른 객체가 이해할 수 있도록 변환하는 특별한 객체입니다.

# adapter의 동작

![[/structure-object-adapter.png]]

1. adapter는 기존에 있던 객체 중 하나와 호환되는 인터페이스를 받습니다.
2. 이 인터페이스를 사용하면 기존 객체는 어댑터의 메서드들을 안전하게 호출할 수 있습니다.
3. 호출을 수신하면 어댑터는 이 요청을 두 번째 객체에 해당 객체가 예상하는 형식과 순서대로 전달합니다.

+ 양방향으로 호출을 변환할 수 있는 양방향 어댑터를 만드는 것도 가능합니다.

# 엔진에서의 adapter 패턴 사용

display_context가 adapter를 통해서, 하는 일

1. texture, surface, font 정보를 adapter를 통해서, 데이터를 가져오고 있음
2. EGL에게 swap하도록 함
3. windows 창에 접근 가능함