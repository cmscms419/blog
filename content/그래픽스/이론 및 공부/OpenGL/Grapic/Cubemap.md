# Cubemap

# Cubemaps

여러 텍스처들을 하나의 텍스처로 매핑한 텍스처입니다.

Cubemap은 기본적으로 큐브의 각 면을 형성하는 2D 텍스처들을 포함하고 있는 텍스처입니다. 

방향 벡터를 사용하여 인덱싱/샘플링될 수 있는 점입니다. 

중앙에 위치해 있는 방향벡터의 원점과 1x1x1의 단위 큐브를 가지고 있다고 생각해보세요. 이 cube map으로부터 텍스처를 샘플링하는 것은 다음 그림처럼 보입니다. 주황색 벡터는 방향 벡터입니다.

![](attachments/cubemaps_sampling.png)

방향만 제공된다면 OpenGL 이 방향과 맞닿는 해당 텍셀을 얻습니다. 그리고 적절히 샘플링된 텍스처 값을 리턴합니다.

이러한 cubemap을 첨부한 큐브 도형을 가지고 있다면 이 cubemap을 샘플링하는 방향 벡터는 cube의 (보간된) vertex 위치와 비슷합니다. 

이 방법으로 우리는 이 큐브가 원점에 존재한다면 이 큐브의 실제 위치 벡터들을 사용하여 cubemap을 샘플링할 수 있습니다.

## Cubemap 생성

Cubemap은 다른 텍스처들과 같은 텍스처이므로 생성하기 위해서 텍스처 연산을 실행하기 전에 텍스처를 생성하고 적절한 텍스처 타겟에 바인딩합니다. 이번에는 GL_TEXTURE_CUBE_MAP에 바인딩합니다.

```cpp
unsigned int textureID;
glGenTextures(1, &textureID);
glBindTexture(GL_TEXTURE_CUBE_MAP, textureID);

```

6개의 면을 가지고 있기때문에 OpenGL은 cubemap의 면들을 타겟팅할 수 있도록 6개의 특별한 텍스처 타겟을 제공해줍니다.

| 텍스처 타겟 | 방향 |
| --- | --- |
| `GL_TEXTURE_CUBE_MAP_POSITIVE_X` | 오른쪽 |
| `GL_TEXTURE_CUBE_MAP_NEGATIVE_X` | 왼쪽 |
| `GL_TEXTURE_CUBE_MAP_POSITIVE_Y` | 위 |
| `GL_TEXTURE_CUBE_MAP_NEGATIVE_Y` | 아래 |
| `GL_TEXTURE_CUBE_MAP_POSITIVE_Z` | 뒤 |
| `GL_TEXTURE_CUBE_MAP_NEGATIVE_Z` | 앞 |

다른 많은 OpenGL의 enum 변수들과 마찬가지로 점점 연속적으로 증가하는 int 형 변수이므로 텍스처의 vector 배열을 가지고 있다면 이들을 반복문으로 돌려 GL_TEXTURE_CUBE_MAP_POSITIVE_X로 시작하여 이 변수를 1씩 증가시켜가면서 효율적으로 모든 텍스처 타겟들을 설정할 수 있습니다.

```cpp
int width, height, nrChannels;
unsigned char *data;
for(GLuint i = 0; i < textures_faces.size(); i++)
{
    data = stbi_load(textures_faces[i].c_str(), &width, &height, &nrChannels, 0);
    glTexImage2D(
        GL_TEXTURE_CUBE_MAP_POSITIVE_X + i,
        0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data
    );
}
```

여기에서 textures_faces라는 이름을 가진 vector를 가지고 있는데 이 것은 cubemap을 위한 모든 텍스처들의 위치를 위 표 순서대로 가지고 있습니다. 이는 현재 바인딩된 cubemap의 각 면에 텍스처를 생성합니다.

Cubemap은 다른 텍스처와 다를게 없는 텍스처이기 때문에 wrapping, filtering method를 지정할 수 있습니다.

```cpp
glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);

```

GL_TEXTURE_WRAP_R은 단순히 텍스처의 3번째 차원(위치의 `z`와 동일)에 해당하는 `R`좌표에 대한 wrapping method를 설정합니다. 정확히 두 면 사이에 있는 텍스처 좌표들이 정확한 면을 가리키지 않을 수 있으므로(일부 하드웨어들의 제한때문에) GL_CLAMP_TO_EDGE를 사용하여 면 사이를 샘플링할때마다 OpenGL이 모서리 값을 리턴하도록 해줍니다.

Fragment shader 내부에서 우리는 다른 샘플러 타입인 `samplerCube`를 사용해야 합니다. 이 타입은 texture 함수를 사용하여 샘플링을 하는 것은 동일하지만 `vec2` 대신에 `vec3`의 방향 벡터를 사용합니다. cubemap을 사용하는 fragment shader의 예는 다음과 같습니다.

```glsl
in vec3 textureDir;// 3D 텍스처 좌표를 나타내는 방향 벡터
uniform samplerCube cubemap;// Cubemap 텍스처 샘플러void main()
{
    FragColor = texture(cubemap, textureDir);
}
```

# Skybox

Skybox는 전체 scene을 둘러싸고 주변 환경 6개의 이미지를 가지고 있는 (큰) 큐브입니다. 

![](attachments/cubemaps_skybox.png)

## Skybox 불러오기

Skybox는 그자체로 단지 cubemap이기 때문에 skybox를 불러오는 것은 전에 보았던 것과 크게 다르지 않습니다. skybox를 불러오기 위해 6개의 텍스처 위치를 가지고 있는 vector를 받아들이는 다음과 같은 함수를 사용할 것입니다.

```cpp
unsigned int loadCubemap(vector<std::string> faces)
{
    unsigned int textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_CUBE_MAP, textureID);

    int width, height, nrChannels;
    for (unsigned int i = 0; i < faces.size(); i++)
    {
        unsigned char *data = stbi_load(faces[i].c_str(), &width, &height, &nrChannels, 0);
        if (data)
        {
            glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i,
                         0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data
            );
            stbi_image_free(data);
        }
        else
        {
            std::cout << "Cubemap texture failed to load at path: " << faces[i] << std::endl;
            stbi_image_free(data);
        }
    }
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);

    return textureID;
}

```

이 함수 자체로만은 그렇게 놀랍지 않습니다. 이는 기본적으로 모두 우리가 이전 섹션에서 봤던 cubemap 코드들을 하나의 관리가능한 함수로 합친 것입니다.

그런 다음 우리가 이 함수를 호출하기 전에 적절한 텍스처 경로를 vector에 불러올 것입니다.

```cpp
vector<std::string> faces;
{
    "right.jpg",
    "left.jpg",
    "top.jpg",
    "bottom.jpg",
    "front.jpg",
    "back.jpg"
};
unsigned int cubemapTexture = loadCubemap(faces);

```

우리는 이제 skybox를 cubemap으로서 불러오고 cubemapTexture에 id를 저장해놓았습니다. 이제 이 것을 큐브에 바인딩할 수 있고 결국에는 언제든 배경으로 사용할 수 있습니다.

## Skybox 그리기

vertex 데이터 필요합니다.

3D 큐브의 텍스처로 사용되는 cubemap은 큐브의 위치를 텍스처 좌표로 사용하여 샘플링될 수 있습니다. 큐브가 원점(0,0,0)에 위치해있을 때 각 위치 벡터들은 원점으로부터의 방향 벡터와 동일합니다. 

이 방향 벡터는 정확히 우리가 해당 텍스처 값을 얻기 위해 필요한 것입니다. 이런 이유로 우리는 오직 위치 벡터만을 제공해주면 되고 텍스처 좌표는 필요 없습니다.

 우리는 오직 하나의 vertex attribute만 필요하므로 vertex shader는 꽤 간단합니다.

```glsl
#version 330 core
layout (location = 0) in vec3 aPos;

out vec3 TexCoords;

uniform mat4 projection;
uniform mat4 view;

void main()
{
    TexCoords = aPos;
    gl_Position = projection * view * vec4(aPos, 1.0);
}

```

입력받은 위치 벡터를 fragment shader로 보낼 텍스처 좌표로 출력한다는 점입니다. 그러면 fragment shader는 이들은 입력 받아 `samplerCude`를 샘플링할 것입니다.

```glsl
#version 330 core
out vec4 FragColor;

in vec3 TexCoords;

uniform samplerCube skybox;

void main()
{
    FragColor = texture(skybox, TexCoords);
}

```

```cpp
glm::mat4 view = glm::mat4(glm::mat3(camera.GetViewMatrix()));
```

이는 어떠한 이동이든 없애줍니다. 하지만 모든 회전 변환은 유지하므로 사용자는 여전히 scene을 둘러볼 수 있습니다.

scene을 둘러보면 scene의 현실적임이 극적으로 증가했음을 알 수 있습니다. 결과는 다음과 같이 보일 것입니다.

## 최적화

 skybox를 제일 처음에 그리면 우리는 fragment shader를 화면의 각 픽셀들마다 실행해야 합니다. 심지어 skybox의 보이는 부분이 아주 작을지라도 말이죠. 

early depth testing을 사용하여 쉽게 폐기된 fragment들은 우리를 구해줄 것입니다.

그래서 성능 향상을 위해 우리는 skybox를 마지막에 렌더링할 것입니다. 그러면 depth buffer는 완전히 다른 오브젝트들의 depth 값으로 채워지므로 우리는 오직 early depth test를 통과한 skybox의 fragment들만 렌더링하면 됩니다. 

이는 비약적으로 fragment shader 호출 횟수를 줄일 수 있습니다. 문제는 skybox 는 대부분 렌더링에 실패할 것이라는 점입니다. 그저 1x1x1 큐브이기 때문이죠. 단순히 depth testing 없이 렌더링하는 것은 해법이 아닙니다. 그러면 skybox가 모든 다른 오브젝트들을 덮어씌울 것이기 때문이죠. 우리는 depth buffer에 트릭을 써서 skybox가 depth 값을 최댓값인 `1.0`을 가지고있다고 믿게 만들어서 앞에 다른 오브젝트들이 있는 곳은 test에 실패하도록 해야합니다.

좌표 시스템에서 우리는 *perspective division*이 vertex shader가 실행된 후에 gl_Position의 `xyz` 좌표를 `w` 요소로 나눔으로써 수행된다고 언급했었습니다. 

또한 우리는 depth testing 강좌에서 나눗셈의 결과 `z` 요소는 vertex의 depth 값과 동일하다고 말했었습니다. 

이 정보를 사용하여 우리는 출력 위치의 `z` 요소를 `w` 요소와 동일하게 설정하여 `z` 값이 항상 `1.0`이 될 수 있도록 만들 수 있습니다. perspective division이 수행될 때 `z` 요소는 `w` / w = `1.0`으로 변환되기 때문입니다.

```glsl
void main()
{
    TexCoords = aPos;
    vec4 pos = projection * view * vec4(aPos, 1.0);
    gl_Position = pos.xyww;
}

```

결과 NDC 좌표는 `1.0`의 `z` 값을 가지게 됩니다. 이는 depth 값의 최댓값입니다. 이 skybox는 결과적으로 오직 다른 오브젝트들이 없는 곳에서만 렌더링되게 됩니다(skybox 앞에 있는 모든 것들은 depth testing에서 통과하게 됩니다).

우리는 depth 함수를 기본값인 GL_LESS 대신에 GL_LEQUAL로 설정해야 합니다.

depth buffer는 skybox에 대해 `1.0` 값으로 채워지므로 우리는 skybox를 통과하게 만들기 위해 *less than*이 아닌 *less than or equal*로 수정해야 합니다.

# 환경 매핑

이제 우리는 하나의 텍스처가 매핑된 환경 오브젝트를 가지고 있고 이를 skybox 이상의 것들에 대해 사용할 수 있습니다. 환경과 cubemap을 사용하여 오브젝트에 빛을 반사 혹은 굴절 시키는 특성을 줄 수 있습니다. 이렇게 환경 cubemap을 사용하는 기술을 environment mapping 기술이라고 부르고 가장 많이 사용되는 것이 reflection(반사)와 refraction(굴절)입니다.

## Reflection(반사)

Reflection은 오브젝트(혹은 오브젝트의 어느 부분)이 주변 환경을 반사(reflect)하는 특성입니다. 시점의 각도를 기반으로 오브젝트의 컬러들은 환경과 동일하게 설정될 수 있습니다. 예를 들어 거울은 반사하는 오브젝트입니다. 시점의 각도에 따라 주변을 반사시키죠.

Reflection의 기본은 그리 어렵지 않습니다. 다음 이미지는 반사 벡터(reflection vector)를 계산하는 방법과 cubemap을 샘플링하기 위해 이 벡터를 사용하는 방법을 보여줍니다.

![](attachments/cubemaps_reflection_theory.png)

View 방향 벡터 I¯ 를 기반으로 오브젝트의 법선 벡터 N¯ 에 따른 반사 벡터 R¯ 을 계산합니다. GLSL의 reflect 함수를 사용하여 이 반사 벡터를 계산할 수 있습니다. 결과 벡터 R¯ 은 cubemap을 인덱싱/샘플링하기 위한 방향 벡터로서 사용됩니다. 최종 효과는 오브젝트가 skybox를 반사하는 것처럼 보입니다.

우리는 이미 scene에 skybox를 가지고 있기때문에 reflection을 생성하는 것은 그리 어렵지 않습니다. 우리는 컨테이너에 반사 속성을 주기 위해 컨테이너에 사용된 fragment shader를 수정할 것입니다.

```glsl
#version 330 coreout vec4 FragColor;

in vec3 Normal;
in vec3 Position;

uniform vec3 cameraPos;
uniform samplerCube skybox;

void main()
{
    vec3 I = normalize(Position - cameraPos);
    vec3 R = reflect(I, normalize(Normal));
    FragColor = vec4(texture(skybox, R).rgb, 1.0);
}

```

먼저 view/camera 방향 벡터 `I`를 계산하고 반사 벡터 `R`을 계산하기 위해 사용합니다. 이 반사 벡터는 skybox cubemap을 샘플링하기 위해 사용될 것입니다. 우리는 fragment의 보간된 Normal과 Position 변수를 가지고 있으므로 vertex shader 또한 수정해야한다는 것을 알아두세요.

```glsl
#version 330 corelayout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;

out vec3 Normal;
out vec3 Position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    Normal = mat3(transpose(inverse(model))) * aNormal;
    Position = vec3(model * vec4(aPos, 1.0));
    gl_Position = projection * view * model * vec4(aPos, 1.0);
}

```

우리는 법선 벡터를 사용하고 있으므로 단위 벡터로 이들을 변환하기를 원합니다. Position 출력 벡터는 world-space 위치 벡터입니다. 이 Position 출력은 fragment shader에서 view 방향 벡터를 계산하기 위해 쓰입니다.

법선을 사용하기 때문에 [vertex data](https://heinleinsgame.tistory.com/code_viewer.php?code=lighting/basic_lighting_vertex_data)를 수정하고 attribute pointer 또한 수정해주어야 합니다. 또한 cameraPos uniform도 설정해주어야 합니다.

그런 다음 우리는 컨테이너를 렌더링하기 전에 cubemap 텍스처를 바인딩해야합니다.

```cpp
glBindVertexArray(cubeVAO);
glBindTexture(GL_TEXTURE_CUBE_MAP, skyboxTexture);
glDrawArrays(GL_TRIANGLES, 0, 36);

```

컴파일 후 코드를 실행해보면 완벽한 거울같은 컨테이너를 볼 수 있습니다. 둘러싼 skybox는 정확히 컨테이너에 반사되고 있습니다.

![](attachments/cubemaps_reflection.png)

## Refraction(굴절)

환경 매핑의 또다른 형태는 refraction(굴절)이라고 불리고 반사와 비슷합니다. 굴절은 material의 변화에 따라 빛의 방향이 달라지는 것을 말합니다. 굴절은 흔히 빛이 직선으로 통과하지 않고 휘어지는 물과 같은 표면에서 볼 수 있습니다.

환경 맵과 함께 굴절은 [Snell's law](http://en.wikipedia.org/wiki/Snell%27s_law)에 설명이 잘 되어있습니다.

![](attachments/cubemaps_refraction_theory.png)

다시 우리는 view 벡터 I¯, 법선 벡터 N¯, 그리고 굴절 벡터 R¯을 가지고 있습니다. 보시다시피 view 벡터의 방향은 약간 휘어집니다. 이 휘어진 벡터 R¯ 은 cubemp을 샘플링합니다.

굴절은 GLSL의 refract 함수를 통해 쉽게 구현될 수 있습니다. 이 함수는 법선 벡터와 view 방향 그리고 두 refractive indices 사이의 비율을 인자로 받습니다.

굴절 index는 material의 빛이 왜곡/휘어지는 정도를 결정합니다. 각 material들은 자신만의 고유한 refractive index를 가지고 있습니다. 가장 많이 쓰이는 refractive index들을 다음 표에 나타내었습니다.

| Material | Refractive index |
| --- | --- |
| 공기 | 1.00 |
| 물 | 1.33 |
| 얼음 | 1.309 |
| 유리 | 1.52 |
| 다이아몬드 | 2.42 |

빛이 통과하는 두 material 사이의 비율을 계산하기 위해 이 refractive index들을 사용합니다. 우리의 경우엔 빛/view 광선이 *공기*에서 *유리*로 향합니다(컨테이너가 유리로 만들어져있다고 가정합니다). 그래서 이 비율은 1.001.52=0.6581.001.52=0.658 입니다.

이미 cubemap이 바인딩되어있고 법선과 함께 vertex data도 가지고 있고 unform으로 camera 위치도 설정했습니다. 우리가 오직 해야할 일은 fragment shader를 수정하는 것 뿐입니다.

```
void main()
{
    float ratio = 1.00 / 1.52;
    vec3 I = normalize(Position - cameraPos);
    vec3 R = refract(I, normalize(Normal), ratio);
    FragColor = vec4(texture(skybox, R).rgb, 1.0);
}

```