# CSG Intersection Demo — A ∩ B
#
# Two intersecting primitives. Only the overlapping volume survives — what's in both A
# AND B. The result is a lens-shaped solid showing where two shapes agree.
#
# Intersection is the *strictest* of the three CSG operators. The result is always
# smaller than (or equal to) either input. Architecturally useful for "the part of the
# room that both ventilation diagrams agree exists."
#
# @identity
# essence: A ∩ B — the intersection operator. Only the volume present in BOTH primitives survives; the result is a lens where the two shapes agree.
# desire: To show that agreement has a shape, and that it is always smaller than either party brought to it.
# critical_parameter: sphere_offset — controls how much the primitives overlap. Small overlap = a sliver; full overlap = nearly a whole primitive; no overlap = nothing at all.
# triggers: Automatic — builds on _ready() and rotates so the lens of agreement is read from all sides.
# emerges: The feeling that "and" is restrictive. Intersection can only ever take away.
# needs: Procedural CSG [has]. Missing: a readout of the surviving volume as the overlap shrinks toward zero.
# relationships: The strictest of the three operators — opposite of csg_union_demo (most permissive). Sits beside csg_difference_demo at csg_compose_workbench.
# truth: Intersection is the shape of consensus. What both shapes agree on is always less than either alone.
# @qfep_term: F.

extends Node3D
class_name CSGIntersectionDemo

@export_category("Intersection Settings")
@export var body_color: Color = Color(1.0, 0.55, 0.4, 1.0)
@export var box_size: Vector3 = Vector3(0.8, 0.8, 0.8)
@export var sphere_radius: float = 0.55
@export var sphere_offset: Vector3 = Vector3(0.3, 0.2, 0.1)
@export var rotation_speed: float = 0.35

var _root_csg: CSGCombiner3D
var _t: float = 0.0


func _ready() -> void:
	_build_intersection()
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("body_color"):
		body_color = config_data["body_color"]


func _process(delta: float) -> void:
	_t += delta * rotation_speed
	if is_instance_valid(_root_csg):
		_root_csg.rotation.y = _t


func _build_intersection() -> void:
	_root_csg = CSGCombiner3D.new()
	_root_csg.name = "IntersectionRoot"
	_root_csg.position.y = 0.7
	var csg_box := CSGBox3D.new()
	csg_box.size = box_size
	csg_box.operation = CSGShape3D.OPERATION_UNION
	_root_csg.add_child(csg_box)
	var csg_sphere := CSGSphere3D.new()
	csg_sphere.radius = sphere_radius
	csg_sphere.position = sphere_offset
	csg_sphere.operation = CSGShape3D.OPERATION_INTERSECTION
	_root_csg.add_child(csg_sphere)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.metallic = 0.3
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = body_color
	mat.emission_energy_multiplier = 0.4
	_root_csg.material_override = mat
	add_child(_root_csg)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "A ∩ B"
	label.font_size = 48
	label.outline_size = 8
	label.modulate = body_color
	label.position = Vector3(0, 1.7, 0.5)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
