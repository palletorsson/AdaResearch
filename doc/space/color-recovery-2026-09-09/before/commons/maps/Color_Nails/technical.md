# Color_Nails - Technical Tutorial

## Color Selection Systems

### The Color Class in Godot

```gdscript
# Color is stored as RGBA (Red, Green, Blue, Alpha)
var color = Color(0.8, 0.3, 0.5, 1.0)

# Access individual channels
var red = color.r      # 0.0 to 1.0
var green = color.g
var blue = color.b
var alpha = color.a    # Transparency

# Alternative constructors
var from_html = Color.html("#FF5733")
var from_hsv = Color.from_hsv(0.5, 0.8, 1.0)  # Hue, Saturation, Value
```

### RGB: Three Numbers, Millions of Colors

### Nail Color Controller Implementation

```gdscript
extends Node3D

signal color_selected(color: Color)

@export var current_color: Color = Color.WHITE

var hue_slider: float = 0.0
var saturation_slider: float = 1.0
var value_slider: float = 1.0

func _on_hue_changed(value: float):
    hue_slider = value
    update_color()

func _on_saturation_changed(value: float):
    saturation_slider = value
    update_color()

func update_color():
    current_color = Color.from_hsv(hue_slider, saturation_slider, value_slider)
    emit_signal("color_selected", current_color)
    update_preview()

func update_preview():
    $PreviewMesh.material_override.albedo_color = current_color
```

### HSV vs RGB Color Models

### Applying Color to Materials

```gdscript
# The hand model receives color from controller
extends MeshInstance3D

func apply_nail_color(color: Color):
    # Create unique material instance
    var mat = StandardMaterial3D.new()
    mat.albedo_color = color

    # Optional: add glossy nail effect
    mat.metallic = 0.3
    mat.roughness = 0.2
    mat.clearcoat = 1.0
    mat.clearcoat_roughness = 0.1

    material_override = mat
```

### Color Balls as Grabbable Samples

### The Grab Stick Scanner

```gdscript
extends XRToolsPickable

signal color_sampled(color: Color)

func sample_color_from(target: Node3D):
    if target.has_method("get_color"):
        var sampled = target.get_color()
        emit_signal("color_sampled", sampled)
    elif target is MeshInstance3D:
        # Sample from material
        var mat = target.get_active_material(0)
        if mat is StandardMaterial3D:
            emit_signal("color_sampled", mat.albedo_color)
```

### Color Interpolation

## Key Takeaway

Color selection interfaces translate between **perceptual models** (HSV - how we think about color) and **computational models** (RGB - how screens display color). The nail salon metaphor makes color personal: not just a property to observe, but a choice to wear. Three sliders control millions of possible hues - the dimensionality of color compressed into simple interaction.

## Implementation Notes and Complexity

The color_nails artifact renders an array of small spike meshes, each with a material whose albedo is driven by an index into a palette. Instantiating N nails produces N MeshInstance3D nodes and N material assignments; the cost is O(N) on setup and effectively zero at runtime once the nails are placed. The per-frame cost is one draw call per nail unless the engine batches them automatically, in which case the cost collapses to the number of unique materials.

The palette is the organising data structure. A small JSON file maps palette indices to RGB triples, and the nails reference the palette by index rather than by colour directly. This indirection is deliberate: changing the palette at runtime retones every nail simultaneously without touching the per-nail data. The indirection also enables palette swaps — a common technique in retro graphics where a single asset is reused under different colour schemes.

Colour space matters more than it usually does in procedural graphics. Godot's default colour space is linear sRGB for shaders and gamma sRGB for the output framebuffer. Mixing the two produces the wrong result: a linear-space interpolation between two gamma-space colours lands on a different point than the gamma-space interpolation between the same two colours. The nail palette is defined in gamma space, and the shader converts to linear on read, which is the convention Godot's built-in materials follow.

Within the sequence, Color_Nails is an early exploration of colour-as-data. The palette indirection argues that colour is not a property of the object but an assignment of one of several possible tones, and the assignment can change. Later maps in the sequence will extend this: Color_Flashlight detaches colour from the object entirely, and Color_Grid_Pallet makes the palette itself a grid the learner can edit.

## Within the Sequence

Color_Nails sits early in the Color sequence. Palette-as-data becomes the sequence's continuing concern, and this map is where the concept enters the learner's vocabulary.

The per-frame cost of the map scales with the number of instanced artifacts and the resolution of the procedural effects. On typical consumer hardware the whole map runs at 60 frames per second with the default parameter ranges; pushing the parameters to their extremes can raise GPU load to the point where frame rate drops, and the map does not hide this from the learner. A corner indicator reads out the current frame time so the learner can observe the cost of their parameter choices.

Failure modes worth naming. A learner who pushes the sliders off the calibrated ranges can produce visually incoherent output — flickering surfaces, runaway growth, or flat featureless fields. The map's controls are clamped at safe bounds, but within those bounds the parameters still interact nonlinearly, and the nonlinear interactions are part of what the map rewards. Understanding the interactions requires running the parameters through their ranges rather than setting them once from a preset.

The map is one station in a longer arc. The artifacts it introduces reappear in later maps with extended parameter sets, composed behaviours, or different contextual framings. The learner who walks this map carefully carries a vocabulary the remaining sequence depends on, and the vocabulary is the map's concrete contribution to the curriculum.
