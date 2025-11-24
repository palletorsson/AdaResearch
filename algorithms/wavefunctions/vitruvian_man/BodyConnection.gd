extends Node3D

@export var left_hand_path: NodePath
@export var right_hand_path: NodePath
@export var spine_color: Color = Color(0.9, 0.9, 0.9, 0.5)

var _left_hand: Node3D
var _right_hand: Node3D
var _mesh: ImmediateMesh
var _mesh_instance: MeshInstance3D

func _ready():
	if left_hand_path:
		_left_hand = get_node_or_null(left_hand_path)
	if right_hand_path:
		_right_hand = get_node_or_null(right_hand_path)
		
	_setup_mesh()

func _setup_mesh():
	_mesh = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _mesh
	_mesh_instance.name = "BodyConnections"
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = spine_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	_mesh_instance.material_override = mat
	
	add_child(_mesh_instance)

func _process(delta):
	if not _left_hand or not _right_hand:
		return
		
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	# Calculate a "spine" position roughly between the hands but lower/centered
	# Hands are at approx y=1.5. Spine top at y=1.5, Spine bottom at y=1.0?
	# Or just connect Left -> Center -> Right
	
	var l_pos = _left_hand.global_position
	var r_pos = _right_hand.global_position
	var center_pos = (l_pos + r_pos) / 2.0
	center_pos.y = min(l_pos.y, r_pos.y) - 0.2 # Slightly below hands
	
	# Draw lines
	_mesh.surface_set_color(spine_color)
	
	# Left Arm
	_mesh.surface_add_vertex(to_local(l_pos))
	_mesh.surface_add_vertex(to_local(center_pos))
	
	# Right Arm
	_mesh.surface_add_vertex(to_local(center_pos))
	_mesh.surface_add_vertex(to_local(r_pos))
	
	# Spine down
	var hip_pos = center_pos - Vector3(0, 0.5, 0)
	_mesh.surface_add_vertex(to_local(center_pos))
	_mesh.surface_add_vertex(to_local(hip_pos))
	
	_mesh.surface_end()
