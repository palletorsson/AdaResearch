extends "res://algorithms/postprocessing/flashlight_demo/flashlight_demo.gd"
## Keep the museum board, faceted receiver and cube; gather their original lamps.
func _ready() -> void:
	super._ready()
	for i in range(4):
		var lamp: Node3D = get_node(["RedFlashlight","GreenFlashlight","BlueFlashlight","WhiteFlashlight"][i])
		preload("close_lamps.gd").arrange(lamp,i,0.4,-1.95)
