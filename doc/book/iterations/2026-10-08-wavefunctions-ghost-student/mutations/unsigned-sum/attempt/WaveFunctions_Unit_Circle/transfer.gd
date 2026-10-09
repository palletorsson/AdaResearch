extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
@export var centre := Vector3(-0.4, 1.6, 0)
@export var radius := 0.6
@export var angle := 0.0
@export var angular_speed := PI
@export var running := true
var point: RigidBody3D
var marker: MeshInstance3D
var label: Label3D
var rods: Array[MeshInstance3D] = []

func circle_position(theta: float) -> Vector3:
    return centre + radius * Vector3(cos(theta), sin(theta), 0)

func graph_position(theta: float) -> Vector3:
    return centre + Vector3(1.6 + 4.0 * theta / TAU, radius * sin(theta), 0)

func line_between(a: Vector3, b: Vector3, colour: Color) -> MeshInstance3D:
    var line := LineSkin.new()
    line.material_override.albedo_color = colour
    add_child(line)
    line.show_segment(a, b - a, a.distance_to(b))
    return line

func _ready() -> void:
    point = PointBody.new()
    point.enabled = false
    point.collision_layer = 0
    point.collision_mask = 0
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.035, 0.035, 0.04)
    ink.roughness = 0.22
    point.get_child(0).material_override = ink
    marker = MeshInstance3D.new()
    var cube := BoxMesh.new()
    cube.size = Vector3.ONE * 0.09
    marker.mesh = cube
    add_child(marker)
    var grey := Color(0.45, 0.45, 0.45)
    for i in range(48):
        var a := TAU * i / 48.0
        var b := TAU * (i + 1) / 48.0
        line_between(circle_position(a), circle_position(b), grey)
        line_between(graph_position(a), graph_position(b), grey)
    line_between(centre - Vector3.RIGHT * 1.2, centre + Vector3.RIGHT * 1.2, grey)
    line_between(centre - Vector3.UP * 1.2, centre + Vector3.UP * 1.2, grey)
    for colour in [grey, Color(0.2, 0.75, 0.35), Color(0.2, 0.5, 0.95), grey]:
        rods.append(line_between(centre, centre, colour))
    label = Label3D.new()
    label.position = centre + Vector3(2.4, 1.4, 0)
    label.font_size = 30
    label.pixel_size = 0.006
    label.outline_size = 8
    add_child(label)
    draw_state()

func _process(delta: float) -> void:
    if running:
        angle = fposmod(angle + angular_speed * delta, TAU)
    draw_state()

func draw_state() -> void:
    var p := circle_position(angle)
    point.position = p
    marker.position = graph_position(angle)
    var starts := [centre, Vector3(p.x, centre.y, centre.z), Vector3(centre.x, p.y, centre.z), p]
    var ends := [p, p, p, marker.position]
    for i in range(rods.size()):
        var displacement: Vector3 = ends[i] - starts[i]
        rods[i].show_segment(starts[i], displacement, displacement.length())
    label.text = "angle %.2f rad | x %+.2f m | y %+.2f m\nGRAPH: horizontal = angle; vertical = y offset" % [angle, p.x - centre.x, p.y - centre.y]
