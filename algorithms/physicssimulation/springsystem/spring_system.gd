extends Node3D

# Spring-Mass System Physics Simulation
# Interactive network of masses connected by springs with real-time physics
#
# @identity
# essence: F = -k(|x|-L)*x-hat. A network of masses connected by Hooke's law springs. Each spring pulls its endpoints toward rest length.
# desire: To see a web of springs breathe — wind perturbing it, colors shifting with tension, the whole system finding equilibrium and losing it again.
# critical_parameter: spring_stiffness (k=50) and damping (0.95). Higher stiffness = faster oscillation, tighter network. Lower damping = longer ringing. Together they set the network's texture.
# triggers: Auto-interaction pulses random forces every 2 seconds, wind oscillates continuously, Space → manual random impulse, auto-rotate reveals 3D structure
# emerges: Tension waves propagating through the network. Color shifting from calm blue to hot pink as springs stretch. Fixed anchor points creating standing wave patterns.
# needs: MultiMesh rendering for masses and springs [has], wind force [has], auto-interaction [has]. Missing: VR grab individual masses, stiffness slider.
# relationships: Network extension of mass_spring_damper (single spring → many). Feeds into cloth simulation (2D grid of springs). Lives in ForcesSystems.
# truth: A spring network is a medium. Perturbation at one point travels through connections. Structure is communication.

@export_category("Spring System Parameters")
@export var mass_count: int = 20
@export var spring_stiffness: float = 50.0
@export var damping: float = 0.95
@export var gravity: float = -9.8
@export var rest_length: float = 2.0
@export var max_spring_length: float = 8.0

@export_category("Mass Properties")
@export var mass_value: float = 1.0
@export var mass_radius: float = 0.2
@export var fixed_anchor_points: bool = true
@export var anchor_count: int = 4

@export_category("Interaction")
@export var enable_mouse_interaction: bool = true
@export var mouse_force_strength: float = 10.0
@export var enable_wind_force: bool = true
@export var wind_strength: float = 2.0

@export_category("Visualization")
@export var show_springs: bool = true
@export var show_velocity_vectors: bool = false
@export var color_by_tension: bool = true
@export var animate_springs: bool = true
@export var auto_rotate: bool = true
@export var auto_interaction: bool = true

## AXIS — WHAT THE MEDIUM IS HELD UP BY.
##
## The truth this artifact carries is "a spring network is a medium; structure is
## communication". A medium always stops somewhere, and where it stops is not part of the
## medium — it is a decision someone made. The four fixed anchors have always been that
## decision, and they have always been invisible: four dimmed dots in a cloud of twenty.
## This axis builds the thing they are bolted to, so the boundary can be seen and argued
## with.
##
## Every value is welded to the ground and untouched by the wind, the auto-impulses or
## where the net happens to be swinging, which is the only way a still of a perpetually
## perturbed system says anything about the axis rather than about the shutter.
##
##   none      no boundary at all: the net floats in the void. The legacy lineage, and a
##             claim in its own right — that a medium can be had without an outside.
##   gantry    an overhead beam on two legs spanning the whole net, with a plumb drop rod
##             from a runner block down to every anchor. Held from ABOVE, industrially.
##   wall      a ribbed back plane standing behind the net with a horizontal cantilever
##             bracket reaching out to every anchor. Held from BEHIND, architecturally.
##   hoop      a tension ring encircling the net on four legs, with a radial stay pulled
##             in from the rim to every anchor. Held from AROUND: a drum head.
##   mast      one central column with guy stays fanning DOWN to every anchor and out to
##             ground plates. Held from a single point at the middle of itself.
##
## Appearance only. No mass, spring, stiffness, damping or anchor index is touched: the
## anchors sit exactly where they always sat and the rig is built to meet them.
@export_enum("none", "gantry", "wall", "hoop", "mast") var suspension: String = "none"
const SUSPENSIONS: PackedStringArray = ["none", "gantry", "wall", "hoop", "mast"]

## Seed for the per-mass jitter in initialize_system(), which decides both where the
## masses sit AND — because springs are wired by proximity — the network's TOPOLOGY. Left
## unseeded, five sweep variants are five different networks and the measurement is of the
## noise. -1 draws from the global stream exactly as this artifact always has, so the
## default lineage is unchanged; any value >= 0 makes the whole net reproducible.
@export var seed_value: int = -1

# System state
var masses: Array = []
var springs: Array = []
var anchors: Array = []
var time_step: float = 0.016
var wind_time: float = 0.0
var rotation_time: float = 0.0
var interaction_timer: float = 0.0

# Visual elements
var mass_meshes: Array = []
var spring_lines: Array = []
var velocity_arrows: Array = []
var system_container: Node3D

# MultiMesh instances for batched rendering
var _mass_multimesh_instance: MultiMeshInstance3D
var _spring_multimesh_instance: MultiMeshInstance3D
var _rig_root: Node3D = null
var _rng := RandomNumberGenerator.new()
var _seeded: bool = false

# Vibrant queer color palette
var queer_colors = [
	Color(1.0, 0.4, 0.7, 1.0),    # Hot pink
	Color(0.8, 0.3, 1.0, 1.0),    # Purple
	Color(0.3, 0.9, 1.0, 1.0),    # Cyan
	Color(1.0, 0.8, 0.2, 1.0),    # Gold
	Color(0.5, 1.0, 0.4, 1.0),    # Lime
	Color(1.0, 0.5, 0.3, 1.0),    # Coral
	Color(0.4, 0.7, 1.0, 1.0),    # Sky blue
	Color(1.0, 0.3, 0.5, 1.0)     # Rose
]

# Mass class
class Mass:
	var position: Vector3
	var velocity: Vector3
	var acceleration: Vector3
	var mass: float
	var radius: float
	var is_fixed: bool = false
	var mesh_instance: MeshInstance3D
	var connected_springs: Array = []
	
	func _init(pos: Vector3, m: float, r: float) -> void:
		position = pos
		velocity = Vector3.ZERO
		acceleration = Vector3.ZERO
		mass = m
		radius = r
	
	func apply_force(force: Vector3) -> void:
		if not is_fixed:
			acceleration += force / mass
	
	func update(delta: float) -> void:
		if not is_fixed:
			# Verlet integration
			velocity += acceleration * delta
			position += velocity * delta
			
			# Reset acceleration
			acceleration = Vector3.ZERO
	
	func set_fixed(fixed: bool) -> void:
		is_fixed = fixed
		if is_fixed:
			velocity = Vector3.ZERO

# Spring class
class Spring:
	var mass1: Mass
	var mass2: Mass
	var rest_length: float
	var stiffness: float
	var current_length: float
	var tension: float
	var line_mesh: MeshInstance3D
	
	func _init(m1: Mass, m2: Mass, length: float, k: float) -> void:
		mass1 = m1
		mass2 = m2
		rest_length = length
		stiffness = k
		
		# Add this spring to both masses
		mass1.connected_springs.append(self)
		mass2.connected_springs.append(self)
	
	func update_physics() -> void:
		var direction = mass2.position - mass1.position
		current_length = direction.length()
		
		if current_length > 0:
			direction = direction.normalized()
			var displacement = current_length - rest_length
			var force_magnitude = stiffness * displacement
			tension = abs(force_magnitude)
			
			var force = direction * force_magnitude
			
			# Apply equal and opposite forces
			mass1.apply_force(force)
			mass2.apply_force(-force)
	
	func update_visual() -> void:
		if line_mesh:
			# Update line position and orientation
			var center = (mass1.position + mass2.position) / 2
			line_mesh.position = center
			
			# Orient line toward mass2
			line_mesh.look_at_from_position(line_mesh.position, mass2.position, Vector3.UP)
			
			# Scale line to match spring length
			line_mesh.scale.z = current_length
			
			# Color by tension if enabled
			var material = line_mesh.material_override
			if material:
				var tension_normalized = clamp(tension / 100.0, 0.0, 1.0)
				# Cycle through vibrant colors based on tension
				var base_color = Color(
					0.5 + sin(tension_normalized * 3.14) * 0.5,
					0.5 + cos(tension_normalized * 3.14 * 1.5) * 0.5,
					0.7 + sin(tension_normalized * 3.14 * 2.0) * 0.3,
					0.9
				)
				material.albedo_color = base_color
				material.emission_enabled = true
				material.emission = base_color * 0.6
				material.emission_energy_multiplier = 1.5

func _ready() -> void:
	_seed_rng()
	setup_environment()
	initialize_system()
	create_visuals()
	setup_camera()
	_build_suspension()   # APPENDED LAST — nothing above it moves

func _process(delta: float) -> void:
	simulate_physics(delta)
	update_wind_force(delta)
	update_visuals()

	# Auto-rotate for 3D effect
	if auto_rotate:
		rotation_time += delta
		rotation.y = sin(rotation_time * 0.3) * 0.5
		rotation.x = cos(rotation_time * 0.2) * 0.2

	# Automatic interaction
	if auto_interaction:
		interaction_timer += delta
		if interaction_timer >= 2.0:
			interaction_timer = 0.0
			_apply_auto_force()

	# Handle mouse interaction
	if enable_mouse_interaction:
		handle_mouse_interaction()

func setup_environment() -> void:
	# Lighting
	var light = DirectionalLight3D.new()
	light.light_energy = 1.0
	light.rotation_degrees = Vector3(-30, 45, 0)
	add_child(light)
	
	# Environment
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.05, 0.1)
	environment.ambient_light_color = Color(0.3, 0.3, 0.4)
	environment.ambient_light_energy = 0.6
	env.environment = environment
	add_child(env)
	
	# Container for all system elements
	system_container = Node3D.new()
	system_container.name = "SpringSystem"
	add_child(system_container)

func initialize_system() -> void:
	masses.clear()
	springs.clear()
	anchors.clear()
	
	# Create masses in a grid-like pattern
	var grid_size = int(sqrt(mass_count))
	var spacing = rest_length * 1.2
	var center_offset = Vector3(
		-grid_size * spacing / 2,
		5,
		-grid_size * spacing / 2
	)
	
	# Create masses
	for i in range(mass_count):
		var x = i % grid_size
		var y = i / grid_size
		
		var position = center_offset + Vector3(
			x * spacing + _rg_randf_range(-0.5, 0.5),
			_rg_randf_range(-1, 1),
			y * spacing + _rg_randf_range(-0.5, 0.5)
		)
		
		var mass = Mass.new(position, mass_value, mass_radius)
		masses.append(mass)
	
	# Create anchor points (fixed masses)
	if fixed_anchor_points and anchor_count > 0:
		for i in range(min(anchor_count, masses.size())):
			var anchor_index = i * (masses.size() / anchor_count)
			masses[anchor_index].set_fixed(true)
			anchors.append(masses[anchor_index])
	
	# Create springs between nearby masses
	for i in range(masses.size()):
		for j in range(i + 1, masses.size()):
			var distance = masses[i].position.distance_to(masses[j].position)
			
			# Connect masses that are close enough
			if distance < rest_length * 2.0:
				var spring = Spring.new(masses[i], masses[j], rest_length, spring_stiffness)
				springs.append(spring)

func create_visuals() -> void:
	mass_meshes.clear()
	spring_lines.clear()

	# --- Mass MultiMesh ---
	var sphere := SphereMesh.new()
	sphere.radius = mass_radius
	sphere.height = mass_radius * 2

	var mass_mat := StandardMaterial3D.new()
	mass_mat.vertex_color_use_as_albedo = true
	mass_mat.emission_enabled = true
	mass_mat.metallic = 0.3
	mass_mat.roughness = 0.7

	var mass_mm := MultiMesh.new()
	mass_mm.transform_format = MultiMesh.TRANSFORM_3D
	mass_mm.use_colors = true
	mass_mm.instance_count = masses.size()
	mass_mm.mesh = sphere
	mass_mm.mesh.material = mass_mat

	_mass_multimesh_instance = MultiMeshInstance3D.new()
	_mass_multimesh_instance.name = "MassMultiMesh"
	_mass_multimesh_instance.multimesh = mass_mm
	system_container.add_child(_mass_multimesh_instance)

	for i in masses.size():
		var mass = masses[i]
		mass_mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, mass.position))
		var color: Color = queer_colors[i % queer_colors.size()]
		if mass.is_fixed:
			color = color * 0.7
		mass_mm.set_instance_color(i, color)

	# --- Spring MultiMesh ---
	if show_springs and not springs.is_empty():
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.03
		cyl.bottom_radius = 0.03
		cyl.height = 1.0

		var spring_mat := StandardMaterial3D.new()
		spring_mat.vertex_color_use_as_albedo = true
		spring_mat.emission_enabled = true
		spring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

		var spring_mm := MultiMesh.new()
		spring_mm.transform_format = MultiMesh.TRANSFORM_3D
		spring_mm.use_colors = true
		spring_mm.instance_count = springs.size()
		spring_mm.mesh = cyl
		spring_mm.mesh.material = spring_mat

		_spring_multimesh_instance = MultiMeshInstance3D.new()
		_spring_multimesh_instance.name = "SpringMultiMesh"
		_spring_multimesh_instance.multimesh = spring_mm
		system_container.add_child(_spring_multimesh_instance)

		for i in springs.size():
			var s = springs[i]
			var t := _compute_spring_transform(s.mass1.position, s.mass2.position)
			spring_mm.set_instance_transform(i, t)
			spring_mm.set_instance_color(i, Color(0.6, 0.6, 0.6, 0.8))

func _compute_spring_transform(from_pos: Vector3, to_pos: Vector3) -> Transform3D:
	"""Compute transform for a unit cylinder to span between two points"""
	var mid := (from_pos + to_pos) * 0.5
	var diff := to_pos - from_pos
	var dist := diff.length()
	if dist < 0.001:
		return Transform3D(Basis.IDENTITY, mid)
	var dir := diff / dist
	var up := Vector3.UP
	if abs(dir.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right := dir.cross(up).normalized()
	up = right.cross(dir).normalized()
	var basis := Basis(right, dir * dist, up)
	return Transform3D(basis, mid)

func setup_camera() -> void:
	var camera = Camera3D.new()
	camera.position = Vector3(0, 8, 12)
	add_child(camera)
	camera.look_at_from_position(camera.position, Vector3(0, 3, 0), Vector3.UP)

func simulate_physics(_delta) -> void:
	var fixed_delta = time_step
	
	# Apply gravity to all masses
	for mass in masses:
		if not mass.is_fixed:
			mass.apply_force(Vector3(0, gravity * mass.mass, 0))
	
	# Update spring forces
	for spring in springs:
		spring.update_physics()
	
	# Apply damping
	for mass in masses:
		if not mass.is_fixed:
			mass.velocity *= damping
	
	# Update mass positions
	for mass in masses:
		mass.update(fixed_delta)
		
		# Simple boundary constraints
		if mass.position.y < -5:
			mass.position.y = -5
			mass.velocity.y = abs(mass.velocity.y) * 0.5

func update_wind_force(delta) -> void:
	if enable_wind_force:
		wind_time += delta
		
		# Create oscillating wind force
		var wind_direction = Vector3(
			sin(wind_time * 0.8) * wind_strength,
			0,
			cos(wind_time * 0.5) * wind_strength * 0.5
		)
		
		for mass in masses:
			if not mass.is_fixed:
				mass.apply_force(wind_direction)

func handle_mouse_interaction() -> void:
	# This is a simplified version - in a real implementation you'd use proper mouse raycasting
	# For now, we'll just apply a random force to simulate interaction
	if Input.is_action_pressed("ui_accept"):  # Space bar
		if masses.size() > 0:
			var random_mass = masses[_rg_randi() % masses.size()]
			if not random_mass.is_fixed:
				var random_force = Vector3(
					_rg_randf_range(-mouse_force_strength, mouse_force_strength),
					_rg_randf_range(0, mouse_force_strength),
					_rg_randf_range(-mouse_force_strength, mouse_force_strength)
				)
				random_mass.apply_force(random_force)

func update_visuals() -> void:
	# Update mass positions and colors via MultiMesh
	if _mass_multimesh_instance:
		var mm := _mass_multimesh_instance.multimesh
		for i in masses.size():
			var mass = masses[i]
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, mass.position))
			# Update color based on velocity
			var speed: float = mass.velocity.length()
			var base_color: Color = queer_colors[i % queer_colors.size()]
			if mass.is_fixed:
				base_color = base_color * 0.7
			if speed > 1.0 and not mass.is_fixed:
				var intensity: float = clamp(speed / 5.0, 0.0, 1.0)
				base_color = base_color.lerp(Color(1.0, 0.4, 0.8), intensity)
			mm.set_instance_color(i, base_color)

	# Update spring transforms and colors via MultiMesh
	if show_springs and _spring_multimesh_instance:
		var smm := _spring_multimesh_instance.multimesh
		for i in springs.size():
			var s = springs[i]
			var t := _compute_spring_transform(s.mass1.position, s.mass2.position)
			smm.set_instance_transform(i, t)
			# Color by tension
			if color_by_tension:
				var tension_normalized: float = clamp(s.tension / 100.0, 0.0, 1.0)
				var c := Color(
					0.5 + sin(tension_normalized * 3.14) * 0.5,
					0.5 + cos(tension_normalized * 3.14 * 1.5) * 0.5,
					0.7 + sin(tension_normalized * 3.14 * 2.0) * 0.3,
					0.9
				)
				smm.set_instance_color(i, c)

func _apply_auto_force() -> void:
	# Apply random forces to create automatic interaction
	if masses.size() > 0:
		var random_indices = []
		for i in range(min(3, masses.size())):
			random_indices.append(_rg_randi() % masses.size())

		for idx in random_indices:
			var mass = masses[idx]
			if not mass.is_fixed:
				var random_force = Vector3(
					_rg_randf_range(-mouse_force_strength, mouse_force_strength),
					_rg_randf_range(-mouse_force_strength, mouse_force_strength),
					_rg_randf_range(-mouse_force_strength, mouse_force_strength)
				)
				mass.apply_force(random_force)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("suspension"):
		var want: String = str(config["suspension"]).strip_edges().to_lower()
		# An unknown word keeps the default. A typo must never publish a silent variant.
		if SUSPENSIONS.has(want):
			suspension = want
	if config.has("seed_value"):
		seed_value = int(config["seed_value"])
	if not masses.is_empty():
		_build_suspension()


func _seed_rng() -> void:
	_seeded = seed_value >= 0
	if _seeded:
		_rng.seed = seed_value


# On the default (-1) these are the same global calls in the same order, so the legacy
# stream is byte for byte what it was.
func _rg_randf_range(a: float, b: float) -> float:
	if _seeded:
		return _rng.randf_range(a, b)
	return randf_range(a, b)


func _rg_randi() -> int:
	if _seeded:
		return _rng.randi()
	return randi()


# ═══════════════════════════════════════════════════════════════════════════
# SUSPENSION — the boundary the medium is fastened to. Bolted to the ground,
# built to meet the anchors exactly where initialize_system() left them, and
# never touched again by wind, impulse or settling.
# ═══════════════════════════════════════════════════════════════════════════
const RG_STEEL := Color(0.44, 0.47, 0.53)
const RG_DARK := Color(0.19, 0.20, 0.24)
const RG_BOLT := Color(0.98, 0.74, 0.26)


func _build_suspension() -> void:
	if is_instance_valid(_rig_root):
		_rig_root.queue_free()
	_rig_root = null
	if masses.is_empty():
		return
	var root := Node3D.new()
	root.name = "Suspension"
	add_child(root)
	_rig_root = root

	# Extent marker. The net is drawn entirely with MultiMeshInstance3D, which an AABB
	# walk that counts MeshInstance3D cannot see — so a capture harness can frame this
	# artifact as a one-metre box while it actually occupies ten. layers = 0 renders it
	# to no camera, so the picture is unchanged and only the measurement is corrected.
	# NEVER `visible = false` here: visibility is hierarchical and would take the rig
	# down with it.
	var lo: Vector3 = masses[0].position
	var hi: Vector3 = masses[0].position
	for m in masses:
		var q: Vector3 = m.position
		lo = Vector3(minf(lo.x, q.x), minf(lo.y, q.y), minf(lo.z, q.z))
		hi = Vector3(maxf(hi.x, q.x), maxf(hi.y, q.y), maxf(hi.z, q.z))
	var pad: float = mass_radius + 0.2
	var marker: MeshInstance3D = _rg_box((lo + hi) * 0.5,
		hi - lo + Vector3(pad, pad, pad) * 2.0, _rg_mat(RG_DARK, 0.9, 0.0))
	marker.name = "ExtentMarker"
	marker.layers = 0
	root.add_child(marker)

	if suspension == "none":
		return

	var pts: Array = []
	for a in anchors:
		pts.append(a.position)
	if pts.is_empty():
		# fixed_anchor_points off: no boundary exists to build, and inventing one would
		# be a picture of a thing the simulation does not have.
		return

	match suspension:
		"gantry":
			_rg_gantry(root, pts, lo, hi)
		"wall":
			_rg_wall(root, pts, lo, hi)
		"hoop":
			_rg_hoop(root, pts, lo, hi)
		"mast":
			_rg_mast(root, pts, lo, hi)
		_:
			pass


# ── GANTRY — held from above ──────────────────────────────────────────────
func _rg_gantry(root: Node3D, pts: Array, lo: Vector3, hi: Vector3) -> void:
	var steel: StandardMaterial3D = _rg_mat(RG_STEEL, 0.4, 0.7)
	var dark: StandardMaterial3D = _rg_mat(RG_DARK, 0.7, 0.3)
	var bolt: StandardMaterial3D = _rg_glow(RG_BOLT, 0.9)
	var cx: float = (lo.x + hi.x) * 0.5
	var z0: float = lo.z - 1.6
	var z1: float = hi.z + 1.6
	var beam_y: float = hi.y + 3.2

	root.add_child(_rg_box(Vector3(cx, beam_y, (z0 + z1) * 0.5),
		Vector3(0.62, 0.55, z1 - z0), steel))
	root.add_child(_rg_box(Vector3(cx, beam_y + 0.34, (z0 + z1) * 0.5),
		Vector3(0.95, 0.13, z1 - z0), dark))
	for lz: float in [z0, z1]:
		root.add_child(_rg_box(Vector3(cx, beam_y * 0.5, lz), Vector3(0.5, beam_y, 0.5), steel))
		root.add_child(_rg_box(Vector3(cx, 0.16, lz), Vector3(1.7, 0.32, 1.7), dark))
		var sgn: float = (-1.0 if lz < (z0 + z1) * 0.5 else 1.0)
		root.add_child(_rg_link(Vector3(cx, beam_y - 0.4, lz + sgn * 0.25),
			Vector3(cx, beam_y - 2.3, lz + sgn * 2.1), 0.11, steel))
	# A runner block on the beam over every anchor, and a plumb rod down to it.
	for p in pts:
		var q: Vector3 = p
		root.add_child(_rg_box(Vector3(cx, beam_y - 0.42, q.z), Vector3(0.5, 0.30, 0.5), dark))
		root.add_child(_rg_link(Vector3(cx, beam_y - 0.55, q.z), q + Vector3(0.0, 0.22, 0.0),
			0.075, steel))
		root.add_child(_rg_box(q + Vector3(0.0, 0.30, 0.0), Vector3(0.26, 0.13, 0.26), bolt))


# ── WALL — held from behind ───────────────────────────────────────────────
func _rg_wall(root: Node3D, pts: Array, lo: Vector3, hi: Vector3) -> void:
	var face: StandardMaterial3D = _rg_mat(Color(0.62, 0.61, 0.58), 0.85, 0.0)
	var steel: StandardMaterial3D = _rg_mat(RG_STEEL, 0.4, 0.7)
	var dark: StandardMaterial3D = _rg_mat(RG_DARK, 0.7, 0.3)
	var bolt: StandardMaterial3D = _rg_glow(RG_BOLT, 0.9)
	var wz: float = lo.z - 2.0
	var cx: float = (lo.x + hi.x) * 0.5
	var w: float = (hi.x - lo.x) + 4.0
	var h: float = hi.y + 2.6

	root.add_child(_rg_box(Vector3(cx, h * 0.5, wz), Vector3(w, h, 0.42), face))
	root.add_child(_rg_box(Vector3(cx, 0.22, wz - 0.12), Vector3(w + 0.7, 0.44, 0.9), dark))
	root.add_child(_rg_box(Vector3(cx, h - 0.2, wz + 0.06), Vector3(w, 0.34, 0.16), dark))
	# Ribs proud of the face so the plane reads as built, not as a backdrop.
	for i in range(7):
		var rx: float = cx + (float(i) / 6.0 - 0.5) * w * 0.94
		root.add_child(_rg_box(Vector3(rx, h * 0.5, wz + 0.26), Vector3(0.20, h - 0.6, 0.14), steel))
	# A mounting plate on the wall and a cantilever bracket out to every anchor.
	for p in pts:
		var q: Vector3 = p
		root.add_child(_rg_box(Vector3(q.x, q.y, wz + 0.30), Vector3(0.70, 0.70, 0.16), dark))
		root.add_child(_rg_link(Vector3(q.x, q.y, wz + 0.36), q, 0.085, steel))
		root.add_child(_rg_link(Vector3(q.x, q.y + 0.85, wz + 0.36),
			Vector3(q.x, q.y + 0.10, (q.z + wz) * 0.5), 0.05, steel))
		root.add_child(_rg_box(q, Vector3(0.26, 0.26, 0.13), bolt))


# ── HOOP — held from around ───────────────────────────────────────────────
func _rg_hoop(root: Node3D, pts: Array, lo: Vector3, hi: Vector3) -> void:
	var steel: StandardMaterial3D = _rg_mat(RG_STEEL, 0.4, 0.7)
	var dark: StandardMaterial3D = _rg_mat(RG_DARK, 0.7, 0.3)
	var bolt: StandardMaterial3D = _rg_glow(RG_BOLT, 0.9)
	var cx: float = (lo.x + hi.x) * 0.5
	var cz: float = (lo.z + hi.z) * 0.5
	var ry: float = 0.0
	for p in pts:
		ry += p.y
	ry /= float(pts.size())
	var rad: float = maxf(hi.x - cx, hi.z - cz) + 2.2

	var seg: int = 32
	for i in range(seg):
		var a0: float = TAU * float(i) / float(seg)
		var a1: float = TAU * float(i + 1) / float(seg)
		root.add_child(_rg_link(
			Vector3(cx + cos(a0) * rad, ry, cz + sin(a0) * rad),
			Vector3(cx + cos(a1) * rad, ry, cz + sin(a1) * rad), 0.17, steel))
	# Four legs to the ground with foot pads.
	for i in range(4):
		var a: float = TAU * float(i) / 4.0 + PI * 0.25
		var fx: float = cx + cos(a) * rad
		var fz: float = cz + sin(a) * rad
		root.add_child(_rg_box(Vector3(fx, ry * 0.5, fz), Vector3(0.40, ry, 0.40), steel))
		root.add_child(_rg_box(Vector3(fx, 0.15, fz), Vector3(1.4, 0.30, 1.4), dark))
	# A radial stay pulled in from the rim to every anchor.
	for p in pts:
		var q: Vector3 = p
		var d: Vector3 = Vector3(q.x - cx, 0.0, q.z - cz)
		if d.length() < 0.01:
			d = Vector3(1.0, 0.0, 0.0)
		var rimv: Vector3 = Vector3(cx, ry, cz) + d.normalized() * rad
		root.add_child(_rg_box(rimv, Vector3(0.40, 0.40, 0.40), dark))
		root.add_child(_rg_link(rimv, q, 0.065, steel))
		root.add_child(_rg_box(q, Vector3(0.24, 0.24, 0.24), bolt))


# ── MAST — held from one point in the middle of itself ────────────────────
func _rg_mast(root: Node3D, pts: Array, lo: Vector3, hi: Vector3) -> void:
	var steel: StandardMaterial3D = _rg_mat(RG_STEEL, 0.4, 0.7)
	var dark: StandardMaterial3D = _rg_mat(RG_DARK, 0.7, 0.3)
	var bolt: StandardMaterial3D = _rg_glow(RG_BOLT, 0.9)
	var cx: float = (lo.x + hi.x) * 0.5
	var cz: float = (lo.z + hi.z) * 0.5
	var top: float = hi.y + 4.0
	var head: Vector3 = Vector3(cx, top, cz)
	var reach: float = maxf(hi.x - cx, hi.z - cz) + 3.4

	root.add_child(_rg_box(Vector3(cx, top * 0.5, cz), Vector3(0.62, top, 0.62), steel))
	root.add_child(_rg_box(Vector3(cx, 0.20, cz), Vector3(2.2, 0.40, 2.2), dark))
	root.add_child(_rg_box(head + Vector3(0.0, 0.18, 0.0), Vector3(1.5, 0.24, 1.5), dark))
	# Collars up the column so it reads as a mast and not as a stick.
	for i in range(4):
		root.add_child(_rg_box(Vector3(cx, top * (0.2 + 0.2 * float(i)), cz),
			Vector3(0.95, 0.15, 0.95), dark))
	# A guy stay fanning down to every anchor.
	for p in pts:
		var q: Vector3 = p
		root.add_child(_rg_link(head + Vector3(0.0, -0.10, 0.0), q, 0.065, steel))
		root.add_child(_rg_box(q, Vector3(0.26, 0.26, 0.26), bolt))
	# Ground guys, so the mast is answered by something.
	for i in range(3):
		var a: float = TAU * float(i) / 3.0 + 0.5
		var gnd: Vector3 = Vector3(cx + cos(a) * reach, 0.18, cz + sin(a) * reach)
		root.add_child(_rg_link(head + Vector3(0.0, -0.35, 0.0), gnd, 0.055, steel))
		root.add_child(_rg_box(gnd, Vector3(0.9, 0.36, 0.9), dark))


# ── Small builders (prefixed so nothing in the network can collide) ───────
func _rg_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _rg_glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func _rg_box(p: Vector3, s: Vector3, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(maxf(s.x, 0.01), maxf(s.y, 0.01), maxf(s.z, 0.01))
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	return mi


# A cylinder spanning a to b, oriented by a hand-built Basis. look_at() needs the node in
# the tree already, and these are built before they are parented.
func _rg_link(a: Vector3, b: Vector3, r: float, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	var d: Vector3 = b - a
	var span: float = d.length()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = maxf(span, 0.002)
	mi.mesh = cm
	mi.material_override = m
	var dir: Vector3 = Vector3.UP
	if span > 0.0001:
		dir = d / span
	var up: Vector3 = Vector3.UP
	if absf(dir.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right: Vector3 = dir.cross(up).normalized()
	var fwd: Vector3 = right.cross(dir).normalized()
	mi.transform = Transform3D(Basis(right, dir, fwd), (a + b) * 0.5)
	return mi
