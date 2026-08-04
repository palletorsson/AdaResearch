extends Node3D


# @identity
# essence: height(x,z,t) = A * sin(omega*x + phi*t) * sin(omega*z) — 2D sine surface
# desire: Stand on a living floor that undulates with sine waves in multiple topologies
# critical_parameter: frequency — controls spatial density of the wave pattern across the surface
# triggers: topology_timer cycles through flat, cylindrical, spherical, toroidal, Mobius mappings
# emerges: the same sine function looks completely different in different coordinate systems
# needs: VR standing on surface [has], topology switching [has]
# relationships: depends on MultiMesh height-field rendering; contrasts with wave_propagation_3d (continuous surface vs tile grid); unlocks topology intuition
# truth: The sine function is universal — it generates different worlds depending on the coordinate system you wrap it in.

# --- DNA ---------------------------------------------------------------------
# manifold: which coordinate system the sine is wrapped onto. "cycle" is the shipped
#   behaviour — the 5-second timer walks all five in turn. Every other value PINS one
#   manifold and stops the timer, so the placement is one place instead of a carousel.
# crossing: how the two sine directions meet. "product" is the shipped egg-crate.
@export_enum("cycle", "plane", "cylinder", "sphere", "torus", "mobius") var manifold: String = "cycle"
@export_enum("product", "sum", "radial", "single") var crossing: String = "product"

var time = 0.0
var grid_size = 25
var instance_count: int
var frequency = 1.0
var amplitude = 1.5
var phase = 0.0
var topology_timer = 0.0
var topology_interval = 5.0

# MultiMesh references
var multi_mesh_instance: MultiMeshInstance3D
var multi_mesh: MultiMesh

# Topology modes
enum TopologyMode {
	FLAT_SINE,
	CYLINDRICAL,
	SPHERICAL,
	TOROIDAL,
	MOBIUS_STRIP
}

var current_topology = TopologyMode.FLAT_SINE

func _ready() -> void:
	instance_count = grid_size * grid_size
	create_multimesh_surface()
	setup_materials()
	_create_capture_anchor()
	_apply_manifold()

# The surface is a MultiMeshInstance3D and the four controls are CSG nodes, so this
# artifact owns not one MeshInstance3D — a measuring camera reads it as a 1 m box and
# frames a 10 m field as if it were a mug. This anchor is sized to the surface in its
# widest topology (spherical, r = 3 + amplitude). layers = 0 means no camera in the game
# ever draws it; it exists only to be measured.
func _create_capture_anchor() -> void:
	var anchor := MeshInstance3D.new()
	anchor.name = "CaptureAnchor"
	var bm := BoxMesh.new()
	bm.size = Vector3(11.0, 11.0, 11.0)
	anchor.mesh = bm
	anchor.layers = 0
	add_child(anchor)

func _apply_manifold() -> void:
	match manifold:
		"cylinder":
			current_topology = TopologyMode.CYLINDRICAL
		"sphere":
			current_topology = TopologyMode.SPHERICAL
		"torus":
			current_topology = TopologyMode.TOROIDAL
		"mobius":
			current_topology = TopologyMode.MOBIUS_STRIP
		_:
			# "plane" and "cycle" both start flat — which is the value the shipped
			# `current_topology` initialiser already held.
			current_topology = TopologyMode.FLAT_SINE
	topology_timer = 0.0

func create_multimesh_surface() -> void:
	# Create the MultiMeshInstance3D as a child of SineSurface
	multi_mesh_instance = MultiMeshInstance3D.new()
	$SineSurface.add_child(multi_mesh_instance)

	# Create the MultiMesh resource
	multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.use_colors = true
	multi_mesh.instance_count = instance_count

	# Create the sphere mesh (matching original radius)
	var sphere = SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	sphere.radial_segments = 8
	sphere.rings = 4
	multi_mesh.mesh = sphere

	# Create material with vertex colors and emission glow
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 1.5

	# We'll use a moderate emission color; per-instance color modulates via albedo
	mat.emission = Color(0.3, 0.3, 0.3)
	sphere.material = mat

	multi_mesh_instance.multimesh = multi_mesh

	# Initialize transforms to origin
	for i in range(instance_count):
		multi_mesh.set_instance_transform(i, Transform3D(Basis(), Vector3.ZERO))
		multi_mesh.set_instance_color(i, Color.WHITE)

func setup_materials() -> void:
	# Control materials (unchanged — only 4 CSG nodes)
	var freq_material = StandardMaterial3D.new()
	freq_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	freq_material.emission_enabled = true
	freq_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$FrequencyControl.material_override = freq_material

	var amp_material = StandardMaterial3D.new()
	amp_material.albedo_color = Color(0.3, 1.0, 0.3, 1.0)
	amp_material.emission_enabled = true
	amp_material.emission = Color(0.1, 0.5, 0.1, 1.0)
	$AmplitudeControl.material_override = amp_material

	var phase_material = StandardMaterial3D.new()
	phase_material.albedo_color = Color(0.3, 0.3, 1.0, 1.0)
	phase_material.emission_enabled = true
	phase_material.emission = Color(0.1, 0.1, 0.5, 1.0)
	$PhaseControl.material_override = phase_material

	var topology_material = StandardMaterial3D.new()
	topology_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	topology_material.emission_enabled = true
	topology_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$TopologyMode.material_override = topology_material

func _process(delta: float) -> void:
	time += delta

	# Switch topology modes — only while the manifold is left un-pinned.
	if manifold == "cycle":
		topology_timer += delta
		if topology_timer >= topology_interval:
			topology_timer = 0.0
			current_topology = (current_topology + 1) % TopologyMode.size()

	# Update parameters
	frequency = 1.0 + sin(time * 0.3) * 0.5
	amplitude = 1.5 + cos(time * 0.2) * 0.8
	phase = time * 2.0

	update_sine_surface()
	animate_controls()

func update_sine_surface() -> void:
	match current_topology:
		TopologyMode.FLAT_SINE:
			update_flat_sine_surface()
		TopologyMode.CYLINDRICAL:
			update_cylindrical_surface()
		TopologyMode.SPHERICAL:
			update_spherical_surface()
		TopologyMode.TOROIDAL:
			update_toroidal_surface()
		TopologyMode.MOBIUS_STRIP:
			update_mobius_surface()

# --- How the two sine directions meet -----------------------------------------
# Every topology below modulated its surface with sin(f*a + phase) * sin(f*b + phase*k).
# That product is one answer to "what happens where an x-wave crosses a z-wave", not the
# only one, and the four answers look nothing alike: a field of bumps, a run of diagonal
# ridges, concentric rings, or a plain corrugation that never crosses anything.
func _wave(a: float, b: float, k: float) -> float:
	match crossing:
		"sum":
			return (sin(frequency * a + phase) + sin(frequency * b + phase * k)) * 0.5
		"radial":
			return sin(frequency * sqrt(a * a + b * b) + phase)
		"single":
			return sin(frequency * a + phase)
		_:
			return sin(frequency * a + phase) * sin(frequency * b + phase * k)

# --- Height-to-color gradient: blue (low) → cyan (mid) → orange (high) ---
func height_to_color(height_value: float) -> Color:
	var t = (height_value + amplitude) / (2.0 * amplitude)
	t = clamp(t, 0.0, 1.0)

	var color: Color
	if t < 0.5:
		# Blue → Cyan  (0.0 → 0.5)
		var s = t * 2.0
		color = Color(0.1, 0.2 + 0.6 * s, 0.9 - 0.1 * s)
	else:
		# Cyan → Orange (0.5 → 1.0)
		var s = (t - 0.5) * 2.0
		color = Color(0.1 + 0.9 * s, 0.8 - 0.3 * s, 0.8 - 0.7 * s)

	return color

# --- Topology update functions (MultiMesh) ---

func update_flat_sine_surface() -> void:
	for x in range(grid_size):
		for z in range(grid_size):
			var idx = x * grid_size + z

			var x_normalized = (x - grid_size / 2.0) / (grid_size / 2.0)
			var z_normalized = (z - grid_size / 2.0) / (grid_size / 2.0)

			var x_pos = x_normalized * 5.0
			var z_pos = z_normalized * 5.0

			var height = amplitude * _wave(x_normalized * PI, z_normalized * PI, 0.7)

			multi_mesh.set_instance_transform(idx, Transform3D(Basis(), Vector3(x_pos, height, z_pos)))
			multi_mesh.set_instance_color(idx, height_to_color(height))

func update_cylindrical_surface() -> void:
	for x in range(grid_size):
		for z in range(grid_size):
			var idx = x * grid_size + z

			var u = (x / float(grid_size)) * 2.0 * PI
			var v = (z - grid_size / 2.0) / (grid_size / 2.0) * 3.0

			var radius = 3.0 + amplitude * _wave(u, v * 0.5, 1.0)

			var pos = Vector3(
				radius * cos(u),
				v,
				radius * sin(u)
			)
			multi_mesh.set_instance_transform(idx, Transform3D(Basis(), pos))
			multi_mesh.set_instance_color(idx, height_to_color(radius - 3.0))

func update_spherical_surface() -> void:
	for x in range(grid_size):
		for z in range(grid_size):
			var idx = x * grid_size + z

			var theta = (x / float(grid_size)) * 2.0 * PI
			var phi = (z / float(grid_size)) * PI

			var radius = 3.0 + amplitude * _wave(theta, phi, 0.8)

			var pos = Vector3(
				radius * sin(phi) * cos(theta),
				radius * cos(phi),
				radius * sin(phi) * sin(theta)
			)
			multi_mesh.set_instance_transform(idx, Transform3D(Basis(), pos))
			multi_mesh.set_instance_color(idx, height_to_color(radius - 3.0))

func update_toroidal_surface() -> void:
	for x in range(grid_size):
		for z in range(grid_size):
			var idx = x * grid_size + z

			var u = (x / float(grid_size)) * 2.0 * PI
			var v = (z / float(grid_size)) * 2.0 * PI

			var major_radius = 3.0
			var minor_radius = 1.0 + amplitude * _wave(u, v, 0.6)

			var pos = Vector3(
				(major_radius + minor_radius * cos(v)) * cos(u),
				minor_radius * sin(v),
				(major_radius + minor_radius * cos(v)) * sin(u)
			)
			multi_mesh.set_instance_transform(idx, Transform3D(Basis(), pos))
			multi_mesh.set_instance_color(idx, height_to_color(minor_radius - 1.0))

func update_mobius_surface() -> void:
	for x in range(grid_size):
		for z in range(grid_size):
			var idx = x * grid_size + z

			var u = (x / float(grid_size)) * 2.0 * PI
			var v = (z - grid_size / 2.0) / (grid_size / 2.0) * 0.5

			var radius = 2.0 + amplitude * sin(frequency * u * 2.0 + phase) * 0.5
			var twist_factor = 1.0 + amplitude * sin(frequency * u + phase) * 0.3

			var pos = Vector3(
				(radius + v * cos(u / 2.0) * twist_factor) * cos(u),
				v * sin(u / 2.0) * twist_factor,
				(radius + v * cos(u / 2.0) * twist_factor) * sin(u)
			)
			multi_mesh.set_instance_transform(idx, Transform3D(Basis(), pos))
			multi_mesh.set_instance_color(idx, height_to_color(v * twist_factor))

# --- Control animations (unchanged) ---

func animate_controls() -> void:
	# Frequency control
	var freq_height = frequency * 0.8 + 0.5
	$FrequencyControl.height = freq_height
	$FrequencyControl.position.y = -3 + freq_height / 2

	# Amplitude control
	var amp_height = amplitude * 0.6 + 0.5
	$AmplitudeControl.height = amp_height
	$AmplitudeControl.position.y = -3 + amp_height / 2

	# Phase control (rotating)
	var phase_height = 1.0 + sin(phase) * 0.3
	$PhaseControl.height = phase_height
	$PhaseControl.position.y = -3 + phase_height / 2
	$PhaseControl.rotation_degrees.y = phase * 180.0 / PI

	# Topology mode indicator
	var topology_height = (current_topology + 1) * 0.3 + 0.5
	$TopologyMode.size.y = topology_height
	$TopologyMode.position.y = -3 + topology_height / 2

	# Update topology indicator color
	var topology_material = $TopologyMode.material_override as StandardMaterial3D
	if topology_material:
		match current_topology:
			TopologyMode.FLAT_SINE:
				topology_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
			TopologyMode.CYLINDRICAL:
				topology_material.albedo_color = Color(0.8, 1.0, 0.2, 1.0)
			TopologyMode.SPHERICAL:
				topology_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
			TopologyMode.TOROIDAL:
				topology_material.albedo_color = Color(0.2, 0.8, 1.0, 1.0)
			TopologyMode.MOBIUS_STRIP:
				topology_material.albedo_color = Color(1.0, 0.2, 0.8, 1.0)

		topology_material.emission = topology_material.albedo_color * 0.3

	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$FrequencyControl.scale.x = pulse
	$AmplitudeControl.scale.x = pulse
	$PhaseControl.scale.x = pulse
	$TopologyMode.scale.x = pulse

func get_topology_name() -> String:
	match current_topology:
		TopologyMode.FLAT_SINE:
			return "Flat Sine Surface"
		TopologyMode.CYLINDRICAL:
			return "Cylindrical"
		TopologyMode.SPHERICAL:
			return "Spherical"
		TopologyMode.TOROIDAL:
			return "Toroidal"
		TopologyMode.MOBIUS_STRIP:
			return "Möbius Strip"
		_:
			return "Unknown"

func get_topology_equation() -> String:
	match current_topology:
		TopologyMode.FLAT_SINE:
			return "z = A*sin(fx)*sin(fz)"
		TopologyMode.CYLINDRICAL:
			return "r = R + A*sin(fu)*sin(fv)"
		TopologyMode.SPHERICAL:
			return "r = R + A*sin(fθ)*sin(fφ)"
		TopologyMode.TOROIDAL:
			return "r_minor = R + A*sin(fu)*sin(fv)"
		TopologyMode.MOBIUS_STRIP:
			return "Möbius with sine modulation"
		_:
			return "Unknown"

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# Guarded: only touch state when a value actually arrived AND actually differs.
	# There is no build to redo — the surface is recomputed from scratch every frame —
	# so the manifold switch only has to re-point current_topology and reset the timer.
	if config.has("manifold"):
		var m: String = str(config["manifold"])
		if m != "" and m != manifold:
			manifold = m
			if is_node_ready():
				_apply_manifold()
	if config.has("crossing"):
		var c: String = str(config["crossing"])
		if c != "" and c != crossing:
			crossing = c
