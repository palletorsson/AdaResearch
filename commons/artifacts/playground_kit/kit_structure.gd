extends Node3D
## THE BUILT LOOK (Palle, 2026-11-06: "if we create a really large playground we want the geometry as simple as
## possible" - the pilot of one record, three looks). A kit piece has two looks, chosen by what it is DOING:
##   - in the hand, loose, or still able to move (flexible on the Triangle stage): the detailed piece, foam and steel
##     sockets, its own meshes;
##   - BUILT - a ball held on its point by the support graph, or a rod whose every end is in such a ball: it folds into
##     this node, one MultiMesh of low spheres and one of thin tubes for the whole scene. Its own meshes hide, a built rod
##     is frozen and stops its per-frame script (it no longer simulates on its joints), and nothing else changes: the bodies stay, so the hand, the
##     support graph, the sockets and the Triangle stage's counts work as before. Picked up, a piece unfolds.
## Made by the support graph (PlaygroundBall.reevaluate) only when a ball has `fold` on - a scene without it never
## gets one. Cost: two draws, about 64 triangles a ball and 12 a rod, whatever the size.

const FOAM := {"pale": "ededed", "pink": "ea72ab", "cyan": "5fd3e6", "steel": "2a2c30"}

var _balls := MultiMeshInstance3D.new()
var _rods := MultiMeshInstance3D.new()
var folded_balls: Array = []
var folded_rods: Array = []

func _init() -> void:
	top_level = true   # instance transforms are world transforms
	name = "PlaygroundStructure"
	var mat := StandardMaterial3D.new();mat.vertex_color_use_as_albedo = true;mat.vertex_color_is_srgb = true;mat.roughness = .8   # instance colours are the FOAM hexes, sRGB
	var sphere := SphereMesh.new();sphere.radius = .07;sphere.height = .14;sphere.radial_segments = 8;sphere.rings = 4
	var tube := CylinderMesh.new();tube.top_radius = .025;tube.bottom_radius = .025;tube.height = 1.0;tube.radial_segments = 6;tube.rings = 1
	tube.cap_top = false;tube.cap_bottom = false
	for pair in [[_balls, sphere, "BuiltBalls"], [_rods, tube, "BuiltRods"]]:
		var mi: MultiMeshInstance3D = pair[0]
		var mm := MultiMesh.new();mm.transform_format = MultiMesh.TRANSFORM_3D;mm.use_colors = true;mm.mesh = pair[1]
		mi.multimesh = mm;mi.material_override = mat;mi.name = pair[2];mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)

## Which pieces are built now, and draw them. `balls` are the scene's playground balls.
func refresh(balls: Array, rods: Array) -> void:
	var now_balls: Array = [];var now_rods: Array = []
	var built := {}
	for b in balls:
		if is_instance_valid(b) and b.fold and b.supported and b.on_grid and not b.held and not b.flexible:built[b] = true;now_balls.append(b)
	for r in rods:
		if not is_instance_valid(r) or r.joints.is_empty() or r.is_picked_up():continue
		if r.joints.all(func(j):return built.has(j.ball)):now_rods.append(r)
	for b in folded_balls:
		if is_instance_valid(b) and not built.has(b):_show(b, true)
	for r in folded_rods:
		if is_instance_valid(r) and r not in now_rods:
			_show(r, true)
			if r.has_meta("kit_built_freeze") and not r.is_picked_up():r.freeze = bool(r.get_meta("kit_built_freeze"))
			r.remove_meta("kit_built_freeze");r.set_physics_process(true)
	for b in now_balls:_show(b, false)
	for r in now_rods:
		_show(r, false)
		if not r.has_meta("kit_built_freeze"):r.set_meta("kit_built_freeze", r.freeze)
		r.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;r.freeze = true;r.set_physics_process(false)   # no hit speed to keep
	folded_balls = now_balls;folded_rods = now_rods
	var mb := _balls.multimesh;mb.instance_count = now_balls.size()
	for i in now_balls.size():
		var b: Node3D = now_balls[i]
		var s: float = (b.radius + b.boss * .5) / .07
		mb.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * s), b.global_position))
		mb.set_instance_color(i, Color(FOAM.get(b.colour, "ea72ab")))
	var mr := _rods.multimesh;mr.instance_count = now_rods.size()
	for i in now_rods.size():
		var r: Node3D = now_rods[i]
		var e0: Vector3 = r.end_global(0);var e1: Vector3 = r.end_global(1)
		var y := e1 - e0
		var x := y.cross(Vector3.UP if absf(y.normalized().dot(Vector3.UP)) < .9 else Vector3.RIGHT).normalized()
		var z := x.cross(y.normalized())
		mr.set_instance_transform(i, Transform3D(Basis(x, y, z), (e0 + e1) / 2.0))   # the tube's unit height along y = the rod
		mr.set_instance_color(i, Color(FOAM.get(r.colour, "ea72ab")))

static func _show(piece: Node, on: bool) -> void:
	for c in piece.get_children():
		if c is MeshInstance3D:c.visible = on
