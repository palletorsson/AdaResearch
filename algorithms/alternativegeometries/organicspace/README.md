# Organic Space

Procedural organic interior space generator — atmospheric, living environments for VR inspired by bio-architectural visualizations.

## QFEP Connection

Organic spaces reject the rectilinear (pure F) in favor of curving, breathing forms (E). The `organic_strength` parameter controls how much the geometry deviates from geometric regularity. High values produce alien, biological interiors; low values retain architectural legibility. λ as spatial experience.

## How It Works

```
┌─────────────────────────────────────┐
│      ╭───────────────╮              │
│     ╱                 ╲             │
│    ╱    ╭─────╮        ╲            │
│   │    ╱       ╲        │           │
│   │   │    ·    │   ╭───┴───╮       │
│   │    ╲       ╱   ╱         ╲      │
│    ╲    ╰─────╯   │           │     │
│     ╲             ╰───────────╯     │
│      ╰──────────────────────────────│
└─────────────────────────────────────┘

Shells, tunnels, chambers — all organic curves.
```

Components:
1. **Base shell**: Outer enclosure using noise-deformed surfaces
2. **Tunnel system**: Connecting passages with organic profiles
3. **Surface details**: Procedural textures and protrusions
4. **Lighting**: Colored accent lights with breathing animation

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `space_size` | (20, 15, 20) | Overall dimensions |
| `detail_level` | 2 | Mesh complexity (lower = more detail) |
| `organic_strength` | 0.8 | Deviation from geometric forms |
| `tunnel_complexity` | 5 | Number of connecting passages |
| `material_variety` | 4 | Material types used |

## Material Library

| Type | Aesthetic | Properties |
|------|-----------|------------|
| **Metallic** | Reflective membrane | High metallic, low roughness |
| **Membrane** | Organic tissue | Translucent pink, high roughness |
| **Crystal** | Frozen liquid | Clear, low roughness |
| **Interactive** | Glowing elements | Emissive cyan |

## Lighting System

- **Ambient**: Soft directional light (cool white)
- **Accent lights**: 4 colored omni lights (pink, blue, green, orange)
- **Animation**: Lights pulse slowly (breathing effect)

## File Structure

| File | Purpose |
|------|---------|
| `organic_space.gd` | Main generator |
| `OrganicLighting` | Atmospheric lighting |
| `OrganicMaterials` | Material library |
| `OrganicMeshGenerator` | Mesh generation utilities |

## Usage

```gdscript
var space = OrganicVRSpace.new()
space.space_size = Vector3(30, 20, 30)  # Larger space
space.organic_strength = 0.9  # More organic
space.tunnel_complexity = 8  # More passages
add_child(space)
```

## VR Experience

Enter a space that feels alive. Walls curve and undulate, colored lights pulse gently, translucent membranes filter views. There are no corners, no right angles — the geometry breathes. Perfect for meditation spaces, alien environments, or abstract experiences.

## Technical Notes

- Uses FastNoiseLite for procedural deformation
- Integrates with marching cubes for complex surfaces
- Transparent materials require proper render order
- Recommended: enable MSAA for smooth curves

## Inspiration

Inspired by bio-architectural visualization and organic design movements:
- Zaha Hadid's flowing forms
- Santiago Calatrava's skeletal structures
- H.R. Giger's biomechanical environments
- "Octavia Diva" model interiors

## See Also

- `bulgingtunnel/` — Simpler organic tunnels
- `spacetopology/marchingcubes/` — Surface generation
- `shaders/queer_materials/` — Organic material aesthetics
