# VoxelBuilderVR.gd — VR Minecraft-style voxel editor
#
# Walk around the map in VR, point controller at surfaces, trigger to add
# cubes, grip to remove. A button saves, B button undoes.
#
# Usage:
#   godot --path . res://commons/maps/catalog/VoxelBuilderVR.tscn -- --map=LSystems_Grammar_Lab

extends Node3D

# ─────────────────────────────────────────────────────────────
#  State
# ─────────────────────────────────────────────────────────────

var _edit_controller: VoxelEditController = null
var _structure_component: GridStructureComponent = null
var _map_name: String = ""
var _right_controller: XRController3D = null
var _raycast: RayCast3D = null
var _initialized: bool = false
var _hud_label: Label3D = null


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	# Parse --map= from command line
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="):
			_map_name = arg.substr(6).strip_edges()

	if _map_name.is_empty():
		_map_name = "LSystems_Grammar_Lab"

	_build_vr_rig()
	_build_edit_system()
	call_deferred("_load_map")


func _build_vr_rig() -> void:
	# XR Origin
	var origin := XROrigin3D.new()
	origin.name = "XROrigin"
	add_child(origin)

	# Camera
	var xr_camera := XRCamera3D.new()
	xr_camera.name = "XRCamera"
	origin.add_child(xr_camera)

	# Right controller (for editing)
	_right_controller = XRController3D.new()
	_right_controller.name = "RightController"
	_right_controller.tracker = &"right_hand"
	origin.add_child(_right_controller)

	# Raycast from controller
	_raycast = RayCast3D.new()
	_raycast.name = "EditRay"
	_raycast.target_position = Vector3(0, 0, -20)
	_raycast.enabled = true
	_right_controller.add_child(_raycast)

	# Ray visual (thin line)
	var ray_mesh := MeshInstance3D.new()
	ray_mesh.name = "RayVisual"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.002
	cyl.bottom_radius = 0.002
	cyl.height = 20.0
	ray_mesh.mesh = cyl
	ray_mesh.position = Vector3(0, 0, -10)
	ray_mesh.rotation.x = PI * 0.5
	var ray_mat := StandardMaterial3D.new()
	ray_mat.albedo_color = Color(0.3, 0.7, 1.0, 0.4)
	ray_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ray_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ray_mesh.material_override = ray_mat
	_right_controller.add_child(ray_mesh)

	# HUD label on wrist
	_hud_label = Label3D.new()
	_hud_label.name = "HUDLabel"
	_hud_label.text = "Voxel Builder VR"
	_hud_label.font_size = 24
	_hud_label.position = Vector3(0, 0.05, -0.1)
	_hud_label.rotation.x = -PI * 0.25
	_hud_label.modulate = Color(0.9, 0.9, 1.0)
	_right_controller.add_child(_hud_label)

	# Connect controller buttons
	_right_controller.button_pressed.connect(_on_button_pressed)

	# Left controller (for locomotion — using existing XR setup)
	var left_controller := XRController3D.new()
	left_controller.name = "LeftController"
	left_controller.tracker = &"left_hand"
	origin.add_child(left_controller)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.12, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.6)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Lights
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, -30, 0)
	key.light_energy = 1.2
	key.shadow_enabled = true
	add_child(key)


func _build_edit_system() -> void:
	_edit_controller = VoxelEditController.new()
	_edit_controller.name = "VoxelEditController"
	add_child(_edit_controller)


func _load_map() -> void:
	print("[VoxelBuilderVR] Loading map: %s" % _map_name)

	var grid_system_scene := load("res://commons/grid/GridSystem.tscn")
	if not grid_system_scene:
		push_error("[VoxelBuilderVR] Cannot load GridSystem")
		return

	var grid_system: Node = grid_system_scene.instantiate()
	grid_system.name = "GridSystem"
	if "map_name" in grid_system:
		grid_system.map_name = _map_name
	add_child(grid_system)

	# Wait for map
	if grid_system.has_signal("map_generation_complete"):
		await grid_system.map_generation_complete
	else:
		for _i in 10:
			# out-of-tree guard: get_tree() is null once a map is torn down
			if not is_inside_tree():
				await tree_entered
			await get_tree().process_frame

	_structure_component = grid_system.find_child("GridStructureComponent", true, false) as GridStructureComponent
	if not _structure_component:
		return

	var data_component = grid_system.find_child("GridDataComponent", true, false)
	if data_component and data_component.has_method("get_structure_data"):
		_structure_component.enable_editing(data_component.get_structure_data())

	_edit_controller.structure_component = _structure_component
	_edit_controller.cube_size = _structure_component.cube_size

	_initialized = true
	print("[VoxelBuilderVR] Ready to edit in VR")


# ═══════════════════════════════════════════════════════════════
# VR INPUT
# ═══════════════════════════════════════════════════════════════

func _on_button_pressed(button_name: String) -> void:
	if not _initialized:
		return

	match button_name:
		"trigger_click":
			# Add cube
			if _edit_controller:
				_edit_controller.try_add()
		"grip_click":
			# Remove cube
			if _edit_controller:
				_edit_controller.try_remove()
		"ax_button":
			# Save
			_save()
		"by_button":
			# Undo
			if _edit_controller:
				_edit_controller.undo()


func _process(_delta: float) -> void:
	if not _initialized or not _right_controller:
		return

	# Update raycast from controller
	var origin: Vector3 = _right_controller.global_position
	var forward: Vector3 = -_right_controller.global_transform.basis.z
	_edit_controller.update_target_from_ray(origin, forward)

	# Update HUD
	if _hud_label and _edit_controller:
		if _edit_controller.has_target:
			var tc := _edit_controller.target_cell
			_hud_label.text = "(%d,%d,%d)\nTrigger=Add Grip=Remove\nA=Save B=Undo" % [tc.x, tc.y, tc.z]
		else:
			_hud_label.text = "Voxel Builder VR\nPoint at grid"


# ═══════════════════════════════════════════════════════════════
# SAVE
# ═══════════════════════════════════════════════════════════════

func _save() -> void:
	if not _structure_component or _map_name.is_empty():
		return
	var ok := VoxelSaveManager.save(_map_name, _structure_component)
	if ok and _hud_label:
		_hud_label.text = "SAVED!"
