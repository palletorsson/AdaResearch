# RotatingCubeArtifact.gd
# A rotating cube artifact that automatically triggers sequences after 5 seconds
# Uses the existing cube_scene.tscn instead of creating a new cube

extends Node3D
class_name RotatingCubeArtifact

# Configuration
@export var rotation_speed: Vector3 = Vector3(0, 45, 0)  # degrees per second
@export var hover_height: float = 0.1
@export var hover_speed: float = 2.0
@export var auto_trigger_time: float = 5.0  # Auto-trigger after 5 seconds

# Scene reference
const CUBE_SCENE_PATH = "res://commons/primitives/cubes/cube_scene.tscn"

# Visual components
var cube_instance: Node3D
var cube_mesh_instance: MeshInstance3D

# State
var initial_position: Vector3
var time_elapsed: float = 0.0
var has_triggered: bool = false

# Signals
signal artifact_activated()
signal sequence_triggered(sequence_name: String)

func _ready():
	print("RotatingCubeArtifact: Initializing - will auto-trigger in %s seconds" % auto_trigger_time)
	
	# Store initial position
	initial_position = position
	
	# Setup visual components using cube_scene.tscn
	_setup_visual_components()
	
	print("RotatingCubeArtifact: Ready - starting auto-trigger countdown")

func _setup_visual_components():
	"""Load and configure the cube from cube_scene.tscn"""
	
	# Load the cube scene
	var cube_scene = load(CUBE_SCENE_PATH) as PackedScene
	if not cube_scene:
		print("ERROR: RotatingCubeArtifact: Could not load cube scene: %s" % CUBE_SCENE_PATH)
		_fallback_cube_creation()
		return
	
	# Instantiate the cube
	cube_instance = cube_scene.instantiate()
	if not cube_instance:
		print("ERROR: RotatingCubeArtifact: Could not instantiate cube scene")
		_fallback_cube_creation()
		return
	
	# Add to scene and make visible
	add_child(cube_instance)
	cube_instance.visible = true
	
	# Find the mesh instance in the cube scene
	cube_mesh_instance = _find_mesh_instance(cube_instance)
	
	if cube_mesh_instance:
		# Configure the cube for artifact use
		_configure_cube_appearance()
		print("RotatingCubeArtifact: Successfully loaded cube_scene.tscn")
	else:
		print("WARNING: RotatingCubeArtifact: Could not find MeshInstance3D in cube scene")
		_fallback_cube_creation()

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	"""Find the MeshInstance3D in the cube scene hierarchy"""
	
	# Check if this node is a MeshInstance3D
	if node is MeshInstance3D:
		return node as MeshInstance3D
	
	# Search children recursively
	for child in node.get_children():
		var mesh_instance = _find_mesh_instance(child)
		if mesh_instance:
			return mesh_instance
	
	return null

func _configure_cube_appearance():
	"""Configure the cube's appearance for the artifact"""
	
	if not cube_mesh_instance:
		return
	
	# Scale the cube to artifact size
	cube_instance.scale = Vector3(0.2, 0.2, 0.2)
	
	# Create artifact material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission_enabled = true
	material.emission = Color.CYAN * 0.3
	material.metallic = 0.5
	material.roughness = 0.3
	
	# Apply material to the cube
	cube_mesh_instance.material_override = material
	
	# Disable any collision (we don't want physics on the artifact)
	var static_body = cube_instance.find_child("CubeBaseStaticBody3D")
	if static_body:
		static_body.process_mode = Node.PROCESS_MODE_DISABLED
	
	print("RotatingCubeArtifact: Configured cube appearance")

func _fallback_cube_creation():
	"""Fallback method if cube_scene.tscn can't be loaded"""
	print("RotatingCubeArtifact: Using fallback cube creation")
	
	# Create mesh instance
	cube_mesh_instance = MeshInstance3D.new()
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(0.2, 0.2, 0.2)
	cube_mesh_instance.mesh = cube_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission_enabled = true
	material.emission = Color.CYAN * 0.3
	material.metallic = 0.5
	material.roughness = 0.3
	cube_mesh_instance.material_override = material
	
	add_child(cube_mesh_instance)
	cube_instance = cube_mesh_instance
	
	print("RotatingCubeArtifact: Fallback cube created")

func _process(delta):
	if not cube_instance:
		return
	
	# Rotate the cube
	cube_instance.rotation_degrees += rotation_speed * delta
	
	# Hover animation
	var hover_offset = sin(Time.get_time_dict_from_system().second * hover_speed) * hover_height
	position = initial_position + Vector3(0, hover_offset, 0)
	
	# Auto-trigger countdown
	if not has_triggered:
		time_elapsed += delta
		
		# Visual feedback showing countdown progress
		_update_countdown_visual()
		
		# Check if it's time to trigger
		if time_elapsed >= auto_trigger_time:
			_trigger_sequence()

func _update_countdown_visual():
	"""Update visual feedback during countdown"""
	if not cube_mesh_instance or not cube_mesh_instance.material_override:
		return
	
	var progress = time_elapsed / auto_trigger_time
	var intensity = 0.3 + progress * 0.7  # Gradually brighten
	
	var material = cube_mesh_instance.material_override as StandardMaterial3D
	if material:
		material.emission = Color.CYAN * intensity

func _trigger_sequence():
	"""Trigger the sequence when countdown reaches zero"""
	print("RotatingCubeArtifact: Auto-trigger time reached - starting sequence!")
	
	has_triggered = true
	
	# Visual feedback for activation
	_show_activation_effect()
	
	# Emit signals
	artifact_activated.emit()
	sequence_triggered.emit("array_tutorial")

func _show_activation_effect():
	"""Show visual effect when artifact activates"""
	if not cube_mesh_instance or not cube_mesh_instance.material_override:
		return
	
	var material = cube_mesh_instance.material_override as StandardMaterial3D
	if material:
		# Flash white
		material.emission = Color.WHITE * 2.0
		
		# Wait then turn green
		await get_tree().create_timer(0.5).timeout
		
		if material and is_instance_valid(cube_mesh_instance):
			material.emission = Color.GREEN * 1.5

# Public API
func reset_artifact():
	"""Reset the artifact to initial state"""
	has_triggered = false
	time_elapsed = 0.0
	
	if cube_instance:
		cube_instance.rotation_degrees = Vector3.ZERO
	
	position = initial_position
	
	# Reset material
	if cube_mesh_instance and cube_mesh_instance.material_override:
		var material = cube_mesh_instance.material_override as StandardMaterial3D
		if material:
			material.emission = Color.CYAN * 0.3

func force_trigger():
	"""Force trigger the sequence immediately"""
	if not has_triggered:
		_trigger_sequence()

func set_countdown_time(new_time: float):
	"""Change the countdown time"""
	auto_trigger_time = new_time
	print("RotatingCubeArtifact: Countdown time set to %f seconds" % new_time)

func get_time_remaining() -> float:
	"""Get remaining time until trigger"""
	if has_triggered:
		return 0.0
	return max(0.0, auto_trigger_time - time_elapsed)

func is_triggered() -> bool:
	"""Check if artifact has been triggered"""
	return has_triggered
