extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Count-led studies. Two, three and four keep both count and rod lengths fixed.
## Presets arrange real grabbable segments; they do not constrain later movement.
signal arrangement_changed(bay: int, preset: String)
const ROD = preload("res://commons/artifacts/line_space_workshop/workshop_rod.gd")
const PRESETS = [["PARALLEL", "PLUS", "X", "SKEW", "RAILS", "DRAWING"], ["TRIANGLE", "OPEN", "DISPLACED"], ["SQUARE", "FOLD", "FOUR GRID"], ["SIX GRID", "SIX LIFT", "TETRAHEDRON", "CUBE"]]
const TITLES = ["TWO LINES", "THREE LINES", "FOUR LINES", "MORE LINES"]
const INKS = [Color("ffc468"), Color("76ddd5"), Color("ed99cf"), Color("a9bfed")]
var modes: Array[int] = [0, 0, 0, 0]
var rods: Array = [[], [], [], []]
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
	for bay in 4:
		var x := bay_x(bay)
		# Small pedestals carry the controls; the studies remain open to the hand.
		box(Vector3(x, 0.43, 0.77), Vector3(0.14, 0.86, 0.24), dark, true)
		box(Vector3(x, 0.91, 0.77), Vector3(0.84, 0.1, 0.33), dark, true)
		for edge in [-0.42, 0.42]:
			box(Vector3(x + edge, 0.96, 0.77), Vector3(0.014, 0.014, 0.33), brass)
		var button = PUSH.instantiate()
		button.rotation = Vector3.ZERO # Face upward on the tabletop.
		button.position = Vector3(x - 0.23, 1.0, 0.77)
		button.scale = Vector3.ONE * 1.25
		add_child(button)
		buttons["NEXT_%d" % bay] = button
		button.pressed.connect(next_preset.bind(bay))
		var caption := label("NEXT", Vector3(x - 0.23, 1.02, 0.92), 0.0011)
		caption.rotation_degrees.x = -65
		var reset_button = PUSH.instantiate()
		reset_button.rotation = Vector3.ZERO
		reset_button.position = Vector3(x + 0.23, 1.0, 0.77)
		reset_button.scale = Vector3.ONE * 1.25
		add_child(reset_button)
		buttons["RESET_%d" % bay] = reset_button
		reset_button.pressed.connect(reset_bay.bind(bay))
		caption = label("RESET", Vector3(x + 0.23, 1.02, 0.92), 0.0011)
		caption.rotation_degrees.x = -65
		caption = label(TITLES[bay], Vector3(x, 2.12, -0.42), 0.0011)
		caption.modulate = INKS[bay]
		caption = label("", Vector3(x, 1.18, 0.37), 0.0009)
		captions.append(caption)
	status = label("GRAB ANY LINE / TURN / DISPLACE / RELEASE\nRESET returns this arrangement. NEXT offers another.", Vector3(0, 0.55, 0.99), 0.0011)
	for bay in 4: reset_bay(bay)

func bay_x(bay: int) -> float:
	return (bay - 1.5) * 0.95

func next_preset(bay: int) -> void:
	if not can_reset(bay): return
	modes[bay] = (modes[bay] + 1) % PRESETS[bay].size()
	reset_bay(bay)

func can_reset(bay: int) -> bool:
	if bay < 0 or bay >= 4: return false
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
		"SKEW": prompt = "Across in view.\nApart in depth."
		"RAILS": prompt = "Look along them.\nThen step aside."
		"DRAWING": prompt = "Here two ends meet."
		"TRIANGLE": prompt = "Three edges close.\nCan they leave a plane?"
		"OPEN": prompt = "One edge turns.\nWhich join opens?"
		"DISPLACED": prompt = "One edge lifts away.\nWhat stops closing?"
		"SQUARE": prompt = "Four equal edges.\nA closed outline."
		"FOLD": prompt = "Still four. Still closed.\nStill flat?"
		"FOUR GRID": prompt = "Two by two.\nCrossings inside spans."
		"SIX GRID": prompt = "Three by three.\nSix rods, nine crossings."
		"SIX LIFT": prompt = "Same six rods.\nCrossings separate."
		"TETRAHEDRON": prompt = "Six edges suggest\nfour faces. No fill yet."
		"CUBE": prompt = "Twelve edges suggest\na body. No fill yet."
	captions[bay].text = "%d / %s\n%s" % [rods[bay].size(), preset, prompt]
	status.text = "GRAB ANY LINE / TURN / DISPLACE / RELEASE\nRESET returns this arrangement. NEXT offers another."
	arrangement_changed.emit(bay, preset)

func add_segment(bay: int, a: Vector3, b: Vector3) -> void:
	var rod = ROD.new()
	rod.name = "Bay%d_Line%d" % [bay + 1, rods[bay].size() + 1]
	rod.span = a.distance_to(b)
	rod.ink = INKS[bay]
	add_child(rod)
	rod.position = (a + b) * 0.5 + Vector3(bay_x(bay), 1.4, -0.23)
	rod.quaternion = Quaternion(Vector3.RIGHT, (b - a).normalized())
	rods[bay].append(rod)

func segments(bay: int, mode: int) -> Array:
	var out: Array = []
	if bay == 0:
		match mode:
			0:
				for y in [-0.18,0.18]: out.append([Vector3(-0.4,y,0),Vector3(0.4,y,0)])
			1: out = [[Vector3(-0.4,0,0),Vector3(0.4,0,0)],[Vector3(0,-0.4,0),Vector3(0,0.4,0)]]
			2:
				out = segments(0, 1)
				for pair in out:
					for i in 2: pair[i] = Quaternion(Vector3.FORWARD, PI / 4) * pair[i]
			3:
				out = segments(0, 1)
				for i in 2: out[1][i].z += 0.25
			4:
				for x in [-0.2,0.2]: out.append([Vector3(x,0,-0.4),Vector3(x,0,0.4)])
			5:
				for x in [-0.3,0.3]: out.append([Vector3(x,0.3-sqrt(0.8*0.8-x*x),0),Vector3(0,0.3,0)])
	elif bay == 1:
		out = loop_segments([Vector3(-0.3,-0.17320508,0),Vector3(0.3,-0.17320508,0),Vector3(0,0.34641016,0)])
		if mode == 1:
			out[2][1] = out[2][0] + Quaternion(Vector3.FORWARD, PI / 4) * (out[2][1] - out[2][0])
		elif mode == 2:
			for i in 2: out[2][i].z += 0.25
	elif bay == 2:
		var vertices := [Vector3(-0.3,-0.3,0),Vector3(0.3,-0.3,0),Vector3(0.3,0.3,0),Vector3(-0.3,0.3,0)]
		if mode == 1:
			# Fold D around diagonal AC: all four edge lengths and joins survive.
			vertices[3] = vertices[0] + Quaternion((vertices[2] - vertices[0]).normalized(), PI / 3) * (vertices[3] - vertices[0])
		out = loop_segments(vertices)
		if mode == 2:
			out = []
			for d in [-0.18,0.18]:
				out.append([Vector3(-0.3,d,0),Vector3(0.3,d,0)])
				out.append([Vector3(d,-0.3,0),Vector3(d,0.3,0)])
	else:
		if mode < 2: out = grid_segments(mode == 1)
		elif mode == 2:
			var vertices := [Vector3(1,1,1),Vector3(1,-1,-1),Vector3(-1,1,-1),Vector3(-1,-1,1)]
			for i in 4:
				for j in range(i + 1, 4): out.append([vertices[i] * (0.6 / sqrt(8.0)), vertices[j] * (0.6 / sqrt(8.0))])
		else:
			for z in [-0.3,0.3]:
				for y in [-0.3,0.3]: out.append([Vector3(-0.3,y,z),Vector3(0.3,y,z)])
				for x in [-0.3,0.3]: out.append([Vector3(x,-0.3,z),Vector3(x,0.3,z)])
			for x in [-0.3,0.3]:
				for y in [-0.3,0.3]: out.append([Vector3(x,y,-0.3),Vector3(x,y,0.3)])
	return out

func loop_segments(vertices: Array) -> Array:
	var out: Array = []
	for i in vertices.size(): out.append([vertices[i], vertices[(i + 1) % vertices.size()]])
	return out

func grid_segments(separated: bool) -> Array:
	var out: Array = []
	for d in [-0.2,0,0.2]:
		out.append([Vector3(-0.3,d,0.25 if separated else 0),Vector3(0.3,d,0.25 if separated else 0)])
		out.append([Vector3(d,-0.3,0),Vector3(d,0.3,0)])
	return out
