extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## A fixed grammar produces records. Footprint and boundary policies make a place.
const PITCH := 0.2
const STRIDE := 4.0
const WIDTHS := [0.4, 1.4, 2.2]
var source: Node3D
var records: Dictionary
var width_index := 1
var built := false
var rooms_enabled := false
var show_rule := false
var address_revealed := false
var notice := ""
var occupied: Dictionary = {}
var room_cells: Dictionary = {}
var geometry: Node3D
var wall_count := 0
var room_addresses: Dictionary = {}
var program: Label3D

func _ready() -> void:
	source = get_parent()
	records = source.plan_records("branch", 1)
	for at in records.rooms: room_addresses[at] = true
	_build_compact_console(["PLAN", "BUILD", "WIDTH", "ROOMS", "RESET", "RULE"], "WHEN A LINE ACQUIRES WALLS")
	# A margin makes the experiment distinguishable from its supporting museum.
	box(Vector3(0, 0.003, -4), Vector3(11.6, 0.006, 11.6), material("243b41"))
	for x in [-5.8, 5.8]: box(Vector3(x, 0.015, -4), Vector3(0.025, 0.025, 11.6), material("bfa875", true))
	for z in [-9.8, 1.8]: box(Vector3(0, 0.015, z), Vector3(11.6, 0.025, 0.025), material("bfa875", true))
	program = label("", Vector3(0, 2.65, -4), 0.002)
	label("ENTER", Vector3(0, 0.025, 0.8), 0.0015).rotation_degrees.x = -90
	label("CONTINUE", Vector3(0, 0.025, -9.35), 0.0015).rotation_degrees.x = -90
	# The retained miniature stands at its old relative place in the rear collection.
	box(Vector3(0, 0.45, -23), Vector3(0.9, 0.9, 0.9), material("29414a"), true)
	label("ORIGINAL MODEL\nwarren / depth 3 / fitted display", Vector3(0, 0.65, -22.54), 0.0007)
	rebuild()
	_stage_hall.call_deferred()

func plan_point(p: Vector3) -> Vector2:
	return Vector2(p.z, -p.x) * STRIDE

func people_inside() -> bool:
	for group in ["em_walker", "player_body", "player"]:
		for person in get_tree().get_nodes_in_group(group):
			if person is Node3D:
				var p := to_local(person.global_position)
				if absf(p.x) < 5.8 and p.z > -9.8 and p.z < 1.8 and p.y > -1 and p.y < 4: return true
	return false

func act(id: String) -> void:
	notice = ""
	if id != "RULE" and people_inside():
		notice = "Someone is in the study. Leave the brass frame,\nthen press again to change its construction."
		refresh(); return
	show_rule = false
	match id:
		"PLAN": built = false
		"BUILD": built = true
		"WIDTH": width_index = (width_index + 1) % WIDTHS.size()
		"ROOMS":
			rooms_enabled = not rooms_enabled
			if rooms_enabled: address_revealed = true
		"RESET": width_index = 1; built = false; rooms_enabled = false; address_revealed = false
		"RULE": address_revealed = true; show_rule = true; refresh(); return
	rebuild()

func add_rectangle(target: Dictionary, low: Vector2, high: Vector2) -> void:
	# Coordinates are multiples of PITCH; epsilon excludes numerical boundary dust.
	for z in range(int(floor((low.y + 0.0001) / PITCH)), int(ceil((high.y - 0.0001) / PITCH))):
		for x in range(int(floor((low.x + 0.0001) / PITCH)), int(ceil((high.x - 0.0001) / PITCH))):
			target[Vector2i(x, z)] = true

func rebuild() -> void:
	if is_instance_valid(geometry): remove_child(geometry); geometry.queue_free()
	geometry = Node3D.new(); geometry.name = "Construction"; add_child(geometry)
	occupied.clear(); room_cells.clear(); wall_count = 0
	var half_width: float = WIDTHS[width_index] * 0.5
	for ends in records.segments:
		var a := plan_point(ends[0]); var b := plan_point(ends[1])
		add_rectangle(occupied, a.min(b) - Vector2.ONE * half_width, a.max(b) + Vector2.ONE * half_width)
	if rooms_enabled:
		for at in room_addresses:
			var p := plan_point(at)
			add_rectangle(room_cells, p - Vector2.ONE * 1.4, p + Vector2.ONE * 1.4)
		occupied.merge(room_cells)
	# Merge adjacent cells for small mesh/collider counts; union removes overlaps.
	for rect in rectangles(occupied):
		var c: Vector2 = (Vector2(rect.position) + Vector2(rect.size) * 0.5) * PITCH
		box(Vector3(c.x, 0.04 if built else 0.008, c.y), Vector3(rect.size.x * PITCH, 0.08 if built else 0.016, rect.size.y * PITCH), material("729d9c" if built else "42616a"), built, geometry)
	for rect in rectangles(room_cells):
		var c: Vector2 = (Vector2(rect.position) + Vector2(rect.size) * 0.5) * PITCH
		box(Vector3(c.x, 0.085 if built else 0.019, c.y), Vector3(rect.size.x * PITCH, 0.006, rect.size.y * PITCH), material("c19875"), false, geometry)
	if built: build_boundaries()
	# The same four centrelines remain visible in every construction.
	for ends in records.segments:
		var a := plan_point(ends[0]); var b := plan_point(ends[1]); var c := (a+b)*0.5
		box(Vector3(c.x, 0.096, c.y), Vector3(absf(b.x-a.x)+0.025, 0.015, absf(b.y-a.y)+0.025), material("fff0bb",true), false, geometry)
	refresh()

func rectangles(cells: Dictionary) -> Array[Rect2i]:
	var remaining := cells.duplicate(); var result: Array[Rect2i] = []
	while not remaining.is_empty():
		var origin: Vector2i = remaining.keys()[0]
		for key: Vector2i in remaining:
			if key.y < origin.y or (key.y == origin.y and key.x < origin.x): origin = key
		var width := 1
		while remaining.has(origin + Vector2i(width, 0)): width += 1
		var height := 1
		while true:
			var full := true
			for x in width:
				if not remaining.has(origin + Vector2i(x, height)): full = false; break
			if not full: break
			height += 1
		for z in height:
			for x in width: remaining.erase(origin + Vector2i(x,z))
		result.append(Rect2i(origin, Vector2i(width,height)))
	return result

func build_boundaries() -> void:
	var edges: Dictionary = {}
	var half_width: float = WIDTHS[width_index] * 0.5
	for cell: Vector2i in occupied:
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			# A shared edge is internal to the union, so it receives no wall.
			if occupied.has(cell + direction): continue
			var center := (Vector2(cell) + Vector2.ONE * 0.5 + Vector2(direction) * 0.5) * PITCH
			# Explicit openings at the two main-stem ends; side branches remain closed.
			if direction.x == 0 and absf(center.x) < half_width and (center.y >= half_width - 0.001 or center.y <= -8.0-half_width+0.001): continue
			var constant: int = cell.x + (1 if direction.x > 0 else 0) if direction.x != 0 else cell.y + (1 if direction.y > 0 else 0)
			var key := Vector3i(direction.x, direction.y, constant)
			if not edges.has(key): edges[key] = []
			edges[key].append(cell.y if direction.x != 0 else cell.x)
	for key: Vector3i in edges:
		var values: Array = edges[key]; values.sort()
		var start: int = values[0]; var previous: int = start
		for i in range(1,values.size()+1):
			if i < values.size() and values[i] == previous+1: previous=values[i]; continue
			wall_run(key,start,previous+1)
			if i < values.size(): start=values[i];previous=start

func wall_run(key: Vector3i, start: int, end: int) -> void:
	var length := (end-start)*PITCH
	var c := Vector3(key.z*PITCH+key.x*0.05,0.93,(start+end)*PITCH*0.5) if key.x != 0 else Vector3((start+end)*PITCH*0.5,0.93,key.z*PITCH+key.y*0.05)
	var size := Vector3(0.1,1.7,length) if key.x != 0 else Vector3(length,1.7,0.1)
	var glass := material("85bac1"); glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; glass.albedo_color.a=0.24
	box(c,size,glass,true,geometry)
	box(Vector3(c.x,0.34,c.z),Vector3(size.x,0.52,size.z),material("c6c4ae"),false,geometry)
	box(Vector3(c.x,1.79,c.z),Vector3(size.x+0.025,0.04,size.z+0.025),material("d4ad77"),false,geometry)
	wall_count += 1

func refresh() -> void:
	# Keep the two instructions available to trace before giving their shared address.
	var answer := " / 1 shared address" if address_revealed else ""
	program.text = "F[+RF][-RF]F\n4 moves / 2 room records" + answer
	if notice != "": readout.text=notice
	elif show_rule: readout.text="F: move / R: mark this position\n2 R records / 1 shared address\nWalls border the union; ends have explicit doors."
	else: readout.text=("%s / clear width %.1f m / rooms %s\n4 segments / 2 R records" + answer) % ["BUILT" if built else "PLAN",WIDTHS[width_index],"ON" if rooms_enabled else "OFF"]

func _stage_hall() -> void:
	var hall: Node = source
	while hall != null and not hall.has_meta("em_map"): hall=hall.get_parent()
	if hall == null or str(hall.get_meta("em_map")) != "LSystems_Architecture": return
	for light in hall.find_children("*","DirectionalLight3D",true,false): light.hide()
	for camera in hall.find_children("*","Camera3D",true,false): camera.current=false
	for caption in hall.find_children("*","Label3D",true,false):
		if not source.is_ancestor_of(caption) and caption.pixel_size > 0.002: caption.pixel_size=0.002
	for at in [Vector3(5,4,13),Vector3(16,4,13),Vector3(10.5,5,31)]:
		var light := OmniLight3D.new();light.position=at;light.omni_range=17;light.light_energy=3.2;hall.add_child(light)

func _build_compact_console(ids: Array, title: String) -> void:
	# All six controls fit within one standing position. Keep the physical
	# button size; compact the spacing instead of shrinking the touch targets.
	var casing := material("263a44")
	box(Vector3(0, 0.95, 2.0), Vector3(1.12, 0.12, 0.44), casing, true)
	for x in [-0.42, 0.42]:
		box(Vector3(x, 0.445, 2.0), Vector3(0.08, 0.89, 0.30), casing, true)
	for i in ids.size():
		var id: String = ids[i]
		var column: int = i % 3
		var row: int = i / 3
		var button = PUSH.instantiate()
		button.position = Vector3((column - 1) * 0.32, 1.045, 1.88 + row * 0.23)
		button.rotation = Vector3.ZERO
		button.scale = Vector3.ONE * 1.15
		add_child(button)
		buttons[id] = button
		button.pressed.connect(act.bind(id))
		var caption := label(id, button.position + Vector3(0, 0.01, 0.09), 0.00065)
		caption.rotation_degrees.x = -70
	box(Vector3(0, 0.90, 2.235), Vector3(1.12, 0.15, 0.025), casing)
	label(title, Vector3(0, 0.90, 2.252), 0.00063)

	# A single transparent plane avoids the doubled opacity of a glass box.
	# Text keeps an opaque outline, so the exhibit is visible behind the panel
	# while the reading remains distinct from its changing background.
	var panel := Node3D.new()
	panel.name = "TextPanel"
	add_child(panel)
	panel.position = Vector3(0, 1.27, 1.58)
	panel.rotation_degrees.x = -35
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	var pane := QuadMesh.new()
	pane.size = Vector2(1.18, 0.36)
	glass.mesh = pane
	var tint := StandardMaterial3D.new()
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	tint.albedo_color = Color(0.12, 0.25, 0.30, 0.14)
	glass.material_override = tint
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel.add_child(glass)
	for y in [-0.19, 0.19]:
		box(Vector3(0, y, 0), Vector3(1.22, 0.016, 0.016), casing, false, panel)
	for x in [-0.60, 0.60]:
		box(Vector3(x, 0, 0), Vector3(0.016, 0.38, 0.016), casing, false, panel)
	for x in [-0.48, 0.48]:
		box(Vector3(x, 1.09, 1.70), Vector3(0.018, 0.22, 0.018), casing)
	readout = label(title, Vector3.ZERO, 0.0011)
	readout.font_size = 28
	readout.outline_size = 7
	readout.outline_modulate = Color(0.025, 0.04, 0.055, 0.95)
	readout.reparent(panel, false)
	readout.position = Vector3(0, 0, 0.009)
