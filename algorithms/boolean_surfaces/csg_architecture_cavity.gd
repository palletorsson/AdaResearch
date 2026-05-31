# CSG Architecture Cavity — real-world example: a room is a wall minus a void
#
# A thick wall block with three openings cut through it: a rectangular doorway, a circular
# porthole, and a tall arched window. All three are CSG subtractions from the same wall.
# The player walks around or through the doorway, experiencing architecture as Boolean
# composition.
#
# Sets up an architectural intuition for everything that follows: cavities in solids,
# rooms in buildings, mortise-and-tenon joints, even the way the chamber's ring of
# stations in the postfoundation capstone will be a wall with seven cavities.
#
# @identity
# essence: A thick wall with three openings — doorway, circular porthole, arched window — each a CSG subtraction from the same solid. Architecture as Boolean difference.
# desire: To turn the difference operator into a habitable space the player can walk through, not merely observe.
# critical_parameter: wall_size against the opening sizes — the ratio of solid to void. Too little solid and the wall stops reading as a wall; too little void and it stops being architecture.
# triggers: Automatic — builds the wall, openings, and ground on _ready(). The player walks up to or through the doorway.
# emerges: The bodily understanding that rooms, doors, and windows are all the same operation: solid minus opening.
# needs: Procedural CSG [has], walkable ground [has]. Missing: a second wall to make an enclosed room the player can stand inside.
# relationships: The applied payoff of csg_difference_demo. Prefigures the postfoundation capstone's ring of seven cavities. The most embodied artifact in the sequence.
# truth: Every architectural cavity is a difference. A room is a wall that has been subtracted from.
# @qfep_term: F — composition algebra applied to architecture.

extends Node3D
class_name CSGArchitectureCavity

@export_category("Wall Settings")
@export var wall_color: Color = Color(0.8, 0.76, 0.7, 1.0)
@export var wall_size: Vector3 = Vector3(3.4, 2.6, 0.4)
@export var door_size: Vector3 = Vector3(0.8, 1.8, 0.6)
@export var door_offset_x: float = -0.9
@export var porthole_radius: float = 0.32
@export var porthole_offset: Vector3 = Vector3(0.0, 1.4, 0.0)
@export var arch_size: Vector3 = Vector3(0.55, 1.0, 0.6)
@export var arch_top_radius: float = 0.28
@export var arch_offset_x: float = 1.1

var _root_csg: CSGCombiner3D


func _ready() -> void:
	_build_wall_with_openings()
	_build_label()
	_build_ground()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("wall_color"):
		wall_color = config_data["wall_color"]


func _build_wall_with_openings() -> void:
	_root_csg = CSGCombiner3D.new()
	_root_csg.name = "WallRoot"
	_root_csg.position.y = wall_size.y * 0.5
	# Solid wall.
	var wall := CSGBox3D.new()
	wall.size = wall_size
	wall.operation = CSGShape3D.OPERATION_UNION
	_root_csg.add_child(wall)
	# Doorway (rectangular subtraction).
	var door := CSGBox3D.new()
	door.size = door_size
	door.position = Vector3(door_offset_x, -wall_size.y * 0.5 + door_size.y * 0.5, 0.0)
	door.operation = CSGShape3D.OPERATION_SUBTRACTION
	_root_csg.add_child(door)
	# Porthole (sphere subtraction).
	var porthole := CSGSphere3D.new()
	porthole.radius = porthole_radius
	porthole.position = porthole_offset
	porthole.operation = CSGShape3D.OPERATION_SUBTRACTION
	_root_csg.add_child(porthole)
	# Arched window: a box union a cylinder, then subtracted as one.
	var arch_combiner := CSGCombiner3D.new()
	arch_combiner.position = Vector3(arch_offset_x, -wall_size.y * 0.5 + arch_size.y * 0.5 + 0.4, 0.0)
	arch_combiner.operation = CSGShape3D.OPERATION_SUBTRACTION
	var arch_box := CSGBox3D.new()
	arch_box.size = arch_size
	arch_box.operation = CSGShape3D.OPERATION_UNION
	arch_combiner.add_child(arch_box)
	var arch_top := CSGCylinder3D.new()
	if arch_top.has_method("set_radius"):
		arch_top.radius = arch_top_radius
	arch_top.height = arch_size.z
	# Cylinder's default axis is Y, rotate around X to lay it sideways.
	arch_top.rotation.x = PI * 0.5
	arch_top.position.y = arch_size.y * 0.5
	arch_top.operation = CSGShape3D.OPERATION_UNION
	arch_combiner.add_child(arch_top)
	_root_csg.add_child(arch_combiner)
	# Material on the wall root.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = wall_color
	mat.roughness = 0.85
	mat.metallic = 0.05
	_root_csg.material_override = mat
	add_child(_root_csg)


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(wall_size.x + 2.0, 0.04, wall_size.z + 4.0)
	ground.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.4, 0.36, 1.0)
	mat.roughness = 0.9
	ground.material_override = mat
	ground.position.y = -0.02
	add_child(ground)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "wall − (door + porthole + window) = room"
	label.font_size = 32
	label.outline_size = 8
	label.modulate = Color(0.95, 0.85, 0.55, 1.0)
	label.position = Vector3(0, wall_size.y + 0.35, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
