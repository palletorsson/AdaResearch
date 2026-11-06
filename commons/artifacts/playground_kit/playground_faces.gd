extends Node3D
## WHAT THE KIT HAS MADE, SHOWN (the Triangle stage, Palle 2026-11-06). One per scene, made by the support graph
## (PlaygroundBall.reevaluate) only when a ball on the stage has `rigidity` "bars" - a map without the stage never
## gets one. For every connected piece of held balls and rods it shows three things:
##   - FACES: a pale panel across every triangle of rods and every square with no rod across it; pink while the face
##     can still move, ivory once every corner is fixed;
##   - THE FREE MOTION: a ball the bars do not fix rocks gently along the motion that is left to it (its rods and faces
##     follow), so the shear of an unbraced square is SEEN, and stops when the brace goes in. Only what is drawn moves:
##     the bodies stay on their grid points, held by the scaffold, so building is never undone by the lesson;
##   - THE COUNT: "4 points (2 on the floor) / 5 rods / 1 free motion" over the piece.
## The arithmetic is kit_rigidity.gd's.

const AMPLITUDE := .035   ## metres: the largest rock, a gesture rather than a collapse
const RATE := .8          ## rocks a second

var pieces: Array = []    # {balls: Array[Node3D], rods: Array[Node3D], bars: Array[Vector2i], rod_ends: Array, flexible, mode, free_motions, anchored, faces}
var _t := 0.0
var _mesh := ImmediateMesh.new()
var _labels: Array[Label3D] = []
var _rigid_mat: StandardMaterial3D
var _flex_mat: StandardMaterial3D
var _moving := false

func _init() -> void:
	top_level = true   # at the world's origin whatever it hangs under: positions below are world positions

func _ready() -> void:
	name = "PlaygroundFaces"
	var mi := MeshInstance3D.new();mi.name = "Faces";mi.mesh = _mesh;mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mi)
	_rigid_mat = _mat(Color(.96, .93, .86, .62))
	_flex_mat = _mat(Color(.92, .45, .67, .38))
	_redraw()

static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new();m.albedo_color = c;m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;m.roughness = .7
	return m

## The support graph's latest word. Visuals of what was shown before go back to rest first.
func show_kit(new_pieces: Array) -> void:
	_rest_all()
	pieces = new_pieces
	_moving = false
	for p in pieces:
		if p.free_motions > 0:_moving = true
	for l in _labels:l.queue_free()
	_labels.clear()
	for p in pieces:
		var l := Label3D.new();l.billboard = BaseMaterial3D.BILLBOARD_ENABLED;l.font_size = 40;l.pixel_size = .0022
		l.outline_size = 8;l.modulate = Color(1, 1, 1) if p.free_motions == 0 else Color(1, .62, .8)
		l.text = count_text(p);l.no_depth_test = false
		var top := -INF;var centre := Vector3.ZERO
		for b in p.balls:top = maxf(top, b.global_position.y);centre += b.global_position
		centre /= maxf(1, p.balls.size())
		l.position = Vector3(centre.x, top + .32, centre.z);add_child(l)
		_labels.append(l)
	if is_inside_tree():_redraw()

static func count_text(p: Dictionary) -> String:
	var on_floor := 0
	for a in p.anchored:
		if a:on_floor += 1
	var motions := "rigid" if p.free_motions == 0 else ("1 free motion" if p.free_motions == 1 else "%d free motions" % p.free_motions)
	return "%d points (%d on the floor) / %d rods / %s" % [p.balls.size(), on_floor, p.bars.size(), motions]

func _process(delta: float) -> void:
	if not _moving:return
	_t += delta
	var s := sin(_t * TAU * RATE) * AMPLITUDE
	for p in pieces:
		if p.free_motions == 0:continue
		for i in p.balls.size():
			if is_instance_valid(p.balls[i]):_offset_ball(p.balls[i], p.mode[i] * s)
		for k in p.rods.size():
			var rod: Node3D = p.rods[k]
			if not is_instance_valid(rod):continue
			var bar: Vector2i = p.bars[k];var ends: Vector2i = p.rod_ends[k]   # ends.x is the rod end at bar.x's ball
			var off := {ends.x: p.mode[bar.x] * s, ends.y: p.mode[bar.y] * s}
			_offset_rod(rod, off.get(0, Vector3.ZERO), off.get(1, Vector3.ZERO))
	_redraw(s)

## The ball's meshes (not its body) moved by `v`.
static func _offset_ball(ball: Node3D, v: Vector3) -> void:
	for c in ball.get_children():
		if c is MeshInstance3D:
			if not c.has_meta("kit_rest"):c.set_meta("kit_rest", c.position)
			c.position = c.get_meta("kit_rest") + ball.global_basis.inverse() * v

## The rod's meshes laid between its two ends moved by v0 and v1.
static func _offset_rod(rod: Node3D, v0: Vector3, v1: Vector3) -> void:
	var e0: Vector3 = rod.end_global(0) + v0;var e1: Vector3 = rod.end_global(1) + v1
	var axis := (e1 - e0).normalized()
	var up := Vector3.UP if absf(axis.dot(Vector3.UP)) < .9 else Vector3.BACK
	var z := axis.cross(up).normalized();var y := z.cross(axis).normalized()
	var local := rod.global_transform.affine_inverse() * Transform3D(Basis(axis, y, z), (e0 + e1) / 2.0)
	for c in rod.get_children():
		if c is MeshInstance3D:
			if not c.has_meta("kit_rest"):c.set_meta("kit_rest", c.transform)
			c.transform = local * (c.get_meta("kit_rest") as Transform3D)

func _rest_all() -> void:
	for p in pieces:
		for n in p.balls + p.rods:
			if not is_instance_valid(n):continue
			for c in n.get_children():
				if c is MeshInstance3D and c.has_meta("kit_rest"):
					var rest: Variant = c.get_meta("kit_rest")
					if rest is Transform3D:c.transform = rest
					else:c.position = rest
					c.remove_meta("kit_rest")

## Every face, twice (both windings, each with its own normal: a culled-off face would light its back wrong).
func _redraw(s := 0.0) -> void:
	_mesh.clear_surfaces()
	for rigid_pass in [true, false]:
		var tris: Array = []
		for p in pieces:
			for f: Array in p.faces:
				var rigid := true
				for i in f:
					if p.flexible[i]:rigid = false
				if rigid != rigid_pass:continue
				var pts: Array[Vector3] = []
				for i in f:
					var b: Node3D = p.balls[i]
					if not is_instance_valid(b):pts.clear();break
					pts.append(b.global_position + p.mode[i] * s)
				if pts.is_empty():continue
				var c := Vector3.ZERO
				for q in pts:c += q
				c /= pts.size()
				for k in pts.size():pts[k] = c + (pts[k] - c) * .86   # inside the balls
				for k in range(1, pts.size() - 1):tris.append([pts[0], pts[k], pts[k + 1]])
		if tris.is_empty():continue
		_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _rigid_mat if rigid_pass else _flex_mat)
		for t in tris:
			# Godot's front face winds CLOCKWISE as seen, so its normal is minus the right-hand cross product
			var n: Vector3 = -(t[1] - t[0]).cross(t[2] - t[0]).normalized()
			for v in [t[0], t[1], t[2]]:_mesh.surface_set_normal(n);_mesh.surface_add_vertex(v)
			for v in [t[0], t[2], t[1]]:_mesh.surface_set_normal(-n);_mesh.surface_add_vertex(v)
		_mesh.surface_end()
