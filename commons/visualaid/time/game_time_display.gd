extends Node3D

@onready var label: Label3D = $StartButton/Label3D

func _process(_delta):
	# Calculate session duration
	var ticks = Time.get_ticks_msec()
	var total_seconds = ticks / 1000
	var seconds = total_seconds % 60
	var minutes = (total_seconds / 60) % 60
	var hours = (total_seconds / 3600)
	
	label.text = "%02d:%02d:%02d" % [hours, minutes, seconds]
