extends Node3D
class_name LatentSpaceWalk

# @identity
# essence: a 3 x 3 m floor plate carrying a 7 x 7 lattice of decoded forms, each one the bilinear blend of four corner genotypes — spire, drum, helix, bloom — so the shape under your left foot and the shape under your right differ by exactly one step of the interpolation
# desire: to put a latent space at body scale instead of on a screen; the walk between two samples is the argument, and an argument about traversal cannot be made by a picture of a grid
# critical_parameter: grid_n — the sampling density of the walk; at 3 the corners read as four unrelated objects, at 7 the morph is continuous, at 11 neighbours become indistinguishable and the lattice stops being legible as steps
# triggers: _ready() lays the plate and lattice lines, then for every cell computes (u, v), blends the four anchor parameter vectors bilinearly, and stacks segments whose radius profile, twist and colour are read straight off the blended vector
# emerges: interpolation felt as distance — the space between two learned forms turns out to be full of forms that were never learned, and every one of them is somewhere you can stand
# needs: MultiMesh of BoxMesh segments [one draw call for 49 forms]; Label3D corner anchors [Godot built-in]; no trained model — the decoder here is four hand-written vectors and a bilinear blend, which is the honest minimum
# relationships: the walkable rung of the machinelearning generative ladder — where a VAE demo shows a slider moving a face, this shows what the slider is: a coordinate in a space that was always dense
# truth: a latent space has no gaps. Every point between two things it learned decodes to something, and most of those somethings were never in the training data — the model is mostly made of what nobody showed it.

## 3 x 3 x 1 m, room scale. The plane is walkable and the walk is the point:
## crossing it in x moves you along one latent axis, crossing it in z the other.
## No trained model is involved and none is claimed — the decoder is four corner
## vectors and a bilinear blend, which is what an interpolation actually is.

@export var plane_size: float = 3.0
@export var grid_n: int = 7
@export var segments: int = 6
@export var show_anchor_labels: bool = true

## The four corner genotypes, in the order [h, radius, twist_per_segment,
## lobe_amp, lobe_freq]. These are the only "learned" points in the space;
## everything else on the plate is between them.
const ANCHOR_A: Array[float] = [0.56, 0.030, 0.00, 0.00, 1.0]   # (u0,v0) spire
const ANCHOR_B: Array[float] = [0.17, 0.110, 0.05, 0.00, 1.0]   # (u1,v0) drum
const ANCHOR_C: Array[float] = [0.46, 0.055, 0.85, 0.10, 1.0]   # (u0,v1) helix
const ANCHOR_D: Array[float] = [0.30, 0.095, 0.22, 0.55, 3.0]   # (u1,v1) bloom

const COLOR_A := Color(0.36, 0.86, 1.00)
const COLOR_B := Color(1.00, 0.76, 0.32)
const COLOR_C := Color(0.86, 0.42, 0.98)
const COLOR_D := Color(0.44, 0.94, 0.56)

const ANCHOR_NAMES: PackedStringArray = ["SPIRE", "DRUM", "HELIX", "BLOOM"]

const PLATE_H := 0.06
const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"

var _built: bool = false
## Only what THIS script parented onto itself — the grid adds label plates and
## tag markers after us and those are not ours to free.
var _created: Array[Node] = []


func _ready() -> void:
	_build_all()
	_built = true


# ─────────────────────────────────────────────────────────────────────
# BUILD
# ─────────────────────────────────────────────────────────────────────

func _build_all() -> void:
	_build_plate()
	_build_lattice_lines()
	_build_forms()
	if show_anchor_labels:
		_build_anchor_labels()
		_build_caption()


func _build_plate() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Plate"
	var box := BoxMesh.new()
	box.size = Vector3(plane_size, PLATE_H, plane_size)
	mi.mesh = box
	mi.position = Vector3(0.0, PLATE_H * 0.5, 0.0)
	mi.material_override = _plate_mat()
	_spawn(mi)


## The lattice the samples sit on, drawn as thin inlaid strips. Without them the
## forms read as scattered props; with them the plate reads as a coordinate
## system you are standing inside.
func _build_lattice_lines() -> void:
	var n: int = maxi(2, grid_n)
	var half: float = plane_size * 0.5
	var pitch: float = plane_size / float(n)
	var mat: Material = _line_mat()
	for i in n + 1:
		var t: float = -half + float(i) * pitch
		var row := MeshInstance3D.new()
		var rb := BoxMesh.new()
		rb.size = Vector3(plane_size, 0.006, 0.012)
		row.mesh = rb
		row.position = Vector3(0.0, PLATE_H + 0.003, t)
		row.material_override = mat
		_spawn(row)
		var col := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(0.012, 0.006, plane_size)
		col.mesh = cb
		col.position = Vector3(t, PLATE_H + 0.003, 0.0)
		col.material_override = mat
		_spawn(col)


## Every decoded form in the lattice, as one MultiMesh of stacked box segments.
## 49 forms x 6 segments is 294 instances and one draw call; building them as
## individual MeshInstance3Ds would be 294 nodes for the same pixels.
func _build_forms() -> void:
	var n: int = maxi(2, grid_n)
	var segs: int = maxi(2, segments)
	var half: float = plane_size * 0.5
	var pitch: float = plane_size / float(n)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = n * n * segs

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "DecodedField"
	mmi.multimesh = mm
	mmi.material_override = _form_mat()

	var k: int = 0
	for i in n:
		for j in n:
			var u: float = float(i) / float(n - 1)
			var v: float = float(j) / float(n - 1)
			var p: Array = _decode(u, v)
			var col: Color = _blend_color(u, v)
			var cx: float = -half + pitch * (float(i) + 0.5)
			var cz: float = -half + pitch * (float(j) + 0.5)
			var h: float = float(p[0])
			var base_r: float = float(p[1])
			var twist: float = float(p[2])
			var lobe_amp: float = float(p[3])
			var lobe_freq: float = float(p[4])
			var seg_h: float = h / float(segs)
			for s in segs:
				var t: float = (float(s) + 0.5) / float(segs)
				# taper along the stack, then modulate by the lobe term — the two
				# ingredients that separate a spire from a bloom.
				var taper: float = 0.55 + 0.45 * sin(t * PI)
				var lobe: float = 1.0 + lobe_amp * sin(t * TAU * lobe_freq)
				var r: float = maxf(0.006, base_r * taper * lobe)
				var y: float = PLATE_H + seg_h * (float(s) + 0.5)
				var b: Basis = Basis(Vector3.UP, twist * float(s))
				b = b.scaled(Vector3(r * 2.0, seg_h, r * 2.0))
				mm.set_instance_transform(k, Transform3D(b, Vector3(cx, y, cz)))
				# darken toward the base so the stack reads as a stack
				var shade: float = 0.55 + 0.45 * t
				mm.set_instance_color(k, Color(col.r * shade, col.g * shade, col.b * shade, 1.0))
				k += 1

	_spawn(mmi)


## Names the four learned points and nothing else. Every other form on the plate
## is deliberately unlabelled — it has no name because nobody ever made one.
func _build_anchor_labels() -> void:
	var half: float = plane_size * 0.5 - 0.16
	var spots: Array = [
		[Vector3(-half, 0.0, -half), COLOR_A, 0],
		[Vector3(half, 0.0, -half), COLOR_B, 1],
		[Vector3(-half, 0.0, half), COLOR_C, 2],
		[Vector3(half, 0.0, half), COLOR_D, 3],
	]
	for spot in spots:
		var pos: Vector3 = spot[0]
		var col: Color = spot[1]
		var idx: int = int(spot[2])
		var post := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(0.05, 0.72, 0.05)
		post.mesh = pb
		post.position = pos + Vector3(0.0, PLATE_H + 0.36, 0.0)
		post.material_override = _post_mat(col)
		_spawn(post)
		var label := Label3D.new()
		label.text = ANCHOR_NAMES[idx]
		label.font_size = 26
		label.outline_size = 6
		label.modulate = col
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = pos + Vector3(0.0, PLATE_H + 0.84, 0.0)
		_spawn(label)


func _build_caption() -> void:
	var label := Label3D.new()
	label.text = "everything between the corners\nwas never trained on"
	label.font_size = 22
	label.outline_size = 5
	label.modulate = Color(0.80, 0.86, 0.95)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0.0, PLATE_H + 1.25, 0.0)
	_spawn(label)


# ─────────────────────────────────────────────────────────────────────
# THE DECODER — four vectors and a bilinear blend
# ─────────────────────────────────────────────────────────────────────

## Bilinear interpolation of the four anchor parameter vectors at (u, v).
## This is the whole "model": no weights, no training, no sampling — the space
## is dense because interpolation is dense, and that is the honest claim.
func _decode(u: float, v: float) -> Array:
	var out: Array = []
	var wa: float = (1.0 - u) * (1.0 - v)
	var wb: float = u * (1.0 - v)
	var wc: float = (1.0 - u) * v
	var wd: float = u * v
	for c in ANCHOR_A.size():
		var val: float = ANCHOR_A[c] * wa + ANCHOR_B[c] * wb + ANCHOR_C[c] * wc + ANCHOR_D[c] * wd
		out.append(val)
	return out


func _blend_color(u: float, v: float) -> Color:
	var top: Color = COLOR_A.lerp(COLOR_B, u)
	var bot: Color = COLOR_C.lerp(COLOR_D, u)
	return top.lerp(bot, v)


func _spawn(node: Node) -> void:
	add_child(node)
	_created.append(node)


# ─────────────────────────────────────────────────────────────────────
# MATERIALS
# ─────────────────────────────────────────────────────────────────────

func _form_mat() -> Material:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.emission_enabled = true
	m.emission = Color.WHITE
	m.emission_energy_multiplier = 0.45
	m.roughness = 0.45
	return m


func _post_mat(col: Color) -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 0.9
	return m


func _line_mat() -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.52, 0.66)
	m.emission_enabled = true
	m.emission = Color(0.40, 0.60, 0.85)
	m.emission_energy_multiplier = 0.7
	return m


func _plate_mat() -> Material:
	return _grid_material(Color(0.16, 0.18, 0.23), Color(0.34, 0.44, 0.60), 0.5)


func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.5
	return fallback


# ─────────────────────────────────────────────────────────────────────
# GRID CONFIG
# ─────────────────────────────────────────────────────────────────────

## Synchronous and scoped to our own children. Nothing deferred: the grid frames
## labels and grounds the artifact immediately after add_child, and a deferred
## rebuild would land after both and undo them.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_build_all()


func apply_grid_config(config_data: Dictionary) -> void:
	var before: Array = [plane_size, grid_n, segments, show_anchor_labels]

	if config_data.has("plane_size"):
		plane_size = maxf(0.5, float(config_data["plane_size"]))
	if config_data.has("grid_n"):
		grid_n = clampi(int(config_data["grid_n"]), 2, 15)
	if config_data.has("segments"):
		segments = clampi(int(config_data["segments"]), 2, 12)
	if config_data.has("show_anchor_labels"):
		show_anchor_labels = bool(config_data["show_anchor_labels"])

	if not _built:
		return  # _ready has not run yet; it will build with these values.
	var after: Array = [plane_size, grid_n, segments, show_anchor_labels]
	if after == before:
		# Nothing geometric changed — leave the placement exactly as it stands.
		return

	_rebuild_now()
	print("[LatentSpaceWalk] Config applied — grid=%dx%d over %.2f m" % [grid_n, grid_n, plane_size])
