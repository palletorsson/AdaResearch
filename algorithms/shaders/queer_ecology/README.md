# Queer Ecology

Shaders exploring hyper-natural and techno-organic aesthetics — chlorophyll overdose, fungal networks, and the cybernetic uncanny.

## QFEP Connection

Queer ecology refuses the nature/culture binary. These shaders embody **nature-that-is-too-much** (E overwhelming F). Super Green is chlorophyll as intensity rather than health; Techno-Fungus is network as organism. Both challenge what "natural" means by pushing it past comfortable limits.

## Shaders

### Super Green (`super_green.gdshader`)

```
Aesthetic: Chlorophyll overdose, radioactive growth, "The Green"
Visual: Pulsing, glowing, breathing organic surface
```

Features:
- **Vertex breathing**: Mesh expands/contracts with time
- **Color pulsing**: Shifts between base and highlight
- **Noise-driven variation**: Organic irregularity

### Techno-Fungus (`techno_fungus.gdshader`)

```
Aesthetic: Cybernetic organism, fungal network, data-rot
Visual: Voronoi cells with glowing veins
```

Features:
- **Voronoi pattern**: Cell-like structure
- **Animated veins**: Pulsing network lines
- **Digital meets organic**: Grid-like yet living

## Parameters

### Super Green
| Uniform | Default | Description |
|---------|---------|-------------|
| `base_color` | Intense green | Primary color |
| `pulse_color` | Bright green | Highlight color |
| `pulse_speed` | 2.0 | Breathing rate |
| `pulse_amount` | 0.1 | Vertex displacement |
| `noise_tex` | — | Optional noise texture |

### Techno-Fungus
| Uniform | Default | Description |
|---------|---------|-------------|
| `spore_color` | Dark blue | Cell interior |
| `vein_color` | Cyan | Network lines |
| `cell_density` | 10.0 | Voronoi cell size |
| `animate_speed` | 1.0 | Animation rate |

## Files

| File | Purpose |
|------|---------|
| `super_green.gdshader` | Hyper-plant material |
| `techno_fungus.gdshader` | Fungal network material |
| `mat_*.tres` | Pre-configured materials |

## Usage

```gdscript
var mat = ShaderMaterial.new()
mat.shader = preload("res://algorithms/shaders/queer_ecology/super_green.gdshader")
mat.set_shader_parameter("pulse_speed", 3.0)  # Faster breathing
mesh.material_override = mat
```

## VR Experience

Apply these materials to organic forms. Super Green makes plants feel radioactive, alive in an unsettling way. Techno-Fungus makes surfaces look like data-network organisms — neither natural nor artificial but something queerly in-between.

## Theoretical Context

From queer ecology (Morton, Chen, Alaimo):
- Nature is not a backdrop; it has agency
- The "natural" is already technological
- Ecology is about relationships, not essences
- Excess and mutation are as natural as balance

These shaders materialize those ideas: nature amplified, nature technologized, nature queered.

## See Also

- `queer_materials/` — Fur, leather, latex
- `queer_collection_2/` — More queer aesthetics
- `swarmintelligence/physarum/` — Organic network growth
