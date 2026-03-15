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
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

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
	control_panel = Node3D.new()
	control_panel.name = "ControlPanel"
	control_panel.position = turret_position + Vector3(1.2, 0.8, 0)
	control_panel.rotation_degrees = Vector3(0, -30, 0)
	add_child(control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.4, 0.35, 0.02)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.05, 0.05, 0.08, 0.95)
	panel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.015
	control_panel.add_child(panel_back)
	
	# Title
	var title = Label3D.new()
	title.text = "TURRET CONTROLS"
	title.pixel_size = 0.001
	title.font_size = 14
	title.position = Vector3(0, 0.13, 0.01)
	control_panel.add_child(title)
	
	# Drop Ball Button
	drop_button = PUSH_BUTTON.instantiate()
	drop_button.name = "DropBallButton"
	drop_button.position = Vector3(0, 0.05, 0.01)
	control_panel.add_child(drop_button)
	_add_button_label(drop_button, "DROP BALL")
	_connect_button(drop_button, drop_ball_now)
	
	# Reset Button
	reset_button = PUSH_BUTTON.instantiate()
	reset_button.name = "ResetButton"
	reset_button.position = Vector3(0, -0.02, 0.01)
	control_panel.add_child(reset_button)
	_add_button_label(reset_button, "RESET")
	_connect_button(reset_button, reset)
	
	# Auto-Drop Toggle Button
	auto_toggle_button = PUSH_BUTTON.instantiate()
	auto_toggle_button.name = "AutoToggleButton"
	auto_toggle_button.position = Vector3(0, -0.09, 0.01)
	control_panel.add_child(auto_toggle_button)
	auto_label = _add_button_label(auto_toggle_button, "AUTO: ON" if auto_drop else "AUTO: OFF")
	_connect_button(auto_toggle_button, _toggle_auto_drop)

func _add_button_label(btn: Node, text: String) -> Label3D:
	var lbl = Label3D.new()
	lbl.name = "ButtonLabel"
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 10
	lbl.position = Vector3(0, -0.025, 0)
	btn.add_child(lbl)
	return lbl

func _connect_button(btn: Node, callback: Callable) -> void:
	# Wait a frame for button to initialize
	await get_tree().process_frame
	
	# Try InteractableAreaButton (XR Tools style)
	var interactable = btn.get_node_or_null("InteractableAreaButton")
	if interactable and interactable.has_signal("button_pressed"):
		interactable.button_pressed.connect(func(_b): callback.call())
	
	# Also try direct pressed signal
	if btn.has_signal("pressed"):
		btn.pressed.connect(callback)

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
