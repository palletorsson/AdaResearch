extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SelfMembershipSet

## @identity
## name: Self-Membership Set
## lineage: the heart of Russell's paradox — the set that is a member of itself,
##   and the set R = { x : x ∉ x } it forces into contradiction.
## essence: a ring/box brace contains a smaller copy of itself, recursively
##   four-to-five levels deep (a set ∈ itself ∈ itself ...), a glowing ∈ symbol
##   between each level. A red panel flickers where R = { x : x ∉ x } asks
##   "is R ∈ R?".
## truth: a set that is a member of itself, all the way down — and the set of
##   all sets that are NOT members of themselves cannot consistently exist.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var brace_blue: Color = Color(0.45, 0.65, 0.98)
@export var contradiction_red: Color = Color(0.902, 0.224, 0.275)
@export var levels: int = 5

var _epsilons: Array[Label3D] = []
var _r_panel: MeshInstance3D
var _r_mat: StandardMaterial3D
var _r_label: Label3D
var _braces: Array[Node3D] = []
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
	_epsilons.clear()
	_braces.clear()

	# --- floor plate (no bench — the diagram stands on the ground) ---
	var plate_mat := _steel_mat(Color(0.30, 0.32, 0.38))
	add_child(_cylinder(Vector3(0.0, 0.01, 0.0), 0.30, 0.02, plate_mat))
	var ring_mat := _glow_mat(wire_purple, 0.5)
	add_child(_torus(Vector3(0.0, 0.025, 0.0), 0.30, 0.010, ring_mat))

	# --- nested braces: each contains a smaller copy of itself ---
	# Outer brace centered around y ~0.62, shrinking inward and upward a touch.
	var n: int = maxi(levels, 2)
	var base_size: float = 0.52
	var base_y: float = 0.62
	for i in range(n):
		var f: float = float(i) / float(n)
		var s: float = base_size * pow(0.62, float(i))     # shrink each level
		var cy: float = base_y + f * 0.10                  # drift up slightly
		var bright: float = 1.4 - f * 0.6
		var brace: Node3D = _make_brace(Vector3(0.0, cy, 0.0), s, _glow_mat(brace_blue, bright))
		add_child(brace)
		_braces.append(brace)
		# a glowing ∈ between this level and the next-inner one
		if i < n - 1:
			var eps := _billboard_label("∈", Vector3(0.0, cy - s * 0.30, 0.02), 26, cool_white)
			add_child(eps)
			_epsilons.append(eps)

	# --- the red R = { x : x ∉ x } panel, standing beside the nest ---
	var panel_x: float = 0.42
	var panel_y: float = 0.78
	_r_mat = _glow_mat(contradiction_red, 1.2)
	_r_panel = _box(Vector3(panel_x, panel_y, 0.0), Vector3(0.34, 0.30, 0.015), _r_mat)
	add_child(_r_panel)
	# wire frame around it
	var fr := _glow_mat(contradiction_red, 1.6)
	add_child(_box(Vector3(panel_x, panel_y + 0.15, 0.01), Vector3(0.34, 0.008, 0.008), fr))
	add_child(_box(Vector3(panel_x, panel_y - 0.15, 0.01), Vector3(0.34, 0.008, 0.008), fr))
	add_child(_box(Vector3(panel_x - 0.17, panel_y, 0.01), Vector3(0.008, 0.30, 0.008), fr))
	add_child(_box(Vector3(panel_x + 0.17, panel_y, 0.01), Vector3(0.008, 0.30, 0.008), fr))
	add_child(_billboard_label("R = { x : x ∉ x }", Vector3(panel_x, panel_y + 0.05, 0.02), 16, cool_white))
	_r_label = _billboard_label("is R ∈ R ?", Vector3(panel_x, panel_y - 0.07, 0.02), 18, contradiction_red)
	add_child(_r_label)

	# --- billboard title ---
	add_child(_billboard_label("SELF-MEMBERSHIP SET", Vector3(0.0, 1.5, 0.0), 32, cool_white))
	add_child(_billboard_label("a set inside itself, all the way down", Vector3(0.0, 1.36, 0.0), 16, wire_purple))


func _make_brace(center: Vector3, size: float, mat: Material) -> Node3D:
	# A "{ ... }" brace rendered as an open box outline: left + right uprights
	# and short returns top/bottom, leaving the front open so you see inside.
	var root := Node3D.new()
	root.position = center
	var half: float = size * 0.5
	var t: float = maxf(size * 0.03, 0.006)  # tube radius scales with level
	# left and right vertical bars
	root.add_child(_box(Vector3(-half, 0.0, 0.0), Vector3(t * 2.0, size, t * 2.0), mat))
	root.add_child(_box(Vector3(half, 0.0, 0.0), Vector3(t * 2.0, size, t * 2.0), mat))
	# top + bottom returns (short, like brace serifs)
	var ret: float = size * 0.22
	root.add_child(_box(Vector3(-half + ret * 0.5, half, 0.0), Vector3(ret, t * 2.0, t * 2.0), mat))
	root.add_child(_box(Vector3(half - ret * 0.5, half, 0.0), Vector3(ret, t * 2.0, t * 2.0), mat))
	root.add_child(_box(Vector3(-half + ret * 0.5, -half, 0.0), Vector3(ret, t * 2.0, t * 2.0), mat))
	root.add_child(_box(Vector3(half - ret * 0.5, -half, 0.0), Vector3(ret, t * 2.0, t * 2.0), mat))
	return root


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# a pulse travels inward through the ∈ symbols — membership going down
	for i in range(_epsilons.size()):
		var eps: Label3D = _epsilons[i]
		if not is_instance_valid(eps):
			continue
		var ph: float = _t * 1.5 - float(i) * 0.6
		var pulse: float = 0.5 + 0.5 * sin(ph)
		eps.modulate = wire_purple.lerp(cool_white, pulse)
		eps.scale = Vector3.ONE * (0.85 + 0.3 * pulse)

	# the nested braces breathe slightly, emphasising the recursion
	for i in range(_braces.size()):
		var b: Node3D = _braces[i]
		if not is_instance_valid(b):
			continue
		var s: float = 1.0 + 0.02 * sin(_t * 2.0 - float(i) * 0.7)
		b.scale = Vector3(s, s, s)

	# the red R-panel flickers — the unresolvable "is R ∈ R?"
	if is_instance_valid(_r_mat):
		var flick: float = 0.5 + 0.5 * sin(_t * 7.0) * (0.6 + 0.4 * sin(_t * 2.3))
		_r_mat.emission_energy_multiplier = (0.6 + flick * 1.6) if emissive else 0.4
		_r_mat.albedo_color = contradiction_red.lerp(Color(0.20, 0.02, 0.05), 1.0 - flick)
	if is_instance_valid(_r_label):
		var blink: float = 1.0 if sin(_t * 5.0) > 0.0 else 0.0
		_r_label.modulate = contradiction_red.lerp(cool_white, blink * 0.5)
