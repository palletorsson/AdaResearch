extends "res://commons/void/lines_area.gd"
## The three original transformation laws. Architecture lives in editable cells.
const Growth = preload("res://commons/void/growing_crossing.gd")
const Turn = preload("res://commons/void/turning_crossing.gd")
const Finish = preload("res://commons/void/trials/transformation/structural_finish.gd")

func _ready() -> void:
	set_meta("source_maps", ["Point_Animatedcube", "Trans_Introduction"])
	var growth := Growth.new()
	growth.name = "GrowingCube"
	# Five-metre gap, with the full cube's top flush with the 3 m decks.
	growth.crossing_size = 5.0
	growth.position = Vector3(-10,.5,0)
	add_child(growth)
	Finish.apply_growth(growth)
	var turn := Turn.new()
	turn.name = "TurningPlank"
	# Banks now finish at -3.5 and 2.5: keep the pivot halfway between them.
	turn.bridge_length = 6.0
	turn.position = Vector3(-.5,2.9,0)
	add_child(turn)
	Finish.apply_rotation(turn, 2.9)
	# The tower's two existing shafts supply the danger. No extra excavation
	# or kill volume: the centre and side aisles retain the normal floor.
	for entry in [
		["MoveCaption","01 / POSITION CHANGES\nWAIT · BOARD · RIDE",Vector3(15.4,3.02,0)],
		["TurnCaption","02 / DIRECTION CHANGES\nCROSS WHEN THE PLANK ALIGNS",Vector3(4.5,3.02,0)],
		["GrowCaption","03 / SIZE CHANGES\nWAIT FOR THE TOP TO MEET THE BANKS",Vector3(-5,3.02,0)],
		["ExitCaption","SAME BODY / THREE TRANSFORMATIONS\nDOWN THE RAMP · A SOUTH-WEST CORNER",Vector3(-16.5,3.02,0)]]:
		var label := words(entry[1],entry[2],true,.0015)
		label.name = entry[0]
	for child in get_children():
		if child is Node3D:
			var bounds := _mesh_bounds(child,child)
			if child == growth:
				bounds = AABB(Vector3.ONE*-growth.max_scale*.5,Vector3.ONE*growth.max_scale)
			part_defaults[str(child.name)] = {
				"position":[child.position.x,child.position.y,child.position.z],
				"rotation":[child.rotation_degrees.x,child.rotation_degrees.y,child.rotation_degrees.z],
				"bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]}

func prepare_editor_preview() -> void:
	var growth := get_node_or_null("GrowingCube")
	if growth != null:
		growth.current_scale = growth.max_scale
		growth.apply_scale()
	var turn := get_node_or_null("TurningPlank")
	if turn != null:
		turn.current_angle = 0
		turn.mesh_instance.rotation_degrees.y = 0
		turn.static_body.transform = turn.mesh_instance.transform
