extends Node3D

@onready var label: Label3D = $StartButton/Label3D

func _process(_delta):
	var calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	label.text = "%d" % calls
