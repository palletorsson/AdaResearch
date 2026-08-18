class_name ArtifactCatalogUI
extends Control

## Main artifact catalog UI controller
## Coordinates filters, browser, and preview components

signal spawn_requested(lookup_name: String)

const COMMENT_DEFAULT_MARKDOWN_PATH := "res://ada_run/desktop_feedback.md"

@onready var _header_label: Label = $VBoxContainer/Header/HBoxContainer/TitleLabel
@onready var _stats_label: Label = $VBoxContainer/Header/HBoxContainer/StatsLabel
@onready var _filters: ArtifactFilters = $VBoxContainer/Filters
@onready var _browser: ArtifactBrowser = $VBoxContainer/HSplitContainer/LeftPanel/Browser
@onready var _preview: ArtifactPreview = $VBoxContainer/HSplitContainer/RightPanel/Preview
@onready var _comment_edit: TextEdit = $VBoxContainer/HSplitContainer/RightPanel/CommentPanel/VBoxContainer/CommentEdit
@onready var _insert_artifact_button: Button = $VBoxContainer/HSplitContainer/RightPanel/CommentPanel/VBoxContainer/CommentButtons/InsertArtifactButton
@onready var _save_comment_button: Button = $VBoxContainer/HSplitContainer/RightPanel/CommentPanel/VBoxContainer/CommentButtons/SaveCommentButton
@onready var _comment_status_label: Label = $VBoxContainer/HSplitContainer/RightPanel/CommentPanel/VBoxContainer/CommentStatusLabel


func _ready():
	_setup_signals()
	# Defer both grid connection and initial refresh to ensure GridSystem is ready
	call_deferred("_connect_to_grid_system")
	call_deferred("_initial_refresh")


func _setup_signals():
	# Connect filter changes
	if _filters:
		_filters.filter_changed.connect(_on_filters_changed)

	# Connect browser selection
	if _browser:
		_browser.artifact_selected.connect(_on_artifact_selected)

	# Connect preview spawn button
	if _preview:
		_preview.spawn_requested.connect(_on_spawn_requested)

	if _insert_artifact_button:
		_insert_artifact_button.pressed.connect(_on_insert_artifact_comment_token_pressed)
	if _save_comment_button:
		_save_comment_button.pressed.connect(_on_save_comment_pressed)


func _connect_to_grid_system():
	# Find GridSystem and connect to map_generation_complete signal
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		return
	var scene_tree = get_tree()
	if not scene_tree:
		return

	var grid_systems = scene_tree.get_nodes_in_group("grid_system")
	if grid_systems.size() > 0:
		var grid_system = grid_systems[0]
		if grid_system.has_signal("map_generation_complete"):
			if not grid_system.map_generation_complete.is_connected(_on_map_generation_complete):
				grid_system.map_generation_complete.connect(_on_map_generation_complete)
				print("ArtifactCatalogUI: Connected to GridSystem map_generation_complete signal")


func _initial_refresh():
	# Wait for GridSystem to be available before first refresh
	# Since catalog is only created after map_generation_complete, GridSystem should exist
	var max_attempts = 50  # Increased timeout to 5 seconds
	var attempt = 0

	while attempt < max_attempts:
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			return
		var scene_tree = get_tree()
		if scene_tree:
			var grid_systems = scene_tree.get_nodes_in_group("grid_system")
			if grid_systems.size() > 0:
				print("ArtifactCatalogUI: GridSystem found in group, loading catalog...")
				_refresh_catalog()
				_update_stats()
				return
			elif attempt % 10 == 0:
				print("ArtifactCatalogUI: Still waiting for GridSystem... (attempt %d/%d)" % [attempt, max_attempts])

		attempt += 1
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().create_timer(0.1).timeout

	# If we get here, something is wrong but show empty catalog gracefully
	push_warning("ArtifactCatalogUI: Timeout waiting for GridSystem after 5 seconds")
	_refresh_catalog()
	_update_stats()


func _on_map_generation_complete():
	print("ArtifactCatalogUI: Map generation complete, refreshing catalog...")
	refresh()


func _refresh_catalog(theme: String = "all", complexity: String = "all", search: String = "", sequence_name: String = "all"):
	if _browser:
		_browser.populate(theme, complexity, search, sequence_name)

	if _preview:
		_preview.clear_preview()

	_update_stats()


func _update_stats():
	if not _stats_label:
		return

	var total = ArtifactCatalogDataProvider.get_total_artifact_count()

	# Handle case where GridSystem isn't loaded yet
	if total == 0:
		_stats_label.text = "Waiting for map to load..."
		return

	var unlocked = ArtifactCatalogDataProvider.get_unlocked_artifact_count()

	if OS.is_debug_build():
		_stats_label.text = "Artifacts: %d (Dev Mode - All Unlocked)" % total
	else:
		_stats_label.text = "Artifacts: %d / %d Unlocked" % [unlocked, total]


func _on_filters_changed(theme: String, complexity: String, sequence_name: String, search_text: String):
	_refresh_catalog(theme, complexity, search_text, sequence_name)


func _on_artifact_selected(lookup_name: String):
	if _preview:
		_preview.show_artifact(lookup_name)
	# Also spawn 3D preview immediately on selection
	spawn_requested.emit(lookup_name)


func _on_spawn_requested(lookup_name: String):
	spawn_requested.emit(lookup_name)


## Public API: Refresh the entire catalog
func refresh():
	if _filters:
		_filters.reset_filters()
	else:
		_refresh_catalog()


## Public API: Close/clear selection
func clear_selection():
	if _browser:
		_browser.clear_selection()
	if _preview:
		_preview.clear_preview()


## Public API: select next visible artifact in the current filter
func select_next_artifact() -> String:
	if not _browser:
		return ""
	return _browser.select_next_artifact()


func _get_selected_lookup_name() -> String:
	if _browser:
		return _browser.get_selected_artifact()
	return ""


func _on_insert_artifact_comment_token_pressed() -> void:
	if not _comment_edit:
		return

	var lookup_name := _get_selected_lookup_name()
	if lookup_name.is_empty():
		_set_comment_status("Select an artifact first.")
		return

	var artifact = ArtifactCatalogDataProvider.get_artifact_by_lookup_name(lookup_name)
	var scene_path := str(artifact.get("scene", "")).strip_edges()

	var token := "[artifact:%s]" % lookup_name
	if not scene_path.is_empty():
		token += " [scene:%s]" % scene_path

	if not _comment_edit.text.is_empty() and not _comment_edit.text.ends_with(" ") and not _comment_edit.text.ends_with("\n"):
		_comment_edit.text += " "
	_comment_edit.text += token
	_comment_edit.grab_focus()
	_set_comment_status("Inserted artifact token.")


func _on_save_comment_pressed() -> void:
	if not _comment_edit:
		return

	var comment_text := _comment_edit.text.strip_edges()
	if comment_text.is_empty():
		_set_comment_status("Write a comment first.")
		return

	var lookup_name := _get_selected_lookup_name()
	var artifact := ArtifactCatalogDataProvider.get_artifact_by_lookup_name(lookup_name)
	var scene_path := str(artifact.get("scene", "")).strip_edges()
	var sequence_name := str(artifact.get("sequence", "")).strip_edges()

	var lines: Array[String] = []
	lines.append("")
	lines.append("## %s | Artifact Catalog" % Time.get_datetime_string_from_system())
	if not lookup_name.is_empty():
		lines.append("- Artifact: `%s`" % lookup_name)
	if not scene_path.is_empty():
		lines.append("- Scene: `%s`" % scene_path)
	if not sequence_name.is_empty():
		lines.append("- Sequence: `%s`" % sequence_name)
	lines.append("- Source: `ArtifactCatalogDesktop3D`")
	lines.append("")
	lines.append(comment_text)
	lines.append("")
	lines.append("---")

	var block := "\n".join(lines)
	if _append_text_to_file(COMMENT_DEFAULT_MARKDOWN_PATH, block):
		_set_comment_status("Saved comment to %s" % COMMENT_DEFAULT_MARKDOWN_PATH)
		_comment_edit.text = ""
		return

	var fallback_path := "user://desktop_feedback/desktop_feedback.md"
	if _append_text_to_file(fallback_path, block):
		_set_comment_status("res:// not writable. Saved comment to %s" % fallback_path)
		_comment_edit.text = ""
		return

	_set_comment_status("Failed to save comment.")


func _append_text_to_file(path: String, content: String) -> bool:
	if not _ensure_parent_directory(path):
		return false

	var file: FileAccess = null
	if FileAccess.file_exists(path):
		file = FileAccess.open(path, FileAccess.READ_WRITE)
		if not file:
			return false
		file.seek_end()
	else:
		file = FileAccess.open(path, FileAccess.WRITE)
		if not file:
			return false

	file.store_string(content)
	file.close()
	return true


func _ensure_parent_directory(path: String) -> bool:
	var base_dir := path.get_base_dir()
	if base_dir.is_empty():
		return true

	var absolute_dir := ProjectSettings.globalize_path(base_dir)
	if DirAccess.dir_exists_absolute(absolute_dir):
		return true

	var make_result := DirAccess.make_dir_recursive_absolute(absolute_dir)
	return make_result == OK or DirAccess.dir_exists_absolute(absolute_dir)


func _set_comment_status(text: String) -> void:
	if _comment_status_label:
		_comment_status_label.text = text
