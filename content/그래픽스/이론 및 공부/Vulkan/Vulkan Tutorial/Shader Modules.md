# Shader Modules

이전 API와 달리, Vulkan의 셰이더 코드는 `GLSL`이나 `HLSL`과 같은 사람이 읽을 수 있는 구문이 아닌 바이트코드 형식으로 지정해야 합니다. 이 bytecode 형식은 `SPIR-V`라고 불리며, Vulkan과 OpenCL(둘 다 Khronos API)과 함께 사용하도록 설계되었습니다. 

이 형식은 그래픽 작성과 셰이더 계산에 사용할 수 있지만, 이번 튜토리얼에서는 Vulkan의 그래픽 파이프라인에서 사용되는 셰이더에 중점을 둘 것입니다.

바이트코드 형식을 사용하면 GPU 공급업체가 셰이더 코드를 네이티브 코드로 변환하기 위해 작성하는 컴파일러가 훨씬 덜 복잡하다는 장점이 있습니다. 

과거에는 GLSL과 같은 사람이 읽을 수 있는 구문을 사용할 때 일부 GPU 공급 업체가 표준 해석에 다소 유연하다는 것을 보여주었습니다. 

이러한 공급업체 중 하나의 GPU로 비자명한 셰이더를 작성하면 구문 오류로 인해 다른 공급업체의 드라이버가 코드를 거부하거나 더 나쁜 경우 컴파일러 버그로 인해 셰이더가 다르게 실행될 위험이 있습니다. SPIR-V와 같은 간단한 바이트코드 형식을 사용하면 피할 수 있기를 바랍니다.

하지만 그렇다고 해서 이 바이트코드를 수작업으로 작성할 필요는 없습니다. Khronos는 GLSL을 SPIR-V로 컴파일하는 벤더 독립 컴파일러를 출시했습니다. 

이 컴파일러는 **셰이더 코드가 완전히 표준을 준수하는지 확인하도록 설계되었으며, 프로그램과 함께 배송할 수 있는 하나의 SPIR-V 바이너리를 생성**합니다. 런타임에 SPIR-V를 생성하기 위해 이 컴파일러를 라이브러리로 포함할 수도 있지만, **이 튜토리얼에서는 이를 수행하지 않을 것입니다.** `glslangValidator.exe`를 통해 직접 이 컴파일러를 사용할 수는 있지만, 대신 Google에서 `glslc.exe`를 사용할 예정입니다. 

`glslc`의 장점은 GCC 및 Clang과 같은 잘 알려진 컴파일러와 동일한 매개변수 형식을 사용하며 추가 기능을 포함한다는 점입니다. 두 컴파일러 모두 이미 Vulkan SDK에 포함되어 있으므로 추가적인 다운로드가 필요하지 않습니다.

GLSL은 C 스타일 구문을 가진 셰이딩 언어입니다. 이 언어에 작성된 프로그램은 모든 객체에 대해 호출되는 `main` 함수를 가지고 있습니다. GLSL은 입력에 대한 매개변수와 출력에 대한 반환 값을 사용하는 대신 전역 변수를 사용하여 입력과 출력을 처리합니다.

이 언어에는 내장 vector 및 matrix primitives와 같은 그래픽 프로그래밍에 도움이 되는 많은 기능이 포함되어 있습니다.

`dot product`, `matrix-vector products` 및 `reflections around a vector`와 같은 연산을 위한 함수가 포함되어 있습니다. 벡터 유형은 요소의 양을 나타내는 숫자와 함께 `vec`라고 합니다. 

예를 들어 3D 위치는 `vec3`에 저장됩니다. 

`.x`와 같은 구성 요소를 통해 단일 구성 요소에 액세스할 수도 있지만 동시에 여러 구성 요소에서 새 벡터를 생성할 수도 있습니다. 

예를 들어 `vec3(1.0, 2.0, 3.0).xy`라는 표현은 `vec2`를 생성합니다. 

벡터의 생성자는 벡터 객체와 스칼라 값의 조합을 취할 수도 있습니다. 

예를 들어 `vec3(vec2(1.0, 2.0), 3.0)`로 `vec3`를 구성할 수 있습니다.

이전 장에서 언급 했듯이 화면에 삼각형을 만들려면 vertex shader과 fragment shader를 작성해야 합니다.

# Vertex shader

The vertex shader processes each incoming vertex. It takes its attributes, like world position, color, normal and texture coordinates as input. The output is the final position in clip coordinates and the attributes that need to be passed on to the fragment shader, like color and texture coordinates. These values will then be interpolated over the fragments by the rasterizer to produce a smooth gradient.

A *clip coordinate* is a four dimensional vector from the vertex shader that is subsequently turned into a *normalized device coordinate* by dividing the whole vector by its last component. These normalized device coordinates are [homogeneous coordinates](https://en.wikipedia.org/wiki/Homogeneous_coordinates) that map the framebuffer to a [-1, 1] by [-1, 1] coordinate system that looks like the following:

![[/image.png]]

You should already be familiar with these if you have dabbled in computer graphics before. If you have used OpenGL before, then you'll notice that the sign of the Y coordinates is now flipped. The Z coordinate now uses the same range as it does in Direct3D, from 0 to 1.

For our first triangle we won't be applying any transformations, we'll just specify the positions of the three vertices directly as normalized device coordinates to create the following shape:

![](attachments/triangle_coordinates.svg)

We can directly output normalized device coordinates by outputting them as clip coordinates from the vertex shader with the last component set to `1`. That way the division to transform clip coordinates to normalized device coordinates will not change anything.

Normally these coordinates would be stored in a vertex buffer, but creating a vertex buffer in Vulkan and filling it with data is not trivial. Therefore I've decided to postpone that until after we've had the satisfaction of seeing a triangle pop up on the screen. We're going to do something a little unorthodox in the meanwhile: include the coordinates directly inside the vertex shader. The code looks like this:

```glsl
#version 450

vec2 positions[3] = vec2[](
    vec2(0.0, -0.5),
    vec2(0.5, 0.5),
    vec2(-0.5, 0.5)
);

void main() {
    gl_Position = vec4(positions[gl_VertexIndex], 0.0, 1.0);
}

```

The `main` function is invoked for every vertex. The built-in `gl_VertexIndex` variable contains the index of the current vertex. This is usually an index into the vertex buffer, but in our case it will be an index into a hardcoded array of vertex data. The position of each vertex is accessed from the constant array in the shader and combined with dummy `z` and `w` components to produce a position in clip coordinates. The built-in variable `gl_Position` functions as the output.

# Fragment shader

The triangle that is formed by the positions from the vertex shader fills an area on the screen with fragments. The fragment shader is invoked on these fragments to produce a color and depth for the framebuffer (or framebuffers). A simple fragment shader that outputs the color red for the entire triangle looks like this:

```glsl
#version 450

layout(location = 0) out vec4 outColor;

void main() {
    outColor = vec4(1.0, 0.0, 0.0, 1.0);
}

```

The `main` function is called for every fragment just like the vertex shader `main` function is called for every vertex. Colors in GLSL are 4-component vectors with the R, G, B and alpha channels within the [0, 1] range. Unlike `gl_Position` in the vertex shader, there is no built-in variable to output a color for the current fragment. You have to specify your own output variable for each framebuffer where the `layout(location = 0)` modifier specifies the index of the framebuffer. The color red is written to this `outColor` variable that is linked to the first (and only) framebuffer at index `0`.

# Per-vertex colors

Making the entire triangle red is not very interesting, wouldn't something like the following look a lot nicer?

![](attachments/triangle_coordinates_colors.png)

We have to make a couple of changes to both shaders to accomplish this. First off, we need to specify a distinct color for each of the three vertices. The vertex shader should now include an array with colors just like it does for positions:

```glsl
vec3 colors[3] = vec3[](
    vec3(1.0, 0.0, 0.0),
    vec3(0.0, 1.0, 0.0),
    vec3(0.0, 0.0, 1.0)
);

```

Now we just need to pass these per-vertex colors to the fragment shader so it can output their interpolated values to the framebuffer. Add an output for color to the vertex shader and write to it in the `main` function:

```glsl
layout(location = 0) out vec3 fragColor;

void main() {
    gl_Position = vec4(positions[gl_VertexIndex], 0.0, 1.0);
    fragColor = colors[gl_VertexIndex];
}

```

Next, we need to add a matching input in the fragment shader:

```glsl
layout(location = 0) in vec3 fragColor;

void main() {
    outColor = vec4(fragColor, 1.0);
}

```

The input variable does not necessarily have to use the same name, they will be linked together using the indexes specified by the `location` directives. The `main` function has been modified to output the color along with an alpha value. As shown in the image above, the values for `fragColor` will be automatically interpolated for the fragments between the three vertices, resulting in a smooth gradient.

# Compiling the shaders

Create a directory called `shaders` in the root directory of your project and store the vertex shader in a file called `shader.vert` and the fragment shader in a file called `shader.frag` in that directory. GLSL shaders don't have an official extension, but these two are commonly used to distinguish them.

The contents of `shader.vert` should be:

```glsl
#version 450

layout(location = 0) out vec3 fragColor;

vec2 positions[3] = vec2[](
    vec2(0.0, -0.5),
    vec2(0.5, 0.5),
    vec2(-0.5, 0.5)
);

vec3 colors[3] = vec3[](
    vec3(1.0, 0.0, 0.0),
    vec3(0.0, 1.0, 0.0),
    vec3(0.0, 0.0, 1.0)
);

void main() {
    gl_Position = vec4(positions[gl_VertexIndex], 0.0, 1.0);
    fragColor = colors[gl_VertexIndex];
}

```

And the contents of `shader.frag` should be:

```glsl
#version 450

layout(location = 0) in vec3 fragColor;

layout(location = 0) out vec4 outColor;

void main() {
    outColor = vec4(fragColor, 1.0);
}

```

We're now going to compile these into SPIR-V bytecode using the `glslc` program.

**Windows**

Create a `compile.bat` file with the following contents:

```bash
C:/VulkanSDK/x.x.x.x/Bin32/glslc.exe shader.vert -o vert.spv
C:/VulkanSDK/x.x.x.x/Bin32/glslc.exe shader.frag -o frag.spv
pause

```

Replace the path to `glslc.exe` with the path to where you installed the Vulkan SDK. Double click the file to run it.

**Linux**

Create a `compile.sh` file with the following contents:

```bash
/home/user/VulkanSDK/x.x.x.x/x86_64/bin/glslc shader.vert -o vert.spv
/home/user/VulkanSDK/x.x.x.x/x86_64/bin/glslc shader.frag -o frag.spv

```

Replace the path to `glslc` with the path to where you installed the Vulkan SDK. Make the script executable with `chmod +x compile.sh` and run it.

**End of platform-specific instructions**

These two commands tell the compiler to read the GLSL source file and output a SPIR-V bytecode file using the `-o` (output) flag.

If your shader contains a syntax error then the compiler will tell you the line number and problem, as you would expect. Try leaving out a semicolon for example and run the compile script again. Also try running the compiler without any arguments to see what kinds of flags it supports. It can, for example, also output the bytecode into a human-readable format so you can see exactly what your shader is doing and any optimizations that have been applied at this stage.

Compiling shaders on the commandline is one of the most straightforward options and it's the one that we'll use in this tutorial, but it's also possible to compile shaders directly from your own code. The Vulkan SDK includes [libshaderc](https://github.com/google/shaderc), which is a library to compile GLSL code to SPIR-V from within your program.

# Loading a shader

Now that we have a way of producing SPIR-V shaders, it's time to load them into our program to plug them into the graphics pipeline at some point. We'll first write a simple helper function to load the binary data from the files.

```c
#include <fstream>

...

static std::vector<char> readFile(const std::string& filename) {
    std::ifstream file(filename, std::ios::ate | std::ios::binary);

    if (!file.is_open()) {
        throw std::runtime_error("failed to open file!");
    }
}

```

The `readFile` function will read all of the bytes from the specified file and return them in a byte array managed by `std::vector`. We start by opening the file with two flags:

- `ate`: Start reading at the end of the file
- `binary`: Read the file as binary file (avoid text transformations)

The advantage of starting to read at the end of the file is that we can use the read position to determine the size of the file and allocate a buffer:

```c
size_t fileSize = (size_t) file.tellg();
std::vector<char> buffer(fileSize);
```

After that, we can seek back to the beginning of the file and read all of the bytes at once:

```c
file.seekg(0);
file.read(buffer.data(), fileSize);
```

And finally close the file and return the bytes:

```c
file.close();

return buffer;
```

We'll now call this function from `createGraphicsPipeline` to load the bytecode of the two shaders:

```c
void createGraphicsPipeline() {
    auto vertShaderCode = readFile("shaders/vert.spv");
    auto fragShaderCode = readFile("shaders/frag.spv");
}

```

Make sure that the shaders are loaded correctly by printing the size of the buffers and checking if they match the actual file size in bytes. Note that the code doesn't need to be null terminated since it's binary code and we will later be explicit about its size.

# Creating shader modules

Let's create a helper function `createShaderModule` to do that.

```c
VkShaderModule createShaderModule(const std::vector<char>& code) {

}

```

함수는 바이트코드를 매개변수로 하는 버퍼를 가져와 이를 통해 [`VkShaderModule`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkShaderModule.html)을 생성합니다.

셰이더 모듈을 만드는 것은 간단합니다. `바이트 코드`와 `그 길이를 가진 버퍼`의 `포인터`만 지정하면 됩니다. 

이 정보는 [`VkShaderModuleCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkShaderModuleCreateInfo.html)구조로 지정되어 있습니다. 

한 가지 문제는 바이트 코드의 크기가 지정되어 있지만 바이트 코드 포인터가 `char`포인터가 아닌 `uint32_t`포인터라는 것입니다. 

따라서 아래와 같이 포인터를 `reinfrete_cast`로 캐스팅해야 합니다. 이러한 캐스트를 수행할 때도 데이터가 `uint32_t`의 정렬 요구 사항을 충족하는지 확인해야 합니다. 다행히 데이터는 기본 할당자가 이미 최악의 경우 정렬 요구 사항을 충족하도록 보장하는 `std:vector`에 저장됩니다.

```c
VkShaderModuleCreateInfo createInfo{};
createInfo.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
createInfo.codeSize = code.size();
createInfo.pCode = reinterpret_cast<const uint32_t*>(code.data());
```

The [`VkShaderModule`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkShaderModule.html) can then be created with a call to [`vkCreateShaderModule`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCreateShaderModule.html):

```cpp
VkShaderModule shaderModule;
if (vkCreateShaderModule(device, &createInfo, nullptr, &shaderModule) != VK_SUCCESS) {
    throw std::runtime_error("failed to create shader module!");
}
```

The parameters are the same as those in previous object creation functions: the logical device, pointer to create info structure, optional pointer to custom allocators and handle output variable. The buffer with the code can be freed immediately after creating the shader module. Don't forget to return the created shader module:

```cpp
return shaderModule;
```

Shader modules are just a thin wrapper around the shader bytecode that we've previously loaded from a file and the functions defined in it. The compilation and linking of the SPIR-V bytecode to machine code for execution by the GPU doesn't happen until the graphics pipeline is created. That means that we're allowed to destroy the shader modules again as soon as pipeline creation is finished, which is why we'll make them local variables in the `createGraphicsPipeline` function instead of class members:

```c
void createGraphicsPipeline() {
    auto vertShaderCode = readFile("shaders/vert.spv");
    auto fragShaderCode = readFile("shaders/frag.spv");

    VkShaderModule vertShaderModule = createShaderModule(vertShaderCode);
    VkShaderModule fragShaderModule = createShaderModule(fragShaderCode);

```

The cleanup should then happen at the end of the function by adding two calls to [`vkDestroyShaderModule`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkDestroyShaderModule.html). All of the remaining code in this chapter will be inserted before these lines.

```c
    ...
    vkDestroyShaderModule(device, fragShaderModule, nullptr);
    vkDestroyShaderModule(device, vertShaderModule, nullptr);
}

```

# Shader stage creation

To actually use the shaders we'll need to assign them to a specific pipeline stage through [`VkPipelineShaderStageCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkPipelineShaderStageCreateInfo.html) structures as part of the actual pipeline creation process.

We'll start by filling in the structure for the vertex shader, again in the `createGraphicsPipeline` function.

```c
VkPipelineShaderStageCreateInfo vertShaderStageInfo{};
vertShaderStageInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
vertShaderStageInfo.stage = VK_SHADER_STAGE_VERTEX_BIT;
```

The first step, besides the obligatory `sType` member, is telling Vulkan in which pipeline stage the shader is going to be used. There is an enum value for each of the programmable stages described in the previous chapter.

```c
vertShaderStageInfo.module = vertShaderModule;
vertShaderStageInfo.pName = "main";
```

The next two members specify the shader module containing the code, and the function to invoke, known as the *entrypoint*. That means that it's possible to combine multiple fragment shaders into a single shader module and use different entry points to differentiate between their behaviors. In this case we'll stick to the standard `main`, however.

There is one more (optional) member, `pSpecializationInfo`, which we won't be using here, but is worth discussing. It allows you to specify values for shader constants. You can use a single shader module where its behavior can be configured at pipeline creation by specifying different values for the constants used in it. This is more efficient than configuring the shader using variables at render time, because the compiler can do optimizations like eliminating `if` statements that depend on these values. If you don't have any constants like that, then you can set the member to `nullptr`, which our struct initialization does automatically.

Modifying the structure to suit the fragment shader is easy:

```c
VkPipelineShaderStageCreateInfo fragShaderStageInfo{};
fragShaderStageInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
fragShaderStageInfo.stage = VK_SHADER_STAGE_FRAGMENT_BIT;
fragShaderStageInfo.module = fragShaderModule;
fragShaderStageInfo.pName = "main";

```

Finish by defining an array that contains these two structs, which we'll later use to reference them in the actual pipeline creation step.

```c
VkPipelineShaderStageCreateInfo shaderStages[] = {vertShaderStageInfo, fragShaderStageInfo};

```

That's all there is to describing the programmable stages of the pipeline. In the next chapter we'll look at the fixed-function stages.