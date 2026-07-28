extends Node3D
class_name KnowledgePrism

# @identity
# essence: one white beam goes in a triangular glass wedge and seven coloured beams come out the far face, each leaving at its own angle — the white was never one thing, and the prism does not add the colours, it stops hiding them
# desire: a pedestal-scale object that argues rather than illustrates; the split has to happen in front of the eye at a measurable spread, not be printed on a poster of a prism
# critical_parameter: spread_degrees against base_deviation_degrees — how far apart the exit angles fan versus how far the whole bundle bends; widen the spread and the claim is loud, close it to zero and the artifact honestly draws a prism that refracts without dispersing
# triggers: _ready() raises the wedge on a stem, lays the incoming beam onto the entry face, then emits beam_count exit cylinders from the far face at deviations interpolated across the spread, each tinted from a seven-stop spectral table
# emerges: a claim you can measure with your head — move sideways and the beams stay put, because they are geometry, not a picture of geometry; the widest-deviating beam is always the violet one
# needs: PrismMesh and CylinderMesh [Godot built-ins]; a rim-lit translucent StandardMaterial3D for the wedge and unshaded emissive beams; Grid.gdshader for the pad and stem [present]; TextScreen PAD plate [present]
# relationships: the primitive the knowledge-and-refraction rooms lean on — wherever a map wants "one input, many readings" stated as an object rather than a caption, this is the object
# truth: the prism adds nothing. Every colour leaving it was already in the beam that entered; separation is not creation, and a thing that looks singular usually just has not been made to bend yet.

## Small, static, pedestal scale. A triangular wedge of glass, one narrow white
## beam entering the near face, and a fan of coloured beams leaving the far one.
## Everything is procedural in _ready(); nothing is authored in the scene.

@export var prism_size: float = 0.20          # width of the triangular wedge
@export var prism_depth: float = 0.16         # extrusion along Z
@export var stem_height: float = 0.45
@export var beam_count: int = 7
@export var spread_degrees: float = 26.0      # angular width of the exit fan
@export var base_deviation_degrees: float = 6.0   # how far the whole bundle bends
@export var in_beam_length: float = 0.34
@export var out_beam_length: float = 0.42
@export var beam_radius: float = 0.008
@export var plate_label: String = "KNOWLEDGE PRISM"
@export var plate_note: String = "white was never one thing"

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

const PAD_W := 0.44

## Seven stops, red to violet. The fan is sampled from this table, so the beam
## that deviates most is always the violet one — the dispersion is ordered, not
## a rainbow scattered for decoration.
const SPECTRUM: Array[Color] = [
	Color(1.00, 0.28, 0.24),
	Color(1.00, 0.55, 0.20),
	Color(1.00, 0.88, 0.28),
	Color(0.40, 0.95, 0.45),
	Color(0.32, 0.88, 1.00),
	Color(0.36, 0.52, 1.00),
	Color(0.66, 0.36, 0.98),
]

var _built: bool = false
## Only what THIS script parented onto itself. Label plates, packaging and tag
## markers the grid adds after us are not ours to free.
var _created: Array[Node] = []


func _ready() -> void:
	_build_all()
	_built = true


# ─────────────────────────────────────────────────────────────────────
# BUILD
# ─────────────────────────────────────────────────────────────────────

func _build_all() -> void:
	_build_pad()
	_build_stem()
	var centre: Vector3 = Vector3(0.0, _prism_y(), 0.0)
	_build_prism(centre)
	_build_in_beam(centre)
	_build_out_fan(centre)
	_build_plate()


func _prism_y() -> float:
	return 0.03 + stem_height + prism_size * 0.5


func _build_pad() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Pad"
	var box := BoxMesh.new()
	box.size = Vector3(PAD_W, 0.03, PAD_W)
	mi.mesh = box
	mi.position = Vector3(0.0, 0.015, 0.0)
	mi.material_override = _witness_mat()
	_spawn(mi)


func _build_stem() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Stem"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.035
	cyl.bottom_radius = 0.05
	cyl.height = stem_height
	cyl.radial_segments = 12
	mi.mesh = cyl
	mi.position = Vector3(0.0, 0.03 + stem_height * 0.5, 0.0)
	mi.material_override = _witness_mat()
	_spawn(mi)


## The wedge itself. PrismMesh's triangle lies in XY and extrudes along Z, so an
## apex-up prism presents one slanted face to -X (entry) and one to +X (exit) —
## exactly the two faces the beams need.
func _build_prism(centre: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Prism"
	var pm := PrismMesh.new()
	pm.size = Vector3(prism_size, prism_size, prism_depth)
	pm.left_to_right = 0.5
	mi.mesh = pm
	mi.position = centre
	mi.material_override = _glass_mat()
	_spawn(mi)


## One narrow white beam, arriving level, meeting the entry face slightly below
## the apex. Deliberately thin: the whole point is that a single line goes in.
func _build_in_beam(centre: Vector3) -> void:
	var entry: Vector3 = centre + Vector3(-prism_size * 0.22, -prism_size * 0.12, 0.0)
	var start: Vector3 = entry + Vector3(-in_beam_length, 0.0, 0.0)
	var mat: Material = _beam_mat(Color(1.0, 1.0, 0.97), 3.2)
	var beam := _beam(start, entry, beam_radius, mat)
	beam.name = "InBeam"
	_spawn(beam)


## The fan. Each exit beam leaves the far face at its own deviation; the
## deviations are evenly spaced across spread_degrees and centred on
## base_deviation_degrees, so at spread 0 the artifact honestly draws a prism
## that bends the light without separating it.
func _build_out_fan(centre: Vector3) -> void:
	var exit_p: Vector3 = centre + Vector3(prism_size * 0.22, -prism_size * 0.04, 0.0)
	var n: int = maxi(1, beam_count)
	var half: float = deg_to_rad(spread_degrees) * 0.5
	var base: float = deg_to_rad(base_deviation_degrees)
	for i in n:
		var f: float = 0.0
		if n > 1:
			f = float(i) / float(n - 1)
		# f = 0 is the least-deviated beam (red), f = 1 the most (violet).
		var ang: float = base - half + f * (half * 2.0)
		var dir: Vector3 = Vector3(cos(ang), sin(ang), 0.0)
		var col: Color = _spectral(f)
		var mat: Material = _beam_mat(col, 2.4)
		var beam := _beam(exit_p, exit_p + dir * out_beam_length, beam_radius * 0.85, mat)
		beam.name = "OutBeam%d" % i
		_spawn(beam)


func _build_plate() -> void:
	# Configure BEFORE add_child — TextScreen's setters only rebuild once the
	# node is in-tree, so driving them afterwards costs a rebuild per property.
	var ts := TextScreenScript.new()
	ts.name = "PrismPlate"
	ts.mode = 2                     # Mode.PAD — reclined plaque
	ts.width_m = 0.30
	ts.position = Vector3(0.0, 0.035, PAD_W * 0.5 - 0.05)
	if ts.has_method("set_text"):
		ts.set_text(plate_label, plate_note)
	_spawn(ts)


# ─────────────────────────────────────────────────────────────────────
# PIECES
# ─────────────────────────────────────────────────────────────────────

## A beam between two points: one cylinder with its Y axis laid along the ray.
func _beam(p1: Vector3, p2: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var d: float = maxf(p1.distance_to(p2), 0.001)
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = d
	cyl.radial_segments = 6
	cyl.rings = 1
	mi.mesh = cyl
	var dir: Vector3 = (p2 - p1).normalized()
	var up: Vector3 = Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		up = Vector3.RIGHT
	var xa: Vector3 = up.cross(dir).normalized()
	var za: Vector3 = dir.cross(xa).normalized()
	mi.transform = Transform3D(Basis(xa, dir, za), (p1 + p2) * 0.5)
	mi.material_override = mat
	return mi


## Sample the seven-stop table at f in [0, 1].
func _spectral(f: float) -> Color:
	var last: int = SPECTRUM.size() - 1
	var x: float = clampf(f, 0.0, 1.0) * float(last)
	var i: int = int(floor(x))
	if i >= last:
		return SPECTRUM[last]
	var t: float = x - float(i)
	var a: Color = SPECTRUM[i]
	var b: Color = SPECTRUM[i + 1]
	return a.lerp(b, t)


func _spawn(node: Node) -> void:
	add_child(node)
	_created.append(node)


# ─────────────────────────────────────────────────────────────────────
# MATERIALS
# ─────────────────────────────────────────────────────────────────────

## Translucent, rim-lit, faintly backlit — glass that shows its edges. The rim
## is what makes a wedge read as a wedge from any angle in a dim map.
func _glass_mat() -> Material:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.72, 0.82, 0.96, 0.30)
	m.metallic = 0.15
	m.roughness = 0.06
	m.rim_enabled = true
	m.rim = 1.0
	m.rim_tint = 0.4
	m.backlight_enabled = true
	m.backlight = Color(0.35, 0.55, 0.75)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## Beams are light, not surfaces: unshaded, additive, no depth writing, so they
## cross the wedge without carving a hole in it.
func _beam_mat(col: Color, energy: float) -> Material:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(col.r, col.g, col.b, 0.9)
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _witness_mat() -> Material:
	return _grid_material(Color(0.28, 0.30, 0.36), Color(0.45, 0.52, 0.64), 0.6)


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
	fallback.roughness = 0.4
	return fallback


# ─────────────────────────────────────────────────────────────────────
# GRID CONFIG
# ─────────────────────────────────────────────────────────────────────

## Synchronous rebuild of our own children only. Nothing deferred: the grid
## frames labels and grounds the artifact immediately after add_child, and a
## deferred rebuild would land after both and undo them.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_build_all()


func apply_grid_config(config_data: Dictionary) -> void:
	var before: Array = [beam_count, spread_degrees, base_deviation_degrees,
		prism_size, stem_height, out_beam_length, in_beam_length,
		plate_label, plate_note]

	if config_data.has("beam_count"):
		beam_count = maxi(1, int(config_data["beam_count"]))
	if config_data.has("spread_degrees"):
		spread_degrees = float(config_data["spread_degrees"])
	if config_data.has("base_deviation_degrees"):
		base_deviation_degrees = float(config_data["base_deviation_degrees"])
	if config_data.has("prism_size"):
		prism_size = maxf(0.05, float(config_data["prism_size"]))
	if config_data.has("stem_height"):
		stem_height = maxf(0.0, float(config_data["stem_height"]))
	if config_data.has("out_beam_length"):
		out_beam_length = maxf(0.05, float(config_data["out_beam_length"]))
	if config_data.has("in_beam_length"):
		in_beam_length = maxf(0.05, float(config_data["in_beam_length"]))
	if config_data.has("label"):
		plate_label = str(config_data["label"])
	if config_data.has("note"):
		plate_note = str(config_data["note"])

	if not _built:
		return  # _ready has not run yet; it will build with these values.
	var after: Array = [beam_count, spread_degrees, base_deviation_degrees,
		prism_size, stem_height, out_beam_length, in_beam_length,
		plate_label, plate_note]
	if after == before:
		# Nothing geometric changed. curation_station hands artifacts an
		# {"emissive": false} one line after framing their labels; rebuilding
		# here would throw that framing away and it is never re-applied.
		return

	_rebuild_now()
	print("[KnowledgePrism] Config applied — beams=%d, spread=%.1f deg" % [beam_count, spread_degrees])
