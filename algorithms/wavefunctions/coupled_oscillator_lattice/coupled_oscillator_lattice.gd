# @identity
# essence: a 2D grid of mass-spring oscillators where each cell nudges its neighbors via configurable coupling — independent at coupling=0, lattice-locked at high values, with central excitation driving the spectrum
# desire: to make the player feel that "wave" is not a thing but a relationship — when one oscillator moves, the lattice answers, and standing modes are simply patterns of agreement
# critical_parameter: coupling_strength — at 0 the grid is independent oscillators; at high values it locks into collective Chladni-like modes; the entire wave spectrum lives on this slider
# triggers: _physics_process() integrates each cell with its neighbors using natural_frequency and damping_coefficient; excitation_amplitude × excitation_frequency drives the central pulse outward through coupling_range
# emerges: standing waves on a grid — synchronization fronts, breathing modes, traveling pulses; the lattice becomes a tunable resonance instrument the player can walk into
# needs: VR walking through the lattice [has]; live coupling-strength slider [missing]; mode-visualization toggle [missing]; apply_grid_config [missing]
# relationships: pairs with wave_interference, sine_space, and seismograph in wavefunctions as the medium that the others measure or excite; reappears in advancedlaboratory's Systems Theory Laboratory as the keystone artifact
# truth: a wave is not a particle traveling — it is a pattern of agreement across coupled cells; the lattice IS the medium

@tool
extends Node3D

# Coupled Oscillator Lattice
# Grid of oscillators where each affects its neighbors
# Demonstrates wave modes, synchronization, and collective behavior

@export_group("Lattice Structure")
@export var lattice_size: Vector2i = Vector2i(12, 12)
@export var oscillator_spacing: float = 0.4
@export var base_height: float = 1.0

@export_group("Oscillator Properties")
@export var natural_frequency: float = 2.0  # Ï‰â‚€
@export var mass: float = 1.0
@export var damping_coefficient: float = 0.02

@export_group("Coupling")
@export var coupling_strength: float = 1.5  # How strongly neighbors affect each other
@export var coupling_range: int = 1  # 1 = nearest neighbors only

@export_group("Excitation")
@export var excite_center: bool = true
@export var excitation_amplitude: float = 0.5
@export var excitation_frequency: float = 2.0
@export_enum("Sine", "Pulse", "Random") var excitation_mode: String = "Sine"

@export_group("Visualization")
@export var oscillator_radius: float = 0.06
@export var color_by_displacement: bool = true
@export var show_connections: bool = false
@export var max_displacement_color: float = 0.8

# Internal data
var oscillators: Array[Dictionary] = []
var time: float = 0.0
var pulse_triggered: bool = false

func _ready() -> void:
	_build_lattice()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	time += delta

	# Apply excitation
	if excite_center:
		_apply_excitation(delta)

	# Update oscillator physics
	_update_oscillators(delta)

	# Update visualization
	_update_visualization()

func _build_lattice() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()

	oscillators.clear()

	# Create oscillators
	for x in range(lattice_size.x):
		for y in range(lattice_size.y):
			var idx = x * lattice_size.y + y
			var grid_pos = Vector2(x, y)

			var oscillator_data = {
				"index": idx,
				"grid_pos": grid_pos,
				"position": Vector3(
					(x - lattice_size.x / 2.0) * oscillator_spacing,
					base_height,
					(y - lattice_size.y / 2.0) * oscillator_spacing
				),
				"displacement": 0.0,  # y displacement from equilibrium
				"velocity": 0.0,
				"acceleration": 0.0,
				"phase": randf() * TAU  # Random initial phase
			}

			oscillators.append(oscillator_data)

			# Create visual sphere
			_create_oscillator_visual(oscillator_data)

func _create_oscillator_visual(osc: Dictionary) -> void:
	var sphere = MeshInstance3D.new()
	sphere.name = "Oscillator_%d" % osc.index

	var mesh = SphereMesh.new()
	mesh.radius = oscillator_radius
	mesh.height = oscillator_radius * 2.0
	sphere.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 1.0)
	mat.metallic = 0.0
	mat.roughness = 1.0
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.3, 0.8)
	mat.emission_energy_multiplier = 0.5
	sphere.material_override = mat

	sphere.position = osc.position
	add_child(sphere)

func _apply_excitation(_delta: float) -> void:
	# Find center oscillator
	var center_x = int(lattice_size.x / 2)
	var center_y = int(lattice_size.y / 2)
	var center_idx = center_x * lattice_size.y + center_y

	if center_idx >= oscillators.size():
		return

	var osc = oscillators[center_idx]

	match excitation_mode:
		"Sine":
			# Continuous sine wave
			var excitation = excitation_amplitude * sin(time * excitation_frequency * TAU)
			osc.displacement = excitation

		"Pulse":
			# Single pulse at start
			if not pulse_triggered and time > 0.5:
				osc.velocity += excitation_amplitude * 10.0
				pulse_triggered = true

		"Random":
			# Random excitation
			if randf() < 0.01:  # 1% chance per frame
				osc.velocity += excitation_amplitude * randf_range(-1.0, 1.0)

func _update_oscillators(delta: float) -> void:
	# Calculate forces from coupling
	var forces: Array[float] = []
	forces.resize(oscillators.size())

	for i in range(oscillators.size()):
		var osc = oscillators[i]
		var total_force = 0.0

		# Restoring force (like a spring to equilibrium)
		var omega_squared = natural_frequency * natural_frequency
		total_force -= omega_squared * osc.displacement

		# Coupling force from neighbors
		var neighbors = _get_neighbors(osc.grid_pos)
		for neighbor_idx in neighbors:
			if neighbor_idx >= 0 and neighbor_idx < oscillators.size():
				var neighbor = oscillators[neighbor_idx]
				# Force proportional to displacement difference
				var coupling_force = coupling_strength * (neighbor.displacement - osc.displacement)
				total_force += coupling_force

		# Damping
		total_force -= damping_coefficient * osc.velocity

		forces[i] = total_force

	# Integrate using velocity Verlet or simple Euler
	for i in range(oscillators.size()):
		var osc = oscillators[i]
		var force = forces[i]

		# F = ma, so a = F/m
		osc.acceleration = force / mass

		# Update velocity and position (Euler integration)
		osc.velocity += osc.acceleration * delta
		osc.displacement += osc.velocity * delta

func _get_neighbors(grid_pos: Vector2) -> Array[int]:
	"""Get indices of neighboring oscillators"""
	var neighbors: Array[int] = []

	for dx in range(-coupling_range, coupling_range + 1):
		for dy in range(-coupling_range, coupling_range + 1):
			if dx == 0 and dy == 0:
				continue  # Skip self

			var nx = int(grid_pos.x) + dx
			var ny = int(grid_pos.y) + dy

			# Check bounds
			if nx >= 0 and nx < lattice_size.x and ny >= 0 and ny < lattice_size.y:
				var neighbor_idx = nx * lattice_size.y + ny
				neighbors.append(neighbor_idx)

	return neighbors

func _update_visualization() -> void:
	for i in range(oscillators.size()):
		var osc = oscillators[i]
		var child_name = "Oscillator_%d" % i
		var child = get_node_or_null(NodePath(child_name))

		if child and child is MeshInstance3D:
			# Update position (oscillate in Y)
			child.position = osc.position + Vector3(0, osc.displacement, 0)

			# Update color based on displacement
			if color_by_displacement:
				var displacement_normalized = clamp(abs(osc.displacement) / max_displacement_color, 0.0, 1.0)
				var color = Color.from_hsv(0.6 - displacement_normalized * 0.3, 0.8, 1.0)

				var mat = child.material_override as StandardMaterial3D
				if mat:
					mat.albedo_color = color
					mat.emission = color * 0.5
					mat.emission_energy_multiplier = displacement_normalized + 0.2

func get_displacement_at(grid_x: int, grid_y: int) -> float:
	"""Get displacement of oscillator at grid position"""
	if grid_x >= 0 and grid_x < lattice_size.x and grid_y >= 0 and grid_y < lattice_size.y:
		var idx = grid_x * lattice_size.y + grid_y
		if idx < oscillators.size():
			return oscillators[idx].displacement
	return 0.0

func apply_displacement(grid_x: int, grid_y: int, displacement: float) -> void:
	"""Manually set displacement at specific oscillator"""
	if grid_x >= 0 and grid_x < lattice_size.x and grid_y >= 0 and grid_y < lattice_size.y:
		var idx = grid_x * lattice_size.y + grid_y
		if idx < oscillators.size():
			oscillators[idx].displacement = displacement

func get_total_energy() -> float:
	"""Calculate total energy in the system"""
	var total_energy = 0.0
	for osc in oscillators:
		# Kinetic energy
		var ke = 0.5 * mass * osc.velocity * osc.velocity
		# Potential energy
		var pe = 0.5 * mass * natural_frequency * natural_frequency * osc.displacement * osc.displacement
		total_energy += ke + pe
	return total_energy

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
