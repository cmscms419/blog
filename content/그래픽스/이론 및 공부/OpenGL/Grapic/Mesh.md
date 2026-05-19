# Mesh

버텍스(Vertex)로 이루어진 폴리곤(Polygon)의 정보를 가지고 있는 폴리곤의 집합을 메쉬

### Mesh 클래스

mesh는 최소한으로 가져야 할 데이터

- 위치 벡터
- 법선 벡터
- 텍스처 좌표 벡터

 추가 

- 텍스처 형태(diffuse/specular map)의 material 데이터도 포함할 수 있습니다.

이제 mesh 클래스에 대한 최소한의 요구사항을 설정하였으니 OpenGL에 vertex를 정의할 수 있습니다.

```cpp
struct Vertex {
    glm::vec3 Position;
    glm::vec3 Normal;
    glm::vec2 TexCoords;
};

```

우리는 각각의 vertex attribute들을 찾는 데에 사용할 수 있는 필요한 벡터들을 Vertex struct에 저장합니다. Vertex struct와는 별도로 Texture struct에 텍스처 데이터를 저장하기를 원합니다.

```cpp
struct Texture {
    unsigned int id;
    string type;
};

```

텍스처의 id와 타입(예를 들어 diffuse 텍스처나 specular 텍스처)을 저장합니다.

vertex와 텍스처에 대해 실제로 우리는 mesh 클래스의 구조를 정의할 수 있습니다.

```cpp
class Mesh {
    public:
				/*  Mesh 데이터  */
				vector<Vertex> vertices;
        vector<unsigned int> indices;
        vector<Texture> textures;
				/*함수*/
				Mesh(vector<Vertex> vertices, vector<unsigned int> indices, vector<Texture> textures);
        void Draw(Shader shader);
    private:
/*  렌더 데이터  */
				unsigned int VAO, VBO, EBO;
/*  함수         */
				void setupMesh();
};

```

생성자에게 mesh의 필수적인 모든 데이터를 줍니다. 

- setupMesh 함수
    - 버퍼들을 초기화합니다.
- Draw 함수
    - mesh를 그립니다.
        - Draw 함수에 shader를 준다는 것을 생각하세요. shader를 전해줌으로써 그리기 전에 여러가지 uniform들을 설정할 수 있습니다(sampler들을 텍스처 유닛에 연결하는 것과 같은).

생성자 함수의 내용은 꽤 간단합니다. 간단히 클래스의 public 변수들을 해당 파라미터 변수로 설정해줍니다. 또한 생성자 내부에서 setupMesh 함수를 호출합니다.

```cpp
Mesh(vector<Vertex> vertices, vector<unsigned int> indices, vector<Texture> textures)
{
    this->vertices = vertices;
    this->indices = indices;
    this->textures = textures;

    setupMesh();
}
```

여기에 특별한 것은 없습니다. 이제 setupMesh 함수를 알아봅시다.

## setupMesh(초기화)

이 생성자 덕분에 우리는 렌더링에 사용할 수 있는 mesh 데이터의 목록을 가질 수 있습니다.

적절한 버퍼들을 설정하고 vertex attribute pointer를 통해 vertex shader layout을 지정해주어야 합니다. 이제 여러분은 이러한 개념에 어려움이 없어야 합니다.

```cpp
void setupMesh()
{
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);

    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);

    glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(Vertex), &vertices[0], GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.size() * sizeof(unsigned int),
                 &indices[0], GL_STATIC_DRAW);

// vertex positionsglEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)0);
// vertex normalsglEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, Normal));
// vertex texture coordsglEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, TexCoords));

    glBindVertexArray(0);
}

```

이 코드는 여러분이 기대한 것과 많이 다르지 않습니다. 하지만 Vertex struct의 도움을 받는다는 점이 다릅니다.

C++에서의 Struct의 속성들은 메모리의 위치가 순차적으로 저장됩니다. 

struct 배열을 생성한다면 struct의 변수들이 순차적으로 정렬되어 array buffer에 필요한 float(실제로는 byte) 배열로 변환합니다.

예를 들어, 우리가 Vertex struct를 채워넣으면 이 메모리 레이아웃은 다음과 같습니다.

```cpp
Vertex vertex;
vertex.Position  = glm::vec3(0.2f, 0.4f, 0.6f);
vertex.Normal    = glm::vec3(0.0f, 1.0f, 0.0f);
vertex.TexCoords = glm::vec2(1.0f, 0.0f);
// = [0.2f, 0.4f, 0.6f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f];
```

이 유용한 특성 덕분에 우리는 Vertex struct들을 buffer 데이터로 전달할 수 있습니다. 

그리고 struct들은 glBufferData 함수에 파라미터로 들어갈 값들로 완벽하게 변환될 수 있습니다.

```cpp
glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(Vertex), vertices[0], GL_STATIC_DRAW);

```

물론 `sizeof` 연산자는 적절한 바이트 크기를 위해 struct에 사용할 수 있습니다. 이는 `32` 바이트(`8` floats * `4` 바이트)입니다.

Struct의 또다른 사용법은 `offsetof(s,m)` 라고 불리는 전처리기 지시문입니다. 

`offsetof`

- 첫 번째 파라미터는 struct
- 두 번째 파라미터는 위 struct의 변수 이름
- 이 매크로는 struct의 시작지점으로부터 입력된 변수까지의 바이트 offset을 리턴합니다. 이는 glVertexAttribPointer 함수의 offset 파라미터를 정의하기에 완벽합니다.

```cpp
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, Normal));

```

이 offset은 `offsetof` 매크로를 사용하여 정의 되었습니다. 

이 경우에서는 법선 벡터의 바이트 offset을 `12` 바이트(`3` floats * `4` 바이트)로 설정합니다.

stride 파라미터는 Vertex struct의 크기로 설정한다

이런식으로 struct를 사용하는 것은 읽기 좋은 코드로 만들어줄 뿐 아니라 구조를 쉽게 확장할 수 있도록 해줍니다. 

우리가 또 다른 vertex attribute를 원한다면 간단히 struct에 추가하기만하면 렌더링이 깨지지 않고 정상적으로 동작합니다.

## Draw(랜더링)

mesh를 실제로 렌더링하기 전에 우리는 먼저 glDrawElements 함수를 호출하기 전에 적절한 텍스처를 바인딩해야 합니다. 

하지만 이는 실제로 약간 어렵습니다. 왜냐하면 이 mesh가 몇 개의 텍스처를 가지고 있는지 어떠한 타입의 텍스처를 가지고 있는지 모르기 때문입니다.

이런 상황에서 shader에 텍스처 유닛과 sampler를 어떻게 설정해야 하기 위해서는 다음과 같은 네이밍 관습을 적용합니다.

1. 각 specular 텍스처는 `texture_specularN` 라고 이름을 붙입니다. 
    1. `texture_specularN` 에서 `N`:  `1`부터 텍스처 sampler에 허용되는 최댓값 사이의 어떠한 숫자

예시)

우리가 3개의 diffuse 텍스처와 2개의 specular 텍스처를 가지고 있다고 해봅시다. 이들의 텍스처 sampler는 다음과 같이 불립니다.

```glsl
uniform sampler2D texture_diffuse1;
uniform sampler2D texture_diffuse2;
uniform sampler2D texture_diffuse3;
uniform sampler2D texture_specular1;
uniform sampler2D texture_specular2;

```

1. 각 diffuse 텍스처는 `texture_diffuseN` 라고 이름을 붙입니다

### 이 습관의 장점

1. shader에서 텍스처 sampler를 있는 만큼 모두 정의할 수 있습니다. 
2. mesh가 실제로 텍스처들을 많이 가지고 있다고 하면 우리는 그들의 이름이 뭔지 알 수 있습니다. 
3. 하나의 mesh에 많은 양의 텍스처들을 처리할 수 있습니다.

```cpp
void Draw(Shader shader)
{
    unsigned int diffuseNr = 1;
    unsigned int specularNr = 1;
    for(unsigned int i = 0; i < textures.size(); i++)
    {
        glActiveTexture(GL_TEXTURE0 + i); // 바인딩하기 전에 적절한 텍스처 유닛 활성화
				// 텍스처 넘버(diffuse_textureN 에서 N) 구하기
				string number;
        string name = textures[i].type;
        if(name == "texture_diffuse")
            number = std::to_string(diffuseNr++);
        else if(name == "texture_specular")
            number = std::to_string(specularNr++);

        shader.setFloat(("material." + name + number).c_str(), i);
        glBindTexture(GL_TEXTURE_2D, textures[i].id);
    }
    glActiveTexture(GL_TEXTURE0);

		// mesh 그리기
		glBindVertexArray(VAO);
    glDrawElements(GL_TRIANGLES, indices.size(), GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);
}

```

먼저 텍스처 타입마다 N 값을 계산하고 적절한 uniform 이름을 얻기 위해 이 N 값을 텍스처의 타입 문자열에 결합시킵니다. 

그런 다음 적절한 sampler를 위치시키고 현재 활성화된 텍스처 유닛에 부합되는 위치 값을 주어주고 텍스처를 바인딩합니다. 

이 것이 Draw 함수에서 shader가 필요한 이유입니다.  또한 우리는 `"material."` 문자열을 최종 uniform 이름에 추가하였습니다. 우리는 일반적으로 텍스처를 material struct에 저장하기 때문입니다(이는 구현에 따라 다를 수 있습니다).

우리는 diffuse, specular 갯수를 `string`으로 변환시키는 동시에 증가시킵니다.

C++에서의 증가 호출 variable++는 variable을 리턴한 **후** variable을 증가시키고 반면에 ++variable은 **먼저** variable을 증가시킨  **후** 그 값을 리턴합니다. 우리 경우에는 값이 std::to_string 에 넘어가고 그 후에 값이 증가하게 됩니다.

방금 정의한 이 Mesh 클래스는 이전의 강좌들에서 다루었던 여러 주제에 대해 깔끔하게 추상화되어 있습니다. 다음 강좌에서는 여러 mesh 오브젝트들로 이루어진 컨테이너 모델을 만들어 보고 실제로 Assimp의 로드 인터페이스를 구현해볼 것입니다.