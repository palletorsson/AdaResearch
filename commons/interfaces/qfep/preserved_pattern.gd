# preserved_pattern.gd
# QFEP φ < 0 Visualization - Preserved Pattern
# Conservative: the pattern that resists change
# Frozen, static, immutable

extends Node3D

class_name QFEPPreservedPattern

# @identity
# essence: _is_on(x, z) marks a fixed grid by the `motif` draft -> static pattern, no _process(), no animation
# desire: confront a pattern that will never change — feel the weight of preservation
# critical_parameter: motif — WHICH inherited draft is the one being kept forever. The absence of time is the other half, and it cannot be a parameter: there is no _process to turn off
# triggers: nothing triggers change — that is the point; apply_grid_config re-lays the cells when the motif, the grid size or the colour changes
# emerges: nothing emerges — the pattern is dead on arrival, perfectly preserved
# needs: no VR controls needed — immutability is the interaction [has]
# relationships: contrasts transforming_pattern (phi>0 vs phi<0); paired with rigid_sculpture; represents conservative phi; shares the word `motif` with the six pattern_tile_* tokens
# truth: negative phi preserves pattern at the cost of life — a frozen checkerboard is a museum piece, not an organism

# --- STAGE-2 DNA (promoted 2026-08-04, by hand) -------------------------------
# THE HARD-CODED CONSTANT WAS THE RULE ITSELF: `(x + z) % 2 == 0`, written inline
# under a comment reading "Classic checkerboard - stable, predictable, preserved".
# The artifact argues that φ<0 preserves a pattern at the cost of life, and then
# never says WHICH pattern, as though there were only one — which is exactly the
# move a conservative order makes about its own conventions. The checkerboard is
# not the pattern; it is one inherited draft among several, and this artifact has
# frozen that one. Naming the choice is the promotion.
#
# THE WORD IS BORROWED, CHARACTER FOR CHARACTER. `motif` = blank | checker |
# cross | twill | houndstooth is pattern_tile_puzzle's axis (six registry tokens
# share that scene), the same question about the same substrate: which figure a
# square grid of cells carries. Its arithmetic is reproduced here cell for cell —
# checker is `(x + y) % 2 == 0`, twill is `(x + y) % 4 < 2`, cross is the centre
# row and column, houndstooth is the same 4x4 bitmap tiled — so the two artifacts
# measure ALIKE and can be compared rather than merely juxtaposed. Only the
# DEFAULT differs: the loom ships `blank`, arriving empty and waiting to be
# edited; this museum piece ships `checker`, the draft it will keep forever.
# (rigid_sculpture borrowed `formation` on the same terms on the same day.)
#
# NOT SHARED WITH random_cubes, its opposite number in this batch. That artifact
# took `macrostate` (uniform|corner|layered|spilled), microstate_counter's word.
# The two are ends of one conceptual line — frozen order against high entropy —
# and it is tempting to put them on one scale. But that scale's values would be
# DEGREES OF NOISE, which is an amount wearing a name, and neither artifact's own
# hidden constant is an amount: one is a draft, the other is a region. A pattern
# has no macrostate and a loose pile has no motif. Different substrate, different
# term of the formula (φ against E(S)), different word — and edge_core refused a
# shared word across terms yesterday for the same reason.
#
# NOT PROMOTED: cell_size and grid_size. Dimensions. `pattern_color` likewise —
# decoration, and dyelot (pattern_tile's second axis) has nothing to swap here,
# since this grid runs on two materials, not eight yarns.
# ------------------------------------------------------------------------------

## Allow-list. A typo in a map token keeps the shipped checkerboard rather than
## rendering a blank slab.
const MOTIFS: PackedStringArray = ["blank", "checker", "cross", "twill", "houndstooth"]

## A 4x4 houndstooth draft, the same bitmap pattern_tile_puzzle carries, reduced to
## on/off because this grid has two materials rather than eight yarns.
const HOUNDSTOOTH_4: Array = [
	[0, 1, 1, 1],
	[0, 0, 1, 1],
	[1, 1, 0, 0],
	[1, 0, 0, 1],
]

## Which inherited draft is the one being preserved. `checker` is the shipped pattern.
@export_enum("blank", "checker", "cross", "twill", "houndstooth") var motif: String = "checker"

## Grid size
@export var grid_size: int = 6

## Cell size
@export var cell_size: float = 0.06

## Pattern color (purple - conservative)
@export var pattern_color: Color = Color(0.6, 0.3, 0.7, 1.0)

# Internal
var _cells: Array[MeshInstance3D] = []
var _built: bool = false

func _ready() -> void:
	_read_dna_meta()
	_build_pattern()
	_built = true

## GridInteractablesComponent sets `config_*` metadata on the ROOT before add_child,
## so this runs ahead of the build. An unknown word keeps the default.
func _read_dna_meta() -> void:
	if has_meta("config_motif"):
		var m_in: String = str(get_meta("config_motif")).strip_edges().to_lower()
		motif = m_in if MOTIFS.has(m_in) else motif
	if has_meta("config_grid_size"):
		grid_size = maxi(1, int(str(get_meta("config_grid_size"))))

func _build_pattern() -> void:
	# Create a fixed, unchanging pattern
	# The draft is chosen once by `motif` and then kept - stable, predictable, preserved

	var mat_on = StandardMaterial3D.new()
	mat_on.albedo_color = pattern_color
	mat_on.emission_enabled = true
	mat_on.emission = pattern_color
	mat_on.emission_energy_multiplier = 0.5

	var mat_off = StandardMaterial3D.new()
	mat_off.albedo_color = Color(0.15, 0.1, 0.2, 0.8)
	mat_off.emission_enabled = true
	mat_off.emission = Color(0.15, 0.1, 0.2)
	mat_off.emission_energy_multiplier = 0.1

	var offset = -grid_size * cell_size / 2.0

	for x in range(grid_size):
		for z in range(grid_size):
			var cell: MeshInstance3D = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(cell_size * 0.9, cell_size * 0.3, cell_size * 0.9)
			cell.mesh = box

			cell.position = Vector3(
				x * cell_size + offset,
				0,
				z * cell_size + offset
			)

			# The draft this pattern preserves - preserved forever
			var is_on: bool = _is_on(x, z)
			cell.material_override = mat_on if is_on else mat_off

			# Slightly raised if on
			if is_on:
				cell.position.y = cell_size * 0.15

			add_child(cell)
			_cells.append(cell)

## Is this cell figure or ground? The `_:` branch is `checker` — `(x + z) % 2 == 0`,
## the shipped rule, so a placement carrying no motif token is cell for cell what it
## has always been, and a typo lands there too.
func _is_on(x: int, z: int) -> bool:
	var n: int = grid_size
	match motif:
		"blank":
			# Nothing is marked. The grid is still here, still perfectly regular,
			# and there is no longer any pattern in it to preserve.
			return false
		"cross":
			# One centred axis each way — the sampler's registration mark.
			return x == n / 2 or z == n / 2
		"twill":
			# 2/2 twill: two up, two down, stepped one per row. The diagonal is not
			# drawn; it falls out of the arithmetic.
			return ((x + z) % 4) < 2
		"houndstooth":
			return int(HOUNDSTOOTH_4[z % 4][x % 4]) != 0
		_:
			# checker — the shipped rule.
			return (x + z) % 2 == 0

# --- Grid config --------------------------------------------------------------

## Grid hook. There was none before, so nothing here was reachable from a map token —
## GridInteractablesComponent calls this on the ROOT and fell through to "no
## configuration method found".
##
## GATED BY DATA, TWICE. A config carrying none of these keys returns before touching
## anything, and even one that carries them rebuilds only when a value actually
## CHANGED, and only after _ready has built once.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_motif: String = motif
	var before_grid: int = grid_size
	var before_cell: float = cell_size
	var before_color: Color = pattern_color

	if config_data.has("motif"):
		var m_in: String = str(config_data["motif"]).strip_edges().to_lower()
		if MOTIFS.has(m_in):
			motif = m_in
	if config_data.has("grid_size"):
		grid_size = maxi(1, int(str(config_data["grid_size"])))
	if config_data.has("cell_size"):
		cell_size = float(str(config_data["cell_size"]))
	if config_data.has("pattern_color"):
		var c = config_data["pattern_color"]
		if c is Color:
			pattern_color = c
		elif c is String and Color.html_is_valid(str(c)):
			pattern_color = Color.html(str(c))

	if not _built:
		return
	if motif == before_motif \
			and grid_size == before_grid \
			and is_equal_approx(cell_size, before_cell) \
			and pattern_color == before_color:
		return
	_rebuild_now()

func _rebuild_now() -> void:
	for c in _cells:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_cells.clear()
	_build_pattern()

# No _process - this pattern doesn't change
# That's the whole point: φ < 0 resists change
