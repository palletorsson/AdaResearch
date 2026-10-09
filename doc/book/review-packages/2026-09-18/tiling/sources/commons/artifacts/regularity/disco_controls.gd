extends Node3D
## Same spatial patterns on both sides of Color; palette and clock stay separable.
const Kit = preload("res://commons/artifacts/regularity/room_tools.gd")
const PATTERNS := ["CHECKER", "ROWS", "DIAGONALS", "SNAKE"]
const PALETTES := [[Color.BLACK,Color.WHITE], [Color("172051"),Color("fc62ad")], [Color("104652"),Color("fcdb35")], [Color("512078"),Color("55f3cf")]]
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
	if running:
		elapsed += delta
		if elapsed >= interval:
			elapsed = fmod(elapsed,interval)
			step()

func cycle_pattern() -> void:
	pattern = (pattern+1)%PATTERNS.size()
	phase = 0
	paint()

func cycle_palette() -> void:
	palette = (palette+1)%PALETTES.size()
	paint()

func cycle_speed() -> void:
	interval = 0.5 if interval<0.3 else (0.25 if interval>0.75 else 1.0)
	paint()

func toggle_running() -> void:
	running = not running
	paint()

func step() -> void:
	phase += 1
	paint()

func value_at(x: int, z: int, width: int, depth: int) -> int:
	match pattern:
		0: return (x+z+phase)%2
		1: return int(z == phase%depth)
		2: return int((x+z+phase)%4 < 2)
		_:
			var index := z*width + (x if z%2==0 else width-1-x)
			return int(posmod(phase-index,width*depth)<width)

func paint() -> void:
	if not is_instance_valid(floor_node) or floor_node.multimesh == null: return
	for z in floor_node.grid_depth:
		for x in floor_node.grid_width:
			floor_node.call("_set_tile",x,z,PALETTES[palette][value_at(x,z,floor_node.grid_width,floor_node.grid_depth)])
	readout.text = "%s | step %d | %.2fs | %s" % [PATTERNS[pattern],phase,interval,"PLAY" if running else "HOLD"]
