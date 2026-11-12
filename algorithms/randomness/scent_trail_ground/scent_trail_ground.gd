# scent_trail_ground.gd
# A ground a body walks on that keeps two records of every step: scent, which fades and is read, and wear, which stays.
#
# @identity
# essence: every walker on the ground writes where it stands: scent(cell) += deposit, wear(cell) += visit. Scent
#   fades by the second; wear by the minute. A blue walker keeps a heading and looks three ways ahead (left, straight,
#   right); with P = attraction it steps toward the strongest scent, otherwise at random. The visitor is one more
#   walker: its feet write the same two records, and it is the only one that does not read them.
# desire: to be walked on. A body that crosses the ground sees its own line light up behind it, sees the blue
#   walkers that meet the line turn onto it, and sees the line stay on as wear after the scent has gone.
# critical_parameter: reads - what a blue walker does with the scent it senses (follow | avoid | blind). `follow`
#   gathers the walkers onto lines; `avoid` sends them where nobody has been; `blind` writes and never reads, which
#   is the random walk the earlier floors showed.
# triggers: walking on the ground writes; the WIPE plate clears both records and scatters the walkers again.
# emerges: a line the visitor walked once is kept by the walkers that found it, or lost if too few did. A ring
#   walked by the visitor can hold walkers that go round it after the visitor has left.
# needs: 12 x 10 m of clear floor [has when placed]; a body that walks [any CharacterBody3D].
# relationships: the body-scale sibling of [[pheromone_terrain]], whose console shows the same feedback from outside,
#   step by step, with visits as height. Here visits are wear, because ground that rises under a foot stops the
#   tower's walker. Kin to [[random_walk_128]] (a walk with no memory) and [[pipe_dream]] (a walker that remembers
#   for itself): here the memory is in the ground and anyone can read it.
# truth: Stigmergy is memory without a brain - the environment itself becomes the communication channel. (Carried
#   from pheromone_terrain.) What a body adds: the record you can see and the signal that is read are two things.
# lineage: MATH - Grasse's stigmergy (1959, termite building); Deneubourg's double-bridge ants (1990); Dorigo's ant
#   colony optimisation (1992); Jones's Physarum agents (2010), the same three-sensor walker. ART - Richard Long, "A
#   Line Made by Walking" (1967): a body's repeated crossing is the drawing. DESIGN - desire paths, paved after the
#   feet have chosen them. ARCHITECTURE - Frei Otto's studies of path networks that settle between many walkers.
# history: 2026-11-12, the Void. Floor Random_Pheromone showed pheromone_terrain as a 4.8 m model with a console;
#   read as code its live walk was switched off there (comparison mode) and its ground is a mesh rebuilt on every
#   step, which a 12 m field cannot carry. The channel the floor is about had no place for a body to enter it.
#   Built as flat ground: the two records live in one texture, the walkers in one batch.
# measured: 2026-11-12, bench, six seeds, 90 walkers. A body's line (11.4 m, walked once at 3 m/s): 6 % of the
#   walkers within 0.35 m of it before, 28 % two seconds after, 24 % at 20 s, 11 % at 80 s - they keep it for about
#   as long as its scent is louder than their own, then it is one line among theirs. A ring (2.5 m, walked twice):
#   65 % at 5 s, 8 % at 20 s. A ring does NOT hold them: a saturated band reads the same left, straight and right,
#   a walker goes straight, and its tangent becomes a branch the next one follows. The first version, in which a
#   diagonal looked sqrt(2) further than straight ahead, turned nobody onto a line met square on (6 % -> 11 %).
#   In the tower: 5 % -> 53 % after the Void's walker crossed three times; 25 s after it left, scent 1.64 -> 1.0
#   (the walkers' ceiling), wear 1.0, 28 % of the walkers still on the line.

extends Node3D

const Stock := preload("res://commons/artifacts/construction_site/stock.gd")

## The eight compass steps in angular order: a heading's neighbours in the list are its turns.
const COMPASS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]
const SCENT_CAP := 2.0      ## the most scent a cell holds: only a visitor's foot fills it
const ANT_CAP := 1.0        ## the most the blue walkers bring a cell to between them: a body is the louder writer
const SHADER := """
shader_type spatial;
uniform sampler2D cells : filter_nearest, repeat_disable;
uniform vec2 grid = vec2(120.0, 100.0);
uniform float now = 0.0;
uniform float scent_fade = 0.1;
uniform float wear_fade = 0.002;
uniform vec3 ground : source_color = vec3(0.1, 0.11, 0.13);
uniform vec3 worn : source_color = vec3(0.8, 0.77, 0.7);
uniform vec3 scent : source_color = vec3(1.0, 0.25, 0.7);
uniform float glow = 1.6;
uniform float walker_cap = 1.0;

// a cell holds (scent when written, when, wear when written, when): both are read forward to now
vec2 record(ivec2 p) {
	p = clamp(p, ivec2(0), ivec2(grid) - ivec2(1));
	vec4 c = texelFetch(cells, p, 0);
	return vec2(max(0.0, c.r - scent_fade * (now - c.g)), max(0.0, c.b - wear_fade * (now - c.a)));
}

void fragment() {
	vec2 g = UV * grid - vec2(0.5);
	ivec2 p = ivec2(floor(g));
	vec2 f = fract(g);
	vec2 v = mix(mix(record(p), record(p + ivec2(1, 0)), f.x), mix(record(p + ivec2(0, 1)), record(p + ivec2(1, 1)), f.x), f.y);
	float s = pow(clamp(v.x / walker_cap, 0.0, 1.0), 0.7);
	// above what the walkers can bring a cell to, only a body has written: its fresh track shows hot and cools to theirs
	float body = clamp(v.x - walker_cap, 0.0, 1.0);
	vec3 hot = mix(scent, vec3(1.0, 0.93, 0.97), body * 0.8);
	float w = smoothstep(0.0, 1.0, clamp(v.y, 0.0, 1.0));
	ALBEDO = mix(mix(ground, worn, w), hot, s * 0.8);
	EMISSION = hot * s * glow * (1.0 + body) + worn * w * 0.32 * (1.0 - s);
	ROUGHNESS = 0.92;
}
"""

## What a blue walker does with the scent it senses.
@export_enum("follow", "avoid", "blind") var reads := "follow"
@export var seed_value := 20261131
@export var width := 12.0               ## metres, east to west
@export var depth := 10.0               ## metres, north to south
@export var cell := 0.1                 ## metres: one step of a blue walker
@export_range(1, 400) var ants := 120
@export var ant_speed := 1.2            ## metres a second
@export_range(0.0, 1.0) var attraction := 0.9      ## how often a step is chosen by scent and not by chance
@export_range(1, 8) var sensor := 4     ## cells ahead a walker senses
@export var ant_scent := 0.2            ## scent a blue walker leaves a step
@export var body_scent := 2.0           ## scent a visitor's foot leaves
@export_range(1, 4) var body_reach := 2 ## cells either side of a visitor's step that are written
@export var scent_fade := 0.12          ## scent lost a second
@export var ant_wear := 0.015           ## wear a blue walker leaves a step
@export var body_wear := 0.03           ## wear a visitor's foot leaves on each cell of its track, each time it lands there
@export var wear_fade := 0.002          ## wear lost a second
@export var warmup_steps := 900         ## steps taken before anyone looks, so the ground is found in use
@export var body_writes := true
## The warm-up is spread over the first seconds so that no frame pays for it. A still photograph cannot wait: with
## this on, all of it is taken before the first frame (about a second's stall at 120 walkers).
@export var warm_at_once := false

var _w := 0
var _h := 0
var _cells := PackedFloat32Array()      # per cell: scent, when written, wear, when written
var _now := 0.0
var _rng := RandomNumberGenerator.new()
var _ax := PackedInt32Array()
var _ay := PackedInt32Array()
var _px := PackedInt32Array()           # where each walker stood a step ago: it is drawn between the two
var _py := PackedInt32Array()
var _ah := PackedInt32Array()
var _at := PackedFloat32Array()         # when each walker last stepped
var _owed := 0.0                        # walker-steps due: a frame takes its share, never the whole round at once
var _cursor := 0
var _dirty := true
var _since_upload := 1.0
var _texture: ImageTexture
var _material: ShaderMaterial
var _batch: MultiMesh
var _bodies: Array[Node3D] = []
var _body_cell := {}
var _last_wipe := -10.0
var _steps := 0
var _warm_left := 0


func _ready() -> void:
	_read_config()
	_w = maxi(8, roundi(width / cell))
	_h = maxi(8, roundi(depth / cell))
	_build_ground()
	_build_ants()
	_build_frame()
	_scatter()
	_warm_left = warmup_steps
	if warm_at_once:
		_warm(_warm_left)
	_upload()
	_place_ants()


func _read_config() -> void:
	if has_meta("config_reads") and str(get_meta("config_reads")) in ["follow", "avoid", "blind"]:
		reads = str(get_meta("config_reads"))
	for key in ["seed_value", "ants", "sensor", "warmup_steps", "body_reach"]:
		for meta in ["config_" + key, "config_seed" if key == "seed_value" else ""]:
			if meta != "" and has_meta(meta): set(key, int(str(get_meta(meta)).to_float()))
	for key in ["width", "depth", "cell", "ant_speed", "attraction", "ant_scent", "body_scent", "scent_fade", "ant_wear", "body_wear", "wear_fade"]:
		if has_meta("config_" + key): set(key, str(get_meta("config_" + key)).to_float())
	for key in ["body_writes", "warm_at_once"]:
		if has_meta("config_" + key): set(key, str(get_meta("config_" + key)).to_lower() in ["true", "1", "yes"])


func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data:
		set_meta("config_" + str(key), config_data[key])
	_read_config()
	if is_inside_tree() and _material != null:
		wipe()


func _step_time() -> float:
	return cell / maxf(.05, ant_speed)


# ---------------------------------------------------------------- the two records

func _scent(index: int) -> float:
	return maxf(0.0, _cells[index] - scent_fade * (_now - _cells[index + 1]))


func _wear(index: int) -> float:
	return maxf(0.0, _cells[index + 2] - wear_fade * (_now - _cells[index + 3]))


func _mark(i: int, j: int, scent: float, wear: float, cap: float = ANT_CAP) -> void:
	if i < 0 or j < 0 or i >= _w or j >= _h:
		return
	var index := 4 * (j * _w + i)
	var had := _scent(index)
	_cells[index] = maxf(had, minf(cap, had + scent))
	_cells[index + 1] = _now
	_cells[index + 2] = minf(1.0, _wear(index) + wear)
	_cells[index + 3] = _now
	_dirty = true


## A footprint: the cell and, at half strength, the four beside it.
func _print(i: int, j: int, scent: float, wear: float) -> void:
	_mark(i, j, scent, wear)
	_mark(i + 1, j, scent * .5, wear * .5)
	_mark(i - 1, j, scent * .5, wear * .5)
	_mark(i, j + 1, scent * .5, wear * .5)
	_mark(i, j - 1, scent * .5, wear * .5)


func _sense(i: int, j: int) -> float:
	if i < 0 or j < 0 or i >= _w or j >= _h:
		return -1.0
	return _scent(4 * (j * _w + i))


# ---------------------------------------------------------------- the blue walkers

func _scatter() -> void:
	_rng.seed = seed_value
	_ax.resize(ants); _ay.resize(ants); _px.resize(ants); _py.resize(ants); _ah.resize(ants); _at.resize(ants)
	_at.fill(_now)
	_cursor = 0
	_owed = 0.0
	for a in ants:
		_ax[a] = _rng.randi_range(2, _w - 3)
		_ay[a] = _rng.randi_range(2, _h - 3)
		_px[a] = _ax[a]
		_py[a] = _ay[a]
		_ah[a] = _rng.randi_range(0, 7)


## One step of every blue walker.
func _step() -> void:
	_steps += 1
	for a in ants:
		_step_ant(a)


## One walker's step: write where it stands, then choose among left, straight and right.
func _step_ant(a: int) -> void:
	_at[a] = _now
	var x := _ax[a]
	var y := _ay[a]
	_print(x, y, ant_scent, ant_wear)
	var heading := _ah[a]
	var chance := _rng.randf()      # both drawn at every setting: one stream, whatever the walkers do with it
	var turn := _rng.randi_range(-1, 1)
	var choice := (heading + turn + 8) % 8
	if reads != "blind" and chance < attraction:
		choice = heading      # equal readings, as on ground nobody walked, leave a walker going straight
		var best := INF if reads == "avoid" else -INF
		for t: int in [0, -1, 1]:
			var c: int = (heading + t + 8) % 8
			var d: Vector2i = COMPASS[c]
			# the three look equally far: a diagonal reaches fewer cells, or a line met square on is never turned onto
			var reach: int = sensor if c % 2 == 0 else maxi(1, roundi(sensor * .7071))
			var value := _sense(x + d.x * reach, y + d.y * reach)
			if value < 0.0:
				continue      # off the ground: nothing to read there
			if (reads == "avoid" and value < best - .0001) or (reads != "avoid" and value > best + .0001):
				best = value
				choice = c
	var step: Vector2i = COMPASS[choice]
	var nx := x + step.x
	var ny := y + step.y
	_px[a] = x
	_py[a] = y
	if nx < 0 or ny < 0 or nx >= _w or ny >= _h:
		_ah[a] = (heading + 4 + turn + 8) % 8      # the edge turns it round
		return
	_ax[a] = nx
	_ay[a] = ny
	_ah[a] = choice


func _cell_at(local: Vector3) -> Vector2i:
	return Vector2i(floori((local.x + width / 2.0) / cell), floori((local.z + depth / 2.0) / cell))


func _cell_centre(i: float, j: float) -> Vector3:
	return Vector3((i + .5) * cell - width / 2.0, 0, (j + .5) * cell - depth / 2.0)


## A visitor's feet write the same two records, along the line from where they last were.
func write_body(from_local: Vector3, to_local: Vector3) -> void:
	var a := _cell_at(from_local)
	var b := _cell_at(to_local)
	var n := maxi(1, maxi(absi(b.x - a.x), absi(b.y - a.y)))
	for k in range(1, n + 1):
		var i := roundi(lerpf(a.x, b.x, float(k) / n))
		var j := roundi(lerpf(a.y, b.y, float(k) / n))
		for dj: int in range(-body_reach, body_reach + 1):      # a body's track is wider than a walker's
			for di: int in range(-body_reach, body_reach + 1):
				var far := Vector2(di, dj).length()
				if far <= body_reach + .5:
					var share := 1.0 if far <= body_reach - .5 else .5
					_mark(i + di, j + dj, body_scent * share, body_wear * share, SCENT_CAP)


func _write_bodies() -> void:
	for body in _bodies:
		if not is_instance_valid(body):
			continue
		var local := to_local(body.global_position)
		var here := _cell_at(local)
		var key := body.get_instance_id()
		if not _body_cell.has(key):
			_body_cell[key] = local
			write_body(local, local)
		elif _cell_at(_body_cell[key]) != here:
			write_body(_body_cell[key], local)
			_body_cell[key] = local


func _warm(steps: int) -> void:
	var take := mini(steps, _warm_left)
	_warm_left -= take
	for i in take:
		_now += _step_time()
		_step()


## True while the ground is still being walked in.
func warming() -> bool:
	return _warm_left > 0


func _process(delta: float) -> void:
	if _warm_left > 0:
		_warm(6)
		_place_ants()
		_since_upload += delta
		if _since_upload >= .07:
			_upload()
		return
	_now += delta
	if body_writes:
		_write_bodies()
	_owed += ants * delta / _step_time()
	var due := mini(int(_owed), ants)      # a long frame is not paid back
	_owed = 0.0 if int(_owed) > ants else _owed - due
	for k in due:
		_step_ant(_cursor)
		_cursor = (_cursor + 1) % ants
	if _cursor < due:
		_steps += 1
	_place_ants()
	_material.set_shader_parameter("now", _now)
	_since_upload += delta
	if _dirty and _since_upload >= .07:
		_upload()


# ---------------------------------------------------------------- what is seen

func _upload() -> void:
	var image := Image.create_from_data(_w, _h, false, Image.FORMAT_RGBAF, _cells.to_byte_array())
	if _texture == null:
		_texture = ImageTexture.create_from_image(image)
		_material.set_shader_parameter("cells", _texture)
	else:
		_texture.update(image)
	_material.set_shader_parameter("now", _now)
	_dirty = false
	_since_upload = 0.0


func _build_ground() -> void:
	_cells.resize(4 * _w * _h)
	_cells.fill(0.0)
	var shader := Shader.new()
	shader.code = SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("grid", Vector2(_w, _h))
	_material.set_shader_parameter("walker_cap", ANT_CAP)
	_material.set_shader_parameter("scent_fade", scent_fade)
	_material.set_shader_parameter("wear_fade", wear_fade)
	var plane := PlaneMesh.new()
	plane.size = Vector2(width, depth)
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.material_override = _material
	ground.position.y = .012
	add_child(ground)
	var area := Area3D.new()
	area.name = "OnTheGround"
	area.collision_layer = 0
	area.collision_mask = 0xFFFFFFFF
	area.position.y = 1.1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 2.2, depth)
	shape.shape = box
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(func(body: Node) -> void:
		if body is CharacterBody3D and not _bodies.has(body): _bodies.append(body))
	area.body_exited.connect(func(body: Node) -> void:
		_bodies.erase(body)
		_body_cell.erase(body.get_instance_id()))


func _build_ants() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(.07, .06, .2)
	var blue := StandardMaterial3D.new()
	blue.albedo_color = Color("2f8bff")
	blue.emission_enabled = true
	blue.emission = Color("2f8bff")
	blue.emission_energy_multiplier = 1.2
	blue.roughness = .5
	_batch = MultiMesh.new()
	_batch.transform_format = MultiMesh.TRANSFORM_3D
	_batch.mesh = mesh
	_batch.instance_count = ants
	var instance := MultiMeshInstance3D.new()
	instance.name = "BlueWalkers"
	instance.multimesh = _batch
	instance.material_override = blue
	instance.custom_aabb = AABB(Vector3(-width / 2.0, 0, -depth / 2.0), Vector3(width, .3, depth))
	add_child(instance)


func _place_ants() -> void:
	var span := _step_time()
	for a in ants:
		var phase := clampf((_now - _at[a]) / span, 0.0, 1.0)
		var at := _cell_centre(lerpf(_px[a], _ax[a], phase), lerpf(_py[a], _ay[a], phase)) + Vector3(0, .045, 0)
		var d: Vector2i = COMPASS[_ah[a]]
		_batch.set_instance_transform(a, Transform3D(Basis(Vector3.UP, atan2(d.x, d.y)), at))


func _build_frame() -> void:
	var edge := Stock.finish("76695a", .95)
	for z in [-depth / 2.0, depth / 2.0]:
		Stock.box(self, "Edge", Vector3(0, .01, z), Vector3(width + .06, .02, .03), edge, false)
	for x in [-width / 2.0, width / 2.0]:
		Stock.box(self, "Edge", Vector3(x, .01, 0), Vector3(.03, .02, depth + .06), edge, false)
	# the board stands at the south edge, to the right of a body that comes from the spawn point
	var at := Vector3(width / 2.0 - 3.2, 1.3, depth / 2.0 + .3)
	for dx in [-.95, .95]:
		Stock.box(self, "SignPost", Vector3(at.x + dx, at.y / 2.0, at.z), Vector3(.05, at.y, .05), edge, false)
	var board := Stock.box(self, "SignBoard", at, Vector3(2.1, .52, .03), Stock.finish("d9cfbd", .9), false)
	var label := Label3D.new()
	label.text = "THE GROUND KEEPS TWO RECORDS OF YOU\npink is scent: it fades, and the blue walkers read it\npale is wear: it stays, for you to read\nwalk across, step off, and see who keeps your line"
	label.font_size = 48
	label.pixel_size = .0011
	label.outline_size = 0
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	label.modulate = Color("202329")
	label.position = Vector3(0, 0, .02)
	board.add_child(label)
	var plate_at := Vector3(-width / 2.0 + 3.6, .02, depth / 2.0 + .55)
	var plate := Stock.box(self, "Wipe", plate_at, Vector3(.8, .04, .8), Stock.finish("c8452f", .6), false)
	var words := Label3D.new()
	words.text = "WIPE"
	words.font_size = 48
	words.pixel_size = .0017
	words.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	words.modulate = Color("f3ece2")
	words.rotation.x = -PI / 2
	words.position = Vector3(0, .025, 0)
	plate.add_child(words)
	var area := Area3D.new()
	area.name = "WipeArea"
	area.collision_layer = 0
	area.collision_mask = 0xFFFFFFFF
	area.position = plate_at + Vector3(0, .5, 0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.8, 1.0, .8)
	shape.shape = box
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_stepped)


func _stepped(body: Node) -> void:
	if not body is CharacterBody3D:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_wipe < 1.5:
		return
	_last_wipe = now
	seed_value += 1
	wipe()


## Clear both records and scatter the walkers from the seed. Nothing is walked in beforehand: the ground is blank.
func wipe() -> void:
	_cells.fill(0.0)
	_material.set_shader_parameter("scent_fade", scent_fade)
	_material.set_shader_parameter("wear_fade", wear_fade)
	_body_cell.clear()
	_scatter()
	_steps = 0
	_warm_left = 0
	_dirty = true
	_upload()


# ---------------------------------------------------------------- for probes

## Advance the ground by whole steps with no frame in between.
func advance(steps: int) -> void:
	for i in steps:
		_now += _step_time()
		_step()


func scent_at(local: Vector3) -> float:
	var c := _cell_at(local)
	return maxf(0.0, _sense(c.x, c.y))


func wear_at(local: Vector3) -> float:
	var c := _cell_at(local)
	if c.x < 0 or c.y < 0 or c.x >= _w or c.y >= _h:
		return 0.0
	return _wear(4 * (c.y * _w + c.x))


## Where every blue walker stands, in the work's own metres.
func ant_places() -> Array:
	var out := []
	for a in ants:
		out.append(_cell_centre(_ax[a], _ay[a]))
	return out


## The share of all wear that lies in the most worn twentieth of the ground: 0.05 when it is even, toward 1 on lines.
func wear_share() -> float:
	var values := []
	var total := 0.0
	for index in range(0, _cells.size(), 4):
		var v := _wear(index)
		values.append(v)
		total += v
	if total <= 0.0:
		return 0.0
	values.sort()
	var top := 0.0
	for k in range(values.size() - values.size() / 20, values.size()):
		top += values[k]
	return top / total
