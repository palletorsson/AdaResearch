# Fractals_13 - Technical Tutorial

## The Mandelbrot Set Algorithm

### Basic Iteration

```gdscript
func mandelbrot_iterate(c: Vector2, max_iterations: int) -> int:
    # Start at z = 0
    var z = Vector2.ZERO

    for i in range(max_iterations):
        # z = z² + c
        # Complex multiplication: (a + bi)² = a² - b² + 2abi
        var z_new = Vector2(
            z.x * z.x - z.y * z.y + c.x,
            2.0 * z.x * z.y + c.y
        )
        z = z_new

        # Escape condition: |z| > 2 (actually |z|² > 4)
        if z.length_squared() > 4.0:
            return i  # Escaped at iteration i

    return max_iterations  # Didn't escape (probably in set)
```

### Full Rendering

```gdscript
func render_mandelbrot(
    width: int,
    height: int,
    center: Vector2,
    zoom: float,
    max_iter: int
) -> Image:
    var image = Image.create(width, height, false, Image.FORMAT_RGB8)

    for px in range(width):
        for py in range(height):
            # Map pixel to complex plane
            var c = Vector2(
                center.x + (px - width / 2.0) / (width / 4.0) / zoom,
                center.y + (py - height / 2.0) / (height / 4.0) / zoom
            )

            var iterations = mandelbrot_iterate(c, max_iter)
            var color = color_map(iterations, max_iter)
            image.set_pixel(px, py, color)

    return image

func color_map(iterations: int, max_iter: int) -> Color:
    if iterations == max_iter:
        return Color.BLACK  # In set

    # Smooth coloring
    var t = float(iterations) / float(max_iter)
    return Color.from_hsv(0.6 + t * 0.4, 0.7, 1.0)
```

### Smooth Coloring (Escape Time with Continuous Index)

```gdscript
func mandelbrot_smooth(c: Vector2, max_iterations: int) -> float:
    var z = Vector2.ZERO

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

### Zooming

```gdscript
extends Node3D

var center = Vector2(-0.5, 0.0)  # Slightly left of origin
var zoom = 1.0
var max_zoom = 1e14  # Limited by float precision

func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom_in(event.position)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom_out()

func zoom_in(screen_pos: Vector2):
    # Zoom toward mouse position
    var world_pos = screen_to_complex(screen_pos)
    center = center + (world_pos - center) * 0.2
    zoom *= 1.5

    if zoom > max_zoom:
        zoom = max_zoom  # Precision limit

    update_render()

func screen_to_complex(screen_pos: Vector2) -> Vector2:
    var viewport_size = get_viewport().size
    return Vector2(
        center.x + (screen_pos.x - viewport_size.x / 2.0) / (viewport_size.x / 4.0) / zoom,
        center.y + (screen_pos.y - viewport_size.y / 2.0) / (viewport_size.y / 4.0) / zoom
    )
```

### Famous Locations

```gdscript
var mandelbrot_locations = {
    "main_cardioid": {
        "center": Vector2(-0.5, 0.0),
        "zoom": 1.0
    },
    "seahorse_valley": {
        "center": Vector2(-0.743643887037151, 0.131825904205330),
        "zoom": 10000.0
    },
    "elephant_valley": {
        "center": Vector2(0.281717921930775, 0.5771052841488505),
        "zoom": 1e6
    },
    "spiral": {
        "center": Vector2(-0.761574, -0.0847596),
        "zoom": 1e8
    },
    "mini_mandelbrot": {
        "center": Vector2(-1.768778833, -0.001738996),
        "zoom": 1e10
    }
}
```

### 3D Mandelbrot Visualization

```gdscript
func mandelbrot_heightmap(
    width: int,
    height: int,
    center: Vector2,
    zoom: float,
    max_iter: int
) -> PackedFloat32Array:
    var heights = PackedFloat32Array()
    heights.resize(width * height)

    for px in range(width):
        for py in range(height):
            var c = Vector2(
                center.x + (px - width / 2.0) / (width / 4.0) / zoom,
                center.y + (py - height / 2.0) / (height / 4.0) / zoom
            )

            var iterations = mandelbrot_smooth(c, max_iter)
            heights[px + py * width] = iterations / float(max_iter)

    return heights

func create_mandelbrot_terrain():
    var heights = mandelbrot_heightmap(128, 128, Vector2(-0.5, 0), 1.0, 100)
    var mesh = create_terrain_from_heights(heights, 128, 5.0)
    $MandelbrotTerrain.mesh = mesh
```

### Perturbation Theory for Deep Zooms

```gdscript
# For deep zooms, use perturbation theory to avoid precision loss
# Reference orbit + perturbation

func mandelbrot_perturbation(
    c: Vector2,
    ref_orbit: Array,  # Pre-computed high-precision reference
    max_iterations: int
) -> int:
    var delta = c - ref_c  # Small offset from reference
    var epsilon = Vector2.ZERO  # Perturbation from reference orbit

    for i in range(min(max_iterations, ref_orbit.size() - 1)):
        var z_ref = ref_orbit[i]

        # Perturbation iteration: ε_{n+1} = 2*z_n*ε_n + ε_n² + δ
        var epsilon_new = Vector2(
            2.0 * (z_ref.x * epsilon.x - z_ref.y * epsilon.y) +
            epsilon.x * epsilon.x - epsilon.y * epsilon.y + delta.x,
            2.0 * (z_ref.x * epsilon.y + z_ref.y * epsilon.x) +
            2.0 * epsilon.x * epsilon.y + delta.y
        )
        epsilon = epsilon_new

        var z_approx = z_ref + epsilon
        if z_approx.length_squared() > 4.0:
            return i

    return max_iterations
```

## Implementation Notes

### GPU Acceleration (Shader)

```glsl
shader_type canvas_item;

uniform vec2 center;
uniform float zoom;
uniform int max_iterations;

void fragment() {
    vec2 c = center + (UV - 0.5) * 4.0 / zoom;
    vec2 z = vec2(0.0);

    int iterations = 0;
    for (int i = 0; i < max_iterations; i++) {
        if (dot(z, z) > 4.0) break;
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        iterations++;
    }

    float t = float(iterations) / float(max_iterations);
    if (iterations == max_iterations) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        COLOR = vec4(hsv_to_rgb(vec3(0.6 + t * 0.4, 0.7, 1.0)), 1.0);
    }
}
```

## Key Takeaway
The Mandelbrot set demonstrates that **infinite complexity can arise from the simplest formula**. Five characters (z² + c) produce a boundary of infinite detail. Each zoom reveals new structure, never repeating exactly. This is computational irreducibility: the only way to know what the boundary looks like is to compute it.
