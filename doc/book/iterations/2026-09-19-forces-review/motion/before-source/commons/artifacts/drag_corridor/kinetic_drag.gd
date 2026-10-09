extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Three physical drag receivers and one explicit locomotion adapter.
const COEFFICIENTS := [0.4, 1.3, 3.2] # kg/s, not densities of real substances
const NAMES := ["AIR", "WATER", "HONEY"]
const BODY_LAYER := 1 << 18
var bodies: Array[RigidBody3D] = []
var arrows: Array[Node3D] = []
var labels: Array[Label3D] = []
var mass_value := 1.0
var active := false
var walk_enabled := false
var parts := false
var rule := false
var elapsed := 0.0
var text_time := 0.0
var exited: Array[bool] = [false, false, false]
var board: Label3D

func _ready() -> void:
	add_to_group("ada_kinetic_media")
	var steel = material("263a44")
	for i in 3:
		var tint = ["9ddfff", "589fd6", "f1b855"][i]
		var z = float(i - 1) * 3.0
		box(Vector3(0, 0.012, z), Vector3(9, 0.02, 2.95), material(tint))
		# Transparent side walls leave a 2.8 m passage and open ends.
		var glass = material(tint)
		glass.albedo_color.a = 0.16
		glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		for x in [-1.4, 1.4]:
			box(Vector3(x, 1.1, z), Vector3(0.04, 2.2, 2.8), glass)
		var title = label(NAMES[i], Vector3(-3, 2.4, z), 0.0024)
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		var read = label("", Vector3(3, 2.0, z), 0.0016)
		read.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		labels.append(read)
		for x in range(-4, 5):
			box(Vector3(x, 0.03, z), Vector3(0.012, 0.025, 2.6), steel)
		var body = RigidBody3D.new()
		body.name = NAMES[i] + "Probe"
		body.mass = mass_value
		body.gravity_scale = 0
		body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
		body.linear_damp = 0
		body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
		body.angular_damp = 0
		body.axis_lock_linear_y = true
		body.axis_lock_linear_z = true
		body.axis_lock_angular_x = true
		body.axis_lock_angular_y = true
		body.axis_lock_angular_z = true
		body.collision_layer = BODY_LAYER
		body.collision_mask = 0
		body.can_sleep = false
		body.freeze = true
		add_child(body)
		body.position = Vector3(-4, 1.4, z)
		box(Vector3.ZERO, Vector3(0.35, 0.35, 0.35), material(tint, true), false, body)
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3.ONE * 0.35
		collision.shape = shape
		body.add_child(collision)
		bodies.append(body)
		arrows.append(make_arrow(material("ef749d", true)))
	var controls = preload("res://commons/artifacts/timing_machines/machine_stage.gd").new()
	add_child(controls)
	controls.position.z = -5.5
	controls.rotation.y = PI
	controls.console(["FIRE", "MASS", "WALK", "PARTS", "RULE"], 0, "SAME LAUNCH / THREE RESISTANCES")
	buttons = controls.buttons
	readout = controls.readout
	for id in buttons: buttons[id].pressed.connect(act.bind(id))
	box(Vector3(-3, 2.0, -5.65), Vector3(3.2, 1.35, 0.06), steel)
	board = label("", Vector3(-3, 2.0, -5.7), 0.0017)
	board.rotation.y = PI
	update_text()
	get_tree().node_added.connect(_on_node_added)
	install_xr_adapter.call_deferred()

func _on_node_added(node: Node) -> void:
	if node is XRToolsPlayerBody:
		install_xr_adapter.call_deferred()

func install_xr_adapter() -> void:
	for body in get_tree().get_nodes_in_group("player_body"):
		if not body is XRToolsPlayerBody or body.get_node_or_null("KineticMediumAdapter") != null:
			continue
		var adapter = preload("res://commons/artifacts/drag_corridor/kinetic_walk_provider.gd").new()
		adapter.name = "KineticMediumAdapter"
		adapter.receiver = body
		body.add_child(adapter)
		# XRTools caches its provider list at ready; this room may arrive later.
		body._movement_providers.append(adapter)
		body._movement_providers.sort_custom(body.sort_by_order)

func walk_multiplier(world_point: Vector3) -> float:
	if not walk_enabled:
		return 1.0
	var p = to_local(world_point)
	if absf(p.x) > 1.35 or p.y < -0.2 or p.y > 2.3 or p.z < -4.5 or p.z >= 4.5:
		return 1.0
	var i = clampi(int(floor((p.z + 4.5) / 3.0)), 0, 2)
	# Deliberate stick/WASD speed mapping; it is not the probe's force integrator.
	return 1.0 / (1.0 + COEFFICIENTS[i])

func act(id: String) -> void:
	match id:
		"FIRE": launch()
		"MASS": mass_value = 1 if mass_value >= 4 else mass_value * 2; reset_probes()
		"WALK": walk_enabled = not walk_enabled
		"PARTS": parts = not parts
		"RULE": rule = not rule
	update_text()

func reset_probes() -> void:
	active = false
	elapsed = 0
	exited = [false, false, false]
	for i in bodies.size():
		bodies[i].freeze = true
		bodies[i].mass = mass_value
		bodies[i].position = Vector3(-4, 1.4, float(i - 1) * 3)
		bodies[i].linear_velocity = Vector3.ZERO

func launch() -> void:
	reset_probes()
	for body in bodies:
		body.freeze = false
		body.linear_velocity = global_basis * Vector3.RIGHT * 4.0
	active = true

func _physics_process(delta: float) -> void:
	if active: elapsed += delta
	for i in bodies.size():
		var body = bodies[i]
		if active and not exited[i]:
			if body.position.x >= 4.0:
				exited[i] = true
				body.freeze = true
			else:
				body.apply_central_force(-COEFFICIENTS[i] * body.linear_velocity)
		var local_force = -COEFFICIENTS[i] * (global_basis.inverse() * body.linear_velocity)
		place_arrow(arrows[i], body.position + Vector3(0, 0.3, 0), local_force * 0.12)
	text_time += delta
	if text_time >= 0.1:
		text_time = 0
		update_text()

func make_arrow(mat: Material) -> Node3D:
	var rig = Node3D.new()
	add_child(rig)
	var shaft = CylinderMesh.new()
	shaft.top_radius = 0.022
	shaft.bottom_radius = 0.022
	shaft.height = 1
	shaft.radial_segments = 8
	var mesh = MeshInstance3D.new()
	mesh.mesh = shaft
	mesh.material_override = mat
	rig.add_child(mesh)
	var cone = CylinderMesh.new()
	cone.top_radius = 0
	cone.bottom_radius = 0.065
	cone.height = 0.15
	cone.radial_segments = 8
	var tip = MeshInstance3D.new()
	tip.mesh = cone
	tip.material_override = mat
	rig.add_child(tip)
	return rig

func place_arrow(rig: Node3D, origin: Vector3, vector: Vector3) -> void:
	rig.visible = parts and vector.length() > 0.002
	if not rig.visible: return
	rig.position = origin + vector * 0.5
	rig.quaternion = Quaternion(Vector3.UP, vector.normalized())
	rig.get_child(0).scale.y = vector.length()
	rig.get_child(1).position.y = vector.length() * 0.5 - 0.075

func update_text() -> void:
	readout.text = "FIRE: 4 m/s / mass %.0f kg / WALK %s" % [mass_value, "ON" if walk_enabled else "OFF"]
	board.text = "Which body travels farther?\nFIRE, watch, then reveal PARTS and RULE.\nWALK applies only inside the centre passage."
	if rule:
		board.text = "Probe: F = -b v; acceleration = F / mass.\nPink force: 0.12 m per newton.\nWalk speed factor = 1 / (1 + b); separate adapter."
	board.text += "\nProbes ignore furniture and player; X only, no gravity.\nEnd of 8 m observation freezes the body.\nWALK: WASD / XR stick, not tracked physical steps."
	for i in labels.size():
		labels[i].text = "b %.1f kg/s\nv %.2f m/s / d %.2f m\n%s" % [COEFFICIENTS[i], bodies[i].linear_velocity.length(), bodies[i].position.x + 4, "FRAME EXIT" if exited[i] else ""]
