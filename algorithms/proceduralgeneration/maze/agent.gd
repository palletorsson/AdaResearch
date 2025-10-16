# agent.gd - AI agent that chases or flees from player
extends Node3D

@export var agent_color := Color.WHITE
@export var speed := 1.0
@export var is_goal := false
@export var trigger_message := "CAUGHT!"

var maze: Maze
var target_index: int
var target_position: Vector3

@onready var mesh_instance = $MeshInstance3D
@onready var light = $OmniLight3D
@onready var particles = $GPUParticles3D

func _ready():
	setup_visuals()

func setup_visuals():
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3.ONE
	mesh_instance.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = agent_color
	material.emission_enabled = true
	material.emission = agent_color
	material.emission_energy_multiplier = 10.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	light.light_color = agent_color
	light.omni_range = 6.0
	light.light_energy = 2.0
	light.shadow_enabled = true
	
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3.ZERO
	particle_material.spread = 180.0
	particle_material.initial_velocity_min = 0.0
	particle_material.initial_velocity_max = 0.0
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_material.emission_box_extents = Vector3(0.125, 0.125, 0.125)
	
	particles.process_material = particle_material
	particles.amount = 100
	particles.lifetime = 30.0
	particles.emitting = true
	particles.one_shot = false
	particles.local_coords = false
	
	var particle_mesh = BoxMesh.new()
	particle_mesh.size = Vector3(0.1, 0.1, 0.1)
	particles.draw_pass_1 = particle_mesh

func start_new_game(new_maze: Maze, coordinates: Vector2i):
	maze = new_maze
	target_index = maze.coordinates_to_index(coordinates)
	target_position = maze.coordinates_to_world_position(coordinates, position.y)
	position = target_position
	visible = true
	particles.emitting = true

func end_game():
	visible = false
	particles.emitting = false

func move(scent: Array, delta: float) -> Vector3:
	var pos = position
	var target_vector = target_position - pos
	var target_distance = target_vector.length()
	var movement = speed * delta
	
	while movement > target_distance:
		pos = target_position
		if try_find_new_target(scent):
			movement -= target_distance
			target_vector = target_position - pos
			target_distance = target_vector.length()
		else:
			position = pos
			return position
	
	position = pos + target_vector.normalized() * movement
	return position

func try_find_new_target(scent: Array) -> bool:
	var cell = maze.cells[target_index]
	var trail_index = -1
	var trail_scent = INF if is_goal else 0.0
	
	var best_trail = {"index": -1, "scent": trail_scent}
	
	if cell & Maze.PASSAGE_NE:
		sniff(scent, target_index + maze.get_step_n() + maze.get_step_e(), best_trail)
	if cell & Maze.PASSAGE_NW:
		sniff(scent, target_index + maze.get_step_n() + maze.get_step_w(), best_trail)
	if cell & Maze.PASSAGE_SE:
		sniff(scent, target_index + maze.get_step_s() + maze.get_step_e(), best_trail)
	if cell & Maze.PASSAGE_SW:
		sniff(scent, target_index + maze.get_step_s() + maze.get_step_w(), best_trail)
	
	if cell & Maze.PASSAGE_E:
		sniff(scent, target_index + maze.get_step_e(), best_trail)
	if cell & Maze.PASSAGE_W:
		sniff(scent, target_index + maze.get_step_w(), best_trail)
	if cell & Maze.PASSAGE_N:
		sniff(scent, target_index + maze.get_step_n(), best_trail)
	if cell & Maze.PASSAGE_S:
		sniff(scent, target_index + maze.get_step_s(), best_trail)
	
	if (is_goal and best_trail.scent < INF) or (not is_goal and best_trail.scent > 0.0):
		target_index = best_trail.index
		target_position = maze.index_to_world_position(target_index, target_position.y)
		return true
	
	return false

func sniff(scent: Array, sniff_index: int, best_trail: Dictionary):
	if sniff_index < 0 or sniff_index >= scent.size():
		return
	
	var detected_scent = scent[sniff_index]
	if is_goal:
		if detected_scent < best_trail.scent:
			best_trail.scent = detected_scent
			best_trail.index = sniff_index
	else:
		if detected_scent > best_trail.scent:
			best_trail.scent = detected_scent
			best_trail.index = sniff_index
