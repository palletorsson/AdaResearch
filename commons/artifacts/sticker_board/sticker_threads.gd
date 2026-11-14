extends Node3D
## THE THREADS OF ONE BOARD - and on a hanging board its cords, its rods and the pins - drawn in the board's frame (a
## child of the board's Face, beside its StickerLayer), from StickerData's view of the truth, and drawn again whenever
## the placements, the designs or the boards change (StickerData watches the truth's files once a second, and applies
## this device's own ops at once).
##
## Every number is the contract's (ada_encyclopedia/src/lib/stickers.ts, ported in commons/stickers/sticker_data.gd), so
## SVG, three.js and VR draw the same strings:
##   - a thread is drawn while it is TIED and both its stickers exist, are on this board and are on (drawn_threads): a
##     cut thread, or one with a peeled end, is not drawn, and is again once it is retied or the end restored;
##   - it runs from pin to pin (pin_of: the middle of the top edge of each sticker's DRAWN box, inset by min(8% of its
##     height, 2 cm)) along thread_curve, a quadratic Bezier sagging along -Y by min(0.12 m, span / 6), as a TUBE in its
##     colour - the agreed colour (AGREED: seen by two or three readers on their own) thicker than the others;
##   - its WORD hangs on a TAG at the curve's u = 0.5, a little in front of the string: a Label3D that faces the viewer
##     (billboard) on a paper card that faces the viewer too (CARD_SHADER), sized to read at 2 m;
##   - on a board that HANGS, every live sticker hangs on a CORD from the paper's top edge straight down to its pin
##     (cord_of), each cord's top on a ROD at the depth it hangs at (one rod per depth in use), and a PIN head where the
##     cord and the threads meet the sticker.
## A string that runs by the paper (a sticker ON the paper lies LIFT over it) is lifted off it by its own radius: at
## most a few millimetres from the contract's curve, there and nowhere else.
##
## For probes: Strings / Cords carry metas ids, ranges ([first vertex, count] each), rings and sides; Rods carries
## depths; Tags holds Tag_<thread id> (Word: the Label3D, Card: its card); drawn_ids, cord_ids, rebuild_ms, redraws.

const StickerData := preload("res://commons/stickers/sticker_data.gd")
const StickerLayer := preload("res://commons/stickers/sticker_layer.gd")
const AGREED := "#8e0c16"          # a thread two or three readers found on their own (the mind map's legend)
const R_AGREED := 0.004            # its tube's radius: 8 mm thick, as the mind map draws it (4.1 px at 500 px/m)
const R_THREAD := 0.0028           # every other thread: 5.6 mm (2.8 px)
## a cord: pale, thinner than a thread (at 2.2 mm it broke into dashes at 3 m in a picture without multisampling)
const R_CORD := 0.0015
const ROD_R := 0.006               # a rod of the rail (the board reads this: its rail's axis is at h / 2 + ROD_R)
const R_PIN := 0.0065              # a pin's head
const FRAME := 0.04                # the board's frame timber (sticker_board.gd FRAME): a rod spans the frame too
const SEGMENTS := 16               # a thread in 16 chords: off its curve by at most 0.23 mm (sag <= 0.12 m)
const SIDES := 8
const CORD_SIDES := 6
const ROD_SIDES := 12
const TAG_GAP := 0.004             # the tag stands this far in front of its string's surface
const TAG_FONT := 64               # px; x TAG_PIXEL = a 2.9 cm em, capitals about 2 cm: 0.57 degrees at 2 m
const TAG_PIXEL := 0.00045
const CORD_COLOUR := Color("ece4d4")
const PIN_COLOUR := Color("c0242b")
const ROD_COLOUR := Color("2a2b30")
const TAG_PAPER := Color("f6f0e2")
const TAG_EDGE := Color("bba985")
const TAG_INK := Color("5a3a2a")
## A tag's card: a paper rectangle with an edge and a punched hole (the board's paper shows through it), that faces
## the viewer as the word's Label3D does (its axes are the camera's) and sits BEHIND the word along the eye's ray, so
## the word is always in front of its own card and both are depth-tested against everything else.
const CARD_SHADER := """shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform vec3 paper : source_color = vec3(0.965, 0.941, 0.886);
uniform vec3 edge : source_color = vec3(0.733, 0.663, 0.522);
uniform vec3 hole : source_color = vec3(0.788, 0.663, 0.471);
uniform float behind = 0.0015;
instance uniform vec2 card_size = vec2(0.2, 0.05);
varying vec2 local;
void vertex() {
	local = VERTEX.xy;
	vec3 world = MODEL_MATRIX[3].xyz + INV_VIEW_MATRIX[0].xyz * VERTEX.x + INV_VIEW_MATRIX[1].xyz * VERTEX.y;
	vec4 v = VIEW_MATRIX * vec4(world, 1.0);
	v.xyz += normalize(v.xyz) * behind;
	POSITION = PROJECTION_MATRIX * v;
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

var board_id := ""
var data: Node = null
var drawn_ids: Array = []          # the threads drawn, in the order of Strings' ranges
var cord_ids: Array = []           # the stickers hanging on a cord, in the order of Cords' ranges
var rebuild_ms := 0.0              # what the last redraw cost
var redraws := 0
var _sig := ""
var _tags: Dictionary = {}         # thread id -> its Tag node
var _string_mat: StandardMaterial3D = null
var _rod_mat: StandardMaterial3D = null
var _pin_mat: StandardMaterial3D = null
var _card_mat: ShaderMaterial = null
var _font: FontVariation = null

func _ready() -> void:
	data = StickerData.get_or_create(get_tree())
	data.placements_changed.connect(redraw)
	data.designs_changed.connect(_again)
	data.boards_changed.connect(_again)
	redraw()

func _again() -> void:
	_sig = ""
	redraw()

## Draw this board's threads (and cords, rods, pins) again, when anything they are made from changed.
func redraw() -> void:
	if data == null or not data.has_method("threads_on"):
		return
	var spec: Dictionary = data.board_spec(board_id)
	var deep := float(spec.get("depth", 0.0))
	var hang := bool(spec.get("hang", false)) and deep > 0.0
	var host := {"kind": "board", "id": board_id}
	var live: Array = []
	var by_id: Dictionary = {}
	for s0 in data.stickers_on("board:" + board_id):
		var s: Dictionary = StickerLayer.drawn_as(s0, host, deep)
		if str(s.get("state", "on")) == "on":
			live.append(s)
			by_id[str(s.get("id", ""))] = s
	var tied: Array = data.threads_on(board_id)
	var sig := JSON.stringify([int(data.revisions.get("designs", -1)), spec, live, tied.map(func(e): return e.thread)])
	if sig == _sig:
		return
	_sig = sig
	var t0 := Time.get_ticks_usec()
	_materials(Color(str(spec.get("paper", "#f4f0e6"))))
	# the pins: the contract's, in doubles, for every live sticker of the board
	var pins: Dictionary = {}
	for s in live:
		pins[str(s.get("id", ""))] = StickerData.pin_of(s, data.design(str(s.get("design", ""))))
	var pinned: Dictionary = {}        # sticker id -> where its pin head is drawn
	# THE THREADS: one tube each along its curve, in one mesh
	var strings := _Acc.new()
	drawn_ids = []
	var ranges: Array = []
	var keep_tags: Dictionary = {}
	for e in tied:
		var t: Dictionary = e.thread
		var a_id := str(e.a.get("id", ""))
		var b_id := str(e.b.get("id", ""))
		if not pins.has(a_id) or not pins.has(b_id):
			continue
		var r := R_AGREED if str(t.get("colour", "")).to_lower() == AGREED else R_THREAD
		var cv := StickerData.thread_curve(pins[a_id], pins[b_id])
		var p := StickerData.v3(cv.p)
		var q := StickerData.v3(cv.q)
		var out_p := _off_paper(p.z, r)
		var out_q := _off_paper(q.z, r)
		var pts: Array = []
		for i in SEGMENTS + 1:
			var u := float(i) / float(SEGMENTS)
			pts.append(StickerData.v3(StickerData.curve_at(cv, u)) + Vector3(0, 0, lerpf(out_p, out_q, u)))
		var side := (q - p).cross(Vector3.UP)
		var first := strings.verts.size()
		_tube(strings, pts, r, SIDES, _colour(str(t.get("colour", StickerData.THREAD_RED))), side if side.length() > 1e-6 else Vector3.BACK)
		drawn_ids.append(str(t.get("id", "")))
		ranges.append([first, strings.verts.size() - first])
		pinned[a_id] = p + Vector3(0, 0, out_p)
		pinned[b_id] = q + Vector3(0, 0, out_q)
		# its word, on a tag at u = 0.5, a little in front of the string
		var mid := StickerData.v3(StickerData.curve_at(cv, 0.5)) + Vector3(0, 0, lerpf(out_p, out_q, 0.5) + r + TAG_GAP)
		var tid := str(t.get("id", ""))
		_tag(tid, str(t.get("word", "")), mid)
		keep_tags[tid] = true
	_mesh("Strings", strings, _string_mat, {"ids": drawn_ids, "ranges": ranges, "rings": SEGMENTS + 1, "sides": SIDES})
	for tid in _tags.keys():
		if not keep_tags.has(tid):
			var gone: Node = _tags[tid]
			_tags.erase(tid)
			gone.get_parent().remove_child(gone)
			gone.queue_free()
	# THE CORDS of a hanging board: from the top edge straight down to each live sticker's pin, on a rod at its depth
	var cords := _Acc.new()
	cord_ids = []
	var cord_ranges: Array = []
	var depths: Dictionary = {}
	if hang:
		for s in live:
			var id := str(s.get("id", ""))
			var line: Array = StickerData.cord_of(pins[id], spec)
			var top := StickerData.v3(line[0])
			var pin := StickerData.v3(line[1])
			var lift := _off_paper(pin.z, R_CORD)
			var first := cords.verts.size()
			_tube(cords, [top + Vector3(0, 0, lift), pin + Vector3(0, 0, lift)], R_CORD, CORD_SIDES, CORD_COLOUR, Vector3.BACK)
			cord_ids.append(id)
			cord_ranges.append([first, cords.verts.size() - first])
			depths[snappedf(top.z + lift, 0.001)] = true
			if not pinned.has(id):
				pinned[id] = pin + Vector3(0, 0, lift)
	_mesh("Cords", cords, _string_mat, {"ids": cord_ids, "ranges": cord_ranges, "rings": 2, "sides": CORD_SIDES})
	var rods := _Acc.new()
	var rod_depths: Array = depths.keys()
	rod_depths.sort()
	var half := float(spec.get("w", 1.0)) / 2.0 + FRAME
	var ry := float(spec.get("h", 1.0)) / 2.0 + ROD_R
	for z in rod_depths:
		_tube(rods, [Vector3(-half, ry, float(z)), Vector3(half, ry, float(z))], ROD_R, ROD_SIDES, ROD_COLOUR, Vector3.UP)
	_mesh("Rods", rods, _rod_mat, {"depths": rod_depths})
	# THE PINS: a red head where a cord or a thread meets a sticker
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
	var heads: Array = pinned.values()
	pins_node.multimesh.instance_count = heads.size()
	for i in heads.size():
		pins_node.multimesh.set_instance_transform(i, Transform3D(Basis(), heads[i]))
	pins_node.visible = heads.size() > 0
	rebuild_ms = float(Time.get_ticks_usec() - t0) / 1000.0
	redraws += 1

## How far a string of radius r is lifted along +Z where it meets a sticker at depth z: off the paper (a sticker on
## it lies LIFT over it), nothing for one that hangs clear of it.
static func _off_paper(z: float, r: float) -> float:
	return maxf(0.0, StickerLayer.LIFT + r + 0.0005 - z)

static func _colour(hex: String) -> Color:
	return Color(hex) if Color.html_is_valid(hex) else Color(StickerData.THREAD_RED)

func _materials(paper: Color) -> void:
	if _string_mat == null:
		_string_mat = StandardMaterial3D.new()
		_string_mat.vertex_color_use_as_albedo = true
		_string_mat.vertex_color_is_srgb = true
		_string_mat.roughness = 0.85
		_rod_mat = StandardMaterial3D.new()
		_rod_mat.albedo_color = ROD_COLOUR
		_rod_mat.metallic = 0.55
		_rod_mat.roughness = 0.4
		_pin_mat = StandardMaterial3D.new()
		_pin_mat.albedo_color = PIN_COLOUR
		_pin_mat.roughness = 0.35
		var sh := Shader.new()
		sh.code = CARD_SHADER
		_card_mat = ShaderMaterial.new()
		_card_mat.shader = sh
		_card_mat.set_shader_parameter("paper", TAG_PAPER)
		_card_mat.set_shader_parameter("edge", TAG_EDGE)
		_font = FontVariation.new()
		_font.base_font = ThemeDB.fallback_font
		_font.variation_embolden = 0.55
		_font.spacing_glyph = 3
	_card_mat.set_shader_parameter("hole", paper)

## One tag: its node by the thread's id (kept from one redraw to the next), the word in capitals on its card.
func _tag(tid: String, word: String, at: Vector3) -> void:
	var holder := get_node_or_null("Tags") as Node3D
	if holder == null:
		holder = Node3D.new()
		holder.name = "Tags"
		add_child(holder)
	var tag: Node3D = _tags.get(tid)
	if tag == null:
		tag = Node3D.new()
		tag.name = "Tag_" + tid
		holder.add_child(tag)
		var card := MeshInstance3D.new()
		card.name = "Card"
		card.mesh = QuadMesh.new()
		card.material_override = _card_mat
		card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		card.extra_cull_margin = 0.3
		tag.add_child(card)
		var label := Label3D.new()
		label.name = "Word"
		label.font = _font
		label.font_size = TAG_FONT
		label.pixel_size = TAG_PIXEL
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.double_sided = true
		label.shaded = false
		label.modulate = TAG_INK
		label.outline_size = 0
		label.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
		label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tag.add_child(label)
		_tags[tid] = tag
	tag.position = at
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

## One mesh child of this node, made again from an accumulator (empty: no surface), with metas for probes.
func _mesh(node_name: String, acc: _Acc, mat: Material, metas: Dictionary) -> void:
	var mi := get_node_or_null(node_name) as MeshInstance3D
	if mi == null:
		mi = MeshInstance3D.new()
		mi.name = node_name
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	var mesh := ArrayMesh.new()
	if not acc.idx.is_empty():
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = acc.verts
		arrays[Mesh.ARRAY_NORMAL] = acc.norms
		arrays[Mesh.ARRAY_COLOR] = acc.cols
		arrays[Mesh.ARRAY_INDEX] = acc.idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mi.mesh = mesh
	mi.material_override = mat
	for k in metas:
		mi.set_meta(k, metas[k])

## A tube along the points: a ring of `sides` round each (ring by ring, `sides` vertices each: probes read them so), its
## axes the curve's tangent and `side` (a curve is drawn in one plane, so one side vector for all its rings: no twist),
## wound to face out. Its quads all turn the same way, so the winding is read once, off the first triangle: Godot's
## front face is clockwise seen from outside, (b - a) x (c - a) pointing into the tube. (A winding read per triangle
## made the mind map's 31 threads cost 14 ms a redraw, most of it here.)
static func _tube(acc: _Acc, pts: Array, r: float, sides: int, colour: Color, side: Vector3) -> void:
	var n := pts.size()
	if n < 2 or sides < 3:
		return
	var base := acc.verts.size()
	var ring_c := PackedFloat32Array()
	var ring_s := PackedFloat32Array()
	ring_c.resize(sides)
	ring_s.resize(sides)
	for k in sides:
		ring_c[k] = cos(TAU * float(k) / float(sides))
		ring_s[k] = sin(TAU * float(k) / float(sides))
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	verts.resize(n * sides)
	norms.resize(n * sides)
	var vi := 0
	for i in n:
		var here: Vector3 = pts[i]
		var tangent: Vector3 = (Vector3(pts[mini(i + 1, n - 1)]) - Vector3(pts[maxi(i - 1, 0)])).normalized()
		var a := side - tangent * side.dot(tangent)
		if a.length() < 1e-6:
			a = tangent.cross(Vector3.RIGHT) if absf(tangent.x) < 0.9 else tangent.cross(Vector3.UP)
		a = a.normalized()
		var b := tangent.cross(a).normalized()
		for k in sides:
			var out := a * ring_c[k] + b * ring_s[k]
			verts[vi] = here + out * r
			norms[vi] = out
			vi += 1
	# the first triangle (v0, v2, v1) of the first quad: wound as it stands unless its face turns out of the tube
	var flip := (verts[sides] - verts[0]).cross(verts[1] - verts[0]).dot(norms[0] + norms[sides] + norms[1]) > 0.0
	var idx := PackedInt32Array()
	idx.resize((n - 1) * sides * 6)
	var ii := 0
	for i in n - 1:
		for k in sides:
			var v0 := base + i * sides + k
			var v1 := base + i * sides + (k + 1) % sides
			var v2 := v0 + sides
			var v3 := v1 + sides
			if flip:
				idx[ii] = v0; idx[ii + 1] = v1; idx[ii + 2] = v2
				idx[ii + 3] = v1; idx[ii + 4] = v3; idx[ii + 5] = v2
			else:
				idx[ii] = v0; idx[ii + 1] = v2; idx[ii + 2] = v1
				idx[ii + 3] = v1; idx[ii + 4] = v2; idx[ii + 5] = v3
			ii += 6
	var cols := PackedColorArray()
	cols.resize(n * sides)
	cols.fill(colour)
	acc.verts.append_array(verts)
	acc.norms.append_array(norms)
	acc.cols.append_array(cols)
	acc.idx.append_array(idx)

class _Acc:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
