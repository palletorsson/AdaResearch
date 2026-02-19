# MarchingCubesSculptVR.gd
# VR Paintable Marching Cubes - Paint in 3D with your controllers!
extends Node3D

@export_category("Sculpting")
@export var brush_radius: float = 0.15
@export var brush_radius_min: float = 0.05
@export var brush_radius_max: float = 0.5
@export var paint_rate: float = 0.05  # Time between paint strokes
@export var erase_mode: bool = false  # When true, removes material

@export_category("Visuals")
@export var sculpt_color: Color = Color(0.4, 0.7, 0.9)
@export var show_brush_indicator: bool = true

@export_category("Volume")
@export var volume_size: float = 2.0  # Size of the sculpting volume in meters
@export var volume_resolution: int = 64  # Voxels per axis (affects detail)

# References
var terrain_generator: Node  # TerrainGeneratorSculpt
var brush_indicator: MeshInstance3D
var volume_bounds: MeshInstance3D

# Controller tracking
var left_controller: Node3D
var right_controller: Node3D
var left_trigger_pressed: bool = false
var right_trigger_pressed: bool = false

# Paint timing
var left_paint_timer: float = 0.0
var right_paint_timer: float = 0.0

# State
var is_initialized: bool = false
var blobs_painted: int = 0

func _ready():
	print("MarchingCubesSculptVR: Initializing VR sculpting...")
	_create_terrain_generator()
	_create_brush_indicator()
	_create_volume_bounds()
	_find_controllers()
	is_initialized = true
	print("MarchingCubesSculptVR: Ready! Use triggers to paint in 3D.")

func _create_terrain_generator():
	# Load and instantiate the sculpt terrain generator
	var sculpt_script = load("res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Scripts/TerrainGeneratorSculpt.gd")
	if not sculpt_script:
		push_error("MarchingCubesSculptVR: Could not load TerrainGeneratorSculpt.gd")
		return

	terrain_generator = MeshInstance3D.new()
	terrain_generator.name = "SculptMesh"
	terrain_generator.set_script(sculpt_script)

	# Configure the generator
	terrain_generator.chunk_scale = volume_size  # 1:1 with VR volume (meters)
	terrain_generator.center_position = Vector3(0, 0, 0)  # Ground level
	terrain_generator.iso_level = 0.3
	terrain_generator.noise_scale = 0.0  # No noise - pure sculpting
	terrain_generator.invert_faces = true  # View from outside
	terrain_generator.continuous_update = true  # Needs re-render on each paint stroke

	# Material — glass wireframe shader (same as voxel_noise_demo)
	var shader = load("res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Shaders/glass_wireframe.gdshader")
	if shader:
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("glass_color", sculpt_color)
		material.set_shader_parameter("outline_color", Color(1.0, 0.0, 0.5, 1.0))
		material.set_shader_parameter("outline_width", 1.5)
		terrain_generator.material_override = material
	else:
		# Fallback to simple material
		var material = StandardMaterial3D.new()
		material.albedo_color = sculpt_color
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		terrain_generator.material_override = material

	add_child(terrain_generator)

	# Add initial blob so there's something to see
	await get_tree().process_frame
	await get_tree().process_frame
	if terrain_generator.has_method("add_blob"):
		# Add a starting sphere in the center
		terrain_generator.add_blob(Vector3(0, 0, 0), 0.3)
		blobs_painted += 1

func _create_brush_indicator():
	brush_indicator = MeshInstance3D.new()
	brush_indicator.name = "BrushIndicator"

	var sphere = SphereMesh.new()
	sphere.radius = brush_radius
	sphere.height = brush_radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	brush_indicator.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.5, 0.0, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.0)
	mat.emission_energy_multiplier = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	brush_indicator.material_override = mat

	brush_indicator.visible = false
	add_child(brush_indicator)

func _create_volume_bounds():
	# Visual indicator of the sculpting volume
	volume_bounds = MeshInstance3D.new()
	volume_bounds.name = "VolumeBounds"

	var box = BoxMesh.new()
	box.size = Vector3(volume_size, volume_size, volume_size)
	volume_bounds.mesh = box

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.3, 0.3, 0.5, 0.1)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	volume_bounds.material_override = mat

	add_child(volume_bounds)

func _find_controllers():
	# Try to find XR controllers in the scene tree
	await get_tree().process_frame

	# Search for controllers by common names
	var root = get_tree().root
	left_controller = _find_node_recursive(root, "LeftController")
	if not left_controller:
		left_controller = _find_node_recursive(root, "XRController3D")  # First one found
	if not left_controller:
		left_controller = _find_node_recursive(root, "LeftHand")

	right_controller = _find_node_recursive(root, "RightController")
	if not right_controller:
		right_controller = _find_node_recursive(root, "RightHand")

	if left_controller:
		print("MarchingCubesSculptVR: Found left controller: ", left_controller.name)
	if right_controller:
		print("MarchingCubesSculptVR: Found right controller: ", right_controller.name)

	if not left_controller and not right_controller:
		print("MarchingCubesSculptVR: No VR controllers found. Use keyboard: SPACE to paint, E to erase, +/- for brush size")

func _find_node_recursive(node: Node, name_contains: String) -> Node3D:
	if node.name.to_lower().contains(name_contains.to_lower()):
		if node is Node3D:
			return node
	for child in node.get_children():
		var found = _find_node_recursive(child, name_contains)
		if found:
			return found
	return null

func _process(delta):
	if not is_initialized:
		return

	# Update paint timers
	left_paint_timer += delta
	right_paint_timer += delta

	# Handle VR controller input
	_handle_vr_input(delta)

	# Handle keyboard input (fallback / desktop mode)
	_handle_keyboard_input(delta)

	# Update brush indicator
	_update_brush_indicator()

func _handle_vr_input(_delta):
	# Check for XR trigger actions
	if left_controller:
		var left_trigger: float = 0.0
		if InputMap.has_action("trigger_click"):
			left_trigger = Input.get_action_strength("trigger_click")
		if InputMap.has_action("trigger_left"):
			left_trigger = max(left_trigger, Input.get_action_strength("trigger_left"))

		if left_trigger > 0.5 and left_paint_timer >= paint_rate:
			_paint_at_controller(left_controller)
			left_paint_timer = 0.0

	if right_controller:
		var right_trigger: float = 0.0
		if InputMap.has_action("trigger_click"):
			right_trigger = Input.get_action_strength("trigger_click")
		if InputMap.has_action("trigger_right"):
			right_trigger = max(right_trigger, Input.get_action_strength("trigger_right"))

		if right_trigger > 0.5 and right_paint_timer >= paint_rate:
			_paint_at_controller(right_controller)
			right_paint_timer = 0.0

func _handle_keyboard_input(_delta):
	# Keyboard controls for desktop testing
	pass  # Handled in _input for key events

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				# Paint at center (desktop mode)
				_paint_at_position(Vector3(0, 0, 0))
			KEY_E:
				# Toggle erase mode
				erase_mode = !erase_mode
				print("Erase mode: ", "ON" if erase_mode else "OFF")
				_update_brush_color()
			KEY_EQUAL, KEY_KP_ADD:
				# Increase brush size
				brush_radius = min(brush_radius + 0.02, brush_radius_max)
				_update_brush_size()
				print("Brush radius: ", brush_radius)
			KEY_MINUS, KEY_KP_SUBTRACT:
				# Decrease brush size
				brush_radius = max(brush_radius - 0.02, brush_radius_min)
				_update_brush_size()
				print("Brush radius: ", brush_radius)
			KEY_C:
				# Clear all blobs
				clear_sculpture()
			KEY_R:
				# Random paint at random position
				var pos = Vector3(
					randf_range(-volume_size/3, volume_size/3),
					randf_range(-volume_size/3, volume_size/3),
					randf_range(-volume_size/3, volume_size/3)
				)
				_paint_at_position(pos)

	# Handle mouse for desktop 3D painting
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Paint at a position based on mouse (simplified - center)
			_paint_at_position(Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.3, 0.3)))

func _paint_at_controller(controller: Node3D):
	if not controller:
		return

	# Get controller position in local space of the sculpt volume
	var world_pos = controller.global_position
	var local_pos = to_local(world_pos)

	_paint_at_position(local_pos)

func _paint_at_position(local_pos: Vector3):
	if not terrain_generator or not terrain_generator.has_method("add_blob"):
		return

	# Check if position is within volume bounds
	var half_size = volume_size / 2.0
	if abs(local_pos.x) > half_size or abs(local_pos.y) > half_size or abs(local_pos.z) > half_size:
		return  # Outside sculpting volume

	# Convert to generator's coordinate space
	# The generator uses a different scale internally
	var scale_factor = terrain_generator.chunk_scale / volume_size
	var gen_pos = local_pos * scale_factor

	# Add blob (positive radius adds material, negative could remove - but shader may not support)
	var effective_radius = brush_radius * scale_factor
	if erase_mode:
		effective_radius = -effective_radius  # Negative radius for erasing (if shader supports)

	terrain_generator.add_blob(gen_pos, abs(effective_radius))
	blobs_painted += 1

	# Visual feedback
	if show_brush_indicator:
		brush_indicator.position = local_pos
		brush_indicator.visible = true
		# Flash effect
		var mat = brush_indicator.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 2.0
			await get_tree().create_timer(0.1).timeout
			if mat:
				mat.emission_energy_multiplier = 0.5

func _update_brush_indicator():
	if not show_brush_indicator:
		brush_indicator.visible = false
		return

	# Position indicator at active controller
	var active_controller = right_controller if right_controller else left_controller
	if active_controller:
		var local_pos = to_local(active_controller.global_position)
		brush_indicator.position = local_pos
		brush_indicator.visible = true
	else:
		brush_indicator.visible = false

func _update_brush_size():
	if brush_indicator and brush_indicator.mesh:
		var sphere = brush_indicator.mesh as SphereMesh
		if sphere:
			sphere.radius = brush_radius
			sphere.height = brush_radius * 2.0

func _update_brush_color():
	if brush_indicator and brush_indicator.material_override:
		var mat = brush_indicator.material_override as StandardMaterial3D
		if mat:
			if erase_mode:
				mat.albedo_color = Color(1.0, 0.2, 0.2, 0.4)  # Red for erase
				mat.emission = Color(1.0, 0.2, 0.2)
			else:
				mat.albedo_color = Color(1.0, 0.5, 0.0, 0.4)  # Orange for paint
				mat.emission = Color(1.0, 0.5, 0.0)

func clear_sculpture():
	if terrain_generator and terrain_generator.has_method("clear_blobs"):
		terrain_generator.clear_blobs()
		blobs_painted = 0
		print("MarchingCubesSculptVR: Sculpture cleared")

		# Add back a small starting blob
		await get_tree().process_frame
		if terrain_generator.has_method("add_blob"):
			terrain_generator.add_blob(Vector3(0, 0, 0), 0.2)
			blobs_painted = 1

func get_blob_count() -> int:
	return blobs_painted
