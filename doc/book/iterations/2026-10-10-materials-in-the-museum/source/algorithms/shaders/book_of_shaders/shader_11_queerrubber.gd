## Shader 11: Queer Rubber — leather, latex, oil slick, pop plastic, fur
## Material extravaganza on 3D objects. Not flat panels. THEATRICAL.

# @identity
# essence: color = PBR(normal, view, roughness, metallic, Fresnel) — five shader materials on 3D objects: leather grain, oil slick thin-film interference, pop plastic Fresnel, fur anisotropy, sad metal
# desire: to watch five rotating objects under dramatic colored lights — leather absorbs, latex catches highlights too sharp, oil slick fractures the spectrum, fur breaks silhouettes
# critical_parameter: rotation_speed — each object spins at a different rate, continuously revealing how the material responds to changing view angles
# triggers: objects rotate automatically in _process; colored OmniLight3D from three angles creates theatrical cross-lighting that exposes each material's character
# emerges: the arc arrangement with dramatic lighting produces a runway/gallery effect — materials become performers, each demanding attention through different optical strategies
# needs: [missing] no VR sliders or buttons — pure showcase; no interactive roughness/metallic control
# relationships: applies all shader techniques from 01-09 to the question of surface identity; feeds into shader_12_pinkextravaganza (everything maxed out)
# truth: every material shader encodes a claim about which bodies deserve to be touched — the question is not how to render realistically but which surfaces get rendered at all

extends Node3D

var materials: Array[ShaderMaterial] = []
var objects: Array[MeshInstance3D] = []
var rotation_speeds: Array[float] = []

# MAP TOKENS (2026-09-25, Palle: "stages large spheres and cubes"), e.g.
#   shader_11_queerrubber:0:0#layout:line#gap:2.2#bodies:1.35#shapes:sphere,torus,sphere,capsule,cube#stage:0.4
#   bodies  multiplies every body's scale ("scale" is the grid component's own key: it scales the node)
#   shapes  mesh kinds in order: sphere | cube | torus | capsule | cylinder
#   stage   a round podium under each body, metres (0 = none); bodies then SIT on it
#   layout  arc (the script's own) | line: a straight line along local z, centred on the anchor,
#           which is the lane between two pier columns of the museum's colonnade
#   gap     metres between body centres in a line
#   arc     the arc's radius, metres
# A token without these keys builds exactly as before.
var _cfg_bodies: float = 1.0
var _cfg_shapes: PackedStringArray = PackedStringArray()
var _cfg_stage: float = 0.0
var _cfg_layout: String = "arc"
var _cfg_gap: float = 2.75
var _cfg_arc: float = 5.0
var _cfg_v2: bool = false
var _built: bool = false

# Existing queer material shaders — referenced, not modified
var material_defs := [
	{
		"shader": "res://algorithms/shaders/queer_materials/leather.gdshader",
		"title": "LEATHER",
		"mesh": "sphere",
		"scale": 1.2,
		"rotation_speed": 0.15
	},
	{
		"shader": "res://algorithms/shaders/queer_collection_2/oil_slick_latex.gdshader",
		"title": "OIL SLICK LATEX",
		"mesh": "torus",
		"scale": 1.0,
		"rotation_speed": 0.2
	},
	{
		"shader": "res://algorithms/shaders/queer_materials/pop_plastic.gdshader",
		"title": "POP PLASTIC",
		"mesh": "sphere",
		"scale": 1.1,
		"rotation_speed": -0.18
	},
	{
		"shader": "res://algorithms/shaders/queer_materials/fur_velvet.gdshader",
		"title": "FUR VELVET",
		"mesh": "capsule",
		"scale": 1.0,
		"rotation_speed": 0.12
	},
	{
		"shader": "res://algorithms/shaders/queer_collection_2/sad_metal.gdshader",
		"title": "SAD METAL",
		"mesh": "cylinder",
		"scale": 1.0,
		"rotation_speed": -0.1
	}
]


func _ready() -> void:
	_build_dramatic_scene()
	_built = true


func _build_dramatic_scene() -> void:
	# Dark ambient lighting cue
	var env_label := Label3D.new()
	env_label.text = "Q U E E R   M A T E R I A L S"
	env_label.font_size = 28
	env_label.pixel_size = 0.001
	env_label.modulate = Color(0.95, 0.15, 0.5)
	env_label.position = Vector3(0.0, 4.0, -2.0)
	env_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(env_label)

	# Arrange objects in a dramatic arc
	var count := material_defs.size()
	var arc_radius: float = _cfg_arc
	var arc_start := -PI * 0.35
	var arc_end := PI * 0.35

	for i in range(count):
		var def = material_defs[i]
		var t: float = float(i) / float(count - 1) if count > 1 else 0.5
		var angle: float = lerp(arc_start, arc_end, t)
		var x: float = sin(angle) * arc_radius
		var z: float = -cos(angle) * arc_radius + arc_radius * 0.3
		if _cfg_layout == "line":
			x = 0.0
			z = (float(i) - float(count - 1) * 0.5) * _cfg_gap
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "Object_%s" % def["title"].replace(" ", "_")
		var s := float(def["scale"]) * _cfg_bodies
		var kind: String = str(def["mesh"])
		if i < _cfg_shapes.size() and _cfg_shapes[i] != "":
			kind = _cfg_shapes[i]
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
			"torus":
				var torus := TorusMesh.new()
				torus.inner_radius = 0.25 * s
				torus.outer_radius = 0.6 * s
				torus.rings = 48
				torus.ring_segments = 24
				mesh_inst.mesh = torus
				half_h = 0.175 * s
			"capsule":
				var capsule := CapsuleMesh.new()
				capsule.radius = 0.4 * s
				capsule.height = 1.2 * s
				mesh_inst.mesh = capsule
				half_h = 0.6 * s
			"cylinder":
				var cyl := CylinderMesh.new()
				cyl.top_radius = 0.5 * s
				cyl.bottom_radius = 0.5 * s
				cyl.height = 1.0 * s
				cyl.radial_segments = 48
				mesh_inst.mesh = cyl
				half_h = 0.5 * s

		# Apply shader material
		var mat := ShaderMaterial.new()
		mat.shader = load(def["shader"])
		mesh_inst.material_override = mat
		mesh_inst.position = Vector3(x, (_cfg_stage + half_h) if _cfg_v2 else 1.5, z)
		add_child(mesh_inst)
		objects.append(mesh_inst)
		materials.append(mat)
		rotation_speeds.append(def["rotation_speed"])

		# Title label below
		var title := Label3D.new()
		title.text = def["title"]
		title.font_size = 16
		title.pixel_size = 0.001
		title.modulate = Color(0.8, 0.2, 0.5)
		title.position = Vector3(x, _cfg_stage + 0.2, z)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(title)
		if _cfg_stage > 0.0:
			_add_stage(Vector3(x, 0.0, z), maxf(0.6, 0.75 * s), _cfg_stage)

	# Dramatic colored lights (as OmniLight3D)
	_add_colored_light(Vector3(-3.0, 3.0, 2.0), Color(1.0, 0.1, 0.5), 8.0)
	_add_colored_light(Vector3(3.0, 3.0, 2.0), Color(0.1, 0.3, 1.0), 8.0)
	_add_colored_light(Vector3(0.0, 4.0, -1.0), Color(0.8, 0.0, 1.0), 6.0)


func _add_colored_light(pos: Vector3, color: Color, energy: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 10.0
	light.shadow_enabled = false
	add_child(light)


func _process(delta: float) -> void:
	for i in range(objects.size()):
		if is_instance_valid(objects[i]):
			objects[i].rotate_y(rotation_speeds[i] * delta)

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
	if config.has("layout"):
		_cfg_layout = str(config["layout"]).strip_edges().to_lower()
		v2 = true
	if config.has("gap"):
		_cfg_gap = clampf(float(str(config["gap"])), 0.5, 12.0)
		v2 = true
	if config.has("arc"):
		_cfg_arc = clampf(float(str(config["arc"])), 2.0, 12.0)
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
	_build_dramatic_scene()
