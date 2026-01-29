class_name DesktopArtifactCatalog
extends CanvasLayer

## Desktop artifact catalog overlay
## Toggle with Tab key, fullscreen UI over game view

signal artifact_spawn_requested(lookup_name: String)
signal catalog_opened
signal catalog_closed

@onready var _catalog_ui: ArtifactCatalogUI = $ArtifactCatalogUI

var _is_open: bool = false
var _spawn_manager: ArtifactSpawnManager = null
var _grid_system_ref: Node = null


func _ready():
	# Set high layer so it renders on top
	layer = 100

	# Start hidden
	visible = false

	# Connect UI signals
	if _catalog_ui:
		_catalog_ui.spawn_requested.connect(_on_spawn_requested)


## Set references from LabGridSystem
func set_references(grid_system: Node, spawn_manager: ArtifactSpawnManager):
	_grid_system_ref = grid_system
	_spawn_manager = spawn_manager
	print("DesktopArtifactCatalog: References set, forcing catalog refresh")
	if _catalog_ui and _catalog_ui.has_method("refresh"):
		_catalog_ui.refresh()


func _input(event: InputEvent):
	# Toggle catalog with Tab key
	if event.is_action_pressed("toggle_artifact_catalog"):
		toggle()
		get_viewport().set_input_as_handled()


func _find_spawn_manager():
	var scene_tree = get_tree()
	if not scene_tree:
		return

	# Look for GridSystem or LabGridSystem which should have the spawn manager
	var grid_systems = scene_tree.get_nodes_in_group("grid_system")
	if grid_systems.size() > 0:
		var grid_system = grid_systems[0]
		for child in grid_system.get_children():
			if child is ArtifactSpawnManager:
				_spawn_manager = child
				return

		# Try lab system
		var lab_systems = scene_tree.get_nodes_in_group("lab_system")
		if lab_systems.size() > 0:
			var lab_system = lab_systems[0]
			for child in lab_system.get_children():
				if child is ArtifactSpawnManager:
					_spawn_manager = child
					return


## Toggle catalog visibility
func toggle():
	if _is_open:
		close()
	else:
		open()


## Open the catalog
func open():
	_is_open = true
	visible = true

	# Pause game when catalog is open
	get_tree().paused = true

	# Grab focus for keyboard navigation
	if _catalog_ui:
		_catalog_ui.grab_focus()

	catalog_opened.emit()
	print("DesktopArtifactCatalog: Opened")


## Close the catalog
func close():
	_is_open = false
	visible = false

	# Unpause game
	get_tree().paused = false

	catalog_closed.emit()
	print("DesktopArtifactCatalog: Closed")


func _on_spawn_requested(lookup_name: String):
	print("DesktopArtifactCatalog: Spawn requested for '%s'" % lookup_name)

	# Try to spawn directly if we have spawn manager
	if _spawn_manager:
		var success = _spawn_manager.spawn_artifact(lookup_name)
		if success:
			# Close catalog after successful spawn
			close()
	else:
		# Emit signal for parent to handle
		artifact_spawn_requested.emit(lookup_name)
		close()


## Public API: Refresh the catalog
func refresh():
	if _catalog_ui and _catalog_ui.has_method("refresh"):
		_catalog_ui.refresh()


## Check if catalog is currently open
func is_open() -> bool:
	return _is_open
