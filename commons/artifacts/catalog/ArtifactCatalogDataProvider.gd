class_name ArtifactCatalogDataProvider
extends RefCounted

## Data provider for artifact catalog system
##
## Queries GridInteractablesComponent registry and provides filtered artifact lists
## Uses ArtifactThemeQuery for theme-based filtering
## Checks LabGridSystem for unlock status (progression mode)

## Get GridSystem from scene tree
static func _find_grid_system() -> Node:
	var scene_tree = Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return null

	# Try to find GridSystem or LabGridSystem
	var grid_systems = scene_tree.get_nodes_in_group("grid_system")
	if grid_systems.size() > 0:
		return grid_systems[0]

	# Fallback: search by class name
	var root = scene_tree.current_scene
	if root:
		for child in root.get_children():
			if child.has_method("get_class") and "GridSystem" in str(child.get_class()):
				return child

	return null

## Get LabGridSystem from scene tree
static func _find_lab_system() -> Node:
	var scene_tree = Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return null

	var lab_systems = scene_tree.get_nodes_in_group("lab_system")
	if lab_systems.size() > 0:
		return lab_systems[0]

	return null

# Cached standalone registry (loaded when GridSystem not available)
static var _standalone_registry: Dictionary = {}
static var _standalone_loaded: bool = false

## Load artifacts directly from JSON files (fallback for standalone/desktop mode)
static func _load_standalone_registry() -> void:
	if _standalone_loaded:
		return
	
	print("ArtifactCatalogDataProvider: Loading artifacts directly (standalone mode)...")
	_standalone_registry.clear()
	
	# Load base registry
	var base_path = "res://commons/artifacts/grid_artifacts.json"
	_load_registry_file(base_path)
	
	# Load modular registries
	var registry_dir = "res://commons/artifacts/registry/"
	var dir = DirAccess.open(registry_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				_load_registry_file(registry_dir + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	_standalone_loaded = true
	print("ArtifactCatalogDataProvider: ✅ Standalone registry loaded with %d artifacts" % _standalone_registry.size())

## Load a single registry JSON file into _standalone_registry
static func _load_registry_file(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("ArtifactCatalogDataProvider: ⚠️ Could not open: %s" % path)
		return
	
	var json = JSON.new()
	var json_text = file.get_as_text()
	file.close()
	
	if json.parse(json_text) != OK:
		print("ArtifactCatalogDataProvider: ⚠️ JSON parse error in: %s" % path)
		return
	
	var data = json.data
	if data is Dictionary:
		# Handle both flat format and "artifacts" wrapper
		var artifacts = data.get("artifacts", data)
		var count_before = _standalone_registry.size()
		if artifacts is Dictionary:
			for key in artifacts.keys():
				var artifact = artifacts[key]
				if artifact is Dictionary:
					# Ensure lookup_name is set
					if not artifact.has("lookup_name"):
						artifact["lookup_name"] = key
					_standalone_registry[key] = artifact
		var count_added = _standalone_registry.size() - count_before
		print("ArtifactCatalogDataProvider: Loaded %d artifacts from %s" % [count_added, path.get_file()])

## Get all artifacts from GridInteractablesComponent registry
## Falls back to direct JSON loading if GridSystem not available (desktop/standalone mode)
## Returns array of artifact dictionaries
static func get_all_artifacts() -> Array:
	print("ArtifactCatalogDataProvider: get_all_artifacts() called")

	var grid_system = _find_grid_system()
	if not grid_system:
		# Fallback: load directly from JSON files (desktop/standalone mode)
		print("ArtifactCatalogDataProvider: GridSystem not found, using standalone mode")
		_load_standalone_registry()
		return _standalone_registry.values()

	print("ArtifactCatalogDataProvider: Found GridSystem: %s" % grid_system.name)

	if not grid_system.has_node("GridInteractablesComponent"):
		# Fallback: load directly
		print("ArtifactCatalogDataProvider: GridInteractablesComponent not found, using standalone mode")
		_load_standalone_registry()
		return _standalone_registry.values()

	var interactables = grid_system.get_node("GridInteractablesComponent")
	print("ArtifactCatalogDataProvider: Found GridInteractablesComponent")

	if not "grid_artifact_registry" in interactables:
		push_warning("ArtifactCatalogDataProvider: grid_artifact_registry property not found in GridInteractablesComponent")
		_load_standalone_registry()
		return _standalone_registry.values()

	var registry = interactables.grid_artifact_registry
	var artifact_count = registry.size()

	if artifact_count == 0:
		# GridSystem exists but registry is empty - try standalone fallback
		print("ArtifactCatalogDataProvider: Registry empty, falling back to standalone mode")
		_load_standalone_registry()
		return _standalone_registry.values()
	
	print("ArtifactCatalogDataProvider: ✅ Found %d artifacts in registry" % artifact_count)
	return registry.values()

## Look up artifacts by lookup_names
static func _lookup_artifacts(lookup_names: Array) -> Array:
	var registry: Dictionary = {}
	
	# Try GridSystem first
	var grid_system = _find_grid_system()
	if grid_system and grid_system.has_node("GridInteractablesComponent"):
		var interactables = grid_system.get_node("GridInteractablesComponent")
		if "grid_artifact_registry" in interactables:
			registry = interactables.grid_artifact_registry
	
	# Fallback to standalone if empty
	if registry.is_empty():
		_load_standalone_registry()
		registry = _standalone_registry

	var artifacts = []
	for lookup_name in lookup_names:
		if registry.has(lookup_name):
			artifacts.append(registry[lookup_name])

	return artifacts

## Get artifacts filtered by theme using ArtifactThemeQuery
static func get_artifacts_by_theme(theme: String) -> Array:
	var lookup_names = ArtifactThemeQuery.get_by_theme(theme)
	return _lookup_artifacts(lookup_names)

## Get artifacts filtered by complexity using ArtifactThemeQuery
static func get_artifacts_by_complexity(complexity: String) -> Array:
	var lookup_names = ArtifactThemeQuery.get_by_complexity(complexity)
	return _lookup_artifacts(lookup_names)

## Get artifacts filtered by category using ArtifactThemeQuery
static func get_artifacts_by_category(category: String) -> Array:
	var lookup_names = ArtifactThemeQuery.get_by_category(category)
	return _lookup_artifacts(lookup_names)

## Get filtered artifacts with multiple criteria
## @param theme: Theme filter ("all" or specific theme)
## @param complexity: Complexity filter ("all" or specific level)
## @param search: Search string to filter by name/description
static func get_filtered_artifacts(theme: String = "all", complexity: String = "all", search: String = "") -> Array:
	var artifacts = get_all_artifacts()

	# Apply theme filter
	if theme != "all" and theme != "":
		var theme_artifacts = get_artifacts_by_theme(theme)
		# Intersect with current artifacts
		var theme_lookup_names = {}
		for artifact in theme_artifacts:
			theme_lookup_names[artifact.get("lookup_name", "")] = true

		var filtered = []
		for artifact in artifacts:
			if theme_lookup_names.has(artifact.get("lookup_name", "")):
				filtered.append(artifact)
		artifacts = filtered

	# Apply complexity filter
	if complexity != "all" and complexity != "":
		var complexity_artifacts = get_artifacts_by_complexity(complexity)
		var complexity_lookup_names = {}
		for artifact in complexity_artifacts:
			complexity_lookup_names[artifact.get("lookup_name", "")] = true

		var filtered = []
		for artifact in artifacts:
			if complexity_lookup_names.has(artifact.get("lookup_name", "")):
				filtered.append(artifact)
		artifacts = filtered

	# Apply search filter
	if search != "":
		var search_lower = search.to_lower()
		var filtered = []
		for artifact in artifacts:
			var name = artifact.get("name", "").to_lower()
			var description = artifact.get("description", "").to_lower()
			var lookup_name = artifact.get("lookup_name", "").to_lower()

			# Also search tags
			var tags_match = false
			if artifact.has("tags"):
				for tag in artifact["tags"]:
					if str(tag).to_lower().contains(search_lower):
						tags_match = true
						break

			if name.contains(search_lower) or description.contains(search_lower) or lookup_name.contains(search_lower) or tags_match:
				filtered.append(artifact)
		artifacts = filtered

	return artifacts

## Check if artifact is unlocked (progression mode)
## Dev mode: all unlocked
## Player mode: check LabGridSystem.unlocked_artifacts
static func is_artifact_unlocked(lookup_name: String) -> bool:
	# Dev mode: all unlocked
	if OS.is_debug_build():
		return true

	# Find Lab system
	var lab_system = _find_lab_system()
	if not lab_system:
		return true  # No lab system = all unlocked

	# Use LabGridSystem's is_artifact_unlocked method if available
	if lab_system.has_method("is_artifact_unlocked"):
		return lab_system.is_artifact_unlocked(lookup_name)

	# Fallback: all unlocked
	return true

## Get total artifact count
static func get_total_artifact_count() -> int:
	return get_all_artifacts().size()

## Get unlocked artifact count
static func get_unlocked_artifact_count() -> int:
	var artifacts = get_all_artifacts()
	var count = 0
	for artifact in artifacts:
		if is_artifact_unlocked(artifact.get("lookup_name", "")):
			count += 1
	return count

## Get artifact by lookup_name
static func get_artifact_by_lookup_name(lookup_name: String) -> Dictionary:
	var grid_system = _find_grid_system()
	if grid_system and grid_system.has_node("GridInteractablesComponent"):
		var interactables = grid_system.get_node("GridInteractablesComponent")
		if "grid_artifact_registry" in interactables:
			var registry = interactables.grid_artifact_registry
			if registry.has(lookup_name):
				return registry[lookup_name]
	
	# Fallback to standalone registry
	_load_standalone_registry()
	if _standalone_registry.has(lookup_name):
		return _standalone_registry[lookup_name]

	return {}