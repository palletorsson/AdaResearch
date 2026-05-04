extends SceneTree

## Render a preview image of the PresenceGrid that *would* be seeded
## from a map's biome_paint layer. Lets you SEE where the deposits
## land before any live-rendering pipeline is wired up.
##
## Output:
##   user://biome_paint/<map>_<channel>.png    (one per kingdom channel)
##   user://biome_paint/<map>_combined.png     (RGBA composite)
##
## Usage:
##   godot --xr-mode off --headless --script res://commons/testing/capture_biome_paint_preview.gd -- --map=<MapName>
##
## How it composes:
##   1. Load commons/maps/<map>/map_data.json
##   2. Pull layers.biome_paint
##   3. Spin up a fresh PresenceGrid sized to the map
##   4. For each painted cell, deposit at the cell's world centre
##      (just like NatureRenderer._seed_from_biome_paint does)
##   5. Run several diffusion ticks so soft edges form
##   6. Save the resulting RGBA texture as PNGs

const _PresenceGrid = preload("res://algorithms/nature_system/systems/presence_grid.gd")
const _BiomePaintTokens = preload("res://algorithms/nature_system/systems/biome_paint_tokens.gd")

var _map: String = "Wavefunctions_Sky_Stairs"
var _diffusion_steps: int = 30
var _resolution: int = 256


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var s := String(raw).strip_edges()
		if s.begins_with("--map="):
			_map = s.substr(6)
		elif s.begins_with("--steps="):
			_diffusion_steps = int(s.substr(8))
		elif s.begins_with("--res="):
			_resolution = int(s.substr(6))
	call_deferred("_run")


func _run() -> void:
	var map_path := "res://commons/maps/%s/map_data.json" % _map
	var f := FileAccess.open(map_path, FileAccess.READ)
	if f == null:
		push_error("map not found: %s" % map_path); quit(1); return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		push_error("bad json in %s" % map_path); quit(1); return
	var data = json.data
	if not (data is Dictionary):
		push_error("map_data not dict"); quit(1); return

	var layers = data.get("layers", {})
	var paint = layers.get("biome_paint", null)
	if not (paint is Array) or paint.is_empty():
		push_error("map has no biome_paint layer: %s" % _map); quit(1); return

	var dims: Dictionary = data.get("map_info", {}).get("dimensions", {"width": 16, "depth": 16})
	var W: int = int(dims.get("width", 16))
	var D: int = int(dims.get("depth", 16))
	var cube_size: float = 1.0
	var map_size := Vector2(float(W) * cube_size, float(D) * cube_size)

	print("biome_paint preview: map=%s W=%d D=%d cube=%.2f" % [_map, W, D, cube_size])

	var grid = _PresenceGrid.new(_resolution, map_size)

	# Cell-to-world: cell (x, z) → world ((x - W/2 + 0.5) * cube, _, (z - D/2 + 0.5) * cube)
	var x0: float = -float(W) * cube_size * 0.5 + cube_size * 0.5
	var z0: float = -float(D) * cube_size * 0.5 + cube_size * 0.5

	var painted := _BiomePaintTokens.iter_painted_cells(paint)
	var total: int = 0
	# Use a generous radius so the painted blob is clearly visible at
	# 256x256 over a 13x14 metre map. cube_size×4 spreads each deposit
	# across roughly 1/4 of a cell-equivalent visually.
	var deposit_radius: float = cube_size * 4.0
	var carve_total: int = 0
	for cell in painted:
		var cx: int = int(cell.get("x", 0))
		var cz: int = int(cell.get("z", 0))
		var world_pos := Vector3(x0 + cx * cube_size, 0.0, z0 + cz * cube_size)
		if cell.get("sterile", false):
			grid.carve(world_pos, 1.0, deposit_radius)
			carve_total += 1
			continue
		var k: int = int(cell.get("kingdom", -1))
		var s: float = float(cell.get("strength", 0.0))
		if k < 0 or s <= 0.0:
			continue
		grid.deposit(world_pos, k, s, deposit_radius)
		total += 1
	print("  deposited %d cells, carved %d" % [total, carve_total])

	# Run diffusion for a while to soften the edges.
	# PresenceGrid.process is rate-limited; force iterations directly.
	# Also force at least one pass so _rebuild_texture runs.
	for i in max(1, _diffusion_steps):
		grid.process(grid.process_interval + 0.01)
	print("  diffused %d steps" % max(1, _diffusion_steps))

	# Save the texture as PNGs. Use the live _data array — get_texture()
	# returns an ImageTexture but extracting its image can lose precision
	# in editor / headless runs. Read the pixels we know about directly.
	var img := Image.create(grid.resolution, grid.resolution, false, Image.FORMAT_RGBA8)
	for y in grid.resolution:
		for x in grid.resolution:
			img.set_pixel(x, y, grid._data[y * grid.resolution + x])
	if img == null:
		push_error("PresenceGrid produced no image"); quit(1); return

	var out_dir := "user://biome_paint"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	# Composite — kingdoms are stuffed into RGBA channels (R=tree, G=creature, B=flower, A=fungus).
	# As a viewable image, save it directly. Alpha will look like fungus density.
	var composite := img.duplicate()
	var composite_path := "%s/%s_combined.png" % [out_dir, _map]
	composite.save_png(composite_path)
	print("  -> %s" % composite_path)

	# Per-channel images (each channel as greyscale RGB). Helps see one
	# kingdom at a time without alpha confusion.
	var channel_names: Array = ["tree", "creature", "flower", "fungus"]
	for ch_idx in 4:
		var ch_img := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGB8)
		for y in img.get_height():
			for x in img.get_width():
				var c: Color = img.get_pixel(x, y)
				var v: float = [c.r, c.g, c.b, c.a][ch_idx]
				ch_img.set_pixel(x, y, Color(v, v, v))
		var ch_path := "%s/%s_%s.png" % [out_dir, _map, channel_names[ch_idx]]
		ch_img.save_png(ch_path)
		print("  -> %s" % ch_path)

	quit(0)
