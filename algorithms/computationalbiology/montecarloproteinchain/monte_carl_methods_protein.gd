extends Node3D

# Monte Carlo Protein Chain Simulation
# This script simulates protein folding using Monte Carlo methods

# Constants
const AMINO_ACIDS = ["ALA", "ARG", "ASN", "ASP", "CYS", "GLN", "GLU", "GLY", "HIS", "ILE", 
					 "LEU", "LYS", "MET", "PHE", "PRO", "SER", "THR", "TRP", "TYR", "VAL"]
const NUM_RESIDUES = 30  # Length of the protein chain
const BOND_LENGTH = 0.8  # Distance between amino acids
const BOND_ANGLE_RANGE = PI/4  # Max angle change during simulation
const TEMPERATURE = 1.0  # Simulation temperature (controls acceptance probability)
const ITERATIONS = 1000  # Number of Monte Carlo iterations
const ITERATION_STEPS = 10  # Steps per visual update

# Residue properties (simplified)
const HYDROPHOBIC = ["ALA", "ILE", "LEU", "MET", "PHE", "TRP", "TYR", "VAL"]
const HYDROPHILIC = ["ARG", "ASN", "ASP", "CYS", "GLN", "GLU", "GLY", "HIS", "LYS", "PRO", "SER", "THR"]
const CHARGE_POSITIVE = ["ARG", "HIS", "LYS"]
const CHARGE_NEGATIVE = ["ASP", "GLU"]

# Variables
var residues = []  # Stores amino acid types
var positions = []  # Stores 3D positions
var spheres = []  # Stores the visual representation
var bonds = []  # Stores the visual links between residues
var current_energy = 0.0
var iteration_count = 0
var rng = RandomNumberGenerator.new()
var paused = false
var energy_label: Label3D

# Class representing an amino acid residue
class Residue:
	var type: String
	var hydrophobic: bool
	var charge: int  # -1, 0, or 1
	
	func _init(aa_type: String):
		type = aa_type
		hydrophobic = HYDROPHOBIC.has(aa_type)
		charge = 0
		if CHARGE_POSITIVE.has(aa_type):
			charge = 1
		elif CHARGE_NEGATIVE.has(aa_type):
			charge = -1

func _ready():
	rng.randomize()
	
	# Setup UI elements
	setup_ui()
	
	# Generate a random protein sequence and initial structure
	generate_protein()
	
	# Create initial visualization
	create_visualization()
	
	# Calculate initial energy
	current_energy = calculate_energy()
	update_energy_display()
	
	# Start Monte Carlo simulation
	start_simulation()

func _process(delta):
	# Slowly rotate the protein for better visualization
	rotate_y(delta * 0.2)

func generate_protein():
	residues.clear()
	positions.clear()
	
	# Generate random amino acid sequence
	for i in range(NUM_RESIDUES):
		var aa_type = AMINO_ACIDS[rng.randi() % AMINO_ACIDS.size()]
		residues.append(Residue.new(aa_type))
	
	# Generate initial positions in a straight line
	for i in range(NUM_RESIDUES):
		positions.append(Vector3(i * BOND_LENGTH, 0, 0))

func setup_ui():
	# Create energy display
	energy_label = Label3D.new()
	energy_label.text = "Energy: 0.0"
	energy_label.position = Vector3(0, 5, 0)
	energy_label.font_size = 64
	energy_label.modulate = Color(1, 1, 0)  # Yellow text
	add_child(energy_label)
	
	# Create a pause button using a 3D button
	var pause_button = Button.new()
	pause_button.text = "Pause/Resume"
	pause_button.position = Vector2(50, 50)
	pause_button.size = Vector2(120, 40)
	pause_button.pressed.connect(_on_pause_button_pressed)
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(pause_button)
	add_child(canvas_layer)

func _on_pause_button_pressed():
	paused = !paused
	if paused:
		$SimulationTimer.stop()
	else:
		$SimulationTimer.start()

func create_visualization():
	# Remove any existing visualization
	for sphere in spheres:
		sphere.queue_free()
	spheres.clear()
	
	for bond in bonds:
		bond.queue_free()
	bonds.clear()
	
	# Create spheres for each amino acid
	for i in range(residues.size()):
		var sphere = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = 0.3
		mesh.height = 0.6
		sphere.mesh = mesh
		
		var material = StandardMaterial3D.new()
		
		# Color based on properties
		if residues[i].hydrophobic:
			material.albedo_color = Color(1, 0.5, 0, 0.8)  # Orange for hydrophobic
		else:
			material.albedo_color = Color(0, 0.7, 1, 0.8)  # Blue for hydrophilic
		
		# Add charge indicators
		if residues[i].charge > 0:
			material.albedo_color = Color(1, 0, 0, 0.8)  # Red for positive
		elif residues[i].charge < 0:
			material.albedo_color = Color(0, 0, 1, 0.8)  # Blue for negative
		
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sphere.material_override = material
		
		sphere.position = positions[i]
		add_child(sphere)
		spheres.append(sphere)
		
		# Create bonds between residues
		if i > 0:
			var bond = create_bond(positions[i-1], positions[i])
			bonds.append(bond)
	
	# Center the protein
	center_protein()

func create_bond(pos1: Vector3, pos2: Vector3) -> MeshInstance3D:
	var bond = MeshInstance3D.new()
	
	# Calculate midpoint and look at direction
	var midpoint = (pos1 + pos2) / 2
	var direction = pos2 - pos1
	var length = direction.length()
	
	# Create cylinder mesh
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.1
	mesh.bottom_radius = 0.1
	mesh.height = length
	bond.mesh = mesh
	
	# Set position and rotation
	bond.position = midpoint
	
	# Calculate rotation to point from pos1 to pos2
	var up_vector = Vector3(0, 1, 0)
	if abs(direction.normalized().dot(up_vector)) > 0.99:
		up_vector = Vector3(1, 0, 0)  # Use different up vector if direction is parallel
	
	bond.look_at_from_position(midpoint, pos2, up_vector)
	
	# Material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7, 0.8)  # Gray
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bond.material_override = material
	
	add_child(bond)
	return bond

func center_protein():
	# Calculate center of mass
	var center = Vector3.ZERO
	for pos in positions:
		center += pos
	center /= positions.size()
	
	# Move protein to center
	for i in range(positions.size()):
		positions[i] -= center
		if i < spheres.size():
			spheres[i].position = positions[i]
	
	# Update bonds
	update_bonds()

func update_bonds():
	for i in range(bonds.size()):
		bonds[i].queue_free()
	bonds.clear()
	
	for i in range(1, positions.size()):
		var bond = create_bond(positions[i-1], positions[i])
		bonds.append(bond)

func start_simulation():
	var timer = Timer.new()
	timer.wait_time = 0.05  # 50ms between visual updates
	timer.timeout.connect(_monte_carlo_step)
	timer.autostart = true
	timer.name = "SimulationTimer"
	add_child(timer)

func _monte_carlo_step():
	if iteration_count >= ITERATIONS:
		$SimulationTimer.stop()
		print("Simulation complete!")
		return
	
	# Perform multiple MC steps between visual updates for efficiency
	for step in range(ITERATION_STEPS):
		perform_monte_carlo_iteration()
	
	# Update visualization
	for i in range(positions.size()):
		spheres[i].position = positions[i]
	
	update_bonds()
	update_energy_display()

func perform_monte_carlo_iteration():
	# Choose a random residue (excluding first and last to simplify)
	var residue_idx = rng.randi_range(1, positions.size() - 2)
	
	# Store original position
	var original_position = positions[residue_idx]
	
	# Propose a new position by randomly moving while maintaining bond length
	var prev_to_current = positions[residue_idx] - positions[residue_idx - 1]
	var current_to_next = positions[residue_idx + 1] - positions[residue_idx]
	
	# Create a random rotation axis
	var rotation_axis = Vector3(
		rng.randf_range(-1, 1),
		rng.randf_range(-1, 1),
		rng.randf_range(-1, 1)
	).normalized()
	
	# Random rotation angle
	var angle = rng.randf_range(-BOND_ANGLE_RANGE, BOND_ANGLE_RANGE)
	
	# Apply rotation to current-to-next vector
	var rotated_vector = current_to_next.rotated(rotation_axis, angle)
	
	# Calculate new position for the current residue
	var new_position = positions[residue_idx - 1] + prev_to_current.normalized() * BOND_LENGTH
	
	# Calculate new position for the next residue
	var new_next_position = new_position + rotated_vector.normalized() * BOND_LENGTH
	
	# Temporarily apply the changes
	positions[residue_idx] = new_position
	positions[residue_idx + 1] = new_next_position
	
	# Calculate energy difference
	var new_energy = calculate_energy()
	var energy_diff = new_energy - current_energy
	
	# Metropolis criterion for accepting/rejecting the move
	var accept = false
	if energy_diff <= 0:
		# Accept moves that lower energy
		accept = true
	else:
		# Accept some moves that increase energy based on Boltzmann probability
		var acceptance_probability = exp(-energy_diff / TEMPERATURE)
		if rng.randf() < acceptance_probability:
			accept = true
	
	if accept:
		# Accept the new configuration
		current_energy = new_energy
	else:
		# Reject and revert to the original position
		positions[residue_idx] = original_position
		positions[residue_idx + 1] = positions[residue_idx] + current_to_next
	
	iteration_count += 1

func calculate_energy() -> float:
	var energy = 0.0
	
	# Calculate various energy contributions
	
	# 1. Bond angle energy - penalize extreme angles
	for i in range(1, positions.size() - 1):
		var v1 = (positions[i-1] - positions[i]).normalized()
		var v2 = (positions[i+1] - positions[i]).normalized()
		var angle = acos(clamp(v1.dot(v2), -1.0, 1.0))
		
		# Penalize deviations from ideal angle (approximately 109.5 degrees for proteins)
		var ideal_angle = 1.91 # ~109.5 degrees in radians
		energy += 10.0 * pow(angle - ideal_angle, 2)
	
	# 2. Non-bonded interactions
	for i in range(positions.size()):
		for j in range(i + 3, positions.size()):  # Skip adjacent residues
			var distance = positions[i].distance_to(positions[j])
			
			# Skip residues that are too far apart (optimization)
			if distance > 5.0:
				continue
			
			# Lennard-Jones potential (simplified)
			var sigma = 1.0  # Equilibrium distance
			var epsilon = 1.0  # Depth of potential well
			
			var repulsive_term = pow(sigma / distance, 12)
			var attractive_term = pow(sigma / distance, 6)
			
			# Calculate interaction strength based on residue types
			var interaction_strength = 1.0
			
			# Hydrophobic interactions
			if residues[i].hydrophobic and residues[j].hydrophobic:
				interaction_strength = 2.0  # Stronger attraction
			
			# Electrostatic interactions
			if residues[i].charge != 0 and residues[j].charge != 0:
				if residues[i].charge * residues[j].charge > 0:
					# Same charge - repulsion
					interaction_strength = 0.5  # Weaker attraction
				else:
					# Opposite charge - attraction
					interaction_strength = 3.0  # Stronger attraction
			
			var lj_energy = 4.0 * epsilon * interaction_strength * (repulsive_term - attractive_term)
			energy += lj_energy
	
	# 3. Hydrophobic burial (simplified)
	for i in range(positions.size()):
		if residues[i].hydrophobic:
			# Count neighbors within a radius
			var neighbor_count = 0
			for j in range(positions.size()):
				if i != j and positions[i].distance_to(positions[j]) < 2.0:
					neighbor_count += 1
			
			# Reward buried hydrophobic residues
			energy -= neighbor_count * 1.0
		else:
			# Count how "buried" a hydrophilic residue is
			var center_distance = positions[i].length()
			if center_distance < 2.0:
				# Penalize buried hydrophilic residues
				energy += (2.0 - center_distance) * 2.0
	
	return energy

func update_energy_display():
	energy_label.text = "Energy: %.2f\nIteration: %d/%d" % [current_energy, iteration_count, ITERATIONS]

# Setup camera and lights for better viewing
func _enter_tree():
	# Set up camera
	var camera = Camera3D.new()
	camera.position = Vector3(0, 0, 20)
	add_child(camera)
	
	# Add a directional light
	var light = DirectionalLight3D.new()
	light.position = Vector3(10, 10, 10)
	light.look_at_from_position(Vector3(10, 10, 10), Vector3.ZERO, Vector3.UP)
	add_child(light)
	
	# Add ambient light
	var ambient_light = DirectionalLight3D.new()
	ambient_light.position = Vector3(-10, -5, -10)
	ambient_light.light_energy = 0.5
	ambient_light.look_at_from_position(Vector3(-10, -5, -10), Vector3.ZERO, Vector3.UP)
	add_child(ambient_light)
