## @identity
## name: Curtain Membrane Room
## concept: Soft pets & membranes (native)
## tier: large
## truth: push through; it parts and falls back. A hanging soft membrane curtain, pinned along its top
##        edge to a bar slung between two posts; the rest hangs free and drapes. Walk into it and your
##        body pushes the cloth aside (player poke deforms it), then it swings closed behind you. Native
##        SoftBody3D cloth — a subdivided plane stood on edge, pinned only along the top so it hangs.
extends Node3D
class_name CurtainMembraneRoom

@export var emissive: bool = false
@export var curtain_width: float = 2.5
@export var curtain_drop: float = 2.4               # how far it hangs below the bar
@export var curtain_color: Color = Color(0.7, 0.45, 0.85)

const GSB = preload("res://commons/soft_body/grab_soft_body.gd")

var _sb: SoftBody3D
var _bar_y: float = 2.8
var _half_w: float = 1.25
var _top_local_z: float = 0.0


func _ready() -> void:
	_build()
	set_process(false)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	var w: float = curtain_width
	var drop: float = curtain_drop
	_half_w = w * 0.5
	_bar_y = drop + 0.3                             # bar sits just above the drop

	# Two posts and a horizontal bar to hang the curtain from.
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.18, 0.19, 0.22)
	fmat.roughness = 0.7
	fmat.metallic = 0.3
	for sx in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.14, _bar_y, 0.14)
		post.mesh = pm
		post.position = Vector3(sx * (_half_w + 0.15), _bar_y * 0.5, 0)
		post.material_override = fmat
		add_child(post)
	var bar := MeshInstance3D.new()
	var barm := BoxMesh.new()
	barm.size = Vector3(w + 0.4, 0.1, 0.1)
	bar.mesh = barm
	bar.position = Vector3(0, _bar_y, 0)
	bar.material_override = fmat
	add_child(bar)

	# The cloth: a finely subdivided PlaneMesh. A plane lies flat in XZ (normal +Y); rotating
	# the SoftBody3D -90 deg about X stands it up in XY, so local +Z maps to world +Y (UP) and
	# local -Z maps DOWN. We then pin the verts at the local +Z edge to the bar so it HANGS.
	var plane := PlaneMesh.new()
	plane.size = Vector2(w, drop)                  # X = width, "depth" (Z) becomes the hanging height
	plane.subdivide_width = 14
	plane.subdivide_depth = 14
	var sb := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 2.0, "stiffness": 0.2, "pressure": 0.0, "damping": 0.25,
		"precision": 5, "color": curtain_color, "emissive": emissive,
	})
	# Cloth should be two-sided so it reads from both sides as you pass through.
	if sb.material_override is StandardMaterial3D:
		(sb.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	sb.mesh = plane
	# Stand it up; place it so its top (local +Z edge, now up) meets the bar.
	sb.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
	# After the rotation the plane's centre needs to sit at bar_y - drop/2 so the top reaches the bar.
	sb.position = Vector3(0, _bar_y - drop * 0.5, 0)
	add_child(sb)
	_sb = sb
	_top_local_z = drop * 0.5                       # local +Z edge = the top after rotation

	add_child(_label("PUSH THROUGH — IT PARTS AND FALLS BACK", Vector3(0, 3.6, 0)))
	call_deferred("_apply_pins")


func _apply_pins() -> void:
	if not is_instance_valid(_sb) or _sb.mesh == null:
		return
	# Pin every vertex along the TOP edge (local z ~ +drop/2) to the world (the bar position).
	# We can't use pin_patch's single-patch model for a whole edge, so pin by z-band directly.
	var mdt := MeshDataTool.new()
	if mdt.create_from_surface(_sb.mesh, 0) != OK:
		return
	var band: float = max(0.02, curtain_drop * 0.04)
	var pinned := 0
	for i in mdt.get_vertex_count():
		var v: Vector3 = mdt.get_vertex(i)
		if absf(v.z - _top_local_z) <= band:
			_sb.set_point_pinned(i, true, NodePath())   # pin to world = hangs from the bar line
			pinned += 1
	# Safety: if subdivision/orientation gave us nothing, fall back to the highest-z row.
	if pinned == 0:
		var max_z: float = -INF
		for i in mdt.get_vertex_count():
			max_z = maxf(max_z, mdt.get_vertex(i).z)
		for i in mdt.get_vertex_count():
			if absf(mdt.get_vertex(i).z - max_z) <= band:
				_sb.set_point_pinned(i, true, NodePath())


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 40
	l.pixel_size = 0.004
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.9, 0.92, 1.0)
	l.outline_size = 8
	return l
