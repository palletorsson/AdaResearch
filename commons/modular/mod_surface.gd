class_name ModularSurface
extends RefCounted
## Module: a surface — the "association" that turns a line into tape or a cube
## into a wooden box. apply(node, name) overrides the material of every mesh
## under the node except the points and strokes that draw the construction.

const NAMES := ["tape", "stripes", "red", "rubber", "metal", "urethane", "grip", "hazard", "wood", "concrete", "cardboard", "warhol", "plastic", "paper", "glow", "rim", "pink_rim"]
const TAPE_PHOTO := "res://commons/modular/textures/marking_tape.png"


static func material(name: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.roughness = 0.9
	match name:
		"tape":
			# Palle's marking tape, the photo, tiled along the length
			var photo: Texture2D = _photo(TAPE_PHOTO)
			m.albedo_texture = photo if photo != null else _diagonal(Color("fef100"), Color("221f20"))
			m.uv1_scale = Vector3(3, 1, 1)
			m.roughness = 0.75
		"stripes":
			m.albedo_texture = _bands([Color("f2eee6"), Color("c83a2f")], 8)
			m.uv1_scale = Vector3(4, 1, 1)
		"red":
			m.albedo_color = Color("c83a2f")
		"rubber":
			m.albedo_color = Color("2a2a2e")
			m.roughness = 0.95
		"metal":
			m.albedo_color = Color("b8bcc2")
			m.roughness = 0.35
			m.metallic = 0.85
		"urethane":
			m.albedo_color = Color("f1e3c2")
			m.roughness = 0.55
		"glow":
			# emission: it is bright without being lit — visible brightness is not illumination
			m.albedo_color = Color("e0568a")
			m.emission_enabled = true
			m.emission = Color("e0568a")
			m.emission_energy_multiplier = 1.4
		"rim":
			# a view-dependent rim: the edge brightens toward grazing angles, whatever the light
			m.albedo_color = Color("3d5a9a")
			m.rim_enabled = true
			m.rim = 1.0
			m.rim_tint = 0.4
			m.roughness = 0.6
		"pink_rim":
			m.albedo_color = Color("f4a6c8")
			m.rim_enabled = true
			m.rim = 1.0
			m.rim_tint = 0.0
			m.emission_enabled = true
			m.emission = Color("f4a6c8")
			m.emission_energy_multiplier = 0.25
			m.roughness = 0.5
		"grip":
			m.albedo_color = Color("1c1c1e")
			m.roughness = 1.0
		"hazard":
			m.albedo_texture = _diagonal(Color("fef100"), Color("221f20"))
			m.uv1_scale = Vector3(4, 1, 1)
		"wood":
			m.albedo_color = Color("c9a978")
			m.albedo_texture = _bands([Color("c9a978"), Color("b8945f")], 16)
			m.uv1_scale = Vector3(1, 6, 1)
		"concrete":
			m.albedo_color = Color("bdb7ad")
			m.roughness = 1.0
		"cardboard":
			m.albedo_color = Color("d3b48c")
		"warhol":
			m.albedo_texture = _bands([Color("f2eee6"), Color("c83a2f"), Color("f2eee6"), Color("2f5fb8")], 4)
			m.uv1_scale = Vector3(1, 2, 1)
		"plastic":
			m.albedo_color = Color("e0742a")
			m.roughness = 0.35
			m.metallic = 0.1
		"paper":
			m.albedo_color = Color("f3ecdd")
		_:
			m.albedo_color = Color(name) if name.is_valid_html_color() else Color("f3ecdd")
	return m


static func apply(node: Node, name: String) -> void:
	var mat := material(name)
	_walk(node, mat)


static func _walk(n: Node, mat: Material) -> void:
	if n is MeshInstance3D and not n.has_meta("construction_mark"):
		(n as MeshInstance3D).material_override = mat
	for c in n.get_children():
		_walk(c, mat)


## A photo as a texture: the imported resource when the editor has imported it, else the
## file read directly (a headless run on a fresh checkout has no .import yet), else null.
static func _photo(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var t: Variant = load(path)
		if t is Texture2D:
			return t
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img != null and not img.is_empty():
		return ImageTexture.create_from_image(img)
	return null


## Diagonal warning stripes drawn into an image (the marking tape without the photo).
static func _diagonal(a: Color, b: Color) -> ImageTexture:
	var w := 256
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var band := w / 4.0
	var slant := h * 0.55
	for y in range(h):
		var shift: float = slant * (float(y) / h)
		for x in range(w):
			var u: float = fposmod(float(x) + shift, band * 2.0)
			img.set_pixel(x, y, b if u < band else a)
	var t := ImageTexture.create_from_image(img)
	return t


## A tiny horizontal band texture (nearest-neighbour, so the bands stay crisp).
static func _bands(colors: Array, per: int) -> ImageTexture:
	var w: int = colors.size() * per
	var img := Image.create(w, 1, false, Image.FORMAT_RGBA8)
	for x in range(w):
		img.set_pixel(x, 0, colors[(x / per) % colors.size()])
	var t := ImageTexture.create_from_image(img)
	return t
