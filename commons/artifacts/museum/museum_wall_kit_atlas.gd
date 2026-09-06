extends Node3D
class_name MuseumWallKitAtlas

## A physical kit sheet: width proofs grouped by semantic family, followed by a
## complete sixteen-metre wall assembled from those same certified pieces.

const PIECE_SCENE := preload("res://commons/artifacts/museum/museum_wall_piece.tscn")
const RUN_SCENE := preload("res://commons/artifacts/museum/museum_wall_run.tscn")

@export var height: float = 4.0


func _ready() -> void:
	var atlas := Node3D.new()
	atlas.name = "MuseumWallAtlasContract"
	atlas.set_meta("grid_m", 1.0)
	atlas.set_meta("piece_families", 7)
	atlas.set_meta("width_range_cells", Vector2i(1, 4))
	atlas.set_meta("quality_tier", "aaa")
	atlas.set_meta("full_build_spec", "endcap:1|service:2|feature:4|window:3|vitrine:3|solid:2|endcap:1")
	add_child(atlas)

	_add_piece_row(atlas, "SolidWidths", "solid", [1, 2, 3, 4], 6.0, -6.5)
	_add_piece_row(atlas, "FeatureWidths", "feature", [1, 2, 3, 4], 6.0, 7.0)
	_add_piece_row(atlas, "WindowWidths", "window", [2, 3, 4], 1.0, -6.5)
	_add_piece_row(atlas, "VitrineWidths", "vitrine", [2, 3, 4], 1.0, 7.0)
	_add_piece_row(atlas, "ServiceWidths", "service", [1, 2, 3, 4], -4.0, -6.5)
	_add_piece_row(atlas, "PortalWidths", "portal", [2, 3, 4], -4.0, 7.0)
	_add_piece_row(atlas, "Endcaps", "endcap", [1, 2], -9.0, -6.5)

	var full_build: Node3D = RUN_SCENE.instantiate()
	full_build.name = "FullBuild_16m"
	full_build.set("run_spec", "endcap:1|service:2|feature:4|window:3|vitrine:3|solid:2|endcap:1")
	full_build.set("height", height)
	full_build.set("enable_collision", false)
	full_build.set("detail_seed", 4067)
	full_build.position = Vector3(4.0, 0, -10.0)
	atlas.add_child(full_build)

	_build_floor(atlas)
	_build_scale_reference(atlas)


func _add_piece_row(parent: Node3D, row_name: String, piece_kind: String, widths: Array, z: float, x_offset: float) -> void:
	var row := Node3D.new()
	row.name = row_name
	row.set_meta("kind", piece_kind)
	row.set_meta("widths_cells", widths)
	row.position = Vector3(x_offset, 0, z)
	parent.add_child(row)
	_add_row_label(row, piece_kind.capitalize(), Vector3(0.0, height + 0.48, 0.0))
	var total := 0.0
	for cells in widths:
		total += float(cells) + 0.8
	var cursor := -total * 0.5
	for cells_value in widths:
		var cells := int(cells_value)
		var piece: Node3D = PIECE_SCENE.instantiate()
		piece.name = "%s_%dm" % [piece_kind.capitalize(), cells]
		piece.set("kind", piece_kind)
		piece.set("width_cells", cells)
		piece.set("height", height)
		piece.set("enable_collision", false)
		piece.set("detail_seed", 4067 + cells * 101 + piece_kind.hash())
		piece.position.x = cursor + float(cells) * 0.5
		row.add_child(piece)
		cursor += float(cells) + 0.8


func _build_floor(parent: Node3D) -> void:
	var floor := Node3D.new()
	floor.name = "AtlasFloor_1m"
	parent.add_child(floor)
	var base_mat := _mat(Color(0.14, 0.15, 0.16), 0.86)
	var grid_mat := _mat(Color(0.24, 0.25, 0.26), 0.78)
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(28.0, 0.05, 24.0)
	var base := MeshInstance3D.new()
	base.name = "FloorQuad"
	base.position = Vector3(0, -0.035, -2.0)
	base.mesh = base_mesh
	base.material_override = base_mat
	floor.add_child(base)
	# Sixty-five slim strips show the one-metre contract without spending almost
	# nine hundred mesh instances on a certification floor.
	for x in range(-14, 15):
		floor.add_child(_grid_strip("GridX_%d" % x, Vector3(float(x) - 0.5, -0.006, -2.0), Vector3(0.012, 0.008, 24.0), grid_mat))
	for z in range(-14, 11):
		floor.add_child(_grid_strip("GridZ_%d" % z, Vector3(0, -0.005, float(z) - 0.5), Vector3(28.0, 0.008, 0.012), grid_mat))


func _build_scale_reference(parent: Node3D) -> void:
	var scale := Node3D.new()
	scale.name = "HumanScale_1_8m"
	scale.position = Vector3(-12.8, 0.0, -10.0)
	parent.add_child(scale)
	var material := _mat(Color(0.055, 0.06, 0.07), 0.5)
	scale.add_child(_grid_strip("Body", Vector3(0, 0.88, 0), Vector3(0.42, 1.35, 0.22), material))
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.16
	head_mesh.height = 0.32
	head_mesh.radial_segments = 16
	head_mesh.rings = 8
	var head := MeshInstance3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.68, 0)
	head.mesh = head_mesh
	head.material_override = material
	scale.add_child(head)
	_add_row_label(scale, "1.8 m", Vector3(0, 2.05, 0))


func _add_row_label(parent: Node3D, text_value: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.name = "Label_%s" % text_value.replace(" ", "_")
	label.text = text_value
	label.position = at
	label.font_size = 64
	label.pixel_size = 0.006
	label.outline_size = 8
	label.modulate = Color(0.94, 0.89, 0.78)
	label.outline_modulate = Color(0.025, 0.03, 0.04)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)


func _grid_strip(node_name: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.mesh = mesh
	instance.material_override = material
	return instance


func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
