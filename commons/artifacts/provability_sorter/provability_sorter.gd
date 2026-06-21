extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ProvabilitySorter

## @identity
## name: Provability Sorter
## lineage: the semantic picture of Godel — the set of TRUE statements strictly
##   contains the set of PROVABLE statements. Tarski-flavoured: truth outruns
##   proof.
## essence: two nested rings on a low plinth — an inner ring PROVABLE inside an
##   outer ring TRUE. Statement-tokens (small spheres) rain down and sort: most
##   settle in the inner PROVABLE disc, but some land in the gold GAP band
##   between the rings — "TRUE BUT UNPROVABLE" — where the Godel sentence sits
##   glowing, never falling inward.
## truth: the provable is a proper subset of the true. The gold band is never
##   empty and never closes; some truths have no proof.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var true_blue: Color = Color(0.40, 0.62, 0.95)
@export var provable_cyan: Color = Color(0.45, 0.85, 0.92)
@export var gap_gold: Color = Color(1.0, 0.78, 0.30)
@export var token_count: int = 22
@export var inner_radius: float = 0.24
@export var outer_radius: float = 0.46
@export var plinth_y: float = 0.30

var _t: float = 0.0
var _mm_inst: MultiMeshInstance3D
var _mm: MultiMesh
var _drop_t: PackedFloat32Array = PackedFloat32Array()    # per-token fall progress phase offset
var _is_gap: PackedInt32Array = PackedInt32Array()        # 1 = lands in the gold gap
var _ang: PackedFloat32Array = PackedFloat32Array()       # resting angle on its ring
var _rest_r: PackedFloat32Array = PackedFloat32Array()    # resting radius
var _spawn_r: PackedFloat32Array = PackedFloat32Array()   # x offset at spawn (above)
var _spawn_z: PackedFloat32Array = PackedFloat32Array()
var _godel_dot: MeshInstance3D
var _godel_mat: StandardMaterial3D
var _gap_ring_mat: StandardMaterial3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_t = 0.0
	# --- low plinth the rings rest on ---
	var plinth_mat := _steel_mat(Color(0.30, 0.32, 0.40))
	add_child(_cylinder(Vector3(0.0, plinth_y - 0.04, 0.0), outer_radius + 0.06, 0.08, plinth_mat))
	# faint plinth top disc
	var top_mat := _glow_mat(Color(0.20, 0.22, 0.30), 0.2)
	add_child(_cylinder(Vector3(0.0, plinth_y + 0.005, 0.0), outer_radius + 0.04, 0.01, top_mat))

	# --- the gold GAP band between the rings (the proper-subset annulus) ---
	# a flat torus filling the mid radius, gold — the home of TRUE-but-unprovable
	var gap_r: float = (inner_radius + outer_radius) * 0.5
	var gap_tube: float = (outer_radius - inner_radius) * 0.5 - 0.005
	_gap_ring_mat = _glow_mat(gap_gold, 0.7)
	var gap_band := _torus(Vector3(0.0, plinth_y + 0.012, 0.0), gap_r, gap_tube, _gap_ring_mat)
	gap_band.scale = Vector3(1.0, 0.10, 1.0)  # flatten into a band on the plinth
	add_child(gap_band)

	# --- outer ring: TRUE ---
	var true_mat := _glow_mat(true_blue, 1.0)
	add_child(_torus(Vector3(0.0, plinth_y + 0.02, 0.0), outer_radius, 0.012, true_mat))
	add_child(_billboard_label("TRUE", Vector3(0.0, plinth_y + 0.10, -outer_radius - 0.02), 18, true_blue))

	# --- inner ring: PROVABLE ---
	var prov_mat := _glow_mat(provable_cyan, 1.0)
	add_child(_torus(Vector3(0.0, plinth_y + 0.02, 0.0), inner_radius, 0.012, prov_mat))
	# faint inner disc to read it as a filled region
	var prov_fill := _glass_mat(provable_cyan, 0.16)
	add_child(_cylinder(Vector3(0.0, plinth_y + 0.015, 0.0), inner_radius - 0.01, 0.006, prov_fill))
	add_child(_billboard_label("PROVABLE", Vector3(0.0, plinth_y + 0.16, 0.0), 16, provable_cyan))

	# gap label
	add_child(_billboard_label("TRUE BUT UNPROVABLE", Vector3(0.0, plinth_y + 0.30, outer_radius + 0.04), 14, gap_gold))

	# --- the Godel sentence: a fixed glowing token sitting in the gap ---
	_godel_mat = _glow_mat(gap_gold, 1.6)
	_godel_dot = _sphere(Vector3(gap_r, plinth_y + 0.05, 0.0), 0.034, _godel_mat)
	add_child(_godel_dot)
	add_child(_billboard_label("G", Vector3(gap_r, plinth_y + 0.13, 0.0), 18, gap_gold))

	# --- the raining statement-tokens (MultiMesh) ---
	_build_tokens(gap_r)

	# --- title ---
	add_child(_billboard_label("PROVABILITY SORTER", Vector3(0.0, 1.5, 0.0), 30, cool_white))
	add_child(_billboard_label("the provable is a proper part of the true", Vector3(0.0, 1.36, 0.0), 14, wire_purple))


func _build_tokens(gap_r: float) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.022
	sphere.height = 0.044
	sphere.radial_segments = 8
	sphere.rings = 4
	var mat := _glow_mat(cool_white, 0.7)
	sphere.material = mat

	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.mesh = sphere
	_mm.instance_count = token_count

	_mm_inst = MultiMeshInstance3D.new()
	_mm_inst.multimesh = _mm
	add_child(_mm_inst)

	_drop_t.resize(token_count)
	_is_gap.resize(token_count)
	_ang.resize(token_count)
	_rest_r.resize(token_count)
	_spawn_r.resize(token_count)
	_spawn_z.resize(token_count)

	var i: int = 0
	while i < token_count:
		_drop_t[i] = _rng.randf()                        # stagger the fall
		# roughly 1 in 4 lands in the gold gap (true-but-unprovable); rest are provable
		var gap: bool = (_rng.randf() < 0.28)
		_is_gap[i] = 1 if gap else 0
		_ang[i] = _rng.randf() * TAU
		if gap:
			_rest_r[i] = gap_r + _rng.randf_range(-0.02, 0.02)
		else:
			_rest_r[i] = _rng.randf() * (inner_radius - 0.04)
		# spawn somewhere above the disc
		var sr: float = _rng.randf() * outer_radius
		var sa: float = _rng.randf() * TAU
		_spawn_r[i] = cos(sa) * sr
		_spawn_z[i] = sin(sa) * sr
		# seed the buffer so a no-process render is still valid
		var bx := Basis().scaled(Vector3.ONE)
		_mm.set_instance_transform(i, Transform3D(bx, Vector3(_spawn_r[i], plinth_y + 0.9, _spawn_z[i])))
		_mm.set_instance_color(i, gap_gold if gap else provable_cyan)
		i += 1


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _mm == null:
		return

	var fall_h: float = 0.9   # spawn height above plinth top
	var period: float = 4.0   # one full fall+reset cycle
	var i: int = 0
	while i < token_count:
		# each token cycles: fall from above to its resting slot, hold, respawn
		var p: float = fmod(_t / period + _drop_t[i], 1.0)
		var rest := Vector3(cos(_ang[i]) * _rest_r[i], plinth_y + 0.05, sin(_ang[i]) * _rest_r[i])
		var spawn := Vector3(_spawn_r[i], plinth_y + 0.05 + fall_h, _spawn_z[i])
		var pos: Vector3
		if p < 0.55:
			# falling — ease the descent, drift x/z toward the resting slot
			var f: float = p / 0.55
			var ef: float = f * f                         # accelerate downward
			pos = spawn.lerp(rest, ef)
			# a little settle bounce near the bottom
			if f > 0.85:
				pos.y += sin((f - 0.85) / 0.15 * PI) * 0.03
		else:
			# resting in its region until the cycle resets
			pos = rest

		var col: Color = gap_gold if _is_gap[i] == 1 else provable_cyan
		var sc: float = 1.0
		if _is_gap[i] == 1:
			# gap tokens pulse — they are the conspicuous remainder
			sc = 1.0 + 0.25 * sin(_t * 3.0 + float(i))
		var b := Basis().scaled(Vector3.ONE * sc)
		_mm.set_instance_transform(i, Transform3D(b, pos))
		_mm.set_instance_color(i, col)
		i += 1

	# the Godel token in the gap breathes and never moves inward
	if is_instance_valid(_godel_dot):
		var pulse: float = 0.5 + 0.5 * sin(_t * 2.2)
		_godel_dot.scale = Vector3.ONE * (1.0 + pulse * 0.18)
	if _godel_mat != null:
		_godel_mat.emission_energy_multiplier = (1.4 + 0.5 * sin(_t * 2.2)) if emissive else 0.0
	if _gap_ring_mat != null:
		_gap_ring_mat.emission_energy_multiplier = (0.6 + 0.25 * sin(_t * 1.6)) if emissive else 0.0
