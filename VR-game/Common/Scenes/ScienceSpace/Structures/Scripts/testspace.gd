extends Node3D

@export var experiment_name: String 
@onready var label3d = $Label3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label3d.text = experiment_name
