extends SceneTree
func _initialize()->void:run.call_deferred()
func run()->void:
	var model=load("res://commons/artifacts/primitive_encounters/wedge_mouse_model.tscn").instantiate()
	root.add_child(model);await create_timer(0.4).timeout
	for b in [model.jump_button,model.home_button,model.reset_button]:
		print("CONTROL ",b.name," basis ",b.basis," cap ",model.to_local(b.get_node("Button/ButtonMesh").global_position)," root ",b.position)
	quit()
