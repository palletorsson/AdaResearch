extends CatalystFoe
class_name PathBuilderFoe

# @identity
# essence: the antagonist of the path-and-block game made whole — a CatalystFoe that doesn't just chase, it BUILDS. It walks the grid dropping primitive blocks to wall your route to the exit, and like every catalyst foe it can be talked down: hit it enough and it flips to friend, stops building, and clears the wall it made.
# desire: to be the single creature the whole game turns on — the thing you either outrun to the teleporter or change the mind of. It wants to embody the design's two solutions in one body: a wall-builder you race, or a foe you befriend.
# critical_parameter: build_shape — which primitive it drops (pyramid → wedge → cube as the curriculum progresses). Pyramids and wedges are passable ramps (early game, harmless teaching); cubes are walls (late game, real threat). Its danger grows exactly with how far you've come.
# triggers: inherits the catalyst arc + chase from CatalystFoe; adds a build timer in _physics_process that drops a path_block ahead of itself toward the player while it is still a foe; on reaching "friend" it stops and frees the blocks it placed.
# emerges: a foe that walks across your route leaving a trail of cubes IS a closing maze; befriending it mid-build is the wall dissolving in real time — the catalyst's thesis as a turning point you can feel.
# needs: CatalystFoe parent (catalyst hit contract, personality arc, enemy group, chase) [inherited]; path_block scenes to drop [preloaded]; a valid player to build toward [guarded]; collision_layer 2 so catalyst projectiles hit it [in .tscn]
# relationships: IS-A CatalystFoe (so PathGameController's Win-B and the real catalyst tool both work on it unchanged); drops path_block (the game's bricks); judged by path_watchdog (its cubes block, its wedges pass); spawned by catalyst_vent (the pylon) in a full level.
# truth: the wall and the one who builds it are the same problem — and both are solved the same way, by changing what the builder wants. You do not break the maze; you befriend its author.

## A CatalystFoe that walks and builds a wall of primitives across the
## player's path — and stops + clears it when befriended. The unified
## antagonist of the path-and-block game.

@export_group("Building")
## Seconds between dropped blocks.
@export var build_interval: float = 2.5
## "pyramid" | "wedge" | "cube" — the curriculum progression. Cube walls;
## pyramid/wedge are passable ramps (harmless early-game blocks).
@export var build_shape: String = "cube"
## How far ahead of itself (toward the player) it drops the block.
@export var build_ahead: float = 1.3
## Cap so a single foe can't carpet the map.
@export var max_blocks: int = 10
## Free the blocks it placed when it becomes a friend (the wall opens).
@export var clear_blocks_on_befriend: bool = true

const BLOCK_SCENES := {
	"cube": preload("res://commons/hazards/path_block/path_cube.tscn"),
	"wedge": preload("res://commons/hazards/path_block/path_wedge.tscn"),
	"pyramid": preload("res://commons/hazards/path_block/path_pyramid.tscn"),
}

var _build_timer: float = 0.0
var _placed: Array = []


func _on_ready() -> void:
	super._on_ready()
	add_to_group("path_builder")
	# Listen to our own arc so we can react to becoming a friend.
	if not personality_changed.is_connected(_on_builder_personality):
		personality_changed.connect(_on_builder_personality)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Only a foe builds; a friend has laid down its tools.
	if _personality == "friend":
		return
	if not is_instance_valid(_player_node):
		return
	_build_timer += delta
	if _build_timer >= build_interval:
		_build_timer = 0.0
		_place_block()


func _place_block() -> void:
	if _placed.size() >= max_blocks:
		return
	var dir: Vector3 = _player_node.global_position - global_position
	dir.y = 0.0
	if dir.length() < 0.05:
		return
	dir = dir.normalized()

	# Grid-snapped drop point a bit ahead toward the player.
	var drop := global_position + dir * build_ahead
	var cx: float = roundf(drop.x)
	var cz: float = roundf(drop.z)
	# Don't stack on a cell we already filled.
	for b in _placed:
		if is_instance_valid(b) and absf(b.global_position.x - cx) < 0.5 and absf(b.global_position.z - cz) < 0.5:
			return

	var scene: PackedScene = BLOCK_SCENES.get(build_shape, BLOCK_SCENES["cube"])
	var block: Node3D = scene.instantiate()
	var root := get_parent()
	if root == null:
		root = get_tree().current_scene
	root.add_child(block)
	# Block origin is its base — sit it on the foe's walking surface
	# (foe is a 0.3m cube, so its base is ~0.15 below its origin).
	block.global_position = Vector3(cx, global_position.y - 0.15, cz)
	_placed.append(block)


func _on_builder_personality(_from_p: String, to_p: String) -> void:
	if to_p != "friend":
		return
	# Befriended: lay down the tools and (optionally) open the wall it made.
	if clear_blocks_on_befriend:
		for b in _placed:
			if is_instance_valid(b):
				b.queue_free()
		_placed.clear()
