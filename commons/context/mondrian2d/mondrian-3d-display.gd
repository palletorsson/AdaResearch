extends Node3D

# This script should be attached to your Mondrian2d root node

@onready var sprite_3d = $Sprite3D
@onready var sub_viewport = $SubViewport

# Adjustable properties
var maintain_aspect_ratio = true
var sprite_width = 2.0  # Width in 3D world units
var border_thickness = 0.05  # Thickness of the black border

func _ready():
	# Wait a frame to ensure viewport is initialized
	await get_tree().process_frame
	
	# Configure the viewport
	setup_viewport()
	
	# Configure the 3D sprite
	setup_sprite()
	
	# Add a frame border
	add_frame_border()

func setup_viewport():
	if sub_viewport:
		# Make sure the viewport is updating
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		
		# You might need to adjust these based on your needs
		sub_viewport.transparent_bg = false
		sub_viewport.size = Vector2(1024, 1024)  # Higher resolution for better quality

func setup_sprite():
	if sprite_3d and sub_viewport:
		# Apply viewport texture to sprite
		sprite_3d.texture = sub_viewport.get_texture()
		
		# Calculate dimensions while maintaining aspect ratio if needed
		var sprite_height = sprite_width
		if maintain_aspect_ratio:
			sprite_height = sprite_width * (55.0 / 60.0)  # Match the 60:55 ratio
		
		# Resize the sprite
		sprite_3d.pixel_size = 0.001  # Adjust for appropriate scale
		
		# Apply material settings
		var material = StandardMaterial3D.new()
		material.albedo_texture = sub_viewport.get_texture()
		material.flags_unshaded = true
		material.flags_transparent = false
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite_3d.material_override = material
		
		# Set the sprite size
		sprite_3d.scale = Vector3(sprite_width, sprite_height, 1.0)

func add_frame_border():
	# Create a black frame around the Mondrian
	var frame = CSGBox3D.new()
	frame.name = "Frame"
	
	# Size slightly larger than the sprite
	var sprite_height = sprite_width
	if maintain_aspect_ratio:
		sprite_height = sprite_width * (55.0 / 60.0)
	
	frame.size = Vector3(
		sprite_width + border_thickness * 2, 
		sprite_height + border_thickness * 2, 
		border_thickness / 2
	)
	
	# Position just behind the sprite
	frame.position = Vector3(0, 0, -0.01)
	
	# Create inner cutout
	var inner = CSGBox3D.new()
	inner.size = Vector3(sprite_width, sprite_height, border_thickness)
	inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	frame.add_child(inner)
	
	# Apply black material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.1, 0.1)
	frame.material = material
	
	add_child(frame)

# Call this if you need to update after viewport size changes
func update_display():
	if sprite_3d and sub_viewport:
		sprite_3d.texture = sub_viewport.get_texture()
		
		# You may need to update other properties as well if they've changed
		var sprite_height = sprite_width
		if maintain_aspect_ratio:
			sprite_height = sprite_width * (55.0 / 60.0)
		
		sprite_3d.scale = Vector3(sprite_width, sprite_height, 1.0)
		
		# Update frame if it exists
		if has_node("Frame"):
			var frame = get_node("Frame")
			frame.size = Vector3(
				sprite_width + border_thickness * 2, 
				sprite_height + border_thickness * 2, 
				border_thickness / 2
			)
			
			# Update inner cutout
			if frame.get_child_count() > 0:
				var inner = frame.get_child(0)
				inner.size = Vector3(sprite_width, sprite_height, border_thickness)
