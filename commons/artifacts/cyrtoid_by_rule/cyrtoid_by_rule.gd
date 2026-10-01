extends Node3D
class_name CyrtoidByRule

# @identity
# essence: one radiolarian shell of the order Cyrtoidea, after Haeckel's plate 31
#   (Kunstformen der Natur, 1904), made by five rules in a row: a profile, the
#   profile turned round its axis, pores opened cell by cell, feet and teeth
#   branched from the lip, bristles branched from a few bars.
# desire: to be read as a sentence of operations and not as a model. Each value of
#   `stage` stops the sentence one rule earlier, so a row of them is the body's own
#   recipe; each value of `form` is the same sentence with other numbers.
# critical_parameter: stage. At "turned" it is a vase; one rule later it is a
#   skeleton. The pore rule is the one that changes what kind of thing this is.
# triggers: _ready() and apply_grid_config() build it; nothing moves afterwards.
# emerges: six forms that a visitor reads as six species are one class and about
#   ten numbers. Haeckel's plate is a comparison sheet of one family.
# needs: MeshData.create_lathe, CellInsetOp, ExtrudeFaceOp, TubeBranchOp [present]
# relationships: kin to `haeckel` (mode cyrtoid), which builds the same order of
#   shells from struts over a surface of revolution; this one uses the mesh
#   grammar's operations and shows them one at a time. It is the Godot course's
#   opening image, remade.
# truth: the wall is a sheet with no thickness, the pores are hexagons where the
#   plate has rounded ones, and the feet are straight. The plate is an
#   idealisation too: its symmetry is drawn.

const CellInsetOp = preload("res://commons/mesh_grammar/operations/cell_inset_op.gd")
const ExtrudeOp = preload("res://commons/mesh_grammar/operations/extrude_face_op.gd")
const TubeOp = preload("res://commons/mesh_grammar/operations/tube_branch_op.gd")

## Which of the plate's bodies. The same rules, other numbers.
@export_enum("helmet", "ovoid", "fringed_dome", "flask", "tripod", "great_dome") var form: String = "helmet":
	set(value):
		form = value
		_rebuild()

## How far down the list of rules the body is built.
@export_enum("profile", "turned", "pored", "footed", "bristled") var stage: String = "bristled":
	set(value):
		stage = value
		_rebuild()

## Height of the shell without its feet, in metres.
@export var height: float = 1.2:
	set(value):
		height = value
		_rebuild()

## Height of the shell's lowest point above this node. Feet hang below it.
@export var lift: float = 0.9:
	set(value):
		lift = value
		_rebuild()

const STAGES: PackedStringArray = ["profile", "turned", "pored", "footed", "bristled"]

## The numbers of each form. points: the profile, Vector2(radius, height), top to
## bottom, the shell spanning about -1 to 1. band: the heights between which pores
## are opened. bar: the bar's width at the top and at the bottom of that band.
## feet and teeth: [count, length, radius] and [count, length]; a count of 0 is none.
## bristles: [share of the bars, length, seed].
const FORMS: Dictionary = {
	"helmet": {
		"points": [Vector2(0.0, 0.97), Vector2(0.025, 0.64), Vector2(0.10, 0.57), Vector2(0.13, 0.47),
			Vector2(0.09, 0.39), Vector2(0.26, 0.21), Vector2(0.44, -0.10), Vector2(0.52, -0.40),
			Vector2(0.50, -0.50), Vector2(0.40, -0.58)],
		"rows": 30, "segments": 36, "band": [0.60, -0.48], "bar": [0.52, 0.24],
		"feet": [3, 0.62, 0.05], "teeth": [0, 0.0], "bristles": [0.06, 0.38, 7],
	},
	"ovoid": {
		"points": [Vector2(0.0, 0.80), Vector2(0.126, 0.773), Vector2(0.243, 0.693), Vector2(0.338, 0.566),
			Vector2(0.407, 0.400), Vector2(0.447, 0.207), Vector2(0.455, 0.0), Vector2(0.432, -0.207),
			Vector2(0.381, -0.400), Vector2(0.306, -0.566), Vector2(0.213, -0.693), Vector2(0.10, -0.80),
			Vector2(0.10, -0.92), Vector2(0.07, -0.95)],
		"rows": 26, "segments": 30, "band": [0.70, -0.72], "bar": [0.34, 0.34],
		"feet": [0, 0.0, 0.0], "teeth": [6, 0.16], "bristles": [0.02, 0.18, 5],
	},
	"fringed_dome": {
		"points": [Vector2(0.0, 0.84), Vector2(0.02, 0.62), Vector2(0.10, 0.54), Vector2(0.10, 0.42),
			Vector2(0.30, 0.32), Vector2(0.50, 0.08), Vector2(0.52, -0.16), Vector2(0.44, -0.26), Vector2(0.34, -0.30)],
		"rows": 22, "segments": 36, "band": [0.40, -0.14], "bar": [0.45, 0.30],
		"feet": [0, 0.0, 0.0], "teeth": [18, 0.34], "bristles": [0.03, 0.20, 5],
	},
	"flask": {
		"points": [Vector2(0.0, 0.97), Vector2(0.02, 0.80), Vector2(0.08, 0.76), Vector2(0.10, 0.68), Vector2(0.07, 0.62),
			Vector2(0.15, 0.52), Vector2(0.12, 0.44), Vector2(0.21, 0.32), Vector2(0.17, 0.22), Vector2(0.28, 0.08),
			Vector2(0.24, -0.02), Vector2(0.46, -0.22), Vector2(0.54, -0.48), Vector2(0.44, -0.74), Vector2(0.22, -0.88),
			Vector2(0.0, -0.90)],
		"rows": 44, "segments": 42, "band": [0.74, -0.86], "bar": [0.55, 0.28],
		"feet": [3, 0.30, 0.03], "teeth": [0, 0.0], "bristles": [0.02, 0.22, 9],
	},
	"tripod": {
		"points": [Vector2(0.0, 1.0), Vector2(0.02, 0.68), Vector2(0.09, 0.62), Vector2(0.11, 0.52), Vector2(0.08, 0.46),
			Vector2(0.22, 0.36), Vector2(0.31, 0.18), Vector2(0.30, 0.06), Vector2(0.22, -0.02)],
		"rows": 20, "segments": 30, "band": [0.50, 0.08], "bar": [0.45, 0.30],
		"feet": [3, 0.95, 0.045], "teeth": [0, 0.0], "bristles": [0.05, 0.22, 11],
	},
	"great_dome": {
		"points": [Vector2(0.0, 1.0), Vector2(0.025, 0.70), Vector2(0.09, 0.64), Vector2(0.12, 0.54), Vector2(0.10, 0.46),
			Vector2(0.34, 0.30), Vector2(0.56, 0.02), Vector2(0.66, -0.28), Vector2(0.62, -0.40), Vector2(0.52, -0.46)],
		"rows": 20, "segments": 24, "band": [0.66, -0.38], "bar": [0.60, 0.12],
		"feet": [0, 0.0, 0.0], "teeth": [12, 0.30], "bristles": [0.06, 0.55, 3],
	},
}

var _bone: StandardMaterial3D
## True while apply_grid_config sets several fields: build once, at the end.
var _hold: bool = false


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	_hold = true
	if config_data.has("form"):
		form = str(config_data["form"])
	if config_data.has("stage"):
		stage = str(config_data["stage"])
	if config_data.has("height"):
		height = float(config_data["height"])
	if config_data.has("lift"):
		lift = float(config_data["lift"])
	_hold = false
	_rebuild()


## The numbers of the current form; an unknown name gives the helmet and says so.
func recipe() -> Dictionary:
	if not FORMS.has(form):
		push_warning("[cyrtoid_by_rule] no form named '%s'; building the helmet. Known: %s" % [form, ", ".join(FORMS.keys())])
		return FORMS["helmet"]
	return FORMS[form]


## The shell as mesh data, in the profile's own units, at the given stage.
func build_shell(at_stage: String) -> MeshData:
	var r: Dictionary = recipe()
	var step: int = STAGES.find(at_stage)
	if step < 0:
		push_warning("[cyrtoid_by_rule] no stage named '%s'; building all of it." % at_stage)
		step = STAGES.size() - 1
	var md: MeshData = MeshData.create_lathe(resample(r["points"], int(r["rows"])), int(r["segments"]))
	if step >= 2:
		var top: float = r["band"][0]
		var bottom: float = r["band"][1]
		var band := MeshSelector.by_callable(func(m: MeshData, i: int) -> bool:
			var y: float = m.get_face_centroid(i).y
			return y <= top and y > bottom)
		CellInsetOp.new(band, {"bar": float(r["bar"][0]), "bar_end": float(r["bar"][1])}).apply(md)
	if step >= 3:
		if int(r["feet"][0]) > 0:
			TubeOp.new(lip_faces(md, int(r["feet"][0])), {"length": float(r["feet"][1]), "start_radius": float(r["feet"][2]),
				"end_radius": 0.003, "segments": 6, "rings": 6, "curve_amount": 0.0}).apply(md)
		if int(r["teeth"][0]) > 0:
			ExtrudeOp.new(lip_faces(md, int(r["teeth"][0])), {"distance": float(r["teeth"][1]), "scale": 0.05, "min_area": 0.000001}).apply(md)
	if step >= 4:
		var some := MeshSelector.by_tag("bar").and_also(MeshSelector.by_random(float(r["bristles"][0]), int(r["bristles"][2])))
		TubeOp.new(some, {"length": float(r["bristles"][1]), "start_radius": 0.010, "end_radius": 0.001,
			"segments": 3, "rings": 1, "curve_amount": 0.0}).apply(md)
	return md


## A profile from a few control points, cut into `rows` equal steps.
func resample(points: Array, rows: int) -> PackedVector2Array:
	var lengths: Array[float] = [0.0]
	for i in range(1, points.size()):
		lengths.append(lengths[i - 1] + (points[i] as Vector2).distance_to(points[i - 1]))
	var total: float = lengths[-1]
	var out := PackedVector2Array()
	for row in range(rows + 1):
		var s: float = total * float(row) / float(rows)
		var k: int = 1
		while k < points.size() - 1 and lengths[k] < s:
			k += 1
		var t: float = inverse_lerp(lengths[k - 1], lengths[k], s)
		out.append((points[k - 1] as Vector2).lerp(points[k], clampf(t, 0.0, 1.0)))
	return out


## `count` faces that look down, evenly round the axis: the lip of the mouth.
func lip_faces(md: MeshData, count: int) -> MeshSelector:
	var picked := PackedInt32Array()
	for k in range(count):
		var want: float = TAU * (float(k) + 0.25) / float(count)
		var best: int = -1
		var near: float = INF
		for fi in range(md.faces.size()):
			if md.get_face_normal(fi).y > -0.5:
				continue
			var c: Vector3 = md.get_face_centroid(fi)
			var off: float = absf(angle_difference(atan2(c.z, c.x), want))
			if off < near:
				near = off
				best = fi
		if best >= 0 and not picked.has(best):
			picked.append(best)
	return MeshSelector.by_index(picked)


func _rebuild() -> void:
	if _hold or not is_node_ready():
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var r: Dictionary = recipe()
	var k: float = height / 2.0
	var lowest: float = INF
	for p in r["points"]:
		lowest = minf(lowest, (p as Vector2).y)
	var raise: float = lift - lowest * k

	var body := MeshInstance3D.new()
	body.name = "Shell"
	if stage == "profile":
		body.mesh = _profile_mesh(resample(r["points"], int(r["rows"])), k)
	else:
		body.mesh = _shell_mesh(build_shell(stage), k)
		body.material_override = _bone_material()
	body.position = Vector3(0.0, raise, 0.0)
	add_child(body)


## MeshData winds its faces counter-clockwise seen from outside; Godot draws the
## clockwise side. Each face is written turned over, with its outward normal, and
## the material shows both sides, so the far wall is seen through the pores.
func _shell_mesh(md: MeshData, k: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for fi in range(md.faces.size()):
		var f: PackedInt32Array = md.faces[fi]
		var n: Vector3 = md.get_face_normal(fi)
		for corner in [0, 2, 1]:
			st.set_normal(n)
			st.add_vertex(md.vertices[f[corner]] * k)
	return st.commit()


## Stage "profile": the half outline and the axis it will turn round, as two
## thin ribbons that face the approach.
func _profile_mesh(points: PackedVector2Array, k: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w: float = 0.006
	for i in range(points.size() - 1):
		_ribbon(st, Vector3(points[i].x, points[i].y, 0.0) * k, Vector3(points[i + 1].x, points[i + 1].y, 0.0) * k, w)
	_ribbon(st, Vector3(0.0, 1.05, 0.0) * k, Vector3(0.0, -1.0, 0.0) * k, w * 0.5)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	var line := StandardMaterial3D.new()
	line.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.albedo_color = Color(0.95, 0.93, 0.88)
	line.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, line)
	return mesh


func _ribbon(st: SurfaceTool, a: Vector3, b: Vector3, half_width: float) -> void:
	var along: Vector3 = (b - a).normalized()
	var side: Vector3 = along.cross(Vector3.BACK).normalized() * half_width
	if side.length_squared() < 0.0000001:
		side = Vector3.RIGHT * half_width
	st.add_vertex(a - side)
	st.add_vertex(a + side)
	st.add_vertex(b + side)
	st.add_vertex(a - side)
	st.add_vertex(b + side)
	st.add_vertex(b - side)


func _bone_material() -> StandardMaterial3D:
	if _bone == null:
		_bone = StandardMaterial3D.new()
		_bone.albedo_color = Color(0.95, 0.93, 0.88)
		_bone.roughness = 0.9
		_bone.cull_mode = BaseMaterial3D.CULL_DISABLED
		# A floor of light, so the thin bars do not go black in a dark hall.
		_bone.emission_enabled = true
		_bone.emission = Color(0.95, 0.93, 0.88)
		_bone.emission_energy_multiplier = 0.12
	return _bone
