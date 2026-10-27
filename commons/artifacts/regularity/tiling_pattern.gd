extends RefCounted
## One integer raster rule, shared by the hall, close study and eye chart.
## Coordinates are image addresses: x goes right, y goes down.

static func image_for(rule: int, phase: int, exception: bool, columns: int = 8, rows: int = 8, tile_pixels: int = 32) -> Image:
	var image_ := Image.create(columns * tile_pixels, rows * tile_pixels, false, Image.FORMAT_RGB8)
	for y in image_.get_height():
		for x in image_.get_width():
			var cy: int = y / tile_pixels
			var px := x
			if rule == 4: px += (cy % 2) * (tile_pixels / 2)
			var cx: int = px / tile_pixels
			var u := px % tile_pixels
			var v := y % tile_pixels
			var rotation := phase
			if rule == 2: rotation += (cx + cy) % 4
			if rule == 5 and exception and cx == 3 and cy == 3: rotation += 1
			for r in rotation % 4:
				var old_u := u
				u = v
				v = tile_pixels - 1 - old_u
			if rule == 3 and cx % 2 == 1: u = tile_pixels - 1 - u
			var black := u > v
			if rule == 1 and (cx + cy) % 2 == 1: black = not black
			image_.set_pixel(x, y, Color.BLACK if black else Color.WHITE)
	return image_


const Rules := preload("res://commons/artifacts/regularity/address_rules.gd")


## A field whose tiles an ADDRESS RULE orients (address_rules.gd: the palette floor's twenty rules,
## the same names as the spatial lab's). The state the rule gives tile (cx, cy) sets its turn,
## mirror, inversion, or turn and inversion; sampling runs as image_for's does (turn, then mirror,
## then the motif), so a rule-driven field and the hall's six read alike. image_for is untouched.
## motif: "triangle" (the hall's: black where u > v) or "quarters" (Truchet's quarter circles).
static func rule_image(rule: String, attribute: String, motif: String, phase: int, columns: int = 8, rows: int = 8, tile_pixels: int = 32) -> Image:
	var image_ := Image.create(columns * tile_pixels, rows * tile_pixels, false, Image.FORMAT_RGB8)
	var states: int = 4 if attribute == "turn" else (8 if attribute == "turn + invert" else 2)
	var half: float = tile_pixels * 0.5
	for y in image_.get_height():
		for x in image_.get_width():
			var cx: int = x / tile_pixels
			var cy: int = y / tile_pixels
			var s: int = Rules.state(rule, cx, cy, states, columns)
			var rotation := phase
			var mirror := false
			var invert := false
			match attribute:
				"turn": rotation += s
				"mirror": mirror = s == 1
				"invert": invert = s == 1
				_:
					rotation += s % 4
					invert = s >= 4
			var u := x % tile_pixels
			var v := y % tile_pixels
			for r in rotation % 4:
				var old_u := u
				u = v
				v = tile_pixels - 1 - old_u
			if mirror: u = tile_pixels - 1 - u
			var black := u > v
			if motif == "quarters":
				var a := Vector2(u + 0.5, v + 0.5)
				black = a.length() < half or (a - Vector2(tile_pixels, tile_pixels)).length() < half
			if invert: black = not black
			image_.set_pixel(x, y, Color.BLACK if black else Color.WHITE)
	return image_

