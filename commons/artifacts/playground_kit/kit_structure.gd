extends Node3D
## THE KIT, DRAWN AS MULTIMESHES (Palle, 2026-11-06: "if we create a really large playground we want the geometry as
## simple as possible", then "these should all be multimesh"). Every playground ball and rod in the main world is drawn
## here, in every state; a piece keeps its body, its collision and its own MeshInstance3D children (bounds, previews and
## the cost probe still read those), but they stay hidden. Two looks, chosen by what a piece is DOING:
##   - DETAILED - in the hand, loose, falling, or still able to move (flexible on the Triangle stage): foam, steel
##     sockets, steel core and foam sleeve, each one shared mesh for the whole scene. The instances are copied from the
##     piece's own (hidden) mesh children - their transforms and colours - so whatever moves those children (the Triangle
##     stage's wobble) moves the drawing too;
##   - BUILT - a ball with `fold` held on its point by the support graph, or a rod whose every end is in such a ball:
##     one low sphere, one thin tube. A built rod is frozen and stops its per-frame script.
## Six draws for the whole kit, whatever its size. Pieces register themselves (`track`, from their _build); the scene
## is redrawn once a frame when something changed (`mark`), and moving pieces are rewritten every frame.
## A piece in another viewport (a SubViewport preview) is left to draw itself. `enabled = false` (a probe's before)
## leaves every piece to its own meshes.

const FOAM := {"pale": "ededed", "pink": "ea72ab", "cyan": "5fd3e6", "steel": "2a2c30"}
const STEEL := "2a2c30"
const FOAM_R := .06          # the shared foam sphere's radius
const SOCKET_H := .035       # the shared socket boss's height (top .016, bottom .02 - the ball's own)
const CORE_R := .012
const SLEEVE_R := .03
const UNSUPPORTED := Color("f59e0b")   # a ball the node editor holds where nothing supports it yet
## What a kit piece costs the hand's budget (inventory_hand.gd spent/fits): the six multimeshes are paid once for the
## whole kit; triangles are the look's - the detailed ones measured (costs.json), the built ones these.
const KIT_DRAWS := 6
const BUILT_TRIANGLES := {"ball": 64, "rod": 12}

static var enabled := true
static var _current: Node = null

var pieces: Array = []         # every tracked ball and rod
var folded_balls: Array = []
var folded_rods: Array = []
var dirty := true
var _slots := {}               # piece -> Array of [MultiMesh, index, MeshInstance3D, scale Vector3]
var _mm := {}                  # role -> MultiMesh
var _built_ids := {}

## The scene's kit renderer, made on first use (added deferred: pieces register from inside their own _ready).
static func current(tree: SceneTree) -> Node:
	if is_instance_valid(_current) and not _current.is_queued_for_deletion():return _current
	if tree == null:return null
	var host: Node = tree.current_scene if tree.current_scene != null else tree.root
	_current = load("res://commons/artifacts/playground_kit/kit_structure.gd").new()
	host.add_child.call_deferred(_current)
	return _current

## A piece built its meshes: draw it here from now on.
static func track(piece: Node3D) -> void:
	if not enabled or not piece.is_inside_tree() or piece.get_viewport() != piece.get_tree().root:return
	var st := current(piece.get_tree())
	if piece not in st.pieces:
		st.pieces.append(piece)
		piece.tree_exiting.connect(func():st.untrack(piece), CONNECT_ONE_SHOT)
	st.dirty = true

## Something changed (the support graph walked again): redraw on the next frame.
static func mark(tree: SceneTree) -> void:
	if is_instance_valid(_current):_current.dirty = true

func untrack(piece: Node) -> void:
	pieces.erase(piece);_slots.erase(piece);dirty = true

func _init() -> void:
	top_level = true   # instance transforms are world transforms
	name = "PlaygroundStructure"
	var foam := StandardMaterial3D.new();foam.vertex_color_use_as_albedo = true;foam.vertex_color_is_srgb = true;foam.roughness = .88
	var steel := StandardMaterial3D.new();steel.albedo_color = Color(STEEL);steel.metallic = .6;steel.roughness = .35
	var sphere := SphereMesh.new();sphere.radius = FOAM_R;sphere.height = FOAM_R * 2;sphere.radial_segments = 24;sphere.rings = 12
	var socket := CylinderMesh.new();socket.top_radius = .016;socket.bottom_radius = .02;socket.height = SOCKET_H;socket.radial_segments = 12
	var core := CylinderMesh.new();core.top_radius = CORE_R;core.bottom_radius = CORE_R;core.height = 1.0;core.radial_segments = 12
	var sleeve := CylinderMesh.new();sleeve.top_radius = SLEEVE_R;sleeve.bottom_radius = SLEEVE_R;sleeve.height = 1.0;sleeve.radial_segments = 20
	var low := SphereMesh.new();low.radius = .07;low.height = .14;low.radial_segments = 8;low.rings = 4
	var tube := CylinderMesh.new();tube.top_radius = .025;tube.bottom_radius = .025;tube.height = 1.0;tube.radial_segments = 6;tube.rings = 1
	tube.cap_top = false;tube.cap_bottom = false
	for role in [["foam", sphere, foam], ["socket", socket, steel], ["core", core, steel], ["sleeve", sleeve, foam],
			["built_ball", low, foam], ["built_rod", tube, foam]]:
		var mm := MultiMesh.new();mm.transform_format = MultiMesh.TRANSFORM_3D;mm.use_colors = true;mm.mesh = role[1]
		var mi := MultiMeshInstance3D.new();mi.name = str(role[0]).capitalize().replace(" ", "");mi.multimesh = mm;mi.material_override = role[2]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mi)
		_mm[role[0]] = mm

func _process(_delta: float) -> void:
	if dirty:
		redraw()
		return
	for p in pieces:
		if is_instance_valid(p) and _slots.has(p) and _moving(p):
			for s in _slots[p]:(s[0] as MultiMesh).set_instance_transform(s[1], _xform(s[2], s[3]))

## A piece that may move this frame: in a hand, a body that is awake, or a flexible ball (and its rods) rocking.
func _moving(p: Node) -> bool:
	if p.is_picked_up() or p.get("held") == true or (not p.freeze and not p.sleeping):return true
	if p.get("flexible") == true:return true
	var joints: Variant = p.get("joints")
	if joints is Array:
		for j in joints:
			if is_instance_valid(j.ball) and j.ball.flexible:return true
	return false

## Everything again: which pieces are built, then every instance.
func redraw() -> void:
	dirty = false
	pieces = pieces.filter(func(p):return is_instance_valid(p) and p.is_inside_tree())
	var balls: Array = pieces.filter(func(p):return p.has_method("grid_point"))
	var rods: Array = pieces.filter(func(p):return p.has_method("end_global"))
	_fold(balls, rods)
	var lists := {}
	for role in _mm:lists[role] = []
	_slots.clear()
	for p in pieces:
		for c in p.get_children():
			if c is MeshInstance3D:c.visible = false
		if _built_ids.has(p):continue
		var slots: Array = []
		for c in p.get_children():
			if not (c is MeshInstance3D) or c.mesh == null:continue
			var role := _role(c)
			if role == "":continue
			slots.append([role, lists[role].size(), c, _scale(role, c.mesh)]);lists[role].append(c)
		_slots[p] = slots
	for role in ["foam", "socket", "core", "sleeve"]:
		var mm: MultiMesh = _mm[role];var list: Array = lists[role]
		mm.instance_count = list.size()
		for i in list.size():
			var c: MeshInstance3D = list[i]
			mm.set_instance_transform(i, Transform3D())   # written below with the scale
			var mat: Variant = c.material_override
			var colour: Color = mat.albedo_color if mat is StandardMaterial3D else Color.WHITE
			var owner_piece: Node = c.get_parent()
			if role == "foam" and owner_piece.get("editing") == true and owner_piece.get("supported") == false:colour = UNSUPPORTED
			mm.set_instance_color(i, colour)
	for p in _slots:
		var resolved: Array = []
		for s in _slots[p]:
			var mm: MultiMesh = _mm[s[0]]
			mm.set_instance_transform(s[1], _xform(s[2], s[3]))
			resolved.append([mm, s[1], s[2], s[3]])
		_slots[p] = resolved
	var mb: MultiMesh = _mm["built_ball"];mb.instance_count = folded_balls.size()
	for i in folded_balls.size():
		var b: Node3D = folded_balls[i]
		mb.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * (b.radius + b.boss * .5) / .07), b.global_position))
		mb.set_instance_color(i, Color(FOAM.get(b.colour, "ea72ab")))
	var mr: MultiMesh = _mm["built_rod"];mr.instance_count = folded_rods.size()
	for i in folded_rods.size():
		var r: Node3D = folded_rods[i]
		var e0: Vector3 = r.end_global(0);var e1: Vector3 = r.end_global(1)
		var y := e1 - e0
		var x := y.cross(Vector3.UP if absf(y.normalized().dot(Vector3.UP)) < .9 else Vector3.RIGHT).normalized()
		mr.set_instance_transform(i, Transform3D(Basis(x, y, x.cross(y.normalized())), (e0 + e1) / 2.0))   # unit height along the rod
		mr.set_instance_color(i, Color(FOAM.get(r.colour, "ea72ab")))

## Which pieces are BUILT: a `fold` ball held on its point, not in a hand, not flexible; a rod whose every end is in one.
func _fold(balls: Array, rods: Array) -> void:
	var now_balls: Array = [];var now_rods: Array = [];var built := {}
	for b in balls:
		if b.fold and b.supported and b.on_grid and not b.held and not b.flexible:built[b] = true;now_balls.append(b)
	for r in rods:
		if r.joints.is_empty() or r.is_picked_up():continue
		if r.joints.all(func(j):return built.has(j.ball)):now_rods.append(r)
	for r in folded_rods:
		if is_instance_valid(r) and r not in now_rods:
			if r.has_meta("kit_built_freeze") and not r.is_picked_up():r.freeze = bool(r.get_meta("kit_built_freeze"))
			r.remove_meta("kit_built_freeze");r.set_physics_process(true)
	for r in now_rods:
		if not r.has_meta("kit_built_freeze"):r.set_meta("kit_built_freeze", r.freeze)
		r.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;r.freeze = true;r.set_physics_process(false)   # no hit speed to keep
	folded_balls = now_balls;folded_rods = now_rods
	_built_ids.clear()
	for p in now_balls + now_rods:_built_ids[p] = true

## Is this piece drawn in the built look now?
func is_built(p: Node) -> bool:
	return _built_ids.has(p)

static func _role(c: MeshInstance3D) -> String:
	var n := str(c.name)
	if n == "Foam":return "foam"
	if n.begins_with("Socket"):return "socket"
	if n == "Core":return "core"
	if n == "Sleeve":return "sleeve"
	return ""

## The shared mesh scaled to this child's own mesh.
static func _scale(role: String, mesh: Mesh) -> Vector3:
	if mesh is SphereMesh:return Vector3.ONE * (mesh.radius / FOAM_R)
	if mesh is CylinderMesh:
		var r0: float = {"socket": .02, "core": CORE_R, "sleeve": SLEEVE_R}.get(role, 1.0)
		var h0: float = SOCKET_H if role == "socket" else 1.0
		var rr: float = maxf(mesh.top_radius, mesh.bottom_radius) / r0
		return Vector3(rr, mesh.height / h0, rr)
	return Vector3.ONE

static func _xform(c: MeshInstance3D, s: Vector3) -> Transform3D:
	var t := c.global_transform
	return Transform3D(t.basis * Basis.from_scale(s), t.origin)
