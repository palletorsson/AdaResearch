@tool
extends RefCounted
class_name BakedTextAlbedo

## Bake text into an albedo texture suitable for any mesh's material.
##
## Use this when you want text to read as part of an artifact's
## surface — printed on the body — rather than floating in front of
## it as a Label3D. The text becomes part of the material, gets lit
## by scene lights, and stays attached to the mesh's UV.
##
## A SubViewport with ColorRect background + Label foreground is
## attached to `host`, rendered for one frame, then queue_freed; the
## final ImageTexture is returned. Caller is responsible for assigning
## it to a material:
##
##   var tex = await BakedTextAlbedo.generate("FIRE", self, ...)
##   var mat: StandardMaterial3D = body.material_override
##   mat.albedo_color = Color.WHITE     # don't tint baked texture
##   mat.albedo_texture = tex
##
## `text_uv.x` controls horizontal position around a CylinderMesh
## (U: 0..1 wraps 360°). For default CylinderMesh UVs:
##   0.00 — +X side    0.25 — +Z (front)
##   0.50 — -X side    0.75 — -Z (back)
##
## Pass `band` to overlay a horizontal stripe (the accent band
## familiar from real safety equipment), e.g.
##   {"color": Color.WHITE, "v_min": 0.46, "v_max": 0.54}


static func generate(
		text: String,
		host: Node,
		bg_color: Color = Color(0.85, 0.05, 0.05, 1.0),
		text_color: Color = Color.WHITE,
		image_size: Vector2i = Vector2i(1024, 512),
		font_size: int = 192,
		text_uv: Vector2 = Vector2(0.5, 0.5),
		band: Dictionary = {}) -> ImageTexture:
	if host == null or not host.is_inside_tree():
		push_warning("BakedTextAlbedo.generate: host must be in tree")
		return null

	var vp := SubViewport.new()
	vp.size = image_size
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	host.add_child(vp)

	# Background fill — covers the whole texture, becomes the body
	# colour when sampled by the mesh.
	var bg := ColorRect.new()
	bg.color = bg_color
	bg.size = Vector2(image_size)
	vp.add_child(bg)

	# Optional horizontal accent band. Drawn BEFORE the text so the
	# text reads over the band (e.g. red FIRE on a white band).
	if band.has("color") and band.has("v_min") and band.has("v_max"):
		var band_rect := ColorRect.new()
		band_rect.color = band["color"]
		var v_min: float = float(band["v_min"])
		var v_max: float = float(band["v_max"])
		band_rect.position = Vector2(0.0, v_min * image_size.y)
		band_rect.size = Vector2(image_size.x, (v_max - v_min) * image_size.y)
		vp.add_child(band_rect)

	# Text label centred on text_uv. Use a band of full image width
	# but limited height; the label is shifted horizontally so the
	# centre of its centred text lands at text_uv.x.
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", text_color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var label_height: float = float(font_size) * 1.4
	label.size = Vector2(image_size.x, label_height)
	label.position = Vector2(
		(text_uv.x - 0.5) * image_size.x,
		text_uv.y * image_size.y - label_height * 0.5)
	vp.add_child(label)

	# Two-frame wait so the viewport draws the children before we read.
	await host.get_tree().process_frame
	await host.get_tree().process_frame

	var image: Image = vp.get_texture().get_image()
	vp.queue_free()

	if image == null:
		push_warning("BakedTextAlbedo.generate: viewport returned null image")
		return null
	return ImageTexture.create_from_image(image)
