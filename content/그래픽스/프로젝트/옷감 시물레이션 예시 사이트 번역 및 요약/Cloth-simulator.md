# Cloth-simulator

[https://github.com/MeghaS94/Cloth-simulator/blob/main/cloth.ipynb](https://github.com/MeghaS94/Cloth-simulator/blob/main/cloth.ipynb)

# 1. Data

옷감 시뮬레이션에 사용되는 숫자 데이터를 맨 처음 초기화한다.

```python
# simulation params
#time step
dt= 1.0
#no. of rows
rows= 5
#no. of cols
cols= 5
#stretch constant
ks= 5e5
#5e10
#shear constant
ksh= 100.0
#100.0
#damping constant
kd= 10
#no. of particles
N= rows*cols
#cloth desity
density= 10.0
#gravity
g= 0.981

# max stretch in u and v direction
bu = 1.0
bv = 1.0
```

```python
# instantiate particle positions, velocities and forces
# positions
points = []
for r in range(rows+1):
    for c in range(cols+1):
        points.append(r)
        points.append(c)
        points.append(0.0)

# 3D world positions of the particles
world_pos = np.transpose(np.array([points]))
# positions in the UV space
uv_pos = np.transpose(np.array([points]))

# velocity
vel = np.array([[0.0] for i in range(3*(rows+1)*(cols+1))])

# force
force = np.array([[0.0] for i in range(3*(rows+1)*(cols+1))])
# external force - add gravity in the z direction
for i in range(2, force.shape[0], 3):
    force[i,0] = -g

# force jacobian matrix
A = np.zeros((3,3))
J = np.block([[A for i in range((rows+1)*(cols+1))] for j in range((rows+1)*(cols+1))])
```

`points` : 입자의 위치 3차원 배열(r,c,0.0) →([0,0],[0,1],[1,0],[1,1])

`world_pos` : 실제 world 좌표계에서 사용하는 위치 벡터 배열

`uv_pos` : 사물의 좌표 벡터 배열

`vel` : 입자의 속도를 저장하는 3차원 벡터 배열이다.

**`force`**: 입자에 작용하는 힘을 저장하는 벡터 배열입니다.

**`g`:**  중력 상수를 나타냅니다. (0.0,0.0,-9.8)

**`A`**는 3x3 크기의 영행렬

**`J`는**  [자코비안 행렬](https://angeloyeo.github.io/2020/07/24/Jacobian.html)  구성 블록입니다.  **`A`** 행렬을 사용하여 구성된 크기가 **`(rows+1)*(cols+1)`**인 블록 행렬입니다. 이 행렬은 입자 시스템의 동역학을 계산하는 데 사용됩니다.

`u`및`v` 방향으로 최대 스트레치

```python
# instantiate inverse mass matrix
invM = np.array([[0.0 for i in range(3*(rows+1)*(cols+1))] for i in range(3*(rows+1)*(cols+1))])
```

`invM`: 질량 행렬의 역행렬입니다.

3개의 case를 나누어서 질량을 계산한다.

- case 1 : 점은 그리드 내부에 있고 6개의 삼각형이 있습니다
- case 2 : 점이 그리드의 모서리에 있고 1개의 삼각형이 있습니다
- case 3 : 점이 그리드 가장자리에 있고 3개의 삼각형이 있습니다

# 2. Calculate

```python
xnew, vnew, f, df_dx = be(world_pos, uv_pos, rows, cols, vel, force, J, ks, bu, bv, invM, dt)
```

맨 처음에는 backward euler 방정식을 사용해서 입자들의 t+dt 시간 뒤의 new 위치 xnew(world_pos), vnew(object_pos)를 구합니다.

# 3. backward euler

```python
def be(world_pos, uv_pos, rows, cols, vel, force, jacobian, ks, bu, bv, invM, dt):

#     for every pos :
#         calculate net force
#         calculate force jacobian
#         calculate
#             Adv = b
#             A = I - dt^2*Minv*df_dx
#             b = dt*Minv*(f_prev + dt*df_dx*v_prev)
#             dv = A\b
#             apply boundary conditions (If applicable)
#             x_new - x_old = dt*(v_prev + dv)
#             update positions
    J = jacobian
    f, df_dx = update_force_and_jacobian(world_pos, rows, cols, uv_pos, ks, bu, bv, force, J)

    I = np.identity(3*(rows+1)*(cols+1), dtype=float)

    A = I - dt*dt*(invM.dot(df_dx))

    b = dt*invM.dot(f + dt*df_dx.dot(vel) )

    dv = np.linalg.solve(A, b)

    xnew = world_pos + dt*(vel + dv)
    vnew = vel + dv

    # update positions, velocities, (force and jacobians?)

    return xnew, vnew, f, df_dx
```

1. force를 합산
2. force에 대한 자코비안 행렬 생성
(Adv = b)는 아직 잘 모름
3. A 계산
4. b 계산
5. 속도의 변화량값(dv) = A\b
6. 해당 값이 경계조건을 만족하는 경우 → 새로운 위치값 구한다.

해당 코드에서 제일 중요한 `update_force_and_jacobian` 를 사용해서 실제 스프링에 적용되는 힘(`f`)과 위치의 변화량에 의한 힘의 변화량(`df_dx`)을 구할 수 있습니다.

# 4. update_force_and_jacobian

```python
def update_force_and_jacobian(world_pos, rows, cols, uv_pos, ks, bu, bv, f, J):
    gridX = cols + 1
    gridY = rows + 1
    world_pos_reshaped = world_pos.reshape(gridX*gridY, 3)
    uv_pos_reshaped = uv_pos.reshape(gridX*gridY, 3)
    f_reshaped = f.reshape(gridX*gridY, 3)

    for index in range(world_pos_reshaped.shape[0]):
        x = world_pos_reshaped[index][0]
        y = world_pos_reshaped[index][1]
        z = world_pos_reshaped[index][2]

        u = uv_pos_reshaped[index][0]
        v = uv_pos_reshaped[index][1]
        t = uv_pos_reshaped[index][2]
        alpha = 0.5

        triangle_indices = get_neighbouring_triangles(index, u, v, gridX, gridY)


        for triangle in triangle_indices:
            f_p_1_st, f_p_2_st, f_p_3_st, Kij_st, Kjk_st, Kki_st = stretch_force_on_all_particles_in_a_triangle(
                                                                    uv_pos_reshaped, world_pos_reshaped,
                                                                    triangle[0], triangle[1], triangle[2],
                                                                    ks, bu, bv, alpha)

            f_p_1_sh, f_p_2_sh, f_p_3_sh, Kij_sh, Kjk_sh, Kki_sh = shear_force_on_all_particles_in_a_triangle(
                                                                    uv_pos_reshaped, world_pos_reshaped,
                                                                    triangle[0], triangle[1], triangle[2],
                                                                    ksh, bu, bv, alpha)


            f_p_1 = f_p_1_st + f_p_1_sh
            f_p_2 = f_p_2_st + f_p_2_sh
            f_p_3 = f_p_3_st + f_p_3_sh

            # print("shear force - ", f_p_1_sh, f_p_2_sh, f_p_3_sh)
            # print("stretch force - ", f_p_1_st, f_p_2_st, f_p_3_st)

            Kij = Kij_st + Kij_sh
            Kjk = Kjk_st + Kjk_sh
            Kki = Kki_st + Kki_sh



            f_reshaped[triangle[0]] += f_p_1.reshape(1,3)[0]
            f_reshaped[triangle[1]] += f_p_2.reshape(1,3)[0]
            f_reshaped[triangle[2]] += f_p_3.reshape(1,3)[0]

            #Kij
            J[3*triangle[0]:3*triangle[0]+3, 3*triangle[1]:3*triangle[1]+3] += Kij
            #Kji
            J[3*triangle[1]:3*triangle[1]+3, 3*triangle[0]:3*triangle[0]+3] += Kij
            #Kjk
            J[3*triangle[1]:3*triangle[1]+3, 3*triangle[2]:3*triangle[2]+3] += Kjk
            #Kkj
            J[3*triangle[2]:3*triangle[2]+3, 3*triangle[1]:3*triangle[1]+3] += Kjk
            #Kki
            J[3*triangle[2]:3*triangle[2]+3, 3*triangle[0]:3*triangle[0]+3] += Kki
            #Kik
            J[3*triangle[0]:3*triangle[0]+3, 3*triangle[2]:3*triangle[2]+3] += Kki

    new_f = f_reshaped.reshape(gridX*gridY*3, 1)
    return new_f, J
```

1. 힘과 자코비안 행렬을 업데이트를 하기 위해서, 한 입자가 인접하고 있는, 삼각형이 몇개이고, 삼각형을 이루는 입자들의 index를 찾는다.
2. 두가지 형태 변형에 대한 힘계산을 한다
    1. `stretch_force_on_all_particles_in_a_triangle` : stretch에 의한 힘 계산 재질에 따른 변형??(정확하지는 않는다.)
    2. `shear_force_on_all_particles_in_a_triangle` : shear에 의한 힘 계산, 평행사변형으로 늘어나는 것과 비슷하다.

## 4.1 stretch_force_on_all_particles_in_a_triangle

```python
def stretch_force_on_all_particles_in_a_triangle(uv_pos, world_pos, idx1, idx2, idx3, k, bu, bv, alpha):
```

`uv_pos` : 옷감의 좌표계

`world_pos` : world 좌표계

`idx1` : 삼각형을 이루는 첫번째 노드 index입니다.

`idx2` : 삼각형을 이루는 두번째 노드 index입니다.

`idx3` : 삼각형을 이루는 셋번째 노드 index입니다.

`k` : 삼각형에 가하는 힘의 상수값

`bu, bv` : uv 좌표계 상에서 삼각형이 늘어날 수 있는 한계 uv 길이

`alpha` : 잘모름???

```python
    uv_i = uv_pos[idx1]
    uv_j = uv_pos[idx2]
    uv_k = uv_pos[idx3]

    p_i = world_pos[idx1]
    p_j = world_pos[idx2]
    p_k = world_pos[idx3]

    # i,j,k = partical index
    # u,v = 2차원 위치 벡터 u, v == x, y
    u_i = uv_i[0]
    v_i = uv_i[1]

    u_j = uv_j[0]
    v_j = uv_j[1]

    u_k = uv_k[0]
    v_k = uv_k[1]

    # uv좌표계 상에서 i -> j,k에 대한 위치 변화량을 알 수 있다.
    dv1 = v_j - v_i
    dv2 = v_k - v_i
    du1 = u_j - u_i
    du2 = u_k - u_i

    # world 좌표계의 벡터를 만들 고있다.
    # world 좌표계의 x,y,z를 만들 고 있다.
    x_i = p_i[0]
    y_i = p_i[1]
    z_i = p_i[2]
    X_i = np.array([[p_i[0]], [p_i[1]], [p_i[2]]])

    x_j = p_j[0]
    y_j = p_j[1]
    z_j = p_j[2]
    X_j = np.array([[p_j[0]], [p_j[1]], [p_j[2]]])

    x_k = p_k[0]
    y_k = p_k[1]
    z_k = p_k[2]
    X_k = np.array([[p_k[0]], [p_k[1]], [p_k[2]]])

```

위는 uv좌표계와 world 좌표계 위치 데이터를 복사한다.

```python
    # calculate wu, wv
    # 2x2 행렬의 역행렬을 구하는 방법이 따로 있다. 그래서 아래처럼 식이 바뀐것이다.
    Wu = ((X_j - X_i)*dv2 - (X_k - X_i)* dv1) / (du1*dv2 - du2*dv1)
    Wu = Wu / np.linalg.norm(Wu)

    Wv = ((X_k - X_i)* du1 - (X_j - X_i)*du2) / (du1*dv2 - du2*dv1)
    Wv = Wv / np.linalg.norm(Wv)

    # condition function
    Cu = np.linalg.norm(Wu) - bu
    Cv = np.linalg.norm(Wv) - bv

    C = np.array([[Cu], [Cv]])
    C_T = np.transpose(C)
```

해당 부분은 논문에서 아래의 부분에 해당한다고 생각합니다.

![Untitled](attachments/Untitled_17.png)

천 자체가 늘어나고 줄어드는 것을 계산하기 위해서, 제약조건 C(x)를 구하는 것이다. 이것을 이용해서  논문의 힘과 힘의 미분값을 구하는 식에 대입해서 구할 수 있다.

![Untitled](attachments/Untitled%201.png)

```python
    # calculate wu, wv
    # 2x2 행렬의 역행렬을 구하는 방법이 따로 있다. 그래서 아래처럼 식이 바뀐것이다.
    Wu = ((X_j - X_i)*dv2 - (X_k - X_i)* dv1) / (du1*dv2 - du2*dv1)
    Wu = Wu / np.linalg.norm(Wu)

    Wv = (-(X_j - X_i)*du2 + (X_k - X_i)* du1) / (du1*dv2 - du2*dv1)
    Wv = Wv / np.linalg.norm(Wv)
```

잘 보면 Wu와 Wv를 구하는 식이 보통 행렬 곱셈식처럼 보이지 않는다. 이것은 2*2일 역행렬을 다른식으로 변환한 것이다.

> 2x2 행렬의 역행렬을 구하는 방법은 다음과 같습니다.
>
>
> 주어진 행렬이 다음과 같다고 가정해 봅시다:
> $A = \begin{bmatrix} a & b \\ c & d \end{bmatrix}$
>
> 이 행렬의 역행렬은 다음과 같이 구할 수 있습니다:
> $A^{-1} = \frac{1}{ad-bc} \begin{bmatrix} d & -b \\ -c & a \end{bmatrix}$
>

```python
# calculate dwu/dx, dwu/dx
    # for Xi
    dWu_dXi = (dv1 - dv2) / (du1*dv2 - du2*dv1)
    dWv_dXi = (du2 - du1) / (du1*dv2 - du2*dv1)

    # for Xj
    dWu_dXj = dv2 / (du1*dv2 - du2*dv1)
    dWv_dXj = -du2 / (du1*dv2 - du2*dv1)

    # for Xk
    dWu_dXk = -dv1 / (du1*dv2 - du2*dv1)
    dWv_dXk = du1 / (du1*dv2 - du2*dv1)
```

`dW_dXi = (dWu_dXi, dWv_dXi)` : world 좌표계의 Xi 위치의 변화량에 따른 uv좌표계의 변화량

`dW_dXj = (dWu_dXj, dWv_dXj)` : world 좌표계의 Xj 위치의 변화량에 따른 uv좌표계의 변화량

`dW_dXk = (dWu_dXk, dWv_dXk)` : world 좌표계의 Xk 위치의 변화량에 따른 uv좌표계의 변화량

내 생각

→ j,k는 앞에서 구한 역행렬에서 해당 변화량을 구할 수 있기 때문이다.

![Untitled](attachments/Untitled%202.png)

```python
    # force on Xi
    f_i_u = (-k * alpha * dWu_dXi * np.identity(3, dtype = float).dot(Wu)) * Cu
    f_i_v = (-k * alpha * dWv_dXi * np.identity(3, dtype = float).dot(Wv)) * Cv
    f_i = f_i_u + f_i_v

    # force on Xj
    f_j_u = (-k * alpha * dWu_dXj * np.identity(3, dtype = float).dot(Wu)) * Cu
    f_j_v = (-k * alpha * dWv_dXj * np.identity(3, dtype = float).dot(Wv)) * Cv
    f_j = f_j_u + f_j_v

    # force on Xk
    f_k_u = (-k * alpha * dWu_dXk * np.identity(3, dtype = float).dot(Wu)) * Cu
    f_k_v = (-k * alpha * dWv_dXk * np.identity(3, dtype = float).dot(Wv)) * Cv
    f_k = f_k_u + f_k_v
```

![Untitled](attachments/Untitled%203.png)

`alpha` 은 0.5 == 1/2 이다.

`dWu_dXi, dWu_dXj, dWu_dXk` 는 각 입자의 index 맞는 위치에 따른 변화량이다. (dx)

`np.identity(3, dtype = float).dot(Wu||Wv)` : C(x)의 제한조건의 변화량

위 의 식을 통해서 i, j, k의 힘을 알 수 있다.

```python
# calculate jacobian matrix
# u direction
temp_mat_1 = (dWu_dXi * np.identity(3, dtype = float)).dot(dWu_dXj * np.identity(3, dtype = float))
temp_mat_3 = (dWu_dXj * np.identity(3, dtype = float)).dot(dWu_dXk * np.identity(3, dtype = float))
temp_mat_4 = (dWu_dXk * np.identity(3, dtype = float)).dot(dWu_dXi * np.identity(3, dtype = float))

temp_mat_2 = np.identity(3, dtype=float) - Wu.dot(np.transpose(Wu))

Kij_u = -k * (alpha * dWu_dXi * np.identity(3, dtype = float).dot(Wu) * \
            alpha * np.transpose(dWu_dXj * (np.identity(3, dtype = float).dot(Wu))) + \
            (alpha / np.linalg.norm(Wu)) * temp_mat_1.dot(temp_mat_2) * Cu)

Kjk_u = -k * (alpha * dWu_dXj * np.identity(3, dtype = float).dot(Wu) * \
            alpha * np.transpose(dWu_dXk * (np.identity(3, dtype = float).dot(Wu))) + \
            (alpha / np.linalg.norm(Wu)) * temp_mat_3.dot(temp_mat_2) * Cu)

Kki_u = -k * (alpha * dWu_dXk * np.identity(3, dtype = float).dot(Wu) * \
            alpha * np.transpose(dWu_dXi * (np.identity(3, dtype = float).dot(Wu))) + \
            (alpha / np.linalg.norm(Wu)) * temp_mat_4.dot(temp_mat_2) * Cu)
```

![Untitled](attachments/Untitled%204.png)

여기서 삼각형의 자코비안 행렬은 만듭니다.

총 3개의 자코비안 행렬 값을 구합니다.

```python
Kij = Kij_u + Kij_v
Kjk = Kjk_u + Kjk_v
Kki = Kki_u + Kki_v
```

- `Kij` : i,j 의 아주 작은 영역을 선형 변환으로 근사시킬 수 있는 값
- `Kjk` : j,k 의 아주 작은 영역을 선형 변환으로 근사시킬 수 있는 값
- `Kki` : k,i 의 아주 작은 영역을 선형 변환으로 근사시킬 수 있는 값

해당 작업은 u좌표계 내에서만 한 것이다. v좌표 또한 위와 비슷하게 하면 된다.

```python
# v direction
temp_mat_1 = (dWv_dXi * np.identity(3, dtype = float)).dot(dWv_dXj * np.identity(3, dtype = float))
temp_mat_3 = (dWv_dXj * np.identity(3, dtype = float)).dot(dWv_dXk * np.identity(3, dtype = float))
temp_mat_4 = (dWv_dXk * np.identity(3, dtype = float)).dot(dWv_dXi * np.identity(3, dtype = float))

temp_mat_2 = np.identity(3, dtype=float) - Wv.dot(np.transpose(Wv))

Kij_v = -k * (alpha * dWv_dXi * np.identity(3, dtype = float).dot(Wv) * \
            alpha * np.transpose(dWv_dXj * (np.identity(3, dtype = float).dot(Wv))) + \
            (alpha / np.linalg.norm(Wv)) * temp_mat_1.dot(temp_mat_2) * Cv)

Kjk_v = -k * (alpha * dWv_dXj * np.identity(3, dtype = float).dot(Wv) * \
            alpha * np.transpose(dWv_dXk * (np.identity(3, dtype = float).dot(Wv))) + \
            (alpha / np.linalg.norm(Wv)) * temp_mat_3.dot(temp_mat_2) * Cv)

Kki_v = -k * (alpha * dWv_dXk * np.identity(3, dtype = float).dot(Wv) * \
            alpha * np.transpose(dWv_dXi * (np.identity(3, dtype = float).dot(Wv))) + \
            (alpha / np.linalg.norm(Wv)) * temp_mat_4.dot(temp_mat_2) * Cv)
```

## 4.2 shear_force_on_all_particles_in_a_triangle

`stretch_force_on_all_particles_in_a_triangle` 에서 나오는 함수와 비슷하다.

```cpp
    # calculate wu, wv
    # 2x2 행렬의 역행렬을 구하는 방법이 따로 있다. 그래서 아래처럼 식이 바뀐것이다.
    Wu = ((X_j - X_i)*dv2 - (X_k - X_i)* dv1) / (du1*dv2 - du2*dv1)
    Wu = Wu / np.linalg.norm(Wu)

    Wv = (-(X_j - X_i)*du2 + (X_k - X_i)* du1) / (du1*dv2 - du2*dv1)
    Wv = Wv / np.linalg.norm(Wv)
```

이 부분까지는 똑같다. 하지만 그 다음 부분이 다르다. shear이라는 행동은

![Untitled](attachments/Untitled%205.png)
