## Shader 11: Queer Rubber — leather, latex, oil slick, pop plastic, fur
## Material extravaganza on 3D objects. Not flat panels. THEATRICAL.
extends Node3D

var materials: Array[ShaderMaterial] = []
var objects: Array[MeshInstance3D] = []
var rotation_speeds: Array[float] = []

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
	var arc_radius := 5.0
	var arc_start := -PI * 0.35
	var arc_end := PI * 0.35

	for i in range(count):
		var def = material_defs[i]
		var t: float = float(i) / float(count - 1) if count > 1 else 0.5
		var angle: float = lerp(arc_start, arc_end, t)
		var x: float = sin(angle) * arc_radius
		var z: float = -cos(angle) * arc_radius + arc_radius * 0.3

		# Create 3D object based on mesh type
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "Object_%s" % def["title"].replace(" ", "_")

		var s := float(def["scale"])
		match def["mesh"]:
			"sphere":
				var sphere := SphereMesh.new()
				sphere.radius = 0.6 * s
				sphere.height = 1.2 * s
				sphere.radial_segments = 64
				sphere.rings = 32
				mesh_inst.mesh = sphere
			"torus":
				var torus := TorusMesh.new()
				torus.inner_radius = 0.25 * s
				torus.outer_radius = 0.6 * s
				torus.rings = 48
				torus.ring_segments = 24
				mesh_inst.mesh = torus
			"capsule":
				var capsule := CapsuleMesh.new()
				capsule.radius = 0.4 * s
				capsule.height = 1.2 * s
				mesh_inst.mesh = capsule
			"cylinder":
				var cyl := CylinderMesh.new()
				cyl.top_radius = 0.5 * s
				cyl.bottom_radius = 0.5 * s
				cyl.height = 1.0 * s
				cyl.radial_segments = 48
				mesh_inst.mesh = cyl

		# Apply shader material
		var mat := ShaderMaterial.new()
		mat.shader = load(def["shader"])
		mesh_inst.material_override = mat
		mesh_inst.position = Vector3(x, 1.5, z)
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
		title.position = Vector3(x, 0.2, z)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(title)

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
	pass
