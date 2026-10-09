extends Node3D
## Same spatial patterns on both sides of Color; palette and clock stay separable.
const Kit = preload("res://commons/artifacts/regularity/room_tools.gd")
const PATTERNS := ["CHECKER", "ROWS", "DIAGONALS", "SNAKE", "SUPER TRIANGLE"]
const TRIANGLE_MODE := 4
const TriangleSurface = preload("res://commons/artifacts/regularity/super_triangle_surface.gd")
const PALETTES := [[Color.BLACK,Color.WHITE], [Color("172051"),Color("fc62ad")], [Color("104652"),Color("fcdb35")], [Color("512078"),Color("55f3cf")]]
const PULSE_SECONDS := 0.15
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

func _ready() -> void:
	colour = str(get_meta("config_mode","mono")) == "colour"
	palette = 1 if colour else 0
	var p := Kit.panel(self,"SAME FLOOR / MORE CHOICES" if colour else "A GRID WITH A CLOCK",Vector3(0,1.2,0))
	p.add_button("PATTERN").pressed.connect(cycle_pattern)
	p.add_button("PLAY / HOLD").pressed.connect(toggle_running)
	p.add_button("ONE STEP").pressed.connect(step)
	readout = p.add_readout("FINDING FLOOR")
	var lower := Kit.panel(self,"PALETTE / TEMPO" if colour else "TEMPO",Vector3(0,0.88,-0.38))
	lower.add_button("SPEED").pressed.connect(cycle_speed)
	if colour: lower.add_button("COLOUR").pressed.connect(cycle_palette)
	_find_floor.call_deferred()

func apply_grid_config(_config: Dictionary) -> void: pass

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
				floor_node.call("_set_tile",column,z,PALETTES[palette][value_at(column,z,floor_node.grid_width,floor_node.grid_depth)])
	if running:
		elapsed += delta
		if elapsed >= interval:
			var remainder := fmod(elapsed,interval)
			step()
			elapsed = remainder
	if pattern == TRIANGLE_MODE:
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
	pattern = (pattern+1)%PATTERNS.size()
	phase = 0
	elapsed = 0.0
	triangle_motion = 0.0
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

func paint() -> void:
	if not is_instance_valid(floor_node) or floor_node.multimesh == null: return
	for z in floor_node.grid_depth:
		for x in floor_node.grid_width:
			floor_node.call("_set_tile",x,z,PALETTES[palette][value_at(x,z,floor_node.grid_width,floor_node.grid_depth)])
	_sync_triangles()
	if pattern == TRIANGLE_MODE:
		readout.text = "SUPER TRIANGLE / %s\n%.2fs | %s" % [TriangleSurface.FAMILIES[(phase / 4) % 6], interval, "PLAY" if running else "HOLD"]
	else:
		readout.text = "%s | step %d | %.2fs | %s" % [PATTERNS[pattern],phase,interval,"PLAY" if running else "HOLD"]

func _sync_triangles() -> void:
	if pattern != TRIANGLE_MODE:
		if is_instance_valid(triangle_surface): triangle_surface.visible = false
		return
	if not is_instance_valid(floor_node): return
	if not is_instance_valid(triangle_surface):
		triangle_surface = TriangleSurface.new()
		triangle_surface.receiver = floor_node
		floor_node.add_child(triangle_surface)
	triangle_surface.visible = true
	triangle_surface.update_pattern(triangle_motion, PALETTES[palette][0], PALETTES[palette][1], pulse_remaining.keys())
