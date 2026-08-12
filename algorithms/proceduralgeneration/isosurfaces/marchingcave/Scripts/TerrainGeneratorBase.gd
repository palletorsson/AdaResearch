class_name TerrainGeneratorBase extends MeshInstance3D

# Settings, references and constants
@export var noise_scale : float = 2.0
@export var noise_offset : Vector3
@export var iso_level : float = 0.0
@export var chunk_scale : float = 1000
@export var center_position : Vector3 = Vector3(0, 10, 0)
@export var use_fallback : bool = false  # Force use simple mesh for testing
@export var invert_faces : bool = false # Flip triangle winding and normals (useful for objects vs caves)
@export var continuous_update : bool = false # Keep re-rendering every frame (for animated shaders like Fountain)
## CAPTURE ONLY, and 0.0 means "leave the material exactly as authored".
##
## TerrainMat.tres fades ALBEDO to black with camera distance:
##   fade = 1.0 - clamp(distance(camera, vertex) / fade_distance * fade_gain, 0, 1)
## at the shipped 500.0 / 1.2 that reaches pure black at about 417 units. Fine for
## a player standing on a 300-unit terrain; fatal to a capture bench, which must
## stand ~1600 units back to frame the whole thing. Measured, the six terrain
## artifacts rendered at a subject mean luminance of 0.0-0.1 out of 255 against 59
## and 168 for the two wave-1 artifacts that do not use this material, and ten
## declared axes were scored WEAK or INERT on frames where the axis is plainly
## visible.
##
## Deliberately NOT read by apply_grid_config, so no map token can reach it: this
## is for dna.fixture, which assigns straight onto the property before _ready.
## Left at 0.0 the material resource is never touched and every placement renders
## byte-identically to before.
@export var capture_fade_distance : float = 0.0

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
var num_triangles : int = 0

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
var _released : bool = false  # Guard release() against double-teardown (PREDELETE + _exit_tree etc.)

func _ready() -> void:
	print("🏳️‍🌈 %s: Starting generation..." % get_class_name())
	_apply_capture_fade()
	array_mesh = ArrayMesh.new()
	mesh = array_mesh
	
	if use_fallback:
		print("🌈 Using fallback mesh for testing...")
		waiting_for_compute = false
		waiting_for_meshthread = false
		_create_fallback_mesh()
		return
	
	print("%s: Initializing compute shaders..." % get_class_name())
	if not init_compute():
		print("❌ %s: Compute initialization failed!" % get_class_name())
		# Set flags to prevent compute processing
		waiting_for_compute = false
		waiting_for_meshthread = false
		_create_fallback_mesh()
		return
	
	print("%s: Running compute shader..." % get_class_name())
	run_compute()
	fetch_and_process_compute_data()
	create_mesh()
	print("✅ %s: Generation complete!" % get_class_name())
	
var _initial_generation_done : bool = false

func _process(delta: float) -> void:
	# Skip compute processing if we're using fallback or if rendering device is null
	if use_fallback or not rendering_device:
		return
	
	if (waiting_for_compute && frame - last_compute_dispatch_frame >= num_waitframes_gpusync):
		fetch_and_process_compute_data()
	elif (waiting_for_meshthread && frame - last_meshthread_start_frame >= num_waitframes_meshthread):
		create_mesh()
		if not continuous_update and not _initial_generation_done:
			_initial_generation_done = true
			set_process(false)  # Stop the loop — no tick
			return
	elif (!waiting_for_compute && !waiting_for_meshthread):
		run_compute()
	
	frame += 1
	time += delta

# Virtual method to be overridden by subclasses
func get_compute_shader_path() -> String:
	push_error("get_compute_shader_path() must be implemented by subclass")
	return ""

# Virtual method to be overridden by subclasses
func get_class_name() -> String:
	return "TerrainGeneratorBase"

func init_compute() -> bool:
	print("%s: Creating rendering device..." % get_class_name())
	rendering_device = RenderingServer.create_local_rendering_device()
	if not rendering_device:
		print("❌ Failed to create local rendering device")
		return false
	
	print("%s: Loading compute shader..." % get_class_name())
	var shader_path = get_compute_shader_path()
	var shader_file : RDShaderFile = load(shader_path)
	if not shader_file:
		print("❌ Failed to load %s" % shader_path)
		return false
	
	print("%s: Compiling SPIRV..." % get_class_name())
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	if not shader_spirv:
		print("❌ Failed to compile SPIRV from shader")
		return false
	
	print("%s: Creating shader from SPIRV..." % get_class_name())
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
	var lut = load_lut("res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Compute/MarchingCubesLUT.txt")
	if lut.is_empty():
		push_error("%s: LUT data is empty, cannot create buffer" % get_class_name())
		return false
	
	var lut_bytes = PackedInt32Array(lut).to_byte_array()
	if lut_bytes.is_empty():
		push_error("%s: LUT byte array is empty" % get_class_name())
		return false
	
	lut_buffer = rendering_device.storage_buffer_create(lut_bytes.size(), lut_bytes)
	if not lut_buffer.is_valid():
		push_error("%s: Failed to create LUT buffer" % get_class_name())
		return false
		
	var lut_uniform = RDUniform.new()
	lut_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	lut_uniform.binding = lut_bind_index
	lut_uniform.add_id(lut_buffer)
	
	# Create buffer setter and pipeline
	print("%s: Creating uniform set and pipeline..." % get_class_name())
	
	var buffers = [triangle_uniform, params_uniform, counter_uniform, lut_uniform]
	buffer_set = rendering_device.uniform_set_create(buffers, shader, buffer_set_index)
	if not buffer_set.is_valid():
		push_error("%s: Failed to create uniform set" % get_class_name())
		return false
		
	pipeline = rendering_device.compute_pipeline_create(shader)
	if not pipeline.is_valid():
		push_error("%s: Failed to create compute pipeline" % get_class_name())
		return false
	
	print("✅ Compute initialization successful!")
	return true
	
func run_compute() -> void:
	# Safety check for null rendering device
	if not rendering_device or not params_buffer.is_valid() or not counter_buffer.is_valid():
		print("❌ run_compute: Invalid compute resources - using fallback")
		_create_fallback_mesh()
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

func fetch_and_process_compute_data() -> void:
	# Safety check for null rendering device
	if not rendering_device:
		print("❌ fetch_and_process_compute_data: Null rendering device - using fallback")
		_create_fallback_mesh()
		return
	
	print("%s: Syncing compute shader..." % get_class_name())
	rendering_device.sync()
	waiting_for_compute = false
	
	print("%s: Fetching compute data..." % get_class_name())
	# Get output
	triangle_data_bytes = rendering_device.buffer_get_data(triangle_buffer)
	counter_data_bytes = rendering_device.buffer_get_data(counter_buffer)
	
	thread = Thread.new()
	thread.start(process_mesh_data)
	waiting_for_meshthread = true
	last_meshthread_start_frame = frame
	
func process_mesh_data() -> void:
	print("%s: Processing mesh data..." % get_class_name())
	var triangle_data = triangle_data_bytes.to_float32_array()
	num_triangles = counter_data_bytes.to_int32_array()[0]
	print("%s: Compute shader generated %d triangles" % [get_class_name(), num_triangles])
	
	# SAFETY CAP: Prevent device hang if shader outputs garbage or too much density
	# 500k triangles is the desktop limit. For Quest VR, reduce to ~65k.
	var safety_limit := 500000
	if num_triangles > safety_limit:
		print("❌ SAFETY ABORT: Triangle count %d exceeds safety limit (%d). Aborting to prevent hang." % [num_triangles, safety_limit])
		num_triangles = 0
		return
	
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
		
		# Invert winding/normals if requested (e.g. for objects viewed from outside vs caves viewed from inside)
		if invert_faces:
			var temp = posB
			posB = posC
			posC = temp
			norm = -norm
			
		verts[tri_index * 3 + 0] = posA
		verts[tri_index * 3 + 1] = posB
		verts[tri_index * 3 + 2] = posC
		normals[tri_index * 3 + 0] = norm
		normals[tri_index * 3 + 1] = norm
		normals[tri_index * 3 + 2] = norm
		
	
func create_mesh() -> void:
	if thread and thread.is_started():
		thread.wait_to_finish()
		thread = null
	
	waiting_for_meshthread = false
	print("%s: Creating mesh - Triangles: %d Vertices: %d FPS: %f" % [get_class_name(), num_triangles, len(verts), Engine.get_frames_per_second()])
	
	if len(verts) > 0:
		var mesh_data = []
		mesh_data.resize(Mesh.ARRAY_MAX)
		mesh_data[Mesh.ARRAY_VERTEX] = verts
		mesh_data[Mesh.ARRAY_NORMAL] = normals
		array_mesh.clear_surfaces()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
		print("✅ %s: Mesh created successfully with %d vertices!" % [get_class_name(), len(verts)])
		_create_collision()
	else:
		print("❌ No vertices generated - creating fallback")
		_create_fallback_mesh()

func _create_fallback_mesh() -> void:
	# Override in subclass
	pass

# Override in subclasses that allocate extra GPU buffers (e.g. a sculpt blob buffer).
# Called from release() AFTER any in-flight compute is synced, so freeing is crash-safe.
func _free_extra_rids() -> void:
	pass

## Opens the material's distance fade for a capture, and ONLY for a capture.
##
## Duplicates the material first. TerrainMat.tres is a shared resource across
## eight scenes, so writing the parameter straight onto it would leak the capture
## setting into every other terrain alive in the same process - which during a
## sweep is exactly what happens next.
func _apply_capture_fade() -> void:
	if capture_fade_distance <= 0.0:
		return
	var mat := material_override
	if mat == null or not (mat is ShaderMaterial):
		return
	var own := (mat as ShaderMaterial).duplicate() as ShaderMaterial
	own.set_shader_parameter("fade_distance", capture_fade_distance)
	material_override = own


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
	
	print("%s: Successfully loaded %d LUT indices from file" % [get_class_name(), indices.size()])
	return indices

func get_embedded_lut() -> Array:
	# Embedded Marching Cubes LUT data (fallback when file can't be loaded)
	var lut_string = "0,8,3,0,1,9,1,8,3,9,8,1,1,2,10,0,8,3,1,2,10,9,2,10,0,2,9,2,8,3,2,10,8,10,9,8,3,11,2,0,11,2,8,11,0,1,9,0,2,3,11,1,11,2,1,9,11,9,8,11,3,10,1,11,10,3,0,10,1,0,8,10,8,11,10,3,9,0,3,11,9,11,10,9,9,8,10,10,8,11,4,7,8,4,3,0,7,3,4,0,1,9,8,4,7,4,1,9,4,7,1,7,3,1,1,2,10,8,4,7,3,4,7,3,0,4,1,2,10,9,2,10,9,0,2,8,4,7,2,10,9,2,9,7,2,7,3,7,9,4,8,4,7,3,11,2,11,4,7,11,2,4,2,0,4,9,0,1,8,4,7,2,3,11,4,7,11,9,4,11,9,11,2,9,2,1,3,10,1,3,11,10,7,8,4,1,11,10,1,4,11,1,0,4,7,11,4,4,7,8,9,0,11,9,11,10,11,0,3,4,7,11,4,11,9,9,11,10,9,5,4,9,5,4,0,8,3,0,5,4,1,5,0,8,5,4,8,3,5,3,1,5,1,2,10,9,5,4,3,0,8,1,2,10,4,9,5,5,2,10,5,4,2,4,0,2,2,10,5,3,2,5,3,5,4,3,4,8,9,5,4,2,3,11,0,11,2,0,8,11,4,9,5,0,5,4,0,1,5,2,3,11,2,1,5,2,5,8,2,8,11,4,8,5,10,3,11,10,1,3,9,5,4,4,9,5,0,8,1,8,10,1,8,11,10,5,4,0,5,0,11,5,11,10,11,0,3,5,4,8,5,8,10,10,8,11,9,7,8,5,7,9,9,3,0,9,5,3,5,7,3,0,7,8,0,1,7,1,5,7,1,5,3,3,5,7,9,7,8,9,5,7,10,1,2,10,1,2,9,5,0,5,3,0,5,7,3,8,0,2,8,2,5,8,5,7,10,5,2,2,10,5,2,5,3,3,5,7,7,9,5,7,8,9,3,11,2,9,5,7,9,7,2,9,2,0,2,7,11,2,3,11,0,1,8,1,7,8,1,5,7,11,2,1,11,1,7,7,1,5,9,5,8,8,5,7,10,1,3,10,3,11,5,7,0,5,0,9,7,11,0,1,0,10,11,10,0,11,10,0,11,0,3,10,5,0,8,0,7,5,7,0,11,10,5,7,11,5,10,6,5,0,8,3,5,10,6,9,0,1,5,10,6,1,8,3,1,9,8,5,10,6,1,6,5,2,6,1,1,6,5,1,2,6,3,0,8,9,6,5,9,0,6,0,2,6,5,9,8,5,8,2,5,2,6,3,2,8,2,3,11,10,6,5,11,0,8,11,2,0,10,6,5,0,1,9,2,3,11,5,10,6,5,10,6,1,9,2,9,11,2,9,8,11,6,3,11,6,5,3,5,1,3,0,8,11,0,11,5,0,5,1,5,11,6,3,11,6,0,3,6,0,6,5,0,5,9,6,5,9,6,9,11,11,9,8,5,10,6,4,7,8,4,3,0,4,7,3,6,5,10,1,9,0,5,10,6,8,4,7,10,6,5,1,9,7,1,7,3,7,9,4,6,1,2,6,5,1,4,7,8,1,2,5,5,2,6,3,0,4,3,4,7,8,4,7,9,0,5,0,6,5,0,2,6,7,3,9,7,9,4,3,2,9,5,9,6,2,6,9,3,11,2,7,8,4,10,6,5,5,10,6,4,7,2,4,2,0,2,7,11,0,1,9,4,7,8,2,3,11,5,10,6,9,2,1,9,11,2,9,4,11,7,11,4,5,10,6,8,4,7,3,11,5,3,5,1,5,11,6,5,1,11,5,11,6,1,0,11,7,11,4,0,4,11,0,5,9,0,6,5,0,3,6,11,6,3,8,4,7,6,5,9,6,9,11,4,7,9,7,11,9,10,4,9,6,4,10,4,10,6,4,9,10,0,8,3,10,0,1,10,6,0,6,4,0,8,3,1,8,1,6,8,6,4,6,1,10,1,4,9,1,2,4,2,6,4,3,0,8,1,2,9,2,4,9,2,6,4,0,2,4,4,2,6,8,3,2,8,2,4,4,2,6,10,4,9,10,6,4,11,2,3,0,8,2,2,8,11,4,9,10,4,10,6,3,11,2,0,1,6,0,6,4,6,1,10,6,4,1,6,1,10,4,8,1,2,1,11,8,11,1,9,6,4,9,3,6,9,1,3,11,6,3,8,11,1,8,1,0,11,6,1,9,1,4,6,4,1,3,11,6,3,6,0,0,6,4,6,4,8,11,6,8,7,10,6,7,8,10,8,9,10,0,7,3,0,10,7,0,9,10,6,7,10,10,6,7,1,10,7,1,7,8,1,8,0,10,6,7,10,7,1,1,7,3,1,2,6,1,6,8,1,8,9,8,6,7,2,6,9,2,9,1,6,7,9,0,9,3,7,3,9,7,8,0,7,0,6,6,0,2,7,3,2,6,7,2,2,3,11,10,6,8,10,8,9,8,6,7,2,0,7,2,7,11,0,9,7,6,7,10,9,10,7,1,8,0,1,7,8,1,10,7,6,7,10,2,3,11,11,2,1,11,1,7,10,6,1,6,7,1,8,9,6,8,6,7,9,1,6,11,6,3,1,3,6,0,9,1,11,6,7,7,8,0,7,0,6,3,11,0,11,6,0,7,11,6,7,6,11,3,0,8,11,7,6,0,1,9,11,7,6,8,1,9,8,3,1,11,7,6,10,1,2,6,11,7,1,2,10,3,0,8,6,11,7,2,9,0,2,10,9,6,11,7,6,11,7,2,10,3,10,8,3,10,9,8,7,2,3,6,2,7,7,0,8,7,6,0,6,2,0,2,7,6,2,3,7,0,1,9,1,6,2,1,8,6,1,9,8,8,7,6,10,7,6,10,1,7,1,3,7,10,7,6,1,7,10,1,8,7,1,0,8,0,3,7,0,7,10,0,10,9,6,10,7,7,6,10,7,10,8,8,10,9,6,8,4,11,8,6,3,6,11,3,0,6,0,4,6,8,6,11,8,4,6,9,0,1,9,4,6,9,6,3,9,3,1,11,3,6,6,8,4,6,11,8,2,10,1,1,2,10,3,0,11,0,6,11,0,4,6,4,11,8,4,6,11,0,2,9,2,10,9,10,9,3,10,3,2,9,4,3,11,3,6,4,6,3,8,2,3,8,4,2,4,6,2,0,4,2,4,6,2,1,9,0,2,3,4,2,4,6,4,3,8,1,9,4,1,4,2,2,4,6,8,1,3,8,6,1,8,4,6,6,10,1,10,1,0,10,0,6,6,0,4,4,6,3,4,3,8,6,10,3,0,3,9,10,9,3,10,9,4,6,10,4,4,9,5,7,6,11,0,8,3,4,9,5,11,7,6,5,0,1,5,4,0,7,6,11,11,7,6,8,3,4,3,5,4,3,1,5,9,5,4,10,1,2,7,6,11,6,11,7,1,2,10,0,8,3,4,9,5,7,6,11,5,4,10,4,2,10,4,0,2,3,4,8,3,5,4,3,2,5,10,5,2,11,7,6,7,2,3,7,6,2,5,4,9,9,5,4,0,8,6,0,6,2,6,8,7,3,6,2,3,7,6,1,5,0,5,4,0,6,2,8,6,8,7,2,1,8,4,8,5,1,5,8,9,5,4,10,1,6,1,7,6,1,3,7,1,6,10,1,7,6,1,0,7,8,7,0,9,5,4,4,0,10,4,10,5,0,3,10,6,10,7,3,7,10,7,6,10,7,10,8,5,4,10,4,8,10,6,9,5,6,11,9,11,8,9,3,6,11,0,6,3,0,5,6,0,9,5,0,11,8,0,5,11,0,1,5,5,6,11,6,11,3,6,3,5,5,3,1,1,2,10,9,5,11,9,11,8,11,5,6,0,11,3,0,6,11,0,9,6,5,6,9,1,2,10,11,8,5,11,5,6,8,0,5,10,5,2,0,2,5,6,11,3,6,3,5,2,10,3,10,5,3,5,8,9,5,2,8,5,6,2,3,8,2,9,5,6,9,6,0,0,6,2,1,5,8,1,8,0,5,6,8,3,8,2,6,2,8,1,5,6,2,1,6,1,3,6,1,6,10,3,8,6,5,6,9,8,9,6,10,1,0,10,0,6,9,5,0,5,6,0,0,3,8,5,6,10,10,5,6,11,5,10,7,5,11,11,5,10,11,7,5,8,3,0,5,11,7,5,10,11,1,9,0,10,7,5,10,11,7,9,8,1,8,3,1,11,1,2,11,7,1,7,5,1,0,8,3,1,2,7,1,7,5,7,2,11,9,7,5,9,2,7,9,0,2,2,11,7,7,5,2,7,2,11,5,9,2,3,2,8,9,8,2,2,5,10,2,3,5,3,7,5,8,2,0,8,5,2,8,7,5,10,2,5,9,0,1,5,10,3,5,3,7,3,10,2,9,8,2,9,2,1,8,7,2,10,2,5,7,5,2,1,3,5,3,7,5,0,8,7,0,7,1,1,7,5,9,0,3,9,3,5,5,3,7,9,8,7,5,9,7,5,8,4,5,10,8,10,11,8,5,0,4,5,11,0,5,10,11,11,3,0,0,1,9,8,4,10,8,10,11,10,4,5,10,11,4,10,4,5,11,3,4,9,4,1,3,1,4,2,5,1,2,8,5,2,11,8,4,5,8,0,4,11,0,11,3,4,5,11,2,11,1,5,1,11,0,2,5,0,5,9,2,11,5,4,5,8,11,8,5,9,4,5,2,11,3,2,5,10,3,5,2,3,4,5,3,8,4,5,10,2,5,2,4,4,2,0,3,10,2,3,5,10,3,8,5,4,5,8,0,1,9,5,10,2,5,2,4,1,9,2,9,4,2,8,4,5,8,5,3,3,5,1,0,4,5,1,0,5,8,4,5,8,5,3,9,0,5,0,3,5,9,4,5,4,11,7,4,9,11,9,10,11,0,8,3,4,9,7,9,11,7,9,10,11,1,10,11,1,11,4,1,4,0,7,4,11,3,1,4,3,4,8,1,10,4,7,4,11,10,11,4,4,11,7,9,11,4,9,2,11,9,1,2,9,7,4,9,11,7,9,1,11,2,11,1,0,8,3,11,7,4,11,4,2,2,4,0,11,7,4,11,4,2,8,3,4,3,2,4,2,9,10,2,7,9,2,3,7,7,4,9,9,10,7,9,7,4,10,2,7,8,7,0,2,0,7,3,7,10,3,10,2,7,4,10,1,10,0,4,0,10,1,10,2,8,7,4,4,9,1,4,1,7,7,1,3,4,9,1,4,1,7,0,8,1,8,7,1,4,0,3,7,4,3,4,8,7,9,10,8,10,11,8,3,0,9,3,9,11,11,9,10,0,1,10,0,10,8,8,10,11,3,1,10,11,3,10,1,2,11,1,11,9,9,11,8,3,0,9,3,9,11,1,2,9,2,11,9,0,2,11,8,0,11,3,2,11,2,3,8,2,8,10,10,8,9,9,10,2,0,9,2,2,3,8,2,8,10,0,1,8,1,10,8,1,10,2,1,3,8,9,1,8,0,9,1,0,3,8"
	
	var index_strings = lut_string.split(',')
	var indices = []
	for s in index_strings:
		if s.strip_edges() != "":
			indices.append(int(s))
	
	print("%s: Using embedded LUT data (%d indices)" % [get_class_name(), indices.size()])
	return indices

func _create_collision() -> void:
	"""Create collision shape for the terrain mesh"""
	if not array_mesh or array_mesh.get_surface_count() == 0:
		print("⚠️ Cannot create collision: No mesh surface available")
		return
	
	# Check if parent is a RigidBody3D (e.g., XRToolsPickable)
	var parent_node = get_parent()
	if parent_node is RigidBody3D:
		print("TerrainGeneratorBase: Parent is RigidBody3D, attaching collision shape to parent.")
		
		# Find or create CollisionShape3D on parent
		var collision_node = parent_node.find_child("CollisionShape3D", false)
		if not collision_node:
			collision_node = CollisionShape3D.new()
			collision_node.name = "CollisionShape3D"
			parent_node.add_child(collision_node)
			if parent_node.owner:
				collision_node.owner = parent_node.owner
		
		# For RigidBodies, creating a Convex Hull from a complex MC mesh is too slow (causes freeze).
		# Instead, we use a simple Bounding Box (AABB) which is instant and stable.
		var aabb = array_mesh.get_aabb()
		var center = aabb.position + (aabb.size / 2.0)
		
		# RE-CENTER VISUALS:
		# Move the mesh instance (self) so that its visual center aligns with the RigidBody origin (0,0,0).
		# This ensures that when you grab the object, you grab it by its center.
		self.position = -center
		
		var shape = BoxShape3D.new()
		shape.size = aabb.size * 0.9 # Shrink slightly to avoid snagging
		
		collision_node.shape = shape
		# Collision shape is centered on RigidBody origin (0,0,0), which now matches the visual center.
		collision_node.position = Vector3.ZERO
		
		# --- DEBUG VISUALIZATION ---
		# Add a visible box so user can see the grab volume
		var debug_mesh = MeshInstance3D.new()
		debug_mesh.name = "DebugGrabBox"
		var box = BoxMesh.new()
		box.size = aabb.size * 0.9
		debug_mesh.mesh = box
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.0, 0.0, 0.3) # Transparent Red
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		debug_mesh.material_override = mat
		
		parent_node.add_child(debug_mesh)
		if parent_node.owner: debug_mesh.owner = parent_node.owner
		# ---------------------------
		
		print("✅ Created FAST Box collision shape for Pickable (Size: %s) and Re-Centered Object." % str(shape.size))
		return

	# Standard StaticBody3D logic for static placement
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
	# Safety check: Don't generate collision for extremely complex meshes to avoid physics crashes
	if num_triangles > 30000:
		print("⚠️ Skipping collision generation for high-polygon mesh (%d triangles)" % num_triangles)
		return

	var shape = array_mesh.create_trimesh_shape()
	if shape:
		collision_shape.shape = shape
		print("✅ Collision shape created with %d triangles" % [shape.get_faces().size() / 3])
	else:
		push_error("❌ Failed to create trimesh collision shape")
	
func _notification(type):
	if type == NOTIFICATION_PREDELETE:
		release()

func release() -> void:
	# Re-entrant guard: PREDELETE can fire alongside other teardown paths, and a second
	# pass over an already-freed device/RIDs segfaults.
	if _released:
		return
	_released = true

	# Stop the per-frame loop so _process can't touch a half-freed device mid-teardown.
	waiting_for_meshthread = false
	set_process(false)

	# Join the mesh-processing worker before freeing anything it reads.
	if thread and thread.is_started():
		thread.wait_to_finish()
	thread = null

	if rendering_device:
		# CRITICAL: a compute dispatch may still be in flight (run_compute() submits but only
		# syncs ~12 frames later). Freeing buffers / the device with pending GPU work is the
		# segfault seen when these artifacts are freed mid-generation (e.g. queue_free during a
		# map's re-curate). Flush it first. sync() must be paired with the prior submit().
		if waiting_for_compute:
			rendering_device.sync()
			waiting_for_compute = false

		# Free in dependency order — the uniform set + pipeline before the buffers/shader they
		# reference — and guard each RID so a partially-initialised device tears down cleanly.
		# buffer_set was previously leaked; a dangling set over freed buffers is itself a crash risk.
		if buffer_set.is_valid(): rendering_device.free_rid(buffer_set)
		if pipeline.is_valid(): rendering_device.free_rid(pipeline)
		if triangle_buffer.is_valid(): rendering_device.free_rid(triangle_buffer)
		if params_buffer.is_valid(): rendering_device.free_rid(params_buffer)
		if counter_buffer.is_valid(): rendering_device.free_rid(counter_buffer)
		if lut_buffer.is_valid(): rendering_device.free_rid(lut_buffer)
		_free_extra_rids()  # subclass-owned buffers, freed after the sync above (crash-safe)
		if shader.is_valid(): rendering_device.free_rid(shader)

		buffer_set = RID()
		pipeline = RID()
		triangle_buffer = RID()
		params_buffer = RID()
		counter_buffer = RID()
		lut_buffer = RID()
		shader = RID()

		rendering_device.free()
		rendering_device = null

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
