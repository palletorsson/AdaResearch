extends Node3D

@onready var label: Label3D = $StartButton/Label3D

func _process(_delta):
	var mem_bytes = OS.get_static_memory_usage()
	var mem_mb = mem_bytes / (1024.0 * 1024.0)
	label.text = "%.2f MB" % mem_mb
