extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const PointBody = preload("point_body.gd")
const LOCAL_PITCH := 0.32
var source := [[0, 1, 0], [0, 0, 1]]
var reflected := false
var widths := [0.32, 0.48]
var width_index := 0
var wall := false
var palette = Palette.new([Color("172051"), Color("fc62ad"), Color("55f3cf")])
var grid: Node3D
var control: PointBody
var label := Label3D.new()

func _ready() -> void:
    grid = GridSurface.new()
    add_child(grid)
    grid.readout.hide()
    control = PointBody.new()
    control.position = Vector3(0, 1.15, 2.5)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.03)
    black.roughness = 0.18
    control.get_child(0).material_override = black
    add_child(control)
    control.action_pressed.connect(choose)
    label.position = Vector3(0, 2.65, 1)
    label.font_size = 26
    label.pixel_size = 0.002
    add_child(label)
    for side in [-1, 1]:
        var card := Label3D.new()
        card.text = "FACE" if side == -1 else "CELL WIDTH"
        card.position = Vector3(side * 0.6, 0.9, 2.5)
        card.font_size = 28
        card.pixel_size = 0.002
        add_child(card)
    place_receiver()
    for address: Vector2i in grid.cells:
        grid.write(address, palette.colours[value_at(address)])

func source_address(address: Vector2i) -> Vector2i:
    var width: int = source[0].size()
    var tile_column := floori(float(address.x) / width)
    var column := posmod(address.x, width)
    if reflected and posmod(tile_column, 2) == 1:
        column = width - 1 - column
    return Vector2i(column, posmod(address.y, source.size()))

func value_at(address: Vector2i) -> int:
    var cell := source_address(address)
    return source[cell.y][cell.x]

func place_receiver() -> void:
    grid.position = Vector3(0.9, 2.2, 0) if wall else Vector3(-0.64, 0.82, 0)
    grid.rotation = Vector3(PI / 2, -PI / 2, 0) if wall else Vector3.ZERO
    grid.scale = Vector3.ONE * widths[width_index] / LOCAL_PITCH

func toggle_face() -> void:
    wall = not wall
    place_receiver()

func toggle_width() -> void:
    width_index = (width_index + 1) % widths.size()
    place_receiver()

func selected_address() -> Vector2i:
    var local: Vector3 = grid.to_local(control.global_position)
    var distance_m: float = local.y * grid.scale.y
    var address := Vector2i(floori((local.x + LOCAL_PITCH / 2) / LOCAL_PITCH), floori((local.z + LOCAL_PITCH / 2) / LOCAL_PITCH))
    if distance_m < 0.12 or distance_m > 0.65 or not grid.cells.has(address):
        return Vector2i(-1, -1)
    return address

func operation() -> String:
    var local := control.global_position
    if local.y < 0.95 or local.y > 1.5 or absf(local.z - 2.5) > 0.25:
        return ""
    if absf(local.x + 0.6) <= 0.25:
        return "FACE"
    if absf(local.x - 0.6) <= 0.25:
        return "CELL WIDTH"
    return ""

func choose(_held: Variant) -> void:
    if operation() == "FACE":
        toggle_face()
    elif operation() == "CELL WIDTH":
        toggle_width()

func _process(_delta: float) -> void:
    var address := selected_address()
    grid.marker.visible = address != Vector2i(-1, -1)
    var selection := "no selection" if operation().is_empty() else operation()
    if grid.marker.visible:
        var cell := source_address(address)
        grid.marker.position = grid.instances.get_instance_transform(grid.cells[address]).origin + Vector3(0, 0.06, 0)
        selection = "surface row %d, column %d -> source row %d, column %d" % [address.y, address.x, cell.y, cell.x]
    label.text = "%s / CELL %.2f m / SOURCE WIDTH %.2f m\n%s\nGRIP: inspect / TRIGGER at label: change receiver" % ["RIGHT WALL" if wall else "TABLE", widths[width_index], source[0].size() * widths[width_index], selection]
