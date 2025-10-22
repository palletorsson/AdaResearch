extends MeshInstance3D

# Settings, references and constants
@export var noise_scale : float = 2.0
@export var noise_offset : Vector3
@export var iso_level : float = 0.0
@export var chunk_scale : float = 1000
@export var center_position : Vector3 = Vector3.ZERO
@export var use_fallback_cave : bool = false  # Force use simple cave for testing

const resolution : int = 8
const num_waitframes_gpusync : int = 12
const num_waitframes_meshthread : int = 90

const work_group_size : int = 8
const num_voxels_per_axis : int = work_group_size * resolution
const buffer_set_index : int = 0
const triangle_bind_index : int = 0
const params_bind_index : int = 1
const counter_bind_index : int = 2
const lut_bind_index : int = 3

# Compute stuff
var rendering_device: RenderingDevice
var shader : RID
var pipeline : RID

var buffer_set : RID
var triangle_buffer : RID
var params_buffer : RID
var counter_buffer : RID
var lut_buffer : RID

# Data received from compute shader
var triangle_data_bytes
var counter_data_bytes
var num_triangles

var array_mesh : ArrayMesh
var verts = PackedVector3Array()
var normals = PackedVector3Array()

# State
var time : float
var frame : int
var last_compute_dispatch_frame : int
var last_meshthread_start_frame : int
var waiting_for_compute : bool
var waiting_for_meshthread : bool
var thread

func _ready():
	print("🏳️‍🌈 TerrainGeneratorFlat: Starting flat landscape with caves generation...")
	array_mesh = ArrayMesh.new()
	mesh = array_mesh
	
	# Check if we should use fallback cave for testing
	if use_fallback_cave:
		print("🌈 Using fallback flat landscape for testing...")
		# Set flags to prevent compute processing
		waiting_for_compute = false
		waiting_for_meshthread = false
		_create_fallback_landscape()
		return
	
	print("TerrainGeneratorFlat: Initializing compute shaders...")
	if not init_compute():
		print("❌ TerrainGeneratorFlat: Compute initialization failed!")
		# Set flags to prevent compute processing
		waiting_for_compute = false
		waiting_for_meshthread = false
		_create_fallback_landscape()
		return
	
	print("TerrainGeneratorFlat: Running compute shader...")
	run_compute()
	fetch_and_process_compute_data()
	create_mesh()
	print("✅ TerrainGeneratorFlat: Flat landscape generation complete!")
	
func _process(delta):
	# Skip compute processing if we're using fallback or if rendering device is null
	if use_fallback_cave or not rendering_device:
		return
	
	if (waiting_for_compute && frame - last_compute_dispatch_frame >= num_waitframes_gpusync):
		fetch_and_process_compute_data()
	elif (waiting_for_meshthread && frame - last_meshthread_start_frame >= num_waitframes_meshthread):
		create_mesh()
	elif (!waiting_for_compute && !waiting_for_meshthread):
		run_compute()
	
	frame += 1
	time += delta
	
func init_compute() -> bool:
	print("TerrainGeneratorFlat: Creating rendering device...")
	rendering_device = RenderingServer.create_local_rendering_device()
	if not rendering_device:
		print("❌ Failed to create local rendering device")
		return false
	
	print("TerrainGeneratorFlat: Loading compute shader...")
	var shader_file : RDShaderFile = load("res://algorithms/proceduralgeneration/marchingcave/Compute/MarchingCubesFlat.glsl")
	if not shader_file:
		print("❌ Failed to load MarchingCubesFlat.glsl")
		return false
	
	print("TerrainGeneratorFlat: Compiling SPIRV...")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	if not shader_spirv:
		print("❌ Failed to compile SPIRV from shader")
		return false
	
	print("TerrainGeneratorFlat: Creating shader from SPIRV...")
	shader = rendering_device.shader_create_from_spirv(shader_spirv)
	if not shader.is_valid():
		print("❌ Failed to create shader from SPIRV")
		return false
	
	# Create triangles buffer
	const max_tris_per_voxel : int = 5
	const max_triangles : int = max_tris_per_voxel * int(pow(num_voxels_per_axis, 3))
	const bytes_per_float : int = 4
	const floats_per_triangle : int = 4 * 3
	const bytes_per_triangle : int = floats_per_triangle * bytes_per_float
	const max_bytes : int = bytes_per_triangle * max_triangles
	
	triangle_buffer = rendering_device.storage_buffer_create(max_bytes)
	var triangle_uniform = RDUniform.new()
	triangle_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	triangle_uniform.binding = triangle_bind_index
	triangle_uniform.add_id(triangle_buffer)
	
	# Create params buffer
	var params_bytes = PackedFloat32Array(get_params_array()).to_byte_array()
	params_buffer = rendering_device.storage_buffer_create(params_bytes.size(), params_bytes)
	var params_uniform = RDUniform.new()
	params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	params_uniform.binding = params_bind_index
	params_uniform.add_id(params_buffer)
	
	# Create counter buffer
	var counter = [0]
	var counter_bytes = PackedFloat32Array(counter).to_byte_array()
	counter_buffer = rendering_device.storage_buffer_create(counter_bytes.size(), counter_bytes)
	var counter_uniform = RDUniform.new()
	counter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	counter_uniform.binding = counter_bind_index
	counter_uniform.add_id(counter_buffer)
	
	# Create lut buffer
	var lut = load_lut("res://algorithms/proceduralgeneration/marchingcave/Compute/MarchingCubesLUT.txt")
	if lut.is_empty():
		push_error("TerrainGeneratorFlat: LUT data is empty, cannot create buffer")
		return false
	
	var lut_bytes = PackedInt32Array(lut).to_byte_array()
	if lut_bytes.is_empty():
		push_error("TerrainGeneratorFlat: LUT byte array is empty")
		return false
	
	lut_buffer = rendering_device.storage_buffer_create(lut_bytes.size(), lut_bytes)
	if not lut_buffer.is_valid():
		push_error("TerrainGeneratorFlat: Failed to create LUT buffer")
		return false
		
	var lut_uniform = RDUniform.new()
	lut_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	lut_uniform.binding = lut_bind_index
	lut_uniform.add_id(lut_buffer)
	
	# Create buffer setter and pipeline
	print("TerrainGeneratorFlat: Creating uniform set and pipeline...")
	print("  - Triangle buffer valid: ", triangle_buffer.is_valid())
	print("  - Params buffer valid: ", params_buffer.is_valid())
	print("  - Counter buffer valid: ", counter_buffer.is_valid())
	print("  - LUT buffer valid: ", lut_buffer.is_valid())
	print("  - Shader valid: ", shader.is_valid())
	
	var buffers = [triangle_uniform, params_uniform, counter_uniform, lut_uniform]
	buffer_set = rendering_device.uniform_set_create(buffers, shader, buffer_set_index)
	if not buffer_set.is_valid():
		push_error("TerrainGeneratorFlat: Failed to create uniform set")
		push_error("  Buffer bindings: [0]=%d [1]=%d [2]=%d [3]=%d" % [
			triangle_uniform.binding, params_uniform.binding, 
			counter_uniform.binding, lut_uniform.binding
		])
		return false
		
	pipeline = rendering_device.compute_pipeline_create(shader)
	if not pipeline.is_valid():
		push_error("TerrainGeneratorFlat: Failed to create compute pipeline")
		return false
	
	print("✅ Compute initialization successful!")
	return true
	
func run_compute():
	# Safety check for null rendering device
	if not rendering_device or not params_buffer.is_valid() or not counter_buffer.is_valid():
		print("❌ run_compute: Invalid compute resources - using fallback")
		_create_fallback_landscape()
		return
	
	# Update params buffer
	var params_bytes = PackedFloat32Array(get_params_array()).to_byte_array()
	rendering_device.buffer_update(params_buffer, 0, params_bytes.size(), params_bytes)
	# Reset counter
	var counter = [0]
	var counter_bytes = PackedFloat32Array(counter).to_byte_array()
	rendering_device.buffer_update(counter_buffer,0,counter_bytes.size(), counter_bytes)

	# Prepare compute list
	var compute_list = rendering_device.compute_list_begin()
	rendering_device.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rendering_device.compute_list_bind_uniform_set(compute_list, buffer_set, buffer_set_index)
	rendering_device.compute_list_dispatch(compute_list, resolution, resolution, resolution)
	rendering_device.compute_list_end()
	
	# Run
	rendering_device.submit()
	last_compute_dispatch_frame = frame
	waiting_for_compute = true

func fetch_and_process_compute_data():
	# Safety check for null rendering device
	if not rendering_device:
		print("❌ fetch_and_process_compute_data: Null rendering device - using fallback")
		_create_fallback_landscape()
		return
	
	print("TerrainGeneratorFlat: Syncing compute shader...")
	rendering_device.sync()
	waiting_for_compute = false
	
	print("TerrainGeneratorFlat: Fetching compute data...")
	# Get output
	triangle_data_bytes = rendering_device.buffer_get_data(triangle_buffer)
	counter_data_bytes = rendering_device.buffer_get_data(counter_buffer)
	
	print("TerrainGeneratorFlat: Triangle data size: ", triangle_data_bytes.size(), " bytes")
	print("TerrainGeneratorFlat: Counter data size: ", counter_data_bytes.size(), " bytes")
	
	thread = Thread.new()
	thread.start(process_mesh_data)
	waiting_for_meshthread = true
	last_meshthread_start_frame = frame
	
func process_mesh_data():
	print("TerrainGeneratorFlat: Processing mesh data...")
	var triangle_data = triangle_data_bytes.to_float32_array()
	num_triangles = counter_data_bytes.to_int32_array()[0]
	print("TerrainGeneratorFlat: Compute shader generated ", num_triangles, " triangles")
	
	var num_verts : int = num_triangles * 3
	verts.resize(num_verts)
	normals.resize(num_verts)
	
	if num_triangles == 0:
		print("❌ No triangles generated by compute shader!")
		return
	
	for tri_index in range(num_triangles):
		var i = tri_index * 16
		var posA = Vector3(triangle_data[i + 0], triangle_data[i + 1], triangle_data[i + 2])
		var posB = Vector3(triangle_data[i + 4], triangle_data[i + 5], triangle_data[i + 6])
		var posC = Vector3(triangle_data[i + 8], triangle_data[i + 9], triangle_data[i + 10])
		var norm = Vector3(triangle_data[i + 12], triangle_data[i + 13], triangle_data[i + 14])
		verts[tri_index * 3 + 0] = posA
		verts[tri_index * 3 + 1] = posB
		verts[tri_index * 3 + 2] = posC
		normals[tri_index * 3 + 0] = norm
		normals[tri_index * 3 + 1] = norm
		normals[tri_index * 3 + 2] = norm
		
	
func create_mesh():
	thread.wait_to_finish()
	waiting_for_meshthread = false
	print("TerrainGeneratorFlat: Creating mesh - Triangles: ", num_triangles, " Vertices: ", len(verts), " FPS: ", Engine.get_frames_per_second())
	
	if len(verts) > 0:
		var mesh_data = []
		mesh_data.resize(Mesh.ARRAY_MAX)
		mesh_data[Mesh.ARRAY_VERTEX] = verts
		mesh_data[Mesh.ARRAY_NORMAL] = normals
		array_mesh.clear_surfaces()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
		print("✅ Flat landscape mesh created successfully with ", len(verts), " vertices!")
		_create_collision()
	else:
		print("❌ No vertices generated - creating fallback landscape")
		_create_fallback_landscape()

func _create_fallback_landscape():
	print("TerrainGeneratorFlat: Creating fallback flat landscape...")
	_create_simple_flat_mesh()
	print("✅ Fallback flat landscape created")

func _create_simple_flat_mesh():
	# Create a simple flat plane with some hills as fallback
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Create a large flat terrain grid
	var size = 200.0  # Size of terrain
	var segments = 50  # Resolution
	var step = size / segments
	
	# Generate vertices for flat terrain with hills
	for z in range(segments + 1):
		for x in range(segments + 1):
			var px = (x - segments / 2.0) * step
			var pz = (z - segments / 2.0) * step
			
			# Add some rolling hills
			var height = 0.0
			height += sin(px * 0.05) * cos(pz * 0.05) * 8.0
			height += sin(px * 0.15) * cos(pz * 0.12) * 3.0
			
			vertices.append(Vector3(px, height, pz))
			normals.append(Vector3.UP)
			uvs.append(Vector2(float(x) / segments, float(z) / segments))
	
	# Generate indices for triangles
	for z in range(segments):
		for x in range(segments):
			var i0 = z * (segments + 1) + x
			var i1 = i0 + 1
			var i2 = (z + 1) * (segments + 1) + x
			var i3 = i2 + 1
			
			# Two triangles per quad
			indices.append(i0)
			indices.append(i2)
			indices.append(i1)
			
			indices.append(i1)
			indices.append(i2)
			indices.append(i3)
	
	# Create the mesh
	var mesh_arrays = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_NORMAL] = normals
	mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh_arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	
	print("✅ Created flat landscape with ", vertices.size(), " vertices, ", indices.size() / 3, " triangles")
	_create_collision()

func get_params_array():
	var params = []
	params.append(time)
	params.append(noise_scale)
	params.append(iso_level)
	params.append(float(num_voxels_per_axis))
	params.append(chunk_scale)
	params.append(center_position.x)
	params.append(center_position.y)
	params.append(center_position.z)
	params.append(noise_offset.x)
	params.append(noise_offset.y)
	params.append(noise_offset.z)
	return params
	
func load_lut(file_path):
	# Try to open the file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		var error = FileAccess.get_open_error()
		print("Warning: Failed to open LUT file: " + file_path + " (Error code: " + str(error) + ")")
		
		# Try alternative path without res://
		var alt_path = file_path.replace("res://", "")
		print("Trying alternative path: " + alt_path)
		file = FileAccess.open(alt_path, FileAccess.READ)
		
		if not file:
			print("Alternative path also failed. Using embedded LUT data.")
			return get_embedded_lut()
	
	var text = file.get_as_text()
	file.close()

	var index_strings = text.split(',')
	var indices = []
	for s in index_strings:
		if s.strip_edges() != "":
			indices.append(int(s))
	
	print("TerrainGeneratorFlat: Successfully loaded " + str(indices.size()) + " LUT indices from file")
	return indices

func get_embedded_lut() -> Array:
	# Embedded Marching Cubes LUT data (fallback when file can't be loaded)
	var lut_string = "0,8,3,0,1,9,1,8,3,9,8,1,1,2,10,0,8,3,1,2,10,9,2,10,0,2,9,2,8,3,2,10,8,10,9,8,3,11,2,0,11,2,8,11,0,1,9,0,2,3,11,1,11,2,1,9,11,9,8,11,3,10,1,11,10,3,0,10,1,0,8,10,8,11,10,3,9,0,3,11,9,11,10,9,9,8,10,10,8,11,4,7,8,4,3,0,7,3,4,0,1,9,8,4,7,4,1,9,4,7,1,7,3,1,1,2,10,8,4,7,3,4,7,3,0,4,1,2,10,9,2,10,9,0,2,8,4,7,2,10,9,2,9,7,2,7,3,7,9,4,8,4,7,3,11,2,11,4,7,11,2,4,2,0,4,9,0,1,8,4,7,2,3,11,4,7,11,9,4,11,9,11,2,9,2,1,3,10,1,3,11,10,7,8,4,1,11,10,1,4,11,1,0,4,7,11,4,4,7,8,9,0,11,9,11,10,11,0,3,4,7,11,4,11,9,9,11,10,9,5,4,9,5,4,0,8,3,0,5,4,1,5,0,8,5,4,8,3,5,3,1,5,1,2,10,9,5,4,3,0,8,1,2,10,4,9,5,5,2,10,5,4,2,4,0,2,2,10,5,3,2,5,3,5,4,3,4,8,9,5,4,2,3,11,0,11,2,0,8,11,4,9,5,0,5,4,0,1,5,2,3,11,2,1,5,2,5,8,2,8,11,4,8,5,10,3,11,10,1,3,9,5,4,4,9,5,0,8,1,8,10,1,8,11,10,5,4,0,5,0,11,5,11,10,11,0,3,5,4,8,5,8,10,10,8,11,9,7,8,5,7,9,9,3,0,9,5,3,5,7,3,0,7,8,0,1,7,1,5,7,1,5,3,3,5,7,9,7,8,9,5,7,10,1,2,10,1,2,9,5,0,5,3,0,5,7,3,8,0,2,8,2,5,8,5,7,10,5,2,2,10,5,2,5,3,3,5,7,7,9,5,7,8,9,3,11,2,9,5,7,9,7,2,9,2,0,2,7,11,2,3,11,0,1,8,1,7,8,1,5,7,11,2,1,11,1,7,7,1,5,9,5,8,8,5,7,10,1,3,10,3,11,5,7,0,5,0,9,7,11,0,1,0,10,11,10,0,11,10,0,11,0,3,10,5,0,8,0,7,5,7,0,11,10,5,7,11,5,10,6,5,0,8,3,5,10,6,9,0,1,5,10,6,1,8,3,1,9,8,5,10,6,1,6,5,2,6,1,1,6,5,1,2,6,3,0,8,9,6,5,9,0,6,0,2,6,5,9,8,5,8,2,5,2,6,3,2,8,2,3,11,10,6,5,11,0,8,11,2,0,10,6,5,0,1,9,2,3,11,5,10,6,5,10,6,1,9,2,9,11,2,9,8,11,6,3,11,6,5,3,5,1,3,0,8,11,0,11,5,0,5,1,5,11,6,3,11,6,0,3,6,0,6,5,0,5,9,6,5,9,6,9,11,11,9,8,5,10,6,4,7,8,4,3,0,4,7,3,6,5,10,1,9,0,5,10,6,8,4,7,10,6,5,1,9,7,1,7,3,7,9,4,6,1,2,6,5,1,4,7,8,1,2,5,5,2,6,3,0,4,3,4,7,8,4,7,9,0,5,0,6,5,0,2,6,7,3,9,7,9,4,3,2,9,5,9,6,2,6,9,3,11,2,7,8,4,10,6,5,5,10,6,4,7,2,4,2,0,2,7,11,0,1,9,4,7,8,2,3,11,5,10,6,9,2,1,9,11,2,9,4,11,7,11,4,5,10,6,8,4,7,3,11,5,3,5,1,5,11,6,5,1,11,5,11,6,1,0,11,7,11,4,0,4,11,0,5,9,0,6,5,0,3,6,11,6,3,8,4,7,6,5,9,6,9,11,4,7,9,7,11,9,10,4,9,6,4,10,4,10,6,4,9,10,0,8,3,10,0,1,10,6,0,6,4,0,8,3,1,8,1,6,8,6,4,6,1,10,1,4,9,1,2,4,2,6,4,3,0,8,1,2,9,2,4,9,2,6,4,0,2,4,4,2,6,8,3,2,8,2,4,4,2,6,10,4,9,10,6,4,11,2,3,0,8,2,2,8,11,4,9,10,4,10,6,3,11,2,0,1,6,0,6,4,6,1,10,6,4,1,6,1,10,4,8,1,2,1,11,8,11,1,9,6,4,9,3,6,9,1,3,11,6,3,8,11,1,8,1,0,11,6,1,9,1,4,6,4,1,3,11,6,3,6,0,0,6,4,6,4,8,11,6,8,7,10,6,7,8,10,8,9,10,0,7,3,0,10,7,0,9,10,6,7,10,10,6,7,1,10,7,1,7,8,1,8,0,10,6,7,10,7,1,1,7,3,1,2,6,1,6,8,1,8,9,8,6,7,2,6,9,2,9,1,6,7,9,0,9,3,7,3,9,7,8,0,7,0,6,6,0,2,7,3,2,6,7,2,2,3,11,10,6,8,10,8,9,8,6,7,2,0,7,2,7,11,0,9,7,6,7,10,9,10,7,1,8,0,1,7,8,1,10,7,6,7,10,2,3,11,11,2,1,11,1,7,10,6,1,6,7,1,8,9,6,8,6,7,9,1,6,11,6,3,1,3,6,0,9,1,11,6,7,7,8,0,7,0,6,3,11,0,11,6,0,7,11,6,7,6,11,3,0,8,11,7,6,0,1,9,11,7,6,8,1,9,8,3,1,11,7,6,10,1,2,6,11,7,1,2,10,3,0,8,6,11,7,2,9,0,2,10,9,6,11,7,6,11,7,2,10,3,10,8,3,10,9,8,7,2,3,6,2,7,7,0,8,7,6,0,6,2,0,2,7,6,2,3,7,0,1,9,1,6,2,1,8,6,1,9,8,8,7,6,10,7,6,10,1,7,1,3,7,10,7,6,1,7,10,1,8,7,1,0,8,0,3,7,0,7,10,0,10,9,6,10,7,7,6,10,7,10,8,8,10,9,6,8,4,11,8,6,3,6,11,3,0,6,0,4,6,8,6,11,8,4,6,9,0,1,9,4,6,9,6,3,9,3,1,11,3,6,6,8,4,6,11,8,2,10,1,1,2,10,3,0,11,0,6,11,0,4,6,4,11,8,4,6,11,0,2,9,2,10,9,10,9,3,10,3,2,9,4,3,11,3,6,4,6,3,8,2,3,8,4,2,4,6,2,0,4,2,4,6,2,1,9,0,2,3,4,2,4,6,4,3,8,1,9,4,1,4,2,2,4,6,8,1,3,8,6,1,8,4,6,6,10,1,10,1,0,10,0,6,6,0,4,4,6,3,4,3,8,6,10,3,0,3,9,10,9,3,10,9,4,6,10,4,4,9,5,7,6,11,0,8,3,4,9,5,11,7,6,5,0,1,5,4,0,7,6,11,11,7,6,8,3,4,3,5,4,3,1,5,9,5,4,10,1,2,7,6,11,6,11,7,1,2,10,0,8,3,4,9,5,7,6,11,5,4,10,4,2,10,4,0,2,3,4,8,3,5,4,3,2,5,10,5,2,11,7,6,7,2,3,7,6,2,5,4,9,9,5,4,0,8,6,0,6,2,6,8,7,3,6,2,3,7,6,1,5,0,5,4,0,6,2,8,6,8,7,2,1,8,4,8,5,1,5,8,9,5,4,10,1,6,1,7,6,1,3,7,1,6,10,1,7,6,1,0,7,8,7,0,9,5,4,4,0,10,4,10,5,0,3,10,6,10,7,3,7,10,7,6,10,7,10,8,5,4,10,4,8,10,6,9,5,6,11,9,11,8,9,3,6,11,0,6,3,0,5,6,0,9,5,0,11,8,0,5,11,0,1,5,5,6,11,6,11,3,6,3,5,5,3,1,1,2,10,9,5,11,9,11,8,11,5,6,0,11,3,0,6,11,0,9,6,5,6,9,1,2,10,11,8,5,11,5,6,8,0,5,10,5,2,0,2,5,6,11,3,6,3,5,2,10,3,10,5,3,5,8,9,5,2,8,5,6,2,3,8,2,9,5,6,9,6,0,0,6,2,1,5,8,1,8,0,5,6,8,3,8,2,6,2,8,1,5,6,2,1,6,1,3,6,1,6,10,3,8,6,5,6,9,8,9,6,10,1,0,10,0,6,9,5,0,5,6,0,0,3,8,5,6,10,10,5,6,11,5,10,7,5,11,11,5,10,11,7,5,8,3,0,5,11,7,5,10,11,1,9,0,10,7,5,10,11,7,9,8,1,8,3,1,11,1,2,11,7,1,7,5,1,0,8,3,1,2,7,1,7,5,7,2,11,9,7,5,9,2,7,9,0,2,2,11,7,7,5,2,7,2,11,5,9,2,3,2,8,9,8,2,2,5,10,2,3,5,3,7,5,8,2,0,8,5,2,8,7,5,10,2,5,9,0,1,5,10,3,5,3,7,3,10,2,9,8,2,9,2,1,8,7,2,10,2,5,7,5,2,1,3,5,3,7,5,0,8,7,0,7,1,1,7,5,9,0,3,9,3,5,5,3,7,9,8,7,5,9,7,5,8,4,5,10,8,10,11,8,5,0,4,5,11,0,5,10,11,11,3,0,0,1,9,8,4,10,8,10,11,10,4,5,10,11,4,10,4,5,11,3,4,9,4,1,3,1,4,2,5,1,2,8,5,2,11,8,4,5,8,0,4,11,0,11,3,4,5,11,2,11,1,5,1,11,0,2,5,0,5,9,2,11,5,4,5,8,11,8,5,9,4,5,2,11,3,2,5,10,3,5,2,3,4,5,3,8,4,5,10,2,5,2,4,4,2,0,3,10,2,3,5,10,3,8,5,4,5,8,0,1,9,5,10,2,5,2,4,1,9,2,9,4,2,8,4,5,8,5,3,3,5,1,0,4,5,1,0,5,8,4,5,8,5,3,9,0,5,0,3,5,9,4,5,4,11,7,4,9,11,9,10,11,0,8,3,4,9,7,9,11,7,9,10,11,1,10,11,1,11,4,1,4,0,7,4,11,3,1,4,3,4,8,1,10,4,7,4,11,10,11,4,4,11,7,9,11,4,9,2,11,9,1,2,9,7,4,9,11,7,9,1,11,2,11,1,0,8,3,11,7,4,11,4,2,2,4,0,11,7,4,11,4,2,8,3,4,3,2,4,2,9,10,2,7,9,2,3,7,7,4,9,9,10,7,9,7,4,10,2,7,8,7,0,2,0,7,3,7,10,3,10,2,7,4,10,1,10,0,4,0,10,1,10,2,8,7,4,4,9,1,4,1,7,7,1,3,4,9,1,4,1,7,0,8,1,8,7,1,4,0,3,7,4,3,4,8,7,9,10,8,10,11,8,3,0,9,3,9,11,11,9,10,0,1,10,0,10,8,8,10,11,3,1,10,11,3,10,1,2,11,1,11,9,9,11,8,3,0,9,3,9,11,1,2,9,2,11,9,0,2,11,8,0,11,3,2,11,2,3,8,2,8,10,10,8,9,9,10,2,0,9,2,2,3,8,2,8,10,0,1,8,1,10,8,1,10,2,1,3,8,9,1,8,0,9,1,0,3,8"
	
	var index_strings = lut_string.split(',')
	var indices = []
	for s in index_strings:
		if s.strip_edges() != "":
			indices.append(int(s))
	
	print("TerrainGeneratorFlat: Using embedded LUT data (" + str(indices.size()) + " indices)")
	return indices

func _create_collision():
	"""Create collision shape for the terrain mesh"""
	if not array_mesh or array_mesh.get_surface_count() == 0:
		print("⚠️ Cannot create collision: No mesh surface available")
		return
	
	# Remove old collision if it exists
	for child in get_children():
		if child is StaticBody3D:
			child.queue_free()
	
	# Create StaticBody3D for collision
	var static_body = StaticBody3D.new()
	static_body.name = "TerrainCollision"
	add_child(static_body)
	
	# Create collision shape from the mesh
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape"
	static_body.add_child(collision_shape)
	
	# Generate trimesh collision shape from the mesh
	var shape = array_mesh.create_trimesh_shape()
	if shape:
		collision_shape.shape = shape
		print("✅ Collision shape created with ", shape.get_faces().size() / 3, " triangles")
	else:
		push_error("❌ Failed to create trimesh collision shape")
	
func _notification(type):
	if type == NOTIFICATION_PREDELETE:
		release()

func release():
	if rendering_device:
		rendering_device.free_rid(pipeline)
		rendering_device.free_rid(triangle_buffer)
		rendering_device.free_rid(params_buffer)
		rendering_device.free_rid(counter_buffer);
		rendering_device.free_rid(lut_buffer);
		rendering_device.free_rid(shader)
		
		pipeline = RID()
		triangle_buffer = RID()
		params_buffer = RID()
		counter_buffer = RID()
		lut_buffer = RID()
		shader = RID()
			
		rendering_device.free()
		rendering_device = null

