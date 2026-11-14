extends Node3D
## PAINT YOUR OWN CAVE FROM BASIC BOOLEANS (the boolean floor, Boolean_Verbs; Palle, 2026-11-14: "can we make small
## version and a big version where player can paint there own cave from basic booleans").
##
## A block and a brush. Aim at the block and hold (trigger, or the left mouse button on the crosshair): the brush stamps
## a boolean where you aim, again as you move - DIFFERENCE carves, UNION builds - as a sphere, a cube or a cylinder.
## Hold still and a carve drills, a third of the brush further along your aim at each step. The player's own movement is
## the carving pass: the Random Boolean Carving's walks and spirals, steered by a hand.
##
## Each stroke keeps a colour (the passes' rule: each movement keeps its colour), so the walls say which stroke made
## them, and a face a carve opens is the brush's, not the block's (the hall: "we could make the new faces announce
## another origin"). The block is the Random Boolean Carving's own satin.
##
##   size small  a 1.0 x 0.7 x 1.0 m block on a stand; the brush 4 - 16 cm, free in three dimensions: a cave you hold
##               in view, at the carvings' scale
##        big    a 7.6 x 4.2 x 7 m block on the floor; the brush 0.55 - 1.5 m, and a CARVE reaches down to a floor 4 cm
##               over the slab with at least 2.2 m of headroom (the shape stood on the floor), so whatever you carve
##               you can walk into; a BUILD stands where you aim
##   the console: CARVE / BUILD, SPHERE / CUBE / CYLINDER, SMALLER / BIGGER, UNDO, RESET
##
## The booleans are Godot's own (CSG on Manifold), used as a CALCULATOR: a hidden CSGCombiner3D that holds, only for the
## length of one cut, one CHUNK of the cave (a CSGMesh3D), the stamps that reach into it (CSG primitives) and the chunk's
## own cell (an intersection, so a union crossing two chunks is not drawn twice); one forced pass, baked to a mesh and a
## collision shape, and the calculator is emptied - so Godot never runs a second, deferred pass at the end of the frame.
## Measured: a pass costs about 2 ms per live operand and about 9 us per triangle of the cave it cuts (43 ms at 4.5k
## triangles, 130 ms at 13k), so the block is cut in chunks (big 4 x 4, small 2 x 2) and a stamp re-cuts only the chunks
## it reaches: the cost of a stroke does not grow with the cave. A stamp shows at once as a see-through mark in its
## stroke's colour; the cut follows at the next flush (small: a few times a second; big: every 1.5 s and when the stroke
## ends).
##
## The cave a body sees and walks on is one MeshInstance3D per chunk and ONE StaticBody3D with a CollisionShape3D per
## chunk (the baked trimesh, back faces colliding), on layer 1 (a body walks on it) and layer 21 (the pointables, which
## both the desktop crosshair and the VR pointer reach; not 23, the VR pointer's suppress layer); the body carries a user
## signal pointer_event, which XRToolsPointerEvent.report() emits on whatever the ray hit. A stroke belongs to the pointer
## that pressed (two hands can each have one, not both at once); a position is painted only where a ray really meets the
## cave (a held desktop press reports camera-plane points off the block).
##
## UNDO returns to the cave as it was before the last stroke (the last ten strokes keep a snapshot; older ones are
## rebuilt from the block). What is painted is kept (export keep): every stamp is saved to
## user://boolean_cave/<key>.json when a stroke ends and replayed, in batches a frame apart, when the floor loads.

const SIZES := ["small", "big"]
const VERBS := ["carve", "build"]
const SHAPES := ["sphere", "cube", "cylinder"]
const SPEC := {
	"small": {"block": Vector3(1.0, 0.7, 1.0), "lift": 0.82, "radius": [0.04, 0.16], "segments": [10, 6], "rate": 10.0,
		"flush": 0.35, "chunks": Vector2i(2, 2), "console": Vector3(-0.55, 0.0, 0.95), "grounded": false},
	"big": {"block": Vector3(7.6, 4.2, 7.0), "lift": 0.0, "radius": [0.55, 1.5], "segments": [12, 7], "rate": 4.0,
		"flush": 1.5, "chunks": Vector2i(4, 4), "console": Vector3(-2.4, 0.0, 4.35), "grounded": true},
}
const DRILL := 0.33                   # how much further along the aim a stamp may go than the last, in radii
const SNAPSHOTS := 10                 # strokes UNDO can step back through without rebuilding
const BATCH := 12                     # stamps cut in per frame when a cave is rebuilt or loaded
const HOLD := 0.2                     # seconds without a pointer event before a held brush drills on its own
const STALE := 10.0                   # seconds without a pointer event after which a stroke is over
const FLOOR := 0.04                   # a big carve's floor over the slab: block material, in the stroke's colour
const HEADROOM := 2.2                 # a big carve is never lower than this, so a body fits where it carved
const POINTABLE := 1 << 20            # layer 21: what the crosshair and the VR pointer reach
const SATIN := Color(0.7, 0.7, 0.8)   # advanced_carver.gd's block: albedo 0.7 0.7 0.8, metallic 0.3, roughness 0.7
const HUES := [Color(0.62, 0.30, 0.92), Color(0.86, 0.22, 0.52), Color(0.30, 0.42, 0.95), Color(0.20, 0.78, 0.72),
	Color(0.95, 0.52, 0.20), Color(0.95, 0.85, 0.30), Color(0.40, 0.85, 0.35), Color(0.98, 0.45, 0.45)]

@export_enum("small", "big") var size := "small"
@export_enum("carve", "build") var verb := "carve"
@export_enum("sphere", "cube", "cylinder") var shape := "sphere"
## The brush's radius as a fraction of the size's range (0 the smallest, 1 the largest).
@export_range(0.0, 1.0) var brush := 0.4
## Keep what is painted: saved after each stroke to user://boolean_cave/, replayed when the floor loads.
@export var keep := true

var _cave: CSGCombiner3D            # the calculator: empty but for the length of one cut
var _view: Node3D                    # the chunks as they are drawn
var _solid: StaticBody3D             # the cave as a body meets it, and as the pointer hits it
var _chunks: Array = []              # {lo, hi, clip_lo, clip_hi, mesh, shape, view, col}
var _queue: Array = []               # stamps painted but not yet cut in
var _snapshots: Array = []           # {meshes, shapes, stamps, strokes} at each stroke's end
var _trail: Node3D
var _stamps: Array = []              # every stamp applied, in order: {c, a (axis), v, s, r, k (stroke)}
var _ghost_key := ""
var _stroke := -1
var _strokes := 0
var _painting := false
var _pointer: Node3D                 # the pointer whose stroke it is
var _last_hit := Vector3.INF
var _last_centre := Vector3.INF
var _last_time := -1.0
var _last_event := 0.0               # when the stroke's pointer last reported
var _last_flush := 0.0
var _ghost: MeshInstance3D
var _label: Label3D
var _buttons := {}
var _materials := {}
var _built := ""
var _loading := false
var _key := ""


func _ready() -> void:
	for key in ["size", "verb", "shape", "brush", "keep"]:
		if has_meta("config_" + key): _take({key: get_meta("config_" + key)})
	_build()


func _take(config: Dictionary) -> void:
	if config.has("size") and str(config["size"]) in SIZES: size = str(config["size"])
	if config.has("verb") and str(config["verb"]) in VERBS: verb = str(config["verb"])
	if config.has("shape") and str(config["shape"]) in SHAPES: shape = str(config["shape"])
	if config.has("brush"): brush = clampf(float(str(config["brush"])), 0.0, 1.0)
	if config.has("keep"): keep = str(config["keep"]).to_lower() in ["true", "1", "1.0", "on", "yes"]


func apply_grid_config(config: Dictionary) -> void:
	_take(config)
	if is_inside_tree(): _build()
	else: _refresh_label()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _build() -> void:
	if _built == size:
		_refresh_label()
		return
	for child in get_children(): child.queue_free()
	_queue.clear()
	_snapshots.clear()
	_chunks.clear()
	_stamps.clear()
	_strokes = 0
	var spec: Dictionary = SPEC[size]
	var block: Vector3 = spec.block
	if size == "small":
		var stand := MeshInstance3D.new()
		var leg := BoxMesh.new()
		leg.size = Vector3(block.x * 0.7, float(spec.lift), block.z * 0.7)
		stand.mesh = leg
		stand.position = Vector3(0, float(spec.lift) * 0.5, 0)
		stand.material_override = _satin()
		stand.name = "Stand"
		add_child(stand)
		var foot := StaticBody3D.new()
		var holder := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = leg.size
		holder.shape = box
		foot.add_child(holder)
		foot.position = stand.position
		add_child(foot)
	var frame := Vector3(0, float(spec.lift), 0)
	_cave = CSGCombiner3D.new()
	_cave.name = "Calculator"
	_cave.visible = false
	_cave.use_collision = false
	_cave.position = frame
	add_child(_cave)
	_view = Node3D.new()
	_view.name = "Cave"
	_view.position = frame
	add_child(_view)
	_solid = StaticBody3D.new()
	_solid.name = "CaveBody"
	_solid.collision_layer = 1 | POINTABLE
	_solid.collision_mask = 0
	_solid.position = frame
	_solid.add_user_signal("pointer_event", [{"name": "event", "type": TYPE_OBJECT}])
	_solid.connect("pointer_event", pointer_event)
	add_child(_solid)
	_make_chunks(spec)
	_trail = Node3D.new()
	_trail.name = "Trail"
	add_child(_trail)
	_ghost = MeshInstance3D.new()
	_ghost.name = "Brush"
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ghost.visible = false
	add_child(_ghost)
	_build_console(spec)
	_built = size
	_key = _save_key()
	_snapshot()
	_refresh_label()
	if keep: _load.call_deferred()


## The block cut into cells. A cell on the block's outside is clipped a brush's radius further out, so a build at the
## edge is not cut off; inside, neighbouring cells meet on one plane.
func _make_chunks(spec: Dictionary) -> void:
	var block: Vector3 = spec.block
	var n: Vector2i = spec.chunks
	var r_max := float(spec.radius[1])
	for i in n.x:
		for j in n.y:
			var lo := Vector3(-block.x * 0.5 + block.x * i / n.x, 0.0, -block.z * 0.5 + block.z * j / n.y)
			var hi := Vector3(-block.x * 0.5 + block.x * (i + 1) / n.x, block.y, -block.z * 0.5 + block.z * (j + 1) / n.y)
			var clip_lo := Vector3(lo.x - (r_max if i == 0 else 0.0), lo.y - r_max, lo.z - (r_max if j == 0 else 0.0))
			var clip_hi := Vector3(hi.x + (r_max if i == n.x - 1 else 0.0), hi.y + r_max, hi.z + (r_max if j == n.y - 1 else 0.0))
			var view := MeshInstance3D.new()
			view.name = "Chunk_%d_%d" % [i, j]
			_view.add_child(view)
			var col := CollisionShape3D.new()
			col.name = view.name
			_solid.add_child(col)
			var chunk := {"lo": lo, "hi": hi, "clip_lo": clip_lo, "clip_hi": clip_hi, "mesh": null, "shape": null, "view": view, "col": col,
				"block_mesh": null, "block_shape": null}
			var out := _compute(chunk, [])
			chunk.block_mesh = out[0]
			chunk.block_shape = out[1]
			_show_chunk(chunk, out[0], out[1])
			_chunks.append(chunk)


func _reset_block() -> void:
	for chunk in _chunks: _show_chunk(chunk, chunk.block_mesh, chunk.block_shape)


func _show_chunk(chunk: Dictionary, mesh: ArrayMesh, shape: Shape3D) -> void:
	chunk.mesh = mesh
	chunk.shape = shape
	(chunk.view as MeshInstance3D).mesh = mesh
	(chunk.col as CollisionShape3D).shape = shape


## ---- the brush ----

func radius() -> float:
	var r: Array = SPEC[size].radius
	return lerpf(float(r[0]), float(r[1]), brush)


## The pointer's events, desktop and VR alike: hover shows the brush, a press starts a stroke, a held move paints. A
## stroke is its pointer's: another pointer's events do not paint into it.
func pointer_event(event: Variant) -> void:
	if event == null or _loading: return
	var who: Node3D = event.pointer
	var mine := not _painting or who == _pointer
	match int(event.event_type):
		XRToolsPointerEvent.Type.ENTERED, XRToolsPointerEvent.Type.MOVED:
			var from := _origin(who, event.position)
			var at := _surface(from, event.position)
			if at != Vector3.INF and mine: _show_ghost(at, (at - from).normalized())
			if _painting and who == _pointer:
				_last_event = _now()
				if at != Vector3.INF: _paint(at, (at - from).normalized(), from)
		XRToolsPointerEvent.Type.PRESSED:
			if _painting: return
			var from := _origin(who, event.position)
			var at := _surface(from, event.position)
			_pointer = who
			begin_stroke()
			if at != Vector3.INF: _paint(at, (at - from).normalized(), from)
		XRToolsPointerEvent.Type.RELEASED:
			if _painting and who == _pointer: end_stroke()
		XRToolsPointerEvent.Type.EXITED:
			# in VR the ray can leave the block's edge mid-stroke while the press stays on: only the brush is hidden
			if mine: _ghost.visible = false


func _origin(who: Node3D, at: Vector3) -> Vector3:
	return who.global_position if is_instance_valid(who) else at + global_basis.z


## Where a ray from `from` through `toward` meets the cave, or INF: a held desktop press reports camera-plane points
## when the crosshair leaves the block, and those are not painted.
func _surface(from: Vector3, toward: Vector3) -> Vector3:
	var dir := toward - from
	if dir.length() < 0.001: return Vector3.INF
	var q := PhysicsRayQueryParameters3D.create(from, from + dir.normalized() * (dir.length() + 0.5), POINTABLE)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or hit.collider != _solid: return Vector3.INF
	return hit.position


func begin_stroke() -> void:
	_painting = true
	_stroke = _strokes
	_strokes += 1
	_last_hit = Vector3.INF
	_last_centre = Vector3.INF
	_last_time = -1.0
	_last_event = _now()


func end_stroke() -> void:
	if not _painting: return
	_painting = false
	_pointer = null
	_flush()
	_snapshot()
	if keep: _save()
	_refresh_label()


## A brush held still keeps drilling at its rate - held still meaning the stroke's pointer has reported nothing for HOLD
## seconds and still aims where it last painted (a desktop pointer sends nothing while the mouse rests); between a moving
## stroke's events it does not (measured in the tower: drilling between events took the stamps of a moving stroke and
## made one deep hole instead of a groove). A stroke whose pointer has gone quiet for STALE seconds is over. And the queue
## is cut in on time.
func _process(_delta: float) -> void:
	var now := _now()
	if _painting:
		if now - _last_event >= STALE or not is_instance_valid(_pointer):
			end_stroke()
		elif _last_hit != Vector3.INF and now - _last_event >= HOLD:
			var from := _pointer.global_position
			var to_hit := (_last_hit - from).normalized()
			if to_hit.dot(-_pointer.global_basis.z) > 0.99 or not _pointer is XRToolsFunctionPointer:
				_paint(_last_hit, to_hit, from)
	if not _queue.is_empty() and not _loading and now - _last_flush >= float(SPEC[size].flush):
		_flush()


## One step of a stroke, at most at the brush's rate. Moved across the surface, a stamp lands where the ray meets it;
## held still, it DRILLS: the next stamp DRILL radii further along the aim than the last. No stamp goes further past the
## last than that (measured on the bench: a stamp that followed its own receding surface tunnelled through the 7 m block
## in four stamps, half a second).
func _paint(at: Vector3, aim: Vector3, from: Vector3) -> void:
	var r := radius()
	var now := _now()
	if _last_time >= 0.0 and now - _last_time < 1.0 / float(SPEC[size].rate): return
	var centre := at + aim * r * (0.55 if verb == "carve" else -0.2)
	if _last_centre != Vector3.INF:
		var lateral := (at - _last_hit) - aim * (at - _last_hit).dot(aim)
		if lateral.length() < r * 0.25:
			if verb == "build": return                 # a build held still does not pile up toward the builder
			centre = _last_centre + aim * r * DRILL
		else:
			var advance := (centre - _last_centre).dot(aim)
			if advance > r * DRILL: centre -= aim * (advance - r * DRILL)
	if verb == "build" and centre.distance_to(from) < r + 0.6: return    # never build over the one who builds
	stamp(_cave.to_local(centre), verb, shape, r, _stroke, _cave.global_basis.inverse() * aim)
	_last_hit = at
	_last_centre = centre
	_last_time = now


## One boolean, in the cave's frame (also the replay's and a probe's way in): queued, marked at once in its stroke's
## colour, cut in at the next flush. Returns its record.
func stamp(c: Vector3, v: String, s: String, r: float, k: int, axis := Vector3.FORWARD) -> Dictionary:
	var block: Vector3 = SPEC[size].block
	var lo := Vector3(-block.x * 0.5, 0, -block.z * 0.5) - Vector3.ONE * r
	var hi := Vector3(block.x * 0.5, block.y, block.z * 0.5) + Vector3.ONE * r
	c = c.clamp(lo, hi)
	var rec := {"c": [snappedf(c.x, 0.001), snappedf(c.y, 0.001), snappedf(c.z, 0.001)],
		"a": [snappedf(axis.x, 0.001), snappedf(axis.y, 0.001), snappedf(axis.z, 0.001)], "v": v, "s": s,
		"r": snappedf(r, 0.001), "k": k}
	_stamps.append(rec)
	_queue.append(rec)
	if not _loading: _mark(rec)
	return rec


## A stamp's reach in the cave's frame (an axis-aligned box that holds every operand it is made of).
func _reach(rec: Dictionary) -> AABB:
	var c := Vector3(rec.c[0], rec.c[1], rec.c[2])
	var r := float(rec.r) * (1.5 if str(rec.s) == "cylinder" else 1.0) + 0.01
	if SPEC[size].grounded and rec.v == "carve":
		c.y = maxf(c.y, HEADROOM - float(rec.r))
		return AABB(Vector3(c.x - r, 0.0, c.z - r), Vector3(2.0 * r, c.y + r, 2.0 * r))
	return AABB(c - Vector3.ONE * r, Vector3.ONE * 2.0 * r)


## The CSG node(s) one stamp is made of. A big CARVE stands its shape on the floor: the shape at the aim, and the same
## section down to FLOOR, at least HEADROOM tall - so a carved cave is a place to walk, not a hole in a wall.
func _operands(rec: Dictionary) -> Array:
	var c := Vector3(rec.c[0], rec.c[1], rec.c[2])
	var r := float(rec.r)
	var op := CSGShape3D.OPERATION_SUBTRACTION if rec.v == "carve" else CSGShape3D.OPERATION_UNION
	var mat := _stroke_material(int(rec.k))
	var seg: Array = SPEC[size].segments
	var nodes := []
	var grounded: bool = SPEC[size].grounded and rec.v == "carve"
	if grounded: c.y = maxf(c.y, HEADROOM - r)
	match str(rec.s):
		"sphere":
			var ball := CSGSphere3D.new()
			ball.radius = r
			ball.radial_segments = int(seg[0])
			ball.rings = int(seg[1])
			ball.position = c
			nodes.append(ball)
			if grounded:
				var post := CSGCylinder3D.new()
				post.radius = r
				post.sides = int(seg[0])
				post.height = c.y - FLOOR
				post.position = Vector3(c.x, FLOOR + post.height * 0.5, c.z)
				nodes.append(post)
		"cube":
			var cube := CSGBox3D.new()
			if grounded:
				var top := c.y + r
				cube.size = Vector3(2.0 * r, top - FLOOR, 2.0 * r)
				cube.position = Vector3(c.x, FLOOR + (top - FLOOR) * 0.5, c.z)
			else:
				cube.size = Vector3.ONE * 2.0 * r
				cube.position = c
			nodes.append(cube)
		_:
			var drum := CSGCylinder3D.new()
			drum.radius = r
			drum.sides = int(seg[0])
			if grounded:
				var top := c.y + r
				drum.height = top - FLOOR
				drum.position = Vector3(c.x, FLOOR + drum.height * 0.5, c.z)
			else:
				# a drill: its axis along the aim
				var a := Vector3(rec.a[0], rec.a[1], rec.a[2])
				if a.length() < 0.5: a = Vector3.FORWARD
				a = a.normalized()
				var side := a.cross(Vector3.UP if absf(a.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT).normalized()
				drum.height = 2.0 * r
				drum.transform = Transform3D(Basis(side, a, side.cross(a)).orthonormalized(), c)
			nodes.append(drum)
	for node in nodes:
		node.operation = op
		node.material = mat
	return nodes


## Cut the queued stamps in: each chunk they reach, once, with all of them.
func _flush() -> void:
	_last_flush = _now()
	_clear_trail()
	if _queue.is_empty(): return
	for chunk in _chunks:
		var cell := AABB(chunk.clip_lo, chunk.clip_hi - chunk.clip_lo)
		var mine := _queue.filter(func(rec): return _reach(rec).intersects(cell))
		if chunk.mesh == null and chunk.block_mesh != null:
			# carved away entirely: a carve has nothing to take from, and CSG would read a first carve as a solid -
			# so an empty chunk takes the stamps from its first build on
			var first_build := -1
			for i in mine.size():
				if mine[i].v == "build":
					first_build = i
					break
			mine = mine.slice(first_build) if first_build >= 0 else []
		if mine.is_empty(): continue
		var out := _compute(chunk, mine)
		_show_chunk(chunk, out[0], out[1])
	_queue.clear()


## The calculator: one chunk as it is (or its cell of the block), these stamps and the chunk's own cell, ONE forced pass,
## baked to a mesh and a collision shape; then it is emptied, so the pass it would run at the end of the frame finds
## nothing to do. The rebuild is forced because bake_static_mesh() returns the mesh the combiner HAS (measured: a stamp
## added in the same frame was missing from it); _update_shape is bound in 4.6. A chunk carved away entirely is empty
## (no mesh, no shape) until a build reaches into it.
func _compute(chunk: Dictionary, recs: Array) -> Array:
	if chunk.mesh == null and chunk.block_mesh == null:
		var box := CSGBox3D.new()
		box.size = chunk.hi - chunk.lo
		box.position = (chunk.lo + chunk.hi) * 0.5
		box.material = _satin()
		_cave.add_child(box)
	elif chunk.mesh != null:
		var cut := CSGMesh3D.new()
		cut.mesh = chunk.mesh
		_cave.add_child(cut)
	for rec in recs:
		for node in _operands(rec): _cave.add_child(node)
	var clip := CSGBox3D.new()
	clip.size = chunk.clip_hi - chunk.clip_lo
	clip.position = (chunk.clip_lo + chunk.clip_hi) * 0.5
	clip.operation = CSGShape3D.OPERATION_INTERSECTION
	_cave.add_child(clip)
	_cave.call("_update_shape")
	var mesh: ArrayMesh = _cave.bake_static_mesh()
	var shape: Shape3D = _cave.bake_collision_shape()
	for child in _cave.get_children(): child.free()
	if mesh == null or mesh.get_surface_count() == 0: return [null, null]
	if shape is ConcavePolygonShape3D: (shape as ConcavePolygonShape3D).backface_collision = true
	return [mesh, shape]


func _snapshot() -> void:
	var meshes := []
	var shapes := []
	for chunk in _chunks:
		meshes.append(chunk.mesh)
		shapes.append(chunk.shape)
	_snapshots.append({"meshes": meshes, "shapes": shapes, "stamps": _stamps.size(), "strokes": _strokes})
	while _snapshots.size() > SNAPSHOTS + 1: _snapshots.pop_front()


## Take the last stroke back: to the snapshot taken before it, else rebuilt from the block without it.
func undo() -> void:
	if _stamps.is_empty() or _loading or _painting: return
	_flush()
	var last := int(_stamps.back().k)
	var rest := _stamps.filter(func(s): return int(s.k) != last)
	var found := -1
	for i in range(_snapshots.size() - 1, -1, -1):
		if int(_snapshots[i].stamps) == rest.size():
			found = i
			break
	if found >= 0:
		for i in _chunks.size(): _show_chunk(_chunks[i], _snapshots[found].meshes[i], _snapshots[found].shapes[i])
		_snapshots.resize(found + 1)
		_stamps = rest
	else:
		await _replay(rest)
	_strokes = maxi(0, last)
	if keep: _save()
	_refresh_label()


func reset() -> void:
	if _loading: return
	await _replay([])
	_strokes = 0
	if keep: _save()
	_refresh_label()


## Rebuild from the block: every stamp again, BATCH a frame (a long cave does not stall the floor's arrival).
func _replay(stamps: Array) -> void:
	_loading = true
	_painting = false
	_queue.clear()
	_clear_trail()
	_stamps.clear()
	_reset_block()
	_snapshots.clear()
	for rec in stamps:
		_stamps.append(rec)
		_queue.append(rec)
		if _queue.size() >= BATCH:
			_flush()
			await get_tree().process_frame
			if not is_inside_tree(): return
	_flush()
	_strokes = 0
	for rec in _stamps: _strokes = maxi(_strokes, int(rec.k) + 1)
	_snapshot()
	_loading = false


## A painted stamp's mark until it is cut in: its shape, see-through, in its stroke's colour.
func _mark(rec: Dictionary) -> void:
	var r := float(rec.r)
	var m: Mesh
	match str(rec.s):
		"sphere":
			var sm := SphereMesh.new()
			sm.radius = r
			sm.height = 2.0 * r
			sm.radial_segments = 12
			sm.rings = 6
			m = sm
		"cube":
			var bm := BoxMesh.new()
			bm.size = Vector3.ONE * 2.0 * r
			m = bm
		_:
			var cm := CylinderMesh.new()
			cm.top_radius = r
			cm.bottom_radius = r
			cm.height = 2.0 * r
			m = cm
	var mark := MeshInstance3D.new()
	mark.mesh = m
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mark.material_override = _mark_material(int(rec.k))
	_trail.add_child(mark)
	mark.global_position = _cave.to_global(Vector3(rec.c[0], rec.c[1], rec.c[2]))
	mark.global_basis = _cave.global_basis


func _clear_trail() -> void:
	if _trail == null: return
	for child in _trail.get_children(): child.queue_free()


## ---- the console ----

func _build_console(spec: Dictionary) -> void:
	var desk := Node3D.new()
	desk.name = "Console"
	desk.position = spec.console
	add_child(desk)
	var panel := MeshInstance3D.new()
	var face := BoxMesh.new()
	face.size = Vector3(1.1, 0.62, 0.04)
	panel.mesh = face
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	panel.material_override = dark
	panel.position = Vector3(0, 1.0, 0)
	panel.rotation.x = -0.45
	desk.add_child(panel)
	var post := MeshInstance3D.new()
	var rod := BoxMesh.new()
	rod.size = Vector3(0.06, 0.9, 0.06)
	post.mesh = rod
	post.position = Vector3(0, 0.45, 0)
	post.material_override = _satin()
	desk.add_child(post)
	_label = Label3D.new()
	_label.pixel_size = 0.0014
	_label.font_size = 30
	_label.outline_size = 4
	_label.width = 720
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.position = Vector3(0, 0.2, 0.03)
	panel.add_child(_label)
	var rows := [[["carve", "CARVE"], ["build", "BUILD"]], [["sphere", "SPHERE"], ["cube", "CUBE"], ["cylinder", "CYLINDER"]],
		[["smaller", "SMALLER"], ["bigger", "BIGGER"], ["undo", "UNDO"], ["reset", "RESET"]]]
	for row in rows.size():
		var n: int = rows[row].size()
		for i in n:
			var key: String = rows[row][i][0]
			var b := _button(key, rows[row][i][1], Vector3((float(i) - (n - 1) * 0.5) * 0.25, 0.04 - row * 0.115, 0.03))
			panel.add_child(b)
			_buttons[key] = b


## A button the crosshair and the VR pointer both press: a pointable body (layer 21) carrying the pointer_event signal.
func _button(key: String, text: String, at: Vector3) -> Node3D:
	var body := StaticBody3D.new()
	body.name = "Button_" + key
	body.collision_layer = POINTABLE
	body.collision_mask = 0
	body.position = at
	var holder := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.23, 0.095, 0.04)
	holder.shape = box
	body.add_child(holder)
	var cap := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box.size
	cap.mesh = mesh
	cap.name = "Cap"
	body.add_child(cap)
	var label := Label3D.new()
	label.text = text
	label.font_size = 26
	label.pixel_size = 0.0012
	label.position = Vector3(0, 0, 0.022)
	label.outline_size = 3
	body.add_child(label)
	body.add_user_signal("pointer_event", [{"name": "event", "type": TYPE_OBJECT}])
	body.connect("pointer_event", func(event): if event != null and int(event.event_type) == XRToolsPointerEvent.Type.PRESSED: press(key))
	return body


## What a console button does (also a probe's way in).
func press(key: String) -> void:
	match key:
		"carve", "build": verb = key
		"sphere", "cube", "cylinder": shape = key
		"smaller": brush = clampf(brush - 0.2, 0.0, 1.0)
		"bigger": brush = clampf(brush + 0.2, 0.0, 1.0)
		"undo": undo()
		"reset": reset()
	_refresh_label()


func _refresh_label() -> void:
	if _label == null: return
	_label.text = "PAINT YOUR OWN CAVE\n%s with a %s, %d cm   -   %d strokes, %d booleans" % [
		"DIFFERENCE: carve" if verb == "carve" else "UNION: build", shape, roundi(radius() * 100.0), _strokes, _stamps.size()]
	for key in _buttons:
		var on: bool = key == verb or key == shape
		var cap: MeshInstance3D = _buttons[key].get_node("Cap")
		cap.material_override = _button_material(on)


func _button_material(on: bool) -> StandardMaterial3D:
	var key := "button_on" if on else "button_off"
	if _materials.has(key): return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.95, 0.52, 0.2) if on else Color(0.32, 0.33, 0.38)
	m.emission_enabled = on
	m.emission = Color(0.95, 0.52, 0.2) * 0.4
	_materials[key] = m
	return m


func _show_ghost(at: Vector3, aim: Vector3) -> void:
	var r := radius()
	_ghost.global_position = at + aim * r * (0.55 if verb == "carve" else -0.2)
	_ghost.global_basis = _cave.global_basis
	_ghost.visible = true
	var key := "%s|%.3f|%d" % [shape, r, _strokes % HUES.size()]
	if key == _ghost_key: return
	_ghost_key = key
	var m: Mesh
	match shape:
		"sphere":
			var s := SphereMesh.new()
			s.radius = r
			s.height = 2.0 * r
			m = s
		"cube":
			var b := BoxMesh.new()
			b.size = Vector3.ONE * 2.0 * r
			m = b
		_:
			var cy := CylinderMesh.new()
			cy.top_radius = r
			cy.bottom_radius = r
			cy.height = 2.0 * r
			m = cy
	_ghost.mesh = m
	var paint := StandardMaterial3D.new()
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = Color(HUES[_strokes % HUES.size()], 0.28 if size == "small" else 0.16)   # a metre-wide brush, fainter
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	paint.no_depth_test = true
	_ghost.material_override = paint


## ---- materials ----

func _satin() -> StandardMaterial3D:
	if _materials.has("satin"): return _materials["satin"]
	var m := StandardMaterial3D.new()
	m.albedo_color = SATIN
	m.metallic = 0.3
	m.roughness = 0.7
	_materials["satin"] = m
	return m


## One material per hue, shared by every stroke of that hue: a baked chunk carries at most nine surfaces.
func _stroke_material(k: int) -> StandardMaterial3D:
	var hue: Color = HUES[posmod(k, HUES.size())]
	var key := "stroke_%d" % posmod(k, HUES.size())
	if _materials.has(key): return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = hue
	m.roughness = 0.45
	m.metallic = 0.15
	m.emission_enabled = true
	m.emission = hue * 0.18
	_materials[key] = m
	return m


func _mark_material(k: int) -> StandardMaterial3D:
	var key := "mark_%d" % posmod(k, HUES.size())
	if _materials.has(key): return _materials[key]
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(HUES[posmod(k, HUES.size())], 0.4)
	_materials[key] = m
	return m


## ---- keeping what is painted ----

func _save_key() -> String:
	var parts := []
	var node: Node = self
	for i in 3:
		node = node.get_parent()
		if node == null: break
		parts.push_front(str(node.name))
	return "_".join(parts).validate_filename() + "_" + size


func _save() -> void:
	DirAccess.make_dir_recursive_absolute("user://boolean_cave")
	var file := FileAccess.open("user://boolean_cave/%s.json" % _key, FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify({"size": size, "stamps": _stamps}))
	file.close()


func _load() -> void:
	var path := "user://boolean_cave/%s.json" % _key
	if not FileAccess.file_exists(path): return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary) or str(data.get("size", "")) != size: return
	await _replay(data.get("stamps", []))
	_refresh_label()


## ---- for a test ----

func state() -> Dictionary:
	var tris := 0
	var carved := false
	for chunk in _chunks:
		if chunk.mesh != chunk.block_mesh: carved = true
		var m: ArrayMesh = chunk.mesh
		if m == null: continue
		for s in m.get_surface_count():
			var n := m.surface_get_array_index_len(s)
			tris += (n if n > 0 else m.surface_get_array_len(s)) / 3
	return {"size": size, "verb": verb, "shape": shape, "radius": snappedf(radius(), 0.001), "stamps": _stamps.size(),
		"strokes": _strokes, "queued": _queue.size(), "live": _cave.get_child_count(), "snapshots": _snapshots.size(),
		"carved": carved, "chunks": _chunks.size(), "triangles": tris, "key": _key}


## What a pointer hits (the cave's body), and the cave's meshes now.
func cave() -> StaticBody3D:
	return _solid


func cave_meshes() -> Array:
	return _chunks.map(func(c): return c.mesh).filter(func(m): return m != null)
