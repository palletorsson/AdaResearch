extends Node3D

const PointBody = preload("res://doc/book/studies/forces-point-lineage/point_body.gd")
const PIVOT := Vector3(0, 1.9, 0)
const LENGTH := 0.75
const GRAVITY := 9.8

var angle := 0.45
var speed := 0.0
var damping := 0.995
var held := false
var crossings := 0
var velocities: Array[Vector3] = []
var last_position := Vector3.ZERO
var bob: XRToolsPickable
var rod: MeshInstance3D
var label: Label3D

func _ready() -> void:
    bob = PointBody.new()
    add_child(bob)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color("17191c")
    black.roughness = 0.16
    bob.get_child(0).material_override = black
    bob.picked_up.connect(begin_hold)
    bob.dropped.connect(end_hold)
    bob.set_meta("desktop_hook_target", self)

    rod = MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.008
    cylinder.bottom_radius = 0.008
    cylinder.height = LENGTH
    rod.mesh = cylinder
    add_child(rod)

    var ring := MeshInstance3D.new()
    var circle := TorusMesh.new()
    circle.inner_radius = 0.17
    circle.outer_radius = 0.19
    ring.mesh = circle
    ring.position = PIVOT + Vector3(0, -LENGTH, 0)
    add_child(ring)

    label = Label3D.new()
    label.font_size = 36
    label.pixel_size = 0.0025
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.position = PIVOT + Vector3(0, 0.32, 0)
    add_child(label)
    draw_state()

func _physics_process(delta: float) -> void:
    if held:
        var offset := to_local(bob.global_position) - PIVOT
        angle = clampf(atan2(offset.x, -offset.y), -PI*0.45, PI*0.45)
        velocities.append((bob.global_position - last_position) / delta)
        if velocities.size() > 5:
            velocities.pop_front()
        last_position = bob.global_position
        speed = 0.0
    else:
        advance(delta)
    draw_state()

func advance(delta: float) -> void:
    var previous := angle
    var acceleration := (GRAVITY / LENGTH) * sin(angle)
    speed += acceleration * delta
    speed *= damping
    angle = clampf(angle + speed * delta, -PI*0.45, PI*0.45)
    if previous * angle < 0.0:
        crossings += 1

func begin_hold(_body: Node3D) -> void:
    held = true
    velocities.clear()
    last_position = bob.global_position

func end_hold(_body: Node3D) -> void:
    held = false
    var velocity := Vector3.ZERO
    for sample in velocities:
        velocity += sample
    if not velocities.is_empty():
        velocity /= velocities.size()
    velocity = global_basis.inverse() * velocity
    var tangent := Vector3(cos(angle), sin(angle), 0)
    speed = clampf(velocity.dot(tangent) / LENGTH, -10.0, 10.0)
    velocities.clear()

func on_desktop_grab(_pointer: Node) -> void:
    if not held:
        begin_hold(bob)

func on_desktop_drop(_pointer: Node) -> void:
    if held:
        end_hold(bob)

func draw_state() -> void:
    var offset := Vector3(sin(angle), -cos(angle), 0) * LENGTH
    if not held:
        bob.global_position = to_global(PIVOT + offset)
    rod.position = PIVOT + offset * 0.5
    rod.rotation.z = angle
    label.text = "angle %+.2f rad   speed %+.2f rad/s\ncrossings %d" % [angle, speed, crossings]
