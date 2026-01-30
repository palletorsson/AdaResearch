# DiscoFloorInteractable.gd
# Wrapper for StandaloneDiscoFloor that works with GridInteractablesComponent
# Spawnable via map JSON: "standalone_disco#width:8#depth:8"

extends Node3D

## Configuration (set via map parameters)
@export var width: int = 8
@export var depth: int = 8
@export var tile_size: float = 0.5
@export var show_controls: bool = true
@export var control_offset: Vector3 = Vector3(0, 1.2, -2.5)

var disco_floor: StandaloneDiscoFloor
var control_panel: Node3D

func _ready() -> void:
	_setup_disco()

func _setup_disco() -> void:
	# Create disco floor
	var floor_script = load("res://commons/context/discofloor/StandaloneDiscoFloor.gd")
	disco_floor = Node3D.new()
	disco_floor.set_script(floor_script)
	disco_floor.name = "DiscoFloor"
	disco_floor.grid_width = width
	disco_floor.grid_depth = depth
	disco_floor.tile_size = tile_size
	disco_floor.auto_start = true
	add_child(disco_floor)
	
	# Create control panel if enabled
	if show_controls:
		var panel_script = load("res://commons/context/discofloor/DiscoControlPanel.gd")
		control_panel = Node3D.new()
		control_panel.set_script(panel_script)
		control_panel.name = "ControlPanel"
		control_panel.position = control_offset
		control_panel.disco_floor_path = NodePath("../DiscoFloor")
		add_child(control_panel)
	
	print("DiscoFloorInteractable: Created %dx%d disco floor" % [width, depth])

## Called by GridInteractablesComponent to apply map parameters
func apply_grid_config(data: Dictionary) -> void:
	if data.has("width"):
		width = int(data.width)
	if data.has("depth"):
		depth = int(data.depth)
	if data.has("tile_size"):
		tile_size = float(data.tile_size)
	if data.has("show_controls"):
		show_controls = str(data.show_controls).to_lower() == "true"
	
	# Rebuild if already setup
	if disco_floor:
		disco_floor.set_grid_size(width, depth)
