extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ElasticityPress

## @identity
## name: "Strain, pressure & elasticity"
## tier: applied
## lineage: Hooke's spring as a stored-energy bank — squeeze it and the work you do is held
##   as strain energy (½kx²); release and it pays back, springing to its rest shape.
## essence: A press, ~1m, with a plate descending onto a soft jelly block. As the plate
##   compresses the block, a strain-energy readout climbs — energy is being banked in the
##   springs. At the bottom the plate lifts, the block springs back, and the readout falls
##   to zero. Elasticity is a battery: deformation in, recovery out, nothing lost to the floor.
## truth: "SQUEEZE STORES ENERGY, RELEASE RETURNS IT — ELASTICITY IS A BATTERY"
## applications: shock absorbers, trampolines, tendons, springs — work stored and given back.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var block_size: float = 0.5
@export var stiffness: float = 0.85
@export var press_period: float = 4.0
@export var block_col: Color = Color(0.95, 0.55, 0.40)
@export var plate_col: Color = Color(0.55, 0.58, 0.64)
@export var frame_col: Color = Color(0.20, 0.21, 0.25)
@export var readout_col: Color = Color(0.98, 0.78, 0.45)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _sim = null
var _block_node: Node3D = null
var _spheres_mm: MultiMesh = null
var _plate: MeshInstance3D = null
var _readout: Label3D = null
var _block_top0: float = 0.0
var _plate_x: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("block_size"):
		block_size = clampf(float(config["block_size"]), 0.3, 0.8)
	if config.has("stiffness"):
		stiffness = clampf(float(config["stiffness"]), 0.4, 0.97)
	if config.has("press_period"):
		press_period = clampf(float(config["press_period"]), 2.0, 8.0)
	if config.has("block_col"):
		block_col = _parse_color(config["block_col"], block_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sim = null
	_block_node = null
	_spheres_mm = null
	_plate = null
	_readout = null
	_build()


func _make_sim() -> void:
	var sim = SBShapes.make_jelly_grid(3, 3, 3, block_size * 0.5, stiffness)
	sim.floor_y = 0.0
	sim.gravity = Vector3(0.0, -2.0, 0.0)
	sim.damping = 0.9
	_sim = sim
	for _i in 30:
		_sim.step()
	# Remember the resting top so we can measure compression later.
	_block_top0 = _block_top()


func _block_top() -> float:
	var top: float = -INF
	for i in _sim.positions.size():
		top = maxf(top, _sim.positions[i].y)
	return top


func _build() -> void:
	# Press frame: base, two posts, top beam (the applied device)
	add_child(_box(Vector3(0.0, 0.04, 0.0), Vector3(0.9, 0.08, 0.7), _matte_mat(frame_col, 0.8)))
	add_child(_cylinder_between(Vector3(-0.38, 0.08, -0.0), Vector3(-0.38, 1.05, 0.0), 0.035, _steel_mat(Color(0.4, 0.42, 0.46))))
	add_child(_cylinder_between(Vector3(0.38, 0.08, 0.0), Vector3(0.38, 1.05, 0.0), 0.035, _steel_mat(Color(0.4, 0.42, 0.46))))
	add_child(_box(Vector3(0.0, 1.08, 0.0), Vector3(0.86, 0.08, 0.3), _matte_mat(frame_col, 0.8)))

	_make_sim()

	# Soft block as a live MultiMesh of particle spheres (no per-frame geometry rebuild).
	_block_node = Node3D.new()
	_block_node.position = Vector3(0.0, 0.08, 0.0)
	add_child(_block_node)

	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = block_size * 0.16
	sm.height = block_size * 0.32
	mm.mesh = sm
	mm.instance_count = _sim.positions.size()
	_spheres_mm = mm
	mmi.multimesh = mm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = block_col
	bmat.roughness = 0.45
	bmat.emission_enabled = true
	bmat.emission = block_col
	bmat.emission_energy_multiplier = 0.3 if emissive else 0.0
	mmi.material_override = bmat
	_block_node.add_child(mmi)
	_refresh_block()

	# The descending plate
	_plate = _box(Vector3(0.0, 0.08 + _block_top0 + 0.05, 0.0), Vector3(block_size + 0.18, 0.05, block_size + 0.18), _steel_mat(plate_col))
	add_child(_plate)

	# Readout panel
	add_child(_box(Vector3(0.52, 0.6, 0.2), Vector3(0.34, 0.2, 0.02), _matte_mat(Color(0.10, 0.11, 0.14), 0.4)))
	_readout = _billboard_label(_readout_text(0.0), Vector3(0.52, 0.6, 0.22), 16, readout_col)
	add_child(_readout)

	add_child(_billboard_label("SQUEEZE STORES ENERGY, RELEASE RETURNS IT", Vector3(0.0, 1.5, 0.0), 20, label_col))


func _refresh_block() -> void:
	if _spheres_mm == null:
		return
	for i in _sim.positions.size():
		var t := Transform3D.IDENTITY
		t.origin = _sim.positions[i]
		_spheres_mm.set_instance_transform(i, t)


func _readout_text(energy: float) -> String:
	return "STRAIN ENERGY\nU = %.3f J\n(banked in the springs)" % energy


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sim == null:
		return

	# Plate cycles down (compress) then up (release).
	var phase: float = fmod(_t, press_period) / press_period
	var press_amt: float = 0.0
	if phase < 0.5:
		press_amt = (phase / 0.5)                  # 0 -> 1 squeeze
	else:
		press_amt = (1.0 - (phase - 0.5) / 0.5)    # 1 -> 0 release
	# Ease for a soft mechanical feel.
	press_amt = press_amt * press_amt * (3.0 - 2.0 * press_amt)

	var travel: float = block_size * 0.45
	var plate_y_local: float = _block_top0 + 0.05 - press_amt * travel
	if _plate != null:
		_plate.position.y = 0.08 + plate_y_local

	# Push the top particles down to follow the plate; let springs distribute the squeeze.
	var ceil_y: float = plate_y_local - 0.02
	for i in _sim.positions.size():
		if _sim.positions[i].y > ceil_y:
			_sim.positions[i].y = ceil_y
	_sim.step()
	_refresh_block()

	# Strain energy ~ how far the block is compressed from rest (½ k x²).
	var compression: float = maxf(_block_top0 - _block_top(), 0.0)
	var energy: float = 0.5 * (stiffness * 60.0) * compression * compression
	if _readout != null:
		_readout.text = _readout_text(energy)
