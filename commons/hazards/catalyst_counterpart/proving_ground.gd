extends "res://commons/hazards/catalyst_counterpart/counterpart_trial.gd"
## Three rooms, one record, one head. An isolated first-abilities playtest.
enum Stage { DRAW, REST, ARRIVING, DEFEND, OPEN, COMPLETE }
const ARENA := Vector3(0, 0, -18)
var stage := Stage.DRAW
var rod: RigidBody3D
var trace: Node3D
var field: Node3D
var arena: Node3D
var tableau: Node3D
var head_rest: Vector3
var gate: StaticBody3D
var gate_leaf: MeshInstance3D
var record: Array[Vector3] = []
var sculpture := Node3D.new()
var start_button: Node3D
var reset_button: Node3D
var transit: Tween
var visitor_override: Node3D
var mounted := false
var catalyst_script := "res://commons/artifacts/ignorance_gallery/resolution_catalyst.gd"

func _ready() -> void:
	name = "CatalystProvingGround"
	# Museum shell supplies floor, exterior walls, light and the real player rig.
	_partition(-7.0)
	_partition(-16.0)
	_wall_text("01  GIVE A LINE TO THE AIR", Vector3(-3.5, 2.65, -6.86), 33)
	_wall_text("Take the rod. Put its tip inside the light.\nDraw, then release it.\nYour line goes ahead of you.", Vector3(-3.5, 2.15, -6.86), 24)
	_box_mesh(Vector3(-5.35, 1.4, -3), Vector3(0.10, 0.8, 0.35), Color(0.18, 0.18, 0.18))
	trace = load("res://commons/hazards/catalyst_counterpart/trial_trace.gd").new()
	trace.grab_point_path = NodePath("Rod")
	trace.draw_sphere_path = NodePath("Rod/WritingTip")
	trace.trail_color = Color(0.9, 0.9, 0.87)
	trace.min_segment_distance = 0.015
	trace.trail_max_points = 1024
	trace.show_data_table = false
	trace.trigger_tag = ""
	rod = load("res://commons/hazards/catalyst_counterpart/charged_rod.gd").new()
	rod.name = "Rod"
	rod.position = Vector3(-5.17, 1.36, -3)
	rod.rotation.x = PI / 2.0
	trace.add_child(rod)
	add_child(trace)
	trace.record_kept.connect(keep_record)
	field = load("res://commons/hazards/becoming_catalyst/first_catalyst_ability.gd").make_glow(0.23)
	field.position = Vector3(-2, 1.4, -3)
	add_child(field)
	var seed := MeshInstance3D.new()
	var seed_mesh := SphereMesh.new()
	seed_mesh.radius = 0.10; seed_mesh.height = 0.20
	seed.mesh = seed_mesh
	seed.material_override = _material(Color(0.025, 0.025, 0.025), 0.15)
	field.add_child(seed)
	rod.field = field
	_plinth(Vector3(-2, 0.5, -3), Vector3(0.65, 1, 0.65))
	_label("CHARGE THE TIP", Vector3(-2, 1.85, -3.1), 24, 0.0018)
	# Second room: actual Durer apparatus, with one still counterpart.
	_wall_text("02  SOMETHING IS WAITING", Vector3(3.5, 2.9, -15.86), 33)
	tableau = load("res://commons/scenes/demos/durer/EngravingScene.tscn").instantiate()
	tableau.position = Vector3(-1.4, 0, -13)
	tableau.scale = Vector3.ONE * 0.78
	add_child(tableau)
	var figure: Node3D = tableau.find_child("Melencolia", true, false)
	figure.hide()
	for body in figure.find_children("*", "CollisionObject3D", true, false):
		body.collision_layer = 0; body.collision_mask = 0
	arena = Node3D.new(); arena.position = ARENA; add_child(arena)
	skull = Skull.new(); arena.add_child(skull)
	head_rest = to_local(tableau.to_global(figure.position + Vector3(-0.19, 2.35, 0.15)))
	skull.global_position = to_global(head_rest)
	skull.rotation.y = PI
	skull.collision_layer = 0
	skull.set_physics_process(false)
	skull.interrupted.connect(_interrupted)
	sculpture.position = Vector3(3.6, 1.45, -11.2)
	add_child(sculpture)
	_plinth(Vector3(3.6, 0.45, -11.2), Vector3(1.1, 0.9, 1.1))
	_label("YOUR LINE, KEPT", Vector3(3.6, 2.35, -11.3), 25, 0.0018)
	# Third room: all the controls remain reachable; the head never leaves this arena.
	_wall_text("03  MAKE ROOM TO PASS", Vector3(-3.5, 2.9, -24.86), 33)
	_label("Take the point. Press BEGIN.\nSidestep the line. Trigger sends a form.\nOne interruption opens the passage.", Vector3(-3.7, 2.05, -18.6), 23, 0.0017)
	catalyst = load(catalyst_script).new()
	catalyst.position = Vector3(-3.7, 1.18, -18)
	add_child(catalyst)
	_plinth(Vector3(-3.7, 0.48, -18), Vector3(0.6, 0.96, 0.6))
	start_button = _button("BEGIN", Vector3(-2.8, 1.10, -18), begin_encounter)
	reset_button = _button("RESET TRIAL", Vector3(3.7, 1.1, -18), reset_trial)
	# Also provide reset at the entrance; no need to complete the trial to recover.
	_button("RESET TRIAL", Vector3(3.7, 1.1, -2.5), reset_trial)
	readout = _label("", Vector3(0, 2.65, -18.4), 24, 0.0018)
	_build_gate()
	_label("THE HEAD REMAINS. THE WAY OPENS.", Vector3(0, 2.2, -28), 29, 0.002)
	mounted = true
	_refresh_status()

func _process(_delta: float) -> void:
	if not mounted: return
	_refresh_status()
	var visitor: Node3D = visitor_override if is_instance_valid(visitor_override) else get_viewport().get_camera_3d()
	if stage == Stage.OPEN and visitor != null:
		var p := to_local(visitor.global_position)
		if p.z < -25.9 and p.z > -29.5 and absf(p.x) < 1.3:
			stage = Stage.COMPLETE

func _refresh_status() -> void:
	if not is_instance_valid(readout): return
	var messages := ["Charge the rod; draw and release a line.", "Your line is kept. Take the point; press BEGIN.", "The still head becomes a moving body.", "Sidestep or interrupt. Trigger sends a form.", "Pass through. The head is resting.", "You carried an ability from making to defending."]
	readout.text = "%s\n%d kept positions  /  %d interruptions  /  %d touches" % [messages[stage], record.size(), skull.interruptions, skull.tags]

func keep_record(points: Array[Vector3]) -> void:
	if points.size() < 2: return
	record = points.duplicate()
	for child in sculpture.get_children(): child.free()
	var low: Vector3 = record[0]; var high: Vector3 = record[0]
	for p in record: low = low.min(p); high = high.max(p)
	var center: Vector3 = (low + high) * 0.5
	var fit := 1.2 / maxf((high - low).length(), 0.01)
	# One batched tube per recorded interval: readable at room distance.
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.009; mesh.bottom_radius = 0.009; mesh.height = 1; mesh.radial_segments = 6
	var batch := MultiMesh.new(); batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh; batch.instance_count = record.size() - 1
	for i in range(record.size() - 1):
		var a: Vector3 = (record[i] - center) * fit
		var b: Vector3 = (record[i + 1] - center) * fit
		var direction: Vector3 = b - a
		var rotation := Basis(Quaternion(Vector3.UP, direction.normalized())) if direction.length() > 0.00001 else Basis.IDENTITY
		batch.set_instance_transform(i, Transform3D(rotation * Basis.from_scale(Vector3(1, direction.length(), 1)), (a + b) * 0.5))
	var view := MultiMeshInstance3D.new(); view.multimesh = batch
	view.material_override = _material(Color(0.07, 0.07, 0.07), 0.35)
	sculpture.add_child(view)
	if stage == Stage.DRAW: stage = Stage.REST

func begin_encounter() -> void:
	if stage != Stage.REST: return
	stage = Stage.ARRIVING
	skull.collision_layer = 0
	transit = create_tween()
	transit.tween_property(skull, "position", Vector3(0, 1.65, -3.5), 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transit.tween_callback(func():
		skull.collision_layer = 2
		skull.set_active(true)
		skull.set_physics_process(true)
		stage = Stage.DEFEND)

func _interrupted() -> void:
	if stage != Stage.DEFEND: return
	stage = Stage.OPEN
	skull.active = false
	# Defer the shape change: this signal can arrive from physics contact.
	gate.get_node("Boundary").set_deferred("disabled", true)
	gate_leaf.hide()

func reset_trial() -> void:
	if is_instance_valid(transit): transit.kill()
	stage = Stage.DRAW
	skull.set_active(false)
	skull.set_physics_process(false)
	skull.collision_layer = 0
	skull.interruptions = 0; skull.tags = 0
	skull.velocity = Vector3.ZERO
	skull.global_position = to_global(head_rest)
	skull.rotation.y = PI
	record.clear()
	trace.clear_trail()
	for child in sculpture.get_children(): child.queue_free()
	rod.reset_charge()
	for projectile in catalyst.projectiles:
		if is_instance_valid(projectile): projectile.queue_free()
	catalyst.projectiles.clear()
	catalyst._cooldown = 0.0
	catalyst.return_home()
	# XRTools release and the rigid-body pose can still be syncing in this frame.
	# Use each tool's existing return timer after that sync; never pull a held tool away.
	if not catalyst.is_resolution_held(): catalyst._return_in = 0.08
	if not rod.held(): rod.return_in = 0.08
	gate.get_node("Boundary").set_deferred("disabled", false)
	gate_leaf.show()

func _partition(z: float) -> void:
	# Two 4 m wings leave a clear 3 m central passage.
	_plinth(Vector3(-3.5, 2, z), Vector3(4, 4, 0.22))
	_plinth(Vector3(3.5, 2, z), Vector3(4, 4, 0.22))

func _build_gate() -> void:
	_partition(-25)
	gate = StaticBody3D.new(); gate.name = "PassageGate"
	gate.position = Vector3(0, 1.4, -25); gate.collision_layer = 1; gate.collision_mask = 0
	add_child(gate)
	var boundary := CollisionShape3D.new(); boundary.name = "Boundary"
	var shape := BoxShape3D.new(); shape.size = Vector3(3, 2.8, 0.22); boundary.shape = shape
	gate.add_child(boundary)
	gate_leaf = MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = shape.size
	gate_leaf.mesh = mesh; gate_leaf.material_override = _material(Color(0.08, 0.08, 0.08), 0.6)
	gate.add_child(gate_leaf)

func _button(caption: String, at: Vector3, action: Callable) -> Node3D:
	var button: Node3D = load("res://commons/interactables/cube_button.tscn").instantiate()
	button.label = caption; button.accent = Color(0.85, 0.85, 0.82)
	button.position = at; button.scale = Vector3.ONE * 1.5
	add_child(button); button.pressed.connect(action)
	_plinth(at + Vector3(0, -0.62, -0.03), Vector3(0.4, 0.95, 0.28))
	return button

func _material(color: Color, rough: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = rough
	return material

func _wall_text(text: String, at: Vector3, size: int) -> void:
	var label := _label(text, at, size, 0.002)
	label.modulate = Color(0.08, 0.08, 0.08)
	label.outline_size = 0

func _box_mesh(at: Vector3, size: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size
	node.mesh = mesh; node.position = at; node.material_override = _material(color, 0.8); add_child(node)

static func mount_test(hall: Node3D) -> Node3D:
	var trial := load("res://commons/hazards/catalyst_counterpart/proving_ground.gd").new() as Node3D
	# Map-space (6.5, 3.5); hall-local Z includes its 4 m entry vestibule.
	var at := hall.to_global(Vector3(6.5, 0, 7.5))
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3, at + Vector3.DOWN * 5, 1)
	var hit := hall.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty():
		trial.free(); push_error("Catalyst test needs the museum floor"); return null
	at.y = hit.position.y
	trial.position = hall.to_local(at); trial.rotation.y = PI
	hall.add_child(trial)
	return trial
