extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Count-led studies. Two, three and four keep both count and rod lengths fixed.
## The live geometry lives in its own filming world; only its images enter the hall.
signal arrangement_changed(bay: int, preset: String)
const ROD = preload("res://commons/artifacts/line_space_workshop/workshop_rod.gd")
const CAMERA_STUDY = preload("res://commons/artifacts/line_space_workshop/camera_study.gd")
const PRESETS = [["PARALLEL", "PLUS", "X", "SKEW", "RAILS", "DRAWING"], ["TRIANGLE", "OPEN", "DISPLACED"], ["SQUARE", "FOLD", "FOUR GRID"], ["SIX GRID", "SIX LIFT", "TETRAHEDRON", "CUBE"]]
const TITLES = ["TWO LINES", "THREE LINES", "FOUR LINES", "MORE LINES"]
const INKS = [Color("ffc468"), Color("76ddd5"), Color("ed99cf"), Color("a9bfed")]
var modes: Array[int] = [0, 0, 0, 0]
var rods: Array = [[], [], [], []]
var captions: Array[Label3D] = []
var studies: Array[Node3D] = []
var film_world: SubViewport
var film_set: Node3D

func label(text: String, at: Vector3, pixels: float = 0.002) -> Label3D:
	var card := super.label(text, at, pixels)
	# Keep metre dimensions, but rasterize small exhibit captions more clearly.
	card.font_size = 84
	card.pixel_size = pixels * 0.5
	card.outline_size = 2
	return card

const HOLD_SECONDS := 6.0
const MOVE_SECONDS := 5.0
const CYCLES = [[0,1,2,3,4,5], [0,1,0,2], [0,1,0,2], [0,1,2,3]]
var _phase: Array[String] = ["hold","hold","hold","hold"]
var _clock: Array[float] = [0.0,0.0,0.0,0.0]
var _cycle_index: Array[int] = [0,0,0,0]
var _target_modes: Array[int] = [0,0,0,0]
var _from: Array = [[],[],[],[]]
var _from_presence: Array = [[],[],[],[]]
var _fold_motion: Array[bool] = [false,false,false,false]

func _ready() -> void:
	film_world = SubViewport.new()
	film_world.name = "PrivateFilmingWorld"
	film_world.own_world_3d = true
	film_world.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(film_world)
	film_set = Node3D.new()
	film_set.name = "AnimatedLineSets"
	film_world.add_child(film_set)
	var brass := material("d6b774")
	box(Vector3(0, 0.003, 0), Vector3(3.8, 0.006, 2.3), material("354a50"))
	for x in [-1.9,1.9]: box(Vector3(x,0.01,0),Vector3(0.018,0.016,2.3),brass)
	for z in [-1.15,1.15]: box(Vector3(0,0.01,z),Vector3(3.8,0.016,0.018),brass)
	for bay in 4:
		var caption := label("",Vector3(bay_x(bay),2.12,-0.42),0.0011)
		caption.modulate = INKS[bay]
		captions.append(caption)
		var initial: Array = segments(bay,0)
		var reserve: Array = segments(3,3) if bay == 3 else initial
		for i in reserve.size():
			var edge: Array = initial[i] if i < initial.size() else reserve[i]
			var rod = ROD.new()
			rod.name = "Bay%d_Line%d" % [bay+1,i+1]
			rod.span = edge[0].distance_to(edge[1])
			rod.ink = INKS[bay]
			rod.film_layer = 1 << (16 + bay)
			film_set.add_child(rod)
			rod.transform = edge_pose(bay,edge)
			rod.set_presence(1.0 if i < initial.size() else 0.0)
			rods[bay].append(rod)
		show_count(bay,initial.size(),initial.size())
		var study := CAMERA_STUDY.new()
		study.name = "CameraStudy%d" % (bay + 1)
		study.workshop = self
		study.bay = bay
		add_child(study)
		studies.append(study)

func bay_x(bay: int) -> float:
	return (bay - 1.5) * 0.95

func edge_pose(bay: int, edge: Array) -> Transform3D:
	var direction: Vector3 = (edge[1]-edge[0]).normalized()
	return Transform3D(Basis(Quaternion(Vector3.RIGHT,direction)),(edge[0]+edge[1])*0.5+Vector3(bay_x(bay),1.4,-0.23))

func show_count(bay: int, before: int, after: int) -> void:
	captions[bay].text = "%d LINES" % after if before == after else "%d → %d LINES" % [before,after]

func _process(delta: float) -> void:
	# A stalled render frame should not skip the movement the visitor came to see.
	advance(minf(delta,0.1))

func advance(delta: float) -> void:
	for bay in 4:
		_clock[bay] += delta
		match _phase[bay]:
			"hold":
				if _clock[bay] >= HOLD_SECONDS:
					_cycle_index[bay] = (_cycle_index[bay]+1) % CYCLES[bay].size()
					begin_motion(bay,CYCLES[bay][_cycle_index[bay]],false)
			"move":
				var t := clampf(_clock[bay]/MOVE_SECONDS,0.0,1.0)
				apply_motion(bay,t*t*(3.0-2.0*t))
				if t >= 1.0:
					modes[bay] = _target_modes[bay]
					_phase[bay] = "hold"
					_clock[bay] = 0.0
					var count: int = segments(bay,modes[bay]).size()
					show_count(bay,count,count)
					arrangement_changed.emit(bay,PRESETS[bay][modes[bay]])

func begin_motion(bay: int, target: int, recovering: bool) -> void:
	_target_modes[bay] = target
	_from[bay] = []
	_from_presence[bay] = []
	for rod in rods[bay]:
		_from[bay].append(rod.transform)
		_from_presence[bay].append(rod.presence)
	_fold_motion[bay] = not recovering and bay == 2 and ((modes[bay] == 0 and target == 1) or (modes[bay] == 1 and target == 0))
	_phase[bay] = "move"
	_clock[bay] = 0.0
	show_count(bay,segments(bay,modes[bay]).size(),segments(bay,target).size())

func apply_motion(bay: int, t: float) -> void:
	var target: Array = segments(bay,_target_modes[bay])
	if _fold_motion[bay]:
		var fold := t if _target_modes[bay] == 1 else 1.0-t
		var edges: Array = segments(2,0)
		var a: Vector3 = edges[0][0]
		var c: Vector3 = edges[2][0]
		var d: Vector3 = edges[3][0]
		d = a + Quaternion((c-a).normalized(),fold*PI/3.0)*(d-a)
		edges[2][1] = d
		edges[3][0] = d
		for i in 4: rods[bay][i].transform = edge_pose(bay,edges[i])
		return
	for i in rods[bay].size():
		var rod = rods[bay][i]
		var start: Transform3D = _from[bay][i]
		var finish: Transform3D = edge_pose(bay,target[i]) if i < target.size() else start
		# Rigid translation plus quaternion rotation: never interpolate endpoint length.
		rod.transform = start.interpolate_with(finish,t)
		rod.set_presence(lerpf(_from_presence[bay][i],1.0 if i < target.size() else 0.0,t))

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
