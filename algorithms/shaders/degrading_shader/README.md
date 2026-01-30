# Degrading Shader

Time-based material entropy shader — rust, wear, and decay as controllable parameters.

## QFEP Connection

Entropy is **time made visible on surfaces**. New objects are ordered (F, intact_color); aged objects show wear (E, damage_color). The `degradation_amount` parameter is λ — how much time has passed, how much order has been lost. This shader makes the second law of thermodynamics aesthetic.

## How It Works

```
degradation_amount = 0.0        degradation_amount = 0.5        degradation_amount = 1.0
┌──────────────────┐           ┌──────────────────┐           ┌──────────────────┐
│ ████████████████ │           │ █▓▓██▓▓█▓▓██▓▓█ │           │ ▒▒▓▓░░▒▒▓▓░░▒▒▓ │
│ ████████████████ │    →      │ ▓▓█▓██▓▓█▓██▓▓█ │    →      │ ░▒▒▓▓▒▒░░▓▓▒▒░ │
│ ████████████████ │           │ ██▓▓█▓▓██▓▓█▓▓█ │           │ ▓░░▒▒▓░░▒▒▓░░▒▒ │
└──────────────────┘           └──────────────────┘           └──────────────────┘
      Pristine                     Weathered                       Rusted
```

## Parameters

| Uniform | Default | Range | Description |
|---------|---------|-------|-------------|
| `degradation_amount` | 0.0 | 0-1 | Overall wear level |
| `intact_color` | Gray-blue | — | Pristine surface color |
| `damage_color` | Brown | — | Rusted/worn color |
| `roughness_boost` | 0.35 | 0-1 | Roughness increase with wear |
| `metallic_boost` | 0.05 | 0-1 | Metallic change with wear |
| `emission_strength` | 0.25 | 0-5 | Edge glow intensity |
| `grain_strength` | 0.08 | 0-1 | Surface noise amount |

## Textures

| Texture | Purpose |
|---------|---------|
| `degradation_map` | Where wear occurs (white = damaged) |

If no texture provided, procedural noise generates wear patterns.

## Wear Calculation

```glsl
// Base wear from texture
float imprint = pow(tex_sample, 1.35) * degradation_amount;

// Global wear across whole surface
float global_wear = degradation_amount * 0.18;

// Combined
float wear = clamp(global_wear + imprint, 0.0, 1.0);
```

## Files

| File | Purpose |
|------|---------|
| `degrading_shader.gdshader` | Main shader |
| `mat_*.tres` | Pre-configured materials |

## Usage

```gdscript
var mat = ShaderMaterial.new()
mat.shader = preload("res://algorithms/shaders/degrading_shader/degrading_shader.gdshader")
mat.set_shader_parameter("degradation_amount", 0.7)  # Very weathered
mat.set_shader_parameter("damage_color", Color(0.4, 0.2, 0.1))  # Rusty brown
mesh.material_override = mat
```

## Animation

Animate `degradation_amount` over time for:
- Objects aging in real-time
- "Restore" effects (1.0 → 0.0)
- Environmental storytelling

```gdscript
func _process(delta):
    degradation_amount += delta * 0.01  # Slow decay
    mat.set_shader_parameter("degradation_amount", degradation_amount)
```

## VR Experience

Apply to metal objects and watch them age. Crank `degradation_amount` from 0 to 1 and observe the transformation: smooth metallic surface becomes rough, pitted, rust-colored. The emission at edges gives a corroded glow.

## Applications

- **Environmental storytelling**: Abandoned facilities, ancient artifacts
- **Time-lapse effects**: Watch objects age
- **Gameplay mechanics**: Durability visualization
- **Art**: Meditation on impermanence

## See Also

- `effects/` — Other material effects
- `shaders/queer_ecology/` — Organic decay
- `cellularautomata/` — Pattern-based degradation
