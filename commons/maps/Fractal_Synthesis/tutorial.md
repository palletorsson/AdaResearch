# Fractal Synthesis

Combine fractals. Overlay, intersect, mask.

Define a fractal generator.

```gdscript
class_name FractalGenerator

func evaluate_at(p: Vector2) -> float:
    return 0.0  # override in subclasses
```

Abstract base. Subclasses provide concrete evaluation.

Koch generator.

```gdscript
class_name KochGenerator extends FractalGenerator

func evaluate_at(p: Vector2) -> float:
    return 1.0 if is_near_koch_curve(p) else 0.0
```

Returns 1 near the Koch curve, 0 elsewhere. Binary membership.

Sierpinski generator.

```gdscript
class_name SierpinskiGenerator extends FractalGenerator

func evaluate_at(p: Vector2) -> float:
    return 1.0 if is_inside_sierpinski(p) else 0.0
```

Returns 1 inside a Sierpinski triangle, 0 outside.

Overlay operator.

```gdscript
class_name OverlayOp extends FractalGenerator

var a: FractalGenerator
var b: FractalGenerator

func evaluate_at(p: Vector2) -> float:
    return max(a.evaluate_at(p), b.evaluate_at(p))
```

Union. Output positive wherever either input is positive.

Intersect operator.

```gdscript
class_name IntersectOp extends FractalGenerator

var a: FractalGenerator
var b: FractalGenerator

func evaluate_at(p: Vector2) -> float:
    return min(a.evaluate_at(p), b.evaluate_at(p))
```

Intersection. Positive only where both inputs are positive.

Scale-offset operator.

```gdscript
class_name ScaleOffsetOp extends FractalGenerator

var inner: FractalGenerator
var scale: Vector2
var offset: Vector2

func evaluate_at(p: Vector2) -> float:
    return inner.evaluate_at((p - offset) / scale)
```

Composed transformation. The fractal is scaled and shifted before evaluation.

Render a composed fractal.

```gdscript
func render_composition(generator: FractalGenerator, bounds: Rect2, resolution: Vector2i) -> ImageTexture:
    var image := Image.create(resolution.x, resolution.y, false, Image.FORMAT_RGBA8)
    for py in resolution.y:
        for px in resolution.x:
            var p := Vector2(
                bounds.position.x + (px / float(resolution.x)) * bounds.size.x,
                bounds.position.y + (py / float(resolution.y)) * bounds.size.y
            )
            var value: float = generator.evaluate_at(p)
            image.set_pixel(px, py, Color.WHITE if value > 0.5 else Color.BLACK)
    return ImageTexture.create_from_image(image)
```

Sample the composed generator at every pixel. Any generator tree can be rendered this way.

Build a composition tree.

```gdscript
func example_composition() -> FractalGenerator:
    var koch := KochGenerator.new()
    var sierpinski := SierpinskiGenerator.new()
    var overlay := OverlayOp.new()
    overlay.a = koch
    overlay.b = sierpinski
    return overlay
```

Generators and operators compose like a DAG. Trees of arbitrary depth are possible.

You can now build fractal generators as subclasses, compose them with overlay / intersect / scale-offset operators, and render the composition to a texture. Fractal_CrossSequence extends into comparisons across other sequences.

Convert iteration to pixel coordinates.

```gdscript
func complex_to_pixel(c: Vector2, bounds: Rect2, resolution: Vector2i) -> Vector2i:
    return Vector2i(
        int((c.x - bounds.position.x) / bounds.size.x * resolution.x),
        int((c.y - bounds.position.y) / bounds.size.y * resolution.y)
    )
```

Maps math-space to image-space. Inverse of pixel-to-complex used in rendering.
