extends Node3D

# Simple 3D Progress Bar for VR
# Minimal progress visualization for Hans Zimmer liturgical sound generation

# Progress bar components
var progress_container: Node3D
var progress_background: MeshInstance3D
var progress_fill: MeshInstance3D
var progress_text: Label3D

# Progress tracking
var current_progress: float = 0.0
var target_progress: float = 0.0

# Materials
var bg_material: StandardMaterial3D
var fill_material: StandardMaterial3D

# Animation

# Signals
signal visualization_complete

func _ready():
	setup_progress_bar()

func _process(delta):
	# Smooth progress animation
	if abs(current_progress - target_progress) > 0.001:
		current_progress = lerp(current_progress, target_progress, delta * 3.0)
		update_progress_bar()

func setup_progress_bar():
	# Container positioned for VR comfort
	progress_container = Node3D.new()
	# Position closer and more visible for VR
	progress_container.position = Vector3(0, 1.5, -1.5)  # Closer and higher
	progress_container.scale = Vector3(3.0, 3.0, 3.0)  # Even larger for VR
	add_child(progress_container)
	
	# Debug: Print position for troubleshooting
	print("Progress bar positioned at: ", progress_container.position)
	print("Progress bar scale: ", progress_container.scale)
	
	# Background bar
	progress_background = MeshInstance3D.new()
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(3.0, 0.3, 0.15)  # Larger for VR
	progress_background.mesh = bg_mesh
	
	bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0.1, 0.1, 0.1, 0.9)
	bg_material.emission_enabled = true
	bg_material.emission = Color(0.2, 0.2, 0.2)  # Brighter for VR
	bg_material.flags_unshaded = true  # Make it visible in VR
	progress_background.material_override = bg_material
	
	progress_container.add_child(progress_background)
	
	# Progress fill bar
	progress_fill = MeshInstance3D.new()
	var fill_mesh = BoxMesh.new()
	fill_mesh.size = Vector3(0.1, 0.25, 0.12)  # Start very small but visible
	progress_fill.mesh = fill_mesh
	
	fill_material = StandardMaterial3D.new()
	fill_material.albedo_color = Color(0.0, 1.0, 1.0)  # Bright cyan
	fill_material.emission_enabled = true
	fill_material.emission = Color(0.0, 1.0, 1.0) * 2.0  # Very bright emission
	fill_material.flags_unshaded = true  # Make it visible in VR
	fill_material.flags_transparent = false  # Ensure it's not transparent
	progress_fill.material_override = fill_material
	
	# Position at left edge
	progress_fill.position = Vector3(-1.45, 0, 0)  # Adjusted for larger size
	progress_container.add_child(progress_fill)
	
	# Progress text - make it much larger and more visible
	progress_text = Label3D.new()
	progress_text.text = "0%"
	progress_text.font_size = 64  # Much larger for VR
	progress_text.position = Vector3(0, 0.6, 0)  # Higher up
	progress_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	progress_text.modulate = Color(1.0, 1.0, 1.0)
	progress_text.outline_size = 8  # Add outline for visibility
	# progress_text.outline_color = Color(0.0, 0.0, 0.0)  # Black outline
	progress_container.add_child(progress_text)


func update_progress_bar():
	if not progress_fill:
		print("ERROR: progress_fill is null!")
		return
		
	# Update fill width and position for larger VR bar
	var fill_width = current_progress * 2.9  # Max width minus small margin (adjusted for 3.0 width)
	progress_fill.mesh.size.x = max(0.1, fill_width)  # Minimum visible width
	progress_fill.position.x = -1.45 + (fill_width * 0.5)  # Adjusted for new positioning
	
	# Update text
	var percentage = int(current_progress * 100)
	progress_text.text = str(percentage) + "%"
	
	# Debug output
	print("Progress bar updated: ", percentage, "% - Fill width: ", fill_width)
	
	# Color transition as progress increases
	var progress_color = Color(0.2, 0.8, 1.0).lerp(Color(0.8, 1.0, 0.2), current_progress)
	fill_material.albedo_color = progress_color
	fill_material.emission = progress_color * 0.5

func update_vr_positioning():
	# Position the progress bar in front of the player's view for VR
	var camera = get_viewport().get_camera_3d()
	if camera:
		# Get camera's forward direction
		var camera_forward = -camera.global_transform.basis.z
		var camera_right = camera.global_transform.basis.x
		
		# Position 2 meters in front of camera, slightly to the right
		var target_position = camera.global_position + camera_forward * 2.0 + camera_right * 0.5
		target_position.y = camera.global_position.y - 0.3  # Slightly below eye level
		
		# Smoothly move the progress bar
		progress_container.global_position = progress_container.global_position.lerp(target_position, 0.1)
		
		# Make it face the camera
		progress_container.look_at(camera.global_position, Vector3.UP)

func update_progress(progress: float):
	target_progress = clamp(progress, 0.0, 1.0)
	
	# Check if complete
	if target_progress >= 1.0:
		var timer = Timer.new()
		timer.wait_time = 2.0
		timer.timeout.connect(fade_out)
		timer.one_shot = true
		add_child(timer)
		timer.start()

func fade_out():
	var tween = create_tween()
	tween.tween_property(progress_container, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func(): visualization_complete.emit())

# Public interface for the main generator
func connect_to_generator(generator_node):
	if generator_node.has_signal("liturgical_progress_updated"):
		generator_node.liturgical_progress_updated.connect(_on_progress_updated)
	if generator_node.has_signal("sacred_generation_complete"):
		generator_node.sacred_generation_complete.connect(_on_generation_complete)

func _on_progress_updated(progress: float):
	update_progress(progress)

func _on_generation_complete():
	update_progress(1.0)

# Debug function to test progress bar visibility
func debug_progress_bar():
	print("=== PROGRESS BAR DEBUG ===")
	print("Container position: ", progress_container.global_position)
	print("Container scale: ", progress_container.scale)
	print("Background exists: ", progress_background != null)
	print("Fill exists: ", progress_fill != null)
	print("Text exists: ", progress_text != null)
	print("Current progress: ", current_progress)
	print("=========================")
