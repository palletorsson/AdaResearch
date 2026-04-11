# capture_editors.gd — Launch each editor, wait, capture screenshot, move to next
# Run: godot --path . --xr-mode off --script res://commons/scenes/editors/capture_editors.gd
extends SceneTree

const EDITORS: Array[Dictionary] = [
	{"scene": "res://commons/scenes/editors/morpho_modifier_editor.tscn", "name": "morpho_modifier"},
	{"scene": "res://commons/scenes/editors/morpho_pipeline_editor.tscn", "name": "morpho_pipeline"},
	{"scene": "res://commons/scenes/editors/glass_tube_editor.tscn", "name": "glass_tube"},
	{"scene": "res://commons/scenes/editors/parametric_surface_editor.tscn", "name": "parametric_surface"},
	{"scene": "res://commons/scenes/editors/mesh_grammar_editor.tscn", "name": "mesh_grammar"},
	{"scene": "res://commons/scenes/editors/procedural_columns_editor.tscn", "name": "procedural_columns"},
	{"scene": "res://commons/scenes/editors/sculpture_editor.tscn", "name": "sculpture"},
	{"scene": "res://commons/scenes/editors/sine_object_editor.tscn", "name": "sine_object"},
	{"scene": "res://commons/scenes/editors/floor_pattern_editor.tscn", "name": "floor_pattern"},
]

var _current_idx: int = 0
var _wait_frames: int = 0
var _output_dir: String = "user://editor_captures"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

func _process(delta: float) -> bool:
	_wait_frames += 1

	if _wait_frames == 1:
		# Load first editor
		if _current_idx < EDITORS.size():
			var scene_path: String = EDITORS[_current_idx]["scene"]
			print("[Capture] Loading: ", scene_path)
			change_scene_to_file(scene_path)
		else:
			print("[Capture] All done!")
			quit()
		return false

	if _wait_frames == 60:  # Wait 1 second at 60fps for scene to render
		# Capture screenshot
		var name: String = EDITORS[_current_idx]["name"]
		var viewport: Viewport = root
		var img: Image = viewport.get_texture().get_image()
		var path: String = _output_dir + "/" + name + ".png"
		var err: int = img.save_png(ProjectSettings.globalize_path(path))
		if err == OK:
			print("[Capture] Saved: ", path)
		else:
			print("[Capture] FAILED to save: ", path, " error=", err)

		# Next editor
		_current_idx += 1
		_wait_frames = 0

	return false
