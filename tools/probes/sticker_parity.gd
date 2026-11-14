extends SceneTree
## STICKER PARITY, THE GODOT HALF (2026-11-13). Lays every design of a designs.json out on a grid exactly as
## tools/sticker_parity.py lays them out for headless Chrome - each design's stored svg rasterised by ThorVG
## (Image.load_svg_from_string) to LONG px on its long side, centred in a CELL x CELL cell, transparent elsewhere - and
## saves the sheet. The Python half compares the two sheets cell by cell.
##
##   godot --headless --path . --xr-mode off --script res://tools/probes/sticker_parity.gd -- --designs=<json> --out=<png>
const CELL := 128
const LONG := 120
const COLS := 10


func _initialize() -> void:
	var src := ""
	var out := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--designs="): src = arg.trim_prefix("--designs=")
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(src))
	if not doc is Dictionary:
		push_error("sticker_parity: no designs at " + src)
		quit(1)
		return
	var designs: Array = doc.designs
	var rows := int(ceil(designs.size() / float(COLS)))
	var sheet := Image.create(COLS * CELL, maxi(rows, 1) * CELL, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for i in designs.size():
		var svg: String = designs[i].svg
		var w := float(svg.get_slice("width=\"", 1).get_slice("\"", 0))
		var h := float(svg.get_slice("height=\"", 1).get_slice("\"", 0))
		var img := Image.new()
		if img.load_svg_from_string(svg, LONG / maxf(w, h)) != OK:
			continue
		img.convert(Image.FORMAT_RGBA8)
		var ox := (i % COLS) * CELL + (CELL - img.get_width()) / 2
		var oy := (i / COLS) * CELL + (CELL - img.get_height()) / 2
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(ox, oy))
	sheet.save_png(out)
	print("[sticker_parity] ", designs.size(), " designs -> ", out)
	quit()
