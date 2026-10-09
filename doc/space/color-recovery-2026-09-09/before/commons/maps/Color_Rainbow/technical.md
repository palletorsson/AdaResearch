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

## Key Takeaway

The rainbow emitter transforms the spectrum from image to environment. By walking through cycling colors, you experience wavelength as **spatial progression** and **temporal change**. The phase offset creates apparent motion - a wave of color flowing through the corridor. This is Newton's spectrum made architectural: not observed through a prism, but inhabited as a tunnel of light.

## Implementation Notes and Complexity

The rainbow gradient is conventionally implemented as a 1D linear interpolation through a sequence of hue stops: red, orange, yellow, green, blue, indigo, violet. Interpolating in RGB space between red and yellow produces a smooth orange; interpolating between green and blue produces a reasonable cyan. Interpolating between violet and red — the gap the wheel closes across — produces a muddy brown in RGB. The map avoids the muddy result by interpolating in HSV space instead.

HSV interpolation keeps hue on a circle. Moving from red to violet through the short arc sweeps across the visible spectrum; moving the long arc produces the same brown the RGB path would. The map's gradient routine computes the shortest angular distance between two hue stops and interpolates along that arc, then converts back to RGB for rendering. The conversion is three multiplications, a conditional branch on the hue sector, and another three multiplications — O(1) per sample.

Rendering the gradient on a surface is a shader operation. The rainbow is a strip or a disc whose UV coordinates map to a hue angle. The shader reads the UV, converts to RGB, and writes the pixel. The cost is trivial on modern hardware, and the gradient redraws at full frame rate even at high resolution. Caching the gradient as a small lookup texture is an optimisation that pays off only when the hue stops are themselves animated, which rarely happens.

Within the sequence, Color_Rainbow connects the algorithmic composition of hues to the physical phenomenon the word rainbow usually names. The prismatic decomposition of white light is a physical process; the algorithmic rainbow is a computational simulation of it. Keeping the two registers distinct — physical versus computational — is one of the sequence's recurring concerns, and this map is where the distinction becomes explicit.

## Within the Sequence

Color_Rainbow is the algorithmic-rainbow map in the Color sequence. The HSV interpolation technique it demonstrates is reused in later maps wherever smooth hue transitions are needed.

The per-frame cost of the map scales with the number of instanced artifacts and the resolution of the procedural effects. On typical consumer hardware the whole map runs at 60 frames per second with the default parameter ranges; pushing the parameters to their extremes can raise GPU load to the point where frame rate drops, and the map does not hide this from the learner. A corner indicator reads out the current frame time so the learner can observe the cost of their parameter choices.

Failure modes worth naming. A learner who pushes the sliders off the calibrated ranges can produce visually incoherent output — flickering surfaces, runaway growth, or flat featureless fields. The map's controls are clamped at safe bounds, but within those bounds the parameters still interact nonlinearly, and the nonlinear interactions are part of what the map rewards. Understanding the interactions requires running the parameters through their ranges rather than setting them once from a preset.

The map is one station in a longer arc. The artifacts it introduces reappear in later maps with extended parameter sets, composed behaviours, or different contextual framings. The learner who walks this map carefully carries a vocabulary the remaining sequence depends on, and the vocabulary is the map's concrete contribution to the curriculum.
