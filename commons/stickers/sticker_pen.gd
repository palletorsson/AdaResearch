extends Node3D
## THE GRAFFITI PEN (Palle, 2026-11-14: "extra scribbles with graffiti pens in different pens and sizes", kept as data):
## the inventory's worn tool for writing on a board's FACE - the front of any board, either face of a cardboard wall -
## with one of the contract's pens (stickers.ts PENS, ported in sticker_data.gd: fine liner, marker, chisel, spray), a
## width inside that pen's range and a colour. It keeps the WORN contract the pad and the tape roll keep (wear,
## put_away, fire_worn, release_worn, apply_config, apply_grid_config, worn_on, worn_active), so the inventory's wand
## forwards the trigger to it with no change to the wand.
##
##   VR (worn on an XRController3D): the pen's TIP stands TIP_REACH ahead of the controller. Hold the trigger with the
##     tip within TOUCH (1.5 cm) of a face, over the board, and the pen is DOWN on that face, writing at the tip's foot
##     on it. It stays down while the trigger is held and the tip stays within LIFT_OFF of that face's plane over the
##     board (a hand pushed through the cardboard, which stops nothing in VR, still writes on the face it went down on,
##     up to PUSH_MOST behind it); lifted, the line is sent, and touched down again the pen begins another.
##   desktop (worn on the camera): hold the left button (or F) aiming at a face, up to `reach`: the pen is down on the
##     face the aim hit, and each point is where the aim's ray crosses that face's plane, kept on the board - the web's
##     3D pen (cardboard3d.ts facePoint), so a drag that leaves the board runs along its edge.
## The face is settle's: on a TWO-SIDED board (a cardboard wall) the back when the tip is behind the middle of the
## cardboard or the aim hit the back; a paper board has only its front ("THE BACK OF THE BOARD", as the pad says), and a
## cut edge takes nothing. The pen writes on boards only: anything else is refused in words.
##
## The points (cardboard3d.ts penStrokes, pens.ts thinStroke, stickers.ts Stroke): in the board's frame as a stroke
## stores them - x and y as seen from the FRONT, on the back too, so a line drawn left to right on a back seen from behind
## runs from +x to -x - kept on the board, one kept whenever the pen has moved StickerData.STROKE_STEP (the contract's 2
## mm) from the last kept one; at the line's end the pen's own last place is kept too (in the last kept point's place
## when it lies within half a step of it, so no line ends in a sliver whose direction is the hand's tremor); a press that
## did not move is a DOT, two points StickerData.STROKE_DOT (0.5 mm) apart along +x (along -x from the right edge); a line
## of more than STROKE_POINTS points goes on as the next stroke from where the last one ends, so nothing is resampled
## away. Each stroke is ONE `scribble` op through StickerData (scribble(): cleanOp's cleaning, applyOps' rules first,
## then the outbox and the POST, as the pad's ops go), drawn by the board's own StickerLayer. While the line is being
## drawn the pen shows it itself, in chunks of PREVIEW_CHUNK points made with the layer's stroke_ribbon and its material,
## so what is shown is what will be drawn; sorted over the face's lines and, as ink lies on the cardboard, under its
## stickers.
##
## THE ERASER (pen "eraser", the graffiti item's pen knob): a press with the tip on a face (VR: within TOUCH, where the
## pen would go down - a press begun in the air waits for the tip to touch) or the desktop's aim on one takes the line
## under it: of that face's lines, the LATEST in the record whose centre line passes within half its width and the
## eraser's reach of the point (pens.ts strokeAt; the reach ERASE_REACH, on the desktop at least ERASE_PX pixels at the
## aim's distance, as the web's eraser) - ONE `erase` op through StickerData.erase: the line is kept in the record as
## erased, with who erased it and when, and is no longer drawn. Nothing under it is refused in words, with no op. One
## erase a press: a hold does not sweep. While it hovers, the line it would take is marked (laid over itself in the web's
## selection blue, a little wider: Sticker3D.tsx drawMark) and its words say whose line it is. Bringing a line back
## (unerase) stays on the web: the Board view's "Bring back", which takes the line this face lost last.
##
## config: pen (fine | marker | chisel | spray | eraser), width ("pen" or "" = the pen's own, "thin" = its least, "thick"
## = its most, or metres - kept inside the pen's range, as cleanStroke keeps it), colour (#rrggbb, or a name of
## stickers.ts PEN_COLOUR_NAMES - black, white, thread red, pink, blue, yellow, green, orange - in PEN_COLOURS' order;
## "red" too, the name round 1's pen took), reach (m, the desktop's aim), mode ("auto": the tip on an XRController3D, the
## aim elsewhere; "tip" or "aim" forces one - a test drives the tip from a plain node).

const StickerData := preload("res://commons/stickers/sticker_data.gd")
const StickerWorld := preload("res://commons/stickers/sticker_world.gd")
const StickerLayer := preload("res://commons/stickers/sticker_layer.gd")
const MASK := (0xFFFFFFFF & ~((1 << 17) | (1 << 19))) & ~(1 << 22) & ~(1 << 16)   # the pad's: not the hands, the body, the UI, held things
const TIP_REACH := 0.08        # the tip ahead of the controller (its -Z), metres, at scale 1
const TOUCH := 0.015           # the tip this near a face puts the pen down ...
const LIFT_OFF := 0.02         # ... and further than this from the face's plane lifts it (a hand trembles by millimetres)
const PUSH_MOST := 0.1         # a tip pushed this far behind its face has left it (a hand through the wall)
const HOVER := 0.12            # the tip's foot is shown on a face this near, before it touches
## A stroke stores its points to 4 places (0.1 mm). A hand held still is never still to the last bit (the aim's crossing
## and a tracked tip wander by nanometres), and pens.ts keeps the drag's end whenever it differs from the last point at
## all - in a browser a still mouse repeats its pixel exactly. An end closer than half the stored step is the same point:
## kept, two such points stored as one and the same, and the press was not read as a dot (measured: [0.21, -0.23] twice).
const STILL := 0.00005
const PREVIEW_CHUNK := 64      # the line being drawn is shown in ribbons of this many points (only the last one is remade)
## The line being drawn sorts this far nearer than the face's own lines (VisualInstance3D.sorting_offset): drawn over
## them, and still under the face's residue and stickers (the scribbles' material sorts before them: sticker_layer.gd).
const PREVIEW_SORT := 1.0
const HOLD_PULSE := 0.06
const ERASER := "eraser"       # the pen knob's eraser (items.json graffiti)
const ERASE_REACH := 0.004     # the eraser takes a line within its half width and this much more (metres)
const ERASE_PX := 6            # ... and on the desktop at least this many pixels at the aim's distance (cardboard3d.ts)
const MARK_COLOUR := Color("2e85ff")   # the line the eraser would take, in the web's selection blue (Sticker3D.tsx SELECT)
const MARK_ALPHA := 0.5
const MARK_WIDER := 0.004      # the mark is the line as it shows and this much wider
const MARK_SORT := 2.0         # sorted over the face's lines and the line being drawn
const ERASER_COLOUR := Color("f2b8c6")  # the eraser's nib and band, and its foot
const LABEL_PX := 0.0007       # the words at arm's length (28 px font: 2 cm), as the pad's
const LABEL_NEAR := 0.9
const LABEL_GROW_MOST := 5.0
const LINE_IDLE := Color("ee478f")
const LINE_REFUSED := Color("ff5068")

signal down(board: String, face: String)
signal scribbled(stroke: Dictionary)
signal erased(stroke: Dictionary)
signal refused(reason: String)

@export var pen := "marker"
@export var width := "pen"
@export var colour := "#16191e"
@export var reach := 4.0
@export var mode := "auto"

var worn_on: Node3D = null
var worn_active := true
var notice := ""
var data: Node = null
var touch: Dictionary = {}          # where the pen would write now (_touch_state), for the cursor and for probes
var line: Dictionary = {}           # the line being drawn: {board, face, node, host, w, h, kept, last, strokes}; {} when up
var sent: Array = []                # the strokes this pen sent (as drawn), oldest first, for probes
var erased_ids: Array = []          # the lines this eraser took, oldest first, for probes
var hot: Dictionary = {}            # the line the eraser would take now ({} when none), for the mark and for probes
var _pressed := false
var _refused_this_press := false
var _spent := false                 # the eraser's press has done its one erase (or its one refusal)
var _mark: MeshInstance3D = null    # the line the eraser would take, marked (top level, in its board's frame)
var _mark_id := ""
var _tip_reach := TIP_REACH
var _model: Node3D = null
var _show_model := true
var _cursor: MeshInstance3D = null
var _cursor_mat: StandardMaterial3D = null
var _label: Label3D = null
var _aim_line: MeshInstance3D = null
var _aim_mat: StandardMaterial3D = null
var _preview: Node3D = null         # the line being drawn, in its board's frame
var _chunk_from := 0                # where the last preview chunk begins in line.kept

func apply_grid_config(config: Dictionary) -> void:
	var p := str(config.get("pen", pen))
	if StickerData.PENS.has(p) or p == ERASER:
		pen = p
	if config.has("width"):
		width = str(config.get("width"))
	if config.has("colour"):
		var c := _colour_of(str(config.get("colour")))
		if c != "":
			colour = c
	reach = clampf(float(config.get("reach", reach)), 0.5, 12.0)
	var m := str(config.get("mode", mode))
	if m in ["auto", "tip", "aim"]:
		mode = m
	if is_inside_tree():
		_refresh_model()

func _ready() -> void:
	var cfg := {}
	for key in ["pen", "width", "colour", "reach", "mode"]:
		if has_meta("config_" + key):
			cfg[key] = get_meta("config_" + key)
	if not cfg.is_empty():
		apply_grid_config(cfg)
	data = StickerData.get_or_create(get_tree())
	_build_model()

## A knob turned while the pen is worn (the inventory's live config): a line being drawn is sent first, in its own pen.
func apply_config(config: Dictionary) -> void:
	_end()
	apply_grid_config(config)

## WEAR: in the hand (the controller) or on the desktop camera; no collision. `scale_factor` sizes the pen, and its tip
## with it. Called again with the same node it only shows itself; with another it moves over.
func wear(ctrl: Node3D, scale_factor := 1.0, show_model := true) -> void:
	_end()
	_pressed = false
	if get_parent() != ctrl:
		if get_parent() != null:
			get_parent().remove_child(self)
		ctrl.add_child(self)
	worn_on = ctrl
	worn_active = true
	visible = true
	_show_model = show_model
	_tip_reach = TIP_REACH * maxf(scale_factor, 0.05)
	transform = Transform3D.IDENTITY
	if _model != null:
		_model.visible = show_model
		_model.scale = Vector3.ONE * maxf(scale_factor, 0.05)

## Put away (another item chosen, or the bracelet out of PLACE): a line being drawn is sent (it was drawn), then the pen
## is hidden and inert.
func put_away() -> void:
	_end()
	_pressed = false
	worn_active = false
	visible = false
	_hide_aim()

## The trigger pressed while worn: the pen goes down as soon as it touches a face (at once when it already does); the
## eraser takes the line under it as soon as it touches one, once.
func fire_worn() -> void:
	if worn_on == null or not worn_active or _pressed:
		return
	_pressed = true
	_refused_this_press = false
	_spent = false
	if is_inside_tree() and data != null:
		touch = _touch_state()
		_press_step(touch)

## Whether this is the eraser rather than a pen.
func is_eraser() -> bool:
	return pen == ERASER

## The trigger let go: the line is sent.
func release_worn() -> void:
	if not _pressed:
		return
	_pressed = false
	_end()

## Whether the pen writes with its tip (VR) rather than along an aim (the desktop camera).
func tip_mode() -> bool:
	if mode == "tip":
		return true
	if mode == "aim":
		return false
	return worn_on is XRController3D

## The tip, in the world.
func tip() -> Vector3:
	return worn_on.global_transform * Vector3(0.0, 0.0, -_tip_reach) if worn_on != null else global_position

## The width a stroke of this pen gets (metres): the knob read against the pen's range (cleanStroke keeps it there too);
## 0 for the eraser, which draws none.
func width_m() -> float:
	if not StickerData.PENS.has(pen):
		return 0.0
	var p: Dictionary = StickerData.PENS[pen]
	match width.strip_edges().to_lower():
		"", "pen", "0":
			return float(p.width)
		"thin":
			return float(p.min)
		"thick":
			return float(p.max)
	return clampf(float(width), float(p.min), float(p.max)) if width.is_valid_float() and float(width) > 0.0 else float(p.width)

## A colour knob's value as #rrggbb: a name of the contract's PEN_COLOUR_NAMES (in PEN_COLOURS' order), "red" (round
## 1's name for thread red), or a hex; "" when it is none of them.
static func _colour_of(v: String) -> String:
	var s := v.strip_edges().to_lower()
	var k := StickerData.PEN_COLOUR_NAMES.find(s)
	if k >= 0:
		return str(StickerData.PEN_COLOURS[k])
	if s == "red":
		return str(StickerData.PEN_COLOURS[StickerData.PEN_COLOUR_NAMES.find("thread red")])
	if not s.begins_with("#"):
		s = "#" + s
	return s if RegEx.create_from_string("^#[0-9a-f]{6}\\z").search(s) != null else ""   # \z: PCRE's $ lets "...\n" through

func _physics_process(_delta: float) -> void:
	if worn_on == null or not worn_active or not is_inside_tree() or data == null:
		_hide_aim()
		return
	touch = _touch_state()
	if _pressed:
		_press_step(touch)
	_draw(touch)

## One step of a held trigger: the pen goes down on the face it touches, follows the line it is drawing, or lifts.
func _press_step(st: Dictionary) -> void:
	if is_eraser():
		_erase_step(st)
		return
	if line.is_empty():
		if bool(st.get("ok", false)):
			_begin(st)
		elif not tip_mode() and not _refused_this_press and str(st.get("reason", "")) != "":
			# the desktop's press on what takes no ink says why, once a press (in VR a tip in the air is simply up)
			_refused_this_press = true
			_refuse(str(st.reason))
		return
	var q: Variant = _follow()
	if q == null:
		_end()                      # lifted off its face (the tip), or the board went
	elif q is Vector2:
		_add(q)

# ==== the eraser ====

## One step of a held trigger with the eraser: the first moment of the press it is on a face (at once for the aim; for
## the tip when it touches) the line under it goes, or the press is refused in words; then the press is spent until the
## trigger is let go - a hold does not sweep.
func _erase_step(st: Dictionary) -> void:
	if _spent:
		return
	if not bool(st.get("ok", false)):
		if not tip_mode():
			_spent = true
			_refuse(_eraser_words(str(st.get("reason", ""))))
		return
	_spent = true
	var s := stroke_under(st)
	if s.is_empty():
		_refuse("NO LINE HERE TO ERASE")
		return
	var id := str(s.get("id", ""))
	if not data.erase(id):
		_refuse("NOT ERASED: " + str(data.last_error).to_upper())
		return
	erased_ids.append(id)
	notice = ""
	_pulse(HOLD_PULSE, 0.05)
	erased.emit(data.stroke(id))

## What the eraser says where the pen's words speak of writing.
static func _eraser_words(reason: String) -> String:
	match reason:
		"AIM AT A BOARD TO WRITE ON IT":
			return "AIM AT A LINE TO ERASE IT"
		"THE PEN WRITES ON A BOARD OR A CARDBOARD WALL":
			return "THE ERASER TAKES LINES OFF A BOARD OR A CARDBOARD WALL"
		"TOUCH THE FACE WITH THE TIP":
			return "TOUCH THE LINE WITH THE TIP"
	return reason if reason != "" else "NO LINE HERE TO ERASE"

## The line the eraser would take where it is on a face now (pens.ts strokeAt over that face's lines, in the record's
## order): the LATEST whose centre line passes within half its width and the eraser's reach of the point; {} when none.
func stroke_under(st: Dictionary) -> Dictionary:
	if data == null or not st.has("board") or not st.has("p") or not bool(st.get("hover", false)):
		return {}
	var tol := erase_reach(st)
	var pt: Vector2 = st.p
	var list: Array = data.strokes_on(str(st.board), str(st.face))
	for i in range(list.size() - 1, -1, -1):
		var s: Dictionary = list[i]
		if dist_to_stroke(float(pt.x), float(pt.y), s.get("points", [])) <= float(s.get("width", 0.0)) / 2.0 + tol:
			return s
	return {}

## How far past a line's half width the eraser takes it (metres): ERASE_REACH, and on the desktop at least ERASE_PX
## pixels at the distance from the aim's eye to the point (the web's eraser: ERASE_PX on screen).
func erase_reach(st: Dictionary) -> float:
	if tip_mode() or not worn_on is Camera3D or not st.has("at") or not is_inside_tree():
		return ERASE_REACH
	var cam := worn_on as Camera3D
	var h := float(get_viewport().get_visible_rect().size.y)
	var per_px := 2.0 * cam.global_position.distance_to(Vector3(st.at)) * tan(deg_to_rad(cam.fov) / 2.0) / maxf(1.0, h)
	return maxf(ERASE_REACH, float(ERASE_PX) * per_px)

## How far a point (the board frame) is from a stroke's centre line (pens.ts distToStroke), in doubles.
static func dist_to_stroke(px: float, py: float, points: Variant) -> float:
	if not points is Array or (points as Array).is_empty():
		return INF
	var pts: Array = points
	if pts.size() == 1:
		return sqrt((px - float(pts[0][0])) ** 2 + (py - float(pts[0][1])) ** 2)
	var best := INF
	for i in range(1, pts.size()):
		var ax := float(pts[i - 1][0])
		var ay := float(pts[i - 1][1])
		var dx := float(pts[i][0]) - ax
		var dy := float(pts[i][1]) - ay
		var l := dx * dx + dy * dy
		var t := clampf(((px - ax) * dx + (py - ay) * dy) / l, 0.0, 1.0) if l > 0.0 else 0.0
		best = minf(best, sqrt((px - (ax + t * dx)) ** 2 + (py - (ay + t * dy)) ** 2))
	return best

## The eraser's mark: the line it would take laid over itself in MARK_COLOUR at MARK_ALPHA, as wide as the line shows
## and MARK_WIDER more (a soft pen's whole reach), with its pen's cap, in its board's frame, sorted over the face's
## lines and under its stickers. Made again only when the line changes; hidden when there is none.
func _show_mark(s: Dictionary, st: Dictionary) -> void:
	if s.is_empty() or not st.has("node") or not is_instance_valid(st.get("node")):
		if _mark != null:
			_mark.hide()
		_mark_id = ""
		return
	if _mark == null:
		_mark = MeshInstance3D.new()
		_mark.name = "EraseMark"
		_mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mark.material_override = StickerLayer.stroke_material()
		_mark.sorting_offset = MARK_SORT
		add_child(_mark)
		_mark.top_level = true
	_mark.global_transform = (st.node as Node3D).global_transform
	var id := str(s.get("id", ""))
	if id != _mark_id:
		_mark_id = id
		var p: Dictionary = StickerData.PENS.get(str(s.get("pen", "")), StickerData.PENS.fine)
		var soft := float(p.get("soft", 0.0))
		var w := float(s.get("width", p.width))
		var shows := w * StickerLayer.soft_reach(soft) * 2.0 if soft > 0.0 else w
		var r := StickerLayer.stroke_ribbon({"face": s.get("face", "front"), "pen": "chisel" if str(p.cap) == "square" else "marker",
			"width": shows + MARK_WIDER, "colour": "#" + MARK_COLOUR.to_html(false), "points": s.get("points", [])})
		var cols: PackedColorArray = r.cols
		for i in cols.size():
			cols[i].a = MARK_ALPHA
		var mesh := ArrayMesh.new()
		if not (r.idx as PackedInt32Array).is_empty():
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = r.verts
			arrays[Mesh.ARRAY_NORMAL] = r.norms
			arrays[Mesh.ARRAY_TEX_UV] = r.uvs
			arrays[Mesh.ARRAY_COLOR] = cols
			arrays[Mesh.ARRAY_INDEX] = r.idx
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_mark.mesh = mesh
		_mark.set_meta("stroke", id)
	_mark.show()

# ==== where the pen is ====

## Where the pen would write now: {ok, reason, host, board, face, node, w, h, p (Vector2, the board's frame), at (the
## point on the face, world), n (the face's outward normal, world), d (the tip's height over the face; 0 for the aim),
## hover (a face is near enough to show the foot on)}.
func _touch_state() -> Dictionary:
	return _touch_tip() if tip_mode() else _touch_aim()

## The aim (the desktop): the face the ray hits first.
func _touch_aim() -> Dictionary:
	var origin := worn_on.global_position
	var dir := -worn_on.global_basis.z.normalized()
	var st := {"ok": false, "reason": "", "hover": false, "origin": origin, "dir": dir, "end": origin + dir * reach}
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * reach, MASK)
	q.exclude = _exclude()
	q.hit_from_inside = false
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		st.reason = "AIM AT A BOARD TO WRITE ON IT"
		return st
	st.end = hit.position
	var found := StickerWorld.host_at(hit.collider)
	if not bool(found.ok) or str((found.get("host", {}) as Dictionary).get("kind", "")) != "board":
		st.reason = "THE PEN WRITES ON A BOARD OR A CARDBOARD WALL"
		return st
	var frame: Transform3D = found.frame
	var at_l := frame.affine_inverse() * Vector3(hit.position)
	var n_l := (frame.basis.transposed() * Vector3(hit.normal)).normalized()
	var host: Dictionary = found.host
	var bid := str(host.get("id", ""))
	var sided: bool = data.board_sided(bid)
	var face := ""
	if n_l.z >= 0.99:
		face = "front"
	elif n_l.z <= -0.99 and sided:
		face = "back"
	else:
		st.reason = "THE BACK OF THE BOARD" if n_l.z < 0.0 and not sided else "THE EDGE OF THE BOARD"
		return st
	return _on_face(st, found, face, Vector2(at_l.x, at_l.y), 0.0)

## The tip (VR): the nearest face whose board lies under the tip, within HOVER; down when within TOUCH.
func _touch_tip() -> Dictionary:
	var t := tip()
	var st := {"ok": false, "reason": "", "hover": false, "origin": t, "dir": -worn_on.global_basis.z.normalized(), "end": t}
	var shape := SphereShape3D.new()
	shape.radius = HOVER
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), t)
	q.collision_mask = MASK
	q.exclude = _exclude()
	var best: Dictionary = {}
	var seen := {}
	for h in get_world_3d().direct_space_state.intersect_shape(q, 16):
		var col: Object = h.get("collider")
		if col == null or seen.has(col.get_instance_id()):
			continue
		seen[col.get_instance_id()] = true
		var found := StickerWorld.host_at(col)
		if not bool(found.ok) or str((found.get("host", {}) as Dictionary).get("kind", "")) != "board":
			continue
		var frame: Transform3D = found.frame
		var tl := frame.affine_inverse() * t
		var bid := str(found.host.get("id", ""))
		var spec: Dictionary = data.board_spec(bid)
		var hw := float(spec.get("w", 1.0)) / 2.0
		var hh := float(spec.get("h", 1.0)) / 2.0
		if absf(tl.x) > hw or absf(tl.y) > hh:
			continue   # not over this board: its foot would be off it
		var sided: bool = data.board_sided(bid)
		var face := "back" if sided and tl.z < -StickerData.CARDBOARD / 2.0 else "front"
		var d := (-StickerData.CARDBOARD - tl.z) if face == "back" else tl.z
		if d > HOVER or d < -PUSH_MOST:
			continue
		if best.is_empty() or absf(d) < absf(float(best.d)):
			best = {"found": found, "face": face, "p": Vector2(tl.x, tl.y), "d": d}
	if best.is_empty():
		return st
	st.hover = true
	var on := _on_face(st, best.found, str(best.face), best.p, float(best.d))
	if float(best.d) > TOUCH:
		on.ok = false
		on.reason = "TOUCH THE FACE WITH THE TIP"
	elif float(best.d) < -StickerData.CARDBOARD:
		on.ok = false
		on.reason = "THE TIP IS BEHIND THE BOARD"
	return on

## A touch on a board's face: what is needed to write there.
func _on_face(st: Dictionary, found: Dictionary, face: String, p: Vector2, d: float) -> Dictionary:
	var host: Dictionary = found.host
	var bid := str(host.get("id", ""))
	var spec: Dictionary = data.board_spec(bid)
	var w := float(spec.get("w", 1.0))
	var h := float(spec.get("h", 1.0))
	var frame: Transform3D = found.frame
	var z := StickerData.stroke_z(face)
	st.ok = true
	st.host = host
	st.board = bid
	st.face = face
	st.node = found.node
	st.w = w
	st.h = h
	st.p = Vector2(clampf(p.x, -w / 2.0, w / 2.0), clampf(p.y, -h / 2.0, h / 2.0))
	st.at = frame * Vector3(st.p.x, st.p.y, z)
	st.n = (frame.basis * Vector3(0.0, 0.0, -1.0 if face == "back" else 1.0)).normalized()
	st.d = d
	st.hover = true
	return st

## Where the line being drawn goes now, on ITS face (Vector2, the board's frame, kept on the board); a frame with no
## point (the aim along the face or behind the eye) is false; null when the pen has lifted or the board is gone.
func _follow() -> Variant:
	var node: Variant = line.get("node")
	if not is_instance_valid(node):
		return null
	var inv: Transform3D = (node as Node3D).global_transform.affine_inverse()
	var hw := float(line.w) / 2.0
	var hh := float(line.h) / 2.0
	var back := str(line.face) == "back"
	var z_face := -StickerData.CARDBOARD if back else 0.0
	if tip_mode():
		var tl := inv * tip()
		var d := (z_face - tl.z) if back else tl.z
		if d > LIFT_OFF or d < -PUSH_MOST or absf(tl.x) > hw + LIFT_OFF or absf(tl.y) > hh + LIFT_OFF:
			return null
		return Vector2(clampf(tl.x, -hw, hw), clampf(tl.y, -hh, hh))
	var o := inv * worn_on.global_position
	var dir := (inv.basis * (-worn_on.global_basis.z)).normalized()
	if absf(dir.z) < 1e-9:
		return false
	var t := (z_face - o.z) / dir.z
	if not (t > 0.0):
		return false
	return Vector2(clampf(o.x + t * dir.x, -hw, hw), clampf(o.y + t * dir.y, -hh, hh))

func _exclude() -> Array:
	var out: Array = []
	var body := get_tree().get_first_node_in_group("player_body")
	if body is CollisionObject3D:
		out.append((body as CollisionObject3D).get_rid())
	return out

# ==== the line ====

func _begin(st: Dictionary) -> void:
	line = {"board": st.board, "face": st.face, "node": st.node, "host": st.host, "w": st.w, "h": st.h, "kept": [st.p], "last": st.p, "strokes": 0}
	_chunk_from = 0
	_clear_preview()
	notice = ""
	_pulse(HOLD_PULSE, 0.05)
	down.emit(str(st.board), str(st.face))
	_show_preview()

## A point of the line: kept when it lies STROKE_STEP or more from the last one kept (to a nanometre: steps summed in
## floating point land either side of an exact 2 mm, as pens.ts says); a line at STROKE_POINTS goes on as the next
## stroke from where this one ends.
func _add(q: Vector2) -> void:
	line.last = q
	var kept: Array = line.kept
	if q.distance_to(kept[-1]) >= StickerData.STROKE_STEP - 1e-9:
		kept.append(q)
		if kept.size() >= StickerData.STROKE_POINTS:
			_send(kept)
			line.kept = [kept[-1]]
			line.last = kept[-1]
			_chunk_from = 0
			_clear_preview()
	_show_preview()

## The line ends (lifted, let go, put away): its own last place kept (pens.ts; one within STILL of the last kept point
## is that point), a press that did not move made a dot, and the stroke sent.
func _end() -> void:
	if line.is_empty():
		return
	var kept: Array = line.kept
	var end: Vector2 = line.last
	var last: Vector2 = kept[-1]
	var far := end.distance_to(last)
	if far > STILL:
		if kept.size() > 1 and far < StickerData.STROKE_STEP / 2.0:
			kept[-1] = end
		else:
			kept.append(end)
	# a line continued past STROKE_POINTS begins on the last one's end: one point more is no new line
	if kept.size() == 1 and int(line.strokes) == 0:
		var x: float = kept[0].x
		var dot := StickerData.STROKE_DOT
		kept.append(Vector2(x + dot if x + dot <= float(line.w) / 2.0 else x - dot, kept[0].y))
	if kept.size() >= 2:
		_send(kept)
	line = {}
	_clear_preview()

## One stroke of the line as ONE scribble op (StickerData.scribble: cleaned as cleanOp cleans it, applied here by
## applyOps' rules, then the outbox and the POST). Doubles go in, not the 32-bit Vector2s.
func _send(kept: Array) -> void:
	var pts: Array = []
	for v in kept:
		pts.append([float((v as Vector2).x), float((v as Vector2).y)])
	var s: Dictionary = data.scribble(str(line.board), str(line.face), pen, pts, colour, width_m())
	line.strokes = int(line.strokes) + 1
	if s.is_empty():
		_refuse("NOT WRITTEN: " + str(data.last_error).to_upper())
		return
	sent.append(s)
	_pulse(HOLD_PULSE * 0.5, 0.04)
	scribbled.emit(s)

func _refuse(reason: String) -> void:
	notice = reason
	if _label != null:
		_label.text = reason
	_pulse(0.15, 0.4)
	refused.emit(reason)

func _pulse(amplitude: float, seconds: float) -> void:
	if worn_on != null and worn_on.has_method("trigger_haptic_pulse"):
		worn_on.trigger_haptic_pulse("haptic", 0.0, amplitude, seconds, 0.0)

# ==== drawing: the line being drawn, the cursor, the words ====

## The line being drawn, as the layer will draw it: its kept points and the pen's own place, in ribbons of PREVIEW_CHUNK
## points in the board's frame; only the last ribbon is made again.
func _show_preview() -> void:
	if line.is_empty() or not is_instance_valid(line.get("node")):
		return
	if _preview == null:
		_preview = Node3D.new()
		_preview.name = "Line"
		add_child(_preview)
		_preview.top_level = true
	_preview.global_transform = (line.node as Node3D).global_transform
	var kept: Array = line.kept
	if kept.size() - _chunk_from > PREVIEW_CHUNK:
		# a full chunk stays as it was last made (up to the pen's place then, short of the newest point); the next one
		# begins a point back, so the step between them is covered
		_chunk_from = kept.size() - 2
	var pts: Array = []
	for i in range(_chunk_from, kept.size()):
		pts.append([kept[i].x, kept[i].y])
	var end: Vector2 = line.last
	if end.distance_to(kept[-1]) > 0.0:
		pts.append([end.x, end.y])
	var rec := {"face": line.face, "pen": pen, "width": width_m(), "colour": colour, "points": pts}
	if pts.size() == 1:
		rec.points = [pts[0], [float(pts[0][0]) + StickerData.STROKE_DOT, pts[0][1]]]
	var r: Dictionary = StickerLayer.stroke_ribbon(rec)
	var node_name := "Chunk%d" % _chunk_from
	var mi := _preview.get_node_or_null(node_name) as MeshInstance3D
	if mi == null:
		mi = MeshInstance3D.new()
		mi.name = node_name
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.material_override = StickerLayer.stroke_material()
		mi.sorting_offset = PREVIEW_SORT
		_preview.add_child(mi)
	var mesh := ArrayMesh.new()
	if not (r.idx as PackedInt32Array).is_empty():
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = r.verts
		arrays[Mesh.ARRAY_NORMAL] = r.norms
		arrays[Mesh.ARRAY_TEX_UV] = r.uvs
		arrays[Mesh.ARRAY_COLOR] = r.cols
		arrays[Mesh.ARRAY_INDEX] = r.idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mi.mesh = mesh

func _clear_preview() -> void:
	if _preview == null:
		return
	for c in _preview.get_children():
		_preview.remove_child(c)
		c.queue_free()

func _draw(st: Dictionary) -> void:
	_ensure_aim()
	var shown := bool(st.get("hover", false)) or bool(st.get("ok", false))
	var eraser := is_eraser()
	var ink := ERASER_COLOUR if eraser else Color(colour)
	# the eraser marks the line it would take (none while a press is spent: it takes one a press)
	hot = stroke_under(st) if eraser and shown and not (_pressed and _spent) else {}
	_show_mark(hot, st)
	if shown and st.has("at"):
		# the foot: a disc of the stroke's width (at least 4 mm, to be seen) on the face, in the pen's colour - the
		# eraser's its reach, in its own colour; faint while the tip hovers, full when the pen would write
		var r := erase_reach(st) if eraser else maxf(width_m(), 0.004) / 2.0
		var n: Vector3 = st.n
		var b := StickerData.basis(n, Vector3.UP if absf(n.y) < 0.9 else Vector3.FORWARD)
		# the disc's axis (its local Y) along the face's normal, its round face on the face (right, n, -up: a turn)
		_cursor.global_transform = Transform3D(Basis(b.right * r * 2.0, n, -b.up * r * 2.0), Vector3(st.at) + n * 0.0015)
		_cursor_mat.albedo_color = Color(ink, 0.95 if bool(st.ok) else 0.35)
		_cursor.show()
	else:
		_cursor.hide()
	var title := "ERASER" if eraser else "%s %d MM" % [str(StickerData.PENS[pen].title).to_upper(), roundi(width_m() * 1000.0)]
	var words := ""
	var back_note := "  (THE BACK)" if str(st.get("face", "")) == "back" else ""
	if eraser:
		if _pressed and _spent:
			words = title + ("\n" + notice if notice != "" else "")
		elif not hot.is_empty():
			# whose line it would take
			words = title + ("\nTRIGGER: ERASE THIS " if tip_mode() else "\nPRESS: ERASE THIS ") + str(StickerData.PENS.get(str(hot.get("pen", "")), StickerData.PENS.fine).title).to_upper() \
				+ " LINE" + back_note + "\nBY " + str(hot.get("by", "SOMEONE")).to_upper()
		elif bool(st.get("ok", false)):
			words = title + "\nNO LINE HERE" + back_note
		elif str(st.get("reason", "")) != "" and (not tip_mode() or bool(st.get("hover", false))):
			words = title + "\n" + _eraser_words(str(st.reason))
	elif not line.is_empty():
		words = title + ("\nON THE BACK" if str(line.face) == "back" else "")
	elif bool(st.get("ok", false)):
		words = title + ("\nHOLD THE TRIGGER: WRITE" if not tip_mode() else "\nTRIGGER: WRITE") + back_note
	elif str(st.get("reason", "")) != "" and (not tip_mode() or bool(st.get("hover", false))):
		words = title + "\n" + str(st.reason)
	if not eraser and notice != "" and line.is_empty() and _pressed:
		words = title + "\n" + notice
	var at_w: Vector3 = Vector3(st.at) if st.has("at") else Vector3(st.get("end", tip()))
	if words != "":
		var eye := get_viewport().get_camera_3d()
		var far := eye.global_position.distance_to(at_w) if eye != null else LABEL_NEAR
		var grow := clampf(far / LABEL_NEAR, 1.0, LABEL_GROW_MOST)
		_label.pixel_size = LABEL_PX * grow
		_label.text = words
		_label.modulate = Color("1d1d1f") if bool(st.get("ok", false)) or not line.is_empty() else LINE_REFUSED
		_label.global_transform = Transform3D(Basis.IDENTITY, at_w + Vector3.UP * 0.035 * grow)
		_label.show()
	else:
		_label.hide()
	# the desktop's aim line (a VR hand needs none: the tip is the pen)
	if not tip_mode():
		var from: Vector3 = st.get("origin", worn_on.global_position)
		var to: Vector3 = st.get("end", from)
		if worn_on is Camera3D:
			from += Vector3(st.get("dir", Vector3.FORWARD)) * minf(.25, from.distance_to(to) * .5)
		var im := _aim_line.mesh as ImmediateMesh
		im.clear_surfaces()
		im.surface_begin(Mesh.PRIMITIVE_LINES)
		im.surface_add_vertex(from)
		im.surface_add_vertex(to)
		im.surface_end()
		_aim_line.global_transform = Transform3D.IDENTITY
		_aim_mat.albedo_color = Color(ink if bool(st.get("ok", false)) else LINE_REFUSED, 0.55)
		_aim_line.show()
	else:
		_aim_line.hide()

func _ensure_aim() -> void:
	if _cursor != null:
		return
	_cursor = MeshInstance3D.new()
	_cursor.name = "Foot"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.5
	disc.bottom_radius = 0.5
	disc.height = 0.0004
	disc.radial_segments = 24
	disc.rings = 1
	_cursor.mesh = disc
	_cursor_mat = StandardMaterial3D.new()
	_cursor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cursor_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cursor_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cursor_mat.no_depth_test = true
	_cursor.material_override = _cursor_mat
	_cursor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_cursor)
	_cursor.top_level = true
	_label = Label3D.new()
	_label.name = "PenWords"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 28
	_label.pixel_size = LABEL_PX
	_label.outline_size = 6
	_label.outline_modulate = Color(1, 1, 1, 0.7)
	_label.no_depth_test = true
	add_child(_label)
	_label.top_level = true
	_aim_line = MeshInstance3D.new()
	_aim_line.name = "AimLine"
	_aim_line.mesh = ImmediateMesh.new()
	_aim_mat = StandardMaterial3D.new()
	_aim_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_aim_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_aim_line.material_override = _aim_mat
	_aim_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_aim_line)
	_aim_line.top_level = true

func _hide_aim() -> void:
	if _cursor != null:
		_cursor.hide()
		_label.hide()
		_aim_line.hide()
	if _mark != null:
		_mark.hide()
	_mark_id = ""
	hot = {}

# ==== the pen itself (worn, and the inventory's miniature) ====

## A marker: a barrel along -Z ending in its nib at the tip (TIP_REACH ahead of the hand), a cap band and a nib in the
## ink's colour.
func _build_model() -> void:
	_model = Node3D.new()
	_model.name = "Pen"
	add_child(_model)
	var barrel := MeshInstance3D.new()
	barrel.name = "Barrel"
	var bm := CylinderMesh.new()
	bm.top_radius = 0.0075
	bm.bottom_radius = 0.0075
	bm.height = 0.12
	bm.radial_segments = 16
	barrel.mesh = bm
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0, -TIP_REACH + 0.016 + 0.06)
	var body := StandardMaterial3D.new()
	body.albedo_color = Color("2a2b30")
	body.roughness = 0.6
	barrel.material_override = body
	_model.add_child(barrel)
	var band := MeshInstance3D.new()
	band.name = "Band"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0079
	cm.bottom_radius = 0.0079
	cm.height = 0.018
	cm.radial_segments = 16
	band.mesh = cm
	band.rotation_degrees = Vector3(90, 0, 0)
	band.position = Vector3(0, 0, -TIP_REACH + 0.016 + 0.009)
	_model.add_child(band)
	var nib := MeshInstance3D.new()
	nib.name = "Nib"
	var nm := CylinderMesh.new()
	nm.top_radius = 0.0012
	nm.bottom_radius = 0.0055
	nm.height = 0.016
	nm.radial_segments = 12
	nib.mesh = nm
	nib.rotation_degrees = Vector3(-90, 0, 0)   # the narrow end at -Z: the tip
	nib.position = Vector3(0, 0, -TIP_REACH + 0.008)
	_model.add_child(nib)
	_model.visible = _show_model
	_refresh_model()

## The band and the nib in the ink's colour (the eraser's: ERASER_COLOUR).
func _refresh_model() -> void:
	if _model == null:
		return
	var ink := StandardMaterial3D.new()
	ink.albedo_color = ERASER_COLOUR if is_eraser() else Color(colour)
	ink.roughness = 0.5
	for n in ["Band", "Nib"]:
		var m := _model.get_node_or_null(n) as MeshInstance3D
		if m != null:
			m.material_override = ink
