extends Node3D
## NINE PILLARS, THREE CLOCKS (floor Noise_Columns; Palle, 2026-11-12: "we need more (9) of the pillars larger,
## more space between and up to the ceiling")
##
## The melting columns compare three clocks on three small columns: a fixed phase, a sine, a noise field. Here the
## same comparison is the hall. Nine pillars stand across the whole floor, eight metres and more apart, from the
## slab to the ceiling, three on each clock. The three on one clock move as one, so the question a body can ask by
## walking is: which three belong together, and which three ever come back to a shape they had.
##
## NOTHING NEW IS DRAWN. The shaft is the columns' own mesh function at one phase, and the phase is the columns'
## own driver (MeltingBerniniColumns.driver_phase). Where a three-column stand is on the same floor, the hall takes
## its clock, its hold, its reveal, its skin and its spin from that stand, so one console runs twelve columns.
## Standing alone it runs its own clock.
##
## UP TO THE CEILING. The mesh function lowers the top of a column as it melts. A pillar that carries a ceiling
## cannot do that, so `holds` says what gives:
##   ceiling  the shaft always spans plinth to capital; the melt shows as the body sagging inside a fixed span
##   free     the top comes away from its capital, as on the small stand
##   hung     the shaft stays on its capital and its foot leaves the plinth
##
## COST. A phase is one of `levels` meshes built once (one a frame while the floor arrives). After that a pillar
## changes by taking another mesh of the ladder: no mesh is built while the hall runs.
const Columns := preload("res://algorithms/proceduralgeneration/hybrid_complex/berninicolumns/MeltingBerniniColumns.gd")
const DRIVERS: PackedStringArray = ["baseline", "periodic", "field"]
const PLINTH := 0.4
const CAPITAL := 0.3
const BLOCK := 1.5              # plinth and capital, metres square
const HZ := 12.0                # a pillar changes at most this often, as on the small stand

@export_enum("ceiling", "free", "hung") var holds := "ceiling"
@export var ceiling := 5.64              ## clear height of the room, metres
@export var girth := 0.5                 ## shaft radius, metres
@export var seed_value := 31415          ## names the field and the deal, as on the small stand
@export var speed := 0.9                 ## the sine's speed, as on the small stand
@export var levels := 36                 ## phases the ladder holds
@export var hold := false                ## a stopped clock (standing alone)
@export var revealed := false            ## the plates name their clocks (standing alone)
@export var build_at_once := false       ## the whole ladder in _ready (a bench or a still)
## Where the nine stand, metres from the work's origin: five in a north row, four in a south row between them.
@export var places: PackedVector2Array = PackedVector2Array([
	Vector2(-17, -5.6), Vector2(-8.5, -5.6), Vector2(0, -5.6), Vector2(8.5, -5.6), Vector2(17, -5.6),
	Vector2(-12.75, 4.9), Vector2(-4.25, 3.4), Vector2(4.25, 3.4), Vector2(12.75, 4.9)])

var _gen                                   # the columns' own script, never in the tree: mesh function and drivers
var _ladder: Array[Mesh] = []
var _built := 0
var _pillars: Array = []                   # {driver, shaft, plates, level, place}
var _span := 0.0
var _drop := 0.0                           # what phase 1 takes from the top, metres
var _time := 0.0
var _next := 0.0
var _console: Node = null
var _seek := 0.0
var _live: Material
var _still: Material
var _matte: StandardMaterial3D
var _marble := true
var _shown := false
var _spent_usec := 0
var _frames := 0


func _ready() -> void:
	_read_config()
	_build()
	if build_at_once:
		while _built < levels: _build_level()
		_apply(true)


func _read_config() -> void:
	for key in ["holds", "ceiling", "girth", "seed", "speed", "hold", "places"]:
		if has_meta("config_" + key): apply_grid_config({key: get_meta("config_" + key)})


func apply_grid_config(config_data: Dictionary) -> void:
	var again := false
	if config_data.has("holds") and str(config_data["holds"]) in ["ceiling", "free", "hung"]:
		holds = str(config_data["holds"])
	if config_data.has("ceiling"): ceiling = float(config_data["ceiling"]); again = true
	if config_data.has("girth"): girth = float(config_data["girth"]); again = true
	if config_data.has("seed"): seed_value = int(config_data["seed"]); again = true
	if config_data.has("speed"): speed = float(config_data["speed"]); again = true
	if config_data.has("hold"): hold = str(config_data["hold"]).to_lower() in ["true", "1", "yes"]
	if config_data.has("places"):
		var asked := PackedVector2Array()
		for pair in str(config_data["places"]).split(";", false):
			var xz := pair.split(",")
			if xz.size() == 2: asked.append(Vector2(float(xz[0]), float(xz[1])))
		if asked.size() > 0: places = asked; again = true
	if is_inside_tree() and _gen != null:
		if again: _build()
		_apply(true)


func _exit_tree() -> void:
	if _gen != null: _gen.free(); _gen = null


## The generator: the columns' script with the small stand's settings, at this room's size.
func _prepare() -> void:
	if _gen != null: _gen.free()
	_gen = Columns.new()
	_gen.field_seed = seed_value
	_gen.melt_speed = speed
	_gen._prepare_trio()
	_gen.marble_shader = Columns.MARBLE_SHADER
	_span = ceiling - PLINTH - CAPITAL
	var k: float = _span / 10.0                               # the file's amplitudes are metres on a ten-metre column
	_gen.column_height = _span
	_gen.column_radius = girth
	_gen.vertical_segments = 64
	_gen.radial_segments = 20
	_gen.melt_strength = Columns.TRIO_MELT / Columns.TRIO_H * _span      # the small stand's drop, in proportion
	_gen._amp_scale = k
	_gen.sine_amplitude = 0.30 * k
	_gen.cosine_amplitude = 0.30 * k
	_gen.overhang_factor = 0.25 * k
	_gen.bulge_amplitude = 0.22 * k
	_gen.chaos_factor = 0.08 * k
	_gen.rib_depth = 0.14 * k
	_drop = 2.0 * float(_gen.melt_strength)


func _build() -> void:
	for child in get_children(): child.queue_free()
	_pillars.clear()
	_ladder.clear()
	_built = 0
	_prepare()
	_ladder.resize(levels)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.62, 0.60, 0.56)
	stone.roughness = 0.9
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	_live = _gen.create_shaft_material(Color(0.86, 0.84, 0.80))
	_still = _gen.create_shaft_material(Color(0.86, 0.84, 0.80))
	_matte = StandardMaterial3D.new()
	_matte.albedo_color = Color(0.80, 0.78, 0.74)
	_matte.roughness = 0.85
	# the deal: three pillars to a clock, by the one seed
	var deal: Array = []
	for i in places.size(): deal.append(DRIVERS[i % DRIVERS.size()])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 9
	for i in range(deal.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var kept = deal[i]; deal[i] = deal[j]; deal[j] = kept
	var block := BoxMesh.new()
	block.size = Vector3(BLOCK, 1.0, BLOCK)
	var strip := BoxMesh.new()
	strip.size = Vector3(1.1, 0.26, 0.02)
	var body := StaticBody3D.new()
	body.name = "Stands"
	add_child(body)
	for i in places.size():
		var root := Node3D.new()
		root.name = "Pillar_%d" % i
		root.position = Vector3(places[i].x, 0, places[i].y)
		add_child(root)
		for part in [[PLINTH, PLINTH / 2.0, "Plinth"], [CAPITAL, ceiling - CAPITAL / 2.0, "Capital"]]:
			var box := MeshInstance3D.new()
			box.name = str(part[2])
			box.mesh = block
			box.scale = Vector3(1, float(part[0]), 1)
			box.position.y = float(part[1])
			box.material_override = stone
			root.add_child(box)
		var shaft := MeshInstance3D.new()
		shaft.name = "Shaft"
		shaft.position.y = PLINTH
		root.add_child(shaft)
		var plates: Array = []
		for side in [1.0, -1.0]:                      # read from the arrival and from behind
			var plate := MeshInstance3D.new()
			plate.mesh = strip
			plate.material_override = dark
			plate.position = Vector3(0, PLINTH / 2.0, side * (BLOCK / 2.0 + 0.01))
			root.add_child(plate)
			var text := Label3D.new()
			text.text = "?"
			text.pixel_size = 0.003
			text.font_size = 56
			text.modulate = Color(0.88, 0.94, 1.0)
			text.outline_size = 6
			text.outline_modulate = Color(0, 0, 0, 1)
			text.position = Vector3(0, PLINTH / 2.0, side * (BLOCK / 2.0 + 0.025))
			text.rotation.y = 0.0 if side > 0 else PI
			root.add_child(text)
			plates.append(text)
		var stand := CollisionShape3D.new()
		var round := CylinderShape3D.new()
		round.radius = girth + 0.25
		round.height = ceiling
		stand.shape = round
		stand.position = Vector3(places[i].x, ceiling / 2.0, places[i].y)
		body.add_child(stand)
		_pillars.append({"driver": str(deal[i]), "shaft": shaft, "plates": plates, "level": -1, "place": places[i]})
	_shown = not revealed          # so the first pass writes the plates
	_name_plates(revealed)


func _build_level() -> void:
	if _built >= levels: return
	_ladder[_built] = _gen.generate_spiral_column_mesh(float(_built) / float(levels - 1))
	_built += 1


## The stand of three small columns on this floor, if there is one: its console runs the hall too.
func _find_console() -> Node:
	var mount := get_parent()
	var host: Node = mount.get_parent() if mount != null else null
	if host == null: return null
	for other in host.get_children():
		if other == mount: continue
		var work := other.get_node_or_null("Artifact")
		if work is Node3D and work.has_method("driver_phase") and str(work.get("stand")) == "trio" and absf((work as Node3D).global_position.y - global_position.y) < 1.5:
			return work
	return null


func _clock() -> float:
	return float(_console.time) if _console != null else _time


func _phase(kind: String, t: float) -> float:
	var source = _console if _console != null else _gen
	return clampf(float(source.driver_phase(kind, t)), 0.0, 1.0)


func _name_plates(on: bool) -> void:
	if on == _shown: return
	_shown = on
	for p in _pillars:
		for text in p.plates: (text as Label3D).text = str(p.driver).to_upper() if on else "?"


func _skin(marble: bool) -> void:
	_marble = marble
	for p in _pillars:
		(p.shaft as MeshInstance3D).material_override = _matte if not marble else (_still if p.driver == "baseline" else _live)


## Every pillar to the phase its clock asks for now.
func _apply(force := false) -> void:
	if _built < levels: return
	var t := _clock()
	for p in _pillars:
		var level: int = roundi(_phase(str(p.driver), t) * float(levels - 1))
		if level == int(p.level) and not force: continue
		p.level = level
		var shaft: MeshInstance3D = p.shaft
		shaft.mesh = _ladder[level]
		var lost: float = _drop * float(level) / float(levels - 1)
		shaft.scale.y = _span / (_span - lost) if holds == "ceiling" else 1.0
		shaft.position.y = PLINTH + (lost if holds == "hung" else 0.0)
	_skin(_marble)


func _process(delta: float) -> void:
	var began := Time.get_ticks_usec()
	if _built < levels:
		_build_level()
		if _built == levels: _apply(true)
	_seek -= delta
	if _seek <= 0.0 and (_console == null or not is_instance_valid(_console)):
		_seek = 1.0
		_console = _find_console()
	var held := hold
	var spin := false
	if _console != null and is_instance_valid(_console):
		held = bool(_console.get("_frozen"))
		spin = bool(_console.get("_spin_on"))
		_name_plates(bool(_console.get("_revealed")))
		if bool(_console.get("_marble_on")) != _marble: _skin(not _marble)
	else:
		_console = null
		_name_plates(revealed)
		if not held: _time += delta
	var t := _clock()
	if _live is ShaderMaterial: (_live as ShaderMaterial).set_shader_parameter("u_time", t)
	if spin:
		for p in _pillars: (p.shaft as MeshInstance3D).rotation.y += delta * 0.3
	if t >= _next or t < _next - 1.0:
		_next = t + 1.0 / HZ
		_apply()
	_spent_usec += Time.get_ticks_usec() - began
	_frames += 1


## ---- for a test ----

func ready_levels() -> int:
	return _built


func following() -> bool:
	return _console != null and is_instance_valid(_console)


func console() -> Node:
	return _console


## Each pillar: its clock, where it stands, its phase level, and the world heights of its shaft's foot and head.
func pillars() -> Array:
	var out := []
	for p in _pillars:
		var shaft: MeshInstance3D = p.shaft
		var foot := 0.0
		var head := 0.0
		if shaft.mesh != null:
			var box: AABB = shaft.global_transform * shaft.mesh.get_aabb()
			foot = box.position.y
			head = box.end.y
		out.append({"driver": p.driver, "at": to_global(Vector3(p.place.x, 0, p.place.y)), "level": p.level, "foot": foot, "head": head,
			"plate": ((p.plates[0]) as Label3D).text})
	return out


## Mean cost of one frame of this work, milliseconds, since the last call.
func frame_ms() -> float:
	var ms := float(_spent_usec) / 1000.0 / maxf(1.0, float(_frames))
	_spent_usec = 0
	_frames = 0
	return ms
