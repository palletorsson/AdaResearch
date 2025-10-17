extends Node3D

const CAStrategy = preload("res://algorithms/cellularautomata/CAchairtests/CAStrategy.gd")

@onready var ca_grid = $CAGrid
@onready var camera = $Camera3D

# UI
@onready var ui = $UI
@onready var gen_label = $UI/Panel/VBox/GenLabel
@onready var cell_label = $UI/Panel/VBox/CellLabel
@onready var strategy_label = $UI/Panel/VBox/StrategyLabel
@onready var btn_reset = $UI/Panel/VBox/HBox1/BtnReset
@onready var btn_step = $UI/Panel/VBox/HBox1/BtnStep
@onready var btn_play = $UI/Panel/VBox/HBox1/BtnPlay
@onready var btn_strategy = $UI/Panel/VBox/HBox2/BtnStrategy
@onready var speed_slider = $UI/Panel/VBox/HBox3/SpeedSlider

# State
var current_strategy: CAStrategy
var strategy_type: int = CAStrategy.StrategyType.SIMPLE_SWITCHED
var is_playing: bool = false
var step_timer: float = 0.0
var step_interval: float = 0.5

# Camera
var camera_rotation: Vector2 = Vector2.ZERO
var camera_distance: float = 40.0
var camera_target: Vector3 = Vector3(10, 12, 10)

func _ready():
	setup_camera()
	setup_ui()
	reset_simulation()

func setup_camera():
	camera.position = camera_target + Vector3(0, 20, -30)
	camera.look_at_from_position(camera.position, camera_target, Vector3.UP)

func setup_ui():
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_step.pressed.connect(_on_step_pressed)
	btn_play.pressed.connect(_on_play_pressed)
	btn_strategy.pressed.connect(_on_strategy_pressed)
	speed_slider.value_changed.connect(_on_speed_changed)

func reset_simulation():
	ca_grid.reset()
	ca_grid.seed_chair_base()
	current_strategy = CAStrategy.new(ca_grid, strategy_type)
	is_playing = false
	update_ui()
	ca_grid.update_visualization()

func _process(delta):
	handle_camera(delta)
	
	if is_playing:
		step_timer += delta
		if step_timer >= step_interval:
			step_timer = 0.0
			step_simulation()

func step_simulation():
	if ca_grid.generation < 30:
		current_strategy.step()
		update_ui()
	else:
		is_playing = false
		btn_play.text = "Play"

func update_ui():
	gen_label.text = "Generation: %d" % ca_grid.generation
	cell_label.text = "Cells: %d" % ca_grid.get_occupied_count()
	
	var strategy_names = [
		"Simple Rule Switching",
		"Cell Memory Based",
		"Gradient/Chemical",
		"Pure CA"
	]
	strategy_label.text = "Strategy: " + strategy_names[strategy_type]

func handle_camera(delta):
	# WASD movement
	var move_speed = 20.0
	var move = Vector3.ZERO
	
	if Input.is_key_pressed(KEY_W):
		move.z -= 1
	if Input.is_key_pressed(KEY_S):
		move.z += 1
	if Input.is_key_pressed(KEY_A):
		move.x -= 1
	if Input.is_key_pressed(KEY_D):
		move.x += 1
	
	if move != Vector3.ZERO:
		camera_target += move.normalized() * move_speed * delta
		camera.position = camera_target + Vector3(0, 20, -30)
		camera.look_at(camera_target)
	
	# Mouse wheel zoom
	if Input.is_action_just_released("ui_page_up"):
		camera_distance = max(20.0, camera_distance - 5.0)
		update_camera_position()
	if Input.is_action_just_released("ui_page_down"):
		camera_distance = min(100.0, camera_distance + 5.0)
		update_camera_position()

func update_camera_position():
	var offset = Vector3(0, camera_distance * 0.5, -camera_distance)
	camera.position = camera_target + offset
	camera.look_at(camera_target)

func _unhandled_input(event):
	# Camera rotation with right mouse button
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera_rotation.x -= event.relative.y * 0.01
		camera_rotation.y -= event.relative.x * 0.01
		camera_rotation.x = clamp(camera_rotation.x, -PI/2, PI/2)
		
		var offset = Vector3(0, camera_distance * 0.5, -camera_distance)
		offset = offset.rotated(Vector3.UP, camera_rotation.y)
		offset = offset.rotated(Vector3.RIGHT, camera_rotation.x)
		camera.position = camera_target + offset
		camera.look_at(camera_target)

func _on_reset_pressed():
	reset_simulation()

func _on_step_pressed():
	step_simulation()

func _on_play_pressed():
	is_playing = !is_playing
	btn_play.text = "Pause" if is_playing else "Play"

func _on_strategy_pressed():
	strategy_type = (strategy_type + 1) % 4
	reset_simulation()

func _on_speed_changed(value: float):
	step_interval = 1.0 / value
