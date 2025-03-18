extends Resource
class_name SpaceConfiguration

# Basic information
@export var id: String = "space_1"
@export var display_name: String = "Space 1"
@export var description: String = ""

# Position and orientation
@export var position: Vector3 = Vector3.ZERO
@export var rotation: Vector3 = Vector3.ZERO
@export var scale: Vector3 = Vector3.ONE

# Data paths
@export_file("*.gd") var structure_data_path: String = ""
@export_file("*.gd") var utility_data_path: String = ""
@export_file("*.gd") var interactable_data_path: String = ""

# Connections to other spaces
@export var connected_spaces: Array[String] = []

# Additional properties
@export var properties: Dictionary = {}

func _init(p_id: String = "space_1", p_name: String = "Space 1"):
	id = p_id
	display_name = p_name
