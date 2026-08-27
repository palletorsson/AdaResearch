extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BackfaceCurtain

## @identity
## lineage: the primitives taxonomy's "normal" rung — a free-standing theatre curtain,
##   sumptuous from the front: pleats, a gold hem, a proscenium arch. Walk around it
##   and it is NOT THERE — not painted black, not thin: absent, because every face is
##   one-sided and the engine culls what faces away. Two floor arrows invite the walk.
## essence: a surface has a FRONT. Normals point; cull_back is the default; the back
##   of a one-sided face is not dark but UNRENDERED. Half of every closed mesh you
##   have ever seen was never drawn — this curtain simply refuses to close.
## truth: one-sided is the engine's default truth; solidity is two lies facing away
##   from each other.
##
## The 2026-08-27 primitives taxonomy refinement (doc/PRIMITIVES_TAXONOMY.md).

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 54
@export var width: float = 2.2
@export var height: float = 2.3
@export_range(6, 24) var pleats: int = 12

func _ready() -> void:
	_rng.seed = seed
	_build_arch()
	_build_curtain()
	_build_invitation()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "pleats"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_arch() -> void:
	# the proscenium is honest two-sided furniture, so the vanishing act belongs to
	# the curtain alone
	var gold := _steel_mat(Color(0.55, 0.44, 0.22))
	for sx in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.14, height + 0.3, 0.14)
		post.mesh = pm
		post.position = Vector3(sx * (width * 0.5 + 0.12), (height + 0.3) * 0.5, 0.0)
		post.material_override = gold
		add_child(post)
	var lintel := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(width + 0.55, 0.16, 0.2)
	lintel.mesh = lm
	lintel.position = Vector3(0.0, height + 0.36, 0.0)
	lintel.material_override = gold
	add_child(lintel)

func _build_curtain() -> void:
	# pleated velvet, built by hand so every triangle keeps its one-sided default:
	# SurfaceTool, front-facing winding ONLY — no doubling, no backs
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := width * 0.5
	for i in range(pleats):
		var x0 := -half + width * float(i) / float(pleats)
		var x1 := -half + width * float(i + 1) / float(pleats)
		# the zigzag: each pleat runs front-to-back, the next back-to-front
		var z0 := 0.05 if i % 2 == 0 else -0.05
		var z1 := -z0
		var a := Vector3(x0, 0.06, z0)
		var b := Vector3(x1, 0.06, z1)
		var c := Vector3(x0, height + 0.28, z0)
		var d := Vector3(x1, height + 0.28, z1)
		var n := (b - a).cross(c - a).normalized()
		for v in [a, b, c]:
			st.set_normal(n)
			st.add_vertex(v)
		for v in [b, d, c]:
			st.set_normal(n)
			st.add_vertex(v)
	var curtain := MeshInstance3D.new()
	curtain.mesh = st.commit()
	var velvet := _matte_mat(Color(0.55, 0.08, 0.12), 0.85)
	velvet.cull_mode = BaseMaterial3D.CULL_BACK   # the default, stated out loud
	curtain.material_override = velvet
	add_child(curtain)
	# the gold hem: a thin one-sided strip low across the front
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ha := Vector3(-half, 0.06, 0.051)
	var hb := Vector3(half, 0.06, 0.051)
	var hc := Vector3(-half, 0.28, 0.051)
	var hd := Vector3(half, 0.28, 0.051)
	var hn := Vector3(0, 0, 1)
	for v in [ha, hb, hc]:
		st2.set_normal(hn)
		st2.add_vertex(v)
	for v in [hb, hd, hc]:
		st2.set_normal(hn)
		st2.add_vertex(v)
	var hem := MeshInstance3D.new()
	hem.mesh = st2.commit()
	hem.material_override = _glow_mat(Color(0.85, 0.68, 0.3), 0.6)
	add_child(hem)

func _build_invitation() -> void:
	# two floor arrows walking the visitor around the right post
	for k in range(2):
		var ang := deg_to_rad(-25.0 - 40.0 * float(k))
		var at := Vector3(width * 0.5 + 0.45 + 0.3 * float(k), 0.02, 0.55 - 0.55 * float(k))
		var arrow := MeshInstance3D.new()
		var am := PrismMesh.new()
		am.size = Vector3(0.22, 0.02, 0.3)
		arrow.mesh = am
		arrow.position = at
		arrow.rotation.y = ang
		arrow.material_override = _glow_mat(Color(0.85, 0.68, 0.3), 0.7)
		add_child(arrow)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "CurtainPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-width * 0.5 - 0.5, 0.24, 0.8)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("BACKFACE CURTAIN",
			"A surface has a FRONT: normals point, and the engine culls what faces away.\nWalk around - the curtain is not painted black behind; it is UNRENDERED.\nSolidity is two lies facing away from each other.")
