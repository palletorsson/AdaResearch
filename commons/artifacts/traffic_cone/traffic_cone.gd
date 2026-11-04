extends Node3D
## THE TRAFFIC CONE (Palle, 2026-11-04, two pictures: a cone "like in the image" under each array cube, and "an
## assortment of cones" among the columns). One procedural family: an orange frustum with a flat tip, no, one or two
## white reflective bands, on a square base plate with cut corners or a round one; or a delineator POST, a tall thin
## cylinder banded near its top. One merged mesh with vertex colours - one draw - shared by every cone of the same
## settings, and a solid collider: a StaticBody, or (body "pickable") an XR Tools pickable that stands frozen until a
## hand takes it and is a Jolt body from then on.
##   config: style plain|band|bands|post, height (m), base square|round|none, wear 0..1 (the base's grime),
##           body static|pickable

const ORANGE := Color("f2671f")
const WHITE := Color("ececea")
const GRIME := Color("3b3633")
const SEGMENTS := 20

@export_enum("plain", "band", "bands", "post") var style := "bands"
@export var height := 0.7
@export_enum("square", "round", "none") var base := "square"
@export_range(0.0, 1.0) var wear := 0.0
@export_enum("static", "pickable") var body := "static"

static var _meshes: Dictionary = {}   # settings -> ArrayMesh, shared
var _built := ""

func apply_grid_config(config: Dictionary) -> void:
	if config.has("style") and str(config.style) in ["plain", "band", "bands", "post"]: style = str(config.style)
	if config.has("height"): height = clampf(float(config.height), 0.1, 3.0)
	if config.has("base") and str(config.base) in ["square", "round", "none"]: base = str(config.base)
	if config.has("wear"): wear = clampf(float(config.wear), 0.0, 1.0)
	if config.has("body") and str(config.body) in ["static", "pickable"]: body = str(config.body)
	if is_inside_tree(): _build()

func _ready() -> void:
	var cfg := {}
	for key in ["style", "height", "base", "wear", "body"]:
		if has_meta("config_" + key): cfg[key] = get_meta("config_" + key)
	apply_grid_config(cfg)
	_build()

func signature() -> String:
	return "%s|%.3f|%s|%.2f" % [style, height, base, wear]

## The proportions, from the pictures: a cone's foot is ~0.42 of its height across, its plate ~1.35 of the foot;
## a post is a 0.08 of its height across, its round foot three times that.
func _dims() -> Dictionary:
	var post := style == "post"
	var plate_h: float = 0.0 if base == "none" else clampf(height * .04, .015, .04)
	var foot_r: float = height * (.04 if post else .21)
	var plate_r: float = foot_r * (3.0 if post else 1.35)
	return {"post": post, "plate_h": plate_h, "foot_r": foot_r, "tip_r": foot_r if post else height * .035, "plate_r": plate_r}

func _build() -> void:
	var sig := signature() + "|" + body
	if sig == _built: return
	_built = sig
	for c in get_children(): remove_child(c);c.queue_free()
	var d := _dims()
	var mi := MeshInstance3D.new();mi.name = "Cone";mi.mesh = mesh_for(self)
	var holder: Node3D = self
	if body == "pickable" and ResourceLoader.exists("res://addons/godot-xr-tools/objects/pickable.tscn"):
		var pk: RigidBody3D = (load("res://addons/godot-xr-tools/objects/pickable.tscn") as PackedScene).instantiate()
		for c in pk.get_children():
			if c is CollisionShape3D and (c as CollisionShape3D).shape == null: c.free()
		pk.name = "Body";pk.mass = 1.0 if not d.post else 2.0
		pk.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC;pk.freeze = true   # stands where it is put until a hand takes it
		add_child(pk);holder = pk
	else:
		var sb := StaticBody3D.new();sb.name = "Body";sb.collision_layer = 1;add_child(sb);holder = sb
	holder.add_child(mi)
	for shape in _shapes(d):holder.add_child(shape)

## The mesh for a cone's settings, made once and shared.
static func mesh_for(c: Node) -> ArrayMesh:
	var sig: String = c.signature()
	if _meshes.has(sig): return _meshes[sig]
	var d: Dictionary = c._dims()
	var h: float = c.height
	var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base_col: Color = ORANGE.lerp(GRIME, .15 + .75 * float(c.wear))
	var y0: float = d.plate_h
	if c.base == "square":
		var r: float = d.plate_r;var cut: float = r * .28
		var pts := [Vector2(-r + cut, -r), Vector2(r - cut, -r), Vector2(r, -r + cut), Vector2(r, r - cut), Vector2(r - cut, r), Vector2(-r + cut, r), Vector2(-r, r - cut), Vector2(-r, -r + cut)]
		_prism(st, pts, 0.0, y0, base_col)
	elif c.base == "round":
		_frustum(st, 0.0, y0, d.plate_r, d.plate_r, base_col, true, true)
	# the bands as fractions of the body above the plate
	var bands: Array = []
	match c.style:
		"band":bands = [[.46, .62]]
		"bands":bands = [[.30, .44], [.58, .72]]
		"post":bands = [[.74, .80], [.86, .92]]
	var cuts: Array = [0.0]
	for b in bands:cuts.append_array(b)
	cuts.append(1.0)
	var body_h: float = h - y0
	for i in cuts.size() - 1:
		var f0: float = cuts[i];var f1: float = cuts[i + 1]
		var white: bool = false
		for b in bands:
			if is_equal_approx(f0, b[0]):white = true
		var r0: float = lerpf(d.foot_r, d.tip_r, f0);var r1: float = lerpf(d.foot_r, d.tip_r, f1)
		_frustum(st, y0 + body_h * f0, y0 + body_h * f1, r0, r1, WHITE if white else ORANGE, i == 0, i == cuts.size() - 2)
	st.generate_normals()
	var m := st.commit()
	var mat := StandardMaterial3D.new();mat.vertex_color_use_as_albedo = true;mat.roughness = .55
	m.surface_set_material(0, mat)
	_meshes[sig] = m
	return m

## A ring band between two heights, its own colour; caps where asked (flat bottom, flat tip).
static func _frustum(st: SurfaceTool, ya: float, yb: float, ra: float, rb: float, col: Color, cap_a: bool, cap_b: bool) -> void:
	st.set_color(col)
	for i in SEGMENTS:
		var a0 := TAU * i / SEGMENTS;var a1 := TAU * (i + 1) / SEGMENTS
		var p0 := Vector3(cos(a0) * ra, ya, sin(a0) * ra);var p1 := Vector3(cos(a1) * ra, ya, sin(a1) * ra)
		var q0 := Vector3(cos(a0) * rb, yb, sin(a0) * rb);var q1 := Vector3(cos(a1) * rb, yb, sin(a1) * rb)
		st.add_vertex(p0);st.add_vertex(q1);st.add_vertex(q0)
		st.add_vertex(p0);st.add_vertex(p1);st.add_vertex(q1)
		if cap_a:st.add_vertex(Vector3(0, ya, 0));st.add_vertex(p1);st.add_vertex(p0)
		if cap_b:st.add_vertex(Vector3(0, yb, 0));st.add_vertex(q0);st.add_vertex(q1)

## A flat plate from a 2D outline (x, z), between two heights.
static func _prism(st: SurfaceTool, pts: Array, ya: float, yb: float, col: Color) -> void:
	st.set_color(col)
	var n: int = pts.size()
	for i in n:
		var a: Vector2 = pts[i];var b: Vector2 = pts[(i + 1) % n]
		var a0 := Vector3(a.x, ya, a.y);var b0 := Vector3(b.x, ya, b.y);var a1 := Vector3(a.x, yb, a.y);var b1 := Vector3(b.x, yb, b.y)
		# Godot's front face is clockwise seen from outside: (b - a) x (c - a) points INTO the solid (as the frustum's sides)
		st.add_vertex(a0);st.add_vertex(b1);st.add_vertex(a1)
		st.add_vertex(a0);st.add_vertex(b0);st.add_vertex(b1)
		st.add_vertex(Vector3(0, yb, 0));st.add_vertex(a1);st.add_vertex(b1)
		st.add_vertex(Vector3(0, ya, 0));st.add_vertex(b0);st.add_vertex(a0)

## The solid: the plate as a thin box or disc, the body as a convex frustum (a post: a cylinder).
func _shapes(d: Dictionary) -> Array:
	var out: Array = []
	if base != "none":
		var plate := CollisionShape3D.new();plate.name = "Plate"
		if base == "square":var bs := BoxShape3D.new();bs.size = Vector3(d.plate_r * 2, d.plate_h, d.plate_r * 2);plate.shape = bs
		else:var cs := CylinderShape3D.new();cs.radius = d.plate_r;cs.height = d.plate_h;plate.shape = cs
		plate.position.y = d.plate_h * .5;out.append(plate)
	var body_shape := CollisionShape3D.new();body_shape.name = "Frustum"
	if d.post:
		var cyl := CylinderShape3D.new();cyl.radius = d.foot_r;cyl.height = height - d.plate_h;body_shape.shape = cyl
		body_shape.position.y = d.plate_h + (height - d.plate_h) * .5
	else:
		var pts := PackedVector3Array()
		for i in 12:
			var a := TAU * i / 12.0
			pts.append(Vector3(cos(a) * d.foot_r, d.plate_h, sin(a) * d.foot_r));pts.append(Vector3(cos(a) * d.tip_r, height, sin(a) * d.tip_r))
		var cv := ConvexPolygonShape3D.new();cv.points = pts;body_shape.shape = cv
	out.append(body_shape)
	return out
