# Julia Set

z_{n+1} = z_n² + c, but c is fixed and z_0 varies.

Test a Julia point.

```gdscript
func julia_iterations(z0: Vector2, c: Vector2, max_iter: int = 100) -> int:
    var z := z0
    for i in max_iter:
        z = Vector2(z.x * z.x - z.y * z.y, 2 * z.x * z.y) + c
        if z.length_squared() > 4:
            return i
    return max_iter
```

Same iteration as Mandelbrot, but the role of z_0 and c swaps. Each c gives a different Julia set.

Render for a given c.

```gdscript
func render_julia(c: Vector2, bounds: Rect2, resolution: Vector2i, max_iter: int = 100) -> ImageTexture:
    var image := Image.create(resolution.x, resolution.y, false, Image.FORMAT_RGBA8)
    for py in resolution.y:
        for px in resolution.x:
            var z0 := Vector2(
                bounds.position.x + (px / float(resolution.x)) * bounds.size.x,
                bounds.position.y + (py / float(resolution.y)) * bounds.size.y
            )
            var iter: int = julia_iterations(z0, c, max_iter)
            image.set_pixel(px, py, iter_to_color(iter, max_iter))
    return ImageTexture.create_from_image(image)
```

Same texture pipeline; the parameter c distinguishes Julia sets from each other.

Animate c.

```gdscript
var c_value: Vector2 = Vector2(-0.7, 0.27)
var c_progress: float = 0.0

func _process(delta: float) -> void:
    c_progress += delta * 0.3
    var angle: float = c_progress
    c_value = Vector2(cos(angle) * 0.7, sin(angle) * 0.27)
    rerender_julia(c_value)
```

Move c along a loop. The Julia set morphs continuously.

Mandelbrot-Julia relationship.

```gdscript
func is_connected_julia(c: Vector2) -> bool:
    return is_in_set(c, 1000)
```

The Julia set is connected iff c is in the Mandelbrot set. Disconnected Julia sets look like dust; connected ones look like coherent shapes.

Pick up Julia samples.

```gdscript
func spawn_julia_sample(c: Vector2) -> MeshInstance3D:
    var sample := MeshInstance3D.new()
    sample.mesh = QuadMesh.new()
    sample.mesh.size = Vector2(1, 1)
    var texture := render_julia(c, Rect2(-2, -2, 4, 4), Vector2i(256, 256))
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = texture
    sample.material_override = mat
    return sample
```

Render a Julia set to a quad. Grab and inspect.

Gallery of c values.

```gdscript
const GALLERY_C := [
    Vector2(-0.7, 0.27),    # "dragon"
    Vector2(0.285, 0.01),   # "dendrite"
    Vector2(-0.8, 0.156),   # "rabbit"
    Vector2(0.37, 0.1),     # "branches"
]
```

Canonical Julia sets. Each c produces a distinct visual identity.

You can now iterate Julia points, render Julia sets for arbitrary c, animate c, test set connectivity via the Mandelbrot relationship, and build a gallery of classic Julia forms. Fractal_Synthesis extends into composed fractals.

Convert iteration to pixel coordinates.

```gdscript
func complex_to_pixel(c: Vector2, bounds: Rect2, resolution: Vector2i) -> Vector2i:
    return Vector2i(
        int((c.x - bounds.position.x) / bounds.size.x * resolution.x),
        int((c.y - bounds.position.y) / bounds.size.y * resolution.y)
    )
```

Maps math-space to image-space. Inverse of pixel-to-complex used in rendering.
