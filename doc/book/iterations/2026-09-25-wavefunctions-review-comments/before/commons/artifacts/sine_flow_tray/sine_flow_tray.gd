extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Museum encounter adapted from landscape_flow_bench. The recorded research
## apparatus is left unchanged. One stationary sine surface, real body contacts.
const NX := 20
const NZ := 32
const BATCH := 32
const RADII := [0.045, 0.075, 0.105]
const RELIEFS := [0.12, 0.30, 0.55]
const WINDOW := 12
var radius_index := 1
var relief_index := 1
var ticks := 0
var running := false
var has_run := false
var reveal := false
var tray: Node3D
var surface: StaticBody3D
var samples := PackedFloat32Array()
var bodies: Array[RigidBody3D] = []
var states: Array[int] = [] # 0 still in, 1 outlet, 2 other exit
var panel: Node3D
var outcome: Label3D
var hz := 60

func _ready() -> void:
	hz = Engine.physics_ticks_per_second
	tray = Node3D.new(); tray.name = "SineTray"
	tray.position = Vector3(0, 1.3, 0); tray.rotation.x = deg_to_rad(20)
	add_child(tray)
	var casing := material("263b45")
	var glass := material("6aacbd")
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color.a = 0.18; glass.roughness = 0.22
	for x in [-1.04, 1.04]:
		box(Vector3(x, 0.30, 0), Vector3(0.08, 0.9, 3.3), glass, true, tray)
		box(Vector3(x, 0.75, 0), Vector3(0.085, 0.025, 3.3), casing, false, tray)
	box(Vector3(0, 0.30, -1.64), Vector3(2.16, 0.9, 0.08), casing, true, tray)
	box(Vector3(0, -0.10, 0), Vector3(2.16, 0.10, 3.3), casing, true, tray)
	box(Vector3(0, 0.02, 1.64), Vector3(2, 0.02, 0.035), material("eebd6d", true), false, tray)
	for x in [-0.8, 0.8]:
		box(Vector3(x, 0.59, 0), Vector3(0.12, 1.18, 0.22), casing, true)
	box(Vector3(0, 0.30, 2.02), Vector3(2.15, 0.12, 0.66), casing, true)
	outcome = label("", Vector3(0, 0.68, 2.38), 0.001)
	box(Vector3(0, 0.68, 2.34), Vector3(2.8, 0.35, 0.04), material("13212b"))
	# A side console leaves the whole surface visible and keeps controls at 1.04 m.
	panel = load("res://commons/artifacts/timing_machines/machine_stage.gd").new()
	panel.name = "SideConsole"; panel.position = Vector3(-2.4, 0, 0); panel.rotation.y = -PI/2
	add_child(panel); panel.console(["RELEASE", "RELIEF", "SIZE", "RESET", "RULE"], 0, "WHAT WILL LEAVE?")
	# Tilt the readout down into the desk instead of hiding the contact surface
	# behind a vertical board. Its face points up towards the standing reader.
	panel.readout.position = Vector3(0, 1.22, -0.12)
	panel.readout.rotation_degrees.x = -55
	for child in panel.get_children():
		if child is MeshInstance3D and is_equal_approx(child.position.y, 1.52):
			child.position = panel.readout.position - Basis(Vector3.RIGHT, deg_to_rad(-55))*Vector3(0,0,0.035)
			child.rotation_degrees.x = -55
			child.mesh.size = Vector3(3.8, 0.5, 0.055)
	for id in panel.buttons:
		buttons[id] = panel.buttons[id]; buttons[id].name = id
		buttons[id].pressed.connect(act.bind(id))
	var title := label("WHAT WILL LEAVE?\nA sine becomes a surface for contact", Vector3(0, 2.05, -1.85), 0.0014)
	box(title.position + Vector3(0, 0, -0.035), Vector3(3.3, 0.50, 0.055), material("13212b"))
	rebuild()

func rebuild() -> void:
	reset_batch()
	if is_instance_valid(surface):
		tray.remove_child(surface); surface.queue_free()
	samples.clear()
	for iz in NZ+1:
		for ix in NX+1:
			var x := -1.0 + 2.0*ix/NX
			var z := -1.6 + 3.2*iz/NZ
			samples.append(sin(TAU*0.9*x) * sin(TAU*0.9*z))
	var low: float = samples[0]; var high: float = samples[0]
	for v in samples: low = minf(low, v); high = maxf(high, v)
	for i in samples.size(): samples[i] = RELIEFS[relief_index]*(samples[i]-low)/(high-low)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in NZ:
		for ix in NX:
			for corner in [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), Vector2i(0,1)]:
				var a: int = ix+corner.x; var b: int = iz+corner.y
				var height: float = samples[b*(NX+1)+a]
				st.set_color(Color("294c68").lerp(Color("9fcaca"), height/RELIEFS[relief_index]))
				st.add_vertex(Vector3(-1.0+2.0*a/NX, height, -1.6+3.2*b/NZ))
	st.generate_normals(); var mesh := st.commit()
	surface = StaticBody3D.new(); surface.name = "MeasuredSurface"; tray.add_child(surface)
	var pm := PhysicsMaterial.new(); pm.friction = 0.45; pm.bounce = 0
	surface.physics_material_override = pm
	var collision := CollisionShape3D.new(); collision.shape = mesh.create_trimesh_shape(); surface.add_child(collision)
	var visual := MeshInstance3D.new(); visual.mesh = mesh
	var finish := material("ffffff"); finish.vertex_color_use_as_albedo = true; finish.roughness = 0.95
	visual.material_override = finish; surface.add_child(visual)
	refresh()

func reset_batch() -> void:
	running = false; has_run = false; ticks = 0
	for body in bodies:
		if is_instance_valid(body): body.get_parent().remove_child(body); body.queue_free()
	bodies.clear(); states.clear()
	refresh()

func release() -> void:
	reset_batch(); has_run = true
	for i in BATCH:
		var body := RigidBody3D.new(); body.name = "Sphere_%02d" % i
		body.mass = 0.1; body.gravity_scale = 1; body.continuous_cd = true; body.freeze = true
		body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE; body.linear_damp = 0.05
		body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE; body.angular_damp = 0.05
		var pm := PhysicsMaterial.new(); pm.friction = 0.45; pm.bounce = 0; body.physics_material_override = pm
		var radius: float = RADII[radius_index]
		var shape := SphereShape3D.new(); shape.radius = radius
		var collision := CollisionShape3D.new(); collision.shape = shape; body.add_child(collision)
		var mesh := SphereMesh.new(); mesh.radius = radius; mesh.height = radius*2
		var visual := MeshInstance3D.new(); visual.mesh = mesh; visual.material_override = material("f8d583"); body.add_child(visual)
		add_child(body)
		body.global_position = tray.to_global(Vector3(-0.75+0.5*(i%4), 1.1, -1.3+0.28*(i/4)))
		bodies.append(body); states.append(0)
	running = true; refresh()

func record_exit(index: int, kind: int) -> void:
	if states[index] != 0: return
	states[index] = kind
	var body := bodies[index]; body.freeze = true; body.collision_layer = 0; body.collision_mask = 0
	body.position = Vector3(-0.92+(index%8)*0.26, 0.48+(index/8)*0.12, 2)
	if kind == 2: body.get_child(1).material_override = material("7c8392")

func _physics_process(_delta: float) -> void:
	if not running: return
	if ticks == 0:
		for body in bodies: body.freeze = false
	for i in bodies.size():
		if states[i] != 0: continue
		var p := tray.to_local(bodies[i].global_position)
		var radius: float = RADII[radius_index]
		if absf(p.x) > 1.06+radius or p.z < -1.68-radius or p.y < -0.4: record_exit(i, 2)
		elif p.z > 1.6+radius: record_exit(i, 1)
	ticks += 1
	if ticks >= WINDOW*hz:
		running = false
		for body in bodies: body.freeze = true
	if ticks%6 == 0 or not running: refresh()

func act(id: String) -> void:
	match id:
		"RELEASE": release()
		"RELIEF": relief_index = (relief_index+1)%RELIEFS.size(); rebuild()
		"SIZE": radius_index = (radius_index+1)%RADII.size(); reset_batch()
		"RESET": radius_index = 1; relief_index = 1; reveal = false; rebuild()
		"RULE": reveal = not reveal
	refresh()

func snapshot() -> Dictionary:
	var c := [0,0,0]
	for state in states: c[state] += 1
	return {"radius_m": RADII[radius_index], "relief_m": RELIEFS[relief_index], "tilt_degrees":20,
		"ticks":ticks, "window_seconds":WINDOW, "physics_hz":hz, "batch":bodies.size(),
		"outlet":c[1], "still_in":c[0], "other_exit":c[2], "running":running}

func refresh() -> void:
	if outcome == null or panel == null: return
	var s := snapshot()
	outcome.text = "OUTLET %d / STILL IN %d / OTHER %d" % [s.outlet,s.still_in,s.other_exit] if has_run else "Predict what leaves. Then RELEASE."
	var state := "RUNNING" if running else ("WINDOW ENDED" if has_run else "READY")
	panel.readout.text = "%s   %.1f / 12 s\nRelief %.2f m / radius %.0f mm / tilt 20 deg\n32 bodies; settings start a fresh trial" % [state,float(ticks)/hz,RELIEFS[relief_index],RADII[radius_index]*1000]
	if reveal:
		panel.readout.text = "height = sin(TAU * .9 * x) * sin(TAU * .9 * z)\n20 x 32 cells; normalised to chosen relief\nMesh -> collision; mass .1 kg; friction .45\nStill in at 12 seconds is not forever."
