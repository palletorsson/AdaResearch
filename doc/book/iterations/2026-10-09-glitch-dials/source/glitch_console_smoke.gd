extends SceneTree
func _initialize()->void:run.call_deferred()
func run()->void:
	var console=load("res://commons/artifacts/camera_glitch_study/glitch_console.gd").new()
	root.add_child(console)
	for i in 4:await process_frame
	assert(console.effect_dial!=null and console.amount_dial!=null and console.buttons.size()==7)
	console.show_state(true,9,"10 / READ EVERY OTHER ROW BACKWARDS",.6,true,true)
	assert(is_equal_approx(console.effect_dial.get_normalized_value(),1.0))
	assert(is_equal_approx(console.amount_dial.get_normalized_value(),.6))
	print("GLITCH CONSOLE INITIALISED")
	quit(0)
