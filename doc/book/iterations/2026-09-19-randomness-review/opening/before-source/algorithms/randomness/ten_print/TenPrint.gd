extends Node3D

# ten_print — 10 PRINT CHR$(205.5+RND(1)); : GOTO 10, stood up as a field of diagonals.
#
# WHAT IT DID BEFORE THE EXPORTS BELOW, which is exactly what the defaults still do
# (two live placements, Ribbon_Randomness_04 and TestMap_Unused_26, carry no config):
#   - a 20 x 20 grid of small CSG spheres at a 0.4 m pitch in the XY plane, x from -4 to
#     3.6, y from 4 down to -3.6, presenting to +Z. The origin is the field's CENTRE, not
#     its base; the placements lift it.
#   - one character per tick. The tick breathes with wall-clock time:
#     generation_speed = 1 + 2 sin(0.2 t), interval = 0.2 / speed. At speed 3 that is a
#     tick every 0.067 s; near speed 0 the interval runs to infinity and the writing stalls;
#     while speed is negative the interval is negative and a tick fires on EVERY frame.
#     The timer resets to 0 on a tick, so at most one character per frame.
#   - the coin: `randf() < probability`, the global unseeded generator, with
#     probability = 0.5 + 0.3 sin(0.3 t) breathing between 0.2 and 0.8. True prints "/".
#   - row-major: column + 1, and at column 20 back to 0 on the next row.
#   - when the cursor has left row 19, the NEXT tick wipes every line, homes the cursor
#     and prints nothing; the tick after that prints at (0, 0) again.
#
# WHAT WAS ADDED (Montfort et al., 10 PRINT, chapter "Regularity"):
#   semicolon   "on"  - today's wrap. The trailing semicolon keeps PRINT on the same line,
#                       so a one-dimensional stream of coin flips is wrapped into a grid.
#               "off" - every character starts a new row at column 0: the same stream
#                       unwrapped, a single column of diagonals and no maze (p. 68).
#   when_full   "clear"  - today's wipe.
#               "scroll" - the rows move up one, the top row leaves, and printing goes on
#                          at the start of the bottom row, as on the C64 screen. The
#                          program never asks for it: the cursor advance and the scroll
#                          belong to PRINT, borrowed from the system (p. 98).
#   seed        -1 (default) - unseeded, today's global randf against the breathing
#                              probability.
#               >= 0         - pinned. Character i is a pure function of (seed, i): its
#                              uniform comes from hash([seed, i]) and its threshold from
#                              seeded_threshold(i), the same 0.2..0.8 breath counted in
#                              draws instead of seconds. Layout, when_full, the tick rate
#                              and the frame rate never reach it, so two instances with one
#                              seed print one stream and differ only in where it lands.
#   count       0 (default) - the field starts empty. N > 0 prints N characters during
#                             the build (clamped to COUNT_MAX), so a still has a field to
#                             show; the live tick carries on from there.
#
# Every key is safe as a map token: `seed` and `count` are listed in
# GridInteractablesComponent.CONFIG_PARAM_NAMES, and `semicolon` / `when_full` take WORDS
# (#semicolon:off, #when_full:scroll), which never reach the rotation shorthand.
#
# THE INTERFACE (2026-09-16, Palle: "this ten print should be an interface for a larger
# 10 print structure"). The screen is the architect's view: the program you can edit, the
# maze as Daedalus sees it (p. 84); the machine executes the pattern so the novice is freed
# to vary it (p. 78). ten_print_structure prints the same stream as a room, cell by cell.
# Three exports, every one defaulting to what the screen already did:
#   controls  "none" (default) - no panel; the two placeholder stubs (ProbabilityControl,
#                                GenerationSpeed) stand where they always stood.
#             "panel"          - the stubs are hidden and a console stands beside the field's
#                                lower right corner, where the GenerationSpeed stub stood: a
#                                RackTemplates panel of six buttons (STEP, RUN, SEMICOLON,
#                                BIAS -, BIAS +, RESEED) and a text_screen above it that shows
#                                the program as it now reads and the state.
#   channel   ""  (default) - joins no group. A WORD (#channel:hall) joins the group
#                             "ten_print_interface", which is how a ten_print_structure with
#                             the same channel IN THE SAME HALL finds this screen. The screen
#                             publishes cell_drawn / field_reset / field_scrolled from the very
#                             code paths that change its field, so a listener cannot drift.
#                             On joining, and on any later channel change, it announces itself
#                             to "ten_print_structure_listener"; an unlinked listener re-runs its
#                             own hall-scoped search, a linked one lets this screen go if its
#                             channel no longer matches (see _announce).
#   bias      -1.0 (default) - today's breathing threshold (clock-driven unseeded, draw-counted
#                              when seeded). 0..1 - a fixed probability for the forward flag.
#                              With seed >= 0 character i is still a pure function of
#                              (seed, i, bias): the uniform is hash([seed, i]), only the
#                              threshold changes.
#
# BIAS AS A TOKEN TAKES WORDS ONLY. `bias` is not in CONFIG_PARAM_NAMES, so #bias:0.3 would be
# read as the rotation shorthand (a silent 0.3 degree turn and the boolean true, which is
# refused). The words: breathing, zero, tenth, fifth, quarter, half, three_quarters,
# four_fifths, nine_tenths, one, and a percent form pNN (#bias:p30 = 0.3). A NUMBER handed to
# apply_grid_config is refused too, so the grid lane and the museum lane (which carries
# strings and has no shorthand branch) can never disagree about one token. The panel's
# BIAS buttons and set("bias", 0.3) are the numeric routes.
#
# THE CONSOLE'S STATUS SCREEN SHOWS WORDS AND NO COUNT (semicolon, bias, running or stopped,
# the channel). Every distinct line is baked into a texture that BakedTextAlbedo caches for the
# life of the process with no eviction, so a growing number on the screen would leak one texture
# per value. The exact figure is in status_line() and get_state().
#
# WHAT "BIAS" MEANS ON THE SCREEN. bias is P(forward flag), and the forward flag draws the
# line rotated +45 degrees about Z, which from the +Z side the screen presents reads as "\" -
# the Commodore's CHR$(205). So the program line on the console shows
# CHR$(K+RND(1)) with K = 206 - bias: bias 0.5 is the book's 205.5, BIAS + lowers K and the
# maze leans toward "\". That is what the one-liner would do with that constant.

signal cell_drawn(draw_index: int, row: int, col: int, forward: bool)
signal field_reset()
signal field_scrolled()

@export_enum("on", "off") var semicolon: String = "on"
@export_enum("clear", "scroll") var when_full: String = "clear"
@export var seed: int = -1
@export var count: int = 0
## The scene's own DirectionalLight3D (energy 1.2), kept from the standalone demo. "on" is the
## default so existing placements are unchanged; "off" hides it, for halls that stand two or
## more screens (a same-seed semicolon pair) where each copy would add a whole key light.
## A WORD value (#own_light:off): the key is not in CONFIG_PARAM_NAMES.
@export_enum("on", "off") var own_light: String = "on"
## "none" (default) keeps the screen as it was; "panel" builds the console. A WORD.
@export_enum("none", "panel") var controls: String = "none"
## "" (default) joins no group. A word joins "ten_print_interface" under this channel.
@export var channel: String = ""
## -1.0 (default) is the breathing threshold; 0..1 is a fixed P(forward flag).
@export var bias: float = -1.0

const WHEN_FULL_VALUES := ["clear", "scroll"]
const CONTROLS_VALUES := ["none", "panel"]
const INTERFACE_GROUP := "ten_print_interface"
## ten_print_structure instances join this group; see _announce().
const STRUCTURE_LISTENER_GROUP := "ten_print_structure_listener"
const BIAS_WORDS := {
	"breathing": -1.0, "zero": 0.0, "tenth": 0.1, "fifth": 0.2, "quarter": 0.25,
	"half": 0.5, "three_quarters": 0.75, "four_fifths": 0.8, "nine_tenths": 0.9, "one": 1.0,
}
## The two placeholder indicators the .tscn stands beside the field. Hidden under a panel.
const STUB_NAMES := ["ProbabilityControl", "GenerationSpeed"]
## The console's buttons, in RackTemplates' Btn_N order (row-major).
const BUTTON_KEYS := ["step", "run", "semicolon", "bias_minus", "bias_plus", "reseed"]
const BUTTON_LABELS := ["STEP", "RUN", "SEMICOLON", "BIAS -", "BIAS +", "RESEED"]
const RACK_TEMPLATES_PATH := "res://commons/audio/rack_templates/RackTemplates.gd"
const TEXT_SCREEN := preload("res://commons/ui/text_screen.gd")

# ── console geometry ────────────────────────────────────────────────────────────
# The field is built in FIELD units: cell centres from -4 to 3.6 in x and 4 to -3.6 in y at a
# 0.4 pitch, so its outer edges are x -4.2 .. 3.8 and y 4.2 .. -3.8, lines at z 0.1.
# Placements SCALE the node (the 10 PRINT hall: ten_print:180:1.5:0.1875), so anything built
# in field units shrinks with it. The console therefore sits under a holder whose local scale
# is 1 / s, where s is the node's world scale: everything under the holder is in METRES.
#
# ARITHMETIC at the hall's placement (lift 1.5 m, s = 0.1875, holder scale 5.333):
#   field right edge   3.8 x 0.1875 = 0.7125 m right of the node origin
#   field bottom edge  1.5 - 3.8 x 0.1875 = 0.7875 m above the floor
#   column             0.656 m wide (the status screen's frame), its left edge CONSOLE_GAP_M
#                      = 0.12 m right of the field: x 0.83 .. 1.49 m, centre 1.16 m - exactly
#                      where the GenerationSpeed stub stood (field x = +8, 1.5 m)
#   panel              RackTemplates 2 x 3 buttons is 0.236 x 0.200 m, at PANEL_SCALE 2.0
#                      0.472 x 0.400 m; centre PANEL_RISE_M = 0.31 m above the bottom edge
#                      = 1.098 m above the floor; the two button rows at +0.070 and -0.086 m
#                      from the panel centre = 1.17 m and 1.01 m (hand height)
#   button             push_button cap radius 0.030 x rack 0.55 x 2.0 = 6.6 cm across;
#                      its press area radius 0.036 x 0.55 x 2.0 = 7.9 cm across, 14.4 cm apart
#   status screen      width 0.62 m (0.656 with its bezel), height 0.384 + 0.036 m; centre
#                      0.05 m above the panel top: 1.558 m above the floor (eye height)
# WHY BESIDE AND NOT UNDER. At this lift the field's bottom edge (0.79 m) is below hand
# height, so a console at 1.0-1.2 m under the field could only stand IN FRONT of its lower
# rows, and from a standing eye 2 m back it hides about 3.5 rows - the row the scroll prints
# on. Beside the lower corner it hides nothing and still reaches hand height. The column
# moves with the field: another lift moves it by the same amount.
const FIELD_RIGHT_EDGE := 3.8
const FIELD_BOTTOM_EDGE := -3.8
const LINE_Z := 0.1
const CONSOLE_GAP_M := 0.12
const CONSOLE_Z_M := 0.02
const CONSOLE_W := 0.656
const PANEL_SCALE := 2.0
const PANEL_RISE_M := 0.31
const PANEL_H_EST := 0.40
const PANEL_Z := 0.008
const STATUS_W := 0.62
const STATUS_GAP_M := 0.05
## text_screen's frame reaches 14 mm behind its origin
const STATUS_Z := 0.016
## The status screen bakes every line into a texture that BakedTextAlbedo caches per string for
## the life of the process, with no eviction. So the SCREEN never shows a number that grows:
## a count (draw_count never resets) would add a texture for every value it ever showed, one
## per STEP press. The rendered lines come from a closed set (2 semicolon x 12 bias x 2 run
## states, one channel line); the exact figure lives in status_line() and get_state().
const STATUS_REFRESH_S := 0.5
const COUNT_MAX := 2000
## How much of the stream is kept for readback (probe, gallery). Beyond it the log stops
## growing; the field itself is unaffected.
const STREAM_LOG_CAP := 4096
## The pinned coin's breath, in draws: one full 0.2..0.8 cycle every 540 characters,
## about what the clock-driven breath spans at the live tick's average rate.
const SEEDED_BREATH := TAU / 540.0
const CHAR_FORWARD := 47   # "/"
const CHAR_BACKWARD := 92  # "\"

var time = 0.0
var grid_size = 20
var cell_size = 0.4
var probability = 0.5
var generation_timer = 0.0
var generation_interval = 0.1
var current_row = 0
var current_col = 0
var maze_lines = []
var grid_nodes = []
var generation_speed = 1.0

## Characters printed since the build (or since a config change restarted the stream).
## A wipe does not reset it: the screen is cleared, the program carries on.
var draw_count: int = 0
## The printed stream as bytes, 47 = "/" and 92 = "\", capped at STREAM_LOG_CAP.
var stream_log := PackedByteArray()
var _built := false
## The live tick (RUN). true is today's behaviour: _process prints on the breathing interval.
var running: bool = true

var _console: Node3D = null
var _status: Node3D = null
var _button_areas: Dictionary = {}
var _console_fit_scale: float = 0.0
var _status_dirty := false
var _status_timer := 0.0

func _ready() -> void:
	if _built:
		return
	create_grid()
	setup_materials()
	start_generation()
	_built = true
	_apply_own_light()
	_prefill()
	# Nothing below runs for a default placement: channel "" and controls "none".
	if channel != "":
		_apply_channel()
	if controls == "panel":
		_apply_controls()

func create_grid() -> void:
	var grid_parent = $GridNodes

	for x in range(grid_size):
		grid_nodes.append([])
		for y in range(grid_size):
			var grid_node = CSGSphere3D.new()
			grid_node.radius = 0.03
			grid_node.position = Vector3(
				-4 + x * cell_size,
				4 - y * cell_size,
				0
			)
			grid_parent.add_child(grid_node)
			grid_nodes[x].append(grid_node)

func setup_materials() -> void:
	# Grid node materials
	var grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.5, 0.5, 0.5, 0.3)
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_material.emission_enabled = true
	grid_material.emission = Color(0.1, 0.1, 0.1, 1.0)

	for row in grid_nodes:
		for node in row:
			node.material_override = grid_material

	# Probability control material
	var prob_material = StandardMaterial3D.new()
	prob_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	prob_material.emission_enabled = true
	prob_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$ProbabilityControl.material_override = prob_material

	# Generation speed material
	var speed_material = StandardMaterial3D.new()
	speed_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	speed_material.emission_enabled = true
	speed_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$GenerationSpeed.material_override = speed_material

func start_generation() -> void:
	current_row = 0
	current_col = 0

	# Clear existing maze lines
	for line in maze_lines:
		line.queue_free()
	maze_lines.clear()
	# The wipe, the restart, the reseed and the semicolon change all come through here.
	field_reset.emit()

func _process(delta: float) -> void:
	time += delta
	if running:
		generation_timer += delta

	# Update parameters
	if bias >= 0.0:
		probability = bias
	elif seed >= 0:
		# Pinned: the indicator shows the threshold the NEXT character will be drawn against.
		probability = seeded_threshold(draw_count)
	else:
		probability = 0.5 + sin(time * 0.3) * 0.3
	generation_speed = 1.0 + sin(time * 0.2) * 2.0
	generation_interval = 0.2 / generation_speed

	# Generate maze step by step
	if running and generation_timer >= generation_interval:
		generation_timer = 0.0
		generate_maze_step()

	animate_ten_print()
	animate_indicators()

	if _console != null:
		_status_timer += delta
		if _status_dirty and _status_timer >= STATUS_REFRESH_S:
			_refresh_status()

## One tick of the loop: at most one character. Deterministic given the state, so a probe
## can drive it directly with _process switched off.
func generate_maze_step() -> void:
	_step(true)

func _step(show_cursor: bool) -> void:
	if current_row >= grid_size:
		if when_full == "scroll":
			_scroll_up()
		else:
			# Reset and start over. This tick prints nothing: the wipe IS the tick.
			start_generation()
			return

	if semicolon == "off":
		current_col = 0

	# Generate line for current cell
	var use_forward_slash: bool = _next_coin()
	var drawn_col: int = current_col
	var drawn_row: int = current_row
	create_maze_line(current_col, current_row, use_forward_slash)
	if stream_log.size() < STREAM_LOG_CAP:
		stream_log.append(CHAR_FORWARD if use_forward_slash else CHAR_BACKWARD)
	draw_count += 1

	# Highlight current position
	if show_cursor:
		highlight_current_position()

	# Move to next position
	if semicolon == "off":
		# No semicolon: PRINT ends the line, so the next character starts a new row.
		current_col = 0
		current_row += 1
	else:
		current_col += 1
		if current_col >= grid_size:
			current_col = 0
			current_row += 1

	# After the cursor moved, so a listener that asks get_next_cell() in its handler is told
	# where the NEXT character lands.
	cell_drawn.emit(draw_count - 1, drawn_row, drawn_col, use_forward_slash)

func _next_coin() -> bool:
	if seed >= 0:
		return coin_is_forward(draw_count)
	# Unseeded: one global randf() per character, as always. A fixed bias only replaces the
	# threshold it is compared against.
	return randf() < (bias if bias >= 0.0 else probability)

## The pinned coin for draw `index`: true prints "/". A pure function of (seed, index, bias);
## nothing about the layout, the wipe or the clock reaches it. Meaningful for seed >= 0.
func coin_is_forward(index: int) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, index])
	return rng.randf() < threshold_at(index)

## The threshold draw `index` is compared against: the fixed bias when one is set, otherwise
## the pinned breath seeded_threshold(index).
func threshold_at(index: int) -> float:
	if bias >= 0.0:
		return bias
	return seeded_threshold(index)

## The pinned coin's bias for draw `index`: 0.5 + 0.3 sin(index * TAU / 540).
func seeded_threshold(index: int) -> float:
	return 0.5 + sin(float(index) * SEEDED_BREATH) * 0.3

## when_full "scroll": every row moves up one, the top row leaves, and the cursor goes to
## the start of the bottom row. Each line keeps the colour it was printed with.
func _scroll_up() -> void:
	var kept: Array = []
	for line in maze_lines:
		var cell: Vector2i = line.get_meta("ten_print_cell", Vector2i.ZERO)
		if cell.y <= 0:
			line.queue_free()
			continue
		cell.y -= 1
		line.set_meta("ten_print_cell", cell)
		line.position = Vector3(
			-4 + cell.x * cell_size,
			4 - cell.y * cell_size,
			0.1
		)
		kept.append(line)
	maze_lines = kept
	current_row = grid_size - 1
	current_col = 0
	field_scrolled.emit()

## `count` characters printed during the build, without the per-step cursor highlight
## (only the last one lights), so a still has a field to show.
func _prefill() -> void:
	var target: int = clampi(count, 0, COUNT_MAX)
	if target <= 0:
		return
	var guard: int = target * 2 + grid_size + 4
	while draw_count < target and guard > 0:
		_step(draw_count + 1 >= target)
		guard -= 1

## A config change after the build restarts the stream at draw 0 on an empty field.
func _restart() -> void:
	draw_count = 0
	stream_log = PackedByteArray()
	_status_dirty = true
	if not _built:
		return
	start_generation()
	_prefill()

func create_maze_line(x: int, y: int, forward_slash: bool) -> void:
	var line = CSGCylinder3D.new()
	line.radius = 0.02

	line.height = cell_size * sqrt(2)  # Diagonal length

	# Position at cell center
	var cell_center = Vector3(
		-4 + x * cell_size,
		4 - y * cell_size,
		0.1
	)
	line.position = cell_center

	# Rotate based on slash type
	if forward_slash:
		line.rotation_degrees = Vector3(0, 0, 45)  # /
	else:
		line.rotation_degrees = Vector3(0, 0, -45) # \

	# Material based on position and type
	var line_material = StandardMaterial3D.new()
	var color_intensity = (x + y) / float(grid_size * 2)

	if forward_slash:
		line_material.albedo_color = Color(
			1.0,
			0.3 + color_intensity * 0.7,
			0.3,
			1.0
		)
	else:
		line_material.albedo_color = Color(
			0.3,
			0.3 + color_intensity * 0.7,
			1.0,
			1.0
		)

	line_material.emission_enabled = true
	line_material.emission = line_material.albedo_color * 0.4
	line.material_override = line_material

	# Where it stands and which character of the stream it is, for scroll and readback.
	line.set_meta("ten_print_cell", Vector2i(x, y))
	line.set_meta("ten_print_draw", draw_count)

	$MazeLines.add_child(line)
	maze_lines.append(line)

func highlight_current_position() -> void:
	# Reset all grid nodes
	for row in grid_nodes:
		for node in row:
			node.scale = Vector3.ONE * 0.5

	# Highlight current position
	if current_row < grid_size and current_col < grid_size:
		var current_node = grid_nodes[current_col][current_row]
		current_node.scale = Vector3.ONE * 2.0

		# Update material
		var highlight_material = StandardMaterial3D.new()
		highlight_material.albedo_color = Color(1.0, 1.0, 0.2, 1.0)
		highlight_material.emission_enabled = true
		highlight_material.emission = Color(0.5, 0.5, 0.1, 1.0)
		current_node.material_override = highlight_material

func animate_ten_print() -> void:
	# Animate maze lines with wave effect
	for i in range(maze_lines.size()):
		var line = maze_lines[i]
		var wave_phase = time * 3.0 - i * 0.1
		var wave_intensity = sin(wave_phase) * 0.2 + 1.0
		line.scale = Vector3.ONE * wave_intensity

		# Update emission based on wave
		var material = line.material_override as StandardMaterial3D
		if material:
			var base_emission = material.albedo_color * 0.4
			material.emission = base_emission * wave_intensity

	# Animate grid nodes. The cursor sits on row 20 between the last character of a full
	# field and the wipe (or scroll); there is no node there, so nothing is exempt. Before
	# this guard that frame indexed grid_nodes[0][20] and raised an out-of-bounds error.
	var cursor_node = null
	if current_col < grid_size and current_row < grid_size:
		cursor_node = grid_nodes[current_col][current_row]
	for x in range(grid_nodes.size()):
		for y in range(grid_nodes[x].size()):
			var node = grid_nodes[x][y]
			if node != cursor_node:  # Don't animate current position
				var pulse = sin(time * 2.0 + x * 0.3 + y * 0.2) * 0.1 + 0.5
				node.scale = Vector3.ONE * pulse

func animate_indicators() -> void:
	# Probability control
	var prob_height = probability * 2.0 + 0.5
	$ProbabilityControl.height = prob_height
	$ProbabilityControl.position.y = -4 + prob_height/2

	# Generation speed indicator
	var speed_height = (generation_speed / 3.0) * 1.5 + 0.5
	$GenerationSpeed.size.y = speed_height
	$GenerationSpeed.position.y = -4 + speed_height/2

	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$ProbabilityControl.scale.x = pulse
	$GenerationSpeed.scale.x = pulse

	# Color changes based on probability
	var prob_material = $ProbabilityControl.material_override as StandardMaterial3D
	if prob_material:
		prob_material.albedo_color = Color(
			1.0,
			0.3 + probability * 0.7,
			0.3,
			1.0
		)
		prob_material.emission = prob_material.albedo_color * 0.5

func get_maze_pattern_info() -> String:
	var forward_count = 0
	var backward_count = 0

	for line in maze_lines:
		if line.rotation_degrees.z == 45:
			forward_count += 1
		else:
			backward_count += 1

	return "Forward: %d, Backward: %d" % [forward_count, backward_count]

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Map token keys: #semicolon:on|off, #when_full:clear|scroll, #seed:N, #count:N,
## #own_light:on|off, #controls:none|panel, #channel:<word>, #bias:<word> (see the header).
## Safe before the tree (the museum configures first) and after _ready (the grid defers
## this call): fields are set, and only a real change to an already-built field restarts
## the stream. An empty config changes nothing. A bias given by a placement describes the
## whole program, so a real bias change restarts too; the panel's BIAS buttons do not.
func apply_grid_config(config: Dictionary) -> void:
	var changed := false
	if config.has("channel"):
		var ch: String = _channel_of(config["channel"], channel)
		if ch != channel:
			channel = ch
			_apply_channel()
	if config.has("controls"):
		var cv: String = _word_of(config["controls"], CONTROLS_VALUES, controls)
		if cv != controls:
			controls = cv
			if _built:
				_apply_controls()
	if config.has("bias"):
		var b: float = _bias_of(config["bias"], bias)
		if not is_equal_approx(b, bias):
			bias = b
			changed = true
			_status_dirty = true
	if config.has("semicolon"):
		var s: String = "on" if _flag(config["semicolon"], semicolon != "off") else "off"
		if s != semicolon:
			semicolon = s
			changed = true
	if config.has("when_full"):
		var w: String = str(config["when_full"]).strip_edges().to_lower()
		if w in WHEN_FULL_VALUES and w != when_full:
			when_full = w
			changed = true
	if config.has("seed"):
		var sd: int = _int_of(config["seed"], seed)
		if sd != seed:
			seed = sd
			changed = true
	if config.has("count"):
		var c: int = clampi(_int_of(config["count"], count), 0, COUNT_MAX)
		if c != count:
			count = c
			changed = true
	if config.has("own_light"):
		own_light = "on" if _flag(config["own_light"], own_light != "off") else "off"
		if _built:
			_apply_own_light()
	if changed:
		_restart()

## Show or hide the scene's own DirectionalLight3D. Visibility only: nothing else depends on it.
func _apply_own_light() -> void:
	var light := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if light != null:
		light.visible = own_light != "off"

## A config truth value. bool("0") is true in GDScript, so words are read explicitly.
func _flag(v: Variant, fallback: bool) -> bool:
	if v is bool:
		return bool(v)
	if v is int or v is float:
		return float(v) != 0.0
	var t: String = str(v).strip_edges().to_lower()
	if t in ["on", "true", "yes", "1"]:
		return true
	if t in ["off", "false", "no", "0", "none"]:
		return false
	return fallback

func _int_of(v: Variant, fallback: int) -> int:
	if v is bool:
		return fallback
	if v is int:
		return int(v)
	if v is float:
		return int(v)
	var t: String = str(v).strip_edges()
	if t.is_valid_int():
		return t.to_int()
	return fallback

## A word from `allowed`. A bool (the shorthand misparse of an unlisted key:number) and an
## unknown word both keep the current value. "off" reads as "none" for controls.
func _word_of(v: Variant, allowed: Array, fallback: String) -> String:
	if v is bool:
		return fallback
	var t: String = str(v).strip_edges().to_lower()
	if t == "off" and allowed.has("none"):
		return "none"
	if allowed.has(t):
		return t
	return fallback

## A channel is a word. A bool is the shorthand misparse and is refused; "none"/"off" and an
## empty value mean no channel.
func _channel_of(v: Variant, fallback: String) -> String:
	if v is bool:
		return fallback
	var t: String = str(v).strip_edges()
	if t.to_lower() in ["none", "off"]:
		return ""
	return t

## A bias from a token: a word from BIAS_WORDS or pNN (percent). Numbers are refused here, a
## bool too, so both placement lanes read one token the same way (see the header).
func _bias_of(v: Variant, fallback: float) -> float:
	if v is bool or v is int or v is float:
		return fallback
	var t: String = str(v).strip_edges().to_lower()
	if BIAS_WORDS.has(t):
		return float(BIAS_WORDS[t])
	if t.length() >= 2 and t.begins_with("p") and t.substr(1).is_valid_int():
		return clampf(float(t.substr(1).to_int()) / 100.0, 0.0, 1.0)
	return fallback


# ══════════════════════════════════════════════════════════════════════════════════
# THE INTERFACE: what a listener reads, and what the console presses.
# Nothing below runs for a placement with controls "none" and channel "".
# ══════════════════════════════════════════════════════════════════════════════════

## What is on the screen now, read back from the live lines themselves:
## Vector2i(col, row) -> true for the forward flag (rotation +45 degrees about Z).
func get_field() -> Dictionary:
	var field: Dictionary = {}
	for line in maze_lines:
		if not is_instance_valid(line) or line.is_queued_for_deletion():
			continue
		var cell: Vector2i = line.get_meta("ten_print_cell", Vector2i(-1, -1))
		if cell.x < 0 or cell.y < 0:
			continue
		field[cell] = line.rotation_degrees.z > 0.0
	return field

## Columns and rows of the screen: Vector2i(cols, rows).
func get_grid_dims() -> Vector2i:
	return Vector2i(grid_size, grid_size)

## The raw cursor, Vector2i(current_col, current_row). Between the last character of a full
## field and the wipe or scroll, row equals the row count (one past the last row).
func get_cursor() -> Vector2i:
	return Vector2i(current_col, current_row)

## Where the NEXT character will land: a full field under clear wipes and prints at (0, 0),
## under scroll prints at the start of the bottom row; semicolon off always prints in column 0.
func get_next_cell() -> Vector2i:
	var col: int = current_col
	var row: int = current_row
	if row >= grid_size:
		col = 0
		row = grid_size - 1 if when_full == "scroll" else 0
	if semicolon == "off":
		col = 0
	return Vector2i(col, row)

func get_state() -> Dictionary:
	return {
		"semicolon": semicolon,
		"when_full": when_full,
		"bias": bias,
		"threshold": bias if bias >= 0.0 else probability,
		"draw_count": draw_count,
		"running": running,
		"seed": seed,
		"channel": channel,
		"controls": controls,
	}

## "semicolon on · bias 0.5 · 213 printed · running"
func status_line() -> String:
	return "semicolon %s · %s · %d printed · %s" % [semicolon, _bias_text(), draw_count,
		"running" if running else "stopped"]

## The one-liner as it now reads. K = 206 - bias, so bias 0.5 is the book's 205.5.
func program_line() -> String:
	var p: float = bias if bias >= 0.0 else 0.5
	var k: String = _hundredths_text(206.0 - p)
	return "10 PRINT CHR$(%s+RND(1))%s : GOTO 10" % [k, ";" if semicolon != "off" else ""]

func _bias_text() -> String:
	if bias < 0.0:
		return "bias breathing"
	return "bias %s" % _hundredths_text(bias, true)

## 205.5 -> "205.5", 205.75 -> "205.75", 206.0 -> "206" (or "1.0" with keep_point).
func _hundredths_text(v: float, keep_point: bool = false) -> String:
	var h: int = roundi(v * 100.0)
	var whole: int = h / 100
	var frac: int = h % 100
	if frac == 0:
		return ("%d.0" % whole) if keep_point else ("%d" % whole)
	if frac % 10 == 0:
		return "%d.%d" % [whole, frac / 10]
	return "%d.%02d" % [whole, frac]

## STEP: one character. When the tick is the wipe of a full field (when_full clear), which
## prints nothing, the press takes one more tick, so a press always prints a character.
func step_once() -> void:
	var before: int = draw_count
	generate_maze_step()
	if draw_count == before:
		generate_maze_step()
	_refresh_status()

## RUN: the live tick on or off. The animation keeps running either way.
func set_running(on: bool) -> void:
	running = on
	if not running:
		generation_timer = 0.0
	_refresh_status()

## SEMICOLON: a real change, so the stream restarts on an empty field (and prefills `count`).
func toggle_semicolon() -> void:
	apply_grid_config({"semicolon": "on" if semicolon == "off" else "off"})
	_refresh_status()

## BIAS - / BIAS +: step a fixed probability by 0.1 within 0..1. From breathing the first
## press starts at the breath's centre, 0.5. The stream is NOT restarted: the next character
## is drawn against the new threshold, so the field leans while you watch.
func nudge_bias(direction: int) -> void:
	var base: float = bias if bias >= 0.0 else 0.5
	var tenths: int = clampi(roundi(base * 10.0) + signi(direction), 0, 10)
	bias = float(tenths) / 10.0
	probability = bias
	_refresh_status()

## RESEED: a pinned seed moves on by one and the stream restarts. An unseeded screen has no
## seed to move; it restarts on a fresh global stream.
func reseed() -> void:
	if seed >= 0:
		apply_grid_config({"seed": seed + 1})
	else:
		_restart()
	_refresh_status()

func press_control(key: String) -> void:
	match key:
		"step":
			step_once()
		"run":
			set_running(not running)
		"semicolon":
			toggle_semicolon()
		"bias_minus":
			nudge_bias(-1)
		"bias_plus":
			nudge_bias(1)
		"reseed":
			reseed()

## The InteractableAreaButton for a console key (see BUTTON_KEYS), or null.
func console_button_area(key: String) -> Area3D:
	return _button_areas.get(key, null) as Area3D

func console_node() -> Node3D:
	return _console if _console != null and is_instance_valid(_console) else null

func status_screen() -> Node3D:
	return _status if _status != null and is_instance_valid(_status) else null

func _apply_channel() -> void:
	if channel != "":
		if not is_in_group(INTERFACE_GROUP):
			add_to_group(INTERFACE_GROUP)
	elif is_in_group(INTERFACE_GROUP):
		remove_from_group(INTERFACE_GROUP)
	# On arrival AND on every later change, to a new word or to none: a structure still linked
	# to this screen hears it and checks the screen's channel against its own.
	if is_inside_tree():
		call_deferred("_announce")

## Tell structures a screen has arrived or changed its channel. The museum can place a hall's
## artifacts across many frames, longer than a structure's own retry. This reaches every
## listener in the tree, which is safe ONLY because the listener ignores the caller: an unlinked
## one re-runs its own hall-scoped search (a screen in another hall is never taken from this
## call), a linked one checks only its OWN screen's channel.
func _announce() -> void:
	if not is_inside_tree():
		return
	get_tree().call_group(STRUCTURE_LISTENER_GROUP, "interface_announced", self)

func _apply_controls() -> void:
	var panel_on: bool = controls == "panel"
	for stub_name in STUB_NAMES:
		var stub := get_node_or_null(NodePath(str(stub_name))) as Node3D
		if stub != null:
			stub.visible = not panel_on
	if panel_on:
		_build_console()
	elif _console != null and is_instance_valid(_console):
		# Hidden and DISABLED: a disabled CollisionObject3D leaves the physics server, so the
		# hidden buttons cannot be pressed. Not freed: push_button awaits frames in _ready.
		_console.visible = false
		_console.process_mode = Node.PROCESS_MODE_DISABLED

func _build_console() -> void:
	if _console != null and is_instance_valid(_console):
		_console.visible = true
		_console.process_mode = Node.PROCESS_MODE_INHERIT
		_fit_console()
		_refresh_status()
		return
	var holder := Node3D.new()
	holder.name = "InterfaceConsole"
	# the console's buttons are hand targets, not the installation's footprint
	holder.set_meta("em_local_instrument", true)
	add_child(holder)
	_console = holder
	_button_areas.clear()

	var rack: GDScript = load(RACK_TEMPLATES_PATH)
	var panel_h: float = PANEL_H_EST
	if rack != null:
		var rows: Array = [[], []]
		for i in range(BUTTON_KEYS.size()):
			rows[0 if i < 3 else 1].append({"type": "button", "label": BUTTON_LABELS[i]})
		# A single space, never "": an empty title is an empty node name in older templates.
		var panel: Node3D = rack.create_panel(" ", rows)
		if panel != null:
			panel.name = "ControlPanel"
			# A blank title still builds an empty Label3D; nothing here is a Label3D.
			var blank_title: Node = panel.get_node_or_null("Title")
			if blank_title != null:
				panel.remove_child(blank_title)
				blank_title.free()
			panel.set_meta("em_local_instrument", true)
			panel.scale = Vector3.ONE * PANEL_SCALE
			panel_h = float(panel.get_meta("panel_h", PANEL_H_EST / PANEL_SCALE)) * PANEL_SCALE
			panel.position = Vector3(0.0, PANEL_RISE_M, PANEL_Z)
			holder.add_child(panel)
			for i in range(BUTTON_KEYS.size()):
				var btn: Node = panel.find_child("Btn_%d" % i, true, false)
				if btn == null:
					continue
				var area: Node = btn.get_node_or_null("InteractableAreaButton")
				if area != null and area.has_signal("button_pressed"):
					var key: String = BUTTON_KEYS[i]
					# button_pressed(button) carries ONE argument: a lambda that takes it
					area.button_pressed.connect(func(_b): press_control(key))
					_button_areas[key] = area

	var ts: Node3D = TEXT_SCREEN.new()
	ts.name = "Status"
	ts.mode = 0                          # SCREEN: a framed face, no post
	ts.width_m = STATUS_W
	ts.title = program_line()
	ts.body = _status_body()
	var status_h: float = STATUS_W * TEXT_SCREEN.ASPECT + TEXT_SCREEN.BEZEL * 2.0
	ts.position = Vector3(0.0, PANEL_RISE_M + panel_h * 0.5 + STATUS_GAP_M + status_h * 0.5, STATUS_Z)
	holder.add_child(ts)
	_status = ts

	_fit_console()
	set_notify_transform(true)
	_status_dirty = false
	_status_timer = 0.0

## The holder's scale undoes the node's world scale, so the console is built in metres, and
## its position is the field's lower right corner plus a gap in metres.
func _fit_console() -> void:
	if _console == null or not is_instance_valid(_console):
		return
	var s: float = _world_scale()
	var inv: float = 1.0 / s
	_console.scale = Vector3(inv, inv, inv)
	_console.position = Vector3(FIELD_RIGHT_EDGE, FIELD_BOTTOM_EDGE, LINE_Z) \
		+ Vector3(CONSOLE_GAP_M + CONSOLE_W * 0.5, 0.0, CONSOLE_Z_M) * inv
	_console_fit_scale = s

func _world_scale() -> float:
	var b: Basis = global_transform.basis if is_inside_tree() else transform.basis
	var sv: Vector3 = b.get_scale()
	var s: float = (absf(sv.x) + absf(sv.y) + absf(sv.z)) / 3.0
	return s if s > 0.0001 else 1.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and _console != null and is_instance_valid(_console):
		if not is_equal_approx(_world_scale(), _console_fit_scale):
			_fit_console()

## Only words from a closed set (see STATUS_REFRESH_S): no count, so no texture per value.
func _status_body() -> String:
	var lines := PackedStringArray()
	lines.append("semicolon %s · %s" % [semicolon, _bias_text()])
	if running:
		lines.append("running · RUN stops it")
	else:
		lines.append("stopped · STEP prints one")
	if channel != "":
		lines.append("the room follows: channel %s" % channel)
	return "\n".join(lines)

## Rewrite the status screen only where its text changed (each set rebuilds the screen).
func _refresh_status() -> void:
	_status_dirty = false
	_status_timer = 0.0
	if _status == null or not is_instance_valid(_status):
		return
	var t: String = program_line()
	var b: String = _status_body()
	var title_changed: bool = str(_status.get("title")) != t
	var body_changed: bool = str(_status.get("body")) != b
	if title_changed and body_changed:
		_status.call("set_text", t, b)
	elif title_changed:
		_status.set("title", t)
	elif body_changed:
		_status.set("body", b)
