# RotatingCubeArtifact.gd
# A rotating cube artifact that can trigger sequences in the lab
# Part of the commons VR lab system

extends Node3D
class_name RotatingCubeArtifact

# Configuration
@export var rotation_speed: Vector3 = Vector3(0, 45, 0)  # degrees per second
@export var hover_height: float = 0.1
@export var hover_speed: float = 2.0
@export var interaction_timer: float = 4.0

# Visual components
@onready var mesh_instance: MeshInstance3D
@onready var collision_shape: CollisionShape3D
@onready var area: Area3D

# State
var initial_position: Vector3
var timer_active: bool = false
var timer_remaining: float = 0.0
var is_being_touched: bool = false

# Signals
signal artifact_activated()
signal sequence_triggered(sequence_name: String)

func _ready():
	print("RotatingCubeArtifact: Initializing")
	
	# Store initial position
	initial_position = position
	
	# Setup visual components
	_setup_visual_components()
	
	# Setup interaction
	_setup_interaction()
	
	print("RotatingCubeArtifact: Ready")

func _setup_visual_components():
	# Create mesh instance
	mesh_instance = MeshInstance3D.new()
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(0.2, 0.2, 0.2)
	mesh_instance.mesh = cube_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission = Color.CYAN * 0.3
	material.metallic = 0.5
	material.roughness = 0.3
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
	print("RotatingCubeArtifact: Visual components setup")

func _setup_interaction():
	# Create Area3D for interaction
	area = Area3D.new()
	area.name = "InteractionArea"
	
	# Create collision shape
	collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.3, 0.3, 0.3)  # Slightly larger than visual
	collision_shape.shape = shape
	
	area.add_child(collision_shape)
	add_child(area)
	
	# Connect signals
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	area.area_entered.connect(_on_area_entered)
	area.area_exited.connect(_on_area_exited)
	
	print("RotatingCubeArtifact: Interaction setup")

func _process(delta):
	# Rotate the cube
	rotation_degrees += rotation_speed * delta
	
	# Hover animation
	var hover_offset = sin(Time.get_time_dict_from_system().second * hover_speed) * hover_height
	position = initial_position + Vector3(0, hover_offset, 0)
	
	# Handle timer
	if timer_active:
		timer_remaining -= delta
		
		# Visual feedback during timer
		if mesh_instance and mesh_instance.material_override:
			var intensity = 0.3 + (1.0 - timer_remaining / interaction_timer) * 0.7
			mesh_instance.material_override.emission = Color.CYAN * intensity
		
		if timer_remaining <= 0.0:
			_trigger_sequence()

func _on_body_entered(body):
	print("RotatingCubeArtifact: Body entered: %s" % body.name)
	_start_interaction()

func _on_body_exited(body):
	print("RotatingCubeArtifact: Body exited: %s" % body.name)
	_stop_interaction()

func _on_area_entered(area_node):
	print("RotatingCubeArtifact: Area entered: %s" % area_node.name)
	# Check if it's a hand area
	if "Hand" in area_node.name or "hand" in area_node.name:
		_start_interaction()

func _on_area_exited(area_node):
	print("RotatingCubeArtifact: Area exited: %s" % area_node.name)
	if "Hand" in area_node.name or "hand" in area_node.name:
		_stop_interaction()

func _start_interaction():
	if not timer_active:
		print("RotatingCubeArtifact: Starting interaction timer (%s seconds)" % interaction_timer)
		timer_active = true
		timer_remaining = interaction_timer
		is_being_touched = true

func _stop_interaction():
	if timer_active and is_being_touched:
		print("RotatingCubeArtifact: Stopping interaction timer")
		timer_active = false
		timer_remaining = 0.0
		is_being_touched = false
		
		# Reset emission
		if mesh_instance and mesh_instance.material_override:
			mesh_instance.material_override.emission = Color.CYAN * 0.3

func _trigger_sequence():
	print("RotatingCubeArtifact: Timer completed - triggering sequence!")
	
	timer_active = false
	is_being_touched = false
	
	# Visual feedback for activation
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.emission = Color.WHITE
	
	# Emit signals
	artifact_activated.emit()
	sequence_triggered.emit("array_tutorial")
	
	# Reset after a moment
	await get_tree().create_timer(1.0).timeout
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.emission = Color.CYAN * 0.3

# Public API
func reset_artifact():
	timer_active = false
	timer_remaining = 0.0
	is_being_touched = false
	rotation_degrees = Vector3.ZERO
	position = initial_position 