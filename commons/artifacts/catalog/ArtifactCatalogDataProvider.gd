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

## Get all artifacts from GridInteractablesComponent registry
## Returns array of artifact dictionaries
static func get_all_artifacts() -> Array:
	var grid_system = _find_grid_system()
	if not grid_system:
		push_warning("ArtifactCatalogDataProvider: GridSystem not found")
		return []

	if not grid_system.has_node("GridInteractablesComponent"):
		push_warning("ArtifactCatalogDataProvider: GridInteractablesComponent not found")
		return []

	var interactables = grid_system.get_node("GridInteractablesComponent")
	if not "grid_artifact_registry" in interactables:
		push_warning("ArtifactCatalogDataProvider: grid_artifact_registry not found")
		return []

	var registry = interactables.grid_artifact_registry
	var artifact_count = registry.size()

	if artifact_count == 0:
		push_warning("ArtifactCatalogDataProvider: grid_artifact_registry is empty - map may not be fully loaded yet")
		print("ArtifactCatalogDataProvider: Waiting for artifacts to load...")
	else:
		print("ArtifactCatalogDataProvider: Found %d artifacts in registry" % artifact_count)

	return registry.values()

## Look up artifacts by lookup_names
static func _lookup_artifacts(lookup_names: Array) -> Array:
	var grid_system = _find_grid_system()
	if not grid_system or not grid_system.has_node("GridInteractablesComponent"):
		return []

	var interactables = grid_system.get_node("GridInteractablesComponent")
	var registry = interactables.grid_artifact_registry

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
	if not grid_system or not grid_system.has_node("GridInteractablesComponent"):
		return {}

	var interactables = grid_system.get_node("GridInteractablesComponent")
	var registry = interactables.grid_artifact_registry

	if registry.has(lookup_name):
		return registry[lookup_name]

	return {}
