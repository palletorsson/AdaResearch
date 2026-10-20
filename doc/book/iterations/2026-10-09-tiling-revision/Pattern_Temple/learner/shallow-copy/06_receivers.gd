extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const PointBody = preload("point_body.gd")
const RULE_NAMES := ["P1", "PM", "PG"]
const ACTIONS := ["TARGET", "RULE", "ALL"]
var source := [[0, 1, 0], [0, 0, 1]]
var recipes: Array = []
var receivers: Array[Node3D] = []
var target := 0
var palette = Palette.new([Color("172051"), Color("fc62ad"), Color("55f3cf")])
var control: PointBody
var label := Label3D.new()

func _ready() -> void:
    assert(source.size() % 2 == 0, "PG needs an even number of source rows.")
    for i in 2:
        recipes.append({"source": source.duplicate(true), "rule": 2})
        var grid := GridSurface.new()
        add_child(grid)
        grid.readout.hide()
        grid.position = Vector3(-1.5, 0.82, 0) if i == 0 else Vector3(0.3, 2.2, 0)
        grid.rotation.x = 0 if i == 0 else PI / 2
        receivers.append(grid)
        repaint(i)
    control = PointBody.new()
    control.position = Vector3(0, 1.15, 2.5)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.03)
    black.roughness = 0.18
    control.get_child(0).material_override = black
    add_child(control)
    control.action_pressed.connect(choose)
    label.position = Vector3(0, 2.75, 0)
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

func source_address(i: int, address: Vector2i) -> Vector2i:
    var data: Array = recipes[i]["source"]
    var rule: int = recipes[i]["rule"]
    var width: int = data[0].size()
    var odd := posmod(floori(float(address.x) / width), 2) == 1
    var cell := Vector2i(posmod(address.x, width), posmod(address.y, data.size()))
    if rule != 0 and odd:
        cell.x = width - 1 - cell.x
    if rule == 2 and odd:
        cell.y = posmod(cell.y + data.size() / 2, data.size())
    return cell

func value_at(i: int, address: Vector2i) -> int:
    var cell := source_address(i, address)
    return recipes[i]["source"][cell.y][cell.x]

func repaint(i: int) -> void:
    for address: Vector2i in receivers[i].cells:
        receivers[i].write(address, palette.colours[value_at(i, address)])

func next_target() -> void:
    target = (target + 1) % receivers.size()

func cycle_rule() -> void:
    recipes[target]["rule"] = (recipes[target]["rule"] + 1) % RULE_NAMES.size()
    repaint(target)

func dress_all() -> void:
    for i in receivers.size():
        if i != target:
            recipes[i] = recipes[target].duplicate()
            repaint(i)

func selected_address() -> Vector2i:
    var grid: Node3D = receivers[target]
    var local: Vector3 = grid.to_local(control.global_position)
    var cell := Vector2i(floori((local.x + 0.16) / 0.32), floori((local.z + 0.16) / 0.32))
    if local.y < 0.12 or local.y > 0.65 or not grid.cells.has(cell):
        return Vector2i(-1, -1)
    return cell

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
        "TARGET": next_target()
        "RULE": cycle_rule()
        "ALL": dress_all()
        _:
            var address := selected_address()
            if address != Vector2i(-1, -1):
                var cell := source_address(target, address)
                var data: Array = recipes[target]["source"]
                data[cell.y][cell.x] = (data[cell.y][cell.x] + 1) % palette.colours.size()
                repaint(target)

func _process(_delta: float) -> void:
    var address := selected_address()
    for i in receivers.size():
        receivers[i].marker.visible = i == target and address != Vector2i(-1, -1)
    var selection := operation()
    if address != Vector2i(-1, -1):
        receivers[target].mark(address)
        var cell := source_address(target, address)
        selection = "surface [%d,%d] -> source [%d,%d]" % [address.y, address.x, cell.y, cell.x]
    label.text = "%s / %s\n%s\nGRIP: inspect / TRIGGER: paint or use named action" % ["TABLE" if target == 0 else "WALL", RULE_NAMES[recipes[target]["rule"]], selection]
