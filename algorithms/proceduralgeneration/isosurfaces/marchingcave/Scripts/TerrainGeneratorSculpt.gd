class_name TerrainGeneratorSculpt extends TerrainGeneratorBase

# --- SDF Sculpter ---
# Allows adding blobs (spheres) to a buffer which are then smooth-blended by the shader.

var blobs_array : Array[Vector4] = [] # x,y,z,radius
var blob_buffer : RID
const blob_bind_index : int = 4

@export var seed_blobs_on_ready: bool = true

func get_class_name() -> String:
	return "TerrainGeneratorSculpt"

func _ready() -> void:
	if seed_blobs_on_ready and blobs_array.is_empty():
		# Seed with an organic vertical form — grows from ground
		var center := center_position
		var s := chunk_scale * 0.15  # smaller blobs = more sculpt detail
		add_blob(center + Vector3(0, -s * 0.2, 0), s * 0.5)   # wide base
		add_blob(center + Vector3(0, s * 0.3, 0), s * 0.35)    # torso
		add_blob(center + Vector3(s * 0.15, s * 0.7, 0), s * 0.25)  # shoulder
		add_blob(center + Vector3(-s * 0.1, s * 0.6, s * 0.08), s * 0.22)
		add_blob(center + Vector3(0, s * 1.0, 0), s * 0.18)    # neck
		add_blob(center + Vector3(0.02, s * 1.3, -0.01), s * 0.15)  # top
		print("%s: Seeded %d initial blobs" % [get_class_name(), blobs_array.size()])
	super._ready()

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Compute/MarchingCubesSculpt.glsl"

func add_blob(pos: Vector3, radius: float) -> void:
	blobs_array.append(Vector4(pos.x, pos.y, pos.z, radius))
	# Note: We don't update buffer instantly here, we do it in run_compute()
	# or we can force a run.
	
	# If we have too many blobs, performance might drop in simple loop shader.
	# 500 is a safe limit for now.
	if blobs_array.size() > 500:
		blobs_array.pop_front() # Remove oldest
	
func clear_blobs() -> void:
	blobs_array.clear()

func get_params_array():
	var params = super.get_params_array()
	# Base returns 11 floats (indices 0-10).
	# Shader expects: index 11 = shapeId, index 12 = numBlobs
	params.append(0.0)  # shapeId (unused placeholder, keeps alignment)
	params.append(float(blobs_array.size()))  # numBlobs
	return params

# --- OVERRIDE INIT_COMPUTE TO ADD BLOB BUFFER ---
# Copied from Base but added Blob Buffer creation and binding.
func init_compute() -> bool:
	print("%s: Creating rendering device..." % get_class_name())
	rendering_device = RenderingServer.create_local_rendering_device()
	if not rendering_device:
		return false
	
	var shader_path = get_compute_shader_path()
	var shader_file : RDShaderFile = load(shader_path)
	if not shader_file: return false
	
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	if not shader_spirv: return false
	
	shader = rendering_device.shader_create_from_spirv(shader_spirv)
	if not shader.is_valid(): return false
	
	# 1. Triangle Buffer
	const max_tris_per_voxel : int = 5
	const max_triangles : int = max_tris_per_voxel * int(pow(num_voxels_per_axis, 3))
	const bytes_per_triangle : int = (4 * 3) * 4
	const max_bytes : int = bytes_per_triangle * max_triangles
	
	triangle_buffer = rendering_device.storage_buffer_create(max_bytes)
	var triangle_uniform = RDUniform.new()
	triangle_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	triangle_uniform.binding = triangle_bind_index
	triangle_uniform.add_id(triangle_buffer)
	
	# 2. Params Buffer
	var params_bytes = PackedFloat32Array(get_params_array()).to_byte_array()
	params_buffer = rendering_device.storage_buffer_create(params_bytes.size(), params_bytes)
	var params_uniform = RDUniform.new()
	params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	params_uniform.binding = params_bind_index
	params_uniform.add_id(params_buffer)
	
	# 3. Counter Buffer
	var counter = [0]
	var counter_bytes = PackedFloat32Array(counter).to_byte_array()
	counter_buffer = rendering_device.storage_buffer_create(counter_bytes.size(), counter_bytes)
	var counter_uniform = RDUniform.new()
	counter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	counter_uniform.binding = counter_bind_index
	counter_uniform.add_id(counter_buffer)
	
	# 4. LUT Buffer
	var lut = load_lut("res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Compute/MarchingCubesLUT.txt")
	var lut_bytes = PackedInt32Array(lut).to_byte_array()
	lut_buffer = rendering_device.storage_buffer_create(lut_bytes.size(), lut_bytes)
	var lut_uniform = RDUniform.new()
	lut_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	lut_uniform.binding = lut_bind_index
	lut_uniform.add_id(lut_buffer)
	
	# 5. NEW: Blob Buffer
	# Initialize with some size, even if empty
	var initial_blobs = PackedVector4Array()
	initial_blobs.resize(500) # Pre-allocate max size
	var blob_bytes = initial_blobs.to_byte_array()
	blob_buffer = rendering_device.storage_buffer_create(blob_bytes.size(), blob_bytes)
	var blob_uniform = RDUniform.new()
	blob_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	blob_uniform.binding = blob_bind_index
	blob_uniform.add_id(blob_buffer)
	
	# Create uniform set
	var buffers = [triangle_uniform, params_uniform, counter_uniform, lut_uniform, blob_uniform]
	buffer_set = rendering_device.uniform_set_create(buffers, shader, buffer_set_index)
	
	pipeline = rendering_device.compute_pipeline_create(shader)
	return true

# --- OVERRIDE RUN_COMPUTE TO UPDATE BLOB BUFFER ---
func run_compute():
	if not rendering_device: return
	
	# Update Blob Buffer
	var blob_data = PackedVector4Array(blobs_array)
	# Ensure we fill the buffer or resize (RD buffers are fixed size usually unless re-created, but buffer_update works if size <= created size)
	# We created 500. So we must send data that fits 500? No, we can update a subset.
	# But actually, PackedByteArray must match size for `buffer_update`? 
	# Safest is to pad to 500 or just recreate if implementation allows (slow).
	# Better: Use a fixed max size array (500) and fill with zero.
	
	if blob_data.size() < 500:
		var missing = 500 - blob_data.size()
		for i in range(missing):
			blob_data.append(Vector4(0,0,0,0)) # Dummy blobs with 0 radius won't affect SDF much (radius 0 sphere is minimal)
			
	var blob_bytes = blob_data.to_byte_array()
	rendering_device.buffer_update(blob_buffer, 0, blob_bytes.size(), blob_bytes)
	
	# Update Params (includes numBlobs)
	var params_bytes = PackedFloat32Array(get_params_array()).to_byte_array()
	rendering_device.buffer_update(params_buffer, 0, params_bytes.size(), params_bytes)
	
	# Reset Counter
	var counter = [0]
	var counter_bytes = PackedFloat32Array(counter).to_byte_array()
	rendering_device.buffer_update(counter_buffer, 0, counter_bytes.size(), counter_bytes)

	# Dispatch
	var compute_list = rendering_device.compute_list_begin()
	rendering_device.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rendering_device.compute_list_bind_uniform_set(compute_list, buffer_set, buffer_set_index)
	rendering_device.compute_list_dispatch(compute_list, resolution, resolution, resolution)
	rendering_device.compute_list_end()
	
	rendering_device.submit()
	last_compute_dispatch_frame = frame
	waiting_for_compute = true

func release():
	if rendering_device:
		rendering_device.free_rid(blob_buffer) # Release new buffer
	super.release()
