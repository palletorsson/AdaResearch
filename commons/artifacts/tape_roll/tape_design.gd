extends RefCounted
## Tape designs (tapes.json): colour, pattern and print, painted by the same rule as the tape studio
## page (ada_encyclopedia src/lib/tape-design.ts texel()), texel for texel. A roll with `tape: <id>`
## wears one; the masking, pink and barrier rolls keep their own skins.
const FILE := "res://commons/artifacts/tape_roll/tapes.json"
const TILE_W := 256
const TILE_H := 64

static func load_design(id: String) -> Dictionary:
	if id == "" or not FileAccess.file_exists(FILE):return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	if not data is Dictionary:return {}
	var d: Variant = (data as Dictionary).get("tapes", {}).get(id, {})
	return d if d is Dictionary else {}

static func _fmod1(x: float) -> float:
	return x - floor(x)

## One texel of a tile w x h (one repeat along the tape, its full width across), as 0..255 per channel.
static func texel(d: Dictionary, x: int, y: int, w: int = TILE_W, h: int = TILE_H) -> PackedInt32Array:
	var fx := (float(x) + 0.5) / float(w);var fy := (float(y) + 0.5) / float(h)
	var ratio := float(d.get("ratio", 0.5));var slant := float(d.get("slant", 0.0))
	var use_b := false
	match str(d.get("pattern", "solid")):
		"diagonal":use_b = _fmod1(fx + fy * slant) < ratio
		"bands":use_b = fx < ratio
		"stripe":use_b = absf(fy - 0.5) < ratio / 2.0
		"edges":use_b = fy < ratio / 2.0 or fy > 1.0 - ratio / 2.0
		"chevron":use_b = _fmod1(fx + absf(fy - 0.5) * slant) < ratio
		"checker":use_b = (int(floor(fx * 2.0)) + int(floor(fy * 2.0))) % 2 == 1
		"dots":use_b = Vector2((fx - 0.5) * float(d.get("pitch", 0.2)) / float(d.get("width", 0.075)), fy - 0.5).length() < ratio / 2.0
		"dashes":use_b = absf(fy - 0.5) < 0.12 and fx < ratio
	var c := Color(str(d.get("b" if use_b else "a", "ffffff")))
	var grain := sin(float(x) * 8.47 + sin(float(y) * 4.1)) * sin(float(y) * 9.73) * float(d.get("grain", 0.0))
	var edge := 1.0 - float(d.get("edge", 0.0)) if (y < 2 or y > h - 3) else 1.0
	var out := PackedInt32Array()
	for v in [c.r, c.g, c.b]:out.append(int(round(clampf(v * edge + grain, 0.0, 1.0) * 255.0)))
	return out

static func tile(d: Dictionary, w: int = TILE_W, h: int = TILE_H) -> Image:
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := texel(d, x, y, w, h)
			image.set_pixel(x, y, Color8(c[0], c[1], c[2]))
	return image

## The skin of a strip: one repeat per `pitch` metres (a strip's UV runs in metres).
static func material(d: Dictionary) -> StandardMaterial3D:
	var m := StandardMaterial3D.new();m.albedo_texture = ImageTexture.create_from_image(tile(d))
	m.uv1_scale = Vector3(1.0 / maxf(float(d.get("pitch", 0.2)), 0.001), 1, 1)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED;m.roughness = float(d.get("rough", 0.6))
	return m

## The paper a printed strip draws its words on: one repeat at the print's scale (96 px across the tape).
static func print_paper(d: Dictionary, px: int) -> Texture2D:
	var w := maxi(4, int(round(float(d.get("pitch", 0.2)) / maxf(float(d.get("width", 0.075)), 0.001) * px)))
	return ImageTexture.create_from_image(tile(d, w, px))
