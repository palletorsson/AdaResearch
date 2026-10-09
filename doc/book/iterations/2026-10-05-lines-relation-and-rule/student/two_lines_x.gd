# incoming.gd
# Source-bound fixture ASSEMBLED from Point One's small solid-point construction.
# Assumed incoming learner state, not a recovered learner portfolio or museum file.
extends Node3D

const RADIUS := 0.14
const CENTRE := Vector3(0, 1.12, 0)

# Supplied drawing helper; the station remains in the configured museum.
const LineSkin = preload("line_skin.gd")
var point_a: XRToolsPickable
var point_b: XRToolsPickable
var line: MeshInstance3D
var distance := 0.0

func _ready() -> void:
	var radius := RADIUS
	var centre := CENTRE
	var body := MeshInstance3D.new()
	body.name = "VisiblePoint"
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 48
	sphere.rings = 24
	body.mesh = sphere
	body.material_override = material(Color(0.97, 0.97, 0.95))
	body.position = centre
	add_child(body)
	var solid := XRToolsPickable.new()
	solid.name = "PointCollision"
	solid.position = centre
	solid.freeze = true
	solid.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	solid.release_mode = XRToolsPickable.ReleaseMode.FROZEN
	solid.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	solid.collision_layer = 4
	solid.collision_mask = 196615
	var collider := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = radius
	collider.shape = sphere_shape
	solid.add_child(collider)
	add_child(solid)
	body.reparent(solid)

	point_a = solid
	point_b = solid.duplicate() as XRToolsPickable
	point_b.name = "SecondPoint"
	point_b.position = CENTRE + Vector3(1.0, 0, 0)
	add_child(point_b)
	line = LineSkin.new()
	line.name = "Segment"
	add_child(line)
	point_a.position = Vector3(-0.6, 0.82, 0)
	point_b.position = Vector3(0.6, 2.02, 0)
	var c := Vector3(-0.6, 2.02, 0)
	var d := Vector3(0.6, 0.82, 0)
	var other_line := LineSkin.new()
	other_line.name = "OtherSegment"
	add_child(other_line)
	other_line.show_segment(c, d - c, (d - c).length())

func material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.32
	return mat

func _process(_delta: float) -> void:
	# Express both held positions in this station's local coordinates.
	var a := to_local(point_a.global_position)
	var b := to_local(point_b.global_position)
	var displacement := b - a
	distance = displacement.length()
	line.show_segment(a, displacement, distance)
