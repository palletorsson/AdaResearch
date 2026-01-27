extends Node
class_name LogManager

## Global log level manager
## Levels: 1=Essential, 2=Info, 3=Verbose
## Usage: Log.info("GridSystem", "Map loaded")
##        Log.verbose("SubtitleTrigger", "Player entered area")

enum Level {
	ESSENTIAL = 1,  # Critical messages only
	INFO = 2,       # Normal informational messages
	VERBOSE = 3     # All debug messages
}

# Current log level (default: Info)
var current_level: Level = Level.INFO

# Category filters (optional - empty means show all)
var enabled_categories: Array[String] = []
var disabled_categories: Array[String] = []

# Color codes for terminal output
const COLORS = {
	Level.ESSENTIAL: "red",
	Level.INFO: "white",
	Level.VERBOSE: "gray"
}

func _ready():
	# Load from settings if available
	_load_settings()

func _load_settings():
	var settings = get_node_or_null("/root/GameManager")
	if settings and settings.has_method("get_setting"):
		var level = settings.get_setting("log_level", Level.INFO)
		current_level = level

## Set log level (1=Essential, 2=Info, 3=Verbose)
func set_level(level: int):
	current_level = clampi(level, Level.ESSENTIAL, Level.VERBOSE)
	print("[Log] Level set to %s" % _level_name(current_level))

func get_level() -> int:
	return current_level

func _level_name(level: Level) -> String:
	match level:
		Level.ESSENTIAL: return "Essential"
		Level.INFO: return "Info"
		Level.VERBOSE: return "Verbose"
	return "Unknown"

## Essential log - always shown unless level is 0
func essential(category: String, message: String):
	_log(Level.ESSENTIAL, category, message)

## Info log - shown at level 2+
func info(category: String, message: String):
	_log(Level.INFO, category, message)

## Verbose log - shown at level 3
func verbose(category: String, message: String):
	_log(Level.VERBOSE, category, message)

## Core logging function
func _log(level: Level, category: String, message: String):
	# Check level
	if level > current_level:
		return

	# Check category filters
	if not _category_allowed(category):
		return

	# Format and print
	var prefix = "[%s]" % category
	print("%s %s" % [prefix, message])

func _category_allowed(category: String) -> bool:
	# If disabled list has this category, block it
	if category in disabled_categories:
		return false

	# If enabled list is empty, allow all
	if enabled_categories.is_empty():
		return true

	# Otherwise, only allow if in enabled list
	return category in enabled_categories

## Enable specific category
func enable_category(category: String):
	if category not in enabled_categories:
		enabled_categories.append(category)
	disabled_categories.erase(category)

## Disable specific category
func disable_category(category: String):
	if category not in disabled_categories:
		disabled_categories.append(category)
	enabled_categories.erase(category)

## Clear all filters
func clear_filters():
	enabled_categories.clear()
	disabled_categories.clear()


# ============================================
# Static convenience functions (use Log singleton)
# ============================================

## Quick access - get the Log singleton
static func get_instance() -> LogManager:
	var root = Engine.get_main_loop()
	if root and root is SceneTree:
		return root.root.get_node_or_null("/root/Log")
	return null
