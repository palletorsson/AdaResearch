# ScoreCubeController.gd
# A utility cube that displays the current score and reacts to score changes
# Place anywhere in the scene to show real-time score updates

extends Node3D
class_name ScoreCubeController

@export var display_format: String = "%d"
@export var celebration_threshold: int = 10  # Every 10 points triggers celebration
@export var pulse_on_score: bool = true
@export var color_change_on_score: bool = true

# Visual components
var mesh_instance: MeshInstance3D
var score_label: Label3D
var shader_material: ShaderMaterial

# Current state
var current_score: int = 0
var last_celebration_score: int = 0

# Animation
var base_scale: Vector3
var is_animating: bool = false

func _ready():
	print("ScoreCube: Initializing score display cube")
	
	# Find visual components
	_setup_visual_components()
	
	# Connect to GameManager signals
	_connect_to_game_manager()
	
	# Initialize display
	_update_score_display(GameManager.get_score())

func _setup_visual_components():
	"""Setup mesh instance, label, and shader material"""
	
	# Find or create mesh instance
	mesh_instance = find_child("MeshInstance3D", true, false)
	if not mesh_instance:
		mesh_instance = find_child("CubeBaseMesh", true, false)
	
	if mesh_instance:
		base_scale = mesh_instance.scale
		shader_material = mesh_instance.material_override as ShaderMaterial
		print("ScoreCube: Found mesh instance")
	else:
		print("ScoreCube: WARNING - No mesh instance found")
	
	# Find or create score label
	score_label = find_child("ScoreLabel", true, false)
	if not score_label:
		score_label = find_child("Label3D", true, false)
	
	if not score_label:
		# Create label if none exists
		score_label = Label3D.new()
		score_label.name = "ScoreLabel"
		score_label.position = Vector3(0, 0.2, 0)
		score_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		score_label.font_size = 64
		score_label.outline_size = 8
		score_label.outline_color = Color.BLACK
		add_child(score_label)
		print("ScoreCube: Created score label")

func _connect_to_game_manager():
	"""Connect to GameManager singleton signals"""
	
	if not GameManager.score_updated.is_connected(_on_score_updated):
		GameManager.score_updated.connect(_on_score_updated)
		print("ScoreCube: Connected to GameManager.score_updated")
	
	if not GameManager.pickup_collected.is_connected(_on_pickup_collected):
		GameManager.pickup_collected.connect(_on_pickup_collected)
		print("ScoreCube: Connected to GameManager.pickup_collected")

func _on_score_updated(new_score: int):
	"""Handle score updates from GameManager"""
	var score_increase = new_score - current_score
	current_score = new_score
	
	print("ScoreCube: Score updated to %d (increase: %d)" % [new_score, score_increase])
	
	# Update visual display
	_update_score_display(new_score)
	
	# Trigger effects if score increased
	if score_increase > 0:
		_trigger_score_effects(score_increase)
		_check_celebration_milestone(new_score)

func _on_pickup_collected(pickup_position: Vector3):
	"""Handle pickup collection events"""
	print("ScoreCube: Pickup collected at %s" % pickup_position)
	
	# Point towards the pickup location briefly
	if pickup_position != Vector3.ZERO:
		_point_towards_pickup(pickup_position)

func _update_score_display(score: int):
	"""Update the score label text"""
	if score_label:
		score_label.text = display_format % score
		score_label.modulate = Color.WHITE

func _trigger_score_effects(score_increase: int):
	"""Trigger visual effects when score increases"""
	
	if pulse_on_score and mesh_instance and not is_animating:
		_pulse_animation()
	
	if color_change_on_score and shader_material:
		_flash_color_effect()
	
	# Scale effect intensity with score increase
	if score_increase >= 5:
		_big_score_effect()

func _pulse_animation():
	"""Pulse animation for score increases"""
	if not mesh_instance or is_animating:
		return
	
	is_animating = true
	var tween = create_tween()
	
	# Scale up then back down
	tween.tween_property(mesh_instance, "scale", base_scale * 1.3, 0.15)
	tween.tween_property(mesh_instance, "scale", base_scale, 0.15)
	
	await tween.finished
	is_animating = false

func _flash_color_effect():
	"""Flash the emission color"""
	if not shader_material:
		return
	
	var original_color = shader_material.get_shader_parameter("emissionColor")
	if not original_color:
		original_color = Color.CYAN
	
	# Flash bright white, then fade back
	shader_material.set_shader_parameter("emissionColor", Color.WHITE)
	shader_material.set_shader_parameter("emission_strength", 5.0)
	
	var tween = create_tween()
	tween.tween_property(shader_material, "shader_parameter/emission_strength", 2.0, 0.3)
	tween.tween_callback(func(): shader_material.set_shader_parameter("emissionColor", original_color))

func _big_score_effect():
	"""Special effect for big score increases (5+ points)"""
	if score_label:
		score_label.modulate = Color.GOLD
		
		var tween = create_tween()
		tween.tween_property(score_label, "scale", score_label.scale * 1.5, 0.2)
		tween.tween_property(score_label, "scale", Vector3.ONE, 0.2)
		tween.tween_property(score_label, "modulate", Color.WHITE, 0.5)

func _check_celebration_milestone(score: int):
	"""Check if we've hit a celebration milestone"""
	var milestones_passed = score / celebration_threshold
	var last_milestones = last_celebration_score / celebration_threshold
	
	if milestones_passed > last_milestones:
		_celebration_effect()
		last_celebration_score = score

func _celebration_effect():
	"""Special celebration effect for milestone achievements"""
	print("ScoreCube: 🎉 CELEBRATION! Milestone reached!")
	
	if shader_material:
		# Rainbow effect
		var tween = create_tween()
		tween.set_loops(3)
		
		for i in range(6):
			var hue = float(i) / 6.0
			var color = Color.from_hsv(hue, 1.0, 1.0)
			tween.tween_callback(func(): shader_material.set_shader_parameter("emissionColor", color))
			tween.tween_interval(0.1)
		
		tween.tween_callback(func(): shader_material.set_shader_parameter("emissionColor", Color.CYAN))
	
	# Spin the cube
	if mesh_instance:
		var spin_tween = create_tween()
		spin_tween.tween_property(mesh_instance, "rotation_degrees", mesh_instance.rotation_degrees + Vector3(0, 720, 0), 1.0)

func _point_towards_pickup(pickup_position: Vector3):
	"""Briefly point the cube towards where a pickup was collected"""
	var direction = (pickup_position - global_position).normalized()
	
	if direction != Vector3.ZERO:
		var target_rotation = Vector3.ZERO
		target_rotation.y = atan2(direction.x, direction.z)
		
		var tween = create_tween()
		tween.tween_property(self, "rotation", target_rotation, 0.3)
		tween.tween_interval(0.5)
		tween.tween_property(self, "rotation", Vector3.ZERO, 0.3)

# Public API
func set_display_format(format: String):
	"""Change how the score is displayed"""
	display_format = format
	_update_score_display(current_score)

func set_celebration_threshold(threshold: int):
	"""Change how often celebrations trigger"""
	celebration_threshold = threshold

func force_celebration():
	"""Trigger celebration effect manually"""
	_celebration_effect()

func get_current_score() -> int:
	"""Get the currently displayed score"""
	return current_score
