extends RefCounted
## The shelf's original AGAIN / YET editions, printed once into a shared atlas.
## A BoxMesh uses six UV tiles; every face carries the same edition mark.
const GLYPHS := {
	"A": [14,17,17,31,17,17,17], "G": [14,17,16,23,17,17,14],
	"I": [31,4,4,4,4,4,31], "N": [17,25,25,21,19,19,17],
	"Y": [17,17,10,4,4,4,4], "E": [31,16,16,30,16,16,31],
	"T": [31,4,4,4,4,4,4],
}

static func make_material(kind: int) -> StandardMaterial3D:
	var paper := Color("f2efe5") if kind == 0 else Color("c5e2cf")
	var accent := Color("cc473c") if kind == 0 else Color("167c79")
	var ink := Color("19333d")
	var word := "AGAIN" if kind == 0 else "YET"
	var atlas := Image.create(384, 256, false, Image.FORMAT_RGBA8)
	atlas.fill(paper)
	for row in 2:
		for column in 3:
			var origin := Vector2i(column * 128, row * 128)
			atlas.fill_rect(Rect2i(origin + Vector2i(0, 12), Vector2i(128, 9)), accent)
			atlas.fill_rect(Rect2i(origin + Vector2i(0, 106), Vector2i(128, 10)), accent)
			var left := (128 - word.length() * 18 + 3) / 2
			for letter in word.length():
				var glyph: Array = GLYPHS[word[letter]]
				for y in 7:
					for x in 5:
						if int(glyph[y]) & (1 << (4-x)):
							atlas.fill_rect(Rect2i(origin + Vector2i(left + letter*18 + x*3, 42+y*3), Vector2i(3,3)), ink)
			for bar in 23:
				var width := 2 if bar % 3 == 0 else 1
				atlas.fill_rect(Rect2i(origin + Vector2i(28+bar*3, 82), Vector2i(width,13)), ink)
	atlas.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(atlas)
	material.roughness = 0.78
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return material
