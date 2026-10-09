extends Node3D
class_name GoedelAtrium

# @identity
# essence: a formal atrium that contains, on a plinth at its exact centre,
#   a perfect 1:10 scale model of itself — and inside that model, visible
#   through its tiny doorway, a 1:100 model on a tiny plinth. One function
#   builds every level. One crack runs through every floor. On the wall
#   opposite the door the room states, in cold emissive lettering:
#   THIS ROOM CANNOT PROVE THIS ROOM — and it is true. The statement
#   persists at every scale, even where it is too small to read.
# desire: to give incompleteness a body the player can stand inside.
#   Nobody reads about self-reference here; they occupy it. The room is
#   the sentence. The model is the sentence naming itself. The player is
#   the variable the room cannot bind.
# critical_parameter: recursion_depth (default 2). Depth 0 is the room
#   you walk; each further level is the room speaking about itself at
#   1:10. One more level changes nothing, and everything.
# triggers: _ready() builds all levels via _build_room(parent, s, depth) —
#   the same parameterized function, called recursively, with a hard stop.
#   The recursion is exact. That is the point.
# emerges: standing at the doorway, the player sees their own doorway in
#   miniature, and inside it another. The architecture believes itself
#   complete — pilasters, coffered beams, a perimeter of pale light — yet
#   a warm fissure runs from the base of the statement wall, under the
#   model, at every scale. The flaw is the only warm light in the room.
#   The flaw is load-bearing.
# needs: nothing. The room is self-contained, which is precisely its
#   problem.
# relationships: sibling to foundations_crisis_apparatus — this is the
#   Gödel station grown to full architectural size. Kin to the fractal
#   artifacts, but where they play self-similarity straight, this room
#   plays it as paradox: the copy is not ornament, it is a statement the
#   original cannot absorb. The crack is the QFEP dark spot given a floor
#   to run through.
# truth: every system rich enough to describe itself contains a room it
#   cannot close. The honest ones light the crack.

## Walk-in architecture, ~8 x 8 m footprint, ~4.6 m tall, origin at the
## floor. One open doorway (1.8 x 2.4 m) on the +Z wall; the statement
## wall faces it on -Z. The plinth and the recursive model sit at centre.

const MAX_DEPTH: int = 4          # absolute hard stop for the recursion
const CRACK_SEGMENTS: int = 9     # fissure polyline segments per level

const WALL_HEIGHT: float = 4.5    # metres at depth 0, scaled by s below
const WALL_THICK: float = 0.25
const FLOOR_TOP: float = 0.03     # raised floor top (avoids z-fighting)
const DOOR_WIDTH: float = 1.8     # >= 1.4 required
const DOOR_HEIGHT: float = 2.4    # >= 2.4 required
const TRIM_HEIGHT: float = 2.46   # just above the door head, unbroken
const PLINTH_HEIGHT: float = 0.8
const PLINTH_REVEAL: float = 0.015  # shadow gap — the crack passes under

const STATEMENT_MAIN: String = "THIS ROOM CANNOT PROVE THIS ROOM."
const STATEMENT_SUB: String = "— and it is true"
const STATEMENT_COLOR: Color = Color(0.93, 0.96, 1.0)

@export var room_size: float = 8.0
@export var recursion_depth: int = 2
@export var accent_color: Color = Color(1.0, 0.56, 0.24)
@export var rng_seed: int = 17

# Shared materials — one set across all recursion levels, so the breathing
# trim and the travelling crack pulse stay synchronised at every scale.
var _wall_mat: StandardMaterial3D
var _pilaster_mat: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _ceiling_mat: StandardMaterial3D
var _beam_mat: StandardMaterial3D
var _plinth_mat: StandardMaterial3D
var _trim_mat: StandardMaterial3D
var _statement_bar_mat: StandardMaterial3D
var _crack_seg_mats: Array[StandardMaterial3D] = []

var _statement_labels: Array[Label3D] = []
var _root: Node3D = null
var _built: bool = false
var _time: float = 0.0
var _next_flicker: float = 9.0
var _flicker_left: float = 0.0


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("room_size"):
		room_size = clampf(float(config_data["room_size"]), 4.0, 16.0)
	if config_data.has("recursion_depth"):
		recursion_depth = clampi(int(config_data["recursion_depth"]), 0, MAX_DEPTH - 1)
	if config_data.has("accent_color"):
		accent_color = Color.from_string(str(config_data["accent_color"]), accent_color)
	elif config_data.has("color"):
		accent_color = Color.from_string(str(config_data["color"]), accent_color)
	if config_data.has("seed"):
		rng_seed = int(config_data["seed"])
	elif config_data.has("rng_seed"):
		rng_seed = int(config_data["rng_seed"])
	if config_data.has("scale"):
		var scale_v: float = clampf(float(config_data["scale"]), 0.2, 4.0)
		scale = Vector3(scale_v, scale_v, scale_v)
	_rebuild()


# ═══════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════

func _build() -> void:
	if _built:
		return
	_statement_labels.clear()
	_make_materials()

	_root = Node3D.new()
	_root.name = "Architecture"
	add_child(_root)

	# Depth 0 = the real room. The model chain hangs off its plinth.
	_build_room(_root, 1.0, 0)

	_build_collision(_root)
	_build_lights(_root)
	_build_capture_camera()
	_built = true


func _rebuild() -> void:
	if _root != null and is_instance_valid(_root):
		_root.name = "_dying_architecture"
		_root.queue_free()
	_root = null
	var old_cam: Node = get_node_or_null("CaptureCamera")
	if old_cam != null:
		old_cam.name = "_dying_camera"
		old_cam.queue_free()
	_statement_labels.clear()
	_built = false
	_build()


## The whole atrium at one scale. Called recursively — same function,
## same proportions, every level. `parent`'s local origin is the floor
## centre of this level; `s` is the scale factor (1.0, 0.1, 0.01...).
func _build_room(parent: Node3D, s: float, depth: int) -> void:
	if depth > recursion_depth or depth > MAX_DEPTH:
		return

	var rs: float = room_size * s
	var half: float = rs * 0.5
	var wt: float = WALL_THICK * s
	var wh: float = WALL_HEIGHT * s
	var f_top: float = FLOOR_TOP * s
	var dw: float = DOOR_WIDTH * s
	var dh: float = DOOR_HEIGHT * s
	var wall_mid_y: float = f_top + wh * 0.5
	var z_face_n: float = -(half - wt)   # statement wall interior face
	var z_face_s: float = half - wt      # door wall interior face

	# ── Floor ──
	_add_box(parent, Vector3(rs, 0.1 * s, rs), Vector3(0.0, f_top - 0.05 * s, 0.0), _floor_mat)

	# ── Walls: statement wall (-Z), east, west, door wall (+Z, split) ──
	_add_box(parent, Vector3(rs, wh, wt),
		Vector3(0.0, wall_mid_y, -(half - wt * 0.5)), _wall_mat)
	_add_box(parent, Vector3(wt, wh, rs - 2.0 * wt),
		Vector3(half - wt * 0.5, wall_mid_y, 0.0), _wall_mat)
	_add_box(parent, Vector3(wt, wh, rs - 2.0 * wt),
		Vector3(-(half - wt * 0.5), wall_mid_y, 0.0), _wall_mat)
	var seg_w: float = (rs - dw) * 0.5
	var seg_x: float = dw * 0.5 + seg_w * 0.5
	_add_box(parent, Vector3(seg_w, wh, wt),
		Vector3(-seg_x, wall_mid_y, half - wt * 0.5), _wall_mat)
	_add_box(parent, Vector3(seg_w, wh, wt),
		Vector3(seg_x, wall_mid_y, half - wt * 0.5), _wall_mat)
	var lintel_h: float = wh - dh
	_add_box(parent, Vector3(dw, lintel_h, wt),
		Vector3(0.0, f_top + dh + lintel_h * 0.5, half - wt * 0.5), _wall_mat)

	# ── Pilaster strips, proud of the interior faces ──
	var po: float = 0.27 * rs
	var p_w: float = 0.2 * s  # strip width — fixed, formal rhythm
	var p_d: float = 0.07 * s
	for off in [-po, 0.0, po]:
		var oz: float = float(off)
		_add_box(parent, Vector3(p_d, wh, p_w),
			Vector3(half - wt - p_d * 0.5, wall_mid_y, oz), _pilaster_mat)
		_add_box(parent, Vector3(p_d, wh, p_w),
			Vector3(-(half - wt) + p_d * 0.5, wall_mid_y, oz), _pilaster_mat)
	for off in [-po, po]:
		var ox: float = float(off)
		_add_box(parent, Vector3(p_w, wh, p_d),
			Vector3(ox, wall_mid_y, z_face_s - p_d * 0.5), _pilaster_mat)
	for off in [-0.38 * rs, 0.38 * rs]:
		var ox2: float = float(off)
		_add_box(parent, Vector3(p_w, wh, p_d),
			Vector3(ox2, wall_mid_y, z_face_n + p_d * 0.5), _pilaster_mat)

	# ── Trim line at 2.4 m: thin emissive band, whole perimeter,
	#    floated proud of the pilasters so it reads unbroken ──
	var trim_y: float = f_top + TRIM_HEIGHT * s
	var trim_len: float = rs - 2.0 * wt
	var trim_inset: float = 0.085 * s
	_add_box(parent, Vector3(trim_len, 0.05 * s, 0.03 * s),
		Vector3(0.0, trim_y, z_face_n + trim_inset), _trim_mat)
	_add_box(parent, Vector3(trim_len, 0.05 * s, 0.03 * s),
		Vector3(0.0, trim_y, z_face_s - trim_inset), _trim_mat)
	_add_box(parent, Vector3(0.03 * s, 0.05 * s, trim_len),
		Vector3(half - wt - trim_inset, trim_y, 0.0), _trim_mat)
	_add_box(parent, Vector3(0.03 * s, 0.05 * s, trim_len),
		Vector3(-(half - wt) + trim_inset, trim_y, 0.0), _trim_mat)

	# ── Coffered ceiling hint: slab + beam grid ──
	_add_box(parent, Vector3(rs, 0.12 * s, rs),
		Vector3(0.0, f_top + wh + 0.06 * s, 0.0), _ceiling_mat)
	var beam_y: float = f_top + wh - 0.11 * s
	for off in [-0.25 * rs, 0.0, 0.25 * rs]:
		var bo: float = float(off)
		_add_box(parent, Vector3(rs - 2.0 * wt, 0.22 * s, 0.16 * s),
			Vector3(0.0, beam_y, bo), _beam_mat)
		_add_box(parent, Vector3(0.16 * s, 0.22 * s, rs - 2.0 * wt),
			Vector3(bo, beam_y, 0.0), _beam_mat)

	# ── The statement ──
	_build_statement(parent, s, depth, z_face_n, f_top)

	# ── The crack: seeded identically at every level — the 1:10 fissure
	#    is an exact 1:10 copy of the real one ──
	_build_crack(parent, s, half, wt, f_top)

	# ── The plinth (with a shadow-gap reveal the crack passes under) ──
	var plinth_w: float = 0.145 * rs
	var plinth_h: float = PLINTH_HEIGHT * s
	var reveal: float = PLINTH_REVEAL * s
	_add_box(parent, Vector3(plinth_w, plinth_h, plinth_w),
		Vector3(0.0, f_top + reveal + plinth_h * 0.5, 0.0), _plinth_mat)

	# ── The model: this room again, 1:10, on the plinth. Hard stop. ──
	if depth < recursion_depth and depth < MAX_DEPTH:
		var model_root := Node3D.new()
		model_root.name = "Model_depth_%d" % (depth + 1)
		model_root.position = Vector3(0.0, f_top + reveal + plinth_h, 0.0)
		parent.add_child(model_root)
		_build_room(model_root, s * 0.1, depth + 1)


func _build_statement(parent: Node3D, s: float, depth: int, z_face_n: float, f_top: float) -> void:
	# Floated 9 cm proud of the wall, in front of the pilaster plane.
	var z_lbl: float = z_face_n + 0.09 * s
	if depth == 0:
		var main_lbl := Label3D.new()
		main_lbl.text = STATEMENT_MAIN
		main_lbl.font_size = 80
		main_lbl.pixel_size = 0.004
		main_lbl.modulate = STATEMENT_COLOR
		main_lbl.outline_size = 4
		main_lbl.position = Vector3(0.0, f_top + 3.15 * s, z_lbl)
		parent.add_child(main_lbl)
		_statement_labels.append(main_lbl)

		var sub_lbl := Label3D.new()
		sub_lbl.text = STATEMENT_SUB
		sub_lbl.font_size = 44
		sub_lbl.pixel_size = 0.004
		sub_lbl.modulate = STATEMENT_COLOR
		sub_lbl.outline_size = 2
		sub_lbl.position = Vector3(0.0, f_top + 2.78 * s, z_lbl)
		parent.add_child(sub_lbl)
		_statement_labels.append(sub_lbl)
	else:
		# Too small to read; the statement persists as a glowing bar.
		_add_box(parent, Vector3(6.0 * s, 0.3 * s, 0.02 * s),
			Vector3(0.0, f_top + 3.15 * s, z_lbl), _statement_bar_mat)
		_add_box(parent, Vector3(1.7 * s, 0.16 * s, 0.02 * s),
			Vector3(0.0, f_top + 2.78 * s, z_lbl), _statement_bar_mat)


func _build_crack(parent: Node3D, s: float, half: float, wt: float, f_top: float) -> void:
	# Jagged fissure from the statement wall's base toward the plinth,
	# passing under the model. Re-seeded with the same seed at every
	# level so the recursion stays exact.
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed

	var z_start: float = -(half - wt)
	var z_end: float = 0.75 * s
	var pts: Array[Vector3] = []
	var x_cur: float = 0.0
	for i in range(CRACK_SEGMENTS + 1):
		var t: float = float(i) / float(CRACK_SEGMENTS)
		if i > 0:
			x_cur += rng.randf_range(-0.3, 0.3) * s
		var x_lim: float = 0.5 * s * (1.0 - t * 0.85)
		x_cur = clampf(x_cur, -x_lim, x_lim)
		pts.append(Vector3(x_cur, f_top + 0.006 * s, lerpf(z_start, z_end, t)))

	for i in range(CRACK_SEGMENTS):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var seg_len: float = p0.distance_to(p1) + 0.02 * s
		var mid: Vector3 = (p0 + p1) * 0.5
		var yaw: float = atan2(p1.x - p0.x, p1.z - p0.z)
		_add_box(parent, Vector3(0.05 * s, 0.012 * s, seg_len), mid,
			_crack_seg_mats[i], yaw)


func _build_collision(parent: Node3D) -> void:
	# Real-scale collision only: floor, four walls (door gap real),
	# lintel, ceiling, and a box guarding plinth + model.
	var body := StaticBody3D.new()
	body.name = "Collision"
	parent.add_child(body)

	var half: float = room_size * 0.5
	var wall_mid_y: float = FLOOR_TOP + WALL_HEIGHT * 0.5

	_add_col(body, Vector3(room_size, 0.14, room_size), Vector3(0.0, FLOOR_TOP - 0.07, 0.0))
	_add_col(body, Vector3(room_size, WALL_HEIGHT, WALL_THICK),
		Vector3(0.0, wall_mid_y, -(half - WALL_THICK * 0.5)))
	_add_col(body, Vector3(WALL_THICK, WALL_HEIGHT, room_size),
		Vector3(half - WALL_THICK * 0.5, wall_mid_y, 0.0))
	_add_col(body, Vector3(WALL_THICK, WALL_HEIGHT, room_size),
		Vector3(-(half - WALL_THICK * 0.5), wall_mid_y, 0.0))
	var seg_w: float = (room_size - DOOR_WIDTH) * 0.5
	var seg_x: float = DOOR_WIDTH * 0.5 + seg_w * 0.5
	_add_col(body, Vector3(seg_w, WALL_HEIGHT, WALL_THICK),
		Vector3(-seg_x, wall_mid_y, half - WALL_THICK * 0.5))
	_add_col(body, Vector3(seg_w, WALL_HEIGHT, WALL_THICK),
		Vector3(seg_x, wall_mid_y, half - WALL_THICK * 0.5))
	var lintel_h: float = WALL_HEIGHT - DOOR_HEIGHT
	_add_col(body, Vector3(DOOR_WIDTH, lintel_h, WALL_THICK),
		Vector3(0.0, FLOOR_TOP + DOOR_HEIGHT + lintel_h * 0.5, half - WALL_THICK * 0.5))
	_add_col(body, Vector3(room_size, 0.14, room_size),
		Vector3(0.0, FLOOR_TOP + WALL_HEIGHT + 0.07, 0.0))
	# Plinth + model guard (keeps hands and bodies out of the recursion).
	var plinth_w: float = 0.145 * room_size
	_add_col(body, Vector3(plinth_w + 0.04, 1.34, plinth_w + 0.04),
		Vector3(0.0, FLOOR_TOP + 0.67, 0.0))


func _build_lights(parent: Node3D) -> void:
	# One cold institutional fill from the coffers; one warm light that
	# belongs to the crack alone.
	var fill := OmniLight3D.new()
	fill.name = "CofferFill"
	fill.light_color = Color(0.85, 0.9, 1.0)
	fill.light_energy = 0.7
	fill.omni_range = room_size * 1.15
	fill.position = Vector3(0.0, FLOOR_TOP + WALL_HEIGHT - 0.35, 0.0)
	parent.add_child(fill)

	var ember := OmniLight3D.new()
	ember.name = "CrackEmber"
	ember.light_color = accent_color
	ember.light_energy = 0.9
	ember.omni_range = room_size * 0.7
	ember.position = Vector3(0.0, 0.4, -room_size * 0.19)
	parent.add_child(ember)


func _build_capture_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "CaptureCamera"
	cam.fov = 62.0
	cam.position = Vector3(1.05, 1.6, room_size * 0.5 - 1.3)
	cam.rotation_degrees = Vector3(1.5, 21.0, 0.0)
	add_child(cam)


# ═══════════════════════════════════════════════════════════════════════
# LIVING — trim breathes, statement doubts itself, crack light travels
# ═══════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not _built:
		return
	_time += delta

	# The trim light slowly breathes.
	if _trim_mat != null:
		var breathe: float = 1.05 + 0.45 * sin(_time * 0.55)
		_trim_mat.emission_energy_multiplier = breathe

	# Every ~9 s the statement flickers once — a doubt.
	if _time >= _next_flicker:
		_flicker_left = 0.22
		_next_flicker = _time + 9.0 + sin(_time * 0.13) * 1.2
	var glow: float = 1.0
	if _flicker_left > 0.0:
		_flicker_left -= delta
		glow = 0.25 + 0.75 * absf(sin(_time * 52.0))
	for lbl in _statement_labels:
		if is_instance_valid(lbl):
			lbl.modulate = Color(
				STATEMENT_COLOR.r * glow,
				STATEMENT_COLOR.g * glow,
				STATEMENT_COLOR.b * glow,
				1.0)
	if _statement_bar_mat != null:
		_statement_bar_mat.emission_energy_multiplier = 1.4 * glow

	# The fissure pulses from wall to plinth — light travelling INTO
	# the model, synchronised across every level (shared materials).
	for i in range(_crack_seg_mats.size()):
		var seg_mat: StandardMaterial3D = _crack_seg_mats[i]
		if seg_mat == null:
			continue
		var wave: float = maxf(0.0, sin(_time * 1.4 - float(i) * 0.55))
		seg_mat.emission_energy_multiplier = 0.7 + 1.6 * wave * wave * wave


# ═══════════════════════════════════════════════════════════════════════
# MATERIALS + HELPERS
# ═══════════════════════════════════════════════════════════════════════

func _make_materials() -> void:
	_wall_mat = _make_mat(Color(0.87, 0.86, 0.82), 0.85)
	_pilaster_mat = _make_mat(Color(0.92, 0.91, 0.88), 0.8)
	_floor_mat = _make_mat(Color(0.78, 0.77, 0.74), 0.9)
	_ceiling_mat = _make_mat(Color(0.84, 0.83, 0.8), 0.9)
	_beam_mat = _make_mat(Color(0.8, 0.79, 0.76), 0.85)
	_plinth_mat = _make_mat(Color(0.3, 0.3, 0.32), 0.6)

	_trim_mat = _make_mat(Color(0.95, 0.97, 1.0), 0.4)
	_trim_mat.emission_enabled = true
	_trim_mat.emission = Color(0.82, 0.9, 1.0)
	_trim_mat.emission_energy_multiplier = 1.2

	_statement_bar_mat = _make_mat(Color(0.9, 0.93, 1.0), 0.4)
	_statement_bar_mat.emission_enabled = true
	_statement_bar_mat.emission = Color(0.88, 0.93, 1.0)
	_statement_bar_mat.emission_energy_multiplier = 1.4

	_crack_seg_mats.clear()
	for _i in range(CRACK_SEGMENTS):
		var seg_mat: StandardMaterial3D = _make_mat(Color(0.12, 0.06, 0.03), 0.7)
		seg_mat.emission_enabled = true
		seg_mat.emission = accent_color
		seg_mat.emission_energy_multiplier = 1.0
		_crack_seg_mats.append(seg_mat)


func _make_mat(albedo: Color, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = rough
	mat.metallic = 0.0
	return mat


func _add_box(parent: Node3D, box_size: Vector3, pos: Vector3, mat: Material, yaw: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box_size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	if yaw != 0.0:
		mi.rotation.y = yaw
	parent.add_child(mi)
	return mi


func _add_col(body: StaticBody3D, box_size: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	cs.shape = shape
	cs.position = pos
	body.add_child(cs)
