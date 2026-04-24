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

## Implementation Notes and Complexity

The Gray-Scott reaction-diffusion model simulates two coupled chemicals on a 2D grid. The update rule for each cell consults its own concentration and the concentrations of its four or eight neighbours, computes the Laplacian (a discrete second derivative), and integrates the two coupled partial differential equations forward by a small time step. The per-cell cost is O(1); the per-step cost for a W times H grid is O(W times H).

Real-time simulation at visible resolution requires careful attention to numerical stability. The time step must satisfy a CFL-style condition: time step less than spatial step squared divided by four times the larger diffusion coefficient. Violating this condition produces instability where the concentrations diverge to infinity within a few frames. The map uses a fixed time step chosen to be safe for the full parameter range the learner can set, at the cost of slower apparent dynamics.

The feed rate f and kill rate k parameters define a phase space. Different regions produce different pattern types: spots, stripes, labyrinths, and mitosis-like cell division. The parameter map is continuous — small changes produce small changes in output — but the boundaries between regions are sharp, so a slider that crosses a boundary shows a visible shift in behaviour.

GPU evaluation is the conventional implementation. A compute shader loads the current concentration grid, computes the update, and writes to a second grid; the two grids swap each frame. The cost on a modern GPU is a fraction of a millisecond for a 512 by 512 grid, leaving plenty of frame budget for interactive parameter tuning.

Within the sequence, Reaction_Diffusion is the chemistry chapter of the procedural generation arc. Previous maps produced structure through geometric operations (branching, subdivision); this map produces structure through chemical dynamics. The map argues that procedural generation is not tied to any single computational paradigm, and chemistry is a legitimate primary substrate.

## Within the Sequence

The map is a chemistry-based entry point to procedural generation. Subsequent maps in the sequence will extend the reaction-diffusion machinery to 3D voxel fields and to coupled multi-species simulations.

The per-frame cost of the map scales with the number of instanced artifacts and the resolution of the procedural effects. On typical consumer hardware the whole map runs at 60 frames per second with the default parameter ranges; pushing the parameters to their extremes can raise GPU load to the point where frame rate drops, and the map does not hide this from the learner. A corner indicator reads out the current frame time so the learner can observe the cost of their parameter choices.

Failure modes worth naming. A learner who pushes the sliders off the calibrated ranges can produce visually incoherent output — flickering surfaces, runaway growth, or flat featureless fields. The map's controls are clamped at safe bounds, but within those bounds the parameters still interact nonlinearly, and the nonlinear interactions are part of what the map rewards. Understanding the interactions requires running the parameters through their ranges rather than setting them once from a preset.

The map is one station in a longer arc. The artifacts it introduces reappear in later maps with extended parameter sets, composed behaviours, or different contextual framings. The learner who walks this map carefully carries a vocabulary the remaining sequence depends on, and the vocabulary is the map's concrete contribution to the curriculum.

## Gray-Scott Shader Kernel

```glsl
// Compute shader fragment for a single Gray-Scott step
uniform sampler2D u_tex;  // current U concentrations
uniform sampler2D v_tex;  // current V concentrations
uniform float du;         // diffusion rate U
uniform float dv;         // diffusion rate V
uniform float feed;       // feed rate
uniform float kill;       // kill rate
uniform vec2 pixel_size;

void fragment() {
    vec2 uv = UV;
    float u = texture(u_tex, uv).r;
    float v = texture(v_tex, uv).r;
    // Laplacian via 5-point stencil
    float u_lap = texture(u_tex, uv + vec2(pixel_size.x, 0)).r
                + texture(u_tex, uv - vec2(pixel_size.x, 0)).r
                + texture(u_tex, uv + vec2(0, pixel_size.y)).r
                + texture(u_tex, uv - vec2(0, pixel_size.y)).r
                - 4.0 * u;
    float v_lap = texture(v_tex, uv + vec2(pixel_size.x, 0)).r
                + texture(v_tex, uv - vec2(pixel_size.x, 0)).r
                + texture(v_tex, uv + vec2(0, pixel_size.y)).r
                - 4.0 * v;
    float new_u = u + du * u_lap - u * v * v + feed * (1.0 - u);
    float new_v = v + dv * v_lap + u * v * v - (feed + kill) * v;
    COLOR = vec4(new_u, new_v, 0.0, 1.0);
}
```
