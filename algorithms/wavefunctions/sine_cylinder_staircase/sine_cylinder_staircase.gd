@tool
extends Node3D

# ----------------- Parameters -----------------
@export var STEP_COUNT: int = 80
@export var TOTAL_TURNS: float = 2.0
@export var BASE_RADIUS: float = 1.6
@export var WALKWAY_OFFSET: float = 0.9
@export var STEP_RISE: float = 0.10
@export var STEP_THICKNESS: float = 0.22
@export var STEP_WIDTH: float = 2.0
@export var MIN_STEP_DEPTH: float = 0.4
@export var WAVE_AMPLITUDE: float = 0.0   # set >0 for wavy path
@export var WAVE_FREQUENCY: float = 2.0
@export var COLLIDER_HEIGHT_OFFSET: float = 0.3 # small lift so it sits on the tread
@export var show_planes: bool = true   # visible bridge planes
@export var show_center_pole: bool = false
@export var debug: bool = false

var _mat_step: StandardMaterial3D
var _mat_plane: StandardMaterial3D

func _ready() -> void:
	_mat_step = _make_step_mat()
	_mat_plane = _make_plane_mat()
	_build()

# ----------------- Build -----------------
func _build() -> void:
	# clear
	for c in get_children():
		c.queue_free()

	var data := _compute_samples()

	# keep roots & spans so we can bridge after we know both steps
	var roots: Array[Node3D] = []
	var spans: Array[float] = []

	var steps_root := Node3D.new()
	steps_root.name = "StairSteps"
	add_child(steps_root)

	for i in range(data.size()):
		var current = data[i]
		var prev = data[max(i - 1, 0)]
		var nxt = data[min(i + 1, data.size() - 1)]

		var current_pos: Vector3 = current.position
		var prev_pos: Vector3 = prev.position
		var nxt_pos: Vector3 = nxt.position

		var root := Node3D.new()
		root.name = "Step_%03d" % i
		root.position = current_pos

		# local axes: x = radial (width), y = up, z = tangent (depth)
		var radial := Vector3(current_pos.x, 0, current_pos.z).normalized()
		var tangent := (nxt_pos - prev_pos); tangent.y = 0.0
		if tangent.length() < 0.001:
			tangent = Vector3(-radial.z, 0, radial.x)
		tangent = tangent.normalized()
		root.basis = Basis(radial, Vector3.UP, tangent).orthonormalized()
		steps_root.add_child(root)

		# span (depth) around the helix; enforce minimum
		var forward_span := (nxt_pos - current_pos); forward_span.y = 0.0
		var backward_span := (current_pos - prev_pos); backward_span.y = 0.0
		var span := 0.5 * forward_span.length() + 0.5 * backward_span.length()
		if span < MIN_STEP_DEPTH:
			span = MIN_STEP_DEPTH

		# mesh
		var m := BoxMesh.new()
		m.size = Vector3(STEP_WIDTH, STEP_THICKNESS, span * 1.35)
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.material_override = _mat_step
		root.add_child(mi)

		# collider
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new(); bs.size = m.size
		cs.shape = bs
		body.add_child(cs)
		root.add_child(body)

		roots.append(root)
		spans.append(span)

		# when we have current & previous, add the plane bridge between their facing edges
		if show_planes and i > 0:
			_add_plane_bridge(roots[i - 1], spans[i - 1], roots[i], spans[i])

	if show_center_pole:
		_add_center_pole(float(STEP_COUNT - 1) * STEP_RISE + 1.0)

# ----------------- Plane bridge (edge-to-edge) -----------------
func _add_plane_bridge(a_root: Node3D, a_span: float, b_root: Node3D, b_span: float) -> void:
	# --- compute facing edges in WORLD space (unchanged logic) ---
	var b_world := b_root.global_transform.origin
	var a_dir_local := a_root.to_local(b_world)
	var a_sign := signf(a_dir_local.z); if a_sign == 0.0: a_sign = 1.0

	var a_edge_center := a_root.to_global(Vector3(0, STEP_THICKNESS * 0.5, a_sign * (a_span * 0.5)))
	var a_left  := a_edge_center + a_root.basis.x * (-STEP_WIDTH * 0.5)
	var a_right := a_edge_center + a_root.basis.x * ( STEP_WIDTH * 0.5)

	var a_world := a_root.global_transform.origin
	var b_dir_local := b_root.to_local(a_world)
	var b_sign := signf(b_dir_local.z); if b_sign == 0.0: b_sign = -1.0

	# near edge on B (opposite sign so it's the edge facing A)
	var b_edge_center := b_root.to_global(Vector3(0, STEP_THICKNESS * 0.5, -b_sign * (b_span * 0.5)))
	var b_left  := b_edge_center + b_root.basis.x * (-STEP_WIDTH * 0.5)
	var b_right := b_edge_center + b_root.basis.x * ( STEP_WIDTH * 0.5)

	# --- build quad (two tris) in WORLD space ---
	var verts_world := PackedVector3Array([a_left, a_right, b_right,  a_left, b_right, b_left])

	# --- convert verts to STAIRCASE-LOCAL space so children align with this node ---
	var to_local: Transform3D = self.global_transform.affine_inverse()
	var verts_local := PackedVector3Array()
	verts_local.resize(verts_world.size())
	for i in range(verts_world.size()):
		verts_local[i] = to_local * verts_world[i]
		verts_local[i].y += COLLIDER_HEIGHT_OFFSET  # lift a tad so it sits on the tread

	# --- visible plane (local space) ---
	var am := ArrayMesh.new()
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts_local
	var n := (verts_local[1] - verts_local[0]).cross(verts_local[5] - verts_local[0]).normalized()
	arr[Mesh.ARRAY_NORMAL] = PackedVector3Array([n, n, n, n, n, n])
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)

	var plane := MeshInstance3D.new()
	plane.name = "BridgePlane"
	plane.mesh = am
	plane.material_override = _mat_plane
	add_child(plane)

	# --- matching collider (same local verts) ---
	var body := StaticBody3D.new()
	body.name = "BridgeCollider"
	var col := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.data = verts_local
	col.shape = shape
	body.add_child(col)
	add_child(body)

	if debug:
		print("Bridge plane added between:", a_root.name, " <-> ", b_root.name)


# ----------------- Helpers -----------------
class StepSample:
	var position: Vector3
	func _init(p: Vector3) -> void:
		position = p

func _compute_samples() -> Array:
	var out: Array = []
	var denom = max(1, STEP_COUNT - 1)
	for i in range(STEP_COUNT):
		var t := float(i) / float(denom)
		var ang := t * TOTAL_TURNS * TAU
		var wave := sin(ang * WAVE_FREQUENCY) * WAVE_AMPLITUDE
		var r := BASE_RADIUS + WALKWAY_OFFSET + wave
		var top := float(i) * STEP_RISE
		var center_y := top - STEP_THICKNESS * 0.5
		out.append(StepSample.new(Vector3(cos(ang) * r, center_y, sin(ang) * r)))
	return out

func _add_center_pole(h: float) -> void:
	var m := CylinderMesh.new()
	m.top_radius = BASE_RADIUS
	m.bottom_radius = BASE_RADIUS
	m.height = h
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position.y = h * 0.5
	add_child(mi)

	# collider
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = BASE_RADIUS
	shape.height = h
	cs.shape = shape
	body.add_child(cs)
	body.position = mi.position
	add_child(body)

func _make_step_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.85, 0.85)
	m.roughness = 0.6
	return m

func _make_plane_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.2, 1.0, 0.25)  # pink, semi-transparent
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	m.render_priority = 1
	return m

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

