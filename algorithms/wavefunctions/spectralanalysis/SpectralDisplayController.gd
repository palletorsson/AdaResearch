# SpectralDisplayController.gd - Links viewport texture to display material

# @identity
# essence: material.albedo_texture = viewport.get_texture() — connects a SubViewport's rendered content to a MeshInstance3D surface as both albedo and emission texture
# desire: to see live audio frequency analysis rendered on a physical surface in VR — a screen-within-a-world that makes sound visible
# critical_parameter: emission_energy_multiplier (3.0) — makes the display glow brightly enough to read in dark VR environments without external lighting
# triggers: _ready waits one frame for viewport initialization, then binds viewport texture to StandardMaterial3D with unshaded rendering and emission
# emerges: the display becomes a self-lit screen floating in 3D space — a viewport rendered as a physical object, collapsing the boundary between UI and architecture
# needs: [missing] no VR sliders or buttons — pure display component; depends on sibling GameSoundMeter.gd for actual spectrum computation
# relationships: the display half of spectrum_display artifact in F20_Well; pairs with GameSoundMeter for audio capture and SpectralMeter for bar rendering
# truth: sound is invisible until you give it a surface — the viewport texture is the membrane where vibration becomes light

extends MeshInstance3D

@export var viewport_node_path: NodePath = "../AudioDisplay"
var viewport: SubViewport

func _ready() -> void:
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
		material.emission_energy_multiplier = 3.0
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		
		# Ensure proper texture filtering and wrapping
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		
		print("SpectralDisplayController [%s]: Connected viewport texture to display material" % name)
		print("SpectralDisplayController [%s]: Viewport: %s, Size: %s" % [name, viewport.name, viewport.size])
		print("SpectralDisplayController [%s]: Texture size: %s" % [name, viewport_texture.get_size()])
	else:
		print("SpectralDisplayController: No StandardMaterial3D found") 

func apply_grid_config(config: Dictionary) -> void:
	pass
