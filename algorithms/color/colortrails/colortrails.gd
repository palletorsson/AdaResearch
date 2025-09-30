extends Node3D
## VR Hand Color Trails (Godot 4)
## Spline-smoothed ribbons, per-hand gradients, width/alpha curves, additive-ish glow.

# ----------------- Trail config -----------------
@export_range(8, 2048, 1) var trail_max_points: int = 256
@export var trail_lifetime: float = 1.75
@export_range(0.001, 0.2, 0.001) var min_sample_distance: float = 0.01
@export_range(0.002, 1.0, 0.001) var base_width: float = 0.08
@export var only_when_trigger_pressed := true
@export var smooth_spline := true
@export_range(2, 64, 1) var smooth_samples_per_segment: int = 6 # more = smoother

@export_range(0.0, 0.02, 0.0005) var ribbon_jitter: float = 0.002

@export var additive_glow := true
@export var disable_depth_test := true

@export var left_gradient: Gradient
@export var right_gradient: Gradient
@export var width_curve: Curve
@export var alpha_curve: Curve

@export var left_hand_path: NodePath
@export var right_hand_path: NodePath

# --------------- Internals ----------------------
const K_POS := "pos"
const K_AGE := "age"
const K_VEL := "vel"

var _left_points: Array[Dictionary] = []
var _right_points: Array[Dictionary] = []

var _left_mesh_inst: MeshInstance3D
var _right_mesh_inst: MeshInstance3D
var _left_mesh := ArrayMesh.new()
var _right_mesh := ArrayMesh.new()

var _left_mat: ShaderMaterial
var _right_mat: ShaderMaterial

var _left_hand: Node3D
var _right_hand: Node3D

var _time := 0.0
var _was_left_drawing := false
var _was_right_drawing := false

# ----------------- Lifecycle --------------------
func _ready() -> void:
	_init_defaults()
	_autodetect_hands()
	_setup_meshes_and_materials()

func _process(delta: float) -> void:
	_time += delta

	_update_trail_for_hand(_left_hand, _left_points, delta, true)
	_update_trail_for_hand(_right_hand, _right_points, delta, false)

	_decay_points(_left_points, delta)
	_decay_points(_right_points, delta)

	_build_ribbon(_left_mesh, _left_points, _left_mesh_inst, left_gradient)
	_build_ribbon(_right_mesh, _right_points, _right_mesh_inst, right_gradient)

# ----------------- Setup ------------------------
func _init_defaults() -> void:
	if width_curve == null:
		width_curve = Curve.new()
		width_curve.add_point(Vector2(0.0, 1.0))
		width_curve.add_point(Vector2(1.0, 0.0))
	if alpha_curve == null:
		alpha_curve = Curve.new()
		alpha_curve.add_point(Vector2(0.0, 1.0))
		alpha_curve.add_point(Vector2(1.0, 0.0))
	if left_gradient == null:
		left_gradient = Gradient.new()
		left_gradient.add_point(0.0, Color(0.2, 0.8, 1.0, 1.0)) # head
		left_gradient.add_point(1.0, Color(0.2, 0.8, 1.0, 0.0)) # tail
	if right_gradient == null:
		right_gradient = Gradient.new()
		right_gradient.add_point(0.0, Color(1.0, 0.2, 0.8, 1.0))
		right_gradient.add_point(1.0, Color(1.0, 0.2, 0.8, 0.0))

func _autodetect_hands() -> void:
	if left_hand_path != NodePath() and has_node(left_hand_path):
		_left_hand = get_node(left_hand_path)
	if right_hand_path != NodePath() and has_node(right_hand_path):
		_right_hand = get_node(right_hand_path)

	if _left_hand == null:
		_left_hand = _find_node_recursive(get_tree().root, "LeftHand") as Node3D
	if _right_hand == null:
		_right_hand = _find_node_recursive(get_tree().root, "RightHand") as Node3D

func _setup_meshes_and_materials() -> void:
	_left_mesh_inst = MeshInstance3D.new()
	_left_mesh_inst.name = "LeftTrailMesh"
	_left_mesh_inst.mesh = _left_mesh
	add_child(_left_mesh_inst)

	_left_mat = _make_trail_material()
	_left_mesh_inst.material_override = _left_mat

	_right_mesh_inst = MeshInstance3D.new()
	_right_mesh_inst.name = "RightTrailMesh"
	_right_mesh_inst.mesh = _right_mesh
	add_child(_right_mesh_inst)

	_right_mat = _make_trail_material()
	_right_mesh_inst.material_override = _right_mat

func _make_trail_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = _trail_shader_code()
	mat.shader = shader
	mat.set_shader_parameter("u_time", 0.0)
	mat.set_shader_parameter("u_additive", 1.0 if additive_glow else 0.0)
	mat.set_shader_parameter("u_disable_depth", 1.0 if disable_depth_test else 0.0)
	return mat

# ----------------- Input helpers ----------------
func _is_trigger_pressed(hand: Node3D) -> bool:
	if hand == null:
		return false
	if hand is XRController3D:
		return (hand as XRController3D).is_button_pressed("trigger_click")
	for c in hand.get_children():
		if c is XRController3D and (c as XRController3D).is_button_pressed("trigger_click"):
			return true
	return Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func _hand_velocity(hand: Node3D) -> Vector3:
	if hand and hand.has_method("get_velocity"):
		return hand.get_velocity()
	return Vector3.ZERO

func _haptic(hand: Node3D, on_strength := 0.25) -> void:
	if hand and hand.has_method("trigger_haptic_pulse"):
		hand.trigger_haptic_pulse("haptic", 0.0, on_strength, 0.08, 0.0)

# ----------------- Update / record ---------------
func _update_trail_for_hand(hand: Node3D, buf: Array, delta: float, is_left: bool) -> void:
	var drawing_now := true
	if only_when_trigger_pressed:
		drawing_now = _is_trigger_pressed(hand)

	if hand != null:
		if is_left and drawing_now and !_was_left_drawing: _haptic(hand)
		if (not is_left) and drawing_now and !_was_right_drawing: _haptic(hand)

	if hand == null:
		_set_was_drawing(is_left, false)
		return

	var p := hand.global_transform.origin
	var should_add := buf.is_empty()
	if not should_add and drawing_now:
		var last_p: Vector3 = buf[-1][K_POS]
		should_add = last_p.distance_to(p) >= min_sample_distance

	if drawing_now and should_add:
		var vel := Vector3.ZERO
		if not buf.is_empty():
			vel = (p - buf[-1][K_POS]) / max(delta, 1e-5)
		buf.append({K_POS: p, K_AGE: 0.0, K_VEL: vel})
		if buf.size() > trail_max_points:
			buf.pop_front()

	_set_was_drawing(is_left, drawing_now)

func _set_was_drawing(is_left: bool, val: bool) -> void:
	if is_left: _was_left_drawing = val
	else: _was_right_drawing = val

func _decay_points(buf: Array, delta: float) -> void:
	for i in range(buf.size() - 1, -1, -1):
		buf[i][K_AGE] = float(buf[i][K_AGE]) + delta
		if float(buf[i][K_AGE]) > trail_lifetime:
			buf.remove_at(i)

# ----------------- Geometry build ----------------
func _build_ribbon(mesh: ArrayMesh, points: Array, mi: MeshInstance3D, grad: Gradient) -> void:
	if points.size() < 2:
		mesh.clear_surfaces()
		return

	var cam := get_viewport().get_camera_3d()
	if cam == null:
		mesh.clear_surfaces()
		return

	var line: Array[Vector3] = []
	line.resize(points.size())
	for i in range(line.size()):
		line[i] = points[i][K_POS]

	var smoothed: Array[Vector3]
	if smooth_spline and line.size() >= 4:
		smoothed = _catmull_rom_resample(line, smooth_samples_per_segment)
	else:
		smoothed = line

	var vtx := PackedVector3Array()
	var nrm := PackedVector3Array()
	var uvs := PackedVector2Array()
	var col := PackedColorArray()
	var idx := PackedInt32Array()

	var total_len = max(1, smoothed.size() - 1)
	for i in range(smoothed.size()):
		var pos := smoothed[i]
		var raw_idx = clamp(int(round(float(i) / float(total_len) * (points.size() - 1))), 0, points.size() - 1)
		var age := float(points[raw_idx][K_AGE])
		var t = clamp(age / max(trail_lifetime, 1e-5), 0.0, 1.0)

		var w_scale := width_curve.sample(t)
		var alpha_scale := alpha_curve.sample(t)
		var width := base_width * w_scale

		var fwd: Vector3
		if i < smoothed.size() - 1:
			fwd = (smoothed[i + 1] - pos).normalized()
		else:
			fwd = (pos - smoothed[i - 1]).normalized()

		var to_cam := (cam.global_transform.origin - pos).normalized()
		var right := fwd.cross(to_cam).normalized()
		if right.length_squared() < 1e-6:
			right = Vector3.RIGHT

		if ribbon_jitter > 0.0:
			var j := _hash_vec3(pos + Vector3(_time, float(i), 0.0)) * 2.0 - 1.0
			right += (Vector3(j, -j, j) * ribbon_jitter)
			right = right.normalized()

		var lft := pos - right * (width * 0.5)
		var rgt := pos + right * (width * 0.5)

		var gcol := grad.sample(1.0 - t)
		gcol.a *= alpha_scale

		vtx.append(lft); vtx.append(rgt)
		nrm.append(to_cam); nrm.append(to_cam)
		var u := float(i) / float(max(1, smoothed.size() - 1))
		uvs.append(Vector2(u, 0.0)); uvs.append(Vector2(u, 1.0))
		col.append(gcol); col.append(gcol)

		if i < smoothed.size() - 1:
			var b := i * 2
			idx.append_array([b, b + 1, b + 2, b + 1, b + 3, b + 2])

	mesh.clear_surfaces()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vtx
	arrays[Mesh.ARRAY_NORMAL] = nrm
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = col
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat := mi.material_override as ShaderMaterial
	if mat:
		mat.set_shader_parameter("u_time", _time)

# ----------------- Spline helpers ----------------
func _catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)

func _catmull_rom_resample(line: Array[Vector3], samples_per_seg: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if line.size() < 4:
		return line.duplicate()

	for i in range(0, line.size() - 3):
		var p0 := line[i]
		var p1 := line[i + 1]
		var p2 := line[i + 2]
		var p3 := line[i + 3]
		for s in range(samples_per_seg):
			var t := float(s) / float(samples_per_seg)
			out.append(_catmull_rom(p0, p1, p2, p3, t))
	out.append(line[line.size() - 2])
	out.append(line[line.size() - 1])
	return out

# ----------------- Utility ----------------------
func _find_node_recursive(n: Node, needle: String) -> Node:
	if n.name == needle:
		return n
	for c in n.get_children():
		var r := _find_node_recursive(c, needle)
		if r:
			return r
	return null

func _hash_vec3(v: Vector3) -> float:
	var s := sin(v.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453
	return s - floor(s) # 0..1

# ----------------- Controls ---------------------
func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed:
		match e.keycode:
			KEY_C:
				_left_points.clear(); _right_points.clear()
				_left_mesh.clear_surfaces(); _right_mesh.clear_surfaces()
			KEY_PLUS, KEY_EQUAL:
				base_width = clamp(base_width * 1.15, 0.005, 0.5)
			KEY_MINUS:
				base_width = clamp(base_width * 0.85, 0.005, 0.5)
			KEY_G:
				additive_glow = !additive_glow
				if _left_mat: _left_mat.set_shader_parameter("u_additive", 1.0 if additive_glow else 0.0)
				if _right_mat: _right_mat.set_shader_parameter("u_additive", 1.0 if additive_glow else 0.0)
			KEY_D:
				disable_depth_test = !disable_depth_test
				if _left_mat: _left_mat.set_shader_parameter("u_disable_depth", 1.0 if disable_depth_test else 0.0)
				if _right_mat: _right_mat.set_shader_parameter("u_disable_depth", 1.0 if disable_depth_test else 0.0)

# ----------------- Shader -----------------------
func _trail_shader_code() -> String:
	return """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform float u_time = 0.0;
uniform float u_additive = 1.0;       // emulate additive highlights
uniform float u_disable_depth = 1.0;  // (hint flag only)

void vertex() {
}

void fragment() {
	vec4 c = COLOR;

	float v = UV.y;
	float edge = smoothstep(0.0, 0.15, v) * smoothstep(0.0, 0.15, 1.0 - v);
	c.rgb *= mix(1.2, 0.9, edge);

	float fr = pow(1.0 - clamp(dot(NORMAL, -VIEW), 0.0, 1.0), 3.0);
	c.rgb += fr * 0.15;

	if (u_additive > 0.5) {
		c.rgb = c.rgb * 0.6 + c.rgb * c.rgb * 0.6;
	}

	ALBEDO = c.rgb;
	ALPHA = c.a;
}
"""
