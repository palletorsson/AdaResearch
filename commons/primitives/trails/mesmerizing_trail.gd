extends MeshInstance3D
class_name MesmerizingTrail

@export var target_path: NodePath
@export var trail_length: int = 50
@export var width: float = 0.5
@export var min_distance: float = 0.1

var _target: Node3D
var _points: Array[Transform3D] = []
var _widths: Array[float] = []

func _ready():
	if target_path:
		_target = get_node(target_path)
	
	# Create unique material instance
	if material_override:
		material_override = material_override.duplicate()

func _process(_delta):
	if not _target:
		return
		
	var current_t = _target.global_transform
	
	# Add point if moved enough
	if _points.is_empty() or _points[0].origin.distance_to(current_t.origin) > min_distance:
		_points.push_front(current_t)
		
		# Limit length
		if _points.size() > trail_length:
			_points.resize(trail_length)
			
	_update_mesh()

func _update_mesh():
	if _points.size() < 2:
		return
		
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	# var indices = PackedInt32Array() # Not needed if strictly organizing for add_surface
	
	# Construct Triangle Strip as Triangles
	# For N points, we have N-1 segments. 
	# Each segment has 2 triangles = 6 vertices (if strictly triangles) or 4 verts + indices.
	# Let's simple quad strip logic with vertices.
	
	# Actually, ArrayMesh with TRIANGLE_STRIP primitive is unreliable for some exporters/shaders?
	# Standard TRIANGLES is safer.
	
	# We need to transform points to local space? 
	# No, easier to make this node global (top level) or subtract global position.
	# Since this node might be attached to the stick, we should be careful.
	# Ideally, Trail is a sibling or top-level. 
	# If it's a child of the moving object, we must transform stored GLOBAL points to LOCAL.
	
	var to_local = global_transform.inverse()
	
	for i in range(_points.size() - 1):
		var t1 = _points[i]
		var t2 = _points[i+1]
		
		var p1 = to_local * t1.origin
		var p2 = to_local * t2.origin
		
		# Calculate "right" vector for width
		# We can use the transform basis right, or compute from direction
		var right1 = (to_local.basis * t1.basis.x).normalized() * width * 0.5
		var right2 = (to_local.basis * t2.basis.x).normalized() * width * 0.5
		
		# Vertices
		var v1 = p1 - right1
		var v2 = p1 + right1
		var v3 = p2 - right2
		var v4 = p2 + right2
		
		# UVs
		var y1 = float(i) / float(trail_length)
		var y2 = float(i+1) / float(trail_length)
		
		# Quad 1: v1, v2, v3
		vertices.push_back(v3); verticals_push(normals, v3, v1, v2); uvs.push_back(Vector2(0, y2))
		vertices.push_back(v2); verticals_push(normals, v3, v1, v2); uvs.push_back(Vector2(1, y1))
		vertices.push_back(v1); verticals_push(normals, v3, v1, v2); uvs.push_back(Vector2(0, y1))
		
		# Quad 2: v2, v4, v3
		vertices.push_back(v2); verticals_push(normals, v2, v4, v3); uvs.push_back(Vector2(1, y1))
		vertices.push_back(v3); verticals_push(normals, v2, v4, v3); uvs.push_back(Vector2(0, y2))
		vertices.push_back(v4); verticals_push(normals, v2, v4, v3); uvs.push_back(Vector2(1, y2))

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	
	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = arr_mesh

func verticals_push(n_arr: PackedVector3Array, a, b, c):
	var n = (b-a).cross(c-a).normalized()
	n_arr.push_back(n)
