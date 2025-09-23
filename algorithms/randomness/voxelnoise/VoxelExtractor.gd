# VoxelExtractor.gd
extends MeshInstance3D
class_name VoxelExtractor

@export var field: VoxelField
@export var iso: float = 0.0
@export var resolution: Vector3i = Vector3i(32, 32, 32) # voxels per axis
@export var smooth_normals := true

var _verts := PackedVector3Array()
var _norms := PackedVector3Array()
var _idx   := PackedInt32Array()

# Tetrahedra split of a cube (using cube corner indices 0..7)
const TETS := [
	Vector4i(0,5,1,6),
	Vector4i(0,1,2,6),
	Vector4i(0,2,3,6),
	Vector4i(0,3,7,6),
	Vector4i(0,7,4,6),
	Vector4i(0,4,5,6)
]

# Edges inside a tetra: pairs of local indices (0..3)
# (0-1, 1-2, 2-0, 0-3, 1-3, 2-3)  -> edge ids 0..5
const TET_EDGE := [
	Vector2i(0,1), Vector2i(1,2), Vector2i(2,0),
	Vector2i(0,3), Vector2i(1,3), Vector2i(2,3)
]

# Marching tetrahedra tri table (Paul Bourke style), listing edge ids per tri.
const TRI_TABLE := [
	[-1],                 # 0  (0000)
	[0,3,2,-1],           # 1  (0001)
	[0,1,4,-1],           # 2  (0010)
	[1,4,2, 2,4,3,-1],    # 3  (0011) -> 2 tris
	[1,2,5,-1],           # 4  (0100)
	[0,3,5, 0,5,1,-1],    # 5
	[0,2,5, 0,5,4,-1],    # 6
	[5,4,3,-1],           # 7
	[3,4,5,-1],           # 8  (1000)
	[4,5,0, 5,2,0,-1],    # 9
	[1,5,0, 5,3,0,-1],    # 10
	[5,2,1,-1],           # 11
	[3,4,2, 2,4,1,-1],    # 12
	[4,1,0,-1],           # 13
	[2,3,0,-1],           # 14
	[-1]                  # 15 (1111)
]

func generate_chunk(box: AABB) -> void:
	assert(field, "VoxelExtractor: assign a VoxelField.")
	iso = iso if iso != 0.0 else field.iso

	print("VoxelExtractor: Generating chunk at ", box.position, " size ", box.size, " iso=", iso)
	_verts.clear(); _norms.clear(); _idx.clear()

	# cube steps
	var nx := resolution.x
	var ny := resolution.y
	var nz := resolution.z
	var step := Vector3(
		box.size.x / float(nx - 1),
		box.size.y / float(ny - 1),
		box.size.z / float(nz - 1)
	)

	# pre-sample scalar field on the grid
	var grid := []
	grid.resize(nx * ny * nz)
	for z in range(nz):
		for y in range(ny):
			for x in range(nx):
				var p := box.position + Vector3(x, y, z) * step
				grid[_gi(x,y,z,nx,ny)] = { "p": p, "v": field.field(p) }

	# march each cube, split to tetra and polygonize
	for z in range(nz - 1):
		for y in range(ny - 1):
			for x in range(nx - 1):
				_poly_cube(x, y, z, nx, ny, grid)

	print("VoxelExtractor: Generated ", _verts.size(), " vertices, ", _idx.size()/3, " triangles")
	_commit_mesh()

func _gi(x:int, y:int, z:int, nx:int, ny:int) -> int:
	return x + y * nx + z * nx * ny

func _poly_cube(x:int, y:int, z:int, nx:int, ny:int, grid:Array) -> void:
	# cube corner ids (0..7)
	var c := [
		Vector3i(x,   y,   z  ),
		Vector3i(x+1, y,   z  ),
		Vector3i(x+1, y+1, z  ),
		Vector3i(x,   y+1, z  ),
		Vector3i(x,   y,   z+1),
		Vector3i(x+1, y,   z+1),
		Vector3i(x+1, y+1, z+1),
		Vector3i(x,   y+1, z+1)
	]
	var P := PackedVector3Array()
	var V := PackedFloat32Array()
	P.resize(8); V.resize(8)
	for i in range(8):
		var vi  = c[i]
		var rec = grid[_gi(vi.x, vi.y, vi.z, nx, ny)]
		P[i] = rec.p
		V[i] = rec.v

	# split into 6 tets and polygonize each
	for t in TETS:
		var ids = [t.x, t.y, t.z, t.w]
		_poly_tetra(P, V, ids)
 

func _interp(p1:Vector3, p2:Vector3, v1:float, v2:float) -> Vector3:
	var mu := 0.5
	var dv := (v2 - v1)
	if abs(dv) > 1e-6:
		mu = clamp((iso - v1) / dv, 0.0, 1.0)
	return p1.lerp(p2, mu)

func _poly_tetra(P:PackedVector3Array, V:PackedFloat32Array, ids:Array) -> void:
	# corner order inside the tetra
	var tp := [P[ids[0]], P[ids[1]], P[ids[2]], P[ids[3]]]
	var tv := [V[ids[0]], V[ids[1]], V[ids[2]], V[ids[3]]]

	# bitmask: 1 if value > iso (inside)
	var mask := 0
	for i in range(4):
		if tv[i] > iso: mask |= (1 << i)

	if mask == 0 or mask == 15:
		return

	# compute all 6 possible edge intersections lazily
	var epos := Array() ; epos.resize(6)
	for e in range(6):
		var a  = TET_EDGE[e].x
		var b  = TET_EDGE[e].y
		epos[e] = _interp(tp[a], tp[b], tv[a], tv[b])

	var entry  = TRI_TABLE[mask]
	for i in range(0, entry.size(), 3):
		if entry[i] == -1: break
		var a  = epos[entry[i+0]]
		var b  = epos[entry[i+1]]
		var c  = epos[entry[i+2]]
		_emit(a, b, c)
 

func _emit(a:Vector3, b:Vector3, c:Vector3) -> void:
	var base := _verts.size()
	_verts.push_back(a); _verts.push_back(b); _verts.push_back(c)
	# flat normal; will be smoothed later if desired
	var n := (b - a).cross(c - a).normalized()
	_norms.push_back(n); _norms.push_back(n); _norms.push_back(n)
	_idx.push_back(base); _idx.push_back(base+1); _idx.push_back(base+2)

func _commit_mesh() -> void:
	if _verts.size() == 0:
		print("VoxelExtractor: No vertices generated - no mesh created")
		return
		
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in _idx:
		st.set_normal(_norms[i])
		st.add_vertex(_verts[i])

	if smooth_normals:
		st.index()
		st.generate_normals()

	mesh = st.commit()
	
	# Add a simple material to make the mesh visible
	if mesh and not material_override:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.6, 1.0)  # Light purple
		mat.roughness = 0.5
		mat.metallic = 0.1
		material_override = mat
		print("VoxelExtractor: Added default material")
