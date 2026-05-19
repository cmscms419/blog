# Shaders

셰이더는 GPU에 있는 작은 프로그램입니다. 이 프로그램은 그래픽 파이프라인의 각 특정 섹션에 대해 실행됩니다. 기본적으로 셰이더는 입력을 출력으로 변환하는 프로그램에 불과합니다. 셰이더는 또한 서로 통신할 수 없다는 점에서 매우 고립된 프로그램입니다. 그들이 가진 유일한 통신은 입력과 출력을 통한 것입니다.

# GLSL

셰이더는 C와 유사한 언어 GLSL로 작성됩니다. GLSL은 그래픽과 함께 사용하도록 조정되었으며 특히 벡터 및 행렬 조작을 대상으로 하는 유용한 기능을 포함합니다.

1. 항상 버전 선언으로 시작한다
2. 입력 및 출력변수
3. uniform 및 main의 목록

각 셰이더의 진입점은 입력 변수를 처리하고 결과를 출력 변수에 출력하는 main 함수에 있습니다.

셰이더의 구조는 일반적으로 다음과 같습니다.

```glsl
#version version_number // 버전 선언

// 입력 변수
in type in_variable_name;
in type in_variable_name;

// 출력 변수
out type out_variable_name;

// unform 변수
uniform type uniform_name;

// main
void main()
{
  // process input(s) and do some weird graphics stuff
  ...
  // output processed stuff to output variable
  out_variable_name = weird_stuff_we_processed;
}
```

입력 변수를 vertex attribute이라고도 합니다. 

하드웨어에 의해 제한적으로 선언할 수 있는 vertex attributes의 최대 수가 있습니다. 

OpenGL은 항상 16 개 이상의 4 구성 요소 정점 속성을 사용할 수 있도록 보장하지만 일부 하드웨어는 다음을 쿼리하여 검색 할 수있는 더 많은 속성을 허용 할 수 있습니다.

```cpp
int nrAttributes;
glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &nrAttributes);
std::cout << "Maximum nr of vertex attributes supported: " << nrAttributes << std::endl;

```

대부분의 목적에 충분해야하는 최소값을 반환합니다.

## Types

GLSL에는 다른 프로그래밍 언어와 마찬가지로 작업 할 변수의 종류를 지정하기위한 데이터 유형이 있습니다. GLSL에는 C: `int`, `float`, `double`, `uint` ,`bool` 및 와 같은 언어에서 알고 있는 대부분의 기본 기본 유형이 있습니다.

### Vectors

GLSL의 벡터는 방금 언급 한 기본 유형에 대한 2,3 또는 4 구성 요소 컨테이너입니다. 다음 형식을 사용할 수 있습니다(`n` 은 구성 요소 수를 나타냄). 

- `vecnn`
    
    : 부동 소수점의 기본 벡터입니다.
    
- `bvecnn`
    
    : 부울의 벡터입니다.
    
- `ivecnn`
    
    : 정수로 구성된 벡터입니다.
    
- `uvecnn`
    
    : 부호 없는 정수로 구성된 벡터입니다.
    
- `dvecnn`
    
    : 이중 성분으로 구성된 벡터입니다.
    

보통의 경우 `floats`로 충분하기 때문에 기본 `vecn`으로 사용합니다. 

### 벡터의 구성 요소

1. .x, .y, z 및 .w를 사용하여 각각 1번째, 2번째, 3번째 및 4번째 구성 요소에 엑세스 할 수 있습니다.
2. GLSL을 사용하면 색상에 `rgba` 를 사용 또는 텍스처 좌표에는 `stpq` 사용하여 동일한 구성 요소에 액세스 할 수도 있습니다.

벡터 데이터 유형은 `Swizzling`이라는구성 요소 선택을 허용합니다. `Swizzling`을 사용하면 다음과 같은 구문을 사용할 수 있습니다.

```glsl
vec2 someVec;
vec4 differentVec = someVec.xyxx;
vec3 anotherVec = differentVec.zyw;
vec4 otherVec = someVec.xxxx + anotherVec.yxzy;

```

최대 4개의 문자 조합을 사용하여 원래 벡터에 해당 구성 요소가 있는 한 동일한 유형의 새 벡터를 만들 수 있습니다. 예를 들어 A의 구성 요소에 액세스할 수 없습니다. 또한 벡터를 다른 벡터 생성자 호출에 인수로 전달하여 필요한 인수 수를 줄일 수 있습니다.

```glsl
vec2 vect = vec2(0.5, 0.7);
vec4 result = vec4(vect, 0.0, 0.0);
vec4 otherResult = vec4(result.xyz, 1.0);
```

## Ins and outs

각 셰이더는 이러한 키워드(`in, out`)를 사용하여 입력 및 출력을 지정할 수 있으며, 출력 변수가 전달되어 다음 셰이더 단계의 입력 변수와 일치하는 모든 위치에서 지정할 수 있습니다. vertex and fragment shader는 약간 다릅니다.

### The vertex shader

The vertex shader는 어떤 형태의 입력을 받아야 하며**,** 그렇지 않으면 꽤 비효율적입니다. The vertex shader는 vertex data를 바로 입력으로 받아드리는 것으로, 다른 입력 방법하고는 다릅니다. vertex data를 구성하는 방식은 CPU에서 vertex attributes을 구성할 수 있도록 위치 metadata로 입력 변수를 지정해서 정의 되어야 한다. vertex shader에는 vertex data와 link 할 수 있는 input에 대한 추가 Layout `layout (location = 0)`이 필요하다. 따라서 정점 셰이더는 입력에 대한 추가 레이아웃 사양이 필요하므로 정점 데이터와 연결할 수 있습니다.

```
layout(location = 0) 지정자를 생략하고 glGetAttribLocation을 통해 OpenGL 코드의 특성 위치를 쿼리하는 것도 가능하지만 정점 셰이더에서 설정하는 것이 좋습니다. 이해하기 쉽고 사용자(및 OpenGL)가 일부 작업을 저장합니다.
```

### fragment shader

fragment shader가 최종 출력 색상 `vec4`을 생성해야 하기 때문에 fragment shader에 색상 출력 변수가 필요하다는 것이다. fragment shader에서 출력 색상을 지정하지 못하면, 해당 fragment 에 대한 color buffer output이 정의되지 않습니다. (보통 OpenGL은 검은색 또는 흰색으로 렌더링함을 한다는 의미이다.).

따라서 한 shader에서 다른 shader로 데이터를 전송하려면 전송 shader에 출력을 선언하고 수신 shader 비슷한 input을 선언해야 합니다. type과 이름이 같을 때,  이 변수를 link한 다음 shader간에 데이터를 전송 할 수 있다.

**Vertex shader**

```glsl
#version 330 core
layout (location = 0)in vec3 aPos; // the position variable has attribute position 0

out vec4 vertexColor; // specify a color output to the fragment shader

void main()
{
    gl_Position = vec4(aPos, 1.0); // see how we directly give a vec3 to vec4's constructor
    vertexColor = vec4(0.5, 0.0, 0.0, 1.0); // set the output variable to a dark-red color
}
```

 **Fragment shader**

```glsl
#version 330 core
out vec4 FragColor;

in vec4 vertexColor; // the input variable from the vertex shader (same name and same type)

void main()
{
    FragColor = vertexColor;
}
```

## Uniforms

Uniforms CPU에 올라가 있는 애플리케이션에서 GPU shader로 데이터를 전달하는 방법이다. 그러나Uniforms 은 vertex attributes과 약간 다릅니다. 무엇보다 Uniforms은 “전역” 이다. 이 의미는 uniform variable는 shader program object 마다 고유하며 shader program의 모든 단계에서 shader에서 액세스할 수 있습니다. 둘째로, Uniforms 값을 어떻게 설정하든, 유니폼은 재설정되거나 업데이트될 때까지 그들의 값을 유지할 것이다.

GLSL에서 uniform을 선언하려면 type과 이름이 있는 shader에 키워드를 추가하기만 하면 된다. 이후 부터 새롭게 선언된 uniform을 shader에 사용할 수 있다.

```glsl
#version 330 core
out vec4 FragColor;

uniform vec4 ourColor; // we set this variable in the OpenGL code.

void main()
{
    FragColor = ourColor;
}
```

fragment shader에 uniform을 선언하고 fragment's output color를 이 uniform 값의 content로 설정한다. uniform은 전역 변수이기 때문에 원하는 shader 단계에서 정의할 수 있으므로 fragment shader에 무언가를 가져오기 위해 vertex shader를 다시 거칠 필요가 없다. vertex shader에서 이 uniform을 사용하지 않기 때문에 거기서 그것을 정의할 필요가 없다.

만약 당신이 당신의 GLSL 코드 어디에서도 사용되지 않는 유니폼을 선언한다면 컴파일러는 몇 가지 좌절스러운 오류의 원인인 컴파일된 버전에서 변수를 조용히 제거할 것이다; 이것을 명심하라!

유니폼은 현재 비어있는데, 아직 유니폼에 데이터를 추가하지 않았으니 한번 해보자. 먼저 셰이더에서 균일한 속성의 인덱스/위치를 찾아야 합니다. 유니폼의 인덱스/위치를 파악하면 값을 업데이트할 수 있습니다. 단편 셰이더에 단일 색상을 전달하는 대신, 시간이 지남에 따라 색상을 점진적으로 변경하여 분위기를 고조시키자:

```cpp
float timeValue = glfwGetTime();
float greenValue = (sin(timeValue) / 2.0f) + 0.5f;
int vertexColorLocation = glGetUniformLocation(shaderProgram, "ourColor");
glUseProgram(shaderProgram);
glUniform4f(vertexColorLocation, 0.0f, greenValue, 0.0f, 1.0f);
```

1. glfwGetTime()을 통해 실행 시간을 초 단위로 검색한다.
2. 그런 다음 sin 함수를 사용하여, 색의 range를 변경하고 결과를 greenValue에 저장합니다.
3. 그런 다음 glGetUniformLocation을 사용하여 uniform의 location의 정보를 불러온다.
4. shader 프로그램과 uniform(위치를 검색하려는)이름을 query 함수에 준다
    1. glGetUniformLocation이 반환되면, location은 X
5. glUniform4f 함수를 사용한여 uniform의 값을 설정할 수 있다. 

uniform 값을 설정하는 방법을 알았으므로 렌더링에 사용할 수 있다. 색상을 점진적으로 변경하려면 프레임마다 이 유니폼을 업데이트해야 합니다. 그렇지 않으면 한 번만 설정하면 삼각형이 단일 단색을 유지합니다.

```cpp
while(!glfwWindowShouldClose(window))
{
    // input
    processInput(window);

    // render
    // clear the colorbuffer
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    // be sure to activate the shader
    glUseProgram(shaderProgram);

    // update the uniform color
float timeValue = glfwGetTime();
float greenValue = sin(timeValue) / 2.0f + 0.5f;
int vertexColorLocation = glGetUniformLocation(shaderProgram, "ourColor");
    glUniform4f(vertexColorLocation, 0.0f, greenValue, 0.0f, 1.0f);

    // now render the triangle
    glBindVertexArray(VAO);
    glDrawArrays(GL_TRIANGLES, 0, 3);

    // swap buffers and poll IO events
    glfwSwapBuffers(window);
    glfwPollEvents();
}
```

## More attributes!

vertex data에 color data를 추가하는 방법

```cpp
float vertices[] = {
    // positions         // colors
     0.5f, -0.5f, 0.0f,  1.0f, 0.0f, 0.0f,   // bottom right
    -0.5f, -0.5f, 0.0f,  0.0f, 1.0f, 0.0f,   // bottom left
     0.0f,  0.5f, 0.0f,  0.0f, 0.0f, 1.0f    // top
};

```

Since we now have more data to send to the vertex shader, it is necessary to adjust the vertex shader to also receive our color value as a vertex attribute input. Note that we set the location of the attribute to 1 with the layout specifier: aColor

```
#version 330 core
layout (location = 0)in vec3 aPos;   // the position variable has attribute position 0
layout (location = 1)in vec3 aColor; // the color variable has attribute position 1

out vec3 ourColor; // output a color to the fragment shader

void main()
{
    gl_Position = vec4(aPos, 1.0);
    ourColor = aColor; // set ourColor to the input color we got from the vertex data
}

```

Since we no longer use a uniform for the fragment's color, but now use the output variable we'll have to change the fragment shader as well: ourColor

```
#version 330 core
out vec4 FragColor;
in vec3 ourColor;

void main()
{
    FragColor = vec4(ourColor, 1.0);
}

```

추가적인 vertex attribute를 추가하고 VBO의 메모리를 수정하였기 때문에 vertex attribute pointer를 다시 구성해야 합니다. VBO 메모리의 수정된 데이터는 다음과 같습니다.

![](attachments/vertex_attribute_pointer_interleaved.png)

현재 layout을 알고 있다면 glVertexAttribPointer 함수를 사용하여 vertex 형식을 수정할 수 있습니다.

```cpp
// position attribute
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 *sizeof(float), (void*)0);
glEnableVertexAttribArray(0);
// color attribute
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 *sizeof(float), (void*)(3*sizeof(float)));
glEnableVertexAttribArray(1);

```

glVertexAttribPointer 함수의 처음 몇개의 파라미터는 비교적 간단합니다. 이번에는 attribute location `1`의 vertex attribute를 구성합니다. 컬러 값은 `float` 타입 `3`개의 크기를 가지고 정규화 하지 않습니다.

우리는 이제 2개의 vertex attribute를 가지고 있기 때문에 *stride* 값을 다시 계산해야 합니다. 데이터 배열의 다음 attribute 값(다음 위치 vector의 `x` 요소)을 받기위해 `float` 타입 크기를 `6` 번 오른쪽으로 이동해야 하고 그 6개 중의 3개는 위치 값이고 나머지 3개는 컬러 값입니다. 이로인해 stride 값은 `float` 크기의 6배입니다(= `24` 바이트).  또한 이번에는 offset를 지정해야 합니다. 각각의 vertex에 대하여 위치 vertex attribute는 첫 번째이므로 offset을 `0`으로 설정합니다. color attribute는 위치 데이터 다음부터 시작하므로 offset은 `3 * sizeof(float)` 입니다(= `12` 바이트).

![](attachments/shaders3.png)

Check out the source code [here](https://learnopengl.com/code_viewer_gh.php?code=src/1.getting_started/3.2.shaders_interpolation/shaders_interpolation.cpp) if you're stuck.

The image may not be exactly what you would expect, since we only supplied 3 colors, not the huge color palette we're seeing right now. This is all the result of something called fragment interpolation in the fragment shader. When rendering a triangle the rasterization stage usually results in a lot more fragments than vertices originally specified. The rasterizer then determines the positions of each of those fragments based on where they reside on the triangle shape.Based on these positions, it interpolates all the fragment shader's input variables. Say for example we have a line where the upper point has a green color and the lower point a blue color. If the fragment shader is run at a fragment that resides around a position at of the line, its resulting color input attribute would then be a linear combination of green and blue; to be more precise: blue and green. `70%30%70%`

This is exactly what happened at the triangle. We have 3 vertices and thus 3 colors, and judging from the triangle's pixels it probably contains around 50000 fragments, where the fragment shader interpolated the colors among those pixels. If you take a good look at the colors you'll see it all makes sense: red to blue first gets to purple and then to blue. Fragment interpolation is applied to all the fragment shader's input attributes.

# Our own shader class

Writing, compiling and managing shaders can be quite cumbersome. As a final touch on the shader subject we're going to make our life a bit easier by building a shader class that reads shaders from disk, compiles and links them, checks for errors and is easy to use. This also gives you a bit of an idea how we can encapsulate some of the knowledge we learned so far into useful abstract objects.

We will create the shader class entirely in a header file, mainly for learning purposes and portability. Let's start by adding the required includes and by defining the class structure:

```cpp
#ifndef SHADER_H
#define SHADER_H

#include <glad/glad.h> // include glad to get all the required OpenGL headers

#include <string>
#include <fstream>
#include <sstream>
#include <iostream>

class Shader
{
public:
    // the program ID
unsignedint ID;

    // constructor reads and builds the shader
    Shader(constchar* vertexPath,constchar* fragmentPath);
    // use/activate the shader
void use();
    // utility uniform functions
void setBool(const std::string &name,bool value)const;
void setInt(const std::string &name,int value)const;
void setFloat(const std::string &name,float value)const;
};

#endif

```

헤더 파일의 맨 위에 여러 전처리기 지시문을 사용했습니다. 이러한 작은 코드 줄을 사용하면 여러 파일에 셰이더 헤더가 포함되어 있더라도 아직 포함되지 않은 경우에만 이 헤더 파일을 포함하고 컴파일하도록 컴파일러에 알립니다. 이렇게 하면 연결 충돌이 방지됩니다.

셰이더 클래스는 셰이더 프로그램의 ID를 보유합니다. 생성자에는 디스크에 간단한 텍스트 파일로 저장할 수있는 정점 및 조각 셰이더의 소스 코드 파일 경로가 각각 필요합니다. 조금 더 추가하기 위해 우리는 또한 우리의 삶을 조금 편하게하기 위해 몇 가지 유틸리티 기능을 추가합니다 : use는 셰이더 프로그램을 활성화하고 모든 set... 함수는 균일 한 위치를 쿼리하고 값을 설정합니다.

## 파일에서 읽기

C++ 파일 스트림을 사용하여 파일의 콘텐츠를 여러 개체로 읽습니다. `string`

```cpp

Shader(constchar* vertexPath,constchar* fragmentPath)
{
    // 1. retrieve the vertex/fragment source code from filePath
    std::string vertexCode;
    std::string fragmentCode;
    std::ifstream vShaderFile;
    std::ifstream fShaderFile;
    // ensure ifstream objects can throw exceptions:
    vShaderFile.exceptions (std::ifstream::failbit | std::ifstream::badbit);
    fShaderFile.exceptions (std::ifstream::failbit | std::ifstream::badbit);
try
    {
        // open files
        vShaderFile.open(vertexPath);
        fShaderFile.open(fragmentPath);
        std::stringstream vShaderStream, fShaderStream;
        // read file's buffer contents into streams
        vShaderStream << vShaderFile.rdbuf();
        fShaderStream << fShaderFile.rdbuf();
        // close file handlers
        vShaderFile.close();
        fShaderFile.close();
        // convert stream into string
        vertexCode   = vShaderStream.str();
        fragmentCode = fShaderStream.str();
    }
catch(std::ifstream::failure e)
    {
        std::cout << "ERROR::SHADER::FILE_NOT_SUCCESFULLY_READ" << std::endl;
    }
constchar* vShaderCode = vertexCode.c_str();
constchar* fShaderCode = fragmentCode.c_str();
    [...]

```

다음으로 셰이더를 컴파일하고 연결해야 합니다. 컴파일/링크가 실패했는지도 검토하고 있으며, 실패한 경우 컴파일 타임 오류를 인쇄합니다. 이것은 디버깅 할 때 매우 유용합니다 (결국 오류 로그가 필요합니다).

```cpp
// 2. compile shaders
unsignedint vertex, fragment;
int success;
char infoLog[512];

// vertex Shader
vertex = glCreateShader(GL_VERTEX_SHADER);
glShaderSource(vertex, 1, &vShaderCode, NULL);
glCompileShader(vertex);
// print compile errors if any
glGetShaderiv(vertex, GL_COMPILE_STATUS, &success);
if(!success)
{
    glGetShaderInfoLog(vertex, 512, NULL, infoLog);
    std::cout << "ERROR::SHADER::VERTEX::COMPILATION_FAILED\n" << infoLog << std::endl;
};

// similiar for Fragment Shader
[...]

// shader Program
ID = glCreateProgram();
glAttachShader(ID, vertex);
glAttachShader(ID, fragment);
glLinkProgram(ID);
// print linking errors if any
glGetProgramiv(ID, GL_LINK_STATUS, &success);
if(!success)
{
    glGetProgramInfoLog(ID, 512, NULL, infoLog);
    std::cout << "ERROR::SHADER::PROGRAM::LINKING_FAILED\n" << infoLog << std::endl;
}

// delete the shaders as they're linked into our program now and no longer necessary
glDeleteShader(vertex);
glDeleteShader(fragment);

```

use 함수는 간단합니다.

```cpp
void use()
{
    glUseProgram(ID);
}

```

균일 한 setter 함수 중 하나에 대해서도 유사하게 :

```cpp
void setBool(const std::string &name,bool value)const
{
    glUniform1i(glGetUniformLocation(ID, name.c_str()), (int)value);
}
void setInt(const std::string &name,int value)const
{
    glUniform1i(glGetUniformLocation(ID, name.c_str()), value);
}
void setFloat(const std::string &name,float value)const
{
    glUniform1f(glGetUniformLocation(ID, name.c_str()), value);
}

```

그리고 완성된 [셰이더 클래스](https://learnopengl.com/code_viewer_gh.php?code=includes/learnopengl/shader_s.h)가 있습니다. 셰이더 클래스를 사용하는 것은 매우 쉽습니다. 셰이더 오브젝트를 한 번 만들고 그 시점부터 간단히 사용하기 시작합니다.

```cpp

Shader ourShader("path/to/shaders/shader.vs", "path/to/shaders/shader.fs");
[...]
while(...)
{
    ourShader.use();
    ourShader.setFloat("someUniform", 1.0f);
    DrawStuff();
}

```

여기서는 꼭짓점과 조각 셰이더 소스 코드를 와 라는 두 개의 파일에 저장했습니다. 셰이더 파일의 이름을 원하는 대로 자유롭게 지정할 수 있습니다. 나는 개인적으로 확장 기능이 매우 직관적이라고 생각합니다. `shader.vsshader.fs.vs.fs`

여기에서 새로 만든 [셰이더 클래스를](https://learnopengl.com/code_viewer_gh.php?code=includes/learnopengl/shader_s.h) 사용하여 [소스](https://learnopengl.com/code_viewer_gh.php?code=src/1.getting_started/3.3.shaders_class/shaders_class.cpp) 코드를 찾을 수 있습니다. 셰이더 파일 경로를 클릭하여 셰이더의 소스 코드를 찾을 수 있습니다.