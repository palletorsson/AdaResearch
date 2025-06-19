# SpectralDisplayController.gd - Links viewport texture to display material
extends MeshInstance3D

@export var viewport_node_path: NodePath = "../AudioDisplay"
var viewport: SubViewport

func _ready():
	# Get the viewport
	print("SpectralDisplayController [%s]: Looking for viewport at path: %s" % [name, viewport_node_path])
	viewport = get_node(viewport_node_path) as SubViewport
	if not viewport:
		print("SpectralDisplayController [%s]: Could not find viewport at path: %s" % [name, viewport_node_path])
		return
	
	print("SpectralDisplayController [%s]: Found viewport: %s" % [name, viewport.name])
	
	# Wait a frame for the viewport to initialize
	await get_tree().process_frame
	
	# Setup the material to display the viewport texture
	if material_override and material_override is StandardMaterial3D:
		var material = material_override as StandardMaterial3D
		var viewport_texture = viewport.get_texture()
		
		material.albedo_texture = viewport_texture
		material.emission_texture = viewport_texture
		material.emission_energy = 3.0
		material.unshaded = true
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.flags_transparent = false
		material.flags_unshaded = true
		
		# Ensure proper texture filtering and wrapping
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		
		print("SpectralDisplayController [%s]: Connected viewport texture to display material" % name)
		print("SpectralDisplayController [%s]: Viewport: %s, Size: %s" % [name, viewport.name, viewport.size])
		print("SpectralDisplayController [%s]: Texture size: %s" % [name, viewport_texture.get_size()])
	else:
		print("SpectralDisplayController: No StandardMaterial3D found") 
