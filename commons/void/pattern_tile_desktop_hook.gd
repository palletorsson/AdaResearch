extends Node
## Both Void hands use XRTools' grab driver. The source cube's picked_up
## handler unfreezes it, making gravity fight that driver. Keep carried cubes
## frozen and let the original dropped handler own snapping and colour updates.
static func attach(puzzle: PatternTilePuzzle) -> void:
	for spawner in puzzle._cube_spawners:
		spawner.get_node("SpawnArea").set_collision_mask_value(3, true)
	for child in puzzle.get_children(): connect_cube(child)
	puzzle.child_entered_tree.connect(func(child: Node): connect_cube.call_deferred(child))

static func connect_cube(child: Node) -> void:
	if not is_instance_valid(child) or not child is PatternTileCube: return
	if child.has_node("VoidTileCarry"): return
	var hook: Node = load("res://commons/void/pattern_tile_desktop_hook.gd").new()
	hook.name = "VoidTileCarry"
	child.add_child(hook)
	child.picked_up.connect(hook.keep_carried_frozen)

func keep_carried_frozen(_pickable: Node) -> void:
	var cube: PatternTileCube = get_parent()
	cube.freeze = true
