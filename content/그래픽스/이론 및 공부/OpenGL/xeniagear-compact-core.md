# 구조

엔진 (xeniagear-compact-core)

라이프 사이클 부터 보기

콘텐츠 쪽에서 엔진을 어떻게 쓰는지 경험을 해보는게 좋음

아래 그림처럼 엔진 계층 구조 만들기

![Untitled](attachments/Untitled_17.png)

xeniagear-compact-core를 봐야합니다.

content (X)

![Untitled](attachments/Untitled%201.png)

[[Object & TypeInfo]]

[[Display & adapter]]

[[Event]]

[[  stay & Layer  ]]

[[bitmap]]

[[text]]

[[surface]]

[[renderer]]

list

앞뒤로 모두 이동이 가능한 이중연결 리스트입니다.

- 길이가 가변적입니다
- 데이터 삽입과 삭제가 용의합니다.

단점

- 랜덤 접근 X, 순차 접근만이 가능합니다.

→ 연결 리스트의 head에서부터 시작하여 해당 노드를 찾아야 하기 때문에, 검색 및 접근 속도가 배열에 비해서 느립니다.

[[Builder]] 패턴 사용됨