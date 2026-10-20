extends "res://commons/void/cube_walkway.gd"
## Seven translations from the old museum, arranged across the two Void shafts.
const Carrier = preload("res://commons/void/trials/transformation/translation_carrier.gd")
const Pit = preload("res://commons/void/lethal_pit.gd")
const Pickup = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
const Finish = preload("res://commons/void/abstract_finish.gd")

func _ready() -> void:
	super._ready()
	for member in recipe.members: Finish.blocks(get_node(member.id))
	for entry in recipe.rides:
		var ride := Carrier.new()
		ride.name=entry.id
		ride.position=Vector3(entry.start[0],entry.start[1],entry.start[2])
		ride.displacement=Vector3(entry.end[0],entry.end[1],entry.end[2])-ride.position
		ride.caption=entry.caption
		ride.tint=Color(entry.color)
		add_child(ride)
	for entry in recipe.pits:
		var pit := Pit.new()
		pit.name=entry.id
		pit.position=Vector3(entry.position[0],-2.35,entry.position[1])
		pit.width=entry.size[0];pit.depth=entry.size[1]
		pit.abstract_finish=true
		add_child(pit)
	for entry in recipe.pickups:
		var pickup: Node3D=Pickup.instantiate()
		pickup.name=entry.id
		pickup.position=Vector3(entry.position[0],entry.position[1],entry.position[2])
		pickup.set_meta("config_motion","slide")
		pickup.set_meta("config_hold","collect")
		pickup.set_meta("config_bob_height",.12)
		pickup.score_provider=get_tree().get_first_node_in_group("void_trial_score")
		add_child(pickup)
		Finish.blocks(pickup, Color("e5c891"))
	for child in get_children():
		if child is Node3D and not part_defaults.has(str(child.name)):
			var bounds := _mesh_bounds(child,child)
			part_defaults[str(child.name)]={"position":[child.position.x,child.position.y,child.position.z],"rotation":[0,0,0],"bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]}

func apply_grid_config(config: Dictionary) -> void:
	super.apply_grid_config(config)
	for child in get_children():
		if child.has_method("rebase"): child.rebase()

func prepare_editor_preview() -> void:
	for child in get_children():
		if child.has_method("prepare_editor_preview"):child.prepare_editor_preview()
