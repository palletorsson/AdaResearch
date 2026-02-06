# PolyhedronNets.gd - 2D net visualizations for polyhedra
extends Node3D

@export var net_type: String = "tetrahedron"
@export var edge_length: float = 0.5
@export var line_thickness: float = 0.01
@export var face_color: Color = Color(1.0, 0.9, 0.7, 0.8)
@export var edge_color: Color = Color(0.2, 0.2, 0.2, 1.0)
@export var fold_progress: float = 0.0:
	set(value):
		field = clamp(value, 0.0, 1.0)
		_apply_fold()
@export var auto_fold: bool = true
@export var fold_delay: float = 0.4
@export var fold_duration: float = 2.0
@export var fold_hold: float = 0.8
@export var loop_fold: bool = false

const PrimitiveMeshBuilder = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")
const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

var _cube_root: Node3D
var _cube_hinges: Dictionary = {}

func _ready():
	match net_type:
		"tetrahedron":
			create_tetrahedron_net()
		"cube":
			create_cube_net()
		"octahedron":
			create_octahedron_net()
	
	if net_type == "cube" and auto_fold:
		_play_fold_animation()

func create_tetrahedron_net():
	# Strip of 4 equilateral triangles
	var h = edge_length * sqrt(3.0) / 2.0  # Triangle height

	# 4 triangles laid flat in a strip
	var vertices_3d: Array[Vector3] = [
		# Triangle 1 (leftmost)
		Vector3(-1.5 * edge_length, 0, 0),
		Vector3(-edge_length, 0, 0),
		Vector3(-1.25 * edge_length, 0, h),
		# Triangle 2
		Vector3(-edge_length, 0, 0),
		Vector3(-0.5 * edge_length, 0, 0),
		Vector3(-0.75 * edge_length, 0, h),
		# Triangle 3 (center)
		Vector3(-0.5 * edge_length, 0, 0),
		Vector3(0, 0, 0),
		Vector3(-0.25 * edge_length, 0, h),
		# Triangle 4 (rightmost)
		Vector3(0, 0, 0),
		Vector3(0.5 * edge_length, 0, 0),
		Vector3(0.25 * edge_length, 0, h)
	]

	var faces = [
		[0, 1, 2],    # Triangle 1
		[3, 4, 5],    # Triangle 2
		[6, 7, 8],    # Triangle 3
		[9, 10, 11]   # Triangle 4
	]

	create_net_mesh(vertices_3d, faces)
	add_fold_line_labels()

func create_cube_net():
	_create_cube_faces()
	add_fold_line_labels()

func create_octahedron_net():
	# Strip of 8 triangles
	var h = edge_length * sqrt(3.0) / 2.0
	var vertices_3d: Array[Vector3] = []
	var faces = []

	# Create strip of 8 triangles alternating up/down
	for i in range(8):
		var x_offset = i * edge_length * 0.5
		var base_idx = vertices_3d.size()

		if i % 2 == 0:  # Point up
			vertices_3d.append(Vector3(x_offset, 0, 0))
			vertices_3d.append(Vector3(x_offset + edge_length * 0.5, 0, 0))
			vertices_3d.append(Vector3(x_offset + edge_length * 0.25, 0, h))
		else:  # Point down
			vertices_3d.append(Vector3(x_offset, 0, 0))
			vertices_3d.append(Vector3(x_offset + edge_length * 0.5, 0, 0))
			vertices_3d.append(Vector3(x_offset + edge_length * 0.25, 0, -h))

		faces.append([base_idx, base_idx + 1, base_idx + 2])

	create_net_mesh(vertices_3d, faces)
	add_fold_line_labels()

func create_net_mesh(vertices: Array[Vector3], faces: Array):
	# Create the flat net with transparency
	var material = GridMaterialFactory.make(face_color, {
		"double_sided": true,
		"edge_color": edge_color
	})

	var mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		vertices,
		faces,
		{
			"name": net_type + "_Net",
			"material": material,
			"double_sided": true
		}
	)

	add_child(mesh_instance)

func _create_cube_faces():
	# Build 6 square faces with hinges so we can fold into a cube.
	var s = edge_length
	_cube_root = Node3D.new()
	_cube_root.name = "CubeNet"
	add_child(_cube_root)

	var material = GridMaterialFactory.make(face_color, {
		"double_sided": true,
		"edge_color": edge_color
	})

	# Center face
	var center_face = _make_face(material)
	_cube_root.add_child(center_face)

	# Top face hinge (positive Z)
	var top_hinge = Node3D.new()
	top_hinge.name = "TopHinge"
	top_hinge.position = Vector3(0, 0, s * 0.5)
	_cube_root.add_child(top_hinge)
	var top_face = _make_face(material)
	top_face.position = Vector3(0, 0, s * 0.5)
	top_hinge.add_child(top_face)
	_cube_hinges["top"] = top_hinge

	# Bottom face hinge (negative Z)
	var bottom_hinge = Node3D.new()
	bottom_hinge.name = "BottomHinge"
	bottom_hinge.position = Vector3(0, 0, -s * 0.5)
	_cube_root.add_child(bottom_hinge)
	var bottom_face = _make_face(material)
	bottom_face.position = Vector3(0, 0, -s * 0.5)
	bottom_hinge.add_child(bottom_face)
	_cube_hinges["bottom"] = bottom_hinge

	# Left face hinge (negative X)
	var left_hinge = Node3D.new()
	left_hinge.name = "LeftHinge"
	left_hinge.position = Vector3(-s * 0.5, 0, 0)
	_cube_root.add_child(left_hinge)
	var left_face = _make_face(material)
	left_face.position = Vector3(-s * 0.5, 0, 0)
	left_hinge.add_child(left_face)
	_cube_hinges["left"] = left_hinge

	# Right face hinge (positive X)
	var right_hinge = Node3D.new()
	right_hinge.name = "RightHinge"
	right_hinge.position = Vector3(s * 0.5, 0, 0)
	_cube_root.add_child(right_hinge)
	var right_root = Node3D.new()
	right_hinge.add_child(right_root)
	var right_face = _make_face(material)
	right_face.position = Vector3(s * 0.5, 0, 0)
	right_root.add_child(right_face)
	_cube_hinges["right"] = right_hinge

	# Back face hinge (attached to right face outer edge)
	var back_hinge = Node3D.new()
	back_hinge.name = "BackHinge"
	back_hinge.position = Vector3(s, 0, 0)
	right_root.add_child(back_hinge)
	var back_face = _make_face(material)
	back_face.position = Vector3(s * 0.5, 0, 0)
	back_hinge.add_child(back_face)
	_cube_hinges["back"] = back_hinge

	_apply_fold()

func _make_face(material: Material) -> MeshInstance3D:
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(edge_length, edge_length)
	var face = MeshInstance3D.new()
	face.mesh = mesh
	face.material_override = material
	return face

func _apply_fold():
	if _cube_hinges.is_empty():
		return
	var angle = deg_to_rad(90.0) * fold_progress
	if _cube_hinges.has("top"):
		_cube_hinges["top"].rotation.x = angle
	if _cube_hinges.has("bottom"):
		_cube_hinges["bottom"].rotation.x = -angle
	if _cube_hinges.has("left"):
		_cube_hinges["left"].rotation.z = angle
	if _cube_hinges.has("right"):
		_cube_hinges["right"].rotation.z = -angle
	if _cube_hinges.has("back"):
		_cube_hinges["back"].rotation.z = angle

func _play_fold_animation():
	fold_progress = 0.0
	var tween = create_tween()
	tween.tween_interval(fold_delay)
	tween.tween_property(self, "fold_progress", 1.0, fold_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if loop_fold:
		tween.tween_interval(fold_hold)
		tween.tween_property(self, "fold_progress", 0.0, fold_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()

func apply_grid_config(config_data: Dictionary) -> void:
	# Allow map strings to control folding behavior (e.g., #fold_duration:6)
	if config_data.has("fold_duration"):
		fold_duration = float(config_data.fold_duration)
	if config_data.has("fold_delay"):
		fold_delay = float(config_data.fold_delay)
	if config_data.has("fold_hold"):
		fold_hold = float(config_data.fold_hold)
	if config_data.has("fold_progress"):
		fold_progress = float(config_data.fold_progress)
	if config_data.has("auto_fold"):
		auto_fold = _parse_bool(config_data.auto_fold)
	if config_data.has("loop_fold"):
		loop_fold = _parse_bool(config_data.loop_fold)

	# Re-run animation when requested
	if net_type == "cube" and auto_fold:
		_play_fold_animation()

func _parse_bool(value) -> bool:
	var text = str(value).to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"

func add_fold_line_labels():
	# Add a label explaining this is a net
	var label = Label3D.new()
	label.text = net_type.capitalize() + " Net (fold along edges)"
	label.font_size = 12
	label.outline_size = 3
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.1, -1.0)
	add_child(label)
