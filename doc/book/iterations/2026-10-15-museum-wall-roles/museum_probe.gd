extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	root.size = Vector2i(1440, 1000)
	museum.call("flush_stamps")
	await create_timer(0.6).timeout
	var pages: Array = []
	var doors: Array = []
	for n in hall.get_children():
		if n.has_meta("em_showing"):
			pages.append({"index": n.get_meta("em_showing"), "position": xyz(n.position)})
		if n is Label3D and n.has_meta("em_speak"):
			observations[str(n.name)] = {"text": n.text, "position": xyz(n.position)}
	for n in museum.find_children("*", "Node3D", true, false):
		if n.has_node("PortalVeil"):
			var labels: Array = []
			for c in n.get_children():
				if c is Label3D: labels.append(c.text)
			doors.append({"name":str(n.name), "position":xyz(n.global_position-hall.global_position), "labels":labels})
	observations.pages = pages
	observations.doors = doors
	observations.frame_mode = hall.get_meta("em_wall_frames_mode", "legacy")
	observations.frame_count = hall.get_meta("em_wall_frames_visible", -1)
	if str(observations.frame_mode) == "off":
		check("quiet hall contains no wall frames or pick targets", pages.is_empty() and hall.get_node_or_null("WallFrames") == null)
		check("quiet hall contains no wall text or cards", hall.find_children("Speak*", "Label3D", false, false).is_empty() and hall.find_children("ShowingCard*", "", false, false).is_empty())
		var ledger: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder+"em_showing_cards.json"))
		var old_cards: Array = (ledger.get("cards",[]) as Array).filter(func(c): return str(c.get("chapter","")) == "randomness" and str(c.get("pearl","")) == str(hall.get_meta("em_pearl","")))
		check("editor ledger removes the hall's old frames", old_cards.is_empty())
	check("next hall destination remains visible", doors.size() == 1 and doors[0].labels.has("Random Entropy"))
	for node in museum.find_children("*", "Node3D", true, false):
		if node.has_node("PortalVeil"):
			var landing: Vector3 = node.to_global(Vector3(0,-0.05,1.0))
			check("exit still has supported approach", not floor_at(landing).is_empty())
			check("door frame retains its collision", node.has_node("FrameCollision"))
	var base := hall.global_position + Vector3(0, 0, 4)
	await snapshot("entry", base + Vector3(6.5,1.65,2.8), base + Vector3(6.5,1.65,14), 75)
	await snapshot("west-wall", base + Vector3(8,1.65,10), base + Vector3(0,1.65,15), 75)
	await snapshot("exit", base + Vector3(6.5,1.65,32), base + Vector3(6.5,1.65,39), 75)
	for d in doors:
		var pos := hall.global_position + Vector3(d.position[0],d.position[1],d.position[2])
		await snapshot("door-"+d.name, pos+Vector3(0,1.6,-4 if d.name.contains("Next") else 4), pos+Vector3(0,1.5,0), 65)
	observations.scope = "Native hall inspection; no headset acceptance."
