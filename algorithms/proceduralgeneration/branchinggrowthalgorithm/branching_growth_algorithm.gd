extends Node3D

# Parameters for the SPICY QUEER growth algorithm 🌈✨
@export var max_branches = 500  # More branches for fabulous density!
@export var attraction_distance = 4.0
@export var min_branch_distance = 0.25
@export var growth_distance = 0.2
@export var jitter = 0.15  # More chaos, more queer energy!
@export var attractor_count = 80  # More attraction points!

# 🏳️‍🌈 QUEER VISUAL PARAMETERS 🏳️‍⚧️
@export var branch_material: Material
@export var branch_radius = 0.03
@export var growth_per_frame = 8  # Faster, more dynamic growth
@export var enable_pride_colors = true
@export var enable_sparkles = true
@export var pulse_strength = 0.3
@export var rainbow_speed = 2.0

# Internal variables - arrays with QUEER POWER! 🌈
var branches = []
var attractors = []

# Mesh for visualization
var mesh_instance: MeshInstance3D
var immediate_mesh: ImmediateMesh

# ✨ SPICY QUEER TIMING AND EFFECTS ✨
var growth_timer = 0.0
var is_growing = false
var time_elapsed = 0.0
var current_pride_flag = 0
var color_cycle_timer = 0.0
var pulse_timer = 0.0

# 🏳️‍🌈 PRIDE FLAG COLORS 🏳️‍⚧️
var pride_flags = {
	"rainbow": [Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN, Color.BLUE, Color.PURPLE],
	"trans": [Color(0.33, 0.8, 1.0), Color(0.96, 0.66, 0.73), Color.WHITE, Color(0.96, 0.66, 0.73), Color(0.33, 0.8, 1.0)],
	"lesbian": [Color(0.84, 0.4, 0.0), Color(1.0, 0.6, 0.4), Color.WHITE, Color(0.83, 0.46, 0.65), Color(0.64, 0.2, 0.4)],
	"bi": [Color(0.84, 0.0, 0.5), Color(0.84, 0.0, 0.5), Color(0.4, 0.2, 0.6), Color(0.0, 0.4, 1.0), Color(0.0, 0.4, 1.0)],
	"pan": [Color(1.0, 0.13, 0.54), Color(1.0, 0.85, 0.0), Color(0.13, 0.69, 1.0)],
	"ace": [Color.BLACK, Color(0.64, 0.64, 0.64), Color.WHITE, Color(0.5, 0.0, 0.5)],
	"nonbinary": [Color.YELLOW, Color.WHITE, Color(0.6, 0.4, 0.8), Color.BLACK]
}
var current_flag_name = "rainbow"

class Branch:
	var position: Vector3
	var direction: Vector3
	var parent_index: int = -1
	var is_active: bool = true
	var generation: int = 0
	var birth_time: float = 0.0  # ✨ For sparkly effects!
	var personal_hue: float = 0.0  # 🌈 Each branch gets its own rainbow position!
	
	func _init(pos: Vector3, dir: Vector3, parent: int = -1, gen: int = 0, time: float = 0.0):
		position = pos
		direction = dir.normalized()
		parent_index = parent
		generation = gen
		birth_time = time
		personal_hue = randf()  # Random rainbow position!

class Attractor:
	var position: Vector3
	var is_reached: bool = false
	var sparkle_phase: float = 0.0  # ✨ For twinkling attractors!
	var attractor_hue: float = 0.0  # 🌈 Each attractor gets fabulous colors!
	
	func _init(pos: Vector3):
		position = pos
		sparkle_phase = randf() * PI * 2
		attractor_hue = randf()

func _ready():
	print("Initializing VR Space Colonization...")
	
	# Set up simple mesh for VR performance
	immediate_mesh = ImmediateMesh.new()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = immediate_mesh
	
	# Use unshaded material for VR performance if none provided
	if not branch_material:
		var material = StandardMaterial3D.new()
		material.flags_unshaded = true
		material.vertex_color_use_as_albedo = true
		material.albedo_color = Color.WHITE
		mesh_instance.material_override = material
	else:
		mesh_instance.material_override = branch_material
	
	add_child(mesh_instance)
	
	# Initialize with a FABULOUS starting branch! 🌈
	add_branch(Vector3.ZERO, Vector3.UP, -1, 0, 0.0)
	
	# Generate fewer attractors for VR
	generate_attractors_vr_optimized()
	
	print("Starting growth with ", branches.size(), " branches and ", attractors.size(), " attractors")
	
	# Start growth process
	start_growth()

func add_branch(position: Vector3, direction: Vector3, parent_index: int = -1, generation: int = 0, birth_time: float = 0.0):
	var branch = Branch.new(position, direction, parent_index, generation, birth_time)
	branches.append(branch)

func generate_attractors_vr_optimized():
	attractors.clear()
	
	# Generate attractors in a more controlled pattern for VR
	var radius = 3.0
	
	for i in range(attractor_count):
		# Use spherical coordinates for better distribution
		var theta = randf() * 2.0 * PI
		var phi = acos(1.0 - 2.0 * randf())  # Better sphere distribution
		var r = radius * pow(randf(), 0.33)  # Cube root for volume distribution
		
		var pos = Vector3(
			r * sin(phi) * cos(theta),
			r * sin(phi) * sin(theta),
			r * cos(phi)
		)
		
		# Avoid attractors too close to origin
		if pos.length() > 0.5:
			attractors.append(Attractor.new(pos))

func start_growth():
	is_growing = true
	growth_timer = 0.0

func _process(delta):
	# ✨ ALWAYS UPDATE QUEER TIMERS FOR FABULOUS EFFECTS! ✨
	time_elapsed += delta
	color_cycle_timer += delta * rainbow_speed
	pulse_timer += delta * 4.0  # Heartbeat-like pulsing
	
	# Cycle through pride flags every 10 seconds
	if color_cycle_timer > 10.0:
		color_cycle_timer = 0.0
		var flag_names = pride_flags.keys()
		current_pride_flag = (current_pride_flag + 1) % flag_names.size()
		current_flag_name = flag_names[current_pride_flag]
		print("Switching to ", current_flag_name, " pride colors! 🌈")
	
	if not is_growing:
		return
	
	growth_timer += delta
	
	# Grow branches at a SPICY rate for dynamic experience! 🔥
	if growth_timer > 0.012:  # Faster updates for more fluid growth
		growth_timer = 0.0
		
		# Process only a limited number of branches per frame to avoid blocking
		var processed_count = 0
		var max_process_per_frame = growth_per_frame
		
		for i in range(growth_per_frame):
			if not grow_step():
				is_growing = false
				print("Growth completed with ", branches.size(), " branches")
				break
			processed_count += 1
			
			# Break if we've processed enough for this frame
			if processed_count >= max_process_per_frame:
				break
		
		# Update mesh every frame for smooth VR
		update_mesh_immediate()

func grow_step() -> bool:
	var active_branches_found = false
	var new_branches = []
	var reached_attractors = []
	
	# Process existing branches
	for i in range(branches.size()):
		var branch = branches[i]
		if not branch.is_active:
			continue
		
		active_branches_found = true
		
		# Find closest attractor
		var closest_attractor_index = -1
		var closest_distance = attraction_distance
		
		for j in range(attractors.size()):
			var attractor = attractors[j]
			if attractor.is_reached:
				continue
			
			var distance = branch.position.distance_to(attractor.position)
			if distance < closest_distance:
				closest_distance = distance
				closest_attractor_index = j
		
		# Grow towards attractor
		if closest_attractor_index >= 0:
			var attractor = attractors[closest_attractor_index]
			var direction = (attractor.position - branch.position).normalized()
			
			# Add SPICY QUEER JITTER for organic flow! 🔥
			if jitter > 0:
				# Flowing, wave-like movement
				var wave_offset = sin(time_elapsed * 3.0 + branch.position.length()) * jitter * 0.5
				direction += Vector3(
					randf_range(-jitter, jitter) + wave_offset,
					randf_range(-jitter, jitter) + sin(time_elapsed * 2.0) * jitter * 0.3,
					randf_range(-jitter, jitter) + cos(time_elapsed * 2.5) * jitter * 0.3
				)
				direction = direction.normalized()
			
			# Create new FABULOUS branch! ✨
			var pulsed_distance = growth_distance * (1.0 + sin(pulse_timer) * pulse_strength * 0.5)
			var new_position = branch.position + direction * pulsed_distance
			new_branches.append({
				"position": new_position,
				"direction": direction,
				"parent": i,
				"generation": branch.generation + 1,
				"birth_time": time_elapsed
			})
			
			# Check if attractor is reached
			if closest_distance < min_branch_distance:
				reached_attractors.append(closest_attractor_index)
				branch.is_active = false
		else:
			# No attractors in range
			branch.is_active = false
		
		# Limit branches for VR performance
		if branches.size() >= max_branches:
			is_growing = false
			return false
	
	# Add new QUEER branches! 🌈
	for branch_data in new_branches:
		add_branch(
			branch_data.position,
			branch_data.direction,
			branch_data.parent,
			branch_data.generation,
			branch_data.birth_time
		)
	
	# Mark reached attractors
	for attractor_index in reached_attractors:
		attractors[attractor_index].is_reached = true
	
	return active_branches_found and new_branches.size() > 0

func update_mesh_immediate():
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	# Draw all branches with FABULOUS QUEER COLORS! 🌈✨
	for i in range(branches.size()):
		var branch = branches[i]
		if branch.parent_index >= 0 and branch.parent_index < branches.size():
			var parent = branches[branch.parent_index]
			
			# Get SPICY colors based on current pride flag!
			var color = get_fabulous_color(branch)
			
			# Add sparkle effect for young branches! ✨
			var age = time_elapsed - branch.birth_time
			if age < 2.0 and enable_sparkles:
				var sparkle_intensity = (2.0 - age) / 2.0
				var sparkle = sin(time_elapsed * 10.0 + branch.position.length()) * 0.5 + 0.5
				color = color.lerp(Color.WHITE, sparkle * sparkle_intensity * 0.6)
			
			# Pulsing brightness based on heartbeat! 💖
			var pulse = sin(pulse_timer) * pulse_strength + 1.0
			color = color * pulse
			
			immediate_mesh.surface_set_color(color)
			immediate_mesh.surface_add_vertex(parent.position)
			immediate_mesh.surface_set_color(color)
			immediate_mesh.surface_add_vertex(branch.position)
	
	immediate_mesh.surface_end()

# 🌈 GET FABULOUS PRIDE COLORS! 🌈
func get_fabulous_color(branch: Branch) -> Color:
	if not enable_pride_colors:
		return Color.WHITE
	
	var current_colors = pride_flags[current_flag_name]
	
	# Use branch's personal hue and generation for color selection
	var color_index = int((branch.personal_hue + branch.generation * 0.1) * current_colors.size()) % current_colors.size()
	var base_color = current_colors[color_index]
	
	# Add rainbow cycling effect
	var rainbow_shift = sin(color_cycle_timer + branch.position.x * 0.5) * 0.2
	var hue_shifted = Color.from_hsv(
		base_color.h + rainbow_shift,
		base_color.s,
		base_color.v,
		base_color.a
	)
	
	return hue_shifted

# VR-specific functions
func set_vr_start_point(position: Vector3):
	"""Set new starting point for VR interaction"""
	clear_growth()
	add_branch(position, Vector3.UP, -1, 0)
	generate_attractors_around_point(position)
	start_growth()

func generate_attractors_around_point(center: Vector3, radius: float = 2.0):
	"""Generate attractors around a specific point for VR interaction"""
	attractors.clear()
	
	for i in range(attractor_count):
		var offset = Vector3(
			randf_range(-radius, radius),
			randf_range(-radius, radius),
			randf_range(-radius, radius)
		)
		
		# Ensure minimum distance from center
		if offset.length() < 0.3:
			offset = offset.normalized() * 0.3
		
		attractors.append(Attractor.new(center + offset))

func add_attractor_at_position(position: Vector3):
	"""Add single attractor at VR controller position"""
	attractors.append(Attractor.new(position))

func clear_growth():
	"""Reset the entire growth system"""
	branches.clear()
	attractors.clear()
	is_growing = false
	immediate_mesh.clear_surfaces()

func pause_growth():
	"""Pause growth for VR menu interaction"""
	is_growing = false

func resume_growth():
	"""Resume growth after VR interaction"""
	is_growing = true

func get_growth_stats() -> Dictionary:
	"""Get stats for VR UI display"""
	var active_count = 0
	var reached_count = 0
	
	for branch in branches:
		if branch.is_active:
			active_count += 1
	
	for attractor in attractors:
		if attractor.is_reached:
			reached_count += 1
	
	return {
		"total_branches": branches.size(),
		"active_branches": active_count,
		"total_attractors": attractors.size(),
		"reached_attractors": reached_count,
		"is_growing": is_growing
	}

# Simplified cylinder rendering for VR (optional)
func enable_cylinder_rendering(enable: bool = true):
	"""Enable/disable cylinder rendering - expensive for VR"""
	if not enable:
		return
		
	# Remove line mesh
	mesh_instance.visible = false
	
	# Create simple cylinder instances (limited number for VR)
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = branch_radius
	cylinder_mesh.bottom_radius = branch_radius
	cylinder_mesh.height = 1.0
	
	var instance_count = 0
	for i in range(min(branches.size(), 100)):  # Limit for VR performance
		var branch = branches[i]
		if branch.parent_index >= 0:
			var parent = branches[branch.parent_index]
			
			var cylinder = MeshInstance3D.new()
			cylinder.mesh = cylinder_mesh
			cylinder.material_override = mesh_instance.material_override
			
			# Position and orient cylinder
			var midpoint = (parent.position + branch.position) * 0.5
			var length = parent.position.distance_to(branch.position)
			var direction = (branch.position - parent.position).normalized()
			
			cylinder.position = midpoint
			cylinder.scale.y = length
			
			# Simple orientation
			if direction != Vector3.UP:
				cylinder.look_at(midpoint + direction, Vector3.UP)
				cylinder.rotate_object_local(Vector3.RIGHT, PI * 0.5)
			
			add_child(cylinder)
			instance_count += 1
			
			# Break if too many for VR
			if instance_count > 50:
				break

# 🌈 FABULOUS DEBUG FUNCTIONS! ✨
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				print("Restarting QUEER growth... 🌈")
				clear_growth()
				add_branch(Vector3.ZERO, Vector3.UP, -1, 0, time_elapsed)
				generate_attractors_vr_optimized()
				start_growth()
			KEY_P:
				if is_growing:
					pause_growth()
					print("Growth paused")
				else:
					resume_growth()
					print("Growth resumed")
			KEY_S:
				var stats = get_growth_stats()
				print("SPICY Stats: ", stats, " Flag: ", current_flag_name, " 🌈")
			KEY_C:
				# Cycle pride flags manually
				var flag_names = pride_flags.keys()
				current_pride_flag = (current_pride_flag + 1) % flag_names.size()
				current_flag_name = flag_names[current_pride_flag]
				color_cycle_timer = 0.0
				print("Switched to ", current_flag_name, " colors! 🏳️‍🌈")
			KEY_T:
				# Toggle sparkles
				enable_sparkles = !enable_sparkles
				print("Sparkles: ", "ON ✨" if enable_sparkles else "OFF")
			KEY_Q:
				# Toggle pride colors
				enable_pride_colors = !enable_pride_colors
				print("Pride colors: ", "FABULOUS 🌈" if enable_pride_colors else "Basic")
