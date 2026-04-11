extends Node3D

# Turret Demo - Spawns balls one at a time for the turret to destroy
# Press SPACE to spawn a ball, or enable auto-spawn

@export_category("Spawn Settings")
@export var auto_spawn: bool = true
@export var spawn_interval: float = 2.0  # Seconds between spawns
@export var max_balls: int = 8  # Max balls alive at once
@export var spawn_height: float = 5.0
@export var spawn_radius: float = 4.0

@export_category("Stats")
@export var show_stats: bool = true

var spawn_timer: float = 0.0
var balls_destroyed: int = 0
var balls_spawned: int = 0

var turret: Node3D
var ball_spawner: Node3D
var stats_label: Label3D

func _ready() -> void:
	turret = $LaserTurret
	ball_spawner = $ColorBalls
	
	# Connect turret signals
	if turret.has_signal("ball_destroyed"):
		turret.ball_destroyed.connect(_on_ball_destroyed)
	
	# Configure ball spawner for manual control
	if ball_spawner:
		ball_spawner.ball_count = 0  # Start with no balls
		ball_spawner.respawn_on_fall = false  # Don't auto-respawn
	
	# Add stats display
	if show_stats:
		_create_stats_display()
	
	# Initial spawn
	if auto_spawn:
		_spawn_single_ball()
	
	print("=== TURRET DEMO ===")
	print("SPACE: Spawn ball")
	print("R: Reset all")
	print("T: Toggle auto-spawn")

func _create_stats_display() -> void:
	stats_label = Label3D.new()
	stats_label.name = "StatsLabel"
	stats_label.position = Vector3(-3, 3, 0)
	stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stats_label.font_size = 32
	stats_label.modulate = Color.WHITE
	stats_label.outline_modulate = Color.BLACK
	stats_label.outline_size = 4
	add_child(stats_label)

func _process(delta: float) -> void:
	if auto_spawn:
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_timer = 0.0
			if _get_ball_count() < max_balls:
				_spawn_single_ball()
	
	_update_stats()

func _get_ball_count() -> int:
	if ball_spawner and "balls" in ball_spawner:
		var count = 0
		for ball in ball_spawner.balls:
			if is_instance_valid(ball):
				count += 1
		return count
	return 0

func _spawn_single_ball() -> void:
	if ball_spawner == null:
		return
	
	# Random position in a ring around the turret
	var angle = randf() * TAU
	var distance = spawn_radius * (0.5 + randf() * 0.5)
	var x = cos(angle) * distance
	var z = sin(angle) * distance
	
	# Override spawn position temporarily
	var old_height = ball_spawner.spawn_height
	ball_spawner.spawn_height = spawn_height
	
	# Create ball directly
	if ball_spawner.has_method("create_ball_directly"):
		var ball = ball_spawner.create_ball_directly("Ball_%d" % balls_spawned)
		ball.position = Vector3(x, spawn_height, z)
		
		var color = ball_spawner.get_random_color()
		ball_spawner.set_ball_color(ball, color)
		
		ball_spawner.add_child(ball)
		ball_spawner.balls.append(ball)
		
		# Small initial velocity
		await get_tree().process_frame
		var rb = ball.get_node_or_null("RigidBody3D")
		if rb:
			rb.linear_velocity = Vector3(
				randf_range(-0.5, 0.5),
				-1.0,
				randf_range(-0.5, 0.5)
			)
		
		balls_spawned += 1
		print("[Demo] Spawned ball #%d at (%.1f, %.1f, %.1f)" % [balls_spawned, x, spawn_height, z])
	
	ball_spawner.spawn_height = old_height

func _on_ball_destroyed(_ball: Node3D) -> void:
	balls_destroyed += 1
	print("[Demo] Ball destroyed! Total: %d" % balls_destroyed)

func _update_stats() -> void:
	if stats_label == null:
		return
	
	var active = _get_ball_count()
	var targeting = "HUNTING" if turret.is_targeting() else "IDLE"
	var firing = " [FIRING]" if turret.is_actively_firing() else ""
	
	stats_label.text = "TURRET: %s%s\nBalls: %d / %d\nDestroyed: %d\nAuto: %s" % [
		targeting, firing, active, max_balls, balls_destroyed,
		"ON" if auto_spawn else "OFF"
	]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # SPACE
		_spawn_single_ball()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				_reset_demo()
			KEY_T:
				auto_spawn = !auto_spawn
				print("[Demo] Auto-spawn: %s" % ("ON" if auto_spawn else "OFF"))

func _reset_demo() -> void:
	# Clear all balls
	if ball_spawner and ball_spawner.has_method("clear_all_balls"):
		ball_spawner.clear_all_balls()
	
	balls_destroyed = 0
	balls_spawned = 0
	spawn_timer = 0.0
	
	print("[Demo] Reset!")
	
	# Spawn initial ball
	if auto_spawn:
		await get_tree().process_frame
		_spawn_single_ball()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
