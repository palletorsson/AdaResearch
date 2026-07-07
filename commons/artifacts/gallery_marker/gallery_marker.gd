# Gallery Marker — a "you-are-here" sub-gallery anchor placed inside larger sequence maps.
#
# Single cell, procedural. A small bronze pedestal with a vertical glowing stake and a
# Label3D floating above. The label is set via `apply_grid_config({"label": "..."})` so
# the same scene serves every `gallery_marker_<sequence>` alias.

extends Node3D
class_name GalleryMarker

@export var label_text: String = "GALLERY"
@export var marker_color: Color = Color(0.78, 0.58, 0.22, 1.0)
@export var stake_height: float = 0.9
@export var pedestal_radius: float = 0.18


func _ready() -> void:
	_build_pedestal()
	_build_stake()
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("label"):
		label_text = String(config_data["label"])
		var lbl: Label3D = get_node_or_null("Label3D") as Label3D
		if lbl:
			lbl.text = label_text
	if config_data.has("marker_color"):
		marker_color = config_data["marker_color"]


func _build_pedestal() -> void:
	var ped: MeshInstance3D = MeshInstance3D.new()
	ped.name = "Pedestal"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = pedestal_radius
	cyl.bottom_radius = pedestal_radius + 0.02
	cyl.height = 0.08
	ped.mesh = cyl
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = marker_color.darkened(0.4)
	mat.roughness = 0.65
	mat.metallic = 0.4
	ped.material_override = mat
	ped.position.y = 0.04
	add_child(ped)


func _build_stake() -> void:
	var stake: MeshInstance3D = MeshInstance3D.new()
	stake.name = "Stake"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.015
	cyl.bottom_radius = 0.02
	cyl.height = stake_height
	stake.mesh = cyl
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = marker_color
	mat.emission_enabled = true
	mat.emission = marker_color
	mat.emission_energy_multiplier = 0.9
	stake.material_override = mat
	stake.position.y = 0.08 + stake_height * 0.5
	add_child(stake)


func _build_label() -> void:
	var lbl: Label3D = Label3D.new()
	lbl.name = "Label3D"
	lbl.text = label_text
	lbl.font_size = 32
	lbl.outline_size = 6
	lbl.modulate = Color(1.0, 0.95, 0.85)
	lbl.outline_modulate = Color(0.05, 0.05, 0.05)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position.y = 0.08 + stake_height + 0.18
	lbl.pixel_size = 0.004
	add_child(lbl)
