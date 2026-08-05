# y_oscillation_cube.gd
# Stage 2: Y-axis oscillation demonstration
# Core concept: y = A * sin(ωt)
# Shows how sine function maps time to vertical position
# Creates cube directly with Grid shader (not cube_scene instantiation)

extends Node3D

class_name YOscillationCube


# @identity
# essence: y(t) = A * sin(2*PI*f*t) — simple harmonic motion along the vertical axis
# desire: Watch a cube bounce on a vertical rail, feeling the simplest possible oscillation
# critical_parameter: frequency — controls how fast the cube oscillates up and down
# triggers: time drives continuous sine evaluation; amplitude and frequency adjustable
# emerges: the most elemental wave visualization — one axis, one sine, one cube
# needs: VR observation [has], amplitude/frequency sliders [missing], ghost trail [has]
# relationships: depends on basic sine function; contrasts with oscillation_controlled_cube (single vs multi-axis oscillation); unlocks y=sin(t) intuition
# truth: y = A*sin(2*pi*f*t) is the simplest sentence in the language of oscillation.

const GRID_SHADER = preload("res://commons/resourses/shaders/Grid.gdshader")

@export var cube_size: float = 0.15  # Size in meters
@export var amplitude: float = 0.2  # A in the formula (movement range)
@export var frequency: float = 1.0  # ω = 2πf
@export var cube_color: Color = Color(0.2, 0.8, 0.5)  # Teal green
@export var show_rail: bool = true
@export var show_trail: bool = true
@export var trail_count: int = 5

## AXIS — WHAT A POSITION PERSISTS AS once the cube has left it. Not the amplitude, not the
## frequency, not the sine: those are what this artifact TEACHES and they run identically at
## every value. What the demonstration decides is whether an oscillation is a present-tense
## fact — a cube, here, now — or something that leaves a record, and what kind of record a
## space is willing to hold.
##
## Adopted word for word — and value for value — from [[mystic_writing_pad]], where the
## vocabulary comes from, and shared with [[draw_dot]], [[grab_sphere_point_snap]],
## [[draw_triangle_faces]] and [[interactive_point_origin_force]]. Each of those puts a mark
## into space and has to decide what space does with it; a bouncing cube is the same
## question asked of a body instead of a stylus. Its two siblings in this registry,
## [[rotating_cube_demo]] and [[oscillation_controlled_cube]], take the same five words.
##
##   none      space does not keep it. The rail and the markers stand, the cube runs, and
##             nothing at all is left behind it — a present with no past
##   trace     the past stays ON THE SURFACE at one strength. Fourteen ghosts, every one the
##             same size and the same ink, no fade — accumulation without depth
##   lattice   a position counts only where it is legal. A ruled ladder of nine rungs stands
##             the full amplitude beside the rail and every ghost is quantised onto it, so
##             the trail is a stair of stations instead of a continuum
##   archive   nothing sinks past recall. Twenty-four ghosts at full brightness, none dimmed
##             by age, until the column is more ghost than air
##   wax       the legacy lineage, byte for byte — five ghosts graded by age over a depth
##             that keeps the lot, each older trace weighted differently from the last
##
## `wax` is this artifact's default because `wax` is what it already was: five graded ghosts
## have shipped since it was written. The other four are the positions it argues against,
## made standable. [[oscillation_controlled_cube]] defaults to `none` for the same reason —
## it has never kept anything — and that is a true statement about it, not a shortfall.
@export_enum("none", "trace", "lattice", "archive", "wax") var retention: String = "wax"
const RETENTIONS: PackedStringArray = ["none", "trace", "lattice", "archive", "wax"]

## AXIS — WHERE IN THE CYCLE THIS EXHIBIT IS CAUGHT.
##
## y = A * sin(wt) is a sentence about TIME, and a room can only ever meet it at one moment.
## The shipped artifact never decides which moment: the cube runs, and whichever instant a
## visitor arrives in is the instant the formula is demonstrated at. That is a real choice
## made by default and never stated, and it is the whole difference between "watch a thing
## oscillate" and "here is what this formula EQUALS at wt = pi/2, and here is what its
## velocity is there".
##
## `phase` is [[slope_tangent_demo]]'s word, taken character for character WITH its value
## list — traverse / crest / steepest / trough — and it is taken because that file's own
## promotion note says these four "are facts about a sine" and declined them for being a
## closed track rather than a sine. This artifact IS the sine, so it can answer all four,
## which is the only condition under which a shared word is honest.
##
##   traverse  the shipped free run. _time accumulates delta exactly as it always has and
##             the cube crosses its rail once per 1/f seconds. The legacy lineage, and the
##             only value whose picture is not reproducible: what a still catches depends
##             on how many frames the boot managed before the shutter
##   crest     wt = pi/2. sin = +1, y = +A, and the velocity is ZERO — the cube is held at
##             the top marker, the moment the motion is furthest from where it started and
##             least in a hurry to be anywhere
##   steepest  wt = 0. sin = 0, y = 0, and |dy/dt| is at its MAXIMUM — the cube sits at the
##             rest height it passes through fastest. The value that separates position
##             from motion: it looks like the cube is doing nothing and it is doing the most
##   trough    wt = 3pi/2. sin = -1, y = -A, velocity zero again — the crest's mirror, at
##             the bottom marker, and the proof that a sine's two still points are not the
##             same point
##
## Three of the four are three DIFFERENT HEIGHTS on the same rail (+A, 0, -A) against
## markers that were already there, so no two values can produce the same still. That is
## the trap slope_tangent_demo warned about — on y = sin(x), zero, steepest and inflection
## are one point — avoided by stationing on POSITION rather than on curvature.
##
## The rate itself is NOT on this axis and could not be: `frequency` is a rate and a rate
## is invisible to a still. What a still can hold is where in the cycle the sentence was
## interrupted.
@export_enum("traverse", "crest", "steepest", "trough") var phase: String = "traverse"
const PHASES: PackedStringArray = ["traverse", "crest", "steepest", "trough"]

var _cube_mesh: MeshInstance3D
var _cube_material: ShaderMaterial
var _label: Label3D
var _formula_label: Label3D
var _rail: MeshInstance3D
var _rail_top_marker: MeshInstance3D
var _rail_bottom_marker: MeshInstance3D
var _trail_ghosts: Array[MeshInstance3D] = []

var _base_y: float = 0.0
var _time: float = 0.0
var _trail_history: Array[float] = []

## PHASE state. `_phase_held` is false on the shipped value, and it is the only thing the
## legacy _process path ever asks about.
var _phase_held: bool = false
var _phase_pin: float = 0.0
var _phase_plate: Label3D = null


func _ready():
	print("y_oscillation_cube: cube_size = ", cube_size)  # Debug
	_base_y = cube_size / 2.0  # Rest position (cube sits on ground)
	_create_cube()
	_create_rail()
	_create_labels()
	_create_trail_ghosts()
	# DNA, LAST: the retention pass runs after the whole legacy build exists. "wax" returns
	# on the first line, so the shipped lineage keeps its exact children in their exact order.
	var _r: String = str(retention).strip_edges().to_lower()
	retention = _r if RETENTIONS.has(_r) else "wax"
	_apply_retention()
	# AND THE PHASE, last of all: "traverse" leaves _phase_held false and returns before it
	# touches _time, so the shipped cube starts at t = 0 and accumulates delta as it always has.
	var _p: String = str(phase).strip_edges().to_lower()
	phase = _p if PHASES.has(_p) else "traverse"
	_apply_phase()


func _create_cube():
	# Create MeshInstance3D with BoxMesh directly
	_cube_mesh = MeshInstance3D.new()
	
	var box = BoxMesh.new()
	box.size = Vector3(cube_size, cube_size, cube_size)  # Set actual size here!
	_cube_mesh.mesh = box
	
	# Create Grid shader material
	_cube_material = ShaderMaterial.new()
	_cube_material.shader = GRID_SHADER
	_cube_material.set_shader_parameter("modelColor", cube_color * 0.2)
	_cube_material.set_shader_parameter("wireframeColor", cube_color)
	_cube_material.set_shader_parameter("emissionColor", cube_color * 1.2)
	_cube_material.set_shader_parameter("width", 3.0)
	_cube_material.set_shader_parameter("blur", 0.5)
	_cube_material.set_shader_parameter("emission_strength", 0.4)
	_cube_material.set_shader_parameter("show_interior", true)
	
	_cube_mesh.material_override = _cube_material
	_cube_mesh.position.y = _base_y
	add_child(_cube_mesh)


func _create_rail():
	if not show_rail:
		return
	
	# Vertical rail showing movement range
	_rail = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.008
	cylinder.bottom_radius = 0.008
	cylinder.height = amplitude * 2 + cube_size
	_rail.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.5, 0.6, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.5, 0.7)
	mat.emission_energy_multiplier = 0.2
	_rail.material_override = mat
	
	_rail.position = Vector3(cube_size * 0.7, _base_y, 0)
	add_child(_rail)
	
	# Top marker (max amplitude)
	_rail_top_marker = _create_range_marker(Color(0.3, 0.8, 0.4))
	_rail_top_marker.position = Vector3(cube_size * 0.7, _base_y + amplitude, 0)
	add_child(_rail_top_marker)
	
	# Bottom marker (min amplitude)
	_rail_bottom_marker = _create_range_marker(Color(0.8, 0.4, 0.3))
	_rail_bottom_marker.position = Vector3(cube_size * 0.7, _base_y - amplitude, 0)
	add_child(_rail_bottom_marker)


func _create_range_marker(color: Color) -> MeshInstance3D:
	var marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	marker.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	marker.material_override = mat
	
	return marker


func _create_labels():
	# Real-time values label
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 56
	_label.outline_size = 6
	_label.text = "t = 0.00\nsin(t) = 0.00\ny = 0.00"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.position = Vector3(-cube_size * 1.5, _base_y + amplitude + 0.1, 0)
	_label.modulate = Color(0.8, 0.9, 1.0)
	add_child(_label)
	
	# Formula label
	_formula_label = Label3D.new()
	_formula_label.pixel_size = 0.001
	_formula_label.font_size = 72
	_formula_label.outline_size = 8
	_formula_label.text = "y = A · sin(ωt)"
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.position = Vector3(0, -0.08, cube_size)
	_formula_label.rotation.x = -PI / 6
	_formula_label.modulate = Color(0.6, 0.85, 1.0)
	add_child(_formula_label)
	
	# Amplitude indicator
	var amp_label = Label3D.new()
	amp_label.pixel_size = 0.001
	amp_label.font_size = 40
	amp_label.text = "A=%.2f" % amplitude
	amp_label.position = Vector3(cube_size * 1.0, _base_y + amplitude * 0.5, 0)
	amp_label.modulate = Color(0.5, 0.8, 0.5)
	add_child(amp_label)


func _create_trail_ghosts():
	if not show_trail:
		return
	
	for i in range(trail_count):
		var ghost = MeshInstance3D.new()
		var box = BoxMesh.new()
		var ghost_size = cube_size * (0.6 + float(i) / trail_count * 0.3)
		box.size = Vector3(ghost_size, ghost_size, ghost_size)
		ghost.mesh = box
		ghost.visible = false
		
		# Create transparent ghost material
		var mat = ShaderMaterial.new()
		mat.shader = GRID_SHADER
		var alpha = 0.1 + (float(i) / trail_count) * 0.2
		mat.set_shader_parameter("modelColor", Color(cube_color.r * 0.2, cube_color.g * 0.2, cube_color.b * 0.2, alpha))
		mat.set_shader_parameter("wireframeColor", Color(cube_color.r, cube_color.g, cube_color.b, alpha))
		mat.set_shader_parameter("emissionColor", Color(cube_color.r, cube_color.g, cube_color.b, alpha * 0.5))
		mat.set_shader_parameter("width", 2.0)
		mat.set_shader_parameter("blur", 0.6)
		mat.set_shader_parameter("emission_strength", 0.2)
		mat.set_shader_parameter("show_interior", false)
		ghost.material_override = mat
		
		add_child(ghost)
		_trail_ghosts.append(ghost)


func _process(delta):
	# PHASE. `_phase_held` is false at "traverse", so the shipped line below is what runs and
	# the clock accumulates exactly as it did. A pinned station re-asserts its own _time every
	# frame instead, which freezes the sine, the labels and the colour feedback together —
	# nothing downstream needs to know, because everything downstream is a function of _time.
	if _phase_held:
		_time = _phase_pin
	else:
		_time += delta

	# Calculate oscillation: y = A * sin(ωt)
	var omega = frequency * TAU  # ω = 2πf
	var sin_value = sin(omega * _time)
	var y_offset = amplitude * sin_value
	
	# Update cube position
	_cube_mesh.position.y = _base_y + y_offset
	
	# Update trail
	_update_trail(y_offset)
	
	# Update labels
	_update_labels(sin_value, y_offset)
	
	# Color feedback based on position
	_update_color_feedback(sin_value)


func _update_trail(current_y_offset: float):
	if not show_trail:
		return

	# RETENTION "lattice" only: a position counts where it is legal. _ret_quantise is 0.0 on
	# every other value, so this compare is the whole cost on the legacy path.
	if _ret_quantise > 0.0:
		current_y_offset = snappedf(current_y_offset, _ret_quantise)

	# Add current position to history
	_trail_history.push_front(current_y_offset)
	if _trail_history.size() > trail_count:
		_trail_history.pop_back()
	
	# Update ghost positions
	for i in range(mini(_trail_history.size(), _trail_ghosts.size())):
		var ghost = _trail_ghosts[i]
		ghost.visible = true
		ghost.position.y = _base_y + _trail_history[i]


func _update_labels(sin_value: float, y_offset: float):
	if _label:
		_label.text = "t = %.2f\nsin(ωt) = %.2f\ny = %.3f" % [
			fmod(_time, 100.0),
			sin_value,
			y_offset
		]
		
		# Move label with cube (track it)
		_label.position.y = _base_y + amplitude + 0.15


func _update_color_feedback(sin_value: float):
	if not _cube_material:
		return
	
	# Intensity based on position (brighter at extremes)
	var intensity = abs(sin_value)
	
	# Color shift: green at top, blue at bottom
	var t = (sin_value + 1.0) / 2.0  # 0 to 1
	var current_color = cube_color.lerp(Color(0.3, 0.9, 0.4), t * 0.3)
	
	_cube_material.set_shader_parameter("wireframeColor", current_color)
	_cube_material.set_shader_parameter("emissionColor", current_color * (1.0 + intensity * 0.5))
	_cube_material.set_shader_parameter("emission_strength", 0.3 + intensity * 0.4)


# Public API

func set_amplitude(a: float) -> void:
	amplitude = a
	# Rebuild rail if needed
	if _rail:
		_rail.queue_free()
		_rail_top_marker.queue_free()
		_rail_bottom_marker.queue_free()
		_create_rail()


func set_frequency(f: float) -> void:
	frequency = f


func get_current_y() -> float:
	return _cube_mesh.position.y - _base_y


func get_cube_instance() -> MeshInstance3D:
	return _cube_mesh


func get_sin_value() -> float:
	var omega = frequency * TAU
	return sin(omega * _time)


func reset() -> void:
	_time = 0.0
	_trail_history.clear()

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
	# Only a token that actually names the axis re-runs the pass; everything else keeps the
	# behaviour this function has always had.
	if config_data.has("retention"):
		var _r: String = str(config_data["retention"]).strip_edges().to_lower()
		retention = _r if RETENTIONS.has(_r) else "wax"
		_apply_retention()
	# Same contract for the station: only a token that actually names `phase` re-runs it, and
	# _apply_phase frees its own plate first, so a config call that arrives BEFORE _ready (the
	# capture harness does exactly that) cannot leave a second one behind when _ready repeats it.
	if config_data.has("phase"):
		var _p: String = str(config_data["phase"]).strip_edges().to_lower()
		phase = _p if PHASES.has(_p) else "traverse"
		_apply_phase()


# ── PHASE ────────────────────────────────────────────────────────────────────
# Where in the cycle the exhibit is caught. Nothing here touches the formula: `amplitude`,
# `frequency`, the rail, the markers, the ghosts and the colour feedback are identical at
# every value, and a pinned station is the SAME sine read at a stated moment rather than a
# different one. The stations are solved from `frequency`, not hard-coded, so a map that
# changes the rate still gets the crest at the crest.


func _apply_phase() -> void:
	# The caption is rebuilt, never accumulated. This function is idempotent by construction
	# because both entry points (_ready and apply_grid_config) may reach it more than once.
	if _phase_plate != null and is_instance_valid(_phase_plate):
		remove_child(_phase_plate)
		_phase_plate.queue_free()
	_phase_plate = null

	_phase_held = (phase != "traverse") and PHASES.has(phase)
	if not _phase_held:
		return                       # the legacy lineage: a free-running clock, untouched

	var omega: float = frequency * TAU
	if absf(omega) < 0.0001:
		omega = TAU                  # a zero rate has no crest; fall back to one cycle a second
	var caption: String = ""
	match phase:
		"crest":
			_phase_pin = (PI * 0.5) / omega
			caption = "crest    wt = pi/2    sin = +1    y = +A    v = 0"
		"steepest":
			_phase_pin = 0.0
			caption = "steepest    wt = 0    sin = 0    y = 0    |v| max"
		"trough":
			_phase_pin = (PI * 1.5) / omega
			caption = "trough    wt = 3pi/2    sin = -1    y = -A    v = 0"
		_:
			_phase_pin = 0.0
	_time = _phase_pin
	_trail_history.clear()

	# ASCII on purpose. The two legacy labels carry a real omega and a real middle dot and
	# they are left exactly as they are; new text does not gamble on the fallback font,
	# because an exponent that renders as a tofu box is worse evidence than a plain line.
	var plate := Label3D.new()
	plate.name = "PhaseStation"
	plate.pixel_size = 0.001
	plate.font_size = 34
	plate.outline_size = 5
	plate.text = caption
	plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.position = Vector3(0.0, _base_y + amplitude + 0.055, cube_size * 0.9)
	plate.modulate = Color(1.0, 0.92, 0.55)
	add_child(plate)
	_phase_plate = plate


# ── RETENTION ────────────────────────────────────────────────────────────────
# One axis, five moments, shared word for word with mystic_writing_pad.gd and with the two
# sibling motion demos in this registry. Everything below runs AFTER the legacy _ready()
# body; "wax" returns on the first line, so the shipped lineage is untouched — same nodes,
# same order, same materials, same alpha ramp.
#
# The rungs differ only in HOW MANY ghosts exist, how they are weighted, and whether the
# positions they take are quantised. The cube, the rail, the markers, the labels, the sine
# and the colour feedback are identical at every value.

## Ladder rung spacing, in metres. 0.0 means "do not quantise" — every value but `lattice`.
var _ret_quantise: float = 0.0
## The ruled ladder built by `lattice`, freed before a rebuild.
var _ret_rule: Node3D = null

const RET_TRACE_COUNT := 14
const RET_ARCHIVE_COUNT := 24
const RET_LATTICE_COUNT := 9
const RET_LATTICE_RUNGS := 9


func _apply_retention() -> void:
	if retention == "wax" or not RETENTIONS.has(retention):
		return                       # the legacy lineage: five graded ghosts, as shipped

	# Everything past here replaces the trail wholesale, so clear the shipped one first.
	for ghost in _trail_ghosts:
		if is_instance_valid(ghost):
			remove_child(ghost)
			ghost.queue_free()
	_trail_ghosts.clear()
	_trail_history.clear()
	if _ret_rule != null and is_instance_valid(_ret_rule):
		remove_child(_ret_rule)
		_ret_rule.queue_free()
	_ret_rule = null
	_ret_quantise = 0.0

	match retention:
		"none":
			trail_count = 0          # nothing is kept; the history stops growing too
		"trace":
			trail_count = RET_TRACE_COUNT
			_ret_build_uniform_ghosts(RET_TRACE_COUNT, cube_size * 0.85, 0.30, 0.22, 2.0)
		"archive":
			trail_count = RET_ARCHIVE_COUNT
			_ret_build_uniform_ghosts(RET_ARCHIVE_COUNT, cube_size * 0.90, 0.62, 0.55, 3.0)
		"lattice":
			trail_count = RET_LATTICE_COUNT
			_ret_quantise = (amplitude * 2.0) / float(maxi(RET_LATTICE_RUNGS - 1, 1))
			_ret_build_uniform_ghosts(RET_LATTICE_COUNT, cube_size * 0.80, 0.42, 0.30, 2.5)
			_ret_build_rule()
		_:
			pass


## Ghosts that are all the SAME: one size, one alpha, no ramp. `trace` uses this to say the
## past sits beside the present rather than under it; `archive` uses it at full strength to
## say nothing has sunk past recall.
func _ret_build_uniform_ghosts(count: int, size: float, alpha: float, emission: float, width: float) -> void:
	for i in range(count):
		var ghost := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(size, size, size)
		ghost.mesh = box
		ghost.visible = false

		var mat := ShaderMaterial.new()
		mat.shader = GRID_SHADER
		mat.set_shader_parameter("modelColor", Color(cube_color.r * 0.2, cube_color.g * 0.2, cube_color.b * 0.2, alpha))
		mat.set_shader_parameter("wireframeColor", Color(cube_color.r, cube_color.g, cube_color.b, alpha))
		mat.set_shader_parameter("emissionColor", Color(cube_color.r, cube_color.g, cube_color.b, alpha))
		mat.set_shader_parameter("width", width)
		mat.set_shader_parameter("blur", 0.4)
		mat.set_shader_parameter("emission_strength", emission)
		mat.set_shader_parameter("show_interior", false)
		ghost.material_override = mat

		add_child(ghost)
		_trail_ghosts.append(ghost)


## LATTICE only — the ruled ladder the positions are quantised onto. Nine rungs standing the
## full amplitude beside the rail, plus the two end stops, so the stair the ghosts climb is
## drawn as well as obeyed. Without the drawing, quantisation looks like a stutter; with it,
## it looks like a rule.
func _ret_build_rule() -> void:
	var rule := Node3D.new()
	rule.name = "RetentionRule"
	add_child(rule)
	_ret_rule = rule

	var ink := StandardMaterial3D.new()
	ink.albedo_color = Color(0.70, 0.78, 0.86, 0.75)
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ink.emission_enabled = true
	ink.emission = Color(0.55, 0.70, 0.85)
	ink.emission_energy_multiplier = 0.45

	var rx: float = -cube_size * 0.85
	for k in range(RET_LATTICE_RUNGS):
		var f: float = float(k) / float(maxi(RET_LATTICE_RUNGS - 1, 1))
		var ry: float = _base_y - amplitude + amplitude * 2.0 * f
		var long_rung: bool = (k == 0) or (k == RET_LATTICE_RUNGS - 1) or (k * 2 == RET_LATTICE_RUNGS - 1)
		var wide: float = cube_size * (0.80 if long_rung else 0.48)
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(wide, 0.004, 0.010)
		bar.mesh = bm
		bar.material_override = ink
		bar.position = Vector3(rx - wide * 0.5 + cube_size * 0.10, ry, 0)
		rule.add_child(bar)

	# The stile the rungs hang off, so the ladder reads as one object.
	var stile := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.006, amplitude * 2.0, 0.010)
	stile.mesh = sm
	stile.material_override = ink
	stile.position = Vector3(rx + cube_size * 0.10, _base_y, 0)
	rule.add_child(stile)
