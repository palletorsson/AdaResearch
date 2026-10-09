extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Three linked studies: directions in a plane, separation in depth, viewpoint.
## Presets arrange real grabbable segments; they do not constrain later movement.
signal arrangement_changed(bay: int, preset: String)
const ROD = preload("res://commons/artifacts/line_space_workshop/workshop_rod.gd")
const PRESETS = [["PARALLEL", "PLUS", "X", "GRID"], ["FLAT", "LIFT", "FRAME"], ["RAILS", "DRAWING"]]
const TITLES = ["1 / COMBINE", "2 / LEAVE THE PLANE", "3 / CHANGE YOUR VIEW"]
const INKS = [Color("ffc468"), Color("76ddd5"), Color("ed99cf")]
var modes: Array[int] = [0, 0, 0]
var rods: Array = [[], [], []]
var captions: Array[Label3D] = []
var status: Label3D

func label(text: String, at: Vector3, pixels: float = 0.002) -> Label3D:
	var card := super.label(text, at, pixels)
	# Keep metre dimensions, but rasterize small exhibit captions more clearly.
	card.font_size = 84
	card.pixel_size = pixels * 0.5
	card.outline_size = 2
	return card

func _ready() -> void:
	var brass := material("d6b774")
	var dark := material("243b43")
	box(Vector3(0, 0.003, 0), Vector3(3.8, 0.006, 2.3), material("354a50"))
	for x in [-1.9, 1.9]: box(Vector3(x, 0.01, 0), Vector3(0.018, 0.016, 2.3), brass)
	for z in [-1.15, 1.15]: box(Vector3(0, 0.01, z), Vector3(3.8, 0.016, 0.018), brass)
	for bay in 3:
		var x := (bay - 1) * 1.25
		# Small pedestals carry the controls; the studies remain open to the hand.
		box(Vector3(x, 0.43, 0.77), Vector3(0.14, 0.86, 0.24), dark, true)
		box(Vector3(x, 0.91, 0.77), Vector3(1.05, 0.1, 0.33), dark, true)
		box(Vector3(x, 0.96, 0.77), Vector3(1.05, 0.014, 0.33), brass)
		var button = PUSH.instantiate()
		button.rotation = Vector3.ZERO # Face upward on the tabletop.
		button.position = Vector3(x - 0.3, 1.0, 0.77)
		button.scale = Vector3.ONE * 1.25
		add_child(button)
		buttons["NEXT_%d" % bay] = button
		button.pressed.connect(next_preset.bind(bay))
		var caption := label("NEXT", Vector3(x - 0.3, 1.02, 0.92), 0.0011)
		caption.rotation_degrees.x = -65
		var reset_button = PUSH.instantiate()
		reset_button.rotation = Vector3.ZERO
		reset_button.position = Vector3(x + 0.3, 1.0, 0.77)
		reset_button.scale = Vector3.ONE * 1.25
		add_child(reset_button)
		buttons["RESET_%d" % bay] = reset_button
		reset_button.pressed.connect(reset_bay.bind(bay))
		caption = label("RESET", Vector3(x + 0.3, 1.02, 0.92), 0.0011)
		caption.rotation_degrees.x = -65
		caption = label(TITLES[bay], Vector3(x, 2.12, -0.42), 0.0011)
		caption.modulate = INKS[bay]
		caption = label("", Vector3(x, 1.13, 0.951), 0.0009)
		captions.append(caption)
	status = label("GRAB ANY LINE / TURN / DISPLACE / RELEASE\nRESET returns this arrangement. NEXT offers another.", Vector3(0, 0.55, 0.99), 0.0011)
	# A sighting frame locates one possible view; there is no projected-image trick.
	for x in [-0.11, 0.11]: box(Vector3(1.25+x, 1.4, 1.04), Vector3(0.012,0.22,0.012), brass)
	for y in [1.29, 1.51]: box(Vector3(1.25,y,1.04),Vector3(0.23,0.012,0.012),brass)
	for bay in 3: reset_bay(bay)

func next_preset(bay: int) -> void:
	if not can_reset(bay): return
	modes[bay] = (modes[bay] + 1) % PRESETS[bay].size()
	reset_bay(bay)

func can_reset(bay: int) -> bool:
	if bay < 0 or bay >= 3: return false
	for rod in rods[bay]:
		if is_instance_valid(rod) and rod.is_picked_up():
			status.text = "Release the line before changing its arrangement."
			return false
	return true

func reset_bay(bay: int) -> void:
	if not can_reset(bay): return
	for rod in rods[bay]:
		if is_instance_valid(rod):
			rod.get_parent().remove_child(rod)
			rod.queue_free()
	rods[bay] = []
	for pair in segments(bay, modes[bay]): add_segment(bay, pair[0], pair[1])
	var preset: String = PRESETS[bay][modes[bay]]
	var prompt := ""
	match preset:
		"PARALLEL": prompt = "Keep a direction.\nChange the spacing."
		"PLUS": prompt = "Two directions share a crossing."
		"X": prompt = "Turn the crossing. What stayed?"
		"GRID": prompt = "Repeat both directions.\nLift one line."
		"FLAT": prompt = "All six lines share one plane."
		"LIFT": prompt = "A crossing in view;\na gap in depth."
		"FRAME": prompt = "Edges suggest a body.\nNo face yet."
		"RAILS": prompt = "Look along them; then step aside."
		"DRAWING": prompt = "Here the lines really meet."
	captions[bay].text = "%s\n%s" % [preset, prompt]
	status.text = "GRAB ANY LINE / TURN / DISPLACE / RELEASE\nRESET returns this arrangement. NEXT offers another."
	arrangement_changed.emit(bay, preset)

func add_segment(bay: int, a: Vector3, b: Vector3) -> void:
	var rod = ROD.new()
	rod.name = "Bay%d_Line%d" % [bay + 1, rods[bay].size() + 1]
	rod.span = a.distance_to(b)
	rod.ink = INKS[bay]
	add_child(rod)
	rod.position = (a + b) * 0.5 + Vector3((bay - 1) * 1.25, 1.4, -0.23)
	rod.quaternion = Quaternion(Vector3.RIGHT, (b - a).normalized())
	rods[bay].append(rod)

func segments(bay: int, mode: int) -> Array:
	var out: Array = []
	if bay == 0:
		match mode:
			0:
				for y in [-0.3,-0.1,0.1,0.3]: out.append([Vector3(-0.42,y,0),Vector3(0.42,y,0)])
			1: out = [[Vector3(-0.4,0,0),Vector3(0.4,0,0)],[Vector3(0,-0.4,0),Vector3(0,0.4,0)]]
			2: out = [[Vector3(-0.3,-0.3,0),Vector3(0.3,0.3,0)],[Vector3(-0.3,0.3,0),Vector3(0.3,-0.3,0)]]
			3: out = grid_segments(false)
	elif bay == 1:
		if mode < 2: out = grid_segments(mode == 1)
		else:
			for z in [-0.3,0.3]:
				for y in [-0.3,0.3]: out.append([Vector3(-0.3,y,z),Vector3(0.3,y,z)])
				for x in [-0.3,0.3]: out.append([Vector3(x,-0.3,z),Vector3(x,0.3,z)])
			for x in [-0.3,0.3]:
				for y in [-0.3,0.3]: out.append([Vector3(x,y,-0.3),Vector3(x,y,0.3)])
	else:
		if mode == 0:
			for x in [-0.35,0,0.35]: out.append([Vector3(x,0,-0.55),Vector3(x,0,0.55)])
		else:
			for x in [-0.35,0,0.35]: out.append([Vector3(x,-0.35,0),Vector3(0,0.35,0)])
	return out

func grid_segments(separated: bool) -> Array:
	var out: Array = []
	for d in [-0.3,0,0.3]:
		out.append([Vector3(-0.42,d,0.25 if separated else 0),Vector3(0.42,d,0.25 if separated else 0)])
		out.append([Vector3(d,-0.42,0),Vector3(d,0.42,0)])
	return out
