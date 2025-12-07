extends Node3D

@onready var label: Label3D = $StartButton/Label3D

func _process(_delta):
	var fps = Engine.get_frames_per_second()
	label.text = "%d FPS" % fps
