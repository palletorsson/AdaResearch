extends LineSnapPuzzleBase
class_name QuadLinePuzzle

# @identity
# essence: quad = 4 edges closing 4 corners — the simplest polygon with a right angle relationship
# desire: learner assembles a square and feels how four equal lengths and right angles constrain each other
# critical_parameter: the 4 corner snap targets — all must be occupied for the square to register
# triggers: snapping all 4 line endpoints to the 4 corner positions in sequence
# emerges: the quad as two triangles sharing a diagonal — every quad in 3D is secretly two triangles
# needs: [missing VR controls — all interaction is line-endpoint snapping]
# relationships: extends LineSnapPuzzleBase; logical predecessor to quad face primitive
# truth: a square is four equal sides and four right angles — remove any one constraint and it changes

## QuadLinePuzzle - Interactive puzzle to form a square from four lines
## Any endpoint can snap to any of the 4 corner targets
##
## STAGE-2 DNA PROMOTION (2026-07-29). This artifact had no exports of its own: the
## four corner targets were four hard-coded Vector3 literals, and the only quad you
## could ever be asked to close was a square. But the artifact's own truth statement
## already names the parameter space — "a square is four equal sides and four right
## angles — remove any one constraint and it changes". That sentence is a genome
## description. It was just never wired to anything.
##
## Two axes —
##
##   figure  WHICH quad you are asked to close   square · rectangle · rhombus · trapezoid
##   plane   how the quad stands in the room     upright · ground
##
## figure is the constraint you drop. square keeps both (equal sides, right angles);
## rectangle drops equal sides; rhombus drops the right angles; trapezoid keeps only
## one parallel pair. The validator is unchanged — quad_constraints() asks for a
## CLOSED_LOOP and nothing more — so every figure is a legitimate solve, and the
## learner discovers that "four lines that close" is a much wider family than the
## square they were shown first.
##
## plane is posture, not decoration: upright the quad hangs in the air like a window
## you look through; ground it lies at your feet like a plan you stand inside, and
## you assemble it by looking down instead of straight ahead.
##
## figure=square + plane=upright reproduce the pre-promotion corner literals exactly,
## and they are the defaults, so the 7 existing placements are untouched.
##
## Usage in map_data.json:
##   "quad_line_puzzle"                          → the square, as before
##   "quad_line_puzzle#figure:rhombus"
##   "quad_line_puzzle#figure:trapezoid#plane:ground"

## Half-extent of the figure, in metres. 0.2 = the pre-promotion 20cm from centre.
const HALF: float = 0.2

## Corners in the figure's own 2D frame (u = across, v = up), unit = HALF.
## Wound TL, TR, BR, BL so marker index order survives every figure.
const FIGURES: Dictionary = {
	# four equal sides, four right angles — the legacy literals
	"square": [Vector2(-1.0, 1.0), Vector2(1.0, 1.0), Vector2(1.0, -1.0), Vector2(-1.0, -1.0)],
	# right angles kept, equal sides dropped
	"rectangle": [Vector2(-1.5, 0.6), Vector2(1.5, 0.6), Vector2(1.5, -0.6), Vector2(-1.5, -0.6)],
	# equal sides kept, right angles dropped — unequal diagonals, wound top/right/bottom/left
	"rhombus": [Vector2(0.0, 1.4), Vector2(1.0, 0.0), Vector2(0.0, -1.4), Vector2(-1.0, 0.0)],
	# neither kept — only one pair stays parallel
	"trapezoid": [Vector2(-0.7, 1.0), Vector2(0.7, 1.0), Vector2(1.4, -1.0), Vector2(-1.4, -1.0)],
}

## Where the four unassembled lines wait, per plane. [start, end] each.
## PARKED_UPRIGHT is the pre-promotion parking, copied literally.
const PARKED_UPRIGHT: Array = [
	[Vector3(0.2, -0.15, -0.15), Vector3(0.2, -0.15, 0.15)],  # Line 1: topmost
	[Vector3(0.2, -0.25, -0.15), Vector3(0.2, -0.25, 0.15)],  # Line 2: upper-mid
	[Vector3(0.2, -0.35, -0.15), Vector3(0.2, -0.35, 0.15)],  # Line 3: lower-mid
	[Vector3(0.2, -0.45, -0.15), Vector3(0.2, -0.45, 0.15)],  # Line 4: bottommost
]
const PARKED_GROUND: Array = [
	[Vector3(0.45, 0.02, -0.15), Vector3(0.45, 0.02, 0.15)],
	[Vector3(0.55, 0.02, -0.15), Vector3(0.55, 0.02, 0.15)],
	[Vector3(0.65, 0.02, -0.15), Vector3(0.65, 0.02, 0.15)],
	[Vector3(0.75, 0.02, -0.15), Vector3(0.75, 0.02, 0.15)],
]

## Which quadrilateral the four lines are asked to close. Changing this changes
## which constraint the puzzle is arguing about, not how big it is.
@export var figure: String = "square"
## Whether the quad hangs as a window (upright) or lies as a plan at your feet (ground).
@export var plane: String = "upright"


func _init() -> void:
	_layout()
	success_message = "Square Complete!"

	# Form constraints: Quad requires 4 connected lines forming a closed loop
	form_constraints = FormConstraint.quad_constraints()


func _ready() -> void:
	# Re-run the layout now that exported values (and any scene overrides) are applied.
	# Idempotent: with the defaults this writes back exactly what _init() wrote.
	_layout()
	super._ready()
	print("QuadLinePuzzle: 4 lines, 4 vertices, figure=%s plane=%s, constraint: CLOSED_LOOP (any connection order)" % [figure, plane])


## Build target_positions and line_start_positions from the two axes.
## Called before the base has built anything — it only writes the source arrays.
func _layout() -> void:
	var corners: Array = FIGURES.get(figure, FIGURES["square"])

	var pts: Array[Vector3] = []
	for c in corners:
		var uv: Vector2 = c
		if plane == "ground":
			# lies flat: u runs east, v runs north, read by looking down
			pts.append(Vector3(uv.x * HALF, 0.0, uv.y * HALF))
		else:
			# upright: the legacy frame — x is the plane normal, v is height, u is depth
			pts.append(Vector3(0.0, uv.y * HALF, uv.x * HALF))
	target_positions = pts

	# The four unassembled lines, parked in a rank. Their length does not matter —
	# endpoints stretch to wherever they snap — so the parking is identical for
	# every figure, and only the plane moves it. Written as literals, not stepped
	# by a loop, so the upright rank is bit-for-bit the pre-promotion parking.
	var source: Array = PARKED_GROUND if plane == "ground" else PARKED_UPRIGHT
	var parked: Array[Array] = []
	for row in source:
		parked.append([row[0], row[1]])
	line_start_positions = parked


func _complete_puzzle() -> void:
	var display = get_node_or_null("QuadLogicDisplay")
	if display:
		display.visible = false
	super._complete_puzzle()


## Grid config. Reached only when a map token carries #figure: or #plane:; anything
## else leaves the puzzle exactly as _ready() built it.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false

	if config_data.has("figure"):
		var f: String = str(config_data["figure"])
		if FIGURES.has(f) and f != figure:
			figure = f
			changed = true

	if config_data.has("plane"):
		var p: String = str(config_data["plane"])
		if (p == "upright" or p == "ground") and p != plane:
			plane = p
			changed = true

	if not changed:
		return

	_layout()
	# The base builds markers and lines with call_deferred from _ready, and this
	# method also arrives deferred — so it may run before or after that build.
	# Only move live nodes if there are live nodes; otherwise the pending build
	# picks up the new arrays on its own.
	if not target_markers.is_empty() or not snap_lines.is_empty():
		_relayout_live()


## Move an already-built puzzle onto the new figure without rebuilding it.
func _relayout_live() -> void:
	var global_targets: Array[Vector3] = []
	for local_pos in target_positions:
		global_targets.append(global_transform * local_pos)

	for i in range(target_markers.size()):
		if i < global_targets.size():
			target_markers[i].global_position = global_targets[i]

	for line in snap_lines:
		if line.has_method("set_shared_targets"):
			line.set_shared_targets(global_targets)

	# re-park the endpoints and clear any snap state held against the old corners
	reset_puzzle()
