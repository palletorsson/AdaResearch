extends Node3D
class_name SamplingBench

## sampling_bench — the only ladder in this wave with something at the top of it.
##
## THE FAMILY. Five artifacts declare `resolution`: animated_noise_explorer and
## queer_marching_cave (mid coarse fine), sphere_mid and facture_bench (coarse mid fine ultra),
## riemann_pump (pump coarse mid fine). Four of the five make `mid` or `coarse` the default,
## which is a quiet admission that the top rung is not where the artifact wants to live.
##
## THE ARGUMENT. This wave puts four ladders on one bench and the four are not the same shape.
## Octaves converge because the series is built to. Depth diverges because each level acts on
## the last. Subdivision converges in shape while its parts list diverges. Resolution is the
## only one of the four with a LIMIT OBJECT: there is a true surface, it exists independently
## of the sampling, and every rung is a wrong answer about a right thing. That makes its error
## measurable in a way the other three simply are not — you can subtract the sample from the
## surface. You cannot subtract a recursion from its limit, because there is not one.
##
## So the claim is: `resolution` looks like the other three and is doing something else, and
## the corpus files all four under the same grammar of a small integer turned up.
##
## THE BODY, NOT A GAUGE. The `error` reading does not chart residuals. It stands the true
## surface and the sampled one in the same space and draws the actual gap between them as
## struts — the error is a thing with a length, standing where it occurs.

## Sampling density. coarse/mid/fine/ultra are sphere_mid's and facture_bench's own values.
@export_enum("coarse", "mid", "fine", "ultra") var resolution: String = "mid":
	set(v):
		resolution = v
		if is_inside_tree():
			_rebuild()

## What is drawn at each density.
##   sample — the sampled surface alone, which is all any member shows.
##   truth  — the sampled surface with the true one behind it as a wire ghost.


##   error  — the gap itself, as struts standing between sample and truth.
@export_enum("sample", "truth", "error") var reading: String = "sample":
	set(v):
		reading = v
		if is_inside_tree():
			_rebuild()


## Whether the rungs stand together or one at a time. THIS IS NOT PART OF THE AXIS, and
## separating it cost a sweep to learn: with "ladder" declared as a value of the ladder axis
## itself, capture_config_sweep unioned the AABB of the all-rungs view with every single-rung
## view, framed the singles against a row five times their width, and photographed them as
## specks — the critic then crashed on a subject box too small to sample. A layout is not a
## rung. The sweep pins this to `single` through dna.fixture; the artifact still stands as the
## whole comparison by default, which is what it is for.
@export_enum("ladder", "single") var layout: String = "ladder":
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()

@export var span: float = 0.80
@export var spacing: float = 0.98

## The four rungs, as grid counts. Named, not numbered, because the family names them.
const RUNGS := {"coarse": 5, "mid": 9, "fine": 17, "ultra": 33}
## The reference. 65 is not "the truth" — it is two doublings past the top rung, which is the
## honest way to say that the limit is approached and never held. Naming it TRUTH in the code
## while knowing it is a sample is the exact confusion this artifact is about, so it is not
## named that.
const REFERENCE := 65
const AMP := 0.17

var _built: Array[Node3D] = []


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("resolution"):
		resolution = str(config_data["resolution"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	_rebuild()


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var steps: Array = (["coarse", "mid", "fine", "ultra"] if layout == "ladder" else [resolution])
	var n: int = steps.size()
	for i in range(n):
		var holder := Node3D.new()
		holder.name = str(steps[i])
		holder.position = Vector3((float(i) - float(n - 1) * 0.5) * spacing, 0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_one(holder, int(RUNGS.get(str(steps[i]), 9)))


## The surface being sampled. A closed analytic form, so the reference is not a finer noise
## but the same function asked at more places.
func _h(u: float, v: float) -> float:
	var x := (u - 0.5) * 4.2
	var z := (v - 0.5) * 4.2
	return (sin(x) * cos(z) * 0.62 + sin(x * 1.9 + z * 0.7) * 0.30) * AMP


func _build_one(holder: Node3D, n: int) -> void:
	match reading:
		"sample":
			holder.add_child(_surface(n, Color(0.76, 0.70, 0.56), false))
		"truth":
			holder.add_child(_surface(REFERENCE, Color(0.42, 0.46, 0.52), true))
			holder.add_child(_surface(n, Color(0.80, 0.72, 0.50), false))
		"error":
			holder.add_child(_surface(REFERENCE, Color(0.40, 0.44, 0.50), true))
			# The gap, where it happens. Sampled at the reference grid but drawn only where
			# it is worth seeing, so a coarse rung is a forest and ultra is nearly bare.
			var step: int = 3
			for r in range(0, REFERENCE, step):
				for c in range(0, REFERENCE, step):
					var u := float(c) / float(REFERENCE - 1)
					var v := float(r) / float(REFERENCE - 1)
					var truth := _h(u, v)
					var samp := _sampled(u, v, n)
					if absf(truth - samp) < 0.0015:
						continue
					var x := (u - 0.5) * span
					var z := (v - 0.5) * span
					holder.add_child(_rod(Vector3(x, samp, z), Vector3(x, truth, z),
							Color(0.88, 0.48, 0.32), 0.004))


## The surface as the coarse grid renders it: nearest grid corners, linearly blended. This is
## what a sampled surface IS — the true function is never consulted between the samples.
func _sampled(u: float, v: float, n: int) -> float:
	var fu: float = u * float(n - 1)
	var fv: float = v * float(n - 1)
	var i0: int = clampi(int(floor(fu)), 0, n - 2)
	var j0: int = clampi(int(floor(fv)), 0, n - 2)
	var tu: float = fu - float(i0)
	var tv: float = fv - float(j0)
	var a := _h(float(i0) / float(n - 1), float(j0) / float(n - 1))
	var b := _h(float(i0 + 1) / float(n - 1), float(j0) / float(n - 1))
	var c := _h(float(i0) / float(n - 1), float(j0 + 1) / float(n - 1))
	var d := _h(float(i0 + 1) / float(n - 1), float(j0 + 1) / float(n - 1))
	return lerp(lerp(a, b, tu), lerp(c, d, tu), tv)


func _surface(n: int, col: Color, wire: bool) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES if wire else Mesh.PRIMITIVE_TRIANGLES)
	for r in range(n - 1):
		for c in range(n - 1):
			var pts: Array = []
			for q in [Vector2i(c, r), Vector2i(c + 1, r), Vector2i(c + 1, r + 1),
					Vector2i(c, r + 1)]:
				var qq: Vector2i = q
				var u := float(qq.x) / float(n - 1)
				var v := float(qq.y) / float(n - 1)
				pts.append(Vector3((u - 0.5) * span, _h(u, v), (v - 0.5) * span))
			if wire:
				# Every fourth line, or the reference reads as a solid grey wall.
				if r % 4 == 0 and c % 4 == 0:
					st.add_vertex(pts[0]); st.add_vertex(pts[1])
					st.add_vertex(pts[0]); st.add_vertex(pts[3])
			else:
				st.add_vertex(pts[0]); st.add_vertex(pts[1]); st.add_vertex(pts[2])
				st.add_vertex(pts[0]); st.add_vertex(pts[2]); st.add_vertex(pts[3])
	if not wire:
		st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.6
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if wire:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(col.r, col.g, col.b, 0.85)
	mi.material_override = m
	return mi


func _rod(a: Vector3, b: Vector3, c: Color, r: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = maxf(a.distance_to(b), 0.0001)
	cyl.radial_segments = 4
	cyl.rings = 0
	mi.mesh = cyl
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.4
	mi.material_override = m
	mi.position = (a + b) * 0.5
	var dir: Vector3 = (b - a).normalized()
	if absf(dir.dot(Vector3.UP)) < 0.999:
		mi.look_at_from_position(mi.position, mi.position + dir, Vector3.UP)
		mi.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	return mi
