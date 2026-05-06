class_name ArtifactThemeQuery
extends RefCounted

## Utility for querying artifacts by theme, category, and complexity.
##
## This tool enables developers to find artifacts by purpose rather than by registry file.
## All methods are static and load data from artifact_theme_index.json on demand.
##
## Example usage:
##   var audio_artifacts = ArtifactThemeQuery.get_by_theme("audio")
##   var beginner_primitives = ArtifactThemeQuery.get_by_themes_and_complexity(["primitives"], "beginner")
##   var qfep_vis = ArtifactThemeQuery.get_by_category("qfep_visualization")

const THEME_INDEX_PATH = "res://commons/artifacts/artifact_theme_index.json"

static var _cached_index: Dictionary = {}
static var _cache_loaded: bool = false


## Load and cache the theme index from JSON file
static func _load_index() -> Dictionary:
	if _cache_loaded:
		return _cached_index

	if not FileAccess.file_exists(THEME_INDEX_PATH):
		push_error("ArtifactThemeQuery: Theme index not found at %s" % THEME_INDEX_PATH)
		return {}

	var file = FileAccess.open(THEME_INDEX_PATH, FileAccess.READ)
	if file == null:
		push_error("ArtifactThemeQuery: Failed to open theme index: %s" % FileAccess.get_open_error())
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("ArtifactThemeQuery: Failed to parse theme index JSON: %s" % json.get_error_message())
		return {}

	_cached_index = json.data
	_cache_loaded = true
	return _cached_index


## Clear the cached index (useful if index file is updated at runtime)
static func clear_cache() -> void:
	_cached_index = {}
	_cache_loaded = false


## Get all artifacts belonging to a specific theme
## @param theme: Theme name (e.g., "audio", "qfep", "procedural", "physics")
## @return: Array of artifact lookup_names
static func get_by_theme(theme: String) -> Array:
	var index = _load_index()
	if not index.has("by_theme"):
		return []

	if not index["by_theme"].has(theme):
		push_warning("ArtifactThemeQuery: Theme '%s' not found in index" % theme)
		return []

	return index["by_theme"][theme]


## Get all available theme names
## @return: Array of theme strings
static func get_all_themes() -> Array:
	var index = _load_index()
	if not index.has("by_theme"):
		return []
	return index["by_theme"].keys()


## Get artifacts matching multiple themes (intersection)
## @param themes: Array of theme names
## @return: Array of artifact lookup_names that belong to ALL specified themes
static func get_by_themes_intersection(themes: Array) -> Array:
	if themes.is_empty():
		return []

	var result_set = {}
	var first_theme_artifacts = get_by_theme(themes[0])

	# Initialize with first theme's artifacts
	for artifact in first_theme_artifacts:
		result_set[artifact] = true

	# Intersect with remaining themes
	for i in range(1, themes.size()):
		var theme_artifacts = get_by_theme(themes[i])
		var theme_set = {}
		for artifact in theme_artifacts:
			theme_set[artifact] = true

		# Keep only artifacts in both sets
		var to_remove = []
		for artifact in result_set.keys():
			if not theme_set.has(artifact):
				to_remove.append(artifact)

		for artifact in to_remove:
			result_set.erase(artifact)

	return result_set.keys()


## Get artifacts matching any of the specified themes (union)
## @param themes: Array of theme names
## @return: Array of artifact lookup_names that belong to ANY specified theme
static func get_by_themes_union(themes: Array) -> Array:
	var result_set = {}

	for theme in themes:
		var artifacts = get_by_theme(theme)
		for artifact in artifacts:
			result_set[artifact] = true

	return result_set.keys()


## Get artifacts by complexity level
## @param complexity: "beginner", "intermediate", "advanced", or "expert"
## @return: Array of artifact lookup_names
static func get_by_complexity(complexity: String) -> Array:
	var index = _load_index()
	if not index.has("by_complexity"):
		return []

	if not index["by_complexity"].has(complexity):
		push_warning("ArtifactThemeQuery: Complexity '%s' not found in index" % complexity)
		return []

	return index["by_complexity"][complexity]


## Get all available complexity levels
## @return: Array of complexity strings
static func get_all_complexity_levels() -> Array:
	var index = _load_index()
	if not index.has("by_complexity"):
		return []
	return index["by_complexity"].keys()


## Get artifacts by category
## @param category: Category name (e.g., "qfep_controller", "procedural_audio")
## @return: Array of artifact lookup_names
static func get_by_category(category: String) -> Array:
	var index = _load_index()
	if not index.has("by_category"):
		return []

	if not index["by_category"].has(category):
		push_warning("ArtifactThemeQuery: Category '%s' not found in index" % category)
		return []

	return index["by_category"][category]


## Get all available categories
## @return: Array of category strings
static func get_all_categories() -> Array:
	var index = _load_index()
	if not index.has("by_category"):
		return []
	return index["by_category"].keys()


## Get artifacts matching themes AND complexity
## @param themes: Array of theme names (union - artifacts in ANY theme)
## @param complexity: Complexity level
## @return: Array of artifact lookup_names
static func get_by_themes_and_complexity(themes: Array, complexity: String) -> Array:
	var theme_artifacts_set = {}
	for artifact in get_by_themes_union(themes):
		theme_artifacts_set[artifact] = true

	var complexity_artifacts = get_by_complexity(complexity)

	var result = []
	for artifact in complexity_artifacts:
		if theme_artifacts_set.has(artifact):
			result.append(artifact)

	return result


## Get artifacts from a specific registry file
## @param registry: Registry filename (e.g., "qfep.json", "arrays.json")
## @return: Array of artifact lookup_names
static func get_by_registry(registry: String) -> Array:
	var index = _load_index()
	if not index.has("by_registry"):
		return []

	if not index["by_registry"].has(registry):
		push_warning("ArtifactThemeQuery: Registry '%s' not found in index" % registry)
		return []

	return index["by_registry"][registry]


## Get summary statistics about the themed artifact system
## @return: Dictionary with counts and metadata
static func get_stats() -> Dictionary:
	var index = _load_index()

	var stats = {
		"total_tagged_artifacts": index.get("total_tagged_artifacts", 0),
		"metadata_version": index.get("metadata_version", "unknown"),
		"last_updated": index.get("last_updated", "unknown"),
		"theme_count": get_all_themes().size(),
		"complexity_levels": get_all_complexity_levels().size(),
		"category_count": get_all_categories().size()
	}

	return stats


## Print a formatted summary of the theme system to console
static func print_summary() -> void:
	var stats = get_stats()

	print("=== Artifact Theme System Summary ===")
	print("Total tagged artifacts: %d" % stats["total_tagged_artifacts"])
	print("Metadata version: %s" % stats["metadata_version"])
	print("Last updated: %s" % stats["last_updated"])
	print("")
	print("Themes (%d):" % stats["theme_count"])
	for theme in get_all_themes():
		var count = get_by_theme(theme).size()
		print("  - %s: %d artifacts" % [theme, count])
	print("")
	print("Complexity Levels (%d):" % stats["complexity_levels"])
	for level in get_all_complexity_levels():
		var count = get_by_complexity(level).size()
		print("  - %s: %d artifacts" % [level, count])
	print("=====================================")