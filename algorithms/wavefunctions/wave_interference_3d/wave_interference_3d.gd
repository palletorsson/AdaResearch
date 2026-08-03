# wave_interference_3d.gd
# Wave Interference 3D — two circular wave sources on a grid of spheres
# Each sphere's Y position = sum of two sine waves from the two sources.
# Color: blue (trough) → white (zero) → orange (peak).
#
# @identity
# essence: two simple waves create a complex pattern — superposition is the grammar of interference
# desire: adjust frequency, separation, amplitude and watch nodes rise and flatten as waves collide
# critical_parameter: evidence — how much of the interference arithmetic the grid puts on the
#   table. One ordered ladder, monotone in disclosure: result (the summed relief alone, the
#   legacy default) < trace (the same field read off as a profile curve on a chart plate) <
#   sources (the two families of expanding crest rings whose crossings ARE the fringes) <
#   longhand (both addend fields printed as flat plates above a rule, the relief below as the sum).
#   separation remains the physical parameter the sliders turn; evidence is what the instrument
#   is willing to show while it turns.
# triggers: _process animates every frame; sliders change frequency, separation, amplitude;
#   _ready reads #evidence: and builds the chosen apparatus; apply_grid_config({evidence}).
# emerges: bright ridges of constructive interference; still lines of destructive cancellation
# needs: RackTemplates panel with 3 sliders [has]; 16x16 sphere grid [has]; 2 source markers [has]
# relationships: builds on wave_interference (2D ring version); feeds diffraction, holography.
#   Carries the same `evidence` ladder as [[wave_interference_tank]] — its direct 2D sibling —
#   and parses a token through that artifact's one reader rather than keeping a second table.
# truth: Two waves meeting don't fight — they add. The pattern they make holds more information than either wave alone.

extends Node3D

class_name WaveInterference3D

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-03). This artifact had ZERO exports. The two
# addends live in _animate_grid() for exactly one line —
#
#     sin(k*d1 - w*t) + sin(k*d2 - w*t)
#
# — computed 256 times a frame, added, and thrown away. Only the sum was ever
# built into geometry, so the artifact could show that interference HAPPENED and
# never that it was addition that did it.
#
# The word and its four rungs are taken character for character from
# wave_interference_tank, this artifact's 2D sibling, which asks the same question
# of the same mathematics in a different body. Not a synonym, not a re-derivation:
# WaveInterferenceTank.evidence_name() is the family's single reader and this file
# calls it, so a spelling can never mean two different rungs in the two twins.
#
# Deliberately NOT the axis: GRID_SIZE, GRID_SPACING, SPHERE_RADIUS or the three
# palette colours. Every one of them is a dial on how big and how pretty, and a
# family swept across them is five photographs of the same claim.
#
# Deliberately NOT routed through evidence: the relief itself. All four rungs
# render the identical 16x16 grid with the identical trough→zero→peak colouring
# from the identical sum; the apparatus is added AROUND it. A variant that
# repainted the spheres would be changing the answer, not the showing.
# ─────────────────────────────────────────────────────────────────────────────

# ── Parameters ───────────────────────────────────────────────────────
const GRID_SIZE: int = 16
const GRID_SPACING: float = 0.018
const SPHERE_RADIUS: float = 0.003
const SOURCE_RADIUS: float = 0.008

const COLOR_TROUGH := Color(0.15, 0.3, 0.95)
const COLOR_ZERO := Color(0.9, 0.9, 0.9)
const COLOR_PEAK := Color(0.95, 0.55, 0.1)

## THE AXIS — how much of the interference arithmetic the grid puts on the table.
## One ordered ladder, monotone in disclosure:
##   result (legacy default) < trace < sources < longhand
## All four render the identical relief; they differ in what is built around it.
@export var evidence: String = "result"

# ── Apparatus built by the evidence axis. All null on the legacy default. ─────
const RING_SEGMENTS: int = 72     # crest-ring tessellation
const ADDEND_RES: int = 12        # lattice of one addend plate (the relief uses 16)
const PLATE_HALF: float = 0.06    # half-width of one addend plate (m)

var _evidence_root: Node3D        # every rung's geometry hangs here, and only here
var _trace_im: ImmediateMesh
var _rings_im: ImmediateMesh
var _addend_im: Array[ImmediateMesh] = []

# ── State ────────────────────────────────────────────────────────────
var _time: float = 0.0
var _frequency: float = 4.0       # 1 – 10
var _separation: float = 0.12     # distance between sources
var _amplitude: float = 0.015

var _grid_spheres: Array[MeshInstance3D] = []
var _grid_mats: Array[StandardMaterial3D] = []
var _source_a: MeshInstance3D
var _source_b: MeshInstance3D
var _grid_root: Node3D


func _ready() -> void:
	_read_meta_overrides()
	_build_grid()
	_build_sources()
	_build_panel()
	_build_evidence()


func _process(delta: float) -> void:
	_time += delta
	_animate_grid()
	_update_evidence()


# ═════════════════════════════════════════════════════════════════════
# GRID
# ═════════════════════════════════════════════════════════════════════

func _build_grid() -> void:
	_grid_root = Node3D.new()
	_grid_root.name = "GridRoot"
	_grid_root.position = Vector3(0.0, 0.35, 0.0)
	add_child(_grid_root)

	var base_mesh := SphereMesh.new()
	base_mesh.radius = SPHERE_RADIUS
	base_mesh.height = SPHERE_RADIUS * 2.0

	var half_extent: float = (GRID_SIZE - 1) * GRID_SPACING * 0.5

	for iz in GRID_SIZE:
		for ix in GRID_SIZE:
			var mi := MeshInstance3D.new()
			mi.mesh = base_mesh
			var mat := StandardMaterial3D.new()
			mat.albedo_color = COLOR_ZERO
			mat.emission_enabled = true
			mat.emission = COLOR_ZERO
			mat.emission_energy_multiplier = 0.4
			mi.material_override = mat

			mi.position = Vector3(
				ix * GRID_SPACING - half_extent,
				0.0,
				iz * GRID_SPACING - half_extent
			)
			_grid_root.add_child(mi)
			_grid_spheres.append(mi)
			_grid_mats.append(mat)


# ═════════════════════════════════════════════════════════════════════
# SOURCES
# ═════════════════════════════════════════════════════════════════════

func _build_sources() -> void:
	var src_mesh := SphereMesh.new()
	src_mesh.radius = SOURCE_RADIUS
	src_mesh.height = SOURCE_RADIUS * 2.0

	var src_mat := StandardMaterial3D.new()
	src_mat.albedo_color = Color(0.95, 0.2, 0.2)
	src_mat.emission_enabled = true
	src_mat.emission = Color(0.95, 0.2, 0.2)
	src_mat.emission_energy_multiplier = 0.8

	_source_a = MeshInstance3D.new()
	_source_a.mesh = src_mesh
	_source_a.material_override = src_mat
	_grid_root.add_child(_source_a)

	_source_b = MeshInstance3D.new()
	_source_b.mesh = src_mesh
	_source_b.material_override = src_mat.duplicate()
	_grid_root.add_child(_source_b)

	_update_source_positions()


func _update_source_positions() -> void:
	var half_sep: float = _separation * 0.5
	_source_a.position = Vector3(-half_sep, 0.0, 0.0)
	_source_b.position = Vector3(half_sep, 0.0, 0.0)


# ═════════════════════════════════════════════════════════════════════
# ANIMATION
# ═════════════════════════════════════════════════════════════════════

func _animate_grid() -> void:
	var k: float = _frequency * TAU  # wave number
	var w: float = _frequency * TAU * 0.5  # angular frequency (half speed for readability)
	var src_a_pos := _source_a.position
	var src_b_pos := _source_b.position

	for i in _grid_spheres.size():
		var mi: MeshInstance3D = _grid_spheres[i]
		var xz := Vector3(mi.position.x, 0.0, mi.position.z)

		var d1: float = xz.distance_to(Vector3(src_a_pos.x, 0.0, src_a_pos.z))
		var d2: float = xz.distance_to(Vector3(src_b_pos.x, 0.0, src_b_pos.z))

		var y: float = _amplitude * (sin(k * d1 - w * _time) + sin(k * d2 - w * _time))
		mi.position.y = y

		# Color: lerp trough → zero → peak
		var norm_y: float = clampf(y / (_amplitude * 2.0), -1.0, 1.0)
		var color: Color
		if norm_y < 0.0:
			color = COLOR_TROUGH.lerp(COLOR_ZERO, norm_y + 1.0)
		else:
			color = COLOR_ZERO.lerp(COLOR_PEAK, norm_y)

		var mat: StandardMaterial3D = _grid_mats[i]
		mat.albedo_color = color
		mat.emission = color


# ═════════════════════════════════════════════════════════════════════
# PANEL
# ═════════════════════════════════════════════════════════════════════

func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("WAVE INTERFERENCE", [
		[{"type": "slider_h", "label": "FREQ", "default": (_frequency - 1.0) / 9.0}],
		[{"type": "slider_h", "label": "SEPARATION", "default": (_separation - 0.04) / 0.26}],
		[{"type": "slider_h", "label": "AMPLITUDE", "default": 0.5}],
	])
	panel.position = Vector3(0, 0.08, 0.18)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	for i in 3:
		var slider: Node = panel.find_child("Param_%d" % i, true, false)
		if slider and slider.has_signal("slider_moved"):
			slider.slider_moved.connect(_on_slider_changed)


func _on_slider_changed(_value: float) -> void:
	var panel_node: Node = get_node_or_null("WAVE_INTERFERENCE")
	if not panel_node:
		return

	for i in 3:
		var slider: Node = panel_node.find_child("Param_%d" % i, true, false)
		if slider and slider.has_method("get_normalized_value"):
			var norm: float = slider.get_normalized_value()
			match i:
				0: _frequency = 1.0 + norm * 9.0        # 1 – 10
				1:
					_separation = 0.04 + norm * 0.26     # 0.04 – 0.30
					_update_source_positions()
				2: _amplitude = 0.005 + norm * 0.025     # 0.005 – 0.030


# ═════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═════════════════════════════════════════════════════════════════════

## LATENT BUG, FIXED HERE. This method existed as `pass`: the artifact advertised a
## configuration hook and silently discarded every key handed to it. It now stores
## the config as metadata in the family's shape and re-reads.
func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	var was: String = evidence
	_read_meta_overrides()
	# Config can arrive either side of _ready — GridInteractablesComponent defers
	# this call, the sweep sets the export before add_child. Rebuild ONLY when the
	# word actually changed AND _ready has already built once (otherwise _ready
	# picks up the new value on its own pass and _grid_root does not exist yet), so
	# a shipped placement carrying no #evidence: token is never touched.
	if is_node_ready() and evidence != was:
		_teardown_evidence()
		_build_evidence()


func _read_meta_overrides() -> void:
	if has_meta("config_evidence"):
		# The family's one reader — see wave_interference_tank.gd. Aliases such as
		# `pattern`, `fronts` and `terms` resolve to the same rungs in both twins
		# because there is exactly one table, and it is not in this file.
		evidence = WaveInterferenceTank.evidence_name(str(get_meta("config_evidence")))


# ═════════════════════════════════════════════════════════════════════
# EVIDENCE — the ladder of disclosure
#
#   result  <  trace  <  sources  <  longhand
#
# _build_evidence() makes the apparatus once; _update_evidence() refills it from
# the frame's own numbers. Both dispatch on the same four rungs so the ladder is
# readable from the code in one place, which is what the DNA declaration derives
# from. `result` has an explicit, empty case rather than living in the `_:`
# fallthrough: the legacy lineage is a deliberate rung of this family, not the
# leftovers.
# ═════════════════════════════════════════════════════════════════════

func _build_evidence() -> void:
	match evidence:
		"result":
			pass                       # the summed relief alone — the shipped build, untouched
		"trace":
			_build_trace()
		"sources":
			_build_rings()
		"longhand":
			_build_addends()
		_:
			pass                       # an unrecognised word is the bare outcome


## Drop every rung's geometry so a changed token can build a different one. Only
## reachable through apply_grid_config; on the default path this never runs.
func _teardown_evidence() -> void:
	if is_instance_valid(_evidence_root):
		_evidence_root.queue_free()
	_evidence_root = null
	_trace_im = null
	_rings_im = null
	_addend_im.clear()


## Everything a rung builds hangs off the Evidence node, never off the grid —
## which is what makes teardown one line. Created lazily, so `result` adds no node
## at all and the legacy tree is what it always was.
func _ev_add(n: Node) -> void:
	if _evidence_root == null:
		_evidence_root = Node3D.new()
		_evidence_root.name = "Evidence"
		_grid_root.add_child(_evidence_root)
	_evidence_root.add_child(n)


func _ev_material(unshaded: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _ev_mesh(unshaded: bool) -> ImmediateMesh:
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = _ev_material(unshaded)
	_ev_add(mi)
	return im


## Trough → zero → peak, exactly the ramp _animate_grid uses on the spheres.
func _wave_color(norm_y: float) -> Color:
	var t: float = clampf(norm_y, -1.0, 1.0)
	if t < 0.0:
		return COLOR_TROUGH.lerp(COLOR_ZERO, t + 1.0)
	return COLOR_ZERO.lerp(COLOR_PEAK, t)


func _half_extent() -> float:
	return (GRID_SIZE - 1) * GRID_SPACING * 0.5


# ── RUNG 1 — TRACE ───────────────────────────────────────────────────
# The same field, read off. A chart plate stands behind the grid and carries the
# height of the centre row as a curve, so the fringe spacing stops being a thing
# you infer from a relief seen at an angle and becomes a line with peaks you can
# count. Nothing is simulated twice: the samples are read back off the spheres
# the relief already placed.

func _build_trace() -> void:
	var half: float = _half_extent()

	var plate := MeshInstance3D.new()
	plate.name = "TracePlate"
	var box := BoxMesh.new()
	box.size = Vector3(half * 2.0 + 0.02, 0.10, 0.002)
	plate.mesh = box
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.06, 0.07, 0.10)
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	plate.material_override = pm
	plate.position = Vector3(0.0, 0.05, -half - 0.03)
	_ev_add(plate)

	_trace_im = _ev_mesh(true)
	_draw_trace()


func _draw_trace() -> void:
	if _trace_im == null:
		return
	_trace_im.clear_surfaces()

	var half: float = _half_extent()
	var row: int = GRID_SIZE / 2
	var gain: float = 0.045 / maxf(_amplitude * 2.0, 0.0005)
	var z_front: float = -half - 0.028

	var curve: Array[Vector3] = []
	for ix in GRID_SIZE:
		var mi: MeshInstance3D = _grid_spheres[row * GRID_SIZE + ix]
		curve.append(Vector3(mi.position.x, 0.05 + mi.position.y * gain, z_front))

	# The zero line the curve is a departure FROM — without it a curve is a shape,
	# with it the crossings are the nodes.
	var zero: Array[Vector3] = [
		Vector3(-half, 0.05, z_front), Vector3(half, 0.05, z_front)]

	_trace_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_ribbon(_trace_im, zero, Color(0.45, 0.47, 0.55), 0.0008, Vector3(0.0, 0.0, 1.0))
	_ribbon(_trace_im, curve, COLOR_PEAK, 0.0018, Vector3(0.0, 0.0, 1.0))
	_trace_im.surface_end()


## A polyline drawn as a flat ribbon inside a chosen plane. A 1 px LINE_STRIP is
## invisible at any sane capture framing, which is how an axis that genuinely moves
## gets reported inert; every rung here draws bands instead.
func _ribbon(im: ImmediateMesh, pts: Array[Vector3], col: Color, half_thick: float,
		plane_normal: Vector3) -> void:
	if pts.size() < 2:
		return
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var d: Vector3 = b - a
		if d.length() < 0.000001:
			continue
		var n: Vector3 = d.cross(plane_normal).normalized() * half_thick
		var quad: Array[Vector3] = [a + n, b + n, b - n, a + n, b - n, a - n]
		for p in quad:
			im.surface_set_color(col)
			im.surface_add_vertex(p)


# ── RUNG 2 — SOURCES ─────────────────────────────────────────────────
# The two addends as what they physically are: two families of crest rings walking
# outward at the same speed. Where a blue ring crosses an orange one, the relief
# behind them has a peak. This is the rung that says the fringes are not a pattern
# the grid HAS but a place where two things arrived together.

func _build_rings() -> void:
	_rings_im = _ev_mesh(true)
	_draw_rings()


func _draw_rings() -> void:
	if _rings_im == null:
		return
	_rings_im.clear_surfaces()

	var k: float = _frequency * TAU
	var w: float = _frequency * TAU * 0.5
	var lambda: float = TAU / maxf(k, 0.0001)
	var phase: float = fmod(w * _time, TAU) / maxf(k, 0.0001)
	var max_r: float = _half_extent() * 1.55
	var y_plane: float = -_amplitude * 1.4

	_rings_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_ring_family(_source_a.position, COLOR_TROUGH, lambda, phase, max_r, y_plane)
	_ring_family(_source_b.position, COLOR_PEAK, lambda, phase, max_r, y_plane)
	_rings_im.surface_end()


func _ring_family(origin: Vector3, tint: Color, lambda: float, phase: float,
		max_r: float, y_plane: float) -> void:
	# A collar at the source itself, always drawn. At low frequency the wavelength
	# is wider than the grid and NOT ONE crest ring falls inside it — without this
	# the surface would be closed empty, which Godot refuses, and the rung would
	# render as nothing on exactly the settings where it has the most to say.
	_ring_outline(origin, tint, SOURCE_RADIUS * 1.8, y_plane, 0.0018)

	var n: int = 0
	while n < 24:
		var r: float = phase + float(n) * lambda
		n += 1
		if r <= 0.001:
			continue
		if r > max_r:
			break
		# Older crests are further out and fainter — a ring is a record of a
		# moment, and the moment is receding.
		var fade: float = clampf(1.0 - r / max_r, 0.15, 1.0)
		var c: Color = Color(tint.r * fade, tint.g * fade, tint.b * fade, 1.0)
		_ring_outline(origin, c, r, y_plane, 0.0015)


func _ring_outline(origin: Vector3, col: Color, r: float, y_plane: float,
		half_thick: float) -> void:
	var loop: Array[Vector3] = []
	for s in RING_SEGMENTS + 1:
		var a0: float = TAU * float(s) / float(RING_SEGMENTS)
		loop.append(Vector3(origin.x + cos(a0) * r, y_plane, origin.z + sin(a0) * r))
	_ribbon(_rings_im, loop, col, half_thick, Vector3(0.0, 1.0, 0.0))


# ── RUNG 3 — LONGHAND ────────────────────────────────────────────────
# The sum written out: plate A, a "+", plate B, a rule, and the relief beyond it
# as the answer. The addends are FLAT colour plates rather than little reliefs,
# and that is a deliberate choice against the obvious one — a relief reads
# differently from every angle, and a rung only legible from the front is a rung
# the evidence loop will photograph three times as nothing. They lie in the SAME
# plane as the relief, so a cell of plate A sits over the same ground as the
# sphere whose height it is one half of.
#
# Placed BEHIND the relief in −Z rather than directly over it. Stacking them
# overhead was the first arrangement and it hid the answer from every elevated
# camera — the occlusion failure the bite reports keep catching as a pair of
# variants measuring 0.00% apart. Both plates stay inside the grid's own 0.27 m
# width, so the variant cannot collide with a neighbour in a map; what it costs
# is depth, not footprint width.
const PLATE_Z: float = -0.215     # behind the relief's far edge at z = −0.135
const PLATE_Y: float = 0.06

func _build_addends() -> void:
	var half: float = _half_extent()

	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.85, 0.86, 0.9)
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var rule := MeshInstance3D.new()
	rule.name = "Rule"
	var bar := BoxMesh.new()
	bar.size = Vector3(half * 2.0, 0.0025, 0.0025)
	rule.mesh = bar
	rule.material_override = rm
	rule.position = Vector3(0.0, PLATE_Y * 0.45, PLATE_Z + PLATE_HALF + 0.02)
	_ev_add(rule)

	for arm in 2:
		var seg := MeshInstance3D.new()
		seg.name = "Plus%d" % arm
		var sb := BoxMesh.new()
		if arm == 0:
			sb.size = Vector3(0.018, 0.0025, 0.0025)
		else:
			sb.size = Vector3(0.0025, 0.0025, 0.018)
		seg.mesh = sb
		seg.material_override = rm
		seg.position = Vector3(0.0, PLATE_Y, PLATE_Z)
		_ev_add(seg)

	_addend_im.clear()
	for _i in 2:
		var im: ImmediateMesh = _ev_mesh(true)
		_addend_im.append(im)
	_draw_addends()


func _draw_addends() -> void:
	if _addend_im.size() < 2:
		return

	var k: float = _frequency * TAU
	var w: float = _frequency * TAU * 0.5
	var cell: float = (PLATE_HALF * 2.0) / float(ADDEND_RES)
	var centres: Array[float] = [-PLATE_HALF - 0.015, PLATE_HALF + 0.015]
	var srcs: Array[Vector3] = [_source_a.position, _source_b.position]

	for side in 2:
		var im: ImmediateMesh = _addend_im[side]
		im.clear_surfaces()
		var cx: float = centres[side]
		var src: Vector3 = srcs[side]
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for iz in ADDEND_RES:
			for ix in ADDEND_RES:
				# Plate coordinates map back onto the SAME footprint the relief
				# covers, so a cell of plate A sits over the same ground as the
				# sphere whose height it is one half of.
				var u: float = (float(ix) + 0.5) / float(ADDEND_RES) - 0.5
				var v: float = (float(iz) + 0.5) / float(ADDEND_RES) - 0.5
				var world := Vector3(u * _half_extent() * 2.0, 0.0, v * _half_extent() * 2.0)
				var d: float = world.distance_to(Vector3(src.x, 0.0, src.z))
				var term: float = sin(k * d - w * _time)
				var col: Color = _wave_color(term)

				var x0: float = cx + (float(ix) / float(ADDEND_RES) - 0.5) * PLATE_HALF * 2.0
				var x1: float = x0 + cell
				var z0: float = PLATE_Z + (float(iz) / float(ADDEND_RES) - 0.5) * PLATE_HALF * 2.0
				var z1: float = z0 + cell
				var y: float = PLATE_Y

				var p00 := Vector3(x0, y, z0)
				var p10 := Vector3(x1, y, z0)
				var p11 := Vector3(x1, y, z1)
				var p01 := Vector3(x0, y, z1)
				var quad: Array[Vector3] = [p00, p10, p11, p00, p11, p01]
				for p in quad:
					im.surface_set_color(col)
					im.surface_add_vertex(p)
		im.surface_end()


func _update_evidence() -> void:
	match evidence:
		"result":
			pass
		"trace":
			_draw_trace()
		"sources":
			_draw_rings()
		"longhand":
			_draw_addends()
		_:
			pass
