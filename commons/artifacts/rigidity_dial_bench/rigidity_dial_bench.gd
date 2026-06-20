extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RigidityDialBench

## @identity
## name: "Soft vs rigid (the alive middle)"
## tier: medium
## lineage: A bench that sweeps a row of bodies along a stiffness axis — crystal-frozen at the
##   left, jiggling and alive through the soft middle, slumped to a puddle at the right. A pointer
##   rides back and forth and lingers at the live centre, because that is where anything happens.
## truth: "THE ALIVE MIDDLE OF THE STIFFNESS AXIS — TOO HARD IS DEAD, TOO LOOSE IS DEAD"
## applications: glass transition, jamming, the order parameter of edge-of-chaos systems, tunable
##   soft actuators — a single knob that turns dead matter into living matter and back.

const N_BODIES: int = 9

@export var bench_w: float = 1.3
@export var crystal_col: Color = Color(0.55, 0.78, 0.98)
@export var soft_col: Color = Color(0.95, 0.55, 0.62)
@export var fluid_col: Color = Color(0.45, 0.70, 0.92)
@export var bench_col: Color = Color(0.16, 0.17, 0.20)
@export var pointer_col: Color = Color(0.98, 0.85, 0.40)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _bodies: Array = []     # each: { node:MeshInstance3D, stiff:float, base:Vector3, phase:float }
var _pointer: Node3D = null
var _top: float = 0.86
var _row_y: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("bench_w"):
		bench_w = clampf(float(config["bench_w"]), 0.9, 1.8)
	if config.has("soft_col"):
		soft_col = _parse_color(config["soft_col"], soft_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_bodies.clear()
	_pointer = null
	_build()


func _build() -> void:
	# Bench.
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(bench_w + 0.2, 0.84, 0.6), _matte_mat(bench_col, 0.85)))
	_row_y = _top + 0.16

	# The dial rail the bodies sit along, with tick marks.
	add_child(_box(Vector3(0.0, _top + 0.01, 0.18), Vector3(bench_w, 0.02, 0.03), _steel_mat(Color(0.5, 0.5, 0.55))))
	for i in range(N_BODIES):
		var fx: float = float(i) / float(N_BODIES - 1)
		var x: float = lerpf(-bench_w * 0.45, bench_w * 0.45, fx)
		add_child(_box(Vector3(x, _top + 0.03, 0.18), Vector3(0.008, 0.04, 0.02), _matte_mat(Color(0.6, 0.6, 0.65), 0.5)))

		# stiff = 1.0 at left (crystal), 0.0 at right (fluid). Aliveness peaks at 0.5.
		var stiff: float = 1.0 - fx
		var col: Color = _state_color(stiff)
		var base := Vector3(x, _row_y, 0.0)
		var body := _sphere(base, 0.07, _glow_mat(col, 0.55))
		add_child(body)
		_bodies.append({ "node": body, "stiff": stiff, "base": base, "phase": _rng.randf() * TAU })

	# Axis end-labels.
	add_child(_billboard_label("CRYSTAL", Vector3(-bench_w * 0.45, _top - 0.02, 0.18), 11, crystal_col))
	add_child(_billboard_label("PUDDLE", Vector3(bench_w * 0.45, _top - 0.02, 0.18), 11, fluid_col))
	add_child(_billboard_label("ALIVE", Vector3(0.0, _top - 0.02, 0.18), 12, soft_col))

	# Pointer that rides to the live middle.
	_pointer = Node3D.new()
	add_child(_pointer)
	var head := _box(Vector3(0.0, _row_y + 0.18, 0.0), Vector3(0.03, 0.1, 0.03), _glow_mat(pointer_col, 0.9))
	head.rotation.z = PI
	_pointer.add_child(head)
	_pointer.add_child(_box(Vector3(0.0, _row_y + 0.26, 0.0), Vector3(0.05, 0.05, 0.05), _glow_mat(pointer_col, 0.7)))

	add_child(_billboard_label("THE ALIVE MIDDLE OF THE STIFFNESS AXIS", Vector3(0.0, 1.6, 0.0), 17, label_col))


func _state_color(stiff: float) -> Color:
	# Blend crystal -> soft -> fluid across the axis.
	if stiff > 0.5:
		return crystal_col.lerp(soft_col, (1.0 - stiff) * 2.0)
	return soft_col.lerp(fluid_col, (0.5 - stiff) * 2.0)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	for b in _bodies:
		var node: MeshInstance3D = b["node"]
		var stiff: float = b["stiff"]
		var base: Vector3 = b["base"]
		var ph: float = b["phase"]
		# Aliveness = how much it jiggles. Bell curve peaking at the soft middle.
		var alive: float = exp(-pow((stiff - 0.5) / 0.28, 2.0))
		var jig: float = sin(_t * 3.2 + ph) * 0.03 * alive
		var bob: float = cos(_t * 2.5 + ph) * 0.02 * alive
		node.position = base + Vector3(0.0, bob, 0.0)
		# Crystal stays a tight sphere; fluid slumps flat; soft pulses round.
		if stiff > 0.85:
			node.scale = Vector3.ONE                      # frozen
		elif stiff < 0.15:
			node.scale = Vector3(1.4, 0.45, 1.4)          # slumped puddle
		else:
			var s: float = 1.0 + jig * 6.0
			node.scale = Vector3(s, 2.0 - s, s)           # breathing
	# Pointer drifts toward the live centre, lingering there.
	if _pointer != null:
		var sway: float = sin(_t * 0.6) * 0.18 * bench_w * 0.5
		_pointer.position.x = lerpf(_pointer.position.x, sway, 0.08)
