## BRDF
Bidirectional Reflectance Distribution Function
양방향 반사율 분포 함수
-> 빛이 들어오는 방향, 빛이 반사되서 나가는 방향이 있으면, 반사율을 알 수 있는 식이다.
## BRDF LUT
빛의 입사각,빛의  반사각, 금속성, 거칠기 정도를 가지고 반사 광선을 미리 계산한 2d texture 이다.

# Diffuse
## irradiance
거칠기 값이 높아지면 환경맵(skymap)에 흩어져있는 샘플 벡터가 뒤얽혀 반사가 더 흐려진다.
표준 및 시야 방향 모두를 입력으로 사용하는 Cook-Torrance BRDF의 정규 분포 함수(NDF)를 사용해 샘플 벡터와 산란 강도를 생성한다.

Cook-Torrance BRDF의 정규 분포 함수(NDF)를 사용하여 샘플 벡터와 그 산란량을 생성합니다. 
이 함수는 법선 방향과 시점 방향을 모두 입력으로 받습니다. 환경 맵을 컨볼루션할 때 시점 방향을 미리 알 수 없기 때문에, 에픽게임즈는 시점 방향(따라서 정반사 방향)을 출력 샘플 방향과 같다고 가정하여 추가적인 근사값을 구합니다.

```cpp
vec3 N = normalize(w_o);
vec3 R = N;
vec3 V = R;
```
## Irradiance Map

•	물체 표면의 각 점에서 받는 **확산 조명(diffuse lighting)을 미리 계산한 큐브맵
•	환경 조명의 낮은 주파수 성분을 캡처
•	실시간 렌더링에서 복잡한 반구 적분을 룩업 테이블로 대체

tags: #PBR #그래픽스 #OpenGL #IBL #IrradianceMap 
source: https://learnopengl.com/PBR/IBL/Diffuse-irradiance

# PBR: Irradiance Map 생성 (Diffuse IBL)

물리 기반 렌더링(PBR)에서 이미지 기반 조명(Image-Based Lighting, IBL)을 구현할 때, 확산(Diffuse) 반사를 처리하기 위해 사용하는 **Irradiance Map** 생성 과정을 정리합니다.

## Irradiance Map이란 무엇인가?

**Irradiance(조도)**는 특정 표면 지점에 도달하는 모든 방향의 빛 에너지의 총합입니다. 실시간으로 표면의 각 점마다 주변 환경(반구, Hemisphere)의 모든 빛을 계산하는 것은 연산량이 너무 많아 불가능합니다.

**Irradiance Map**은 이 복잡한 적분 계산을 **미리 한 번만 수행**하여 그 결과를 큐브맵 텍스처에 저장해 둔 것입니다. 이 맵은 특정 방향(`N`)을 향하는 표면이 받게 될 **총 확산광의 색상**을 담고 있습니다.

> [!TIP] 핵심 비유
> Irradiance Map은 원본 환경 맵(Environment Map)을 **아주 흐릿하게(Blurry) 만든 버전**이라고 생각할 수 있습니다. 확산 반사는 빛이 들어오는 정확한 방향보다는 전반적인 빛의 색상과 강도에 더 영향을 받기 때문입니다.

---

## Irradiance Map을 만드는 원리: 컨볼루션 (Convolution)

Irradiance Map을 생성하는 과정은 수학적으로 **컨볼루션(Convolution)**이라고 부릅니다. 이는 환경 맵의 모든 빛에 대해 렌더링 방정식의 **확산 부분(반사율 적분)**을 미리 계산하는 것과 같습니다.

```
Lo(p, ωo) = kd * (c/π) * ∫Ω Li(p, ωi) (n · ωi) dωi
```

- **∫Ω**: 표면 위쪽의 반구(hemisphere) 전체에 대해 적분(모든 값을 더함).
- **Li(p, ωi)**: 특정 방향(`ωi`)에서 들어오는 빛 (원본 환경 맵의 픽셀 값).
- **(n · ωi)**: 표면 법선(`n`)과 입사광 방향(`ωi`)의 내적. 빛이 표면을 비스듬히 비출수록 빛의 양이 줄어드는 효과(코사인 가중치).

이 복잡한 적분을 미리 계산하여 텍스처에 저장하는 것이 목표입니다.

---
## Irradiance Map 생성 과정 (Step-by-Step)

이 과정은 런타임이 아닌, 로딩 시 또는 별도의 오프라인 프로세스에서 단 한 번만 실행됩니다.

### 1. 준비물: HDR 환경 맵과 큐브맵

먼저, 고화질 동적 범위(HDR) 환경 맵(`.hdr` 파일)을 로드하여 3D 큐브맵(`envCubemap`)으로 변환합니다. 이 큐브맵이 Irradiance 계산의 원본 데이터가 됩니다.

### 2. 최종 결과물을 담을 빈 큐브맵 생성

Irradiance 계산 결과를 저장할 새로운 큐브맵을 생성합니다.

- **저해상도(Low-Resolution):** Irradiance는 저주파(low-frequency) 데이터이므로 고해상도가 필요 없습니다. 보통 **32x32**나 64x64 정도의 작은 크기로 충분합니다.

```cpp
unsigned int irradianceMap;
glGenTextures(1, &irradianceMap);
glBindTexture(GL_TEXTURE_CUBE_MAP, irradianceMap);
for (unsigned int i = 0; i < 6; ++i)
{
    // 32x32 크기의 빈 텍스처를 큐브맵의 각 면에 할당
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_RGB16F, 32, 32, 0, GL_RGB, GL_FLOAT, nullptr);
}
glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
```

### 3. 렌더링을 위한 프레임버퍼(FBO) 설정

생성된 Irradiance 큐브맵의 각 면에 렌더링하기 위해 프레임버퍼(FBO)를 설정합니다.

```cpp
unsigned int captureFBO, captureRBO;
glGenFramebuffers(1, &captureFBO);
glGenRenderbuffers(1, &captureRBO);

glBindFramebuffer(GL_FRAMEBUFFER, captureFBO);
glBindRenderbuffer(GL_RENDERBUFFER, captureRBO);
glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, 32, 32); // Irradiance Map 크기와 동일하게
glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, captureRBO);
```

### 4. 컨볼루션 셰이더 작성

#### Vertex Shader
정점 위치를 클립 공간 좌표로 변환하고, 월드 공간 위치를 프래그먼트 셰이더로 넘겨줍니다. 이 월드 공간 위치가 큐브맵을 샘플링할 방향 벡터가 됩니다.

```glsl
#version 330 core
layout (location = 0) in vec3 aPos;

out vec3 WorldPos;

uniform mat4 projection;
uniform mat4 view;

void main()
{
    WorldPos = aPos;  
    gl_Position =  projection * view * vec4(WorldPos, 1.0);
}
```

#### Fragment Shader (핵심 로직)
큐브의 각 픽셀 위치(`WorldPos`)를 법선 벡터 `N`으로 간주하고, `N`을 중심으로 하는 반구 내에서 여러 방향으로 샘플링하여 평균을 냅니다.

```glsl
#version 330 core
out vec4 FragColor;
in vec3 WorldPos;

uniform samplerCube environmentMap;

const float PI = 3.14159265359;

void main()
{		
    // WorldPos를 정규화하여 현재 픽셀이 계산할 법선 벡터 N으로 사용
    vec3 N = normalize(WorldPos);
    vec3 irradiance = vec3(0.0);   
    
    // N을 중심으로 하는 접선 공간(tangent space) 생성
    vec3 up    = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(up, N));
    up       = normalize(cross(N, right));
       
    float sampleDelta = 0.025;
    int nrSamples = 0; 
    // 반구 전체를 순회하며 샘플링 (적분 근사)
    for(float phi = 0.0; phi < 2.0 * PI; phi += sampleDelta)
    {
        for(float theta = 0.0; theta < 0.5 * PI; theta += sampleDelta)
        {
            // 구면 좌표계를 사용하여 샘플 방향 벡터 생성
            vec3 tangentSample = vec3(sin(theta) * cos(phi),  sin(theta) * sin(phi), cos(theta));
            // 접선 공간 샘플을 월드 공간으로 변환
            vec3 sampleVec = tangentSample.x * right + tangentSample.y * up + tangentSample.z * N; 

            // 샘플 방향으로 환경 맵을 조회하고, 코사인 가중치를 적용하여 누적
            irradiance += texture(environmentMap, sampleVec).rgb * cos(theta) * sin(theta);
            nrSamples++;
        }
    }
    // 샘플 수와 적분 상수로 정규화
    irradiance = PI * irradiance * (1.0 / float(nrSamples));
    
    FragColor = vec4(irradiance, 1.0);
}
```

### 5. 큐브맵의 6개 면에 렌더링 실행

루프를 돌며 큐브맵의 6개 면(+X, -X, +Y, -Y, +Z, -Z)에 각각 렌더링을 수행합니다.

1. 컨볼루션 셰이더를 활성화합니다.
2. 원본 환경 맵(`envCubemap`)을 셰이더에 바인딩합니다.
3. 6개의 `view` 행렬과 90도 `projection` 행렬을 준비합니다.
4. FBO를 바인딩하고 뷰포트를 Irradiance Map 크기(32x32)로 설정합니다.
5. 루프를 돌며 `glFramebufferTexture2D`를 사용하여 렌더링 대상을 큐브맵의 각 면으로 지정하고 큐브를 그립니다.

---

## Irradiance Map 사용법

이제 PBR 렌더링 파이프라인의 최종 셰이더에서 이 `irradianceMap`을 사용합니다.

```glsl
// PBR Fragment Shader
uniform samplerCube irradianceMap;
// ...

void main()
{
    // ...
    vec3 N = normalize(v_Normal); // 프래그먼트의 법선 벡터
    
    // Irradiance Map에서 법선 방향에 해당하는 미리 계산된 확산광을 조회
    vec3 irradiance = texture(irradianceMap, N).rgb;
    
    // 알베도와 곱하여 최종 확산광 계산
    vec3 diffuse = irradiance * albedo;
    
    // ... 나머지 반사(specular) 계산과 합산 ...
    vec3 Lo = (kD * diffuse) + specular; 
    // ...
}
```

> [!SUCCESS] 핵심 요약
> 복잡한 실시간 적분 계산이 `texture(irradianceMap, N)` 라는 단 한 번의 텍스처 조회로 대체되어 엄청난 성능 향상을 가져옵니다. 이것이 바로 이미지 기반 조명(IBL)의 핵심 원리입니다.

tags: #PBR #그래픽스 #OpenGL #IBL #Specular #LUT
source: https://learnopengl.com/PBR/IBL/Specular-IBL

# PBR: Specular IBL (Pre-filtered Map & BRDF LUT)

Irradiance Map으로 확산(Diffuse) 반사를 처리했다면, 이제 반사광(Specular) 부분을 처리할 차례입니다. 확산 반사와 달리 반사광은 **표면의 거칠기(Roughness)**와 **바라보는 방향(View Direction)**에 따라 크게 달라집니다.

- **매끄러운 표면(Roughness = 0)**: 거울처럼 주변 환경을 선명하게 반사합니다.
- **거친 표면(Roughness = 1)**: 주변 환경을 넓고 흐릿하게 반사합니다.

이러한 복잡성 때문에, Irradiance Map처럼 단순히 하나의 흐릿한 맵만으로는 반사광을 표현할 수 없습니다.

> [!NOTE] 분할 합 근사법 (Split Sum Approximation)
> 반사광을 계산하는 렌더링 방정식의 적분은 너무 복잡해서 실시간으로 풀 수 없습니다. Epic Games에서 발표한 이 기법은 적분을 두 개의 분리된 부분으로 나누어 각각 미리 계산하고, 런타임에 이 둘의 결과를 조합하여 근사치를 구합니다.
>
> **Specular Integral ≈ (Part 1: Pre-filtered Env Map) ⊗ (Part 2: BRDF LUT)**

---

## 1. Pre-filtered Environment Map

이것이 분할 합 근사법의 첫 번째 부분입니다.

### 개념

**Pre-filtered Environment Map**은 원본 환경 맵을 **다양한 거칠기(Roughness) 레벨에 따라 미리 흐릿하게(pre-filter) 만들어 놓은 맵**입니다. 이 맵은 여러 개의 밉맵(Mipmap) 레벨을 가지며, 각 밉맵 레벨이 특정 거칠기에 해당하는 반사 결과를 저장합니다.

- **Mipmap Level 0**: Roughness 0.0에 해당. 원본 환경 맵처럼 선명한 상태.
- **Mipmap Level 1**: 약간의 Roughness. 조금 흐릿한 상태.
- **Mipmap Level N (마지막)**: Roughness 1.0에 해당. 매우 흐릿한 상태.

![Prefilter Mipmap Levels](attachments/ibl_prefilter_map.png)
*(거칠기가 증가할수록 (밉맵 레벨이 높아질수록) 맵이 점점 더 흐려지는 것을 볼 수 있습니다.)*

### 생성 과정

1.  **결과를 저장할 큐브맵 생성**: Irradiance Map과 유사하지만, 밉맵 레벨을 가질 수 있도록 설정합니다. 보통 128x128과 같이 좀 더 높은 해상도로 시작합니다.

    ```cpp
    unsigned int prefilterMap;
    glGenTextures(1, &prefilterMap);
    glBindTexture(GL_TEXTURE_CUBE_MAP, prefilterMap);
    for (unsigned int i = 0; i < 6; ++i)
    {
        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_RGB16F, 128, 128, 0, GL_RGB, GL_FLOAT, nullptr);
    }
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    // ... (WRAP_T, WRAP_R 설정)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR); // 밉맵 필터링 활성화!
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glGenerateMipmap(GL_TEXTURE_CUBE_MAP); // 밉맵을 위한 메모리 할당
    ```

2.  **Pre-filter 컨볼루션 셰이더 작성**: 이 셰이더는 각 밉맵 레벨에 해당하는 흐릿한 이미지를 생성합니다.
    - 셰이더는 `roughness` 값을 입력받습니다.
    - 법선 `N`과 시선 `V`가 같다고 가정하고 반사 벡터 `R`을 계산합니다(`R=N`).
    - **중요도 샘플링(Importance Sampling)**을 사용하여 `roughness`에 따라 GGX 분포를 따르는 샘플 벡터들을 생성합니다. 거칠수록 샘플 벡터들이 넓은 원뿔(cone) 모양으로 퍼집니다.
    - 이 샘플 벡터들을 사용하여 원본 환경 맵을 여러 번 샘플링하고, 그 결과의 평균을 내어 최종 색상을 계산합니다.

    ```glsl
    // Pre-filter Fragment Shader
    #version 330 core
    out vec4 FragColor;
    in vec3 WorldPos;

    uniform samplerCube environmentMap;
    uniform float roughness;

    const float PI = 3.14159265359;
    // ... (Hammersley, ImportanceSampleGGX 등 유틸리티 함수) ...

    void main()
    {
        vec3 N = normalize(WorldPos);
        vec3 R = N;
        vec3 V = R;

        const uint SAMPLE_COUNT = 1024u;
        float totalWeight = 0.0;
        vec3 prefilteredColor = vec3(0.0);
        for(uint i = 0u; i < SAMPLE_COUNT; ++i)
        {
            vec2 Xi = Hammersley(i, SAMPLE_COUNT);
            vec3 H  = ImportanceSampleGGX(Xi, N, roughness);
            vec3 L  = normalize(2.0 * dot(V, H) * H - V);

            float NdotL = max(dot(N, L), 0.0);
            if(NdotL > 0.0)
            {
                prefilteredColor += texture(environmentMap, L).rgb * NdotL;
                totalWeight      += NdotL;
            }
        }
        prefilteredColor = prefilteredColor / totalWeight;
        FragColor = vec4(prefilteredColor, 1.0);
    }
    ```

3.  **밉맵 레벨 별 렌더링**: 루프를 돌면서 밉맵 레벨 0부터 마지막 레벨까지 렌더링을 수행합니다. 각 루프마다 `roughness` 값을 `0.0`에서 `1.0`으로 증가시키고, FBO의 렌더링 대상을 해당 밉맵 레벨로 지정합니다.

### 사용법

최종 PBR 셰이더에서 반사 벡터 `R`과 재질의 `roughness`를 사용하여 이 맵을 샘플링합니다. `roughness` 값은 어떤 밉맵 레벨을 읽을지 결정하는 데 사용됩니다.

```glsl
float roughness = material.roughness;
vec3 R = reflect(-V, N);
vec3 prefilteredColor = textureLod(prefilterMap, R, roughness * 4.0).rgb; // 4.0은 최대 밉맵 레벨
```

---

## 2. BRDF Integration Map (LUT)

이것이 분할 합 근사법의 두 번째 부분입니다.

### 개념

분할된 적분의 두 번째 부분은 **환경 맵에 전혀 의존하지 않고**, 오직 **시선 각도(`NdotV`)**와 **표면 거칠기(`roughness`)**에만 의존합니다. 이 두 입력 값에 대한 적분 결과를 미리 계산하여 2D 텍스처에 저장해 둘 수 있는데, 이것이 바로 **BRDF Integration Map** 또는 **BRDF 조회 테이블(LookUp Table, LUT)**입니다.

- **X축**: `NdotV` (표면 법선과 시선 벡터의 내적, 0.0 ~ 1.0)
- **Y축**: `roughness` (거칠기, 0.0 ~ 1.0)
- **저장되는 값 (R, G 채널)**: 적분 결과인 **Scale**과 **Bias**. 이 값들은 런타임에 프레넬(Fresnel) 방정식을 근사하는 데 사용됩니다.

![BRDF LUT](attachments/ibl_brdf_lut.png)
*(생성된 2D BRDF LUT. 붉은색은 Scale, 녹색은 Bias를 나타낸다.)*

### 생성 과정

1.  **결과를 저장할 2D 텍스처 생성**: 512x512 크기의 2채널 부동소수점 텍스처(RG16F)를 생성합니다.

    ```cpp
    unsigned int brdfLUTTexture;
    glGenTextures(1, &brdfLUTTexture);
    glBindTexture(GL_TEXTURE_2D, brdfLUTTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RG16F, 512, 512, 0, GL_RG, GL_FLOAT, 0);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    // ... (WRAP_T, MIN/MAG_FILTER 설정)
    ```

2.  **BRDF 통합(Integration) 셰이더 작성**: 화면 크기의 사각형을 렌더링하면서, 각 픽셀의 텍스처 좌표(`texCoord.x` -> `NdotV`, `texCoord.y` -> `roughness`)를 입력으로 받아 적분을 수행합니다.

    ```glsl
    // BRDF Integration Fragment Shader
    #version 330 core
    out vec2 FragColor;
    in vec2 TexCoords;

    const float PI = 3.14159265359;
    // ... (GeometrySchlickGGX, GeometrySmith 등 유틸리티 함수) ...

    // BRDF 적분을 계산하는 함수
    vec2 IntegrateBRDF(float NdotV, float roughness)
    {
        // ... (중요도 샘플링을 사용한 몬테카를로 적분 로직) ...
        // ... 함수는 Scale(A)과 Bias(B) 값을 반환 ...
        return vec2(A, B);
    }

    void main()
    {
        vec2 integratedBRDF = IntegrateBRDF(TexCoords.x, TexCoords.y);
        FragColor = integratedBRDF;
    }
    ```

3.  **FBO에 렌더링**: FBO에 이 2D 텍스처를 첨부하고 사각형을 한 번만 렌더링하면 `brdfLUTTexture`가 완성됩니다.

### 사용법

최종 PBR 셰이더에서 현재 프래그먼트의 `NdotV` 값과 재질의 `roughness`를 텍스처 좌표로 사용하여 이 LUT를 샘플링합니다.

```glsl
float NdotV = max(dot(N, V), 0.0);
float roughness = material.roughness;
vec2 brdf = texture(brdfLUT, vec2(NdotV, roughness)).rg;
```

---

## 최종 조합

이제 미리 계산된 두 텍스처를 사용하여 최종 반사광을 계산합니다.

```glsl
// 최종 PBR 셰이더 내부
void main()
{
    // ... (기본 변수 설정) ...

    vec3 F = fresnelSchlick(NdotV, F0); // 프레넬 항 계산

    // 1. Pre-filtered Map에서 환경 반사광 샘플링
    vec3 prefilteredColor = textureLod(prefilterMap, R, roughness * 4.0).rgb;

    // 2. BRDF LUT에서 Scale과 Bias 샘플링
    vec2 brdf  = texture(brdfLUT, vec2(NdotV, roughness)).rg;

    // 3. 두 결과를 조합하여 최종 Specular IBL 계산
    vec3 specular = prefilteredColor * (F * brdf.x + brdf.y);

    // ... (확산광(Diffuse IBL)과 합산) ...
    vec3 Lo = (kD * diffuse) + specular;
    // ...
}
```

> [!SUCCESS] 핵심 요약
> - **Pre-filtered Environment Map**: 다양한 `roughness`에 대한 환경 반사 결과를 밉맵에 저장합니다.
> - **BRDF LUT**: `NdotV`와 `roughness`에 따른 프레넬 보정값(Scale, Bias)을 2D 텍스처에 저장합니다.
>
> 이 두 가지를 미리 계산해 둠으로써, 실시간 셰이더에서는 단 두 번의 텍스처 조회와 간단한 연산만으로 매우 사실적인 반사광을 구현할 수 있습니다.