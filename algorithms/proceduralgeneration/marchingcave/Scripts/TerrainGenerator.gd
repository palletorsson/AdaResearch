extends MeshInstance3D

# Settings, references and constants
@export var noise_scale : float = 2.0
@export var noise_offset : Vector3
@export var iso_level : float = 1
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
	print("🏳️‍🌈 TerrainGenerator: Starting cave generation...")
	array_mesh = ArrayMesh.new()
	mesh = array_mesh
	
	# Check if we should use fallback cave for testing
	if use_fallback_cave:
		print("🌈 Using fallback rainbow cave for testing...")
		# Set flags to prevent compute processing
		waiting_for_compute = false
		waiting_for_meshthread = false
		_create_fallback_cube()
		return
	
	print("TerrainGenerator: Initializing compute shaders...")
	if not init_compute():
		print("❌ TerrainGenerator: Compute initialization failed!")
		# Set flags to prevent compute processing
		waiting_for_compute = false
		waiting_for_meshthread = false
		_create_fallback_cube()
		return
	
	print("TerrainGenerator: Running compute shader...")
	run_compute()
	fetch_and_process_compute_data()
	create_mesh()
	print("✅ TerrainGenerator: Cave generation complete!")
	
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
	print("TerrainGenerator: Creating rendering device...")
	rendering_device = RenderingServer.create_local_rendering_device()
	if not rendering_device:
		print("❌ Failed to create local rendering device")
		return false
	
	print("TerrainGenerator: Loading compute shader...")
	var shader_file : RDShaderFile = load("res://algorithms/proceduralgeneration/marchingcave/Compute/MarchingCubes.glsl")
	if not shader_file:
		print("❌ Failed to load MarchingCubes.glsl")
		return false
	
	print("TerrainGenerator: Compiling SPIRV...")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	if not shader_spirv:
		print("❌ Failed to compile SPIRV from shader")
		return false
	
	print("TerrainGenerator: Creating shader from SPIRV...")
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
	var lut_bytes = PackedInt32Array(lut).to_byte_array()
	lut_buffer = rendering_device.storage_buffer_create(lut_bytes.size(), lut_bytes)
	var lut_uniform = RDUniform.new()
	lut_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	lut_uniform.binding = lut_bind_index
	lut_uniform.add_id(lut_buffer)
	
	# Create buffer setter and pipeline
	print("TerrainGenerator: Creating uniform set and pipeline...")
	var buffers = [triangle_uniform, params_uniform, counter_uniform, lut_uniform]
	buffer_set = rendering_device.uniform_set_create(buffers, shader, buffer_set_index)
	pipeline = rendering_device.compute_pipeline_create(shader)
	
	if not buffer_set.is_valid() or not pipeline.is_valid():
		print("❌ Failed to create uniform set or pipeline")
		return false
	
	print("✅ Compute initialization successful!")
	return true
	
func run_compute():
	# Safety check for null rendering device
	if not rendering_device or not params_buffer.is_valid() or not counter_buffer.is_valid():
		print("❌ run_compute: Invalid compute resources - using fallback")
		_create_fallback_cube()
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
		_create_fallback_cube()
		return
	
	print("TerrainGenerator: Syncing compute shader...")
	rendering_device.sync()
	waiting_for_compute = false
	
	print("TerrainGenerator: Fetching compute data...")
	# Get output
	triangle_data_bytes = rendering_device.buffer_get_data(triangle_buffer)
	counter_data_bytes = rendering_device.buffer_get_data(counter_buffer)
	
	print("TerrainGenerator: Triangle data size: ", triangle_data_bytes.size(), " bytes")
	print("TerrainGenerator: Counter data size: ", counter_data_bytes.size(), " bytes")
	
	thread = Thread.new()
	thread.start(process_mesh_data)
	waiting_for_meshthread = true
	last_meshthread_start_frame = frame
	
func process_mesh_data():
	print("TerrainGenerator: Processing mesh data...")
	var triangle_data = triangle_data_bytes.to_float32_array()
	num_triangles = counter_data_bytes.to_int32_array()[0]
	print("TerrainGenerator: Compute shader generated ", num_triangles, " triangles")
	
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
	print("TerrainGenerator: Creating mesh - Triangles: ", num_triangles, " Vertices: ", len(verts), " FPS: ", Engine.get_frames_per_second())
	
	if len(verts) > 0:
		var mesh_data = []
		mesh_data.resize(Mesh.ARRAY_MAX)
		mesh_data[Mesh.ARRAY_VERTEX] = verts
		mesh_data[Mesh.ARRAY_NORMAL] = normals
		array_mesh.clear_surfaces()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
		print("✅ Cave mesh created successfully with ", len(verts), " vertices!")
	else:
		print("❌ No vertices generated - creating fallback cube")
		_create_fallback_cube()

func _create_fallback_cube():
	print("TerrainGenerator: Creating fallback rainbow cave...")
	_create_simple_cave_mesh()
	print("✅ Fallback rainbow cave created")

func _create_simple_cave_mesh():
	# Create a simple tunnel/cave mesh as fallback
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Create a long, winding organic cave tunnel
	var base_radius = 12.0
	var length = 200.0  # Much longer!
	var segments = 40   # More detail
	var rings = 100     # Many more sections
	
	# Generate vertices for organic tunnel
	for ring in range(rings + 1):
		var progress = float(ring) / rings
		var z = (progress - 0.5) * length
		
		# Cave path curves and winds through space
		var path_curve_x = sin(progress * PI * 4.0) * 30.0  # S-curves
		var path_curve_y = cos(progress * PI * 6.0) * 20.0  # Vertical waves
		
		# Radius varies along the tunnel (wider and narrower sections)
		var radius_variation = 0.7 + 0.6 * sin(progress * PI * 8.0)
		var current_radius = base_radius * radius_variation
		
		for seg in range(segments):
			var angle = float(seg) / segments * TAU
			var base_x = cos(angle) * current_radius
			var base_y = sin(angle) * current_radius
			
			# Multiple layers of organic noise
			var noise1 = sin(z * 0.02 + angle * 4.0) * 0.3      # Large bumps
			var noise2 = sin(z * 0.08 + angle * 12.0) * 0.15    # Medium details  
			var noise3 = sin(z * 0.2 + angle * 8.0) * 0.08      # Fine texture
			var noise4 = cos(z * 0.15 + angle * 6.0 + PI) * 0.12 # Asymmetric variations
			
			# Combine all noise layers
			var total_noise = 1.0 + noise1 + noise2 + noise3 + noise4
			
			# Add some chaos for more organic feeling
			var chaos_x = sin(z * 0.03 + angle * 7.0 + progress * 10.0) * 2.0
			var chaos_y = cos(z * 0.04 + angle * 5.0 + progress * 8.0) * 1.5
			
			# Final position with path curves and noise
			var final_x = (base_x * total_noise) + path_curve_x + chaos_x
			var final_y = (base_y * total_noise) + path_curve_y + chaos_y
			
			vertices.append(Vector3(final_x, final_y, z))
			
			# Calculate normal for proper lighting (pointing inward for cave feel)
			var normal_dir = Vector3(final_x - path_curve_x, final_y - path_curve_y, 0).normalized()
			normals.append(-normal_dir)  # Inward-facing normals
			
			# UV mapping with some distortion for interesting texture flow
			var u = float(seg) / segments
			var v = progress + sin(progress * PI * 4.0) * 0.1  # Flowing UV
			uvs.append(Vector2(u, v))
	
	# Generate indices for triangles (double-sided)
	for ring in range(rings):
		for seg in range(segments):
			var current = ring * segments + seg
			var next = ring * segments + (seg + 1) % segments
			var next_ring_current = (ring + 1) * segments + seg
			var next_ring_next = (ring + 1) * segments + (seg + 1) % segments
			
			# Two triangles per quad (front faces)
			indices.append(current)
			indices.append(next_ring_current)
			indices.append(next)
			
			indices.append(next)
			indices.append(next_ring_current)
			indices.append(next_ring_next)
			
			# Two triangles per quad (back faces - reversed winding)
			indices.append(current)
			indices.append(next)
			indices.append(next_ring_current)
			
			indices.append(next)
			indices.append(next_ring_next)
			indices.append(next_ring_current)
	
	# Create the mesh
	var mesh_arrays = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_NORMAL] = normals
	mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh_arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	
	print("✅ Created double-sided cave tunnel with ", vertices.size(), " vertices, ", indices.size() / 3, " triangles")

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
	var file = FileAccess.open(file_path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()

	var index_strings = text.split(',')
	var indices = []
	for s in index_strings:
		indices.append(int(s))
		
	return indices
	
	
func _notification(type):
	if type == NOTIFICATION_PREDELETE:
		release()

func release():
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
	rendering_device= null
