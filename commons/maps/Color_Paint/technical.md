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

```gdscript
extends MeshInstance3D

var paint_texture: ImageTexture
var paint_image: Image
var texture_size: int = 512

func _ready():
    initialize_paint_canvas()

func initialize_paint_canvas():
    # Create blank canvas
    paint_image = Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
    paint_image.fill(Color.TRANSPARENT)

    paint_texture = ImageTexture.create_from_image(paint_image)

    # Apply to material
    var mat = get_active_material(0).duplicate() as StandardMaterial3D
    mat.detail_enabled = true
    mat.detail_albedo = paint_texture
    mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MIX
    material_override = mat

func receive_paint(color: Color, world_pos: Vector3, radius: float):
    # Convert world position to UV coordinates
    var uv = world_to_uv(world_pos)

    # Paint circle on texture
    paint_circle(uv, radius, color)

    # Update texture
    paint_texture.update(paint_image)
```

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

```gdscript
func paint_circle(center: Vector2, radius: float, color: Color):
    var pixel_radius = int(radius * texture_size)
    var center_pixel = Vector2i(center * texture_size)

    for y in range(-pixel_radius, pixel_radius + 1):
        for x in range(-pixel_radius, pixel_radius + 1):
            var dist = Vector2(x, y).length()
            if dist <= pixel_radius:
                var pixel = center_pixel + Vector2i(x, y)
                if pixel.x >= 0 and pixel.x < texture_size and \
                   pixel.y >= 0 and pixel.y < texture_size:
                    # Soft edge falloff
                    var alpha = 1.0 - (dist / pixel_radius)
                    alpha = pow(alpha, 0.5)  # Soften falloff curve

                    var existing = paint_image.get_pixelv(pixel)
                    var blended = existing.blend(Color(color.r, color.g, color.b, alpha))
                    paint_image.set_pixelv(pixel, blended)
```

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

```gdscript
# When paint overlaps, colors blend
func blend_paint_colors(existing: Color, new_paint: Color, opacity: float) -> Color:
    # Simple alpha blending
    return existing.lerp(new_paint, opacity)

# More realistic: treat as subtractive (paint absorbs light)
func subtractive_blend(existing: Color, new_paint: Color) -> Color:
    # Multiply blending approximates subtractive mixing
    return Color(
        existing.r * new_paint.r,
        existing.g * new_paint.g,
        existing.b * new_paint.b
    )

# Result: layering paint darkens the surface
# Red over blue doesn't make purple, makes dark red-purple
```

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
