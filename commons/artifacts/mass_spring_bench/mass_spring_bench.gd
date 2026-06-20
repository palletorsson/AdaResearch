extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MassSpringBench

## @identity
## name: "Mass-spring networks"
## tier: medium
## lineage: the lattice from the toy — a whole grid of Hooke springs, no shape authored
## essence: A bench-top grid of masses and springs, ~0.6m of jelly, sitting on a pillar.
##   Nobody modelled its form. We placed nodes on a lattice, wired each to its neighbours,
##   and let gravity and the springs argue. The shape it settles into — the slump, the bulge —
##   is what the network agrees on. The springs are drawn as thin wires so you see the net.
## truth: "NOBODY MODELLED THIS SHAPE — THE SPRINGS DID" — form emerges from the lattice
## applications: cloth, soft robots, deformable props — model the connections, not the surface.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var nx: int = 4
@export var ny: int = 3
@export var nz: int = 4
@export var cell: float = 0.16
@export var stiffness: float = 0.6
@export var pre_steps: int = 80
@export var body_col: Color = Color(0.92, 0.45, 0.58)
@export var wire_col: Color = Color(0.30, 0.85, 0.95)
@export var base_col: Color = Color(0.16, 0.17, 0.20)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _sway: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("nx"):
		nx = clampi(int(config["nx"]), 2, 6)
	if config.has("ny"):
		ny = clampi(int(config["ny"]), 2, 5)
	if config.has("nz"):
		nz = clampi(int(config["nz"]), 2, 6)
	if config.has("stiffness"):
		stiffness = clampf(float(config["stiffness"]), 0.2, 0.95)
	if config.has("body_col"):
		body_col = _parse_color(config["body_col"], body_col)
	if config.has("wire_col"):
		wire_col = _parse_color(config["wire_col"], wire_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway = null
	_build()


func _build() -> void:
	# Bench base + pillar (medium tier staging)
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.1, 0.2, 0.7), _matte_mat(base_col, 0.85)))
	add_child(_cylinder(Vector3(0.0, 0.45, 0.0), 0.07, 0.5, _steel_mat(Color(0.34, 0.36, 0.40))))
	# A thin tray the jelly rests on
	add_child(_box(Vector3(0.0, 0.84, 0.0), Vector3(nx * cell + 0.2, 0.02, nz * cell + 0.2), _matte_mat(Color(0.22, 0.23, 0.27), 0.7)))

	var sway := Node3D.new()
	sway.name = "JellySway"
	add_child(sway)
	_sway = sway

	# Build a jelly lattice and let it settle — the shape nobody specified.
	var sim = SBShapes.make_jelly_grid(nx, ny, nz, cell, stiffness)
	# Rest it on the tray, not on the engine's far-down floor.
	sim.floor_y = 0.0
	sim.gravity = Vector3(0.0, -4.5, 0.0)
	sim.damping = 0.985
	# Give a tiny asymmetric tilt so it slumps to one side — visible disagreement.
	for i in sim.positions.size():
		sim.positions[i] += Vector3(_rng.randf_range(-0.01, 0.01), 0.0, _rng.randf_range(-0.01, 0.01))
		sim.prev_positions[i] = sim.positions[i]
	for _i in pre_steps:
		sim.step()

	# Snapshot node: spheres at masses + thin wires along springs (show the net).
	var node: Node3D = SBShapes.to_node3d(sim, {
		"color": [body_col.r, body_col.g, body_col.b],
		"show_wires": true,
		"wire_color": [wire_col.r, wire_col.g, wire_col.b],
		"particle_radius": 0.03,
		"roughness": 0.45,
	})
	# Lift the settled body up onto the tray surface.
	node.position = Vector3(0.0, 0.86, 0.0)
	sway.add_child(node)

	add_child(_billboard_label("NOBODY MODELLED THIS SHAPE — THE SPRINGS DID", Vector3(0.0, 1.6, 0.0), 22, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sway != null:
		_sway.rotation.y = sin(_t * 0.35) * 0.14
