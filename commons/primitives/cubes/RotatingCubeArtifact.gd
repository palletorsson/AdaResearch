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
	
	# Instantiate the cube
	cube_instance = cube_scene.instantiate()
	cube_instance.scale = Vector3(0.5, 0.5, 0.5)
	# Add to scene and make visible
	add_child(cube_instance)
	cube_instance.visible = true
	
	# Find the mesh instance in the cube scene
	cube_mesh_instance = _find_mesh_instance(cube_instance)
	

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



func _process(delta):
	if not cube_instance:
		return
	
	# Rotate the cube
	cube_instance.rotation_degrees += rotation_speed * delta
	
	# Hover animation
	var hover_offset = sin(Time.get_time_dict_from_system().second * hover_speed) * hover_height
	position = initial_position + Vector3(0, hover_offset, 0)
	
