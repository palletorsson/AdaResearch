# Interactables — VR Input Components

Reusable XR interaction primitives for hands-on control in VR maps. Each component wraps godot-xr-tools with standardized signals and label support.

## Components

| File | Description |
|------|-------------|
| `slider_horizontal.gd/.tscn` | Horizontal slider — `slider_moved` signal, `get/set_normalized_value()` |
| `slider_axis.gd/.tscn` | General-purpose axis slider with configurable orientation |
| `dial_smooth.gd/.tscn` | Rotary dial with smooth continuous rotation |
| `push_button.gd/.tscn` | Pushable VR button — `button_pressed` signal via `InteractableAreaButton` |
| `push_button_2d3d.gd/.tscn` | Hybrid button that works in both 2D overlay and 3D space |
| `interactable_area_button_pointer.gd` | Pointer-based button activation for desktop/ray interaction |

Joystick and lever variants (`joystick_smooth`, `joystick_snap`, `joystick_zero`, `lever_smooth`, `lever_snap`, `lever_zero`) are scene-only configurations of shared interactable base classes.

## Usage

```gdscript
var slider = preload("res://commons/interactables/slider_horizontal.tscn").instantiate()
slider.slider_moved.connect(_on_value_changed)
slider.set_normalized_value(0.5)
slider.set_param_name("Speed")
```

Labels live at `slider.get_node_or_null("Frame/LabelName")`.
