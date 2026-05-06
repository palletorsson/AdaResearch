# Ada UI Demo Scenes

Two demo scenes for reviewing and testing the design system.

## ui_theme_demo.tscn — 2D Theme Preview
Opens as a standalone 2D scene. Shows every themed control:
- Buttons (normal, green, red, orange, disabled)
- Sliders with live value readout
- Inputs, dropdowns, spinboxes
- Checkboxes and toggles
- Progress bars
- Tab container
- Parameter cards (rack style)
- Full color palette swatches

**How to test:** Open in Godot → F5 (run current scene)

## vr_component_demo.tscn — 3D VR Component Showcase
All VR interactables and display modules on a white backdrop:
- Sliders: vertical, horizontal, snap, zero, axis
- Rotary: dials, wheel
- Interactive: buttons, joystick, XY pad, lever
- VR audio controls: TE-style knobs and faders
- Displays: waveform, spectrum, simple waveform, lissajous, monitor

**How to test:**
- Desktop: Open → F5, orbit camera with mouse
- VR: Launch with XR runtime, walk up to the rack and grab controls
- Press **R** to rebuild the layout

Both scenes use `ada_theme.tres` and `commons/ui/materials/` exclusively.
