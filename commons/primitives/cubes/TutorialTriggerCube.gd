# TutorialTriggerCube.gd
# A simple tutorial trigger that just requests a tutorial after a delay
# Completely decoupled from sequence management

extends Node3D
class_name TutorialTriggerCube

# Configuration
@export var rotation_speed: Vector3 = Vector3(0, 45, 0)
@export var hover_height: float = 0.1
@export var hover_speed: float = 2.0
@export var trigger_delay: float = 5.0
@export var one_time_only: bool = true

# Visual components
@onready var mesh_instance: MeshInstance3D

# State
var initial_position: Vector3
var time_elapsed: float = 0.0
var has_triggered: bool = false

# Signals
signal tutorial_requested()

func _ready():
	print("TutorialTriggerCube: Initializing - will request tutorial in %s seconds" % trigger_delay)
	
	# Store initial position
	initial_position = position
	
	# Setup visual components
	_setup_visual_components()
	
	print("TutorialTriggerCube: Ready - starting countdown")

func _setup_visual_components():
	# Create mesh instance
	mesh_instance = MeshInstance3D.new()
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(0.2, 0.2, 0.2)
	mesh_instance.mesh = cube_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.ORANGE
	material.emission = Color.ORANGE * 0.3
	material.metallic = 0.5
	material.roughness = 0.3
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
	print("TutorialTriggerCube: Visual components setup")

func _process(delta):
	# Rotate the cube
	rotation_degrees += rotation_speed * delta
	
	# Hover animation
	var hover_offset = sin(Time.get_time_dict_from_system().second * hover_speed) * hover_height
	position = initial_position + Vector3(0, hover_offset, 0)
	
	# Countdown to tutorial request
	if not has_triggered:
		time_elapsed += delta
		
		# Visual feedback showing countdown progress
		if mesh_instance and mesh_instance.material_override:
			var progress = time_elapsed / trigger_delay
			var intensity = 0.3 + progress * 0.7  # Gradually brighten
			mesh_instance.material_override.emission = Color.ORANGE * intensity
		
		# Check if it's time to request tutorial
		if time_elapsed >= trigger_delay:
			_request_tutorial()

func _request_tutorial():
	print("TutorialTriggerCube: Time reached - requesting tutorial!")
	
	has_triggered = true
	
	# Visual feedback for activation
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.emission = Color.YELLOW * 2.0
	
	# Emit tutorial request signal
	tutorial_requested.emit()
	
	# Flash effect
	await get_tree().create_timer(0.5).timeout
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.emission = Color.GREEN * 1.5
	
	# Remove self if one-time only
	if one_time_only:
		await get_tree().create_timer(1.0).timeout
		print("TutorialTriggerCube: One-time trigger complete, removing self")
		queue_free()

func force_trigger():
	"""Force trigger the tutorial request immediately"""
	if not has_triggered:
		_request_tutorial()

func reset_trigger():
	"""Reset the trigger for testing purposes"""
	has_triggered = false
	time_elapsed = 0.0
	rotation_degrees = Vector3.ZERO
	position = initial_position
	
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.emission = Color.ORANGE * 0.3 