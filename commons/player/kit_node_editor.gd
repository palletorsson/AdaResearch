extends Node3D
## THE NODE EDITOR (Palle, 2026-11-06: "the editor should work as a selector, so click on the element like a ball, then
## we can point to the edit space by hitting the nodes with the fire button; the same goes for the other elements").
## Choose a kit element in the hand (the prism or the belt): the ball, the rod or the brace. The EDIT SPACE is a box of
## nodes on the bench's grid (SIZE nodes, the stage's pitch), drawn as small dots; the first shot on a floor sets it
## down there, centred on the shot. Then:
##   - BALL: fire at a node -> a ball on that node;
##   - ROD / BRACE: fire at a node (it turns pink, a line follows the aim), fire at a second node -> the piece between
##     them, any number of steps along one axis (a rod) or along one face diagonal (a brace); a missing ball at either
##     end is made too, as Blender makes an edge's vertices. Fire the first node again to let it go;
##   - GRIP: a half-made rod is let go; pointing at a placed piece takes it back (the wand's grip); pointing at no node,
##     the box is cleared and the next shot sets it down somewhere else.
## Pieces placed here are made by the hand (budget, keeping, taking back) and held where they were fired, like Blender's
## edit mode: a ball on a node with nothing under it does not fall, and is drawn amber until something supports it.
## Driven by inventory_wand.gd for both rigs (the VR prism's right controller, the desktop camera).

const Items = preload("res://commons/player/inventory_items.gd")
const SIZE := Vector3i(6, 4, 6)   # nodes across x, up y, across z
const PICK := 0.2                 # metres: how near the aim line a node must pass to be hit
const REACH := 12.0               # a 6 m box seen from outside its edge: its far corner is ~9 m away
const HUB := 0.085                # a ball's radius + boss: row 0's centre stands this far over the floor

var hand: Node = null
var has_box := false
var origin := Vector3.ZERO        # where node (0, 0, 0) touches the floor
var first: Variant = null         # Vector3i: a rod's first node, or null
var aimed: Variant = null         # Vector3i: the node under the aim this frame, or null
var notice := ""
var _dots: MultiMeshInstance3D
var _mark: MeshInstance3D
var _first_mark: MeshInstance3D
var _line: MeshInstance3D

func _ready() -> void:
	_dots = MultiMeshInstance3D.new();_dots.name = "Nodes";_dots.top_level = true
	var dot := SphereMesh.new();dot.radius = .022;dot.height = .044;dot.radial_segments = 8;dot.rings = 4
	var mm := MultiMesh.new();mm.transform_format = MultiMesh.TRANSFORM_3D;mm.mesh = dot;_dots.multimesh = mm
	_dots.material_override = _flat(Color(1, 1, 1, .55));_dots.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(_dots)
	_mark = _ball_mark(Color("f59e0b"), .07, "Aimed");_first_mark = _ball_mark(Color("ea72ab"), .08, "First")
	_line = MeshInstance3D.new();_line.name = "Stretch";_line.top_level = true;_line.mesh = ImmediateMesh.new()
	_line.material_override = _flat(Color("ea72ab", .9));add_child(_line)
	hide_all()

static func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new();m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;m.no_depth_test = true
	return m

func _ball_mark(c: Color, r: float, title: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new();mi.name = title;mi.top_level = true
	var s := SphereMesh.new();s.radius = r;s.height = r * 2;s.radial_segments = 16;s.rings = 8;mi.mesh = s
	mi.material_override = _flat(Color(c, .75));mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mi)
	return mi

## The element in the hand is a kit piece (ball, rod or brace) and the bench has a GRID: the node editor has the
## trigger. On a contact stage (Point One, floors 0-2: "no grid yet - balls snap to each other") there are no nodes,
## and a ball is placed where the hand points as before.
func active() -> bool:
	return hand != null and hand.current != "" and kind() != "" and str(hand.stage().get("snap", "grid")) == "grid"

## "ball", "rod", "brace" or "".
func kind() -> String:
	var it: Dictionary = Items.item(hand.current)
	match str(it.get("token", "")):
		"playground_ball":return "ball"
		"playground_rod":return "brace" if bool((it.get("defaults", {}) as Dictionary).get("diagonal", false)) else "rod"
	return ""

func pitch() -> Vector2:
	return hand.pitch() if hand != null else Vector2.ONE

## A node's ball centre in the world.
func world(n: Vector3i) -> Vector3:
	var g := pitch()
	return origin + Vector3(n.x * g.x, n.y * g.y + HUB, n.z * g.x)

func hide_all() -> void:
	if _dots == null:return
	_dots.visible = false;_mark.visible = false;_first_mark.visible = false;_line.visible = false

## Every frame while active: the box (or where it would go), the node under the aim, the stretch from a first node.
func update(aim: Node3D, exclude: Array = []) -> void:
	var from := aim.global_position;var dir := -aim.global_basis.z
	if not has_box:
		var hit := _floor_hit(aim, exclude)
		_mark.visible = false;_first_mark.visible = false;_line.visible = false
		if hit.is_empty():_dots.visible = false;return
		_draw_dots(_box_origin(hit.position), .25)   # where the box would go: faint
		return
	_draw_dots(origin, .55)
	aimed = pick(aim, exclude)
	_mark.visible = aimed != null
	if aimed != null:_mark.global_position = world(aimed)
	_first_mark.visible = first != null
	if first != null:
		_first_mark.global_position = world(first)
		var to: Vector3 = world(aimed) if aimed != null else from + dir * 2.0
		var im: ImmediateMesh = _line.mesh;im.clear_surfaces();im.surface_begin(Mesh.PRIMITIVE_LINES)
		im.surface_add_vertex(world(first));im.surface_add_vertex(to);im.surface_end();_line.visible = true
	else:
		_line.visible = false

func _draw_dots(at: Vector3, alpha: float) -> void:
	var mm := _dots.multimesh
	if mm.instance_count != SIZE.x * SIZE.y * SIZE.z:mm.instance_count = SIZE.x * SIZE.y * SIZE.z
	var g := pitch();var i := 0
	for x in SIZE.x:
		for y in SIZE.y:
			for z in SIZE.z:
				mm.set_instance_transform(i, Transform3D(Basis(), at + Vector3(x * g.x, y * g.y + HUB, z * g.x)));i += 1
	(_dots.material_override as StandardMaterial3D).albedo_color.a = alpha
	_dots.visible = true

## The box centred on a floor point, its corner node on the grid.
func _box_origin(p: Vector3) -> Vector3:
	var g := pitch()
	return Vector3(roundf(p.x / g.x) * g.x - floorf(SIZE.x / 2.0) * g.x, p.y, roundf(p.z / g.x) * g.x - floorf(SIZE.z / 2.0) * g.x)

## The node the aim picks: one the aim line passes within PICK of; else, pointing at the floor inside the box, the floor
## node nearest the spot (aiming at a dot exactly is hard in a headset).
func pick(aim: Node3D, exclude: Array = []) -> Variant:
	var n: Variant = aim_node(aim.global_position, -aim.global_basis.z)
	if n != null or not has_box:return n
	var hit := _floor_hit(aim, exclude)
	if hit.is_empty() or not _in_box(hit.position):return null
	var g := pitch();var local: Vector3 = Vector3(hit.position) - origin
	return Vector3i(clampi(roundi(local.x / g.x), 0, SIZE.x - 1), 0, clampi(roundi(local.z / g.x), 0, SIZE.z - 1))

## Is a floor point over the box (within half a pitch of its outer nodes), on the box's floor?
func _in_box(p: Vector3) -> bool:
	var g := pitch();var local := p - origin
	return absf(local.y) < .05 and local.x > -g.x * .5 and local.z > -g.x * .5 and local.x < (SIZE.x - .5) * g.x and local.z < (SIZE.z - .5) * g.x

## The node nearest the aim line within PICK (the nearer along the line when two are as near); null when none.
func aim_node(from: Vector3, dir: Vector3) -> Variant:
	if not has_box:return null
	var best: Variant = null;var best_score := INF
	for x in SIZE.x:
		for y in SIZE.y:
			for z in SIZE.z:
				var n := Vector3i(x, y, z);var v := world(n) - from;var t := v.dot(dir)
				if t <= 0.0 or t > REACH:continue
				var d := (v - dir * t).length()
				if d > PICK:continue
				var score := d + t * .01
				if score < best_score:best_score = score;best = n
	return best

func _floor_hit(aim: Node3D, exclude: Array) -> Dictionary:
	var from := aim.global_position;var q := PhysicsRayQueryParameters3D.create(from, from - aim.global_basis.z * REACH, 1)
	var skip: Array[RID] = [];for r in exclude:skip.append(r)
	for i in 8:
		q.exclude = skip
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty():return {}
		var c: Object = hit.collider
		if c is Node and ((c as Node).is_in_group("playground_balls") or (c as Node).is_in_group("playground_rods")):skip.append(hit.rid);continue
		return hit if Vector3(hit.normal).y > .7 else {}   # a floor, not a wall
	return {}

## THE TRIGGER. Returns box, placed, first, cancelled, refused ("" when not active).
func press(aim: Node3D, exclude: Array = []) -> String:
	if not active():return ""
	notice = ""
	if not has_box:
		var hit := _floor_hit(aim, exclude)
		if hit.is_empty():notice = "point at a floor to set the edit space down";return "refused"
		origin = _box_origin(hit.position);has_box = true;first = null
		return "box"
	var n: Variant = pick(aim, exclude)
	if n == null:
		var hit := _floor_hit(aim, exclude)
		if not hit.is_empty() and not _in_box(hit.position):   # a shot on the floor outside the box moves it there
			origin = _box_origin(hit.position);first = null
			return "box"
		notice = "aim at a node";return "refused"
	if kind() == "ball":
		if ball_at(n) != null:notice = "a ball is already there";return "refused"
		return "placed" if make_ball(n) != null else "refused"
	if first == null:first = n;return "first"
	if n == first:first = null;return "cancelled"
	var a: Vector3i = first
	first = null
	return "placed" if make_rod(a, n) != null else "refused"

## THE GRIP, when the wand did not take a piece back: a half-made rod let go, else the box cleared. True if used.
func grip() -> bool:
	if not active():return false
	if first != null:first = null;return true
	if has_box and aimed == null:has_box = false;hide_all();return true
	return false

func ball_at(n: Vector3i) -> Node3D:
	var p := world(n)
	for b in get_tree().get_nodes_in_group("playground_balls"):
		if is_instance_valid(b) and not b.held and b.global_position.distance_to(p) < .01:return b
	return null

## A ball on node `n`, made by the hand from the "point" item and held where it was fired.
func make_ball(n: Vector3i) -> Node3D:
	var id := _item_for("playground_ball", false)
	if id == "" or not hand.fits(id):notice = hand.notice if id != "" else "no ball item";return null
	var b: Node3D = hand.spawn_at(Transform3D(Basis(), world(n)), id, hand.config_for(id))
	if b == null:notice = "could not make a ball";return null
	b.editing = true;b.snap_to = "grid"   # the node is the place: no contact snapping here
	b.settle()
	return b

## A rod (or brace) from node a to node b: balls made where missing, the piece laid between their facing mouths.
func make_rod(a: Vector3i, b: Vector3i) -> Node3D:
	var d := b - a;var nonzero: Array = []
	for k in 3:
		if d[k] != 0:nonzero.append(absi(d[k]))
	var brace := kind() == "brace"
	var steps := 0
	if not brace and nonzero.size() == 1:steps = nonzero[0]
	elif brace and nonzero.size() == 2 and nonzero[0] == nonzero[1]:steps = nonzero[0]
	if steps == 0:
		notice = "a brace runs along a face diagonal" if brace else "a rod runs along the grid, one axis at a time";return null
	var ends: Array = []
	for n in [a, b]:
		var ball: Node3D = ball_at(n)
		if ball == null:ball = make_ball(n)
		if ball == null:return null
		ends.append(ball)
	var id: String = hand.current
	if not hand.fits(id):notice = hand.notice;return null
	var cfg: Dictionary = hand.config_for(id);cfg["units"] = steps
	var dirn := (world(b) - world(a)).normalized()
	var ia := _facing(ends[0], dirn);var ib := _facing(ends[1], -dirn)
	if ia < 0 or ib < 0:notice = "these balls have no diagonal sockets (the brace needs the Triangle stage)" if brace else "no socket faces that way";return null
	var ma: Vector3 = ends[0].socket_global(ia);var mb: Vector3 = ends[1].socket_global(ib)
	var rod: Node3D = hand.spawn_at(Transform3D(_basis_x(dirn), (ma + mb) / 2.0), id, cfg)
	if rod == null:notice = "could not make the piece";return null
	rod.apply_grid_config(cfg)
	rod.set_meta("inv_cfg", cfg);rod.set_meta("inv_key", id + "|" + JSON.stringify(cfg))
	rod.global_transform = Transform3D(_basis_x(dirn), (ma + mb) / 2.0)
	if rod.settle() < 2:notice = "the piece did not reach both sockets"
	return rod

## The id of the hand's item for a kit token (the ball when a rod needs its ends).
static func _item_for(token: String, diagonal: bool) -> String:
	for it in Items.items():
		if str(it.get("token", "")) == token and bool((it.get("defaults", {}) as Dictionary).get("diagonal", false)) == diagonal:return str(it.id)
	return ""

## The ball's free socket pointing along `dir` (exactly: a rod's axis or a brace's diagonal), or -1.
static func _facing(ball: Node3D, dir: Vector3) -> int:
	var dirs: Array = ball.dirs()
	for i in dirs.size():
		if (dirs[i] as Vector3).dot(dir) > .999 and ball.socket_free(i):return i
	return -1

static func _basis_x(axis: Vector3) -> Basis:
	var up := Vector3.UP if absf(axis.dot(Vector3.UP)) < .9 else Vector3.BACK
	var z := axis.cross(up).normalized();var y := z.cross(axis).normalized()
	return Basis(axis, y, z)
