# Merge Conflict Visualizer — paraconsistent engineering as visible architecture
#
# Two intersecting pillars come together at a glowing junction. One pillar is labeled
# "branch A" with a blue tint; the other "branch B" with orange. At their meeting, two
# overlapping geometries occupy the same volume — the artifact does NOT pick one. The
# conflict is held, not resolved.
#
# This is paraconsistent logic in three dimensions: hold contradiction without collapse.
# The system continues to function while the two truths coexist.
#
# @identity: First map where the player sees contradiction as material.
# @qfep_term: Edge — both/and, not either/or.

extends Node3D
class_name MergeConflictVisualizer

@export var branch_a_color: Color = Color(0.45, 0.75, 1.0, 1.0)
@export var branch_b_color: Color = Color(1.0, 0.55, 0.3, 1.0)
@export var conflict_color: Color = Color(1.0, 0.85, 0.3, 1.0)
@export var pillar_height: float = 1.8

var _t: float = 0.0
var _conflict_glow: MeshInstance3D


func _ready() -> void:
	_build_pillar(branch_a_color, Vector3(-0.4, 0, 0), Vector3(0.2, pillar_height, 0.2), "branch A")
	_build_pillar(branch_b_color, Vector3(0.4, 0, 0), Vector3(0.2, pillar_height, 0.2), "branch B")
	_build_conflict_junction()
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	pass


func _process(delta: float) -> void:
	_t += delta * 1.6
	if is_instance_valid(_conflict_glow):
		var mat := _conflict_glow.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 2.5 + 1.0 * sin(_t)


func _build_pillar(color: Color, pos: Vector3, size: Vector3, label_text: String) -> void:
	var pillar := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	pillar.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	pillar.material_override = mat
	pillar.position = pos + Vector3(0, pillar_height * 0.5, 0)
	add_child(pillar)
	var label := Label3D.new()
	label.text = label_text
	label.font_size = 22
	label.outline_size = 5
	label.modulate = color
	label.position = pos + Vector3(0, pillar_height + 0.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)


func _build_conflict_junction() -> void:
	_conflict_glow = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	_conflict_glow.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = conflict_color
	mat.emission_enabled = true
	mat.emission = conflict_color
	mat.emission_energy_multiplier = 2.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.7
	_conflict_glow.material_override = mat
	_conflict_glow.position = Vector3(0, pillar_height * 0.6, 0)
	add_child(_conflict_glow)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "hold contradiction, keep running"
	label.font_size = 26
	label.outline_size = 6
	label.modulate = conflict_color
	label.position = Vector3(0, pillar_height + 0.55, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
