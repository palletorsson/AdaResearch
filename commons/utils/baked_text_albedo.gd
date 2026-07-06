@tool
extends RefCounted
class_name BakedTextAlbedo

## Render arbitrary text into an ImageTexture by drawing glyph bitmaps
## directly into an Image via TextServer. No SubViewport, no render-loop
## dependency, works under --no-window / headless modes.
##
## The result is a transparent-bg image with the text painted in
## text_color (alpha taken from each glyph's coverage mask). Intended
## use is as the albedo of a Decal node projected onto an artifact's
## body — see commons/artifacts/fire_extinguisher for the canonical
## example.
##
## Process-level cache keys on (text + colour + size + font_size) so
## repeated calls with the same args reuse a single ImageTexture.

static var _texture_cache: Dictionary = {}


static func _cache_key(text: String, text_color: Color,
		image_size: Vector2i, font_size: int) -> String:
	return "%s|%s|%dx%d|%d" % [
		text, text_color, image_size.x, image_size.y, font_size]


## Render `text` into a transparent-bg ImageTexture at the given size.
## text_color tints the glyph mask. Image size should be large enough
## to contain the text at the chosen font_size — text is centred.
##
## Returns null if the font is unavailable or the text is empty.
static func generate_text_image(
		text: String,
		text_color: Color = Color.WHITE,
		image_size: Vector2i = Vector2i(512, 256),
		font_size: int = 160) -> ImageTexture:
	if text.is_empty():
		return null
	var key := _cache_key(text, text_color, image_size, font_size)
	if _texture_cache.has(key):
		return _texture_cache[key]

	var font: Font = ThemeDB.fallback_font
	if font == null:
		push_warning("BakedTextAlbedo: no fallback font")
		return null
	var font_rids: Array = font.get_rids()
	if font_rids.is_empty():
		push_warning("BakedTextAlbedo: font has no RIDs")
		return null
	var font_rid: RID = font_rids[0]
	var font_size_v := Vector2i(font_size, 0)

	var ts := TextServerManager.get_primary_interface()
	if ts == null:
		push_warning("BakedTextAlbedo: no TextServer interface")
		return null

	# Target image, fully transparent. set_pixel writes the tinted text.
	var img := Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Measure total text width by summing advances. We also collect the
	# glyph data per character so we don't re-query TextServer for each
	# render pass.
	var glyphs: Array = []
	var text_width: float = 0.0
	for c in text:
		var unicode := c.unicode_at(0)
		var gi: int = ts.font_get_glyph_index(font_rid, font_size, unicode, 0)
		if gi == 0:
			# Skip unrenderable codepoints, still advance space-ish.
			text_width += float(font_size) * 0.3
			continue
		# Make sure the glyph is rendered into the atlas cache. This
		# call is idempotent for already-cached glyphs. Signature is
		# (font_rid, size_v: Vector2i, glyph_index: int).
		ts.font_render_glyph(font_rid, font_size_v, gi)
		var advance: Vector2 = ts.font_get_glyph_advance(font_rid, font_size, gi)
		glyphs.append({
			"index": gi,
			"advance": advance,
		})
		text_width += advance.x

	# Centred origin. baseline_y is the glyph baseline — font_get_glyph_offset
	# returns offsets relative to the baseline, with .y typically negative
	# (the glyph rises above its baseline).
	var origin_x: float = (float(image_size.x) - text_width) * 0.5
	var baseline_y: float = float(image_size.y) * 0.5 + float(font_size) * 0.32

	# Blit each glyph from its atlas tile into the target image.
	var cursor_x: float = origin_x
	for g in glyphs:
		var gi: int = g["index"]
		var advance: Vector2 = g["advance"]

		var tex_idx: int = ts.font_get_glyph_texture_idx(font_rid, font_size_v, gi)
		if tex_idx < 0:
			cursor_x += advance.x
			continue
		var atlas: Image = ts.font_get_texture_image(font_rid, font_size_v, tex_idx)
		if atlas == null:
			cursor_x += advance.x
			continue
		var uv: Rect2 = ts.font_get_glyph_uv_rect(font_rid, font_size_v, gi)
		var off: Vector2 = ts.font_get_glyph_offset(font_rid, font_size_v, gi)
		var glyph_w: int = int(uv.size.x)
		var glyph_h: int = int(uv.size.y)
		if glyph_w <= 0 or glyph_h <= 0:
			cursor_x += advance.x
			continue

		var dst_origin_x: int = int(round(cursor_x + off.x))
		var dst_origin_y: int = int(round(baseline_y + off.y))
		var aw: int = atlas.get_width()
		var ah: int = atlas.get_height()

		for gy in range(glyph_h):
			var ay: int = dst_origin_y + gy
			if ay < 0 or ay >= image_size.y:
				continue
			var sy: int = int(uv.position.y) + gy
			if sy < 0 or sy >= ah:
				continue
			for gx in range(glyph_w):
				var ax: int = dst_origin_x + gx
				if ax < 0 or ax >= image_size.x:
					continue
				var sx: int = int(uv.position.x) + gx
				if sx < 0 or sx >= aw:
					continue
				var src_px: Color = atlas.get_pixel(sx, sy)
				# Glyph atlas pixel coverage formula that works across
				# the three formats Godot rasterises into:
				#   L8   — luminance = coverage, alpha = 1.0
				#   LA8  — luminance = 1, alpha = coverage
				#   RGBA — RGB = white in glyph, alpha = coverage
				# Multiplying luminance by alpha collapses to coverage
				# in every case (max RGB gives 1 in LA8/RGBA cases and
				# the actual luminance in L8).
				var lum: float = max(src_px.r, max(src_px.g, src_px.b))
				var coverage: float = lum * src_px.a
				if coverage < 0.02:
					continue
				img.set_pixel(ax, ay, Color(
					text_color.r, text_color.g, text_color.b,
					coverage * text_color.a))

		cursor_x += advance.x

	var tex := ImageTexture.create_from_image(img)
	_texture_cache[key] = tex
	return tex


## Convenience for callers that want to embed the text into an opaque
## panel (band background + text on top). Returns an ImageTexture with
## the bg colour everywhere, a centred horizontal band, and the text
## painted over it. Useful when you want the result to look like a
## printed label patch rather than a decal sticker.
static func generate_panel_image(
		text: String,
		bg_color: Color = Color(0.85, 0.05, 0.05, 1.0),
		text_color: Color = Color.WHITE,
		image_size: Vector2i = Vector2i(512, 256),
		font_size: int = 160,
		band: Dictionary = {}) -> ImageTexture:
	# Render the text mask first (transparent bg).
	var text_tex: ImageTexture = generate_text_image(text, text_color, image_size, font_size)
	if text_tex == null:
		return null
	# Compose: bg + optional band + text mask.
	var panel := Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	panel.fill(bg_color)
	if band.has("color") and band.has("v_min") and band.has("v_max"):
		var band_color: Color = band["color"]
		var v_min: float = float(band["v_min"])
		var v_max: float = float(band["v_max"])
		var y0: int = int(v_min * image_size.y)
		var y1: int = int(v_max * image_size.y)
		for y in range(max(0, y0), min(image_size.y, y1)):
			for x in range(image_size.x):
				panel.set_pixel(x, y, band_color)
	# Blend text mask on top.
	var text_img: Image = text_tex.get_image()
	if text_img != null:
		for y in range(image_size.y):
			for x in range(image_size.x):
				var tpx: Color = text_img.get_pixel(x, y)
				if tpx.a < 0.02:
					continue
				var bpx: Color = panel.get_pixel(x, y)
				var out_r: float = tpx.r * tpx.a + bpx.r * (1.0 - tpx.a)
				var out_g: float = tpx.g * tpx.a + bpx.g * (1.0 - tpx.a)
				var out_b: float = tpx.b * tpx.a + bpx.b * (1.0 - tpx.a)
				panel.set_pixel(x, y, Color(out_r, out_g, out_b, 1.0))
	return ImageTexture.create_from_image(panel)


# ── Drop-in mesh helpers — the integrated-text principle ──────────────
# These return a ready-to-place MeshInstance3D (a QuadMesh facing +Z) whose
# albedo is baked text, so a prop can paint its signage ONTO its surface instead
# of floating a Label3D in front of it (the fire_extinguisher principle). Size the
# quad in METERS roughly where the old Label3D sat; the font auto-fits the width.

## A lit, transparent-background text quad — text painted across the surface, the
## bare-letters case (no plate). `world_size` is the quad size in meters. Pass
## `unshaded=true` for a self-lit readout (screens), false (default) for paint that
## takes scene light. Returns a MeshInstance3D (QuadMesh, +Z normal) or null.
static func make_label_mesh(text: String, text_color: Color, world_size: Vector2,
		px_per_m: int = 1400, unshaded: bool = false) -> MeshInstance3D:
	if text.is_empty():
		return null
	var img_sz := _image_size_for(world_size, px_per_m)
	var fs := _fit_font_size(text, img_sz)
	var tex: ImageTexture = generate_text_image(text, text_color, img_sz, fs)
	if tex == null:
		return null
	return _text_quad(tex, world_size, true, unshaded)


## A small floating TAG — an integrated 2D-in-3D display board: a framed dark
## face with a thin lit accent edge and text baked onto it, billboarded to face
## the viewer. The canonical "nice display" for short scene annotations (a value,
## an axis name) that would otherwise be a bare floating Label3D. Returns a Node3D
## (frame + face + accent + text). `world_h` is the board height in metres; width
## auto-fits the text. Set billboard=false for a fixed-orientation board.
## `accent` colours the lit edge strip; pass Color(0,0,0,0) for no accent.
static func make_tag(text: String, text_color: Color = Color(0.9, 0.95, 1.0),
		world_h: float = 0.06, bg_color: Color = Color(0.08, 0.09, 0.11),
		billboard: bool = true, accent: Color = Color(0.86, 0.40, 0.16)) -> Node3D:
	if text.is_empty():
		return null
	var w: float = world_h * (0.9 + 0.66 * float(text.length()))   # auto-fit width to text (+margin so nothing clips)
	var root := Node3D.new()
	root.name = "Tag"
	var bb := BaseMaterial3D.BILLBOARD_ENABLED if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	# Frame plate — a slightly larger lighter border behind the face (the bezel).
	var frame := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(w + world_h * 0.16, world_h * 1.18, 0.004)
	frame.mesh = fbox
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = bg_color.lightened(0.22)
	fmat.roughness = 0.45
	fmat.metallic = 0.2
	fmat.billboard_mode = bb
	frame.material_override = fmat
	frame.position.z = -0.002
	root.add_child(frame)
	# Dark glass face.
	var plate := MeshInstance3D.new()
	var pbox := BoxMesh.new()
	pbox.size = Vector3(w, world_h, 0.006)
	plate.mesh = pbox
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = bg_color
	pmat.roughness = 0.35
	pmat.metallic = 0.1
	pmat.billboard_mode = bb
	plate.material_override = pmat
	root.add_child(plate)
	# Thin lit accent edge along the bottom — the "powered board" read.
	if accent.a > 0.0:
		var edge := MeshInstance3D.new()
		var ebox := BoxMesh.new()
		ebox.size = Vector3(w * 0.9, world_h * 0.09, 0.008)
		edge.mesh = ebox
		var emat := StandardMaterial3D.new()
		emat.albedo_color = accent
		emat.emission_enabled = true
		emat.emission = accent
		emat.emission_energy_multiplier = 1.4
		emat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		emat.billboard_mode = bb
		edge.material_override = emat
		edge.position = Vector3(0, -world_h * 0.44, 0.004)
		root.add_child(edge)
	# Baked text on the face — sized with margin inside the board so glyphs never touch the bezel.
	var label := make_label_mesh(text, text_color, Vector2(w * 0.86, world_h * 0.6), 1400, true)
	if label:
		label.position.z = 0.005
		if billboard:
			var lm = label.material_override
			if lm is StandardMaterial3D:
				lm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		root.add_child(label)
	return root


## An opaque label PLATE — background colour everywhere + text on top (the
## EMPLOYEES-ONLY / printed-patch case). Replaces a coloured BoxMesh plate plus its
## Label3D with one textured quad. `band` is forwarded to generate_panel_image.
static func make_panel_mesh(text: String, bg_color: Color, text_color: Color,
		world_size: Vector2, px_per_m: int = 1400, unshaded: bool = false,
		band: Dictionary = {}) -> MeshInstance3D:
	if text.is_empty():
		return null
	var img_sz := _image_size_for(world_size, px_per_m)
	var fs := _fit_font_size(text, img_sz)
	var tex: ImageTexture = generate_panel_image(text, bg_color, text_color, img_sz, fs, band)
	if tex == null:
		return null
	return _text_quad(tex, world_size, false, unshaded)


## Image resolution matching the quad's aspect (so glyphs aren't stretched),
## capped so a long thin sign doesn't allocate a giant texture.
static func _image_size_for(world_size: Vector2, px_per_m: int) -> Vector2i:
	var w: int = clampi(int(round(maxf(0.01, world_size.x) * float(px_per_m))), 16, 2048)
	var h: int = clampi(int(round(maxf(0.01, world_size.y) * float(px_per_m))), 16, 2048)
	return Vector2i(w, h)


## Largest font that keeps `text` inside ~90% of the image width AND ~70% of its
## height — so the text fills the quad without clipping at the edges.
static func _fit_font_size(text: String, img_sz: Vector2i) -> int:
	var n: int = maxi(1, text.length())
	# Fallback-font glyphs advance ~0.58·font on average; solve for the width fit.
	var by_width: int = int(0.90 * float(img_sz.x) / (0.58 * float(n)))
	var by_height: int = int(0.70 * float(img_sz.y))
	return clampi(mini(by_width, by_height), 8, 480)


static func _text_quad(tex: ImageTexture, world_size: Vector2, transparent: bool, unshaded: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = world_size
	mi.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = Color.WHITE
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A stacked block of baked text lines — for boards/screens that show several lines
## (whiteboard, info_screen, slide_projector). Returns a Node3D centred on its origin
## (+Z normal) holding one baked label quad per non-empty line, top line first. Each
## line quad is `max_width` wide × `line_height` tall; `gap` adds vertical spacing.
static func make_text_block(lines: Array, text_color: Color, line_height: float,
		max_width: float, gap: float = 0.0, unshaded: bool = false) -> Node3D:
	var root := Node3D.new()
	var n: int = lines.size()
	if n == 0:
		return root
	var pitch: float = line_height + gap
	var total: float = pitch * float(n)
	for i in range(n):
		var line := str(lines[i])
		if line.strip_edges() == "":
			continue
		var q: MeshInstance3D = make_label_mesh(line, text_color, Vector2(max_width, line_height), 1400, unshaded)
		if q == null:
			continue
		# Top line at the top of the block; block centred on the root origin.
		q.position = Vector3(0.0, total * 0.5 - line_height * 0.5 - pitch * float(i), 0.0)
		root.add_child(q)
	return root
