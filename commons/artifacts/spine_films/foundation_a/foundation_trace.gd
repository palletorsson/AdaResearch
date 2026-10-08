extends "res://commons/artifacts/spine_films/film_stage.gd"
## Native presentation of drawTrace(), next-sample and join-next.
## These eight given candidates are NOT player tracking or live hand replay.
const G = preload("res://commons/artifacts/spine_films/early/geometry.gd")
const SOURCE := "res://commons/artifacts/spine_films/foundation_source.js"
const CANDIDATES := [Vector2(0,0),Vector2(.3,.1),Vector2(1,.2),Vector2(1.2,.1),Vector2(2,1),Vector2(3,1.5),Vector2(3.1,1.5),Vector2(4,0)]
const THRESHOLD := .8
const PINK := Color("ca628f")
const INK := Color("273330")
var manual_mode := false
var candidate_index := 0
var retained_indices: Array[int] = [0]
var joined_count := 0
var last_distance := 0.0
var last_from := 0
var last_kept := true
var last_operation := "start"
var status_text := "One starting position; no joined segments."
var sample_bodies: Array[MeshInstance3D] = []
var retained_bodies: Array[MeshInstance3D] = []
var links: Array[MeshInstance3D] = []
var list_cells: Array[MeshInstance3D] = []
var list_labels: Array[Label3D] = []
var halo: Node3D
var measure: MeshInstance3D
var distance_label: Label3D
var count_label: Label3D

func _build() -> void:
	title_text = "Read a candidate. Keep a position. Join a pair."
	duration = 28.0
	phases = ["EIGHT GIVEN CANDIDATES", "TEST THE NEXT POSITION", "READ THE REMAINING CANDIDATES", "JOIN RETAINED NEIGHBOURS"]
	notes = ["The list starts with one position. These eight candidates are supplied, not a live hand recording.", "Measure from the last retained position. Keep the candidate only when distance is at least 0.8 m.", "A rejected candidate does not become the next distance origin. Five of the eight positions remain.", "Each loop step joins one stored neighbour pair. Joining does not change the stored positions."]
	source_paths = [SOURCE]
	G.box(display,Vector3(0,.10,.25),Vector3(6.0,.20,4.2),Color("294052"))
	# Display coordinates use the source's two values as X and Z, with equal units.
	for i in range(CANDIDATES.size()):
		var at := location(i)
		sample_bodies.append(G.sphere(display,at,.055,Color("b7c0ba")))
		retained_bodies.append(G.sphere(display,at,.105,INK))
		G.line(display,at-Vector3(0,.09,0),at-Vector3(0,.03,0),Color("82909a"),.012)
	for i in range(7):
		links.append(G.line(display,Vector3.ZERO,Vector3.RIGHT,PINK,.025))
		var x := -2.4+i*.8
		list_cells.append(G.box(display,Vector3(x,.27,1.85),Vector3(.74,.13,.56),Color("e0ded5")))
		list_labels.append(G.label(display,"",Vector3(x,.48,1.85),INK,.14))
	halo = Node3D.new()
	display.add_child(halo)
	for i in range(32):
		var a := Vector3(cos(TAU*i/32.0)*.19,.03,sin(TAU*i/32.0)*.19)
		var b := Vector3(cos(TAU*(i+1)/32.0)*.19,.03,sin(TAU*(i+1)/32.0)*.19)
		G.line(halo,a,b,PINK,.012)
	measure = G.line(display,Vector3.ZERO,Vector3.RIGHT,G.GOLD,.009)
	distance_label = G.label(display,"",Vector3(0,.85,-1.5),G.GOLD,.20)
	count_label = G.label(display,"",Vector3(0,.35,2.63),G.WHITE,.15)
	evidence = {"source_functions":["drawTrace","next-sample click","join-next click"], "candidate_count":8,"distance_threshold":THRESHOLD,"initial_indices":[0],"expected_final_indices":[0,2,4,5,7],"metric":"Euclidean distance to the last retained sample, not the previous candidate","presentation":"Source (x,y) samples embedded as (x,constant,z), with equal units. No live hand or museum trace is read."}
	frame_scene(Vector3(0,.48,.35),9.8,.12,.63)

func location(index: int) -> Vector3:
	var p: Vector2 = CANDIDATES[index]
	return Vector3(p.x-2.0,.34,.75-p.y)

func _reset_record() -> void:
	candidate_index = 0
	retained_indices.assign([0])
	joined_count = 0
	last_distance = 0.0
	last_from = 0
	last_kept = true
	last_operation = "start"
	status_text = "One starting position; no joined segments."

func _read_candidate() -> bool:
	if candidate_index>=CANDIDATES.size()-1: return false
	candidate_index += 1
	last_from = retained_indices[-1]
	last_distance = (CANDIDATES[candidate_index] as Vector2).distance_to(CANDIDATES[last_from])
	last_kept = last_distance>=THRESHOLD
	last_operation = "read"
	if last_kept: retained_indices.append(candidate_index)
	status_text = "Distance %.2f m: %s" % [last_distance,"true, append this position." if last_kept else "false, leave the list unchanged."]
	return true

func _join_next() -> bool:
	if joined_count>=retained_indices.size()-1: return false
	joined_count += 1
	last_operation = "join"
	status_text = "Join points[%d] to points[%d]. The stored positions stay unchanged." % [joined_count-1,joined_count]
	return true

func _draw(time: float) -> void:
	if not manual_mode:
		_reset_record()
		var phase := phase_index(time)
		var u := phase_progress(time)
		var read_count := 0
		if phase==1: read_count = mini(4,1+int(u*4))
		elif phase==2: read_count = mini(7,5+int(u*3))
		elif phase==3: read_count = 7
		for i in range(read_count): _read_candidate()
		if phase==3:
			for i in range(mini(4,int(u*5))): _join_next()
	for i in range(CANDIDATES.size()):
		sample_bodies[i].visible = not retained_indices.has(i)
		retained_bodies[i].visible = retained_indices.has(i)
	for i in range(7):
		if i<joined_count:
			G.line_pose(links[i],location(retained_indices[i]),location(retained_indices[i+1]))
		else: links[i].visible = false
		list_cells[i].visible = i<retained_indices.size()
		list_labels[i].visible = i<retained_indices.size()
		if i<retained_indices.size():
			var p: Vector2 = CANDIDATES[retained_indices[i]]
			list_labels[i].text = "[%d]\n(%.1f, %.1f)" % [i,p.x,p.y]
	halo.position = location(candidate_index)
	var showing_join := last_operation=="join" or (not manual_mode and phase_index(time)==3)
	if showing_join:
		measure.visible = false
		distance_label.text = "Join a stored neighbour pair." if joined_count==0 else "Loop: points[%d] to points[%d]" % [joined_count-1,joined_count]
	elif candidate_index>0:
		G.line_pose(measure,location(last_from)+Vector3(0,.12,0),location(candidate_index)+Vector3(0,.12,0))
		distance_label.text = "%.2f m %s 0.8 / %s" % [last_distance,">=" if last_kept else "<","KEEP" if last_kept else "LEAVE OUT"]
	else:
		measure.visible = false
		distance_label.text = "Read a candidate before testing its distance."
	count_label.text = "points.size() = %d    /    joined segments = %d" % [retained_indices.size(),joined_count]

func experiment_controls() -> Array:
	return [{"key":"read","label":"READ NEXT"},{"key":"join","label":"JOIN PAIR"},{"key":"reset","label":"RESET"}]

func experiment_action(key: String) -> void:
	if key not in ["read","join","reset"]: return
	manual_mode = true
	running = false
	match key:
		"read": _read_candidate()
		"join": _join_next()
		"reset": _reset_record()
	refresh()

func refresh() -> void:
	super.refresh()
	if manual_mode and _note!=null:
		_note.text = status_text
		_footer.text = "MANUAL / READ a candidate / JOIN a retained pair / eight supplied samples, not a live hand"

func replay() -> void:
	manual_mode = false
	_reset_record()
	super.replay()

func state_snapshot() -> Dictionary:
	return {"candidate":candidate_index,"retained_indices":retained_indices.duplicate(),"joined":joined_count,"last_distance":last_distance,"last_from":last_from,"last_kept":last_kept,"manual":manual_mode}

func experiment_snapshot() -> Dictionary:
	var points: Array = []
	for index in retained_indices:
		var p: Vector2 = CANDIDATES[index]
		points.append([p.x,p.y])
	return {"candidate":candidate_index,"points":points,"indices":retained_indices.duplicate(),"joined":joined_count,"distance":last_distance,"last_from":last_from,"keep":last_kept,"manual":manual_mode}

func validation() -> Dictionary:
	var expected_indices: Array[int] = [0]
	for i in range(1,candidate_index+1):
		if (CANDIDATES[i] as Vector2).distance_to(CANDIDATES[expected_indices[-1]])>=THRESHOLD: expected_indices.append(i)
	var geometry_ok := true
	for i in range(CANDIDATES.size()):
		geometry_ok = geometry_ok and retained_bodies[i].visible==retained_indices.has(i) and retained_bodies[i].position.is_equal_approx(location(i))
	for i in range(7): geometry_ok = geometry_ok and links[i].visible==(i<joined_count)
	return {"passed":candidate_index>=0 and candidate_index<8 and retained_indices==expected_indices and joined_count>=0 and joined_count<retained_indices.size() and geometry_ok,"state":state_snapshot(),"evidence":evidence}
