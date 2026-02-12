class_name ArtifactBrowser
extends Control

## Tree widget for browsing artifacts grouped by scene folder

signal artifact_selected(lookup_name: String)

@onready var _tree: Tree = $Tree

var _current_artifacts: Array = []


func _ready():
	_tree.hide_root = true
	_tree.item_selected.connect(_on_tree_item_selected)


## Populate tree with artifacts grouped by scene folder
func populate(theme_filter: String = "all", complexity_filter: String = "all", search: String = "", sequence_filter: String = "all"):
	_tree.clear()

	# Get filtered artifacts
	_current_artifacts = ArtifactCatalogDataProvider.get_filtered_artifacts(
		theme_filter,
		complexity_filter,
		search,
		sequence_filter
	)

	if _current_artifacts.is_empty():
		_show_empty_message()
		return

	var root = _tree.create_item()

	var artifacts_by_folder := {}
	for artifact in _current_artifacts:
		var folder_key := _extract_folder_group(str(artifact.get("scene", "")))
		if not artifacts_by_folder.has(folder_key):
			artifacts_by_folder[folder_key] = []
		(artifacts_by_folder[folder_key] as Array).append(artifact)

	var folder_keys: Array[String] = []
	for folder_name in artifacts_by_folder.keys():
		folder_keys.append(str(folder_name))
	folder_keys.sort()

	print("ArtifactBrowser: Populated with %d artifacts across %d folders" % [
		_current_artifacts.size(),
		folder_keys.size()
	])

	for folder_name in folder_keys:
		var folder_artifacts: Array = artifacts_by_folder.get(folder_name, [])
		if folder_artifacts.is_empty():
			continue

		folder_artifacts.sort_custom(func(a, b):
			var a_name := str((a as Dictionary).get("name", (a as Dictionary).get("lookup_name", ""))).to_lower()
			var b_name := str((b as Dictionary).get("name", (b as Dictionary).get("lookup_name", ""))).to_lower()
			return a_name < b_name
		)

		var folder_item := _tree.create_item(root)
		folder_item.set_text(0, "%s (%d)" % [folder_name, folder_artifacts.size()])
		folder_item.set_selectable(0, false)
		folder_item.set_collapsed(false)

		for artifact in folder_artifacts:
			_add_artifact_item(folder_item, artifact)

	# Force tree to repaint
	_tree.queue_redraw()
	queue_redraw()


func _extract_folder_group(scene_path: String) -> String:
	var trimmed := scene_path.strip_edges()
	if trimmed.is_empty():
		return "unmapped"

	if trimmed.begins_with("res://"):
		trimmed = trimmed.trim_prefix("res://")

	var slash_index := trimmed.rfind("/")
	if slash_index < 0:
		return "unmapped"

	var folder_path := trimmed.substr(0, slash_index)
	var parts := folder_path.split("/")
	if parts.size() >= 2 and (parts[0] == "commons" or parts[0] == "algorithms"):
		return "%s/%s" % [parts[0], parts[1]]
	if parts.size() >= 1:
		return parts[0]
	return "unmapped"


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


func select_next_artifact() -> String:
	var root := _tree.get_root()
	if not root:
		return ""

	var items: Array[TreeItem] = []
	_collect_selectable_artifact_items(root, items)
	if items.is_empty():
		return ""

	var selected := _tree.get_selected()
	var current_index := -1
	if selected:
		current_index = items.find(selected)

	var next_index := 0
	if current_index >= 0:
		next_index = (current_index + 1) % items.size()

	var next_item := items[next_index]
	next_item.select(0)

	var lookup_name := str(next_item.get_metadata(0))
	if not lookup_name.is_empty():
		artifact_selected.emit(lookup_name)
	return lookup_name


func _collect_selectable_artifact_items(item: TreeItem, out_items: Array[TreeItem]) -> void:
	if item.get_parent() and item.is_selectable(0):
		var lookup_name := str(item.get_metadata(0))
		if not lookup_name.is_empty():
			out_items.append(item)

	var child := item.get_first_child()
	while child:
		_collect_selectable_artifact_items(child, out_items)
		child = child.get_next()


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
