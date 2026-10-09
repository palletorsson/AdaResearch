# Fractals_10 - Technical Tutorial

## Julia Set Algorithm

### Basic Iteration

```gdscript
func julia_iterate(z: Vector2, c: Vector2, max_iterations: int) -> int:
    # z and c are complex numbers represented as Vector2
    # Real part = x, Imaginary part = y

    for i in range(max_iterations):
        # z = z² + c
        # (a + bi)² = a² - b² + 2abi
        var z_new = Vector2(
            z.x * z.x - z.y * z.y + c.x,
            2.0 * z.x * z.y + c.y
        )
        z = z_new

        # Escape condition: |z| > 2
        if z.length_squared() > 4.0:
            return i  # Escaped at iteration i

    return max_iterations  # Didn't escape (probably in set)
```

### Rendering the Julia Set

### Famous Julia Sets

```gdscript
# Different c values produce different Julia sets

var julia_gallery = {
    "dendrite": Vector2(-0.7, 0.27015),
    "rabbit": Vector2(-0.123, 0.745),
    "siegel_disk": Vector2(-0.391, -0.587),
    "douady_rabbit": Vector2(-0.122561, 0.744862),
    "spiral": Vector2(0.285, 0.01),
    "disconnected": Vector2(0.285, 0.53),
    "basilica": Vector2(-1.0, 0.0),
    "airplane": Vector2(-1.755, 0.0)
}

func render_gallery():
    for name in julia_gallery:
        var c = julia_gallery[name]
        var image = render_julia(c, 512, 512, 1.0)
        save_image(image, "julia_%s.png" % name)
```

### Julia-Mandelbrot Relationship

### Interactive Parameter Exploration

```gdscript
extends Node3D

var current_c = Vector2(-0.7, 0.27015)
var julia_texture: ImageTexture

func _ready():
    update_julia()

func _input(event):
    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        # Map mouse position to c parameter
        var mouse_pos = event.position
        current_c = Vector2(
            (mouse_pos.x / get_viewport().size.x - 0.5) * 4.0,
            (mouse_pos.y / get_viewport().size.y - 0.5) * 4.0
        )
        update_julia()

func update_julia():
    var image = render_julia(current_c, 256, 256, 1.0)
    julia_texture = ImageTexture.create_from_image(image)
    $JuliaDisplay.texture = julia_texture
```

### 3D Julia Visualization

### Smooth Iteration Count

```gdscript
func julia_smooth(z: Vector2, c: Vector2, max_iterations: int) -> float:
    for i in range(max_iterations):
        var z_new = Vector2(
            z.x * z.x - z.y * z.y + c.x,
            2.0 * z.x * z.y + c.y
        )
        z = z_new

        if z.length_squared() > 256.0:  # Higher bailout for smoothing
            # Smooth iteration count
            var log_zn = log(z.length_squared()) / 2.0
            var nu = log(log_zn / log(2.0)) / log(2.0)
            return float(i) + 1.0 - nu

    return float(max_iterations)
```

## Implementation Notes

### GPU Acceleration
Julia sets are embarrassingly parallel—each pixel is independent:

## Key Takeaway
The Julia set is the Mandelbrot's complement—same formula (z² + c), different question. Mandelbrot asks "which c values are bounded?"; Julia asks "which z values are bounded for fixed c?". Each point in the Mandelbrot set indexes a connected Julia set; each point outside indexes disconnected dust. **Parameter space and dynamic space are dual views of the same underlying mathematics.**

## Implementation Notes and Complexity

The synthesis map assembles the sequence's fractal techniques into a single composable system. Each fractal — Cantor subtraction, Koch addition, Mandelbrot iteration, Sierpinski removal — is represented as a generator whose output can be composed with the outputs of the others. The composition graph is a small DAG; nodes are generators, edges carry geometry or colour data.

Generators are O(1) to instantiate and O(structure size) to evaluate. A Koch snowflake at depth 5 produces 3 times 4 to the 5 equals 3072 line segments; a Sierpinski triangle at depth 5 produces 3 to the 5 equals 243 filled triangles. The composition cost depends on how outputs are combined: overlaying is O(sum of sizes), intersecting requires spatial data structures and is O(N log N) for N combined elements.

The map's combinator set is deliberately small. Overlay, intersect, mask, and scale-offset are the four operations. Each operation has a clear geometric interpretation, and the small vocabulary means that the learner can compose complex structures without a combinatorial explosion of options. Larger combinator vocabularies tend to produce more expressive systems but harder-to-predict results, and the map prioritises predictability.

Memory management matters at deep composition. A tree with multiple generators at depth 5 or higher can produce tens of thousands of geometric primitives. Godot's scene-tree representation becomes a bottleneck at this scale; the map uses MultiMeshInstance3D for repeated primitives and batches draws aggressively.

Within the sequence, Synthesis closes the fractals arc. Previous maps introduced individual fractals; this map treats them as primitives in a compositional algebra. The algebra's expressive power is the sequence's closing argument: fractals are not only individually beautiful but compositionally productive, and the combinations produce structures that no single fractal could have generated alone.
