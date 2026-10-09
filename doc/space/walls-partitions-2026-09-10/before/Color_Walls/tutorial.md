# Color Walls

The corridor becomes a gradient. Surface is continuous flow.

Generate a gradient texture.

```gdscript
func gradient_texture(width: int, height: int, start: Color, end: Color) -> ImageTexture:
    var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
    for x in width:
        var t: float = float(x) / (width - 1)
        var color := start.lerp(end, t)
        for y in height:
            image.set_pixel(x, y, color)
    return ImageTexture.create_from_image(image)
```

Linear interpolation between start and end. The result is a horizontal stripe of smooth colour.

Apply to a wall.

```gdscript
func apply_gradient_wall(wall: MeshInstance3D, texture: ImageTexture) -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = texture
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
    wall.material_override = mat
```

Linear filtering gives smooth transitions. The wall reads as continuous colour rather than as a sequence of pixels.

Build a multi-stop gradient.

```gdscript
func multi_stop_gradient(stops: Array, width: int, height: int) -> ImageTexture:
    var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
    for x in width:
        var t: float = float(x) / (width - 1)
        var color: Color = sample_stops(stops, t)
        for y in height:
            image.set_pixel(x, y, color)
    return ImageTexture.create_from_image(image)

func sample_stops(stops: Array, t: float) -> Color:
    for i in range(stops.size() - 1):
        if t <= stops[i + 1].position:
            var segment_t: float = (t - stops[i].position) / (stops[i + 1].position - stops[i].position)
            return stops[i].color.lerp(stops[i + 1].color, segment_t)
    return stops[-1].color
```

Each stop has a position (0..1) and a colour. The sampler finds the correct segment and interpolates within it.

Build a corridor of gradients.

```gdscript
func spawn_corridor() -> void:
    for i in 8:
        var wall := MeshInstance3D.new()
        wall.mesh = BoxMesh.new()
        wall.scale = Vector3(5, 3, 0.1)
        wall.position = Vector3(0, 1.5, -i * 3)
        var start_hue: float = float(i) / 8
        var end_hue: float = float(i + 1) / 8
        var tex := gradient_texture(512, 128, Color.from_hsv(start_hue, 0.9, 0.9), Color.from_hsv(end_hue, 0.9, 0.9))
        apply_gradient_wall(wall, tex)
        add_child(wall)
```

Each wall is one segment of the full hue cycle. Walking the corridor walks the spectrum.

Map colour to a mood.

```gdscript
func mood_for_color(color: Color) -> String:
    var hue: float = color.h
    if hue < 0.1 or hue > 0.9: return "alert"
    elif hue < 0.3: return "warm"
    elif hue < 0.5: return "calm"
    elif hue < 0.7: return "fresh"
    else: return "cool"
```

Heuristic mapping. The colour's dominant hue range suggests a mood label.

Animate the gradient through time.

```gdscript
func _process(delta: float) -> void:
    gradient_offset = fmod(gradient_offset + delta * 0.1, 1.0)
    for wall in gradient_walls:
        update_gradient_offset(wall, gradient_offset)
```

The full gradient scrolls along the wall. The corridor appears to flow.

You can now build a gradient texture, multi-stop gradients, a gradient corridor, and animate the flow. Color_Flashlight extends colour into the interaction between light and surface.
