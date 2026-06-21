extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ImpossibleObjectPress

## @identity
## name: Impossible Object Press — Locally Fine, Globally Impossible
## concept: Escher & impossible objects
## tier: applied
## lineage: the impossible-figure tradition — Reutersvard's triangle (1934), the Penrose
##   triangle and blivet (devil's fork), the impossible cube. Each is drawable, each is
##   buildable only as an illusion.
## essence: a small press that stamps out impossible objects. The platen lowers, a die
##   strikes, and a new figure rises — a Penrose triangle, then a blivet, then an
##   impossible cube. Each is locally consistent at every joint and globally impossible.
##   A readout names the figure on the platen.
## truth: a generator can be perfectly correct at every step and still produce things that
##   cannot exist. Soundness is local; impossibility is a property of the whole.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent: Color = Color(0.98, 0.66, 0.28)
@export var cycle_time: float = 4.2

var _t: float = 0.0
var _platen: MeshInstance3D
var _ram: MeshInstance3D
var _stage: Node3D            # holder for the current figure
var _readout: Label3D
var _names: Array = ["PENROSE TRIANGLE", "BLIVET (DEVIL'S FORK)", "IMPOSSIBLE CUBE"]
var _current: int = -1


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("cycle_time"):
		cycle_time = float(config["cycle_time"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_current = -1
	var steel: StandardMaterial3D = _steel_mat(Color(0.34, 0.36, 0.44))
	var purple_mat: StandardMaterial3D = _glow_mat(wire_purple, 0.6)
	var base_mat: StandardMaterial3D = _matte_mat(Color(0.10, 0.11, 0.16), 0.85)

	# --- base + platen ---
	add_child(_box(Vector3(0.0, 0.04, 0.0), Vector3(0.9, 0.08, 0.7), base_mat))
	_platen = _box(Vector3(0.0, 0.12, 0.0), Vector3(0.62, 0.05, 0.5), _glow_mat(cool_white, 0.4))
	add_child(_platen)

	# --- two press columns ---
	add_child(_cylinder(Vector3(-0.38, 0.55, -0.28), 0.035, 0.95, steel))
	add_child(_cylinder(Vector3(0.38, 0.55, -0.28), 0.035, 0.95, steel))
	# crown beam
	add_child(_box(Vector3(0.0, 1.02, -0.28), Vector3(0.86, 0.10, 0.14), steel))

	# --- the ram (descends to stamp) ---
	_ram = _box(Vector3(0.0, 0.72, 0.0), Vector3(0.5, 0.16, 0.4), _steel_mat(Color(0.5, 0.52, 0.6)))
	add_child(_ram)
	# die teeth under the ram
	add_child(_box(Vector3(0.0, 0.62, 0.0), Vector3(0.46, 0.04, 0.36), purple_mat))

	# --- the figure stage on the platen ---
	_stage = Node3D.new()
	_stage.position = Vector3(0.0, 0.16, 0.0)
	add_child(_stage)
	_stamp_figure(0)

	# --- readout ---
	_readout = _billboard_label("PRESSING…", Vector3(0.0, 1.32, 0.0), 22, accent)
	add_child(_readout)
	add_child(_billboard_label("locally fine — globally impossible", Vector3(0.0, 1.12, 0.0), 13, wire_purple))
	add_child(_billboard_label("IMPOSSIBLE OBJECT PRESS", Vector3(0.0, 1.5, 0.0), 18, cool_white))


func _clear_stage() -> void:
	for c in _stage.get_children():
		_stage.remove_child(c)
		c.queue_free()


func _stamp_figure(which: int) -> void:
	if which == _current:
		return
	_current = which
	_clear_stage()
	if which == 0:
		_make_penrose()
	elif which == 1:
		_make_blivet()
	else:
		_make_cube()
	if _readout != null:
		_readout.text = _names[which]


func _bar(a: Vector3, b: Vector3, thick: float, mat: Material) -> void:
	# a square-section bar from a to b (box aligned to the segment)
	var d: Vector3 = b - a
	var length: float = d.length()
	if length < 0.001:
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(thick, thick, length)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = (a + b) * 0.5
	mi.look_at_from_position(mi.position, b, Vector3.UP)
	_stage.add_child(mi)


func _make_penrose() -> void:
	var mat: StandardMaterial3D = _glow_mat(accent, 1.1)
	var s: float = 0.26
	var h: float = s * 0.866
	var v_bl: Vector3 = Vector3(-s * 0.5, 0.0, -h / 3.0)
	var v_br: Vector3 = Vector3(s * 0.5, 0.0, -h / 3.0)
	var v_top: Vector3 = Vector3(0.0, 0.0, h * 2.0 / 3.0)
	var z_gap: float = s * 0.25
	var v_top_back: Vector3 = v_top + Vector3(0.0, z_gap, 0.0)
	_bar(v_bl, v_br, 0.06, mat)
	_bar(v_br, v_top_back, 0.06, mat)
	_bar(v_top, v_bl, 0.06, mat)


func _make_blivet() -> void:
	# The devil's fork: 3 round prongs at top resolve into 2 rectangular prongs at base.
	var mat: StandardMaterial3D = _glow_mat(accent, 1.1)
	var back: float = -0.22
	var front: float = 0.22
	var y: float = 0.18
	# back plate (where 2 rectangular prongs live)
	_stage.add_child(_box(Vector3(0.0, y, back), Vector3(0.34, 0.16, 0.04), mat))
	# 2 solid prongs from back plate
	_bar(Vector3(-0.10, y + 0.04, back), Vector3(-0.10, y + 0.04, front), 0.05, mat)
	_bar(Vector3(0.10, y - 0.04, back), Vector3(0.10, y - 0.04, front), 0.05, mat)
	# 3 round prongs at the front (the impossible third emerges from the gap)
	var prong: StandardMaterial3D = _glow_mat(cool_white, 0.9)
	_round_prong(Vector3(-0.12, y + 0.05, front - 0.02), Vector3(-0.12, y + 0.05, front + 0.16), 0.022, prong)
	_round_prong(Vector3(0.0, y, front - 0.02), Vector3(0.0, y, front + 0.16), 0.022, prong)
	_round_prong(Vector3(0.12, y - 0.05, front - 0.02), Vector3(0.12, y - 0.05, front + 0.16), 0.022, prong)


func _round_prong(a: Vector3, b: Vector3, r: float, mat: Material) -> void:
	_stage.add_child(_cylinder_between(a, b, r, mat))


func _make_cube() -> void:
	# Impossible cube: a wireframe cube where two edges swap front/back at a joint.
	var mat: StandardMaterial3D = _glow_mat(accent, 1.1)
	var s: float = 0.20
	var v: Array = [
		Vector3(-s, -s, -s), Vector3(s, -s, -s), Vector3(s, s, -s), Vector3(-s, s, -s),
		Vector3(-s, -s, s), Vector3(s, -s, s), Vector3(s, s, s), Vector3(-s, s, s)
	]
	# offset everything up so it sits on the platen
	var lift: Vector3 = Vector3(0.0, s + 0.04, 0.0)
	# 12 edges
	var edges: Array = [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7]
	]
	var thick: float = 0.035
	var i: int = 0
	while i < edges.size():
		var e: Array = edges[i]
		var a: Vector3 = v[e[0]] + lift
		var b: Vector3 = v[e[1]] + lift
		_bar(a, b, thick, mat)
		i += 1
	# the impossible joint — a stub bar crossing in front where it should pass behind
	_bar(Vector3(s, s, -s) + lift, Vector3(-s, -s, s) + lift * 0.4, thick * 0.9, _glow_mat(cool_white, 1.0))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var phase: float = fmod(_t, cycle_time) / cycle_time
	var idx: int = int(_t / cycle_time) % _names.size()

	# ram motion: descend (0..0.3) strike, lift (0.3..0.6), dwell (0.6..1.0)
	var ram_y: float = 0.72
	if phase < 0.3:
		var f: float = phase / 0.3
		ram_y = lerp(0.72, 0.34, f * f)
	elif phase < 0.6:
		ram_y = lerp(0.34, 0.72, (phase - 0.3) / 0.3)
	else:
		ram_y = 0.72
	if is_instance_valid(_ram):
		_ram.position.y = ram_y

	# at the strike, swap the figure
	if phase >= 0.28 and phase < 0.34:
		_stamp_figure(idx)

	# figure rises and spins to show it from all angles
	if _stage != null:
		var rise: float = 0.16 + 0.05 * (0.5 + 0.5 * sin(phase * PI))
		_stage.position.y = rise
		_stage.rotation.y = _t * 0.7

	# readout pulses
	if is_instance_valid(_readout):
		_readout.modulate = accent.lerp(cool_white, 0.5 + 0.5 * sin(_t * 3.0))
