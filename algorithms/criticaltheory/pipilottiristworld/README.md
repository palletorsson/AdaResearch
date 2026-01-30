# Pipilotti Rist World

Immersive video art environment inspired by Pipilotti Rist — saturated colors, floating projections, and dreamlike atmospheres.

## QFEP Connection

Rist's work is **sensory overflow as critique**. Her installations flood viewers with color, sound, and image — too much to process rationally (E overwhelming F). The `saturation_amount` and `projection_intensity` parameters control this overwhelm. Her work asks: what happens when we stop trying to understand and just feel?

## Aesthetic Signature

Pipilotti Rist's style:
- **Hyper-saturated colors**: Pinks, blues, greens pushed to extremes
- **Projected video**: Onto furniture, bodies, architecture
- **Floating/pulsing**: Organic, breathing movement
- **Domestic surrealism**: Familiar objects made strange

```
    ╭────────────────────────╮
    │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
    │  ▓▓ PROJECTED ▓▓▓▓▓▓  │
    │  ▓▓   VIDEO   ▓▓▓▓▓▓  │  ← Video on irregular surfaces
    │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
    ╰────────────────────────╯
         🌸 floating objects 🌸
```

## Parameters

### Visual
| Export | Default | Description |
|--------|---------|-------------|
| `saturation_amount` | 1.5 | Color intensity boost |
| `color_shift_speed` | 0.2 | Hue cycling rate |
| `projection_intensity` | 1.2 | Video brightness |
| `use_post_processing` | true | Enable effects |

### Environment
| Export | Default | Description |
|--------|---------|-------------|
| `fog_color` | Magenta | Atmospheric haze |
| `ambient_light_color` | Blue-purple | Room tone |
| `sky_color` | Pink | Background color |

### Projection
| Export | Default | Description |
|--------|---------|-------------|
| `video_paths` | [] | Video file paths |
| `image_paths` | [] | Image file paths |
| `projection_scale` | 1.0 | Projection size |
| `projection_overlap` | true | Allow blending |

### Animation
| Export | Default | Description |
|--------|---------|-------------|
| `pulsating_speed` | 0.5 | Breathing rate |
| `floating_objects_speed` | 0.3 | Drift rate |
| `rotation_speed` | 0.1 | Slow rotation |

## Files

| File | Purpose |
|------|---------|
| `pipilotti_rist_world.gd` | Environment generator |
| `*.tscn` | Scene file |

## Usage

```gdscript
var rist = PipilottiRistWorld.new()
rist.saturation_amount = 2.0  # Even more saturated
rist.video_paths = ["res://videos/flowers.webm"]
add_child(rist)
```

## VR Experience

Enter a space of pure sensation. Colors pulse, videos project onto floating surfaces, the fog shifts hue. There's no clear narrative — just immersion. Close your eyes and you'll still see the afterimages. This is art that bypasses cognition.

## About Pipilotti Rist

Swiss video artist (b. 1962) known for:
- "Ever Is Over All" (1997) — Woman smashing cars with flower
- "Pour Your Body Out" (2008) — MoMA floor-to-ceiling projection
- Installations in museums, churches, public spaces

Her work is often described as "feminist," "psychedelic," and "joyful" — rare combinations in contemporary art.

## See Also

- `remainstobeseen/` — Mona Hatoum (different aesthetic)
- `earthsdelight/` — Bosch-inspired landscapes
- `shaders/queer_materials/` — Material aesthetics
