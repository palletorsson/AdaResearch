extends Node3D
class_name PathWatchdog

# @identity
# essence: the referee of the path-and-block game — every half-second it asks "does a walkable route still exist from the player to the teleporter?" and when the answer turns to NO it starts a five-second clock that ends the level. It draws the answer as a ribbon on the floor so the player can watch the route narrow and redden as blocks land.
# desire: to make the maze's topology FELT. A grid of cells is just data until something cares whether you can cross it; the watchdog cares, out loud, on a clock. It wants the loss to be legible — never a surprise, always a thing you saw coming and could have prevented.
# critical_parameter: grace_seconds — the window between "path blocked" and "level restarts". It is the fairness valve: long enough that a momentary seal isn't instant death and you can re-open a route or befriend the builder; short enough that walling you in is a real threat. Five seconds is the felt sweet spot.
# triggers: a scan timer (scan_interval) recomputes a BFS over cell-occupancy between start and goal; transitions between OPEN and BLOCKED drive the countdown; expiry calls DeathEffect.play (or reloads).
# emerges: with a block-builder foe in the map, the ribbon becomes a live readout of the duel — you and the builder are both editing the same graph, and the red line is the scoreboard.
# needs: a start (player, else spawn, else self) [resolved at runtime]; a goal (a Teleport node) [resolved at runtime]; physics blockers on the lattice [queried each scan]; a ribbon MeshInstance [built]; DeathEffect autoload for restart [optional, falls back to scene reload]
# relationships: referee to blockbuilderentity + catalyst_foe (they edit the graph, this judges it); cousin to map_pathfinder.py (the same reachability question, but at RUNTIME and on a clock instead of at design time); sibling to DeathEffect (it asks for the restart this hands out).
# truth: a level is solvable until someone proves it isn't. The watchdog is that proof, running live — it turns "is there a path?" from a design-time guarantee into a moment-to-moment stake.

## Runtime path referee for the path-and-block game.
##
## Every `scan_interval` seconds it BFS-searches a cell lattice between
## the player (start) and the teleporter (goal), treating cells that
## overlap a physics blocker as impassable. If a route exists it draws
## a green ribbon along it. If none exists it reddens and starts a
## `grace_seconds` countdown; on expiry it triggers a restart.
##
## Self-contained: discovers start/goal/blockers at runtime, no hard
## dependency on GridSystem. Drop it into a map and it works.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Rules")
## Seconds the path may stay blocked before the level restarts.
@export var grace_seconds: float = 5.0
## How often (seconds) to recompute the route.
@export var scan_interval: float = 0.5
## Win when the player reaches within this distance of the goal.
@export var reach_distance: float = 1.6

@export_group("Lattice")
## Cell size of the reachability lattice (metres). Match the grid.
@export var cell_size: float = 1.0
## Extra cells of padding around the start/goal bounding box.
@export var region_margin: int = 4
## Probe sphere radius for "is this cell blocked" (metres).
@export var probe_radius: float = 0.34
## Height above floor to probe — high enough to miss the floor slab,
## low enough to catch any standing block / wall.
@export var probe_height: float = 0.6
## How far below the walking surface a floor may sit and still count as
## "there is ground here". A cell with no ground within this drop is a
## void and never joins the path. Set <= 0 to disable the floor test
## (flat maps with a continuous floor).
@export var floor_drop: float = 1.4
## Physics layers a blocker can live on. Default: everything.
@export_flags_3d_physics var blocker_mask: int = 0xFFFFFFFF
## Bodies in any of these groups are RAMPS/PASSABLE — they don't block
## the path even though they have a collider. A wedge or pyramid the
## player can walk up is tagged here; a cube wall is not. This is the
## cube-vs-wedge distinction that gives the game its texture.
@export var walkable_groups: Array[String] = ["path_passable", "ramp"]

@export_group("Ribbon")
@export var ribbon_width: float = 0.16
@export var ribbon_height: float = 0.06    # above the walking surface
@export var color_open: Color = Color(0.30, 0.95, 0.55)
@export var color_blocked: Color = Color(1.0, 0.28, 0.22)

@export_group("Behaviour")
## When true, expiry triggers a restart. Off = scoreboard only (debug).
@export var restart_on_timeout: bool = true

# ── Signals ───────────────────────────────────────────────────────────

signal path_opened
signal path_blocked
signal countdown_tick(remaining: float)
signal level_failed
signal level_cleared

# ── Internal ──────────────────────────────────────────────────────────

const PLAYER_GROUPS := ["player", "vr_player", "player_body"]

var _start_node: Node3D = null
var _goal_node: Node3D = null
var _scan_timer: float = 0.0
var _blocked: bool = false
var _countdown: float = 0.0
var _ribbon: MeshInstance3D = null
var _ribbon_mat: StandardMaterial3D = null
var _resolved: bool = false
var _cleared: bool = false
# True only when an actual player rig was found. The restart/countdown
# is gated on this so the watchdog is inert in capture / gallery / editor
# contexts where there is no player to fail.
var _has_real_player: bool = false
# Walking-surface Y, derived from the start node each scan so the probe
# and ribbon track the real floor regardless of the grid's vertical
# convention (height-1 blocks, ramps, lowered labs, etc).
var _floor_ref_y: float = 0.0


func _ready() -> void:
	# Register so the game controller can find the referee.
	add_to_group("path_watchdog")
	_read_metadata_overrides()
	_build_ribbon()
	call_deferred("_resolve_endpoints")


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()


func _read_metadata_overrides() -> void:
	grace_seconds = _num_meta("config_grace_seconds", grace_seconds)
	scan_interval = _num_meta("config_scan_interval", scan_interval)
	cell_size = _num_meta("config_cell_size", cell_size)
	reach_distance = _num_meta("config_reach_distance", reach_distance)
	if has_meta("config_restart_on_timeout"):
		var v := str(get_meta("config_restart_on_timeout")).to_lower()
		restart_on_timeout = v in ["true", "1", "yes", "on"]


# Tolerant numeric meta read. The map-token config parser sometimes
# stores a bare `true` for keys it doesn't recognise as values; never
# let that zero out a parameter — fall back to the current value.
func _num_meta(key: String, fallback: float) -> float:
	if not has_meta(key):
		return fallback
	var v = get_meta(key)
	if v is float or v is int:
		return float(v)
	var s := str(v)
	if s.is_valid_float():
		return float(s)
	return fallback


# ── Endpoint discovery ────────────────────────────────────────────────

func _resolve_endpoints() -> void:
	_start_node = _find_player()
	_goal_node = _find_teleport()
	_resolved = true
	# Run one scan immediately so the ribbon shows on the first frame
	# (VR + headless capture).
	_scan()


func _find_player() -> Node3D:
	for g in PLAYER_GROUPS:
		var nodes := get_tree().get_nodes_in_group(g)
		if not nodes.is_empty() and nodes[0] is Node3D:
			_has_real_player = true
			return nodes[0]
	# Fallback: a spawn marker, else this node's own position. These are
	# NOT a real player, so the failure clock stays disarmed.
	for g in ["spawn", "spawn_point", "SpawnPoint"]:
		var sp := get_tree().get_nodes_in_group(g)
		if not sp.is_empty() and sp[0] is Node3D:
			return sp[0]
	return self


func _find_teleport() -> Node3D:
	# Teleport is `class_name Teleport extends Node3D`. Walk the tree.
	var root := get_tree().current_scene
	if root == null:
		root = get_tree().root
	var found := _recursive_find_class(root, "Teleport")
	if found:
		return found
	# Fallback group.
	for g in ["teleporter", "teleport"]:
		var t := get_tree().get_nodes_in_group(g)
		if not t.is_empty() and t[0] is Node3D:
			return t[0]
	return null


func _recursive_find_class(node: Node, klass: String) -> Node3D:
	if node is Node3D:
		var scr = node.get_script()
		if scr != null and scr.get_global_name() == klass:
			return node
	for c in node.get_children():
		var r := _recursive_find_class(c, klass)
		if r != null:
			return r
	return null


# ── Main loop ─────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _resolved or _cleared:
		return

	# Win check — player reached the goal.
	if _start_node and _goal_node:
		var d: float = Vector2(
			_start_node.global_position.x - _goal_node.global_position.x,
			_start_node.global_position.z - _goal_node.global_position.z).length()
		if d <= reach_distance:
			_on_cleared()
			return

	_scan_timer += delta
	if _scan_timer >= scan_interval:
		_scan_timer = 0.0
		_scan()

	if _blocked and restart_on_timeout and _has_real_player:
		_countdown -= delta
		countdown_tick.emit(maxf(_countdown, 0.0))
		# Pulse the ribbon brightness with the countdown urgency.
		if _ribbon_mat:
			var urgency: float = 1.0 - clampf(_countdown / maxf(grace_seconds, 0.01), 0.0, 1.0)
			_ribbon_mat.emission_energy_multiplier = 1.5 + urgency * 3.0
		if _countdown <= 0.0:
			_fail()


func _scan() -> void:
	if _start_node == null or _goal_node == null:
		return
	# Track the walking surface off the start node (player feet / spawn).
	_floor_ref_y = _start_node.global_position.y
	var path := _find_route(_start_node.global_position, _goal_node.global_position)
	if path.is_empty():
		_enter_blocked()
		# Keep the last ribbon but recolour it red as a "this route died" cue.
		_recolor_ribbon(color_blocked)
	else:
		_enter_open()
		_draw_ribbon(path, color_open)


func _enter_blocked() -> void:
	if _blocked:
		return
	_blocked = true
	_countdown = grace_seconds
	path_blocked.emit()


func _enter_open() -> void:
	if not _blocked:
		return
	_blocked = false
	_countdown = grace_seconds
	if _ribbon_mat:
		_ribbon_mat.emission_energy_multiplier = 1.5
	path_opened.emit()


func _fail() -> void:
	level_failed.emit()
	if not restart_on_timeout:
		return
	var death = get_node_or_null("/root/DeathEffect")
	if death and death.has_method("play"):
		var pos: Vector3 = _start_node.global_position if _start_node else global_position
		death.play(pos)
	else:
		get_tree().reload_current_scene()


func _on_cleared() -> void:
	_cleared = true
	_recolor_ribbon(color_open)
	level_cleared.emit()


# ── Reachability (BFS over cell occupancy) ────────────────────────────

func _find_route(start_w: Vector3, goal_w: Vector3) -> Array:
	var start_c := _to_cell(start_w)
	var goal_c := _to_cell(goal_w)

	# Bounded region = AABB of start/goal padded by region_margin cells.
	var min_x: int = min(start_c.x, goal_c.x) - region_margin
	var max_x: int = max(start_c.x, goal_c.x) + region_margin
	var min_z: int = min(start_c.y, goal_c.y) - region_margin
	var max_z: int = max(start_c.y, goal_c.y) + region_margin

	var space := get_world_3d().direct_space_state
	var walkable := {}
	for cx in range(min_x, max_x + 1):
		for cz in range(min_z, max_z + 1):
			var c := Vector2i(cx, cz)
			# Start and goal cells are always walkable (the player / pad
			# themselves may overlap the probe).
			if c == start_c or c == goal_c:
				walkable[c] = true
			else:
				# Passable = there is floor to stand on AND nothing walls it.
				# The floor test stops the route from cutting across voids
				# (the "0" cells of a real map's gaps).
				walkable[c] = _cell_has_floor(space, c) and not _cell_blocked(space, c)

	# BFS (4-connectivity → grid-honest, no diagonal squeezing).
	var came_from := {}
	var queue: Array[Vector2i] = [start_c]
	var seen := {start_c: true}
	var found := false
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == goal_c:
			found = true
			break
		for nb in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nxt: Vector2i = cur + nb
			if seen.has(nxt):
				continue
			if not walkable.get(nxt, false):
				continue
			seen[nxt] = true
			came_from[nxt] = cur
			queue.push_back(nxt)

	if not found:
		return []

	# Reconstruct cell path → world points.
	var cells: Array[Vector2i] = [goal_c]
	var node := goal_c
	while node != start_c and came_from.has(node):
		node = came_from[node]
		cells.push_front(node)
	var pts: Array = []
	for cell in cells:
		pts.append(_to_world(cell))
	return pts


func _cell_blocked(space: PhysicsDirectSpaceState3D, cell: Vector2i) -> bool:
	var center := _to_world(cell)
	center.y = _floor_ref_y + probe_height
	var shape := SphereShape3D.new()
	shape.radius = probe_radius
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis.IDENTITY, center)
	params.collision_mask = blocker_mask
	params.collide_with_areas = false
	params.collide_with_bodies = true
	# Look at several overlaps, not just one — a cell can hold both a
	# ramp and (a neighbour's) wall edge.
	var hits := space.intersect_shape(params, 8)
	if hits.is_empty():
		return false
	# Blocked only if SOME overlapping body is a real wall. Bodies that
	# are all walkable ramps (wedge/pyramid) leave the cell passable.
	for h in hits:
		var col = h.get("collider")
		if col == null:
			continue
		if not _is_walkable_body(col):
			return true
	return false


# Is there ground to stand on in this cell? A downward ray from just
# above the walking surface; a hit within floor_drop means floor, no hit
# means void. Disabled when floor_drop <= 0 (flat continuous-floor maps).
func _cell_has_floor(space: PhysicsDirectSpaceState3D, cell: Vector2i) -> bool:
	if floor_drop <= 0.0:
		return true
	var top := _to_world(cell)
	top.y = _floor_ref_y + 0.25
	var bottom := top
	bottom.y = _floor_ref_y - floor_drop
	var params := PhysicsRayQueryParameters3D.create(top, bottom)
	params.collision_mask = blocker_mask
	params.collide_with_areas = false
	params.collide_with_bodies = true
	var hit := space.intersect_ray(params)
	return not hit.is_empty()


# Walk the collider's ancestor chain looking for a walkable-group tag —
# the StaticBody is often a child of the artifact node that carries the
# group.
func _is_walkable_body(node) -> bool:
	var n = node
	var depth := 0
	while n != null and depth < 4:
		if n is Node:
			for g in walkable_groups:
				if n.is_in_group(g):
					return true
		n = n.get_parent()
		depth += 1
	return false


func _to_cell(w: Vector3) -> Vector2i:
	return Vector2i(int(roundf(w.x / cell_size)), int(roundf(w.z / cell_size)))


func _to_world(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) * cell_size, _floor_ref_y + ribbon_height, float(cell.y) * cell_size)


# ── Ribbon ────────────────────────────────────────────────────────────

func _build_ribbon() -> void:
	_ribbon = MeshInstance3D.new()
	_ribbon.name = "PathRibbon"
	# Draw in world space — the watchdog node may be parked on any cell,
	# but the ribbon vertices are absolute world coords.
	_ribbon.top_level = true
	_ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ribbon_mat = StandardMaterial3D.new()
	_ribbon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ribbon_mat.vertex_color_use_as_albedo = true
	_ribbon_mat.albedo_color = color_open
	_ribbon_mat.emission_enabled = true
	_ribbon_mat.emission = color_open
	_ribbon_mat.emission_energy_multiplier = 1.5
	_ribbon_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ribbon_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	add_child(_ribbon)


func _draw_ribbon(world_pts: Array, color: Color) -> void:
	if _ribbon == null or world_pts.size() < 2:
		return
	_ribbon_mat.albedo_color = color
	_ribbon_mat.emission = color
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _ribbon_mat)
	var hw: float = ribbon_width * 0.5
	for i in world_pts.size():
		var p: Vector3 = world_pts[i]
		# Perpendicular (in XZ) to the local travel direction.
		var dir: Vector3
		if i < world_pts.size() - 1:
			dir = (world_pts[i + 1] - p)
		else:
			dir = (p - world_pts[i - 1])
		dir.y = 0.0
		if dir.length() < 0.0001:
			dir = Vector3.FORWARD
		dir = dir.normalized()
		var perp := Vector3(-dir.z, 0.0, dir.x) * hw
		# Ribbon is top_level → vertices are world coords directly.
		im.surface_set_color(color)
		im.surface_add_vertex(p - perp)
		im.surface_set_color(color)
		im.surface_add_vertex(p + perp)
	im.surface_end()
	_ribbon.mesh = im


func _recolor_ribbon(color: Color) -> void:
	if _ribbon_mat:
		_ribbon_mat.albedo_color = color
		_ribbon_mat.emission = color
