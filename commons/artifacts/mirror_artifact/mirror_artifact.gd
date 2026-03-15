extends Node3D
class_name MirrorArtifact

## Reflective mirror panel showing the player what their hands look like.
## A large vertical mirror surface with a decorative frame and label.

func _ready() -> void:
	_build_mirror()

func _build_mirror() -> void:
	# Mirror surface — large vertical plane
	var mirror_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.5, 2.0)
	mirror_mesh.mesh = plane
	# Rotate plane to be vertical (facing +Z)
	mirror_mesh.rotation_degrees.x = 90.0
	mirror_mesh.position.y = 1.0

	var mirror_mat := StandardMaterial3D.new()
	mirror_mat.metallic = 1.0
	mirror_mat.roughness = 0.0
	mirror_mat.albedo_color = Color(0.9, 0.9, 1.0)
	mirror_mesh.material_override = mirror_mat
	add_child(mirror_mesh)

	# Decorative frame — 4 thin box edges around the mirror
	var frame_color := Color(0.35, 0.25, 0.15)  # dark wood tone
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = frame_color

	var frame_thickness := 0.04
	var frame_depth := 0.03

	# Top edge
	_add_frame_edge(Vector3(0, 2.0, 0), Vector3(1.5 + frame_thickness * 2, frame_thickness, frame_depth), frame_mat)
	# Bottom edge
	_add_frame_edge(Vector3(0, 0.0, 0), Vector3(1.5 + frame_thickness * 2, frame_thickness, frame_depth), frame_mat)
	# Left edge
	_add_frame_edge(Vector3(-0.75 - frame_thickness * 0.5, 1.0, 0), Vector3(frame_thickness, 2.0, frame_depth), frame_mat)
	# Right edge
	_add_frame_edge(Vector3(0.75 + frame_thickness * 0.5, 1.0, 0), Vector3(frame_thickness, 2.0, frame_depth), frame_mat)

	# Label above the mirror
	var label := Label3D.new()
	label.text = "Mirror"
	label.font_size = 64
	label.position = Vector3(0, 2.15, 0)
	label.modulate = Color.WHITE
	add_child(label)

func _add_frame_edge(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var edge := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	edge.mesh = box
	edge.position = pos
	edge.material_override = mat
	add_child(edge)

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("scale"):
		scale = Vector3.ONE * float(config_data["scale"])
