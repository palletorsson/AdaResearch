## Shader 12: PINK EXTRAVAGANZA — Drag shader finale
## Melted candy, crushed pearl, memory skin, queer water, DRAG EXTRAVAGANZA
## This is LOUD. This is the final boss. Everything is maxed out.

# @identity
# essence: every uniform cranked past its intended range — melted candy vertex displacement, crushed pearl iridescence, oil slick latex, queer water refraction, drag extravaganza stacking all effects
# desire: to stand in a room where five impossible materials bob and spin under pink/purple light — to witness the GPU compute beauty that taste would forbid
# critical_parameter: rotation_speed — the spinning objects cycle view angles continuously, each revealing a different excess of the material at every moment
# triggers: _process rotates objects and adds gentle sinusoidal bobbing; three OmniLight3D in pink/purple cast theatrical shadows; water plane sits on the floor refracting wrong on purpose
# emerges: the composition — elevated sphere, flanking objects, floor water, HUGE pink title — produces drag runway energy; extravagance as computational posture
# needs: [missing] no VR sliders or buttons — pure maximalist showcase; no interactive control, only witness
# relationships: finale of the entire shader sequence; stacks techniques from all 11 prior lessons; the anti-thesis of shader_01's minimal gradient
# truth: taste is a disciplinary mechanism — extravagance refuses it; the GPU does not know what is too much, it just computes

extends Node3D

var materials: Array[ShaderMaterial] = []
var objects: Array[MeshInstance3D] = []
var rotation_speeds: Array[float] = []

# MAP TOKENS (2026-09-25, Palle: "stages large spheres and cubes then spaces"), e.g.
#   shader_12_pinkextravaganza:0:0#bodies:1.5#shapes:sphere,torus,cube,plane,sphere_big#stage:0.35#water:12
#   bodies  multiplies the three flanking bodies' scale (the big sphere keeps its own; it floats)
#   shapes  mesh kinds in order: sphere | cube | torus | capsule | plane | sphere_big
#   stage   a round podium under each flanking body, metres (0 = none); bodies then SIT on it
#   water   the floor water's side in metres, centred on the anchor (the script's own is 8 m at z + 2)
# A token without these keys builds exactly as before.
var _cfg_bodies: float = 1.0
var _cfg_shapes: PackedStringArray = PackedStringArray()
var _cfg_stage: float = 0.0
var _cfg_water: float = 0.0
var _cfg_v2: bool = false
var _built: bool = false

var material_defs := [
	{
		"shader": "res://algorithms/shaders/queer_collection_2/melted_candy.gdshader",
		"title": "MELTED CANDY",
		"mesh": "sphere",
		"scale": 1.3,
		"rotation_speed": 0.25,
		"y_offset": 0.0
	},
	{
		"shader": "res://algorithms/shaders/queer_collection_2/crushed_pearl.gdshader",
		"title": "CRUSHED PEARL",
		"mesh": "torus",
		"scale": 1.1,
		"rotation_speed": -0.15,
		"y_offset": 0.3
	},
	{
		"shader": "res://algorithms/shaders/queer_collection_2/oil_slick_latex.gdshader",
		"title": "OIL SLICK LATEX",
		"mesh": "capsule",
		"scale": 1.2,
		"rotation_speed": 0.1,
		"y_offset": -0.2
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/queer_water.gdshader",
		"title": "QUEER WATER",
		"mesh": "plane",
		"scale": 2.0,
		"rotation_speed": 0.0,
		"y_offset": -0.5
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/drag_extravaganza.gdshader",
		"title": "★ DRAG EXTRAVAGANZA ★",
		"mesh": "sphere_big",
		"scale": 2.0,
		"rotation_speed": 0.3,
		"y_offset": 1.0
	}
]


func _ready() -> void:
	_build_finale_scene()
	_built = true


func _build_finale_scene() -> void:
	# The main title — HUGE and PINK
	var main_title := Label3D.new()
	main_title.text = "★ P I N K   E X T R A V A G A N Z A ★"
	main_title.font_size = 36
	main_title.pixel_size = 0.001
	main_title.modulate = Color(1.0, 0.08, 0.58)
	main_title.outline_size = 4
	main_title.outline_modulate = Color(0.5, 0.0, 0.3)
	main_title.position = Vector3(0.0, 5.5, -3.0)
	main_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(main_title)

	# Place objects in a dramatic spread
	var positions := [
		Vector3(-4.5, 1.8, 0.0),
		Vector3(-1.5, 2.0, -1.0),
		Vector3(1.5, 1.5, -0.5),
		Vector3(0.0, 0.1, 2.0),     # Water plane on the floor
		Vector3(0.0, 3.0, -2.0)     # Big center sphere elevated
	]

	for i in range(material_defs.size()):
		var def = material_defs[i]
		var pos := positions[i] as Vector3
		pos.y += float(def["y_offset"])

		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "Object_%d" % i
		var kind: String = str(def["mesh"])
		if i < _cfg_shapes.size() and _cfg_shapes[i] != "":
			kind = _cfg_shapes[i]
		var s := float(def["scale"]) * (1.0 if kind in ["sphere_big", "plane"] else _cfg_bodies)
		var half_h: float = 0.6 * s
		match kind:
			"sphere":
				var sphere := SphereMesh.new()
				sphere.radius = 0.6 * s
				sphere.height = 1.2 * s
				sphere.radial_segments = 64
				sphere.rings = 32
				mesh_inst.mesh = sphere
			"cube":
				var box := BoxMesh.new()
				box.size = Vector3(1.0, 1.0, 1.0) * s
				mesh_inst.mesh = box
				half_h = 0.5 * s
			"sphere_big":
				var sphere := SphereMesh.new()
				sphere.radius = 0.8 * s
				sphere.height = 1.6 * s
				sphere.radial_segments = 48
				sphere.rings = 24
				mesh_inst.mesh = sphere
				half_h = 0.8 * s
			"torus":
				var torus := TorusMesh.new()
				torus.inner_radius = 0.3 * s
				torus.outer_radius = 0.7 * s
				torus.rings = 64
				torus.ring_segments = 32
				mesh_inst.mesh = torus
				half_h = 0.2 * s
			"capsule":
				var capsule := CapsuleMesh.new()
				capsule.radius = 0.45 * s
				capsule.height = 1.4 * s
				mesh_inst.mesh = capsule
				half_h = 0.7 * s
			"plane":
				var plane := PlaneMesh.new()
				var wsz: float = _cfg_water if _cfg_water > 0.0 else 4.0 * s
				plane.size = Vector2(wsz, wsz)
				half_h = 0.0
				plane.subdivide_width = 24
				plane.subdivide_depth = 24
				mesh_inst.mesh = plane

		var mat := ShaderMaterial.new()
		mat.shader = load(def["shader"])
		mesh_inst.material_override = mat
		if _cfg_v2 and kind == "plane" and _cfg_water > 0.0:
			pos = Vector3(0.0, 0.1, 0.0)
		elif _cfg_v2 and kind != "sphere_big":
			pos.y = _cfg_stage + half_h
		mesh_inst.position = pos
		add_child(mesh_inst)
		objects.append(mesh_inst)
		materials.append(mat)
		rotation_speeds.append(def["rotation_speed"])
		if _cfg_stage > 0.0 and kind not in ["plane", "sphere_big"]:
			_add_stage(Vector3(pos.x, 0.0, pos.z), maxf(0.6, 0.75 * s), _cfg_stage)

		# Dramatic labels with billboard
		var title := Label3D.new()
		title.text = def["title"]
		title.font_size = 14
		title.pixel_size = 0.001
		title.modulate = Color(1.0, 0.3, 0.7)
		title.outline_size = 2
		title.outline_modulate = Color(0.3, 0.0, 0.2)
		title.position = pos + Vector3(0.0, -1.0, 0.0)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(title)

	# DRAMATIC LIGHTING (shadows off for performance — emission carries the look)
	_add_light(Vector3(-5.0, 5.0, 3.0), Color(1.0, 0.0, 0.5), 8.0)
	_add_light(Vector3(5.0, 5.0, 3.0), Color(0.5, 0.0, 1.0), 8.0)
	_add_light(Vector3(0.0, 6.0, -2.0), Color(1.0, 0.1, 0.8), 6.0)


func _add_light(pos: Vector3, color: Color, energy: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 10.0
	light.shadow_enabled = false
	add_child(light)


func _process(delta: float) -> void:
	for i in range(objects.size()):
		if is_instance_valid(objects[i]) and rotation_speeds[i] != 0.0:
			objects[i].rotate_y(rotation_speeds[i] * delta)
			# Gentle bobbing for the theatrical objects
			if i != 3: # Not the water plane
				objects[i].position.y += sin(Time.get_ticks_msec() * 0.001 + float(i) * 1.5) * 0.001

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	var v2 := false
	if config.has("bodies"):
		_cfg_bodies = clampf(float(str(config["bodies"])), 0.2, 6.0)
		v2 = true
	if config.has("shapes"):
		_cfg_shapes = PackedStringArray()
		for part in str(config["shapes"]).split(","):
			_cfg_shapes.append(part.strip_edges().to_lower())
		v2 = true
	if config.has("stage"):
		_cfg_stage = clampf(float(str(config["stage"])), 0.0, 3.0)
		v2 = true
	if config.has("water"):
		_cfg_water = clampf(float(str(config["water"])), 0.0, 40.0)
		v2 = true
	if not v2:
		return
	_cfg_v2 = true
	if _built:
		_rebuild()


## A low round stage under a body (visual only: the museum's walk map cannot see an
## artifact's own colliders, so a stage that blocked would block in silence).
func _add_stage(at: Vector3, radius: float, height: float) -> void:
	var podium := MeshInstance3D.new()
	podium.name = "Stage_%d" % get_child_count()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 48
	podium.mesh = cyl
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.16, 0.16, 0.19)
	m.roughness = 0.9
	podium.material_override = m
	podium.position = Vector3(at.x, height * 0.5, at.z)
	add_child(podium)


func _rebuild() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
	objects.clear()
	materials.clear()
	rotation_speeds.clear()
	_build_finale_scene()
