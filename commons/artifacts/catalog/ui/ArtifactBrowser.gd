class_name ArtifactBrowser
extends Control

## Tree widget for browsing artifacts by theme categories

signal artifact_selected(lookup_name: String)

@onready var _tree: Tree = $Tree

var _current_artifacts: Array = []


func _ready():
	_tree.hide_root = true
	_tree.item_selected.connect(_on_tree_item_selected)


## Populate tree with artifacts grouped by theme
func populate(theme_filter: String = "all", complexity_filter: String = "all", search: String = ""):
	_tree.clear()

	# Get filtered artifacts
	_current_artifacts = ArtifactCatalogDataProvider.get_filtered_artifacts(
		theme_filter,
		complexity_filter,
		search
	)

	if _current_artifacts.is_empty():
		_show_empty_message()
		return

	var root = _tree.create_item()

	# Get all themes
	var all_themes = ArtifactThemeQuery.get_all_themes()

	# Group artifacts by theme
	var artifacts_by_theme = {}
	var uncategorized = []
	for theme in all_themes:
		artifacts_by_theme[theme] = []

	for artifact in _current_artifacts:
		var artifact_themes = artifact.get("dev_themes", [])
		var matched_any_theme = false

		if not artifact_themes.is_empty():
			for artifact_theme in artifact_themes:
				if artifacts_by_theme.has(artifact_theme):
					artifacts_by_theme[artifact_theme].append(artifact)
					matched_any_theme = true

		# Add to uncategorized if no themes OR no matching themes found
		if artifact_themes.is_empty() or not matched_any_theme:
			uncategorized.append(artifact)

	print("ArtifactBrowser: Populated with %d artifacts, %d uncategorized, %d themes" % [
		_current_artifacts.size(), uncategorized.size(), all_themes.size()
	])

	# Add uncategorized artifacts FIRST (most artifacts are here)
	# Limit initial display to prevent performance issues
	const MAX_INITIAL_DISPLAY = 100

	if not uncategorized.is_empty():
		var uncategorized_item = _tree.create_item(root)
		var display_count = mini(uncategorized.size(), MAX_INITIAL_DISPLAY)
		var total_count = uncategorized.size()

		if total_count > MAX_INITIAL_DISPLAY:
			uncategorized_item.set_text(0, "All Artifacts (showing %d of %d - use search to filter)" % [display_count, total_count])
		else:
			uncategorized_item.set_text(0, "All Artifacts (%d)" % total_count)

		uncategorized_item.set_selectable(0, false)
		uncategorized_item.set_collapsed(false)  # Show expanded by default

		# Only add first N items to prevent UI freeze
		for i in range(display_count):
			_add_artifact_item(uncategorized_item, uncategorized[i])

	# Create theme categories
	for theme in all_themes:
		var theme_artifacts = artifacts_by_theme[theme]
		if theme_artifacts.is_empty():
			continue

		# Create theme category item
		var theme_item = _tree.create_item(root)
		theme_item.set_text(0, "%s (%d)" % [theme.capitalize(), theme_artifacts.size()])
		theme_item.set_selectable(0, false)
		theme_item.set_collapsed(true)

		# Add artifacts in this theme
		for artifact in theme_artifacts:
			_add_artifact_item(theme_item, artifact)

	# Force tree to repaint
	_tree.queue_redraw()
	queue_redraw()


func _add_artifact_item(parent_item: TreeItem, artifact: Dictionary):
	var item = _tree.create_item(parent_item)
	var artifact_name = artifact.get("name", artifact.get("lookup_name", "Unknown"))
	var lookup_name = artifact.get("lookup_name", "")

	item.set_text(0, artifact_name)
	item.set_metadata(0, lookup_name)

	# Lock indicator for progression mode
	if not ArtifactCatalogDataProvider.is_artifact_unlocked(lookup_name):
		item.set_custom_color(0, Color(0.5, 0.5, 0.5))
		item.set_suffix(0, " 🔒")
		item.set_tooltip_text(0, "Locked - complete sequences to unlock")
	else:
		item.set_tooltip_text(0, artifact.get("description", ""))


func _show_empty_message():
	var root = _tree.create_item()
	var empty_item = _tree.create_item(root)
	empty_item.set_text(0, "No artifacts found")
	empty_item.set_selectable(0, false)
	empty_item.set_custom_color(0, Color(0.7, 0.7, 0.7))


func _on_tree_item_selected():
	var selected = _tree.get_selected()
	if not selected:
		return

	var lookup_name = selected.get_metadata(0)
	if lookup_name and lookup_name != "":
		artifact_selected.emit(lookup_name)


func _update_stats():
	# Could emit signal to update header stats if needed
	pass


## Clear selection
func clear_selection():
	if _tree.get_selected():
		_tree.get_selected().deselect(0)


## Get currently selected artifact lookup_name
func get_selected_artifact() -> String:
	var selected = _tree.get_selected()
	if selected:
		return selected.get_metadata(0)
	return ""