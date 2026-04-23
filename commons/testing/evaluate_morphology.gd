extends SceneTree

const MorphologySimClass = preload("res://commons/morphology_grammar/morphology_sim.gd")

var _config_path: String = ""
var _output_path: String = "user://morphology_gallery/eval.json"


func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty():
		push_error("evaluate_morphology: --config=<path> required")
		quit(1)
		return
	call_deferred("_run")


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := String(raw).strip_edges()
		if not a.begins_with("--"):
			continue
		var eq := a.find("=")
		if eq <= 2:
			continue
		var key := a.substr(2, eq - 2)
		var val := a.substr(eq + 1)
		match key:
			"config":
				_config_path = val
			"out":
				_output_path = val


func _run() -> void:
	var txt := FileAccess.get_file_as_string(_config_path)
	if txt.is_empty():
		txt = FileAccess.get_file_as_string(ProjectSettings.globalize_path(_config_path))
	if txt.is_empty():
		push_error("evaluate_morphology: empty config")
		quit(1)
		return

	var json := JSON.new()
	if json.parse(txt) != OK or not (json.data is Dictionary):
		push_error("evaluate_morphology: invalid JSON")
		quit(1)
		return

	var cfg: Dictionary = json.data
	var sim = MorphologySimClass.new()
	var result: Dictionary = sim.simulate(cfg)
	var mesh_data = result.get("mesh_data")
	if mesh_data == null:
		push_error("evaluate_morphology: missing mesh_data")
		quit(1)
		return

	var summary := sim.summarize(mesh_data)
	summary["id"] = cfg.get("id", "")
	summary["family"] = cfg.get("family", "")

	var abs_out := ProjectSettings.globalize_path(_output_path)
	var out_dir := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(out_dir):
		DirAccess.make_dir_recursive_absolute(out_dir)
	var fa := FileAccess.open(abs_out, FileAccess.WRITE)
	if fa == null:
		push_error("evaluate_morphology: failed to open output")
		quit(1)
		return
	fa.store_string(JSON.stringify(summary, "  "))
	fa.close()
	print("evaluate_morphology: saved %s" % abs_out)
	quit(0)
