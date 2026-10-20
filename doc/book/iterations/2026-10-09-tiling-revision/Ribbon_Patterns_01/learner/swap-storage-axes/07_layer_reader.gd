extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const PointBody = preload("point_body.gd")
const LAYER_COUNT := 4
const SHIFT_STEP := 1
const ACTIONS := ["LAYER", "SLICE", "SHIFT"]
var source := [[0, 1, 0], [0, 0, 1]] # [z][x]
var values: Array = [] # [y][z][x]
var layers: Array[Node3D] = []
var layer := 0
var shifted := false
var slice_only := false
var palette = Palette.new([Color("172051"), Color("fc62ad"), Color("55f3cf")])
var reference: Node3D
var control: PointBody
var label := Label3D.new()

func _ready() -> void:
    reference = GridSurface.new()
    add_child(reference)
    reference.position = Vector3(-1.5, 0.65, 0)
    reference.readout.hide()
    for address: Vector2i in reference.cells:
        reference.write(address, palette.colours[source[posmod(address.y, source.size())][posmod(address.x, source[0].size())]])
    for y in LAYER_COUNT:
        var grid := GridSurface.new()
        add_child(grid)
        grid.position = Vector3(0.3, 0.55 + y * 0.4, 0)
        grid.readout.hide()
        layers.append(grid)
    control = PointBody.new()
    control.position = Vector3(0, 1.15, 2.5)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.03)
    black.roughness = 0.18
    control.get_child(0).material_override = black
    add_child(control)
    control.action_pressed.connect(choose)
    label.position = Vector3(0, 2.65, 0)
    label.font_size = 26
    label.pixel_size = 0.002
    add_child(label)
    for i in ACTIONS.size():
        var card := Label3D.new()
        card.text = ACTIONS[i]
        card.position = Vector3((i - 1) * 0.6, 0.9, 2.5)
        card.font_size = 28
        card.pixel_size = 0.002
        add_child(card)
    fill_values()
    update_view()

func source_address(x: int, y: int, z: int) -> Vector2i:
    var offset := y * SHIFT_STEP if shifted else 0
    return Vector2i(posmod(x + offset, source[0].size()), posmod(z, source.size()))

func sample(x: int, y: int, z: int) -> int:
    var cell := source_address(x, y, z)
    return source[cell.y][cell.x]

func fill_values() -> void:
    values.clear()
    for y in LAYER_COUNT:
        var sheet: Array = []
        for z in 5:
            var row: Array = []
            for x in 5:
                row.append(sample(z, y, x))
            sheet.append(row)
        values.append(sheet)
        for address: Vector2i in layers[y].cells:
            layers[y].write(address, palette.colours[values[y][address.y][address.x]])

func update_view() -> void:
    for y in layers.size():
        layers[y].visible = not slice_only or y == layer

func operation() -> String:
    var local := to_local(control.global_position)
    if local.y < 0.95 or local.y > 1.5 or absf(local.z - 2.5) > 0.25:
        return ""
    for i in ACTIONS.size():
        if absf(local.x - (i - 1) * 0.6) <= 0.2:
            return ACTIONS[i]
    return ""

func choose(_held: Variant) -> void:
    match operation():
        "LAYER":
            layer = (layer + 1) % layers.size()
            update_view()
        "SLICE":
            slice_only = not slice_only
            update_view()
        "SHIFT":
            shifted = not shifted
            fill_values()

func selected_address() -> Vector2i:
    var grid: Node3D = layers[layer]
    var local: Vector3 = grid.to_local(control.global_position)
    var cell := Vector2i(floori((local.x + 0.16) / 0.32), floori((local.z + 0.16) / 0.32))
    if local.y < 0.12 or local.y > 0.35 or not grid.cells.has(cell):
        return Vector2i(-1, -1)
    return cell

func _process(_delta: float) -> void:
    var address := selected_address()
    for y in layers.size():
        layers[y].marker.visible = y == layer and address != Vector2i(-1, -1)
    reference.marker.visible = address != Vector2i(-1, -1)
    var selection := operation()
    if address != Vector2i(-1, -1):
        layers[layer].mark(address)
        var cell := source_address(address.x, layer, address.y)
        reference.mark(cell)
        selection = "VOLUME [%d][%d][%d] <- SOURCE [%d][%d] = %d" % [layer, address.y, address.x, cell.y, cell.x, values[layer][address.y][address.x]]
    var visible_cells := 25 if slice_only else LAYER_COUNT * 25
    label.text = "%s / LAYER %d / %d VISIBLE / %d STORED\n%s\nGRIP: inspect / TRIGGER at a label: act" % ["SHIFT" if shifted else "REPEAT", layer, visible_cells, LAYER_COUNT * 25, selection]
