extends Node3D

class_name BoidManager

# Boid prefab to spawn
@export var boid_scene: PackedScene
@export var num_boids = 50

# Spawn area
@export var spawn_area_size = Vector3(20, 10, 20)

# VR related
@export var vr_player_path: NodePath

# Stored reference to VR controller nodes for interaction
@export var left_controller_path: NodePath
@export var right_controller_path: NodePath

# Interaction parameters
@export var interaction_radius = 3.0
@export var attraction_strength = 5.0
@export var repulsion_strength = 8.0

var boids = []
var vr_player = null
var left_controller = null
var right_controller = null

# Controller button states
var left_trigger_pressed = false
var right_trigger_pressed = false

func _ready():
	# Get VR references
	if vr_player_path:
		vr_player = get_node_or_null(vr_player_path)
	
	if left_controller_path:
		left_controller = get_node_or_null(left_controller_path)
	
	if right_controller_path:
		right_controller = get_node_or_null(right_controller_path)
	
	# Spawn boids
	spawn_boids()
	
	# Connect controller input signals
	_connect_controller_signals()

func spawn_boids():
	for i in range(num_boids):
		var boid_instance = boid_scene.instantiate()
		add_child(boid_instance)
		
		# Set random position within spawn area
		var half_size = spawn_area_size / 2
		boid_instance.global_position = Vector3(
			randf_range(-half_size.x, half_size.x),
			randf_range(-half_size.y, half_size.y),
			randf_range(-half_size.z, half_size.z)
		) + self.global_position
		
		# Set VR player reference
		if vr_player and boid_instance.has_method("set"):
			boid_instance.set("vr_player_path", boid_instance.get_path_to(vr_player))
		
		boids.append(boid_instance)

func _connect_controller_signals():
	# Connect controller input signals if using OpenXR
	if left_controller:
		# For OpenXR plugin
		if left_controller.has_signal("button_pressed"):
			left_controller.connect("button_pressed", Callable(self, "_on_left_controller_button_pressed"))
			left_controller.connect("button_released", Callable(self, "_on_left_controller_button_released"))
	
	if right_controller:
		if right_controller.has_signal("button_pressed"):
			right_controller.connect("button_pressed", Callable(self, "_on_right_controller_button_pressed"))
			right_controller.connect("button_released", Callable(self, "_on_right_controller_button_released"))

func _physics_process(delta):
	# Handle controller interaction with boids
	_process_controller_interaction()

func _process_controller_interaction():
	# Process left controller
	if left_controller and left_trigger_pressed:
		var controller_pos = left_controller.global_position
		var controller_forward = -left_controller.global_transform.basis.z.normalized()
		_interact_with_nearby_boids(controller_pos, controller_forward, true)  # true for attract
	
	# Process right controller
	if right_controller and right_trigger_pressed:
		var controller_pos = right_controller.global_position
		var controller_forward = -right_controller.global_transform.basis.z.normalized()
		_interact_with_nearby_boids(controller_pos, controller_forward, false)  # false for repel

func _interact_with_nearby_boids(controller_pos, direction, attract):
	for boid in boids:
		var distance = controller_pos.distance_to(boid.global_position)
		
		if distance < interaction_radius:
			# Calculate influence based on distance (stronger when closer)
			var influence = 1.0 - (distance / interaction_radius)
			
			if attract:
				# Direction toward controller
				var force_dir = (controller_pos - boid.global_position).normalized()
				boid.apply_force_from_vr(force_dir, attraction_strength * influence, 0.5)
			else:
				# Direction away from controller
				var force_dir = (boid.global_position - controller_pos).normalized()
				boid.apply_force_from_vr(force_dir, repulsion_strength * influence, 0.5)

# Controller input handlers for OpenXR
func _on_left_controller_button_pressed(button_name):
	if button_name == "trigger_click" or button_name == "trigger":
		left_trigger_pressed = true

func _on_left_controller_button_released(button_name):
	if button_name == "trigger_click" or button_name == "trigger":
		left_trigger_pressed = false

func _on_right_controller_button_pressed(button_name):
	if button_name == "trigger_click" or button_name == "trigger":
		right_trigger_pressed = true

func _on_right_controller_button_released(button_name):
	if button_name == "trigger_click" or button_name == "trigger":
		right_trigger_pressed = false

# Alternative input method for desktop testing
func _input(event):
	# For testing without VR hardware
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			# When space is pressed, make boids attracted to the VR player
			if vr_player:
				for boid in boids:
					var direction = vr_player.global_position - boid.global_position
					boid.apply_force_from_vr(direction, attraction_strength, 1.0)
		
		if event.pressed and event.keycode == KEY_ESCAPE:
			# When escape is pressed, make boids flee from the VR player
			if vr_player:
				for boid in boids:
					var direction = boid.global_position - vr_player.global_position
					boid.apply_force_from_vr(direction, repulsion_strength, 1.0)

# Return the array of boids for optimization
func get_boids():
	return boids
