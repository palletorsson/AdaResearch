@tool
extends Node3D

@export var width: int = 128              # Width of the image texture
@export var height: int = 128             # Height of the image texture
@export var area_size: int = 2            # Size of each step in the random walk
@export var interval: float = 0.1         # Time interval between steps
@export var label_text: String = ""       # Label text
@onready var label3d = $GrabPaper/id_info_Label3D
var sample_rate: int = 2                  # Defines how frequently the texture is sampled

enum WalkSelection { AUTO, SIMPLE, DIAGONAL, BROWNIAN, FRACTAL, FIBONACCI_SPIRAL, SELF_AVOIDING, LEVY_FLIGHT }
@export var selected_walk_type: WalkSelection = WalkSelection.AUTO

@export var background_color: Color = Color(0, 1, 0, 1)   # Default: Green
@export var pixel_color: Color = Color(1, 0, 1, 1)        # Default: Pink

# State variables
var img := Image.new()
var texture := ImageTexture.new()
var current_position: Vector2
var turn_count: int = 0
var visited_positions := {}
var chosen_walk_type
var is_walking: bool = false              # Flag to control random walk
var time_since_last_step: float = 0.0     # Timer for step interval

@onready var mesh_instance: MeshInstance3D = $GrabPaper/RandomWalkPlanMesh

func _ready():
	if not mesh_instance:
		push_error("MeshInstance3D not found in RandomWalk node!")
		return
	await get_tree().create_timer(1.0).timeout
	# Set walk type
	if selected_walk_type == WalkSelection.AUTO:
		var walk_types = RandomWalk.WalkType.values()
		chosen_walk_type = walk_types[randi() % walk_types.size()]
	else:
		chosen_walk_type = {
			WalkSelection.SIMPLE: RandomWalk.WalkType.SIMPLE,
			WalkSelection.DIAGONAL: RandomWalk.WalkType.DIAGONAL,
			WalkSelection.BROWNIAN: RandomWalk.WalkType.BROWNIAN,
			WalkSelection.FRACTAL: RandomWalk.WalkType.FRACTAL,
			WalkSelection.FIBONACCI_SPIRAL: RandomWalk.WalkType.FIBONACCI_SPIRAL,
			WalkSelection.SELF_AVOIDING: RandomWalk.WalkType.SELF_AVOIDING,
			WalkSelection.LEVY_FLIGHT: RandomWalk.WalkType.LEVY_FLIGHT
		}.get(selected_walk_type, RandomWalk.WalkType.SIMPLE)
	
	# Initialize image and texture
	img = ImageHelper.create_image(width, height, background_color)
	texture = ImageHelper.create_texture_from_image(img)
	MaterialHelper.assign_unique_material(mesh_instance, texture)
	
	# Start at center
	current_position = Vector2(width / 2, height / 2)
	
	# Perform initial random walk (20-80 steps)
	var initial_steps = randi_range(20, 80)
	print("Performing initial random walk with ", initial_steps, " steps")
	for i in range(initial_steps):
		current_position = RandomWalk.perform_random_walk(
			img, current_position, area_size, width, height, chosen_walk_type, visited_positions, pixel_color
		)
		turn_count += 1
	texture.set_image(img)
	MaterialHelper.update_texture_material(mesh_instance, texture)
	
	if img.get_data().size() == 0:
		push_error("Image creation failed.")
	
	if label3d:
		label3d.text = label_text
	else:
		push_warning("Label3D node not found at path: GrabPaper/id_info_Label3D")

func _process(delta):
	if is_walking:
		time_since_last_step += delta
		if time_since_last_step >= interval:
			current_position = RandomWalk.perform_random_walk(
				img, current_position, area_size, width, height, chosen_walk_type, visited_positions, pixel_color
			)
			turn_count += 1
			texture.set_image(img)
			MaterialHelper.update_texture_material(mesh_instance, texture)
			time_since_last_step = 0.0

func _on_grab_paper_grabbed(pickable: Variant, by: Variant) -> void:
	print("Item picked up, starting random walk")
	is_walking = true
	time_since_last_step = 0.0  # Reset timer for immediate step

func _on_grab_paper_dropped(pickable: Variant) -> void:
	print("Item dropped, stopping random walk")
	is_walking = false
