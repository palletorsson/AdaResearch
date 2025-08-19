extends Node3D
class_name RunningTextDisplay

# Appearance settings
@export var text: String = "YOUR TEXT GOES HERE... POWER IS THE MOST OBVIOUS APHRODISIAC..."
@export var font_size: int = 24
@export var text_color: Color = Color(0, 1, 1, 1)  # Cyan color like Holzer often uses
@export var background_color: Color = Color(0, 0, 0, 1)
@export var display_width: float = 2.0
@export var display_height: float = 0.2

# Animation settings
@export var scroll_speed: float = 0.5
@export var direction: Vector2 = Vector2(-1, 0)  # Default: scroll left
@export_enum("Left", "Right", "Up", "Down", "Diagonal") var scroll_direction: int = 0:
	set(value):
		scroll_direction = value
		match scroll_direction:
			0: direction = Vector2(-1, 0)  # Left
			1: direction = Vector2(1, 0)   # Right
			2: direction = Vector2(0, -1)  # Up
			3: direction = Vector2(0, 1)   # Down
			4: direction = Vector2(-1, -1).normalized()  # Diagonal

# Node references
var viewport: SubViewport
var viewport_sprite: Sprite3D
var label: Label

# Animation variables
var scroll_position: Vector2 = Vector2.ZERO
var text_size: Vector2 = Vector2.ZERO

func _ready():
	# Create the display mesh
	create_led_display()
	
	# Setup scrolling text
	setup_viewport_text()

func create_led_display():
	# Create a simple flat box to represent the LED display
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(display_width, display_height, 0.02)
	mesh_instance.mesh = box_mesh
	
	# Add material with emissive properties to simulate LED
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.1, 0.1, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.2, 0.2, 0.2)
	material.emission_energy = 0.5
	mesh_instance.material_override = material
	
	add_child(mesh_instance)

func setup_viewport_text():
	# Create viewport for the text
	viewport = SubViewport.new()
	viewport.size = Vector2(int(display_width * 100), int(display_height * 100))
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	
	# Create a Control to hold the text
	var control = Control.new()
	control.size = viewport.size
	viewport.add_child(control)
	
	# Create the label for the text
	label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Create a font with the desired size
	var font = label.get_theme_font("font")
	var font_size_override = label.get_theme_font_size("font_size")
	font_size_override = font_size
	label.add_theme_font_size_override("font_size", font_size)
	
	# Set the color
	label.add_theme_color_override("font_color", text_color)
	
	# Position the label
	label.position = Vector2(viewport.size.x, 0)
	label.size = Vector2(viewport.size.x * 10, viewport.size.y)  # Make it extra wide for scrolling
	control.add_child(label)
	
	# Calculate the actual text size
	text_size = label.get_minimum_size()
	
	# Create the sprite to display the viewport
	viewport_sprite = Sprite3D.new()
	viewport_sprite.texture = viewport.get_texture()
	viewport_sprite.pixel_size = 0.01  # Adjust based on your scale
	viewport_sprite.position = Vector3(0, 0, 0.011)  # Slightly in front of the box
	viewport_sprite.scale = Vector3(display_width, display_height, 1) / viewport_sprite.pixel_size
	add_child(viewport_sprite)

func _process(delta):
	# Calculate scrolling based on direction and speed
	scroll_position += direction * scroll_speed * delta * 100
	
	# Reset position when text has scrolled off screen
	match scroll_direction:
		0:  # Left
			if scroll_position.x <= -text_size.x - viewport.size.x:
				scroll_position.x = viewport.size.x
		1:  # Right
			if scroll_position.x >= viewport.size.x:
				scroll_position.x = -text_size.x
		2:  # Up
			if scroll_position.y <= -text_size.y - viewport.size.y:
				scroll_position.y = viewport.size.y
		3:  # Down
			if scroll_position.y >= viewport.size.y:
				scroll_position.y = -text_size.y
		4:  # Diagonal
			if scroll_position.x <= -text_size.x - viewport.size.x or scroll_position.y <= -text_size.y - viewport.size.y:
				scroll_position = Vector2(viewport.size.x, viewport.size.y)
	
	# Update label position
	label.position = Vector2(viewport.size.x, 0) + scroll_position
