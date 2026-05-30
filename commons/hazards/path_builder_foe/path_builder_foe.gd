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
## Edge size of each dropped block (1.0 = fills a 1m cell).
@export var build_size: float = 1.0
## Render dropped blocks with the grid wireframe shader (floor look).
@export var build_use_grid_shader: bool = false
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


# Map-token config (path_builder_foe#build_shape:pyramid#use_grid_shader:1 …).
# The base only reads health/speed/etc., so read the build params here.
func apply_grid_config(config: Dictionary) -> void:
	super.apply_grid_config(config)
	if config.has("build_shape"):
		build_shape = String(config["build_shape"]).to_lower()
	if config.has("build_interval"):
		build_interval = float(config["build_interval"])
	if config.has("build_ahead"):
		build_ahead = float(config["build_ahead"])
	if config.has("max_blocks"):
		max_blocks = int(config["max_blocks"])
	if config.has("build_size"):
		build_size = float(config["build_size"])
	if config.has("use_grid_shader"):
		build_use_grid_shader = String(config["use_grid_shader"]).to_lower() in ["1", "true", "yes", "on"]


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
	var to_player: Vector3 = _player_node.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	if dist < 0.05:
		return
	var dir: Vector3 = to_player.normalized()

	# March a LINE of blocks from the foe toward the player: each interval
	# drop at the FIRST still-empty cell along that line. This builds a
	# growing wall toward the player even when the foe is standing still —
	# without it, a stationary foe re-targets the same cell and only ever
	# places one block.
	var steps: int = max(2, int(ceil(dist)))
	for k in range(steps):
		var drop := global_position + dir * (build_ahead + float(k))
		var cx: float = roundf(drop.x)
		var cz: float = roundf(drop.z)
		if _cell_filled(cx, cz):
			continue
		# Only build on an EXISTING floor cube — never float a block over
		# the void. Skip empty cells and march on to the next solid one.
		if not _has_floor_at(cx, cz):
			continue
		_spawn_block_at(cx, cz)
		return


func _cell_filled(cx: float, cz: float) -> bool:
	for b in _placed:
		if is_instance_valid(b) and absf(b.global_position.x - cx) < 0.5 and absf(b.global_position.z - cz) < 0.5:
			return true
	return false


# Is there a floor cube under this cell? Downward ray from just above the
# foe's walking surface; a hit means solid ground to build on, no hit
# means void (don't place there).
func _has_floor_at(cx: float, cz: float) -> bool:
	var space := get_world_3d().direct_space_state
	var from := Vector3(cx, global_position.y + 0.6, cz)
	var to := Vector3(cx, global_position.y - 2.0, cz)
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collision_mask = 0xFFFFFFFF
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.exclude = [get_rid()]
	return not space.intersect_ray(params).is_empty()


func _spawn_block_at(cx: float, cz: float) -> void:
	var scene: PackedScene = BLOCK_SCENES.get(build_shape, BLOCK_SCENES["cube"])
	var block: Node3D = scene.instantiate()
	# Set DNA before add_child so the block's _ready/_build uses it.
	block.set("size", build_size)
	block.set("use_grid_shader", build_use_grid_shader)
	var root := get_parent()
	if root == null:
		root = get_tree().current_scene
	root.add_child(block)
	# Sit the block base on the foe's walking surface (foe is a 0.3m
	# cube, so its base is ~0.15 below its origin).
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
