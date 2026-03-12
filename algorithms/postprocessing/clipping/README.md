# Clipping Planes

Shader-based object slicing with glowing cut edges — dynamic cross-sections revealing interior geometry.

## QFEP Connection

Clipping planes **reveal hidden structure**. An object appears solid (F, surface), but the slice shows what's inside (E, interior). The clipping distance parameter moves the boundary — controlling what's visible and what's hidden. This is λ as the threshold of visibility.

## How It Works

```
Before clipping:        After clipping:
┌──────────────┐       ┌─────────╱
│              │       │        ╱
│    Solid     │  →    │   ═══╱  ← Glowing edge
│    Object    │       │     ╱
│              │       │    ╱
└──────────────┘       └───╱
```

Shader discards fragments on one side of a plane, creating the illusion of a cut.

## Shader Logic

```glsl
// Calculate distance from fragment to plane
vec3 to_plane = world_pos - plane_position;
float distance = dot(to_plane, plane_normal);

// Discard if behind plane
if (distance < plane_distance) {
    discard;
}

// Glow near the edge
float edge_factor = 1.0 - smoothstep(0.0, edge_glow, abs(distance - plane_distance));
```

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `num_objects` | 8 | Objects to slice |
| `clipping_speed` | 1.0 | Plane animation speed |
| `object_scale` | 2.0 | Object size |

### Shader Uniforms

| Uniform | Default | Description |
|---------|---------|-------------|
| `plane_distance` | 0.0 | Cut position (-10 to 10) |
| `plane_normal` | (1,0,0) | Cut direction |
| `plane_position` | (0,0,0) | Plane anchor point |
| `edge_glow` | 0.2 | Glow width |
| `edge_color` | Cyan | Cut edge color |
| `base_color` | Purple | Object color |
| `metallic` | 0.3 | Surface metallic |
| `roughness` | 0.4 | Surface roughness |

## Files

| File | Purpose |
|------|---------|
| `clipping_planes_vr.gd` | Demo controller |
| `*.tscn` | Scene file |

## Usage

```gdscript
var clip = preload("res://algorithms/postprocessing/clipping/clipping.tscn").instantiate()
clip.clipping_speed = 0.5  # Slower animation
clip.num_objects = 12  # More objects
add_child(clip)
```

## VR Experience

Objects float in space, sliced by invisible planes that sweep through them. The cut edges glow cyan, revealing the "inside" of solid forms. The planes move continuously, creating an endlessly transforming sculpture.

## Applications

- **Medical visualization**: CT/MRI slice views
- **CAD/Engineering**: Cross-section views
- **Art installations**: Revealing interior space
- **VR portals**: Seeing through walls

## Technical Notes

- Uses `depth_prepass_alpha` for correct depth sorting
- `discard` in fragment shader removes pixels
- Edge glow uses `smoothstep` for soft falloff
- Multiple planes can be combined

## See Also

- `shaders/` — Other shader effects
- `transformation/` — Geometric operations
- `datastructures/` — Data visibility
