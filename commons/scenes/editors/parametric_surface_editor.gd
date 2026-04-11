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
]
const SURFACE_NAMES: Array[String] = [
	"Breather", "Catenoid", "Dini", "Double Enneper", "Enneper Order 3",
	"Figure Eight Knot", "Helicoid", "Klein Bottle", "Mobius Strip",
	"Parametric", "Seashell", "Torus Knot", "Trefoil Knot", "Wave Torus",
]

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
			{"id": "surface_type", "label": "Type (0-13)", "min": 0.0, "max": 13.0, "step": 1.0, "default": 13.0},
			{"id": "scale", "label": "Scale", "min": 0.05, "max": 1.0, "step": 0.01, "default": 0.18},
		]},
		{"name": "Resolution", "params": [
			{"id": "res_u", "label": "U Steps", "min": 10.0, "max": 100.0, "step": 2.0, "default": 40.0},
			{"id": "res_v", "label": "V Steps", "min": 10.0, "max": 100.0, "step": 2.0, "default": 24.0},
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

	# Apply generic params — map param_a/param_b to surface-specific exports
	var param_a: float = p("param_a", 0.5)
	var param_b: float = p("param_b", 0.5)
	_apply_surface_specific_params(instance, type_idx, param_a, param_b)

	content_root.add_child(instance)

	# Update info label
	var surface_name: String = SURFACE_NAMES[type_idx]
	info_label.text = "%s | %dv %df" % [surface_name, u_res * v_res, u_res * v_res * 2]


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
