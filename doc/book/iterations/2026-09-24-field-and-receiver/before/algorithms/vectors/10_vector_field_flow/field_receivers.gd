extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## One dimensionless spatial rule, two explicit receiver adapters.
## Kinematic comparison, not a force applied to the visitor or a rigid body.
const STEP := 1.0 / 120.0
const START := Vector3(-2, 0, -2)
const HISTORY_LIMIT := 240
const FIELD_NAMES := ["SINK", "SWIRL", "UNIFORM"]
var field_index := 0
var gain := 1.0
var sign_value := 1.0
var running := false
var field_visible := false
var trails_visible := false
var rule_visible := false
var positions: Array[Vector3] = [START, START]
var velocities: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var stopped: Array[bool] = [false, false]
var markers: Array[Node3D] = []
var wall_markers: Array[Node3D] = []
var receiver_labels: Array[Label3D] = []
var histories: Array = [[], []]
var trail_meshes: Array[ImmediateMesh] = []
var trail_views: Array[MeshInstance3D] = []
var elapsed := 0.0
var accumulator := 0.0
var sample_steps := 0
var readout_time := 0.0
var wall: Label3D
var state_label: Label3D
var shafts: MultiMeshInstance3D
var tips: MultiMeshInstance3D
var sample_origins: Array[Vector3] = []
var field_rebuilds := 0

func _ready() -> void:
	var steel = material("243a44")
	var gold = material("d2af68")
	for x in range(-5, 6):
		box(Vector3(x, 0.012, 0), Vector3(0.012, 0.01, 8), steel)
	for z in range(-4, 5):
		box(Vector3(0, 0.012, z), Vector3(10, 0.01, 0.012), steel)
	for x in [-5.0, 5.0]:
		box(Vector3(x, 0.025, 0), Vector3(0.04, 0.025, 8), gold)
	for z in [-4.0, 4.0]:
		box(Vector3(0, 0.025, z), Vector3(10, 0.025, 0.04), gold)
	box(Vector3(0, 2.5, -5), Vector3(8, 4.6, 0.1), steel, true)
	label("ONE FIELD / TWO WAYS TO RECEIVE IT", Vector3(0, 4.4, -4.92), 0.003)
	wall = label("", Vector3(0, 3.4, -4.92), 0.0018)
	label("WALL PLAN / same X-Z paths / X: 0.5 m per m, Z: 0.28 m per m", Vector3(0, 0.65, -4.92), 0.0016)
	box(Vector3(0, 1.85, -4.92), Vector3(5, 0.015, 0.01), gold)
	box(Vector3(0, 1.85, -4.92), Vector3(0.015, 2.24, 0.01), gold)
	label("0", Vector3(-0.12, 1.70, -4.90), 0.0015)
	bank(["RUN", "RESET", "FIELD", "REVERSE"], -1.0, 0)
	bank(["GAIN", "ARROWS", "TRAILS", "RULE"], 1.1, PI)
	state_label = label("", Vector3(0, 1.32, -1.2), 0.0012)
	var centre = label("STAND HERE", Vector3(0, 0.028, 0), 0.0018)
	centre.rotation_degrees.x = -90
	for i in 2:
		var mat = material("63edd9" if i == 0 else "f88db9", true)
		var marker = Node3D.new()
		add_child(marker)
		markers.append(marker)
		box(Vector3.ZERO, Vector3.ONE * (0.24 if i == 0 else 0.32), mat, false, marker)
		var wall_marker = Node3D.new()
		add_child(wall_marker)
		wall_markers.append(wall_marker)
		box(Vector3.ZERO, Vector3(0.09, 0.09, 0.02), mat, false, wall_marker)
		var nameplate = Label3D.new()
		marker.add_child(nameplate)
		nameplate.text = "CYAN" if i == 0 else "PINK"
		receiver_labels.append(nameplate)
		nameplate.position.y = 0.25
		nameplate.font_size = 38
		nameplate.pixel_size = 0.0014
		var mesh = ImmediateMesh.new()
		var view = MeshInstance3D.new()
		view.mesh = mesh
		view.material_override = mat
		add_child(view)
		trail_meshes.append(mesh)
		trail_views.append(view)
	build_field()
	reset_run()

func bank(ids: Array, z: float, yaw: float) -> void:
	var rig = Node3D.new()
	add_child(rig)
	rig.position.z = z
	rig.rotation.y = yaw
	box(Vector3(0, 0.94, 0), Vector3(3.4, 0.16, 0.5), material("263a44"), true, rig)
	for x in [-1.4, 1.4]:
		box(Vector3(x, 0.45, 0), Vector3(0.14, 0.9, 0.25), material("263a44"), true, rig)
	for i in ids.size():
		var id: String = ids[i]
		var button = PUSH.instantiate()
		rig.add_child(button)
		button.position = Vector3((i - 1.5) * 0.75, 1.04, 0)
		button.scale = Vector3.ONE * 1.15
		buttons[id] = button
		button.pressed.connect(act.bind(id))
		var caption = Label3D.new()
		rig.add_child(caption)
		caption.text = id
		caption.position = button.position + Vector3(0, 0.065, 0.18)
		caption.font_size = 42
		caption.pixel_size = 0.001
		caption.rotation_degrees.x = -55

func field_at(p: Vector3) -> Vector3:
	var value: Vector3
	match field_index:
		0: value = Vector3(-p.x, 0, -p.z) * 0.35
		1: value = Vector3(-p.z, 0, p.x) * 0.35
		_: value = Vector3.RIGHT * 0.8
	return value.limit_length(2.0) * gain * sign_value

func build_field() -> void:
	var shaft = CylinderMesh.new()
	shaft.top_radius = 0.012
	shaft.bottom_radius = 0.012
	shaft.height = 1.0
	shaft.radial_segments = 6
	var tip = CylinderMesh.new()
	tip.top_radius = 0
	tip.bottom_radius = 0.055
	tip.height = 0.12
	tip.radial_segments = 6
	for x in range(-4, 5):
		for z in range(-3, 4): sample_origins.append(Vector3(x, 0.05, z))
	for mesh in [shaft, tip]:
		var view = MultiMeshInstance3D.new()
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = sample_origins.size()
		view.multimesh = mm
		view.material_override = material("d2af68", true)
		add_child(view)
		if shafts == null: shafts = view
		else: tips = view
	refresh_field()

func refresh_field() -> void:
	field_rebuilds += 1
	for i in sample_origins.size():
		var value = field_at(sample_origins[i])
		var length = value.length() * 0.4
		var basis = Basis.IDENTITY
		if length > 0.0001: basis = Basis(Quaternion(Vector3.UP, value.normalized()))
		var origin = sample_origins[i]
		var direction = value.normalized()
		shafts.multimesh.set_instance_transform(i, Transform3D(basis.scaled(Vector3(1, length, 1)), origin + direction * length * 0.5))
		tips.multimesh.set_instance_transform(i, Transform3D(basis.scaled(Vector3.ONE if length > 0.0001 else Vector3.ZERO), origin + direction * length))
	shafts.visible = field_visible
	tips.visible = field_visible

func act(id: String) -> void:
	match id:
		"RUN": running = not running
		"RESET": reset_run()
		"FIELD": field_index = (field_index + 1) % FIELD_NAMES.size(); refresh_field()
		"REVERSE": sign_value *= -1; refresh_field()
		"GAIN": gain = 0.5 if gain >= 1.5 else gain + 0.5; refresh_field()
		"ARROWS": field_visible = not field_visible; shafts.visible = field_visible; tips.visible = field_visible
		"TRAILS": trails_visible = not trails_visible; draw_trails()
		"RULE": rule_visible = not rule_visible
	update_views()

func reset_run() -> void:
	positions = [START, START]
	velocities = [Vector3.ZERO, Vector3.ZERO]
	stopped = [false, false]
	histories = [[START], [START]]
	elapsed = 0
	accumulator = 0
	sample_steps = 0
	running = false
	draw_trails()
	update_views()

func _physics_process(delta: float) -> void:
	if running: advance(delta)
	update_markers()
	readout_time += delta
	if readout_time >= 0.1:
		readout_time = 0
		update_views()

func advance(delta: float) -> void:
	# A stalled frame advances at most 0.25 model seconds; no unbounded catch-up.
	accumulator += minf(delta, 0.25)
	while accumulator + 0.0000001 >= STEP:
		accumulator -= STEP
		elapsed += STEP
		for i in 2:
			if stopped[i]: continue
			var sample = field_at(positions[i])
			if i == 0: velocities[i] = sample # 1 m/s per field unit
			else: velocities[i] += sample * STEP # 1 m/s² per field unit
			positions[i] += velocities[i] * STEP
			if absf(positions[i].x) >= 5 or absf(positions[i].z) >= 4:
				stopped[i] = true # retain outgoing state; no contact response
		sample_steps += 1
		if sample_steps >= 12:
			sample_steps = 0
			for i in 2:
				histories[i].append(positions[i])
				if histories[i].size() > HISTORY_LIMIT: histories[i].pop_front()
			draw_trails()
		if stopped[0] and stopped[1]: running = false; accumulator = 0; break

func update_markers() -> void:
	for i in markers.size():
		markers[i].position = positions[i] + Vector3(0, 1.45 + i * 0.45, 0)
		wall_markers[i].position = wall_position(positions[i], i)

func wall_position(p: Vector3, index: int) -> Vector3:
	return Vector3(p.x * 0.5, 1.85 - p.z * 0.28, -4.88 + index * 0.025)

func draw_trails() -> void:
	for i in trail_meshes.size():
		var mesh = trail_meshes[i]
		mesh.clear_surfaces()
		trail_views[i].visible = trails_visible
		if histories[i].size() < 2: continue
		# The wall and floor are two views of exactly the same sampled positions.
		for wall_plan in [false, true]:
			mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
			for p: Vector3 in histories[i]:
				mesh.surface_add_vertex(wall_position(p, i) if wall_plan else p + Vector3(0, 1.45 + i * 0.45, 0))
			mesh.surface_end()

func update_views() -> void:
	update_markers()
	# Keep body identity visible; the existing RULE control reveals the receiver operation.
	for i in receiver_labels.size():
		receiver_labels[i].text = (["SET v", "ADD to v"] if rule_visible else ["CYAN", "PINK"])[i]
	state_label.text = "%s / gain %.1f / sign %+.0f / %.1f s / %s" % [FIELD_NAMES[field_index], gain, sign_value, elapsed, "RUNNING" if running else "PAUSED"]
	wall.text = "RUN. Which body crosses the centre?\nFollow cyan and pink; pause and compare their paths.\nRULE reveals how each body receives the field."
	if rule_visible:
		wall.text = "Cyan: v = field(p) * 1 m/s; p += v * dt\nPink: v += field(p) * 1 m/s² * dt; p += v * dt\nThis field has no units; its receivers supply them.\nArrow scale: 0.4 m per field unit / 63 samples"
	wall.text += "\nRESET pauses; edits keep state. Heights separate the views only.\nNo collisions or player force. Frame exit freezes outgoing state.\n120 steps/s; trail 240 samples at 10 Hz; stalls cap at 0.25 s."
	for i in 2:
		if stopped[i]: wall.text += "\n%s EXITED / last speed %.2f m/s" % ["CYAN" if i == 0 else "PINK", velocities[i].length()]
