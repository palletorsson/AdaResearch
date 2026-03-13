extends Node3D
## BellCurveTerrain.gd
## Builds a 20×20 quad grid (Y up) shaped into a 3D bell curve.
## Uses HeightMapShape3D for smooth player collisions.

@export var quads_x: int = 20
@export var quads_z: int = 20
@export var cell_size: float = 1.0
@export_range(0.1, 10.0, 0.1) var height_scale: float = 5.0   # overall height of the bell (Y-axis)
@export_range(0.1, 5.0, 0.1) var spread: float = 2.0          # width of the bell
@export var randomize_on_ready: bool = false                  # disabled - create once only
@export var update_interval: float = 2.0                      # seconds between new bell randomizations
@export var add_noise: bool = true                            # small random surface noise on Z-axis
@export var noise_strength: float = 0.05                      # subtle Z-axis noise variation

var verts: PackedVector3Array
var original_verts: PackedVector3Array  # Store original flat grid positions
var uvs: PackedVector2Array
var indices: PackedInt32Array

var mesh_instance: MeshInstance3D
var body: StaticBody3D
var shape_node: CollisionShape3D
var rng := RandomNumberGenerator.new()
var time_accum := 0.0

func _ready() -> void:
	rng.randomize()
	_build_nodes()
	_build_flat_grid()
	original_verts = verts.duplicate()  # Save original positions
	_make_bell_curve()
	_commit_mesh()
	_update_collider()

func _process(delta: float) -> void:
	time_accum += delta
	if time_accum >= update_interval and randomize_on_ready:
		time_accum = 0.0
		_make_bell_curve()
		_commit_mesh()
		await get_tree().process_frame
		_update_collider()

# ---------------------------------------------------------------------
# --- node + geometry setup ------------------------------------------
func _build_nodes() -> void:
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)

	# Apply SimpleGrid shader material
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	mesh_instance.material_override = shader_mat

	body = StaticBody3D.new()
	add_child(body)

	shape_node = CollisionShape3D.new()
	body.add_child(shape_node)

func _build_flat_grid() -> void:
	var vx := quads_x + 1
	var vz := quads_z + 1

	verts = PackedVector3Array()
	uvs = PackedVector2Array()
	indices = PackedInt32Array()
	verts.resize(vx * vz)
	uvs.resize(vx * vz)

	var width := float(quads_x) * cell_size
	var depth := float(quads_z) * cell_size
	var x0 := -width * 0.5
	var z0 := -depth * 0.5

	for z in range(vz):
		for x in range(vx):
			var idx := z * vx + x
			var px := x0 + float(x) * cell_size
			var pz := z0 + float(z) * cell_size
			verts[idx] = Vector3(px, 0.0, pz)
			uvs[idx] = Vector2(float(x) / quads_x, float(z) / quads_z)

	for z in range(quads_z):
		for x in range(quads_x):
			var i0 := z * vx + x
			var i1 := i0 + 1
			var i2 := i0 + vx
			var i3 := i2 + 1
			indices.push_back(i0)
			indices.push_back(i2)
			indices.push_back(i1)
			indices.push_back(i1)
			indices.push_back(i2)
			indices.push_back(i3)

# ---------------------------------------------------------------------
# --- bell-curve deformation -----------------------------------------
func _make_bell_curve() -> void:
	if verts.is_empty() or original_verts.is_empty():
		return

	var center_x := 0.0
	var center_z := 0.0
	var h := height_scale * rng.randf_range(0.8, 1.2)
	var s := spread * rng.randf_range(0.8, 1.2)

	for i in range(verts.size()):
		# Start from the original flat grid position
		var orig := original_verts[i]
		var dx := orig.x - center_x
		var dz := orig.z - center_z
		var dist_sq := (dx * dx + dz * dz) / (s * s)

		# Apply bell curve to Y (height)
		var y := h * exp(-dist_sq)

		# Apply subtle random noise to Z-axis only
		var z_noise := 0.0
		if add_noise:
			z_noise = rng.randf_range(-noise_strength, noise_strength)

		verts[i] = Vector3(orig.x, y, orig.z + z_noise)

# ---------------------------------------------------------------------
# --- mesh + collider update -----------------------------------------
func _commit_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in indices.size():
		var idx := indices[i]
		st.set_uv(uvs[idx])
		st.add_vertex(verts[idx])
	st.generate_normals()
	var mesh := st.commit()
	mesh_instance.mesh = mesh

func _update_collider() -> void:
	if verts.is_empty():
		return

	var size_x := quads_x + 1
	var size_z := quads_z + 1
	var heights := PackedFloat32Array()

	for z in range(size_z):
		for x in range(size_x):
			var idx := z * size_x + x
			heights.append(verts[idx].y)

	var shape := HeightMapShape3D.new()
	shape.map_width = size_x
	shape.map_depth = size_z
	shape.map_data = heights
	shape_node.shape = shape

	# Drop collider slightly for safe walking margin
	body.transform.origin.y = -0.05

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

