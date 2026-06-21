extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name HaltingBench

## @identity
## name: The Halting Problem — A Verdict That Cannot Settle
## lineage: Turing, 1936. There is no algorithm that, given any program and its
##   input, decides whether that program halts. The proof feeds the decider its
##   own description and inverts the answer — a diagonal that contradicts itself.
## essence: a machine on a plinth is fed a punched tape that is its OWN
##   description, asked "WILL THIS STOP?" A verdict lamp tries to choose between
##   HALTS and LOOPS but flips forever, the arrow on the dial unable to rest.
## truth: no algorithm decides whether every program halts — assume one exists,
##   feed it itself, and it must do the opposite of whatever it answers.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var halt_green: Color = Color(0.40, 0.92, 0.55)
@export var loop_red: Color = Color(0.902, 0.224, 0.275)
@export var flip_period: float = 1.8

var _lamp_halts: MeshInstance3D
var _lamp_loops: MeshInstance3D
var _needle: Node3D
var _tape: Node3D
var _qmark: Label3D
var _t: float = 0.0


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
	var purple_mat := _glow_mat(wire_purple, 0.7)
	var steel := _steel_mat(Color(0.34, 0.36, 0.44))
	var white_mat := _glow_mat(cool_white, 0.6)

	# floor chalk disc
	add_child(_torus(Vector3(0.0, 0.02, 0.0), 0.72, 0.01, purple_mat))

	# --- the machine: a boxy decider on a plinth ---
	add_child(_box(Vector3(0.0, 0.18, 0.0), Vector3(0.5, 0.36, 0.4), steel))
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(0.56, 0.12, 0.46), _glow_mat(Color(0.20, 0.24, 0.34), 0.5)))
	add_child(_billboard_label("DECIDER  H(P, P)", Vector3(0.0, 0.66, 0.0), 16, cool_white))

	# --- the tape fed in: the machine's OWN description (punched cells) ---
	_tape = Node3D.new()
	add_child(_tape)
	var tape_mat := _matte_mat(Color(0.85, 0.86, 0.92), 0.6)
	var hole_mat := _glow_mat(wire_purple, 0.9)
	var n: int = 12
	for i in range(n):
		var x: float = -0.55 - float(i) * 0.10
		_tape.add_child(_box(Vector3(x, 0.30, 0.0), Vector3(0.09, 0.10, 0.012), tape_mat))
		# punched bit pattern (its own code)
		if (i * 7 + 3) % 3 == 0:
			_tape.add_child(_box(Vector3(x, 0.30, 0.008), Vector3(0.03, 0.03, 0.01), hole_mat))
	add_child(_billboard_label("its own description", Vector3(-1.1, 0.46, 0.0), 13, wire_purple))

	# --- the verdict panel: two lamps HALTS / LOOPS + a dial needle ---
	var panel := Vector3(0.0, 0.86, 0.22)
	add_child(_box(panel, Vector3(0.6, 0.34, 0.03), steel))
	_lamp_halts = _sphere(panel + Vector3(-0.16, 0.06, 0.03), 0.05, _glow_mat(halt_green, 0.4))
	_lamp_loops = _sphere(panel + Vector3(0.16, 0.06, 0.03), 0.05, _glow_mat(loop_red, 0.4))
	add_child(_lamp_halts)
	add_child(_lamp_loops)
	add_child(_billboard_label("HALTS", panel + Vector3(-0.16, 0.16, 0.0), 12, halt_green))
	add_child(_billboard_label("LOOPS", panel + Vector3(0.16, 0.16, 0.0), 12, loop_red))

	# the dial + needle that can never rest between the two
	add_child(_torus(panel + Vector3(0.0, -0.06, 0.03), 0.11, 0.006, white_mat))
	_needle = Node3D.new()
	_needle.position = panel + Vector3(0.0, -0.06, 0.04)
	add_child(_needle)
	_needle.add_child(_cylinder_between(Vector3.ZERO, Vector3(0.0, 0.10, 0.0), 0.006, _glow_mat(cool_white, 1.2)))

	# --- the question that never resolves ---
	_qmark = _billboard_label("WILL THIS STOP?", Vector3(0.0, 1.16, 0.0), 22, loop_red)
	add_child(_qmark)

	# --- title ---
	add_child(_billboard_label("THE HALTING PROBLEM", Vector3(0.0, 1.5, 0.0), 30, cool_white))
	add_child(_billboard_label("no algorithm decides whether every program halts", Vector3(0.0, 1.36, 0.0), 14, wire_purple))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# the needle swings between HALTS and LOOPS and never settles (diagonal flip)
	var phase: float = fmod(_t, flip_period) / flip_period
	var tri: float = absf(phase * 2.0 - 1.0)
	var eased: float = tri * tri * (3.0 - 2.0 * tri)
	# but add a contradiction jerk: near the moment it would commit, it inverts
	var commit: float = smoothstep(0.42, 0.5, tri) - smoothstep(0.5, 0.58, tri)
	var ang: float = lerpf(-0.9, 0.9, eased) - commit * 0.6
	if is_instance_valid(_needle):
		_needle.rotation.z = -ang

	# the two lamps fight: as the needle leans green, HALTS brightens, and vice
	var lean: float = (ang + 0.9) / 1.8  # 0 = halts side, 1 = loops side
	if is_instance_valid(_lamp_halts):
		var mh: StandardMaterial3D = _lamp_halts.material_override as StandardMaterial3D
		if mh != null:
			mh.emission_energy_multiplier = (1.0 if emissive else 0.3) * lerpf(1.6, 0.1, lean)
	if is_instance_valid(_lamp_loops):
		var ml: StandardMaterial3D = _lamp_loops.material_override as StandardMaterial3D
		if ml != null:
			ml.emission_energy_multiplier = (1.0 if emissive else 0.3) * lerpf(0.1, 1.6, lean)

	# the tape slowly feeds into the machine, looping (it never finishes reading)
	if is_instance_valid(_tape):
		var feed: float = fmod(_t * 0.15, 0.10)
		_tape.position.x = feed

	# the question pulses red — the verdict that cannot come
	if is_instance_valid(_qmark):
		var pulse: float = 0.5 + 0.5 * sin(_t * 4.0)
		_qmark.modulate = loop_red.lerp(cool_white, pulse * 0.4)
		_qmark.scale = Vector3.ONE * (1.0 + pulse * 0.15)
