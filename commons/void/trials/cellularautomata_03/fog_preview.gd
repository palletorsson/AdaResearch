extends "res://algorithms/cellularautomata/volumetric_fog/volumetric_fog_ca.gd"
## The source's existing central-slice fallback also serves the Mobile renderer.
## Both desktop and VR in Void use Mobile; volumetric fog requires Forward+.
func _setup_fog() -> void:
	if RenderingServer.get_current_rendering_method() == "forward_plus":
		super._setup_fog()
		return
	var img := Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.BLACK)
	slice_texture = ImageTexture.create_from_image(img)
	slice_preview = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(8, 8)
	slice_preview.mesh = quad
	var material := StandardMaterial3D.new()
	material.albedo_texture = slice_texture
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	slice_preview.material_override = material
	add_child(slice_preview)
	var note := Label3D.new()
	note.text = "FOG FIELD / CENTRAL Z SLICE\nVolume rendering needs Forward+"
	note.font_size = 42
	note.pixel_size = .008
	note.position.y = 4.6
	note.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(note)
	_update_texture()
