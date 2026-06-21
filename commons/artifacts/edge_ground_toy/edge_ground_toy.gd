extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EdgeGroundToy

## @identity
## name: Edge-Ground Toy — The Edge Was Never the Failure
## concept: The edge is the ground
## tier: small
## lineage: post-crisis synthesis. Through the foundations crisis the edge — the limit, the
##   boundary where order runs out and the open begins — was read as the failure: the place a
##   system broke down, the proof a foundation was incomplete. The reversal is the thesis: the
##   edge was never the failure. It is the GROUND. The seam between order and the open is the
##   only place rich enough to build on (the lambda-edge, where structure and possibility meet).
##   A figure that stands on the limit as if it were solid floor has not fallen; it has finally
##   found the ground.
## essence: a held token (~0.4 m). Down the middle runs a seam: on one side a small ordered
##   crystal-block (regular, cool), on the other an open void of drifting motes. A tiny figure
##   stands ON the seam — feet planted on the join itself — and it holds, steady, lit warm. The
##   seam glows teal under its feet to show it is load-bearing. The figure does not topple into
##   either side; the edge carries it.
## truth: the edge was never the failure; it's the ground you build on. The limit holds your
##   weight — stand on the seam and it does not give.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var ground_teal: Color = Color(0.35, 0.88, 0.80)    # warm "load-bearing edge" accent
@export var mote_count: int = 14
@export var spin_speed: float = 0.3

var _t: float = 0.0
var _figure: Node3D
var _seam_mat: StandardMaterial3D
var _motes: Array = []           # {mi:MeshInstance3D, base:Vector3, phase:float}


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("mote_count"):
		mote_count = int(config["mote_count"])
	if config.has("spin_speed"):
		spin_speed = float(config["spin_speed"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_motes = []
	_t = 0.0

	# --- ORDER side: a small regular crystal-block (cool, structured) at x < 0 ---
	var order_mat: StandardMaterial3D = _glow_mat(wire_purple, 0.6)
	var gx: int = 0
	while gx < 3:
		var gy: int = 0
		while gy < 2:
			var gz: int = 0
			while gz < 3:
				var p: Vector3 = Vector3(-0.20 - float(gx) * 0.055, -0.04 + float(gy) * 0.055, -0.07 + float(gz) * 0.055)
				add_child(_box(p, Vector3(0.04, 0.04, 0.04), order_mat))
				gz += 1
			gy += 1
		gx += 1

	# --- VOID side: open drifting motes (the open, unstructured) at x > 0 ---
	var m: int = 0
	while m < mote_count:
		var base: Vector3 = Vector3(
			_rng.randf_range(0.08, 0.22),
			_rng.randf_range(-0.08, 0.12),
			_rng.randf_range(-0.10, 0.10))
		var mote: MeshInstance3D = _sphere(base, 0.008, _glow_mat(cool_white, 0.7))
		add_child(mote)
		_motes.append({"mi": mote, "base": base, "phase": _rng.randf_range(0.0, TAU)})
		m += 1

	# --- THE SEAM: the edge between order and void (a thin teal floor-strip at x=0) ---
	_seam_mat = _glow_mat(ground_teal, 1.6)
	add_child(_box(Vector3(0.0, -0.075, 0.0), Vector3(0.012, 0.012, 0.26), _seam_mat))
	# a faint plinth line so it reads as ground, not a wall
	add_child(_box(Vector3(0.0, -0.082, 0.0), Vector3(0.05, 0.004, 0.26), _glow_mat(ground_teal, 0.8)))

	# --- THE FIGURE: a tiny person standing ON the seam (feet on the join) ---
	_figure = Node3D.new()
	_figure.position = Vector3(0.0, 0.0, 0.0)
	add_child(_figure)
	var fig_mat: StandardMaterial3D = _glow_mat(ground_teal, 1.8)
	# legs planted on the seam
	_figure.add_child(_cylinder(Vector3(-0.012, -0.05, 0.0), 0.006, 0.05, fig_mat))
	_figure.add_child(_cylinder(Vector3(0.012, -0.05, 0.0), 0.006, 0.05, fig_mat))
	# torso
	_figure.add_child(_cylinder(Vector3(0.0, 0.0, 0.0), 0.012, 0.06, fig_mat))
	# head
	_figure.add_child(_sphere(Vector3(0.0, 0.045, 0.0), 0.016, fig_mat))
	# arms out, balanced — standing, not falling
	_figure.add_child(_cylinder_between(Vector3(0.0, 0.012, 0.0), Vector3(-0.05, 0.022, 0.0), 0.005, fig_mat))
	_figure.add_child(_cylinder_between(Vector3(0.0, 0.012, 0.0), Vector3(0.05, 0.022, 0.0), 0.005, fig_mat))

	# --- billboard title ---
	add_child(_billboard_label("THE EDGE IS THE GROUND", Vector3(0.0, 0.28, 0.0), 18, cool_white))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	rotation.y += delta * spin_speed

	# the figure stands steady — only the faintest balancing sway (it holds; it does not topple)
	if _figure != null:
		_figure.rotation.z = sin(_t * 1.1) * 0.04
		_figure.position.y = sin(_t * 1.4) * 0.004

	# the load-bearing seam pulses teal to show it carries the weight
	if _seam_mat != null:
		var pulse: float = 0.5 + 0.5 * sin(_t * 2.2)
		_seam_mat.emission_energy_multiplier = (1.4 + 1.2 * pulse) if emissive else 0.3

	# void motes drift (the open side is unstructured, restless)
	var i: int = 0
	while i < _motes.size():
		var md: Dictionary = _motes[i]
		var b: Vector3 = Vector3(md["base"])
		var ph: float = float(md["phase"])
		var mi: MeshInstance3D = md["mi"]
		if is_instance_valid(mi):
			mi.position = b + Vector3(
				sin(_t * 0.8 + ph) * 0.02,
				cos(_t * 0.9 + ph * 1.3) * 0.02,
				sin(_t * 0.7 + ph * 0.7) * 0.02)
		i += 1
