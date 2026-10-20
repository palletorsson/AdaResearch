extends Node3D
const Model = preload("model.gd")
const V2World = preload("v2_world.gd")
const PointBody = preload("res://commons/artifacts/particle_swarm_walk/point_body.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
const HOME := Vector3(-6, 1.18, -2.6)
const GOLD := Color("ffcf65")
const DARK := Color("111721")
var model = Model.new()
var point: XRToolsPickable
var views: Array[Dictionary] = []
var textures: Array[ImageTexture] = []
var images: Array[Image] = []
var status: Label3D
var mode_words: Label3D
var buttons: Array[Node3D] = []
var released := 0.0
var ant_mesh: ArrayMesh
var field_material: StandardMaterial3D
var v2_material: ShaderMaterial

func mat(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = .42
	return m

func box(size: Vector3, at: Vector3, colour: Color, parent: Node3D, solid := false) -> MeshInstance3D:
	var surface := MeshInstance3D.new()
	var mesh := BoxMesh.new(); mesh.size = size
	surface.mesh = mesh; surface.position = at; surface.material_override = mat(colour)
	parent.add_child(surface)
	if solid:
		var body := StaticBody3D.new(); body.collision_layer = 1; body.collision_mask = 0
		var boundary := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size
		boundary.shape = shape; body.add_child(boundary); parent.add_child(body); body.position = at
	return surface

func words(text: String, at: Vector3, size := 28) -> Label3D:
	var label := Label3D.new(); label.text = text; label.position = at
	label.font_size = size; label.pixel_size = .003; label.outline_size = 6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	return label

func _ready() -> void:
	model.v2 = V2World.new(); add_child(model.v2)
	process_physics_priority = 2
	v2_material = ShaderMaterial.new()
	v2_material.shader = preload("v2_field.gdshader")
	for n in [64, 40]:
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		images.append(img); textures.append(ImageTexture.create_from_image(img))
	field_material = mat(Color.WHITE)
	field_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	field_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	ant_mesh = make_ant_mesh()
	box(Vector3(8.12, .025, 8.12), Vector3(0, .014, 0), GOLD, self)
	make_view(self, Vector3(0, .031, 0), 8.0, "WalkIn")
	box(Vector3(1.94, .09, 1.94), Vector3(-6, .92, 2.5), DARK, self, true)
	box(Vector3(.55, .87, .55), Vector3(-6, .435, 2.5), Color("eee8dc"), self, true)
	make_view(self, Vector3(-6, .971, 2.5), 1.8, "Table")
	box(Vector3(.4, 1.0, .4), Vector3(-6, .5, -2.6), Color("eee8dc"), self, true)
	point = PointBody.new(); point.name = "CarryThePattern"; add_child(point); point.position = HOME
	box(Vector3(.48, .018, .48), Vector3(0, .055, -.31), GOLD, point)
	make_view(point, Vector3(0, .065, -.31), .45, "Hand")
	point.action_pressed.connect(func(_p):
		if point.held(): toggle_play())
	words("ONE PATTERN / THREE SIZES", Vector3(-.1, 3.35, -4.65), 62)
	words("A hand. A table. A floor you can cross.", Vector3(-.1, 3, -4.65), 27)
	mode_words = words("", Vector3(0, 2.55, -4.65), 27)
	words("HAND / 45 cm\nTake the black point\nTrigger: pause / continue", HOME + Vector3(0, .63, 0), 21)
	words("TABLE / 1.8 m", Vector3(-6, 1.8, 2.5), 24)
	words("WALK IN / 8 m", Vector3(0, .16, 4.55), 31)
	box(Vector3(1.15, .09, 1.1), Vector3(-6, .9, 0), DARK, self, true)
	box(Vector3(.22, .85, .22), Vector3(-6, .425, 0), Color("eee8dc"), self, true)
	add_button("TRAILS", Vector3(-6.38, .96, -.28), func(): select(0))
	add_button("TURMITES", Vector3(-6, .96, -.28), func(): select(1))
	add_button("ANT COLONY\nV2", Vector3(-5.62, .96, -.28), func(): select(2))
	add_button("PAUSE / PLAY", Vector3(-6.3, .96, .28), toggle_play)
	add_button("RESTART", Vector3(-5.7, .96, .28), restart)
	status = words("", Vector3(-6, 1.67, 0), 21)
	paint()

func add_button(title: String, at: Vector3, action: Callable) -> void:
	var b := PushButton.instantiate(); b.name = title.replace(" / ", ""); add_child(b)
	b.position = at; b.rotation = Vector3.ZERO; b.scale = Vector3.ONE * 1.5
	b.pressed.connect(action); buttons.append(b)
	words(title, at + Vector3(0, .18, 0), 14)

func make_view(parent: Node3D, at: Vector3, span: float, title: String) -> void:
	var frame := Node3D.new(); frame.name = title; parent.add_child(frame); frame.position = at
	var plane := MeshInstance3D.new(); var quad := PlaneMesh.new(); quad.size = Vector2(span, span)
	plane.mesh = quad; plane.material_override = field_material; frame.add_child(plane)
	var ants := MultiMeshInstance3D.new(); var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true; mm.mesh = ant_mesh; mm.instance_count = 100
	ants.multimesh = mm; frame.add_child(ants)
	var finish := mat(GOLD); finish.vertex_color_use_as_albedo = true
	finish.metallic = .32; finish.roughness = .27
	finish.emission_enabled = true; finish.emission = GOLD; finish.emission_energy_multiplier = .12
	ants.material_override = finish
	var anchors := Node3D.new(); frame.add_child(anchors)
	var centers: Array[Vector3] = [Vector3.ZERO]
	centers.append_array(model.v2.colony._anchor_positions())
	for i in range(centers.size()):
		var marker := MeshInstance3D.new(); var disc := CylinderMesh.new()
		var r: float = (3.0 if i == 0 else 4.5) / 50.0 * span
		disc.top_radius = r; disc.bottom_radius = r; disc.height = span * .003
		marker.mesh = disc
		marker.position = centers[i] / 50.0 * span + Vector3.UP * span * .002
		var colour := mat(Color("4bbfd5") if i == 0 else Color("eb547e"))
		colour.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		marker.material_override = colour; anchors.add_child(marker)
	views.append({"root": frame, "plane": plane, "ants": ants, "span": span, "anchors": anchors})

func make_ant_mesh() -> ArrayMesh:
	# One combined ant silhouette, instanced three times per agent (one per view).
	# The legs are visual signs, not a gait or a separate simulation.
	var builder := SurfaceTool.new(); builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in [Vector3(0, .09, -.22), Vector3(0, .09, 0), Vector3(0, .1, .19)]:
		var bead := SphereMesh.new(); bead.radius = .1 if p.z > -.1 else .14
		bead.height = bead.radius * 2; bead.radial_segments = 8; bead.rings = 4
		builder.append_from(bead, 0, Transform3D(Basis(), p))
	for side in [-1, 1]:
		for z in [-.13, 0, .13]:
			var a := Vector3(0, .09, z); var b := Vector3(side * .26, .025, z * 1.8)
			var leg := CylinderMesh.new(); leg.top_radius = .014; leg.bottom_radius = .014
			leg.height = a.distance_to(b); leg.radial_segments = 4
			var direction := (b - a).normalized()
			builder.append_from(leg, 0, Transform3D(Basis(Quaternion(Vector3.UP, direction)), (a + b) / 2))
	return builder.commit()

func _physics_process(dt: float) -> void:
	if point.held(): released = 0
	else:
		released += dt
		if released > 5 and (point.position.distance_to(HOME) > .001 or not point.rotation.is_zero_approx()):
			point.position = HOME; point.rotation = Vector3.ZERO
	if model.advance(dt): paint()

func select(which: int) -> void:
	model.select(which); paint()

func toggle_play() -> void:
	model.playing = not model.playing; paint()

func restart() -> void:
	model.reset(model.mode); paint()

func paint() -> void:
	if images.is_empty(): return
	if model.mode == 2:
		v2_material.set_shader_parameter("trail_texture", model.v2.colony.p_texture)
	else:
		var img := images[model.mode]; var n: int = model.size()
		for y in range(n):
			for x in range(n):
				var c: Color
				if model.mode == 0:
					# Display-only map. The original concentration is retained verbatim.
					var v: float = clampf(model.trail._pheromone[y*n+x] / 3.0, 0, 1)
					c = DARK.lerp(Color("126679"), minf(v*4, 1)).lerp(GOLD, pow(v, .65))
				else: c = model.turmite._palette[int(model.turmite._state[y][x])]
				img.set_pixel(x, y, c)
		textures[model.mode].update(img)
		field_material.albedo_texture = textures[model.mode]
	for view in views:
		view.plane.material_override = v2_material if model.mode == 2 else field_material
		view.anchors.visible = model.mode == 2
		view.ants.material_override.albedo_color = Color.WHITE if model.mode == 2 else GOLD
		view.ants.material_override.emission = Color.WHITE if model.mode == 2 else GOLD
		var span: float = view.span
		var mm: MultiMesh = view.ants.multimesh; mm.visible_instance_count = model.count()
		for i in range(model.count()):
			var p: Vector2 = model.position_of(i)
			var body_size := .038 if model.mode == 2 else .095
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, model.yaw_of(i)).scaled(Vector3.ONE * span * body_size), Vector3(p.x*span, span*.006, p.y*span)))
			var colour := Color.WHITE if i != 0 else Color("7bdbe9")
			if model.mode == 2:
				colour = Color("ff7895") if model.v2.ants[i].current_state == SimpleAnt.State.RETURNING else GOLD
			mm.set_instance_color(i, colour)
	if status != null:
		status.text = ("RUNNING" if model.playing else "PAUSED") + " / %d %s\n%d agents / same live state" % [model.steps[model.mode], "physics ticks" if model.mode == 2 else "steps", model.count()]
	if mode_words != null:
		mode_words.text = ["TRAILS / sense, deposit, diffuse, fade", "TURMITES / turn, write, move / starts at step 900", "ANT COLONY V2 / 100 ants\nCyan: home trail / Rose: food trail\nGold ants: foraging / Pink ants: returning"][model.mode]
	if buttons.size() == 5:
		buttons[0].set_selected(model.mode == 0)
		buttons[1].set_selected(model.mode == 1)
		buttons[2].set_selected(model.mode == 2)
		buttons[3].set_selected(not model.playing)

func get_museum_occupied_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for z in [-2.6, 0, 2.5]:
		var half := .98 if z == 2.5 else .6
		for dx in [-half, 0.0, half]:
			for dz in [-half, 0.0, half]:
				var p := to_global(Vector3(-6+dx, 0, z+dz)); var c := Vector2i(floori(p.x), floori(p.z))
				if not result.has(c): result.append(c)
	return result
