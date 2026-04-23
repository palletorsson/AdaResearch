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

## Key Takeaway

The grid colorizer reveals that **images are color grids**. Every digital image is a 2D array of color values at indexed positions. When you color a grid tile, you are doing exactly what image editing software does: setting pixel values at coordinates. The spectrum forest extends this to 3D, showing that color itself is a three-dimensional space (HSV or RGB) that can be navigated spatially.

## Implementation Notes and Complexity

The palette grid is a 2D array of colour cells whose contents can be edited in place. Each cell holds an RGBA quadruple. The grid's dimensions are fixed at load, but the cell values are mutable, so the whole palette can be retoned without reallocating. The edit operation is O(1) per cell; a full-palette retone is O(W times H) where W and H are the grid's dimensions.

The grid is backed by an ImageTexture in Godot. Editing a cell writes to the underlying Image, and the Image must be pushed back to the texture for the GPU to see the change. This push is not free: it triggers a texture upload, which in the worst case stalls the render thread briefly. For interactive editing at palette scale (16 by 16 or smaller), the stall is imperceptible. For larger grids, batching multiple cell edits between pushes is necessary to maintain frame rate.

The palette's content is referenced by other nodes via palette-index lookups. When the palette changes, those nodes do not automatically redraw; they have to be notified and re-render. Godot's signal system is the conventional plumbing. The palette emits a palette_changed signal, and interested nodes connect to it. The signal is cheap — a few function calls — but the downstream redraw can be expensive depending on how many nodes are listening and how much geometry each has to refresh.

Within the sequence, Color_Grid_Pallet introduces the palette as a first-class artifact the learner can edit. Previous maps treated colour as assignment; this map treats it as collection. The grid's cells can be rearranged, retoned, or replaced wholesale, and the changes propagate to whatever art is referencing them. The sequence's later maps extend this with interactive palette composition and wavelength-based response.
