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
## Cells wide the wall grows ACROSS the approach (perpendicular to the
## foe→player line). >1 makes a real wall instead of a thin line.
@export var wall_width: int = 6
## Cap so a single foe can't carpet the map.
@export var max_blocks: int = 14
## Edge size of each dropped block (1.0 = fills a 1m cell).
@export var build_size: float = 1.0
## Render dropped blocks with the grid wireframe shader (floor look).
@export var build_use_grid_shader: bool = false
## Free the blocks it placed when it becomes a friend (the wall opens).
@export var clear_blocks_on_befriend: bool = true

@export_group("Walk-Build cycle")
## How fast the builder walks to its next build spot (m/s).
@export var walk_speed: float = 1.6
## Pause after each placement while the pyramid "hatches" (seconds).
@export var hatch_seconds: float = 1.0
## How close to the target cell the foe must get before it places.
@export var arrive_distance: float = 1.2
## Give up walking to a target after this long (stuck) and pick another.
@export var walk_timeout: float = 5.0

const BLOCK_SCENES := {
	"cube": preload("res://commons/hazards/path_block/path_cube.tscn"),
	"wedge": preload("res://commons/hazards/path_block/path_wedge.tscn"),
	"pyramid": preload("res://commons/hazards/path_block/path_pyramid.tscn"),
}

var _placed: Array = []
# Raw structure layer (rows of "0"/"1"/"2") — placement allowed only on
# level 1 (walkable floor). Empty in standalone scenes (physics fallback).
var _struct_grid: Array = []

# Walk → place → hatch cycle.
enum BState { WALK, PLACE, HATCH }
var _bstate: int = BState.WALK
var _target_cell: Vector2i = Vector2i.ZERO
var _has_target: bool = false
var _walk_time: float = 0.0
var _hatch_timer: float = 0.0
const _NO_CELL := Vector2i(-99999, -99999)


func _on_ready() -> void:
	super._on_ready()
	add_to_group("path_builder")
	_struct_grid = _find_structure_grid()
	# Listen to our own arc so we can react to becoming a friend.
	if not personality_changed.is_connected(_on_builder_personality):
		personality_changed.connect(_on_builder_personality)


# Read the raw structure layer (rows of "0"/"1"/"2") from the map's data
# component. Source of truth for walkable level-1 cells. [] → standalone.
func _find_structure_grid() -> Array:
	var n: Node = get_parent()
	while n != null:
		var grid := _structure_from(n)
		if not grid.is_empty():
			return grid
		n = n.get_parent()
	return _search_structure(get_tree().current_scene)


func _structure_from(n: Node) -> Array:
	if n == null:
		return []
	if "data_component" in n and n.get("data_component") != null:
		var dc = n.get("data_component")
		if "json_loader" in dc and dc.get("json_loader") != null \
				and dc.json_loader.has_method("get_structure_layer"):
			return dc.json_loader.get_structure_layer()
	if n.has_method("get_structure_layer"):
		return n.call("get_structure_layer")
	return []


func _search_structure(node: Node) -> Array:
	if node == null:
		return []
	var grid := _structure_from(node)
	if not grid.is_empty():
		return grid
	for c in node.get_children():
		var r := _search_structure(c)
		if not r.is_empty():
			return r
	return []


func _structure_height(cx: float, cz: float) -> int:
	var z: int = int(roundf(cz))
	var x: int = int(roundf(cx))
	if z < 0 or z >= _struct_grid.size():
		return 0
	var row = _struct_grid[z]
	if not (row is Array) or x < 0 or x >= row.size():
		return 0
	var v := str(row[x]).strip_edges()
	return int(v) if v.is_valid_int() else 0


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


# The builder no longer drops blocks remotely on a timer — it WALKS to a
# spot, PLACES a pyramid, then HATCHES (pauses) before walking to the
# next spot. We drive movement ourselves (constant walking height; the
# grid floor is flat) rather than the base chase, so the cadence reads.
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_player_node):
		_find_player()
	# Befriended, out of budget, or no player → stand still.
	if _personality == "friend" or _player_node == null or _placed.size() >= max_blocks:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	match _bstate:
		BState.WALK:  _state_walk(_delta)
		BState.PLACE: _state_place()
		BState.HATCH: _state_hatch(_delta)
	# Keep to the walking surface — flat level-1 floor, no gravity needed
	# (the foe's collision mask is 0, so move_and_slide just integrates).
	velocity.y = 0.0
	move_and_slide()


func _state_walk(delta: float) -> void:
	if not _has_target:
		if not _choose_build_target():
			velocity = Vector3.ZERO
			return
		_walk_time = 0.0
	_walk_time += delta
	var tw := _cell_world(_target_cell)
	var to := Vector3(tw.x - global_position.x, 0.0, tw.z - global_position.z)
	var d := to.length()
	if d <= arrive_distance:
		velocity = Vector3.ZERO
		_bstate = BState.PLACE
		return
	if _walk_time > walk_timeout:   # stuck → pick a new target
		_has_target = false
		velocity = Vector3.ZERO
		return
	var dir: Vector3 = to / maxf(d, 0.001)
	velocity.x = dir.x * walk_speed
	velocity.z = dir.z * walk_speed


func _state_place() -> void:
	var cx := float(_target_cell.x)
	var cz := float(_target_cell.y)
	if not _cell_filled(cx, cz) and _has_floor_at(cx, cz):
		_spawn_block_at(cx, cz)
	_has_target = false
	_hatch_timer = hatch_seconds
	_bstate = BState.HATCH


func _state_hatch(delta: float) -> void:
	velocity = Vector3.ZERO
	_hatch_timer -= delta
	if _hatch_timer <= 0.0:
		_bstate = BState.WALK


# World centre of a cell at the foe's walking height.
func _cell_world(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x), global_position.y, float(cell.y))


# Choose the next cell to wall: prefer a cell on the player's live route
# to the exit; else the first reachable empty floor cell toward the
# player. Returns false when nothing valid is found.
func _choose_build_target() -> bool:
	var rc := _route_target_cell()
	if rc != _NO_CELL:
		_target_cell = rc
		_has_target = true
		return true
	var to_player: Vector3 = _player_node.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	if dist < 0.05:
		return false
	var dir: Vector3 = to_player.normalized()
	for k in range(max(2, int(ceil(dist)))):
		var drop := global_position + dir * (build_ahead + float(k))
		var cx: float = roundf(drop.x)
		var cz: float = roundf(drop.z)
		if _cell_filled(cx, cz):
			continue
		if not _has_floor_at(cx, cz):
			continue
		_target_cell = Vector2i(int(cx), int(cz))
		_has_target = true
		return true
	return false


# Map 0,1,2,3,4 → 0,+1,-1,+2,-2 so a search fans outward from the centre.
func _wall_offset(i: int) -> int:
	var step: int = (i + 1) / 2
	return step if (i % 2 == 1) else -step


# A cell on the watchdog's current player→exit route (middle stretch,
# empty, walkable level-1) to walk to and wall. _NO_CELL if none.
func _route_target_cell() -> Vector2i:
	var wd = get_tree().get_first_node_in_group("path_watchdog")
	if wd == null or not wd.has_method("get_path_points"):
		return _NO_CELL
	var pts: Array = wd.get_path_points()
	if pts.size() < 3:
		return _NO_CELL
	var n: int = pts.size()
	var mid: int = n / 2
	for d in range(n):
		var idx: int = mid + _wall_offset(d)
		if idx <= 0 or idx >= n - 1:
			continue
		var p: Vector3 = pts[idx]
		var cx: float = roundf(p.x)
		var cz: float = roundf(p.z)
		if _cell_filled(cx, cz):
			continue
		if not _has_floor_at(cx, cz):
			continue
		return Vector2i(int(cx), int(cz))
	return _NO_CELL


func _cell_filled(cx: float, cz: float) -> bool:
	for b in _placed:
		if is_instance_valid(b) and absf(b.global_position.x - cx) < 0.5 and absf(b.global_position.z - cz) < 0.5:
			return true
	return false


# Can the foe build on this cell? Only on structure LEVEL 1 — the
# walkable floor. The placed block raises that cell toward level 2 and
# blocks the level-1 path. Rejects, straight from the structure data:
#   • level 0 / out of bounds → void or outside the structure
#   • level 2+ → already raised; the player can't walk there anyway
# Falls back to a physics floor-probe only when no structure grid exists
# (standalone test scenes).
func _has_floor_at(cx: float, cz: float) -> bool:
	if not _struct_grid.is_empty():
		return _structure_height(cx, cz) == 1
	# Physics fallback (no structure grid).
	var space := get_world_3d().direct_space_state
	var from := Vector3(cx, global_position.y + 2.5, cz)
	var to := Vector3(cx, global_position.y - 2.0, cz)
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collision_mask = 0xFFFFFFFF
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.exclude = [get_rid()]
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return false
	return float(hit.position.y) <= global_position.y + 0.5


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
