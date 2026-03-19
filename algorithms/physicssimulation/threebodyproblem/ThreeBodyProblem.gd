extends Node3D

# @identity
# essence: F_ij = G*m_i*m_j/r^2. Three bodies, three mutual attractions, no closed-form solution. Deterministic rules, unpredictable trajectories.
# desire: To watch three glowing bodies dance — orbiting, swapping partners, ejecting one, recapturing — Poincare's impossibility made visible.
# critical_parameter: gravitational_constant (0.1) and initial conditions. Tiny changes in starting positions produce wildly different long-term behavior. This IS chaos.
# triggers: Auto-start — bodies attract pairwise, trails trace history. Reset button → return to initial positions. Pause → freeze the dance. Mass slider → all masses change.
# emerges: Figure-eight orbits (rare, unstable). Hierarchical pairs (two orbit closely, third orbits the pair). Ejection events (one body flung away). Sensitivity to initial conditions.
# needs: VR UI buttons [has], trail visualization [has], auto-rotate for 3D perspective [has]. Missing: VR grabbable bodies to set initial conditions, Lyapunov exponent display.
# relationships: Extends exercise_1_8 (two-body attraction → three-body chaos). Pairs with nbody_simulation (3 → N). Gateway to chaos_attractor (strange attractors from deterministic ODEs).
# truth: Three bodies under gravity have no formula. The future is computable but not predictable. Determinism and predictability are not the same thing.

class_name ThreeBodyProblem

var bodies = []
var paused = false
var trails_enabled = true
var gravitational_constant = 0.1
var time_scale = 1.0
var rotation_time = 0.0

# Vibrant queer color palette for bodies
var queer_colors = [
	Color(1.0, 0.4, 0.7, 1.0),    # Hot pink
	Color(0.8, 0.3, 1.0, 1.0),    # Purple
	Color(0.3, 0.9, 1.0, 1.0),    # Cyan
	Color(1.0, 0.8, 0.2, 1.0),    # Gold
	Color(0.5, 1.0, 0.4, 1.0),    # Lime
	Color(1.0, 0.5, 0.3, 1.0)     # Coral
]

func _ready() -> void:
	# Scale for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	_create_star_field()
	_initialize_bodies()
	_connect_ui()
	_apply_vibrant_colors()

	# Auto-start simulation
	paused = false
	trails_enabled = true

func _create_star_field() -> void:
	# Create a background star field using a single MultiMeshInstance3D
	# instead of 200 individual CSGSphere3D nodes (saves ~200 RIDs).
	var star_field := get_node_or_null("StarField")
	if not star_field:
		return

	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.03
	star_mesh.height = 0.06
	star_mesh.radial_segments = 4
	star_mesh.rings = 2

	var star_material := StandardMaterial3D.new()
	star_material.albedo_color = Color.WHITE
	star_material.emission_enabled = true
	star_material.emission = Color.WHITE * 0.5
	star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = star_mesh
	mm.instance_count = 200

	# Seed star positions and random sizes via per-instance transforms
	for i in range(200):
		var angle1: float = randf_range(0, 2 * PI)
		var angle2: float = randf_range(0, PI)
		var radius: float = randf_range(50, 100)
		var pos := Vector3(
			radius * sin(angle2) * cos(angle1),
			radius * sin(angle2) * sin(angle1),
			radius * cos(angle2)
		)
		var s: float = randf_range(0.3, 1.5)  # Random scale variation
		var t := Transform3D(Basis().scaled(Vector3(s, s, s)), pos)
		mm.set_instance_transform(i, t)
		# Slight color variation for visual depth
		var brightness: float = randf_range(0.6, 1.0)
		mm.set_instance_color(i, Color(brightness, brightness, brightness + 0.1, 1.0))

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = star_material
	star_field.add_child(mmi)

func _initialize_bodies() -> void:
	var celestial = get_node_or_null("CelestialBodies")
	if not celestial:
		return
	bodies = celestial.get_children()
	
	# Initialize each body
	for body in bodies:
		body.initialize()

func _physics_process(delta: float) -> void:
	if paused:
		return

	# Auto-rotate for dynamic 3D view
	rotation_time += delta
	rotation.y = sin(rotation_time * 0.2) * 0.4
	rotation.x = cos(rotation_time * 0.15) * 0.15

	# Apply gravitational forces between all bodies
	_apply_gravitational_forces(delta)

	# Update body positions and velocities
	_update_bodies(delta)

	# Update trails
	if trails_enabled:
		_update_trails()

func _apply_gravitational_forces(_delta) -> void:
	# Calculate gravitational forces between all pairs of bodies
	for i in range(bodies.size()):
		for j in range(i + 1, bodies.size()):
			var body1 = bodies[i]
			var body2 = bodies[j]
			
			var distance_vector = body2.position - body1.position
			var distance = distance_vector.length()
			
			if distance > 0.1:  # Avoid division by zero
				var force_magnitude = gravitational_constant * body1.body_mass * body2.body_mass / (distance * distance)
				var force_direction = distance_vector.normalized()
				
				# Apply equal and opposite forces
				body1.apply_force(force_direction * force_magnitude)
				body2.apply_force(-force_direction * force_magnitude)

func _update_bodies(delta) -> void:
	# Update each body's physics
	for body in bodies:
		body.update_physics(delta * time_scale)

func _update_trails() -> void:
	# Update trails for each body
	for body in bodies:
		body.update_trail()

func _connect_ui() -> void:
	var reset_btn = get_node_or_null("UI/VBoxContainer/ResetButton")
	if reset_btn:
		reset_btn.pressed.connect(_on_reset_pressed)
	var pause_btn = get_node_or_null("UI/VBoxContainer/PauseButton")
	if pause_btn:
		pause_btn.pressed.connect(_on_pause_pressed)
	var trail_btn = get_node_or_null("UI/VBoxContainer/TrailToggle")
	if trail_btn:
		trail_btn.pressed.connect(_on_trail_toggle_pressed)
	var mass_slider = get_node_or_null("UI/VBoxContainer/MassSlider")
	if mass_slider:
		mass_slider.value_changed.connect(_on_mass_changed)

func _on_reset_pressed() -> void:
	# Reset all bodies to initial positions (CelestialBody.reset_to_initial
	# already clears trail_points and rebuilds the ImmediateMesh)
	for body in bodies:
		body.reset_to_initial()

func _on_pause_pressed() -> void:
	paused = !paused
	var pause_btn = get_node_or_null("UI/VBoxContainer/PauseButton")
	if pause_btn:
		pause_btn.text = "Resume" if paused else "Pause"

func _on_trail_toggle_pressed() -> void:
	trails_enabled = !trails_enabled
	var trail_btn = get_node_or_null("UI/VBoxContainer/TrailToggle")
	if trail_btn:
		trail_btn.text = "Trails: " + ("ON" if trails_enabled else "OFF")
	
	if !trails_enabled:
		# Clear trails by resetting each body's trail data
		for body in bodies:
			body.trail_points.clear()
			body._rebuild_trail_mesh()

func _on_mass_changed(value: float) -> void:
	# Update mass of all bodies
	for body in bodies:
		body.body_mass = value

	# Update UI label
	var mass_label = get_node_or_null("UI/VBoxContainer/MassLabel")
	if mass_label:
		mass_label.text = "Mass: " + str(int(value))

func _apply_vibrant_colors() -> void:
	# Apply vibrant queer colors to celestial bodies.
	# CelestialBody.set_trail_color() handles both body mesh and trail material.
	for i in range(bodies.size()):
		var body: CelestialBody = bodies[i] as CelestialBody
		if body == null:
			continue
		var color: Color = queer_colors[i % queer_colors.size()]
		body.set_trail_color(color)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
