# Queer Materials

Procedural shaders exploring tactile, sensual, and subcultural material aesthetics — fur, leather, latex.

## QFEP Connection

Materials encode **cultural meaning through physics**. These shaders don't just simulate surfaces — they invoke queer aesthetic histories: the softness of velvet, the gleam of leather, the wet shine of latex. Material properties (F, physics) carry cultural weight (E, meaning). The "queer" in queer materials is the refusal of neutral, default textures.

## Materials

### Fur / Velvet (`fur_velvet.gdshader`)

```
Aesthetic: Soft, plush, touchable, luxurious
Physics: Light scattering on micro-fibers
```

- Deep red/purple base
- Sheen color at grazing angles
- Noise-based surface variation
- Velvet's characteristic "direction"

### Leather (`leather.gdshader`)

```
Aesthetic: Fetish, tactile, high-contrast, shiny but imperfect
Physics: Subsurface scattering, grain texture, fold patterns
```

- Deep black default
- Procedural grain at multiple scales
- Fold patterns suggest use and wear
- Rim lighting for dimensionality

### Pop Plastic / Latex (`pop_plastic.gdshader`)

```
Aesthetic: Artificial, high-gloss, candy-colored, "Super Pop"
Physics: High specular, minimal roughness, iridescence
```

- Hot pink default (very shiny)
- View-dependent color shift
- Wet-look reflection
- Cyan rim light accent

## Parameters (Leather example)

| Uniform | Default | Description |
|---------|---------|-------------|
| `albedo_color` | Black | Base color |
| `roughness` | 0.3 | Surface smoothness |
| `metallic` | 0.1 | Metal-like reflection |
| `grain_scale` | 50.0 | Texture frequency |
| `grain_strength` | 0.5 | Texture intensity |
| `fold_scale` | 5.0 | Large crease frequency |
| `fold_strength` | 0.2 | Crease depth |
| `rim_color` | Dark gray | Edge highlight |
| `rim_width` | 0.5 | Rim light extent |

## Files

| File | Purpose |
|------|---------|
| `fur_velvet.gdshader` | Velvet material |
| `leather.gdshader` | Leather material |
| `pop_plastic.gdshader` | Latex/plastic material |
| `mat_*.tres` | Pre-configured material resources |

## Usage

```gdscript
var mat = ShaderMaterial.new()
mat.shader = preload("res://algorithms/shaders/queer_materials/leather.gdshader")
mat.set_shader_parameter("albedo_color", Color(0.2, 0.0, 0.0))  # Dark red
mesh.material_override = mat
```

Or use the pre-made `.tres` files:
```gdscript
mesh.material_override = preload("res://algorithms/shaders/queer_materials/mat_leather.tres")
```

## VR Experience

Apply these materials to objects and observe how they respond to light. Move around them — notice the velvet's directional sheen, the leather's subtle grain catching highlights, the plastic's iridescent shift. These materials reward close inspection.

## Theoretical Context

Materials are not neutral. The history of queer aesthetics includes:
- **Velvet**: Luxury, decadence, sensuality
- **Leather**: BDSM subculture, resilience, identity
- **Latex**: Performance, transformation, artificiality

These shaders make those histories tactile.

## See Also

- `shaders/queer_collection_2/` — More queer aesthetics
- `shaders/queer_ecology/` — Environmental shaders
- `color/` — Color theory
