extends Node3D

@onready var sprite_3d = $Sprite3D
@onready var sub_viewport = $SubViewport

	
func _ready():
	# Wait for viewport to initialize
	await get_tree().process_frame
	setup_canvas()
	# Set up the Sprite3D with the viewport texture
	$Sprite3D.texture = $SubViewport.get_texture()

	# Position the Sprite3D in front of the camera
	$Sprite3D.global_position = $Camera3D.global_position + $Camera3D.global_transform.basis.z * -3

	# Make sure sprite is visible with unshaded material
	var material = StandardMaterial3D.new()
	material.albedo_texture = $SubViewport.get_texture()
	material.flags_unshaded = true
	$Sprite3D.material_override = material

func setup_canvas():
	# Apply viewport texture to sprite
	sprite_3d.texture = sub_viewport.get_texture()
	
	# Create an unshaded material (ignores lighting)
	var material = StandardMaterial3D.new()
	material.albedo_texture = sub_viewport.get_texture()
	material.flags_unshaded = true  # This makes it ignore lighting
	material.flags_transparent = false
	
	sprite_3d.material_override = material
