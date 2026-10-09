# perlin_terrain_sculptor.gd
# Voxel sculpture tool where Perlin noise is the brush
# VR-enabled with slider controls

# @identity
# essence: voxel_on[pos] = noise_3d(pos × frequency) > threshold — a 24³ grid that thresholds Perlin noise, with VR sliders broadcasting changes to linked voxelnoise receivers
# desire: to sculpt with mathematics — to move a VR slider and feel the threshold of existence rise through a landscape of cubes, watching matter emerge and dissolve at your hand
# critical_parameter: threshold — the cut-plane through the noise field; at -1.0 everything is solid, at 1.0 everything is void, and interesting terrain lives between -0.3 and 0.3
# triggers: noise_scale changes restructure what frequencies create terrain features; octaves add detail without changing the overall scale; dragging sliders broadcasts payload to voxelnoise peers via signal
# emerges: the learner discovers that sculpting with noise parameters is fundamentally different from sculpting with geometry — you are not placing matter, you are choosing which noise values count as matter
# needs: threshold slider [has] (slider_horizontal); noise_scale slider [has]; octaves slider [has]; push button for regenerate [has]; info Label3D [has]
# relationships: broadcasts terrain_controls_changed to voxelnoise receivers; paired with voxelnoise in Noise_Voxel map; contrasts with direct mesh sculpting
# truth: noise-based sculpting inverts the usual creative act — instead of adding form, you reveal it by moving the threshold through a pre-existing mathematical landscape

extends Node3D

class_name PerlinTerrainSculptor

signal terrain_controls_changed(payload: Dictionary)

## Grid dimensions
@export var grid_size: int = 24
@export var voxel_size: float = 0.04

## Noise parameters
@export_group("Noise")
@export var noise_scale: float = 4.0:
	set(value):
		noise_scale = clampf(value, 0.5, 20.0)
		if _noise:
			_noise.frequency = noise_scale * 0.1
		_generate_terrain()
		_sync_scale_slider()
		_broadcast_controls_to_voxelnoise()

@export var noise_octaves: int = 3:
	set(value):
		noise_octaves = clampi(value, 1, 6)
		if _noise:
			_noise.fractal_octaves = noise_octaves
		_generate_terrain()
		_broadcast_controls_to_voxelnoise()

@export var threshold: float = 0.0:
	set(value):
		threshold = clampf(value, -1.0, 1.0)
		_generate_terrain()
		_sync_threshold_slider()
		_update_info()
		_broadcast_controls_to_voxelnoise()

## Colors
@export var voxel_color: Color = Color(0.3, 0.7, 0.4)
@export var height_gradient: bool = true

# ── THE CONTRACT (stand:lattice) — N4, 12 September 2026 ────────────────────
#
# WHEN DOES A VALUE BECOME A PLACE A BODY CAN OCCUPY? This bench and the voxel
# terrain across the room were already linked — and the link passed CONTROL
# VALUES, not samples: the bench sampled Perlin at its own coordinates with a
# height bias, the receiver sampled its own noise at world integers with its own
# iso level, and a room could say the two were "the same field" only by not
# looking. So the sampler is written down here, once, as four static functions,
# and both displays go through them.
#
#   contract_noise(seed, scale, octaves)      the basis: Perlin, fbm
#   contract_value(noise, u, v, w)            the coordinates, from a NORMALISED
#                                             position, so a small model and a
#                                             large terrain sample one field
#   contract_bias(v)                          the height bias, kept and named
#   contract_occupied(value, v, threshold)    the predicate, greater-than
#
# THE SCALE RELATIONSHIP IS DECLARED AND TRUE: both displays take (u, v, w) in
# [0,1] across their own extent and multiply by CONTRACT_SPAN. The bench is a
# magnified model of the same volume the terrain fills, cell for cell.
#
#   stand:none     SHIPPED. _generate_terrain keeps its own maths exactly, the
#                  eighteen existing placements sample what they sampled, and
#                  the receiver keeps its legacy linked behaviour.
#   stand:lattice  The bench takes the contract, names a five-digit seed, and
#                  stands a plate that reads ONE selected cell: its coordinate,
#                  the field's value there, the height bias, the threshold, and
#                  the decision those four make together. THRESHOLD moves at a
#                  fixed seed; CELL walks the selection; CUT opens the lattice.
#
# AND THE BROADCAST IS SCOPED. `call_group("voxelnoise_receivers", …)` reaches
# every receiver in the tree, which in a streaming museum means other halls: a
# visitor turning this threshold was retuning a terrain two rooms away. It is
# filtered to receivers under this body's own hall now.
const CONTRACT_SPAN: float = 9.6        # the field's extent, shared by both displays
const CONTRACT_BIAS_SCALE: float = 0.5  # the height bias, as shipped
const LATTICE_THRESHOLDS: Array = [-0.20, -0.10, 0.00, 0.10, 0.20]

@export_enum("none", "lattice") var stand: String = "none"
@export var lattice_seed: int = -1

var _lattice_root: Node3D = null
var _lattice_readout: Label3D = null
var _cell: Vector3i = Vector3i(12, 12, 12)
var _threshold_i: int = 2
var _named_seed: int = 0
var _cut: bool = false
var _last_rebuild_ms: float = 0.0
var _rebuilds: int = 0


## The basis. One noise, made one way, from a named number.
static func contract_noise(seed_value: int, scale: float, octaves: int) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_PERLIN
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.frequency = scale * 0.1
	n.fractal_octaves = octaves
	n.seed = seed_value
	return n


## The coordinates. u, v, w are the position INSIDE the display, 0 to 1, so a
## 24-cell model and a 32-cell terrain ask the field the same question.
static func contract_value(n: FastNoiseLite, u: float, v: float, w: float) -> float:
	if n == null:
		return 0.0
	return n.get_noise_3d(u * CONTRACT_SPAN, v * CONTRACT_SPAN, w * CONTRACT_SPAN)


## The height bias: the shipped one, named. Lower cells are helped, upper cells
## hindered, which is what makes a terrain rather than a cloud.
static func contract_bias(v: float) -> float:
	return (v - 0.5) * CONTRACT_BIAS_SCALE


## The predicate. Greater-than, and nothing else — which is why raising the
## threshold can only ever take cells away.
static func contract_occupied(value: float, v: float, threshold: float) -> bool:
	return value - contract_bias(v) > threshold

var _voxels: Array = []
var _multimesh: MultiMesh
var _multimesh_instance: MultiMeshInstance3D
var _noise: FastNoiseLite
var _active_voxel_count: int = 0
var _info_label: Label3D

# VR Controls
var _threshold_slider: Node
var _scale_slider: Node
var _control_panel: Node3D
var _grid_config: Dictionary = {}


func _ready():
	add_to_group("perlin_terrain_sculptors")
	if _grid_config.has("stand"):
		var sv: String = str(_grid_config["stand"]).strip_edges().to_lower()
		stand = "lattice" if sv in ["lattice", "model", "cells", "bench"] else "none"
	if _grid_config.has("seed"):
		lattice_seed = int(_grid_config["seed"])
	_init_noise()
	_init_voxels()
	_create_multimesh()
	_create_base()
	_create_labels()
	_create_vr_controls()
	_generate_terrain()
	if stand == "lattice":
		_build_lattice_stand()
		_update_lattice_readout()
	call_deferred("_broadcast_controls_to_voxelnoise")

func _init_noise():
	if stand == "lattice":
		# a five-digit number a visitor can read off the plate and say out loud
		if lattice_seed < 0:
			var namer := RandomNumberGenerator.new()
			namer.randomize()
			lattice_seed = namer.randi_range(10000, 99999)
		_named_seed = lattice_seed
		threshold = float(LATTICE_THRESHOLDS[_threshold_i])
		_noise = contract_noise(lattice_seed, noise_scale, noise_octaves)
		return
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.frequency = noise_scale * 0.1
	_noise.fractal_octaves = noise_octaves
	_noise.seed = randi()

func _init_voxels():
	_voxels.clear()
	for x in range(grid_size):
		var plane = []
		for y in range(grid_size):
			var row = []
			row.resize(grid_size)
			for z in range(grid_size):
				row[z] = false
			plane.append(row)
		_voxels.append(plane)

func _create_multimesh():
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	
	var max_voxels = grid_size * grid_size * grid_size
	_multimesh.instance_count = max_voxels
	_multimesh.visible_instance_count = 0
	
	var box = BoxMesh.new()
	box.size = Vector3.ONE * voxel_size * 0.95
	_multimesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.15
	
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "VoxelMultiMesh"
	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.material_override = mat
	add_child(_multimesh_instance)

func _create_base():
	var base = MeshInstance3D.new()
	base.name = "Base"
	
	var total_size = grid_size * voxel_size
	var box = BoxMesh.new()
	box.size = Vector3(total_size + 0.06, 0.03, total_size + 0.06)
	base.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.15)
	mat.metallic = 0.6
	mat.roughness = 0.4
	base.material_override = mat
	
	base.position = Vector3(0, -0.015 - total_size/2, 0)
	add_child(base)

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 24
	var total_size = grid_size * voxel_size
	_info_label.position = Vector3(0, total_size/2 + 0.15, -total_size/2 - 0.08)
	add_child(_info_label)
	_update_info()

func _create_vr_controls():
	var total_size = grid_size * voxel_size
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var mount: String = str(_grid_config.get("mount", ""))
	var use_csg := mount in ["shelf", "wall", "floor"]

	var panel: Node3D = RackTpl.create_panel("TERRAIN", [
		[
			{"type": "slider_h", "label": "THRESH", "default": (threshold + 1.0) / 2.0},
			{"type": "slider_h", "label": "SCALE", "default": (noise_scale - 0.5) / 19.5},
		],
		[
			{"type": "button", "label": "SEED"},
		],
	], use_csg)

	if use_csg:
		var tilt := 35.0
		var color := Color(0.12, 0.12, 0.12)
		if mount == "wall":
			tilt = 0.0
		elif mount == "floor":
			tilt = 25.0
			color = Color(0.55, 0.38, 0.22)
		_control_panel = RackTpl.create_csg_case(0.28, 0.18, 0.16, tilt, panel, color)
		_control_panel.position = Vector3(0, 0.04, total_size / 2 + 0.15)
	else:
		_control_panel = panel
		_control_panel.position = Vector3(0, 0.04, total_size / 2 + 0.15)
		_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	_threshold_slider = _control_panel.find_child("Param_0", true, false)
	_scale_slider = _control_panel.find_child("Param_1", true, false)

	if _threshold_slider and _threshold_slider.has_signal("slider_moved"):
		_threshold_slider.slider_moved.connect(_on_threshold_slider_moved)
	if _scale_slider and _scale_slider.has_signal("slider_moved"):
		_scale_slider.slider_moved.connect(_on_scale_slider_moved)

	var seed_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if seed_btn:
		var area = seed_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_new_seed)

func _sync_threshold_slider() -> void:
	if _threshold_slider and _threshold_slider.has_method("set_normalized_value"):
		_threshold_slider.set_normalized_value((threshold + 1.0) / 2.0)

func _sync_scale_slider() -> void:
	if _scale_slider and _scale_slider.has_method("set_normalized_value"):
		_scale_slider.set_normalized_value((noise_scale - 0.5) / 19.5)

func _on_threshold_slider_moved(_position):
	if _threshold_slider and _threshold_slider.has_method("get_normalized_value"):
		var norm = _threshold_slider.get_normalized_value()
		threshold = norm * 2.0 - 1.0

func _on_scale_slider_moved(_position):
	if _scale_slider and _scale_slider.has_method("get_normalized_value"):
		var norm = _scale_slider.get_normalized_value()
		noise_scale = 0.5 + norm * 19.5

func _on_new_seed():
	_noise.seed = randi()
	_generate_terrain()
	_broadcast_controls_to_voxelnoise()

func _update_info():
	if _info_label:
		_info_label.text = "PERLIN TERRAIN\nScale: %.1f | Thresh: %.2f\nVoxels: %d" % [noise_scale, threshold, _active_voxel_count]

func _generate_terrain():
	if not _noise:
		return

	var t0: int = Time.get_ticks_usec()
	if stand == "lattice":
		# THE CONTRACT, and nothing else. Normalised coordinates so this model and
		# the terrain across the room ask one field the same question.
		var last: int = maxi(1, grid_size - 1)
		for x in range(grid_size):
			for y in range(grid_size):
				for z in range(grid_size):
					var u := float(x) / float(last)
					var v := float(y) / float(last)
					var w := float(z) / float(last)
					_voxels[x][y][z] = contract_occupied(contract_value(_noise, u, v, w), v, threshold)
		_last_rebuild_ms = float(Time.get_ticks_usec() - t0) / 1000.0
		_rebuilds += 1
		_rebuild_multimesh()
		_update_lattice_readout()
		return

	var half = grid_size / 2.0

	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				var wx = (x - half) * voxel_size
				var wy = (y - half) * voxel_size
				var wz = (z - half) * voxel_size

				var n = _noise.get_noise_3d(wx * 10, wy * 10, wz * 10)
				var height_bias = (float(y) / grid_size - 0.5) * 0.5

				_voxels[x][y][z] = n - height_bias > threshold

	_last_rebuild_ms = float(Time.get_ticks_usec() - t0) / 1000.0
	_rebuilds += 1
	_rebuild_multimesh()

func _rebuild_multimesh():
	var half = grid_size / 2.0
	var idx = 0
	_active_voxel_count = 0
	
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				# CUT: the near half steps aside so the inside can be read. It hides
				# cells rather than changing them — the decision is the same and the
				# plate's count does not move.
				if _cut and z > grid_size / 2:
					continue
				if _voxels[x][y][z]:
					var pos = Vector3(
						(x - half + 0.5) * voxel_size,
						(y - half + 0.5) * voxel_size,
						(z - half + 0.5) * voxel_size
					)
					
					var transform = Transform3D()
					transform.origin = pos
					_multimesh.set_instance_transform(idx, transform)
					
					var color = voxel_color
					if height_gradient:
						var t = float(y) / grid_size
						color = voxel_color.lerp(Color(0.8, 0.9, 1.0), t * 0.5)
					_multimesh.set_instance_color(idx, color)
					
					idx += 1
					_active_voxel_count += 1
	
	_multimesh.visible_instance_count = idx
	_update_info()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				threshold += 0.05
			KEY_DOWN:
				threshold -= 0.05
			KEY_LEFT:
				noise_scale = maxf(0.5, noise_scale - 0.5)
			KEY_RIGHT:
				noise_scale += 0.5
			KEY_R:
				reset()
			KEY_N:
				_on_new_seed()

func reset():
	threshold = 0.0
	noise_scale = 4.0
	_noise.seed = randi()
	_generate_terrain()
	_broadcast_controls_to_voxelnoise()

func _build_voxelnoise_payload() -> Dictionary:
	var scale_norm: float = clampf((noise_scale - 0.5) / 19.5, 0.0, 1.0)
	return {
		"threshold": threshold,
		"noise_scale": noise_scale,
		"noise_scale_norm": scale_norm,
		"noise_octaves": noise_octaves,
		"seed": int(_noise.seed if _noise else 0),
		"source_path": str(get_path()),
		# Under the staging the receiver is told to use the CONTRACT rather than its
		# own coordinates: one field, two representations. Absent, the legacy link.
		"contract": stand == "lattice",
		"contract_span": CONTRACT_SPAN,
		"contract_bias_scale": CONTRACT_BIAS_SCALE,
	}

func _broadcast_controls_to_voxelnoise() -> void:
	if not is_inside_tree():
		return

	var payload: Dictionary = _build_voxelnoise_payload()
	terrain_controls_changed.emit(payload)

	if not get_tree():
		return
	# SCOPED TO THIS HALL. call_group reaches every receiver in the tree, and in a
	# streaming museum that is other rooms: turning this threshold was retuning a
	# terrain two halls away. The nearest ancestor that owns a hall is the one
	# whose receivers may hear it; with no such ancestor (a bench scene on its own)
	# the behaviour is the old one.
	var hall: Node = _hall_ancestor()
	var reached: Array = []
	for r in get_tree().get_nodes_in_group("voxelnoise_receivers"):
		if hall != null and not hall.is_ancestor_of(r):
			continue
		if r.has_method("apply_perlin_terrain_controls"):
			r.call("apply_perlin_terrain_controls", payload)
			reached.append(str((r as Node).name))
	_last_broadcast = {"hall": str(hall.name) if hall != null else "(none)", "reached": reached,
		"receivers_in_tree": get_tree().get_nodes_in_group("voxelnoise_receivers").size()}


## The hall this bench stands in, if it stands in one: the museum names its
## segments, and a body's own segment is the boundary of its audience.
func _hall_ancestor() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n.has_meta("em_map") or str(n.name).begins_with("Seg"):
			return n
		n = n.get_parent()
	return null

func apply_grid_config(config_data: Dictionary):
	_grid_config = config_data
	for key in config_data:
		if key in self:
			set(key, config_data[key])

# ═════════════════════════════════════════════════════════════════════════════
# THE LATTICE — stand:lattice. Nothing below runs at stand:none.
# ═════════════════════════════════════════════════════════════════════════════

var _last_broadcast: Dictionary = {}


## The selected cell, as the plate reads it: where it is, what the field says
## there, what the bias does to that, and the decision the threshold makes.
func cell_report(c: Vector3i = Vector3i(-1, -1, -1)) -> Dictionary:
	var cell: Vector3i = c if c.x >= 0 else _cell
	var last: int = maxi(1, grid_size - 1)
	var u := float(cell.x) / float(last)
	var v := float(cell.y) / float(last)
	var w := float(cell.z) / float(last)
	var value: float = contract_value(_noise, u, v, w)
	var bias: float = contract_bias(v)
	return {
		"cell": [cell.x, cell.y, cell.z],
		"normalised": [snappedf(u, 0.001), snappedf(v, 0.001), snappedf(w, 0.001)],
		"value": snappedf(value, 0.0001),
		"bias": snappedf(bias, 0.0001),
		"threshold": snappedf(threshold, 0.0001),
		"decision": contract_occupied(value, v, threshold),
	}


## How many cells the threshold admits, and how many separate pieces they make.
## Connectivity is a fact about the SET, not a promise about walking: the plate
## says so, because a body needs a floor, a headroom and a way in.
func occupancy_report() -> Dictionary:
	var occupied: int = 0
	var seen: Dictionary = {}
	var components: int = 0
	var largest: int = 0
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				if _voxels[x][y][z]:
					occupied += 1
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				var k := Vector3i(x, y, z)
				if not _voxels[x][y][z] or seen.has(k):
					continue
				components += 1
				var size: int = 0
				var queue: Array = [k]
				seen[k] = true
				while not queue.is_empty():
					var cur: Vector3i = queue.pop_back()
					size += 1
					for d in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
						var n2: Vector3i = cur + d
						if n2.x < 0 or n2.y < 0 or n2.z < 0 or n2.x >= grid_size or n2.y >= grid_size or n2.z >= grid_size:
							continue
						if seen.has(n2) or not _voxels[n2.x][n2.y][n2.z]:
							continue
						seen[n2] = true
						queue.append(n2)
				largest = maxi(largest, size)
	return {"occupied": occupied, "cells": grid_size * grid_size * grid_size,
		"pieces": components, "largest_piece": largest}


func _build_lattice_stand() -> void:
	if _lattice_root != null and is_instance_valid(_lattice_root):
		return
	var HangarKit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	_lattice_root = Node3D.new()
	_lattice_root.name = "LatticeStand"
	add_child(_lattice_root)

	var case_root := Node3D.new()
	case_root.name = "Readout"
	case_root.set_meta("em_local_instrument", true)
	case_root.position = Vector3(0.0, -0.42, 0.62)
	case_root.rotation_degrees = Vector3(-20, 0, 0)
	_lattice_root.add_child(case_root)
	case_root.add_child(HangarKit.box(Vector3.ZERO, Vector3(1.20, 0.30, 0.014), dark))
	_lattice_readout = Label3D.new()
	_lattice_readout.name = "Text"
	_lattice_readout.pixel_size = 0.00090
	_lattice_readout.font_size = 17
	_lattice_readout.line_spacing = 0.5
	_lattice_readout.modulate = Color(0.88, 0.94, 1.0)
	_lattice_readout.outline_size = 3
	_lattice_readout.outline_modulate = Color(0, 0, 0, 1)
	_lattice_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_lattice_readout.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_lattice_readout.position = Vector3(-0.575, 0.138, 0.010)
	case_root.add_child(_lattice_readout)

	# the marker: a wire cage round the cell the plate is talking about
	var marker := MeshInstance3D.new()
	marker.name = "CellMarker"
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * (voxel_size * 1.9)
	marker.mesh = bm
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(1.0, 0.85, 0.25, 0.55)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = mm
	_lattice_root.add_child(marker)

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl != null:
		var panel: Node3D = RackTpl.create_panel("", [
			[{"type": "button", "label": "THRESHOLD"}, {"type": "button", "label": "CELL"}],
			[{"type": "button", "label": "SEED"}, {"type": "button", "label": "CUT"}],
		], true)
		panel.name = "Panel"
		panel.set_meta("em_local_instrument", true)
		panel.position = Vector3(0.78, -0.36, 0.66)
		panel.rotation_degrees = Vector3(-26, 0, 0)
		panel.scale = Vector3(1.4, 1.4, 1.4)
		_lattice_root.add_child(panel)
		var actions := {"Btn_0": func(): next_threshold(), "Btn_1": func(): next_cell(), "Btn_2": func(): new_lattice_seed(), "Btn_3": func(): toggle_cut()}
		for btn_name in actions.keys():
			var btn: Node = panel.find_child(btn_name, true, false)
			if btn == null:
				continue
			var area: Node = btn.get_node_or_null("InteractableAreaButton")
			if area != null and area.has_signal("button_pressed"):
				var action: Callable = actions[btn_name]
				area.button_pressed.connect(func(_b): action.call())
	_place_cell_marker()


func _place_cell_marker() -> void:
	if _lattice_root == null:
		return
	var marker: Node3D = _lattice_root.get_node_or_null("CellMarker")
	if marker == null:
		return
	var half: float = grid_size / 2.0
	marker.position = Vector3((_cell.x - half) * voxel_size, (_cell.y - half) * voxel_size, (_cell.z - half) * voxel_size)


func _update_lattice_readout() -> void:
	if _lattice_readout == null or not is_instance_valid(_lattice_readout):
		return
	var r: Dictionary = cell_report()
	var o: Dictionary = occupancy_report()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("seed %d · threshold %+.2f · %d³ cells · rebuilt in %.1f ms" % [_named_seed, threshold, grid_size, _last_rebuild_ms])
	lines.append("cell %d,%d,%d   field %+.4f   bias %+.4f" % [int(r["cell"][0]), int(r["cell"][1]), int(r["cell"][2]), float(r["value"]), float(r["bias"])])
	lines.append("%+.4f − %+.4f = %+.4f  %s  %+.2f   →   %s" % [float(r["value"]), float(r["bias"]),
		float(r["value"]) - float(r["bias"]), ">", float(r["threshold"]),
		("OCCUPIED" if bool(r["decision"]) else "empty")])
	lines.append("%d of %d cells occupied, in %d separate pieces (the largest %d)" % [int(o["occupied"]), int(o["cells"]), int(o["pieces"]), int(o["largest_piece"])])
	lines.append("connected is not walkable: this is a set of cells, not a verified passage")
	_lattice_readout.text = "\n".join(lines)


## Up the threshold. The field does not move; the admitted set can only shrink.
func next_threshold() -> void:
	if stand != "lattice":
		return
	_threshold_i = (_threshold_i + 1) % LATTICE_THRESHOLDS.size()
	threshold = float(LATTICE_THRESHOLDS[_threshold_i])
	_generate_terrain()
	_broadcast_controls_to_voxelnoise()


func next_cell() -> void:
	if stand != "lattice":
		return
	var step: Array = [Vector3i(12, 12, 12), Vector3i(6, 8, 17), Vector3i(17, 6, 9), Vector3i(9, 17, 6), Vector3i(15, 12, 15)]
	var i: int = 0
	for k in range(step.size()):
		if step[k] == _cell:
			i = (k + 1) % step.size()
			break
	_cell = step[i]
	_place_cell_marker()
	_update_lattice_readout()


func new_lattice_seed() -> void:
	if stand != "lattice":
		return
	var namer := RandomNumberGenerator.new()
	namer.randomize()
	lattice_seed = namer.randi_range(10000, 99999)
	_named_seed = lattice_seed
	_noise = contract_noise(lattice_seed, noise_scale, noise_octaves)
	_generate_terrain()
	_broadcast_controls_to_voxelnoise()


## Open the lattice: the near half of the model hides so the inside can be seen.
func toggle_cut() -> void:
	if stand != "lattice":
		return
	_cut = not _cut
	_rebuild_multimesh()
	_update_lattice_readout()


## The lattice as the room can read it.
func lattice_state() -> Dictionary:
	var o: Dictionary = occupancy_report()
	return {
		"stand": stand, "seed": _named_seed, "threshold": snappedf(threshold, 0.0001),
		"threshold_index": _threshold_i, "grid": grid_size, "cut": _cut,
		"cell": cell_report(), "occupancy": o,
		"rebuild_ms": snappedf(_last_rebuild_ms, 0.01), "rebuilds": _rebuilds,
		"contract": {"span": CONTRACT_SPAN, "bias_scale": CONTRACT_BIAS_SCALE,
			"basis": "perlin fbm", "octaves": noise_octaves, "scale": noise_scale},
		"broadcast": _last_broadcast,
	}


## Every cell's decision at a threshold, without touching the display: the probe's
## way of asking whether raising the line can ever ADD a cell.
func occupied_count_at(t: float) -> int:
	var last: int = maxi(1, grid_size - 1)
	var n: int = 0
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				var v := float(y) / float(last)
				if contract_occupied(contract_value(_noise, float(x) / float(last), v, float(z) / float(last)), v, t):
					n += 1
	return n
