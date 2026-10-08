extends Node3D
## A self-contained Boolean egg study: three different operations held together
## by color, scale, and a quiet ring of light. It is an original study after
## Kapoor's void work, not a reconstruction of any one artwork.

const PLINTH_SIZE := Vector3(7.8, 0.34, 3.2)
@export var show_ground := true
@export var museum_mount := false

func _ready() -> void:
	_build_stage()
	_build_light_ring()
	_build_eggs()
	_build_labels()

func _build_stage() -> void:
	var floor := _box("Ground", Vector3(12.0, 0.12, 7.0), Vector3(0.0, -0.34, 0.0), Color("#11121e"), 0.92)
	if show_ground:
		add_child(floor)
	else:
		floor.free()
	var plinth := _box("Egg plinth", PLINTH_SIZE, Vector3(0.0, -0.13, 0.0), Color("#dedbe2"), 0.68)
	add_child(plinth)
	plinth.create_trimesh_collision()
	var reveal := _box("Plinth shadowline", Vector3(7.84, 0.08, 3.24), Vector3(0.0, -0.34, 0.0), Color("#292735"), 0.82)
	add_child(reveal)

func _build_light_ring() -> void:
	var ring := MeshInstance3D.new()
	ring.name = "The almost-halo"
	var torus := TorusMesh.new()
	torus.inner_radius = 2.46
	torus.outer_radius = 2.50
	torus.rings = 96
	torus.ring_segments = 8
	ring.mesh = torus
	ring.position = Vector3(0.0, 2.55, -1.0)
	ring.rotation.x = deg_to_rad(90.0)
	if museum_mount:
		ring.scale = Vector3.ONE * 0.87
		ring.position.y = 2.22
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.34, 0.20, 0.66, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.12, 0.055, 0.34, 1.0)
	material.emission_energy_multiplier = 0.8
	ring.material_override = material
	add_child(ring)

func _build_eggs() -> void:
	_add_union_egg(Vector3(-2.28, 0.30, 0.0), Color("#38224f"), Color("#704773"))
	_add_intersection_egg(Vector3(0.0, 0.30, 0.0), Color("#202957"), Color("#354b87"))
	_add_subtracted_egg(Vector3(2.28, 0.30, 0.0), Color("#174746"), Color("#090b13"))

func _add_union_egg(at: Vector3, body_color: Color, crest_color: Color) -> void:
	var form := CSGCombiner3D.new()
	form.name = "Union — paired ovoids"
	form.use_collision = true
	form.position = at
	var body := _csg_egg("First body", Vector3(0.0, 0.74, 0.0), Vector3(0.72, 1.0, 0.62), body_color)
	form.add_child(body)
	var crest := _csg_egg("Second body / UNION", Vector3(0.12, 1.10, 0.04), Vector3(0.47, 0.67, 0.46), crest_color)
	crest.operation = CSGShape3D.OPERATION_UNION
	form.add_child(crest)
	add_child(form)

func _add_intersection_egg(at: Vector3, body_color: Color, cut_color: Color) -> void:
	var form := CSGCombiner3D.new()
	form.name = "Intersection — shared volume"
	form.use_collision = true
	form.position = at
	var first := _csg_egg("First volume", Vector3(-0.10, 0.74, 0.0), Vector3(0.78, 0.99, 0.63), body_color)
	form.add_child(first)
	var second := _csg_egg("Second volume / INTERSECTION", Vector3(0.34, 0.82, 0.02), Vector3(0.68, 0.91, 0.58), cut_color)
	second.operation = CSGShape3D.OPERATION_INTERSECTION
	form.add_child(second)
	add_child(form)

func _add_subtracted_egg(at: Vector3, body_color: Color, cavity_color: Color) -> void:
	var form := CSGCombiner3D.new()
	form.name = "Subtraction — opened egg"
	form.use_collision = true
	form.position = at
	var body := _csg_egg("Outer ovoid", Vector3(0.0, 0.72, 0.0), Vector3(0.73, 1.02, 0.62), body_color)
	form.add_child(body)
	var opening := _csg_egg("Cutter / SUBTRACTION", Vector3(0.0, 0.87, 0.55), Vector3(0.48, 0.63, 0.44), cavity_color)
	# Remove lighting cues from the real concavity; its rim still shows depth.
	var void_material := StandardMaterial3D.new()
	void_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	void_material.albedo_color = Color("#030208")
	opening.material = void_material
	opening.operation = CSGShape3D.OPERATION_SUBTRACTION
	form.add_child(opening)
	add_child(form)

func _csg_egg(label: String, at: Vector3, dimensions: Vector3, color: Color) -> CSGSphere3D:
	var egg := CSGSphere3D.new()
	egg.name = label
	egg.radius = 1.0
	egg.radial_segments = 48
	egg.rings = 32
	egg.position = at
	egg.scale = dimensions
	egg.material = _egg_material(color)
	return egg

func _egg_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.29
	material.metallic = 0.12
	material.emission_enabled = true
	material.emission = color * 0.14
	material.emission_energy_multiplier = 0.72
	return material

func _build_labels() -> void:
	_add_label("BOOLEAN EGGS", Vector3(0.0, 3.0, -0.15), 0.34, Color("#f1edf8"))
	_add_label("UNION", Vector3(-2.28, 0.20, 1.16), 0.15, Color("#d1b1df"))
	_add_label("INTERSECTION", Vector3(0.0, 0.20, 1.16), 0.15, Color("#b7c5f2"))
	_add_label("SUBTRACTION", Vector3(2.28, 0.20, 1.16), 0.15, Color("#a4dad2"))
	_add_label("Three operations. Three bodies. No single final form.", Vector3(0.0, 2.56, -0.15), 0.14, Color("#aaa6b8"))

func _add_label(text_value: String, at: Vector3, size: float, color: Color) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.position = at
	label.font_size = int(size * 100.0)
	label.pixel_size = 0.01
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)

func _box(label: String, dimensions: Vector3, at: Vector3, color: Color, roughness: float) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	var box_mesh := BoxMesh.new()
	box_mesh.size = dimensions
	mesh_instance.mesh = box_mesh
	mesh_instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	mesh_instance.material_override = material
	return mesh_instance
