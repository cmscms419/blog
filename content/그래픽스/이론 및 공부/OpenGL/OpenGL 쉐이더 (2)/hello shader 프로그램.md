# hello shader 프로그램

### GLuint **glCreateShader**( GLenumshaderType);

- shader 자료형 : **GL_VERTEX_SHADER**, **GL_FRAGMENT_SHADER**
- shaderID 값을 return한다.

### void **glShaderSource**( GLuint shaderID, GLsizei count, const GLchar** string, const GLint* length );

- shader의 “string”에서 shader code를 다운 받습니다.
- 보통 1개의 소스를 사용한다.

### void **glCompileShader**( GLuint shaderID );

- 소스코드를 obj 파일로 컴파일 한다.
- Opengl program 전체로는 여러 개의 shader가 존재 가능하다.

### GLuint **glCreateProgram**( void )

- shader program을 만든다
- programID를 return 한다.

### void **glAttachShader**( GLuint programID, GLuint shaderID );

- program에게 shader를 붙입니다.
- 주의 : vertex shader와 fragment shader만 붙일 수 있다.

### void **glLinkProgram**( GLunit programID )

- shader obj를 프로그램에 연결한다.

### void **glUseProgram**( GLuint programID );

- GPU에 프로그램을 설치한다.
- Opengl program 전체로는 여러 개의 shader가 존재 가능하다.

### GLint glGetAttribLocation( GLuint programID, const GLchar* name )

- shader program의 name의 위치를 가져옵니다.
- vertex attribute의 index 값을 return

void glEnableVertexAttribArray( GLuint index )

- vertex array를 turn on 합니다.

void glDisableVertexAttribArray( GLuint index )

- vertex array를 turn off 합니다.

### void glFinish( void )

- OpenGL call을 종료합니다.

**void glVertexAttribPointer(GLuint index, GLint size, GLenumtype, GLboolean normalized, GLsizei stride, const GLvoid* pointer)**

- 사용자가 제공한다. "array" → pointer
- size : 1, 2, 3, 4 → float, vec2, vec3, vec4 in shader program
- type : GL_INT, GL_FLOAT, …
- normalized : usually GL_FALSE
- stride : usually 0
- pointer : start address of the array

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(2)/hello%20shader%20프로그램/Untitled.png)

### void glDrawArrays( GLenum mode, GLint first, GLsizei count )

- 그래픽 파이프라인을 통해서 결과를 얻기 위한 트리거 역할을 한다.
- mode = GL_POINTS, GL_LINES, GL_TRIANGLES, …
- first : attribute arrays의 시작 index를 의미한다.
- count : attribute arrays의 정점의 개수

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(2)/hello%20shader%20프로그램/Untitled%201.png)

![Untitled](그래픽스/이론%20및%20공부/OpenGL/OpenGL%20쉐이더%20(2)/hello%20shader%20프로그램/Untitled%202.png)