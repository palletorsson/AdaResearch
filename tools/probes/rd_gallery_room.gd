extends "res://tools/probes/sampling_room.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(1.0).timeout
	var stream = museum.get("_portal_stream")
	if stream != null:
		stream.set_process(false)
		stream.set_physics_process(false)
	var player = museum.get("_player")
	if player is Node3D:
		player.hide()
		player.set_process(false)
		player.set_physics_process(false)
		player.global_position = Vector3(0,-100,0)
	camera.set_cull_mask_value(19, false)
	var attributes := CameraAttributesPractical.new()
	attributes.exposure_multiplier = 0.28
	camera.attributes = attributes
	var desk := find_scene("/timing_machines/soft_workshop.gd")
	check("Existing live reaction desk remains", desk != null and desk.chapter == "reaction" and desk.model != null)
	if desk == null: return
	map_origin = desk.global_position - hall.global_basis * Vector3(8.5,0,6.5)
	await snapshot("gallery-approach", map_at(Vector3(22.5,1.7,26.1)), map_at(Vector3(22.5,0.9,35)), 65)
	await snapshot("gallery-inside", map_at(Vector3(22.5,1.7,31.6)), map_at(Vector3(24.7,0.9,33)), 65)
	await snapshot("gallery-in-hall", map_at(Vector3(27.2,2.2,27)), map_at(Vector3(21.7,0.9,37)), 62)
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	if spec.get("baseline", false):
		completed = true
		return
	var gallery: Node3D
	for node in hall.find_children("*", "Node3D", true, false):
		if node.get_meta("source", "") == "res://commons/rd_grammar/research_configs.json":
			gallery = node
			break
	check("Baked gallery installed in the actual museum", gallery != null)
	if gallery == null: return
	var count := 0
	for node in gallery.get_children():
		if node.has_meta("config"):
			count += 1
			check(str(node.name) + " has geometry, label and solid plinth", node.has_node("Field") and node.has_node("Parameters") and node.has_node("Plinth/Support"))
	check("All eighteen studies survive museum cartridge packing", count == 18)
	check("Gallery is a saved simulation, without a running solver", gallery.get_script() == null and gallery.get_meta("snapshot", false))
	var routes := [
		[Vector3(27,0,27),Vector3(27,0,60.5),Vector3(15.5,0,60.5),Vector3(15.5,0,62.5)],
		[Vector3(22.5,0,26),Vector3(22.5,0,59)]]
	var blocked: Array = []
	var gaps: Array = []
	var samples := 0
	for route in routes:
		for i in range(route.size()-1):
			var a: Vector3 = route[i]
			var b: Vector3 = route[i+1]
			var steps := ceili(a.distance_to(b)/0.25)
			for j in steps+1:
				var p := map_at(a.lerp(b,float(j)/steps)+Vector3.UP*0.01)
				samples += 1
				if not hits(p).is_empty(): blocked.append(xyz(p))
				if floor_at(p).is_empty(): gaps.append(xyz(p))
	check("Gallery aisle and onward route have capsule clearance", blocked.is_empty())
	check("Gallery aisle and onward route retain continuous floor", gaps.is_empty())
	observations.route = {"samples":samples,"blocked":blocked,"gaps":gaps}
	observations.scope = "Native museum render and collision checks. No physical headset test."
	completed = true
