# transforming_pattern.gd
# QFEP φ > 0 Visualization - Transforming Pattern
# Queer signature: pattern that embraces change
# Constantly evolving, never the same twice

extends Node3D

class_name QFEPTransformingPattern

# @identity
# essence: _combined(x, z) sets every cell's height, scale, hue and spin from a wave field whose SHAPE is the `concert` draft — three incommensurate waves by default
# desire: watch a grid that never settles — and see whether the cells are dancing together, in turn, or each alone
# critical_parameter: concert — HOW the change is distributed among the cells. transform_speed is only how fast; concert is who moves with whom
# triggers: _process continuously updates height, scale, color, and rotation of every cell from the wave field
# emerges: traveling wave fronts and interference patterns that no single wave produces alone
# needs: VR speed control [missing], wave parameter adjustment [missing]
# relationships: contrasts preserved_pattern (phi<0 frozen vs phi>0 flowing); paired with fluid_form; represents positive phi
# truth: positive phi means the pattern itself is in motion — transformation is not corruption but the signature of life

# --- STAGE-2 DNA (promoted 2026-08-04, by hand) -------------------------------
# THE HARD-CODED CONSTANT WAS THE WAVE FIELD. Three lines, written inline with no
# name on them:
#     wave1 = sin(_time + x*0.8 + z*0.3)
#     wave2 = cos(_time*1.3 + x*0.4 - z*0.7)
#     wave3 = sin(_time*0.7 - x*0.5 + z*0.9)
# averaged, and the average then drives height, scale, hue and spin. Three periods
# that share no common multiple means no cell ever agrees with its neighbour and
# the grid never repeats — which is a strong claim about what becoming looks like,
# made silently, as though it were the only way a thing can change.
#
# THE AXIS IS `concert`: how the change is DISTRIBUTED among the cells. Everything
# at once (unison), a front sweeping across (front), rings out of a centre
# (ripple), three rhythms at odds (superposition, the shipped field), or every
# cell on its own clock (solitary). Same φ>0, same restlessness, five different
# politics of who transforms with whom — and each of the five is a different
# still, because the shape of a wave field is spatial and a photograph can hold it.
#
# WHY NOT A WORD FROM THE FAMILY. Three were on the table and all three were
# refused for cause:
#   `motif`, preserved_pattern's axis (blank|checker|cross|twill|houndstooth),
#     shared with the six pattern_tile_* tokens. That axis asks which cells are
#     FIGURE and which are GROUND. This grid has no ground: every cell is on, and
#     always was. Borrowing the word would mean inventing a mask that masks
#     nothing, and the two artifacts would not measure alike.
#   `accord`, boid_manager's word (school|orb|lane|lattice), and the best-fitting
#     English of the three — a flock's accord IS how many bodies agree. But its
#     values are ARRANGEMENTS OF POSITIONS that agents reach by rule, and these
#     are PHASE RELATIONS across a grid that never moves. One list cannot serve
#     both, and a shared word with two value lists is the science_screen fault
#     wearing a friendlier face.
#   `field`, vector_field_grid's word (cells|orbit|sink|saddle|shear), is the
#     critical-point taxonomy of a VECTOR field. This is a scalar height field
#     and has no saddles to name.
#
# AND THE ONE AXIS THAT IS REALLY THERE, DECLINED ON THE EVIDENCE. This artifact
# and preserved_pattern ARE the two ends of one axis: φ<0 frozen against φ>0
# flowing, the presence or absence of time. That axis is honest, it is the pair's
# whole point, and it is exactly the axis a still photograph cannot see — one
# frame of a moving grid and one frame of a frozen grid are the same picture.
# preserved_pattern's own promotion said this from the other end ("the absence of
# time... cannot be a parameter: there is no _process to turn off"). So it stays
# undeclared here too, and `concert` says something a frame can actually witness.
#
# NOT PROMOTED: transform_speed (a rate — invisible to a still, and the loop has
# published a finished-looking six-tile nothing on a duration axis before),
# grid_size and cell_size (dimensions), pattern_color (decoration, and _process
# overwrites it on frame one anyway).
# ------------------------------------------------------------------------------

## Allow-list. A typo in a map token keeps the shipped wave field rather than
## flattening the grid to a plate.
const CONCERTS: PackedStringArray = ["superposition", "unison", "front", "ripple", "solitary"]

## How the transformation is distributed among the cells. `superposition` is the shipped field.
@export_enum("superposition", "unison", "front", "ripple", "solitary") var concert: String = "superposition"

## Grid size
@export var grid_size: int = 6

## Cell size
@export var cell_size: float = 0.06

## Transform speed
@export var transform_speed: float = 0.8

## Pattern color (gold - embrace)
@export var pattern_color: Color = Color(1.0, 0.8, 0.2, 1.0)

## EVIDENCE FIXTURE, not an axis. Negative = the free-running clock this has always
## had. Any value >= 0 pins _time there and stops it advancing, so five variants are
## photographed at ONE phase and every difference between the frames belongs to
## `concert` rather than to how many frames each boot happened to run.
@export var phase_lock: float = -1.0

# Internal
var _cells: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []
var _time: float = 0.0
var _built: bool = false

func _ready() -> void:
	_read_dna_meta()
	_build_pattern()
	_built = true

## GridInteractablesComponent sets `config_*` metadata on the ROOT before add_child,
## so this runs ahead of the build. An unknown word keeps the default.
func _read_dna_meta() -> void:
	if has_meta("config_concert"):
		var c_in: String = str(get_meta("config_concert")).strip_edges().to_lower()
		concert = c_in if CONCERTS.has(c_in) else concert
	if has_meta("config_grid_size"):
		grid_size = maxi(1, int(str(get_meta("config_grid_size"))))

func _build_pattern() -> void:
	var offset = -grid_size * cell_size / 2.0

	for x in range(grid_size):
		for z in range(grid_size):
			var cell = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(cell_size * 0.9, cell_size * 0.3, cell_size * 0.9)
			cell.mesh = box

			cell.position = Vector3(
				x * cell_size + offset,
				0,
				z * cell_size + offset
			)

			var mat = StandardMaterial3D.new()
			mat.albedo_color = pattern_color
			mat.emission_enabled = true
			mat.emission = pattern_color
			mat.emission_energy_multiplier = 0.5
			cell.material_override = mat

			add_child(cell)
			_cells.append(cell)
			_materials.append(mat)

## The wave field, in the range of a unit sine. The `_:` branch is the shipped one —
## the three inline waves, unchanged term for term — so a placement carrying no
## concert token moves exactly as it always has, and a typo lands there too.
func _combined(x: int, z: int) -> float:
	var out: float = 0.0
	match concert:
		"unison":
			# No spatial term at all: every cell shares one phase. The grid rises
			# and falls as a single body — transformation as a thing done together,
			# and nothing to see between one cell and the next.
			out = sin(_time)
		"front":
			# A plane wave marching along +x. Change arrives as an edge that has
			# already passed some cells and not yet reached others.
			out = sin(_time - float(x) * 0.9)
		"ripple":
			# Rings out of the middle. Change has an origin, and distance from it
			# is the only thing that decides when a cell's turn comes.
			var c: float = float(grid_size - 1) * 0.5
			var r: float = Vector2(float(x) - c, float(z) - c).length()
			out = sin(_time - r * 1.1)
		"solitary":
			# A fixed per-cell phase offset — deterministic, no randf, so a variant
			# is one object and not five. Every cell moves; no cell moves WITH
			# another. Restlessness with nothing shared in it.
			var phase: float = fmod(float(x) * 12.9898 + float(z) * 78.233, TAU)
			out = sin(_time + phase)
		_:
			# superposition — the shipped field: three periods with no common
			# multiple, so the pattern never repeats and no neighbour agrees.
			var wave1: float = sin(_time + x * 0.8 + z * 0.3)
			var wave2: float = cos(_time * 1.3 + x * 0.4 - z * 0.7)
			var wave3: float = sin(_time * 0.7 - x * 0.5 + z * 0.9)
			out = (wave1 + wave2 + wave3) / 3.0
	return out

func _process(delta: float) -> void:
	if phase_lock >= 0.0:
		_time = phase_lock
	else:
		_time += delta * transform_speed

	# Every cell transforms independently
	for i in range(_cells.size()):
		var cell = _cells[i]
		var mat = _materials[i]

		var x: int = i % grid_size
		var z: int = i / grid_size

		# Wave patterns that constantly shift
		var combined: float = _combined(x, z)

		# Height transforms
		cell.position.y = combined * cell_size * 0.5

		# Scale transforms
		var scale_factor = 0.7 + (combined + 1) * 0.3
		cell.scale = Vector3(scale_factor, 1.0 + combined * 0.5, scale_factor)

		# Color transforms - cycling through warm colors
		var hue_shift = sin(_time * 0.5 + i * 0.1) * 0.1
		var color = Color.from_hsv(
			fmod(0.12 + hue_shift, 1.0),  # Gold hue with variation
			0.8,
			0.9 + combined * 0.1
		)
		mat.albedo_color = color
		mat.emission = color
		mat.emission_energy_multiplier = 0.3 + (combined + 1) * 0.3

		# Rotation transforms
		cell.rotation.y = _time * 0.3 + combined * 0.5

# --- Grid config --------------------------------------------------------------

## Grid hook. There was none before, so nothing here was reachable from a map token —
## GridInteractablesComponent calls this on the ROOT and fell through to "no
## configuration method found".
##
## GATED BY DATA. `concert` needs no rebuild at all: the field is evaluated fresh
## every frame, so a new word is simply obeyed on the next one. Only the two
## dimensions can force a rebuild, and only when one of them actually CHANGED and
## _ready has already built once.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("concert"):
		var c_in: String = str(config_data["concert"]).strip_edges().to_lower()
		if CONCERTS.has(c_in):
			concert = c_in
	if config_data.has("phase_lock"):
		phase_lock = float(str(config_data["phase_lock"]))
	if config_data.has("transform_speed"):
		transform_speed = float(str(config_data["transform_speed"]))
	if config_data.has("pattern_color"):
		var col = config_data["pattern_color"]
		if col is Color:
			pattern_color = col
		elif col is String and Color.html_is_valid(str(col)):
			pattern_color = Color.html(str(col))

	var before_grid: int = grid_size
	var before_cell: float = cell_size
	if config_data.has("grid_size"):
		grid_size = maxi(1, int(str(config_data["grid_size"])))
	if config_data.has("cell_size"):
		cell_size = float(str(config_data["cell_size"]))

	if not _built:
		return
	if grid_size == before_grid and is_equal_approx(cell_size, before_cell):
		return
	_rebuild_now()

func _rebuild_now() -> void:
	for c in _cells:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_cells.clear()
	_materials.clear()
	_build_pattern()

# The pattern never settles - always becoming
