extends "res://tools/probes/tape_rolls_main.gd"
## Focused native floor check; uses the real mouse pickup driver.
func run() -> void:
	root.size = Vector2i(1440,900);level = 3;photo_mode = "--capture" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	load("res://commons/void/game.gd").requested_floor = 3
	await start(false)
	var area: Node3D = station("setting_out");var field: Node3D = area.get_node("PairingPoints")
	await frames(8)
	check("Twelve existing points, three initial lines and six loose points",field.points.size()==12 and field.manager._connections.size()==3 and field.points.filter(func(p):return p.connected_points.is_empty()).size()==6)
	var reciprocal := true;var contained := true
	for pair in field.initial_pairs:
		var a: Node3D = field.points[pair.x];var b: Node3D = field.points[pair.y]
		reciprocal = reciprocal and a.is_connected_to(b) and b.is_connected_to(a) and field.manager.are_points_connected(a,b)
	for line in field.manager._connections.values():contained = contained and line.get_parent()==field and line._mesh_instance.mesh!=null
	check("Seeded lines use reciprocal native graph state",reciprocal)
	check("Actual line meshes remain inside the editable field",contained)
	check("Preconnected examples do not solve the entrance gate",not area.get_node("MeasurementRoom").unlocked)
	game.place_player(field.to_global(Vector3(.5,.06,2)));await frames(20)
	await photograph_tape(field,"pairing-preconnected")
	var b: Node3D = field.points[1];var line: Node3D = field.manager._connections.values().filter(func(l):return l.point_a==b or l.point_b==b)[0]
	var before: float = line.get_length()
	if await input_grab("Seeded endpoint / ",b,b.get_node("CollisionShape3D"),.4,.10):
		await input_tip_to(b,b.global_position+Vector3(.45,.25,.25));await frames(8);await drop_tool();await frames(8)
		check("An already-connected point still moves by native mouse pickup",absf(line.get_length()-before)>.12 and field.manager._connections.size()==3)
	var a: Node3D = field.points[2];b = field.points[3]
	if await input_grab("Loose endpoint / ",b,b.get_node("CollisionShape3D"),.4,.10):
		await input_tip_to(b,a.global_position+Vector3(.16,0,0));await frames(8);await drop_tool();await frames(12)
		check("A loose pair can still be joined by the player",field.manager._connections.size()==4 and a.is_connected_to(b))
	check("Player-created pairing also leaves the separate door closed",not area.get_node("MeasurementRoom").unlocked)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Actual saved Point Lines floor, reciprocal seeded graph and native desktop pickup/release of connected and loose endpoints. Adjacent asynchronous content excluded; physical headset not tested."}
	FileAccess.open(out.path_join("pairing-preconnected-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
