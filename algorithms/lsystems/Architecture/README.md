# L-System Architecture

3D architectural structures generated via L-System grammar rules — buildings from string rewriting.

## QFEP Connection

L-Systems encode **growth rules** that unfold into form. The axiom is potential (F); the rules are transformation logic; the result is emergent structure (E). Architecture becomes a consequence of simple rules repeatedly applied — deterministic yet surprising in its complexity.

## How It Works

```
Axiom: X                    After iterations:
                                    │
                               ┌────┼────┐
                               │    │    │
                          ┌────┴────┼────┴────┐
                          │    │    │    │    │
                          ...  ...  ...  ...  ...
```

Rules:
- `X → F[+X]F[-X][^X][&X]`: Branch in four orthogonal directions
- `F → FF`: Double segment length each generation

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `iterations` | 3 | Number of rule applications |
| `step_length` | 0.5 | Segment length |
| `structure_thickness` | 0.06 | Branch thickness |
| `angle` | 90.0 | Rotation angle (degrees) |
| `show_animation` | false | Animate growth |

## Turtle Commands

| Symbol | Action |
|--------|--------|
| `F` | Move forward, draw segment |
| `+` | Turn right (yaw) |
| `-` | Turn left (yaw) |
| `^` | Pitch up |
| `&` | Pitch down |
| `[` | Push state (save position/orientation) |
| `]` | Pop state (restore position/orientation) |

## Material

```gdscript
structure_material.albedo_color = Color(0.7, 0.7, 0.8)  # Concrete gray
structure_material.metallic = 0.3
structure_material.roughness = 0.6
```

Architectural aesthetic: brutalist concrete with subtle emission.

## Files

| File | Purpose |
|------|---------|
| `architecture.gd` | Main generator |
| `*.tscn` | Scene file |

## Usage

```gdscript
var arch = preload("res://algorithms/lsystems/Architecture/architecture.tscn").instantiate()
arch.iterations = 4  # More complex
arch.angle = 60.0  # Non-orthogonal
add_child(arch)
```

## VR Experience

Walk through the generated structure. Each iteration doubles complexity — what starts as a simple cross becomes a dense lattice. The 90° angles give it a modernist, Escher-like quality. Change the angle to create organic vs geometric aesthetics.

## Architectural Variations

| Angle | Aesthetic |
|-------|-----------|
| 90° | Orthogonal, modernist |
| 60° | Hexagonal patterns |
| 45° | Diamond lattice |
| 25° | Organic, tree-like |

## See Also

- `lsystems/Growth/` — Organic plant systems
- `lsystems/Ecosystem/` — Competing L-Systems
- `arrays/` — Repetitive structures
