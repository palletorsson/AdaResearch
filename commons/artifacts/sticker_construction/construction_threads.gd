extends "res://commons/artifacts/sticker_board/sticker_threads.gd"
## THE THREADS OF A CONSTRUCTION, drawn in the construction's frame (a child of sticker_construction.gd, beside its
## walls): every thread a wall holds within itself (drawn_threads, as a board draws its own) and every thread tied
## between two of its walls (drawn_wall_threads), with what the board's threads draw - the tube along thread_curve in
## the thread's colour (the agreed colour thicker), 16 chords and 8 sides, its word on a tag, a red pin head at each end
## - so a thread on a wall reads as a thread on a board. This node extends sticker_threads.gd and keeps its tube, tag,
## mesh and material code; only what is drawn and where differs:
##   - A THREAD NEVER PASSES THROUGH CARDBOARD (stickers.ts overWalls, overBoard, threadPieces; ported in
##     sticker_data.gd). A thread BETWEEN WALLS runs from pin to pin as drawn_wall_threads gives them (wall_point of
##     pin_of, the construction's frame) over every wall in its way, by the points it gives (`over`: two over each wall,
##     THREAD_CLEAR off its near and far face, THREAD_OVER above its top edge). A WALL'S OWN thread runs from pin to pin
##     (pin_of of each sticker as the wall draws it, on its front or its back) in the wall's board frame, and one that
##     joins the two faces goes over the wall's top edge by over_board's points in that frame; its pins and points are
##     carried into the construction's frame by wall_point (the board frame is only turned about +Y and moved, so the
##     curve of the carried points is the carried curve: its sag is still along -Y). Either is drawn in PIECES, [p,
##     ...over, q] pairwise (thread_pieces), each a tube along its own thread_curve, a ball of the string's radius where
##     two pieces meet (it closes the bend over the edge, as hang3d.ts does), its word on a tag at the middle (u = 0.5)
##     of the longest piece. A thread no wall stands in the way of is the one curve it always was.
##   - each PIN end is lifted off its face as a board lifts a string off its paper (LIFT + r + 0.5 mm, sticker_threads.gd
##     _off_paper), along that face's outward normal in the construction's frame - +Z of the wall's board frame for a
##     front sticker, -Z for a back one - and the lift runs along its piece to nothing at the piece's other end when that
##     is a point over an edge, where the string is the contract's own (THREAD_CLEAR off the cardboard, THREAD_OVER over
##     it). So no tube cuts into the cardboard at its pins, and every ring stays within 6.5 mm of the contract's curve.
##   - a tag: flat on a face, facing out, when the tag piece's two ends stand on faces turned the same way and its middle
##     runs along them (within TAG_ALONG of both faces' planes: a wall's own thread, two walls side by side, a piece that
##     runs up a face to the edge it goes over). An end stands on the face of its sticker, or, at a point over an edge, on
##     the face it is THREAD_CLEAR off (cardboard3d.ts endFaces). A tag ON a face lies FLAT on it (FLAT_CARD_SHADER, the
##     board's card unbillboarded): a billboard 12 mm off the cardboard turns toward an eye behind the wall and its edge
##     passes through 5 mm of board (construction_behind.png, 2026-11-15); the web hides such a tag from the far side
##     instead (cardboard3d.ts tagSeen). A tag whose piece is the hop over an edge stands ABOVE its string, clear of the
##     cardboard under it; any other hangs below its string's middle, in the open between the walls, a billboard.
## A thread whose end is on a wall this construction does not stand (its board gone, or not cardboard) is not drawn.
## STAGED: drawn again when the placements, the designs, the boards or the constructions change, and only when what it
## is made of changed - a thread a piece of work, within the frame's budget shared with the walls' layers
## (sticker_layer.gd stage_may, stage_spent); the strings shown are the last ones made until the new ones are all made
## (busy() says so). For probes: Strings carries metas ids, ranges (each thread's [first vertex, count], its pieces'
## tubes one after another), rings and sides (each piece's tube), pieces (thread id -> how many) and kinds ("wall" or
## "between" per id); Joints is a MultiMesh of the balls; drawn_ids, rebuild_ms (all of a pass's pieces) and redraws.

const TAG_ALONG := 0.016           # a thread "runs along" its faces when its middle is this close to both (hang3d.ts TAG_LIFT)
## A tag's card as the board's (CARD_SHADER: paper, an edge, a punched hole the face shows through) but lying in its own
## plane, front side only.
const FLAT_CARD_SHADER := """shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;
uniform vec3 paper : source_color = vec3(0.965, 0.941, 0.886);
uniform vec3 edge : source_color = vec3(0.733, 0.663, 0.522);
uniform vec3 hole : source_color = vec3(0.788, 0.663, 0.471);
instance uniform vec2 card_size = vec2(0.2, 0.05);
varying vec2 local;
void vertex() {
	local = VERTEX.xy;
}
void fragment() {
	vec2 h = card_size * 0.5;
	float rim = 0.0012;
	vec3 c = paper;
	if (abs(local.x) > h.x - rim || abs(local.y) > h.y - rim) { c = edge; }
	if (distance(local, vec2(-h.x + h.y * 0.75, 0.0)) < h.y * 0.3) { c = hole; }
	ALBEDO = c;
}
"""
const FLAT_CARD_BEHIND := 0.0005   # a flat card lies this far behind its word (toward the face)

var construction_id := ""
var kinds: Dictionary = {}         # thread id -> "wall" | "between"
var pieces_of: Dictionary = {}     # thread id -> how many pieces it is drawn in (1: the one curve)
var flat_tags := 0                 # tags laid on a face (the rest hang in the open), for probes
var stage_usec := 0                # what this node's staged pieces have cost in all (probes)
var stage_pieces := 0
var _flat_mat: ShaderMaterial = null
var _queue: Array = []             # the pass still to draw: [kind, arg] - "look", "plan", "thread" (an item), "commit"
var _replan := false
var _pass: Dictionary = {}         # the pass being drawn (_plan): its sig, what its threads have made so far
var _pass_usec := 0                # what the pass being drawn has cost so far
## The look every construction's threads share, made once a session and one piece a frame ("look"): the tags' two
## shaders (a Shader made from code costs 8 to 11 ms on this desktop, the same code made again as much: measured
## 2026-11-15), their font (its first use 3 ms) and the strings', rods' and pins' materials.
static var _shared: Dictionary = {}

func _ready() -> void:
	super()
	if data != null and data.has_signal("constructions_changed"):
		data.constructions_changed.connect(_again)

## Draw the construction's threads again when anything they are made from changed: planned, and drawn a piece at a time.
func redraw() -> void:
	if data == null or not data.has_method("wall_threads") or not data.has_method("construction"):
		return
	_replan = true
	set_process(true)

## Whether a pass is still being drawn (what is shown is the last one finished).
func busy() -> bool:
	return _replan or not _queue.is_empty()

func _process(_delta: float) -> void:
	while true:
		if _replan:
			_replan = false
			_queue.push_front(["plan", null])
			if _font == null:
				_queue.push_front(["look", null])   # the materials and the font's first use (3 ms), a piece of their own
		if _queue.is_empty():
			set_process(false)
			return
		var piece: Array = _queue[0]
		var kind := str(piece[0])
		if not StickerLayer.stage_may("threads_" + kind):
			return
		_queue.pop_front()
		var t0 := Time.get_ticks_usec()
		var what := ""
		match kind:
			"look":
				what = _warm_look()
				if what != "":
					_queue.push_front(["look", null])   # one shared piece of the look a piece
				else:
					_materials(Color(_paper()))
			"plan":
				_plan()
			"own":
				_plan_own()
			"between":
				_plan_between(piece[1])
			"thread":
				_draw_one(piece[1])
			"commit":
				_commit()
		var spent := Time.get_ticks_usec() - t0
		stage_usec += spent
		stage_pieces += 1
		_pass_usec += spent
		if kind == "commit":
			rebuild_ms = float(_pass_usec) / 1000.0
		StickerLayer.stage_spent("threads_" + kind, spent)
		if spent > 5000 and StickerLayer.stage_slow.size() < 40:
			var arg := what if what != "" else (str((piece[1] as Dictionary).thread.get("id", "")) if piece[1] is Dictionary else "")
			StickerLayer.stage_slow.append(["threads_" + kind, "construction:" + construction_id, arg, snappedf(float(spent) / 1000.0, 0.001)])

## What a pass draws: each wall's own threads, then those between walls, in the truth's order - found in pieces of
## their own ("own", then "between" a few threads at a time: the contract's drawnWallThreads with its over_walls costs
## some 0.3 ms a thread), then drawn a thread a piece. Nothing when what is shown is made of what the truth holds (the
## sig: a hash of the construction, its walls' boards, the stickers on them and the threads between those, and the
## designs' revision); the pass being drawn goes on when it is made of it (a change that changed nothing here).
const BETWEEN_AT_ONCE := 6

func _plan() -> void:
	var c: Dictionary = data.construction(construction_id)
	var walls: Dictionary = {}     # board id -> {wall, table, board, yaw}
	var tables: Dictionary = {}
	var specs: Array = []          # every wall's board as read (a paper board standing in it is in the threads' way too)
	for t in c.get("tables", []):
		tables[str(t.get("id", ""))] = t
	for w in c.get("walls", []):
		var bid := str(w.get("board", ""))
		var b: Dictionary = data.board_spec(bid)
		specs.append(b)
		var t: Variant = tables.get(str(w.get("table", "")))
		if t is Dictionary and StickerData.two_sided(b):
			walls[bid] = {"wall": w, "table": t, "board": b, "yaw": StickerData.wall_yaw(t, w)}
	# the view kept to the walls' stickers and the threads between them: the contract's drawnThreads and
	# drawnWallThreads (ported) read it, and draw what they would draw over the whole view - a thread they draw has both
	# its ends on walls - in a few milliseconds instead of reading every sticker and thread once a wall (13 ms)
	var mine := {"stickers": [], "threads": []}
	var on_walls := {}
	for bid in walls:
		for s in data.stickers_on("board:" + bid):
			(mine.stickers as Array).append(s)
			on_walls[str(s.get("id", ""))] = true
	for t in data.threads:
		if on_walls.has(str(t.get("a", ""))) and on_walls.has(str(t.get("b", ""))):
			(mine.threads as Array).append(t)
	var sig := "%d|%d" % [[int(data.revisions.get("designs", -1)), c, specs, mine.stickers, mine.threads].hash(), (mine.threads as Array).size()]
	if sig == _sig:
		_queue = []
		_pass = {}
		return
	if not _pass.is_empty() and str(_pass.sig) == sig:
		return
	_materials(Color(_paper()))
	_pass_usec = 0
	_pass = {"sig": sig, "c": c, "mine": mine, "walls": walls, "items": [], "between": [], "strings": _Acc.new(), "ids": [], "kinds": {}, "pieces": {},
		"ranges": [], "pinned": {}, "keep": {}, "joints": [], "flat": 0, "card_half": _font.get_height(TAG_FONT) * TAG_PIXEL * 1.3 / 2.0}
	_queue = [["own", null]]
	var tl: Array = mine.threads
	for i in range(0, tl.size(), BETWEEN_AT_ONCE):
		_queue.append(["between", tl.slice(i, i + BETWEEN_AT_ONCE)])
	_queue.append(["between", null])   # the last: the pass's threads queued, in the truth's order

## The walls' own threads of the pass being drawn (drawnThreads over each wall).
func _plan_own() -> void:
	if _pass.is_empty():
		return
	for bid in _pass.walls:
		for e in StickerData.drawn_threads(_pass.mine, bid):
			(_pass.items as Array).append({"thread": e.thread, "a": e.a, "b": e.b, "kind": "wall", "board": bid})

## Some of the threads between walls of the pass being drawn (drawnWallThreads over those threads: each thread is
## drawn or not, and gets its pins and points, by itself); `chunk` null: they are all found, and queued to be drawn.
func _plan_between(chunk: Variant) -> void:
	if _pass.is_empty():
		return
	if chunk == null:
		for it in _pass.items:
			_queue.append(["thread", it])
		for it in _pass.between:
			_queue.append(["thread", it])
		_queue.append(["commit", null])
		return
	var c: Dictionary = _pass.c
	if c.is_empty():
		return
	for e in StickerData.drawn_wall_threads({"stickers": _pass.mine.stickers, "threads": chunk}, c, data.boards, data.designs):
		(_pass.between as Array).append({"thread": e.thread, "a": e.a, "b": e.b, "p": e.p, "q": e.q, "over": e.get("over", []), "kind": "between"})

## The board's look (sticker_threads.gd _materials, the same materials and font) on the session's shared ones; only the
## card's material is this node's own, its punched hole showing this construction's paper.
func _materials(paper: Color) -> void:
	if _string_mat == null:
		while _warm_look() != "":
			pass
		_string_mat = _shared.string
		_rod_mat = _shared.rod
		_pin_mat = _shared.pin
		_font = _shared.font
		_card_mat = ShaderMaterial.new()
		_card_mat.shader = _shared.card
		_card_mat.set_shader_parameter("paper", TAG_PAPER)
		_card_mat.set_shader_parameter("edge", TAG_EDGE)
	_card_mat.set_shader_parameter("hole", paper)

## One piece of the shared look made, when one is still missing: what it made ("" when nothing was missing).
static func _warm_look() -> String:
	if not _shared.has("card"):
		_shared["card"] = _new_shader(CARD_SHADER)
		return "card"
	elif not _shared.has("flat"):
		_shared["flat"] = _new_shader(FLAT_CARD_SHADER)
		return "flat"
	elif not _shared.has("font"):
		var font := FontVariation.new()
		font.base_font = ThemeDB.fallback_font
		font.variation_embolden = 0.55
		font.spacing_glyph = 3
		font.get_height(TAG_FONT)
		_shared["font"] = font
		return "font"
	elif not _shared.has("string"):
		var s := StandardMaterial3D.new()
		s.vertex_color_use_as_albedo = true
		s.vertex_color_is_srgb = true
		s.roughness = 0.85
		var rod := StandardMaterial3D.new()
		rod.albedo_color = ROD_COLOUR
		rod.metallic = 0.55
		rod.roughness = 0.4
		var pin := StandardMaterial3D.new()
		pin.albedo_color = PIN_COLOUR
		pin.roughness = 0.35
		_shared["rod"] = rod
		_shared["pin"] = pin
		_shared["string"] = s
		return "materials"
	return ""

## A shader from code, and a first material on it, kept: the shader is compiled for its first material (8 to 15 ms),
## so here, in the look's own piece, and not at the first tag.
static func _new_shader(code: String) -> Shader:
	var sh := Shader.new()
	sh.code = code
	var first := ShaderMaterial.new()
	first.shader = sh
	_shared["first_" + str(_shared.size())] = first
	return sh

## The paper the tags' holes show: the construction's first wall's.
func _paper() -> String:
	for w in data.construction(construction_id).get("walls", []):
		var b: Dictionary = data.board_spec(str(w.get("board", "")))
		if StickerData.two_sided(b):
			return str(b.get("paper", "#c4a27a"))
	return "#c4a27a"

## One thread of the pass: its pieces' tubes into the pass's strings, the balls where they meet, its tag.
func _draw_one(it: Dictionary) -> void:
	if _pass.is_empty():
		return
	var walls: Dictionary = _pass.walls
	var t: Dictionary = it.thread
	var tid := str(t.get("id", ""))
	var ends := [_end(it.a, walls), _end(it.b, walls)]
	if (ends[0] as Dictionary).is_empty() or (ends[1] as Dictionary).is_empty():
		return
	var p_arr: Array
	var q_arr: Array
	var over: Array = []
	if str(it.kind) == "between":
		p_arr = it.p
		q_arr = it.q
		over = it.get("over", [])
	else:
		# a wall's own: over its top edge when it joins its two faces (over_board, in the board frame), carried
		var w: Dictionary = walls[str(it.board)]
		p_arr = ends[0].pin
		q_arr = ends[1].pin
		for v in StickerData.over_board(ends[0].local, ends[1].local, w.board):
			over.append(StickerData.wall_point(w.table, w.wall, w.board, v))
	var r := R_AGREED if str(t.get("colour", "")).to_lower() == AGREED else R_THREAD
	var colour := _colour(str(t.get("colour", StickerData.THREAD_RED)))
	var pc := StickerData.thread_pieces(p_arr, q_arr, over)
	var pieces: Array = pc.pieces
	var last := pieces.size() - 1
	var off := _off_paper(0.0, r)          # a sticker lies ON its face: its string is lifted off it
	var la: Vector3 = ends[0].n * off
	var lb: Vector3 = ends[1].n * off
	var strings: _Acc = _pass.strings
	var first := strings.verts.size()
	for k in pieces.size():
		var cv := StickerData.thread_curve(pieces[k][0], pieces[k][1])
		var l0: Vector3 = la if k == 0 else Vector3.ZERO
		var l1: Vector3 = lb if k == last else Vector3.ZERO
		var pts: Array = []
		for i in SEGMENTS + 1:
			var u := float(i) / float(SEGMENTS)
			pts.append(StickerData.v3(StickerData.curve_at(cv, u)) + l0.lerp(l1, u))
		var side := (StickerData.v3(cv.q) - StickerData.v3(cv.p)).cross(Vector3.UP)
		_tube(strings, pts, r, SIDES, colour, side if side.length() > 1e-6 else Vector3.BACK)
		if k > 0:
			(_pass.joints as Array).append([StickerData.v3(pieces[k][0]), r, colour])
	(_pass.ids as Array).append(tid)
	_pass.kinds[tid] = str(it.kind)
	_pass.pieces[tid] = pieces.size()
	(_pass.ranges as Array).append([first, strings.verts.size() - first])
	var p := StickerData.v3(p_arr)
	var q := StickerData.v3(q_arr)
	_pass.pinned[str(it.a.get("id", ""))] = p + la
	_pass.pinned[str(it.b.get("id", ""))] = q + lb
	# its word, on the longest piece: out of its faces when it runs along them, over the string on a hop over an edge,
	# else hung below the string
	var tk := int(pc.tag)
	var tcv := StickerData.thread_curve(pieces[tk][0], pieces[tk][1])
	var mid := StickerData.v3(StickerData.curve_at(tcv, 0.5)) + ((la if tk == 0 else Vector3.ZERO) + (lb if tk == last else Vector3.ZERO)) / 2.0
	var faces := end_faces(p, ends[0].n, over, q, ends[1].n)
	var fa: Array = faces[tk]
	var fb: Array = faces[tk + 1]
	var na: Vector3 = fa[0]
	var nb: Vector3 = fb[0]
	var along := na.dot(nb) > 0.0 and absf((mid - Vector3(fa[1])).dot(na)) < TAG_ALONG + off and absf((mid - Vector3(fb[1])).dot(nb)) < TAG_ALONG + off
	var facing := (na + nb).normalized() if (na + nb).length() > 1e-6 else Vector3.ZERO
	var word := str(t.get("word", ""))
	if along and facing != Vector3.ZERO:
		_flat_tag(tid, word, mid + facing * (r + TAG_GAP), facing)
		_pass.flat = int(_pass.flat) + 1
	elif not over.is_empty() and tk % 2 == 1:
		_unflatten(tid)
		_tag(tid, word, mid + Vector3(0.0, r + TAG_GAP + float(_pass.card_half), 0.0))
	else:
		_unflatten(tid)
		_tag(tid, word, mid - Vector3(0.0, r + TAG_GAP + float(_pass.card_half), 0.0))
	_pass.keep[tid] = true

## The pass's strings, balls and pins made the ones shown; the tags of threads no longer drawn go.
func _commit() -> void:
	if _pass.is_empty():
		return
	_sig = str(_pass.sig)
	drawn_ids = _pass.ids
	kinds = _pass.kinds
	pieces_of = _pass.pieces
	flat_tags = int(_pass.flat)
	_mesh("Strings", _pass.strings, _string_mat, {"ids": drawn_ids, "ranges": _pass.ranges, "rings": SEGMENTS + 1, "sides": SIDES, "kinds": kinds, "pieces": pieces_of})
	for tid in _tags.keys():
		if not (_pass.keep as Dictionary).has(tid):
			_drop_tag(tid)
	# the balls where two pieces of a thread meet, in its colour and at its radius
	var joints_node := get_node_or_null("Joints") as MultiMeshInstance3D
	if joints_node == null:
		joints_node = MultiMeshInstance3D.new()
		joints_node.name = "Joints"
		joints_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var jm := MultiMesh.new()
		jm.transform_format = MultiMesh.TRANSFORM_3D
		jm.use_colors = true
		var unit := SphereMesh.new()
		unit.radius = 1.0
		unit.height = 2.0
		unit.radial_segments = 12
		unit.rings = 6
		jm.mesh = unit
		joints_node.multimesh = jm
		joints_node.material_override = _string_mat
		add_child(joints_node)
	var joints: Array = _pass.joints
	joints_node.multimesh.instance_count = joints.size()
	for i in joints.size():
		joints_node.multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * float(joints[i][1])), joints[i][0]))
		joints_node.multimesh.set_instance_color(i, joints[i][2])
	joints_node.visible = joints.size() > 0
	# the pins: a red head where a thread meets a sticker
	var pins_node := get_node_or_null("Pins") as MultiMeshInstance3D
	if pins_node == null:
		pins_node = MultiMeshInstance3D.new()
		pins_node.name = "Pins"
		pins_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var ball := SphereMesh.new()
		ball.radius = R_PIN
		ball.height = R_PIN * 2.0
		ball.radial_segments = 12
		ball.rings = 6
		mm.mesh = ball
		pins_node.multimesh = mm
		pins_node.material_override = _pin_mat
		add_child(pins_node)
	var heads: Array = (_pass.pinned as Dictionary).values()
	pins_node.multimesh.instance_count = heads.size()
	for i in heads.size():
		pins_node.multimesh.set_instance_transform(i, Transform3D(Basis(), heads[i]))
	pins_node.visible = heads.size() > 0
	cord_ids = []
	redraws += 1
	_pass = {}

## The faces each point of a thread's [p, ...over, q] stands on (cardboard3d.ts endFaces), each [n, on]: its outward
## normal and a point of its plane. A pin stands on its sticker's face; the two points over a wall stand THREAD_CLEAR
## off that wall's near and far faces, which face away from each other along the line between the two.
static func end_faces(p: Vector3, np: Vector3, over: Array, q: Vector3, nq: Vector3) -> Array:
	var faces: Array = [[np, p]]
	for i in range(0, over.size() - 1, 2):
		var near := StickerData.v3(over[i])
		var far := StickerData.v3(over[i + 1])
		var d := Vector3(near.x - far.x, 0.0, near.z - far.z)
		var n := d.normalized() if d.length() > 0.0 else Vector3.RIGHT
		faces.append([n, near - n * StickerData.THREAD_CLEAR])
		faces.append([-n, far + n * StickerData.THREAD_CLEAR])
	faces.append([nq, q])
	return faces

## A tag laid FLAT on its face: the board's tag - its word in capitals on a card with a punched hole the face shows
## through - facing `facing`, the card FLAT_CARD_BEHIND behind the word, front sides only. A tag of this thread made as a
## billboard before is made again.
func _flat_tag(tid: String, word: String, at: Vector3, facing: Vector3) -> void:
	var holder := get_node_or_null("Tags") as Node3D
	if holder == null:
		holder = Node3D.new()
		holder.name = "Tags"
		add_child(holder)
	var tag: Node3D = _tags.get(tid)
	if tag != null and not bool(tag.get_meta("flat", false)):
		_drop_tag(tid)
		tag = null
	if _flat_mat == null:
		while _warm_look() != "":
			pass
		_flat_mat = ShaderMaterial.new()
		_flat_mat.shader = _shared.flat
		_flat_mat.set_shader_parameter("paper", TAG_PAPER)
		_flat_mat.set_shader_parameter("edge", TAG_EDGE)
	_flat_mat.set_shader_parameter("hole", _card_mat.get_shader_parameter("hole"))
	if tag == null:
		tag = Node3D.new()
		tag.name = "Tag_" + tid
		tag.set_meta("flat", true)
		holder.add_child(tag)
		var card := MeshInstance3D.new()
		card.name = "Card"
		card.mesh = QuadMesh.new()
		card.material_override = _flat_mat
		card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		card.position = Vector3(0.0, 0.0, -FLAT_CARD_BEHIND)
		tag.add_child(card)
		var label := Label3D.new()
		label.name = "Word"
		label.font = _font
		label.font_size = TAG_FONT
		label.pixel_size = TAG_PIXEL
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.double_sided = false
		label.shaded = false
		label.modulate = TAG_INK
		label.outline_size = 0
		label.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
		label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tag.add_child(label)
		_tags[tid] = tag
	# its +Z out of the face, its +Y up the face (world up laid on it)
	var up := Vector3.UP - facing * facing.dot(Vector3.UP)
	tag.transform = Transform3D(Basis.looking_at(-facing, up if up.length() > 1e-4 else Vector3.FORWARD), at)
	var text := word.to_upper()
	var label: Label3D = tag.get_node("Word")
	var card: MeshInstance3D = tag.get_node("Card")
	if label.text != text:
		label.text = text
		var size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, TAG_FONT) * TAG_PIXEL
		var line := _font.get_height(TAG_FONT) * TAG_PIXEL
		var hole := line * 0.9
		var w := size.x + hole + line * 0.5
		var h := line * 1.3
		label.offset = Vector2(hole / 2.0 / TAG_PIXEL, 0.0)
		(card.mesh as QuadMesh).size = Vector2(w, h)
		card.set_instance_shader_parameter("card_size", Vector2(w, h))

## A thread's tag that hangs in the open: one made flat on a face before goes, so the board's billboard is made.
func _unflatten(tid: String) -> void:
	var tag: Node3D = _tags.get(tid)
	if tag != null and bool(tag.get_meta("flat", false)):
		_drop_tag(tid)

func _drop_tag(tid: String) -> void:
	var gone: Node = _tags.get(tid)
	_tags.erase(tid)
	if is_instance_valid(gone):
		gone.get_parent().remove_child(gone)
		gone.queue_free()

## One end of a thread on a wall of this construction: {pin (Array, the construction's frame), local (Array, the pin in
## the wall's board frame), n (its face's outward normal in the construction's frame)}; {} when its sticker is on no
## wall of it.
func _end(s: Dictionary, walls: Dictionary) -> Dictionary:
	var h: Dictionary = s.get("host", {})
	var bid := str(h.get("id", ""))
	if str(h.get("kind", "")) != "board" or not walls.has(bid):
		return {}
	var w: Dictionary = walls[bid]
	var drawn := StickerLayer.drawn_as(s, h, 0.0, true)
	var local := StickerData.pin_of(drawn, data.design(str(s.get("design", ""))))
	var pin := StickerData.wall_point(w.table, w.wall, w.board, local)
	var nz := -1.0 if float(StickerData.a3(drawn.get("n"))[2]) < 0.0 else 1.0
	return {"pin": pin, "local": local, "n": Basis(Vector3.UP, deg_to_rad(float(w.yaw))) * Vector3(0.0, 0.0, nz)}
