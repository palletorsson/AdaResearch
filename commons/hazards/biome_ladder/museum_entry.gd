extends RefCounted
const Route := preload("res://commons/hazards/biome_ladder/route.gd")

static func mount(museum: Node3D, hall: Node3D, tile: Array) -> Node3D:
	var stage := Route.index_for_map(str(hall.get_meta("em_map", "")))
	if stage < 0 or tile.is_empty() or hall.has_node("BiomeLadderEntry"): return null
	var end := int(hall.get_meta("em_passage_start", -1))
	var row := clampi(end - 1 if end > 0 else tile.size() - 1, 0, tile.size() - 1)
	var columns: Array[int] = []
	for x in range(tile[row].size()):
		if str(tile[row][x]) in ["1", "1s"]: columns.append(x)
	if columns.is_empty(): return null
	var door_x := (float(columns[0]) + float(columns[-1])) * 0.5
	# Stand inside the room, not inside the generated portal's thick jamb.
	row = maxi(0, row - 2)
	var best_x := -1
	var best_distance := INF
	# These two halls have a centre-line exit pedestal. Keep its approach free.
	var desired_x := door_x + (2.0 if stage >= 2 else 0.0)
	for x in range(tile[row].size()):
		if not str(tile[row][x]) in ["1", "1s"]: continue
		var distance := absf(float(x) - desired_x)
		if distance < best_distance: best_x = x; best_distance = distance
	if best_x < 0: return null
	# Small reachable control beside the existing route; never seals its exit.
	var entry := Node3D.new(); entry.name = "BiomeLadderEntry"
	entry.position = Vector3(best_x + 0.5, 0, 4 + row + 0.4)
	entry.rotation.y = PI
	hall.add_child(entry)
	var button: Node3D = load("res://commons/interactables/cube_button.tscn").instantiate()
	button.position.y = 1.08; button.label = "ENTER BIOME"; button.accent = Color(0.85, 0.85, 0.85)
	entry.add_child(button)
	var entering := [false]
	button.pressed.connect(func():
		if entering[0]: return
		entering[0] = true
		Route.enter(museum, stage, true))
	var label := Label3D.new(); label.text = "BIOME / " + Route.STAGES[stage].title + "\nEnter the next world"
	label.position.y = 1.48; label.font_size = 28; label.pixel_size = 0.0016; label.outline_size = 3
	entry.add_child(label)
	return entry
