
# ===============================
# TOPOLOGY MANAGER - Orchestrates the spaces
# ===============================
extends Node3D
class_name TopologyManager

@export var space_separation: float = 30.0
@export var teleport_height: float = 5.0

# Space Selection - Choose which mathematical territories to create
@export_group("Mathematical Spaces")
@export var create_sine_space: bool = true
@export var create_noise_space: bool = true
@export var create_voronoi_space: bool = true
@export var create_random_space: bool = true

# Optional: Advanced spaces
@export_group("Advanced Spaces") 
@export var create_mobius_space: bool = false
@export var create_torus_space: bool = false
@export var create_hyperbolic_space: bool = false

var spaces: Array[Node3D] = []
var current_space_index: int = 0

func _ready():
	create_selected_topology_spaces()

func create_selected_topology_spaces():
	spaces.clear()
	var position_index = 0
	
	# Create only selected spaces
	if create_sine_space:
		var sine_space = create_space("SineSpace", preload("res://commons/context/walkgrids/SineSpace.gd"))
		if sine_space:
			sine_space.position.x = position_index * space_separation
			spaces.append(sine_space)
			position_index += 1
	
	if create_noise_space:
		var noise_space = create_space("NoiseSpace", preload("res://commons/context/walkgrids/NoiseSpace.gd"))
		if noise_space:
			noise_space.position.x = position_index * space_separation
			spaces.append(noise_space)
			position_index += 1
	
	if create_voronoi_space:
		var voronoi_space = create_space("VoronoiSpace", preload("res://commons/context/walkgrids/VoronoiSpace.gd"))
		if voronoi_space:
			voronoi_space.position.x = position_index * space_separation
			spaces.append(voronoi_space)
			position_index += 1
	
	if create_random_space:
		var random_space = create_space("RandomSpace", preload("res://commons/context/walkgrids/RandomSpace.gd"))
		if random_space:
			random_space.position.x = position_index * space_separation
			spaces.append(random_space)
			position_index += 1
	
	# Advanced spaces (placeholder for future implementation)
	if create_mobius_space:
		print("Mobius space not yet implemented")
		# var mobius_space = create_mobius_space_instance()
	
	if create_torus_space:
		print("Torus space not yet implemented") 
		# var torus_space = create_torus_space_instance()
	
	if create_hyperbolic_space:
		print("Hyperbolic space not yet implemented")
		# var hyperbolic_space = create_hyperbolic_space_instance()
	
	print("Created %d mathematical spaces" % spaces.size())
	

func create_space(space_name: String, script_resource: Script) -> Node3D:
	var space = script_resource.new()
	space.name = space_name
	add_child(space)
	return space
