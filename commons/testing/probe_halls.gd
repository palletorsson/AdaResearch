extends SceneTree
## PROBE: walk order of the 5 primitives halls as shipped
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("_first_chapter", "primitives")
	get_root().add_child(m)
	await create_timer(6.0).timeout
	m.set("_lazy_pending", 0)
	for i in range(4):
		m.call("_build_segment")
		await create_timer(0.3).timeout
	quit(0)
