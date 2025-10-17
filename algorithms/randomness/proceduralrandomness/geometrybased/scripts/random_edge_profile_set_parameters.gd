extends Node3D

@export var profile_height: float = 1.0  # Change this value to modify height
@export var label_text: String = ""  # Label text
@onready var profile = $GrabPaper/RandomEdgeProfile  # Get child node
@onready var info = $GrabPaper/id_info_Label3D # Get child node

func _ready():
	if profile:
		profile.set_height(profile_height)  # Call method to set height
