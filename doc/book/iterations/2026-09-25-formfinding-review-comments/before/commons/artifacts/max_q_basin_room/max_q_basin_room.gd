extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MaxQBasinRoom

## @identity
## name: "Two staged responses: a Q interpretation"
## tier: large
## lineage: two wells side by side with deliberately different receivers. The narrow well
##   contains a static mesh cube; the broad well displays a Verlet lattice driven by periodic
##   random displacements and a separate floor constraint. Neither implements a shared Q objective.
## essence: Compare the staged responses, then consider the proposition that the desired form
##   need not have the lowest score. The optional reveal delays the alive/dead interpretation.
## truth: "MAX Q IS THE LIVELIEST MINIMUM, NOT THE DEEPEST" is this work's proposal,
##   not a measured Q value or a test separating living matter from dead matter.
## applications: asking which responses a model values, and which conditions its author supplies.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

# The wells hang DOWN from a rim, but the grid auto-grounds every artifact by its lowest
# vertex. Built with the rim at y=0 the room was lifted 2.25 m and its floor became a lid
# floating over the hall's walls. So the rim stands on an open tank at deck_h — below a
# standing eye, so you look down into both wells — and the whole body starts at y=0.
@export var floor_size: float = 5.0
@export var deck_h: float = 1.05
@export var dead_x: float = -1.5
@export var alive_x: float = 0.8
@export var dead_depth: float = 0.95   # deep and narrow
@export var alive_depth: float = 0.30  # shallow and wide (the original 2.2 : 0.7 ratio)
@export var dead_rim: float = 0.7
@export var alive_rim: float = 1.6
@export var floor_col: Color = Color(0.12, 0.13, 0.16)
@export var dead_col: Color = Color(0.40, 0.42, 0.50)
@export var alive_col: Color = Color(0.50, 0.95, 0.65)
@export var live_body_col: Color = Color(0.55, 0.95, 0.70)
@export var label_col: Color = Color(0.86, 0.92, 0.98)
## Opt-in comparison before the Q interpretation; other placements keep their original labels.
@export var reveal_on_request: bool = false

var _t: float = 0.0
var _sim = null
var _live_mm: MultiMesh = null
var _live_holder: Node3D = null
var _alive_center: Vector3 = Vector3.ZERO
var _interpretation_visible := false
var _interpretation_button: Node3D
var _interpretation_title: Label3D
var _deep_label: Label3D
var _shallow_label: Label3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("floor_size"):
		floor_size = float(config["floor_size"])
	if config.has("alive_col"):
		alive_col = _parse_color(config["alive_col"], alive_col)
	if config.has("dead_col"):
		dead_col = _parse_color(config["dead_col"], dead_col)
	if config.has("reveal_on_request"):
		reveal_on_request = str(config["reveal_on_request"]).to_lower() in ["true", "1"]
	if not is_node_ready():
		return
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sim = null
	_live_mm = null
	_live_holder = null
	_interpretation_button = null
	_build()


func _well_mesh(center: Vector3, rim_radius: float, depth: float, narrow: bool, col: Color) -> MeshInstance3D:
	# A funnel of stacked rings — a basin in the floor. narrow = steep pit, wide = gentle bowl.
	var segs: int = 30
	var bands: int = 9
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for b in range(bands + 1):
		var f: float = float(b) / float(bands)             # 0 rim -> 1 bottom
		var rr: float = rim_radius * (1.0 - f)
		# narrow well drops fast (f^0.5 steep walls); wide well is a soft parabola (f^2)
		var depth_f: float = (sqrt(f) if narrow else (f * f))
		var y: float = -depth * depth_f
		for s in range(segs + 1):
			var th: float = (float(s) / float(segs)) * TAU
			verts.append(center + Vector3(rr * cos(th), y, rr * sin(th)))
			normals.append(Vector3.UP)
	var stride: int = segs + 1
	for b in range(bands):
		for s in range(segs):
			var i0: int = b * stride + s
			var i1: int = b * stride + s + 1
			var i2: int = (b + 1) * stride + s + 1
			var i3: int = (b + 1) * stride + s
			indices.append_array([i0, i1, i2, i0, i2, i3])
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	var mat := _matte_mat(col, 0.5, 0.2)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.25 if emissive else 0.0
	mi.material_override = mat
	return mi


func _build() -> void:
	# Open tank: four low walls, no lid, so the wells are seen from above.
	var tank_mat := _matte_mat(floor_col, 0.95, 0.1)
	var half: float = floor_size * 0.5
	var wall_t: float = 0.06
	for side in [-1.0, 1.0]:
		add_child(_box(Vector3(0.0, deck_h * 0.5, side * half), Vector3(floor_size, deck_h, wall_t), tank_mat))
		add_child(_box(Vector3(side * half, deck_h * 0.5, 0.0), Vector3(wall_t, deck_h, floor_size), tank_mat))

	# Everything below hangs from the rim; the soft-body sim works in this frame.
	var stage := Node3D.new()
	stage.position = Vector3(0.0, deck_h, 0.0)
	add_child(stage)

	# DEAD well — deep and narrow.
	var dead_c := Vector3(dead_x, 0.0, 0.0)
	stage.add_child(_well_mesh(dead_c, dead_rim, dead_depth, true, dead_col))
	# A static mesh at the bottom — one cube, never moving.
	stage.add_child(_box(dead_c + Vector3(0.0, -dead_depth * 0.82, 0.0), Vector3(0.28, 0.28, 0.28), _matte_mat(dead_col, 0.6, 0.4)))
	_deep_label = _billboard_label("", dead_c + Vector3(0.0, 1.0, 0.0), 18, Color(0.78, 0.80, 0.86))
	stage.add_child(_deep_label)

	# ALIVE well — shallow and wide.
	_alive_center = Vector3(alive_x, 0.0, 0.0)
	stage.add_child(_well_mesh(_alive_center, alive_rim, alive_depth, false, alive_col))
	_shallow_label = _billboard_label("", _alive_center + Vector3(0.0, 1.0, 0.0), 18, Color(0.70, 0.96, 0.78))
	stage.add_child(_shallow_label)

	# A soft body living in the alive well — live MultiMesh of particles.
	var sim = SBShapes.make_jelly_grid(3, 3, 3, 0.22, 0.55)
	sim.gravity = Vector3(0.0, -2.6, 0.0)
	sim.damping = 0.97
	sim.floor_y = -10.0
	for i in sim.positions.size():
		sim.positions[i] += _alive_center + Vector3(0.0, 0.6, 0.0)
		sim.prev_positions[i] = sim.positions[i]
	_sim = sim
	for _i in 60:
		_constrain_alive()
		_sim.step()

	_live_holder = Node3D.new()
	stage.add_child(_live_holder)
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var smesh := SphereMesh.new()
	smesh.radius = 0.11
	smesh.height = 0.22
	mm.mesh = smesh
	mm.instance_count = _sim.positions.size()
	_live_mm = mm
	mmi.multimesh = mm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = live_body_col
	bmat.roughness = 0.4
	bmat.emission_enabled = true
	bmat.emission = live_body_col
	bmat.emission_energy_multiplier = 0.4 if emissive else 0.0
	mmi.material_override = bmat
	_live_holder.add_child(mmi)
	_refresh_live()

	var title_h: float = deck_h + (1.6 if reveal_on_request else 2.0)
	_interpretation_title = _billboard_label("", Vector3(0.0, title_h, 0.0), 20 if reveal_on_request else 28, label_col)
	add_child(_interpretation_title)
	_interpretation_visible = not reveal_on_request
	_update_interpretation()
	if reveal_on_request:
		var presets = load("res://commons/ui/interface_presets.gd")
		var console: Node3D = presets.build("machine", "TWO WELLS")
		console.name = "InterpretationConsole"
		console.face_to_origin = false
		console.body_height = 0.85
		console.board_width = 0.9
		console.position = Vector3(-1.6, 0, floor_size * 0.5 + 0.4)
		add_child(console)
		console.add_readout("Compare the responses first")
		_interpretation_button = console.add_button("INTERPRET")
		_interpretation_button.pressed.connect(_toggle_interpretation)


func _toggle_interpretation() -> void:
	_interpretation_visible = not _interpretation_visible
	_update_interpretation()


func _update_interpretation() -> void:
	_deep_label.text = "DEAD WELL\ndeep · narrow · one frozen shape" if _interpretation_visible else "DEEP / NARROW"
	_shallow_label.text = "ALIVE WELL\nshallow · wide · keeps re-finding" if _interpretation_visible else "SHALLOW / WIDE"
	_interpretation_title.text = "MAX Q IS THE LIVELIEST MINIMUM, NOT THE DEEPEST" if _interpretation_visible else "Compare the two wells.\nWhat stays still; what keeps changing?"
	if reveal_on_request and _interpretation_visible:
		_interpretation_title.text += "\nA proposal about these staged responses, not a test of life.\nStatic mesh on one side; periodically driven lattice on the other."


func _alive_floor_h(x: float, z: float) -> float:
	# Wide shallow parabola centred on the alive well.
	var d := Vector2(x - _alive_center.x, z - _alive_center.z)
	var f: float = clampf(d.length() / alive_rim, 0.0, 1.0)
	return -alive_depth * (f * f) + 0.11


func _constrain_alive() -> void:
	for i in _sim.positions.size():
		var p: Vector3 = _sim.positions[i]
		var fh: float = _alive_floor_h(p.x, p.z)
		if p.y < fh:
			_sim.positions[i].y = fh
			# Slide toward the basin centre (downhill).
			var to_center := Vector2(_alive_center.x - p.x, _alive_center.z - p.z)
			_sim.positions[i].x += to_center.x * 0.0015
			_sim.positions[i].z += to_center.y * 0.0015


func _refresh_live() -> void:
	if _live_mm == null:
		return
	for i in _sim.positions.size():
		var t := Transform3D.IDENTITY
		t.origin = _sim.positions[i]
		_live_mm.set_instance_transform(i, t)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sim != null:
		# Periodic jostle — the alive body never finishes settling; it keeps re-finding.
		if fmod(_t, 2.5) < delta:
			for i in _sim.positions.size():
				_sim.positions[i] += Vector3(_rng.randf_range(-0.08, 0.08), _rng.randf_range(0.02, 0.12), _rng.randf_range(-0.08, 0.08))
		_constrain_alive()
		_sim.step()
		_refresh_live()
