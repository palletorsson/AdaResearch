# parametric_surface_editor.gd — Wraps the real parametric surfaces at
# commons/primitives/parametric/ into a live editor.
# Loads actual .tscn scene files and adjusts @export parameters.
extends BaseGeometryEditor

const SURFACE_SCENES: Array[String] = [
	"res://commons/primitives/parametric/breather_surface.tscn",
	"res://commons/primitives/parametric/catenoid.tscn",
	"res://commons/primitives/parametric/dini_surface.tscn",
	"res://commons/primitives/parametric/double_enneper.tscn",
	"res://commons/primitives/parametric/enneper_order3.tscn",
	"res://commons/primitives/parametric/figure_eight_knot.tscn",
	"res://commons/primitives/parametric/helicoid.tscn",
	"res://commons/primitives/parametric/klein_bottle.tscn",
	"res://commons/primitives/parametric/mobius_strip.tscn",
	"res://commons/primitives/parametric/parametric.tscn",
	"res://commons/primitives/parametric/seashell.tscn",
	"res://commons/primitives/parametric/torus_knot.tscn",
	"res://commons/primitives/parametric/trefoil_knot.tscn",
	"res://commons/primitives/parametric/wave_torus.tscn",
	# Glass forms as parametric surfaces
	"res://commons/primitives/parametric/glass_surfaces.tscn",
	"res://commons/primitives/parametric/glass_surfaces.tscn",
	"res://commons/primitives/parametric/glass_surfaces.tscn",
	"res://commons/primitives/parametric/glass_surfaces.tscn",
	"res://commons/primitives/parametric/glass_surfaces.tscn",
	"res://commons/primitives/parametric/glass_surfaces.tscn",
	"res://commons/primitives/parametric/glass_surfaces.tscn",
	"res://commons/primitives/parametric/glass_surfaces.tscn",
	"res://commons/primitives/parametric/glass_surfaces.tscn",
	"res://commons/primitives/parametric/glass_surfaces.tscn",
]
const SURFACE_NAMES: Array[String] = [
	"Breather", "Catenoid", "Dini", "Double Enneper", "Enneper Order 3",
	"Figure Eight Knot", "Helicoid", "Klein Bottle", "Mobius Strip",
	"Parametric", "Seashell", "Torus Knot", "Trefoil Knot", "Wave Torus",
	# Glass forms
	"Glass: Straight Tube", "Glass: 90° Corner", "Glass: S-Bend",
	"Glass: U-Bend", "Glass: Spiral Coil", "Glass: Flask",
	"Glass: Beaker", "Glass: Y-Junction", "Glass: Torus Ring",
	"Glass: Twisted Ribbon",
]
# Glass shape_type indices (offset from surface index 14)
const GLASS_START_IDX: int = 14

# Common @export property names found across the parametric surface scripts.
# Each surface extends XRToolsPickable with u_steps, v_steps, and surface-specific
# params like major_radius, minor_radius, wave_amplitude, spiral_tightness, etc.
const COMMON_STEP_PROPS: Array[String] = ["u_steps", "v_steps"]
const SCALE_PROPS: Array[String] = [
	"major_radius", "minor_radius", "radius", "shell_opening",
	"surface_scale", "scale_factor",
]


func _get_editor_name() -> String:
	return "Parametric Surfaces"


func _get_parameter_groups() -> Array:
	return [
		{"name": "Surface", "params": [
			{"id": "surface_type", "label": "Surface", "options": [
			"Breather", "Catenoid", "Dini", "Double Enneper", "Enneper Order 3",
			"Figure Eight Knot", "Helicoid", "Klein Bottle", "Mobius Strip",
			"Parametric", "Seashell", "Torus Knot", "Trefoil Knot", "Wave Torus",
			"Glass: Straight", "Glass: Corner", "Glass: S-Bend", "Glass: U-Bend",
			"Glass: Spiral", "Glass: Flask", "Glass: Beaker", "Glass: Y-Junction",
			"Glass: Ring", "Glass: Twisted Ribbon",
		], "default": 13.0},
			{"id": "scale", "label": "Scale", "min": 0.05, "max": 1.0, "step": 0.01, "default": 0.18},
		]},
		{"name": "Resolution", "params": [
			{"id": "res_u", "label": "U Steps", "min": 10.0, "max": 100.0, "step": 2.0, "default": 40.0},
			{"id": "res_v", "label": "V Steps", "min": 10.0, "max": 100.0, "step": 2.0, "default": 24.0},
		]},
		{"name": "Material", "params": [
			{"id": "mat_type", "label": "Material", "options": ["Default", "Glass", "Metal", "Clay"], "default": 0.0},
		]},
		{"name": "Surface Params", "params": [
			{"id": "param_a", "label": "Param A", "min": 0.01, "max": 2.0, "step": 0.01, "default": 0.5},
			{"id": "param_b", "label": "Param B", "min": 0.01, "max": 2.0, "step": 0.01, "default": 0.5},
		]},
	]


func _rebuild() -> void:
	_clear_content()

	var type_idx: int = clampi(int(p("surface_type", 13)), 0, SURFACE_SCENES.size() - 1)
	var scene_path: String = SURFACE_SCENES[type_idx]

	var scene: PackedScene = load(scene_path) as PackedScene
	if not scene:
		return

	var instance: Node3D = scene.instantiate() as Node3D
	if not instance:
		return

	# Apply resolution parameters — these surfaces use u_steps / v_steps
	var u_res: int = clampi(int(p("res_u", 40)), 10, 100)
	var v_res: int = clampi(int(p("res_v", 24)), 10, 100)
	_try_set(instance, "u_steps", u_res)
	_try_set(instance, "v_steps", v_res)

	# Apply scale — surfaces use different property names for radius/scale
	var scale_val: float = p("scale", 0.18)
	var scale_applied := false
	for prop_name in SCALE_PROPS:
		if instance.get(prop_name) != null:
			var original: float = instance.get(prop_name) as float
			# Scale relative to original default
			instance.set(prop_name, original * (scale_val / 0.18))
			scale_applied = true
	if not scale_applied:
		instance.scale = Vector3.ONE * scale_val

	# Set glass shape_type if this is a glass surface
	if type_idx >= GLASS_START_IDX:
		_try_set(instance, "shape_type", type_idx - GLASS_START_IDX)

	# Apply generic params — map param_a/param_b to surface-specific exports
	var param_a: float = p("param_a", 0.5)
	var param_b: float = p("param_b", 0.5)
	_apply_surface_specific_params(instance, type_idx, param_a, param_b)

	content_root.add_child(instance)

	# Apply material override if not "Default"
	# Deferred because the surface scripts build their mesh in _ready()
	var mat_type: int = int(p("mat_type", 0))
	if mat_type > 0:
		var mat := StandardMaterial3D.new()
		match mat_type:
			1:  # Glass
				mat.albedo_color = Color(0.85, 0.92, 1.0, 0.4)
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.roughness = 0.05
				mat.metallic = 0.1
				mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			2:  # Metal
				mat.albedo_color = Color(0.8, 0.82, 0.85)
				mat.roughness = 0.15
				mat.metallic = 0.9
			3:  # Clay
				mat.albedo_color = Color(0.85, 0.75, 0.65)
				mat.roughness = 0.95
				mat.metallic = 0.0
		_apply_material_deferred.call_deferred(instance, mat)

	# Update info label
	var surface_name: String = SURFACE_NAMES[type_idx]
	var mat_names: Array[String] = ["Default", "Glass", "Metal", "Clay"]
	info_label.text = "%s | %s | %dv" % [surface_name, mat_names[mat_type], u_res * v_res]


## Apply material to all MeshInstance3D nodes in the tree (called deferred after _ready).
## Forces override by setting BOTH material_override AND surface materials on the mesh.
func _apply_material_deferred(root_node: Node, mat: Material) -> void:
	_apply_mat_recursive(root_node, mat)

func _apply_mat_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		mi.material_override = mat
		# Also override surface materials on the mesh itself (some scripts set these)
		if mi.mesh:
			for si in mi.mesh.get_surface_count():
				mi.mesh.surface_set_material(si, mat)
	for child in node.get_children():
		_apply_mat_recursive(child, mat)


## Try to set a property on an instance, only if it exists.
func _try_set(instance: Node3D, prop: String, value: Variant) -> bool:
	if instance.get(prop) != null:
		instance.set(prop, value)
		return true
	return false


## Map the generic param_a / param_b sliders to surface-specific @export vars.
## Each surface has different meaningful parameters.
func _apply_surface_specific_params(instance: Node3D, type_idx: int,
		param_a: float, param_b: float) -> void:
	match type_idx:
		0:  # Breather
			_try_set(instance, "surface_scale", param_a * 0.3)
		1:  # Catenoid
			_try_set(instance, "surface_scale", param_a * 0.3)
		2:  # Dini
			_try_set(instance, "surface_scale", param_a * 0.3)
		3:  # Double Enneper
			_try_set(instance, "surface_scale", param_a * 0.3)
		4:  # Enneper Order 3
			_try_set(instance, "surface_scale", param_a * 0.3)
		5:  # Figure Eight Knot
			_try_set(instance, "surface_scale", param_a * 0.3)
		6:  # Helicoid
			_try_set(instance, "surface_scale", param_a * 0.3)
		7:  # Klein Bottle
			_try_set(instance, "surface_scale", param_a * 0.3)
		8:  # Mobius Strip
			_try_set(instance, "surface_scale", param_a * 0.3)
		9:  # Parametric
			_try_set(instance, "surface_scale", param_a * 0.3)
		10:  # Seashell
			_try_set(instance, "spiral_tightness", param_a * 0.3)
			_try_set(instance, "shell_opening", param_b * 0.2)
		11:  # Torus Knot
			_try_set(instance, "surface_scale", param_a * 0.3)
		12:  # Trefoil Knot
			_try_set(instance, "surface_scale", param_a * 0.3)
		13:  # Wave Torus
			_try_set(instance, "wave_amplitude", param_a * 0.04)
			_try_set(instance, "wave_frequency_u", param_b * 16.0)
