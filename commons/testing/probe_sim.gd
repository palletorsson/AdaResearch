extends SceneTree
## PROBE: the grid map as an installation in the reactor hall
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("_first_chapter", "transformation")
	m.set("start_map", "Trans_Introduction")
	get_root().add_child(m)
	await create_timer(8.0).timeout
	var sim: Node = m.find_child("Simulation_*", true, false)
	if sim == null:
		print("SIM: none found"); quit(1); return
	var bodies: int = 0
	var cubes: int = 0
	for n in sim.find_children("*", "Node3D", true, false):
		bodies += 1
		if String(n.name).to_lower().contains("transport"):
			cubes += 1
	var tele: int = 0
	for n in sim.find_children("*", "Node3D", true, false):
		if String(n.name).to_lower().contains("teleport"):
			tele += 1
	print("SIM: %s at %s — %d nodes, %d transport nodes, %d teleport nodes left (want 0)" % [sim.name, (sim as Node3D).global_position, bodies, cubes, tele])
	quit(0)
