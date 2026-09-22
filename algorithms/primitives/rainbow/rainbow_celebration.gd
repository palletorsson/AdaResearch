extends Node3D
## An opt-in room-scale celebration around the existing band generator.
## Geometry and collision stay fixed when the colour partition changes.
const Controls = preload("res://commons/ui/control_panel.gd")
const MODES := ["six", "roygbiv", "continuous", "two"]
const COUNTS := [6, 7, 48, 2]
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

func _ready() -> void:
	arch = load("res://algorithms/primitives/rainbow/rainbow.gd").new()
	arch.name = "BandComparison"
	arch.banding = MODES[0]
	arch.substance = "solid"
	arch.scale = Vector3.ONE * 0.23
	arch.position = Vector3(0, 0.18, -2)
	add_child(arch)
	arch.get_node("AtmosphereParticles").queue_free()
	arch.set_process(false)
	_build_party()
	_apply_palette()

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
	for i in range(8):
		var h: float = heights[i]
		var tile := _box("CandyStep_%d" % i, Vector3(-3.1, h * 0.5, 6.3 - i * 1.5), Vector3(1.8, h, 1.45), Color.WHITE, true)
		tiles.append(tile)
		_box("StepPiping", Vector3(-3.1, h + 0.013, 6.3 - i * 1.5), Vector3(1.72, 0.025, 1.37), Color("fff0e1"))
	for i in range(6):
		var tile := _box("ColourPaver_%d" % i, Vector3(0, 0.014, 5.9 - i * 1.7), Vector3(2.25, 0.022, 1.45), Color.WHITE)
		tiles.append(tile)
	for i in range(3):
		_mushroom(Vector3(4.3, 0, 5 - i * 4.5), [Color("fc65b5"), Color("70def1"), Color("bb85fc")][i], -8.0 + i * 8.0)
	for i in range(8):
		_star(Vector3(-4.8 + i * 1.35, 3.4 + sin(i * 0.8) * 0.7, -5.8), [Color("ffdf69"), Color("fa9bc8"), Color("84e9ed")][i % 3])
	# Three striped banners add pink/cyan/white and brown/black alongside the
	# arc's editable palette, rather than calling one partition exhaustive.
	var flags := [[Color("55cce4"), Color("f4aac8"), Color.WHITE, Color("f4aac8"), Color("55cce4")], [Color("ffc857"), Color.WHITE, Color("a76ed5"), Color("282032")], [Color("603e32"), Color("211b28"), Color("f887aa"), Color("67d6e9"), Color.WHITE]]
	for f in range(3):
		var colours: Array = flags[f]
		for i in range(colours.size()):
			_box("PartyBanner", Vector3(-4.8, 3.1 - i * 0.14, 5 - f * 4.5), Vector3(1.0, 0.14, 0.035), colours[i])
		_box("BannerPole", Vector3(-5.34, 1.7, 5 - f * 4.5), Vector3(0.035, 3.4, 0.035), Color("ffdc80"))
	_box("WelcomePanel", Vector3(0, 5.95, -2), Vector3(5.8, 0.65, 0.1), Color("572c77"))
	_label("EVERY BODY / MORE COLOUR", Vector3(0, 5.95, -1.93), 65)
	var panel := Controls.new()
	panel.name = "PartyControls"
	panel.title = "MAKE ANOTHER RAINBOW"
	panel.position = Vector3(2.15, 1.05, 7.4)
	panel.spacing = 0.4
	add_child(panel)
	readout = panel.add_readout("6 bands / same width")
	var divide: Node3D = panel.add_button("RE-DIVIDE")
	divide.pressed.connect(next_banding)
	buttons.append(divide)
	var party: Node3D = panel.add_button("CELEBRATE")
	party.pressed.connect(celebrate)
	buttons.append(party)
	_box("ControlPlinth", Vector3(2.15, 0.48, 7.35), Vector3(0.95, 0.96, 0.65), Color("eab7dd"), true)
	# Entering this small centre patch gives a welcoming burst; repeat at the button.
	trigger = Area3D.new()
	trigger.name = "WelcomePatch"
	trigger.collision_layer = 0
	trigger.collision_mask = 1 | (1 << 19)
	trigger.position = Vector3(0, 1, 6.4)
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
	multi.instance_count = 96
	confetti.multimesh = multi
	var mat := _material(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	confetti.material_override = mat
	confetti.visible = false
	add_child(confetti)

func _welcome(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("player_body") or body.is_in_group("vr_player") or body.is_in_group("em_walker"):
		celebrate()

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
		tiles[i].material_override.albedo_color = arch.rainbow_colors[i % arch.rainbow_colors.size()]

func celebrate() -> void:
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
	for i in range(96):
		var a: float = i * 2.39996
		var t: float = party_time
		var speed: float = 0.7 + (i % 9) * 0.13
		var p := Vector3(cos(a) * (0.35 + t * speed), 1.4 + (3.4 + (i % 7) * 0.2) * t - 1.8 * t * t, 3.0 + sin(a) * t * speed)
		var basis := Basis.from_euler(Vector3(t * 2 + a, t * 3, a))
		confetti.multimesh.set_instance_transform(i, Transform3D(basis, p))
		confetti.multimesh.set_instance_color(i, Color.from_hsv(fposmod(i * 0.137, 1.0), 0.6, 1.0))
