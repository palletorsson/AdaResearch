extends "res://commons/void/cube_walkway.gd"
## The Animated Cube kit, used for one shaft crossing. No surrounding course.
const Carrier = preload("res://commons/void/trials/transformation/suspended_carrier.gd")

func _ready() -> void:
	super._ready()
	var ride := Carrier.new()
	ride.name = "SuspendedPlatform"
	ride.position = Vector3(-10,1,4)
	add_child(ride)
	var bounds := _mesh_bounds(ride,ride)
	part_defaults[str(ride.name)] = {"position":[-10,1,4],"rotation":[0,0,0],"bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]}

func apply_grid_config(config: Dictionary) -> void:
	super.apply_grid_config(config)
	for child in get_children():
		if child.has_method("rebase"): child.rebase()

func prepare_editor_preview() -> void:
	for child in get_children():
		if child.has_method("prepare_editor_preview"): child.prepare_editor_preview()
