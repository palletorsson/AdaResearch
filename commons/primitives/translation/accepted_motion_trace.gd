extends MeshInstance3D
## A bounded record of accepted handle positions, seated just in front of the door.
## Visual only: it neither constrains the hand nor changes the door's collision.
const MAX_POINTS := 256
const STEP := 0.006
const RADIUS := 0.004
const DISPLAY_OFFSET := Vector3(0, 0, 0.09)
var points: PackedVector3Array = []
var ink: StandardMaterial3D

func _ready() -> void:
	name = "AcceptedMotionTrace"
	mesh = ImmediateMesh.new()
	ink = StandardMaterial3D.new()
	ink.albedo_color = Color("ffe4a0")
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func reset(at: Vector3) -> void:
	points = PackedVector3Array([at])
	if mesh != null: mesh.clear_surfaces()

func record(at: Vector3) -> void:
	if not at.is_finite(): return
	if points.is_empty(): reset(at); return
	if points[-1].distance_squared_to(at) < STEP * STEP: return
	points.append(at)
	if points.size() > MAX_POINTS: points.remove_at(0)
	_redraw()

func _redraw() -> void:
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, ink)
	for i in range(1, points.size()):
		var a := points[i-1] + DISPLAY_OFFSET
		var b := points[i] + DISPLAY_OFFSET
		var direction := (b-a).normalized()
		var reference := Vector3.FORWARD if absf(direction.dot(Vector3.FORWARD)) < 0.9 else Vector3.UP
		var u := direction.cross(reference).normalized() * RADIUS
		var v := direction.cross(u).normalized() * RADIUS
		for side in 6:
			var angle := TAU * float(side) / 6.0
			var next := TAU * float(side+1) / 6.0
			var offset := u*cos(angle) + v*sin(angle)
			var other := u*cos(next) + v*sin(next)
			for vertex in [a+offset,b+offset,b+other,a+offset,b+other,a+other]:
				mesh.surface_add_vertex(vertex)
	mesh.surface_end()
