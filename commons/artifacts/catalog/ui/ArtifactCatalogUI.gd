class_name ArtifactCatalogUI
extends Control

## Main artifact catalog UI controller
## Coordinates filters, browser, and preview components

signal spawn_requested(lookup_name: String)

@onready var _header_label: Label = $VBoxContainer/Header/HBoxContainer/TitleLabel
@onready var _stats_label: Label = $VBoxContainer/Header/HBoxContainer/StatsLabel
@onready var _filters: ArtifactFilters = $VBoxContainer/Filters
@onready var _browser: ArtifactBrowser = $VBoxContainer/HSplitContainer/LeftPanel/Browser
@onready var _preview: ArtifactPreview = $VBoxContainer/HSplitContainer/RightPanel/Preview


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


func _connect_to_grid_system():
	# Find GridSystem and connect to map_generation_complete signal
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
		await get_tree().create_timer(0.1).timeout

	# If we get here, something is wrong but show empty catalog gracefully
	push_warning("ArtifactCatalogUI: Timeout waiting for GridSystem after 5 seconds")
	_refresh_catalog()
	_update_stats()


func _on_map_generation_complete():
	print("ArtifactCatalogUI: Map generation complete, refreshing catalog...")
	refresh()


func _refresh_catalog(theme: String = "all", complexity: String = "all", search: String = ""):
	if _browser:
		_browser.populate(theme, complexity, search)

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


func _on_filters_changed(theme: String, complexity: String, search_text: String):
	_refresh_catalog(theme, complexity, search_text)


func _on_artifact_selected(lookup_name: String):
	if _preview:
		_preview.show_artifact(lookup_name)


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