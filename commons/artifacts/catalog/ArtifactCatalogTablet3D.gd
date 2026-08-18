class_name ArtifactCatalogTablet3D
extends Node3D

## VR kiosk for artifact catalog
## Embeds 2D catalog UI in 3D space using Viewport2Din3D

signal artifact_spawn_requested(lookup_name: String)

@export var screen_width: float = 1.6
@export var screen_height: float = 1.2

@onready var _viewport_2d_in_3d: Node3D = $Viewport2Din3D

var _catalog_ui: ArtifactCatalogUI = null
var _spawn_manager: ArtifactSpawnManager = null


func _ready():
	# Connect to UI signals after scene is ready
	call_deferred("_connect_ui_signals")
	call_deferred("_find_spawn_manager")
	call_deferred("_ensure_viewport_updates")


func _connect_ui_signals():
	# Get the catalog UI instance from the Viewport2Din3D node
	if _viewport_2d_in_3d and _viewport_2d_in_3d.has_method("get_scene_instance"):
		_catalog_ui = _viewport_2d_in_3d.get_scene_instance()
		if _catalog_ui:
			_catalog_ui.spawn_requested.connect(_on_spawn_requested)
			print("ArtifactCatalogTablet3D: Connected to UI signals")
		else:
			push_warning("ArtifactCatalogTablet3D: Could not get catalog UI instance")
	else:
		# Alternative: try to find it as a child
		_catalog_ui = _find_catalog_ui_recursive(_viewport_2d_in_3d)
		if _catalog_ui:
			_catalog_ui.spawn_requested.connect(_on_spawn_requested)
			print("ArtifactCatalogTablet3D: Found and connected to UI")


func _find_catalog_ui_recursive(node: Node) -> ArtifactCatalogUI:
	if node is ArtifactCatalogUI:
		return node

	for child in node.get_children():
		var result = _find_catalog_ui_recursive(child)
		if result:
			return result

	return null


func _ensure_viewport_updates():
	# Force the SubViewport to use UPDATE_ALWAYS mode for continuous rendering
	if _viewport_2d_in_3d:
		var viewport = _viewport_2d_in_3d.get_node_or_null("Viewport")
		if viewport and viewport is SubViewport:
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			print("ArtifactCatalogTablet3D: Set viewport to UPDATE_ALWAYS")

		# Also try setting the update_mode property if it exists
		if _viewport_2d_in_3d.has_method("set_update_mode"):
			_viewport_2d_in_3d.set_update_mode(1)  # 1 = UPDATE_ALWAYS
		elif "update_mode" in _viewport_2d_in_3d:
			_viewport_2d_in_3d.update_mode = 1


func _find_spawn_manager():
	# Try to find spawn manager in the scene
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		return
	var scene_tree = get_tree()
	if not scene_tree:
		return

	# Look for GridSystem or LabGridSystem which should have the spawn manager
	var grid_systems = scene_tree.get_nodes_in_group("grid_system")
	if grid_systems.size() > 0:
		var grid_system = grid_systems[0]
		# Check if spawn manager exists as child
		for child in grid_system.get_children():
			if child is ArtifactSpawnManager:
				_spawn_manager = child
				return

		# If not found, try lab system
		var lab_systems = scene_tree.get_nodes_in_group("lab_system")
		if lab_systems.size() > 0:
			var lab_system = lab_systems[0]
			for child in lab_system.get_children():
				if child is ArtifactSpawnManager:
					_spawn_manager = child
					return


func _on_spawn_requested(lookup_name: String):
	print("ArtifactCatalogTablet3D: Spawn requested for '%s'" % lookup_name)

	# Try to spawn directly if we have spawn manager
	if _spawn_manager:
		_spawn_manager.spawn_artifact(lookup_name)
	else:
		# Emit signal for parent to handle
		artifact_spawn_requested.emit(lookup_name)


## Public API: Refresh the catalog
func refresh_catalog():
	if _catalog_ui and _catalog_ui.has_method("refresh"):
		_catalog_ui.refresh()