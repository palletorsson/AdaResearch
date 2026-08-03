# Mandelbrot Set Visualization - MultiMesh Optimized
# VR-optimized with GPU instancing for high performance
#
# @identity
# essence: z_{n+1} = z_n^2 + c, z_0 = 0. Each pixel is c; color = escape time. The set is the catalog of all Julia sets.
# desire: To be explored as landscape — use_3d_height lifts escaped points by iteration count, turning the fractal into a mountain range
# critical_parameter: use_3d_height — when true, the Mandelbrot boundary becomes a cliff face, the deepest iterations the tallest peaks
# triggers: ui_accept → random zoom + center; time → gentle pulse animation; goto_seahorse_valley/elephant_valley/spiral → famous coordinates
# emerges: The 3D landscape reveals that the Mandelbrot boundary is where computation is hardest — the tallest peaks are the longest escapes
# needs: VR navigation [missing], zoom control [missing], Julia set preview at cursor [missing]
# relationships: CPU MultiMesh sibling to mandelbrot_dive (GPU shader); the 3D height map that mandelbrot_dive renders flat
# truth: The Mandelbrot set is not a picture — it is an infinite computation, and the boundary is where that computation refuses to halt.

extends Node3D

# Fractal parameters
@export var resolution := 100
@export var max_iterations := 100
@export var zoom := 1.0
@export var center := Vector2(-0.5, 0.0)
@export var point_size := 0.08
@export var height_scale := 2.0
@export var use_3d_height := true

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `readout`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT THE ESCAPE COUNT IS CLAIMED TO BE. Every point of this artifact is one
# number: how many squarings c survived before it ran away. The build already
# makes a choice about that number and hides the choice in a bool — use_3d_height
# spends it on ELEVATION, so the boundary of the set becomes a cliff and the room
# reads the Mandelbrot set as terrain. Spend the same number differently and the
# same computation is a different claim about what it computed.
#
# ONE WORD, SIX ARTIFACTS. `readout` and these three values are adopted verbatim
# from perlin_noise, simplex_noise, perlin_noise_terrain and random_edge_profile,
# which ask exactly this of a noise field. Same spelling, same order, same
# default. Where they turn a sampled float into height, colour or a bar, this
# turns an integer iteration count into the same three things — the claim is the
# same claim, so the fractal can be COMPARED against the noise sequence instead of
# merely walked past.
#
#   relief   the shipped landscape: one cube per c, lifted by its escape count,
#            a hollow skin over a black plain where the set itself never escapes.
#            Byte for byte the legacy build.  (DEFAULT)
#   plate    every cube dropped to y = 0. The identical 10,000 samples in the
#            identical order with the identical colours, spent entirely on hue:
#            the flat plate the whole tradition of Mandelbrot images actually is,
#            and the set reduced to a black island in it.
#   column   the escape count as a FILLED bar. Each sampled c becomes a stack of
#            cubes from the plane up to its own height, so what was a hollow skin
#            becomes solid mass and the plain where the set lives reads as a hole
#            punched through it. Sampled on every second row and column so the
#            bars stand apart rather than fusing into one block.
#
# STRICTLY ADDITIVE, AND THE FIELD IS NOT TOUCHED. _apply_readout() is appended
# to the END of _ready(), AFTER _generate_fractal() has run untouched, and it
# reads the MultiMesh that function produced. No value re-runs the iteration: the
# same c values are visited in the same order and get the same colours. Only what
# is done with the returned count changes. `relief` returns immediately.
const READOUTS: PackedStringArray = ["relief", "plate", "column"]
@export_enum("relief", "plate", "column") var readout: String = "relief"

## Stand an INVISIBLE box (layers = 0) around the sampled extent. It has to
## exist twice over: this artifact is built ENTIRELY from a MultiMeshInstance3D
## and the framing walk measures MeshInstance3D only, so with no anchor the
## camera is placed from a 1 m fallback box and looks past a 9.6 m fractal; and
## `plate` has no height at all while `relief` has 2 m of it, so a camera sized
## per variant would frame three different crops and the bite report would be a
## picture of the framing. Sized from resolution/point_size/height_scale, which
## no readout touches, so all three are framed identically.
## Default false — not one placement changes.
@export var capture_anchor: bool = false

## Untyped and NOT exported on purpose: sweep fixtures assign this directly
## pre-_ready as the string "true", and a typed bool silently rejects that.
##
## false (the default, and what every existing placement gets) = today exactly:
## _animate_fractal keeps breathing the whole instance +/- 5% on a 2 rad/s sine.
## true parks the pulse at 1.0. A sweep should pin it — two captures of the SAME
## readout taken a third of a second apart are two differently sized fractals,
## and the critic would report the shutter as an axis.
var freeze_pulse = false

## Instances the `column` value builds. Parented UNDER fractal_multimesh_instance
## so they inherit the pulse transform exactly as the shipped skin does.
var _column_instance: MultiMeshInstance3D = null

var time := 0.0

# MultiMesh for GPU instancing
var fractal_multimesh_instance: MultiMeshInstance3D
var fractal_multimesh: MultiMesh
var point_mesh: BoxMesh

# Material
var fractal_material: StandardMaterial3D

# Generation state for incremental updates
var is_generating := false
var generation_progress := 0.0

func _ready() -> void:
	_read_dna()
	_setup_mesh()
	_setup_material()
	_setup_multimesh()
	_generate_fractal()
	# APPENDED LAST, after the field has been sampled. Reads the MultiMesh
	# _generate_fractal() just filled and returns immediately at `relief`.
	_apply_readout()

func _setup_mesh() -> void:
	# Small cube for each point
	point_mesh = BoxMesh.new()
	point_mesh.size = Vector3(point_size, point_size, point_size)

func _setup_material() -> void:
	fractal_material = StandardMaterial3D.new()
	fractal_material.vertex_color_use_as_albedo = true
	fractal_material.emission_enabled = true
	fractal_material.emission_energy_multiplier = 0.4

func _setup_multimesh() -> void:
	fractal_multimesh = MultiMesh.new()
	fractal_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	fractal_multimesh.use_colors = true
	fractal_multimesh.mesh = point_mesh

	fractal_multimesh_instance = MultiMeshInstance3D.new()
	fractal_multimesh_instance.name = "MandelbrotMultiMesh"
	fractal_multimesh_instance.multimesh = fractal_multimesh
	fractal_multimesh_instance.material_override = fractal_material
	add_child(fractal_multimesh_instance)

func _process(delta: float) -> void:
	time += delta
	_animate_fractal()

func _generate_fractal() -> void:
	# Pre-calculate all points
	var point_data: Array[Dictionary] = []
	var scale_factor = 4.0 / zoom / resolution

	for y in range(resolution):
		for x in range(resolution):
			var real = center.x + (float(x) - resolution / 2.0) * scale_factor
			var imag = center.y + (float(y) - resolution / 2.0) * scale_factor

			var iterations = _mandelbrot_iterations(real, imag)
			var normalized_iter = float(iterations) / max_iterations

			# Calculate position
			var pos_x = (float(x) - resolution / 2.0) * point_size * 1.2
			var pos_z = (float(y) - resolution / 2.0) * point_size * 1.2
			var pos_y = 0.0

			if use_3d_height and iterations < max_iterations:
				# Use iteration count for height - creates a 3D landscape
				pos_y = normalized_iter * height_scale

			# Calculate color
			var point_color: Color
			if iterations >= max_iterations:
				point_color = Color.BLACK
			else:
				# Smooth coloring using continuous potential
				var hue = fmod(normalized_iter * 5.0, 1.0)
				point_color = Color.from_hsv(hue, 0.85, 1.0)

			point_data.append({
				"position": Vector3(pos_x, pos_y, pos_z),
				"color": point_color,
				"iterations": iterations
			})

	# Update MultiMesh in one batch
	var instance_count = point_data.size()
	fractal_multimesh.instance_count = instance_count

	for idx in range(instance_count):
		var data = point_data[idx]
		var transform = Transform3D(Basis(), data.position)
		fractal_multimesh.set_instance_transform(idx, transform)
		fractal_multimesh.set_instance_color(idx, data.color)

	print("Mandelbrot: Generated %d points" % instance_count)

func _mandelbrot_iterations(c_real: float, c_imag: float) -> int:
	var z_real := 0.0
	var z_imag := 0.0
	var iteration := 0

	while iteration < max_iterations:
		var z_real_sq = z_real * z_real
		var z_imag_sq = z_imag * z_imag

		if z_real_sq + z_imag_sq > 4.0:
			break

		var new_real = z_real_sq - z_imag_sq + c_real
		var new_imag = 2.0 * z_real * z_imag + c_imag
		z_real = new_real
		z_imag = new_imag
		iteration += 1

	return iteration

func _animate_fractal() -> void:
	if not fractal_multimesh_instance:
		return

	# Gentle pulsing animation
	var pulse = 1.0 + sin(time * 2.0) * 0.05
	if freeze_pulse:
		pulse = 1.0
	fractal_multimesh_instance.scale = Vector3.ONE * pulse

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		# Generate new view
		zoom = 1.0 + randf() * 500.0
		center = Vector2(randf() * 2.0 - 1.5, randf() * 2.0 - 1.0)
		_generate_fractal()
		print("Mandelbrot: New zoom=%.1f center=(%.3f, %.3f)" % [zoom, center.x, center.y])

# Public API
func set_zoom_level(new_zoom: float) -> void:
	zoom = new_zoom
	_generate_fractal()

func set_center_point(new_center: Vector2) -> void:
	center = new_center
	_generate_fractal()

func set_resolution_level(new_resolution: int) -> void:
	resolution = new_resolution
	_generate_fractal()

func zoom_to_point(point: Vector2, new_zoom: float) -> void:
	center = point
	zoom = new_zoom
	_generate_fractal()

# Interesting locations to explore
func goto_seahorse_valley() -> void:
	center = Vector2(-0.75, 0.1)
	zoom = 50.0
	_generate_fractal()

func goto_elephant_valley() -> void:
	center = Vector2(0.275, 0.0)
	zoom = 30.0
	_generate_fractal()

func goto_spiral() -> void:
	center = Vector2(-0.761574, -0.0847596)
	zoom = 200.0
	_generate_fractal()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	var was: String = readout
	_read_dna()
	if readout != was and fractal_multimesh != null:
		# Re-sample from scratch so `plate` is not applied twice to an already
		# flattened buffer. The iteration is deterministic, so this reproduces
		# the same field it produced in _ready.
		_generate_fractal()
		_apply_readout()


# ═══════════════════════════════════════════════════════════════════════════
# readout — everything below is new and nothing above it moved.
# ═══════════════════════════════════════════════════════════════════════════

## Map tokens arrive as config_<key> metadata. An unreadable word keeps the
## shipped landscape rather than blanking a fractal four rooms expect to see.
func _read_dna() -> void:
	if has_meta("config_readout"):
		var v: String = str(get_meta("config_readout")).strip_edges().to_lower()
		if READOUTS.has(v):
			readout = v
	if has_meta("config_capture_anchor"):
		capture_anchor = _truthy(get_meta("config_capture_anchor"))
	if has_meta("config_freeze_pulse"):
		freeze_pulse = _truthy(get_meta("config_freeze_pulse"))


func _truthy(value) -> bool:
	var s: String = str(value).strip_edges().to_lower()
	return s == "true" or s == "1" or s == "yes"


func _apply_readout() -> void:
	if _column_instance != null and is_instance_valid(_column_instance):
		_column_instance.queue_free()
		_column_instance = null
	fractal_multimesh_instance.layers = 1

	var key: String = str(readout).strip_edges().to_lower()
	if not READOUTS.has(key):
		key = "relief"

	match key:
		"plate":
			_flatten_to_plate()
		"column":
			_build_columns()
			fractal_multimesh_instance.layers = 0

	if capture_anchor:
		_add_capture_anchor()


## Drop every instance to the plane. The transforms are rewritten in place, so
## the instance count, the ordering and every colour are the ones the iteration
## produced — the only thing lost is the elevation the escape count was spent on.
func _flatten_to_plate() -> void:
	for idx in range(fractal_multimesh.instance_count):
		var xform: Transform3D = fractal_multimesh.get_instance_transform(idx)
		xform.origin.y = 0.0
		fractal_multimesh.set_instance_transform(idx, xform)


## The escape count as filled mass. Heights are READ BACK from the skin the
## iteration already built rather than recomputed, so this is the same field: a
## point standing at y = 1.4 in `relief` becomes a bar of cubes from 0 to 1.4.
##
## Every second row and column only. At full resolution the bars fuse into one
## slab and the picture is a black box; halving the sample grid in both axes
## leaves daylight between them and drops the instance count from a quarter of a
## million to a few thousand.
func _build_columns() -> void:
	var step: float = maxf(point_size, 0.01)
	var stride := 2
	var positions: Array[Vector3] = []
	var colors: Array[Color] = []

	for idx in range(fractal_multimesh.instance_count):
		# The generator walks y (outer) then x (inner), so index / resolution is
		# the row and index % resolution the column.
		var row: int = idx / resolution
		var col: int = idx % resolution
		if row % stride != 0 or col % stride != 0:
			continue
		var xform: Transform3D = fractal_multimesh.get_instance_transform(idx)
		var tint: Color = fractal_multimesh.get_instance_color(idx)
		var top: float = xform.origin.y
		var levels: int = int(top / step)
		# Always one cube, so the interior of the set (top = 0) still reads as a
		# floor rather than as a hole with nothing in it.
		for level in range(levels + 1):
			positions.append(Vector3(xform.origin.x, float(level) * step, xform.origin.z))
			colors.append(tint)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = point_mesh
	mm.instance_count = positions.size()
	for i in range(positions.size()):
		mm.set_instance_transform(i, Transform3D(Basis(), positions[i]))
		mm.set_instance_color(i, colors[i])

	_column_instance = MultiMeshInstance3D.new()
	_column_instance.name = "MandelbrotColumns"
	_column_instance.multimesh = mm
	_column_instance.material_override = fractal_material
	# Parented under the shipped instance so it inherits the breathing pulse.
	# layers is per-instance and NOT hierarchical, which is why muting the parent
	# above leaves this child drawing.
	fractal_multimesh_instance.add_child(_column_instance)


## An invisible box over the sampled extent. Sized from the sampling constants,
## never from the built points: a box measured from the scene would be 2 m tall
## for `relief` and paper-thin for `plate`, and the three shots would be framed
## differently — which is the failure this exists to prevent.
func _add_capture_anchor() -> void:
	if has_node("CaptureAnchor"):
		return
	var span: float = float(resolution) * point_size * 1.2
	var anchor := MeshInstance3D.new()
	anchor.name = "CaptureAnchor"
	var bm := BoxMesh.new()
	bm.size = Vector3(span, height_scale + point_size * 2.0, span)
	anchor.mesh = bm
	# Points run -span/2 .. +span/2 in X and Z, and 0 .. height_scale in Y.
	anchor.position = Vector3(0.0, (height_scale + point_size * 2.0) * 0.5 - point_size, 0.0)
	anchor.layers = 0
	add_child(anchor)
