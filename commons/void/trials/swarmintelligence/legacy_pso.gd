extends "res://algorithms/swarmintelligence/particleswarmoptimization/particle_swarm_optimization.gd"
## Preserve the solver and its exact readings; place the screen overlay in space
## so the collection has the same readable instrument in desktop and XR.
var readout: Label3D

func setup_ui() -> void:
	super.setup_ui()
	performance_display.get_parent().hide()
	readout=Label3D.new();readout.name="OriginalSwarmReadings"
	readout.position=Vector3(12.6,1.5,5)
	readout.font_size=28;readout.pixel_size=.003
	readout.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	readout.outline_size=8;add_child(readout)

func _process(delta: float) -> void:
	super._process(delta)
	readout.text=performance_display.text
