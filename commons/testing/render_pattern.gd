extends SceneTree

## Render a wallpaper-group pattern config to a PNG.
## DNA = { group, tile_size, motif_seed, palette, motif, canvas_size, density }.
##
## Usage:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/render_pattern.gd -- \
##     --config=<path.json> --out=user://pattern_gallery/<id>.png

const PatternSimScript = preload("res://commons/pattern_grammar/pattern_sim.gd")

var _config_path: String = ""
var _output_path: String = "user://pattern_gallery/out.png"


func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty():
		push_error("render_pattern: --config required"); quit(1); return
	call_deferred("_run")


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := String(raw).strip_edges()
		if not a.begins_with("--"): continue
		var eq := a.find("=")
		if eq <= 2: continue
		var key := a.substr(2, eq - 2)
		var val := a.substr(eq + 1)
		match key:
			"config": _config_path = val
			"out":    _output_path = val


func _run() -> void:
	var txt := FileAccess.get_file_as_string(_config_path)
	if txt.is_empty():
		txt = FileAccess.get_file_as_string(ProjectSettings.globalize_path(_config_path))
	if txt.is_empty():
		push_error("render_pattern: empty config"); quit(1); return
	var j := JSON.new()
	if j.parse(txt) != OK or not (j.data is Dictionary):
		push_error("render_pattern: bad JSON"); quit(1); return
	var cfg: Dictionary = j.data

	print("render_pattern: group=%s canvas=%d tile=%d seed=%d" % [
		cfg.get("group", "p4m"),
		int(cfg.get("canvas_size", 512)),
		int(cfg.get("tile_size", 32)),
		int(cfg.get("motif_seed", 7)),
	])

	var img: Image = PatternSimScript.render_to_image(cfg)
	if img == null:
		push_error("render_pattern: render returned null"); quit(1); return

	var abs_out := ProjectSettings.globalize_path(_output_path)
	var od := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(od):
		DirAccess.make_dir_recursive_absolute(od)
	var err := img.save_png(abs_out)
	if err != OK:
		push_error("render_pattern: save failed"); quit(1); return
	print("render_pattern: saved %s" % abs_out)
	quit(0)
