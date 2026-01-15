# Color_Grid_Pallet - Technical Tutorial

## Grid-Based Color Systems

### Color as Indexed Data

```gdscript
# Every tile in the grid stores a color at coordinates
var color_grid: Array[Array] = []

func initialize_grid(width: int, height: int):
    color_grid.resize(height)
    for y in range(height):
        color_grid[y] = []
        color_grid[y].resize(width)
        for x in range(width):
            color_grid[y][x] = Color.WHITE  # Default color

func set_tile_color(x: int, y: int, color: Color):
    if x >= 0 and x < width and y >= 0 and y < height:
        color_grid[y][x] = color
        update_tile_visual(x, y)

func get_tile_color(x: int, y: int) -> Color:
    return color_grid[y][x]
```

### The GridColorizer Implementation

```gdscript
extends Node3D

signal tile_colored(x: int, y: int, color: Color)

@export var grid_reference: GridMap
@export var current_color: Color = Color.RED

var selected_tile: Vector2i = Vector2i(-1, -1)

func _on_tile_selected(world_pos: Vector3):
    # Convert world position to grid coordinates
    var grid_pos = grid_reference.local_to_map(world_pos)
    selected_tile = Vector2i(grid_pos.x, grid_pos.z)
    highlight_tile(selected_tile)

func apply_color():
    if selected_tile.x >= 0:
        emit_signal("tile_colored", selected_tile.x, selected_tile.y, current_color)
        color_tile_mesh(selected_tile, current_color)

func color_tile_mesh(pos: Vector2i, color: Color):
    # Access the specific tile's material
    var cell_item = grid_reference.get_cell_item(Vector3i(pos.x, 0, pos.y))
    # Apply color through material override or shader
```

### Images as Color Grids

```gdscript
# An image IS a color grid
var image = Image.create(256, 256, false, Image.FORMAT_RGBA8)

# Set pixel color (same as setting grid tile)
image.set_pixel(x, y, Color.RED)

# Get pixel color
var pixel_color = image.get_pixel(x, y)

# The conceptual model is identical:
# Grid tile at (3, 5) = Pixel at (3, 5)
# Both store Color values at indexed positions
```

### Spectrum Forest: 3D Color Space

```gdscript
# The spectrum forest visualizes color in 3D
extends Node3D

func create_spectrum_forest():
    var spacing = 0.5

    for h in range(10):  # Hue variation (X axis)
        for s in range(10):  # Saturation variation (Y axis)
            for v in range(10):  # Value variation (Z axis)
                var tree = create_colored_tree()
                tree.position = Vector3(h, v, s) * spacing

                # Color from position
                var color = Color.from_hsv(
                    h / 10.0,  # Hue
                    s / 10.0,  # Saturation
                    v / 10.0   # Value
                )
                tree.set_color(color)
                add_child(tree)

# Walking through the forest = walking through color space
# X = hue, Y = value, Z = saturation
# Position encodes color
```

### Color Palette Management

```gdscript
# Predefined palettes for quick selection
var palettes = {
    "primary": [Color.RED, Color.GREEN, Color.BLUE],
    "secondary": [Color.CYAN, Color.MAGENTA, Color.YELLOW],
    "grayscale": [],
    "rainbow": []
}

func _ready():
    # Generate grayscale palette
    for i in range(10):
        var gray = float(i) / 9.0
        palettes["grayscale"].append(Color(gray, gray, gray))

    # Generate rainbow palette
    for i in range(12):
        var hue = float(i) / 12.0
        palettes["rainbow"].append(Color.from_hsv(hue, 1.0, 1.0))

func select_from_palette(palette_name: String, index: int) -> Color:
    return palettes[palette_name][index]
```

### Real-Time Grid Updates

```gdscript
# Efficient grid coloring with MultiMesh
extends MultiMeshInstance3D

func update_tile_color(index: int, color: Color):
    # Use custom data to pass color to shader
    multimesh.set_instance_custom_data(index, color)

# Shader receives color per instance
# shader_type spatial;
# instance uniform vec4 instance_color : source_color;
# void fragment() {
#     ALBEDO = instance_color.rgb;
# }
```

### Additive Color Mixing on Grid

```gdscript
# When colors overlap or blend
func mix_tile_colors(x: int, y: int, new_color: Color, blend_mode: String):
    var existing = get_tile_color(x, y)
    var result: Color

    match blend_mode:
        "replace":
            result = new_color
        "additive":
            # Light mixing (RGB add, clamped)
            result = Color(
                min(existing.r + new_color.r, 1.0),
                min(existing.g + new_color.g, 1.0),
                min(existing.b + new_color.b, 1.0)
            )
        "multiply":
            # Subtractive-like effect
            result = existing * new_color
        "average":
            result = existing.lerp(new_color, 0.5)

    set_tile_color(x, y, result)
```

### Export Grid as Image

```gdscript
# Save your grid painting as an image file
func export_grid_to_image(filename: String):
    var width = color_grid[0].size()
    var height = color_grid.size()
    var image = Image.create(width, height, false, Image.FORMAT_RGBA8)

    for y in range(height):
        for x in range(width):
            image.set_pixel(x, y, color_grid[y][x])

    image.save_png("user://" + filename + ".png")
```

## Key Takeaway

The grid colorizer reveals that **images are color grids**. Every digital image is a 2D array of color values at indexed positions. When you color a grid tile, you are doing exactly what image editing software does: setting pixel values at coordinates. The spectrum forest extends this to 3D, showing that color itself is a three-dimensional space (HSV or RGB) that can be navigated spatially.
