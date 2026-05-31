# CSG Union Demo — A ∪ B
#
# Two intersecting Godot CSG primitives (a box and a sphere) rendered with the union
# operation. Where they overlap, no seam — the union creates a single composite solid.
# A slow rotation orbits the camera so the player sees how the union flows around both.
#
# @identity
# essence: A ∪ B — the union operator. Two CSG primitives (box + sphere) fused into one seamless solid; where they overlap, no seam survives.
# desire: To show that joining is not stacking. The union is a single skin around two volumes, not two objects merely touching.
# critical_parameter: sphere_offset — how far the sphere sits from the box. Far apart = barely fused; overlapping = one blob. The overlap is where union does its work.
# triggers: Automatic — builds on _ready(), then slowly rotates so the player reads the fused surface from every angle.
# emerges: The intuition that "or" has a shape. Anything in A OR B belongs to the result.
# needs: Procedural CSG [has]. Missing: a before/after toggle that separates the two inputs back out.
# relationships: The most permissive of the three operators. Contrasts with csg_intersection_demo (strictest) and csg_difference_demo (subtractive). Introduced together at csg_compose_workbench.
# truth: Union is the generous operator. It keeps everything either shape claims.
# @qfep_term: F (pure composition, no entropy).

extends Node3D
class_name CSGUnionDemo

@export_category("Union Settings")
@export var body_color: Color = Color(0.55, 0.85, 1.0, 1.0)
@export var box_size: Vector3 = Vector3(0.7, 0.7, 0.7)
@export var sphere_radius: float = 0.5
@export var sphere_offset: Vector3 = Vector3(0.4, 0.25, 0.0)
@export var rotation_speed: float = 0.35

var _root_csg: CSGCombiner3D
var _t: float = 0.0


func _ready() -> void:
	_build_union()
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("body_color"):
		body_color = config_data["body_color"]
	if config_data.has("box_size"):
		box_size = config_data["box_size"]
	if config_data.has("sphere_radius"):
		sphere_radius = float(config_data["sphere_radius"])


func _process(delta: float) -> void:
	_t += delta * rotation_speed
	if is_instance_valid(_root_csg):
		_root_csg.rotation.y = _t


func _build_union() -> void:
	_root_csg = CSGCombiner3D.new()
	_root_csg.name = "UnionRoot"
	_root_csg.position.y = 0.7
	# The box.
	var csg_box := CSGBox3D.new()
	csg_box.size = box_size
	csg_box.operation = CSGShape3D.OPERATION_UNION
	_root_csg.add_child(csg_box)
	# The sphere — also union, additive.
	var csg_sphere := CSGSphere3D.new()
	csg_sphere.radius = sphere_radius
	csg_sphere.position = sphere_offset
	csg_sphere.operation = CSGShape3D.OPERATION_UNION
	_root_csg.add_child(csg_sphere)
	# Material on the root.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.metallic = 0.3
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = body_color
	mat.emission_energy_multiplier = 0.3
	_root_csg.material_override = mat
	add_child(_root_csg)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "A ∪ B"
	label.font_size = 48
	label.outline_size = 8
	label.modulate = body_color
	label.position = Vector3(0, 1.7, 0.5)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
