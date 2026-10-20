extends Node3D

const PointBody = preload("point_body.gd")
const Canvas = preload("canvas.gd")
const Controls = preload("controls.gd")

@export var ink := Color(0.8, 0.2, 0.6)
var radius := 0.06
var max_distance := 3.0
var automatic := true
var elapsed := 0.0
var held := false
var active := false
var spraying := false
var painting := false
var point: XRToolsPickable
var canvas: MeshInstance3D
var readout: Label3D

func _ready() -> void:
    canvas = Canvas.new()
    canvas.position = Vector3(0, 1.5, 0)
    canvas.rotation.x = PI / 2.0
    add_child(canvas)
    point = PointBody.new()
    point.position = Vector3(0, 1.5, 1.5)
    add_child(point)
    var stem := MeshInstance3D.new()
    var nozzle := BoxMesh.new()
    nozzle.size = Vector3(0.035, 0.035, 0.22)
    stem.mesh = nozzle
    stem.position.z = -0.2
    point.add_child(stem)
    point.picked_up.connect(func(_body): set_held(true))
    point.dropped.connect(func(_body): set_held(false))
    point.action_pressed.connect(func(_body): set_action("spray", true))
    point.action_released.connect(func(_body): set_action("spray", false))
    readout = Label3D.new()
    readout.position = Vector3(0, 2.95, 0)
    readout.font_size = 30
    readout.pixel_size = 0.004
    add_child(readout)
    add_child(Controls.new())

func set_held(value: bool) -> void:
    held = value
    if not held:
        active = false

func set_action(action_name: String, pressed: bool) -> void:
    if action_name == "spray":
        active = pressed and held

func _physics_process(delta: float) -> void:
    elapsed += delta
    manual_step(delta)
    if automatic:
        automatic_step(elapsed, delta)
    readout.text = "MARK" if painting else ("SPRAY / MISS" if spraying else "READY")

func manual_step(delta: float) -> void:
    painting = false
    spraying = held and active
    if not spraying:
        return
    var origin := point.global_position
    var direction := -point.global_basis.z.normalized()
    var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * max_distance, 1, [point.get_rid()])
    query.collide_with_areas = true
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.get("collider") != canvas.receiver:
        return
    painting = canvas.draw_spray(hit.position, direction, radius, ink, 1.0 - exp(-7.0 * delta))

func automatic_step(time: float, delta: float) -> void:
    var uv := Vector2(0.5 + 0.3 * sin(time), 0.5 + 0.3 * sin(time * 1.3))
    var hit: Vector3 = canvas.world_at(uv)
    canvas.draw_spray(hit, -canvas.global_basis.y.normalized(), radius, ink, 1.0 - exp(-7.0 * delta))
