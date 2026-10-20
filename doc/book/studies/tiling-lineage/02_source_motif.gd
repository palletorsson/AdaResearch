extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const PointBody = preload("point_body.gd")
var source := [[0, 1, 0], [0, 0, 1]]
var palette = Palette.new([Color("172051"), Color("fc62ad"), Color("55f3cf")])
var grid: Node3D
var control: PointBody
var label := Label3D.new()

func _ready() -> void:
    grid = GridSurface.new()
    grid.position = Vector3(-0.64, 0.82, 0)
    add_child(grid)
    grid.readout.hide()
    control = PointBody.new()
    control.position = Vector3(0, 1.15, 1.9)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.03)
    black.roughness = 0.18
    control.get_child(0).material_override = black
    add_child(control)
    control.action_pressed.connect(choose)
    label.position = Vector3(0, 1.65, 0.3)
    label.font_size = 26
    label.pixel_size = 0.002
    add_child(label)
    paint()

func source_address(address: Vector2i) -> Vector2i:
    return Vector2i(posmod(address.x, source[0].size()), posmod(address.y, source.size()))

func value_at(address: Vector2i) -> int:
    var cell := source_address(address)
    return source[cell.y][cell.x]

func paint() -> void:
    for address: Vector2i in grid.cells:
        grid.write(address, palette.colours[value_at(address)])

func selected_address() -> Vector2i:
    var local: Vector3 = grid.to_local(control.global_position)
    var address := Vector2i(floori((local.x + 0.16) / 0.32), floori((local.z + 0.16) / 0.32))
    if local.y < 0.12 or local.y > 0.65 or not grid.cells.has(address):
        return Vector2i(-1, -1)
    return address

func edit(address: Vector2i) -> void:
    var cell := source_address(address)
    source[cell.y][cell.x] = (source[cell.y][cell.x] + 1) % palette.colours.size()
    paint()

func choose(_held: Variant) -> void:
    var address := selected_address()
    if address != Vector2i(-1, -1):
        edit(address)

func _process(_delta: float) -> void:
    var address := selected_address()
    grid.marker.visible = address != Vector2i(-1, -1)
    var selection := "outside / no edit"
    if grid.marker.visible:
        var cell := source_address(address)
        grid.marker.position = grid.instances.get_instance_transform(grid.cells[address]).origin + Vector3(0, 0.06, 0)
        selection = "preview %s -> source row %d, column %d" % [address, cell.y, cell.x]
    label.text = "SOURCE %s\n%s\nGRIP: move above a tile / TRIGGER: change its shared source" % [source, selection]
