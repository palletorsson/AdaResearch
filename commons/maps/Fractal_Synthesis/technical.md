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

```gdscript
func render_julia(c: Vector2, width: int, height: int, zoom: float) -> Image:
    var image = Image.create(width, height, false, Image.FORMAT_RGB8)

    for px in range(width):
        for py in range(height):
            # Map pixel to complex plane
            var z = Vector2(
                (px - width / 2.0) / (width / 4.0) / zoom,
                (py - height / 2.0) / (height / 4.0) / zoom
            )

            var iterations = julia_iterate(z, c, 100)

            # Color based on escape time
            var color = escape_time_color(iterations, 100)
            image.set_pixel(px, py, color)

    return image

func escape_time_color(iterations: int, max_iter: int) -> Color:
    if iterations == max_iter:
        return Color.BLACK  # In set

    # Smooth coloring
    var t = float(iterations) / float(max_iter)
    return Color.from_hsv(t * 0.7, 0.8, 1.0)
```

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

```gdscript
func mandelbrot_iterate(c: Vector2, max_iterations: int) -> int:
    var z = Vector2.ZERO  # Always start at z=0

    for i in range(max_iterations):
        var z_new = Vector2(
            z.x * z.x - z.y * z.y + c.x,
            2.0 * z.x * z.y + c.y
        )
        z = z_new

        if z.length_squared() > 4.0:
            return i

    return max_iterations

# Key relationship:
# If c is IN the Mandelbrot set → Julia set for c is CONNECTED
# If c is OUT of the Mandelbrot set → Julia set for c is DISCONNECTED (Cantor dust)
# If c is ON the Mandelbrot boundary → Julia set has maximum complexity

func julia_connectivity(c: Vector2) -> String:
    var mandel_result = mandelbrot_iterate(c, 1000)
    if mandel_result == 1000:
        return "connected"
    else:
        return "disconnected"
```

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

```gdscript
func julia_heightmap(c: Vector2, resolution: int, max_height: float) -> PackedFloat32Array:
    var heights = PackedFloat32Array()
    heights.resize(resolution * resolution)

    for x in range(resolution):
        for y in range(resolution):
            var z = Vector2(
                (x - resolution / 2.0) / (resolution / 4.0),
                (y - resolution / 2.0) / (resolution / 4.0)
            )

            var iterations = julia_iterate(z, c, 50)
            var height = (float(iterations) / 50.0) * max_height

            heights[x + y * resolution] = height

    return heights

func create_julia_terrain(c: Vector2):
    var heights = julia_heightmap(c, 64, 5.0)
    var terrain_mesh = generate_terrain_mesh(heights, 64)
    $TerrainMesh.mesh = terrain_mesh
```

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

```gdscript
# Compute shader for Julia set
shader_type canvas_item;

uniform vec2 c;
uniform int max_iterations;
uniform float zoom;

void fragment() {
    vec2 z = (UV - 0.5) * 4.0 / zoom;

    int iterations = 0;
    for (int i = 0; i < max_iterations; i++) {
        if (dot(z, z) > 4.0) break;
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        iterations++;
    }

    float t = float(iterations) / float(max_iterations);
    COLOR = vec4(hsv_to_rgb(vec3(t * 0.7, 0.8, iterations == max_iterations ? 0.0 : 1.0)), 1.0);
}
```

## Key Takeaway
The Julia set is the Mandelbrot's complement—same formula (z² + c), different question. Mandelbrot asks "which c values are bounded?"; Julia asks "which z values are bounded for fixed c?". Each point in the Mandelbrot set indexes a connected Julia set; each point outside indexes disconnected dust. **Parameter space and dynamic space are dual views of the same underlying mathematics.**
