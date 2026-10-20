extends "res://commons/void/cube_walkway.gd"
## The museum's tc -> sc -> rc, carried by the same unit cubes and wp ramps.
const Ferry = preload("res://commons/void/portal_ferry.tscn")
const Growth = preload("res://commons/void/growing_crossing.gd")
const Turn = preload("res://commons/void/turning_crossing.gd")
const Pit = preload("res://commons/void/lethal_pit.gd")

func _ready() -> void:
	super._ready()
	set_meta("source_maps", ["Primitives_Polythedra", "Point_Animatedcube", "Trans_Introduction"])
	var ferry: Node3D = Ferry.instantiate()
	ferry.name = "MovingPlatform"
	ferry.position = Vector3(11.5,0,0)
	ferry.rotation_degrees.y = 180
	add_child(ferry)
	var growth := Growth.new()
	growth.name = "GrowingCube"
	growth.position.y = -.5
	add_child(growth)
	var turn := Turn.new()
	turn.name = "TurningPlank"
	turn.position = Vector3(-10,.9,0)
	add_child(turn)
	for x in [10.0,0.0,-10.0]:
		var pit := Pit.new()
		pit.name = "TransportPit" if x>0 else ("GrowthPit" if x==0 else "RotationPit")
		pit.position = Vector3(x,-2.35,0)
		pit.width = 3 if x==0 else 5
		add_child(pit)
	# The maximum growth envelope is the editor preview; runtime still begins
	# at 0.5m. All anchors/parts retain stable identifiers and independent poses.
	for child in get_children():
		if child is Node3D and not part_defaults.has(str(child.name)):
			var bounds := _mesh_bounds(child,child)
			if child==growth: bounds=AABB(Vector3(-1.5,-1.5,-1.5),Vector3.ONE*3)
			part_defaults[str(child.name)]={"position":[child.position.x,child.position.y,child.position.z],"rotation":[child.rotation_degrees.x,child.rotation_degrees.y,child.rotation_degrees.z],"bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]}

func apply_grid_config(config: Dictionary) -> void:
	super.apply_grid_config(config)
	if has_node("MovingPlatform"): get_node("MovingPlatform").rebase()

func prepare_editor_preview() -> void:
	if has_node("GrowingCube"):
		var growth: Node3D=get_node("GrowingCube")
		growth.current_scale=growth.max_scale
		growth.apply_scale()
