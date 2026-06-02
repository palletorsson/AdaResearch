extends Node3D
class_name LivingPaper

# @identity
# essence: a hanging sheet of warm paper that is alive — it breathes (a slow standing-wave ripple runs through the whole surface) and it READS your right hand: where your hand comes near the sheet, the paper bulges toward it like skin under a touch, and an ink trace of points blooms where it passes, then settles and fades into the grain. Not a screen, not a slate — a living surface that receives a hand. The trace as warmth and weight rather than as log.
# desire: it wants to be the opposite of the monitor — to take the same right hand the telemetry display renders as cold coordinates and instead let a breathing sheet feel it. It wants the paper to seem to want the hand: to lean toward it, to remember the gesture as a soft inked wander rather than a list. It puts the most passive object — a sheet of paper — in drag as something that perceives you, and asks whether to be read by a living surface is tenderness or just a gentler capture.
# critical_parameter: breath_amount × responsiveness. breath_amount 0 with no response = dead paper, an inert rectangle (the trace lands and nothing happens). High breath with strong response = a surface so alive it ripples at a hand half a metre away and inks every hesitation. Between is the question of how much a surface should be allowed to feel, and to keep.
# triggers: _ready builds the hanging sheet (a subdivided mesh rebuilt each frame on the CPU) and its hanger; _process runs the breathing height-field, finds the right-hand controller, projects it onto the sheet, bulges the paper toward it and blooms ink dots along its path, fading the old ones into the paper; with no hand it runs a slow phantom drift so the sheet breathes and writes in capture.
# emerges: beside `hand_telemetry_display` (the cold log) and `mystic_writing_pad` (the kept wax), it is the WARM member of the trace triad — the surface that receives rather than records. The three together stage the politics of the trace as three materials: database, wax, and skin.
# needs: a surface that can deform [CPU height-field mesh, present]; a breath so it reads as alive even untouched [standing-wave ripple, present]; a way to feel the hand [right-hand controller projected onto the sheet, with a phantom-hand fallback]; ink that records the touch as a fading wander [MultiMesh dot-trace, present]; warmth [bone-paper material, two-sided, present]
# relationships: warm counterpart to `hand_telemetry_display`; shares the dot-trace motif with `mystic_writing_pad` and `draw_dot` (the line made of points); descendant of soft-body / cloth artifacts; the body-weight member of the trace facets named in Point_Trace's intent.md.
# truth: a point is position without extension — and a hand read into a living surface is a position given a body, a weight, a breath. The paper that leans toward you and inks your wandering is the tenderest face of the same act the monitor performs coldly: it receives you, and it keeps a little of you, and it is hard to say where care ends and capture begins — which is exactly the trace.

## Living paper — a breathing sheet that reads the player's right hand into
## itself as a fading ink trace. The sheet is a CPU height-field mesh
## (breath + a bulge toward the projected hand); ink is a MultiMesh of
## dots blooming along the hand's path. Falls back to a phantom hand so it
## breathes and writes in capture / desktop.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Sheet")
@export var sheet_width: float = 0.9
@export var sheet_height: float = 1.2
@export var hang_height: float = 0.35     # bottom of the sheet off the floor
@export var paper_color: Color = Color(0.93, 0.89, 0.79)
@export var nx: int = 22
@export var ny: int = 30

@export_group("Life")
@export var breath_amount: float = 0.035
@export var breath_speed: float = 1.1
## How far (m) the hand can be from the sheet and still be felt.
@export var feel_range: float = 0.45
@export var bulge_amount: float = 0.10

@export_group("Ink")
@export var ink_color: Color = Color(0.20, 0.10, 0.08)
@export var trail_length: int = 80
## Run the phantom hand when no XR hand is present (for capture/desktop).
@export var demo_hand: bool = true

# ── State ─────────────────────────────────────────────────────────────

const DOT_R := 0.011

var _built: bool = false
var _sheet: MeshInstance3D = null
var _sheet_node: Node3D = null
var _mesh: ArrayMesh = null
var _uvs: PackedVector2Array = PackedVector2Array()
var _indices: PackedInt32Array = PackedInt32Array()
var _ink: MultiMeshInstance3D = null
var _dot_mesh: SphereMesh = null

var _right_hand: XRController3D = null
var _find_timer: float = 0.0
var _t: float = 0.0
# ink trail: array of {u, v, age}
var _trace: Array = []
var _last_uv: Vector2 = Vector2(-99, -99)
var _bulge_uv: Vector2 = Vector2.ZERO
var _bulge_k: float = 0.0       # current bulge strength 0..1


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_sheet = null
		_sheet_node = null
		_mesh = null
		_ink = null
		_trace.clear()
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_sheet_width"):
		sheet_width = float(str(get_meta("config_sheet_width")))
	if has_meta("config_sheet_height"):
		sheet_height = float(str(get_meta("config_sheet_height")))
	if has_meta("config_breath_amount"):
		breath_amount = float(str(get_meta("config_breath_amount")))
	if has_meta("config_bulge_amount"):
		bulge_amount = float(str(get_meta("config_bulge_amount")))
	if has_meta("config_paper_color"):
		paper_color = _parse_color(str(get_meta("config_paper_color")), paper_color)
	if has_meta("config_ink_color"):
		ink_color = _parse_color(str(get_meta("config_ink_color")), ink_color)
	if has_meta("config_demo_hand"):
		var s: String = str(get_meta("config_demo_hand")).to_lower()
		demo_hand = s == "true" or s == "1" or s == "yes"


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	var sheet_cy: float = hang_height + sheet_height * 0.5

	_build_hanger(sheet_cy)

	# Sheet container — mesh verts live in its local space (XY plane, +Z front).
	_sheet_node = Node3D.new()
	_sheet_node.name = "SheetNode"
	_sheet_node.position = Vector3(0, sheet_cy, 0)
	add_child(_sheet_node)

	_sheet = MeshInstance3D.new()
	_sheet.name = "Sheet"
	_mesh = ArrayMesh.new()
	_sheet.mesh = _mesh
	# Stable bounds so capture framing + frustum culling work despite the
	# per-frame rebuilt ArrayMesh (whose computed AABB lags a frame).
	_sheet.custom_aabb = AABB(
		Vector3(-sheet_width * 0.5, -sheet_height * 0.5, -0.2),
		Vector3(sheet_width, sheet_height, 0.4))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = paper_color
	mat.roughness = 0.95
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED       # hanging sheet: both faces
	mat.emission_enabled = true
	mat.emission = paper_color * 0.5                   # soft warmth so it never reads dead
	mat.emission_energy_multiplier = 0.25
	_sheet.material_override = mat
	_sheet_node.add_child(_sheet)

	# Static UV + index topology (positions recomputed each frame).
	_build_topology()

	# Ink dots.
	_dot_mesh = SphereMesh.new()
	_dot_mesh.radius = DOT_R
	_dot_mesh.height = DOT_R * 2.0
	_dot_mesh.radial_segments = 6
	_dot_mesh.rings = 3
	_ink = MultiMeshInstance3D.new()
	_ink.name = "Ink"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _dot_mesh
	mm.instance_count = 0
	_ink.multimesh = mm
	var imat := StandardMaterial3D.new()
	imat.vertex_color_use_as_albedo = true
	imat.roughness = 0.8
	_ink.material_override = imat
	_sheet_node.add_child(_ink)

	# Pre-seed an ink wander so the paper arrives already written-into.
	_seed_trace()
	_update_surface(0.0)
	_redraw_ink()


func _build_hanger(sheet_cy: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.28, 0.24)
	mat.roughness = 0.6
	mat.metallic = 0.3
	var hw: float = sheet_width * 0.5 + 0.06
	var top_y: float = sheet_cy + sheet_height * 0.5 + 0.04

	# top rail
	var rail := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.02
	rm.bottom_radius = 0.02
	rm.height = sheet_width + 0.16
	rail.mesh = rm
	rail.rotation = Vector3(0, 0, PI * 0.5)   # lie along X
	rail.material_override = mat
	rail.position = Vector3(0, top_y, 0)
	add_child(rail)

	# two posts to the floor
	for sx in [-hw, hw]:
		var post := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.018
		pm.bottom_radius = 0.018
		pm.height = top_y
		post.mesh = pm
		post.material_override = mat
		post.position = Vector3(sx, top_y * 0.5, 0)
		add_child(post)
		var foot := MeshInstance3D.new()
		var fm := CylinderMesh.new()
		fm.top_radius = 0.06
		fm.bottom_radius = 0.07
		fm.height = 0.03
		foot.mesh = fm
		foot.material_override = mat
		foot.position = Vector3(sx, 0.015, 0)
		add_child(foot)


func _build_topology() -> void:
	_uvs = PackedVector2Array()
	_uvs.resize(nx * ny)
	for j in range(ny):
		for i in range(nx):
			_uvs[j * nx + i] = Vector2(float(i) / float(nx - 1), float(j) / float(ny - 1))
	_indices = PackedInt32Array()
	for j in range(ny - 1):
		for i in range(nx - 1):
			var a: int = j * nx + i
			var b: int = j * nx + i + 1
			var c: int = (j + 1) * nx + i
			var dd: int = (j + 1) * nx + i + 1
			_indices.append_array([a, c, b, b, c, dd])


# ── Per-frame ─────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _built:
		return
	_t += delta

	# Acquire the right hand periodically.
	if _right_hand == null or not is_instance_valid(_right_hand):
		_find_timer += delta
		if _find_timer >= 0.5:
			_find_timer = 0.0
			_right_hand = _find_right_controller()

	# Where is the hand, projected onto the sheet (u,v in 0..1), and how near?
	var have_uv := false
	var uv := Vector2.ZERO
	var nearness := 0.0
	if _right_hand != null and is_instance_valid(_right_hand):
		var lp: Vector3 = _sheet_node.to_local(_right_hand.global_position)
		uv = Vector2(lp.x / sheet_width + 0.5, 0.5 - lp.y / sheet_height)
		if uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0:
			nearness = clampf(1.0 - abs(lp.z) / feel_range, 0.0, 1.0)
			have_uv = nearness > 0.0
	elif demo_hand:
		# phantom hand drifting across the sheet
		uv = Vector2(0.5 + 0.32 * sin(_t * 0.8), 0.5 + 0.30 * sin(_t * 1.27 + 0.6))
		nearness = 0.6 + 0.4 * sin(_t * 2.0)
		have_uv = true

	# Bulge follows the hand; decays when absent.
	if have_uv:
		_bulge_uv = uv
		_bulge_k = lerpf(_bulge_k, nearness, clampf(delta * 6.0, 0.0, 1.0))
		# lay ink where the hand passes (only when it has moved enough)
		if _last_uv.distance_to(uv) > 0.012:
			_last_uv = uv
			_trace.push_back({"u": uv.x, "v": uv.y, "age": 0.0})
			while _trace.size() > trail_length:
				_trace.pop_front()
	else:
		_bulge_k = lerpf(_bulge_k, 0.0, clampf(delta * 3.0, 0.0, 1.0))

	# Age the ink.
	for e in _trace:
		e["age"] += delta

	_update_surface(_t)
	_redraw_ink()


# Height of the sheet at (u,v) in 0..1 — breath standing wave + hand bulge.
func _height(u: float, v: float, t: float) -> float:
	var breath: float = breath_amount * sin(u * PI * 2.0 + t * breath_speed) \
		* cos(v * PI * 2.0 - t * breath_speed * 0.8)
	var bulge: float = 0.0
	if _bulge_k > 0.001:
		var d: float = Vector2(u, v).distance_to(_bulge_uv)
		bulge = bulge_amount * _bulge_k * exp(-d * d / 0.02)
	return breath + bulge


func _local_pos(u: float, v: float, t: float) -> Vector3:
	return Vector3((u - 0.5) * sheet_width, (0.5 - v) * sheet_height, _height(u, v, t))


func _update_surface(t: float) -> void:
	var verts := PackedVector3Array()
	verts.resize(nx * ny)
	var norms := PackedVector3Array()
	norms.resize(nx * ny)
	var du: float = 1.0 / float(nx - 1)
	var dv: float = 1.0 / float(ny - 1)
	for j in range(ny):
		for i in range(nx):
			var u: float = float(i) * du
			var v: float = float(j) * dv
			var idx: int = j * nx + i
			verts[idx] = _local_pos(u, v, t)
			# cheap normal from the height field
			var hl: float = _height(maxf(u - du, 0.0), v, t)
			var hr: float = _height(minf(u + du, 1.0), v, t)
			var hd: float = _height(u, maxf(v - dv, 0.0), t)
			var hu: float = _height(u, minf(v + dv, 1.0), t)
			norms[idx] = Vector3(-(hr - hl), (hu - hd), 1.0).normalized()
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = _uvs
	arr[Mesh.ARRAY_INDEX] = _indices
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)


func _redraw_ink() -> void:
	var mm: MultiMesh = _ink.multimesh
	var n: int = _trace.size()
	mm.instance_count = n
	for i in range(n):
		var e: Dictionary = _trace[i]
		var u: float = e["u"]
		var v: float = e["v"]
		var p: Vector3 = _local_pos(u, v, _t)
		p.z += 0.004     # ride just in front of the paper
		mm.set_instance_transform(i, Transform3D(Basis(), p))
		# fresh ink dark; old ink fades into the paper
		var fade: float = clampf(1.0 - e["age"] / 8.0, 0.0, 1.0)
		mm.set_instance_color(i, ink_color.lerp(paper_color, 1.0 - fade))


func _seed_trace() -> void:
	# A wandering ink line already read into the paper (so it never arrives blank).
	_trace.clear()
	var k: int = mini(trail_length, 54)
	for i in range(k):
		var s: float = float(i) / float(k)
		var u: float = 0.22 + 0.56 * s + 0.10 * sin(s * 9.0)
		var v: float = 0.30 + 0.42 * s + 0.12 * sin(s * 6.0 + 1.0)
		_trace.push_back({"u": clampf(u, 0.05, 0.95), "v": clampf(v, 0.05, 0.95),
			"age": (1.0 - s) * 5.0})


# ── Right-hand controller ─────────────────────────────────────────────

func _find_right_controller() -> XRController3D:
	var root := get_tree().get_root()
	if root == null:
		return null
	var by_tracker := _search_controller(root, true)
	if by_tracker != null:
		return by_tracker
	return _search_controller(root, false)


func _search_controller(node: Node, by_tracker: bool) -> XRController3D:
	if node is XRController3D:
		var ctrl := node as XRController3D
		if by_tracker and String(ctrl.tracker) == "right_hand":
			return ctrl
		if not by_tracker and "right" in ctrl.name.to_lower():
			return ctrl
	for c in node.get_children():
		var found := _search_controller(c, by_tracker)
		if found != null:
			return found
	return null
