extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WireframeConfession

## @identity
## lineage: the primitives taxonomy's closing rung — a torus on a plinth, and beside
##   it its own confession: the SAME mesh with every triangle edge drawn as a glowing
##   line, extracted at runtime from the mesh's actual arrays. Not an artist's
##   wireframe — the real seams, read from the same vertices the solid is drawn with.
## essence: under every solid here, triangles all the way down. The torus looks like
##   a continuous curve; its twin testifies to 1,152 edges. The confession is built
##   by surface_get_arrays() — the twin cannot lie about the original, because it IS
##   the original, undressed.
## truth: everything is triangles. Smoothness is what triangles wear in public.
##
## The 2026-08-27 primitives taxonomy refinement (doc/PRIMITIVES_TAXONOMY.md) — the
## loop closes: rung 1's point had no body, and every body since was points, wired.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 56
@export var spin: float = 0.2

var _pair: Array = []

func _ready() -> void:
	_rng.seed = seed
	_build_plinths()
	_build_pair()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "spin"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	# they turn in step: the body and its testimony, always the same angle
	for n in _pair:
		n.rotation.y += spin * delta

func _build_plinths() -> void:
	for sx in [-0.75, 0.75]:
		var plinth := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.28
		pm.bottom_radius = 0.34
		pm.height = 0.9
		plinth.mesh = pm
		plinth.position = Vector3(sx, 0.45, 0.0)
		plinth.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.9)
		add_child(plinth)

func _build_pair() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.14
	torus.outer_radius = 0.3

	var dressed := MeshInstance3D.new()
	dressed.mesh = torus
	dressed.position = Vector3(-0.75, 1.25, 0.0)
	dressed.material_override = _matte_mat(Color(0.75, 0.35, 0.5), 0.3, 0.2)
	add_child(dressed)
	_pair.append(dressed)

	# THE CONFESSION: read the torus's own arrays and draw every triangle edge once
	var arrays := torus.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var edges := {}
	var tri_count := idx.size() / 3
	for t in range(tri_count):
		for e in range(3):
			var a := idx[t * 3 + e]
			var b := idx[t * 3 + (e + 1) % 3]
			var key := Vector2i(mini(a, b), maxi(a, b))
			edges[key] = true
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for key in edges:
		im.surface_add_vertex(verts[key.x])
		im.surface_add_vertex(verts[key.y])
	im.surface_end()
	var undressed := MeshInstance3D.new()
	undressed.mesh = im
	undressed.position = Vector3(0.75, 1.25, 0.0)
	var mat := _glow_mat(Color(0.45, 0.85, 0.8), 1.1)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	undressed.material_override = mat
	add_child(undressed)
	_pair.append(undressed)

	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.22
	tag.position = Vector3(0.75, 0.92, 0.42)
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text("%d edges" % edges.size(), "read from surface_get_arrays - the same mesh, undressed")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "ConfessionPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-1.35, 0.24, 0.7)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("WIREFRAME CONFESSION",
			"Under every solid here, triangles all the way down. The twin is not a\ndrawing - it is the torus's own arrays, every edge extracted and lit.\nSmoothness is what triangles wear in public.")
