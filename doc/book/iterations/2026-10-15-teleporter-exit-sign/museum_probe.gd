extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	root.size = Vector2i(1440,1000)
	museum.call("flush_stamps")
	await create_timer(0.8).timeout
	var navigation: Node3D = museum.get("_portal_stream")
	if navigation != null: navigation.set_process(false)
	var frame := hall.get_node_or_null("HallPortals/NextHall") as Node3D
	var sign := hall.get_node_or_null("HallPortals/NextHall/ExitSign") as Node3D
	check("exit sign is mounted on the working teleporter", sign != null)
	var signs: Array = []
	for node in hall.find_children("*", "Node3D", true, false):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("/exit_sign.gd"):
			signs.append(str(node.get_path()))
	observations.exit_signs = signs
	check("no duplicate exit sign remains on the walls", signs.size() == 1)
	if frame == null: return
	await snapshot("exit-sign", frame.to_global(Vector3(-1.6,1.65,4.4)), frame.to_global(Vector3(0,1.6,0)), 58)
	await snapshot("exit-sign-detail", frame.to_global(Vector3(0,2.3,2.0)), frame.to_global(Vector3(0,2.5,0)), 48)
	observations.scope = "Native museum placement and rendered legibility; teleporter behavior unchanged."
