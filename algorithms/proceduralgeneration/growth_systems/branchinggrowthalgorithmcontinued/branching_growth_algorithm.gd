extends Node3D

# Parameters for the SPICY QUEER growth algorithm 🌈✨
@export var max_branches = 100  # More branches for fabulous density!
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

# 🌱 CONTINUOUS GROWTH SYSTEM 🌱
@export var continuous_growth = true
@export var growth_phases = true
@export var seasonal_changes = true
@export var branch_lifespan = 30.0  # How long branches stay active
@export var attractor_regeneration_rate = 0.5  # New attractors per second
@export var environmental_influence = true
@export var growth_acceleration = 1.0  # Speed multiplier over time

# Growth phase variables
var current_growth_phase = 0  # 0=rapid, 1=steady, 2=flowering, 3=dormant
var phase_timer = 0.0
var phase_duration = 20.0  # Seconds per phase
var attractor_timer = 0.0
var branch_death_timer = 0.0
var environmental_timer = 0.0

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
	var age: float = 0.0  # 🌱 Branch age for continuous growth
	var energy: float = 1.0  # 🌱 Branch energy level
	var growth_rate: float = 1.0  # 🌱 Individual growth rate
	var is_dying: bool = false  # 🌱 Branch death state
	
	func _init(pos: Vector3, dir: Vector3, parent: int = -1, gen: int = 0, time: float = 0.0) -> void:
		position = pos
		direction = dir.normalized()
		parent_index = parent
		generation = gen
		birth_time = time
		personal_hue = randf()  # Random rainbow position!
		age = 0.0
		energy = 1.0
		growth_rate = randf_range(0.8, 1.2)  # Slight variation in growth rate

class Attractor:
	var position: Vector3
	var is_reached: bool = false
	var sparkle_phase: float = 0.0  # ✨ For twinkling attractors!
	var attractor_hue: float = 0.0  # 🌈 Each attractor gets fabulous colors!
	var age: float = 0.0  # 🌱 Attractor age
	var strength: float = 1.0  # 🌱 Attractor strength
	var is_temporary: bool = false  # 🌱 Temporary attractors for continuous growth
	
	func _init(pos: Vector3, temp: bool = false) -> void:
		position = pos
		sparkle_phase = randf() * PI * 2
		attractor_hue = randf()
		age = 0.0
		strength = randf_range(0.7, 1.3)
		is_temporary = temp

func _ready() -> void:
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

func add_branch(position: Vector3, direction: Vector3, parent_index: int = -1, generation: int = 0, birth_time: float = 0.0) -> void:
	var branch = Branch.new(position, direction, parent_index, generation, birth_time)
	
	# Inherit some properties from parent if available
	if parent_index >= 0 and parent_index < branches.size():
		var parent = branches[parent_index]
		branch.energy = parent.energy * 0.9  # Slightly less energy than parent
		branch.growth_rate = parent.growth_rate * randf_range(0.8, 1.2)  # Some variation
	
	branches.append(branch)

func generate_attractors_vr_optimized() -> void:
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

func start_growth() -> void:
	is_growing = true
	growth_timer = 0.0

func _process(delta: float) -> void:
	# ✨ ALWAYS UPDATE QUEER TIMERS FOR FABULOUS EFFECTS! ✨
	time_elapsed += delta
	color_cycle_timer += delta * rainbow_speed
	pulse_timer += delta * 4.0  # Heartbeat-like pulsing
	
	# 🌱 CONTINUOUS GROWTH SYSTEM UPDATES 🌱
	if continuous_growth:
		update_continuous_growth_system(delta)
	
	# Cycle through pride flags every 10 seconds
	if color_cycle_timer > 10.0:
		color_cycle_timer = 0.0
		var flag_names = pride_flags.keys()
		current_pride_flag = (current_pride_flag + 1) % flag_names.size()
		current_flag_name = flag_names[current_pride_flag]
		print("Switching to ", current_flag_name, " pride colors! 🌈")
	
	# Always keep growing if continuous growth is enabled
	if continuous_growth:
		is_growing = true
	
	if not is_growing:
		return
	
	growth_timer += delta
	
	# Grow branches at a SPICY rate for dynamic experience! 🔥
	if growth_timer > 0.012:  # Faster updates for more fluid growth
		growth_timer = 0.0
		
		# Process only a limited number of branches per frame to avoid blocking
		var processed_count = 0
		var max_process_per_frame = int(growth_per_frame * growth_acceleration)
		
		for i in range(max_process_per_frame):
			if not grow_step():
				if not continuous_growth:
					is_growing = false
					print("Growth completed with ", branches.size(), " branches")
				break
			processed_count += 1
			
			# Break if we've processed enough for this frame
			if processed_count >= max_process_per_frame:
				break
		
		# Update mesh every frame for smooth VR
		update_mesh_immediate()

func update_continuous_growth_system(delta: float) -> void:
	"""Update the continuous growth system with phases, aging, and environmental effects"""
	# Update timers
	phase_timer += delta
	attractor_timer += delta
	branch_death_timer += delta
	environmental_timer += delta
	
	# Update growth phases
	if growth_phases:
		update_growth_phases()
	
	# Age branches and attractors
	age_branches(delta)
	age_attractors(delta)
	
	# Regenerate attractors for continuous growth
	if attractor_timer > 1.0 / attractor_regeneration_rate:
		attractor_timer = 0.0
		generate_new_attractors()
	
	# Environmental effects
	if environmental_influence and environmental_timer > 1.0:
		environmental_timer = 0.0
		apply_environmental_effects()

func update_growth_phases() -> void:
	"""Update growth phases for seasonal changes"""
	if phase_timer > phase_duration:
		phase_timer = 0.0
		current_growth_phase = (current_growth_phase + 1) % 4
		print("Growth phase changed to: ", get_phase_name(current_growth_phase), " 🌱")
	
	# Adjust growth parameters based on phase
	match current_growth_phase:
		0:  # Rapid growth
			growth_acceleration = 1.5
			growth_distance = 0.25
		1:  # Steady growth
			growth_acceleration = 1.0
			growth_distance = 0.2
		2:  # Flowering
			growth_acceleration = 0.8
			growth_distance = 0.15
			enable_sparkles = true
		3:  # Dormant
			growth_acceleration = 0.3
			growth_distance = 0.1

func get_phase_name(phase: int) -> String:
	match phase:
		0: return "Rapid Growth"
		1: return "Steady Growth"
		2: return "Flowering"
		3: return "Dormant"
		_: return "Unknown"

func age_branches(delta: float) -> void:
	"""Age branches and handle death/regeneration"""
	for branch in branches:
		branch.age += delta
		
		# Reduce energy over time
		branch.energy = max(0.0, branch.energy - delta * 0.01)
		
		# Mark old branches for death
		if branch.age > branch_lifespan and not branch.is_dying:
			branch.is_dying = true
			branch.is_active = false
		
		# Remove very old branches
		if branch.age > branch_lifespan * 2.0:
			branch.is_active = false

func age_attractors(delta: float) -> void:
	"""Age attractors and remove old temporary ones"""
	for i in range(attractors.size() - 1, -1, -1):
		var attractor = attractors[i]
		attractor.age += delta
		
		# Remove old temporary attractors
		if attractor.is_temporary and attractor.age > 15.0:
			attractors.remove_at(i)

func generate_new_attractors() -> void:
	"""Generate new attractors for continuous growth"""
	var new_attractor_count = 2 + randi() % 3  # 2-4 new attractors
	
	for i in range(new_attractor_count):
		# Generate attractors in expanding areas
		var radius = 4.0 + time_elapsed * 0.1  # Expanding radius over time
		var theta = randf() * 2.0 * PI
		var phi = acos(1.0 - 2.0 * randf())
		var r = radius * pow(randf(), 0.33)
		
		var pos = Vector3(
			r * sin(phi) * cos(theta),
			r * sin(phi) * sin(theta),
			r * cos(phi)
		)
		
		# Add some temporary attractors for dynamic growth
		var is_temporary = randf() < 0.3
		attractors.append(Attractor.new(pos, is_temporary))

func apply_environmental_effects() -> void:
	"""Apply environmental effects that influence growth"""
	# Wind effect - slight random movement
	for branch in branches:
		if branch.is_active:
			var wind_effect = Vector3(
				randf_range(-0.05, 0.05),
				randf_range(-0.02, 0.02),
				randf_range(-0.05, 0.05)
			)
			branch.direction += wind_effect
			branch.direction = branch.direction.normalized()
	
	# Seasonal color changes
	if seasonal_changes:
		var seasonal_hue_shift = sin(time_elapsed * 0.1) * 0.1
		# This will be applied in the color generation

func grow_step() -> bool:
	var active_branches_found = false
	var new_branches = []
	var reached_attractors = []
	
	# Process existing branches
	for i in range(branches.size()):
		var branch = branches[i]
		if not branch.is_active or branch.is_dying:
			continue
		
		active_branches_found = true
		
		# Find closest attractor (considering strength and energy)
		var closest_attractor_index = -1
		var closest_distance = attraction_distance * (1.0 + (1.0 - branch.energy) * 0.5)  # Weaker branches have shorter range
		
		for j in range(attractors.size()):
			var attractor = attractors[j]
			if attractor.is_reached:
				continue
			
			var distance = branch.position.distance_to(attractor.position)
			var effective_distance = distance / attractor.strength  # Stronger attractors have more influence
			if effective_distance < closest_distance:
				closest_distance = effective_distance
				closest_attractor_index = j
		
		# Grow towards attractor
		if closest_attractor_index >= 0:
			var attractor = attractors[closest_attractor_index]
			var direction = (attractor.position - branch.position).normalized()
			
			# Add SPICY QUEER JITTER for organic flow! 🔥
			if jitter > 0:
				# Flowing, wave-like movement with energy influence
				var energy_factor = branch.energy * 0.5 + 0.5
				var wave_offset = sin(time_elapsed * 3.0 + branch.position.length()) * jitter * energy_factor
				direction += Vector3(
					randf_range(-jitter, jitter) + wave_offset,
					randf_range(-jitter, jitter) + sin(time_elapsed * 2.0) * jitter * 0.3,
					randf_range(-jitter, jitter) + cos(time_elapsed * 2.5) * jitter * 0.3
				)
				direction = direction.normalized()
			
			# Create new FABULOUS branch! ✨
			var pulsed_distance = growth_distance * branch.growth_rate * (1.0 + sin(pulse_timer) * pulse_strength * 0.5)
			var energy_modifier = branch.energy * 0.5 + 0.5  # Energy affects growth distance
			var new_position = branch.position + direction * pulsed_distance * energy_modifier
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

func update_mesh_immediate() -> void:
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
		# Use energy-based grayscale for non-pride mode
		var energy_factor = branch.energy * 0.5 + 0.5
		return Color(energy_factor, energy_factor, energy_factor, 1.0)
	
	var current_colors = pride_flags[current_flag_name]
	
	# Use branch's personal hue and generation for color selection
	var color_index = int((branch.personal_hue + branch.generation * 0.1) * current_colors.size()) % current_colors.size()
	var base_color = current_colors[color_index]
	
	# Add rainbow cycling effect
	var rainbow_shift = sin(color_cycle_timer + branch.position.x * 0.5) * 0.2
	
	# Add seasonal hue shift
	var seasonal_shift = 0.0
	if seasonal_changes:
		seasonal_shift = sin(time_elapsed * 0.1) * 0.1
	
	# Add energy-based brightness
	var energy_brightness = branch.energy * 0.3 + 0.7
	
	# Add age-based effects
	var age_factor = 1.0
	if branch.age > branch_lifespan * 0.8:
		age_factor = 0.6  # Fade older branches
	
	var hue_shifted = Color.from_hsv(
		base_color.h + rainbow_shift + seasonal_shift,
		base_color.s,
		base_color.v * energy_brightness * age_factor,
		base_color.a * age_factor
	)
	
	return hue_shifted

# VR-specific functions
func set_vr_start_point(position: Vector3) -> void:
	"""Set new starting point for VR interaction"""
	clear_growth()
	add_branch(position, Vector3.UP, -1, 0)
	generate_attractors_around_point(position)
	start_growth()

func generate_attractors_around_point(center: Vector3, radius: float = 2.0) -> void:
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

func add_attractor_at_position(position: Vector3) -> void:
	"""Add single attractor at VR controller position"""
	attractors.append(Attractor.new(position))

func clear_growth() -> void:
	"""Reset the entire growth system"""
	branches.clear()
	attractors.clear()
	is_growing = false
	immediate_mesh.clear_surfaces()

func pause_growth() -> void:
	"""Pause growth for VR menu interaction"""
	is_growing = false

func resume_growth() -> void:
	"""Resume growth after VR interaction"""
	is_growing = true

func get_growth_stats() -> Dictionary:
	"""Get stats for VR UI display"""
	var active_count = 0
	var dying_count = 0
	var reached_count = 0
	var temporary_attractors = 0
	var total_energy = 0.0
	
	for branch in branches:
		if branch.is_active:
			active_count += 1
		if branch.is_dying:
			dying_count += 1
		total_energy += branch.energy
	
	for attractor in attractors:
		if attractor.is_reached:
			reached_count += 1
		if attractor.is_temporary:
			temporary_attractors += 1
	
	var average_energy = total_energy / max(1, branches.size())
	
	return {
		"total_branches": branches.size(),
		"active_branches": active_count,
		"dying_branches": dying_count,
		"total_attractors": attractors.size(),
		"reached_attractors": reached_count,
		"temporary_attractors": temporary_attractors,
		"is_growing": is_growing,
		"continuous_growth": continuous_growth,
		"current_phase": get_phase_name(current_growth_phase),
		"growth_acceleration": growth_acceleration,
		"average_energy": average_energy,
		"time_elapsed": time_elapsed
	}

# Simplified cylinder rendering for VR (optional)
func enable_cylinder_rendering(enable: bool = true) -> void:
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
func _input(event: InputEvent) -> void:
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
			KEY_G:
				# Toggle continuous growth
				continuous_growth = !continuous_growth
				print("Continuous growth: ", "ON 🌱" if continuous_growth else "OFF")
			KEY_PLUS, KEY_EQUAL:
				# Increase growth acceleration
				growth_acceleration = min(3.0, growth_acceleration + 0.2)
				print("Growth acceleration: ", growth_acceleration)
			KEY_MINUS:
				# Decrease growth acceleration
				growth_acceleration = max(0.1, growth_acceleration - 0.2)
				print("Growth acceleration: ", growth_acceleration)
			KEY_F:
				# Toggle growth phases
				growth_phases = !growth_phases
				print("Growth phases: ", "ON 🌱" if growth_phases else "OFF")
			KEY_E:
				# Toggle environmental effects
				environmental_influence = !environmental_influence
				print("Environmental effects: ", "ON 🌬️" if environmental_influence else "OFF")
			KEY_N:
				# Force new attractor generation
				generate_new_attractors()
				print("Generated new attractors! ✨")
			KEY_L:
				# Toggle seasonal changes
				seasonal_changes = !seasonal_changes
				print("Seasonal changes: ", "ON 🍂" if seasonal_changes else "OFF")

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
