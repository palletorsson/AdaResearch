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
