extends Node3D

@onready var label: Label3D = $StartButton/Label3D

func _process(_delta):
	var speed = Engine.time_scale
	label.text = "%.2fx" % speed
