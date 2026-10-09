extends Node3D
## The Point One study has its own directional light and diffuse fill.
## Its spheres use layer 18; the existing museum floor also receives this sun
## on layer 17. No extra floor geometry is needed. Other halls keep their lighting.
const STUDY_LAYER := 1 << 17
const FLOOR_LAYER := 1 << 16
const ButtonScript = preload("res://commons/interactables/interactable_area_button_pointer.gd")
var sun: DirectionalLight3D
var fill: OmniLight3D
var button: Area3D
var lever: MeshInstance3D
var caption: Label3D
var enabled := true
var receivers: Array[MultiMeshInstance3D] = []
var _floor_surfaces: Array = []
var _bound_points := 0
var _other_lights: Array = []
var _surfaces: Array = []
var _hall: Node3D
var _elapsed := 1.0
var _turn: Tween
var _lights_bound := false

func _ready() -> void:
	var plate := box(Vector3(0.20,0.32,0.035),Vector3(0,1.28,0),Color("ece9df"))
	plate.name = "SwitchPlate"
	lever = box(Vector3(0.08,0.13,0.05),Vector3(0,1.28,0.035),Color("393936"))
	lever.name = "Lever"
	caption = Label3D.new()
	caption.position = Vector3(0,1.56,0.025)
	caption.font_size = 32
	caption.pixel_size = 0.0015
	caption.outline_size = 0
	caption.modulate = Color("353531")
	add_child(caption)
	button = Area3D.new()
	button.name = "SunSwitchButton"
	button.set_script(ButtonScript)
	button.set("button",NodePath("../Lever"))
	button.set("displacement",Vector3.ZERO)
	button.collision_layer = 1 << 20
	button.collision_mask = 393216
	button.position = Vector3(0,1.28,0.04)
	var shape := CollisionShape3D.new()
	var volume := BoxShape3D.new()
	volume.size = Vector3(0.16,0.24,0.12)
	shape.shape = volume
	button.add_child(shape)
	add_child(button)
	button.connect("button_pressed",func(_b): set_sun_enabled(not enabled))
	sun = DirectionalLight3D.new()
	sun.name = "PointStudySun"
	sun.light_cull_mask = STUDY_LAYER | FLOOR_LAYER
	sun.shadow_caster_mask = STUDY_LAYER
	sun.light_energy = 1.6
	sun.light_color = Color(1.0,0.96,0.89)
	sun.shadow_enabled = true
	sun.shadow_bias = 0.015
	sun.shadow_normal_bias = 0.2
	sun.directional_shadow_max_distance = 45.0
	add_child(sun)
	sun.global_rotation_degrees = Vector3(-36,-32,0)
	fill = OmniLight3D.new()
	fill.name = "PointStudyFill"
	fill.light_cull_mask = STUDY_LAYER
	fill.light_energy = 0.42
	fill.omni_range = 24.0
	fill.omni_attenuation = 0.3
	fill.shadow_enabled = false
	add_child(fill)
	fill.global_position = global_position + Vector3(-1.5,3,1)
	set_sun_enabled(true)
	_bind_hall.call_deferred()

func box(size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var form := BoxMesh.new()
	form.size = size
	mesh.mesh = form
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.85
	mesh.material_override = material
	mesh.position = at
	add_child(mesh)
	return mesh

func set_sun_enabled(value: bool) -> void:
	enabled = value
	sun.visible = enabled
	caption.text = "SUN / ON" if enabled else "SUN / OFF"
	if _turn: _turn.kill()
	_turn = create_tween()
	_turn.tween_property(lever,"rotation:x",deg_to_rad(-24 if enabled else 24),0.16)

func _bind_hall() -> void:
	var node := get_parent()
	while node != null:
		if node is Node3D and str(node.get_meta("em_map","")) == "Point_One":
			_hall = node
			break
		node = node.get_parent()
	# Supports a standalone map/scene as well as the streamed museum.
	if _hall == null and get_parent() is Node3D: _hall = get_parent()
	_prepare_study()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < 1.0 or not is_instance_valid(_hall): return
	_elapsed = 0.0
	_prepare_study()

func _prepare_study() -> void:
	# Stamping may finish after this artifact enters the tree. Each object is
	# claimed once; newly loaded lights also exclude these dedicated surfaces.
	for node in _hall.find_children("*","Node3D",true,false):
		if node.get_script() == null or not str(node.get_script().resource_path).ends_with("/point_condition.gd"): continue
		if node.condition not in ["visible","solid","pedestal"] or node.get_meta("point_sun_claimed",false): continue
		if not is_instance_valid(node.point): continue
		node.set_meta("point_sun_claimed",true)
		for mesh in node.find_children("*","MeshInstance3D",true,false):
			# The point changes under its own sun; its museum support keeps the
			# room's light, matching the empty station's otherwise identical base.
			if mesh.name in ["PointPlinth", "Pedestal"]: continue
			_surfaces.append({"node":weakref(mesh),"layers":mesh.layers,"material":mesh.material_override})
			mesh.layers = STUDY_LAYER
			if mesh.material_override is StandardMaterial3D:
				mesh.material_override = mesh.material_override.duplicate()
				mesh.material_override.disable_ambient_light = true
		_bound_points += 1
	# The museum batches its architecture by material. Claim only the flat,
	# ground-level floor batches directly in this hall, never artifact plinths.
	# Keep their material, ordinary light layers, geometry and collision intact.
	for child in _hall.get_children():
		if not child is MultiMeshInstance3D or child in receivers: continue
		var bounds: AABB = child.transform * child.get_aabb()
		if absf(bounds.end.y) > 0.01 or bounds.position.y < -0.3: continue
		if bounds.size.y < 0.05 or bounds.size.x < 0.5 or bounds.size.z < 0.5: continue
		_floor_surfaces.append({"node":weakref(child),"layers":child.layers})
		child.layers |= FLOOR_LAYER
		receivers.append(child)
	for light in get_tree().root.find_children("*","Light3D",true,false):
		if not _lights_bound: _exclude_light(light)
	if not _lights_bound:
		get_tree().node_added.connect(_on_node_added)
		_lights_bound = true
	if _bound_points == 3 and not receivers.is_empty(): set_process(false)

func _on_node_added(node: Node) -> void:
	if node is Light3D: _exclude_light.call_deferred(node)

func _exclude_light(light: Light3D) -> void:
	if not is_instance_valid(light) or light == sun or light == fill: return
	if ((light.light_cull_mask | light.shadow_caster_mask) & STUDY_LAYER) == 0: return
	_other_lights.append({"node":weakref(light),"mask":light.light_cull_mask,"casters":light.shadow_caster_mask})
	light.light_cull_mask &= ~STUDY_LAYER
	light.shadow_caster_mask &= ~STUDY_LAYER

func _exit_tree() -> void:
	for item in _floor_surfaces:
		var floor_mesh = item.node.get_ref()
		if is_instance_valid(floor_mesh):
			floor_mesh.layers = (floor_mesh.layers & ~FLOOR_LAYER) | (item.layers & FLOOR_LAYER)
	for item in _other_lights:
		var light = item.node.get_ref()
		if is_instance_valid(light):
			light.light_cull_mask |= (item.mask & STUDY_LAYER)
			light.shadow_caster_mask |= (item.casters & STUDY_LAYER)
	for item in _surfaces:
		var mesh = item.node.get_ref()
		if is_instance_valid(mesh):
			mesh.layers = item.layers
			mesh.material_override = item.material
