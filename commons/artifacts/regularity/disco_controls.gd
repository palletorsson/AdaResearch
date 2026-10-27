extends Node3D
## Same spatial patterns on both sides of Color; palette and clock stay separable.
const Kit = preload("res://commons/artifacts/regularity/room_tools.gd")
const PATTERNS := ["CHECKER", "ROWS", "DIAGONALS", "SNAKE", "SUPER TRIANGLE"]
const TRIANGLE_MODE := 4
const TriangleSurface = preload("res://commons/artifacts/regularity/super_triangle_surface.gd")
const PALETTES := [[Color.BLACK,Color.WHITE], [Color("172051"),Color("fc62ad")], [Color("104652"),Color("fcdb35")], [Color("512078"),Color("55f3cf")]]
const PULSE_SECONDS := 0.15
const Rules := preload("res://commons/artifacts/regularity/address_rules.gd")
## The RULES button: moving patterns from the rule thread of the spine (address_rules.gd, the
## palette floor's twenty rules; ada_encyclopedia's disco floor study). A beat enters as the console's
## own patterns let it: cycle = (rule + phase) mod n through the palette, travel = the rule at
## (x - phase, z); or a beat is a generation: an elementary rule on a ring, its history scrolling
## along the floor, and Life on a torus. Off at load (rule_mode -1), so both disco halls open as
## they did; PATTERN returns to the console's own patterns. The automata belong to a later
## sequence (cellularautomata), so RULES offers them only when the map asks: `#automata:on`
## (Palle, 2026-10-27: "we can not really use ca rules in that map but we can have them as an
## option"). Neither disco map sets it. A multi-state rule shades between the
## palette's two colours (grey levels on the black-and-white floor).
const RULE_PATTERNS := [
	["RINGS / CYCLE", "cycle", "rings", 4],
	["SPIRAL / CYCLE", "cycle", "spiral", 4],
	["PASCAL / TRAVEL", "travel", "pascal", 2],   # not xor: at 2 states xor IS the sum checkerboard, so it travelled as CHECKER
	["RULE 90", "elementary", "", 90],
	["RULE 30", "elementary", "", 30],
	["LIFE", "life", "", 0],
]
var colour := false
var floor_node: Node3D
var pattern := 0
var palette := 0
var phase := 0
var running := true
var interval := 0.5
var elapsed := 0.0
var readout: Label
var retry := 0.0
var sequencer: Node
var pulse_remaining: Dictionary = {}
var triangle_surface: MeshInstance3D
var triangle_motion := 0.0
var rule_mode := -1
var automata := false
## The automata's state, kept at _cells_phase and advanced one generation a beat (never rerun).
var _cells: Array = []
var _cells_phase := -1

func _ready() -> void:
	colour = str(get_meta("config_mode","mono")) == "colour"
	automata = str(get_meta("config_automata","off")).to_lower() in ["on","true","yes"]
	palette = 1 if colour else 0
	var p := Kit.panel(self,"SAME FLOOR / MORE CHOICES" if colour else "A GRID WITH A CLOCK",Vector3(0,1.2,0))
	p.add_button("PATTERN").pressed.connect(cycle_pattern)
	p.add_button("PLAY / HOLD").pressed.connect(toggle_running)
	p.add_button("ONE STEP").pressed.connect(step)
	p.add_button("RULES").pressed.connect(cycle_rules)
	readout = p.add_readout("FINDING FLOOR")
	var lower := Kit.panel(self,"PALETTE / TEMPO" if colour else "TEMPO",Vector3(0,0.88,-0.38))
	lower.add_button("SPEED").pressed.connect(cycle_speed)
	if colour: lower.add_button("COLOUR").pressed.connect(cycle_palette)
	_find_floor.call_deferred()

func apply_grid_config(config: Dictionary) -> void:
	if not config.has("automata"): return
	automata = str(config["automata"]).to_lower() in ["on","true","yes"]
	if rule_mode >= 0 and not _offered(rule_mode):
		rule_mode = -1
		paint()

## Whether RULES offers pattern i here: the address rules always, the automata on `#automata:on`.
func _offered(i: int) -> bool:
	return automata or not (str(RULE_PATTERNS[i][1]) in ["elementary","life"])

func _find_floor() -> void:
	for n in Kit.room_root(self).find_children("*","Node3D",true,false):
		if n.get_script() == load("res://commons/context/discofloor/StandaloneDiscoFloor.gd"):
			floor_node = n
			floor_node.set_process(false)
			floor_node.monochrome = not colour
			paint()
			return

func _process(delta: float) -> void:
	if not is_instance_valid(floor_node):
		retry += delta
		if retry > 0.5:
			retry = 0.0
			_find_floor()
		return
	# The normal floor may finish a deferred rebuild after this console is ready.
	floor_node.set_process(false)
	_bind_sequencer()
	# The floor's own animation is disabled here. Expire musical flashes even
	# while our visual clock is held, restoring its current values and palette.
	for column in pulse_remaining.keys():
		pulse_remaining[column] -= delta
		if pulse_remaining[column] <= 0.0:
			pulse_remaining.erase(column)
			for z in floor_node.grid_depth:
				floor_node.call("_set_tile",column,z,tile_colour(column,z,floor_node.grid_width,floor_node.grid_depth))
	if running:
		elapsed += delta
		if elapsed >= interval:
			var remainder := fmod(elapsed,interval)
			step()
			elapsed = remainder
	if pattern == TRIANGLE_MODE and rule_mode < 0:
		if running: triangle_motion = float(phase % 24) + elapsed / interval
		_sync_triangles()

func _bind_sequencer() -> void:
	if is_instance_valid(sequencer): return
	var bridge := floor_node.get_node_or_null("SequencerBridge")
	if bridge == null: return
	sequencer = bridge.get("step_sequencer")
	if is_instance_valid(sequencer) and not sequencer.is_connected("step_triggered",_on_musical_step):
		sequencer.connect("step_triggered",_on_musical_step)

func _on_musical_step(_track: int, step_index: int) -> void:
	if is_instance_valid(floor_node) and floor_node.is_running:
		pulse_remaining[step_index % floor_node.grid_width] = PULSE_SECONDS

func cycle_pattern() -> void:
	if rule_mode >= 0:
		# back from the rules to the console's own pattern, where it was left
		rule_mode = -1
		phase = 0
		elapsed = 0.0
		paint()
		return
	pattern = (pattern+1)%PATTERNS.size()
	phase = 0
	elapsed = 0.0
	triangle_motion = 0.0
	paint()

func cycle_rules() -> void:
	rule_mode = (rule_mode+1)%RULE_PATTERNS.size()
	while not _offered(rule_mode):
		rule_mode = (rule_mode+1)%RULE_PATTERNS.size()
	phase = 0
	elapsed = 0.0
	_cells_phase = -1
	paint()

func cycle_palette() -> void:
	palette = (palette+1)%PALETTES.size()
	paint()

func cycle_speed() -> void:
	var fraction := elapsed / interval
	interval = 0.5 if interval<0.3 else (0.25 if interval>0.75 else 1.0)
	elapsed = fraction * interval
	paint()

func toggle_running() -> void:
	running = not running
	paint()

func step() -> void:
	phase += 1
	elapsed = 0.0
	triangle_motion = float(phase % 24)
	paint()

func value_at(x: int, z: int, width: int, depth: int) -> int:
	match pattern:
		0: return (x+z+phase)%2
		1: return int(z == phase%depth)
		2: return int((x+z+phase)%4 < 2)
		TRIANGLE_MODE: return 0 # The opt-in surface carries the two-tone motif.
		_:
			var index := z*width + (x if z%2==0 else width-1-x)
			return int(posmod(phase-index,width*depth)<width)

## The state a rule pattern gives tile (x, z) at the current phase: 0 .. states-1.
func rule_state(x: int, z: int, width: int, depth: int) -> int:
	var f: Array = RULE_PATTERNS[rule_mode]
	match str(f[1]):
		"cycle":
			return (Rules.state(f[2], x, z, f[3], width) + phase) % int(f[3])
		"travel":
			return Rules.state(f[2], posmod(x - phase, width), z, f[3], width)
	_sync_cells(width, depth)
	if str(f[1]) == "life":
		return int(_cells[z][x])
	# elementary: the last `depth` generations, the newest at z = depth - 1
	var g: int = depth - 1 - z
	return int(_cells[g][x]) if g < _cells.size() else 0

func rule_states() -> int:
	var f: Array = RULE_PATTERNS[rule_mode]
	return int(f[3]) if str(f[1]) in ["cycle", "travel"] else 2

## Bring the automata to the current phase: one generation per beat from where they were, or from
## the seed when the phase went back (a new pattern, a reset). Same seeds as the lab's disco floor.
func _sync_cells(width: int, depth: int) -> void:
	var f: Array = RULE_PATTERNS[rule_mode]
	if _cells_phase > phase or _cells_phase < 0:
		_cells_phase = 0
		if str(f[1]) == "life":
			_cells = []
			for z in depth:
				var row: Array = []
				row.resize(width)
				row.fill(0)
				_cells.append(row)
			var cz: int = depth / 2 - 1
			var cx: int = width / 2 - 1
			for rc in [[0, 1], [0, 2], [1, 0], [1, 1], [2, 1]]:
				_cells[(cz + rc[0]) % depth][(cx + rc[1]) % width] = 1
		else:
			var seed_row: Array = []
			seed_row.resize(width)
			seed_row.fill(0)
			seed_row[width / 2] = 1
			_cells = [seed_row]   # newest first
	while _cells_phase < phase:
		_cells_phase += 1
		if str(f[1]) == "life":
			var next: Array = []
			for z in depth:
				var row: Array = []
				for x in width:
					var k: int = 0
					for dz in [-1, 0, 1]:
						for dx in [-1, 0, 1]:
							if dz != 0 or dx != 0:
								k += int(_cells[posmod(z + dz, depth)][posmod(x + dx, width)])
					var alive: bool = int(_cells[z][x]) == 1
					row.append(1 if (alive and (k == 2 or k == 3)) or (not alive and k == 3) else 0)
				next.append(row)
			_cells = next
		else:
			var rule: int = int(f[3])
			var p: Array = _cells[0]
			var row: Array = []
			for i in width:
				var nb: int = int(p[posmod(i - 1, width)]) * 4 + int(p[i]) * 2 + int(p[(i + 1) % width])
				row.append((rule >> nb) & 1)
			_cells.push_front(row)
			if _cells.size() > depth:
				_cells.resize(depth)

func tile_colour(x: int, z: int, width: int, depth: int) -> Color:
	if rule_mode < 0:
		return PALETTES[palette][value_at(x,z,width,depth)]
	var n: int = rule_states()
	return PALETTES[palette][0].lerp(PALETTES[palette][1], float(rule_state(x,z,width,depth)) / float(maxi(n - 1, 1)))

func paint() -> void:
	if not is_instance_valid(floor_node) or floor_node.multimesh == null: return
	for z in floor_node.grid_depth:
		for x in floor_node.grid_width:
			floor_node.call("_set_tile",x,z,tile_colour(x,z,floor_node.grid_width,floor_node.grid_depth))
	_sync_triangles()
	if rule_mode >= 0:
		readout.text = "RULES / %s
step %d | %.2fs | %s" % [RULE_PATTERNS[rule_mode][0], phase, interval, "PLAY" if running else "HOLD"]
	elif pattern == TRIANGLE_MODE:
		readout.text = "SUPER TRIANGLE / %s\n%.2fs | %s" % [TriangleSurface.FAMILIES[(phase / 4) % 6], interval, "PLAY" if running else "HOLD"]
	else:
		readout.text = "%s | step %d | %.2fs | %s" % [PATTERNS[pattern],phase,interval,"PLAY" if running else "HOLD"]

func _sync_triangles() -> void:
	if pattern != TRIANGLE_MODE or rule_mode >= 0:
		if is_instance_valid(triangle_surface): triangle_surface.visible = false
		return
	if not is_instance_valid(floor_node): return
	if not is_instance_valid(triangle_surface):
		triangle_surface = TriangleSurface.new()
		triangle_surface.receiver = floor_node
		floor_node.add_child(triangle_surface)
	triangle_surface.visible = true
	triangle_surface.update_pattern(triangle_motion, PALETTES[palette][0], PALETTES[palette][1], pulse_remaining.keys())
