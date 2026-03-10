extends Node3D
## Builds a 3D scene from raw primitives — boxes, spheres, cylinders, planes.
## Each primitive gets position, rotation, scale, and a material (color + emission).
## Called via apply_grid_config() with a "primitives" array in the config.

func _ready() -> void:
	pass


func apply_grid_config(config: Dictionary) -> void:
	var primitives: Array = config.get("primitives", [])
	var camera_cfg: Dictionary = config.get("camera", {})
	var lights: Array = config.get("lights", [])
	var bg_color: String = config.get("background", "#1a1a2e")

	print("primitive_scene_builder: %d primitives, %d lights" % [primitives.size(), lights.size()])

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(bg_color)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(config.get("ambient", "#333344"))
	env.ambient_light_energy = config.get("ambient_energy", 0.4)
	# Tonemap: 0=linear, 1=reinhardt, 2=filmic, 3=aces
	env.tonemap_mode = 2

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Lights
	if lights.is_empty():
		# Default key light
		lights = [{"type": "directional", "direction": [-0.5, -1, -0.3], "color": "#ffffff", "energy": 1.0}]

	for light_cfg in lights:
		_add_light(light_cfg)

	# Build primitives
	for prim in primitives:
		if not prim is Dictionary:
			continue
		_build_primitive(prim)

	# Camera
	_add_camera(camera_cfg)

	print("primitive_scene_builder: Scene built with %d children" % get_child_count())


func _build_primitive(cfg: Dictionary) -> void:
	var mesh_type: String = str(cfg.get("mesh", "box"))
	var mesh: Mesh = null

	match mesh_type:
		"box":
			var bm := BoxMesh.new()
			bm.size = _vec3(cfg.get("mesh_size", [1, 1, 1]))
			mesh = bm
		"sphere":
			var sm := SphereMesh.new()
			sm.radius = cfg.get("radius", 0.5)
			sm.height = cfg.get("height", 1.0)
			sm.radial_segments = cfg.get("segments", 32)
			sm.rings = cfg.get("rings", 16)
			mesh = sm
		"cylinder":
			var cm := CylinderMesh.new()
			cm.top_radius = cfg.get("top_radius", 0.5)
			cm.bottom_radius = cfg.get("bottom_radius", 0.5)
			cm.height = cfg.get("height", 1.0)
			cm.radial_segments = cfg.get("segments", 16)
			mesh = cm
		"cone":
			var cm := CylinderMesh.new()
			cm.top_radius = 0.0
			cm.bottom_radius = cfg.get("bottom_radius", 0.5)
			cm.height = cfg.get("height", 1.0)
			cm.radial_segments = cfg.get("segments", 8)
			mesh = cm
		"plane":
			var pm := PlaneMesh.new()
			pm.size = Vector2(cfg.get("width", 1.0), cfg.get("depth", 1.0))
			mesh = pm
		"torus":
			var tm := TorusMesh.new()
			tm.inner_radius = cfg.get("inner_radius", 0.2)
			tm.outer_radius = cfg.get("outer_radius", 0.5)
			mesh = tm
		"capsule":
			var cm := CapsuleMesh.new()
			cm.radius = cfg.get("radius", 0.5)
			cm.height = cfg.get("height", 2.0)
			mesh = cm
		"prism":
			var pm := PrismMesh.new()
			pm.size = _vec3(cfg.get("mesh_size", [1, 1, 1]))
			mesh = pm

	if not mesh:
		return

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = cfg.get("name", mesh_type)

	# Material
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(str(cfg.get("color", "#ffffff")))

	var emission_color: String = str(cfg.get("emission", ""))
	if not emission_color.is_empty():
		mat.emission_enabled = true
		mat.emission = Color(emission_color)
		mat.emission_energy_multiplier = cfg.get("emission_energy", 2.0)

	var metallic: float = cfg.get("metallic", 0.0)
	mat.metallic = metallic
	mat.roughness = cfg.get("roughness", 0.7)

	var transparency: float = cfg.get("transparency", 0.0)
	if transparency > 0.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var c := mat.albedo_color
		c.a = 1.0 - transparency
		mat.albedo_color = c

	if cfg.get("unshaded", false):
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	mi.material_override = mat

	# Transform
	var pos = cfg.get("position", [0, 0, 0])
	mi.position = _vec3(pos)

	var rot = cfg.get("rotation", [0, 0, 0])
	mi.rotation_degrees = _vec3(rot)

	var scl = cfg.get("scale", [1, 1, 1])
	mi.scale = _vec3(scl)

	add_child(mi)


func _add_light(cfg: Dictionary) -> void:
	var light_type: String = str(cfg.get("type", "directional"))

	match light_type:
		"directional":
			var dl := DirectionalLight3D.new()
			dl.light_color = Color(str(cfg.get("color", "#ffffff")))
			dl.light_energy = cfg.get("energy", 1.0)
			dl.shadow_enabled = cfg.get("shadow", true)
			var dir = cfg.get("direction", [-0.5, -1, -0.3])
			dl.rotation = Vector3(atan2(-dir[1], sqrt(dir[0] * dir[0] + dir[2] * dir[2])),
				atan2(dir[0], dir[2]), 0)
			add_child(dl)
		"omni":
			var ol := OmniLight3D.new()
			ol.light_color = Color(str(cfg.get("color", "#ffffff")))
			ol.light_energy = cfg.get("energy", 1.0)
			ol.omni_range = cfg.get("range", 10.0)
			ol.position = _vec3(cfg.get("position", [0, 3, 0]))
			ol.shadow_enabled = cfg.get("shadow", false)
			add_child(ol)
		"spot":
			var sl := SpotLight3D.new()
			sl.light_color = Color(str(cfg.get("color", "#ffffff")))
			sl.light_energy = cfg.get("energy", 1.0)
			sl.spot_range = cfg.get("range", 10.0)
			sl.spot_angle = cfg.get("angle", 30.0)
			sl.position = _vec3(cfg.get("position", [0, 3, 0]))
			sl.look_at(_vec3(cfg.get("target", [0, 0, 0])))
			sl.shadow_enabled = cfg.get("shadow", false)
			add_child(sl)


func _add_camera(cfg: Dictionary) -> void:
	var cam := Camera3D.new()
	cam.name = "CaptureCamera"
	cam.fov = cfg.get("fov", 50.0)
	cam.position = _vec3(cfg.get("position", [0, 3, 8]))

	var target = cfg.get("look_at", [0, 0, 0])
	add_child(cam)
	cam.look_at(_vec3(target), Vector3.UP)

	print("primitive_scene_builder: Camera at %s → %s (fov=%d)" % [cam.position, _vec3(target), cam.fov])


func _vec3(arr) -> Vector3:
	if arr is Array and arr.size() >= 3:
		return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
	if arr is Array and arr.size() >= 2:
		return Vector3(float(arr[0]), float(arr[1]), 0)
	return Vector3.ZERO
