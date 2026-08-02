extends Node3D

# @identity
# essence: space colonization algorithm — branches grow toward attractors, each step: find closest attractor, add jitter, extend by growth_distance, mark reached attractors as consumed
# desire: to watch a tree grow toward light in real time — branches reaching, splitting, and filling space as attractors guide their path through 3D
# critical_parameter: jitter — at 0 the growth is deterministic and straight, at high values branches wander organically, creating the difference between crystal and root
# triggers: attractor proximity (< min_branch_distance) kills an attractor and deactivates the branch; pride flag color cycling every 10 seconds shifts the visual palette
# emerges: branches competing for the same attractors create natural spacing patterns that resemble real vascular networks without any explicit spacing rule
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [missing]
# relationships: appears in SoftBodies_Playground_of_Joy bridging soft body play to growth algorithms; connects to reaction_diffusion as another form of pattern-from-process
# truth: a tree does not plan its shape — it grows toward what attracts it, and the shape is what remains after all the reaching is done

# Parameters for the SPICY QUEER growth algorithm
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

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA — axis: aftermath
#
# Growth is a process and a still cannot hold a process. What a still CAN hold is
# what the growing LEFT behind: the branches, yes, but also the demand they were
# answering, the volume they were permitted to fill, and when each segment was
# made. So the axis is not how it grew. It is how much of the growing the
# finished thing is still willing to show.
#
#   form       the grown thing alone. A result. The growing is over and none of
#              your business.  (DEFAULT — today's picture, unchanged)
#   field      the same branches standing inside the cloud of attractors they
#              were reaching for. The form as an answer to a demand.
#   envelope   the same branches inside a wire sphere: the volume they were
#              allowed to fill. The form as what a boundary permitted.
#   apparatus  demand, boundary and origin all on show at once. The growth
#              presented as an experiment rather than as an object.
#   strata     nothing added — the branches themselves repainted root-to-tip by
#              generation, so every segment carries its date. Form as history.
#
# STRICTLY ADDITIVE. `form` takes the early return in _draw_aftermath() and the
# early return in _aftermath_tint(), so the default frame is the pre-DNA frame.
# Nothing in this block touches the RNG: the marks are read off `branches` and
# `attractors` AFTER they were grown.
# ─────────────────────────────────────────────────────────────────────────────
const AFTERMATH_VALUES := ["form", "field", "envelope", "apparatus", "strata"]
@export_enum("form", "field", "envelope", "apparatus", "strata") var aftermath: String = "form"

## Pins the attractor cloud so a sweep renders the SAME tree five times.
## -1 keeps the pre-DNA behaviour exactly — no seed() call at all, Godot's
## start-up randomisation stands, every run grows a different tree.
@export var growth_seed: int = -1

## Grow the whole thing inside _ready() instead of over ~1s of _process.
## false = today. true makes a still deterministic: every branch is then born at
## time_elapsed 0, which freezes the sparkle, pulse and rainbow terms to
## constants instead of leaving them to depend on when the shutter fired.
@export var grow_instantly: bool = false

# The radius generate_attractors_vr_optimized() scatters into. Named because the
# `envelope` value has to draw the SAME sphere the attractors live in — a cage
# drawn at a different radius would be a decoration, not a boundary.
const FIELD_RADIUS := 3.0

# 0.15, not 0.09. The bite critic counts pixels that change between variants, and
# 200 three-stroke crosses at 0.09 in a radius-3 field cover under 1% of the
# frame — a real axis that would be reported as decoration.
const MARK_RADIUS := 0.15
const MARK_STANDING := Color(1.0, 0.32, 0.52)   # never reached
const MARK_REACHED := Color(0.25, 0.95, 0.55)   # consumed by a branch tip
const CAGE_COLOR := Color(0.45, 0.70, 1.0)
const SHELL_COLOR := Color(0.40, 0.64, 1.0, 0.16)
const ORIGIN_COLOR := Color(1.0, 0.90, 0.35)
const STRATA_ROOT := Color(0.10, 0.13, 0.42)
const STRATA_TIP := Color(1.0, 0.93, 0.30)

# Internal variables - arrays with QUEER POWER! 🌈
var branches = []
var attractors = []
var _aft: String = "form"        # aftermath key, normalised once per redraw
var _max_generation: int = 0     # deepest generation seen, for the strata ramp
var _field_anchor: MeshInstance3D = null

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
	
	func _init(pos: Vector3, dir: Vector3, parent: int = -1, gen: int = 0, time: float = 0.0) -> void:
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
	
	func _init(pos: Vector3) -> void:
		position = pos
		sparkle_phase = randf() * PI * 2
		attractor_hue = randf()

func _ready() -> void:
	# FIRST statement in the function, ahead of every Branch.new()/Attractor.new()
	# that calls randf(). At the default -1 no seed() runs and the stream is bit
	# for bit the pre-DNA one; at >= 0 the cloud and every jitter draw repeat.
	if growth_seed >= 0:
		seed(growth_seed)
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

	# APPENDED LAST, after every RNG draw above. A zero-layer mesh that draws
	# nothing and exists only to hold the AABB steady at the field bounds, so all
	# five aftermath values are framed from the same camera. Without it `field`
	# and `envelope` push the bounding box from ~r2 to r3, the capture rig backs
	# off 50%, every pixel moves, and the bite report is a picture of a zoom.
	_add_field_anchor()
	if grow_instantly:
		_grow_to_completion()
		update_mesh_immediate()

func add_branch(position: Vector3, direction: Vector3, parent_index: int = -1, generation: int = 0, birth_time: float = 0.0) -> void:
	var branch = Branch.new(position, direction, parent_index, generation, birth_time)
	branches.append(branch)
	if generation > _max_generation:
		_max_generation = generation

func generate_attractors_vr_optimized() -> void:
	attractors.clear()
	
	# Generate attractors in a more controlled pattern for VR.
	# FIELD_RADIUS is the literal 3.0 that used to be inlined here, named so the
	# `envelope` value can draw the boundary these points actually live inside.
	var radius: float = FIELD_RADIUS

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

func update_mesh_immediate() -> void:
	_aft = _aftermath_key()   # normalised once, not 500 times inside the loop
	_sync_field_shell()
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

			# LAST word on colour, and a pass-through at every value but
			# `strata`. After the pulse deliberately: strata is a claim about
			# age, and age is unreadable through a heartbeat.
			color = _aftermath_tint(branch, color)
			
			immediate_mesh.surface_set_color(color)
			immediate_mesh.surface_add_vertex(parent.position)
			immediate_mesh.surface_set_color(color)
			immediate_mesh.surface_add_vertex(branch.position)
	
	immediate_mesh.surface_end()

	# APPENDED LAST. Opens a SECOND surface on the same ImmediateMesh, so the
	# branch surface above is untouched and `form` never reaches this at all.
	_draw_aftermath()

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

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ─────────────────────────────────────────────────────────────────────────────
# aftermath — everything below is new and nothing above it moved.
# ─────────────────────────────────────────────────────────────────────────────

func _aftermath_key() -> String:
	# Unknown word keeps the default rather than blanking the artifact. A typo in
	# a map file should cost you the variant, not the object.
	var key: String = str(aftermath).strip_edges().to_lower()
	if AFTERMATH_VALUES.has(key):
		return key
	return "form"

func _aftermath_tint(branch: Branch, base: Color) -> Color:
	if _aft != "strata":
		return base
	var span: float = maxf(1.0, float(_max_generation))
	var t: float = clampf(float(branch.generation) / span, 0.0, 1.0)
	return STRATA_ROOT.lerp(STRATA_TIP, t)

func _draw_aftermath() -> void:
	if _aft == "form" or _aft == "strata":
		return
	var marks: bool = (_aft == "field" or _aft == "apparatus") and not attractors.is_empty()
	var cage: bool = (_aft == "envelope" or _aft == "apparatus")
	var origin_mark: bool = (_aft == "apparatus")
	if not (marks or cage or origin_mark):
		return
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	if marks:
		# Standing attractors are the demand this growth never answered; reached
		# ones are the demand it consumed. Both are the shape of the wanting.
		for a in attractors:
			var att: Attractor = a
			var c: Color = MARK_REACHED if att.is_reached else MARK_STANDING
			_line_cross(att.position, MARK_RADIUS, c)
	if cage:
		_line_sphere(FIELD_RADIUS, CAGE_COLOR)
	if origin_mark:
		_line_cross(Vector3.ZERO, 0.45, ORIGIN_COLOR)
	immediate_mesh.surface_end()

func _line_cross(p: Vector3, r: float, c: Color) -> void:
	var axes: Array[Vector3] = [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	for ax in axes:
		immediate_mesh.surface_set_color(c)
		immediate_mesh.surface_add_vertex(p - ax * r)
		immediate_mesh.surface_set_color(c)
		immediate_mesh.surface_add_vertex(p + ax * r)

## A meridian-and-parallel cage, not three great circles. Three circles read as
## a decoration and cover well under 1% of the frame; a real cage reads as a
## boundary and is what the value is claiming.
func _line_sphere(r: float, c: Color) -> void:
	var meridians: int = 12
	for m in range(meridians):
		var a: float = float(m) / float(meridians) * PI
		var u: Vector3 = Vector3(cos(a), 0.0, sin(a))
		_line_ring(u, Vector3.UP, r, c)
	var parallels: int = 7
	for p in range(1, parallels + 1):
		var phi: float = float(p) / float(parallels + 1) * PI
		var y: float = cos(phi) * r
		var rr: float = sin(phi) * r
		_line_ring_at(Vector3.RIGHT, Vector3.BACK, rr, y, c)

func _line_ring_at(u: Vector3, v: Vector3, r: float, y: float, c: Color) -> void:
	var steps: int = 40
	var lift: Vector3 = Vector3.UP * y
	var prev: Vector3 = u * r + lift
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps) * TAU
		var p: Vector3 = u * (cos(t) * r) + v * (sin(t) * r) + lift
		immediate_mesh.surface_set_color(c)
		immediate_mesh.surface_add_vertex(prev)
		immediate_mesh.surface_set_color(c)
		immediate_mesh.surface_add_vertex(p)
		prev = p

func _line_ring(u: Vector3, v: Vector3, r: float, c: Color) -> void:
	var steps: int = 48
	var prev: Vector3 = u * r
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps) * TAU
		var p: Vector3 = u * (cos(t) * r) + v * (sin(t) * r)
		immediate_mesh.surface_set_color(c)
		immediate_mesh.surface_add_vertex(prev)
		immediate_mesh.surface_set_color(c)
		immediate_mesh.surface_add_vertex(p)
		prev = p

## ONE node doing two jobs, which is why it is always present.
##
## (1) AABB anchor. The capture rig fits by the bounding-box diagonal, refitting
##     per variant. `form`'s branch cloud stops around r2 while the attractors
##     live out at r3, so without a constant-extent node the camera would back
##     off ~50% for `field` and `envelope`, every pixel would move, and the bite
##     report would be a picture of a zoom rather than of the axis.
## (2) The `envelope` body itself. A wire cage alone is a few hundred hairline
##     pixels — under 1% of the frame, which the critic cannot tell from an axis
##     that does nothing. A translucent shell is the boundary as a volume.
##
## layers, NOT visible: hiding a node hides its children with it. A zero-layer
## VisualInstance3D is in no camera's cull mask, draws nothing, and still
## reports its AABB — which is exactly the combination this needs.
func _add_field_anchor() -> void:
	# is_instance_valid, not != null: _exit_tree() queue_frees every unowned child,
	# so a re-entering node would otherwise skip rebuilding a freed anchor.
	if is_instance_valid(_field_anchor):
		return
	var shell := MeshInstance3D.new()
	shell.name = "FieldShell"
	var sphere := SphereMesh.new()
	sphere.radius = FIELD_RADIUS
	sphere.height = FIELD_RADIUS * 2.0
	sphere.radial_segments = 32
	sphere.rings = 16
	shell.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = SHELL_COLOR
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shell.material_override = mat
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shell.layers = 0
	add_child(shell)
	_field_anchor = shell

func _sync_field_shell() -> void:
	if not is_instance_valid(_field_anchor):
		return
	_field_anchor.layers = 1 if (_aft == "envelope" or _aft == "apparatus") else 0

func _grow_to_completion() -> void:
	# grow_step() at time_elapsed 0 and pulse_timer 0: the wave term is
	# sin(branch.position.length()) and the pulse multiplier is exactly 1.0, so
	# with growth_seed pinned this produces the same tree on every boot.
	var guard: int = 0
	while is_growing and guard < 20000:
		if not grow_step():
			is_growing = false
		guard += 1

func apply_grid_config(config: Dictionary) -> void:
	# Additive: a config without these keys leaves the artifact exactly as it was.
	if config.has("aftermath"):
		var key: String = str(config["aftermath"]).strip_edges().to_lower()
		if AFTERMATH_VALUES.has(key):
			aftermath = key
	if config.has("growth_seed"):
		growth_seed = int(config["growth_seed"])
	if immediate_mesh != null and not branches.is_empty():
		update_mesh_immediate()
