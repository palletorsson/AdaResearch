# Color Grid Pallet

A grid becomes a palette. Each cell holds a colour.

Build the grid.

```gdscript
const GRID_SIZE := Vector2i(4, 4)
var palette_grid: Array = []  # 2D array of Color

func build_grid() -> void:
    palette_grid.clear()
    for y in GRID_SIZE.y:
        var row: Array = []
        for x in GRID_SIZE.x:
            row.append(Color.WHITE)
        palette_grid.append(row)
```

Sixteen cells, all white. The grid is a small image with each pixel editable.

Paint a cell.

```gdscript
func paint_cell(x: int, y: int, color: Color) -> void:
    palette_grid[y][x] = color
    emit_signal("palette_changed")
```

Direct assignment. The signal lets listeners know to re-render.

Render the grid as a texture.

```gdscript
func grid_to_texture() -> ImageTexture:
    var image := Image.create(GRID_SIZE.x, GRID_SIZE.y, false, Image.FORMAT_RGBA8)
    for y in GRID_SIZE.y:
        for x in GRID_SIZE.x:
            image.set_pixel(x, y, palette_grid[y][x])
    return ImageTexture.create_from_image(image)
```

Each grid cell becomes one texel. The result is a 4x4 texture ready to apply to any surface.

Scale the texture up without blurring.

```gdscript
func apply_pixelated(mesh: MeshInstance3D, texture: ImageTexture) -> void:
    var material := StandardMaterial3D.new()
    material.albedo_texture = texture
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    mesh.material_override = material
```

Nearest-neighbour filtering preserves the discrete blocks. Linear filtering would blur them into gradients.

Link cells to a painting controller.

```gdscript
func _on_cell_clicked(cell_coords: Vector2i) -> void:
    var selected_color: Color = color_picker.selected_color
    paint_cell(cell_coords.x, cell_coords.y, selected_color)
```

The user picks a colour, then clicks a cell. The cell updates to the picked colour.

Spawn a 3D constellation from the grid.

```gdscript
func spawn_color_constellation() -> void:
    for y in GRID_SIZE.y:
        for x in GRID_SIZE.x:
            var sphere := MeshInstance3D.new()
            sphere.mesh = SphereMesh.new()
            sphere.position = Vector3(x, y, 0) * 0.5
            var mat := StandardMaterial3D.new()
            mat.albedo_color = palette_grid[y][x]
            sphere.material_override = mat
            add_child(sphere)
```

Each grid cell becomes a coloured sphere. The grid's 2D layout becomes a spatial relationship.

Interpolate between cells for a smooth palette.

```gdscript
func smooth_sample(u: float, v: float) -> Color:
    var x: float = u * (GRID_SIZE.x - 1)
    var y: float = v * (GRID_SIZE.y - 1)
    var x0: int = int(floor(x)); var x1: int = min(x0 + 1, GRID_SIZE.x - 1)
    var y0: int = int(floor(y)); var y1: int = min(y0 + 1, GRID_SIZE.y - 1)
    var fx: float = x - x0; var fy: float = y - y0
    var c00: Color = palette_grid[y0][x0]; var c10: Color = palette_grid[y0][x1]
    var c01: Color = palette_grid[y1][x0]; var c11: Color = palette_grid[y1][x1]
    return c00.lerp(c10, fx).lerp(c01.lerp(c11, fx), fy)
```

Bilinear interpolation between four corner cells. The result is a smooth palette at any (u, v) position.

You can now build a grid palette, paint cells, render the grid as a pixelated texture, and sample a smooth palette via interpolation. Color_Rainbow extends into a continuous spectrum.
