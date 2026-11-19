extends Node3D
## An opt-in room-scale celebration around the existing band generator.
## Geometry and collision stay fixed when the colour partition changes.
const Controls = preload("res://commons/ui/control_panel.gd")
const MODES := ["six", "roygbiv", "continuous", "two"]
const COUNTS := [6, 7, 48, 2]
const PartyPickup = preload("res://algorithms/primitives/rainbow/rainbow_party_pickup.tscn")
const SparkBurst = preload("res://algorithms/primitives/rainbow/rainbow_spark_burst.gd")
const GroundPhysics = preload("res://addons/godot-xr-tools/overrides/ground_physics.gd")
const GroundSettings = preload("res://addons/godot-xr-tools/overrides/ground_physics_settings.gd")
const FullFloorScript = preload("res://commons/artifacts/rainbow_playground/full_floor_playground.gd")
var walk_pickups: Node3D
var spark_bursts: Node3D
var collected_cubes := 0
var arch: Node3D
var mode_index := 0
var readout: Label
var buttons: Array[Node3D] = []
var tiles: Array[MeshInstance3D] = []
var confetti: MultiMeshInstance3D
var party_time := 0.0
var celebration_count := 0
var trigger: Area3D
var _party_active := false
var playground := false
var full_floor := false
var _full_floor: Node3D
var _burst_z := 3.0
var _pavers: Array[MeshInstance3D] = []

func _ready() -> void:
	name = "RainbowCelebration"
	playground = bool(get_parent().get_meta("config_playground", false))
	full_floor = bool(get_parent().get_meta("config_full_floor", false))
	arch = load("res://algorithms/primitives/rainbow/rainbow.gd").new()
	arch.name = "BandComparison"
	arch.banding = MODES[0]
	arch.substance = "solid"
	if full_floor:
		arch.scale = Vector3(0.24, 0.20, 0.22)
		arch.position = Vector3(0.0, 0.16, -1.6)
	else:
		arch.scale = Vector3.ONE * 0.23
		if playground:
			arch.scale.x *= 1.15
		arch.position = Vector3(0, 0.18, -2)
	add_child(arch)
	arch.get_node("AtmosphereParticles").queue_free()
	arch.set_process(false)
	_build_party()
	_apply_palette()
	_build_walk_celebration()
	if full_floor:
		_build_full_floor_playground()
	elif playground:
		_build_playground()

func _material(c: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.32
	m.metallic = metallic
	return m

func _mesh(label: String, mesh: Mesh, at: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	n.mesh = mesh
	n.material_override = mat
	n.position = at
	add_child(n)
	if solid:
		n.create_convex_collision()
	return n

func _box(label: String, at: Vector3, size: Vector3, colour: Color, solid: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(label, mesh, at, _material(colour), solid)

func _ball(label: String, at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 20
	mesh.rings = 12
	var n := _mesh(label, mesh, at, _material(colour))
	n.scale = size
	return n

func _label(text: String, at: Vector3, font_size: int = 64) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = at
	l.font_size = font_size
	l.pixel_size = 0.003
	l.outline_size = 5
	add_child(l)

func _mushroom(at: Vector3, colour: Color, lean: float) -> void:
	# Pearlescent stalk, candy cap, extravagant collar: familiar platform shape
	# treated as a dressed body. These are scenery, not enemies or pickups.
	var stem := CylinderMesh.new()
	stem.top_radius = 0.23
	stem.bottom_radius = 0.4
	stem.height = 1.45
	var stalk := _mesh("PearlStalk", stem, at + Vector3.UP * 0.73, _material(Color("ead8f4"), 0.2))
	stalk.rotation_degrees.z = lean
	_ball("CandyCap", at + Vector3(0, 1.6, 0), Vector3(2.3, 0.85, 2.3), colour)
	for i in range(10):
		var a: float = TAU * i / 10.0
		_ball("CollarPearl", at + Vector3(cos(a) * 0.64, 1.13, sin(a) * 0.64), Vector3.ONE * 0.23, Color("fff3d9"))
	for i in range(7):
		var a: float = TAU * i / 7.0
		_ball("CapSpot", at + Vector3(cos(a) * 0.65, 1.91, sin(a) * 0.65), Vector3(0.28, 0.075, 0.28), Color("fff3ed"))

func _star(at: Vector3, colour: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(10):
		var a: float = TAU * i / 10.0 + PI * 0.5
		var b: float = TAU * (i + 1) / 10.0 + PI * 0.5
		var ra := 0.4 if i % 2 == 0 else 0.18
		var rb := 0.4 if (i + 1) % 2 == 0 else 0.18
		surface.add_vertex(Vector3.ZERO)
		surface.add_vertex(Vector3(cos(a) * ra, sin(a) * ra, 0))
		surface.add_vertex(Vector3(cos(b) * rb, sin(b) * rb, 0))
	var mat := _material(colour, 0.35)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh("PartyStar", surface.commit(), at, mat)

func _build_party() -> void:
	# Optional low stepping route; the centre and both museum side aisles stay level.
	var heights := [0.18, 0.36, 0.54, 0.72, 0.90, 0.72, 0.54, 0.36]
	var nb_trim := [Color("ffc857"), Color("ffffff"), Color("a76ed5"), Color("282032")]
	for i in range(8):
		var h: float = heights[i]
		if full_floor:
			# Placed north of the East-West Color Crossroad with Non-Binary trim integrated!
			var sz := 2.35 - i * 0.98
			var tile := _box("CandyStep_%d" % i, Vector3(-3.65, h * 0.5, sz), Vector3(1.85, h, 0.94), Color.WHITE, true)
			tiles.append(tile)
			_box("StepNBTrim_%d" % i, Vector3(-3.65, h + 0.012, sz + 0.43), Vector3(1.80, 0.024, 0.08), nb_trim[i % nb_trim.size()])
		else:
			var tile := _box("CandyStep_%d" % i, Vector3(-3.1, h * 0.5, 6.3 - i * 1.5), Vector3(1.8, h, 1.45), Color.WHITE, true)
			tiles.append(tile)
			if playground:
				_box("StepNosing", Vector3(-3.1, h + 0.009, 6.96 - i * 1.5), Vector3(1.72, 0.018, 0.07), Color("fff0e1"))
			else:
				_box("StepPiping", Vector3(-3.1, h + 0.013, 6.3 - i * 1.5), Vector3(1.72, 0.025, 1.37), Color("fff0e1"))
	if not full_floor:
		for i in range(6):
			var tile := _box("ColourPaver_%d" % i, Vector3(0, 0.014, 5.9 - i * 1.7), Vector3(2.25, 0.022, 1.45), Color.WHITE)
			tiles.append(tile)
			_pavers.append(tile)
	if not playground and not full_floor:
		for i in range(3):
			_mushroom(Vector3(4.3, 0, 5 - i * 4.5), [Color("fc65b5"), Color("70def1"), Color("bb85fc")][i], -8.0 + i * 8.0)
	if full_floor:
		for i in range(12):
			_star(Vector3(-5.8 + i * 1.05, 3.35 + sin(i * 0.85) * 0.65, -4.4), [Color("ffdf69"), Color("fa9bc8"), Color("84e9ed")][i % 3])
	else:
		for i in range(8):
			_star(Vector3(-4.8 + i * 1.35, 3.4 + sin(i * 0.8) * 0.7, -5.8), [Color("ffdf69"), Color("fa9bc8"), Color("84e9ed")][i % 3])
	if not full_floor:
		# Three striped banners add pink/cyan/white and brown/black alongside the
		# arc's editable palette, rather than calling one partition exhaustive.
		var flags := [[Color("55cce4"), Color("f4aac8"), Color.WHITE, Color("f4aac8"), Color("55cce4")], [Color("ffc857"), Color.WHITE, Color("a76ed5"), Color("282032")], [Color("603e32"), Color("211b28"), Color("f887aa"), Color("67d6e9"), Color.WHITE]]
		for f in range(3):
			var colours: Array = flags[f]
			for i in range(colours.size()):
				_box("PartyBanner", Vector3(-4.8, 3.1 - i * 0.14, 5 - f * 4.5), Vector3(1.0, 0.14, 0.035), colours[i])
			_box("BannerPole", Vector3(-5.34, 1.7, 5 - f * 4.5), Vector3(0.035, 3.4, 0.035), Color("ffdc80"))
	var panel_y := 5.18 if full_floor else 5.95
	var panel_z := -1.6 if full_floor else -2.0
	_box("WelcomePanel", Vector3(0, panel_y, panel_z), Vector3(5.8, 0.56 if full_floor else 0.65, 0.1), Color("572c77"))
	_label("EVERY BODY / MORE COLOUR", Vector3(0, panel_y, panel_z + 0.07), 65)
	var panel := Controls.new()
	panel.name = "PartyControls"
	panel.title = "MAKE ANOTHER RAINBOW"
	var plinth_height := 0.76 if (playground or full_floor) else 0.96
	var ctrl_x := 3.35 if full_floor else 2.15
	var ctrl_z := 6.65 if full_floor else 7.4
	panel.position = Vector3(ctrl_x, plinth_height + 0.09, ctrl_z)
	panel.spacing = 0.4
	add_child(panel)
	readout = panel.add_readout("6 bands / same width")
	var divide: Node3D = panel.add_button("RE-DIVIDE")
	divide.pressed.connect(next_banding)
	buttons.append(divide)
	var party: Node3D = panel.add_button("CELEBRATE")
	party.pressed.connect(celebrate)
	buttons.append(party)
	var plinth_width := 0.75 if (playground or full_floor) else 0.95
	_box("ControlPlinth", Vector3(ctrl_x, plinth_height * 0.5, ctrl_z - 0.05), Vector3(plinth_width, plinth_height, 0.65), Color("eab7dd"), true)
	# Entering this small centre patch gives a welcoming burst; repeat at the button.
	trigger = Area3D.new()
	trigger.name = "WelcomePatch"
	trigger.collision_layer = 0
	trigger.collision_mask = 1 | (1 << 19)
	trigger.position = Vector3(0, 1, 4.6 if full_floor else 6.4)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 2.5, 1)
	shape.shape = box
	trigger.add_child(shape)
	add_child(trigger)
	trigger.body_entered.connect(_welcome)
	confetti = MultiMeshInstance3D.new()
	confetti.name = "Confetti"
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2(0.075, 0.14)
	multi.mesh = quad
	multi.instance_count = 220 if full_floor else (160 if playground else 96)
	confetti.multimesh = multi
	var mat := _material(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	confetti.material_override = mat
	confetti.visible = false
	add_child(confetti)

func _welcome(body: Node3D) -> void:
	if _is_visitor(body):
		celebrate()

func _is_visitor(body: Node3D) -> bool:
	return body.is_in_group("player") or body.is_in_group("player_body") or body.is_in_group("vr_player") or body.is_in_group("em_walker")

func next_banding() -> void:
	mode_index = (mode_index + 1) % MODES.size()
	arch.apply_grid_config({"banding": MODES[mode_index]})
	_apply_palette()
	celebrate()

func _apply_palette() -> void:
	readout.text = "%d bands / same width" % COUNTS[mode_index]
	# Separate overlapping opaque arcs slightly in depth to avoid coplanar flicker.
	arch._arc_roots[1].position.z = -0.16
	# Candy colour stays readable in the museum's changing light. This is a
	# display material choice; opaque bands still have no collision surface.
	for arc_root in arch._arc_roots:
		for band in arc_root.get_children():
			band.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(tiles.size()):
		var material: StandardMaterial3D = tiles[i].material_override
		material.albedo_color = arch.rainbow_colors[i % arch.rainbow_colors.size()]
		material.emission = material.albedo_color

func celebrate() -> void:
	_start_burst(3.0)

func _start_burst(z: float) -> void:
	_burst_z = z
	party_time = 0.0
	_party_active = true
	celebration_count += 1
	confetti.visible = true
	_update_confetti()

func _process(delta: float) -> void:
	if not _party_active:
		return
	party_time += delta
	if party_time >= 3.5:
		_party_active = false
		confetti.visible = false
		return
	_update_confetti()

func _update_confetti() -> void:
	for i in range(confetti.multimesh.instance_count):
		var a: float = i * 2.39996
		var t: float = party_time
		var speed: float = 0.7 + (i % 9) * 0.13
		var p := Vector3(cos(a) * (0.35 + t * speed), 1.4 + (3.4 + (i % 7) * 0.2) * t - 1.8 * t * t, _burst_z + sin(a) * t * speed)
		var z_cap := 8.4 if full_floor else 7.6
		if (playground or full_floor) and (p.y < 0.06 or absf(p.z) > z_cap):
			confetti.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
			continue
		var basis := Basis.from_euler(Vector3(t * 2 + a, t * 3, a))
		confetti.multimesh.set_instance_transform(i, Transform3D(basis, p))
		confetti.multimesh.set_instance_color(i, Color.from_hsv(fposmod(i * 0.137, 1.0), 0.6, 1.0))

func _build_walk_celebration() -> void:
	walk_pickups = Node3D.new()
	walk_pickups.name = "WalkPickups"
	add_child(walk_pickups)
	spark_bursts = Node3D.new()
	spark_bursts.name = "WalkSparks"
	add_child(spark_bursts)
	for i in range(5):
		var cube: Node3D = PartyPickup.instantiate()
		cube.name = "CelebrationCube_%d" % (i + 1)
		cube.position = Vector3(0, 0.25 if full_floor else 0.1, (2.7 - i * 2.0) if full_floor else (4.2 - i * 2.1))
		cube.party_collected.connect(_cube_collected)
		walk_pickups.add_child(cube)
	if not full_floor:
		_build_finish_banner()

func _cube_collected(world_point: Vector3) -> void:
	collected_cubes += 1
	if playground and not _pavers.is_empty():
		var point := to_local(world_point)
		var index := clampi(roundi((5.9 - point.z) / 1.7), 0, _pavers.size() - 1)
		_pavers[index].material_override.emission_enabled = true
	# The signal arrives during physics; build the visual burst after the flush.
	_release_sparks.call_deferred(world_point)

func _build_full_floor_playground() -> void:
	_full_floor = FullFloorScript.new()
	add_child(_full_floor)
	_full_floor.setup(self)
	var finish := Area3D.new()
	finish.name = "FinishCelebration"
	finish.position = Vector3(0, 1.0, -6.55)
	finish.collision_layer = 0
	finish.collision_mask = trigger.collision_mask
	var sensor := CollisionShape3D.new()
	var zone := BoxShape3D.new()
	zone.size = Vector3(6.4, 2.2, 0.7)
	sensor.shape = zone
	finish.add_child(sensor)
	finish.body_entered.connect(_finish_entered)
	add_child(finish)

func sample_crosswalk_point(preferred_local: Vector3) -> Dictionary:
	if _full_floor != null and _full_floor.has_method("sample_crosswalk_point"):
		return _full_floor.call("sample_crosswalk_point", preferred_local)
	return {}

func _build_playground() -> void:
	var colours := [Color("ff55ab"), Color("59dff6"), Color("d1a0ff"), Color("ffd55e")]
	for i in range(colours.size()):
		var x := 3.9 if i % 2 == 0 else 3.45
		var z := 4.9 - i * 2.65
		var top: float = [0.34, 0.65, 0.96, 0.64][i]
		_build_jump_cap(i, Vector3(x, top, z), colours[i])
	_build_ribbons(colours)
	_label("JUMP CAPS", Vector3(3.9, 1.12, 5.75), 48)
	_label("EAT A MUSHROOM\nCHANGE THE VIEW", Vector3(-1.75, 1.03, 7.18), 40)
	_box("FinishMarquee", Vector3(0, 5.05, -7.0), Vector3(3.6, 0.42, 0.12), Color("571256"))
	_label("EVERY BODY WINS", Vector3(0, 5.05, -6.92), 72)
	var finish := Area3D.new()
	finish.name = "FinishCelebration"
	finish.position = Vector3(0, 1.0, -6.95)
	finish.collision_layer = 0
	finish.collision_mask = trigger.collision_mask
	var sensor := CollisionShape3D.new()
	var zone := BoxShape3D.new()
	zone.size = Vector3(6.0, 2.0, 0.55)
	sensor.shape = zone
	finish.add_child(sensor)
	finish.body_entered.connect(_finish_entered)
	add_child(finish)

func _build_jump_cap(index: int, at: Vector3, colour: Color) -> void:
	var stem := CylinderMesh.new()
	stem.height = at.y - 0.17
	stem.top_radius = 0.36
	stem.bottom_radius = 0.55
	_mesh("PearlStalk", stem, Vector3(at.x, stem.height * 0.5, at.z), _material(Color("f3cde9")))
	var cap := CylinderMesh.new()
	cap.height = 0.22
	cap.top_radius = 1.02
	cap.bottom_radius = 1.13
	cap.radial_segments = 32
	var platform := _mesh("JumpCap%d" % (index + 1), cap, at - Vector3.UP * 0.11, _material(colour, 0.25), true)
	var ground := GroundPhysics.new()
	ground.name = "GroundPhysics"
	ground.physics = GroundSettings.new()
	ground.physics.flags = GroundSettings.GroundPhysicsFlags.JUMP_VELOCITY
	ground.physics.jump_velocity = 5.8
	platform.get_child(0).add_child(ground)
	for spot in range(7):
		var angle := TAU * spot / 7.0
		var point := at + Vector3(cos(angle) * 0.75, 0.0, sin(angle) * 0.75)
		_ball("CapPearl", point, Vector3(0.22, 0.04, 0.22), Color("fff0e9"))

func _build_ribbons(colours: Array) -> void:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lanes := [-4.1, -3.1, -2.15, 1.9, 2.95, 4.0]
	for ribbon in range(lanes.size()):
		mesh.set_color(colours[ribbon % colours.size()])
		for section in range(32):
			var z0 := 5.7 - section * 0.35
			var z1 := z0 - 0.35
			for vertex in [Vector2(0, z0), Vector2(1, z0), Vector2(1, z1), Vector2(0, z0), Vector2(1, z1), Vector2(0, z1)]:
				var phase: float = vertex.y * 0.65 + ribbon * 0.44
				mesh.add_vertex(Vector3(lanes[ribbon] + sin(phase) * 0.5 + vertex.x * 0.27, 4.87 + cos(phase) * 0.47, vertex.y))
	var material := _material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh("FestivalRibbons", mesh.commit(), Vector3.ZERO, material)

func _finish_entered(body: Node3D) -> void:
	if _is_visitor(body):
		_start_burst(-5.75)

func _release_sparks(world_point: Vector3) -> void:
	# There are five one-shot cubes per hall visit. Also cap the active pool.
	if spark_bursts.get_child_count() >= 5:
		var oldest := spark_bursts.get_child(0)
		spark_bursts.remove_child(oldest)
		oldest.queue_free()
	var burst: Node3D = SparkBurst.new()
	burst.palette.assign(arch.rainbow_colors)
	burst.position = spark_bursts.to_local(world_point)
	spark_bursts.add_child(burst)

func _build_finish_banner() -> void:
	# A separate six-stripe banner: changing the arch does not rewrite flags.
	for side in [-1, 1]:
		var pole := CylinderMesh.new()
		pole.top_radius = 0.045
		pole.bottom_radius = 0.055
		pole.height = 4.95
		pole.radial_segments = 12
		_mesh("FinishPoleLeft" if side < 0 else "FinishPoleRight", pole, Vector3(side * 3.4, 2.475, -7.0), _material(Color("e5c387"), 0.35), true)
		_box("FinishPoleFoot", Vector3(side * 3.4, 0.045, -7), Vector3(0.4, 0.09, 0.4), Color("eee9df"), true)
	var colours := [Color("ee4053"), Color("ff952d"), Color("ffdc55"), Color("46bb82"), Color("4e88e5"), Color("9b67d9")]
	for stripe in range(6):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for section in range(40):
			var u0: float = float(section) / 40.0
			var u1: float = float(section + 1) / 40.0
			var v0: float = float(stripe) / 6.0
			var v1: float = float(stripe + 1) / 6.0
			for uv in [Vector2(u0,v0), Vector2(u0,v1), Vector2(u1,v0), Vector2(u1,v0), Vector2(u0,v1), Vector2(u1,v1)]:
				var sag: float = sin(uv.x * PI)
				surface.add_vertex(Vector3(lerpf(-3.4, 3.4, uv.x), 4.7 - uv.y * 1.6 - sag * 0.25, sin(uv.x * TAU * 3.0) * sag * 0.12))
		surface.generate_normals()
		var mat := _material(colours[stripe])
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mesh("FinishBannerStripe_%d" % stripe, surface.commit(), Vector3(0,0,-7), mat)
