# Marching Cubes

density filed 또는 signedDistance filed 같은 스칼라 값들이 격자에 저장되어 있는 데이터를 삼각형 메쉬로 바꾸는 알고리즘이다.

어떤 공간의 내 사각형/육면체 내의 각 점에 대한 밀도 값들로 mesh를 생성하는 알고리즘이다.

## 2차원

![Untitled](attachments/Untitled_17.png)

흰색의 `bc[dtID]` 를 1로 하고, 블랙을 -1로 설정한다.

그 중간의 값 0을 vertex로 지정해서 선을 긋는다.

알고리즘은 엣지를 찾아서, 값의 차이가 많이 나는 곳을 찾는다.

차이의 값이 0인 곳을 찾아서, 선을 그어준다.

위의 그림은 2차원으로 선, 도형을 그릴 수 있는 패턴이 적다. 이 패턴이 3차원으로 넘어가면, 256개로 아주 많아진다.

![[https://en.wikipedia.org/wiki/Marching_cubes](https://en.wikipedia.org/wiki/Marching_cubes)](Marching%20Cubes%203665c95651e848ba8911b38f94da954e/img1.daumcdn.png)

[https://en.wikipedia.org/wiki/Marching_cubes](https://en.wikipedia.org/wiki/Marching_cubes)

위와 같은 흐름으로 어떤 한 mesh를 생성할 수 있는 알고리즘이 마로 **Marching Cubes**이다