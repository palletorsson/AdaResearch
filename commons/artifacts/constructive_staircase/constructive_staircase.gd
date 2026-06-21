extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ConstructiveStaircase

## @identity
## name: Constructive Staircase
## lineage: Brouwer's intuitionism — a mathematical object exists only once you
##   have CONSTRUCTED it. The law of the excluded middle (P or not-P) is rejected:
##   before construction, a statement is neither true nor false.
## essence: a staircase that builds itself one step at a time. Built steps are
##   solid white treads with crisp wire edges. The region ahead is not empty and
##   not solid — it is an undetermined cyan haze, ghost-steps that are neither
##   there nor not-there. A pulse of construction crystallises the next step out
##   of the haze; when the flight completes it dissolves back and begins again.
## truth: the next step isn't true-or-false until you build it — existence is
##   construction, not the absence of a contradiction.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.92, 0.94, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent_cyan: Color = Color(0.30, 0.92, 0.92)
@export var step_count: int = 7
@export var build_interval: float = 0.85   # seconds between each new step
@export var hold_full: float = 1.6         # pause once the whole flight stands

var _built_root: Node3D     # solid, crystallised steps
var _haze_root: Node3D      # undetermined ghost-steps ahead
var _counter: Label3D
var _t: float = 0.0
var _built: int = 0         # how many steps are currently solid

const STEP_W: float = 0.42          # tread width (x)
const STEP_D: float = 0.16          # tread depth (z)
const STEP_RISE: float = 0.14       # height gained per step (y)
const Y0: float = 0.04              # first tread top sits just above floor


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
	# --- chalk ring on the floor (no bench) ---
	var ring_mat := _glow_mat(wire_purple, 0.5)
	add_child(_torus(Vector3(0.0, 0.02, 0.0), 0.56, 0.012, ring_mat))

	# ground baseline the flight climbs from (a single drawn line in z)
	var base_z: float = -float(step_count) * STEP_D * 0.5
	add_child(_box(Vector3(0.0, 0.02, base_z - 0.02), Vector3(STEP_W + 0.10, 0.01, 0.02), ring_mat))

	# two persistent roots: what is built (solid) and what is ahead (haze)
	_built_root = Node3D.new()
	add_child(_built_root)
	_haze_root = Node3D.new()
	add_child(_haze_root)

	_built = 0
	_t = 0.0
	_rebuild_steps()

	# --- labels ---
	add_child(_billboard_label("CONSTRUCTIVE STAIRCASE", Vector3(0.0, 1.5, 0.0), 30, cool_white))
	add_child(_billboard_label("exists only once built — no excluded middle", Vector3(0.0, 1.36, 0.0), 16, accent_cyan))
	# running tally of how many steps have been constructed so far
	_counter = _billboard_label("0 / %d built" % step_count, Vector3(0.0, 1.20, 0.0), 18, cool_white)
	add_child(_counter)


# Position of the top-front corner reference for step index i (0-based).
func _step_center(i: int) -> Vector3:
	var base_z: float = -float(step_count) * STEP_D * 0.5
	var y: float = Y0 + float(i) * STEP_RISE
	var z: float = base_z + float(i) * STEP_D + STEP_D * 0.5
	return Vector3(0.0, y, z)


# Clear and redraw both roots according to _built. crystal_t in 0..1 animates the
# step currently being constructed (the frontier between solid and haze).
func _rebuild_steps(crystal_t: float = 1.0) -> void:
	for c in _built_root.get_children():
		_built_root.remove_child(c)
		c.queue_free()
	for c in _haze_root.get_children():
		_haze_root.remove_child(c)
		c.queue_free()

	var white := _matte_mat(cool_white, 0.5)
	var wire := _glow_mat(wire_purple, 0.9)

	for i in range(step_count):
		var c: Vector3 = _step_center(i)
		if i < _built:
			# --- SOLID, constructed step: white tread + riser + crisp wire edge ---
			_built_root.add_child(_box(Vector3(c.x, c.y, c.z), Vector3(STEP_W, 0.035, STEP_D), white))
			# riser dropping to the step below (or to baseline for the first)
			var riser_h: float = STEP_RISE
			_built_root.add_child(_box(
				Vector3(c.x, c.y - riser_h * 0.5, c.z - STEP_D * 0.5),
				Vector3(STEP_W, riser_h, 0.02), white))
			# drawn front edge
			_built_root.add_child(_box(
				Vector3(c.x, c.y + 0.02, c.z + STEP_D * 0.5),
				Vector3(STEP_W + 0.02, 0.008, 0.008), wire))
			_built_root.add_child(_box(
				Vector3(c.x - STEP_W * 0.5, c.y + 0.02, c.z),
				Vector3(0.008, 0.008, STEP_D), wire))
			_built_root.add_child(_box(
				Vector3(c.x + STEP_W * 0.5, c.y + 0.02, c.z),
				Vector3(0.008, 0.008, STEP_D), wire))
		elif i == _built:
			# --- THE FRONTIER step, crystallising out of the haze ---
			# It rises and brightens from haze -> solid as crystal_t goes 0 -> 1.
			var lift: float = (1.0 - crystal_t) * STEP_RISE * 0.8
			var col: Color = accent_cyan.lerp(cool_white, crystal_t)
			var alpha: float = lerp(0.30, 0.95, crystal_t)
			var emerging := _glass_mat(col, alpha)
			_haze_root.add_child(_box(
				Vector3(c.x, c.y - lift, c.z),
				Vector3(STEP_W, 0.035 + 0.02 * (1.0 - crystal_t), STEP_D), emerging))
			# wire outline sharpening as it solidifies
			var edge := _glow_mat(col, 0.6 + crystal_t * 1.2)
			_haze_root.add_child(_box(
				Vector3(c.x, c.y - lift + 0.02, c.z + STEP_D * 0.5),
				Vector3(STEP_W + 0.02, 0.008, 0.008), edge))
		else:
			# --- UNDETERMINED region ahead: ghost-haze, neither solid nor empty ---
			# Faint, translucent, slightly jittered cyan boxes — present as
			# possibility, absent as fact. (NOT-true and NOT-false.)
			var ghost := _glass_mat(accent_cyan, 0.10)
			var jx: float = _rng.randf_range(-0.012, 0.012)
			var jz: float = _rng.randf_range(-0.012, 0.012)
			_haze_root.add_child(_box(
				Vector3(c.x + jx, c.y, c.z + jz),
				Vector3(STEP_W * 0.92, 0.028, STEP_D * 0.92), ghost))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# total cycle: build each step in turn, hold the full flight, then reset.
	var build_phase: float = float(step_count) * build_interval
	var cycle: float = build_phase + hold_full
	var local: float = fmod(_t, cycle)

	var target_built: int
	var crystal_t: float = 1.0
	if local < build_phase:
		target_built = int(local / build_interval)
		# fractional progress of the step currently crystallising
		var frac: float = fmod(local, build_interval) / build_interval
		# smoothstep the crystallisation
		crystal_t = frac * frac * (3.0 - 2.0 * frac)
	else:
		target_built = step_count
		crystal_t = 1.0

	# rebuild whenever the count changes OR (cheaply) while a step is crystallising
	var need_rebuild: bool = (target_built != _built)
	_built = target_built
	# during the crystallising window we want a smooth lift, so rebuild the
	# frontier each frame; the haze jitter is regenerated but that reads as shimmer.
	if local < build_phase or need_rebuild:
		_rebuild_steps(crystal_t)

	# update the constructed-count readout; haze region shimmers cyan
	if is_instance_valid(_counter):
		_counter.text = "%d / %d built" % [_built, step_count]
		var pulse: float = 0.5 + 0.5 * sin(_t * 3.0)
		_counter.modulate = cool_white.lerp(accent_cyan, pulse * 0.5)
