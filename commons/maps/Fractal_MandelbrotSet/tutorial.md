# Mandelbrot Set

z_{n+1} = z_n² + c. Points c that don't escape form the set.

Test a single point.

```gdscript
func mandelbrot_iterations(c: Vector2, max_iter: int = 100) -> int:
    var z := Vector2.ZERO
    for i in max_iter:
        z = Vector2(z.x * z.x - z.y * z.y, 2 * z.x * z.y) + c
        if z.length_squared() > 4:
            return i
    return max_iter
```

Iterate z = z² + c. Return iteration count if it escapes, max_iter if it stays bounded.

Render the set as a texture.

```gdscript
func render_mandelbrot(bounds: Rect2, resolution: Vector2i, max_iter: int = 100) -> ImageTexture:
    var image := Image.create(resolution.x, resolution.y, false, Image.FORMAT_RGBA8)
    for py in resolution.y:
        for px in resolution.x:
            var c := Vector2(
                bounds.position.x + (px / float(resolution.x)) * bounds.size.x,
                bounds.position.y + (py / float(resolution.y)) * bounds.size.y
            )
            var iter: int = mandelbrot_iterations(c, max_iter)
            var color: Color = iter_to_color(iter, max_iter)
            image.set_pixel(px, py, color)
    return ImageTexture.create_from_image(image)
```

Iterate every pixel; colour by iteration count. The characteristic Mandelbrot silhouette emerges.

Colour mapping.

```gdscript
func iter_to_color(iter: int, max_iter: int) -> Color:
    if iter == max_iter: return Color.BLACK
    var t: float = float(iter) / max_iter
    return Color.from_hsv(t * 0.7, 0.9, 0.9)
```

Points in the set (max iterations reached) are black; escape times colour the boundary.

Smooth colouring.

```gdscript
func smooth_iter(c: Vector2, max_iter: int = 100) -> float:
    var z := Vector2.ZERO
    for i in max_iter:
        z = Vector2(z.x * z.x - z.y * z.y, 2 * z.x * z.y) + c
        if z.length_squared() > 4:
            return i + 1 - log(log(z.length()) / log(2))
    return max_iter
```

Fractional iteration count. Eliminates banding in the colour gradient.

Zoom control.

```gdscript
var view_centre: Vector2 = Vector2(-0.75, 0.0)
var view_width: float = 3.0

func zoom(factor: float, at: Vector2) -> void:
    view_centre = at
    view_width *= factor
    rerender()
```

Zoom in on a point. At factor 0.5, the view doubles in detail.

Detect interior.

```gdscript
func is_in_set(c: Vector2, max_iter: int = 1000) -> bool:
    return mandelbrot_iterations(c, max_iter) == max_iter
```

Definitive membership requires infinite iterations. A finite cap gives approximate membership.

Animate zoom.

```gdscript
var zoom_target: Vector2 = Vector2(-0.745, 0.186)

func animate_zoom(duration: float) -> void:
    var tween := create_tween()
    tween.tween_method(func(t):
        var z: float = pow(0.1, t)
        view_width = 3.0 * z
        rerender()
    , 0.0, 1.0, duration)
```

Exponential zoom. The observer falls toward an interior point; detail unfolds forever.

You can now render the Mandelbrot set, colour it smoothly, zoom interactively, and animate descent into the boundary. Fractal_JuliaSet extends into the related Julia family.
