# Volumetric Fog CA

Cellular automata driving fog density. Living clouds.

## QFEP Connection

Fog is **E made visible** — disorder, diffusion, entropy given form. But here the fog follows CA rules, creating structured patterns within the chaos. The fog is alive, evolving, computing.

## How It Works

1. 3D grid of CA cells (32×32×32 by default)
2. Each cell is alive (1) or dead (0)
3. CA rules update the grid each tick
4. Cell states drive a FogVolume's density texture
5. Alive cells = fog, dead cells = clear

## The Result

Clouds that pulse, shift, and evolve according to CA rules. Not random noise — structured emergence.

## Parameters

```gdscript
@export var grid_size: Vector3i = Vector3i(32, 32, 32)  # CA resolution
@export var update_interval: float = 0.1                # Seconds between steps
@export var smooth_factor: float = 0.5                  # Density smoothing
```

## Technical

- Uses Godot's `FogVolume` with `FogMaterial`
- Density controlled by 3D texture generated from CA state
- Each CA step updates the density texture
- Runs in real-time (not pre-computed)

## VR Experience

Walk through living fog. The mist has structure — it's not random but evolving. Watch patterns form and dissolve. This is atmosphere with agency.

## Files

- `volumetric_fog_ca.gd` — CA + fog integration
- `volumetric_fog_ca.tscn` — Scene setup
