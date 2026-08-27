extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheFourthLimit

## @identity
## lineage: four gates in a rank, built to one standard, facing the walker together so the
##   comparison is instant and nobody has to be told to make it. Three are honest limits
##   and the fourth is furniture wearing their uniform. Euler, Turing, Riemann — and then
##   the thing this whole project is about.
## essence: I is solid brass and carries the Konigsberg graph embossed on its face: four
##   banks, seven bridges, and it will not open because it CANNOT. II is solid brass with a
##   peephole that is dark — you may look, and looking tells you nothing; you would have to
##   go through to find out, which is the only way there has ever been. III stands ajar at
##   45 degrees with three fading ghosts of itself at 67.5, 78.75 and 84.4 — each push takes
##   half what remains, so it opens forever and never reaches the jamb. IV is GLASS. Locked,
##   with a small screw beside the plate, and behind it a warm lamp burning in the dark.
## truth: the first three you accept, live, or approach. The fourth you can SEE THROUGH, and
##   that is the whole argument — it is not explained to you, it is wanted. A default has no
##   image of its own; the only way to picture one is to put it in the rank beside real
##   limits and let the eye do the accusing.
## critical_parameter: gate_iv — it decides what the fourth limit IS. `glass` is the default
##   seen and denied; `brass` disguises it as a proof and the rank reads as four honest
##   walls; `open` is the screw already turned; `gone` removes the gate entirely and the
##   lamp simply stands there, which is what a limit looks like after nobody believes in it.
## triggers: none. No _process, no clock, no interaction — every mark is a function of
##   (behind, gate_iv, seed) computed once in _ready.
##
## Built 2026-08-27 from doc/THE_LIMITS.md, after Palle's "and the visual desire": the
## taxonomy was epistemic and had no wanting in it. Plaques were the first draft's mistake.
## There are no plaques here. Roman numerals cut into the threshold, and nothing else.

const BRASS := Color(0.77, 0.69, 0.48)
const BRASS_DARK := Color(0.44, 0.38, 0.25)
const STONE := Color(0.13, 0.13, 0.15)
const GLASSY := Color(0.62, 0.78, 0.86)
const WARM := Color(1.0, 0.80, 0.45)
const NUMERALS := ["I", "II", "III", "IV"]

# Konigsberg: four banks, seven bridges. Embossed on gate I because it is the reason
# that gate does not open. Positions are in gate-face space (metres, origin at centre).
const BANKS := [Vector2(0.0, 0.34), Vector2(0.0, -0.34), Vector2(-0.30, 0.0), Vector2(0.30, 0.0)]
const BRIDGES := [[0, 2], [0, 2], [0, 3], [1, 2], [1, 2], [1, 3], [2, 3]]

@export var seed: int = 4
## What stands behind the fourth gate — the thing you are being denied.
@export_enum("lamp", "garden", "mirror", "crowd") var behind: String = "lamp"
## What the fourth gate IS. See critical_parameter above.
@export_enum("glass", "brass", "open", "gone") var gate_iv: String = "glass"
@export var gate_w: float = 1.10
@export var gate_h: float = 2.15
@export var spacing: float = 1.92


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("behind"):
		behind = str(config_data["behind"])
	if config_data.has("gate_iv"):
		gate_iv = str(config_data["gate_iv"])
	if config_data.has("seed"):
		seed = int(config_data["seed"])
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	_rng.seed = seed
	_threshold()
	for i in range(4):
		_gate(i)
	_behind()


# --- the ground the rank stands on -------------------------------------------

func _threshold() -> void:
	var span: float = spacing * 3.0 + gate_w + 1.1
	var mat := _matte_mat(STONE, 0.9, 0.0)
	add_child(_box(Vector3(0, 0.05, 0), Vector3(span, 0.10, 1.5), mat))
	# roman numerals cut into the sill, one per gate. The only text in the piece.
	for i in range(4):
		var x: float = _gate_x(i)
		var lab := _billboard_label(NUMERALS[i], Vector3(x, 0.16, 0.60), 56, BRASS_DARK)
		lab.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lab.rotation_degrees = Vector3(-90, 0, 0)
		lab.outline_size = 0
		add_child(lab)


func _gate_x(i: int) -> float:
	return (float(i) - 1.5) * spacing


# --- the gates ---------------------------------------------------------------

func _gate(i: int) -> void:
	var x: float = _gate_x(i)
	if i == 3 and gate_iv == "gone":
		return                      # no frame either: there was never a gate here
	_frame(x)
	match i:
		0: _leaf_proof(x)
		1: _leaf_peephole(x)
		2: _leaf_zeno(x)
		3: _leaf_fourth(x)


## Brass jambs and lintel, identical on every gate — the uniform that makes the fourth
## gate's disguise possible.
func _frame(x: float) -> void:
	var mat := _steel_mat(BRASS)
	var jamb := Vector3(0.13, gate_h + 0.16, 0.30)
	add_child(_box(Vector3(x - gate_w * 0.5 - 0.065, (gate_h + 0.16) * 0.5, 0), jamb, mat))
	add_child(_box(Vector3(x + gate_w * 0.5 + 0.065, (gate_h + 0.16) * 0.5, 0), jamb, mat))
	add_child(_box(Vector3(x, gate_h + 0.08, 0), Vector3(gate_w + 0.26, 0.16, 0.30), mat))


func _leaf_mesh(x: float, mat: Material) -> MeshInstance3D:
	return _box(Vector3(x, gate_h * 0.5, 0), Vector3(gate_w, gate_h, 0.09), mat)


## I — the proof. Konigsberg embossed in relief: it does not open, and here is why.
func _leaf_proof(x: float) -> void:
	var leaf := _steel_mat(BRASS_DARK)
	add_child(_leaf_mesh(x, leaf))
	var relief := _steel_mat(BRASS)
	var cy: float = gate_h * 0.56
	var nodes: Array[Vector3] = []
	for b in BANKS:
		var p := Vector3(x + b.x, cy + b.y, 0.055)
		nodes.append(p)
		add_child(_sphere(p, 0.045, relief))
	# seven bridges. Two pairs are doubled, so they bow apart to stay countable.
	var seen := {}
	for e in BRIDGES:
		var a: int = int(e[0])
		var b2: int = int(e[1])
		var key: String = "%d-%d" % [a, b2]
		var n: int = int(seen.get(key, 0))
		seen[key] = n + 1
		var bow: float = 0.0 if n == 0 else 0.075
		_bridge(nodes[a], nodes[b2], bow, relief)


func _bridge(a: Vector3, b: Vector3, bow: float, mat: Material) -> void:
	if is_zero_approx(bow):
		add_child(_cylinder_between(a, b, 0.016, mat))
		return
	var mid: Vector3 = (a + b) * 0.5
	var out: Vector3 = (b - a).cross(Vector3.FORWARD).normalized() * bow
	add_child(_cylinder_between(a, mid + out, 0.016, mat))
	add_child(_cylinder_between(mid + out, b, 0.016, mat))


## II — the undecidable. A peephole you may look through, which is dark. The only way to
## learn whether it opens is to go through it, and you cannot go through it.
func _leaf_peephole(x: float) -> void:
	add_child(_leaf_mesh(x, _steel_mat(BRASS_DARK)))
	var ring := _steel_mat(BRASS)
	var eye: float = gate_h * 0.62
	add_child(_torus(Vector3(x, eye, 0.05), 0.075, 0.016, ring))
	# the hole itself: unlit, non-emissive, and it stays that way
	var dark := _matte_mat(Color(0.02, 0.02, 0.03), 1.0, 0.0)
	add_child(_box(Vector3(x, eye, 0.052), Vector3(0.115, 0.115, 0.006), dark))


## III — the horizon. Ajar at 45 degrees, with three ghosts of itself at 67.5, 78.75 and
## 84.4. Each push takes half of what is left, so it opens forever and never arrives.
func _leaf_zeno(x: float) -> void:
	var hinge: float = x - gate_w * 0.5
	var angle: float = 45.0
	_swing(hinge, angle, _steel_mat(BRASS_DARK))
	var remaining: float = 90.0 - angle
	for g in range(3):
		remaining *= 0.5
		var a: float = 90.0 - remaining
		var alpha: float = 0.34 - float(g) * 0.09
		_swing(hinge, a, _glass_mat(BRASS, alpha))


func _swing(hinge_x: float, degrees: float, mat: Material) -> void:
	var pivot := Node3D.new()
	pivot.position = Vector3(hinge_x, 0, 0)
	# swing TOWARD the viewer: the Zeno ghosts are the whole of gate III, and swung away
	# they hide behind their own leaf, leaving a door that merely stands open.
	pivot.rotation_degrees = Vector3(0, -degrees, 0)
	add_child(pivot)
	pivot.add_child(_box(Vector3(gate_w * 0.5, gate_h * 0.5, 0), Vector3(gate_w, gate_h, 0.09), mat))


## IV — the default. Whatever it is made of, it stands in the same frame as the three
## honest gates, which is the only reason it is visible at all.
func _leaf_fourth(x: float) -> void:
	match gate_iv:
		"brass":
			# disguised as a proof. The rank now reads as four honest walls, and the lamp
			# behind is invisible — which is what a default looks like from the outside.
			add_child(_leaf_mesh(x, _steel_mat(BRASS_DARK)))
			_lock(x, false)
		"open":
			# the screw already turned. The leaf stands aside; the way is clear.
			_swing(x - gate_w * 0.5, 104.0, _steel_mat(BRASS_DARK))
		_:
			# glass: seen, and denied. This is the default.
			add_child(_leaf_mesh(x, _glass_mat(GLASSY, 0.17)))
			_lock(x, true)


## The lock plate, the handle, and the small screw. The screw is the entire difference
## between this gate and the three beside it, and it is 9 mm across.
func _lock(x: float, lit: bool) -> void:
	var brass := _steel_mat(BRASS)
	var plate_y: float = gate_h * 0.46
	add_child(_box(Vector3(x + gate_w * 0.34, plate_y, 0.052), Vector3(0.10, 0.24, 0.012), brass))
	add_child(_cylinder_between(
		Vector3(x + gate_w * 0.30, plate_y, 0.075),
		Vector3(x + gate_w * 0.30, plate_y, 0.16), 0.018, brass))
	var screw_mat := _glow_mat(WARM, 0.9) if lit else _steel_mat(BRASS_DARK)
	add_child(_cylinder_between(
		Vector3(x + gate_w * 0.34, plate_y - 0.155, 0.050),
		Vector3(x + gate_w * 0.34, plate_y - 0.155, 0.062), 0.0045, screw_mat))


# --- what you are being denied -----------------------------------------------

func _behind() -> void:
	var x: float = _gate_x(3)
	var z: float = -1.15
	match behind:
		"garden":
			var soil := _matte_mat(Color(0.16, 0.12, 0.09), 1.0, 0.0)
			add_child(_box(Vector3(x, 0.16, z), Vector3(0.62, 0.22, 0.62), soil))
			var green := _glow_mat(Color(0.36, 0.82, 0.42), 0.55)
			for i in range(9):
				var a: float = _rng.randf() * TAU
				var r: float = _rng.randf() * 0.22
				var h: float = 0.30 + _rng.randf() * 0.34
				var base := Vector3(x + cos(a) * r, 0.27, z + sin(a) * r)
				add_child(_cylinder_between(base, base + Vector3(0, h, 0), 0.011, green))
				add_child(_sphere(base + Vector3(0, h, 0), 0.038, green))
		"mirror":
			# you see yourself: the default was yours
			var silver := _steel_mat(Color(0.86, 0.88, 0.92))
			silver.roughness = 0.02
			silver.metallic = 1.0
			add_child(_box(Vector3(x, gate_h * 0.52, z - 0.1), Vector3(0.86, 1.55, 0.05), silver))
			add_child(_box(Vector3(x, 0.10, z - 0.1), Vector3(0.98, 0.20, 0.34), _steel_mat(BRASS_DARK)))
		"crowd":
			var body := _matte_mat(Color(0.30, 0.32, 0.38), 0.85, 0.0)
			for i in range(5):
				var px: float = x - 0.44 + float(i) * 0.22 + _rng.randf() * 0.05
				var pz: float = z + _rng.randf() * 0.5
				var hh: float = 0.92 + _rng.randf() * 0.26
				add_child(_cylinder_between(Vector3(px, 0.0, pz), Vector3(px, hh, pz), 0.075, body))
				add_child(_sphere(Vector3(px, hh + 0.10, pz), 0.098, body))
		_:
			# lamp: the simplest wanting there is — a warm light in a dark room
			var post := _steel_mat(BRASS_DARK)
			add_child(_cylinder_between(Vector3(x, 0.0, z), Vector3(x, 0.86, z), 0.028, post))
			add_child(_box(Vector3(x, 0.03, z), Vector3(0.26, 0.06, 0.26), post))
			var shade := _glass_mat(WARM, 0.55)
			add_child(_sphere(Vector3(x, 0.98, z), 0.155, _glow_mat(WARM, 2.6)))
			add_child(_torus(Vector3(x, 1.02, z), 0.20, 0.022, shade))
			var lamp := OmniLight3D.new()
			lamp.position = Vector3(x, 0.98, z)
			lamp.light_color = WARM
			lamp.light_energy = 2.2
			lamp.omni_range = 4.2
			add_child(lamp)
