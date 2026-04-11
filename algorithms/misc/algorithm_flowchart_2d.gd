extends Node3D
class_name AlgorithmFlowChart3D

# Visual settings — VR scale (meters)
const BOX_SIZE := Vector3(0.12, 0.05, 0.005)
const GRID_SPACING := Vector3(0.15, 0.08, 0.0)
const CONNECTION_COLOR := Color(0.7, 0.7, 0.7, 0.8)

# Category colors
const CATEGORY_COLORS = {
	"entry": Color(0.9, 0.9, 0.9),
	"foundation": Color(0.8, 0.9, 1.0),
	"audio": Color(1.0, 0.9, 0.8),
	"random": Color(0.9, 1.0, 0.8),
	"visual": Color(1.0, 0.8, 0.9),
	"physics": Color(0.8, 1.0, 1.0),
	"advanced": Color(1.0, 0.8, 1.0)
}

# Data structure for flowchart — positions as grid coords (converted to 3D in _build)
var flowchart_data = {
	"max_x_outline_bott_plug": {"pos": Vector2(0, 0), "text": "Max_X\nOutline bott plug", "type": "entry", "connections": []},
	"pattern_generation": {"pos": Vector2(2, 0), "text": "Pattern Generation", "type": "foundation", "connections": []},
	"procedural_generation": {"pos": Vector2(6, 0), "text": "Procedural\nGeneration", "type": "advanced", "connections": []},
	# Row 1
	"arrays": {"pos": Vector2(0, 1), "text": "Arrays", "type": "foundation", "connections": ["tutorial_single"]},
	"meshes": {"pos": Vector2(1, 1), "text": "Meshes", "type": "visual", "connections": ["meshes_one"]},
	"wave_audio": {"pos": Vector2(2, 1), "text": "Wave Audio", "type": "audio", "connections": ["wave_one"]},
	"randomness": {"pos": Vector2(3, 1), "text": "Randomness", "type": "random", "connections": ["random_one"]},
	"noise": {"pos": Vector2(4, 1), "text": "Noise", "type": "random", "connections": ["noise_one"]},
	"physics_sim": {"pos": Vector2(5, 1), "text": "Physics Sim", "type": "physics", "connections": []},
	"soft_bodies": {"pos": Vector2(6, 1), "text": "Soft Bodies", "type": "physics", "connections": []},
	"recursive_emergence": {"pos": Vector2(7, 1), "text": "Recursive\nEmergence", "type": "advanced", "connections": []},
	"swarm_intelligence": {"pos": Vector2(8, 1), "text": "Swarm Intelligence", "type": "advanced", "connections": []},
	"machine_learning": {"pos": Vector2(9, 1), "text": "Machine Learning", "type": "advanced", "connections": []},
	# Arrays track
	"tutorial_single": {"pos": Vector2(0, 2), "text": "Tutorial_Single", "type": "foundation", "connections": ["tutorial_col"]},
	"tutorial_col": {"pos": Vector2(0, 3), "text": "Tutorial_Col", "type": "foundation", "connections": ["tutorial_row"]},
	"tutorial_row": {"pos": Vector2(0, 4), "text": "Tutorial_Row", "type": "foundation", "connections": ["tutorial_2d"]},
	"tutorial_2d": {"pos": Vector2(0, 5), "text": "Tutorial_2D", "type": "foundation", "connections": ["tutorial_3d", "tutorial_color"]},
	"tutorial_3d": {"pos": Vector2(-1, 6), "text": "Tutorial_3d7", "type": "foundation", "connections": []},
	"tutorial_color": {"pos": Vector2(0, 6), "text": "Tutorial_Color", "type": "foundation", "connections": ["more_datastructs", "tutorial_disco"]},
	"more_datastructs": {"pos": Vector2(-1, 7), "text": "More datastructs", "type": "foundation", "connections": []},
	"tutorial_disco": {"pos": Vector2(0, 7), "text": "Tutorial_Disco", "type": "foundation", "connections": []},
	# Meshes track
	"meshes_one": {"pos": Vector2(1, 2), "text": "Meshes_One\nFusion primitives", "type": "visual", "connections": ["meshes_two"]},
	"meshes_two": {"pos": Vector2(1, 3), "text": "Meshes_Two", "type": "visual", "connections": []},
	# Wave Audio track
	"wave_one": {"pos": Vector2(2, 2), "text": "Wave_One", "type": "audio", "connections": ["wave_two"]},
	"wave_two": {"pos": Vector2(2, 3), "text": "Wave_Two", "type": "audio", "connections": ["wave_three"]},
	"wave_three": {"pos": Vector2(2, 4), "text": "Wave_Three", "type": "audio", "connections": ["wave_four"]},
	"wave_four": {"pos": Vector2(2, 5), "text": "Wave_Four", "type": "audio", "connections": ["wave_walk"]},
	"wave_walk": {"pos": Vector2(2, 6), "text": "Wave_Walk", "type": "audio", "connections": ["wave_five"]},
	"wave_five": {"pos": Vector2(2, 7), "text": "Wave_Five", "type": "audio", "connections": ["wave_six"]},
	"wave_six": {"pos": Vector2(2, 8), "text": "Wave_Six", "type": "audio", "connections": []},
	# Randomness track
	"random_one": {"pos": Vector2(3, 2), "text": "Random_One\nrandom_rimose\nrandom_loses", "type": "random", "connections": ["random_two"]},
	"random_two": {"pos": Vector2(3, 3), "text": "Random_Two\nrandom_rimose\nrandom_loses", "type": "random", "connections": ["random_three"]},
	"random_three": {"pos": Vector2(3, 4), "text": "Random_Three\nrandom_rimose\nrandom_loses", "type": "random", "connections": ["random_four"]},
	"random_four": {"pos": Vector2(3, 5), "text": "Random_Four\nrandom_rimose\nrandom_loses", "type": "random", "connections": ["random_walk"]},
	"random_walk": {"pos": Vector2(3, 6), "text": "Random_Walk\nrandom_rimose\nrandom_loses", "type": "random", "connections": ["random_five"]},
	"random_five": {"pos": Vector2(3, 7), "text": "Random_Five\nrandom_rimose\nrandom_loses", "type": "random", "connections": ["random_six"]},
	"random_six": {"pos": Vector2(3, 8), "text": "Random_Six\nrandom_rimose\nrandom_loses", "type": "random", "connections": []},
	# Noise track
	"noise_one": {"pos": Vector2(4, 2), "text": "Noise_One\nwarking_cloud", "type": "random", "connections": ["noise_two"]},
	"noise_two": {"pos": Vector2(4, 3), "text": "Noise_Two\nbig_noise_torus", "type": "random", "connections": ["noise_four"]},
	"noise_four": {"pos": Vector2(4, 4), "text": "Noise_Four\ncolor_noise_tv", "type": "random", "connections": ["noise_five"]},
	"noise_five": {"pos": Vector2(4, 5), "text": "Noise_Five\ncolor_noise_tv", "type": "random", "connections": ["noise_six"]},
	"noise_six": {"pos": Vector2(4, 6), "text": "Noise_Six\ncolor_noise_tv", "type": "random", "connections": []}
}

var _node_positions: Dictionary = {}  # node_id -> Vector3
var _connections_mesh: MeshInstance3D = null

func _ready() -> void:
	_build_flowchart()

func _grid_to_world(grid_pos: Vector2) -> Vector3:
	# X goes right, Y goes down (negative in 3D Y)
	return Vector3(
		grid_pos.x * GRID_SPACING.x,
		-grid_pos.y * GRID_SPACING.y,
		0.0
	)

func _build_flowchart() -> void:
	# Background panel
	var bg_mesh := MeshInstance3D.new()
	var bg_quad := QuadMesh.new()
	bg_quad.size = Vector2(1.8, 0.9)
	bg_mesh.mesh = bg_quad
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.1, 0.1, 0.12)
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mesh.material_override = bg_mat
	bg_mesh.position = Vector3(0.6, -0.3, -0.005)
	add_child(bg_mesh)

	# Create node boxes
	for node_id in flowchart_data.keys():
		var node_data: Dictionary = flowchart_data[node_id]
		var world_pos := _grid_to_world(node_data.pos)
		_node_positions[node_id] = world_pos
		_create_box(node_id, node_data, world_pos)

	# Draw connections with ImmediateMesh
	_draw_connections()

func _create_box(node_id: String, node_data: Dictionary, world_pos: Vector3) -> void:
	var box_node := Node3D.new()
	box_node.position = world_pos
	add_child(box_node)

	# Flat box mesh
	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = BOX_SIZE
	mesh_inst.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	var cat_color: Color = CATEGORY_COLORS.get(node_data.type, Color.WHITE)
	mat.albedo_color = cat_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	box_node.add_child(mesh_inst)

	# Label on front face
	var label := Label3D.new()
	label.text = node_data.text.replace("\n", " ")
	label.font_size = 16
	label.position = Vector3(0, 0, BOX_SIZE.z / 2.0 + 0.001)
	label.modulate = Color(0.15, 0.15, 0.15)
	label.width = BOX_SIZE.x * 900  # pixel width for wrapping
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box_node.add_child(label)

func _draw_connections() -> void:
	var im := ImmediateMesh.new()
	_connections_mesh = MeshInstance3D.new()
	_connections_mesh.mesh = im
	_connections_mesh.position = Vector3(0, 0, BOX_SIZE.z / 2.0 + 0.002)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = CONNECTION_COLOR
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = false
	_connections_mesh.material_override = mat
	add_child(_connections_mesh)

	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	for node_id in flowchart_data.keys():
		var node_data: Dictionary = flowchart_data[node_id]
		var from_pos: Vector3 = _node_positions.get(node_id, Vector3.ZERO)
		for conn_id in node_data.connections:
			var to_pos: Vector3 = _node_positions.get(conn_id, Vector3.ZERO)
			# Line from center of source to center of target
			im.surface_add_vertex(from_pos)
			im.surface_add_vertex(to_pos)

			# Arrow head
			var dir := (to_pos - from_pos)
			if dir.length() > 0.001:
				dir = dir.normalized()
				var arrow_len := 0.015
				var perp := Vector3(-dir.y, dir.x, 0).normalized() * arrow_len * 0.5
				var arrow_base := to_pos - dir * arrow_len
				im.surface_add_vertex(to_pos)
				im.surface_add_vertex(arrow_base + perp)
				im.surface_add_vertex(to_pos)
				im.surface_add_vertex(arrow_base - perp)

	im.surface_end()

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
