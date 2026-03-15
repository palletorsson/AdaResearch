# perlin_terrain_sculptor.gd
# Voxel sculpture tool where Perlin noise is the brush
# VR-enabled with slider controls

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

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	add_to_group("perlin_terrain_sculptors")
	_init_noise()
	_init_voxels()
	_create_multimesh()
	_create_base()
	_create_labels()
	_create_vr_controls()
	_generate_terrain()
	call_deferred("_broadcast_controls_to_voxelnoise")

func _init_noise():
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
	
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.04, total_size/2 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.5, 0.18, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# Threshold slider (-1 to 1)
	_threshold_slider = SLIDER_HORIZONTAL.instantiate()
	_threshold_slider.name = "ThresholdSlider"
	_threshold_slider.position = Vector3(-0.12, 0.04, 0)
	_threshold_slider.rotation_degrees.x = -30
	var thresh_label = _threshold_slider.get_node_or_null("Frame/LabelName")
	if thresh_label:
		thresh_label.text = "THRESH"
	_control_panel.add_child(_threshold_slider)
	_threshold_slider.slider_moved.connect(_on_threshold_slider_moved)
	
	# Scale slider (0.5 to 20)
	_scale_slider = SLIDER_HORIZONTAL.instantiate()
	_scale_slider.name = "ScaleSlider"
	_scale_slider.position = Vector3(0.12, 0.04, 0)
	_scale_slider.rotation_degrees.x = -30
	var scale_label = _scale_slider.get_node_or_null("Frame/LabelName")
	if scale_label:
		scale_label.text = "SCALE"
	_control_panel.add_child(_scale_slider)
	_scale_slider.slider_moved.connect(_on_scale_slider_moved)
	
	# New Seed button
	var seed_btn = PUSH_BUTTON.instantiate()
	seed_btn.name = "SeedButton"
	seed_btn.position = Vector3(-0.08, -0.04, 0)
	seed_btn.rotation_degrees.x = -30
	_control_panel.add_child(seed_btn)
	_add_button_label(seed_btn, "SEED")
	var seed_area = seed_btn.get_node_or_null("InteractableAreaButton")
	if seed_area:
		seed_area.button_pressed.connect(_on_new_seed)
	
	# Reset button
	var reset_btn = PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetButton"
	reset_btn.position = Vector3(0.08, -0.04, 0)
	reset_btn.rotation_degrees.x = -30
	_control_panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RST")
	var reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(reset)
	
	call_deferred("_sync_sliders_deferred")

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 12
	lbl.position = Vector3(0, -0.025, 0)
	btn.add_child(lbl)

func _sync_sliders_deferred():
	_sync_threshold_slider()
	_sync_scale_slider()

func _sync_threshold_slider():
	if _threshold_slider and _threshold_slider.has_method("set_normalized_value"):
		_threshold_slider.set_normalized_value((threshold + 1.0) / 2.0)

func _sync_scale_slider():
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
	
	_rebuild_multimesh()

func _rebuild_multimesh():
	var half = grid_size / 2.0
	var idx = 0
	_active_voxel_count = 0
	
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
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
		"source_path": str(get_path())
	}

func _broadcast_controls_to_voxelnoise() -> void:
	if not is_inside_tree():
		return

	var payload: Dictionary = _build_voxelnoise_payload()
	terrain_controls_changed.emit(payload)

	if get_tree():
		get_tree().call_group("voxelnoise_receivers", "apply_perlin_terrain_controls", payload)

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
