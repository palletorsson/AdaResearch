extends Node3D
class_name ProbabilitySphere

# @identity
# essence: a wire-caged sphere holding a fixed table of sample points, re-seated by the chosen distribution so the crowding of the dots IS the probability and the cage IS the space they were drawn from
# desire: to stop probability being a number printed on a face and make it a place — somewhere you can look and see that the outcomes are not spread evenly, and see where they went instead
# critical_parameter: distribution — uniform / centre / shell / split; it changes only the radius each fixed direction is pushed to, so the sample space is provably the same object across all four and only the density moved
# triggers: _ready() builds the Halton table (radical inverse, base 2/3/5), applies a fixed stride shuffle, maps each point's third coordinate through the inverse CDF of the chosen profile, and writes the result into one MultiMesh
# emerges: the four profiles read as four different objects until you notice the cage never changed size — the argument that a distribution is not a shape but a way of occupying one
# needs: SphereMesh points [Godot built-in, one MultiMesh]; TorusMesh great circles [built-in]; Grid.gdshader for the cage [present]; TextScreen PAD plate [present]
# relationships: the seq-1..6 companion to the randomness sequence's live samplers — this is what those artifacts show once you take the clock out and are left with the distribution itself
# truth: no randf() runs here, and nothing about the picture would improve if one did. Randomness is not the generator; it is the shape the generator's outputs pile into, and a fixed table piles the same way every time.

## A compact pedestal sphere for the `structure` sequence, where randf() is not yet
## curriculum. Every point comes from a deterministic low-discrepancy table
## (Halton, bases 2/3/5) put through a fixed stride shuffle — the same table, the
## same order, on every build and every machine. What the distribution axis moves
## is where along its own ray each point is allowed to sit.

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

## Size of the baked sample table. The shuffle stride is coprime with it, so
## _shuffled_index is a permutation and never repeats a point.
const TABLE_SIZE: int = 256
const SHUFFLE_STRIDE: int = 37
const SHUFFLE_OFFSET: int = 11

@export var shell_radius: float = 0.30
@export var samples: int = 120
@export var point_radius: float = 0.017
@export var sphere_label: String = "PROBABILITY SPHERE"

## Which way the density leans. Only the radial mapping changes — direction,
## count and cage are identical across all four values, which is the claim.
##   uniform  density flat through the ball; radius = R * u^(1/3)
##   centre   density piles on the mean; radius = R * u
##   shell    density hugs the boundary; radius = R * u^(1/9)
##   split    one space, two answers — two small lobes above and below the mean
@export_enum("uniform", "centre", "shell", "split") var distribution: String = "uniform"

const DISTRIBUTIONS: PackedStringArray = ["uniform", "centre", "shell", "split"]

const NOTES: Dictionary = {
	"uniform": "every outcome equally likely",
	"centre": "the density collapses on the mean",
	"shell": "the likely outcomes are all at the edge",
	"split": "one space, two answers",
}

const PAD_W: float = 0.62
const CENTRE_Y: float = 0.42

var _built: bool = false

## Every node THIS script parented onto itself. A rebuild frees these and nothing
## else — the grid adds label plates, packaging and tag markers after us, and they
## are not ours to destroy.
var _created: Array[Node] = []


func _ready() -> void:
	_build_all()
	_built = true


func _build_all() -> void:
	_build_pad()
	_build_post()
	_build_cage()
	_build_shell()
	_build_points()
	_build_label()


# ── the fixed table ──────────────────────────────────────────────────

## Van der Corput radical inverse — index written in `base`, digits reflected
## about the point. Pure integer arithmetic; no generator, no seed, no state.
func _radical_inverse(index: int, base: int) -> float:
	var result: float = 0.0
	var f: float = 1.0 / float(base)
	var i: int = index
	while i > 0:
		result += f * float(i % base)
		@warning_ignore("integer_division")
		i = i / base
		f = f / float(base)
	return result


## A permutation of the table, not a random draw. Stride 37 is coprime with 256,
## so every index is visited exactly once. The shuffle matters because `split`
## assigns lobes by parity — without it the two lobes would take the low and high
## halves of an ordered sequence and the split would be an artefact of the order.
func _shuffled_index(i: int) -> int:
	return (i * SHUFFLE_STRIDE + SHUFFLE_OFFSET) % TABLE_SIZE


## The inverse-CDF exponent. With radius = R * u^(1/k) the volume density goes as
## r^(k-3): k = 3 is flat, k < 3 leans inward, k > 3 leans outward.
func _radial_exponent() -> float:
	match distribution:
		"centre":
			return 1.0
		"shell":
			return 9.0
		_:
			return 3.0


func _sample_count() -> int:
	return clampi(samples, 8, TABLE_SIZE)


## Direction from two table coordinates, radius from the third through the
## distribution's inverse CDF. Same directions every time; only the radii move.
func _sample_points() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var n: int = _sample_count()
	var exponent: float = _radial_exponent()
	for i in range(n):
		var k: int = _shuffled_index(i) + 1        # radical inverse of 0 is 0
		var u1: float = _radical_inverse(k, 2)
		var u2: float = _radical_inverse(k, 3)
		var u3: float = _radical_inverse(k, 5)
		var z: float = 1.0 - 2.0 * u1
		var ring: float = sqrt(maxf(0.0, 1.0 - z * z))
		var phi: float = TAU * u2
		var dir: Vector3 = Vector3(ring * cos(phi), z, ring * sin(phi))
		if distribution == "split":
			var lobe: float = 1.0 if (k % 2) == 0 else -1.0
			var r_lobe: float = shell_radius * 0.38 * pow(u3, 1.0 / 3.0)
			out.append(dir * r_lobe + Vector3(0.0, lobe * shell_radius * 0.46, 0.0))
		else:
			var r: float = shell_radius * pow(u3, 1.0 / exponent)
			out.append(dir * r)
	return out


## Warm at the centre, cool at the rim. Hue carries radius so the density profile
## survives a still frame, where a cluster and a crowd look alike in grey.
func _point_color(p: Vector3) -> Color:
	var t: float = clampf(p.length() / maxf(0.0001, shell_radius), 0.0, 1.0)
	var warm: Color = Color(1.00, 0.70, 0.32)
	var cool: Color = Color(0.36, 0.78, 1.00)
	return warm.lerp(cool, t)


# ── the body ─────────────────────────────────────────────────────────

func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


func _build_pad() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Pad"
	var box := BoxMesh.new()
	box.size = Vector3(PAD_W, 0.04, PAD_W)
	mi.mesh = box
	mi.position = Vector3(0.0, 0.02, 0.0)
	mi.material_override = _witness_mat()
	_own(mi)


func _build_post() -> void:
	var bottom: float = 0.04
	var top: float = CENTRE_Y - shell_radius
	var h: float = maxf(0.02, top - bottom)
	var mi := MeshInstance3D.new()
	mi.name = "Post"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.045
	cyl.bottom_radius = 0.06
	cyl.height = h
	cyl.radial_segments = 10
	mi.mesh = cyl
	mi.position = Vector3(0.0, bottom + h * 0.5, 0.0)
	mi.material_override = _witness_mat()
	_own(mi)


## Three great circles. They are the readable edge of the sample space — the
## transparent skin alone disappears at 0.4 scale, the rings do not.
func _build_cage() -> void:
	var holder := Node3D.new()
	holder.name = "Cage"
	holder.position = Vector3(0.0, CENTRE_Y, 0.0)
	_own(holder)
	var mat: Material = _cage_mat()
	var rots: Array[Vector3] = [
		Vector3(0.0, 0.0, 0.0),
		Vector3(PI * 0.5, 0.0, 0.0),
		Vector3(0.0, 0.0, PI * 0.5),
	]
	for r in rots:
		var mi := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = maxf(0.001, shell_radius - 0.006)
		torus.outer_radius = shell_radius + 0.006
		torus.rings = 48
		torus.ring_segments = 5
		mi.mesh = torus
		mi.rotation = r
		mi.material_override = mat
		holder.add_child(mi)


## The sample space itself: a low-alpha skin that writes no depth, so every point
## inside it stays visible. Depth writing here would hide the argument behind it.
func _build_shell() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Shell"
	var sphere := SphereMesh.new()
	sphere.radius = shell_radius
	sphere.height = shell_radius * 2.0
	sphere.radial_segments = 32
	sphere.rings = 16
	mi.mesh = sphere
	mi.position = Vector3(0.0, CENTRE_Y, 0.0)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.albedo_color = Color(0.50, 0.68, 0.92, 0.11)
	mi.material_override = mat
	_own(mi)


func _build_points() -> void:
	var pts: Array[Vector3] = _sample_points()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var dot := SphereMesh.new()
	dot.radius = point_radius
	dot.height = point_radius * 2.0
	dot.radial_segments = 7
	dot.rings = 4
	mm.mesh = dot
	mm.instance_count = pts.size()
	for i in range(pts.size()):
		var p: Vector3 = pts[i]
		var t := Transform3D()
		t.origin = p
		mm.set_instance_transform(i, t)
		mm.set_instance_color(i, _point_color(p))

	var mi := MultiMeshInstance3D.new()
	mi.name = "Samples"
	mi.multimesh = mm
	mi.position = Vector3(0.0, CENTRE_Y, 0.0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mi.material_override = mat
	_own(mi)


func _build_label() -> void:
	# Configure BEFORE add_child — TextScreen's setters only rebuild once in-tree,
	# so driving them after the add costs a queue_free per property.
	var ts := TextScreenScript.new()
	ts.name = "SpherePlate"
	ts.mode = 2                       # Mode.PAD — reclined plaque
	ts.width_m = 0.34
	ts.position = Vector3(0.0, 0.045, PAD_W * 0.5 - 0.06)
	if ts.has_method("set_text"):
		ts.set_text(sphere_label, str(NOTES.get(distribution, "")))
	_created.append(ts)
	add_child(ts)


# ── material ─────────────────────────────────────────────────────────

func _cage_mat() -> Material:
	return _grid_material(Color(0.42, 0.58, 0.78), Color(0.55, 0.88, 1.0), 2.2)


func _witness_mat() -> Material:
	return _grid_material(Color(0.30, 0.32, 0.38), Color(0.45, 0.50, 0.60), 0.5)


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
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	return fallback


# ── config ───────────────────────────────────────────────────────────

## Accept an axis value only if it names something we actually build. A typo in a
## map token has to land on the shipped look whole, never half-apply.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous and scoped to our own children. Nothing deferred: the grid frames
## labels and grounds the artifact right after add_child, and a deferred rebuild
## would land after both and undo them.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_build_all()


func apply_grid_config(config_data: Dictionary) -> void:
	var before_distribution: String = distribution
	var before_samples: int = samples
	var before_radius: float = shell_radius
	var before_point: float = point_radius
	var before_label: String = sphere_label

	if config_data.has("distribution"):
		distribution = _pick_axis(str(config_data["distribution"]), DISTRIBUTIONS, distribution)
	if config_data.has("samples"):
		samples = clampi(int(config_data["samples"]), 8, TABLE_SIZE)
	if config_data.has("shell_radius"):
		shell_radius = maxf(0.05, float(config_data["shell_radius"]))
	if config_data.has("point_radius"):
		point_radius = maxf(0.003, float(config_data["point_radius"]))
	if config_data.has("label"):
		sphere_label = str(config_data["label"])

	if not _built:
		# _ready has not run yet; it will build with the values just resolved.
		return
	if (distribution == before_distribution and samples == before_samples
			and is_equal_approx(shell_radius, before_radius)
			and is_equal_approx(point_radius, before_point)
			and sphere_label == before_label):
		# Nothing geometric changed. curation_station hands every artifact it
		# curates {"emissive": false} moments after framing labels — rebuilding
		# here would throw that framing away and never get it back.
		return

	_rebuild_now()
	print("[ProbabilitySphere] Config applied — distribution=%s, samples=%d" % [distribution, _sample_count()])
