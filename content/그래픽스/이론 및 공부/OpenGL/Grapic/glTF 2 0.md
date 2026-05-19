# glTF 2.0

![[/gltfOverview-2.0.0b.png]]

## 4/26 질문

2번의 내용 계속 정리하기

사양의 5번 같은 경우는 최상위 문서로 부터 관련 있는것 끼리 묶기

# glTF 2.0 사양 문서의 정리

1. 머리말
    1. 이 문서의 목적
2. 소개
    1. 용어에 대한 해석 → 문서를 이해하기 위해서
    2. 이 문서에 사용된 예제(JSON 파일) 이해돕기 위해서
3. 개념
    1. glTF 2.0의 구조
    2. sence, asset, texture 같은 오브젝트에 관한 설명
4. GLB 파일 형식 사양
    1. 바이너리 파일에 대한 구조
5. 속성 참조
    1. glTF의 사양에 들어가는 참조 데이터에 대한 설명
        1. 참조 데이터의 이름
        2. 참조 데이터의 값
        3. 참조 데이터의 역할
        4. 참조 데이터가 반드시 필요하는 가에 대해서
        5. 기타 등

# 무엇인가?

[https://ko.wikipedia.org/wiki/GlTF](https://ko.wikipedia.org/wiki/GlTF)

3차원 장면과 모델을 표현하는 파일 포맷

JSON 표준을 기반으로 하고 있습니다.

크로노스 그룹의 3D Format 작업반에서 제정한 표준입니다.

효율성과 상호 운용성을 강조한 파일 포맷으로서, 실행에 필요한 부하를 최소화 하도록 설계되었다.

## 역사

2012/3

COLLADA와 WebGL을 결합하는 작업을 시작

Fabrice Robinet은 JSON 포맷에 기반한 효율적인 이진 파일을 사용하는 방식을 제안

2012년에 SIGGRAPH에서 개최한 WebGL meetup 행상에서 처음 glTF 관련 데이터 보여 주었다

초기에는 WebGL TF(WebGL Transmissions Format)이라고 했습니다.

2013/3

Cesium에서는 glTF  채택을 공식 발표하였고, 2017년 8월 10일 [3D Tiles](http://cesiumjs.org/2016/09/06/3D-Tiles-and-the-OGC/) [Archived](https://web.archive.org/web/20170818125144/http://cesiumjs.org/2016/09/06/3D-Tiles-and-the-OGC/)
 2017년 8월 18일 - [웨이백 머신](https://ko.wikipedia.org/wiki/%EC%9B%A8%EC%9D%B4%EB%B0%B1_%EB%A8%B8%EC%8B%A0)  로 [OGC Community](https://ko.wikipedia.org/w/index.php?title=Open_Geospatial_Consortium&action=edit&redlink=1) 표준으로 채택되었다. 

이 표준은 glTF 기반으로서 위치 데이터 정보, 메타데이터, 스타일 데이터를 대규모의 3차원 지형 데이터 세트로 저장하고 이를 스트리밍하는데 활용하였다.

## glTF 2.0

glTF 2.0 표준은 2017년 6월 5일, Web3D 2017 Conference 행사에서 공식 발표되었다.

# glTF

API 중립 런타임 자산 전달 형식입니다. 

3D 콘텐츠 전송 및 로드를 위한 효율적이고 확장 가능

상호 운용 가능한 형식을 제공

3D 콘텐츠 생성 도구와 최신 그래픽 애플리케이션 사이의 격차를 해소합니다.

네트워크를 통해 3D 컨텐츠를 효율적으로 전송하기 위해서

Khronos Group에서 설계 및 지정되었습니다

glTF의 핵심은 3d 모델을 포함한 Scene의 구조와 구성으로 정의된 json 파일 입니다.

## 문서화 규칙(문서의 목적)

glTF의 사양은 asset을 사용 또는 만드는 프로그램 개발자가 사용하기 위한 것을 목표로 만든 문서입니다.

# glTF의 구성

## **General**

![Untitled](attachments/Untitled_17.png)

glTF의 asset 최상위 배열간의 관계를 나타낸것입니다.

## asset

어떤 결과물 → asset

glTF의 asset에는 자신만의 속

asset은 glTF 버전을 반드시 정해야 합니다.

minVersion 속성을 정해서 asset을 로드하는데 필요한 glTF 버전을 정할 수 있습니다.

- 버전 속성
- 메타데이타 : 어떤 목적, 사용할 것인지 이름을 넣어둔 데이터입니다.
    - generator
    - copyright

```json
// asset에 필요한 데
"asset": {
				"version": "2.0",
				"generator": "collada2gltf@f356b99aef8868f74877c7ca545f2cd206b9d3b7",
				"copyright": "2017 (c) Khronos Group"
    }
```

### 구현할 때, 팁

클라이언트 구현에서는 먼저 minVersion 속성이 지정되었는지 확인하고 주 버전과 부 버전이 모두 지원되는지 확인해야 합니다. minVersion이 지정되지 않은 경우 클라이언트는 버전 속성을 확인하고 주 버전이 지원되는지 확인해야 합니다. GLB 형식을 로드하는 클라이언트는 GLB 헤더에 지정된 버전만 GLB 컨테이너 버전을 참조하므로 JSON 청크에서 minVersion 및 버전 속성도 확인해야 합니다.

## **Indices and Names**

glTF asset의 객체는 해당 배열의 index로 참조됩니다. 

bufferView는 buffer 배열에 buffer의 index를 지정하여 buffer를 참조합니다.

```json
{
    "buffers": [
        {
            "byteLength": 1024,
            "uri": "path-to.bin"
        }
    ],
    "bufferViews": [
        {
            "buffer": 0,
            "byteLength": 512,
            "byteOffset": 0
        }
    ]
}
```

여기서는 buffer와 bufferView 배열에는 각각 하나의 요소가 들어있습니다.

bufferView는 버퍼의 index를 사용해서 buffer를 참조하고 있습니다. : → `"buffer": 0`

index는 반드시 정수여야 하고, 기존 요소를 가리켜야 합니다.

index는 내부 glTF 참조에 사용되지만, name은 display 같은 프로그램별 용도로 사용됩니다.??

어떤 최상위 glTF 객체는 목적을 위해서 name 속성을 사용할 수 있습니다.

이러한 속성 값은 asset이 작성될 때 생성된 값을 포함하기 위한 것이므로 고유하다고 보장되지 않습니다.

### **Coordinate System and Units**

glTF는 오른손 좌표계를 사용합니다.

모든 선형 거리의 단위는 미터

모든 각도는 라디안 단위

+ 회전은 시계 방향

R, G, B, 색상은 [권장 ITU-R BT.709](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#bt709) 색도 좌표를 사용

![Untitled](attachments/Untitled%201.png)

## Scene

glTF 2.0 asset은 렌더링할 시각적 개체 집합인 0개 이상의 Scene을 **포함할 수 있습니다

Scene은 Scene배열로 정의 되어 있습니다.

`scene.node` 배열의 모든 노드들은 반드시 rootnode여야 합니다. 이 노드들은 반드시 어떤 노드의 `node.children` 배열에 있으면 안됩니다.

똑같은 root node가 여러개의 scene을 가질 수  있습니다.

추가적인 root-level 속성 scene(단일하지 않음)은 로드 시 배열에서 표시해야 하는 scene을 식별합니다.

scene이 정의 되진않는 경우, 클라이언트 구현은 특정한 scene을 요청될 때까지 랜더링을 지연합니다.

scene이 포함되지 않은 glTF asset은 materials 또는 mehs와 같은 개별 entities의 라이브러리로 취급되어야 합니다.

```json
// 단일 노드가 포함된 단일 scne으로 glTF asset을 정의합니다.
{
    "nodes": [
        {
            "name": "singleNode"
        }
    ],
    "scenes": [
        {
            "name": "singleScene",
            "nodes": [
                0
            ]
        }
    ],
    "scene": 0
}
```

### **Nodes and Hierarchy**

glTF assets은 노드 즉 렌더링 할 씬을 구성하는 객체로 정의할 수 있습니다.

노드는 변환 속성을 가질 수 있습니다.

노드는 노드 계층 구조로 알려진 parent-child 계층 구조로 구성되어있습니다.

parent 노드가 없는 노드를 root node라고 합니다.

노드 계층 구조는 분리된 엄격한 tree야 합니다. 즉 노드 계층 구조에는 주기(cycles)가 있으면 안되고, 각 노드에는 반드시 0 또는 1 개의 상위 노드가 있어야 합니다.

```json
{
    "nodes": [
        {
            "name": "Car",
            "children": [1, 2, 3, 4]
        },
        {
            "name": "wheel_1"
        },
        {
            "name": "wheel_2"
        },
        {
            "name": "wheel_3"
        },
        {
            "name": "wheel_4"
        }
    ]
}
```

### **Transformations**

모든 노드들은 mareix , translation, rotation, scale 속성(TRS 속성) 제공하여 local 공간 변환을 할 수 있습니다. 

translation, scale은 local 좌표계의 3D 벡터입니다.

rotation은 local 좌표계에서 퀘터니엄 단위(사원수 :**복소수를 확장해 만든 수 체계**) 값으로 XYZW이며, W값은 스칼라 값입니다.

matrix가 정의되면, TRS 속성을 분해 할 수 있습니다. (아마 T, R, S 로 나눌 수 있다는 뜻)

노드가 애니메이션의 타켓인 경우(animation.channel.target 참조됨) , TRS 속성만 존재할 수있습니다. martix는 안됩니다.

local 공간 변환 행렬을 구성하려면 TRS 속성을 행렬로 변환하고 순서대로 곱해야 합니다. T * R * S 순서로

1. 크기
2. 회전
3. 이동

노드의 전역 변환 매트릭스는 부모 노드와 자체 local 변환 매트릭스의 전역 변환 매트릭스의 곱입니다. 노드에 부모 노드가 없을 경우 전역 변환 행렬은 로컬 변환 행렬과 동일합니다.

Box 라는 이름의 노드의 예입니다

회전 및 변환이 정의되어 있습니다.

```json
{
    "nodes": [
        {
            "name": "Box",
            "rotation": [
                0,
                0,
                0,
                1
            ],
            "scale": [
                1,
                1,
                1
            ],
            "translation": [
                -17.7082,
                -11.4156,
                2.0922
            ]
        }
    ]
}
```

이 노드는 TRS 값을 사용하기 보다는 matrix 속성을 사용하여 연결된 camera가 있는 노드에 대한 변환을 의미합니

```json
{
    "nodes": [
        {
            "name": "node-camera",
            "camera": 1,
            "matrix": [
                -0.99975,
                -0.00679829,
                0.0213218,
                0,
                0.00167596,
                0.927325,
                0.374254,
                0,
                -0.0223165,
                0.374196,
                -0.927081,
                0,
                -0.0115543,
                0.194711,
                -0.478297,
                1
            ]
        }
    ]
}
```

## **Binary Data Storage**

Binary blob : 데이터베이스 관리 시스템의 하나의 객체로서 저장되는 이진 데이트의 모임

→ 이진 데이터

URI : 특정 리소스를 식별하는 통합 자원 식별자를 의미합니다

→ 식별자입니다.

buffer는 이진 blob으로 저장된 임의의 데이터입니다. 버퍼에는 geometry, animation, skin 및 images의 모든 조합이 포함될 수 있습니다.

Binary ****blob은 압축 해제를 제외하고 추가 parsing이 필요하지 않으므로 GPU 버퍼 및 텍스처를 효율적으로 생성할 수 있습니다.

glTF asset에는 버퍼 리소스가 얼마든지 있을 수 있습니다. 버퍼는 asset의 버퍼 배열에 정의됩니다.

버퍼 크기에 대한 엄격한 상한은 없지만 일부 JSON parsing가 byteLength를 올바르게 구문 분석하지 못할 수 있으므로 glTF asset은 $2^{53}$바이트보다 큰 버퍼를 사용하지 않아야 합니다. GLB 이진 chunk로 저장된 버퍼의 암묵적 제한은 $2^{32}-1$바이트입니다.

이 규격에 정의된 모든 버퍼 데이터(즉, geometry속성, geometry인덱스, sparse accessor 데이터, animation 입력 및 출력, inverse bind 매트릭스)는 작은 endian 바이트 순서를 사용해야 합니다.

parsing : 인터프리터나 컴파일러의 구성 요소 중 하나로, 입력 토큰에 내재된 자료구조를 빌드하고 문법을 검사한다.

parsing는 일련의 입력 문자로부터 토큰을 만들기 위해 별도의 [낱말 분석기](https://ko.wikipedia.org/wiki/%EB%82%B1%EB%A7%90_%EB%B6%84%EC%84%9D)를 이용하기도 한다.

다음 예제에서는 버퍼를 정의합니다. byteLength 속성은 버퍼 파일의 크기를 지정합니다. uri 속성은 버퍼 데이터에 대한 URI입니다.

```json
{
   "buffers": [
       {
           "byteLength": 102040,
           "uri": "duck.bin"
       }
   ]
}
```

참조된 리소스의 바이트 길이는 `buffer.byteLength` 속성보다 크거나 같아야 합니다.

또는 base64 인코딩의 `data` : URI를 통해 버퍼 데이터를 glTF 파일에 포함할 수 있습니다.

`data` : URI를 버퍼 저장에 사용하는 경우 해당 `mediatype`필드를 `application/octet-stream` 또는 `application/gltf-buffer`로 설정해야 합니다.

buffer view는 `byteOffset`속성에 지정된 버퍼로의 byteoffset과 버퍼 뷰의 `byteLength` 속성에 지정된 총 바이트 길이로 정의된 버퍼 내 데이터의 연속 세그먼트를 나타냅니다.

images, vertex index, vertex 속성 또는 inverse bind 행렬에 사용되는 buffer view에는 한 가지 유형의 데이터만 포함되어야 합니다. 즉, vertex index 및 vertex 속성 모두에 동일한 buffer view를 사용해서는 안 됩니다.

buffer view가 vertex index 또는 속성 접근자에 의해 사용되는 경우 요소 배열 버퍼 또는 배열 버퍼 값을 각각 사용하여`bufferView.target`을 지정해야 합니다.

아래 bufferView.target은 카메라의 투영애 정의된 enum을 사용합니다.

```json
{
    "bufferViews": [
        {
            "buffer": 0,
            "byteLength": 25272,
            "byteOffset": 0,
            "target": 34963
        },
        {
            "buffer": 0,
            "byteLength": 76768,
            "byteOffset": 25272,
            "byteStride": 32,
            "target": 34962
        }
    ]
}
```

버퍼 뷰가 정점 속성 데이터에 사용되는 경우 byteStride 속성을 가질 수 있습니다. 

이 속성은 각 정점 사이의 스트라이드를 바이트 단위로 정의합니다. 다른 유형의 데이터가 있는 버퍼 뷰는 확장에 의해 명시적으로 활성화되지 않은 경우 byteStride를 정의해서는 안 됩니다.

버퍼 및 버퍼 보기에 유형 정보가 없습니다. 파일에서 검색할 원시 데이터를 정의하기만 하면 됩니다. glTF 자산 내의 개체(메쉬, 스킨, 애니메이션)는 액세스자를 통해 버퍼 또는 버퍼 뷰에 액세스합니다.

### **GLB-stored Buffer**

glTF asset은 GLB 파일 컨테이너를 사용하여 glTF JSON과 하나의 glTF 버퍼를 하나의 파일로 패킹할 수 있습니다. 이러한 버퍼에 대한 데이터는 GLB 저장 BIN 청크를 통해 제공됩니다.

GLB 저장 BIN 청크에서 제공하는 데이터가 있는 버퍼는 버퍼 배열의 첫 번째 요소여야 하며 `buffer.uri` 속성이 정의되지 않은 상태여야 합니다. 이러한 버퍼가 있는 경우에는 빈 청크가 있어야 합니다.

버퍼 배열의 첫 번째 요소가 아닌 buffer.uri 속성이 정의되지 않은 모든 glTF 버퍼는 GLB 저장 BIN 청크를 참조하지 않으며 이러한 버퍼의 동작은 향후 확장 및 규격 버전을 수용하기 위해 정의되지 않은 상태로 유지됩니다.

BIN 청크의 바이트 길이는 GLB 패딩 요구 사항을 충족하기 위해 JSON 정의 buffer.byteLength 값보다 최대 3바이트 클 수 있습니다.

```json
청크(chunk) : 파일 형식에서 사용되는 정보의 조각, 청크에는 매개 변수(청크 유형, 주석, 크기 등)를 나타내는 해더가 포함되어 있습니다.
```

```json
{
    "buffers": [
        {
            "byteLength": 35884
        },
        {
            "byteLength": 504,
            "uri": "external.bin"
        }
  ]
}
```

### **Accessors**

mesh, skin 및 animations의 모든 이진 데이터는 버퍼에 저장되고 Accessors를 통해 검색됩니다.

Accessors는 bufferView 내에서 입력된 배열로 데이터를 검색하는 방법을 정의합니다. 

Accessors 도구는 component 유형(예: float)과 데이터 유형(예: 3D 벡터의 경우 VEC3)을 지정하며, 이들을 결합하면 각 데이터 요소에 대한 전체 데이터 유형이 정의됩니다. 요소 수는 `count` 속성을 사용하여 지정합니다. 요소는 예를 들어 vertex indices, vertex attributes, animation keyframes 등이 될 수 있습니다.

`byteOffset` 속성은 참조된 bufferView 내에서 첫 번째 데이터 요소의 위치를 지정합니다. 접근자가 정점 속성(즉, 메시 원시 또는 해당 형태의 대상에 의해 참조됨)에 사용되는 경우, 후속 데이터 요소의 위치는 `bufferView.byteStride`  속성에 의해 제어됩니다. 

Accessors가 다른 종류의 데이터(vertex indices, animation keyframes 등)에 사용되는 경우, 접근자의 데이터 요소는 꽉 채워지게 됩니다.

모든 Accessors 권한은 asset의 Accessors 권한 배열에 저장됩니다.

다음 예제에서는 두 개의 Accessors 장치를 보여 줍니다. 

첫 번째는 primitive’s indices를 검색하기 위한 스칼라 accessor 장치

두 번째는 primitive’s position data를 검색하기 위한 3-float 구성 요소 벡터 accessor 장치입니다.

```json
{
    "accessors": [
        {
            "bufferView": 0,
            "byteOffset": 0,
            "componentType": 5123,
            "count": 12636,
            "max": [
                4212
            ],
            "min": [
                0
            ],
            "type": "SCALAR"
        },
        {
            "bufferView": 1,
            "byteOffset": 0,
            "componentType": 5126,
            "count": 2399,
            "max": [
                0.961799,
                1.6397,
                0.539252
            ],
            "min": [
                -0.692985,
                0.0992937,
                -0.613282
            ],
            "type": "VEC3"
        }
    ]
}
```

### Accessor Data Types

| **`componentType`** | **Data Type** | **Signed** | **Bits** |
| --- | --- | --- | --- |
| `5120` | *signed byte* | Signed, two’s complement | 8 |
| `5121` | *unsigned byte* | Unsigned | 8 |
| `5122` | *signed short* | Signed, two’s complement | 16 |
| `5123` | *unsigned short* | Unsigned | 16 |
| `5125` | *unsigned int* | Unsigned | 32 |
| `5126` | *float* | Signed | 32 |

요소의 크기

| **`type`** | **Number of components** |
| --- | --- |
| `"SCALAR"` | 1 |
| `"VEC2"` | 2 |
| `"VEC3"` | 3 |
| `"VEC4"` | 4 |
| `"MAT2"` | 4 |
| `"MAT3"` | 9 |
| `"MAT4"` | 16 |

### **Sparse Accessors(희소 인코딩)**

배열의 희소 인코딩은 참조 배열에 대한 증분 변경을 설명할 때 조밀 인코딩보다 메모리 효율적인 경우가 많습니다. 

이것은 종종 형태 대상을 인코딩할 때 해당됩니다(일반적으로 형태 대상에서 몇 개의 변위된 정점을 설명하는 것이 모든 형태 대상 정점을 전송하는 것보다 더 효율적입니다).

표준 접근자와 유사하게 희소 접근자는 버퍼 뷰에 저장된 데이터에서 입력된 요소의 배열을 초기화합니다. `accessor.bufferView`가 정의되지 않은 경우 희소한 accessor는 크기(accessor element의 크기) *(`accessor.count`) 바이트의 0 배열로 초기화됩니다.

또한 스파스 액세스에는 초기화 값과 다른 요소를 설명하는 스파스 JSON 개체가 포함됩니다. 스파스 개체에는 다음과 같은 필수 속성이 포함되어 있습니다:

- `count`: 변위된 요소의 수. 이 숫자는 기본 액세서 요소의 수보다 커서는 **안 됩니다.**
- `indices`: 교체할 값 인덱스의 위치 및 구성 요소 유형을 설명하는 개체입니다. 인덱스는 엄격하게 증가하는 시퀀스를 형성 **해야 합니다.** 인덱스는 기본 액세서 요소의 수보다 크거나 같으면 **안 됩니다**
- `values`:  `index`에서 참조된 인덱스에 해당하는 변위된 요소의 위치를 설명하는 객체.

```json
{
    "accessors": [
        {
            "bufferView": 0,
            "byteOffset": 0,
            "componentType": 5123,
            "count": 12636,
            "type": "VEC3",
            "sparse": {
                "count": 10,
                "indices": {
                    "bufferView": 1,
                    "byteOffset": 0,
                    "componentType": 5123
                },
                "values": {
                    "bufferView": 2,
                    "byteOffset": 0
                }
            }
        }
    ]
}
```

**Data Alignment(**데이터 정렬)

**Accessors Bounds(접근자 경계)**

accessor.min 및 accessor.max 속성은 각각 구성 요소별 최소값과 최대값을 포함하는 배열입니다. 이러한 배열의 길이는 액세스 구성 요소의 수와 같아야 합니다.

glTF JSON에 저장된 값은 버퍼에 저장된 실제 최소 및 최대 이진 값과 일치해야 합니다. accessor.normalized 플래그는 이러한 속성에 영향을 주지 않습니다.

희소 접근자 최소 및 최대 속성은 희소 대체가 적용되면 최소 및 최대 구성 요소 값에 각각 해당합니다.

sparseView 또는 bufferView가 정의되지 않은 경우 min 및 max 속성에 값이 있을 수 있습니다. 이는 이진 데이터가 외부 수단(예: 확장을 통해)으로 제공되는 경우에 사용하기 위한 것입니다.

부동 소수점 구성요소의 경우 JSON 저장 최소값과 최대값은 단일 정밀 부동을 나타내며 잠재적인 경계 불일치를 방지하기 위해 사용 전에 단일 정밀도로 반올림해야 합니다.

## **Geometry**

모든 노드는 mesh 속성에 정의된 하나의 mesh를 포함할 수 있습니다. mesh는 참조된 skin물체에 제공된 정보를 사용하여 피부를 벗길 수 있습니다. 메시에는 모핑 대상이 있을 수 있습니다.

### mesh

primitives 배열에 정의 되어 있습니다.

primitive는 GPU draw 호출에 필요한 데이터에 해당합니다.

primitive는 draw 호출에 사용된 정점 속성에 해당하는 하나 이상의 속성을 지정합니다.

primitive index는 인덱스 속성도 정의합니다.

속성 및 인덱스는 해당 데이터를 포함하는 액세스에 대한 참조로 정의됩니다.

각 primitive MAX는 GPU 토폴로지 유형(예: 삼각형 세트)에 해당하는 matarial 및 mode를 지정합니다.

```json
{
    "meshes": [
        {
            "primitives": [
                {
                    "attributes": {
                        "NORMAL": 23,
                        "POSITION": 22,
                        "TANGENT": 24,
                        "TEXCOORD_0": 25
                    },
                    "indices": 21,
                    "material": 3,
                    "mode": 4
                }
            ]
        }
    ]
}
```

각 특성은 특성 개체의 속성으로 정의됩니다. 속성의 이름은 POSITION과 같이 정점 속성을 식별하는 열거된 값에 해당합니다. 속성 값은 데이터를 포함하는 액세스 장치의 인덱스입니다.

사양은 POSITION, NORMAL, TANGENT, TEXCODOR_n, COLOR_n, JONSION_n 및 WEATES_n 속성 의미를 정의합니다.

응용 프로그램별 특성 의미론은 _TEMPERATE와 같은 밑줄로 시작해야 합니다. 응용 프로그램별 특성 의미론은 부호 없는 int 구성 요소 유형을 사용하면 안 됩니다.

각 속성 의미 속성에 대한 유효한 접근자 유형 및 구성 요소 유형은 아래에 정의되어 있습니다.

| **이름** | **접근자 유형** | **구성 요소 유형** | **설명** |
| --- | --- | --- | --- |
| `POSITION` | VEC3 | *float* | XYZ 정점 위치 변위 |
| `NORMAL` | VEC3 | *float* | XYZ 정점 법선 변위 |
| `TANGENT` | VEC3 | *float* | XYZ 정점 접선 변위 |
| `TEXCOORD_n` | VEC2 | *float부호 있는 바이트* 정규화*부호 짧은* 정규화*부호 없는 바이트* 정규화*부호 없는 짧은* 정규화 | ST 텍스처 좌표 변위 |
| `COLOR_n` | VEC3VEC4 | *float부호 있는 바이트* 정규화*부호 짧은* 정규화*부호 없는 바이트* 정규화*부호 없는 짧은* 정규화 | RGB 또는 RGBA 색상 델타 |

POSITION 접근기는 최소 및 최대 속성을 정의해야 합니다.

위치, 정규 및 탄젠트 속성에 대한 변위는 스킨 또는 노드 변환과 같은 메시 정점에 영향을 미치는 변환 행렬 전에 적용해야 합니다.

기본 메시 프리미티브가 접선을 지정하지 않는 경우, 클라이언트 구현은 일반 텍스처와 관련된 업데이트된 정점 위치, 정규 및 텍스처 좌표와 함께 기본 MikkTSPACE 알고리듬을 사용하여 각 모핑 대상에 대한 접선을 계산해야 합니다.

기본 메시 프리미티브가 정규를 지정하지 않는 경우 클라이언트 구현은 각 형태 대상에 대해 평평한 정규를 계산해야 합니다. 제공된 접선과 해당 변위(있는 경우)는 무시해야 합니다.

COLOR_n 델타가 "VEC3" 유형의 액세서를 사용하는 경우 알파 성분의 값은 0.0으로 가정해야 합니다.

컬러 델타를 적용한 후 각 COLOR_0 모핑된 액세스 요소의 모든 구성 요소를 [0.0, 1.0] 범위로 클램프해야 합니다.

모든 Morph 대상 액세스 장치는 원래 프리미티브의 액세스 장치와 동일한 개수를 가져야 합니다.

모핑 대상이 있는 메쉬는 선택적 메쉬를 정의할 수도 있습니다.기본 대상의 가중치를 저장하는 가중치 속성입니다. 노드를 사용할 때는 이러한 가중치를 사용해야 합니다.가중치가 정의되지 않았습니다. 메쉬일 때.가중치가 정의되지 않았습니다. 기본 대상의 가중치는 0입니다.

다음 예제에서는 두 개의 형태 대상을 추가하여 이전 예제에서 정의한 메쉬를 형태 가능한 메쉬로 확장합니다:

```json
{
    "primitives": [
        {
            "attributes": {
                "NORMAL": 23,
                "POSITION": 22,
                "TANGENT": 24,
                "TEXCOORD_0": 25
            },
            "indices": 21,
            "material": 3,
            "targets": [
                {
                    "NORMAL": 33,
                    "POSITION": 32,
                    "TANGENT": 34
                },
                {
                    "NORMAL": 43,
                    "POSITION": 42,
                    "TANGENT": 44
                }
            ]
        }
    ],
    "weights": [0, 0.5]
}
```

형태 대상의 수는 제한되지 않습니다. 클라이언트 구현은 8개 이상의 정형화된 특성을 지원해야 합니다. 즉, 각 Morph 표적이 하나의 속성을 가질 때 8개의 Morph 표적을 지원해야 하며, 각 Morph 표적이 두 개의 속성을 가질 때 4개의 Morph 표적을 지원하거나 각 Morph 표적이 세 개 또는 네 개의 속성을 가질 때 두 개의 Morph 표적을 지원해야 합니다.

더 많은 형태화된 속성이 포함된 자산의 경우, 클라이언트 구현은 가중치가 가장 높은 형태화된 대상의 8개 속성만 사용하도록 선택할 수 있습니다.

## skin

glTF 2.0 메시는 피부 객체, joint 계층 및 지정된 정점 속성을 통해 선형 혼합 스킨을 지원합니다.

`skins`은 asset의 `skin` 배열에 저장됩니다. 
각 `skins`는 `skins`포즈를 취하기 위해 joint로 사용되는 노드의 인덱스를 나열하는 필수 joint속성과 각 joint과 동일한 공간으로 스킨을 가져오는 데 사용되는 `inverseBindMatrices` 데이터를 사용하여 접근자를 가리키는 선택적`inverseBindMatrices`속성에 의해 정의됩니다.

`joints` 의 순서는`skin.joints` 배에 의해 정의됩니다. `joints` 배열 및`inverseBindMatrices`액세스 요소의 순서와 일치해야 합니다(후자가 있는 경우). 골격 속성(있는 경우)은 조인트 계층 구조의 공통 루트인 노드 또는 공통 루트의 직접 또는 간접 상위 노드를 가리킵니다.

### **Joint Hierarchy**

`skins`메시 포즈를 제어하는 데 사용되는 조인트 계층 구조는 단순히 노드 계층 구조이며, 각 노드는 스킨의 참조에 의해 조인트로 지정됩니다.

관절 배열. 각 피부의 관절에는 공통 뿌리라고 하는 공통 모절(직접 또는 간접)이 있어야 하며, 이 모절 자체일 수도 있고 아닐 수도 있습니다. 

씬(scene) 내의 노드에서 스킨을 참조하는 경우 공통 루트가 동일한 씬(scene)에 속해야 합니다.

### **Skinned Mesh Attributes**

스킨 메시에는 스킨 계산에 사용되는 정점 속성이 있어야 합니다. JOINGS_n 속성 데이터에는 해당 피부의 관절 지수가 포함되어 있습니다. 정점에 영향을 미치는 조인트 배열. WEATES_n 속성 데이터는 조인트가 정점에 얼마나 강하게 영향을 미치는지 나타내는 가중치를 정의합니다.

피부 제거를 적용하기 위해 각 접합부에 대해 변환 행렬이 계산됩니다. 그런 다음 정점별 변환 행렬은 결합 변환 행렬의 가중 선형 합으로 계산됩니다. 기본 노드가 변환되기 전에 조인트별 역 바인딩 행렬(있는 경우)을 적용해야 합니다.

### **Instantiation**

메쉬는 `node.mesh`속성으로 인스턴스화됩니다. 동일한 메쉬가 다른 변환을 가질 수 있는 많은 노드에서 사용될 수 있습니다.

## **Texture Data**

glTF 2.0은 텍스처 액세스를 텍스처, 이미지 및 샘플러의 세 가지 개체 유형으로 구분합니다.

### **텍스처**

텍스처는 자산의 `textures`배열에 저장됩니다. `source`텍스처는 속성과 샘플러 인덱스( ) 로 표시되는 이미지 인덱스로 정의됩니다

glTF 2.0은 정적 2D 텍스처만 지원합니다.

### **이미지**

텍스처가 참조하는 이미지는 `images`자산의 배열에 저장됩니다.

각 이미지에는 다음 중 하나가 포함됩니다.

- 지원되는 이미지 형식 중 하나의 외부 파일에 대한 URI(또는 IRI) 또는
- 포함된 데이터가 있는 데이터 URI(**데이터 URI 스킴**)
- `bufferView`에 대한 참조; 이 경우 `mimeType` **반드시** 정의되어야 합니다.

클라이언트 구현은 일부 이미지의 미디어 유형을 수동으로 결정해야 할 **수도 있습니다 .** 

이러한 경우 처음 몇 바이트의 값을 확인하는 데 다음 표를 사용해야 합니다

| **매체 유형** | **패턴 길이** | **패턴 바이트** |
| --- | --- | --- |
| `image/png` | 8 | `0x89 0x50 0x4E 0x47 0x0D 0x0A 0x1A 0x0A` |
| `image/jpeg` | 3 | `0xFF 0xD8 0xFF` |

이미지 데이터는 후자가 정의될 때 `image.mimeType` 속성과 일치 **해야 합니다 .**

opengl 텍스처 좌표

![Untitled](attachments/Untitled%202.png)

PNG 또는 JPEG 이미지의 모든 색상 공간 정보(예: ICC 프로필, 의도, 감마 값 등)는 무시해야 **합니다.**

효과적인 전달 함수(인코딩)는 이미지를 참조하는 glTF 개체에 의해 정의됩니다(대부분의 경우 material에서 사용되는 텍스처임).

### **Samplers**

**Samplers**는 asset의 **sampler** 배열에 저장됩니다. 각 샘플러는 **filtering** 및 **wrapping** 모드를 지정합니다.

**Samplers** 특성은 특성 참조에 정의된 [정수 열거형](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-sampler)을 사용합니다.

클라이언트 구현은 지정된 **filtering** 모드를 따라야 합니다. 후자가 정의되지 않은 경우 클라이언트 구현은 자체적으로 기본 텍스처 **filtering** 설정을 설정할 수 있습니다.

클라이언트 구현은 지정된 **wrapping a**모드를 따라야 합니다.

### **Filtering**

필터링 모드는 텍스처의 확대 및 축소를 제어합니다.

확대 모드는 다음과 같습니다:

*Nearest*. 요청된 각 텍셀 좌표에 대해 표본 추출기는 가장 가까운 좌표를 가진 텍셀을 선택합니다. 이 프로세스를 "가장 가까운 이웃"이라고도 합니다.

Linear. 요청된 각 텍셀 좌표에 대해 샘플러는 인접한 여러 텍셀의 가중치 합을 계산합니다. 이 프로세스를 "이선형 보간"이라고도 합니다.

최소화 모드는 다음과 같습니다:

*Nearest*. 요청된 각 텍셀 좌표에 대해 샘플러는 원래 이미지에서 가장 가까운(맨하탄 거리 내) 좌표를 가진 텍셀을 선택합니다. 이 프로세스를 "가장 가까운 이웃"이라고도 합니다.

Linear. 요청된 각 텍셀 좌표에 대해 샘플러는 원본 이미지에서 인접한 여러 텍셀의 가중치 합을 계산합니다. 이 프로세스를 "이선형 보간"이라고도 합니다.

*Nearest-mipmap-nearest*. 요청된 각 텍셀 좌표에 대해 샘플러는 먼저 원본 이미지의 미리 축소된 버전 중 하나를 선택한 다음 해당 이미지에서 가장 가까운(맨하탄 거리에 있는) 좌표를 가진 텍셀을 선택합니다.

*Linear-mipmap-nearest*. 요청된 각 텍셀 좌표에 대해 샘플러는 먼저 원본 이미지의 미리 축소된 버전 중 하나를 선택한 다음, 이 이미지에서 인접한 여러 텍셀의 가중치 합을 계산합니다.

*Nearest-mipmap-linear*. 요청된 각 텍셀 좌표에 대해 샘플러는 먼저 원본 영상의 사전 최소화된 두 버전을 선택하고 각 이미지에서 가장 가까운(맨하탄 거리 내) 좌표를 가진 텍셀을 선택한 다음 이 두 중간 결과 사이에 최종 선형 보간을 수행합니다.

*Linear-mipmap-linear*. 요청된 각 텍셀 좌표에 대해 샘플러는 먼저 원본 이미지의 사전 최소화된 두 버전을 선택하고 각 버전에서 인접한 여러 텍셀의 가중치 합계를 계산한 다음 이 두 중간 결과 사이에 최종 선형 보간을 수행합니다. 이 프로세스를 "삼선 보간"이라고도 합니다.

mipmap 모드를 제대로 지원하려면 클라이언트 구현에서 런타임에 mipmap을 생성해야 합니다. 런타임 mipmap 생성이 불가능한 경우 클라이언트 구현은 다음과 같이 최소화 필터링 모드를 재정의해야 합니다:

| **밉맵 축소 모드** | **폴백 모드** |
| --- | --- |
| *Nearest-mipmap-nearest
Nearest-mipmap-linear* | *Nearest* |
| Linear-mipmap-nearest
Linear-mipmap-linear | *Linear* |

### **Wrapping**

TEXCOORD_n 특성 값을 통해 제공되는 정점별 텍스처 좌표는 이미지 크기에 대해 정규화됩니다(정규화된 액세스 또는 속성과 혼동하지 않도록 후자는 데이터 인코딩만 참조). 즉, (0.0, 0.0)의 텍스처 좌표 값은 첫 번째(왼쪽 위) 영상 픽셀의 시작을 가리키고, (1.0, 1.0)의 텍스처 좌표 값은 마지막(오른쪽 아래) 영상 픽셀의 끝을 가리킵니다.

## **Materials**

glTF는 PBR(Physical Based Rendering)에서 널리 사용되는 material 표현을 기반으로 하는 공통 매개변수 집합을 사용하여 재료를 정의합니다. 

구체적으로 glTF는 metallic-roughness material model을 사용합니다. 이 선언적인 materials 표현을 사용하면 플랫폼 전체에서 glTF 파일을 일관되게 렌더링할 수 있습니다.

### **Metallic-Roughness Material**

metallic-roughness material model과 관련된 모든 매개변수는 재료 객체의 pbrMetalRoughness 속성에 정의됩니다.

다음 예는 **Metallic-Roughness** 매개변수를 사용하여 금과 같은 재료를 정의하는 방법을 보여줍니다:

```json
{
    "materials": [
        {
            "name": "gold",
            "pbrMetallicRoughness": {
                "baseColorFactor": [ 1.000, 0.766, 0.336, 1.0 ],
                "metallicFactor": 1.0,
                "roughnessFactor": 0.0
            }
        }
    ]
}
```

- base color - material의 기본 색상.
- metalness - material의 금속성; 값의 범위는 `0.0`(비금속) 에서 `1.0`(금속)까지입니다.
- roughness - material의 거칠기 0.0(부드럽고) ~ 1.0(거친)

기본 *색상* 텍스처는 [sRGB 광전자 전송 함수](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#srgb) 로 인코딩된 8비트 값을 포함해야 **하므로** RGB 값은 계산에 사용되기 전에 실제 선형 값으로 디코딩되어야 합니다 **.** 올바른 필터링을 달성하려면 선형 보간을 수행하기 전에 전달 함수를 디코딩 **해야 합니다** .

금속성 및 거칠기 속성에 대한 텍스처는 `metallicRoughnessTexture` 라는 단일 텍스처로 함께 압축됩니다 . *녹색* 채널 에는 `Roughness`값이 포함되고 *파란색*  채널에는 `metallic`값이 포함됩니다. 이 텍스처는 선형 전달 함수로 인코딩해야 하며 **채널당** 8비트 이상을 사용할 수 있습니다.

예를 들어, 8비트 RGBA 값이 `[64, 124, 231, 255]`에서 샘플링되고 로 주어진다고 `baseColorTexture`가정합니다 . 그런 다음 최종 *기본 색상* 값은 (전달 함수를 디코딩하고 인수를 곱한 후)입니다.

`baseColorFactor[0.2, 1.0, 0.7, 1.0]`

`[0.051 * 0.2, 0.202 * 1.0, 0.799 * 0.7, 1.0 * 1.0] = [0.0102, 0.202, 0.5593, 1.0]`

재료 속성 외에도 프리미티브가 속성 시맨틱 속성을 사용하여 정점 색상을 지정하는 경우 이 값은 *기본 색상*`COLOR_0` 에 대한 추가 선형 승수 역할을 합니다 .

양방향 반사율 분포 함수(BRDF) 자체의 구현은 장치 성능 및 리소스 제약에 따라 달라질 **수 있습니다.** BRDF 계산에 대한 자세한 내용은 [부록 B를](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#appendix-b-brdf-implementation) 참조하십시오 .

### 3.9.3. 추가 텍스처

재료 정의는 glTF 확장을 통해 제공될 수 있는 다른 재료 모델뿐만 아니라 금속 거칠기 재료 모델에도 사용할 수 있는 **추가 텍스처를 제공합니다.**

다음 추가 텍스처가 지원됩니다.

- **normal** : 탄젠트 공간 노멀 텍스처. 텍스처는 탄젠트 공간에서 법선 벡터의 XYZ 구성 요소를 선형 전달 함수로 저장된 RGB 값으로 인코딩합니다. 일반 텍스처는 어쨌든 사용되지 않는 *알파* 채널을 포함하면 **안 됩니다 .** *역* 양자화 후 텍셀 값은 *다음* 과 같이 매핑 *되어야* **합니다**.
    - *red*
    [0.0 .. 1.0] to X [-1 .. 1]
    - *green*
    [0.0 .. 1.0] to Y [-1 .. 1]
    - *blue*
    (0.5 .. 1.0] maps to Z (0 .. 1].
        - 일반 텍스처는 0.5보다 작거나 같은 파란색 값을 포함하면 안 됩니다. → [https://www.youtube.com/watch?v=Y3rn-4Nup-E](https://www.youtube.com/watch?v=Y3rn-4Nup-E)
        - 법선 벡터가 항상 수직이고, 나머지 부분은 필요없다. 왜냐하면 0~0.5 사이 값으로 다 계산이 가능하기 때문입니다.
- 이 매핑은 sampledValue * 2.0 - 1.0 계산됩니다.

일반 텍스처에 대한 텍스처 바인딩은 일반 벡터의 X 및 Y 구성 요소를 선형으로 스케일링하는 스칼라 값을 추가로 포함할 수 있습니다**.**

법선 벡터는 조명 방정식에 사용되기 전에 정규화되어야 합니다 **.** 스케일링을 사용하면 스케일링 후에 벡터 정규화가 발생합니다.

- **occlusion** : **occlusion** 텍스처. 주변 소스로부터 간접 조명을 적게 받는 영역을 나타냅니다. 직접 조명은 영향을 받지 않습니다. *텍스처의 빨간색* 채널 은 `0.0`완전히 가려진 영역(간접 조명 없음)을 의미하고 가려지지 않은 영역(완전 간접 조명)을 의미하는 폐색 값을 인코딩합니다 `1.0`. 다른 텍스처 채널(있는 경우)은 폐색에 영향을 주지 않습니다.
- 
    
    ![Untitled](attachments/Untitled%203.png)
    
    오클루전 맵에 대한 텍스처 바인딩은 선택적으로 오클루전 효과를 줄이는 데 사용되는 스칼라 값을 포함할 수 있습니다( **MAY) .** `strength`존재하는 경우 오클루전 값에 `1.0 + strength * (occlusionTexture - 1.0)`.
    
- **emissive** : **발광 텍스처**와 요소는 재질에서 방출되는 빛의 색상과 강도를 제어합니다. 텍스처는 [sRGB 광전자 전송 함수](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#srgb) 로 인코딩된 8비트 값을 포함해야 하므로 **RGB** 값은 계산에 사용되기 전에 실제 선형 값으로 디코딩되어야 합니다 **.** 올바른 필터링을 달성하려면 선형 보간을 수행하기 전에 전달 함수를 디코딩 **해야 합니다** .
    
    물리적 조명 단위가 필요한 구현의 경우 이미시브 텍스처와 요소의 곱셈 곱에 대한 단위는 제곱미터당 칸델라( **cd/m 2** )이며 때로는 *니트* 라고도 합니다 .
    
    |  | 구현 참고 사항
    값은 평방 미터당 지정되기 때문에 표면을 따라 지정된 지점의 밝기를 나타냅니다. 그러나 실제 조명 단위에서 렌더링된 픽셀의 밝기로의 정확한 변환에는 카메라의 노출 설정에 대한 지식이 필요하며 glTF 확장에 의해 달리 정의되지 않는 한 구현 세부 정보로 남아 있습니다.
    많은 렌더링 엔진은 의 이미시브 팩터가 `1.0`완전히 노출된 픽셀을 초래한다고 가정하여 이 계산을 단순화합니다. |
    | --- | --- |

다음 예는 `pbrMetallicRoughness`매개변수와 추가 텍스처를 사용하여 정의된 재질을 보여줍니다.

```json
{
    "materials": [
        {"name": "Material0",
            "pbrMetallicRoughness": {
                "baseColorFactor": [ 0.5, 0.5, 0.5, 1.0 ],
                "baseColorTexture": {
                    "index": 1,
                    "texCoord": 1
                },"metallicFactor": 1,
                "roughnessFactor": 1,
                "metallicRoughnessTexture": {
                    "index": 2,
                    "texCoord": 1
                }
            },"normalTexture": {
                "scale": 2,
                "index": 3,
                "texCoord": 1
            },"emissiveFactor": [ 0.2, 0.1, 0.0 ]
        }
    ]
}
```

클라이언트 구현이 리소스 바인딩되고 정의된 모든 텍스처를 지원할 수 없는 경우 다음 우선 순위에 따라 이러한 추가 텍스처를 지원 **해야 합니다(SHOULD ).** 리소스 바운드 구현은 텍스처를 아래에서 위로 떨어뜨려야 **합니다(SHOULD ).**

| Texture | **기능이 지원되지 않을 때 렌더링 영향** |
| --- | --- |
| Normal | 형상은 제작된 것보다 덜 상세하게 나타납니다. |
| Occlusion | 더 어둡게 하려는 영역에서 모델이 더 밝게 나타납니다. |
| Emissive | 조명이 있는 모델은 켜지지 않습니다. 예를 들어 자동차 모델의 헤드라이트는 켜지는 대신 꺼집니다. |

### 3.9.4. 알파 커버리지(투명도)

속성 `alphaMode`은 알파 값이 해석되는 방식을 정의합니다. 알파 값은 금속 거칠기 재료 모델의 *기본 색상 의 네 번째 구성 요소에서 가져옵니다.*

`alphaMode`다음 값 중 하나일 수 있습니다.

- `OPAQUE`렌더링된 출력은 완전히 불투명하며 모든 알파 값은 무시됩니다.
- `MASK`*렌더링된 출력은 알파 값과 지정된 알파 컷오프* 값 에 따라 완전히 불투명하거나 완전히 투명합니다 . 가장자리의 정확한 모양은 "Alpha-to-Coverage"와 같은 구현 관련 기술의 영향을 받을 수 있습니다 **.**
- `BLEND`[렌더링된 출력은 디지털 이미지 합성](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#compositing) 에 설명된 대로 "over" 연산자를 사용하여 배경과 결합됩니다 .

alphaMode가 MASK로 설정된 경우 alphaCutoff 속성은 컷오프 임계값을 지정합니다. 알파 값이 알파 컷오프 값보다 크거나 같으면 완전히 불투명한 것으로 렌더링되고, 그렇지 않으면 완전히 투명한 것으로 렌더링됩니다. alphaCutoff 값은 다른 모드에서는 무시됩니다.

### 3.9.5. 양면의(face culling 하고 상관있음)

`doubleSided` 의 속성은 재질이 양면인지 여부를 지정합니다.

이 값이 false이면 후면 컬링이 활성화됩니다. 즉, 전면 삼각형만 렌더링됩니다.

이 값이 true이면 뒷면 컬링이 비활성화되고 양면 조명이 활성화됩니다. 뒷면은 조명 방정식이 평가되기 전에 법선이 반전되어야 합니다 **.**

### 3.9.6. 기본 재료

메쉬가 재질을 지정하지 않을 때 사용되는 기본 재질은 속성이 지정되지 않은 재질로 정의됩니다. 모든 기본값이 [`material`](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-material)적용됩니다.

|  | 구현 참고 사항
이 재질은 빛을 발산하지 않으며 장면에 일부 조명이 없으면 검은색이 됩니다. |
| --- | --- |

### 3.9.7. 포인트 및 라인 재료

*이 사양은 삼각형이 아닌 프리미티브(예: 점* 또는 *선* ) 의 크기나 스타일을 정의하지 않으며 애플리케이션은 이러한 프리미티브를 적절하게 렌더링하기 위해 다양한 기술을 사용할 수 있습니다**.** 그러나 일관성을 위해 다음 규칙을 **권장합니다** .

- 점과 선은 뷰포트 공간에서 너비가 1픽셀이어야 합니다**.**
- `NORMAL`및 `TANGENT`속성이 있는 점 또는 선은 일반 텍스처를 포함한 표준 조명으로 렌더링해야 합니다**.**
- 점 또는 선의 속성에 `NORMAL`는 있지만 `TANGENT`은 없는 표준 조명으로 렌더링되어야 하지만 재료의 일반 텍스처는 무시해야 합니다**.**
- `NORMAL`속성이 없는 포인트 또는 라인은 조명 없이 렌더링되어야 **하며 대신** *기본 색상* 값(위에서 정의된 대로, `COLOR_0`존재하는 경우 곱함)과 *이미시브* 값 의 합계를 사용해야 합니다 .

### 3.10. 카메라

### 3.10.1. 개요

카메라는 asset의 `cameras`배열에 저장됩니다. 각 카메라는 `type`투영 유형(원근 또는 직교)을 지정하는 속성과 세부 정보를 정의하는 `perspective`또는 `orthographic` 속성을 정의합니다. 카메라는 `node.camera`속성을 사용하여 노드 내에서 인스턴스화됩니다.

카메라 개체는 뷰 공간에서 클립 공간으로 장면 좌표를 변환하는 투영 행렬을 정의합니다.

카메라 인스턴스를 포함하는 노드는 장면 좌표를 전역 공간에서 뷰 공간으로 변환하는 뷰 매트릭스를 정의합니다.

### 3.10.2. 매트릭스 보기

로컬 +X 축이 오른쪽에 있고

"렌즈"가 로컬 -Z 축을 향하며 

카메라 상단이 로컬 +Y 축에 정렬

뷰 매트릭스는 스케일링이 무시된 카메라를 포함하는 노드의 전역 변환에서 파생됩니다. 노드의 전역 변환이 ID인 경우 카메라의 위치는 원점입니다.

### 3.10.3. 투영 행렬

### 3.10.3.1. 개요

투영은 원근 또는 직교일 수 있습니다.

원근 투영에는 유한과 무한의 두 가지 하위 유형이 있습니다. 속성이 정의되지 않은 경우 `zfar`카메라는 무한 투영을 정의합니다. 그렇지 않으면 카메라가 유한 투영을 정의합니다.

다음 예제에서는 Y 시야, 종횡비 및 클리핑 정보에 대해 제공된 값을 사용하여 두 개의 원근 카메라를 정의합니다.

```json
{
    "cameras": [
        {"name": "Finite perspective camera",
            "type": "perspective",
            "perspective": {
                "aspectRatio": 1.5,
                "yfov": 0.660593,
                "zfar": 100,
                "znear": 0.01
            }
        },
        {"name": "Infinite perspective camera",
            "type": "perspective",
            "perspective": {
                "aspectRatio": 1.5,
                "yfov": 0.660593,
                "znear": 0.01
            }
        }
    ]
}
```

클라이언트 구현은 다음 프로젝션 매트릭스를 사용해야 **합니다(SHOULD ).**

### 3.10.3.2. 무한 원근 투영

[https://www.princetoninstruments.com/learn/camera-fundamentals/field-of-view-and-angular-field-of-view](https://www.princetoninstruments.com/learn/camera-fundamentals/field-of-view-and-angular-field-of-view)

- `a`에서 설정한 시야의 종횡비(높이에 대한 너비) `camera.perspective.aspectRatio`또는 뷰포트의 종횡비입니다.
- `y`에 의해 설정된 라디안 단위의 수직 시야입니다 `camera.perspective.yfov`.
- `n`에 의해 설정된 근거리 클리핑 평면까지의 거리입니다 `camera.perspective.znear`.

그러면 프로젝션 매트릭스는 다음과 같이 정의된다.

![Untitled](attachments/Untitled%204.png)

제공된 카메라의 종횡비가 뷰포트의 종횡비와 일치하지 않는 경우 클라이언트 구현은 뷰포트를 채우기 위해 자르거나 균일하지 않은 크기 조정("스트레칭")을 수행하면 **안 됩니다( SHOULD NOT).**

### 3.10.3.3. 유한 원근 투영

허락하다

- `a`에서 설정한 시야의 종횡비(높이에 대한 너비) `camera.perspective.aspectRatio`또는 뷰포트의 종횡비입니다.
- `y`에 의해 설정된 라디안 단위의 수직 시야입니다 `camera.perspective.yfov`.
- `f`에 의해 설정된 원거리 클리핑 평면까지의 거리입니다 `camera.perspective.zfar`.
- `n`에 의해 설정된 근거리 클리핑 평면까지의 거리입니다 `camera.perspective.znear`.

그러면 프로젝션 매트릭스는 다음과 같이 정의된다.

![Untitled](attachments/Untitled%205.png)

제공된 카메라의 종횡비가 뷰포트의 종횡비와 일치하지 않는 경우 클라이언트 구현은 뷰포트를 채우기 위해 자르거나 균일하지 않은 크기 조정("스트레칭")을 수행하면 **안 됩니다( SHOULD NOT).**

### 3.10.3.4. 직교 투영

허락하다

- `r`에 의해 설정된 직교 너비의 절반이어야 합니다 `camera.orthographic.xmag`.
- `t`에 의해 설정된 직교 높이의 절반이어야 합니다 `camera.orthographic.ymag`.
- `f`에 의해 설정된 원거리 클리핑 평면까지의 거리입니다 `camera.orthographic.zfar`.
- `n`에 의해 설정된 근거리 클리핑 평면까지의 거리입니다 `camera.orthographic.znear`.

그러면 프로젝션 매트릭스는 다음과 같이 정의된다.

![Untitled](attachments/Untitled%206.png)

`r / t`뷰포트의 종횡비와 일치하지 않는 경우 클라이언트 구현은 뷰포트를 채우기 위해 자르거나 균일하지 않은 크기 조정("스트레칭")을 수행하면 **안 됩니다( SHOULD NOT).**

### 3.11. 애니메이션

glTF는 노드 변환의 키 프레임 애니메이션을 통해 joint 및 skin 처리된 애니메이션을 지원합니다.

key frame data는 버퍼에 저장되고 접근자를 사용하여 애니메이션에서 참조됩니다.

glTF 2.0은 유사한 방식으로 인스턴스화된 모프 타겟의 애니메이션도 지원합니다.

`animations`모든 애니메이션은 asset의 배열 에 저장됩니다 . 

애니메이션은 채널 집합( `channels`속성)과 키 프레임 데이터 및 보간 방법( `samplers`속성)으로 접근자를 지정하는 샘플러 집합 으로 정의됩니다.

다음 예는 예상되는 애니메이션 사용법을 보여줍니다.

```json
{
    "animations": [
        {"name": "Animate all properties of one node with different samplers",
            "channels": [
                {"sampler": 0,
                    "target": {
                        "node": 1,
                        "path": "rotation"
                    }
                },
                {"sampler": 1,
                    "target": {
                        "node": 1,
                        "path": "scale"
                    }
                },
                {"sampler": 2,
                    "target": {
                        "node": 1,
                        "path": "translation"
                    }
                }
            ],"samplers": [
                {"input": 4,
                    "interpolation": "LINEAR",
                    "output": 5
                },
                {"input": 4,
                    "interpolation": "LINEAR",
                    "output": 6
                },
                {"input": 4,
                    "interpolation": "LINEAR",
                    "output": 7
                }
            ]
        },
        {"name": "Animate two nodes with different samplers",
            "channels": [
                {"sampler": 0,
                    "target": {
                        "node": 0,
                        "path": "rotation"
                    }
                },
                {"sampler": 1,
                    "target": {
                        "node": 1,
                        "path": "rotation"
                    }
                }
            ],"samplers": [
                {"input": 0,
                    "interpolation": "LINEAR",
                    "output": 1
                },
                {"input": 2,
                    "interpolation": "LINEAR",
                    "output": 3
                }
            ]
        },
        {"name": "Animate two nodes with the same sampler",
            "channels": [
                {"sampler": 0,
                    "target": {
                        "node": 0,
                        "path": "rotation"
                    }
                },
                {"sampler": 0,
                    "target": {
                        "node": 1,
                        "path": "rotation"
                    }
                }
            ],"samplers": [
                {"input": 0,
                    "interpolation": "LINEAR",
                    "output": 1
                }
            ]
        },
        {"name": "Animate a node rotation channel and the weights of a Morph Target it instantiates",
            "channels": [
                {"sampler": 0,
                    "target": {
                        "node": 1,
                        "path": "rotation"
                    }
                },
                {"sampler": 1,
                    "target": {
                        "node": 1,
                        "path": "weights"
                    }
                }
            ],"samplers": [
                {"input": 4,
                    "interpolation": "LINEAR",
                    "output": 5
                },
                {"input": 4,
                    "interpolation": "LINEAR",
                    "output": 6
                }
            ]
        }
    ]
}
```

*Channels은* 키 프레임 애니메이션의 출력 값을 계층의 특정 노드에 연결합니다. 

채널의 `sampler`속성에는 포함하는 애니메이션 배열에 있는 샘플러 중 하나의 인덱스가 포함됩니다. `target`속성 은 해당 속성을 사용하여 애니메이션을 적용할 노드와 를 사용하여 애니메이션을 적용할 노드의 속성을 식별하는 개체입니다 . 애니메이션이 적용되지 않은 속성은 애니메이션 중에 해당 값을 유지해야 합니다 **(MUST) .**

sampler → 명령하는 놈

`node` 가 정의되지 않은 경우 채널을 무시해야 **합니다**

유효한 경로 이름은 `"translation"`, `"rotation"`, `"scale"`및 `"weights"` 입니다.

모프 대상이 있는 메시를 포함하지 않는 노드는 `"weights"`경로로 대상을 지정하면 안 됩니다 **(MUST NOT)** .

하나의 애니메이션 내에서 각 대상(노드와 경로의 조합)을 두 번 이상 사용해서는 **안 됩니다 .**

|  | 구현 참고 사항
이렇게 하면 하나의 대상이 둘 이상의 겹치는 샘플러에 의해 영향을 받을 때 잠재적인 모호성을 방지할 수 있습니다. |
| --- | --- |

각 애니메이션의 **샘플러는**`input` /`output` 쌍 을 정의합니다. 선형 시간을 초 단위로 나타내는 부동 소수점 스칼라 값 집합입니다. 및 애니메이션 속성을 나타내는 벡터 또는 스칼라 세트. 모든 값은 버퍼에 저장되고 접근자를 통해 액세스됩니다. 출력 액세서 유형은 아래 표를 참조하십시오. 키 간의 보간은 속성에 지정된 보간 방법을 사용하여 수행됩니다 `interpolation`. 지원되는 `interpolation`값은 `LINEAR`, `STEP`및 입니다 `CUBICSPLINE`. 보간 모드에 대한 추가 정보는 [부록 C를](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#appendix-c-interpolation) 참조하십시오 .

각 샘플러의 입력은 `t = 0`상위 항목의 시작으로 정의된 에 상대적입니다 `animations`. 제공된 입력 범위 전후에 출력은 입력 범위의 가장 가까운 끝으로 고정되어야 합니다 **.**

|  | 구현 참고 사항
예를 들어 애니메이션에 대한 가장 초기 샘플러 입력이 인 경우 `t = 10`클라이언트 구현은 `t = 0`사용 가능한 첫 번째 출력 값으로 고정된 출력으로 해당 애니메이션 채널의 재생을 시작해야 합니다. |
| --- | --- |

주어진 애니메이션 내의 샘플러는 다른 입력을 가질 **수 있습니다** .

| **`channel.path`** | **접근자 유형** | **구성 요소 유형** | **설명** |
| --- | --- | --- | --- |
| `"translation"` | `"VEC3"` | float | XYZ 변환 벡터 |
| `"rotation"` | `"VEC4"` | float부호 있는 바이트 정규화 부호없는 바이트 정규화부호 짧은 정규화부호 없는 짧은 정규화 | XYZW 회전 쿼터니언 |
| `"scale"` | `"VEC3"` | float | XYZ 축척 벡터 |
| `"weights"` | `"SCALAR"` | float부호 있는 바이트 정규화 부호없는 바이트 정규화부호 짧은 정규화부호 없는 짧은 정규화 | 모프 타겟의 가중치 |

구현은 다음 방정식을 사용하여 정규화된 정수에서 실제 부동 소수점 값을 디코딩해야 하며 그 **반대** 의 경우도 마찬가지입니다.`fc`

| **`accessor.componentType`** | **int-to-float** | **float-to-int** |
| --- | --- | --- |
| *부호 있는 바이트* | `f = max(c / 127.0, -1.0)` | `c = round(f * 127.0)` |
| *부호 없는 바이트* | `f = c / 255.0` | `c = round(f * 255.0)` |
| *짧은 서명* | `f = max(c / 32767.0, -1.0)` | `c = round(f * 32767.0)` |
| *서명되지 않은 짧은* | `f = c / 65535.0` | `c = round(f * 65535.0)` |

애니메이션 샘플러의 `input`접근자는 해당 및 속성이 정의되어 있어야 **합니다** .`minmax`

|  | 구현 참고 사항
Autodesk 3ds Max 또는 Maya의 시간 왜곡과 같은 비선형 시간 입력이 있는 애니메이션은 glTF 애니메이션으로 직접 표현할 수 없습니다. glTF는 런타임 형식이며 비선형 시간 입력은 런타임에 계산하는 데 비용이 많이 듭니다. 내보내기 구현은 정확한 표현을 위해 비선형 시간 애니메이션을 선형 입력 및 출력으로 샘플링해야 합니다. |
| --- | --- |

모프 대상 애니메이션 프레임은 애니메이션된 모프 대상의 대상 수와 동일한 길이의 스칼라 시퀀스로 정의됩니다. 이러한 스칼라 시퀀스는 최종 크기가 애니메이션 프레임 수를 곱한 모프 대상 수와 동일한 출력 액세서의 단일 스트림으로 종단 간 놓여 있어야 합니다 **.**

모프 대상 애니메이션은 본질적으로 희박합니다. 모프 대상 애니메이션 저장을 위해 [희소 접근자를 사용하는 것을 고려하십시오.](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#sparse-accessors) 보간 에 사용하면 `CUBICSPLINE`접선(ak , b k ) 및 값(v k )이 키프레임 내에서 그룹화됩니다.

1 , a 2 ,... an ,v 1 ,v 2 ,... vn , b 1 ,b 2 ,... bn

보간 모드에 대한 추가 정보는 [부록 C를](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#appendix-c-interpolation) 참조하십시오 .

스킨 애니메이션은 스킨의 관절 계층 구조에서 관절을 애니메이션하여 달성됩니다.

### 3.12. 확장명 지정

glTF는 기본 형식을 새로운 기능으로 확장할 수 있는 확장 메커니즘을 정의합니다. 모든 glTF 개체는 다음 예제와 같이 선택적 `extensions` 속성을 가질 **수 있습니다.**

```json
{
    "material": [
        {"extensions": {
                "KHR_materials_sheen": {
                    "sheenColorFactor": [
                        1.0,
                        0.329,
                        0.1
                    ],"sheenRoughnessFactor": 0.8
                }
            }
        }
    ]
}
```

glTF 자산에 사용되는 모든 확장은 최상위 배열 객체에 나열되어야 합니다 **.**`extensionsUsed` 예:

```json
{
    "extensionsUsed": [
        "KHR_materials_sheen",
        "VENDOR_physics"
    ]
}
```

자산을 로드 및/또는 렌더링하는 데 필요한 모든 glTF 확장은 최상위 배열에 나열되어야 합니다( **예**`extensionsRequired` :

```json
{
    "extensionsRequired": [
        "KHR_texture_transform"
    ],"extensionsUsed": [
        "KHR_texture_transform"
    ]
}
```

`extensionsRequired`의 하위 집합입니다 `extensionsUsed`. 의 모든 값은 에도 존재해야 `extensionsRequired` **합니다**`extensionsUsed` .

# GLB 파일 형식

glTF는 사용하기 위한 옵션이 2개가 있습니다.

- glTF JSON은 외부 binary data(geometry, key frames, skins) 및 이미지를 가리킵니다.
- glTF JSON은 데이터 URI를 사용하여 base64로 인코딩된 이진 데이터 및 이미지 인라인을 포함합니다.

따라서 glTF 파일을 로드하려면 일반적으로 모든 이진 데이터를 가져오기 위한 별도의 요청이나 base64 인코딩으로 인한 추가 공간이 필요합니다. 

Base64 인코딩은 디코딩을 위해 추가 처리가 필요하며 파일 크기를 증가시킵니다(인코딩된 리소스의 경우 ~33%). 

전송 계층 gzip은 파일 크기 증가를 완화하지만 압축 해제 및 디코딩은 여전히 상당한 로딩 시간을 추가합니다.

이 파일 크기 및 처리 오버헤드를 방지하기 위해 JSON, 버퍼 및 이미지를 포함한 glTF 자산을 단일 바이너리 blob에 저장할 수 있는 컨테이너 형식인 Binary glTF*가 도입되었습니다.*

Binary glTF asset은 여전히 외부 리소스를 참조할 수 있습니다. 예를 들어 이미지를 별도의 파일로 유지하려는 애플리케이션은 이미지를 제외하고 장면에 필요한 모든 것을 Binary glTF에 포함할 수 있습니다.

## Binary glTF 구조

바이너리 glTF(예를 들어 파일일 수 있음)는 다음과 같은 구조를 갖습니다.

- *헤더* 라고 하는 12바이트 프리앰블 .
- JSON 콘텐츠 및 이진 데이터를 포함하는 하나 이상의 *청크입니다 .*

JSON을 포함하는 청크 *는* 평소와 같이 외부 리소스를 참조할 **수 있으며 (MAY) 다른** *청크* 내에 저장된 리소스도 참조할 수 있습니다 .

### 4.3. 파일 확장자 및 미디어 유형

Binary glTF와 함께 사용할 파일 확장자는 `.glb`.

등록된 미디어 유형은 입니다 `model/gltf-binary`.

### 4.4. 바이너리 glTF 레이아웃

### 4.4.1. 개요

이진 glTF는 리틀 엔디안입니다. 아래 그림은 바이너리 glTF 자산의 예를 보여줍니다.

![Untitled](attachments/Untitled%207.png)

[[]]

그림 8. 바이너리 glTF 레이아웃

### 4.4.2. 머리글

12바이트 헤더는 세 개의 4바이트 항목으로 구성됩니다.

```json
uint32 magic
uint32 version
uint32 length
```

- `magic` **반드시** `0x46546C67` 같아야 합니다. ASCII 문자열이며 `glTF`데이터를 Binary glTF로 식별하는 데 사용할 수 있습니다.
- `version`Binary glTF 컨테이너 형식의 버전을 나타냅니다. 이 사양은 버전 2를 정의합니다.
    
    GLB 형식을 로드하는 클라이언트 구현은 GLB 헤더에 지정된 버전이 GLB 컨테이너 버전만 참조하므로 JSON 청크의 [자산 버전 속성](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#asset) 도 확인 **해야 합니다 .**
    
- `length`*헤더* 및 모든 *청크를* 포함한 바이너리 glTF의 총 길이( 바이트)입니다.

### 4.4.3. 청크

### 4.4.3.1. 개요

각 청크의 구조는 다음과 같습니다.

```json
uint32 chunkLength
uint32 chunkType
ubyte[] chunkData
```

- `chunkLength`의 길이 `chunkData`(바이트)입니다.
- `chunkType`청크의 유형을 나타냅니다. [자세한 내용은 표 1을](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#table-chunktypes) 참조하십시오 .
- `chunkData`청크의 바이너리 페이로드입니다.

각 청크의 시작과 끝은 4바이트 경계에 정렬되어야 합니다 **.** 패딩 체계에 대한 청크 정의를 참조하십시오. 청크는 [표 1](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#table-chunktypes) 에 주어진 순서대로 정확하게 나타나야 **합니다** .

|  | **청크 유형** | **ASCII** | **설명** | **발생** |
| --- | --- | --- | --- | --- |
| 1. | 0x4E4F534A | JSON | Structured JSON content | 1 |
| 2. | 0x004E4942 | BIN | Binary buffer | 0 or 1 |

클라이언트 구현은 glTF 확장이 처음 두 청크 뒤에 오는 새로운 유형의 추가 청크를 참조할 수 있도록 알 수 없는 유형의 청크를 무시해야 합니다( **MUST) .**

### 4.4.3.2. 구조화된 JSON 콘텐츠

이 청크는 .gltf 파일 내에서 제공되는 glTF JSON을 보유합니다.

|  | ECMAScript 구현 참고 사항
JavaScript 구현에서 `TextDecoder`API를 사용하여 ArrayBuffer에서 glTF 콘텐츠를 추출한 다음 `JSON.parse`평소와 같이 JSON을 구문 분석할 수 있습니다. |
| --- | --- |

이 청크는 Binary glTF 자산의 첫 번째 청크여야 합니다**.** 이 청크를 먼저 읽음으로써 구현은 후속 청크에서 리소스를 점진적으로 검색할 수 있습니다. 이렇게 하면 바이너리 glTF 자산에서 선택한 리소스 하위 집합만 읽을 수도 있습니다.

정렬 요구 사항을 충족하려면 이 청크를 후행 문자( ) 로 채워야 **합니다** .`Space0x20`

### 4.4.3.3. 바이너리 버퍼

이 청크에는 지오메트리, 애니메이션 키 프레임, 스킨 및 이미지에 대한 바이너리 페이로드가 포함되어 있습니다. [JSON에서 이 청크를 참조하는 방법에 대한 자세한 내용은 GLB 저장 버퍼를](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#glb-stored-buffer) 참조하세요 .

이 청크는 Binary glTF 자산의 두 번째 청크여야 합니다**.** 정렬 요구 사항을 충족하려면 이 청크를 후행 0( )으로 채워야 **합니다**. 바이너리 버퍼가 비어 있거나 다른 방법으로 저장될 때 이 청크는 생략되어야 합니다**.**