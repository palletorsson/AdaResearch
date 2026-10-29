extends Node3D
## A contextual map of sticky notes on a pinboard, drawn from commons/data/sticky_maps/<map>.json: the same
## file the encyclopedia's /sticky-map edits and draws in three.js, by the same rules (ada_encyclopedia
## src/lib/sticky-map.ts; the numbers below are copied from it). The board watches its file once a second
## and redraws when a save changes it. A copy at user://sticky_maps/<map>.json is read first (where a
## headset's copy will land); res:// is read-only in an export, so on the Quest the watch finds nothing yet.
## Origin: the floor, under the middle of the board; the notes face +Z. A board with shape "arc" bends round a
## vertical axis `radius` in front of its middle (a half-cylinder when width = PI * radius): its middle stays at the
## origin, its ends come round towards +Z, the stickers bend with it, and its threads run head to head through the air.
@export var map_id := "ai_assemblage"

const KIND := {
	"argument": [0.8, 0.52, "f4f0e6", "1d1d1f"], "proposition": [0.72, 0.46, "f2a65a", "1d1d1f"],
	"concept": [0.46, 0.46, "f6dc6b", "1d1d1f"], "minus": [0.46, 0.46, "2b2b2b", "f4f0e6"],
	"history": [0.44, 0.44, "9cc7e8", "1d1d1f"], "void": [0.48, 0.48, "ec8fba", "1d1d1f"],
	"question": [0.44, 0.44, "a8d89a", "1d1d1f"], "purpose": [0.44, 0.44, "d9d4ca", "1d1d1f"],
	"note": [0.4, 0.4, "f6dc6b", "1d1d1f"]}
const CORK := "b98d5f"
const FRAME := "c9a978"
const BOARD_DEPTH := 0.03
const FRAME_WIDTH := 0.08
const FACE_PX := 512
const PIN_R := 0.018
const PIN_COLOR := "c0392b"
const PIN_INSET := 0.04
const THREAD := {"thread": [0.004, "b3261e"], "traverses": [0.0025, "3a3a3a"]}
const THREAD_COLOURS := {"red": "b3261e", "black": "2b2b2b", "blue": "2a5db0", "yellow": "e0b000", "white": "f4f0e6"}
## a needle: a round head on a steel shaft into the cork (the stickers' own and the ones pushed in alone)
const NEEDLE_HEAD := 0.018
const NEEDLE_SHAFT := 0.003
const NEEDLE_STEEL := "b8bcc2"
const NOTE_Z := 0.012
const THREAD_Z := 0.006   # just behind the paper: threads come out at the pins and the notes stay readable

var map: Dictionary = {}
var _path := ""
var _stamp := -1
var _since := 0.0
var _bold: FontVariation
var _radius := 0.0   # an arc board's radius; 0 is a flat board

func apply_grid_config(config: Dictionary) -> void:
	map_id = str(config.get("map", map_id))

func _ready() -> void:
	_bold = FontVariation.new();_bold.base_font = ThemeDB.fallback_font;_bold.variation_embolden = 0.7
	_reload()

func _file() -> String:
	var user := "user://sticky_maps/%s.json" % map_id
	return user if FileAccess.file_exists(user) else "res://commons/data/sticky_maps/%s.json" % map_id

func _process(delta: float) -> void:
	_since += delta
	if _since < 1.0:return
	_since = 0.0
	var path := _file();var stamp := FileAccess.get_modified_time(path)
	if path != _path or (stamp != 0 and stamp != _stamp):_reload()

func _reload() -> void:
	_path = _file();_stamp = FileAccess.get_modified_time(_path)
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_path)) if FileAccess.file_exists(_path) else null
	if not data is Dictionary:return
	map = data
	for c in get_children():
		remove_child(c);c.queue_free()   # out before the new ones come in, so their names stay Note_<id>
	_build()

## A note's small turn on the board: the same hash of its id as the web page's tilt().
static func tilt(id: String) -> float:
	var h := 0
	for i in id.length():h = (h * 31 + id.unicode_at(i)) % 1000003
	return float((h % 41) - 20) / 10.0

static func pin_at(n: Dictionary) -> Vector2:
	var k: Array = KIND.get(str(n.kind), KIND.note)
	return Vector2(float(n.x), float(n.y) + float(k[1]) / 2.0 - PIN_INSET)

## Where a point of the board stands (x along it, y up, z out towards the viewer): the web page's bend(). A flat
## board is itself; an arc bends round its axis at (0, *, radius).
func bend(p: Vector3) -> Vector3:
	if _radius <= 0.0:return p
	var th := p.x / _radius;var r := _radius - p.z
	return Vector3(r * sin(th), p.y, _radius - r * cos(th))

## A small thing at board x stands on the arc unbent: the board turned and carried so that x lands on the curve.
func _rigid(x: float) -> Transform3D:
	if _radius <= 0.0:return Transform3D.IDENTITY
	var turn := Basis(Vector3.UP, -x / _radius)
	return Transform3D(turn, bend(Vector3(x, 0, 0)) - turn * Vector3(x, 0, 0))

## A primitive laid out in board space by `xform`, bent onto the arc, in the frame of `local`: its vertices, and its
## normals turned with them. Subdivide it along x first, or the curve is a polygon.
func _bent(prim: PrimitiveMesh, xform: Transform3D, local := Transform3D.IDENTITY) -> ArrayMesh:
	var arrays := prim.get_mesh_arrays();var inv := local.affine_inverse()
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX];var nr: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for i in v.size():
		var p := xform * v[i]
		v[i] = inv * bend(p);nr[i] = (inv.basis * (Basis(Vector3.UP, -p.x / _radius) * (xform.basis * nr[i]))).normalized()
	arrays[Mesh.ARRAY_VERTEX] = v;arrays[Mesh.ARRAY_NORMAL] = nr;arrays[Mesh.ARRAY_TANGENT] = null
	var am := ArrayMesh.new();am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays);return am

func _box(size: Vector3, at: Vector3, color: String, rough := 0.9) -> MeshInstance3D:
	var m := MeshInstance3D.new();var b := BoxMesh.new();b.size = size;m.mesh = b;m.position = at
	if _radius > 0.0:   # bent round the arc, in slices of 4 cm along it
		b.subdivide_width = int(ceil(size.x / .04));m.mesh = _bent(b, Transform3D(Basis(), at));m.position = Vector3.ZERO
	var mat := StandardMaterial3D.new();mat.albedo_color = Color(color);mat.roughness = rough;m.material_override = mat;add_child(m)
	return m

func _build() -> void:
	var b: Dictionary = map.get("board", {"width": 7.6, "height": 3.3, "bottom": 0.25})
	var w := float(b.width);var h := float(b.height);var bottom := float(b.bottom);var cy := bottom + h / 2.0
	_radius = float(b.get("radius", 0.0)) if str(b.get("shape", "flat")) == "arc" else 0.0
	var cork := _box(Vector3(w, h, BOARD_DEPTH), Vector3(0, cy, -BOARD_DEPTH / 2.0), CORK, .95);cork.name = "Cork"
	var body := StaticBody3D.new();var shape := CollisionShape3D.new()
	if _radius > 0.0:
		shape.shape = cork.mesh.create_trimesh_shape()   # the bent cork itself
	else:
		var bs := BoxShape3D.new();bs.size = Vector3(w + 2 * FRAME_WIDTH, h + 2 * FRAME_WIDTH, BOARD_DEPTH + .02)
		shape.shape = bs;shape.position = Vector3(0, cy, -BOARD_DEPTH / 2.0)
	body.add_child(shape);add_child(body)
	var fw := FRAME_WIDTH
	for f in [[w + 2 * fw, fw, 0.0, bottom + h + fw / 2.0], [w + 2 * fw, fw, 0.0, bottom - fw / 2.0], [fw, h, -w / 2.0 - fw / 2.0, cy], [fw, h, w / 2.0 + fw / 2.0, cy]]:
		_box(Vector3(f[0], f[1], BOARD_DEPTH + .02), Vector3(f[2], f[3], -BOARD_DEPTH / 2.0), FRAME, .7)
	for sx in [-w / 2.0 + .3, w / 2.0 - .3]:_box(Vector3(.08, bottom, .5), Vector3(sx, bottom / 2.0, -.1), FRAME, .7)
	var ends := {}   # a thread's end: a sticker's needle, or a needle on its own
	for n in map.get("notes", []):
		ends[str(n.id)] = pin_at(n)
		_note(n)
	for p in map.get("pins", []):
		ends[str(p.id)] = Vector2(float(p.x), float(p.y))
		_needle(Vector2(float(p.x), float(p.y)), str(p.get("color", PIN_COLOR))).name = "Needle_" + str(p.id)
	for l in map.get("links", []):
		if not ends.has(str(l.from)) or not ends.has(str(l.to)):continue
		var pa: Vector2 = ends[str(l.from)];var pc: Vector2 = ends[str(l.to)]
		var th: Array = THREAD.get(str(l.get("kind", "thread")), THREAD.thread)
		var colour: String = str(THREAD_COLOURS.get(str(l.get("color", "")), l.get("color", th[1])))
		if _radius > 0.0:   # head to head, through the air
			_rod(bend(Vector3(pa.x, pa.y, NOTE_Z + .014)), bend(Vector3(pc.x, pc.y, NOTE_Z + .014)), float(th[0]), colour)
		else:
			_rod(Vector3(pa.x, pa.y, THREAD_Z), Vector3(pc.x, pc.y, THREAD_Z), float(th[0]), colour)

func _note(n: Dictionary) -> void:
	var k: Array = KIND.get(str(n.kind), KIND.note);var nw := float(k[0]);var nh := float(k[1])
	var g := Node3D.new();g.name = "Note_" + str(n.id);g.position = Vector3(float(n.x), float(n.y), NOTE_Z);g.rotation.z = deg_to_rad(tilt(str(n.id)));add_child(g)
	g.set_meta("note_id", str(n.id))
	var flat := g.transform   # where the note lies in board space; on an arc it stands at its place on the curve and its paper bends
	if _radius > 0.0:g.transform = _rigid(float(n.x)) * flat
	var paper := MeshInstance3D.new();var pb := BoxMesh.new();pb.size = Vector3(nw, nh, .003);paper.mesh = pb
	if _radius > 0.0:
		pb.subdivide_width = int(ceil(nw / .02));paper.mesh = _bent(pb, flat, g.transform)
	var pm := StandardMaterial3D.new();pm.albedo_color = Color(str(k[2]));pm.roughness = .9;paper.material_override = pm;g.add_child(paper)
	# the face: 2D in 3D, title and text laid out in a SubViewport and worn as the note's front
	var W := FACE_PX;var H := int(round(FACE_PX * nh / nw));var m := W * .07
	var view := SubViewport.new();view.size = Vector2i(W, H);view.disable_3d = true;view.transparent_bg = false;view.render_target_update_mode = SubViewport.UPDATE_ONCE;g.add_child(view)
	var bg := ColorRect.new();bg.color = Color(str(k[2]));bg.position = Vector2.ZERO;bg.size = Vector2(W, H);view.add_child(bg)
	var col := VBoxContainer.new();col.position = Vector2(m, m);col.size = Vector2(W - 2 * m, H - 1.6 * m);col.clip_contents = true;col.add_theme_constant_override("separation", int(W * .09 * .35));view.add_child(col)
	for part in [[str(n.title), int(round(W * .09)), true], [str(n.short), int(round(W * .065)), false]]:
		var lab := Label.new();lab.text = part[0];lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;lab.custom_minimum_size.x = W - 2 * m
		lab.add_theme_font_size_override("font_size", part[1]);lab.add_theme_color_override("font_color", Color(str(k[3])))
		if part[2]:lab.add_theme_font_override("font", _bold)
		col.add_child(lab)
	var face := MeshInstance3D.new();var q := QuadMesh.new();q.size = Vector2(nw, nh);face.mesh = q;face.position.z = .0016
	if _radius > 0.0:
		q.subdivide_width = int(ceil(nw / .02));face.mesh = _bent(q, flat * Transform3D(Basis(), Vector3(0, 0, .0016)), g.transform);face.position = Vector3.ZERO
	var fm := StandardMaterial3D.new();fm.albedo_texture = view.get_texture();fm.roughness = .85;fm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR;face.material_override = fm;g.add_child(face)
	_needle(pin_at(n), PIN_COLOR)

func _needle(at: Vector2, head: String) -> Node3D:
	var root := Node3D.new();root.transform = _rigid(at.x);add_child(root)
	var shaft := MeshInstance3D.new();var c := CylinderMesh.new();c.top_radius = NEEDLE_SHAFT;c.bottom_radius = NEEDLE_SHAFT;c.height = NOTE_Z + .014;c.radial_segments = 8;shaft.mesh = c
	shaft.position = Vector3(at.x, at.y, (NOTE_Z + .014) / 2.0);shaft.rotation_degrees.x = 90
	var sm := StandardMaterial3D.new();sm.albedo_color = Color(NEEDLE_STEEL);sm.metallic = .8;sm.roughness = .3;shaft.material_override = sm;root.add_child(shaft)
	var ball := MeshInstance3D.new();var s := SphereMesh.new();s.radius = NEEDLE_HEAD;s.height = NEEDLE_HEAD * 2;ball.mesh = s;ball.position = Vector3(at.x, at.y, NOTE_Z + .014)
	var bm := StandardMaterial3D.new();bm.albedo_color = Color(head);bm.roughness = .35;ball.material_override = bm;root.add_child(ball)
	return root

func _rod(a: Vector3, b: Vector3, r: float, color: String) -> void:
	var d := b - a;if d.length() < .001:return
	var m := MeshInstance3D.new();var c := CylinderMesh.new();c.top_radius = r;c.bottom_radius = r;c.height = d.length();c.radial_segments = 8;m.mesh = c
	m.position = a + d * .5;m.basis = Basis(Quaternion(Vector3.UP, d.normalized()))
	var mat := StandardMaterial3D.new();mat.albedo_color = Color(color);mat.roughness = .8;m.material_override = mat;add_child(m)
