extends "res://commons/artifacts/force_capability_lab/force_point.gd"
## The learned PointBody becomes a handhold on a path, rather than a loose prop.

func _ready() -> void:
	super()
	remove_from_group("ada_thrust_points")
	set_meta("hold_preserves_world_transform", true)
	release_mode = ReleaseMode.FROZEN
	freeze = true
	gravity_scale = 0
	collision_mask = 0
	sphere.radius = 0.19
	sphere.height = 0.38
	get_child(1).shape.radius = 0.19
	jet.visible = false
	var finish: StandardMaterial3D = get_child(0).material_override
	finish.albedo_color = Color("222a36")
	finish.metallic = 0.65
	finish.roughness = 0.13

func pick_up(by: Node3D) -> void:
	var home := global_transform
	super(by)
	if is_instance_valid(_grab_driver):
		# Retain XR Tools ownership/signals/release, but not its hand-follow motion.
		_grab_driver.update_position = false
		_grab_driver.update_rotation = false
		_grab_driver.update_scale = false
	global_transform = home

func on_desktop_drop(_pointer: Node3D = null) -> void:
	super(_pointer)
	freeze = true

func _process(_dt: float) -> void:
	jet.visible = false

func release_rider() -> void:
	if is_instance_valid(desktop_pointer):
		if desktop_pointer.has_method("_drop_held"):
			desktop_pointer.call("_drop_held")
		else:
			on_desktop_drop()
	if is_picked_up(): drop()
