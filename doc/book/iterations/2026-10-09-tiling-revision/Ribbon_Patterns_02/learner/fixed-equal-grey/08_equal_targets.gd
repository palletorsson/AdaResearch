extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const PointBody = preload("point_body.gd")
const ACTIONS := ["SWAP", "EQUAL", "CONNECT"]
var source := [[0, 1, 0], [0, 0, 1]] # [z][x]
var palette = Palette.new([Color("172051"), Color("fc62ad"), Color("55f3cf")])
var selected := Vector2i(0, 0)
var swapped := false
var equal := false
var connected := false
var reference: Node3D
var control: PointBody
var targets: Array[MeshInstance3D] = []
var surrounds: Array[MeshInstance3D] = []
var bridge: MeshInstance3D
var target_material := StandardMaterial3D.new()
var label := Label3D.new()

func _ready() -> void:
    reference = GridSurface.new()
    add_child(reference)
    reference.position = Vector3(-0.64, 0.7, 1.0)
    reference.readout.hide()
    for cell: Vector2i in reference.cells:
        reference.write(cell, palette.colours[value_at(cell)])
    target_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    for x in [-0.95, 0.95]:
        surrounds.append(box(Vector3(x, 1.75, 0), Vector3(1.8, 1.2, 0.06)))
        var target := box(Vector3(x, 1.75, 0.08), Vector3(0.38, 0.38, 0.06))
        target.material_override = target_material
        targets.append(target)
    bridge = box(Vector3(0, 1.75, 0.09), Vector3(1.9, 0.07, 0.04))
    bridge.material_override = target_material
    control = PointBody.new()
    control.position = Vector3(0, 1.15, 2.8)
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
        card.position = Vector3((i - 1) * 0.6, 0.9, 2.8)
        card.font_size = 28
        card.pixel_size = 0.002
        add_child(card)
    refresh()

func value_at(cell: Vector2i) -> int:
    return source[posmod(cell.y, source.size())][posmod(cell.x, source[0].size())]

func refresh() -> void:
    target_material.albedo_color = palette.colours[value_at(selected)]
    for i in 2:
        var dark := (i == 0) != swapped
        surrounds[i].material_override.albedo_color = Color(0.5, 0.5, 0.5) if equal else (Color(0.1, 0.1, 0.1) if dark else Color(0.9, 0.9, 0.9))
    bridge.visible = connected
    reference.mark(selected)

func operation() -> String:
    var local := to_local(control.global_position)
    if local.y < 0.95 or local.y > 1.5 or absf(local.z - 2.8) > 0.25:
        return ""
    for i in ACTIONS.size():
        if absf(local.x - (i - 1) * 0.6) <= 0.2:
            return ACTIONS[i]
    return ""

func hovered_cell() -> Vector2i:
    var local: Vector3 = reference.to_local(control.global_position)
    var cell := Vector2i(floori((local.x + 0.16) / 0.32), floori((local.z + 0.16) / 0.32))
    if local.y < 0.12 or local.y > 0.35 or not reference.cells.has(cell):
        return Vector2i(-1, -1)
    return cell

func choose(_held: Variant) -> void:
    match operation():
        "SWAP": swapped = not swapped
        "EQUAL": equal = not equal
        "CONNECT": connected = not connected
        _:
            var cell := hovered_cell()
            if cell != Vector2i(-1, -1): selected = cell
    refresh()

func _process(_delta: float) -> void:
    var address := Vector2i(posmod(selected.x, source[0].size()), posmod(selected.y, source.size()))
    label.text = "SOURCE [%d][%d] = %d / BOTH TARGETS #%s\n%s / %s\nGRIP: move / TRIGGER: select cell or act at label" % [address.y, address.x, value_at(selected), target_material.albedo_color.to_html(false), "EQUAL SURROUNDS" if equal else "DARK + LIGHT", operation()]

func box(at: Vector3, size: Vector3) -> MeshInstance3D:
    var view := MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = size
    view.mesh = shape
    view.position = at
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    view.material_override = material
    add_child(view)
    return view
