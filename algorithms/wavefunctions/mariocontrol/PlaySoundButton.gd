extends StaticBody3D

## Play Sound Button
## Simple button to trigger sound playback on the MarioSoundController
## Place this as a child or sibling of MarioSoundController

@export var button_color: Color = Color(0.3, 1.0, 0.3, 1.0)  # Green
@export var button_size: Vector3 = Vector3(0.15, 0.15, 0.05)

var mesh_instance: MeshInstance3D
var material: StandardMaterial3D
var sound_controller: Node3D
var is_pressed: bool = false

func _ready() -> void:
	_create_button_visual()
	_find_sound_controller()

	# Connect to grab signals if using XR Tools
	#if has_signal("body_entered"):
		#body_entered.connect(_on_button_touched)

func _create_button_visual() -> void:
	# Create button mesh
	mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = button_size
	mesh_instance.mesh = box_mesh

	# Create material
	material = StandardMaterial3D.new()
	material.albedo_color = button_color
	material.emission_enabled = true
	material.emission = button_color * 0.6
	material.metallic = 0.5
	material.roughness = 0.4
	mesh_instance.material_override = material

	add_child(mesh_instance)

	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = button_size
	collision_shape.shape = box_shape
	add_child(collision_shape)

	# Add label
	var label = Label3D.new()
	label.text = "PLAY"
	label.position = Vector3(0, button_size.y * 0.5 + 0.1, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 28
	label.modulate = Color(1, 1, 1, 0.9)
	label.outline_size = 4
	label.outline_modulate = Color(0, 0, 0, 1)
	label.scale = Vector3.ONE * 0.06
	add_child(label)

func _find_sound_controller() -> void:
	# Try to find MarioSoundController in parent
	sound_controller = get_parent()
	if sound_controller and sound_controller.has_method("play_sound"):
		print("PlaySoundButton: Found sound controller")
	else:
		# Try to find it as a sibling
		if get_parent():
			sound_controller = get_parent().get_node_or_null("MarioSoundController")
			if sound_controller and sound_controller.has_method("play_sound"):
				print("PlaySoundButton: Found sound controller as sibling")
			else:
				push_warning("PlaySoundButton: Could not find MarioSoundController")
				sound_controller = null

func _on_button_touched(body: Node3D) -> void:
	# Check if touched by player hand
	if body.is_in_group("player_hand") or body.name.contains("Hand"):
		_press_button()

func _press_button() -> void:
	if is_pressed:
		return

	is_pressed = true

	# Visual feedback - button press animation
	var tween = create_tween()
	tween.tween_property(mesh_instance, "position:z", button_size.z * 0.3, 0.05)
	tween.tween_property(mesh_instance, "position:z", 0.0, 0.1)

	# Flash button
	if material:
		material.emission = button_color * 2.0

	# Play sound
	if sound_controller:
		sound_controller.play_sound()
	else:
		print("PlaySoundButton: No sound controller found!")

	# Reset after delay
	await get_tree().create_timer(0.3).timeout
	is_pressed = false
	if material:
		material.emission = button_color * 0.6

# Alternative API for programmatic triggering
func trigger() -> void:
	_press_button()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

