extends Node3D

const WaitCycle = preload("wait_cycle.gd")
const PointBody = preload("point_body.gd")
var cycle := WaitCycle.new()
var clock_ms := 0.0
var running := false
var point: XRToolsPickable
var stone: AnimatableBody3D
var collision: CollisionShape3D
var surface: MeshInstance3D
var crown: MeshInstance3D
var beacon: MeshInstance3D
var status: Label3D

func _ready() -> void:
    box(Vector3(3, 0.14, 1.8), Vector3(0, 0.07, 0), Color(0.12, 0.12, 0.14))
    box(Vector3(3, 2.5, 0.06), Vector3(0, 1.25, -0.8), Color(0.84, 0.82, 0.78))
    label("ONE STONE / ONE CLOCK", Vector3(0, 2.3, -0.75), 30)
    status = label("", Vector3(0, 1.96, -0.74), 21)
    stone = AnimatableBody3D.new()
    stone.sync_to_physics = false
    stone.collision_layer = 1
    stone.collision_mask = 0
    add_child(stone)
    surface = box(Vector3.ONE * 0.6, Vector3.ZERO, Color.WHITE)
    remove_child(surface)
    stone.add_child(surface)
    collision = CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3.ONE * 0.6
    collision.shape = shape
    stone.add_child(collision)
    crown = MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = 0.31
    ring.outer_radius = 0.37
    crown.mesh = ring
    crown.material_override = finish(Color(1, 0.78, 0.13))
    crown.position.y = 0.33
    stone.add_child(crown)
    beacon = MeshInstance3D.new()
    var bulb := SphereMesh.new()
    bulb.radius = 0.05
    bulb.height = 0.1
    beacon.mesh = bulb
    beacon.position.y = 0.43
    beacon.material_override = finish(Color.WHITE)
    stone.add_child(beacon)
    for i in range(4):
        label(["REPLAY", "RUN / STOP", "CUE", "+0.25 s"][i], Vector3((i - 1.5) * 0.7, 0.35, 0.91), 22)
    point = PointBody.new()
    point.position = Vector3(0, 0.6, 0.7)
    add_child(point)
    point.action_pressed.connect(use_point)
    replay()

func replay() -> void:
    running = false
    clock_ms = 0.0
    cycle.replay()
    redraw()

func _physics_process(delta: float) -> void:
    if running:
        clock_ms += delta * 1000.0
        cycle.advance_to(int(clock_ms))
    redraw()

func use_point(_held) -> void:
    var x := point.global_position.x
    if x < -0.7:
        replay()
    elif x < 0.0:
        running = not running
    elif x < 0.7:
        cycle.cue_enabled = not cycle.cue_enabled
    elif not running:
        clock_ms += 250.0
        cycle.advance_to(int(clock_ms))
    redraw()

func redraw() -> void:
    stone.position = Vector3(0, 1.35 + cycle.height() * 0.6, 0)
    collision.disabled = not cycle.supports()
    surface.material_override.albedo_color = [Color.CYAN, Color.CORAL, Color(0.15, 0.16, 0.2), Color.GREEN][cycle.state]
    crown.visible = cycle.cue_visible()
    beacon.visible = cycle.state == WaitCycle.State.LEAVES or cycle.state == WaitCycle.State.RETURNS
    status.text = "%s | %s | seed %d | draw %d\nwait %.3f s | left %.3f s | support %s\nclock %.3f s | phase ends %.3f s" % [
        WaitCycle.NAMES[cycle.state], "RUNNING" if running else "PAUSED", cycle.run_seed, cycle.draws,
        cycle.drawn_seconds, cycle.wait_left_ms() / 1000.0, "ON" if cycle.supports() else "OFF",
        cycle.now_ms / 1000.0, cycle.until_ms / 1000.0]

func finish(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return mat

func box(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
    var view := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    view.mesh = mesh
    view.position = at
    view.material_override = finish(color)
    add_child(view)
    return view

func label(words: String, at: Vector3, font_size: int) -> Label3D:
    var view := Label3D.new()
    view.text = words
    view.position = at
    view.font_size = font_size
    view.pixel_size = 0.0025
    view.modulate = Color(0.02, 0.02, 0.02) if at.z < 0 else Color.WHITE
    view.outline_size = 0
    add_child(view)
    return view
