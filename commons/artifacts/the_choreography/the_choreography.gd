extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheChoreography

## @identity
## lineage: the transformation SUPER OBJECT — a proscenium stage, one dancer, every
##   transform. Five copies of the same figure stand mid-performance: slid from her
##   ghost at the origin (translation), turned (rotation), grown (scale), tipped
##   sideways through a shear, and one wearing all of it composed. Above them, the
##   order-matters pair: two small dancers given the SAME two moves in opposite
##   order, ending in visibly different places, their paths drawn as arcs. At the
##   back, the mirror dancer performs the composed move and then UNWINDS it by the
##   affine inverse, returning home over and over. The floor is her footprint,
##   stamped into a tiling by a repeated transform. And the whole stage slowly
##   revolves, carrying every local pose through the world: local and global.
## essence: the sequence truth performed — "what stays the same when everything
##   changes?" The dancer. Same figure in every station; the transforms are all
##   that differ, and the differences are the whole curriculum.
## truth: identity preserved under transformation. The dancer is the invariant.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 65
@export var stage_turn: float = 0.06     # rad/s — the global carrying the locals
@export var unwind_s: float = 6.0        # the inverse dancer's out-and-back period

var _stage: Node3D
var _mirror_dancer: Node3D
# the composed move the mirror performs, then unsays: T(0.5, 0, 0.25) then R_y(70 deg)
var _fwd := Transform3D(Basis(Vector3.UP, deg_to_rad(70.0)), Vector3.ZERO) \
	* Transform3D(Basis.IDENTITY, Vector3(0.5, 0.0, 0.25))

func _ready() -> void:
	_rng.seed = seed
	_build_proscenium()
	_stage = Node3D.new()
	_stage.position = Vector3(0.0, 0.18, 0.0)
	add_child(_stage)
	_build_floor_tiling()
	_build_stations()
	_build_order_pair()
	_build_inverse_dancer()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "stage_turn", "unwind_s"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	# local and global: every pose below is untouched while the stage turns them all
	_stage.rotation.y += stage_turn * delta
	# the inverse: out by _fwd, home by _fwd.affine_inverse(), forever
	var t := fmod(float(Time.get_ticks_msec()) / 1000.0, unwind_s) / unwind_s
	var k := t * 2.0
	var xf: Transform3D
	if k < 1.0:
		xf = Transform3D.IDENTITY.interpolate_with(_fwd, k)
	else:
		xf = _fwd.interpolate_with(_fwd * (_fwd.affine_inverse() * _fwd).affine_inverse(), 0.0) \
			.interpolate_with(Transform3D.IDENTITY, k - 1.0)
	_mirror_dancer.transform = Transform3D(xf.basis, xf.origin + Vector3(0.0, 0.0, -1.05))

# --- the dancer, reused everywhere ---------------------------------------------------

func _dancer(tint: Color, ghost: bool = false) -> Node3D:
	var d := Node3D.new()
	var mat: StandardMaterial3D
	if ghost:
		mat = _matte_mat(tint, 0.8)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.22
	else:
		mat = _matte_mat(tint, 0.55)
	var torso := MeshInstance3D.new()
	var tm := CapsuleMesh.new()
	tm.radius = 0.07
	tm.height = 0.34
	torso.mesh = tm
	torso.position = Vector3(0.0, 0.42, 0.0)
	torso.material_override = mat
	d.add_child(torso)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.06
	hm.height = 0.12
	head.mesh = hm
	head.position = Vector3(0.0, 0.66, 0.0)
	head.material_override = mat
	d.add_child(head)
	var skirt := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.07
	sm.bottom_radius = 0.16
	sm.height = 0.2
	skirt.mesh = sm
	skirt.position = Vector3(0.0, 0.22, 0.0)
	skirt.material_override = mat
	d.add_child(skirt)
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		var am := CapsuleMesh.new()
		am.radius = 0.022
		am.height = 0.26
		arm.mesh = am
		arm.position = Vector3(side * 0.12, 0.5, 0.0)
		arm.rotation.z = side * deg_to_rad(65.0)
		arm.material_override = mat
		d.add_child(arm)
	return d

# --- stations ------------------------------------------------------------------------

func _build_proscenium() -> void:
	var boards := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 1.9
	bm.bottom_radius = 2.0
	bm.height = 0.18
	boards.mesh = bm
	boards.position = Vector3(0.0, 0.09, 0.0)
	boards.material_override = _matte_mat(Color(0.16, 0.12, 0.1), 0.8)
	add_child(boards)
	var gold := _steel_mat(Color(0.55, 0.44, 0.22))
	for sx in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.12, 2.6, 0.12)
		post.mesh = pm
		post.position = Vector3(sx * 1.85, 1.3, -1.55)
		post.material_override = gold
		add_child(post)
	var lintel := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(3.95, 0.16, 0.16)
	lintel.mesh = lm
	lintel.position = Vector3(0.0, 2.65, -1.55)
	lintel.material_override = gold
	add_child(lintel)

func _build_floor_tiling() -> void:
	# the tiling rung: her footprint (a small ellipse pair) stamped by a repeated
	# rotation about the stage centre — a transform, applied again and again
	for k in range(10):
		var xf := Transform3D(Basis(Vector3.UP, TAU * float(k) / 10.0), Vector3.ZERO)
		for side in [-0.045, 0.045]:
			var print_at := xf * Vector3(1.45, 0.0, side * 2.2)
			var footp := MeshInstance3D.new()
			var fm := CylinderMesh.new()
			fm.top_radius = 0.055
			fm.bottom_radius = 0.055
			fm.height = 0.012
			footp.mesh = fm
			footp.scale = Vector3(1.0, 1.0, 1.7)
			footp.position = Vector3(print_at.x, 0.012, print_at.z)
			footp.rotation.y = TAU * float(k) / 10.0
			footp.material_override = _glow_mat(Color(0.85, 0.75, 0.5), 0.5)
			_stage.add_child(footp)

func _build_stations() -> void:
	# the ghost at the origin every station is measured from
	var ghost := _dancer(Color(0.85, 0.85, 0.9), true)
	ghost.position = Vector3(0.0, 0.0, 0.35)
	_stage.add_child(ghost)
	var specs := [
		["translate", Color(0.35, 0.65, 0.95), Transform3D(Basis.IDENTITY, Vector3(-1.25, 0.0, 0.35))],
		["rotate", Color(0.95, 0.6, 0.25), Transform3D(Basis(Vector3.UP, deg_to_rad(140.0)), Vector3(-0.65, 0.0, -0.6))],
		["scale", Color(0.55, 0.85, 0.45), Transform3D(Basis.IDENTITY.scaled(Vector3(1.45, 1.45, 1.45)), Vector3(0.75, 0.0, -0.55))],
		["shear", Color(0.8, 0.45, 0.85), Transform3D(Basis(Vector3(1, 0, 0), Vector3(0.55, 1, 0), Vector3(0, 0, 1)), Vector3(1.3, 0.0, 0.35))],
		["composed", Color(0.95, 0.8, 0.3), Transform3D(Basis(Vector3.UP, deg_to_rad(-70.0)).scaled(Vector3(1.2, 1.2, 1.2)), Vector3(0.35, 0.0, 1.0))],
	]
	for s in specs:
		var d := _dancer(s[1])
		d.transform = s[2]
		_stage.add_child(d)
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.13
		var at: Vector3 = (s[2] as Transform3D).origin
		tag.position = Vector3(at.x, 0.02, at.z + 0.45)
		_stage.add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text(s[0], "")

func _build_order_pair() -> void:
	# the same two moves, opposite orders: T = slide 0.45 along x, R = 90 deg about
	# the ORIGIN. R after T orbits her away; T after R steps her sideways.
	var slide := Transform3D(Basis.IDENTITY, Vector3(0.45, 0.0, 0.0))
	var turn := Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), Vector3.ZERO)
	var pedestal := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(1.7, 0.06, 0.7)
	pedestal.mesh = pm
	pedestal.position = Vector3(0.0, 1.75, -1.35)
	pedestal.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.85)
	add_child(pedestal)
	var cases := [["T then R", turn * slide, Color(0.35, 0.65, 0.95)],
		["R then T", slide * turn, Color(0.95, 0.6, 0.25)]]
	for i in range(2):
		var root := Node3D.new()
		root.position = Vector3(-0.55 + 1.1 * float(i), 1.79, -1.35)
		root.scale = Vector3.ONE * 0.5
		add_child(root)
		var ghost := _dancer(Color(0.8, 0.8, 0.85), true)
		root.add_child(ghost)
		var moved := _dancer(cases[i][2])
		moved.transform = cases[i][1]
		root.add_child(moved)
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.16
		tag.position = Vector3(-0.55 + 1.1 * float(i), 1.72, -0.95)
		add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text(cases[i][0], "same two moves")

func _build_inverse_dancer() -> void:
	_mirror_dancer = _dancer(Color(0.7, 0.75, 0.95))
	_stage.add_child(_mirror_dancer)
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.18
	tag.position = Vector3(0.0, 0.02, -1.55)
	_stage.add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text("the inverse", "out by the move, home by affine_inverse")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "ChoreographyPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-2.0, 0.24, 1.35)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THE CHOREOGRAPHY",
			"One dancer, every transform: slid, turned, grown, sheared, composed -\nher ghost at the origin, the order-matters pair ending apart on the same\ntwo moves, the mirror unwinding home by affine_inverse, her footprints\ntiled by repetition, and the whole stage turning every local through the\nworld. What stays the same when everything changes? The dancer.")
