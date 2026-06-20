extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EnergyLandscapeBench

## @identity
## name: "Settling: gradient descent toward max Q"
## tier: medium
## lineage: the bowl, generalised to a wrinkled surface — many basins, each a possible rest
##   state; height is energy, so the low places are the stable ones.
## essence: A bench-top wavy landscape, ~0.6m, where height means energy. A soft body is
##   dropped onto the hills and rolls. It does not find the deepest valley on the map — only
##   the nearest one downhill from where it landed. The basin it ends in is its answer: a
##   local minimum, reached by following the slope, not by surveying the whole terrain.
## truth: "IT FINDS THE NEAREST VALLEY, NOT THE DEEPEST" — descent is local, not global
## applications: training, annealing, protein folding — landscapes with many rest states.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var grid: int = 22
@export var span: float = 0.62
@export var amp: float = 0.09
@export var blob_size: float = 0.14
@export var low_col: Color = Color(0.22, 0.30, 0.55)
@export var high_col: Color = Color(0.85, 0.55, 0.95)
@export var blob_col: Color = Color(0.95, 0.85, 0.40)
@export var base_col: Color = Color(0.16, 0.17, 0.20)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _sway: Node3D = null
var _sim = null
var _blob_mm: MultiMesh = null
var _blob_holder: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("grid"):
		grid = clampi(int(config["grid"]), 10, 40)
	if config.has("span"):
		span = float(config["span"])
	if config.has("amp"):
		amp = clampf(float(config["amp"]), 0.03, 0.18)
	if config.has("blob_col"):
		blob_col = _parse_color(config["blob_col"], blob_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway = null
	_sim = null
	_blob_mm = null
	_blob_holder = null
	_build()


func _energy(x: float, z: float) -> float:
	# Wavy landscape — two sine ridges crossed; a few basins of varying depth.
	return amp * (sin(x * 9.0) * 0.6 + cos(z * 7.0) * 0.5 + sin((x + z) * 5.0) * 0.4)


func _landscape_mesh() -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	mm.mesh = bm
	var count: int = grid * grid
	mm.instance_count = count
	var cell: float = span / float(grid)
	var idx: int = 0
	var lo: float = INF
	var hi: float = -INF
	# First pass for colour range.
	for gz in range(grid):
		for gx in range(grid):
			var x: float = (float(gx) / float(grid - 1) - 0.5) * span
			var z: float = (float(gz) / float(grid - 1) - 0.5) * span
			var h: float = _energy(x, z)
			lo = minf(lo, h)
			hi = maxf(hi, h)
	for gz in range(grid):
		for gx in range(grid):
			var x: float = (float(gx) / float(grid - 1) - 0.5) * span
			var z: float = (float(gz) / float(grid - 1) - 0.5) * span
			var h: float = _energy(x, z)
			var col_t: float = (h - lo) / maxf(hi - lo, 1e-4)
			var xf := Transform3D(Basis().scaled(Vector3(cell * 0.95, 0.02, cell * 0.95)), Vector3(x, h, z))
			mm.set_instance_transform(idx, xf)
			mm.set_instance_color(idx, low_col.lerp(high_col, col_t))
			idx += 1
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.2 if emissive else 0.0
	mi.material_override = mat
	return mi


func _make_sim() -> void:
	# A small jelly dropped off-centre so it rolls into a nearby basin.
	var sim = SBShapes.make_jelly_grid(2, 2, 2, blob_size * 0.5, 0.7)
	sim.gravity = Vector3(0.0, -3.5, 0.0)
	sim.damping = 0.96
	sim.floor_y = -10.0
	# Offset it onto a slope.
	for i in sim.positions.size():
		sim.positions[i] += Vector3(span * 0.22, 0.2, -span * 0.18)
		sim.prev_positions[i] = sim.positions[i]
	_sim = sim


func _build() -> void:
	# Bench base + pillar
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.1, 0.2, 0.7), _matte_mat(base_col, 0.85)))
	add_child(_cylinder(Vector3(0.0, 0.45, 0.0), 0.07, 0.5, _steel_mat(Color(0.34, 0.36, 0.40))))

	var sway := Node3D.new()
	sway.name = "LandscapeSway"
	add_child(sway)
	_sway = sway

	# Landscape sits on top of the pillar.
	var land := _landscape_mesh()
	land.position = Vector3(0.0, 0.86, 0.0)
	sway.add_child(land)

	# Soft body as a live MultiMesh; constrained to ride the surface each frame.
	_make_sim()
	_blob_holder = Node3D.new()
	_blob_holder.position = Vector3(0.0, 0.86, 0.0)
	sway.add_child(_blob_holder)
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = blob_size * 0.28
	sm.height = blob_size * 0.56
	mm.mesh = sm
	mm.instance_count = _sim.positions.size()
	_blob_mm = mm
	mmi.multimesh = mm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = blob_col
	bmat.roughness = 0.4
	bmat.emission_enabled = true
	bmat.emission = blob_col
	bmat.emission_energy_multiplier = 0.35 if emissive else 0.0
	mmi.material_override = bmat
	_blob_holder.add_child(mmi)
	_settle_blob_to_surface()
	_refresh_blob()

	add_child(_billboard_label("IT FINDS THE NEAREST VALLEY, NOT THE DEEPEST", Vector3(0.0, 1.6, 0.0), 22, label_col))


func _settle_blob_to_surface() -> void:
	# Pre-roll the blob so the snapshot already sits in a basin.
	for _i in 90:
		_constrain_to_surface()
		_sim.step()


func _constrain_to_surface() -> void:
	# Each particle cannot sink below the landscape height at its (x,z).
	for i in _sim.positions.size():
		var p: Vector3 = _sim.positions[i]
		var floor_h: float = _energy(p.x, p.z) + blob_size * 0.28
		if p.y < floor_h:
			_sim.positions[i].y = floor_h
			# Gentle downhill nudge so it slides toward lower energy (gradient).
			var gx: float = (_energy(p.x + 0.01, p.z) - _energy(p.x - 0.01, p.z)) / 0.02
			var gz: float = (_energy(p.x, p.z + 0.01) - _energy(p.x, p.z - 0.01)) / 0.02
			_sim.positions[i].x -= gx * 0.0008
			_sim.positions[i].z -= gz * 0.0008


func _refresh_blob() -> void:
	if _blob_mm == null:
		return
	for i in _sim.positions.size():
		var t := Transform3D.IDENTITY
		t.origin = _sim.positions[i]
		_blob_mm.set_instance_transform(i, t)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sim != null:
		_constrain_to_surface()
		_sim.step()
		_refresh_blob()
	if _sway != null:
		_sway.rotation.y = sin(_t * 0.3) * 0.12
