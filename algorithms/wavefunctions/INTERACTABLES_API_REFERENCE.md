# Interactables API Reference

## Quick Fix Guide

**❌ WRONG (old code):**
```gdscript
@onready var slider = $Slider1  # Gets wrapper Node3D, not actual slider
slider.value_changed.connect(_on_slider_changed)
slider.set_value(0.5)
```

**✅ CORRECT:**
```gdscript
# Access the inner InteractableSlider, not the wrapper
@onready var slider = $Slider1/SliderOrigin/InteractableSlider
slider.slider_moved.connect(_on_slider_changed)
slider.slider_position = 0.5
```

## Important: Wrapper vs Inner Slider

The `slider_smooth.gd` is a **wrapper** around the actual `XRToolsInteractableSlider`.

**File structure:**
```
Slider1 (Node3D with slider_smooth.gd)
└── SliderOrigin (Node3D)
    └── InteractableSlider (XRToolsInteractableSlider) ← THIS is what you need!
```

**You must access the inner InteractableSlider to use the API!**

---

## Slider API

**Location:** `res://commons/interactables/slider_smooth.gd`

### Signal
- **`slider_moved(position: float)`** - Emitted when slider is moved
  - `position` range: 0.0 to 1.0

### Properties
- **`slider_position: float`** - Get/set slider value (0.0 to 1.0)
- **`slider_limit_min: float`** - Minimum position (default: 0.0)
- **`slider_limit_max: float`** - Maximum position (default: 1.0)
- **`default_position: float`** - Reset position

### Example Usage

```gdscript
# Connect to signal
func _setup_slider():
    var slider = get_node("MySlider")
    slider.slider_moved.connect(_on_slider_moved)

    # Set initial position
    slider.slider_position = 0.5

    # Set limits
    slider.slider_limit_min = 0.0
    slider.slider_limit_max = 1.0

# Signal handler
func _on_slider_moved(position: float) -> void:
    # position is 0.0 to 1.0
    var actual_value = lerp(min_value, max_value, position)
    print("Slider moved to: ", actual_value)
```

---

## Wheel API

**Wheels use the same API as sliders:**

```gdscript
# Wheel has same signals and properties
wheel.slider_moved.connect(_on_wheel_moved)
wheel.slider_position = 0.3

func _on_wheel_moved(position: float) -> void:
    var angle = position * TAU  # or lerp to your range
    print("Wheel at: ", angle)
```

---

## Button API

**Location:** `res://commons/interactables/push_button.gd` (wrapper)
**Inner Node:** `res://addons/godot-xr-tools/interactables/interactable_area_button.gd`

**Structure:**
```
ToggleButton (Node3D with push_button.gd wrapper)
└── InteractableAreaButton (XRToolsInteractableAreaButton) ← THIS has the signals!
```

### Signals
- **`button_pressed(button)`** - Emitted when button is pressed
- **`button_released(button)`** - Emitted when button is released

### Properties
- **`pressed: bool`** - Current state (true if pressed)

### Example Usage

```gdscript
# WRONG: Access wrapper
@onready var button = $MyButton  # Gets wrapper, no signal!

# CORRECT: Access inner InteractableAreaButton
@onready var button = $MyButton/InteractableAreaButton

# Connect to signal
func _setup_button():
    button.button_pressed.connect(_on_button_pressed)
    button.button_released.connect(_on_button_released)

# Signal handlers
func _on_button_pressed(_button) -> void:
    print("Button pressed!")
    is_playing = true

func _on_button_released(_button) -> void:
    print("Button released!")
    is_playing = false
```

---

## Common Patterns

### Map Slider to Custom Range

```gdscript
# Example: Map slider 0-1 to frequency 100-1000 Hz
func _on_frequency_slider_moved(position: float) -> void:
    var frequency = lerp(100.0, 1000.0, position)
    audio_player.pitch_scale = frequency / 440.0
```

### Initialize Slider to Match Current Value

```gdscript
# Example: Set slider to match current frequency
func _initialize_slider():
    var current_freq = 440.0
    var min_freq = 100.0
    var max_freq = 1000.0

    # Map current value to 0-1 range
    var slider_pos = inverse_lerp(min_freq, max_freq, current_freq)
    frequency_slider.slider_position = slider_pos
```

### Multiple Sliders

```gdscript
# Example: 8 harmonic sliders
var harmonic_sliders: Array = []

func _setup_controls():
    for i in range(8):
        var slider = get_node("Slider%d" % (i + 1))
        if slider:
            harmonic_sliders.append(slider)
            # Use bind() to pass index
            slider.slider_moved.connect(_on_harmonic_moved.bind(i))
            slider.slider_position = 0.0

func _on_harmonic_moved(position: float, index: int) -> void:
    harmonic_amplitudes[index] = position
    print("Harmonic %d: %.2f" % [index + 1, position])
```

### Toggle Button

```gdscript
@onready var toggle_button = $ToggleButton/InteractableAreaButton
var is_active: bool = false

func _setup_button():
    toggle_button.button_pressed.connect(_on_toggle)

func _on_toggle(_button) -> void:
    is_active = !is_active
    if is_active:
        audio_player.play()
    else:
        audio_player.stop()
    print("Audio ", "ON" if is_active else "OFF")
```

---

## Fixed Files

The following files have been corrected to use the proper API:

- ✅ `algorithms/wavefunctions/beat_frequencies/BeatFrequencies.gd`
  - Changed `value_changed` → `slider_moved`
  - Changed `set_value()` → `slider_position`

- ✅ `algorithms/wavefunctions/harmonic_builder/HarmonicBuilder.gd`
  - Fixed all slider connections
  - Fixed frequency wheel connection
  - Fixed preset application

- ✅ `algorithms/wavefunctions/spherical_harmonics/SphericalHarmonics.gd`
  - No changes needed (doesn't connect sliders yet)

- ✅ `algorithms/wavefunctions/oscillating_wave/OscillatingWave.gd`
  - No changes needed (doesn't connect sliders yet)

---

## Testing

After these fixes, all demos should work without errors:

```gdscript
# Test each scene
1. res://algorithms/wavefunctions/beat_frequencies/BeatFrequencies.tscn
2. res://algorithms/wavefunctions/harmonic_builder/HarmonicBuilder.tscn
3. res://algorithms/wavefunctions/spherical_harmonics/SphericalHarmonics.tscn
4. res://algorithms/wavefunctions/oscillating_wave/OscillatingWave.tscn
```

All slider signals should now work correctly!
