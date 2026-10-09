extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
@export var count := 7
@export var spacing := 0.5
@export var mass := 1.0
@export var restoring := 4.0
@export var coupling := 12.0
@export var damping := 0.3
@export var running := true
var displacement: Array[float] = []
var velocity: Array[float] = []
var points: Array[RigidBody3D] = []
var links: Array[MeshInstance3D] = []
var label: Label3D
var elapsed := 0.0

func _ready() -> void:
    assert(count >= 3 and mass > 0.0)
    for i in range(count):
        var point := PointBody.new()
        point.enabled = false
        point.collision_layer = 0
        point.collision_mask = 0
        add_child(point)
        var ink := StandardMaterial3D.new()
        ink.albedo_color = Color(0.95, 0.45, 0.65) if i == count / 2 else Color(0.04, 0.04, 0.05)
        ink.roughness = 0.25
        point.get_child(0).material_override = ink
        points.append(point)
        if i > 0:
            var link := LineSkin.new()
            add_child(link)
            links.append(link)
    label = Label3D.new()
    label.position = Vector3(0, 2.5, 0)
    label.font_size = 30
    label.pixel_size = 0.004
    add_child(label)
    reset()

func reset() -> void:
    displacement.resize(count)
    velocity.resize(count)
    displacement.fill(0.0)
    velocity.fill(0.0)
    displacement[count / 2] = 0.3
    elapsed = 0.0
    draw_state()

func _physics_process(delta: float) -> void:
    if running:
        step(delta)
    draw_state()

func step(delta: float) -> void:
    var next_displacement := displacement.duplicate()
    var next_velocity := velocity.duplicate()
    for i in range(count - 1, -1, -1):
        var force := -restoring * displacement[i] - damping * velocity[i]
        for j in [i - 1, i + 1]:
            if j >= 0 and j < count:
                force += coupling * (displacement[j] - displacement[i])
        next_velocity[i] = velocity[i] + force / mass * delta
        next_displacement[i] = displacement[i] + next_velocity[i] * delta
    displacement = next_displacement
    velocity = next_velocity
    elapsed += delta

func draw_state() -> void:
    for i in range(count):
        points[i].position = Vector3((i - (count - 1) * 0.5) * spacing, 1.4 + displacement[i], 0)
    for i in range(links.size()):
        var a := points[i].position
        var difference := points[i + 1].position - a
        links[i].show_segment(a, difference, difference.length())
        links[i].visible = coupling > 0.0
    label.text = "t %.2f s | coupling %.1f N/m\ncentre %+.3f m | next %+.3f m" % [elapsed, coupling, displacement[count / 2], displacement[count / 2 + 1]]
