extends Node3D

@onready var label: Label3D = $StartButton/Label3D

func _process(_delta):
	var frame_count = Engine.get_process_frames()
	label.text = "%d" % frame_count
