# wave_interference_tank.gd
# Two-source wave interference demonstration
# Shows constructive/destructive interference patterns
#
# QFEP: Interference as superposition — waves don't "fight", they add
# Patterns emerge from phase relationships

extends Node3D

class_name WaveInterferenceTank

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

## Implements two-source wave interference to visualize constructive and destructive patterns.
## Computes wave height at each grid point as the superposition of two circular waves
## (A·sin(kr−ωt)), colored by amplitude. VR sliders control frequency and source separation.

# @identity
# essence: a ripple tank with two coherent sources, and a decision about how much of its own
#   arithmetic it is willing to show. The water is always the same water: A·sin(kr₁−ωt) summed
#   with A·sin(kr₂−ωt+Δφ) across a 64×64 grid, coloured trough-to-peak. What changes is whether
#   you are handed the finished pattern, the pattern read off as a profile curve, the two
#   spreading fronts that built it, or the whole sum written out in longhand with both addends
#   above the rule.
# desire: to stop being a picture of interference and become an operation you can watch someone
#   perform — because a pattern shown without its terms teaches that interference is a thing
#   waves HAVE, when it is a thing addition DOES.
# critical_parameter: evidence — how much of the interference arithmetic the tank puts on the
#   table. One ordered ladder, monotone in disclosure: result (the summed field alone, the
#   legacy default) < trace (the same field read off as a profile curve on a chart plate) <
#   sources (the two families of expanding crest rings whose crossings ARE the fringes) <
#   longhand (both addend fields printed as plates above a rule, the tank below as the sum).
# triggers: _ready reads #evidence: and builds the chosen apparatus; _process refills it from
#   the same height data the water already uses; apply_grid_config({evidence}).
# emerges: at `result` the tank is a demonstration you believe; at `longhand` it is a claim you
#   can check, because both operands are visible and you can see for yourself that the bright
#   band is where two crests landed together. The ladder is the difference between being shown
#   and being told how.
# needs: nothing new — every rung is drawn from _heights and the same k, ω, r₁, r₂ and Δφ the
#   simulation already computes. The mathematics is curriculum and is untouched by all four.
# relationships: kin to [[sine_wave_controller]], which carries the same `evidence` ladder for a
#   single sine — the pair asks one question in two bodies. Sits in the wavefunctions sequence.
# truth: superposition is an operation, not an appearance — and an instrument that only ever
#   shows you the answer is teaching the appearance.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27). This artifact had ten exports and every one
# of them was a dial on the PHYSICS: frequency, amplitude, speed, separation,
# phase, tank size, three colours. Not one of them was about the demonstration.
# You could make the water faster, bluer, deeper or wider, and in every case you
# got the identical epistemic object: a finished pattern, presented as a fact.
#
# For a machine, that is the wrong family. The register of a ripple tank barely
# matters — nobody asks which institution a ripple tank belongs to. What matters
# is what it makes legible and what it keeps in the box, and this one kept
# everything in the box: the two component waves exist in _update_wave_surface()
# for exactly one line each (wave1, wave2) before being added together and thrown
# away. The addends are computed 4096 times a frame and never shown once.
#
# So the axis is EVIDENCE — how much of the arithmetic is on the table:
#
#   result  <  trace  <  sources  <  longhand
#
#   result    the summed field. An outcome, undifferentiated. THE LEGACY LINEAGE.
#   trace     the same field read off as a curve: the profile along z = 0 (the
#             line through both sources) drawn on a chart plate behind the tank.
#             The outcome, but with its shape committed to and measurable.
#   sources   two families of expanding crest rings, one colour per source, laid
#             over the water. Now you see that there are TWO PROCESSES arriving,
#             and that the bright fringes sit exactly where the two families
#             cross. The construction, not the picture.
#   longhand  both addends printed as plates above a rule, with a "+" between
#             them and the tank underneath as the sum. Long addition, in water.
#
# Every rung reads the SAME numbers the simulation already produces. `trace`
# samples the existing _heights array. `sources` solves the crest condition
# kr − ωt + φ = π/2 + 2πn for the very k, ω and φ in _update_wave_surface().
# `longhand` evaluates wave1 and wave2 with the same expression, on a coarser
# lattice. Nothing here changes the mathematics — R5: the physics is curriculum.
#
# Deliberately NOT the axis: a "speed" or "tempo" knob. wave_frequency and
# wave_speed were the tempting choices and both are per-second quantities that a
# still photograph cannot see except through wavelength, which is already an
# export. Promoting a rate would have produced a family of identical tiles.
#
# Deliberately NOT routed through evidence: the water itself. Every rung renders
# the same surface with the same colours; the apparatus is added AROUND it. A
# variant that repainted the tank would be changing the answer, not the showing.
# ─────────────────────────────────────────────────────────────────────────────

## Width and length of the square water tank (meters)
@export_range(0.2, 2.0, 0.1) var tank_size: float = 0.8
## Depth of the tank walls (meters)
@export_range(0.02, 0.3, 0.01) var tank_depth: float = 0.08

## Wave oscillation rate (Hz)
@export_range(0.5, 10.0, 0.1) var wave_frequency: float = 3.0:
	set(value):
		wave_frequency = clampf(value, 0.5, 10.0)
		_sync_freq_slider()

## Peak displacement of the wave surface (meters)
@export_range(0.001, 0.1, 0.001) var wave_amplitude: float = 0.02

## Propagation speed of waves across the tank (meters/second)
@export_range(0.05, 2.0, 0.05) var wave_speed: float = 0.3

## Distance between the two wave sources as a fraction of tank_size
@export_range(0.1, 0.8, 0.05) var source_separation: float = 0.4:
	set(value):
		source_separation = clampf(value, 0.1, 0.8)
		_update_source_positions()

## Phase offset between the two sources (0 to 2π radians)
@export_range(0.0, 6.283, 0.01) var phase_difference: float = 0.0:
	set(value):
		phase_difference = fmod(value, TAU)

## Color at wave peaks (maximum displacement)
@export var color_peak: Color = Color(0.2, 0.6, 1.0)
## Color at wave troughs (minimum displacement)
@export var color_trough: Color = Color(0.1, 0.1, 0.2)
## Color of the two source markers
@export var color_source: Color = Color(1.0, 0.4, 0.2)

## THE AXIS — how much of the interference arithmetic the tank puts on the table.
## One ordered ladder, monotone in disclosure:
##   result (legacy default) < trace < sources < longhand
## All four render the identical water; they differ in what is built around it.
@export var evidence: String = "result"

## Spellings that mean a rung already on the ladder. `terms` and `addends` are the
## words a mathematician reaches for; `longhand` is the word for the act of writing
## them down, and the act is what the rung actually builds. `pattern`, `field` and
## `none` all name the bare outcome, which is `result`.
const EVIDENCE_ALIASES := {
	"none": "result",
	"pattern": "result",
	"field": "result",
	"profile": "trace",
	"section": "trace",
	"fronts": "sources",
	"terms": "longhand",
	"addends": "longhand",
}

## The pair's one reader for an evidence token. Static so [[sine_wave_controller]]
## parses #evidence: through this exact function rather than keeping a second table
## that could drift — the two artifacts are one family on this axis and there must
## be exactly one place a word is turned into a rung.
static func evidence_name(raw: String) -> String:
	var word: String = raw.strip_edges().to_lower()
	return str(EVIDENCE_ALIASES.get(word, word))

# State
var _time: float = 0.0

# Visuals
var _tank_base: MeshInstance3D
var _tank_walls: Node3D
var _surface_mesh: MeshInstance3D
var _source_1: MeshInstance3D
var _source_2: MeshInstance3D
var _source_1_pos: Vector3
var _source_2_pos: Vector3
var _info_label: Label3D
var _control_panel: Node3D
var _freq_slider: Node
var _sep_slider: Node

# Cached per-frame objects (avoid GC pressure)
var _im: ImmediateMesh
var _surface_mat: StandardMaterial3D

# Grid for wave surface
var _grid_resolution: int = 64
var _heights: Array[float] = []

# Track created nodes for cleanup
var _created_nodes: Array[Node] = []

# Apparatus built by the evidence axis. All null on the legacy default.
const RING_SEGMENTS: int = 72      # crest-ring tessellation
const ADDEND_RES: int = 28         # lattice of one addend plate (the tank uses 64)
var _evidence_root: Node3D         # every rung's geometry hangs here, and only here
var _trace_mi: MeshInstance3D
var _trace_im: ImmediateMesh
var _rings_mi: MeshInstance3D
var _rings_im: ImmediateMesh
var _addend_im: Array[ImmediateMesh] = []

var RackTpl = load("res://commons/audio/rack_templates/RackTemplates.gd")

func _ready() -> void:
	_read_meta_overrides()
	_create_tank()
	_create_sources()
	_create_surface()
	_create_labels()
	_create_vr_controls()
	_update_source_positions()
	_build_evidence()

## LATENT BUG, FIXED HERE (was wave_interference_tank.gd:397). This method existed
## as `pass`: the artifact advertised a configuration hook and silently discarded
## every key handed to it. That is the unreachable-critical_parameter class the
## project keeps a whole checker for. It now stores the config as metadata in the
## family's shape and re-reads. Off the default path either way — a scan of all
## map_data.json files finds zero placements carrying any config on this token.
func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	var was: String = evidence
	_read_meta_overrides()
	# Config can arrive AFTER _ready — GridInteractablesComponent defers this call,
	# and capture_artifact_config.gd makes it post-add_child. Without the rebuild
	# the token would only ever set a variable nobody reads again, which is the
	# silent-fallback failure the whole DNA loop was built to catch. The sweeper
	# (capture_config_sweep.gd) sets the export BEFORE add_child and takes the
	# _ready path instead; both roads now arrive.
	if is_inside_tree() and evidence != was:
		_teardown_evidence()
		_build_evidence()

func _read_meta_overrides() -> void:
	if has_meta("config_evidence"):
		evidence = evidence_name(str(get_meta("config_evidence")))

## Builds the tank base and transparent glass walls.
func _create_tank() -> void:
	# Tank base (dark)
	_tank_base = MeshInstance3D.new()
	_tank_base.name = "TankBase"
	var box = BoxMesh.new()
	box.size = Vector3(tank_size, 0.02, tank_size)
	_tank_base.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.08)
	_tank_base.material_override = mat
	_tank_base.position = Vector3(0, -tank_depth, 0)
	add_child(_tank_base)
	_created_nodes.append(_tank_base)

	# Glass walls
	_tank_walls = Node3D.new()
	_tank_walls.name = "TankWalls"
	add_child(_tank_walls)
	_created_nodes.append(_tank_walls)

	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.7, 0.85, 1.0, 0.2)
	wall_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var wall_positions = [
		Vector3(0, -tank_depth / 2, tank_size / 2),
		Vector3(0, -tank_depth / 2, -tank_size / 2),
		Vector3(tank_size / 2, -tank_depth / 2, 0),
		Vector3(-tank_size / 2, -tank_depth / 2, 0)
	]
	var wall_rotations_deg = [0.0, 0.0, 90.0, 90.0]

	# MultiMesh for all 4 walls (single draw call)
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(tank_size, tank_depth, 0.005)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = wall_mesh
	mm.instance_count = 4

	for i in range(4):
		var xf := Transform3D()
		if i >= 2:
			xf = xf.rotated(Vector3.UP, deg_to_rad(wall_rotations_deg[i]))
		xf.origin = wall_positions[i]
		mm.set_instance_transform(i, xf)

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "TankWallsMM"
	mmi.multimesh = mm
	mmi.material_override = wall_mat
	_tank_walls.add_child(mmi)

## Creates the two wave source markers.
func _create_sources() -> void:
	_source_1 = _create_source_marker("Source1")
	add_child(_source_1)
	_created_nodes.append(_source_1)

	_source_2 = _create_source_marker("Source2")
	add_child(_source_2)
	_created_nodes.append(_source_2)

## Returns a glowing sphere MeshInstance3D to mark a wave source.
func _create_source_marker(source_name: String) -> MeshInstance3D:
	var source = MeshInstance3D.new()
	source.name = source_name
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	source.mesh = sphere

	var smat = StandardMaterial3D.new()
	smat.albedo_color = color_source
	smat.emission_enabled = true
	smat.emission = color_source
	smat.emission_energy_multiplier = 0.5
	source.material_override = smat

	return source

## Repositions source markers based on current source_separation.
func _update_source_positions() -> void:
	var half_sep = source_separation * tank_size / 2.0
	_source_1_pos = Vector3(-half_sep, 0, 0)
	_source_2_pos = Vector3(half_sep, 0, 0)

	if _source_1:
		_source_1.position = _source_1_pos
	if _source_2:
		_source_2.position = _source_2_pos

## Creates the wave surface mesh node and initializes the height grid.
func _create_surface() -> void:
	_surface_mesh = MeshInstance3D.new()
	_surface_mesh.name = "WaveSurface"
	add_child(_surface_mesh)
	_created_nodes.append(_surface_mesh)

	# Pre-allocate ImmediateMesh and material (reused every frame)
	_im = ImmediateMesh.new()
	_surface_mesh.mesh = _im

	_surface_mat = StandardMaterial3D.new()
	_surface_mat.vertex_color_use_as_albedo = true
	_surface_mat.emission_enabled = true
	_surface_mat.emission_energy_multiplier = 0.3
	_surface_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_surface_mesh.material_override = _surface_mat

	# Initialize height array
	_heights.resize(_grid_resolution * _grid_resolution)
	for i in range(_heights.size()):
		_heights[i] = 0.0

## Creates the floating info label.
func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 16
	_info_label.position = Vector3(0, 0.15, 0)
	_info_label.text = "WAVE INTERFERENCE"
	add_child(_info_label)
	_created_nodes.append(_info_label)

## Builds the VR control panel with frequency/separation sliders and phase preset buttons.
func _create_vr_controls() -> void:
	_control_panel = RackTpl.create_panel("INTERFERENCE", [
		[{"type": "slider_h", "label": "FREQ", "default": (wave_frequency - 0.5) / 9.5},
		 {"type": "slider_h", "label": "SEP", "default": (source_separation - 0.1) / 0.7}],
		[{"type": "button", "label": "IN PHASE"},
		 {"type": "button", "label": "OPPOSITE"},
		 {"type": "button", "label": "QUARTER"},
		 {"type": "button", "label": "EIGHTH"}],
	])
	_control_panel.position = Vector3(0, 0.02, tank_size / 2 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	_created_nodes.append(_control_panel)

	_freq_slider = _control_panel.find_child("Param_0", true, false)
	if _freq_slider and _freq_slider.has_signal("slider_moved"):
		_freq_slider.slider_moved.connect(_on_freq_changed)

	_sep_slider = _control_panel.find_child("Param_1", true, false)
	if _sep_slider and _sep_slider.has_signal("slider_moved"):
		_sep_slider.slider_moved.connect(_on_sep_changed)

	var phase_values = [0.0, PI, PI / 2, PI / 4]
	for i in range(4):
		var btn = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var phase = phase_values[i]
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(func(_b): phase_difference = phase)

	call_deferred("_sync_sliders")

## Syncs both slider positions to current parameter values.
func _sync_sliders() -> void:
	_sync_freq_slider()
	_sync_sep_slider()

## Updates the frequency slider thumb to match wave_frequency.
func _sync_freq_slider() -> void:
	if _freq_slider and _freq_slider.has_method("set_normalized_value"):
		_freq_slider.set_normalized_value((wave_frequency - 0.5) / 9.5)

## Updates the separation slider thumb to match source_separation.
func _sync_sep_slider() -> void:
	if _sep_slider and _sep_slider.has_method("set_normalized_value"):
		_sep_slider.set_normalized_value((source_separation - 0.1) / 0.7)

## Called when the frequency slider is moved by the player.
func _on_freq_changed(_pos) -> void:
	if _freq_slider and _freq_slider.has_method("get_normalized_value"):
		wave_frequency = 0.5 + _freq_slider.get_normalized_value() * 9.5

## Called when the separation slider is moved by the player.
func _on_sep_changed(_pos) -> void:
	if _sep_slider and _sep_slider.has_method("get_normalized_value"):
		source_separation = 0.1 + _sep_slider.get_normalized_value() * 0.7

func _process(delta: float) -> void:
	_time += delta
	_update_wave_surface()
	_update_info()
	_update_evidence()

## Computes wave heights on the grid via two-source superposition.
func _update_wave_surface() -> void:
	var half_size = tank_size / 2.0
	var cell_size = tank_size / float(_grid_resolution)
	var wavelength = wave_speed / maxf(wave_frequency, 0.0001)
	var k = TAU / maxf(wavelength, 0.0001)
	var omega = TAU * wave_frequency

	for j in range(_grid_resolution):
		for i in range(_grid_resolution):
			var x = -half_size + (i + 0.5) * cell_size
			var z = -half_size + (j + 0.5) * cell_size
			var pos = Vector3(x, 0, z)

			# Distance from each source
			var r1 = pos.distance_to(_source_1_pos)
			var r2 = pos.distance_to(_source_2_pos)

			# Wave from source 1: A * sin(kr1 - ωt)
			# Wave from source 2: A * sin(kr2 - ωt + φ)
			var wave1 = wave_amplitude * sin(k * r1 - omega * _time)
			var wave2 = wave_amplitude * sin(k * r2 - omega * _time + phase_difference)

			# Superposition
			var total = wave1 + wave2

			# Damping near edges
			var edge_dist = minf(minf(half_size - absf(x), half_size - absf(z)), half_size)
			var edge_factor = clampf(edge_dist / 0.1, 0.0, 1.0)
			total *= edge_factor

			_heights[j * _grid_resolution + i] = total

	_build_surface_mesh()

## Rebuilds the ImmediateMesh triangle surface from current height data.
func _build_surface_mesh() -> void:
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_size = tank_size / 2.0
	var cell_size = tank_size / float(_grid_resolution)

	for j in range(_grid_resolution - 1):
		for i in range(_grid_resolution - 1):
			var x0 = -half_size + i * cell_size
			var x1 = -half_size + (i + 1) * cell_size
			var z0 = -half_size + j * cell_size
			var z1 = -half_size + (j + 1) * cell_size

			var h00 = _heights[j * _grid_resolution + i]
			var h10 = _heights[j * _grid_resolution + i + 1]
			var h01 = _heights[(j + 1) * _grid_resolution + i]
			var h11 = _heights[(j + 1) * _grid_resolution + i + 1]

			var v00 = Vector3(x0, h00, z0)
			var v10 = Vector3(x1, h10, z0)
			var v01 = Vector3(x0, h01, z1)
			var v11 = Vector3(x1, h11, z1)

			# Colors based on height
			var c00 = _height_to_color(h00)
			var c10 = _height_to_color(h10)
			var c01 = _height_to_color(h01)
			var c11 = _height_to_color(h11)

			# Triangle 1
			_im.surface_set_color(c00)
			_im.surface_add_vertex(v00)
			_im.surface_set_color(c10)
			_im.surface_add_vertex(v10)
			_im.surface_set_color(c11)
			_im.surface_add_vertex(v11)

			# Triangle 2
			_im.surface_set_color(c00)
			_im.surface_add_vertex(v00)
			_im.surface_set_color(c11)
			_im.surface_add_vertex(v11)
			_im.surface_set_color(c01)
			_im.surface_add_vertex(v01)

	_im.surface_end()

## Maps a height value to a color between trough and peak.
func _height_to_color(h: float) -> Color:
	var t = clampf((h / maxf(wave_amplitude, 0.0001) + 1.0) / 2.0, 0.0, 1.0)
	return color_trough.lerp(color_peak, t)

## Updates the info label with current wavelength and phase.
func _update_info() -> void:
	var wavelength = wave_speed / maxf(wave_frequency, 0.0001)
	var phase_deg = rad_to_deg(phase_difference)
	_info_label.text = "WAVE INTERFERENCE\nλ = %.2f  Δφ = %.0f°" % [wavelength, phase_deg]

# ── evidence: the ladder of disclosure ───────────────────────────────────────
#
#   result  <  trace  <  sources  <  longhand
#
# _build_evidence() makes the apparatus once; _update_evidence() refills it from
# the frame's own numbers. Both dispatch on the same four rungs so the ladder is
# readable from the code in one place, which is what the DNA declaration derives
# from. `result` has an explicit, empty case rather than living in the `_:`
# fallthrough: the legacy lineage is a deliberate rung of this family, not the
# leftovers, and the family's own value list should say so.

func _build_evidence() -> void:
	match evidence:
		"result":
			pass                              # the summed field alone — 1 placement, untouched
		"trace":
			_build_trace()
		"sources":
			_build_rings()
		"longhand":
			_build_addends()
		_:
			pass                              # an unrecognised word is the bare outcome

## Drop every rung's geometry so a changed token can build a different one. Only
## reachable through apply_grid_config; on the default path this never runs.
func _teardown_evidence() -> void:
	if is_instance_valid(_evidence_root):
		_created_nodes.erase(_evidence_root)
		_evidence_root.queue_free()
	_evidence_root = null
	_addend_im.clear()
	_trace_mi = null
	_trace_im = null
	_rings_mi = null
	_rings_im = null

## Everything a rung builds hangs off the Evidence node, never off the tank —
## which is what makes teardown one line and makes it impossible for a rebuild to
## take the water with it. Created lazily, so `result` adds no node at all and the
## legacy tree is byte-for-byte what it was.
func _ev_add(n: Node) -> void:
	if _evidence_root == null:
		_evidence_root = Node3D.new()
		_evidence_root.name = "Evidence"
		add_child(_evidence_root)
		_created_nodes.append(_evidence_root)
	_evidence_root.add_child(n)

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

# Two small material helpers. Kept local rather than pulled from a kit: this
# artifact has never had a preload beyond RackTemplates and the promotion should
# not import a look with it.
func _flat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.35
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m

# A vertex-coloured, unshaded, double-sided surface. Unshaded because these are
# readouts, not objects in the room's light; double-sided because a capture orbits
# and a one-sided chart is an inert axis from two of the four angles.
func _readout_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

# RUNG 1 — TRACE. A chart plate standing behind the tank carrying the water's own
# cross-section along z = 0, the line that runs through both sources and therefore
# through every fringe. The plate goes at the BACK on purpose: the front is the
# player's approach and already holds the control rack, and a chart taller than
# the tank still reads from all four capture angles when it stands behind it.
func _build_trace() -> void:
	var w: float = tank_size + 0.08
	var h: float = 0.40
	var z: float = -(tank_size * 0.5 + 0.05)

	var plate := MeshInstance3D.new()
	plate.name = "TracePlate"
	var pb := BoxMesh.new()
	pb.size = Vector3(w, h, 0.014)
	plate.mesh = pb
	plate.position = Vector3(0, h * 0.5, z)
	plate.material_override = _flat(Color(0.035, 0.045, 0.065), 0.9)
	_ev_add(plate)

	var rule := MeshInstance3D.new()
	rule.name = "TraceZero"
	var rb := BoxMesh.new()
	rb.size = Vector3(tank_size, 0.004, 0.004)
	rule.mesh = rb
	rule.position = Vector3(0, h * 0.5, z + 0.010)
	rule.material_override = _glow(Color(0.42, 0.50, 0.60), 0.5)
	_ev_add(rule)

	var cap: MeshInstance3D = BakedText.make_label_mesh(
			"PROFILE  z = 0", Color(0.60, 0.74, 0.88), Vector2(0.30, 0.045), 1400, true)
	if cap:
		cap.position = Vector3(-tank_size * 0.5 + 0.17, h - 0.05, z + 0.010)
		_ev_add(cap)

	_trace_mi = MeshInstance3D.new()
	_trace_mi.name = "TraceCurve"
	_trace_im = ImmediateMesh.new()
	_trace_mi.mesh = _trace_im
	_trace_mi.position = Vector3(0, h * 0.5, z + 0.012)
	_trace_mi.material_override = _readout_material()
	_ev_add(_trace_mi)

func _draw_trace() -> void:
	if _trace_im == null:
		return
	var n: int = _grid_resolution
	if _heights.size() < n * n:
		return
	var row: int = int(n / 2)
	var half: float = tank_size * 0.5
	var cell: float = tank_size / float(n)
	# ±2A (the largest a two-source sum can reach) maps to ±0.15 m of plate.
	var gain: float = 0.15 / maxf(wave_amplitude * 2.0, 0.0001)

	var xs: PackedFloat32Array = PackedFloat32Array()
	var ys: PackedFloat32Array = PackedFloat32Array()
	for i in range(n):
		xs.append(-half + (float(i) + 0.5) * cell)
		ys.append(clampf(_heights[row * n + i] * gain, -0.18, 0.18))

	_trace_im.clear_surfaces()
	_trace_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	# The area under the curve. This is what makes the rung BITE rather than being
	# a hairline nobody can see from three metres: a lit lobe per half-cycle.
	var fill: Color = Color(color_peak.r, color_peak.g, color_peak.b, 0.40)
	for i in range(n - 1):
		var ax: float = xs[i]
		var bx: float = xs[i + 1]
		var ay: float = ys[i]
		var by: float = ys[i + 1]
		_trace_im.surface_set_color(fill)
		_trace_im.surface_add_vertex(Vector3(ax, 0.0, 0.0))
		_trace_im.surface_set_color(fill)
		_trace_im.surface_add_vertex(Vector3(bx, 0.0, 0.0))
		_trace_im.surface_set_color(fill)
		_trace_im.surface_add_vertex(Vector3(bx, by, 0.0))
		_trace_im.surface_set_color(fill)
		_trace_im.surface_add_vertex(Vector3(ax, 0.0, 0.0))
		_trace_im.surface_set_color(fill)
		_trace_im.surface_add_vertex(Vector3(bx, by, 0.0))
		_trace_im.surface_set_color(fill)
		_trace_im.surface_add_vertex(Vector3(ax, ay, 0.0))
	# The curve itself, a ribbon offset along the segment normal so a steep
	# stretch stays as thick as a flat one.
	var lw: float = 0.012
	var line: Color = Color(0.62, 0.92, 1.0, 1.0)
	for i in range(n - 1):
		var a: Vector2 = Vector2(xs[i], ys[i])
		var b: Vector2 = Vector2(xs[i + 1], ys[i + 1])
		var d: Vector2 = b - a
		if d.length() < 0.000001:
			continue
		var nrm: Vector2 = Vector2(-d.y, d.x).normalized() * (lw * 0.5)
		var p0: Vector2 = a - nrm
		var p1: Vector2 = a + nrm
		var p2: Vector2 = b + nrm
		var p3: Vector2 = b - nrm
		_trace_im.surface_set_color(line)
		_trace_im.surface_add_vertex(Vector3(p0.x, p0.y, 0.002))
		_trace_im.surface_set_color(line)
		_trace_im.surface_add_vertex(Vector3(p1.x, p1.y, 0.002))
		_trace_im.surface_set_color(line)
		_trace_im.surface_add_vertex(Vector3(p2.x, p2.y, 0.002))
		_trace_im.surface_set_color(line)
		_trace_im.surface_add_vertex(Vector3(p0.x, p0.y, 0.002))
		_trace_im.surface_set_color(line)
		_trace_im.surface_add_vertex(Vector3(p2.x, p2.y, 0.002))
		_trace_im.surface_set_color(line)
		_trace_im.surface_add_vertex(Vector3(p3.x, p3.y, 0.002))
	_trace_im.surface_end()

# RUNG 2 — SOURCES. The construction rather than the picture: the crest circles of
# each source, drawn in that source's own colour, riding just clear of the water.
# Where an orange ring crosses a green one, two crests have arrived together, and
# that crossing is exactly where the summed field below is at its brightest. The
# fringe stops being a fact about the water and becomes a fact about two arrivals.
func _build_rings() -> void:
	_rings_mi = MeshInstance3D.new()
	_rings_mi.name = "CrestRings"
	_rings_im = ImmediateMesh.new()
	_rings_mi.mesh = _rings_im
	_rings_mi.position = Vector3(0, wave_amplitude * 2.4 + 0.012, 0)
	_rings_mi.material_override = _readout_material()
	_rings_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ev_add(_rings_mi)

func _draw_rings() -> void:
	if _rings_im == null:
		return
	# The crest condition of the SAME wave the surface is running:
	#   k·r − ω·t + φ = π/2 + 2πn   ⇒   r = λ(¼ + n) + v·t − φ·λ/2π
	var lam: float = maxf(wave_speed / maxf(wave_frequency, 0.0001), 0.012)
	var rmax: float = tank_size * 0.98
	var band: float = clampf(lam * 0.26, 0.009, 0.036)
	var base_1: float = fposmod(wave_speed * _time + lam * 0.25, lam)
	var base_2: float = fposmod(
			wave_speed * _time + lam * 0.25 - phase_difference * lam / TAU, lam)

	_rings_im.clear_surfaces()
	_rings_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_emit_crests(_source_1_pos, base_1, lam, rmax, band,
			Color(color_source.r, color_source.g, color_source.b, 0.95))
	_emit_crests(_source_2_pos, base_2, lam, rmax, band, Color(0.24, 0.96, 0.74, 0.95))
	_rings_im.surface_end()

# One family of crests. Segments whose corners fall outside the tank are dropped
# rather than clipped — a square hole in a round ring is the tank wall, and the
# rings should stop at the glass like real ripples do.
func _emit_crests(origin: Vector3, base: float, lam: float, rmax: float,
		band: float, col: Color) -> void:
	var half: float = tank_size * 0.5 - 0.008
	var n: int = 0
	while n < 32:
		var r: float = base + float(n) * lam
		n += 1
		if r > rmax:
			break
		if r <= band:
			continue
		var r0: float = r - band * 0.5
		var r1: float = r + band * 0.5
		var fade: float = clampf(1.0 - r / rmax, 0.22, 1.0)
		var c: Color = Color(col.r, col.g, col.b, col.a * fade)
		for s in range(RING_SEGMENTS):
			var a0: float = TAU * float(s) / float(RING_SEGMENTS)
			var a1: float = TAU * float(s + 1) / float(RING_SEGMENTS)
			var p00: Vector3 = origin + Vector3(cos(a0) * r0, 0.0, sin(a0) * r0)
			var p01: Vector3 = origin + Vector3(cos(a0) * r1, 0.0, sin(a0) * r1)
			var p10: Vector3 = origin + Vector3(cos(a1) * r0, 0.0, sin(a1) * r0)
			var p11: Vector3 = origin + Vector3(cos(a1) * r1, 0.0, sin(a1) * r1)
			if absf(p00.x) > half or absf(p00.z) > half:
				continue
			if absf(p01.x) > half or absf(p01.z) > half:
				continue
			if absf(p10.x) > half or absf(p10.z) > half:
				continue
			if absf(p11.x) > half or absf(p11.z) > half:
				continue
			_rings_im.surface_set_color(c)
			_rings_im.surface_add_vertex(p00)
			_rings_im.surface_set_color(c)
			_rings_im.surface_add_vertex(p01)
			_rings_im.surface_set_color(c)
			_rings_im.surface_add_vertex(p11)
			_rings_im.surface_set_color(c)
			_rings_im.surface_add_vertex(p00)
			_rings_im.surface_set_color(c)
			_rings_im.surface_add_vertex(p11)
			_rings_im.surface_set_color(c)
			_rings_im.surface_add_vertex(p10)

# RUNG 3 — LONGHAND. The sum written out: plate A, a "+", plate B, a rule, and the
# tank below as the answer. The addends are FLAT colour plates rather than little
# reliefs, and that is a deliberate choice against the obvious one — a relief reads
# differently from every angle, and a rung that is only legible from the front is a
# rung the evidence loop will photograph three times as nothing.
#
# The plates stack INSIDE the tank's own footprint (0.34 m each, side by side under
# 0.8 m of tank) so the variant cannot collide with a neighbour in a real map. What
# it costs instead is height: the artifact grows to about a metre.
func _build_addends() -> void:
	var tile: float = 0.34
	var y0: float = 0.46
	var lean: float = -35.0
	var names: Array = ["A", "B"]
	for s in range(2):
		var holder := Node3D.new()
		holder.name = "Addend%d" % s
		var hx: float = -0.21
		if s == 1:
			hx = 0.21
		holder.position = Vector3(hx, y0, -0.02)
		holder.rotation_degrees = Vector3(lean, 0.0, 0.0)
		_ev_add(holder)

		var back := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(tile + 0.028, tile + 0.028, 0.010)
		back.mesh = bb
		back.position = Vector3(0, 0, -0.008)
		back.material_override = _flat(Color(0.045, 0.05, 0.07), 0.85)
		holder.add_child(back)

		var mi := MeshInstance3D.new()
		mi.name = "AddendField"
		var im := ImmediateMesh.new()
		mi.mesh = im
		mi.material_override = _readout_material()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi)
		_addend_im.append(im)

		var lab: MeshInstance3D = BakedText.make_label_mesh(
				str(names[s]), Color(0.96, 0.94, 0.86), Vector2(0.055, 0.055), 1400, true)
		if lab:
			lab.position = Vector3(0, tile * 0.5 + 0.048, 0.002)
			holder.add_child(lab)

	var plus: MeshInstance3D = BakedText.make_label_mesh(
			"+", Color(0.96, 0.94, 0.86), Vector2(0.075, 0.075), 1400, true)
	if plus:
		plus.position = Vector3(0, y0, -0.02)
		plus.rotation_degrees = Vector3(lean, 0.0, 0.0)
		_ev_add(plus)

	# The rule you draw before writing the answer. The tank is the answer.
	var rule := MeshInstance3D.new()
	rule.name = "AdditionRule"
	var rb := BoxMesh.new()
	rb.size = Vector3(tank_size * 0.92, 0.013, 0.013)
	rule.mesh = rb
	rule.position = Vector3(0, 0.255, -0.02)
	rule.material_override = _glow(Color(0.96, 0.94, 0.86), 1.6)
	_ev_add(rule)

func _draw_addends() -> void:
	if _addend_im.size() < 2:
		return
	var tile: float = 0.34
	var n: int = ADDEND_RES
	var step: float = tile / float(n)
	var half_t: float = tile * 0.5
	var half_size: float = tank_size * 0.5
	var span: float = tank_size / float(n)
	# The same k and ω the water is using, read the same way.
	var wavelength: float = wave_speed / maxf(wave_frequency, 0.0001)
	var k: float = TAU / maxf(wavelength, 0.0001)
	var omega: float = TAU * wave_frequency

	for s in range(2):
		var im: ImmediateMesh = _addend_im[s]
		if im == null:
			continue
		var src: Vector3 = _source_1_pos
		var ph: float = 0.0
		if s == 1:
			src = _source_2_pos
			ph = phase_difference
		# One evaluation per lattice point rather than four per cell.
		var cols: PackedColorArray = PackedColorArray()
		cols.resize((n + 1) * (n + 1))
		for j in range(n + 1):
			for i in range(n + 1):
				var wx: float = -half_size + float(i) * span
				var wz: float = -half_size + float(j) * span
				var r: float = Vector3(wx, 0.0, wz).distance_to(src)
				cols[j * (n + 1) + i] = _height_to_color(
						wave_amplitude * sin(k * r - omega * _time + ph))
		im.clear_surfaces()
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in range(n):
			for i in range(n):
				var u0: float = -half_t + float(i) * step
				var u1: float = -half_t + float(i + 1) * step
				var v0: float = half_t - float(j) * step
				var v1: float = half_t - float(j + 1) * step
				var c00: Color = cols[j * (n + 1) + i]
				var c10: Color = cols[j * (n + 1) + i + 1]
				var c01: Color = cols[(j + 1) * (n + 1) + i]
				var c11: Color = cols[(j + 1) * (n + 1) + i + 1]
				im.surface_set_color(c00)
				im.surface_add_vertex(Vector3(u0, v0, 0.0))
				im.surface_set_color(c10)
				im.surface_add_vertex(Vector3(u1, v0, 0.0))
				im.surface_set_color(c11)
				im.surface_add_vertex(Vector3(u1, v1, 0.0))
				im.surface_set_color(c00)
				im.surface_add_vertex(Vector3(u0, v0, 0.0))
				im.surface_set_color(c11)
				im.surface_add_vertex(Vector3(u1, v1, 0.0))
				im.surface_set_color(c01)
				im.surface_add_vertex(Vector3(u0, v1, 0.0))
		im.surface_end()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: phase_difference = 0.0
			KEY_2: phase_difference = PI
			KEY_3: phase_difference = PI / 2
			KEY_4: phase_difference = PI / 4
			KEY_UP: wave_frequency = minf(wave_frequency + 0.5, 10.0)
			KEY_DOWN: wave_frequency = maxf(wave_frequency - 0.5, 0.5)
			KEY_LEFT: source_separation = maxf(source_separation - 0.05, 0.1)
			KEY_RIGHT: source_separation = minf(source_separation + 0.05, 0.8)

func set_phase(phi: float) -> void:
	phase_difference = phi

func set_frequency(f: float) -> void:
	wave_frequency = f

func set_separation(s: float) -> void:
	source_separation = s

func _exit_tree() -> void:
	# Disconnect signals to prevent dangling references
	if _freq_slider and _freq_slider.slider_moved.is_connected(_on_freq_changed):
		_freq_slider.slider_moved.disconnect(_on_freq_changed)
	if _sep_slider and _sep_slider.slider_moved.is_connected(_on_sep_changed):
		_sep_slider.slider_moved.disconnect(_on_sep_changed)
	# Free created nodes
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()
	# Drop the evidence meshes so a torn-down tank cannot be redrawn into.
	_evidence_root = null
	_addend_im.clear()
	_trace_im = null
	_rings_im = null
