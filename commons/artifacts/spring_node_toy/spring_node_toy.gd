extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SpringNodeToy

## @identity
## name: "Mass-spring networks"
## tier: small
## lineage: Hooke's law made physical — two masses, one spring, the atom of every soft body
## essence: A held two-mass-one-spring, ~0.4m across. One node hangs, the other is pinned;
##   the spring between them pulls toward its rest length, overshoots, settles. This single
##   pair is the unit cell. A jelly, a cloth, a face — all of them are just this, repeated.
## truth: "A SOFT BODY IS JUST THIS, MANY TIMES" — one spring pulling toward rest, copied
## applications: cloth, hair, muscle, jelly — every deformable thing is a network of these.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var span: float = 0.40
@export var rest_len: float = 0.22
@export var node_radius: float = 0.045
@export var anchor_col: Color = Color(0.55, 0.58, 0.64)
@export var node_col: Color = Color(0.95, 0.45, 0.55)
@export var spring_col: Color = Color(0.55, 0.85, 0.95)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _sway: Node3D = null
var _sim = null
var _free_idx: int = 1
var _pinned_idx: int = 0
var _spring_wire: MeshInstance3D = null
var _free_node: MeshInstance3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("span"):
		span = float(config["span"])
	if config.has("rest_len"):
		rest_len = float(config["rest_len"])
	if config.has("node_col"):
		node_col = _parse_color(config["node_col"], node_col)
	if config.has("spring_col"):
		spring_col = _parse_color(config["spring_col"], spring_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway = null
	_sim = null
	_spring_wire = null
	_free_node = null
	_build()


func _make_sim() -> void:
	# Hand-built unit cell: one pinned anchor on top, one free mass below.
	var sim = SBShapes.SoftBodySimScript.new()
	sim.topology = "generic"
	sim.stiffness = 0.35
	sim.gravity = Vector3(0.0, -2.2, 0.0)
	sim.damping = 0.97
	sim.floor_y = -span
	var top: Vector3 = Vector3(0.0, span * 0.5, 0.0)
	_pinned_idx = sim.add_particle(top, true)
	# Start the free node stretched out so the spring visibly pulls it home.
	var start: Vector3 = top + Vector3(0.06, -span * 0.95, 0.0)
	_free_idx = sim.add_particle(start, false)
	sim.add_spring(_pinned_idx, _free_idx, rest_len)
	_sim = sim
	# Pre-settle once so the capture shows a relaxed, near-rest pose.
	for _i in 40:
		_sim.step()


func _refresh_geometry() -> void:
	var a: Vector3 = _sim.positions[_pinned_idx]
	var b: Vector3 = _sim.positions[_free_idx]
	if _free_node != null:
		_free_node.position = b
	if _spring_wire != null:
		_spring_wire.transform = Transform3D(_basis_y_to(b - a), (a + b) * 0.5)
		var mesh := _spring_wire.mesh as CylinderMesh
		mesh.height = maxf(a.distance_to(b), 0.001)


func _build() -> void:
	# Held housing — a small handle so it reads as a desk toy, not a floating sim.
	add_child(_box(Vector3(0.0, -span * 0.62, 0.0), Vector3(span * 0.7, 0.05, span * 0.32), _steel_mat(Color(0.30, 0.32, 0.37))))
	add_child(_cylinder(Vector3(0.0, -span * 0.5, 0.0), 0.018, span * 0.3, _matte_mat(Color(0.40, 0.42, 0.47), 0.5)))

	var sway := Node3D.new()
	sway.name = "SpringSway"
	add_child(sway)
	_sway = sway

	_make_sim()
	var a: Vector3 = _sim.positions[_pinned_idx]
	var b: Vector3 = _sim.positions[_free_idx]

	# Pinned anchor (top, fixed)
	sway.add_child(_sphere(a, node_radius * 0.9, _matte_mat(anchor_col, 0.35, 0.5)))
	# A little ceiling bracket above the anchor
	sway.add_child(_box(a + Vector3(0.0, node_radius + 0.01, 0.0), Vector3(span * 0.34, 0.02, span * 0.18), _matte_mat(anchor_col, 0.5)))

	# Spring drawn as a single cylinder (the rest-length bond)
	_spring_wire = _cylinder_between(a, b, 0.012, _glow_mat(spring_col, 1.4))
	sway.add_child(_spring_wire)

	# Free mass (the moving node)
	_free_node = _sphere(b, node_radius, _glow_mat(node_col, 1.2))
	sway.add_child(_free_node)

	add_child(_billboard_label("A SOFT BODY IS JUST THIS, MANY TIMES", Vector3(0.0, span * 0.85, 0.0), 18, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Keep the unit cell gently alive — a tiny periodic nudge, then let it settle.
	if _sim != null:
		if fmod(_t, 3.0) < delta:
			_sim.positions[_free_idx] += Vector3(_rng.randf_range(-0.05, 0.05), -0.05, _rng.randf_range(-0.03, 0.03))
		_sim.step()
		_refresh_geometry()
	if _sway != null:
		_sway.rotation.y = sin(_t * 0.4) * 0.18
