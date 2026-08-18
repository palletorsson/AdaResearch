extends SceneTree
## Probe: open the LIVE plan at a chapter + map (as the Inspector would) and
## build 4 segments; print what each segment says it is.
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var m: Node3D = ps.instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("start_chapter", "primitives")
	m.set("start_map", "Point_Lines")
	get_root().add_child(m)
	await create_timer(0.8).timeout
	for i in range(3):
		m.call("_build_segment")
		await create_timer(0.2).timeout
	quit(0)
