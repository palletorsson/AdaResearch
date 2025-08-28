# MetaballScene.gd
# Updated to work with the .tscn file structure
extends Node3D

@onready var metaball_generator: MetaballGenerator = $MetaballGenerator
@onready var ui_control: Control = $UI/Control

# UI references
@onready var metaball_count_label: Label = $UI/Control/ControlPanel/VBoxContainer/MetaballCountLabel
@onready var metaball_count_slider: HSlider = $UI/Control/ControlPanel/VBoxContainer/MetaballCountSlider
@onready var iso_level_label: Label = $UI/Control/ControlPanel/VBoxContainer/IsoLevelLabel
@onready var iso_level_slider: HSlider = $UI/Control/ControlPanel/VBoxContainer/IsoLevelSlider
@onready var animation_speed_label: Label = $UI/Control/ControlPanel/VBoxContainer/AnimationSpeedLabel
@onready var animation_speed_slider: HSlider = $UI/Control/ControlPanel/VBoxContainer/AnimationSpeedSlider
@onready var stats_label: Label = $UI/Control/ControlPanel/VBoxContainer/StatsLabel
@onready var performance_label: Label = $UI/Control/PerformanceLabel

# Player components
var player: CharacterBody3D
var camera: Camera3D

# Player movement settings
var mouse_sensitivity: float = 0.002
var movement_speed: float = 8.0
var run_multiplier: float = 2.0
var jump_velocity: float = 8.0
var gravity: float = 20.0

# UI state
var ui_visible: bool = true
var fps_update_timer: float = 0.0

func _ready():
	setup_player()
	setup_ui_initial_values()
	
	# Capture mouse initially
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Connect to metaball generator if it exists
	if metaball_generator:
		# Update UI when generation completes
		update_stats_display()

func setup_player():
	# Create player character
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 15, 20)  # Start above and away from metaballs
	add_child(player)
	
	# Add collision shape for player
	var collision_shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.4
	collision_shape.shape = capsule
	collision_shape.name = "CollisionShape3D"
	player.add_child(collision_shape)
	
	# Add camera
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 0.6, 0)  # Eye level
	camera.fov = 75.0
	player.add_child(camera)
	
	# Set as current camera
	camera.current = true

func setup_ui_initial_values():
	if not metaball_generator:
		return
		
	# Initialize slider values
	metaball_count_slider.value = metaball_generator.metaball_count
	iso_level_slider.value = metaball_generator.iso_level
	animation_speed_slider.value = metaball_generator.animation_speed
	
	# Update labels
	metaball_count_label.text = "Metaball Count: %d" % metaball_generator.metaball_count
	iso_level_label.text = "ISO Level: %.2f" % metaball_generator.iso_level
	animation_speed_label.text = "Animation Speed: %.1f" % metaball_generator.animation_speed

func update_stats_display():
	if not metaball_generator or not stats_label:
		return
	
	var vertices_count = 0
	if metaball_generator.mesh_instance and metaball_generator.mesh_instance.mesh:
		var mesh = metaball_generator.mesh_instance.mesh
		if mesh.get_surface_count() > 0:
			var arrays = mesh.surface_get_arrays(0)
			if arrays[Mesh.ARRAY_VERTEX]:
				vertices_count = arrays[Mesh.ARRAY_VERTEX].size()
	
	stats_label.text = "Generation Time: %.1f ms\nVertices: %d" % [
		metaball_generator.generation_time,
		vertices_count
	]

func _input(event):
	# Handle mouse capture toggle
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				toggle_mouse_capture()
			KEY_TAB:
				toggle_ui_visibility()
			KEY_R:
				if metaball_generator:
					metaball_generator.regenerate()
					update_stats_display()
	
	# Handle mouse look (only when captured)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if camera:
			# Rotate camera based on mouse movement
			camera.rotate_y(-event.relative.x * mouse_sensitivity)
			camera.rotate_object_local(Vector3(1, 0, 0), -event.relative.y * mouse_sensitivity)
			
			# Clamp vertical rotation
			var rotation = camera.rotation_degrees
			rotation.x = clamp(rotation.x, -90, 90)
			camera.rotation_degrees = rotation

func _physics_process(delta):
	if player:
		handle_player_movement(delta)
	
	# Update FPS display
	update_performance_display(delta)

func handle_player_movement(delta):
	# Add gravity
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		player.velocity.y = jump_velocity
	
	# Get input direction
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_forward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y -= 1
	
	# Calculate movement speed (with run modifier)
	var current_speed = movement_speed
	if Input.is_action_pressed("run"):
		current_speed *= run_multiplier
	
	# Calculate movement direction relative to camera
	var direction = Vector3.ZERO
	if input_dir != Vector2.ZERO and camera:
		var camera_basis = camera.global_transform.basis
		direction = (camera_basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()
	
	# Apply horizontal movement
	if direction != Vector3.ZERO:
		player.velocity.x = direction.x * current_speed
		player.velocity.z = direction.z * current_speed
	else:
		# Friction
		player.velocity.x = move_toward(player.velocity.x, 0, current_speed * delta * 8)
		player.velocity.z = move_toward(player.velocity.z, 0, current_speed * delta * 8)
	
	# Move the player
	player.move_and_slide()

func update_performance_display(delta):
	fps_update_timer += delta
	if fps_update_timer >= 0.5:  # Update every 0.5 seconds
		fps_update_timer = 0.0
		if performance_label:
			var fps = Engine.get_frames_per_second()
			var frame_time = 1000.0 / max(fps, 1)  # Convert to milliseconds
			performance_label.text = "FPS: %d\nFrame Time: %.1f ms" % [fps, frame_time]

func toggle_mouse_capture():
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_ui_visibility():
	ui_visible = not ui_visible
	ui_control.visible = ui_visible

# UI Signal Handlers (connected in the .tscn file)
func _on_regenerate_button_pressed():
	if metaball_generator:
		metaball_generator.regenerate()
		update_stats_display()

func _on_metaball_count_slider_value_changed(value: float):
	if metaball_generator:
		metaball_generator.set_metaball_count(int(value))
		metaball_count_label.text = "Metaball Count: %d" % int(value)
		update_stats_display()

func _on_iso_level_slider_value_changed(value: float):
	if metaball_generator:
		metaball_generator.set_iso_level(value)
		iso_level_label.text = "ISO Level: %.2f" % value
		update_stats_display()

func _on_animation_speed_slider_value_changed(value: float):
	if metaball_generator:
		metaball_generator.set_animation_speed(value)
		animation_speed_label.text = "Animation Speed: %.1f" % value
