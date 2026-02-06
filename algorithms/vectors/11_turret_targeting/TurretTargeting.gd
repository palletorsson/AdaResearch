extends Node3D

# Turret Targeting - Combined demo showing vector operations in action
# Demonstrates: Subtraction (direction), Magnitude (range), Normalization (aim), Dot product (lock)

@export_category("Layout")
@export var turret_position: Vector3 = Vector3(0, 0, 0)
@export var dropper_offset: Vector3 = Vector3(0, 3, 2)

@export_category("Dropper")
@export var drop_interval: float = 2.5
@export var max_balls: int = 50  # No practical limit
@export var auto_drop: bool = true

@export_category("Turret")  
@export var detection_range: float = 8.0
@export var damage_per_second: float = 50.0  # ~2 sec to kill a 100hp ball
@export var laser_color: Color = Color(1.0, 0.05, 0.0)

@export_category("Display")
@export var show_stats: bool = true

var turret: Node3D
var dropper: Node3D
var stats_label: Label3D

var balls_destroyed: int = 0
var session_start: float = 0.0

const TURRET_SCENE = preload("res://algorithms/vectors/11_turret_targeting/LaserTurret.tscn")
const DROPPER_SCENE = preload("res://algorithms/vectors/11_turret_targeting/BallDropper.tscn")

func _ready() -> void:
	session_start = Time.get_ticks_msec() / 1000.0
	
	_setup_turret()
	_setup_dropper()
	
	if show_stats:
		_create_stats_display()
	
	if turret.has_signal("ball_destroyed"):
		turret.ball_destroyed.connect(_on_ball_destroyed)

func _setup_turret() -> void:
	turret = TURRET_SCENE.instantiate()
	turret.name = "LaserTurret"
	turret.position = turret_position
	turret.detection_range = detection_range
	turret.damage_per_second = damage_per_second
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
	stats_label.position = turret_position + Vector3(-1.5, 1.5, 0)
	stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stats_label.font_size = 28
	stats_label.outline_size = 4
	stats_label.outline_modulate = Color.BLACK
	add_child(stats_label)

func _process(_delta: float) -> void:
	if show_stats and stats_label:
		_update_stats()

func _update_stats() -> void:
	var elapsed = (Time.get_ticks_msec() / 1000.0) - session_start
	var active_balls = dropper.get_ball_count() if dropper else 0
	var status = "FIRING" if turret.is_actively_firing() else ("TRACKING" if turret.is_targeting() else "SCANNING")
	
	stats_label.text = "TURRET: %s\nBalls: %d/%d\nDestroyed: %d\nTime: %.0fs" % [
		status, active_balls, max_balls, balls_destroyed, elapsed
	]
	
	if turret.is_actively_firing():
		stats_label.modulate = Color(1.0, 0.3, 0.2)
	elif turret.is_targeting():
		stats_label.modulate = Color(1.0, 0.8, 0.2)
	else:
		stats_label.modulate = Color(0.5, 1.0, 0.5)

func _on_ball_destroyed(_ball: Node3D, _pos: Vector3) -> void:
	balls_destroyed += 1

func reset() -> void:
	dropper.clear_all()
	balls_destroyed = 0
	session_start = Time.get_ticks_msec() / 1000.0

func set_auto_drop(enabled: bool) -> void:
	dropper.auto_drop = enabled
	auto_drop = enabled

func drop_ball_now() -> void:
	dropper.force_drop()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				drop_ball_now()
			KEY_R:
				reset()
			KEY_T:
				set_auto_drop(not auto_drop)
