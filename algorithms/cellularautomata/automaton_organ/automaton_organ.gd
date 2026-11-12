extends Node3D
## THE AUTOMATON ORGAN (floor CA_AgentsCircuits; Palle, 2026-11-12: "and then cellular automata as beats, or
## tones, harmonics?")
##
## Sixteen cells in a ring, one elementary rule, and three ways to hear a row.
##   HARMONICS  every cell owns a pipe. Pipe k is the first pipe's length divided by k (3.12 m, 1.56 m, 1.04 m ...),
##              so it sounds k times the first pipe's 55 Hz: the row is a set of partials of one tone.
##   BEATS      a row is one bar of sixteen steps. A playhead crosses it; where a cell is alive, something sounds.
##   TONES      what sounds is that cell's pipe, so a bar is a rhythm and a melody at once, both written by the rule.
## `plays` chooses: steps (the playhead, cell by cell), chord (every live pipe at the top of the bar), pulse (the
## playhead with one drum for every live cell: the beat without the pitch).
## At the end of a bar the rule makes the next row, and the old rows slide out over the floor as a carpet.
##
## THE FLOOR IS THE ROW. The carpet's first line, at the pipes' feet, is the present. Step on a pad and its cell
## flips: the rule goes on from what you left.
##
## THE RULE IS THE ROOM'S. Where a rule explorer stands on the same floor, the organ plays the rule its console is
## set to. Alone it plays `rule`.
##
## It sounds only while a body is near. Sixteen short samples are rendered once; nothing is synthesised while it plays.
const RULES := {"sierpinski": 90, "chaos": 30, "gliders": 110, "weave": 150, "traffic": 184}
const CELLS := 16
const ROWS := 8                       # the present and seven earlier rows on the floor: rule 90's whole triangle on a ring of sixteen
const PAD := 0.5
const CARPET := 0.4                   # where the carpet begins, in front of the bench
const FIRST_PIPE := 3.12              # metres: an open pipe sounding 55 Hz
const FIRST_TONE := 55.0
const RATE := 11025
const PLINTH := 0.3

@export_enum("sierpinski", "chaos", "gliders", "weave", "traffic") var rule := "sierpinski"
@export_enum("steps", "chord", "pulse") var plays := "steps"
@export var step_seconds := 0.16        ## one step of the bar
@export var always := false             ## play with nobody near (a bench or a test)
@export var render_at_once := false     ## every sample in _ready (a bench or a test)
@export var preroll := 0                ## bars the rule has already run when the work appears (a still picture needs a full carpet)
@export var loudness_db := -12.0

var _number := 90
var _row := PackedByteArray()
var _past: Array[PackedByteArray] = []
var _step := 0
var _clock := 0.0
var _bars := 0
var _pads: MultiMesh
var _pipes: Array[MeshInstance3D] = []
var _glow := PackedFloat32Array()
var _tones: Array[AudioStreamWAV] = []
var _drum: AudioStreamWAV
var _render_tone := 0                   # the sample being rendered: 0..15 the tones, 16 the drum, 17 done
var _render_at := 0
var _render_data := PackedByteArray()
var _voices: Array[AudioStreamPlayer3D] = []
var _voice := 0
var _near := {}
var _on_pad := {}                       # body -> the pad it stands on
var _explorer: Node = null
var _seek := 0.0
var _board: Label3D
var _pressed := -10.0
var _now := 0.0
var _resting := false
var _log: Array = []                    # the notes of the bar being played: [step, cell]
var _last_bar: Array = []
var _plates: Array[Vector3] = []
var _spent_usec := 0
var _frames := 0
var _sounded := 0


func _ready() -> void:
	for key in ["rule", "plays", "step_seconds", "always", "loudness_db", "render_at_once", "preroll"]:
		if has_meta("config_" + key): apply_grid_config({key: get_meta("config_" + key)})
	_number = int(RULES[rule])
	if render_at_once: _render_some(1 << 30)
	_build()
	_seed()
	_paint()
	_write()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("rule") and RULES.has(str(config_data["rule"])):
		rule = str(config_data["rule"])
		_number = int(RULES[rule])
		if is_inside_tree() and _pads != null: _seed(); _paint(); _write()
	if config_data.has("plays") and str(config_data["plays"]) in ["steps", "chord", "pulse"]: plays = str(config_data["plays"])
	if config_data.has("step_seconds"): step_seconds = maxf(0.01, float(config_data["step_seconds"]))
	if config_data.has("always"): always = str(config_data["always"]).to_lower() in ["true", "1", "yes"]
	if config_data.has("render_at_once"): render_at_once = str(config_data["render_at_once"]).to_lower() in ["true", "1", "yes"]
	if config_data.has("loudness_db"): loudness_db = float(config_data["loudness_db"])
	if config_data.has("preroll"):
		preroll = clampi(int(float(str(config_data["preroll"]))), 0, 64)
		if is_inside_tree() and _pads != null: _seed(); _paint(); _write()


## ---- the rule ----

static func next_row(row: PackedByteArray, number: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(row.size())
	var n := row.size()
	for i in n:
		var code: int = (int(row[(i + n - 1) % n]) << 2) | (int(row[i]) << 1) | int(row[(i + 1) % n])
		out[i] = (number >> code) & 1
	return out


func _seed() -> void:
	_row = PackedByteArray()
	_row.resize(CELLS)
	_row[CELLS / 2] = 1
	if rule == "traffic":
		for i in [1, 2, 5, 9, 10, 13]: _row[i] = 1          # cars on a ring: the rule only moves what is there
	_past.clear()
	_step = 0
	_clock = 0.0
	_log.clear()
	for i in preroll: _turn()


## The bar is over: the row joins the carpet and the rule makes the next one.
func _turn() -> void:
	_past.push_front(_row)
	if _past.size() > ROWS - 1: _past.resize(ROWS - 1)
	_row = next_row(_row, _number)
	var live := 0
	for v in _row: live += v
	if live == 0 or live == CELLS:      # a row with nothing left to say starts over
		_row = PackedByteArray()
		_row.resize(CELLS)
		_row[CELLS / 2] = 1


## ---- the sound, rendered once ----

## Sixteen tones and one drum, a slice a frame: a floor that arrives must not stall on its organ. Tone k is the
## pipe's own frequency, a little of its octave so the lowest are heard on small speakers, and a breath at the start.
func _render_some(budget: int) -> void:
	while budget > 0 and _render_tone <= CELLS:
		var drum: bool = _render_tone == CELLS
		var count: int = int((0.3 if drum else 0.6) * RATE)
		if _render_at == 0:
			_render_data = PackedByteArray()
			_render_data.resize(count * 2)
		var until: int = mini(count, _render_at + budget)
		budget -= until - _render_at
		var f: float = FIRST_TONE * float(_render_tone + 1)
		var level: float = 0.55 / sqrt(float(_render_tone + 1))
		for i in range(_render_at, until):
			var t: float = float(i) / RATE
			var v: float
			if drum:
				v = sin(TAU * (70.0 + 110.0 * exp(-t * 38.0)) * t) * exp(-t * 16.0) * 0.8 * minf(t / 0.002, 1.0)
			else:
				v = (sin(TAU * f * t) + 0.35 * sin(TAU * 2.0 * f * t) + 0.12 * sin(TAU * 3.0 * f * t)) * level * minf(t / 0.008, 1.0) * exp(-t * 5.0)
				if t < 0.05: v += (fposmod(sin(float(i) * 12.9898) * 43758.5453, 1.0) - 0.5) * exp(-t * 90.0) * 0.15
			_render_data.encode_s16(i * 2, clampi(int(v * 32767.0), -32768, 32767))
		_render_at = until
		if _render_at >= count:
			var audio := AudioStreamWAV.new()
			audio.format = AudioStreamWAV.FORMAT_16_BITS
			audio.mix_rate = RATE
			audio.data = _render_data
			if drum: _drum = audio
			else: _tones.append(audio)
			_render_tone += 1
			_render_at = 0


## ---- the instrument ----

func _pipe_x(k: int) -> float:
	return (float(k) - float(CELLS - 1) * 0.5) * PAD


func _build() -> void:
	for child in get_children(): child.queue_free()
	_pipes.clear()
	_voices.clear()
	_plates.clear()
	_glow = PackedFloat32Array()
	_glow.resize(CELLS)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	var bench := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(float(CELLS) * PAD + 0.3, PLINTH, 0.6)
	bench.mesh = slab
	bench.material_override = dark
	bench.position = Vector3(0, PLINTH * 0.5, 0)
	add_child(bench)
	var solid := StaticBody3D.new()
	var block := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(float(CELLS) * PAD + 0.3, 3.6, 0.6)
	block.shape = box
	block.position = Vector3(0, 1.8, 0)
	solid.add_child(block)
	add_child(solid)
	for k in CELLS:
		var tall: float = FIRST_PIPE / float(k + 1)
		var pipe := MeshInstance3D.new()
		pipe.name = "Pipe_%d" % (k + 1)
		var tube := CylinderMesh.new()
		tube.height = tall
		tube.top_radius = 0.045 + 0.11 / sqrt(float(k + 1))
		tube.bottom_radius = tube.top_radius
		tube.radial_segments = 18
		pipe.mesh = tube
		var skin := StandardMaterial3D.new()
		skin.albedo_color = Color("5bcefa").lerp(Color("f5a9b8"), float(k) / float(CELLS - 1))
		skin.metallic = 0.5
		skin.roughness = 0.35
		skin.emission_enabled = true
		skin.emission = Color(1.0, 0.95, 0.8)
		skin.emission_energy_multiplier = 0.0
		pipe.material_override = skin
		pipe.position = Vector3(_pipe_x(k), PLINTH + tall * 0.5, 0)
		add_child(pipe)
		_pipes.append(pipe)
		var mark := Label3D.new()             # the pipe's number and its tone, on the bench under it
		mark.text = "%d\n%d Hz" % [k + 1, int(FIRST_TONE) * (k + 1)]
		mark.pixel_size = 0.0019
		mark.font_size = 30
		mark.outline_size = 3
		mark.outline_modulate = Color(0, 0, 0, 1)
		mark.modulate = Color(0.82, 0.88, 0.96)
		mark.position = Vector3(_pipe_x(k), PLINTH * 0.5, 0.305)
		add_child(mark)
	# the carpet: the present at the pipes' feet, earlier rows further out
	_pads = MultiMesh.new()
	_pads.transform_format = MultiMesh.TRANSFORM_3D
	_pads.use_colors = true
	var tile := BoxMesh.new()
	tile.size = Vector3(PAD * 0.92, 0.02, PAD * 0.92)
	_pads.mesh = tile
	_pads.instance_count = CELLS * ROWS
	for r in ROWS:
		for k in CELLS:
			_pads.set_instance_transform(r * CELLS + k, Transform3D(Basis(), Vector3(_pipe_x(k), 0.012, CARPET + (float(r) + 0.5) * PAD)))
	var flat := StandardMaterial3D.new()
	flat.vertex_color_use_as_albedo = true
	flat.vertex_color_is_srgb = true
	flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var carpet := MultiMeshInstance3D.new()
	carpet.name = "Carpet"
	carpet.multimesh = _pads
	carpet.material_override = flat
	add_child(carpet)
	for i in 12:
		var voice := AudioStreamPlayer3D.new()
		voice.unit_size = 4.0
		voice.max_distance = 22.0
		voice.volume_db = loudness_db
		add_child(voice)
		_voices.append(voice)
	# who is near, and who stands on the present
	var zone := Area3D.new()
	zone.collision_layer = 0
	zone.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(float(CELLS) * PAD + 8.0, 4.0, float(ROWS) * PAD + 9.0)
	var room_shape := CollisionShape3D.new()
	room_shape.shape = room
	room_shape.position = Vector3(0, 2.0, 2.5)
	zone.add_child(room_shape)
	zone.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _near[b] = true)
	zone.body_exited.connect(func(b: Node) -> void:
		_near.erase(b); _on_pad.erase(b))
	add_child(zone)
	# the board past the short pipes; two plates at the middle of the carpet's far edge, the whole row before them
	var stand := Node3D.new()
	stand.name = "Board"
	stand.position = Vector3(float(CELLS) * PAD * 0.5 + 0.9, 0, 1.6)
	stand.rotation.y = -0.6
	add_child(stand)
	var panel := MeshInstance3D.new()
	var face := BoxMesh.new()
	face.size = Vector3(2.0, 1.15, 0.06)
	panel.mesh = face
	panel.material_override = dark
	panel.position.y = 1.3
	stand.add_child(panel)
	var post := MeshInstance3D.new()
	var leg := BoxMesh.new()
	leg.size = Vector3(0.12, 0.74, 0.06)
	post.mesh = leg
	post.material_override = dark
	post.position.y = 0.37
	stand.add_child(post)
	_board = Label3D.new()
	_board.pixel_size = 0.0022
	_board.font_size = 30
	_board.line_spacing = 2.0
	_board.modulate = Color(0.88, 0.94, 1.0)
	_board.outline_size = 4
	_board.outline_modulate = Color(0, 0, 0, 1)
	_board.width = 860
	_board.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_board.position = Vector3(0, 1.3, 0.035)
	stand.add_child(_board)
	var pad := BoxMesh.new()
	pad.size = Vector3(0.7, 0.03, 0.7)
	var press := BoxShape3D.new()
	press.size = Vector3(0.6, 1.0, 0.6)
	for entry in [["STEPS\nCHORD\nPULSE", 0], ["REST", 1]]:
		var plate := MeshInstance3D.new()
		plate.mesh = pad
		plate.material_override = dark
		plate.position = Vector3(-0.55 + float(entry[1]) * 1.1, 0.015, CARPET + float(ROWS) * PAD + 0.5)
		add_child(plate)
		var word := Label3D.new()
		word.text = str(entry[0])
		word.pixel_size = 0.003
		word.font_size = 34
		word.modulate = Color(1.0, 0.82, 0.16)
		word.rotation_degrees = Vector3(-90, 0, 0)
		word.position = plate.position + Vector3(0, 0.02, 0)
		add_child(word)
		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 0xFFFFFFFF
		var area_shape := CollisionShape3D.new()
		area_shape.shape = press
		area_shape.position.y = 0.5
		area.add_child(area_shape)
		area.position = plate.position
		_plates.append(plate.position)
		var which: int = int(entry[1])
		area.body_entered.connect(func(b: Node) -> void:
			if b is CharacterBody3D: press_plate(which))
		add_child(area)


func _paint() -> void:
	for r in ROWS:
		var row: PackedByteArray = _row if r == 0 else (_past[r - 1] if r - 1 < _past.size() else PackedByteArray())
		for k in CELLS:
			var alive: bool = row.size() == CELLS and row[k] == 1
			var tone := Color(0.07, 0.08, 0.11)
			if alive: tone = Color("f5a9b8").lerp(Color(0.35, 0.3, 0.4), float(r) / float(ROWS))
			if r == 0:
				tone = Color(1.0, 0.97, 0.9) if alive else Color(0.16, 0.17, 0.22)
				if k == _step and plays != "chord": tone = Color(1.0, 0.82, 0.16) if alive else Color(0.45, 0.38, 0.12)
			_pads.set_instance_color(r * CELLS + k, tone)


func _sound(k: int, drum := false) -> void:
	_log.append([_step, k, 1 if drum else 0])
	_glow[k] = 1.0
	if _resting or (not always and _near.is_empty()): return
	if (drum and _drum == null) or (not drum and k >= _tones.size()): return      # not rendered yet
	var voice: AudioStreamPlayer3D = _voices[_voice]
	_voice = (_voice + 1) % _voices.size()
	voice.stream = _drum if drum else _tones[k]
	voice.position = Vector3(_pipe_x(k), PLINTH + 0.4, 0.1)
	voice.volume_db = loudness_db
	voice.play()
	_sounded += 1


## One step of the bar; at the bar's end the rule makes the next row.
func tick() -> void:
	if plays == "chord":
		if _step == 0:
			for k in CELLS: if _row[k] == 1: _sound(k)
	elif _row[_step] == 1:
		_sound(_step, plays == "pulse")
	_step += 1
	if _step >= CELLS:
		_step = 0
		_bars += 1
		_last_bar = _log.duplicate()
		_log.clear()
		if _explorer != null and is_instance_valid(_explorer): _number = int(_explorer.get("rule"))
		_turn()
		_write()
	_paint()


## The rule explorer on this floor, if there is one.
func _find_explorer() -> Node:
	var mount := get_parent()
	var host: Node = mount.get_parent() if mount != null else null
	if host == null: return null
	for other in host.get_children():
		if other == mount: continue
		var work := other.get_node_or_null("Artifact")
		if work is Node3D and work.has_method("set_rule") and work.get("rule") is int and absf((work as Node3D).global_position.y - global_position.y) < 3.0:
			return work
	return null


## Plate 0: the next way of playing. Plate 1: rest.
func press_plate(which: int) -> void:
	if _now - _pressed < 1.2: return
	_pressed = _now
	if which == 0: plays = ["steps", "chord", "pulse"][(["steps", "chord", "pulse"].find(plays) + 1) % 3]
	else: _resting = not _resting
	_write()


func _write() -> void:
	if _board == null: return
	var lines := PackedStringArray(["A RULE PLAYS ITS OWN ROWS",
		"Sixteen cells, sixteen pipes: pipe k is the first pipe divided by k and sounds k times its 55 Hz.",
		"A row is a bar of sixteen steps. Step on the row at the pipes' feet and a cell flips.", "",
		"RULE %d%s  |  playing %s%s  |  bar %d" % [_number, "" if _explorer == null else " (the console's)", plays.to_upper(), "  |  RESTING" if _resting else "", _bars + 1]])
	_board.text = "\n".join(lines)


func _process(delta: float) -> void:
	var began := Time.get_ticks_usec()
	_now += delta
	if _render_tone <= CELLS: _render_some(700)
	_seek -= delta
	if _seek <= 0.0 and (_explorer == null or not is_instance_valid(_explorer)):
		_seek = 1.5
		_explorer = _find_explorer()
		if _explorer != null: _number = int(_explorer.get("rule")); _write()
	_clock += delta
	var done := 0
	while _clock >= step_seconds and done < 8:
		_clock -= step_seconds
		done += 1
		tick()
	for k in CELLS:
		if _glow[k] > 0.0:
			_glow[k] = maxf(0.0, _glow[k] - delta * 2.4)
			(_pipes[k].material_override as StandardMaterial3D).emission_energy_multiplier = _glow[k] * 2.2
	# a body on the present row flips the cell it steps onto
	for b in _near:
		if not is_instance_valid(b): continue
		var here: Vector3 = to_local((b as Node3D).global_position)
		var pad := -1
		if here.z >= CARPET and here.z < CARPET + PAD and here.y < 0.6:
			var k: int = floori(here.x / PAD + float(CELLS) * 0.5)
			if k >= 0 and k < CELLS: pad = k
		if pad != int(_on_pad.get(b, -1)):
			_on_pad[b] = pad
			if pad >= 0:
				_row[pad] = 1 - _row[pad]
				_paint()
	_spent_usec += Time.get_ticks_usec() - began
	_frames += 1


## ---- for a test ----

func row() -> PackedByteArray:
	return _row


func number() -> int:
	return _number


func bars() -> int:
	return _bars


## The notes of the last whole bar: [step, cell, 1 for the drum].
func last_bar() -> Array:
	return _last_bar


func earlier(back: int) -> PackedByteArray:
	return _past[back - 1] if back >= 1 and back <= _past.size() else PackedByteArray()


func following() -> bool:
	return _explorer != null and is_instance_valid(_explorer)


## How many of the seventeen samples are rendered.
func ready_samples() -> int:
	return _render_tone


## Cycles a second of tone k (1..16): the time between the first and the last rising zero crossing of its sample.
func tone_hz(k: int) -> float:
	var data: PackedByteArray = _tones[k - 1].data
	var first := -1.0
	var last := -1.0
	var cycles := -1
	var before := 0
	for i in range(int(RATE * 0.06), mini(int(RATE * 0.45), data.size() / 2)):
		var v: int = data.decode_s16(i * 2)
		if before < 0 and v >= 0:
			var at: float = float(i) - float(v) / float(v - before)      # where the line between the two samples crosses zero
			if first < 0.0: first = at
			last = at
			cycles += 1
		before = v
	return float(cycles) * RATE / (last - first) if cycles > 0 else 0.0


func pipe_m(k: int) -> float:
	return (_pipes[k - 1].mesh as CylinderMesh).height


func pad_centre(k: int) -> Vector3:
	return to_global(Vector3(_pipe_x(k), 0, CARPET + PAD * 0.5))


## How many notes have left a speaker.
func sounded() -> int:
	return _sounded


func plate_centre(which: int) -> Vector3:
	return to_global(_plates[which])


func frame_ms() -> float:
	var ms := float(_spent_usec) / 1000.0 / maxf(1.0, float(_frames))
	_spent_usec = 0
	_frames = 0
	return ms
