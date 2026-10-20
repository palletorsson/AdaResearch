extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const PointBody = preload("point_body.gd")
var palettes := [
    Palette.new([Color.BLACK, Color.WHITE]),
    Palette.new([Color(0.4, 0.4, 0.4), Color(0.4, 0.4, 0.4)]),
    Palette.new([Color("104652"), Color("fcdb35")]),
    Palette.new([Color("512078"), Color("55f3cf")])]
var palette_index := 1
var phase := 0
var playing := false
var elapsed := 0.0
var interval := 0.5
var grid: Node3D
var control: PointBody
var label := Label3D.new()

func _ready() -> void:
    grid = GridSurface.new()
    grid.position = Vector3(-0.64, 0.82, 0)
    add_child(grid)
    grid.marker.hide()
    grid.readout.hide()
    control = PointBody.new()
    control.position = Vector3(0, 1.0, 1.9)
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

func value_at(address: Vector2i) -> int:
    return posmod(address.x + address.y + phase, 2)

func paint() -> void:
    var pair: Array[Color] = palettes[palette_index].colours
    for address: Vector2i in grid.cells:
        grid.write(address, pair[value_at(address)])
    label.text = "PALETTE %d / STEP %d / %s\nGRIP + TRIGGER: left = palette / middle = step / right = play-hold" % [palette_index, phase, "PLAY" if playing else "HOLD"]

func cycle_palette() -> void:
    palette_index = (palette_index + 1) % palettes.size()
    paint()

func step() -> void:
    phase += 1
    elapsed = 0.0
    paint()

func toggle_running() -> void:
    playing = not playing
    paint()

func choose(_held: Variant) -> void:
    if control.position.x < -0.3:
        cycle_palette()
    elif control.position.x > 0.3:
        toggle_running()
    else:
        step()

func _process(delta: float) -> void:
    if not playing:
        return
    elapsed += delta
    var changed := false
    while elapsed >= interval:
        elapsed -= interval
        phase += 1
        changed = true
    if changed:
        paint()
