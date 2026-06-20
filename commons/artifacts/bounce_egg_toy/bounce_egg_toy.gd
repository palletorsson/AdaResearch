extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BounceEggToy

## @identity
## name: "Bounce & play"
## tier: small
## lineage: A little jelly cube as a bouncing egg — drop it, the floor constraint squashes
##   the lower particles, the springs store that squash and fling it back up.
## essence: A held squishy egg, ~0.4m, that bounces and squashes in your hand. Each landing
##   flattens it; the springs hold the impact for an instant, then give it all back as the next
##   hop. Nothing breaks — the deformation is the whole trick. A toy you can keep in one hand.
## truth: "SQUASH ON LANDING, SPRING ON THE WAY UP — IT KEEPS WHAT IT HITS"
## applications: bouncy balls, hopping toys, impact cushions — energy stored in a squash, returned as a hop.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var egg_size: float = 0.18
@export var stiffness: float = 0.9
@export var hop_height: float = 0.16
@export var egg_col: Color = Color(0.96, 0.78, 0.32)
@export var shell_col: Color = Color(0.99, 0.90, 0.55)
@export var label_col: Color = Color(0.95, 0.92, 0.80)

var _t: float = 0.0
var _sim = null
var _mm: MultiMesh = null
var _egg_node: Node3D = null
var _floor_y: float = 0.04


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("egg_size"):
		egg_size = clampf(float(config["egg_size"]), 0.12, 0.26)
	if config.has("stiffness"):
		stiffness = clampf(float(config["stiffness"]), 0.6, 0.97)
	if config.has("hop_height"):
		hop_height = clampf(float(config["hop_height"]), 0.08, 0.24)
	if config.has("egg_col"):
		egg_col = _parse_color(config["egg_col"], egg_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sim = null
	_mm = null
	_egg_node = null
	_build()


func _build() -> void:
	# A small dish so the egg has somewhere to land — held-scale, no table.
	add_child(_cylinder(Vector3(0.0, 0.02, 0.0), egg_size * 1.4, 0.04, _matte_mat(shell_col, 0.5)))

	var sim = SBShapes.make_jelly_box(egg_size, stiffness)
	sim.floor_y = _floor_y
	sim.gravity = Vector3(0.0, -3.0, 0.0)
	sim.damping = 0.94
	_sim = sim
	# Pre-settle so the capture shows a relaxed, slightly-squashed egg at rest.
	for _i in 40:
		_sim.step()

	_egg_node = Node3D.new()
	add_child(_egg_node)

	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = egg_size * 0.42
	sm.height = egg_size * 0.84
	sm.radial_segments = 10
	sm.rings = 6
	mm.mesh = sm
	mm.instance_count = _sim.positions.size()
	_mm = mm
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = egg_col
	mat.roughness = 0.35
	mat.emission_enabled = true
	mat.emission = egg_col
	mat.emission_energy_multiplier = 0.4 if emissive else 0.0
	mmi.material_override = mat
	_egg_node.add_child(mmi)
	_refresh_egg()

	add_child(_billboard_label("SQUASH ON LANDING, SPRING ON THE WAY UP", Vector3(0.0, egg_size * 2.4 + 0.18, 0.0), 14, label_col))


func _refresh_egg() -> void:
	if _mm == null:
		return
	for i in _sim.positions.size():
		var t := Transform3D.IDENTITY
		t.origin = _sim.positions[i]
		_mm.set_instance_transform(i, t)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sim == null:
		return
	# Drive a bounce: lift the egg on a sine, then let it fall and squash on the floor.
	var phase: float = fmod(_t, 1.4) / 1.4
	# Toss energy: at the top of each cycle, give the particles upward velocity by
	# nudging prev_positions down (Verlet velocity = pos - prev).
	if phase < 0.04:
		for i in _sim.positions.size():
			_sim.prev_positions[i].y = _sim.positions[i].y - hop_height * 0.12
	_sim.step()
	# Floor constraint already squashes lower particles; springs store + return it.
	_refresh_egg()
	# Subtle hand-held sway so a held toy reads as alive even between bounces.
	if _egg_node != null:
		_egg_node.rotation.z = sin(_t * 1.6) * 0.05
