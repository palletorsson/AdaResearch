extends Node3D
## ONE VALUE / TWO BODIES, TO WALK (floor Noise_One; the Void, 2026-11-12)
##
## The noise torus is a ring left out in a field: one value for each point, spent once as height and once as
## colour. Its stand puts the two spendings on two small rings on a bench. Here the ring is the bench ring's top
## face sixteen times larger, lying on the slab round shaft B, so the shaft is the hole of the torus and a body
## walks the ring. On the south half the value is HEIGHT: the floor swells and sinks as the field slides through,
## and a body standing still is lifted and set down. On the north half the same value is LIGHT on a flat floor.
## At the two seams a swell arrives as a glow.
##
## THE SAME FIELD, NOT A COPY OF IT. The mesh is built in the bench ring's own units and scaled, and it wears the
## torus's own shader, so a point of this ring samples exactly what the same point of the bench ring samples.
## Where the stand of two rings is on the same floor the walk takes its clock, amplitude, grain and remap from it:
## FREEZE on the console holds the floor under your feet.
##
## BELOW ZERO. A negative value cannot lower a slab. The south half lies just under the slab's top, so only what
## is above zero shows and carries: the floor clips the relief the way the colour reading clips to black.
##
## COST. The picture is the shader. The ground a body stands on is a small triangle mesh re-read from the same
## function on the CPU, and only while a body is on the ring.
const SHADER := preload("res://commons/resourses/shaders/noiseTorus.gdshader")
const K := 16.25                 # metres of this ring to one unit of the bench ring (centreline 0.32 -> 5.2 m)
const R_IN := 4.4                # clear of the shaft's corners (4.24 m)
const R_OUT := 6.0
const EDGE := 0.35               # the relief fades to nothing over this at the two rims
const SEAM := 0.8                # and over this before a seam
const UNDER := 0.03              # the relief half rests this far under the slab's top
const RADIAL := 6                # lines of the ground mesh across the track
const ROUND := 48                # and segments along a half

@export_enum("halves", "relief", "colour", "both") var split := "halves"
@export var amplitude := 0.02    ## in the bench ring's units (its own default); times K in metres
@export var frequency := 14.0    ## cells to one unit of the bench ring (its own default)
@export var speed := 0.935       ## cells a second (the torus's shipped noise_speed)
@export var hue_speed := 0.03    ## the bench cycles the rainbow every 1.4 s; a floor this size does not
@export var hold := false        ## a stopped clock (standing alone)
@export var start_time := 0.0
@export var collide := true
@export var board_east := true   ## the board stands outside the ring to the east (the arrival side of shaft A), else west

var _time := 0.0
var _off := 0.0
var _remap := false
var _pair: Node = null
var _seek := 0.0
var _mats: Array = []            # one ShaderMaterial a half: [south, north]
var _relief: Array = [true, false]
var _colour: Array = [false, true]
var _shapes: Array = [null, null]        # ConcavePolygonShape3D a relief half
var _grid: Array = [null, null]          # {sx, sz, w, x, z, map, faces}
var _cache := {}
var _inside := {}
var _board: Label3D
var _tick := 0
var _stale := true
var _read := 0.0
var _spent_usec := 0
var _frames := 0


func _ready() -> void:
	for key in ["split", "hold", "time", "collide", "hue_speed", "board"]:
		if has_meta("config_" + key): apply_grid_config({key: get_meta("config_" + key)})
	_time = start_time
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	var again := false
	if config_data.has("split") and str(config_data["split"]) in ["halves", "relief", "colour", "both"] and str(config_data["split"]) != split:
		split = str(config_data["split"]); again = true
	if config_data.has("hold"): hold = str(config_data["hold"]).to_lower() in ["true", "1", "yes"]
	if config_data.has("time"): start_time = float(config_data["time"]); _time = start_time
	if config_data.has("collide"): collide = str(config_data["collide"]).to_lower() in ["true", "1", "yes"]; again = true
	if config_data.has("hue_speed"): hue_speed = float(config_data["hue_speed"])
	if config_data.has("board") and (str(config_data["board"]) == "east") != board_east: board_east = not board_east; again = true
	if again and is_inside_tree() and not _mats.is_empty(): _build()


## How much of the relief a point keeps: nothing at the rims, and nothing at a seam the relief ends on.
func _weight(r: float, along: float, ends: bool) -> float:
	var w: float = smoothstep(0.0, EDGE, r - R_IN) * smoothstep(0.0, EDGE, R_OUT - r)
	if ends: w *= smoothstep(0.0, SEAM, 5.2 * minf(along, PI - along))
	return w


func _build() -> void:
	for child in get_children(): child.queue_free()
	_mats.clear()
	_inside.clear()
	_relief = [split in ["halves", "relief", "both"], split in ["relief", "both"]]
	_colour = [split in ["colour", "both"], split in ["halves", "colour", "both"]]
	var ends: bool = _relief[0] != _relief[1]
	var ring := Node3D.new()
	ring.name = "Ring"
	ring.scale = Vector3.ONE * K
	add_child(ring)
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	add_child(ground)
	for half in 2:
		var mat := ShaderMaterial.new()
		mat.shader = SHADER
		mat.set_shader_parameter("elongation_factor", 1.0)
		mat.set_shader_parameter("pair_field", true)
		mat.set_shader_parameter("walk_surface", true)
		mat.set_shader_parameter("show_relief", 1.0 if _relief[half] else 0.0)
		mat.set_shader_parameter("show_colour", 1.0 if _colour[half] else 0.0)
		mat.set_shader_parameter("plain_albedo", Vector3(0.98, 0.68, 0.76))
		_mats.append(mat)
		# the picture: a polar grid in the bench ring's units
		var rows := 12
		var cols := 150
		var verts := PackedVector3Array()
		var normals := PackedVector3Array()
		var colours := PackedColorArray()
		var index := PackedInt32Array()
		var y: float = (-UNDER if _relief[half] else 0.012) / K
		for j in cols + 1:
			var along: float = PI * float(j) / float(cols)
			var angle: float = along + (PI if half == 1 else 0.0)
			for i in rows + 1:
				var r: float = lerpf(R_IN, R_OUT, float(i) / float(rows))
				verts.append(Vector3(cos(angle) * r / K, y, sin(angle) * r / K))
				normals.append(Vector3.UP)
				var w: float = _weight(r, along, ends)
				colours.append(Color(w, w, w, 1.0))
		for j in cols:
			for i in rows:
				var a: int = j * (rows + 1) + i
				var b: int = a + rows + 1
				index.append_array(PackedInt32Array([a, b, a + 1, a + 1, b, b + 1]))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colours
		arrays[Mesh.ARRAY_INDEX] = index
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.custom_aabb = AABB(Vector3(-0.38, -0.01, -0.38), Vector3(0.76, 0.07, 0.76))      # the shader lifts it
		var body := MeshInstance3D.new()
		body.name = "South" if half == 0 else "North"
		body.mesh = mesh
		body.material_override = mat
		ring.add_child(body)
		# the ground a body stands on: the same function, read on a coarser grid
		_shapes[half] = null
		_grid[half] = null
		if _relief[half] and collide:
			var g := {"sx": PackedFloat32Array(), "sz": PackedFloat32Array(), "w": PackedFloat32Array(), "x": PackedFloat32Array(), "z": PackedFloat32Array(), "map": PackedInt32Array()}
			for j in ROUND + 1:
				var along: float = PI * float(j) / float(ROUND)
				var angle: float = along + (PI if half == 1 else 0.0)
				for i in RADIAL:
					var r: float = lerpf(R_IN, R_OUT, float(i) / float(RADIAL - 1))
					g.x.append(cos(angle) * r); g.z.append(sin(angle) * r)
					g.sx.append(cos(angle) * r / K); g.sz.append(sin(angle) * r / K)
					g.w.append(_weight(r, along, ends))
			for j in ROUND:
				for i in RADIAL - 1:
					var a: int = j * RADIAL + i
					var b: int = a + RADIAL
					g.map.append_array(PackedInt32Array([a, b, a + 1, a + 1, b, b + 1]))
			var faces := PackedVector3Array()
			faces.resize(g.map.size())
			g["faces"] = faces
			_grid[half] = g
			var shape := ConcavePolygonShape3D.new()
			shape.backface_collision = true
			_shapes[half] = shape
			var holder := CollisionShape3D.new()
			holder.name = "Ground_%d" % half
			holder.shape = shape
			ground.add_child(holder)
	# who is on the ring
	var zone := Area3D.new()
	zone.name = "Zone"
	zone.collision_layer = 0
	zone.collision_mask = 0xFFFFFFFF          # the tower's walker is on a layer of its own
	var round := CylinderShape3D.new()
	round.radius = R_OUT + 0.6
	round.height = 3.0
	var zone_shape := CollisionShape3D.new()
	zone_shape.shape = round
	zone_shape.position.y = 1.5
	zone.add_child(zone_shape)
	zone.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _inside[b] = true; _stale = true)
	zone.body_exited.connect(func(b: Node) -> void: _inside.erase(b))
	add_child(zone)
	# the two seams, and what the ring says
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.96, 0.96, 0.98)
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var line := BoxMesh.new()
	line.size = Vector3(R_OUT - R_IN, 0.012, 0.05)
	for side in [-1.0, 1.0]:
		var mark := MeshInstance3D.new()
		mark.mesh = line
		mark.material_override = white
		mark.position = Vector3(side * (R_IN + R_OUT) / 2.0, 0.02, 0)
		add_child(mark)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	var stand := Node3D.new()
	stand.name = "Board"
	stand.position = Vector3(6.5 if board_east else -6.5, 0, 2.4)
	stand.rotation.y = 0.57 if board_east else -0.57
	add_child(stand)
	var panel := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(1.9, 1.05, 0.06)
	panel.mesh = slab
	panel.material_override = dark
	panel.position.y = 1.25
	stand.add_child(panel)
	var post := MeshInstance3D.new()
	var leg := BoxMesh.new()
	leg.size = Vector3(0.12, 0.75, 0.06)
	post.mesh = leg
	post.material_override = dark
	post.position.y = 0.375
	stand.add_child(post)
	_board = Label3D.new()
	_board.pixel_size = 0.0022
	_board.font_size = 30
	_board.line_spacing = 2.0
	_board.modulate = Color(0.88, 0.94, 1.0)
	_board.outline_size = 4
	_board.outline_modulate = Color(0, 0, 0, 1)
	_board.width = 800
	_board.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_board.position = Vector3(0, 1.25, 0.035)
	stand.add_child(_board)
	_cache.clear()
	_stale = true
	_push()
	_write()


## The stand of two rings on this floor, if there is one: its console runs the walk too.
func _find_pair() -> Node:
	var mount := get_parent()
	var host: Node = mount.get_parent() if mount != null else null
	if host == null: return null
	for other in host.get_children():
		if other == mount: continue
		var work := other.get_node_or_null("Artifact")
		if work is Node3D and work.has_method("field_value") and str(work.get("stand")) == "pair" and absf((work as Node3D).global_position.y - global_position.y) < 1.5:
			return work
	return null


## The clock and the settings to the two materials.
func _push() -> void:
	_off = fmod(_time, 3600.0) * speed
	for mat in _mats:
		var m: ShaderMaterial = mat
		m.set_shader_parameter("local_time", _time)
		m.set_shader_parameter("noise_scale", frequency)
		m.set_shader_parameter("height_multiplier", amplitude)
		m.set_shader_parameter("noise_speed", speed)
		m.set_shader_parameter("hue_shift_speed", hue_speed)
		m.set_shader_parameter("remap_signed", _remap)


func _lattice(ix: int, iz: int) -> float:
	var key: int = (ix << 32) | (iz & 0xffffffff)
	var kept = _cache.get(key)
	if kept != null: return kept
	# the torus's own integer hash (noisetorus.gd _hash2, noiseTorus.gdshader pair_hash)
	var h: int = ((ix & 0xffffffff) ^ (((iz & 0xffffffff) * 0x45d9f3b) & 0xffffffff))
	h = (((h >> 16) ^ h) * 0x45d9f3b) & 0xffffffff
	h = (((h >> 16) ^ h) * 0x45d9f3b) & 0xffffffff
	h = (h >> 16) ^ h
	var value: float = -1.0 + 2.0 * float(h & 65535) / 65535.0
	if _cache.size() > 6000: _cache.clear()
	_cache[key] = value
	return value


## The field at a point given in the bench ring's units, now.
func value_at(sx: float, sz: float) -> float:
	var px: float = sx * frequency + _off
	var pz: float = sz * frequency + _off
	var ix: int = floori(px)
	var iz: int = floori(pz)
	var fx: float = px - float(ix)
	var fz: float = pz - float(iz)
	var ux: float = fx * fx * (3.0 - 2.0 * fx)
	var uz: float = fz * fz * (3.0 - 2.0 * fz)
	return lerpf(lerpf(_lattice(ix, iz), _lattice(ix + 1, iz), ux), lerpf(_lattice(ix, iz + 1), _lattice(ix + 1, iz + 1), ux), uz)


## What a point of the ring is, in metres from the work's origin: {on, half, value, height, light}.
func read_at(x: float, z: float) -> Dictionary:
	var r: float = Vector2(x, z).length()
	if r < R_IN or r > R_OUT: return {"on": false}
	var angle: float = fposmod(atan2(z, x), TAU)
	var half: int = 0 if angle < PI else 1
	var along: float = angle - (PI if half == 1 else 0.0)
	var v: float = value_at(x / K, z / K)
	var lift: float = maxf(0.0, _weight(r, along, _relief[0] != _relief[1]) * amplitude * K * v - UNDER) if _relief[half] else 0.0
	var light: float = ((v + 1.0) * 0.5 if _remap else maxf(v, 0.0)) if _colour[half] else 0.0
	return {"on": true, "half": half, "value": v, "height": lift, "light": light, "relief": _relief[half], "colour": _colour[half]}


func _ground() -> void:
	for half in 2:
		var g = _grid[half]
		if g == null: continue
		var count: int = g.x.size()
		var top := PackedFloat32Array()
		top.resize(count)
		var gain: float = amplitude * K
		for i in count:
			top[i] = maxf(0.0, g.w[i] * gain * value_at(g.sx[i], g.sz[i]) - UNDER) - 0.015
		var faces: PackedVector3Array = g.faces
		var map: PackedInt32Array = g.map
		for i in map.size():
			var at: int = map[i]
			faces[i] = Vector3(g.x[at], top[at], g.z[at])
		(_shapes[half] as ConcavePolygonShape3D).set_faces(faces)


func _write() -> void:
	if _board == null: return
	var lines := PackedStringArray(["ONE VALUE / TWO BODIES", "The ring on the bench, laid flat round the shaft.",
		"South half: the value is height under you. North half: the same value is light.", ""])
	var body: Node3D = null
	for b in _inside: if is_instance_valid(b): body = b
	var got := {"on": false}
	if body != null:
		var here: Vector3 = to_local(body.global_position)
		got = read_at(here.x, here.z)
	if got.on:
		var spent: String = "lifts you %.2f m" % float(got.height) if got.relief else "lights the floor %d %%" % roundi(float(got.light) * 100.0)
		if got.relief and got.colour: spent += " and lights it %d %%" % roundi(float(got.light) * 100.0)
		lines.append("UNDER YOU  %+.2f  %s" % [float(got.value), spent])
	else:
		lines.append("Step onto the ring.")
	lines.append("%s the console on the bench." % ("Run by" if _pair != null else "Alone: no stand of two rings is on this floor, so not run by"))
	_board.text = "\n".join(lines)


func _process(delta: float) -> void:
	var began := Time.get_ticks_usec()
	_seek -= delta
	if _seek <= 0.0 and (_pair == null or not is_instance_valid(_pair)):
		_seek = 1.0
		_pair = _find_pair()
	var was_time := _time
	var was := [amplitude, frequency, speed, _remap]
	if _pair != null and is_instance_valid(_pair):
		_time = float(_pair.get("_pair_time"))
		amplitude = float(_pair.PAIR_AMPS[int(_pair.get("_amp_i"))])
		frequency = float(_pair.PAIR_FREQS[int(_pair.get("_freq_i"))])
		speed = float(_pair.noise_speed)
		_remap = bool(_pair.get("_remap"))
	else:
		_pair = null
		if not hold: _time += delta
	if _time != was_time or was != [amplitude, frequency, speed, _remap]:
		_push()
		_stale = true
	_read -= delta
	if _read <= 0.0:
		_read = 0.2
		_write()
	_spent_usec += Time.get_ticks_usec() - began
	_frames += 1


func _physics_process(_delta: float) -> void:
	_tick += 1
	if not _stale or _inside.is_empty() or _tick % 2 != 0: return
	var began := Time.get_ticks_usec()
	_ground()
	_stale = false
	_spent_usec += Time.get_ticks_usec() - began


## ---- for a test ----

func following() -> bool:
	return _pair != null and is_instance_valid(_pair)


func pair() -> Node:
	return _pair


func bodies() -> int:
	return _inside.size()


## Mean cost of one frame of this work, milliseconds, since the last call.
func frame_ms() -> float:
	var ms := float(_spent_usec) / 1000.0 / maxf(1.0, float(_frames))
	_spent_usec = 0
	_frames = 0
	return ms
