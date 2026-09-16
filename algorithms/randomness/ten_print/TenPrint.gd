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

@export_enum("on", "off") var semicolon: String = "on"
@export_enum("clear", "scroll") var when_full: String = "clear"
@export var seed: int = -1
@export var count: int = 0
## The scene's own DirectionalLight3D (energy 1.2), kept from the standalone demo. "on" is the
## default so existing placements are unchanged; "off" hides it, for halls that stand two or
## more screens (a same-seed semicolon pair) where each copy would add a whole key light.
## A WORD value (#own_light:off): the key is not in CONFIG_PARAM_NAMES.
@export_enum("on", "off") var own_light: String = "on"

const WHEN_FULL_VALUES := ["clear", "scroll"]
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

func _ready() -> void:
	if _built:
		return
	create_grid()
	setup_materials()
	start_generation()
	_built = true
	_apply_own_light()
	_prefill()

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

func _process(delta: float) -> void:
	time += delta
	generation_timer += delta

	# Update parameters
	if seed >= 0:
		# Pinned: the indicator shows the threshold the NEXT character will be drawn against.
		probability = seeded_threshold(draw_count)
	else:
		probability = 0.5 + sin(time * 0.3) * 0.3
	generation_speed = 1.0 + sin(time * 0.2) * 2.0
	generation_interval = 0.2 / generation_speed

	# Generate maze step by step
	if generation_timer >= generation_interval:
		generation_timer = 0.0
		generate_maze_step()

	animate_ten_print()
	animate_indicators()

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

func _next_coin() -> bool:
	if seed >= 0:
		return coin_is_forward(draw_count)
	return randf() < probability

## The pinned coin for draw `index`: true prints "/". A pure function of (seed, index);
## nothing about the layout, the wipe or the clock reaches it. Meaningful for seed >= 0.
func coin_is_forward(index: int) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, index])
	return rng.randf() < seeded_threshold(index)

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


## Map token keys: #semicolon:on|off, #when_full:clear|scroll, #seed:N, #count:N.
## Safe before the tree (the museum configures first) and after _ready (the grid defers
## this call): fields are set, and only a real change to an already-built field restarts
## the stream. An empty config changes nothing.
func apply_grid_config(config: Dictionary) -> void:
	var changed := false
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
