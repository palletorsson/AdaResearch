# CSG Difference Demo — A − B
#
# A solid box with a sphere subtracted from it. The sphere is invisible; only its
# *negative space* survives in the resulting solid. The box has a bite taken out.
#
# This is the operator that makes architecture: every cavity, every door, every
# window is a Boolean difference of a wall minus an opening.
#
# @identity
# essence: A − B — the difference operator. A solid box minus an invisible sphere; only the sphere's negative space survives, biting a cavity into the box.
# desire: To reveal that absence is constructive. The hole is not missing material — it is the operator's product.
# critical_parameter: sphere_offset — where the bite lands. Center = a clean internal void; edge = an open notch that breaks the silhouette.
# triggers: Automatic — builds on _ready() and rotates so the cavity reads as a deliberate carved form.
# emerges: The architectural intuition that every door, window, and room is a wall minus an opening.
# needs: Procedural CSG [has]. Missing: an order-sensitivity demo (A−B vs B−A) showing difference is non-commutative.
# relationships: The subtractive operator — the only non-commutative one of the three. Foundation for csg_architecture_cavity, which subtracts three openings from a wall. Grouped at csg_compose_workbench.
# truth: To make a room, subtract a void from a solid. Architecture is difference.
# @qfep_term: F.

extends Node3D
class_name CSGDifferenceDemo

@export_category("Difference Settings")
@export var body_color: Color = Color(0.7, 0.6, 0.95, 1.0)
@export var box_size: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var sphere_radius: float = 0.55
@export var sphere_offset: Vector3 = Vector3(0.3, 0.1, 0.3)
@export var rotation_speed: float = 0.35

var _root_csg: CSGCombiner3D
var _t: float = 0.0


func _ready() -> void:
	_build_difference()
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("body_color"):
		body_color = config_data["body_color"]


func _process(delta: float) -> void:
	_t += delta * rotation_speed
	if is_instance_valid(_root_csg):
		_root_csg.rotation.y = _t


func _build_difference() -> void:
	_root_csg = CSGCombiner3D.new()
	_root_csg.name = "DifferenceRoot"
	_root_csg.position.y = 0.7
	var csg_box := CSGBox3D.new()
	csg_box.size = box_size
	csg_box.operation = CSGShape3D.OPERATION_UNION
	_root_csg.add_child(csg_box)
	var csg_sphere := CSGSphere3D.new()
	csg_sphere.radius = sphere_radius
	csg_sphere.position = sphere_offset
	csg_sphere.operation = CSGShape3D.OPERATION_SUBTRACTION
	_root_csg.add_child(csg_sphere)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.metallic = 0.3
	mat.roughness = 0.5
	mat.emission_enabled = true
	mat.emission = body_color
	mat.emission_energy_multiplier = 0.3
	_root_csg.material_override = mat
	add_child(_root_csg)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "A − B"
	label.font_size = 48
	label.outline_size = 8
	label.modulate = body_color
	label.position = Vector3(0, 1.7, 0.5)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
