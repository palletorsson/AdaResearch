# Queer Morphology Specimen

A synthesis artifact presenting a soft-body creature in a specimen jar whose form continuously shifts between rigid crystalline structure and fluid dissolution. It teaches concepts from the QFEP (Queer Feminist Epistemology of Physics) framework: edge-of-chaos dynamics and the process of becoming.

## How It Works

Two QFEP parameters drive the specimen's behavior. Lambda controls proximity to the edge of chaos: low values produce a stiff, crystalline body while high values make it fluid and dissipative. Phi controls becoming versus resistance: negative values increase damping (resisting change) while positive values reduce it (embracing transformation). These parameters feed into a SoftBody3D's physics properties and a custom fluid shader that fills the jar, producing visible changes in stiffness, pressure, color, and turbulence. The specimen breathes most actively when lambda sits near the critical 0.5 threshold.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `jar_height` | float | `0.4` |
| `jar_radius` | float | `0.15` |
| `lambda` | float (0.0-1.0) | `0.5` |
| `phi` | float (-1.0-1.0) | `0.0` |
| `base_stiffness` | float | `0.5` |
| `base_pressure` | float | `1.0` |
| `base_damping` | float | `0.05` |
| `specimen_color` | Color | `Color(0.4, 0.2, 0.6, 0.85)` |
| `fluid_color` | Color | `Color(0.6, 0.8, 0.7, 0.3)` |
| `fluid_turbulence` | float | `0.5` |

## Features

- Glass jar with refraction, lid, base, and museum pedestal
- SoftBody3D specimen with physics driven by lambda and phi parameters
- Custom GLSL fluid shader responding to both QFEP parameters in real time
- Five labeled states: Crystalline, Stable, Edge of Chaos, Fluid, Dissolving
- VR control panel with lambda and phi sliders plus preset buttons
- Keyboard controls for desktop testing (arrow keys and number presets)
- Breathing oscillation that peaks at the edge of chaos

## Files

- `queer_morphology_specimen.gd` -- Main script
- `queer_morphology_specimen.tscn` -- Scene file
