extends "res://algorithms/proceduralgeneration/growth_systems/reactiondiffusion/2d_in_3d_turing_pattern_reaction_diffusion.gd"
## Export the original live viewport sprite as an equivalent textured quad.
## This hook runs only for the web arrangement snapshot; native scene is intact.
func prepare_editor_preview() -> void:
	var sprite: Sprite3D = get_node("Sprite3D")
	var picture := sprite.texture.get_image()
	if picture == null or picture.is_empty():
		push_error("Reaction diffusion viewport has no source image for export")
		return
	var panel := MeshInstance3D.new()
	panel.name = "OriginalViewportSpriteSnapshot"
	var quad := QuadMesh.new()
	quad.size = Vector2(picture.get_width(),picture.get_height())*sprite.pixel_size
	panel.mesh=quad;panel.transform=sprite.transform
	var finish := StandardMaterial3D.new()
	finish.albedo_texture=ImageTexture.create_from_image(picture)
	finish.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	finish.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	finish.cull_mode=BaseMaterial3D.CULL_DISABLED
	panel.material_override=finish;add_child(panel)
	sprite.hide()
	set_meta("void_preview_kind","viewport_sprite_snapshot")
