extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EthicsBench

## @identity
## name: Ethics Bench
## truth: Choose what to exclude out loud, and stay answerable for it.
##
## Ethical design after incompleteness — MEDIUM, floor-standing (~1m, label y~1.5).
## The ethical-design bench: a chosen design decision (lit teal cluster) shown
## WITH its excluded set made visible right beside it (dark cluster, not hidden).
## An amber "ANSWERABLE" stamp descends and presses onto the decision, then lifts.

@export var stamp_period: float = 3.0      # seconds per stamp cycle
@export var chosen_count: int = 5          # items inside the chosen design
@export var excluded_count: int = 4        # items in the visible excluded set

const COOL_WHITE := Color(0.90, 0.92, 0.97)
const SLATE := Color(0.34, 0.38, 0.48)
const PURPLE := Color(0.58, 0.42, 0.92)
const TEAL := Color(0.30, 0.82, 0.78)
const AMBER := Color(0.98, 0.72, 0.28)
const EXCLUDED := Color(0.10, 0.10, 0.15)
const EXCLUDED_RIM := Color(0.55, 0.28, 0.30)

var _stamp: Node3D = null
var _stamp_mat: StandardMaterial3D = null
var _chosen_nodes: Array[MeshInstance3D] = []
var _press_flash: MeshInstance3D = null
var _press_mat: StandardMaterial3D = null
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
	_chosen_nodes.clear()

	# --- Bench top (cool/formal white slab on slate legs) ------------------
	var top_mat: StandardMaterial3D = _matte_mat(COOL_WHITE, 0.7)
	add_child(_box(Vector3(0, 0.50, 0), Vector3(1.10, 0.05, 0.55), top_mat))
	var leg_mat: StandardMaterial3D = _steel_mat(SLATE)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			add_child(_cylinder(Vector3(0.46 * sx, 0.25, 0.20 * sz), 0.03, 0.50, leg_mat))

	# A purple wireframe divider down the middle — the explicit line of choice.
	add_child(_box(Vector3(0, 0.56, 0), Vector3(0.012, 0.10, 0.55), _glow_mat(PURPLE, 1.5)))

	# --- LEFT: the chosen design (lit, teal) -------------------------------
	var chosen_plate: StandardMaterial3D = _glass_mat(TEAL, 0.22)
	add_child(_box(Vector3(-0.30, 0.53, 0), Vector3(0.42, 0.012, 0.42), chosen_plate))
	for i in range(chosen_count):
		var a: float = TAU * float(i) / float(chosen_count)
		var p := Vector3(-0.30 + cos(a) * 0.13, 0.58, sin(a) * 0.13)
		var node: MeshInstance3D = _box(p, Vector3(0.05, 0.06, 0.05), _glow_mat(TEAL, 1.6))
		add_child(node)
		_chosen_nodes.append(node)
	add_child(_sphere(Vector3(-0.30, 0.62, 0), 0.04, _glow_mat(COOL_WHITE, 1.4)))
	add_child(_billboard_label("CHOSEN", Vector3(-0.30, 0.86, 0), 18, TEAL))

	# --- RIGHT: the excluded set, MADE VISIBLE (dark, not hidden) ----------
	var ex_plate: StandardMaterial3D = _matte_mat(Color(0.04, 0.04, 0.07), 0.95)
	add_child(_box(Vector3(0.30, 0.535, 0), Vector3(0.42, 0.012, 0.42), ex_plate))
	# a dark-red rim — visible, acknowledged, on display rather than buried
	add_child(_torus(Vector3(0.30, 0.55, 0), 0.20, 0.008, _glow_mat(EXCLUDED_RIM, 1.0)))
	for j in range(excluded_count):
		var a2: float = TAU * float(j) / float(excluded_count) + 0.4
		var p2 := Vector3(0.30 + cos(a2) * 0.13, 0.57, sin(a2) * 0.13)
		var dark: MeshInstance3D = _box(p2, Vector3(0.05, 0.05, 0.05), _matte_mat(EXCLUDED, 0.9))
		add_child(dark)
		# faint outline so the excluded items remain countable, not erased
		add_child(_box(p2, Vector3(0.054, 0.054, 0.054), _glow_mat(EXCLUDED_RIM, 0.5)))
	add_child(_billboard_label("EXCLUDED — VISIBLE", Vector3(0.30, 0.86, 0), 16, AMBER))

	# --- The descending AMBER "ANSWERABLE" stamp ---------------------------
	_stamp = Node3D.new()
	add_child(_stamp)
	_stamp_mat = _glow_mat(AMBER, 1.8)
	# stamp head
	_stamp.add_child(_box(Vector3(-0.30, 0.0, 0), Vector3(0.30, 0.06, 0.30), _stamp_mat))
	_stamp.add_child(_cylinder(Vector3(-0.30, 0.12, 0), 0.025, 0.18, _steel_mat(SLATE)))
	_stamp.add_child(_billboard_label("ANSWERABLE", Vector3(-0.30, 0.30, 0), 18, AMBER))

	# A press-flash decal that lights when the stamp lands on the decision.
	_press_mat = _glow_mat(AMBER, 0.0)
	_press_flash = _box(Vector3(-0.30, 0.565, 0), Vector3(0.40, 0.006, 0.40), _press_mat)
	add_child(_press_flash)

	# --- Title -------------------------------------------------------------
	add_child(_billboard_label("STAY ANSWERABLE", Vector3(0, 1.5, 0), 34, COOL_WHITE))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# Stamp cycle: descend, press (flash), lift.
	var phase: float = fmod(_t, stamp_period) / stamp_period
	var height: float
	var pressed: bool = false
	if phase < 0.4:
		# descending
		height = lerp(0.42, 0.10, phase / 0.4)
	elif phase < 0.55:
		# pressed down on the decision
		height = 0.10
		pressed = true
	else:
		# lifting back up
		height = lerp(0.10, 0.42, (phase - 0.55) / 0.45)
	if _stamp != null:
		_stamp.position.y = 0.62 + height

	# Press flash glows on contact (constructive amber).
	if _press_mat != null:
		var energy: float = (2.4 if pressed else 0.0)
		_press_mat.emission_energy_multiplier = energy if emissive else 0.0

	# Chosen items gently pulse (the design is live, in use).
	for i in range(_chosen_nodes.size()):
		var node: MeshInstance3D = _chosen_nodes[i]
		var s: float = 1.0 + 0.10 * sin(_t * 3.0 + float(i))
		node.scale = Vector3(1.0, s, 1.0)
