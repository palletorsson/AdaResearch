# MetaballGenerator.gd
# Procedural metaball system using marching cubes algorithm
extends Node3D
class_name MetaballGenerator

@export var grid_size: Vector3i = Vector3i(64, 32, 64)
@export var cell_size: float = 0.5
@export var iso_level: float = 1.0
@export var metaball_count: int = 8
@export var animation_speed: float = 0.5
@export var generate_on_ready: bool = true
@export var max_steps: int = 5  # Stop after this many steps (0 = unlimited)
@export var step_duration: float = 0.4  # Seconds per step

# Shader to apply to the metaball surface
@export var surface_shader: Shader

# Step state
var current_step: int = 0
var stepping: bool = false
var step_timer: float = 0.0
var is_stopped: bool = false

# Metaball properties
var metaballs: Array[Metaball] = []
var field_values: PackedFloat32Array = []
var mesh_instance: MeshInstance3D
var array_mesh: ArrayMesh  # Reused across frames
var collision_shape: CollisionShape3D
var static_body: StaticBody3D

# Pre-computed grid world positions (avoids recomputing every frame)
var grid_positions_x: PackedFloat32Array = []
var grid_positions_y: PackedFloat32Array = []
var grid_positions_z: PackedFloat32Array = []

# Per-metaball max influence distance squared (for culling)
var influence_radius_sq: PackedFloat32Array = []

# Marching cubes lookup tables
var edge_table: PackedInt32Array
var tri_table: Array[PackedInt32Array]

# Bourke offsets as flat array for speed
var bourke_x: PackedInt32Array = PackedInt32Array([0,1,1,0,0,1,1,0])
var bourke_y: PackedInt32Array = PackedInt32Array([0,0,1,1,0,0,1,1])
var bourke_z: PackedInt32Array = PackedInt32Array([0,0,0,0,1,1,1,1])

# Edge vertex pairs (flat)
var edge_v1: PackedInt32Array = PackedInt32Array([0,1,2,3,4,5,6,7,0,1,2,3])
var edge_v2: PackedInt32Array = PackedInt32Array([1,2,3,0,5,6,7,4,4,5,6,7])

# Performance tracking
var generation_time: float = 0.0

class Metaball:
	var position: Vector3
	var strength: float
	var radius: float
	var target_strength: float
	var animation_phase: float
	# Lava lamp: mainly vertical motion with slight horizontal drift
	var rise_speed: float
	var drift_freq_x: float
	var drift_freq_z: float
	var drift_amount: float
	var phase_offset: float
	
	func _init(pos: Vector3, str: float, rad: float) -> void:
		position = pos
		strength = str
		target_strength = str
		radius = rad
		animation_phase = randf() * TAU
		# Vertical bobbing at different speeds
		rise_speed = randf_range(0.3, 0.8)
		# Small horizontal drift
		drift_freq_x = randf_range(0.5, 1.5)
		drift_freq_z = randf_range(0.5, 1.5)
		drift_amount = randf_range(0.3, 0.7)
		phase_offset = randf() * TAU
	
	func get_field_value(point: Vector3) -> float:
		var dist_sq = position.distance_squared_to(point)
		if dist_sq < 0.0001:
			return strength * 10000.0
		return strength * radius * radius / dist_sq
	
	func update(delta: float, bounds: Vector3) -> void:
		animation_phase += delta
		
		# Vertical: full height bobbing like a lava lamp
		var target_y = bounds.y * 0.8 * sin(animation_phase * rise_speed + phase_offset)
		# Horizontal: small gentle drift
		var target_x = bounds.x * drift_amount * sin(animation_phase * drift_freq_x + phase_offset)
		var target_z = bounds.z * drift_amount * cos(animation_phase * drift_freq_z + phase_offset * 1.3)
		
		var target_pos = Vector3(target_x, target_y, target_z)
		position = position.lerp(target_pos, delta * 2.5)
		
		# Gentle strength pulsing
		strength = target_strength * (0.92 + 0.08 * sin(animation_phase * 0.6 + phase_offset))

func _ready() -> void:
	setup_marching_cubes_tables()
	_precompute_grid_positions()
	setup_scene()
	
	if generate_on_ready:
		generate_metaballs()
		generate_mesh()
		# Auto-start stepping
		if max_steps > 0:
			start_stepping()

func _precompute_grid_positions() -> void:
	# Pre-compute axis positions once — no per-frame math for grid coords
	grid_positions_x.resize(grid_size.x)
	grid_positions_y.resize(grid_size.y)
	grid_positions_z.resize(grid_size.z)
	var half_x = grid_size.x * 0.5
	var half_y = grid_size.y * 0.5
	var half_z = grid_size.z * 0.5
	for i in grid_size.x:
		grid_positions_x[i] = (i - half_x) * cell_size
	for i in grid_size.y:
		grid_positions_y[i] = (i - half_y) * cell_size
	for i in grid_size.z:
		grid_positions_z[i] = (i - half_z) * cell_size

func setup_scene() -> void:
	# Create mesh instance with reusable ArrayMesh
	mesh_instance = MeshInstance3D.new()
	array_mesh = ArrayMesh.new()
	mesh_instance.mesh = array_mesh
	add_child(mesh_instance)
	
	# Use the pink shader if assigned, otherwise fallback to standard material
	if surface_shader:
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = surface_shader
		mesh_instance.material_override = shader_mat
	else:
		# Try loading PinkTeleport shader by default
		var pink_shader = load("res://commons/resourses/shaders/PinkTeleport.gdshader")
		if pink_shader:
			var shader_mat = ShaderMaterial.new()
			shader_mat.shader = pink_shader
			mesh_instance.material_override = shader_mat
		else:
			# Fallback: glossy organic material
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.15, 0.55, 0.85)
			material.metallic = 0.3
			material.roughness = 0.25
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			material.rim_enabled = true
			material.rim = 0.3
			material.rim_tint = 0.4
			mesh_instance.material_override = material

func generate_metaballs() -> void:
	metaballs.clear()
	influence_radius_sq.clear()
	var bounds = Vector3(grid_size) * cell_size * 0.5
	
	# Small balls distributed vertically through the column
	for i in metaball_count:
		var y_frac = float(i) / float(metaball_count) * 2.0 - 1.0
		var pos = Vector3(
			randf_range(-bounds.x * 0.3, bounds.x * 0.3),
			bounds.y * y_frac * 0.7,
			randf_range(-bounds.z * 0.3, bounds.z * 0.3)
		)
		
		var strength = randf_range(0.7, 1.0)
		var radius = randf_range(0.35, 0.55)
		metaballs.append(Metaball.new(pos, strength, radius))
	
	_update_influence_radii()

func _update_influence_radii() -> void:
	# Max distance where a metaball's field > min_threshold
	# Beyond this, the contribution is negligible
	var min_threshold = iso_level * 0.05  # 5% of iso — anything less won't matter
	influence_radius_sq.resize(metaballs.size())
	for i in metaballs.size():
		var mb = metaballs[i]
		# field = strength * r² / d²  →  d = r * sqrt(strength / threshold)
		var max_dist = mb.radius * sqrt(mb.target_strength / min_threshold)
		influence_radius_sq[i] = max_dist * max_dist

func generate_mesh() -> void:
	var start_time = Time.get_ticks_usec()
	var num_metaballs = metaballs.size()
	
	# Cache metaball data into flat arrays for inner-loop speed
	var mb_px: PackedFloat32Array = []
	var mb_py: PackedFloat32Array = []
	var mb_pz: PackedFloat32Array = []
	var mb_sr2: PackedFloat32Array = []  # strength * radius²
	mb_px.resize(num_metaballs)
	mb_py.resize(num_metaballs)
	mb_pz.resize(num_metaballs)
	mb_sr2.resize(num_metaballs)
	for i in num_metaballs:
		var mb = metaballs[i]
		mb_px[i] = mb.position.x
		mb_py[i] = mb.position.y
		mb_pz[i] = mb.position.z
		mb_sr2[i] = mb.strength * mb.radius * mb.radius
	
	# Calculate field values with influence-radius culling
	var total_points = grid_size.x * grid_size.y * grid_size.z
	if field_values.size() != total_points:
		field_values.resize(total_points)
	
	var sx = grid_size.x
	var sy = grid_size.y
	var stride_y = sx
	var stride_z = sx * sy
	
	var index = 0
	for z in grid_size.z:
		var wz = grid_positions_z[z]
		for y in grid_size.y:
			var wy = grid_positions_y[y]
			for x in grid_size.x:
				var wx = grid_positions_x[x]
				var total_field = 0.0
				for m in num_metaballs:
					var dx = wx - mb_px[m]
					var dy = wy - mb_py[m]
					var dz = wz - mb_pz[m]
					var dist_sq = dx * dx + dy * dy + dz * dz
					if dist_sq < influence_radius_sq[m]:
						if dist_sq < 0.0001:
							total_field += mb_sr2[m] * 10000.0
						else:
							total_field += mb_sr2[m] / dist_sq
				field_values[index] = total_field
				index += 1
	
	# --- Marching cubes pass ---
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	for z in range(grid_size.z - 1):
		for y in range(grid_size.y - 1):
			for x in range(grid_size.x - 1):
				_march_cube_fast(x, y, z, stride_y, stride_z, vertices, normals, indices)
	
	# Reuse ArrayMesh — clear old surface, add new
	array_mesh.clear_surfaces()
	if vertices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	generation_time = (Time.get_ticks_usec() - start_time) / 1000.0

func _march_cube_fast(x: int, y: int, z: int, stride_y: int, stride_z: int, vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> void:
	# Inline field lookups — no function call overhead, no Vector3i allocations
	var base_idx = z * stride_z + y * stride_y + x
	var cv0 = field_values[base_idx]
	var cv1 = field_values[base_idx + 1]
	var cv2 = field_values[base_idx + stride_y + 1]
	var cv3 = field_values[base_idx + stride_y]
	var cv4 = field_values[base_idx + stride_z]
	var cv5 = field_values[base_idx + stride_z + 1]
	var cv6 = field_values[base_idx + stride_z + stride_y + 1]
	var cv7 = field_values[base_idx + stride_z + stride_y]
	
	# Cube index
	var cube_index = 0
	if cv0 > iso_level: cube_index |= 1
	if cv1 > iso_level: cube_index |= 2
	if cv2 > iso_level: cube_index |= 4
	if cv3 > iso_level: cube_index |= 8
	if cv4 > iso_level: cube_index |= 16
	if cv5 > iso_level: cube_index |= 32
	if cv6 > iso_level: cube_index |= 64
	if cv7 > iso_level: cube_index |= 128
	
	if cube_index == 0 or cube_index == 255:
		return
	
	# Corner world positions from precomputed axes
	var px0 = grid_positions_x[x]
	var px1 = grid_positions_x[x + 1]
	var py0 = grid_positions_y[y]
	var py1 = grid_positions_y[y + 1]
	var pz0 = grid_positions_z[z]
	var pz1 = grid_positions_z[z + 1]
	
	# Pack corners: pos + value (avoid PackedVector3Array allocation)
	var cp_x = PackedFloat32Array([px0,px1,px1,px0,px0,px1,px1,px0])
	var cp_y = PackedFloat32Array([py0,py0,py1,py1,py0,py0,py1,py1])
	var cp_z = PackedFloat32Array([pz0,pz0,pz0,pz0,pz1,pz1,pz1,pz1])
	var cv = PackedFloat32Array([cv0,cv1,cv2,cv3,cv4,cv5,cv6,cv7])
	
	# Edge intersections
	var ev_x = PackedFloat32Array()
	var ev_y = PackedFloat32Array()
	var ev_z = PackedFloat32Array()
	ev_x.resize(12); ev_y.resize(12); ev_z.resize(12)
	
	var edges = edge_table[cube_index]
	for i in 12:
		if edges & (1 << i):
			var a = edge_v1[i]
			var b = edge_v2[i]
			var val_a = cv[a]
			var val_b = cv[b]
			var t = clampf((iso_level - val_a) / (val_b - val_a), 0.0, 1.0)
			ev_x[i] = cp_x[a] + t * (cp_x[b] - cp_x[a])
			ev_y[i] = cp_y[a] + t * (cp_y[b] - cp_y[a])
			ev_z[i] = cp_z[a] + t * (cp_z[b] - cp_z[a])
	
	# Triangles
	var tri_cfg = tri_table[cube_index]
	var base = vertices.size()
	
	var ti = 0
	while ti < tri_cfg.size():
		var e0 = tri_cfg[ti]
		if e0 == -1:
			break
		var e1 = tri_cfg[ti + 1]
		var e2 = tri_cfg[ti + 2]
		
		var v1 = Vector3(ev_x[e0], ev_y[e0], ev_z[e0])
		var v2 = Vector3(ev_x[e1], ev_y[e1], ev_z[e1])
		var v3 = Vector3(ev_x[e2], ev_y[e2], ev_z[e2])
		
		vertices.append(v1)
		vertices.append(v2)
		vertices.append(v3)
		
		var normal = (v2 - v1).cross(v3 - v1).normalized()
		normals.append(normal)
		normals.append(normal)
		normals.append(normal)
		
		indices.append(base)
		indices.append(base + 1)
		indices.append(base + 2)
		base += 3
		ti += 3

var regen_timer: float = 0.0
var regen_interval: float = 0.2
const REGEN_MIN: float = 0.1
const REGEN_MAX: float = 0.5
const TIME_BUDGET_MS: float = 15.0

func _process(delta: float) -> void:
	if metaballs.size() == 0 or is_stopped:
		return
	
	if not stepping:
		return
	
	# Accumulate time for this step
	step_timer += delta
	
	# During a step: animate metaballs smoothly
	var bounds = Vector3(grid_size) * cell_size * 0.5
	for metaball in metaballs:
		metaball.update(delta * animation_speed, bounds)
	
	# Regenerate mesh
	regen_timer += delta
	if regen_timer >= regen_interval:
		regen_timer = 0.0
		generate_mesh()
		if generation_time > TIME_BUDGET_MS * 1.5:
			regen_interval = minf(regen_interval * 1.3, REGEN_MAX)
		elif generation_time < TIME_BUDGET_MS * 0.5:
			regen_interval = maxf(regen_interval * 0.85, REGEN_MIN)
	
	# Check if this step is complete
	if step_timer >= step_duration:
		step_timer = 0.0
		current_step += 1
		# Final mesh regen at step boundary for clean state
		generate_mesh()
		print("Metaball step %d/%d complete" % [current_step, max_steps])
		
		if max_steps > 0 and current_step >= max_steps:
			stepping = false
			is_stopped = true
			print("Metaball simulation stopped after %d steps" % max_steps)

# --- Public step API (for future player interface) ---

func start_stepping() -> void:
	"""Begin stepping. Resets step counter."""
	current_step = 0
	stepping = true
	is_stopped = false
	step_timer = 0.0
	print("Metaball stepping started (max %d steps)" % max_steps)

func do_single_step() -> void:
	"""Execute one step on demand (for player button)."""
	if metaballs.size() == 0:
		return
	var bounds = Vector3(grid_size) * cell_size * 0.5
	# Advance each metaball by one step_duration worth of time
	for metaball in metaballs:
		metaball.update(step_duration * animation_speed, bounds)
	generate_mesh()
	current_step += 1
	print("Metaball manual step %d" % current_step)

func reset_simulation() -> void:
	"""Reset metaballs to fresh random positions."""
	current_step = 0
	stepping = false
	is_stopped = false
	step_timer = 0.0
	generate_metaballs()
	generate_mesh()

func get_step_count() -> int:
	return current_step

func is_simulation_stopped() -> bool:
	return is_stopped

# Marching cubes lookup tables setup — complete Paul Bourke tables
func setup_marching_cubes_tables() -> void:
	edge_table = PackedInt32Array([
		0x0,0x109,0x203,0x30a,0x406,0x50f,0x605,0x70c,0x80c,0x905,0xa0f,0xb06,0xc0a,0xd03,0xe09,0xf00,
		0x190,0x99,0x393,0x29a,0x596,0x49f,0x795,0x69c,0x99c,0x895,0xb9f,0xa96,0xd9a,0xc93,0xf99,0xe90,
		0x230,0x339,0x33,0x13a,0x636,0x73f,0x435,0x53c,0xa3c,0xb35,0x83f,0x936,0xe3a,0xf33,0xc39,0xd30,
		0x3a0,0x2a9,0x1a3,0xaa,0x7a6,0x6af,0x5a5,0x4ac,0xbac,0xaa5,0x9af,0x8a6,0xfaa,0xea3,0xda9,0xca0,
		0x460,0x569,0x663,0x76a,0x66,0x16f,0x265,0x36c,0xc6c,0xd65,0xe6f,0xf66,0x86a,0x963,0xa69,0xb60,
		0x5f0,0x4f9,0x7f3,0x6fa,0x1f6,0xff,0x3f5,0x2fc,0xdfc,0xcf5,0xfff,0xef6,0x9fa,0x8f3,0xbf9,0xaf0,
		0x650,0x759,0x453,0x55a,0x256,0x35f,0x55,0x15c,0xe5c,0xf55,0xc5f,0xd56,0xa5a,0xb53,0x859,0x950,
		0x7c0,0x6c9,0x5c3,0x4ca,0x3c6,0x2cf,0x1c5,0xcc,0xfcc,0xec5,0xdcf,0xcc6,0xbca,0xac3,0x9c9,0x8c0,
		0x8c0,0x9c9,0xac3,0xbca,0xcc6,0xdcf,0xec5,0xfcc,0xcc,0x1c5,0x2cf,0x3c6,0x4ca,0x5c3,0x6c9,0x7c0,
		0x950,0x859,0xb53,0xa5a,0xd56,0xc5f,0xf55,0xe5c,0x15c,0x55,0x35f,0x256,0x55a,0x453,0x759,0x650,
		0xaf0,0xbf9,0x8f3,0x9fa,0xef6,0xfff,0xcf5,0xdfc,0x2fc,0x3f5,0xff,0x1f6,0x6fa,0x7f3,0x4f9,0x5f0,
		0xb60,0xa69,0x963,0x86a,0xf66,0xe6f,0xd65,0xc6c,0x36c,0x265,0x16f,0x66,0x76a,0x663,0x569,0x460,
		0xca0,0xda9,0xea3,0xfaa,0x8a6,0x9af,0xaa5,0xbac,0x4ac,0x5a5,0x6af,0x7a6,0xaa,0x1a3,0x2a9,0x3a0,
		0xd30,0xc39,0xf33,0xe3a,0x936,0x83f,0xb35,0xa3c,0x53c,0x435,0x73f,0x636,0x13a,0x33,0x339,0x230,
		0xe90,0xf99,0xc93,0xd9a,0xa96,0xb9f,0x895,0x99c,0x69c,0x795,0x49f,0x596,0x29a,0x393,0x99,0x190,
		0xf00,0xe09,0xd03,0xc0a,0xb06,0xa0f,0x905,0x80c,0x70c,0x605,0x50f,0x406,0x30a,0x203,0x109,0x0
	])

	# Complete triangle table — all 256 cases
	var t = [
		[-1],
		[0,8,3,-1],
		[0,1,9,-1],
		[1,8,3,9,8,1,-1],
		[1,2,10,-1],
		[0,8,3,1,2,10,-1],
		[9,2,10,0,2,9,-1],
		[2,8,3,2,10,8,10,9,8,-1],
		[3,11,2,-1],
		[0,11,2,8,11,0,-1],
		[1,9,0,2,3,11,-1],
		[1,11,2,1,9,11,9,8,11,-1],
		[3,10,1,11,10,3,-1],
		[0,10,1,0,8,10,8,11,10,-1],
		[3,9,0,3,11,9,11,10,9,-1],
		[9,8,10,10,8,11,-1],
		[4,7,8,-1],
		[4,3,0,7,3,4,-1],
		[0,1,9,8,4,7,-1],
		[4,1,9,4,7,1,7,3,1,-1],
		[1,2,10,8,4,7,-1],
		[3,4,7,3,0,4,1,2,10,-1],
		[9,2,10,9,0,2,8,4,7,-1],
		[2,10,9,2,9,7,2,7,3,7,9,4,-1],
		[8,4,7,3,11,2,-1],
		[11,4,7,11,2,4,2,0,4,-1],
		[9,0,1,8,4,7,2,3,11,-1],
		[4,7,11,9,4,11,9,11,2,9,2,1,-1],
		[3,10,1,3,11,10,7,8,4,-1],
		[1,11,10,1,4,11,1,0,4,7,11,4,-1],
		[4,7,8,9,0,11,9,11,10,11,0,3,-1],
		[4,7,11,4,11,9,9,11,10,-1],
		[9,5,4,-1],
		[9,5,4,0,8,3,-1],
		[0,5,4,1,5,0,-1],
		[8,5,4,8,3,5,3,1,5,-1],
		[1,2,10,9,5,4,-1],
		[3,0,8,1,2,10,4,9,5,-1],
		[5,2,10,5,4,2,4,0,2,-1],
		[2,10,5,3,2,5,3,5,4,3,4,8,-1],
		[9,5,4,2,3,11,-1],
		[0,11,2,0,8,11,4,9,5,-1],
		[0,5,4,0,1,5,2,3,11,-1],
		[2,1,5,2,5,8,2,8,11,4,8,5,-1],
		[10,3,11,10,1,3,9,5,4,-1],
		[4,9,5,0,8,1,8,10,1,8,11,10,-1],
		[5,4,0,5,0,11,5,11,10,11,0,3,-1],
		[5,4,8,5,8,10,10,8,11,-1],
		[9,7,8,5,7,9,-1],
		[9,3,0,9,5,3,5,7,3,-1],
		[0,7,8,0,1,7,1,5,7,-1],
		[1,5,3,3,5,7,-1],
		[9,7,8,9,5,7,10,1,2,-1],
		[10,1,2,9,5,0,5,3,0,5,7,3,-1],
		[8,0,2,8,2,5,8,5,7,10,5,2,-1],
		[2,10,5,2,5,3,3,5,7,-1],
		[7,9,5,7,8,9,3,11,2,-1],
		[9,5,7,9,7,2,9,2,0,2,7,11,-1],
		[2,3,11,0,1,8,1,7,8,1,5,7,-1],
		[11,2,1,11,1,7,7,1,5,-1],
		[9,5,8,8,5,7,10,1,3,10,3,11,-1],
		[5,7,0,5,0,9,7,11,0,1,0,10,11,10,0,-1],
		[11,10,0,11,0,3,10,5,0,8,0,7,5,7,0,-1],
		[11,10,5,7,11,5,-1],
		[10,6,5,-1],
		[0,8,3,5,10,6,-1],
		[9,0,1,5,10,6,-1],
		[1,8,3,1,9,8,5,10,6,-1],
		[1,6,5,2,6,1,-1],
		[1,6,5,1,2,6,3,0,8,-1],
		[9,6,5,9,0,6,0,2,6,-1],
		[5,9,8,5,8,2,5,2,6,3,2,8,-1],
		[2,3,11,10,6,5,-1],
		[11,0,8,11,2,0,10,6,5,-1],
		[0,1,9,2,3,11,5,10,6,-1],
		[5,10,6,1,9,2,9,11,2,9,8,11,-1],
		[6,3,11,6,5,3,5,1,3,-1],
		[0,8,11,0,11,5,0,5,1,5,11,6,-1],
		[3,11,6,0,3,6,0,6,5,0,5,9,-1],
		[6,5,9,6,9,11,11,9,8,-1],
		[5,10,6,4,7,8,-1],
		[4,3,0,4,7,3,6,5,10,-1],
		[1,9,0,5,10,6,8,4,7,-1],
		[10,6,5,1,9,7,1,7,3,7,9,4,-1],
		[6,1,2,6,5,1,4,7,8,-1],
		[1,2,5,5,2,6,3,0,4,3,4,7,-1],
		[8,4,7,9,0,5,0,6,5,0,2,6,-1],
		[7,3,9,7,9,4,3,2,9,5,9,6,2,6,9,-1],
		[3,11,2,7,8,4,10,6,5,-1],
		[5,10,6,4,7,2,4,2,0,2,7,11,-1],
		[0,1,9,4,7,8,2,3,11,5,10,6,-1],
		[9,2,1,9,11,2,9,4,11,7,11,4,5,10,6,-1],
		[8,4,7,3,11,5,3,5,1,5,11,6,-1],
		[5,1,11,5,11,6,1,0,11,7,11,4,0,4,11,-1],
		[0,5,9,0,6,5,0,3,6,11,6,3,8,4,7,-1],
		[6,5,9,6,9,11,4,7,9,7,11,9,-1],
		[10,4,9,6,4,10,-1],
		[4,10,6,4,9,10,0,8,3,-1],
		[10,0,1,10,6,0,6,4,0,-1],
		[8,3,1,8,1,6,8,6,4,6,1,10,-1],
		[1,4,9,1,2,4,2,6,4,-1],
		[3,0,8,1,2,9,2,4,9,2,6,4,-1],
		[0,2,4,4,2,6,-1],
		[8,3,2,8,2,4,4,2,6,-1],
		[10,4,9,10,6,4,11,2,3,-1],
		[0,8,2,2,8,11,4,9,10,4,10,6,-1],
		[3,11,2,0,1,6,0,6,4,6,1,10,-1],
		[6,4,1,6,1,10,4,8,1,2,1,11,8,11,1,-1],
		[9,6,4,9,3,6,9,1,3,11,6,3,-1],
		[8,11,1,8,1,0,11,6,1,9,1,4,6,4,1,-1],
		[3,11,6,3,6,0,0,6,4,-1],
		[6,4,8,11,6,8,-1],
		[7,10,6,7,8,10,8,9,10,-1],
		[0,7,3,0,10,7,0,9,10,6,7,10,-1],
		[10,6,7,1,10,7,1,7,8,1,8,0,-1],
		[10,6,7,10,7,1,1,7,3,-1],
		[1,2,6,1,6,8,1,8,9,8,6,7,-1],
		[2,6,9,2,9,1,6,7,9,0,9,3,7,3,9,-1],
		[7,8,0,7,0,6,6,0,2,-1],
		[7,3,2,6,7,2,-1],
		[2,3,11,10,6,8,10,8,9,8,6,7,-1],
		[2,0,7,2,7,11,0,9,7,6,7,10,9,10,7,-1],
		[1,8,0,1,7,8,1,10,7,6,7,10,2,3,11,-1],
		[11,2,1,11,1,7,10,6,1,6,7,1,-1],
		[8,9,6,8,6,7,9,1,6,11,6,3,1,3,6,-1],
		[0,9,1,11,6,7,-1],
		[7,8,0,7,0,6,3,11,0,11,6,0,-1],
		[7,11,6,-1],
		[7,6,11,-1],
		[3,0,8,11,7,6,-1],
		[0,1,9,11,7,6,-1],
		[8,1,9,8,3,1,11,7,6,-1],
		[10,1,2,6,11,7,-1],
		[1,2,10,3,0,8,6,11,7,-1],
		[2,9,0,2,10,9,6,11,7,-1],
		[6,11,7,2,10,3,10,8,3,10,9,8,-1],
		[7,2,3,6,2,7,-1],
		[7,0,8,7,6,0,6,2,0,-1],
		[2,7,6,2,3,7,0,1,9,-1],
		[1,6,2,1,8,6,1,9,8,8,7,6,-1],
		[10,7,6,10,1,7,1,3,7,-1],
		[10,7,6,1,7,10,1,8,7,1,0,8,-1],
		[0,3,7,0,7,10,0,10,9,6,10,7,-1],
		[7,6,10,7,10,8,8,10,9,-1],
		[6,8,4,11,8,6,-1],
		[3,6,11,3,0,6,0,4,6,-1],
		[8,6,11,8,4,6,9,0,1,-1],
		[9,4,6,9,6,3,9,3,1,11,3,6,-1],
		[6,8,4,6,11,8,2,10,1,-1],
		[1,2,10,3,0,11,0,6,11,0,4,6,-1],
		[4,11,8,4,6,11,0,2,9,2,10,9,-1],
		[10,9,3,10,3,2,9,4,3,11,3,6,4,6,3,-1],
		[8,2,3,8,4,2,4,6,2,-1],
		[0,4,2,4,6,2,-1],
		[1,9,0,2,3,4,2,4,6,4,3,8,-1],
		[1,9,4,1,4,2,2,4,6,-1],
		[8,1,3,8,6,1,8,4,6,6,10,1,-1],
		[10,1,0,10,0,6,6,0,4,-1],
		[4,6,3,4,3,8,6,10,3,0,3,9,10,9,3,-1],
		[10,9,4,6,10,4,-1],
		[4,9,5,7,6,11,-1],
		[0,8,3,4,9,5,11,7,6,-1],
		[5,0,1,5,4,0,7,6,11,-1],
		[11,7,6,8,3,4,3,5,4,3,1,5,-1],
		[9,5,4,10,1,2,7,6,11,-1],
		[6,11,7,1,2,10,0,8,3,4,9,5,-1],
		[7,6,11,5,4,10,4,2,10,4,0,2,-1],
		[3,4,8,3,5,4,3,2,5,10,5,2,11,7,6,-1],
		[7,2,3,7,6,2,5,4,9,-1],
		[9,5,4,0,8,6,0,6,2,6,8,7,-1],
		[3,6,2,3,7,6,1,5,0,5,4,0,-1],
		[6,2,8,6,8,7,2,1,8,4,8,5,1,5,8,-1],
		[9,5,4,10,1,6,1,7,6,1,3,7,-1],
		[1,6,10,1,7,6,1,0,7,8,7,0,9,5,4,-1],
		[4,0,10,4,10,5,0,3,10,6,10,7,3,7,10,-1],
		[7,6,10,7,10,8,5,4,10,4,8,10,-1],
		[6,9,5,6,11,9,11,8,9,-1],
		[3,6,11,0,6,3,0,5,6,0,9,5,-1],
		[0,11,8,0,5,11,0,1,5,5,6,11,-1],
		[6,11,3,6,3,5,5,3,1,-1],
		[1,2,10,9,5,11,9,11,8,11,5,6,-1],
		[0,11,3,0,6,11,0,9,6,5,6,9,1,2,10,-1],
		[11,8,5,11,5,6,8,0,5,10,5,2,0,2,5,-1],
		[6,11,3,6,3,5,2,10,3,10,5,3,-1],
		[5,8,9,5,2,8,5,6,2,3,8,2,-1],
		[9,5,6,9,6,0,0,6,2,-1],
		[1,5,8,1,8,0,5,6,8,3,8,2,6,2,8,-1],
		[1,5,6,2,1,6,-1],
		[1,3,6,1,6,10,3,8,6,5,6,9,8,9,6,-1],
		[10,1,0,10,0,6,9,5,0,5,6,0,-1],
		[0,3,8,5,6,10,-1],
		[10,5,6,-1],
		[11,5,10,7,5,11,-1],
		[11,5,10,11,7,5,8,3,0,-1],
		[5,11,7,5,10,11,1,9,0,-1],
		[10,7,5,10,11,7,9,8,1,8,3,1,-1],
		[11,1,2,11,7,1,7,5,1,-1],
		[0,8,3,1,2,7,1,7,5,7,2,11,-1],
		[9,7,5,9,2,7,9,0,2,2,11,7,-1],
		[7,5,2,7,2,11,5,9,2,3,2,8,9,8,2,-1],
		[2,5,10,2,3,5,3,7,5,-1],
		[8,2,0,8,5,2,8,7,5,10,2,5,-1],
		[9,0,1,5,10,3,5,3,7,3,10,2,-1],
		[9,8,2,9,2,1,8,7,2,10,2,5,7,5,2,-1],
		[1,3,5,3,7,5,-1],
		[0,8,7,0,7,1,1,7,5,-1],
		[9,0,3,9,3,5,5,3,7,-1],
		[9,8,7,5,9,7,-1],
		[5,8,4,5,10,8,10,11,8,-1],
		[5,0,4,5,11,0,5,10,11,11,3,0,-1],
		[0,1,9,8,4,10,8,10,11,10,4,5,-1],
		[10,11,4,10,4,5,11,3,4,9,4,1,3,1,4,-1],
		[2,5,1,2,8,5,2,11,8,4,5,8,-1],
		[0,4,11,0,11,3,4,5,11,2,11,1,5,1,11,-1],
		[0,2,5,0,5,9,2,11,5,4,5,8,11,8,5,-1],
		[9,4,5,2,11,3,-1],
		[2,5,10,3,5,2,3,4,5,3,8,4,-1],
		[5,10,2,5,2,4,4,2,0,-1],
		[3,10,2,3,5,10,3,8,5,4,5,8,0,1,9,-1],
		[5,10,2,5,2,4,1,9,2,9,4,2,-1],
		[8,4,5,8,5,3,3,5,1,-1],
		[0,4,5,1,0,5,-1],
		[8,4,5,8,5,3,9,0,5,0,3,5,-1],
		[9,4,5,-1],
		[4,11,7,4,9,11,9,10,11,-1],
		[0,8,3,4,9,7,9,11,7,9,10,11,-1],
		[1,10,11,1,11,4,1,4,0,7,4,11,-1],
		[3,1,4,3,4,8,1,10,4,7,4,11,10,11,4,-1],
		[4,11,7,9,11,4,9,2,11,9,1,2,-1],
		[9,7,4,9,11,7,9,1,11,2,11,1,0,8,3,-1],
		[11,7,4,11,4,2,2,4,0,-1],
		[11,7,4,11,4,2,8,3,4,3,2,4,-1],
		[2,9,10,2,7,9,2,3,7,7,4,9,-1],
		[9,10,7,9,7,4,10,2,7,8,7,0,2,0,7,-1],
		[3,7,10,3,10,2,7,4,10,1,10,0,4,0,10,-1],
		[1,10,2,8,7,4,-1],
		[4,9,1,4,1,7,7,1,3,-1],
		[4,9,1,4,1,7,0,8,1,8,7,1,-1],
		[4,0,3,7,4,3,-1],
		[4,8,7,-1],
		[9,10,8,10,11,8,-1],
		[3,0,9,3,9,11,11,9,10,-1],
		[0,1,10,0,10,8,8,10,11,-1],
		[3,1,10,11,3,10,-1],
		[1,2,11,1,11,9,9,11,8,-1],
		[3,0,9,3,9,11,1,2,9,2,11,9,-1],
		[0,2,11,8,0,11,-1],
		[3,2,11,-1],
		[2,3,8,2,8,10,10,8,9,-1],
		[9,10,2,0,9,2,-1],
		[2,3,8,2,8,10,0,1,8,1,10,8,-1],
		[1,10,2,-1],
		[1,3,8,9,1,8,-1],
		[0,9,1,-1],
		[0,3,8,-1],
		[-1]
	]

	tri_table = []
	for i in 256:
		tri_table.append(PackedInt32Array(t[i]))

# Public interface functions
func regenerate() -> void:
	generate_metaballs()
	generate_mesh()

func set_metaball_count(count: int) -> void:
	metaball_count = count
	regenerate()

func set_iso_level(level: float) -> void:
	iso_level = level
	generate_mesh()

func set_animation_speed(speed: float) -> void:
	animation_speed = speed

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
