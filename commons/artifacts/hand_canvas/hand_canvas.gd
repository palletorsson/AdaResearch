extends Node3D
class_name HandCanvas
## THE HAND CANVAS (Palle, 2026-10-30: "a large transparency canvas for hand painting. Imagine you have multiple
## indicators on your hands and you can touch the canvas with one or many - one finger, two fingers, three, or
## the whole hand - and the stroke changes"). A big pane of glass on uprights, like Point Trace's GlassWall, that
## the HANDS paint: every fingertip bone of every tracked hand (Thumb/Index/Middle/Ring/Little _Tip_L/R) and the
## knuckle under the middle finger are INDICATORS; one that comes within `touch_depth` of the face leaves a mark,
## and each frame it stays, a segment. How many of one hand's indicators touch at once decides the stroke:
## one fingertip a thin line, two a double-width one, three wider still, four a broad band, the whole hand (five
## tips and the knuckle) a soft wash. The touch band is asymmetric: `touch_depth` in front of the face and
## `press_depth` behind it, since a hand on a controller pushes through the glass rather than stopping at it. Left and right hands paint in their own colours. Paint accumulates in a
## SubViewport that never clears; the pane shows it through the glass. Pens mark it too (ada_writable_board).
## Config: width, height, px_per_m, touch_depth, left_colour, right_colour, wash_alpha.

@export var width := 4.0
@export var height := 2.5
@export var px_per_m := 320.0
@export var touch_depth := 0.025
## how far THROUGH the glass an indicator still counts: a hand holding a controller cannot stop at the glass, it
## goes in, and an open hand pressed to its knuckle has its relaxed fingertips 5-6 cm past the face (measured)
@export var press_depth := 0.08
@export var left_colour := Color("3ab0ff")
@export var right_colour := Color("ff9a3c")
@export var wash_alpha := 0.35
## stroke width in metres for 1, 2, 3, 4 and 5+ touching indicators
@export var widths: PackedFloat32Array = PackedFloat32Array([0.012, 0.028, 0.05, 0.08, 0.14])
@export var glass_tint := Color(0.78, 0.9, 0.95, 0.14)

const TIPS := ["Thumb_Tip", "Index_Tip", "Middle_Tip", "Ring_Tip", "Little_Tip"]
const KNUCKLE := "Middle_Proximal"
const SURFACE_THICKNESS := 0.012

var _vp: SubViewport
var _paint: Node2D
var _pending: Array = []            # segments to draw this frame: {a: Vector2, b: Vector2, w: float, col: Color}
var _last: Dictionary = {}          # indicator key -> last touch (Vector2 px)
var _hands: Array = []              # {skel: Skeleton3D, side: "L"/"R", tips: Array[int], knuckle: int}
var _scan_t := 0.0
var touching: Dictionary = {"L": 0, "R": 0}   # indicators of each hand on the glass this frame
var marks := 0                      # segments drawn so far
var _pane: MeshInstance3D

func _ready() -> void:
	add_to_group("ada_writable_board")
	_build()

func apply_grid_config(config: Dictionary) -> void:
	width = clampf(float(config.get("width", width)), 1.0, 12.0)
	height = clampf(float(config.get("height", height)), 1.0, 4.0)
	px_per_m = clampf(float(config.get("px_per_m", px_per_m)), 64.0, 800.0)
	touch_depth = clampf(float(config.get("touch_depth", touch_depth)), 0.005, 0.1)
	press_depth = clampf(float(config.get("press_depth", press_depth)), 0.0, 0.3)
	wash_alpha = clampf(float(config.get("wash_alpha", wash_alpha)), 0.05, 1.0)
	if config.has("left_colour"):left_colour = Color(str(config.left_colour))
	if config.has("right_colour"):right_colour = Color(str(config.right_colour))
	if is_inside_tree():
		for c in get_children():remove_child(c);c.queue_free()
		_build()

func _build() -> void:
	# the paint: a viewport that never clears, drawn into by a Node2D that draws only what is new
	_vp = SubViewport.new();_vp.name = "Paint";_vp.size = Vector2i(int(width * px_per_m), int(height * px_per_m));_vp.transparent_bg = true
	_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER;_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS;_vp.disable_3d = true
	add_child(_vp)
	_paint = Node2D.new();_paint.name = "Strokes";_paint.draw.connect(_draw_pending);_vp.add_child(_paint)
	# the pane: glass with the paint on it, facing +Z
	_pane = MeshInstance3D.new();_pane.name = "Pane";var quad := QuadMesh.new();quad.size = Vector2(width, height);_pane.mesh = quad
	var m := StandardMaterial3D.new();m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color.WHITE;m.albedo_texture = _vp.get_texture();_pane.material_override = m;_pane.position = Vector3(0, height / 2, SURFACE_THICKNESS);add_child(_pane)
	var glass := MeshInstance3D.new();glass.name = "Glass";var gq := QuadMesh.new();gq.size = Vector2(width, height);glass.mesh = gq
	var gm := StandardMaterial3D.new();gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;gm.albedo_color = glass_tint;gm.roughness = .1;gm.metallic = .2;gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.material_override = gm;glass.position = Vector3(0, height / 2, 0);add_child(glass)
	# the frame, as Point Trace's glass wall: two uprights on feet, a lit edge
	for x in [-width / 2 - .03, width / 2 + .03]:
		_box("Upright", Vector3(x, height / 2, 0), Vector3(.06, height + .1, .08), Color("737d7c"))
		_box("Foot", Vector3(x, .02, 0), Vector3(.34, .04, .7), Color("737d7c"))
	_box("Top", Vector3(0, height + .05, 0), Vector3(width + .12, .04, .06), Color("9fb3b1"))
	# a body the pointer and a placing ray can hit; it stands on the floor
	var body := StaticBody3D.new();body.name = "GlassContact";body.collision_layer = 1
	var cs := CollisionShape3D.new();var shape := BoxShape3D.new();shape.size = Vector3(width, height, .024);cs.shape = shape
	body.position = Vector3(0, height / 2, SURFACE_THICKNESS);body.add_child(cs);add_child(body)
	var label := Label3D.new();label.text = "HAND CANVAS · touch with one finger, two, the whole hand";label.font_size = 26;label.pixel_size = .0025
	label.modulate = Color("9fb3b1");label.position = Vector3(0, -.06, .06);add_child(label)
	_hands.clear();_last.clear();marks = 0

func _box(n: String, at: Vector3, size: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new();mi.name = n;var b := BoxMesh.new();b.size = size;mi.mesh = b
	var m := StandardMaterial3D.new();m.albedo_color = col;m.roughness = .6;m.metallic = .3;mi.material_override = m;mi.position = at;add_child(mi)

## The writing face in GLOBAL space, as the whiteboard answers the pen (draw_dot.gd).
func write_surfaces() -> Array:
	var xf := global_transform
	return [{"origin": xf * Vector3(0, height / 2, SURFACE_THICKNESS), "normal": (xf.basis * Vector3(0, 0, 1)).normalized(),
		"u": (xf.basis * Vector3(1, 0, 0)).normalized(), "v": (xf.basis * Vector3(0, 1, 0)).normalized(), "half_w": width / 2, "half_h": height / 2}]

## Every tracked hand in the tree: a Skeleton3D with fingertip bones. Looked for once a second.
func _scan_hands() -> void:
	_hands.clear()
	for sk in get_tree().root.find_children("*", "Skeleton3D", true, false):
		var s := sk as Skeleton3D;var side := ""
		for sfx in ["L", "R"]:
			if s.find_bone("Index_Tip_" + sfx) >= 0:side = sfx
		if side == "":continue
		var tips: Array = []
		for t in TIPS:
			var i := s.find_bone(t + "_" + side)
			if i >= 0:tips.append(i)
		_hands.append({"skel": s, "side": side, "tips": tips, "knuckle": s.find_bone(KNUCKLE + "_" + side)})

func _physics_process(delta: float) -> void:
	_scan_t -= delta
	if _scan_t <= 0.0:_scan_hands();_scan_t = 1.0
	var touched_now: Dictionary = {}
	touching = {"L": 0, "R": 0}
	var per_hand: Dictionary = {}   # side -> [{key, px}]
	for h in _hands:
		var s: Skeleton3D = h.skel
		if not is_instance_valid(s) or not s.is_inside_tree():continue
		var points: Array = []
		var bones: Array = h.tips.duplicate()
		if h.knuckle >= 0:bones.append(h.knuckle)
		for i in bones:
			var g: Vector3 = s.global_transform * s.get_bone_global_pose(i).origin
			var l: Vector3 = to_local(g)
			var d: float = l.z - SURFACE_THICKNESS   # + in front of the face, - pushed through it
			if d > touch_depth or d < -press_depth or absf(l.x) > width / 2 or l.y < 0 or l.y > height:continue
			points.append({"key": str(s.get_instance_id()) + ":" + str(i), "px": Vector2((l.x + width / 2) * px_per_m, (height - l.y) * px_per_m)})
		if not points.is_empty():per_hand[h.side] = (per_hand.get(h.side, []) as Array) + points
	for side in per_hand:
		var points: Array = per_hand[side];var n: int = points.size();touching[side] = n
		var w: float = widths[clampi(n, 1, widths.size()) - 1] * px_per_m
		var col: Color = left_colour if side == "L" else right_colour
		if n >= 5:col.a = wash_alpha   # the whole hand: a wash
		for p in points:
			var a: Vector2 = _last.get(p.key, p.px)
			_pending.append({"a": a, "b": p.px, "w": w, "col": col});touched_now[p.key] = p.px
	_last = touched_now
	if not _pending.is_empty():_paint.queue_redraw()

func _draw_pending() -> void:
	for seg in _pending:
		if seg.a.distance_to(seg.b) < .5:_paint.draw_circle(seg.b, seg.w / 2, seg.col)
		else:
			_paint.draw_line(seg.a, seg.b, seg.col, seg.w, true)
			_paint.draw_circle(seg.a, seg.w / 2, seg.col);_paint.draw_circle(seg.b, seg.w / 2, seg.col)
		marks += 1
	_pending.clear()

## For looking and for probes: the paint as an image (the viewport's texture).
func image() -> Image:
	return _vp.get_texture().get_image()

## Everything wiped: the viewport is cleared once, with the paint redrawn empty that frame so the clear lands.
func clear() -> void:
	_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE;_last.clear();_pending.clear();marks = 0;_paint.queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
