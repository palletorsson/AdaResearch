extends Node3D

@export var profile_height: float = 1.0  # Change this value to modify height
@export var label_text: String = ""  # Label text
var profile: Node
var info: Node

func _ready():
	profile = get_node_or_null("GrabPaper/RandomEdgeProfile")
	info = get_node_or_null("GrabPaper/id_info_Label3D")
	
	if profile:
		profile.set_height(profile_height)  # Call method to set height
