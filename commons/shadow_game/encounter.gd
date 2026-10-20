extends Node3D
## Make a crossing. Three persistent objects, one physical relation at a time.
const PointBody := preload("res://commons/shadow_game/point.gd")
const Piece := preload("res://commons/shadow_game/piece.gd")
const BoxBody := preload("res://commons/museum_runner/forms/box_body.gd")
const LineSkin := preload("res://commons/museum_runner/forms/line_skin.gd")
const SocketFrame := preload("res://commons/shadow_game/socket_frame.gd")
const HOMES := {"sphere": Vector3(0, 1.12, 3.7), "cube": Vector3(-2.05, 1.2, 2.5), "stick": Vector3(1.8, 1.25, 1.8)}
const CUBE_SOCKET := Vector3(-1.65, 1.08, -0.2)
const POINT_SOCKET := Vector3(0, 1.12, -6.1)
const MAX_SAMPLES := 256
const SPACING := 0.12
signal changed
signal crossing_completed
var save_path := "user://shadow-game/world-v1.json"
var objects: Dictionary = {}
var placed: Dictionary = {}
var samples: Array[Dictionary] = []
var trace_root: Node3D
var bridge: AnimatableBody3D
var bridge_target := PI / 2.0
var powered := false
var completed := false
var restored := false
var save_error := ""
var stroke_start := true
var readout: Label3D
var socket_material: StandardMaterial3D
var goal_material: StandardMaterial3D
var goal_label: Label3D
var menu_action: Callable
var museum_action: Callable
var menu_button: Node3D
var recall_button: Node3D
var reset_button: Node3D
var _reset_armed_until := 0

func _ready() -> void:
	_build_place()
	_build_objects()
	trace_root = Node3D.new()
	trace_root.name = "KeptTrace"
	add_child(trace_root)
	load_game()
	_refresh()

func _build_place() -> void:
	# Raised museum fragments over a real biome. The gap has no hidden floor.
	_box(self, Vector3(0, -0.22, 3), Vector3(8, 0.44, 8), Color("29383f"), true)
	_box(self, Vector3(0, -0.22, -7.4), Vector3(8, 0.44, 6.8), Color("29383f"), true)
	for x in [-4.0, 4.0]:
		_box(self, Vector3(x, 0.1, 3), Vector3(0.12, 0.2, 8), Color("403f3e"), true)
	# A short museum passage behind arrival frames the view towards the biome.
	for x in [-2.7, 2.7]:
		_box(self, Vector3(x, 2, 6.55), Vector3(2.5, 4, 0.28), Color("e7e4d9"), true)
	_box(self, Vector3(0, 3.55, 6.55), Vector3(3, 0.9, 0.28), Color("e7e4d9"), true)
	var title := _label("ENDLESS MUSEUM", Vector3(0, 3.62, 6.36), 0.0023, 50)
	title.rotation.y = PI
	var subtitle := _label("always another room", Vector3(0, 3.30, 6.36), 0.0016, 30)
	subtitle.rotation.y = PI
	_label("SHADOW GAME", Vector3(0, 2.9, -9.6), 0.0040, 68)
	_label("a world made from what you learn", Vector3(0, 2.47, -9.59), 0.0020, 34)
	for x in [-2.7, 2.7]:
		_box(self, Vector3(x, 1.8, -9.8), Vector3(0.18, 3.6, 0.18), Color("aaa697"), true)
	_box(self, Vector3(0, 3.6, -9.8), Vector3(5.58, 0.18, 0.18), Color("aaa697"), true)
	for key in HOMES:
		var at: Vector3 = HOMES[key]
		var height: float = 0.98 if key == "sphere" else (0.98 if key == "cube" else 0.86)
		_box(self, Vector3(at.x, height/2, at.z), Vector3(0.48, height, 0.48), Color("ece8dc"), true)
	_label("THE POINT", Vector3(0, 0.67, 3.95), 0.0011, 28)
	_label("TAKE THE CUBE", Vector3(-2.05, 1.75, 2.5), 0.0015, 28)
	_label("HOLD THE STICK\nTrigger turns the bridge", Vector3(1.8, 1.95, 1.8), 0.0014, 27)
	_box(self, CUBE_SOCKET - Vector3(0, 0.66, 0), Vector3(0.72, 0.84, 0.72), Color("333e40"), true)
	var socket := _box(self, CUBE_SOCKET - Vector3(0, 0.23, 0), Vector3(0.66, 0.02, 0.66), Color("d69fae"))
	socket_material = socket.material_override
	_frame(CUBE_SOCKET, Vector3.ONE * 0.48, Color("e9b5c7"))
	_label("1  /  PLACE THE CUBE", CUBE_SOCKET + Vector3(0, 0.9, 0), 0.00145, 28)
	_box(self, Vector3(0, 0.49, -6.1), Vector3(0.55, 0.98, 0.55), Color("ece8dc"), true)
	var dish := _box(self, POINT_SOCKET - Vector3(0, 0.13, 0), Vector3(0.4, 0.025, 0.4), Color("9da49b"))
	goal_material = dish.material_override
	goal_label = _label("3  /  BRING THE POINT", POINT_SOCKET + Vector3(0, 0.72, 0), 0.0017, 30)
	bridge = AnimatableBody3D.new()
	bridge.name = "TurningBridge"
	bridge.sync_to_physics = false
	bridge.position = Vector3(0, -0.06, -0.9)
	bridge.rotation.y = PI/2
	add_child(bridge)
	var beam := _box(bridge, Vector3(0, 0, -1.7), Vector3(1.6, 0.12, 3.4), Color("3d4949"))
	var shape := BoxShape3D.new()
	shape.size = beam.mesh.size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = beam.position
	bridge.add_child(collider)
	for x in [-0.73, 0.73]:
		_box(bridge, Vector3(x, 0.071, -1.7), Vector3(0.035, 0.018, 3.4), Color("e6b1c5"))
	for i in range(1, 8):
		_box(bridge, Vector3(0, 0.064, -i * 0.43), Vector3(1.45, 0.008, 0.015), Color("77847d"))
	_label("2  /  TURN A LINE INTO A CROSSING", Vector3(0, 0.04, -0.25), 0.0014, 27).rotation.x = -PI/2
	readout = _label("", Vector3(-2.1, 1.7, 5.55), 0.0016, 28)
	readout.rotation.y = PI
	var instructions := _label("PLACE THE CUBE  /  TURN WITH THE STICK  /  CARRY THE POINT\nA fall returns you here. Your objects remain.", Vector3(0, 2.4, 6.35), 0.0014, 26)
	instructions.rotation.y = PI
	# Reachable buttons face towards the start; gaze is not required for gameplay.
	menu_button = _button("MAIN MENU", Vector3(2.7, 1.1, 4.5), func(): if menu_action.is_valid(): menu_action.call())
	_button("MUSEUM", Vector3(2.7, 1.4, 4.5), func(): if museum_action.is_valid(): museum_action.call())
	recall_button = _button("RECALL LOOSE OBJECTS", Vector3(-2.7, 1.1, 4.5), recall_loose)
	reset_button = _button("RESET · PRESS TWICE", Vector3(-2.7, 1.4, 4.5), request_reset)

func _build_objects() -> void:
	for key in HOMES:
		var body: XRToolsPickable
		if key == "sphere": body = PointBody.new()
		else:
			body = Piece.new()
			body.form = key
		body.name = key.capitalize()
		body.position = HOMES[key]
		body.set_meta("shadow_identity", key)
		add_child(body)
		objects[key] = body
		placed[key] = body.transform
		body.dropped.connect(func(_object): _released.call_deferred(key))
		body.picked_up.connect(func(_object): _taken(key))
	objects.stick.action_pressed.connect(func(_object): turn_bridge())

func _taken(key: String) -> void:
	if key == "sphere": stroke_start = true
	_refresh()

func _released(key: String) -> void:
	var body: Node3D = objects[key]
	if body.is_held(): return
	if body.position.y < -0.6 or absf(body.position.x) > 8 or body.position.z < -12 or body.position.z > 8:
		body.transform = placed[key]
	if key == "cube" and body.position.distance_to(CUBE_SOCKET) < 0.48:
		body.position = CUBE_SOCKET
		body.rotation = Vector3.ZERO
	if key == "sphere" and body.position.distance_to(POINT_SOCKET) < 0.4 and bridge_open() and cube_in_place():
		body.position = POINT_SOCKET
		if not completed:
			completed = true
			crossing_completed.emit()
	placed[key] = body.transform
	_refresh()
	save_game()

func cube_in_place() -> bool:
	return not objects.cube.is_held() and objects.cube.position.distance_to(CUBE_SOCKET) < 0.08

func bridge_open() -> bool: return absf(bridge.rotation.y) < 0.015

func turn_bridge() -> bool:
	if not objects.stick.is_held() or not cube_in_place(): return false
	# Ignore repeats while turning: one press gives one unambiguous quarter-turn.
	if absf(bridge.rotation.y - bridge_target) > 0.001: return false
	bridge_target = PI/2 if bridge_open() else 0.0
	changed.emit()
	return true

func _physics_process(delta: float) -> void:
	var now_powered := cube_in_place()
	if powered != now_powered:
		powered = now_powered
		_refresh()
	if powered and absf(bridge.rotation.y - bridge_target) > 0.0001:
		bridge.rotation.y = move_toward(bridge.rotation.y, bridge_target, delta * 0.65)
		if is_equal_approx(bridge.rotation.y, bridge_target):
			_refresh()
			save_game()
	if objects.sphere.is_held(): _sample(objects.sphere.position)

func _sample(at: Vector3) -> void:
	if samples.size() >= MAX_SAMPLES: return
	if not stroke_start and not samples.is_empty() and _vector(samples[-1].p).distance_to(at) < SPACING: return
	var entry := {"p": [at.x, at.y, at.z], "start": stroke_start}
	if not stroke_start and not samples.is_empty(): _trace_segment(_vector(samples[-1].p), at)
	samples.append(entry)
	stroke_start = false
	if samples.size() == MAX_SAMPLES: readout.text += "\nTrace full. Your drawing is kept."

func _trace_segment(a: Vector3, b: Vector3) -> void:
	var line := LineSkin.new()
	line.show_segment(a, b-a, a.distance_to(b))
	trace_root.add_child(line)

func _refresh() -> void:
	if objects.is_empty(): return
	powered = cube_in_place()
	socket_material.albedo_color = Color("d6f1cb") if powered else Color("d69fae")
	goal_material.albedo_color = Color("e9b4d0") if completed else Color("9da49b")
	goal_label.text = "YOU MADE A CROSSING\nYour trace stays." if completed else "3  /  BRING THE POINT"
	readout.text = "THE CROSSING REMAINS\nMove the objects. Make another arrangement." if completed else ("Carry the point across." if bridge_open() else ("Hold the stick. Press trigger." if powered else "The cube gives the hinge a place to begin."))
	if not save_error.is_empty(): readout.text += "\nCould not save this visit."
	changed.emit()

func recall_loose() -> void:
	for key in objects:
		var body: Node3D = objects[key]
		if body.is_held(): continue
		if key == "cube" and cube_in_place(): continue
		if key == "sphere" and completed and body.position.distance_to(POINT_SOCKET) < 0.1: continue
		body.position = HOMES[key]
		body.rotation = Vector3.ZERO
		placed[key] = body.transform
	_refresh()
	save_game()

func request_reset() -> void:
	var now := Time.get_ticks_msec()
	if now > _reset_armed_until:
		_reset_armed_until = now + 4000
		readout.text = "Press RESET again to clear this arrangement."
		return
	_reset_armed_until = 0
	reset_game()

func reset_game() -> bool:
	for body in objects.values():
		if body.is_held():
			readout.text = "Release the object before resetting."
			return false
	for key in objects:
		objects[key].transform = Transform3D(Basis.IDENTITY, HOMES[key])
		placed[key] = objects[key].transform
	bridge.rotation.y = PI/2
	bridge_target = PI/2
	completed = false
	samples.clear()
	stroke_start = true
	for line in trace_root.get_children(): line.queue_free()
	_refresh()
	save_game()
	return true

func snapshot() -> Dictionary:
	var poses := {}
	for key in objects:
		var pose: Transform3D = placed[key] if objects[key].is_held() else objects[key].transform
		var p := pose.origin
		var r := pose.basis.get_euler()
		poses[key] = {"position": [p.x,p.y,p.z], "rotation": [r.x,r.y,r.z]}
	return {"schema":1, "objects":poses, "angle":bridge.rotation.y, "target":bridge_target, "completed":completed, "trace":samples.duplicate(true)}

func save_game() -> bool:
	if save_path.is_empty(): return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_path.get_base_dir()))
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		save_error = error_string(FileAccess.get_open_error())
		_refresh()
		return false
	file.store_string(JSON.stringify(snapshot(), "\t", true, true))
	file.close()
	save_error = ""
	return true

func load_game() -> bool:
	if save_path.is_empty() or not FileAccess.file_exists(save_path): return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not valid_snapshot(data):
		save_error = "Unrecognised saved arrangement"
		return false
	for key in objects:
		objects[key].position = _vector(data.objects[key].position)
		objects[key].rotation = _vector(data.objects[key].rotation)
		placed[key] = objects[key].transform
	bridge.rotation.y = float(data.angle)
	bridge_target = float(data.target)
	completed = data.completed
	samples.clear()
	for item in data.trace: samples.append(item)
	for line in trace_root.get_children():
		trace_root.remove_child(line)
		line.queue_free()
	for i in range(1,samples.size()):
		if not samples[i].start: _trace_segment(_vector(samples[i-1].p), _vector(samples[i].p))
	stroke_start = true
	restored = true
	_refresh()
	return true

static func valid_snapshot(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema") != 1: return false
	if not data.get("objects") is Dictionary or not data.get("trace") is Array: return false
	if not data.get("completed") is bool or data.trace.size() > MAX_SAMPLES: return false
	for key in HOMES:
		var item: Variant = data.objects.get(key)
		if not item is Dictionary: return false
		if not _valid_vector(item.get("position")) or not _valid_vector(item.get("rotation")): return false
	for key in ["angle","target"]:
		if not (data.get(key) is float or data.get(key) is int): return false
		if not is_finite(float(data[key])) or float(data[key]) < -0.001 or float(data[key]) > PI/2 + 0.001: return false
	for item in data.trace:
		if not item is Dictionary or not _valid_vector(item.get("p")) or not item.get("start") is bool: return false
	return true

static func _valid_vector(value: Variant) -> bool:
	if not value is Array or value.size() != 3: return false
	for number in value:
		if not (number is float or number is int) or not is_finite(float(number)) or absf(float(number)) > 100: return false
	return true

static func _vector(value: Array) -> Vector3: return Vector3(float(value[0]), float(value[1]), float(value[2]))

func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color, solid := false) -> MeshInstance3D:
	var view := BoxBody.new(size)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = color
	finish.roughness = 0.65
	view.material_override = finish
	view.position = at
	parent.add_child(view)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		view.add_child(body)
	return view

func _frame(at: Vector3, size: Vector3, color: Color) -> void:
	var frame := SocketFrame.new()
	frame.position = at
	frame.size = size
	frame.colour = color
	add_child(frame)

func _label(caption: String, at: Vector3, pixel: float, font_size: int) -> Label3D:
	var label := Label3D.new()
	label.text = caption
	label.position = at
	label.font = load("res://commons/font/Roboto-VariableFont_wdth,wght.ttf")
	label.font_size = font_size
	label.pixel_size = pixel * 1.25
	label.outline_size = 0
	label.modulate = Color("293738")
	add_child(label)
	return label

func _button(caption: String, at: Vector3, action: Callable) -> Node3D:
	var button := load("res://commons/interactables/cube_button.tscn").instantiate() as Node3D
	button.position = at
	button.scale = Vector3.ONE * 1.5
	button.label = caption
	add_child(button)
	button.pressed.connect(action)
	return button
