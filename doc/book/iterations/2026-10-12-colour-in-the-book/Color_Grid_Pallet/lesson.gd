extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const Controls = preload("controls.gd")

var selected := Vector2i(2, 2)
var palette_index := 0
var palettes: Array = []
var grid: Node3D

func _ready() -> void:
    var sample := Color(0.1875, 0.5, 0.359375)
    palettes = [
        Palette.new([sample, Color.WHITE, Color.BLACK]),
        Palette.new([Color(0.8, 0.2, 0.6), Color(1, 0.8, 0.15)])
    ]
    grid = GridSurface.new()
    add_child(grid)
    add_child(Controls.new())
    apply_rule()
    select_address(selected)

func select_address(address: Vector2i) -> void:
    if not grid.cells.has(address):
        return
    selected = address
    grid.mark(selected)

func paint_selected() -> void:
    var palette = palettes[palette_index]
    grid.write(selected, palette.current_colour())
    palette.next_colour()
    grid.mark(selected)

func next_palette() -> void:
    palette_index = (palette_index + 1) % palettes.size()

func apply_rule() -> void:
    var colours: Array[Color] = palettes[palette_index].colours
    for address: Vector2i in grid.cells:
        var i := (address.x + address.y) % colours.size()
        grid.write(address, colours[i])
    grid.mark(selected)
