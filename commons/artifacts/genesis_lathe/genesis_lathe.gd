extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GenesisLathe

## @identity
## lineage: the primitives SUPER OBJECT — the whole ladder performed on one long
##   bench, forever. Station by station: a crosshair marking a point the engine
##   cannot draw (its stand-in blinking); a line GROWING out of it on a loop; three
##   edges closing into the first face, which fades in with its shadow; the plane
##   the face industrialises into; the seven words in procession on a slow turntable;
##   one sphere stepping through its smoothness budget, 4 to 64 segments; and at the
##   bench's end a torus beside its own wireframe confession. A spark glides the
##   whole timeline and starts again.
## essence: from nothing to everything in seven stations — each station is its rung's
##   hero shrunk to bench scale, and the bench is the ladder made walkable. The spark
##   is the reader.
## truth: a point, a line, a face, a plane, seven words, a budget, a confession —
##   everything is built from nothing, and the building never stops.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const BENCH_L := 4.6

@export var seed: int = 64
@export var loop_s: float = 9.0         # one full genesis, seconds

var _standin: MeshInstance3D
var _line: MeshInstance3D
var _face: MeshInstance3D
var _face_mat: StandardMaterial3D
var _plane: MeshInstance3D
var _turntable: Node3D
var _budget_sphere: MeshInstance3D
var _budget_meshes: Array = []
var _budget_tag: Node3D
var _spark: Node3D
var _confession_pair: Array = []

func _ready() -> void:
	_rng.seed = seed
	_build_bench()
	_station_point()
	_station_line()
	_station_face()
	_station_plane()
	_station_words()
	_station_budget()
	_station_confession()
	_build_spark()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "loop_s"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	var t := fmod(float(Time.get_ticks_msec()) / 1000.0, loop_s) / loop_s
	# the spark reads the bench left to right, then returns
	_spark.position = Vector3(-BENCH_L * 0.5 + BENCH_L * t, 1.62, 0.0)
	# 1: the stand-in blinks on its own beat
	_standin.visible = fmod(t * 7.0, 1.0) < 0.62
	# 2: the line grows from the point, over and over
	var lg := clampf(t * 6.0 - 0.6, 0.0, 1.0)
	_line.scale.y = maxf(lg, 0.001)
	# 3: the face fades in once the line has lived
	_face_mat.albedo_color.a = clampf(t * 6.0 - 1.6, 0.0, 0.9)
	# 4: the plane rises
	_plane.scale = Vector3.ONE * clampf(t * 6.0 - 2.2, 0.05, 1.0)
	# 5: the procession turns
	_turntable.rotation.y += delta * 0.4
	# 6: the budget steps 4 -> 8 -> 16 -> 64 through the loop
	var step := clampi(int(t * 4.0 * 1.6) % 4, 0, 3)
	if _budget_sphere.mesh != _budget_meshes[step]:
		_budget_sphere.mesh = _budget_meshes[step]
		if _budget_tag and _budget_tag.has_method("set_text"):
			_budget_tag.set_text("segments %d" % [4, 8, 16, 64][step], "")
	# 7: the confession pair turns in step
	for n in _confession_pair:
		n.rotation.y += delta * 0.5

func _tag(at: Vector3, txt: String) -> Node3D:
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.12
	tag.position = at
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text(txt, "")
	return tag

func _build_bench() -> void:
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(BENCH_L + 0.3, 0.09, 0.9)
	top.mesh = tm
	top.position = Vector3(0.0, 0.9, 0.0)
	top.material_override = _matte_mat(Color(0.14, 0.13, 0.15), 0.85)
	add_child(top)
	for sx in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.12, 0.9, 0.7)
		leg.mesh = lm
		leg.position = Vector3(sx * (BENCH_L * 0.5 - 0.1), 0.45, 0.0)
		leg.material_override = _matte_mat(Color(0.1, 0.1, 0.12), 0.9)
		add_child(leg)

func _sx(i: int) -> float:
	# seven stations, evenly along the bench
	return -BENCH_L * 0.5 + BENCH_L * (float(i) + 0.5) / 7.0

func _station_point() -> void:
	var x := _sx(0)
	for horizontal in [true, false]:
		var hair := MeshInstance3D.new()
		var hm := CylinderMesh.new()
		hm.top_radius = 0.002
		hm.bottom_radius = 0.002
		hm.height = 0.3
		hair.mesh = hm
		hair.position = Vector3(x, 1.25, 0.0)
		if horizontal:
			hair.rotation.z = PI * 0.5
		else:
			hair.rotation.x = PI * 0.5
		hair.material_override = _glow_mat(Color(0.9, 0.25, 0.2), 1.4)
		add_child(hair)
	_standin = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.022
	sm.height = 0.044
	_standin.mesh = sm
	_standin.position = Vector3(x, 1.25, 0.0)
	_standin.material_override = _glow_mat(Color(0.95, 0.9, 0.8), 2.2)
	add_child(_standin)
	_tag(Vector3(x, 0.98, 0.42), "point")

func _station_line() -> void:
	var x := _sx(1)
	_line = MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.006
	lm.bottom_radius = 0.006
	lm.height = 0.5
	_line.mesh = lm
	_line.position = Vector3(x, 1.25, 0.0)
	_line.rotation.z = deg_to_rad(28.0)
	_line.material_override = _glow_mat(Color(0.4, 0.7, 0.95), 1.2)
	add_child(_line)
	_tag(Vector3(x, 0.98, 0.42), "line")

func _station_face() -> void:
	var x := _sx(2)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(-0.18, -0.15, 0.0)
	var b := Vector3(0.18, -0.15, 0.0)
	var c := Vector3(0.0, 0.19, 0.0)
	var n := Vector3(0, 0, 1)
	for v in [a, b, c]:
		st.set_normal(n)
		st.add_vertex(v)
	for v in [a, c, b]:
		st.set_normal(-n)
		st.add_vertex(v)
	_face = MeshInstance3D.new()
	_face.mesh = st.commit()
	_face.position = Vector3(x, 1.3, 0.0)
	_face_mat = _glow_mat(Color(0.95, 0.6, 0.2), 0.6)
	_face_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_face.material_override = _face_mat
	_face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(_face)
	_tag(Vector3(x, 0.98, 0.42), "face")

func _station_plane() -> void:
	var x := _sx(3)
	_plane = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(0.42, 0.42)
	_plane.mesh = pm
	_plane.position = Vector3(x, 1.28, 0.0)
	_plane.rotation.x = deg_to_rad(62.0)
	var m := _matte_mat(Color(0.5, 0.8, 0.6), 0.55)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_plane.material_override = m
	add_child(_plane)
	_tag(Vector3(x, 0.98, 0.42), "plane")

func _station_words() -> void:
	var x := _sx(4)
	_turntable = Node3D.new()
	_turntable.position = Vector3(x, 1.22, 0.0)
	add_child(_turntable)
	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.3
	dm.bottom_radius = 0.3
	dm.height = 0.02
	disc.mesh = dm
	disc.position = Vector3(0.0, -0.12, 0.0)
	disc.material_override = _steel_mat(Color(0.35, 0.33, 0.3))
	_turntable.add_child(disc)
	var meshes: Array = []
	var box := BoxMesh.new()
	box.size = Vector3(0.09, 0.09, 0.09)
	meshes.append(box)
	var sph := SphereMesh.new()
	sph.radius = 0.055
	sph.height = 0.11
	meshes.append(sph)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.045
	cyl.bottom_radius = 0.045
	cyl.height = 0.11
	meshes.append(cyl)
	var cap := CapsuleMesh.new()
	cap.radius = 0.04
	cap.height = 0.13
	meshes.append(cap)
	var pri := PrismMesh.new()
	pri.size = Vector3(0.09, 0.09, 0.09)
	meshes.append(pri)
	var tor := TorusMesh.new()
	tor.inner_radius = 0.03
	tor.outer_radius = 0.06
	meshes.append(tor)
	var pla := PlaneMesh.new()
	pla.size = Vector2(0.11, 0.11)
	meshes.append(pla)
	for i in range(7):
		var ang := TAU * float(i) / 7.0
		var word := MeshInstance3D.new()
		word.mesh = meshes[i]
		word.position = Vector3(cos(ang) * 0.22, 0.0, sin(ang) * 0.22)
		if meshes[i] is PlaneMesh:
			word.rotation.x = deg_to_rad(70.0)
		var pm2 := _matte_mat(Color.from_hsv(0.06 + 0.02 * float(i), 0.45, 0.85), 0.65)
		if meshes[i] is PlaneMesh:
			pm2.cull_mode = BaseMaterial3D.CULL_DISABLED
		word.material_override = pm2
		_turntable.add_child(word)
	_tag(Vector3(x, 0.98, 0.42), "seven words")

func _station_budget() -> void:
	var x := _sx(5)
	for seg in [4, 8, 16, 64]:
		var m := SphereMesh.new()
		m.radius = 0.14
		m.height = 0.28
		m.radial_segments = seg
		m.rings = maxi(seg / 2, 2)
		_budget_meshes.append(m)
	_budget_sphere = MeshInstance3D.new()
	_budget_sphere.mesh = _budget_meshes[0]
	_budget_sphere.position = Vector3(x, 1.28, 0.0)
	_budget_sphere.material_override = _matte_mat(Color.from_hsv(0.55, 0.25, 0.85), 0.35, 0.15)
	add_child(_budget_sphere)
	_budget_tag = _tag(Vector3(x, 0.98, 0.42), "budget")

func _station_confession() -> void:
	var x := _sx(6)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.07
	torus.outer_radius = 0.15
	var dressed := MeshInstance3D.new()
	dressed.mesh = torus
	dressed.position = Vector3(x - 0.17, 1.28, 0.0)
	dressed.material_override = _matte_mat(Color(0.75, 0.35, 0.5), 0.3, 0.2)
	add_child(dressed)
	_confession_pair.append(dressed)
	var arrays := torus.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var edges := {}
	for tI in range(idx.size() / 3):
		for e in range(3):
			var p := idx[tI * 3 + e]
			var q := idx[tI * 3 + (e + 1) % 3]
			edges[Vector2i(mini(p, q), maxi(p, q))] = true
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for key in edges:
		im.surface_add_vertex(verts[key.x])
		im.surface_add_vertex(verts[key.y])
	im.surface_end()
	var undressed := MeshInstance3D.new()
	undressed.mesh = im
	undressed.position = Vector3(x + 0.17, 1.28, 0.0)
	var mat := _glow_mat(Color(0.45, 0.85, 0.8), 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	undressed.material_override = mat
	add_child(undressed)
	_confession_pair.append(undressed)
	_tag(Vector3(x, 0.98, 0.42), "confession")

func _build_spark() -> void:
	_spark = Node3D.new()
	add_child(_spark)
	var orb := MeshInstance3D.new()
	var om := SphereMesh.new()
	om.radius = 0.03
	om.height = 0.06
	orb.mesh = om
	orb.material_override = _glow_mat(Color(0.98, 0.9, 0.6), 2.4)
	_spark.add_child(orb)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "LathePlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-BENCH_L * 0.5 - 0.35, 0.24, 0.75)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("GENESIS LATHE",
			"The whole ladder on one bench, forever: a point's blinking stand-in, the\nline that grows from it, three edges closing into the first face, the plane,\nthe seven words in procession, a sphere paying its smoothness budget,\nand the torus confessing its triangles. The spark is the reader.")
