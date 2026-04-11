# Nature System — Shaders

Shared shader used by all five kingdoms for DNA-driven surface rendering.

## critter_dna.gdshader

A universal spatial shader that reads DNA-derived uniforms and produces per-kingdom surface patterns. Every uniform maps to a `CritterDNA` gene via `CritterTraitMapper`.

### Uniform Groups

| Group | Uniforms | Driven By |
|-------|----------|-----------|
| Color | `primary_color`, `secondary_color`, `wing_color` | DNA color genes |
| Pattern | `pattern_type` (0–1, interpolates 20 patterns), `pattern_density`, `pattern_scale`, `pattern_rotation`, `pattern_intensity` | DNA pattern genes |
| Effects | `effect_flags` (vec4: edge detection, cellular influence, darkness, color mixing) | DNA effect genes |
| Material | `iridescence`, `metallic`, `roughness`, `specular_tint`, `transparency`, `cracking` | DNA surface genes |
| Animation | `wave_intensity`, `wave_amplitude`, `wave_frequency`, `wave_speed`, `wave_direction` | DNA behavior genes |
| Bond | `emission_energy`, `rim_light` | Transmutation bond level |
| LOD | `detail_level` | Current LOD setting |

### Per-Instance Variation

`MultiMeshInstance3D` elements (petals, leaves, gills) encode per-instance variation in `INSTANCE_COLOR` and `INSTANCE_CUSTOM.r` (pattern rotation offset), so a single draw call produces visually distinct elements.

## Files

- `critter_dna.gdshader` — Universal DNA-expression spatial shader.

See the parent [Nature System README](../README.md) for the full architecture.
