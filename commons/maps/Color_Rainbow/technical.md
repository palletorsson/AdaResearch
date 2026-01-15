# Color_Rainbow - Technical Tutorial

## Spectrum Generation

### The Visible Spectrum in Code

```gdscript
# Wavelength to RGB conversion (simplified)
func wavelength_to_rgb(wavelength_nm: float) -> Color:
    # Visible spectrum: ~380nm (violet) to ~750nm (red)
    var r, g, b: float

    if wavelength_nm < 380:
        return Color.BLACK
    elif wavelength_nm < 440:
        r = -(wavelength_nm - 440) / (440 - 380)
        g = 0.0
        b = 1.0
    elif wavelength_nm < 490:
        r = 0.0
        g = (wavelength_nm - 440) / (490 - 440)
        b = 1.0
    elif wavelength_nm < 510:
        r = 0.0
        g = 1.0
        b = -(wavelength_nm - 510) / (510 - 490)
    elif wavelength_nm < 580:
        r = (wavelength_nm - 510) / (580 - 510)
        g = 1.0
        b = 0.0
    elif wavelength_nm < 645:
        r = 1.0
        g = -(wavelength_nm - 645) / (645 - 580)
        b = 0.0
    elif wavelength_nm <= 750:
        r = 1.0
        g = 0.0
        b = 0.0
    else:
        return Color.BLACK

    return Color(r, g, b)
```

### Rainbow Emitter Implementation

```gdscript
extends Node3D

@export var cycle_speed: float = 0.5
@export var phase_offset: float = 0.1
@export var emission_strength: float = 3.0

var time_offset: float = 0.0

func _ready():
    time_offset = phase_offset * get_index()

func _process(delta):
    var t = fmod(Time.get_ticks_msec() / 1000.0 * cycle_speed + time_offset, 1.0)
    var color = get_spectrum_color(t)
    set_emission_color(color)

func get_spectrum_color(t: float) -> Color:
    # t = 0.0 to 1.0 maps to full spectrum
    return Color.from_hsv(t, 1.0, 1.0)

func set_emission_color(color: Color):
    var mat = $MeshInstance3D.get_active_material(0) as StandardMaterial3D
    mat.emission = color
    mat.emission_energy_multiplier = emission_strength
```

### Phase Offset for Wave Effect

```gdscript
# Multiple emitters with phase offset create traveling wave
func setup_rainbow_corridor(emitter_count: int):
    for i in range(emitter_count):
        var emitter = rainbow_emitter_scene.instantiate()
        emitter.position.z = i * spacing

        # Phase offset based on position
        # Creates wave that travels through corridor
        emitter.phase_offset = float(i) / emitter_count

        add_child(emitter)

# Result: color wave appears to flow through corridor
# Each emitter is slightly ahead/behind its neighbors
```

### The Spectrum Is Linear, Not Circular

```gdscript
# Physical spectrum: 380nm → 750nm (violet to red)
# This is LINEAR - there is no wavelength between red and violet

var spectrum_start = 380  # nm (violet)
var spectrum_end = 750    # nm (red)

# But HSV color wheel is CIRCULAR
# Hue 0.0 (red) → 0.167 (yellow) → 0.33 (green) → 0.5 (cyan) →
# 0.67 (blue) → 0.83 (magenta) → 1.0 (red again)

# The color wheel includes MAGENTA (hue ~0.83)
# But magenta has NO wavelength - it's not in the physical spectrum
# Screens add magenta to "close the loop" perceptually
```

### Emissive Materials for Color Glow

```gdscript
# Rainbow corridor uses emission, not just albedo
func create_glowing_material(color: Color, strength: float) -> Material:
    var mat = StandardMaterial3D.new()
    mat.albedo_color = color

    # Emission makes the surface appear to glow
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = strength

    # Optional: add bloom in environment settings
    # to enhance glow effect

    return mat
```

### Color Palette Configuration

```gdscript
# From map_data.json settings:
# "palette": "rainbow_gradient"
# "emission_color": "0.0, 0.8, 1.0, 1.0"
# "emission_strength": 3.0

func apply_palette_settings(settings: Dictionary):
    if settings.has("palette"):
        match settings.palette:
            "rainbow_gradient":
                enable_spectrum_cycling()
            "monochrome":
                set_fixed_color(Color.WHITE)

    if settings.has("emission_strength"):
        set_emission_energy(settings.emission_strength)
```

### Walking Speed and Color Duration

```gdscript
# How long player spends in each color zone
var corridor_length = 10.0  # meters
var walk_speed = 2.0  # meters per second
var spectrum_zones = 7  # ROYGBIV

var time_per_zone = corridor_length / spectrum_zones / walk_speed
# ~0.7 seconds per color at normal walking speed

# Cycle speed should be calibrated to walking speed
# Too fast: colors blur together
# Too slow: player moves faster than color changes
```

### Pickup Cube as Checkpoint

```gdscript
extends Area3D

signal collected

func _on_body_entered(body):
    if body.is_in_group("player"):
        emit_signal("collected")
        # Visual feedback
        queue_free()  # Or respawn after delay

# Mid-corridor pickup creates:
# 1. Reason to continue walking
# 2. Interaction point in passive experience
# 3. Progress marker
```

## Key Takeaway

The rainbow emitter transforms the spectrum from image to environment. By walking through cycling colors, you experience wavelength as **spatial progression** and **temporal change**. The phase offset creates apparent motion - a wave of color flowing through the corridor. This is Newton's spectrum made architectural: not observed through a prism, but inhabited as a tunnel of light.
