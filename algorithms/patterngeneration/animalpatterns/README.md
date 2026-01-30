# Animal Patterns

Procedural shader for animal print textures — leopard spots, tiger stripes, zebra lines, and more.

## QFEP Connection

Animal patterns are **Turing patterns in nature**. Reaction-diffusion systems (F, chemical rules) produce spots, stripes, and rosettes (E, emergent forms). The same math governs leopard spots and zebrafish stripes. This shader parameterizes those patterns for artistic control.

## Presets

```
Leopard:           Tiger:             Zebra:
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ ◯ ◯   ◯ ◯   │  │ ████  ████  │  │ ███████████ │
│  ◯ ◯ ◯   ◯  │  │   ████  ██  │  │   █████████ │
│ ◯   ◯ ◯  ◯  │  │ ██  ████    │  │ ███████████ │
│  ◯ ◯   ◯ ◯  │  │   ██  ████  │  │   █████████ │
└──────────────┘  └──────────────┘  └──────────────┘
 Rosette spots     Curved stripes     Bold stripes
```

## Available Presets

| Preset | Pattern | Base Color | Mark Color |
|--------|---------|------------|------------|
| **Leopard** | Rosettes | Golden tan | Dark brown |
| **Tiger** | Curved stripes | Orange | Black |
| **Zebra** | Bold stripes | White | Black |
| **Dalmatian** | Irregular spots | White | Black |
| **Snake** | Scales/diamonds | Variable | Variable |

## Parameters

### Pattern Selection
| Export | Options | Description |
|--------|---------|-------------|
| `preset` | Leopard/Tiger/Zebra/Dalmatian/Snake | Quick preset |
| `pattern` | 0-4 | Pattern type (shader uniform) |

### Common Parameters
| Uniform | Default | Description |
|---------|---------|-------------|
| `scale` | ~16-25 | Pattern frequency |
| `base_col` | Varies | Background color |
| `mark_col` | Varies | Pattern color |
| `rough` | 0.6-0.8 | Surface roughness |
| `contrast` | 1.0-1.5 | Mark intensity |

### Pattern-Specific
| Uniform | Used By | Description |
|---------|---------|-------------|
| `spot_density` | Leopard, Dalmatian | Spot frequency |
| `rosette_ring` | Leopard | Ring around spots |
| `stripe_thickness` | Tiger, Zebra | Line width |
| `stripe_curve` | Tiger, Zebra | Stripe curvature |
| `normal_amount` | All | Bump map intensity |

## Files

| File | Purpose |
|------|---------|
| `animal_patterns.gd` | Preset controller |
| `AnimalPrint.gdshader` | Pattern shader |
| `*.tscn` | Demo scene |

## Usage

```gdscript
var animal = preload("res://algorithms/patterngeneration/animalpatterns/animal.tscn").instantiate()
animal.preset = "Tiger"
add_child(animal)

# Or modify shader directly:
var mat = mesh.material_override as ShaderMaterial
mat.set_shader_parameter("base_col", Color.PINK)  # Pink tiger!
```

## VR Experience

Apply animal patterns to objects and watch them wrap around 3D forms. Switch presets to compare how different animals evolved different solutions to the same mathematical constraints. The patterns tile seamlessly.

## Biological Basis

These patterns emerge from reaction-diffusion:
- **Activator**: Chemical that promotes pigment
- **Inhibitor**: Chemical that suppresses pigment
- **Diffusion rates**: Different speeds create patterns

Alan Turing described this in 1952 — decades before computers could simulate it.

## See Also

- `cellularautomata/` — Discrete pattern generation
- `shaders/` — Other procedural textures
- `swarmintelligence/physarum/` — Organic pattern formation
