extends Node3D


# @identity
# essence: a cubic spline through grabbable points with authored per-span sag
# desire: Grab control points in VR and sculpt hanging cable curves in real-time
# critical_parameter: control_point_count — determines degrees of freedom for curve shaping
# triggers: moving any control point recomputes the spline and regenerates the cable mesh
# emerges: a hanging-cable appearance from downward Bezier handles, without gravity integration
# needs: VR grab on control points [has], cable thickness control [missing]
# relationships: depends on Curve3D spline interpolation; contrasts with BigPipeSystem (flexible vs rigid segments); unlocks curve intuition
# truth: The hand changes a drafted curve; this code neither solves a chain's equilibrium nor conserves its length.

@export var point_scene: PackedScene = preload("res://commons/primitives/point/grab_sphere_point.tscn")
@export var line_material: ShaderMaterial = preload("res://commons/resourses/shaders/line_shader.tres")
@export var control_point_count: int = 4  # Number of control points
@export var cable_length: float = 4.0  # Total length/spacing
@export var cable_thickness: float = 0.02
@export var tube_sides: int = 8
@export var spline_resolution: int = 20  # Points per segment for smooth curve
@export var gravity_sag: float = 0.5  # How much the cable sags

## AXIS — SLACK: where the SHAPE of a run comes from, once the anchors are given.
## Shared word for word with [[line_builder_3d]] and [[BigPipeSystem]], the other two
## builders in this tier. All three are handed a set of points and asked to make a run
## between them; all three have to answer the same question — does the run admit that
## it has weight? One vocabulary, three different homes on it. This artifact's home is
## `catenary`, a legacy name for hand-drafted Bezier sag rather than a physical
## minimisation. The other four values are the
## positions it is arguing AGAINST, made buildable so the argument can be seen.
##
##   chord     weight denied. A taut straight member from anchor to anchor: with the
##             control points level, a rigid rod where a cable should be.
##   spline    weight drawn rather than derived. One fair batten curve between the END
##             anchors only, a constant shallow depth that owes nothing to the span —
##             and the interior control spheres visibly do NOT sit on it. The curve is
##             a drafting convention that has stopped agreeing with its own data.
##   catenary  THE LEGACY LINEAGE. Bezier handles pull each span down by a fraction of
##             its own length, so the run reads as a row of shallow swags with the
##             anchors standing up between them.
##   festoon   more cable than the gap needs. The same swags, ~3x deeper, hanging in
##             loops that drop most of the way to the floor.
##   truss     the run refuses to hang and SHOWS what stops it: the cable pulled dead
##             straight, a chord carried above it, verticals at six stations and a
##             zigzag web between. A cable that has been turned into a girder.
##
## The sag here is a static shape, not a settling animation. Only changed controls
## or settings rebuild the mesh.
@export var slack: String = "catenary"
const SLACKS: PackedStringArray = ["chord", "spline", "catenary", "festoon", "truss"]

var control_points: Array[Node3D] = []
var curve: Curve3D
var mesh_instance: MeshInstance3D
const Sweep = preload("res://commons/primitives/pipes/swept_tube.gd")
var _previous_state: Array = []
var _cached_material: ShaderMaterial
var _material_source: ShaderMaterial

func _ready() -> void:
	curve = Curve3D.new()
	curve.up_vector_enabled = false # The shared sweep transports its own frame.
	mesh_instance = $CableMesh
	_spawn_control_points()
	_update_cable()

func _process(_delta):
	var state: Array = [cable_thickness,tube_sides,spline_resolution,gravity_sag,slack,line_material]
	for point in control_points: state.append(to_local(point.global_position))
	if state != _previous_state:
		_previous_state = state
		_update_cable()

func _spawn_control_points() -> void:
	var parent = $ControlPoints
	control_points.clear()

	# Create control points distributed along cable length
	for i in range(control_point_count):
		var point = point_scene.instantiate()
		var t = float(i) / float(control_point_count - 1) if control_point_count > 1 else 0.5
		var x = (t - 0.5) * cable_length
		point.position = Vector3(x, 1, 0)
		parent.add_child(point)
		control_points.append(point)

func _update_cable() -> void:
	if control_points.size() < 2:
		mesh_instance.mesh = null
		return

	# Non-default constructions remain below. The default retains its Curve3D drape,
	# now with span-aligned handles and a shared continuous sweep.
	if slack != "catenary":
		_update_cable_slack()
		return

	# Clear and rebuild curve
	curve.clear_points()

	# Add control points to the authored sag curve.
	for i in range(control_points.size()):
		var pos = to_local(control_points[i].global_position)
		curve.add_point(pos)

	# Apply sag between control points using Bezier handles
	for i in range(control_points.size() - 1):
		var p1 = to_local(control_points[i].global_position)
		var p2 = to_local(control_points[i + 1].global_position)
		var distance = p1.distance_to(p2)

		# Set Bezier handles for the chosen cable-like sag.
		curve.set_point_out(i, (p2-p1)*0.3 + Vector3.DOWN*gravity_sag*distance*0.5)
		if i + 1 < control_points.size():
			curve.set_point_in(i + 1, (p1-p2)*0.3 + Vector3.DOWN*gravity_sag*distance*0.5)

	# Generate tube mesh from curve
	_generate_tube_from_curve()

func _generate_tube_from_curve() -> void:
	var has_span := false
	for i in curve.point_count-1:
		has_span = has_span or curve.get_point_position(i).distance_to(curve.get_point_position(i+1)) > 0.001
	if not has_span:
		mesh_instance.mesh = null; return
	var total_length := curve.get_baked_length()
	if total_length < 0.001:
		mesh_instance.mesh = null
		return
	var count := clampi(int(total_length*spline_resolution),2,256)
	var positions := PackedVector3Array()
	for i in count:
		positions.append(curve.sample_baked(float(i)/(count-1)*total_length))
	var built: Dictionary = Sweep.build(positions,cable_thickness,tube_sides)
	mesh_instance.mesh = built.get("mesh")
	mesh_instance.material_override = _create_cable_material()

func _create_cable_material() -> ShaderMaterial:
	if _cached_material and _material_source == line_material: return _cached_material
	_material_source = line_material
	var mat := line_material.duplicate() as ShaderMaterial
	_cached_material = mat

	mat.set_shader_parameter("time_offset", 0.0)
	mat.set_shader_parameter("flow_speed", 0.0)
	mat.set_shader_parameter("glow_intensity", 1.0)
	mat.set_shader_parameter("thickness_variation", 0.0)
	mat.set_shader_parameter("pulse_frequency", 0.0)

	return mat

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# LEGACY: this method has always taken a config and done nothing with it. It still
	# ignores every key but one — a `slack` token, so a map can pick the lineage with
	# `cable_builder:0:0#slack:truss`. No rebuild is needed or done here: _process
	# detects changed controls or settings each frame. An unknown word keeps the default.
	if config.has("slack"):
		var s: String = str(config["slack"]).strip_edges().to_lower()
		if SLACKS.has(s):
			slack = s


# ── SLACK ─────────────────────────────────────────────────────────────────────
# Alternate authored constructions retain their original SurfaceTool emitter.


func _update_cable_slack() -> void:
	var anchors := PackedVector3Array()
	for p in control_points:
		anchors.append(to_local(p.global_position))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat := _create_cable_material()
	st.set_material(mat)

	match slack:
		"chord":
			_emit_run(st, anchors, cable_thickness)
		"spline":
			_emit_run(st, _drafted_arc(anchors), cable_thickness)
		"festoon":
			_emit_run(st, _swag(anchors, gravity_sag * 1.2), cable_thickness)
		"truss":
			_emit_run(st, anchors, cable_thickness)
			_emit_truss(st, anchors)
		_:
			# unreachable at a valid value; an unknown word draws the plain chord
			_emit_run(st, anchors, cable_thickness)

	st.generate_normals()
	var mesh := st.commit()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat


## The lofting batten: ONE fair bow between the two end anchors, of a fixed depth that
## owes nothing to the span. The interior control points are left where they are, off
## the curve — which is the argument. A drawn curve is not a derived one.
func _drafted_arc(a: PackedVector3Array) -> PackedVector3Array:
	var n: int = a.size()
	if n < 2:
		return a
	var p0: Vector3 = a[0]
	var pn: Vector3 = a[n - 1]
	var depth: float = 0.45
	var steps: int = 40
	var out := PackedVector3Array()
	for k in range(steps + 1):
		var t: float = float(k) / float(steps)
		var p: Vector3 = p0.lerp(pn, t)
		p.y -= depth * 4.0 * t * (1.0 - t)
		out.append(p)
	return out


## Per-span downward bow, zero at each anchor and deepest at mid-span, scaled by the
## length of that span. factor is the depth as a fraction of the span.
func _swag(a: PackedVector3Array, factor: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	var steps: int = 14
	for i in range(a.size() - 1):
		var p1: Vector3 = a[i]
		var p2: Vector3 = a[i + 1]
		var span: float = p1.distance_to(p2)
		for k in range(steps + 1):
			if i > 0 and k == 0:
				continue
			var t: float = float(k) / float(steps)
			var p: Vector3 = p1.lerp(p2, t)
			p.y -= factor * span * 4.0 * t * (1.0 - t)
			out.append(p)
	return out


## The structure that carries the cable instead of letting it hang: a straight chord
## above the run, verticals at six stations, and a zigzag web between the two.
func _emit_truss(st: SurfaceTool, a: PackedVector3Array) -> void:
	var n: int = a.size()
	if n < 2:
		return
	var rise := Vector3(0.0, 0.7, 0.0)
	var r: float = maxf(cable_thickness * 0.8, 0.012)
	var low_a: Vector3 = a[0]
	var low_b: Vector3 = a[n - 1]
	var top_a: Vector3 = low_a + rise
	var top_b: Vector3 = low_b + rise
	_emit_run(st, _pair(top_a, top_b), r)
	var stations: int = 6
	for i in range(stations + 1):
		var t: float = float(i) / float(stations)
		var low: Vector3 = low_a.lerp(low_b, t)
		var high: Vector3 = top_a.lerp(top_b, t)
		_emit_run(st, _pair(low, high), r)
		if i < stations:
			var t2: float = float(i + 1) / float(stations)
			var low2: Vector3 = low_a.lerp(low_b, t2)
			var high2: Vector3 = top_a.lerp(top_b, t2)
			if i % 2 == 0:
				_emit_run(st, _pair(low, high2), r)
			else:
				_emit_run(st, _pair(high, low2), r)


func _pair(a: Vector3, b: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.append(a)
	out.append(b)
	return out


## The same swept-circle tube the legacy body builds, over an arbitrary path, into a
## SurfaceTool the caller owns — so one commit carries the cable AND its structure.
func _emit_run(st: SurfaceTool, path: PackedVector3Array, radius: float) -> void:
	var last: int = path.size() - 1
	if last < 1:
		return
	for i in range(last):
		var p1: Vector3 = path[i]
		var p2: Vector3 = path[i + 1]
		var delta: Vector3 = p2 - p1
		if delta.length_squared() < 0.0000001:
			continue
		var segment_dir: Vector3 = delta.normalized()

		var up := Vector3.UP
		if absf(segment_dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right: Vector3 = segment_dir.cross(up).normalized()
		var forward: Vector3 = right.cross(segment_dir).normalized()

		var uv_x1: float = float(i) / float(last)
		var uv_x2: float = float(i + 1) / float(last)

		for side in range(tube_sides):
			var angle1: float = (float(side) / float(tube_sides)) * TAU
			var angle2: float = (float(side + 1) / float(tube_sides)) * TAU
			var offset1: Vector3 = (right * cos(angle1) + forward * sin(angle1)) * radius
			var offset2: Vector3 = (right * cos(angle2) + forward * sin(angle2)) * radius

			st.set_uv(Vector2(uv_x1, float(side) / float(tube_sides)))
			st.add_vertex(p1 + offset1)
			st.set_uv(Vector2(uv_x2, float(side) / float(tube_sides)))
			st.add_vertex(p2 + offset1)
			st.set_uv(Vector2(uv_x2, float(side + 1) / float(tube_sides)))
			st.add_vertex(p2 + offset2)

			st.set_uv(Vector2(uv_x1, float(side) / float(tube_sides)))
			st.add_vertex(p1 + offset1)
			st.set_uv(Vector2(uv_x2, float(side + 1) / float(tube_sides)))
			st.add_vertex(p2 + offset2)
			st.set_uv(Vector2(uv_x1, float(side + 1) / float(tube_sides)))
			st.add_vertex(p1 + offset2)
