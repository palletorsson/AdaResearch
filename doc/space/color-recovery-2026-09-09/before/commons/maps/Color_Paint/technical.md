# Color_Paint - Technical Tutorial

## Paint Physics Simulation

### Paint Projectile Implementation

```gdscript
extends RigidBody3D

@export var paint_color: Color = Color.RED
@export var splat_size: float = 0.3

func _ready():
    # Set visual color
    $MeshInstance3D.material_override.albedo_color = paint_color

func _on_body_entered(body):
    if body.has_method("receive_paint"):
        # Calculate impact point
        var contact_point = get_contact_point(body)
        body.receive_paint(paint_color, contact_point, splat_size)

        # Splatter effect
        spawn_splatter_particles(contact_point)
        queue_free()  # Paint is consumed
```

### Paintable Surface

### World Position to UV Conversion

```gdscript
func world_to_uv(world_pos: Vector3) -> Vector2:
    # For a sphere, use spherical coordinates
    var local_pos = to_local(world_pos).normalized()

    # Spherical to UV
    var u = 0.5 + atan2(local_pos.z, local_pos.x) / TAU
    var v = 0.5 - asin(local_pos.y) / PI

    return Vector2(u, v)

# For a flat surface, simpler projection:
func world_to_uv_flat(world_pos: Vector3) -> Vector2:
    var local = to_local(world_pos)
    var u = (local.x + size.x/2) / size.x
    var v = (local.z + size.z/2) / size.z
    return Vector2(u, v)
```

### Paint Circle with Soft Edges

### Paint Launcher

```gdscript
extends Node3D

@export var launch_force: float = 10.0
@export var paint_colors: Array[Color] = [Color.RED, Color.BLUE, Color.YELLOW]
var current_color_index: int = 0

var paint_projectile_scene = preload("res://paint_projectile.tscn")

func _on_trigger_pressed():
    launch_paint()

func _on_grip_pressed():
    # Cycle colors
    current_color_index = (current_color_index + 1) % paint_colors.size()
    update_color_preview()

func launch_paint():
    var projectile = paint_projectile_scene.instantiate()
    projectile.paint_color = paint_colors[current_color_index]

    get_tree().root.add_child(projectile)
    projectile.global_position = global_position

    # Launch in controller's forward direction
    var direction = -global_transform.basis.z
    projectile.linear_velocity = direction * launch_force
```

### Color Blending on Impact

### Splatter Particle Effects

```gdscript
extends GPUParticles3D

func spawn_splatter(position: Vector3, color: Color, normal: Vector3):
    global_position = position

    # Set particle color
    var mat = process_material as ParticleProcessMaterial
    mat.color = color

    # Emit in hemisphere around impact normal
    var basis = Basis()
    basis.y = normal
    basis.x = normal.cross(Vector3.UP).normalized()
    basis.z = normal.cross(basis.x)
    transform.basis = basis

    emitting = true
```

## Key Takeaway

Paint physics connects digital color to physical intuitions. Throwing paint projectiles engages spatial reasoning, trajectory calculation, and force estimation. The color results from action - where you aimed, how hard you threw, what was already on the surface. This is color as process rather than selection, bridging the gap between the weightless digital and the tactile physical.

## Implementation Notes and Complexity

Painting on a surface requires a writable texture. Godot's ImageTexture supports per-pixel updates: the learner's brush writes RGBA values into the Image, and the Image is pushed to the GPU at the end of each stroke. Per-pixel writes are O(1), but the texture upload has a fixed per-frame cost that dominates for small strokes. Batching writes within a frame — accumulating brush samples into a dirty rectangle and uploading only that region — is the standard optimisation.

The brush itself is a small convolution kernel. A soft brush is a Gaussian bump whose centre sits at the cursor position and whose extent falls off smoothly. Each brush sample writes several pixels with weighted contributions, so the cost of a stroke scales with brush area rather than with stroke length. A brush of radius R writes O(R squared) pixels per sample, and the stroke's total cost is the sample count times the per-sample cost.

Blending modes matter for paint-over semantics. Alpha blending with a fresh colour produces a weighted average of new and existing pigment, which is the conventional paint behaviour. Additive blending produces a colour that can exceed full saturation, which is closer to stage-light behaviour than to paint. The map exposes the blending mode as a parameter so the learner can compare the two; switching between them reveals that painting is not a single operation but a family of related ones with different mathematical signatures.

Within the sequence, Color_Paint is where the learner's hand becomes the colour input. Previous maps presented colour as pre-assigned; this map lets the learner author colour into a surface. The painting operation is the first place in the sequence where colour is a choice made by the learner rather than by the authoring system, and the shift carries the sequence forward into the interactive-palette territory the later maps explore.

## Within the Sequence

Color_Paint is where the learner authors colour directly. The brush-as-convolution pattern shows up again in later maps where procedural texturing draws on the same per-pixel write machinery.

The per-frame cost of the map scales with the number of instanced artifacts and the resolution of the procedural effects. On typical consumer hardware the whole map runs at 60 frames per second with the default parameter ranges; pushing the parameters to their extremes can raise GPU load to the point where frame rate drops, and the map does not hide this from the learner. A corner indicator reads out the current frame time so the learner can observe the cost of their parameter choices.

Failure modes worth naming. A learner who pushes the sliders off the calibrated ranges can produce visually incoherent output — flickering surfaces, runaway growth, or flat featureless fields. The map's controls are clamped at safe bounds, but within those bounds the parameters still interact nonlinearly, and the nonlinear interactions are part of what the map rewards. Understanding the interactions requires running the parameters through their ranges rather than setting them once from a preset.

The map is one station in a longer arc. The artifacts it introduces reappear in later maps with extended parameter sets, composed behaviours, or different contextual framings. The learner who walks this map carefully carries a vocabulary the remaining sequence depends on, and the vocabulary is the map's concrete contribution to the curriculum.
