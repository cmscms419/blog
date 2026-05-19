# Assimp

3d modeling tools(blender같은)를 이용해서 만든, 복잡한 오브젝트의 데이터를 뽑을 수 있습니다.

### 3D modeling tools

3d model을 만드는 프로그램

→ 만든 모델에서 데이터 추출 가능

model 포맷에 들어있는 데이터

- 모든 vertex 좌표
- 법선
- 텍스처 좌표(uv 좌표계)

위의 데이터를 자동 생성합니다.

### uv-mapping

![Untitled](attachments/Untitled_17.png)

![Untitled](attachments/Untitled%201.png)

![Untitled](attachments/Untitled%202.png)

따라서 이러한 추출된 모델 파일들을 분석하여 모든 관련된 정보들을 추출하는 것이 우리의 일입니다. 

그런 다음 이 정보들을 OpenGL이 이해할 수 있는 형식으로 저장해야 합니다. 

하지만 모델 데이터를 추출할 때 가질 수 있는 파일 포맷은 아주 많이 존재합니다.

예를 들어

- Wavefront .obj 와 같은 모델 포맷
    - 모델 컬러
    - diffuse/specular map들과 같은 작은 material 정보들과 함께 모델 데이터
- XML 기반의 [Collada 파일 포맷](http://en.wikipedia.org/wiki/COLLADA) 과 같은 모델 포맷
    - light,
    - 다양한 종류의 material들
    - 애니메이션 데이터
    - 카메라
    - 완전한 scene 정보 등을 아주 광범위하게 가지고 있습니다.  → 유니티의 씬 같은 정보??

Wavefront 오브젝트 포맷 특징

- 분석하기 쉬운 모델 포맷
- Wavefront wiki에서 포맷 구조 확인해 보기

## Model loading 라이브러리 : Assimp

가장 많이 쓰이는 model importing 라이브러리는 Assimp라고 불리며 *Open Asset Import Library*를 의미합니다.

- Assimp는 모든 모델의 데이터들을 Assimp가 생성한 데이터 구조로 불러옴으로써 많은 종류의 모델 파일 포맷을 import(그리고 추출하는 것 또한 가능)할 수 있습니다.
- Assimp가 모델을 로드하기만 하면 Assimp의 데이터 구조에서 우리가 원하는 모든 데이터를 얻을 수 있습니다.
- Assimp의 데이터구조가 import된 파일 포맷의 유형과 관계없이 동일하게 유지되기 때문에 모든 다른 파일 포맷들을 추상화해줍니다.
- Assimp를 통해 모델을 import할 때 전체적인 모델을 import된 모든 모델/scene을 포함하고 있는 *scene*객체에 불러옵니다. 그런 다음 Assimp는 노드의 모음을 가지게 되는데 각 노드는 자신의 자식 모드들을 인덱싱할 index들을 가지고 있습니다.

간략화한 Assimp의 구조 모델

![](attachments/assimp_structure.png)

- Scene/model
    - 모든 데이터는 scene 객체에 포함됩니다. 또한 scene의 루트 노드에 대한 참조를 가지고 있습니다.
- 노드
    - 자식 노드들을 포함
    - mMeshes 배열 안의 데이터를 가리키는 인덱스들의 모음을 가지고 있습니다.
    - 루트 노드의 mMeshes 배열은 실제 Mesh 객체들을 가지고 있다.
    - 일반 노드의 mMeshes 배열에 들어있는 값은 오직 scene의 mesh 배열에 대한 index들만 가지고 있습니다.
- Mesh 객체
    - 렌더링하는 데에 필요한 모든 관련 데이터들을 포함합니다.
        - 오브젝트의 vertex 위치
        - 법선 벡터
        - 텍스처 좌표
        - 면
        - material
    - Mesh는 여러개의 면들을 가집니다.
- 면(Face)
    - 렌더링 기본 오브젝트(삼각형, 사각형, 점)를 나타냅니다.
    - 면은 primitive를 형성하기 위한 vertex들의 index를 가지고 있습니다.
    - vertex들과 index들이 분리되어있기 때문에 index 버퍼를 통해 렌더링하는 것을 쉽게 만들어 줍니다
- mesh는 Material 객체도 가지고 있습니다.
    - 이 객체는 오브젝트의 material 속성들을 얻기위한 여러가지 함수들을 관리합니다.
    - 텍스처 map(diffuse, specular map)과 컬러를 생각하시면 됩니다.

사용할 때 순서

1. Scene 객체에 오브젝트를 불러오는 것입니다. 각 노드들의 해당 Mesh 객체들을 재귀적(우리는 각 노드의 자식들을 재귀적으로 검색합니다)으로 얻습니다.
2. vertex 데이터와 index, material 속성들을 얻기 위해 각 Mesh 객체를 처리합니다. 

→ 그 결과는 하나의 `Model` 객체에 포함시킬 mesh 데이터의 모음이 됩니다.

**Mesh란 무엇인가**

모델링 툴에서 오브젝트를 모델링할 때 아티스트들은 일반적으로 하나의 도형을 벗어나서 전체 모델을 생성하지 않습니다. 일반적으로 각 모델은 여러개의 서브 모델/도형을 가지고 있습니다. 하나의 모델을 이루는 각각의 서브 모델/도형들은 mesh라고 불립니다. 

예시)

인간과 같은 캐릭터를 생각해 보면

아티스트들은 일반적으로 머리, 팔다리, 옷, 무기와 같은 분리되어 있는 요소들을 먼저 모델링하고 이러한 mesh들을 결합하여 결과물을 만듭니다.

하나의 mesh는 OpenGL에서 오브젝트를 그리기위해 필요한 최소한의 것을 나타냅니다(vertex 데이터, index, material 속성들). 모델은 (일반적으로) 여러 mesh들로 이루어져 있습니다.