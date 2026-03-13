## Shader 12: PINK EXTRAVAGANZA — Drag shader finale
## Melted candy, crushed pearl, memory skin, queer water, DRAG EXTRAVAGANZA
## This is LOUD. This is the final boss. Everything is maxed out.
extends Node3D

var materials: Array[ShaderMaterial] = []
var objects: Array[MeshInstance3D] = []
var rotation_speeds: Array[float] = []

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
		var s := float(def["scale"])

		match def["mesh"]:
			"sphere":
				var sphere := SphereMesh.new()
				sphere.radius = 0.6 * s
				sphere.height = 1.2 * s
				sphere.radial_segments = 64
				sphere.rings = 32
				mesh_inst.mesh = sphere
			"sphere_big":
				var sphere := SphereMesh.new()
				sphere.radius = 0.8 * s
				sphere.height = 1.6 * s
				sphere.radial_segments = 48
				sphere.rings = 24
				mesh_inst.mesh = sphere
			"torus":
				var torus := TorusMesh.new()
				torus.inner_radius = 0.3 * s
				torus.outer_radius = 0.7 * s
				torus.rings = 64
				torus.ring_segments = 32
				mesh_inst.mesh = torus
			"capsule":
				var capsule := CapsuleMesh.new()
				capsule.radius = 0.45 * s
				capsule.height = 1.4 * s
				mesh_inst.mesh = capsule
			"plane":
				var plane := PlaneMesh.new()
				plane.size = Vector2(4.0 * s, 4.0 * s)
				plane.subdivide_width = 24
				plane.subdivide_depth = 24
				mesh_inst.mesh = plane

		var mat := ShaderMaterial.new()
		mat.shader = load(def["shader"])
		mesh_inst.material_override = mat
		mesh_inst.position = pos
		add_child(mesh_inst)
		objects.append(mesh_inst)
		materials.append(mat)
		rotation_speeds.append(def["rotation_speed"])

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

