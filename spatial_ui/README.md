# Spatial UI

> 3D interface components for VR and desktop

## Overview

Spatial UI provides interface elements that exist in 3D space rather than as screen overlays. Essential for VR where 2D HUDs cause discomfort, but also used in desktop mode for immersive interfaces.

## Components

### Labels & Text
- `Label3D` wrappers with billboarding
- Code displays with syntax highlighting
- Tutorial text panels

### Controls
- 3D sliders (grab and slide)
- Buttons (poke or grab)
- Dials and knobs
- Toggle switches

### Information Displays
- Parameter controllers with value readout
- Progress meters
- Oscilloscopes and visualizers

### Containers
- Floating panels
- Grabbable clipboards
- Information boards

## Structure

```
spatial_ui/
├── labels/              # Text display components
├── controls/            # Interactive controls
├── displays/            # Information visualization
├── panels/              # Container panels
└── parameter_controller_3d.tscn  # Common parameter UI
```

## Usage

### Parameter Controller

```gdscript
var controller = preload("res://spatial_ui/parameter_controller_3d.tscn").instantiate()
controller.parameter_name = "Frequency"
controller.min_value = 0.1
controller.max_value = 10.0
controller.value_changed.connect(_on_frequency_changed)
add_child(controller)
```

### Code Display

```gdscript
var display = preload("res://spatial_ui/code_display.tscn").instantiate()
display.set_code("func example():\n    return 42")
display.language = "gdscript"
```

## VR Considerations

- **Distance**: UI elements should be 0.5-2m from user
- **Scale**: Text ~0.01-0.02 units per character height
- **Interaction**: Support both grab and poke
- **Billboarding**: Optional face-camera for readability

## Interaction Patterns

Most controls emit signals:

```gdscript
# Slider
signal value_changed(new_value: float)

# Button
signal pressed()
signal released()

# Toggle
signal toggled(is_on: bool)
```

## Integration with XR Tools

Spatial UI components work with `godot-xr-tools`:
- `XRToolsPickable` for grabbable elements
- `XRToolsInteractableArea` for poke zones
- Proper collision layers for VR hands
