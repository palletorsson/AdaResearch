# Reaction-Diffusion — Technical

## Gray-Scott Equations

```
∂U/∂t = Dᵤ∇²U - UV² + F(1-U)
∂V/∂t = Dᵥ∇²V + UV² - (F+k)V
```

Where:
- `U, V` = chemical concentrations
- `Dᵤ, Dᵥ` = diffusion rates
- `F` = feed rate
- `k` = kill rate
- `∇²` = Laplacian (sum of neighbors minus center)

## Basic Implementation

```gdscript
extends Node

var width = 256
var height = 256
var U: Array = []
var V: Array = []
var nextU: Array = []
var nextV: Array = []

# Parameters
var Du = 1.0      # U diffusion rate
var Dv = 0.5      # V diffusion rate
var feed = 0.037  # Feed rate
var kill = 0.06   # Kill rate
var dt = 1.0      # Time step

func _ready():
    initialize()

func initialize():
    U.resize(width * height)
    V.resize(width * height)
    nextU.resize(width * height)
    nextV.resize(width * height)
    
    # Start with U=1, V=0 everywhere
    for i in range(width * height):
        U[i] = 1.0
        V[i] = 0.0
    
    # Seed some V in the center
    seed_center()

func seed_center():
    var cx = width / 2
    var cy = height / 2
    for dx in range(-10, 10):
        for dy in range(-10, 10):
            var i = (cy + dy) * width + (cx + dx)
            V[i] = 1.0

func _process(delta):
    for step in range(10):  # Multiple steps per frame
        simulate_step()
    update_texture()

func simulate_step():
    for y in range(1, height - 1):
        for x in range(1, width - 1):
            var i = y * width + x
            
            # Laplacian (5-point stencil)
            var lapU = U[i-1] + U[i+1] + U[i-width] + U[i+width] - 4*U[i]
            var lapV = V[i-1] + V[i+1] + V[i-width] + V[i+width] - 4*V[i]
            
            # Reaction term
            var uvv = U[i] * V[i] * V[i]
            
            # Update
            nextU[i] = U[i] + dt * (Du * lapU - uvv + feed * (1.0 - U[i]))
            nextV[i] = V[i] + dt * (Dv * lapV + uvv - (feed + kill) * V[i])
    
    # Swap buffers
    var tmp = U
    U = nextU
    nextU = tmp
    tmp = V
    V = nextV
    nextV = tmp
```

## Pattern Presets

```gdscript
var presets = {
    "coral":   {"feed": 0.055, "kill": 0.062},
    "mitosis": {"feed": 0.0367, "kill": 0.0649},
    "fingers": {"feed": 0.037, "kill": 0.06},
    "spots":   {"feed": 0.025, "kill": 0.05},
    "waves":   {"feed": 0.018, "kill": 0.051},
    "maze":    {"feed": 0.029, "kill": 0.057},
    "bubbles": {"feed": 0.012, "kill": 0.047},
    "worms":   {"feed": 0.078, "kill": 0.061}
}
```

## GPU Shader Version

```glsl
#[compute]
#version 450

layout(local_size_x = 16, local_size_y = 16) in;

layout(set = 0, binding = 0, rgba32f) uniform image2D current;
layout(set = 0, binding = 1, rgba32f) uniform image2D next;

layout(push_constant) uniform Params {
    float Du, Dv, feed, kill, dt;
};

void main() {
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = imageSize(current);
    
    // Sample neighbors
    vec4 c = imageLoad(current, pos);
    vec4 l = imageLoad(current, pos + ivec2(-1, 0));
    vec4 r = imageLoad(current, pos + ivec2(1, 0));
    vec4 u = imageLoad(current, pos + ivec2(0, -1));
    vec4 d = imageLoad(current, pos + ivec2(0, 1));
    
    float U = c.r;
    float V = c.g;
    
    // Laplacian
    float lapU = l.r + r.r + u.r + d.r - 4.0 * U;
    float lapV = l.g + r.g + u.g + d.g - 4.0 * V;
    
    // Reaction
    float uvv = U * V * V;
    
    // Update
    float newU = U + dt * (Du * lapU - uvv + feed * (1.0 - U));
    float newV = V + dt * (Dv * lapV + uvv - (feed + kill) * V);
    
    imageStore(next, pos, vec4(newU, newV, 0.0, 1.0));
}
```

## 3D Extension

```gdscript
# 3D Laplacian has 6 neighbors
func laplacian_3d(field, x, y, z):
    return (
        field[x-1][y][z] + field[x+1][y][z] +
        field[x][y-1][z] + field[x][y+1][z] +
        field[x][y][z-1] + field[x][y][z+1] -
        6 * field[x][y][z]
    )
```
