extends Node3D
## Preserve the original museum MultiMesh and collider, flush with the Void slab.
var floor_node: Node3D

func _ready() -> void:
	var source: Node3D = load("res://commons/context/discofloor/standalone_disco_floor.tscn").instantiate()
	floor_node = source.get_node("DiscoFloor")
	floor_node.grid_width = 12
	floor_node.grid_depth = 12
	floor_node.tile_size = 0.8
	floor_node.floor_y_offset = 0.005
	add_child(source)
	# A palette comparison must not become nearly white under the tower's
	# ambient light plus the original constant white emission. Keep the tile
	# values, original mesh and instance colours; give this receiver a flat finish.
	var finish: StandardMaterial3D = floor_node.multimesh_instance.material_override
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	finish.emission_enabled = false
	floor_node.get_node("FloorCollision").set_meta("void_floor_surface", true)
	set_meta("em_visibility_bounds", AABB(Vector3(-4.8,0,-4.8),Vector3(9.6,.025,9.6)))

func prepare_editor_preview() -> void:
	# Export a declared checker phase, rather than whichever animation frame won.
	var host := preload("res://commons/artifacts/regularity/room_tools.gd").room_root(self)
	for node in host.find_children("*", "Node3D", true, false):
		if node.get_script() == load("res://commons/artifacts/regularity/disco_controls.gd"):
			node.running = false
			node.phase = 0
			node.paint()
