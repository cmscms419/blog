# Model

실제 로딩, 변환 코드를 생성할 것입니다. 

이 강좌의 목표는 전체적인 모델(여러 mesh들을 가지고 있는)을 나타내는 또 다른 클래스를 생성하는 것입니다.

나무로 된 발코니, 타워, 수영장을 가지고 있는 집은 여전히 하나의 모델로 로드될 수 있습니다. 

우리는 Assimp를 통해 모델을 로드하고 이 것을 이전 강좌에서 생성한 여러 Mesh 객체들로 변환할 것입니다.

## Model 클래스의 구조

```cpp
class Model
{
    public:
/*  함수   */
				Model(char *path)
        {
            loadModel(path);
        }
        void Draw(Shader shader);
    private:
/*  Model 데이터  */
				vector<Mesh> meshes;
        string directory;
/*  함수   */
				void loadModel(string path);
        void processNode(aiNode *node, const aiScene *scene);
        Mesh processMesh(aiMesh *mesh, const aiScene *scene);
        vector<Texture> loadMaterialTextures(aiMaterial *mat, aiTextureType type,
                                             string typeName);
};
```

이 Model 클래스는 Mesh 객체들의 vector를 가지고 있고 생성자에서 파일의 위치를 요구합니다.

그런 다음 loadModel 함수를 생성자에서 호출하여 파일을 불러옵니다.

private 함수들은 Assimp의 import 루틴의 일부분을 처리합니다.

파일 경로의 디렉터리를 저장합니다. 나중에 텍스처를 로드할 때 필요하기 때문입니다.

Draw 함수는 특별한 것은 없고 기본적으로 반복문을 이용하여 각 mesh들의 Draw 함수를 호출시킵니다.

```cpp
void Draw(Shader shader)
{
    for(unsigned int i = 0; i < meshes.size(); i++)
        meshes[i].Draw(shader);
}

```

## OpenGL에 3D 모델을 불러오기

모델을 불러오고 그 것을 우리만의 구조로 변환하기 위해서 먼저 Assimp의 적절한 헤더파일을 포함해야합니다.

```cpp
#include <assimp/Importer.hpp>
#include <assimp/scene.h>
#include <assimp/postprocess.h>
```

호출할 첫 번째 함수는 loadModel 함수이고 이 함수는 생성자로부터 직접적으로 호출됩니다. 

### loadModel

scene 객체라고 불리는 Assimp의 데이터 구조에 모델을 불러오기 위해 Assimp를 사용합니다. 

scene 객체가 Assimp 데이터 인터페이스의 루트 객체입니다.

scene 객체를 가지게되면 불러온 모델로부터 우리가 원하는 모든 데이터를 얻을 수 있습니다.

Assimp의 대단한 점은 모든 각기 다른 파일 포맷들을 불러오는 것에 대한 기술적인 상세사항들을 깔끔하게 추상화했다는 점입니다.

```cpp
void loadModel(string path)
{
    Assimp::Importer import;
    const aiScene *scene = import.ReadFile(path, aiProcess_Triangulate | aiProcess_FlipUVs);

    if(!scene || scene->mFlags & AI_SCENE_FLAGS_INCOMPLETE || !scene->mRootNode)
    {
        cout << "ERROR::ASSIMP::" << import.GetErrorString() << endl;
        return;
    }
    directory = path.substr(0, path.find_last_of('/'));

    processNode(scene->mRootNode, scene);
}

```

먼저 Assimp 네임스페이스의 실제 Importer 객체를 선언합니다.

그런 다음 이 객체의 ReadFile 함수를 호출합니다. 

### ReadFile

첫 번째 파라미터 : 파일의 경로를 요구

두 번째 파라미터 : 여러 post-processing(전처리) 옵션들을 받습니다. 

Assimp는 간단히 파일을 불러오는 것 외에도 불러온 데이터에 추가적인 계산/연산을 하는 여러 옵션들을 지정할 수 있도록 해줍니다. 

aiProcess-Triangulate 를 설정함으로써 Assimp에게 모델이 삼각형으로만 이루어지지 않았다면 모델의 모든 primitive 도형들을 삼각형으로 변환하라고 말해줍니다. 

aiProcess-FlipUVs 는 텍스처 좌표를 y 축으로 뒤집어줍니다

→ (OpenGL에서 대부분의 이미지들은 y 축을 중심으로 거꾸로 된다는 것을 기억할 것입니다. 이 문제를 전처리 옵션으로 간단히 해결할 수 있습니다). 

다음은 약간의 유용한 다른 옵션들입니다.

- aiProcess_GenNormals : 모델이 법선 벡터들을 가지고 있지 않다면 각 vertex에 대한 법선을 실제로 생성합니다.
- aiProcess_SplitLargeMeshes : 큰 mesh들을 여러개의 작은 서브 mesh들로 나눕니다. 렌더링이 허용된 vertex 수의 최댓값을 가지고 있을 때 유용하고 오직 작은 mesh들만 처리할 수 있습니다.
- aiProcess_OptimizeMeshes : 반대로 여러 mesh들을 하나의 큰 mesh로 합칩니다. 최적화를 위해 드로잉 호출을 줄일 수 있습니다.

어려운 작업은 반환된 scene 객체를 사용하여 불러온 데이터를 `Mesh` 객체들의 배열로 변환하는 것입니다.

## processNode

1. scene의 노드들을 처리하기 위해 첫 번째 노드(루트 노드)를 재귀적으로 동작하는 processNode 함수로 전달합니다. 
2. 각 노드는 (아마도) 자식들을 가지고 있을 것이기 때문에 먼저 노드를 처리하고 그런 다음 계속해서 이 노드의 모든 자식들을 처리합니다. 

이는 재귀적인 구조에 적합하므로 재귀적인 함수를 정의할 것입니다. 재귀적 함수는 어떠한 처리를 하고 특정한 조건을 만족할때까지 recursively(재귀적으로) 다른 파라미터로 동일한 함수를 호출합니다. 우리의 경우에 exit condition(종료 조건)은 모든 노드들이 처리되었을 때 만족합니다.

Assimp의 구조로부터 기억할 수 있듯이 각 노드는 mesh index들의 모음을 가지고 있습니다. 각 index는 scene 객체 내부의 특정한 mesh를 가리킵니다. 따라서 이러한 mesh index들을 얻고 각 mesh들을 얻고 그 후 각 mesh들을 처리하고 나서 각 노드의 자식 노드들에게도 이 작업을 반복합니다. processNode 함수의 내용은 다음과 같습니다.

```cpp
void processNode(aiNode *node, const aiScene *scene)
{
// 노드의 모든 mesh들을 처리(만약 있다면)
for(unsigned int i = 0; i < node->mNumMeshes; i++)
    {
        aiMesh *mesh = scene->mMeshes[node->mMeshes[i]];
        meshes.push_back(processMesh(mesh, scene));
    }
// 그런 다음 각 자식들에게도 동일하게 적용
for(unsigned int i = 0; i < node->mNumChildren; i++)
    {
        processNode(node->mChildren[i], scene);
    }
}

```

모든 mesh들이 처리되면 노드의 모든 자식들에게 반복하고 동일한 processNode 함수를 호출합니다. 노드가 더 이상의 자식을 가지고 있지 않다면 이 함수는 실행을 멈춥니다.

### Assimp에서 Mesh로

`aiMesh` 객체를 우리의 mesh 객체로 변환하는 것은 그렇게 어렵지 않습니다. 우리가 해야할 일은 각 mesh들의 관련된 속성들에 접근하여 우리만의 객체에 저장하는 것입니다. processMesh 함수의 일반적인 구조는 다음과 같습니다.

```cpp
Mesh processMesh(aiMesh *mesh, const aiScene *scene)
{
    vector<Vertex> vertices;
    vector<unsigned int> indices;
    vector<Texture> textures;

    for(unsigned int i = 0; i < mesh->mNumVertices; i++)
    {
        Vertex vertex;
// vertex 위치, 법선, 텍스처 좌표를 처리
        ...
        vertices.push_back(vertex);
    }
// indices 처리
    ...
// material 처리
	  if(mesh->mMaterialIndex >= 0)
    {
        ...
    }

    return Mesh(vertices, indices, textures);
}
```

Mesh를 처리하는 것은 기본적으로 세 부분으로 이루어집니다. 모든 vertex 데이터를 얻고, mesh의 indices를 얻고, 마지막으로 연관된 material 데이터를 얻는 것입니다. 처리된 데이터는 하나의 `3` 벡터에 저장되고 함수를 호출한 곳으로 이 벡터가 리턴됩니다.

```cpp
glm::vec3 vector;
vector.x = mesh->mVertices[i].x;
vector.y = mesh->mVertices[i].y;
vector.z = mesh->mVertices[i].z;
vertex.Position = vector;

```

Assimp는 직관적이지 않은 vertex 위치 배열 mVertices 를 호출합니다.

법선을 위한 작업도 특별한 것이 없습니다.

```cpp
vector.x = mesh->mNormals[i].x;
vector.y = mesh->mNormals[i].y;
vector.z = mesh->mNormals[i].z;
vertex.Normal = vector;

```

텍스처 좌표는 거의 비슷하지만 Assimp가 각 vertex마다 최대 8개의 텍스처를 허용합니다. 또한 mesh가 실제로 텍스처 좌표를 가지고 있는지 확인해야합니다(항상 가지고 있는 것이 아닙니다).

```cpp
// mTextureCoords[0]는 텍스처 좌표를 가지고 있는가를 판단해줍니다
if(mesh->mTextureCoords[0])
{
    glm::vec2 vec;
    vec.x = mesh->mTextureCoords[0][i].x;
    vec.y = mesh->mTextureCoords[0][i].y;
    vertex.TexCoords = vec;
}
else
    vertex.TexCoords = glm::vec2(0.0f, 0.0f);

```

vertex struct는 이제 필요한 vertex 속성들로 완전히 채워졌습니다. 이 것을 vertices vector의 끝에 삽입할 수 있습니다. 이 처리는 mesh의 각 vertex 마다 수행됩니다.

### Indices

Assimp의 인터페이스는 각 mesh들이 face의 배열을 가지고 있도록 정의했습니다. 각 face들은 하나의 primitive를 나타냅니다. (aiProcess_Triangulate 옵션 때문에) 항상 삼각형입니다. 

face는 우리가 어떠한 순서로 vertex들을 그려야하는지를 정의하는 indices를 가지고 있습니다. 그래서 우리는 모든 face에 대해 반복문을 돌려 모든 face의 indices를 indices vector에 저장해야 합니다.

```cpp
for(unsigned int i = 0; i < mesh->mNumFaces; i++)
{
    aiFace face = mesh->mFaces[i];
    for(unsigned int j = 0; j < face.mNumIndices; j++)
        indices.push_back(face.mIndices[j]);
}

```

바깥의 루프가 끝나면 이제 glDrawElements 함수를 통해 mesh를 그리기 위한 vertex, index 데이터가 완벽히 설정된 것입니다. 하지만 mesh의 material 또한 처리해야 합니다.

### Material

노드와 마찬가지로 mesh는 오직 material 객체의 index만 가지고 있습니다. 

실제 mesh의 material을 얻기위해서는 scene의 mMaterial 배열을 인덱싱해야 합니다. mesh의 material index는 mMaterialIndex 속성에 설정되어 있습니다.

```cpp
// 매테리얼 값이 있는지 판단
if(mesh->mMaterialIndex >= 0)
{
    aiMaterial *material = scene->mMaterials[mesh->mMaterialIndex];
    vector<Texture> diffuseMaps = loadMaterialTextures(material,
                                        aiTextureType_DIFFUSE, "texture_diffuse");
    textures.insert(textures.end(), diffuseMaps.begin(), diffuseMaps.end());
    vector<Texture> specularMaps = loadMaterialTextures(material,
                                        aiTextureType_SPECULAR, "texture_specular");
    textures.insert(textures.end(), specularMaps.begin(), specularMaps.end());
}
```

먼저 scene의 mMaterials 배열로부터 `aiMaterial` 객체를 얻습니다. 

그런 다음 mesh의 diffuse, specular 텍스처들을 불러와야 합니다. 

material 객체는 내부적으로 각 텍스처 타입에 대한 텍스처 위치의 배열을 저장합니다. 

여러 텍스처 타입들은 `aiTextureType_` 접두사로 분류됩니다.

loadMaterialTextures 함수는 **주어진** **텍스처 타입의 모든 텍스처 위치들에 대해 반복문을 돌리고 텍스처 파일의 위치를 얻은 다음 불러오고 텍스처를 생성하며 이 정보를 Vertex struct에 저장합니다.** 이는 다음과 같습니다.

```cpp
vector<Texture> loadMaterialTextures(aiMaterial *mat, aiTextureType type, string typeName)
{
    vector<Texture> textures;
    for(unsigned int i = 0; i < mat->GetTextureCount(type); i++)
    {
        aiString str;
        mat->GetTexture(type, i, &str);
        Texture texture;
        texture.id = TextureFromFile(str.C_Str(), directory);
        texture.type = typeName;
        texture.path = str;
        textures.push_back(texture);
    }
    return textures;
}
```

먼저 GetTextureCount 함수를 통해 이 material에 저장된 텍스처의 갯수를 확인합니다. 이 함수는 텍스처 타입 중 하나를 파라미터로 받습니다. 그런 다음 결과를 `aiString`에 저장하는 GetTexture 함수를 통해 각 텍스처 파일의 위치를 얻습니다. 다음에 TextureFromFile 함수의 도움을 받습니다. 이 함수는 (SOIL과 함께) 텍스처를 불러오고 이 텍스처의 ID를 리턴합니다. 여러분이 이 함수가 어떻게 작성되어있는지 확신할 수 없다면 이 강좌의 마지막에 있는 전체 소스 코드에서 확인하세요.

우리가 model 파일의 텍스처 파일 경로가 model 파일 경로와 동일하다고 가정했다는 것을 알아두세요. 우리는 간단히 텍스처 위치 문자열과 (loadModel 함수에서 얻은) 디렉터리 문자열을 결합하여 완전한 텍스처 경로를 얻을 수 있습니다(이 것이 GetTexture 함수도 디렉터리 문자열을 필요로 하는 이유입니다).

어떠한 모델들은 그들의 텍스처 위치에 대해서 여전히 절대 경로를 사용합니다. 이는 일부 기기에서 작동하지 않을 수 있습니다. 이 경우에 텍스처에 대한 로컬 경로를 사용하기 위해 파일을 수작업으로 수정해야 합니다.

그리고 이것으로 Assimp를 사용하여 모델을 불러오는 작업이 끝났습니다.

# 최적화

그래서 우리는 model 코드에 약간의 변형을 줄 것입니다. 불러온 모든 텍스처들을 전역으로 저장하고 텍스처를 불러오고 싶을때마다 먼저 그 텍스처가 이미 불러와졌는지 확인합니다. 이미 불러온 텍스처라면 이 텍스처를 가져오고 전체적인 텍스처를 불러오는 과정은 생략하여 많은 프로세싱 파워를 절약할 수 있습니다. 이러한 텍스처 비교를 가능하게 하기 위해서 그들의 경로 또한 저장해야합니다.

```cpp
struct Texture {
    unsigned int id;
    string type;
    string path;// 다른 텍스처와 비교하기 위해 텍스처의 경로를 저장
};

```

그런 다음 모델 클래스의 맨 위에 private 변수로 선언된 또 다른 vector에 불러온 모든 텍스처를 저장합니다.

```cpp
vector<Texture> textures_loaded;
```

그런 다음 loadMaterialTextures 함수에서 텍스처 경로를 textures_loaded vector에 있는 모든 텍스처의 경로와 비교하여 현재 텍스처 경로가 다른 것들과 같은지를 확인합니다. 같다면 텍스처를 불러오고 생성하는 부분을 생략하고 간단히 texture struct에 존재하는 것을 사용하기만 하면 됩니다. (수정된) 함수는 다음과 같습니다.

```cpp
vector<Texture> loadMaterialTextures(aiMaterial *mat, aiTextureType type, string typeName)
{
    vector<Texture> textures;
    for(unsigned int i = 0; i < mat->GetTextureCount(type); i++)
    {
        aiString str;
        mat->GetTexture(type, i, &str);
        bool skip = false;
        for(unsigned int j = 0; j < textures_loaded.size(); j++)
        {
            if(std::strcmp(textures_loaded[j].path.data(), str.C_Str()) == 0)
            {
                textures.push_back(textures_loaded[j]);
                skip = true;
                break;
            }
        }
        if(!skip)
        {// 텍스처가 이미 불러와져있지 않다면 불러옵니다.
            Texture texture;
            texture.id = TextureFromFile(str.C_Str(), directory);
            texture.type = typeName;
            texture.path = str.C_Str();
            textures.push_back(texture);
            textures_loaded.push_back(texture);// 불러온 텍스처를 삽입합니다.
        }
    }
    return textures;
}

```