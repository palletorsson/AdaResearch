# @identity
# essence: an 8 x 8 board of columns that nobody arranged - five cells Conway called R, one rule, and a word that says how long the rule has run - each column as tall as the live cells around it and painted with what the height cannot say, whether it was born this generation or has stood since the seed
# desire: that a visitor walk the streets the rule emptied, read the neighbour count with their body - hip, eye, over the head - and check the paint against the height to find, under crowd, the one column that has stood since the seed
# critical_parameter: run, because it decides which generation stands: seed is the five cells laid flat, crowd is the densest moment before the crash, field is the spread after it. paint only changes what the columns confess about their age
# triggers: _ready() reads config_run / config_paint metadata, runs B3/S23 from the fixed start for 0, 8 or 13 generations, builds one column per live cell, the plate and the body once. apply_grid_config rebuilds only when one of the two words actually changes
# emerges: under crowd an orange column among blue newborns - the cell at row 5, column 5, alive since the seed, age nine - and under field streets nobody drew, one and two dead cells wide
# needs: floor at y=0 under the origin [the grid provides it]; 4.37 m of headroom [the museum's halls have it]; a lit hall, since nothing here emits [the hall provides it]; a body approaching from +Z to read the plate [spatial_needs, player_position "front"]; apply_grid_config [present]
# relationships: the deterministic, colliding, time-axis re-do of ca_conway_city (cellular_automata.json), whose one colour was a random palette pick per cell; the field companion of chroma_stack's by_neighbour, where the neighbour was the one shape below; the walk-scale answer to the crown-jewel reading of dna_primitive_stack_ps_ca01_conway_city, stood in Color_Context_Placed
# truth: colour can be a record rather than a property. The height says how many stand round a column now; the paint says how long it has stood, and neither can be read off the other - under crowd the tallest column (4.35 m, six neighbours) is newborn, and the one that has stood since the seed stands a step shorter at 3.70 m with five

extends Node3D
class_name ChromaLife

## CHROMA_LIFE -- Conway's Life as a field of columns, colour as the rule's record.
##
## Color_Context_Placed's sequence truth is that a colour value enters an encounter:
## a light, a surface, a position, a neighbour and a viewer. chroma_stack made the
## neighbour ONE shape below. Here the neighbour is everyone around, the relation is
## a count, and the colour remembers how long the company has been there.
##
## Five cells - the ones Conway called R - are set down on an 8 x 8 board and B3/S23
## is run for as many generations as `run` names:
##
##   seed    generation 0: the five cells stood as columns (n = 2, 2, 3, 3, 4), the
##           totem laid flat.
##   crowd   generation 8: 18 columns in a 6 x 6 cluster, n 3..6, nine newborn and
##           nine survivors, one of them an original cell alive since the seed.
##           The densest moment before the crash (generation 9 falls to 11).
##   field   generation 13: 16 columns spread over 7 x 7 cells, nine at eye height,
##           eight newborn; the streets between them are what the rule emptied.
##
## Each live cell is a 0.40 m column whose HEIGHT is the crowd around it on the shown
## generation: h = min(4.35, 0.45 + 0.65 n), so 0 is a knee, 1 a hip, 2 the eye, 3
## over the head, 4 is 3.05, 5 is 3.70 and 6 is 4.35. The body is the ruler.
##
## `paint` decides what the colour records, which the height cannot:
##
##   one     ochre on every column: the paint knows nothing of the run.
##   age     the family ramp (hue 0.62 blue to 0.08 orange) at t = (age - 1) / 8:
##           newborn blue, nine generations orange. Same direction as chroma_stack's
##           by_height (older / higher = warmer); it is not inverted for the critic.
##   birth   two colours, 0.40 apart in luminance: newborn YELLOW, survivor BLUE.
##
## There is deliberately no `count` paint: colour by neighbour count is
## ca_conway_city's default and the height already says that number.
##
## THE BOARD, in metres. 8 x 8 cells at pitch 0.55 on a 4.40 x 0.02 x 4.40 dark
## board; cell (r, c) is at x = (c - 3.5) * 0.55, z = (r - 3.5) * 0.55, row 0
## north (-Z), column 0 west (-X). Columns stand on the board's top at y 0.02. An
## unseen anchor (layers = 0) 4.40 x 4.37 x 4.40 - the board's 0.02 plus the
## tallest column's 4.35 - holds the AABB constant across every value, so the
## sweep camera does not shrink the seed and field tiles. The
## plate stands on a post over cell (7, 2), which is dead in every run value.
##
## THE START is the whole work: R = (3,5), (3,6), (4,4), (4,5), (5,5), exactly
## these cells and exactly this orientation (the R-pentomino has eight). Age is
## tracked during the run - 1 at birth, +1 per survived generation - never read off
## the last frame. The board is bounded with dead cells outside; simulated in the
## session that wrote this to be IDENTICAL to unbounded Life through generation 13
## with this start, so no tile is a picture of the border.
##
## THE PLATE. One text_screen in SCREEN mode on a dark post at the board's south
## edge, 1.20 m up, 0.90 wide, facing +Z and never turned about Y. Title = the two
## words in force, body = the run's sentence and the paint's sentence. Rebuilt with
## everything else on every rebuild.
##
## NO RANDOMNESS, no hash, no seed word: the outcome is a pure function of (run, the
## fixed five cells, B3/S23, the bounded 8 x 8 board). 64 cells x 13 steps runs once
## in _ready behind the _built guard and again only when a word changes, so the
## museum's before-_ready configure and the grid's deferred echo do not double-run
## it. Built-in meshes only. No emission. No lights, no timers, no per-frame work.
##
## ARITHMETIC, not renders (the session that wrote this did not run Godot):
##   Predicted closest pair: paint=one vs paint=age at any run, about 20% - a lower
##   bound. The family ramp is not monotonic in luminance (0.39, 0.54, 0.65, 0.62,
##   0.59, 0.65, 0.72, 0.73, 0.58 across its eighths) against ochre's 0.62, so only
##   newborns (blue, -0.23) and two-generation columns (-0.08) move, and the pair
##   rests on the newborns: at field 8 of 16 columns, about 14 m^2 of world surface
##   over two visible faces, far over the hottest 5% of a ~26 m^2 crop. one vs birth
##   moves every column by at least 0.13 (about 27%); age vs birth at least 0.36 on
##   newborns (30%+); run pairs move columns on and off the dark board (40%+).
##   A sweep BELOW 20% on the named row means age is not being tracked (an all-blue
##   age tile means the tracker resets every step) or the board is occluded.
##
## NOT COMPILED OR CAPTURED in the session that wrote it. The lead compiles and
## captures every artifact of the pass in one boot afterwards.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# -- The board, in metres. EVERYTHING SITS ABOVE y = 0. ------------------------
# The origin is the board's centre at floor level. The board's underside is at
# y = 0 exactly, so a map token with an explicit y (where auto-grounding is
# skipped) still stands the work on the floor rather than half through it.
const BOARD_N := 8            ## cells per side
const PITCH := 0.55           ## cell pitch; a single dead cell leaves 0.70 m between columns
const BOARD_W := 4.40         ## BOARD_N * PITCH
const BOARD_T := 0.02         ## the board's thickness; the columns stand on its top
const COLUMN_W := 0.40        ## a column's width across X and Z
const H_BASE := 0.45          ## a column with no neighbour: the knee
const H_PER_NEIGHBOUR := 0.65 ## each live Moore neighbour adds this
const H_MAX := 4.35           ## six neighbours; on the board's top it reaches 4.37
const ANCHOR_H := BOARD_T + H_MAX ## the unseen box that pins the AABB across values: 4.37, the board plus the tallest column
const ROUGHNESS := 0.55       ## one roughness for every surface, so only hue differs

# -- The plate ------------------------------------------------------------------
const PLATE_W := 0.90
const PLATE_Y := 1.20         ## reading height; text_screen's own stand default is 1.15
const PLATE_GAP := 0.001      ## between the post's +Z face plane and the frame's back
const SCREEN_BACK := 0.014    ## text_screen SCREEN: frame centred at z -0.008, 12 mm deep
const MOUNT_SIDE := 0.08      ## the dark post that holds the plate
const MOUNT_COLOR := Color(0.20, 0.22, 0.27)
const POST_COL := 2           ## the post stands over cell (7, 2), dead in every run value
const POST_Z := 1.85          ## post centre; its +Z face at 1.89 keeps the plate inside the board's 2.20
const POST_H := 1.55          ## from the board's top at 0.02 to 1.57, above the plate's top

# -- The colour vocabulary --------------------------------------------------------
## The single coat for paint `one`.
const OCHRE := Color(0.78, 0.60, 0.30)
## `birth`: newborn YELLOW, survivor BLUE - chroma_stack's constants, 0.40 apart in luminance.
const BLUE := Color(0.16, 0.36, 0.80)
const YELLOW := Color(0.92, 0.78, 0.18)
## The age ramp: HSV hue from 0.62 (blue) at birth to 0.08 (orange) at nine
## generations, at one saturation and one value so only the hue carries the number.
const RAMP_H0 := 0.62
const RAMP_H1 := 0.08
const RAMP_S := 0.75
const RAMP_V := 0.85
const RAMP_SPAN := 8.0        ## t = (age - 1) / RAMP_SPAN: age 1 is blue, age 9 is orange

# -- THE AXES ---------------------------------------------------------------------
## How long the rule has run. `seed` is the default: the five cells laid flat.
@export_enum("seed", "crowd", "field") var run: String = "seed"
## What the colour records. `one` is the default: a coat.
@export_enum("one", "age", "birth") var paint: String = "one"

## The allow-lists, same spelling and same order as the @export_enum lines above.
## An unknown word warns and falls back to the DEFAULT, never to an empty board.
const RUNS: PackedStringArray = ["seed", "crowd", "field"]
const PAINTS: PackedStringArray = ["one", "age", "birth"]
const DEFAULT_RUN := "seed"
const DEFAULT_PAINT := "one"
## Generations per run word. Words, never numbers, on the map token: a numeric
## value would be numericised by the sweep and refused by the typed property.
const GENERATIONS: Dictionary = {"seed": 0, "crowd": 8, "field": 13}

## The start: Conway's R-pentomino as [row, column] on the 8 x 8 board, row 0
## north, column 0 west. EXACTLY these five cells in EXACTLY this orientation; a
## one-cell or one-orientation slip silently changes every tile.
const R_PENTOMINO: Array = [[3, 5], [3, 6], [4, 4], [4, 5], [5, 5]]

## One honest sentence per run and per paint, for the plate. The counts are exact
## for this start and were confirmed by simulation before they were written.
const RUN_BODY: Dictionary = {
	"seed": "Five cells, the ones Conway called R, stood as columns: the crowd around each is its height.",
	"crowd": "Eight generations from the seed, eighteen columns: the crowd around each is its height.",
	"field": "Thirteen generations from the seed, sixteen columns and the streets the rule emptied.",
}
const PAINT_BODY: Dictionary = {
	"one": "One ochre: the paint knows nothing of the run.",
	"age": "Blue was born this generation; orange has stood since the seed.",
	"birth": "Yellow was born this generation; blue survived the last.",
}
## The age sentence is TRUE only under crowd: at seed every column is newborn, and at
## field the oldest column is five generations old, which the ramp paints green, not
## orange (review finding L3, 2026-09-17). One sentence per run, so the plate never
## names a colour the board does not carry.
const AGE_BODY: Dictionary = {
	"seed": "All five are newborn: blue. Nothing has had time to age.",
	"crowd": "Blue was born this generation; orange has stood since the seed.",
	"field": "Blue was born this generation; the greenest column has stood five.",
}

## True once _ready has built once. apply_grid_config before that only stores.
var _built: bool = false


func _ready() -> void:
	# The museum stamps config_* metadata on the root BEFORE it enters the tree,
	# and the grid calls apply_grid_config call_deferred, AFTER this. So the meta
	# read happens here, before a single mesh is made.
	_read_meta_overrides()
	_build()
	_built = true


# -- the build ------------------------------------------------------------------

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var generations: int = int(GENERATIONS.get(run, GENERATIONS[DEFAULT_RUN]))
	var ages: PackedInt32Array = _run_life(generations)

	var body := StaticBody3D.new()
	body.name = "Body"

	# The board: a dark 2 cm lip the body walks on. One box, one shape.
	var board := BoxMesh.new()
	board.size = Vector3(BOARD_W, BOARD_T, BOARD_W)
	var board_pos := Vector3(0.0, BOARD_T * 0.5, 0.0)
	_add_mesh(board, board_pos, MOUNT_COLOR, "Board")
	_add_box_shape(body, board_pos, board.size)

	# One column per live cell, as tall as the crowd around it on THIS generation,
	# painted by what `paint` records. The body gets one box per column from the
	# same numbers as the mesh.
	for r in range(BOARD_N):
		for c in range(BOARD_N):
			var age: int = ages[_index(r, c)]
			if age <= 0:
				continue
			var n: int = _neighbours(ages, r, c)
			var h: float = _column_height(n)
			var pos := Vector3(_cell_x(c), BOARD_T + h * 0.5, _cell_z(r))
			var column := BoxMesh.new()
			column.size = Vector3(COLUMN_W, h, COLUMN_W)
			_add_mesh(column, pos, _paint_for(age), "Column_%d_%d" % [r, c])
			_add_box_shape(body, pos, column.size)

	_add_anchor()
	_add_plate(body)
	add_child(body)


# -- the rule -------------------------------------------------------------------

## B3/S23 from the fixed start for `generations` steps on the bounded board. The
## returned array holds one int per cell: 0 dead, otherwise the cell's AGE (1 at
## birth, +1 per survived generation), so age is bookkeeping of the run itself and
## never a reading of the last frame.
func _run_life(generations: int) -> PackedInt32Array:
	var ages := PackedInt32Array()
	ages.resize(BOARD_N * BOARD_N)
	ages.fill(0)
	for cell in R_PENTOMINO:
		ages[_index(int(cell[0]), int(cell[1]))] = 1
	for _g in range(generations):
		ages = _step(ages)
	return ages


## One generation. Outside the board every cell is dead and stays dead.
func _step(ages: PackedInt32Array) -> PackedInt32Array:
	var next := PackedInt32Array()
	next.resize(BOARD_N * BOARD_N)
	next.fill(0)
	for r in range(BOARD_N):
		for c in range(BOARD_N):
			var n: int = _neighbours(ages, r, c)
			var age: int = ages[_index(r, c)]
			if age > 0:
				if n == 2 or n == 3:
					next[_index(r, c)] = age + 1
			elif n == 3:
				next[_index(r, c)] = 1
	return next


## Live Moore neighbours of (r, c); cells off the board count as dead.
func _neighbours(ages: PackedInt32Array, r: int, c: int) -> int:
	var n: int = 0
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			if dr == 0 and dc == 0:
				continue
			var rr: int = r + dr
			var cc: int = c + dc
			if rr < 0 or rr >= BOARD_N or cc < 0 or cc >= BOARD_N:
				continue
			if ages[_index(rr, cc)] > 0:
				n += 1
	return n


func _index(r: int, c: int) -> int:
	return r * BOARD_N + c


# -- the geometry ---------------------------------------------------------------

## h = min(4.35, 0.45 + 0.65 n): knee, hip, eye, over the head, 3.05, 3.70, 4.35.
func _column_height(n: int) -> float:
	return minf(H_MAX, H_BASE + H_PER_NEIGHBOUR * float(n))


## Column c's centre along X: column 0 is west, column 7 east.
func _cell_x(c: int) -> float:
	return (float(c) - float(BOARD_N - 1) * 0.5) * PITCH


## Row r's centre along Z: row 0 is north (-Z), row 7 south, where the plate is.
func _cell_z(r: int) -> float:
	return (float(r) - float(BOARD_N - 1) * 0.5) * PITCH


## MeshInstance3D + StandardMaterial3D through the surface override, not
## material_override. Matte, no metal, no emission: only the hue differs.
func _add_mesh(mesh: Mesh, pos: Vector3, c: Color, node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.0
	m.roughness = ROUGHNESS
	mi.set_surface_override_material(0, m)
	mi.position = pos
	add_child(mi)
	return mi


func _add_box_shape(body: StaticBody3D, pos: Vector3, size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = pos
	body.add_child(shape)


## The anchor: a MeshInstance3D no camera draws (layers = 0, no light sees it
## either, and cast_shadow is OFF besides) sized exactly to the union of every
## value - 4.40 x 4.37 x 4.40, the board's 0.02 plus a six-neighbour column's
## 4.35 - so the capture's AABB, which counts MeshInstance3D only, is the same
## for seed, crowd and field. It has no collider: it is not a thing the body
## meets.
func _add_anchor() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Anchor"
	var box := BoxMesh.new()
	box.size = Vector3(BOARD_W, ANCHOR_H, BOARD_W)
	mi.mesh = box
	mi.layers = 0
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0.0, ANCHOR_H * 0.5, 0.0)
	add_child(mi)


## The plate: text_screen.gd and nothing else, since it is the one text lane that
## renders in a capture. SCREEN mode (0) is the framed face alone - no floor post,
## no recline. The board has no face at reading height, so a dark post stands on
## the board over the dead cell (7, 2) and the plate's back sits in the plane of
## the post's +Z face at reading height. Nothing is turned about Y: the face
## presents to +Z, south, inside the board's own edge.
func _add_plate(body: StaticBody3D) -> void:
	var post_x: float = _cell_x(POST_COL)
	var post := BoxMesh.new()
	post.size = Vector3(MOUNT_SIDE, POST_H, MOUNT_SIDE)
	var post_pos := Vector3(post_x, BOARD_T + POST_H * 0.5, POST_Z)
	_add_mesh(post, post_pos, MOUNT_COLOR, "PlatePost")
	_add_box_shape(body, post_pos, post.size)

	var back_z: float = POST_Z + MOUNT_SIDE * 0.5 + PLATE_GAP
	var screen := TextScreenScript.new()
	screen.name = "Plate"
	screen.mode = 0
	screen.width_m = PLATE_W
	screen.title = _plate_title()
	screen.body = _plate_body()
	screen.position = Vector3(post_x, PLATE_Y, back_z + SCREEN_BACK)
	add_child(screen)

	# The plate is 0.936 x 0.594 m of visible object standing off the post; a
	# visitor should not put a hand through it.
	var plate_h: float = PLATE_W * 0.62 + 0.036
	_add_box_shape(body, Vector3(post_x, PLATE_Y, back_z + 0.010),
		Vector3(PLATE_W + 0.036, plate_h, 0.020))


## "CROWD <middle dot> AGE": the two words in force, in caps, joined by U+00B7 (written as an escape so the source stays ASCII).
func _plate_title() -> String:
	return "%s \u00b7 %s" % [run.to_upper(), paint.to_upper()]


## The run's sentence, then the paint's.
func _plate_body() -> String:
	var run_line: String = str(RUN_BODY.get(run, RUN_BODY[DEFAULT_RUN]))
	var paint_line: String = str(PAINT_BODY.get(paint, PAINT_BODY[DEFAULT_PAINT]))
	if paint == "age":
		paint_line = str(AGE_BODY.get(run, AGE_BODY[DEFAULT_RUN]))
	return run_line + " " + paint_line


# -- the paints -----------------------------------------------------------------

## One colour per column from `paint` and the column's age, and nothing else.
func _paint_for(age: int) -> Color:
	match paint:
		"one":
			return OCHRE
		"age":
			return _ramp((float(age) - 1.0) / RAMP_SPAN)
		"birth":
			return YELLOW if age == 1 else BLUE
	return OCHRE


## The ramp is a property of TIME here: t = 0 is a newborn (blue), t = 1 is nine
## generations (orange). Same constants and same direction as chroma_stack's
## by_height, so the family reads one way: older, like higher, is warmer.
func _ramp(t: float) -> Color:
	var hue: float = lerpf(RAMP_H0, RAMP_H1, clampf(t, 0.0, 1.0))
	return Color.from_hsv(hue, RAMP_S, RAMP_V, 1.0)


# -- DNA plumbing -----------------------------------------------------------------

## Per-cell configuration, read from config_* metadata. Keys honoured:
##
##   #run:<seed|crowd|field>     how many generations the rule has run (0 / 8 / 13)
##   #paint:<one|age|birth>      what the colour records
##
## Both values are WORDS, so neither key needs to sit in CONFIG_PARAM_NAMES: only a
## `#key:<number>` on an unlisted key is eaten as the tutorial's rotation shorthand.
## An unknown word warns and falls back to the default.
func _read_meta_overrides() -> void:
	run = _axis_word("config_run", RUNS, run, DEFAULT_RUN, "run")
	paint = _axis_word("config_paint", PAINTS, paint, DEFAULT_PAINT, "paint")


func _axis_word(meta_key: String, allowed: PackedStringArray, current: String,
		fallback: String, axis: String) -> String:
	if not has_meta(meta_key):
		return current
	var v: String = str(get_meta(meta_key)).strip_edges().to_lower()
	if v == "":
		return current
	if allowed.has(v):
		return v
	push_warning("chroma_life: unknown %s '%s' - using '%s'" % [axis, v, fallback])
	return fallback


## The grid's hook. Every key is stored as config_<key> metadata and re-read, so a
## value set here and a value stamped by the museum before _ready take the same
## path. Before the first build this only stores; after it, it rebuilds ONLY when
## one of the two words actually changed - curation_station's blanket
## apply_grid_config({"emissive": false}) must not re-run the rule.
func apply_grid_config(config: Dictionary) -> void:
	var run_before: String = run
	var paint_before: String = paint
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	if not _built:
		return
	if run == run_before and paint == paint_before:
		return
	_build()
