# ===========================================================================
# NOC Example 11.1: Flappy Bird
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 11.1 - Flappy Bird VR
## Manual Flappy Bird clone with gravity, pipe spawning, and collision detection
## 
# Bird entity
class Bird extends VREntity:
	var flap_force: float = 0.15
	var gravity: Vector3 = Vector3(0, -0.5, 0)

	func setup_mesh():
		mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.03
		mesh_instance.mesh = sphere
		add_child(mesh_instance)

	func _physics_process(delta):
		# Apply gravity
		apply_force(gravity)
		super._physics_process(delta)

		# Keep within tank Y bounds
		if position_v.y > 0.45:
			position_v.y = 0.45
			velocity.y = 0
		if position_v.y < -0.45:
			position_v.y = -0.45
			velocity.y = 0

	func flap():
		velocity.y = flap_force

# Pipe obstacle
class Pipe extends Node3D:
	var gap_y: float = 0.0
	var gap_size: float = 0.2
	var speed: float = 0.15
	var passed: bool = false

	var upper_mesh: MeshInstance3D
	var lower_mesh: MeshInstance3D
	var secondary_pink: Color = Color(0.9, 0.5, 0.8, 0.5)  # Translucent

	func _init(y_pos: float = 0.0):
		gap_y = y_pos

	func _ready():
		create_pipes()

	func create_pipes():
		# Upper pipe
		upper_mesh = MeshInstance3D.new()
		var upper_box = BoxMesh.new()
		upper_box.size = Vector3(0.08, 0.5 - gap_y - gap_size / 2, 0.08)
		upper_mesh.mesh = upper_box
		upper_mesh.position = Vector3(0, 0.25 + gap_y + gap_size / 2, 0)

		var mat_upper = StandardMaterial3D.new()
		mat_upper.albedo_color = secondary_pink
		mat_upper.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		upper_mesh.material_override = mat_upper
		add_child(upper_mesh)

		# Lower pipe
		lower_mesh = MeshInstance3D.new()
		var lower_box = BoxMesh.new()
		lower_box.size = Vector3(0.08, 0.5 + gap_y - gap_size / 2, 0.08)
		lower_mesh.mesh = lower_box
		lower_mesh.position = Vector3(0, -0.25 + gap_y - gap_size / 2, 0)

		var mat_lower = StandardMaterial3D.new()
		mat_lower.albedo_color = secondary_pink
		mat_lower.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lower_mesh.material_override = mat_lower
		add_child(lower_mesh)

	func _process(delta):
		position.x -= speed * delta

		# Check if pipe passed
		if not passed and position.x < 0.2:
			passed = true

	func check_collision(bird_pos: Vector3) -> bool:
		# Simple box collision
		if abs(bird_pos.x - position.x) < 0.05:
			# Check if bird is in gap
			if bird_pos.y < gap_y - gap_size / 2 or bird_pos.y > gap_y + gap_size / 2:
				return true
		return false

# Main scene variables
var bird: Bird
var pipes: Array[Pipe] = []
var score: int = 0
var game_over: bool = false

var spawn_timer: float = 0.0
var spawn_interval: float = 2.0

# UI
var score_label: Label3D
var game_over_label: Label3D
var instruction_label: Label3D

func _ready():

	# Create bird
	bird = Bird.new()
	bird.position_v = Vector3(0.2, 0, 0)
	add_child(bird)

	# Create UI labels
	create_ui()

	# Spawn first pipe
	spawn_pipe()

func create_ui():
	# Score label
	score_label = Label3D.new()
	score_label.text = "Score: 0"
	score_label.font_size = 32
	score_label.outline_size = 4
	score_label.position = Vector3(0, 0.4, -0.4)
	score_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(score_label)

	# Instruction label
	instruction_label = Label3D.new()
	instruction_label.text = "Press SPACE to flap"
	instruction_label.font_size = 24
	instruction_label.outline_size = 2
	instruction_label.position = Vector3(0, 0.3, -0.4)
	instruction_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(instruction_label)

	# Game over label (hidden initially)
	game_over_label = Label3D.new()
	game_over_label.text = "GAME OVER\nPress R to restart"
	game_over_label.font_size = 40
	game_over_label.outline_size = 6
	game_over_label.position = Vector3(0, 0, -0.3)
	game_over_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	game_over_label.modulate = Color(1, 0, 0, 1)
	game_over_label.visible = false
	add_child(game_over_label)

func _process(delta):
	if game_over:
		# Check for restart
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_R):
			restart_game()
		return

	# Handle input
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		bird.flap()

	# Spawn pipes
	spawn_timer += delta
	if spawn_timer > spawn_interval:
		spawn_pipe()
		spawn_timer = 0.0

	# Update pipes
	for pipe in pipes:
		# Check collision
		if pipe.check_collision(bird.position_v):
			end_game()

		# Check if passed
		if pipe.passed and not game_over:
			score += 1
			score_label.text = "Score: " + str(score)
			pipe.passed = false  # Prevent multiple scores

	# Remove off-screen pipes
	var to_remove: Array[Pipe] = []
	for pipe in pipes:
		if pipe.position.x < -0.6:
			to_remove.append(pipe)

	for pipe in to_remove:
		pipes.erase(pipe)
		pipe.queue_free()

func spawn_pipe():
	"""Spawn a new pipe at random height"""
	var gap_y = randf_range(-0.2, 0.2)
	var pipe = Pipe.new(gap_y)
	pipe.position = Vector3(0.5, 0, 0)
	add_child(pipe)
	pipes.append(pipe)

func end_game():
	"""End the game"""
	game_over = true
	game_over_label.visible = true
	bird.velocity = Vector3.ZERO

func restart_game():
	"""Restart the game"""
	game_over = false
	game_over_label.visible = false
	score = 0
	score_label.text = "Score: 0"

	# Reset bird
	bird.position_v = Vector3(0.2, 0, 0)
	bird.velocity = Vector3.ZERO

	# Clear pipes
	for pipe in pipes:
		pipe.queue_free()
	pipes.clear()

	spawn_timer = 0.0
	spawn_pipe()
