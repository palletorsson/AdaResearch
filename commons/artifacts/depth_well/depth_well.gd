extends Node3D
class_name DepthWell

## depth_well — the same integer, the opposite curve.
##
## THE FAMILY. Six artifacts declare `depth`: example_8_3_recursion_circles_vr (1-5),
## fractal_recursion_2 (1 2 4 6 7), lsystem_dungeon (1-4), lsystem_editor (0 2 3 4 6),
## room_grammar (1-5), space_filling_curve_gallery — which names its rungs sketch, sparse,
## standard, fine, and so is the one member that admits the number is a budget.
##
## THE ARGUMENT, AND IT ONLY EXISTS BECAUSE octave_stack IS IN THE SAME WAVE. Both families
## hand the user one integer and invite them to turn it up. In octaves the contributions HALVE,
## so the sum converges and the last rung cannot matter. Here each level acts on everything the
## last level made, so the parts count MULTIPLIES — with a branching factor of 3, depth 5 is
## 243 tips where depth 1 was 3. Same interface, same word, and the curves point in opposite
## directions. Neither family says which kind it is, and a user has no way to tell from the
## control: both are a spin box labelled with a small integer.
##
## WHAT IS FORECLOSED by the two of them sharing a grammar: that some ladders have a limit
## object and some do not. Sum enough octaves and you approach a particular field. Recurse
## forever and there is no tree — the thing diverges. The interface hides the difference.
##
## THE BODY, NOT A GAUGE. No count printed anywhere. Each rung is the actual recursion, built;
## the `tips` reading marks only the ends, so the multiplication is read off the picture as
## density, and `cost` stacks every level's members as its own horizontal course, which makes
## the pyramid the family's own geometry rather than a bar chart of it.

## Recursion depth. 1..5 is example_8_3_recursion_circles_vr's and room_grammar's shared range.
@export_enum("1", "2", "3", "4", "5") var depth: String = "3":
	set(v):
		depth = v
		if is_inside_tree():
			_rebuild()

## What is drawn of each recursion.
##   whole — every branch at every level, the reading the family ships.
##   tips  — only the terminal ends. Density is the multiplication, seen directly.
##   cost  — each level's members laid out as its own horizontal course, stacked. The parts


##           list as built form: every course is as wide as that level is numerous.
@export_enum("whole", "tips", "cost") var reading: String = "whole":
	set(v):
		reading = v
		if is_inside_tree():
			_rebuild()

## Branching factor. Three is the smallest that multiplies visibly without becoming a thicket
## at depth 5, and it is fixed so five variants differ in DEPTH alone.

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

@export var branches: int = 3
@export var spacing: float = 1.06

const SPREAD := 0.62
const SHRINK := 0.62
const TRUNK := 0.30

var _built: Array[Node3D] = []


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("depth"):
		depth = str(config_data["depth"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	if config_data.has("branches"):
		branches = int(config_data["branches"])
	_rebuild()


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var steps: Array = [1, 2, 3, 4, 5] if layout == "ladder" else [int(depth)]
	var n: int = steps.size()
	for i in range(n):
		var holder := Node3D.new()
		holder.name = "d%d" % steps[i]
		holder.position = Vector3((float(i) - float(n - 1) * 0.5) * spacing, 0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_one(holder, int(steps[i]))


func _build_one(holder: Node3D, d: int) -> void:
	# Every level's segments, gathered first, so all three readings are the same recursion
	# read three ways rather than three different recursions.
	var levels: Array = []
	for _i in range(d):
		levels.append([])
	_grow(levels, Vector3(0.0, -0.44, 0.0), Vector3.UP, TRUNK, 0, d)
	match reading:
		"whole":
			for l in range(levels.size()):
				for seg in levels[l]:
					holder.add_child(_rod(seg[0], seg[1], _band(l, d), 0.011 * pow(0.8, l)))
		"tips":
			var last: Array = levels[levels.size() - 1]
			for seg in last:
				var mi := MeshInstance3D.new()
				var sp := SphereMesh.new()
				sp.radius = 0.016
				sp.height = 0.032
				sp.radial_segments = 6
				sp.rings = 3
				mi.mesh = sp
				mi.material_override = _mat(_band(d - 1, d), 0.35)
				mi.position = seg[1]
				holder.add_child(mi)
		"cost":
			# One horizontal course per level, each as long as that level is numerous.
			for l in range(levels.size()):
				var count: int = (levels[l] as Array).size()
				var y: float = -0.44 + 0.17 * float(l)
				var pitch: float = 0.62 / float(maxi(count, 1))
				for k in range(count):
					var x: float = (float(k) - float(count - 1) * 0.5) * pitch
					holder.add_child(_rod(Vector3(x, y, 0.0), Vector3(x, y + 0.10, 0.0),
							_band(l, d), 0.008))


func _grow(levels: Array, base: Vector3, dir: Vector3, len_: float, lvl: int, d: int) -> void:
	if lvl >= d:
		return
	var tip: Vector3 = base + dir * len_
	(levels[lvl] as Array).append([base, tip])
	for b in range(branches):
		var a := TAU * float(b) / float(branches) + float(lvl) * 0.7
		var side := Vector3(cos(a), 0.0, sin(a))
		var nd: Vector3 = (dir + side * SPREAD).normalized()
		_grow(levels, tip, nd, len_ * SHRINK, lvl + 1, d)


func _band(l: int, d: int) -> Color:
	if d <= 1:
		return Color(0.84, 0.72, 0.44)
	var t := float(l) / float(d - 1)
	return Color(0.86, 0.74, 0.42).lerp(Color(0.40, 0.62, 0.74), t)


func _rod(a: Vector3, b: Vector3, c: Color, r: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = r * 0.8
	cyl.bottom_radius = r
	cyl.height = maxf(a.distance_to(b), 0.0001)
	cyl.radial_segments = 5
	cyl.rings = 0
	mi.mesh = cyl
	mi.material_override = _mat(c, 0.0)
	mi.position = (a + b) * 0.5
	var dir: Vector3 = (b - a).normalized()
	if absf(dir.dot(Vector3.UP)) < 0.999:
		mi.look_at_from_position(mi.position, mi.position + dir, Vector3.UP)
		mi.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	return mi


func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m
