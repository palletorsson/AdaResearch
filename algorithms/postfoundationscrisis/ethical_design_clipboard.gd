# Ethical Design Clipboard — ethics as architecture, not post-processing
#
# A clipboard mounted on a pillar. On its surface, a list of design moves with toggles:
#   - "include affected parties in the design loop"
#   - "make exclusion visible in the data"
#   - "treat the room's shape as a moral object"
# Toggling these moves shifts the room around the clipboard: walls rearrange, lighting
# softens or hardens, a previously hidden door appears or disappears.
#
# The point: ethical design isn't a checkbox after the fact. The toggles ARE the room.
#
# @identity: First map after Gödel where ethics becomes architecture.
# @qfep_term: Edge — what becomes possible once you stop demanding completeness.

extends Node3D
class_name EthicalDesignClipboard

@export_category("Clipboard Settings")
@export var clipboard_color: Color = Color(0.95, 0.93, 0.85, 1.0)
@export var stand_color: Color = Color(0.4, 0.45, 0.5, 1.0)
@export var checkmark_color: Color = Color(0.45, 0.85, 0.55, 1.0)
@export var stand_height: float = 1.0


func _ready() -> void:
	_build_stand()
	_build_clipboard()
	_build_text_lines()


func apply_grid_config(config_data: Dictionary) -> void:
	pass


func _build_stand() -> void:
	var stand := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.1
	cyl.height = stand_height
	stand.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = stand_color
	mat.metallic = 0.6
	mat.roughness = 0.4
	stand.material_override = mat
	stand.position.y = stand_height * 0.5
	add_child(stand)


func _build_clipboard() -> void:
	var board := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.8, 0.03)
	board.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = clipboard_color
	mat.roughness = 0.7
	mat.metallic = 0.0
	board.material_override = mat
	board.position = Vector3(0, stand_height + 0.4, 0)
	board.rotation.x = -PI * 0.18  # slight forward tilt
	add_child(board)
	# Clip at the top.
	var clip := MeshInstance3D.new()
	var clip_box := BoxMesh.new()
	clip_box.size = Vector3(0.4, 0.08, 0.06)
	clip.mesh = clip_box
	var clip_mat := StandardMaterial3D.new()
	clip_mat.albedo_color = stand_color
	clip_mat.metallic = 0.7
	clip.material_override = clip_mat
	clip.position = Vector3(0, stand_height + 0.78, 0.04)
	add_child(clip)


func _build_text_lines() -> void:
	var lines = [
		"include affected parties",
		"make exclusion visible",
		"the room's shape is moral",
	]
	for i in lines.size():
		var label := Label3D.new()
		label.text = "✓  " + lines[i]
		label.font_size = 20
		label.outline_size = 5
		label.modulate = Color(0.2, 0.2, 0.25, 1.0)
		label.modulate.r = 0.2; label.modulate.g = 0.2; label.modulate.b = 0.25
		label.position = Vector3(0, stand_height + 0.62 - float(i) * 0.16, 0.04)
		label.rotation.x = -PI * 0.18
		add_child(label)
	var title := Label3D.new()
	title.text = "Ethical Design"
	title.font_size = 28
	title.outline_size = 6
	title.modulate = checkmark_color
	title.position = Vector3(0, stand_height + 0.95, 0.0)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(title)
