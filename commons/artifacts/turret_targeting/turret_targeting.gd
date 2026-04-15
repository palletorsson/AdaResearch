extends Node3D

class_name TurretTargeting

# Turret Targeting - Laser turret tracks and destroys falling balls
# Demonstrates: Vector subtraction (direction), magnitude (range), normalization (aim), dot product (lock)
# VR-enabled with push button controls

signal ball_destroyed(ball: Node3D, position: Vector3)
signal target_acquired(ball: Node3D)
signal target_lost

@export_category("Layout")
@export var turret_position: Vector3 = Vector3(0, 0, 0)
@export var dropper_offset: Vector3 = Vector3(0, 3, 2)

@export_category("Dropper")
@export var drop_interval: float = 2.5
@export var max_balls: int = 4
@export var auto_drop: bool = true

@export_category("Turret")  
@export var detection_range: float = 8.0
@export var burn_time: float = 0.3
@export var laser_color: Color = Color(1.0, 0.05, 0.0)

@export_category("Display")
@export var show_stats: bool = true
@export var show_controls: bool = true

var turret: Node3D
var dropper: Node3D
var stats_label: Label3D

var balls_destroyed: int = 0
var session_start: float = 0.0

# VR Controls
var control_panel: Node3D
var drop_button: Node
var reset_button: Node
var auto_toggle_button: Node
var auto_label: Label3D

const TURRET_SCENE = preload("res://commons/artifacts/turret_targeting/laser_turret.tscn")
const DROPPER_SCENE = preload("res://commons/artifacts/turret_targeting/ball_dropper.tscn")

func _ready() -> void:
	session_start = Time.get_ticks_msec() / 1000.0
	
	_setup_turret()
	_setup_dropper()
	
	if show_stats:
		_create_stats_display()
	
	if show_controls:
		_create_vr_controls()
	
	if turret.has_signal("ball_destroyed"):
		turret.ball_destroyed.connect(_on_ball_destroyed)

func _setup_turret() -> void:
	turret = TURRET_SCENE.instantiate()
	turret.name = "LaserTurret"
	turret.position = turret_position
	turret.detection_range = detection_range
	turret.burn_time = burn_time
	turret.laser_color = laser_color
	add_child(turret)

func _setup_dropper() -> void:
	dropper = DROPPER_SCENE.instantiate()
	dropper.name = "BallDropper"
	dropper.position = turret_position + dropper_offset
	dropper.drop_interval = drop_interval
	dropper.max_balls = max_balls
	dropper.auto_drop = auto_drop
	dropper.initial_velocity = Vector3(0, 0, -0.5)
	add_child(dropper)

func _create_stats_display() -> void:
	stats_label = Label3D.new()
	stats_label.name = "StatsLabel"
	stats_label.position = turret_position + Vector3(-1.2, 1.2, 0)
	stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stats_label.font_size = 24
	stats_label.outline_size = 4
	stats_label.outline_modulate = Color.BLACK
	add_child(stats_label)

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	control_panel = RackTpl.create_panel("TURRET", [
		[{"type": "button", "label": "DROP BALL"}],
		[{"type": "button", "label": "RESET"}],
		[{"type": "button", "label": "AUTO"}],
	])
	control_panel.position = turret_position + Vector3(1.2, 0.8, 0)
	control_panel.rotation_degrees = Vector3(-25, -30, 0)
	add_child(control_panel)

	drop_button = control_panel.find_child("Btn_0", true, false)
	if drop_button:
		var area: Node = drop_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): drop_ball_now())

	reset_button = control_panel.find_child("Btn_1", true, false)
	if reset_button:
		var area: Node = reset_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): reset())

	auto_toggle_button = control_panel.find_child("Btn_2", true, false)
	if auto_toggle_button:
		var area: Node = auto_toggle_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _toggle_auto_drop())

func _toggle_auto_drop() -> void:
	auto_drop = not auto_drop
	dropper.auto_drop = auto_drop
	if auto_label:
		auto_label.text = "AUTO: ON" if auto_drop else "AUTO: OFF"

func _process(_delta: float) -> void:
	if show_stats and stats_label:
		_update_stats()

func _update_stats() -> void:
	var elapsed = (Time.get_ticks_msec() / 1000.0) - session_start
	var active_balls = dropper.get_ball_count() if dropper else 0
	var status = "FIRING" if turret.is_actively_firing() else ("TRACKING" if turret.is_targeting() else "SCANNING")
	
	stats_label.text = "%s\nBalls: %d/%d\nDestroyed: %d" % [
		status, active_balls, max_balls, balls_destroyed
	]
	
	if turret.is_actively_firing():
		stats_label.modulate = Color(1.0, 0.3, 0.2)
	elif turret.is_targeting():
		stats_label.modulate = Color(1.0, 0.8, 0.2)
	else:
		stats_label.modulate = Color(0.5, 1.0, 0.5)

func _on_ball_destroyed(_ball: Node3D, _pos: Vector3) -> void:
	balls_destroyed += 1
	emit_signal("ball_destroyed", _ball, _pos)

# Public API
func reset() -> void:
	dropper.clear_all()
	balls_destroyed = 0
	session_start = Time.get_ticks_msec() / 1000.0

func set_auto_drop(enabled: bool) -> void:
	auto_drop = enabled
	dropper.auto_drop = enabled
	if auto_label:
		auto_label.text = "AUTO: ON" if enabled else "AUTO: OFF"

func drop_ball_now() -> void:
	dropper.force_drop()

func get_destroyed_count() -> int:
	return balls_destroyed

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
