# Remains to be Seen

A VR installation inspired by Mona Hatoum's work — suspended wire furniture frames creating an atmosphere of absence and domestic uncanny.

## QFEP Connection

Hatoum's work explores **the familiar made strange**. Domestic objects (chairs, tables, beds) — symbols of order and home (F) — are rendered skeletal, suspended, unstable (E). The title itself is QFEP: what "remains to be seen" exists in potential, not yet collapsed into certainty.

## Concept

```
    ╭────╮     ╭────╮     ╭────╮
    │    │     │    │     │    │
    ╰────╯     ╰────╯     ╰────╯
       │          │          │
       │          │          │     ← Suspended wire furniture
       │          │          │
    ╭──┴──╮   ╭──┴──╮   ╭──┴──╮
    │ ▢▢▢ │   │ ▢▢▢ │   │ ▢▢▢ │
    ╰─────╯   ╰─────╯   ╰─────╯
```

Wire-frame furniture (chairs, tables, beds) hang in a grid formation:
- **Material**: Metallic dark grey wire
- **Lighting**: Dim, atmospheric, directional from above
- **Movement**: Subtle swaying, slow rotation
- **Fog**: Soft atmospheric depth

## Technical Details

| Variable | Value | Description |
|----------|-------|-------------|
| `grid_size` | 5 | Objects per row/column |
| `grid_spacing` | 1.5 | Distance between objects |
| `rotation_speed` | 0.2 | Slow ambient rotation |
| `subtle_movement_amplitude` | 0.1 | Sway amount |
| `swing_speed` | 0.8 | Pendulum frequency |

## Wire Material

```gdscript
wire_material.albedo_color = Color(0.2, 0.2, 0.2)
wire_material.metallic = 0.8
wire_material.roughness = 0.3
```

Slightly reflective, industrial, institutional.

## Environment

- **Ambient light**: Very dim blue-grey
- **Fog**: Subtle, adds depth and mystery
- **Directional light**: From above, casting shadows through wire

## Files

| File | Purpose |
|------|---------|
| `remains_to_be_seen.tscn` | Installation scene |
| `remains_to_be_seen.gd` | Generation and animation |

## Usage

```gdscript
var installation = preload("res://algorithms/criticaltheory/remainstobeseen/remains_to_be_seen.tscn").instantiate()
add_child(installation)
```

## VR Experience

Walk among the suspended furniture. The familiar forms of domestic life — rendered in cold wire, hung like specimens or warnings — create unease. The subtle movement suggests breath or wind, but nothing living is present. You're walking through the ghost of a home.

## About Mona Hatoum

Palestinian-British artist (b. 1952) known for installations that transform domestic objects into sources of anxiety. Her work explores:
- **Displacement**: Home as impossible return
- **Surveillance**: Domestic space as not-safe
- **Body**: Furniture as stand-in for absent bodies
- **Scale**: Giant or miniature distortions

## Critical Context

"Remains to be Seen" (and similar works) asks:
- What happens when we see through objects to their structures?
- What makes a house a home — objects or inhabitants?
- Can furniture be violent?
- What remains when people are gone?

## See Also

- `criticaltheory/` — Other art-theory installations
- `shaders/queer_materials/` — Material aesthetics
- `emergentsystems/ecosystemsimulation2/` — Absence and presence
