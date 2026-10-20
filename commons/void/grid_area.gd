# The existing Grid hangs in Trace's shaft A; its controls stand on the rim.
extends Node3D

const GridScene = preload("res://commons/primitives/line/grid_lines.tscn")

func _ready() -> void:
	var grid := GridScene.instantiate() as Node3D
	grid.name = "SavedTraceGrid"
	grid.position = Vector3(-3.3, -1.0, -1.8)
	grid.rotation_speed = 0.0
	grid.set_meta("config_panel", "1")
	grid.set_meta("config_selection", "1")
	add_child(grid)
	# The replay monitor stands on the west rim, opposite its former east
	# position. Keep the complete support on the slab and face the south aisle.
	for part in ["ArchivePanel", "ArchiveFoot", "ArchiveStem", "ArchiveBracket"]:
		var node := grid.get_node(part) as Node3D
		node.position.x = -3.1
		node.position.z -= 1.35
	label("YOUR DRAWING / ANOTHER ADDRESS", Vector3(-6.2, 2.1, 0), false)
	label("DISPLAY ONLY / THE LINES ARE NOT A FLOOR", Vector3(-0.2, 0.025, -1.8), true)

func label(text: String, at: Vector3, floor_text: bool) -> void:
	var node := Label3D.new()
	node.text = text
	node.position = at
	node.font_size = 48
	node.pixel_size = 0.0014 if floor_text else 0.0015
	node.outline_size = 0
	node.modulate = Color("202329")
	if floor_text: node.rotation.x = -PI / 2.0
	add_child(node)
