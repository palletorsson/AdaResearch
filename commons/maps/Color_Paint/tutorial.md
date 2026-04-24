# Color Paint

Paint is gestural. Throw a ball; the surface accepts the splash.

Spawn a paintable sphere.

```gdscript
class_name PaintableSphere extends MeshInstance3D

var paint_image: Image

func _ready() -> void:
    paint_image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
    paint_image.fill(Color.WHITE)
    refresh_material()

func refresh_material() -> void:
    var texture := ImageTexture.create_from_image(paint_image)
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = texture
    material_override = mat
```

The sphere carries an editable image. Refreshing the material pushes the image back to the GPU.

Apply a paint splash.

```gdscript
func splash(uv: Vector2, color: Color, radius: float = 10.0) -> void:
    var centre: Vector2i = Vector2i(uv * Vector2(paint_image.get_size()))
    for dy in range(-int(radius), int(radius) + 1):
        for dx in range(-int(radius), int(radius) + 1):
            var d: float = Vector2(dx, dy).length()
            if d > radius: continue
            var alpha: float = 1.0 - d / radius
            var p := centre + Vector2i(dx, dy)
            if p.x < 0 or p.x >= paint_image.get_width(): continue
            if p.y < 0 or p.y >= paint_image.get_height(): continue
            var existing := paint_image.get_pixel(p.x, p.y)
            var blended := existing.lerp(color, alpha)
            paint_image.set_pixel(p.x, p.y, blended)
    refresh_material()
```

Soft-edge brush. Each pixel within the radius gets a weighted blend with the new colour.

Convert a ball impact to a UV coordinate.

```gdscript
func impact_to_uv(impact_world: Vector3) -> Vector2:
    var local: Vector3 = to_local(impact_world)
    var u: float = 0.5 + atan2(local.z, local.x) / TAU
    var v: float = 0.5 - asin(local.y / local.length()) / PI
    return Vector2(u, v)
```

Spherical coordinates for a sphere's UV. Works for any point on the surface.

Detect ball collision with sphere.

```gdscript
func _on_area_body_entered(body: RigidBody3D) -> void:
    if body.is_in_group("paint_ball"):
        var impact_point: Vector3 = body.global_position
        var uv := impact_to_uv(impact_point)
        splash(uv, body.paint_color)
```

Contact triggers the splash. The ball's colour determines the splash colour.

Build an Albers wall.

```gdscript
func build_albers_square(inner: Color, outer: Color, centre: Vector3) -> Node3D:
    var outer_quad := build_quad(centre, Vector2(1.5, 1.5), outer)
    var inner_quad := build_quad(centre + Vector3.FORWARD * 0.01, Vector2(0.75, 0.75), inner)
    var group := Node3D.new()
    group.add_child(outer_quad); group.add_child(inner_quad)
    return group
```

Josef Albers's nested squares. The inner colour looks different depending on the outer.

Compare two colours in context.

```gdscript
func spawn_comparison(left: Color, right: Color, shared_inner: Color) -> void:
    var left_square := build_albers_square(shared_inner, left, Vector3(-2, 1, 0))
    var right_square := build_albers_square(shared_inner, right, Vector3(2, 1, 0))
    add_child(left_square); add_child(right_square)
```

Same inner colour, different surroundings. The inner colour reads differently in each context.

Reset the painted surface.

```gdscript
func clear_paint() -> void:
    paint_image.fill(Color.WHITE)
    refresh_material()
```

Return to a blank canvas. Subsequent splashes start fresh.

You can now build a paintable sphere, splash colour at any UV position, detect ball impacts, and set up Albers-style comparisons. Color_Walls extends into environmental colour.
