# MapInfoLabel.gd
# Shows "Loading..." during map load, then hides when done
# Attach to a Label3D under XRCamera3D

extends Label3D

@export var loading_text: String = "Loading..."

var is_loading: bool = true

func _ready():
	text = loading_text
	modulate = Color(1, 1, 1, 0.8)
	visible = true
	
	# Connect to GridSystem signals
	call_deferred("_connect_to_grid_system")

func _connect_to_grid_system():
	var grid_system = _find_grid_system(get_tree().root)
	
	if grid_system:
		if grid_system.has_signal("map_generation_complete"):
			if not grid_system.map_generation_complete.is_connected(_on_map_loaded):
				grid_system.map_generation_complete.connect(_on_map_loaded)
				print("MapInfoLabel: Connected to GridSystem")
	else:
		# Retry after a delay
		await get_tree().create_timer(1.0).timeout
		_connect_to_grid_system()

func _find_grid_system(node: Node) -> Node:
	if node.get_script():
		var script_path = node.get_script().resource_path
		if "GridSystem" in script_path or "LabGridSystem" in script_path:
			return node
	
	for child in node.get_children():
		var result = _find_grid_system(child)
		if result:
			return result
	
	return null

func _on_map_loaded():
	is_loading = false
	visible = false
	print("MapInfoLabel: Loading complete - hiding label")

