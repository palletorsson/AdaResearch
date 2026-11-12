extends Node3D
## THE LAYER AT THE YELLOW LINE, AS A FLOOR (floor Noise_Voxel; the Void, 2026-11-12)
##
## The voxel block says matter is a threshold: a cell is there where the field is above the line. The block is
## looked at, and a screen beside it shows one layer of it as a picture. Here that layer is the floor over a shaft:
## 24 x 24 cells, a quarter of a metre each, exactly the shaft's six metres. A cell above the line is a cube with
## its top at the slab; a cell below the line is not there, and under it is the shaft. A body crosses on what the
## line admits. Move the line and the floor under the next step is decided again.
##
## ONE FIELD, THREE DISPLAYS. The floor is a receiver of the bench (group voxelnoise_receivers), like the block:
## it is told the seed, the scale, the line and the held cell, and asks the field through the bench's own contract
## (PerlinTerrainSculptor.contract_noise / contract_value / contract_occupied) at the same normalised places. The
## layer is the held cell's layer, the one the yellow frame marks in the block.
##
## Two plates on the slab at the west rim press the bench's own buttons: MOVE THE LINE and NEXT CELL. Alone (no
## bench on the floor) they step the floor's own line and layer.
const THRESHOLDS: Array = [-0.20, -0.10, 0.00, 0.10, 0.20]      # the bench's own five lines
const LAYERS: Array = [12, 8, 6, 17]                            # the layers of the bench's held cells
const MARGIN := 0.06

@export_enum("matter", "margin", "field") var shows := "matter"
@export var grid := 24
@export var cell := 0.25
@export var layer := 12
@export var line := 0.0
@export var seed_value := 31415
@export var noise_scale := 4.0
@export var octaves := 3

var _noise: FastNoiseLite
var _held := Vector3i(12, 12, 12)
var _there := PackedByteArray()          # 1 where the line admits the cell
var _score := PackedFloat32Array()       # field minus bias
var _cubes: MultiMesh
var _ghosts: MultiMesh
var _shape: ConcavePolygonShape3D
var _frame: MeshInstance3D
var _board: Label3D
var _bench: Node = null
var _seek := 0.0
var _inside := {}
var _read := 0.0
var _pressed := -10.0
var _now := 0.0
var _told := false
var _spent_usec := 0
var _frames := 0


func _ready() -> void:
	for key in ["shows", "layer", "line", "seed"]:
		if has_meta("config_" + key): apply_grid_config({key: get_meta("config_" + key)})
	add_to_group("voxelnoise_receivers")
	_noise = PerlinTerrainSculptor.contract_noise(seed_value, noise_scale, octaves)
	_build()
	_decide()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("shows") and str(config_data["shows"]) in ["matter", "margin", "field"]: shows = str(config_data["shows"])
	if config_data.has("layer"): layer = clampi(int(config_data["layer"]), 0, grid - 1)
	if config_data.has("line"): line = float(config_data["line"])
	if config_data.has("seed"): seed_value = int(config_data["seed"])
	if is_inside_tree() and _cubes != null:
		_noise = PerlinTerrainSculptor.contract_noise(seed_value, noise_scale, octaves)
		_decide()


## ---- the bench speaks (the same two calls the voxel block answers) ----

func _mine(payload: Dictionary) -> bool:
	var source := get_node_or_null(str(payload.get("source_path", "")))
	if source is Node3D and absf((source as Node3D).global_position.y - global_position.y) > 3.0: return false      # a bench on another floor
	if source != null: _bench = source
	return true


func apply_perlin_terrain_controls(payload: Dictionary) -> void:
	if not bool(payload.get("contract", false)) or not _mine(payload): return
	seed_value = int(payload.get("seed", seed_value))
	noise_scale = float(payload.get("noise_scale", noise_scale))
	octaves = int(payload.get("noise_octaves", octaves))
	grid = int(payload.get("grid_size", grid))
	line = clampf(float(payload.get("threshold", line)), -1.0, 1.0)
	var asked: Array = payload.get("selected_cell", [_held.x, _held.y, _held.z])
	if asked.size() == 3: _held = Vector3i(int(asked[0]), int(asked[1]), int(asked[2]))
	layer = clampi(_held.y, 0, grid - 1)
	_noise = PerlinTerrainSculptor.contract_noise(seed_value, noise_scale, octaves)
	_told = true
	if _cubes != null: _decide()


func apply_perlin_cell_selection(held: Vector3i) -> void:
	if not _told: return
	_held = held
	layer = clampi(held.y, 0, grid - 1)
	if _cubes != null: _decide()


## The bench on this floor, if it has not spoken yet: the floor may have arrived after its first word.
func _find_bench() -> Node:
	var mount := get_parent()
	var host: Node = mount.get_parent() if mount != null else null
	if host == null: return null
	for other in host.get_children():
		if other == mount: continue
		var work := other.get_node_or_null("Artifact")
		if work is Node3D and work.has_method("_build_voxelnoise_payload") and str(work.get("stand")) == "lattice" and absf((work as Node3D).global_position.y - global_position.y) < 3.0:
			return work
	return null


## ---- the floor ----

func _at(x: int, z: int) -> Vector3:
	return Vector3((float(x) - float(grid - 1) * 0.5) * cell, 0.0, (float(z) - float(grid - 1) * 0.5) * cell)


## The cell a point of the floor lies in (x, z), or (-1, -1) off it. Local metres.
func cell_at(local: Vector3) -> Vector2i:
	var x: int = floori(local.x / cell + float(grid) * 0.5)
	var z: int = floori(local.z / cell + float(grid) * 0.5)
	return Vector2i(x, z) if x >= 0 and z >= 0 and x < grid and z < grid else Vector2i(-1, -1)


func _cube_mesh() -> ArrayMesh:
	# a cube with every face's own 0..1 UV, so an edge can be drawn on each face
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var index := PackedInt32Array()
	for axis in 3:
		for side in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = side
			var a := Vector3.ZERO
			a[(axis + 1) % 3] = 1.0
			var b := Vector3.ZERO
			b[(axis + 2) % 3] = 1.0
			var start := verts.size()
			for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				verts.append((n + a * corner.x + b * corner.y) * 0.5)
				normals.append(n)
				uvs.append(corner * 0.5 + Vector2(0.5, 0.5))
			index.append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = index
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _build() -> void:
	for child in get_children(): child.queue_free()
	# the block's own look: blue glass, a pink edge. Here by each face's UV; per-instance colour tints the fill.
	var look := Shader.new()
	look.code = """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.5, 1.0);
uniform float edge_width = 0.07;
uniform float ghost = 0.0;
void fragment() {
	vec2 d = min(UV, 1.0 - UV);
	float edge = 1.0 - smoothstep(edge_width * 0.6, edge_width, min(d.x, d.y));
	vec3 fill = COLOR.rgb;
	ALBEDO = mix(fill, outline_color.rgb, edge);
	METALLIC = 0.1;
	ROUGHNESS = 0.1;
	EMISSION = outline_color.rgb * edge * 1.2 + fill * 0.15;
	if (ghost > 0.5 && edge < 0.5) { discard; }
}
"""
	var cube := _cube_mesh()
	for ghost in [false, true]:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = cube
		mm.instance_count = grid * grid
		mm.visible_instance_count = 0
		var mat := ShaderMaterial.new()
		mat.shader = look
		mat.set_shader_parameter("ghost", 1.0 if ghost else 0.0)
		if ghost: mat.set_shader_parameter("outline_color", Color(1.0, 0.82, 0.16))
		var inst := MultiMeshInstance3D.new()
		inst.name = "Ghosts" if ghost else "Cubes"
		inst.multimesh = mm
		inst.material_override = mat
		inst.custom_aabb = AABB(Vector3(-3.2, -0.4, -3.2), Vector3(6.4, 0.6, 6.4))
		add_child(inst)
		if ghost: _ghosts = mm
		else: _cubes = mm
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	_shape = ConcavePolygonShape3D.new()
	_shape.backface_collision = true
	var holder := CollisionShape3D.new()
	holder.shape = _shape
	ground.add_child(holder)
	add_child(ground)
	# the bench's held cell, as on the block
	var yellow := StandardMaterial3D.new()
	yellow.albedo_color = Color(1.0, 0.82, 0.16)
	yellow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_frame = MeshInstance3D.new()
	_frame.name = "HeldCell"
	var ring := TorusMesh.new()
	ring.inner_radius = cell * 0.62
	ring.outer_radius = cell * 0.72
	ring.rings = 4
	ring.ring_segments = 6
	_frame.mesh = ring
	_frame.material_override = yellow
	_frame.rotation.y = PI / 4.0
	add_child(_frame)
	# who is on it
	var half: float = float(grid) * cell * 0.5
	var zone := Area3D.new()
	zone.collision_layer = 0
	zone.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(half * 2.0 + 0.6, 3.0, half * 2.0 + 0.6)
	var room_shape := CollisionShape3D.new()
	room_shape.shape = room
	room_shape.position.y = 1.0
	zone.add_child(room_shape)
	zone.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _inside[b] = true)
	zone.body_exited.connect(func(b: Node) -> void: _inside.erase(b))
	add_child(zone)
	# the two plates on the slab at the west rim
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	var pad := BoxMesh.new()
	pad.size = Vector3(0.7, 0.03, 0.7)
	var press := BoxShape3D.new()
	press.size = Vector3(0.6, 1.0, 0.6)
	for entry in [["MOVE\nTHE LINE", -0.9, 0], ["NEXT\nCELL", 0.9, 1]]:
		var plate := MeshInstance3D.new()
		plate.mesh = pad
		plate.material_override = dark
		plate.position = Vector3(-half - 0.75, 0.015, float(entry[1]))
		add_child(plate)
		var word := Label3D.new()
		word.text = str(entry[0])
		word.pixel_size = 0.003
		word.font_size = 40
		word.modulate = Color(1.0, 0.82, 0.16)
		word.rotation_degrees = Vector3(-90, -90, 0)
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
		var which: int = int(entry[2])
		area.body_entered.connect(func(b: Node) -> void:
			if b is CharacterBody3D: press_plate(which))
		add_child(area)
	# what the floor says
	var stand := Node3D.new()
	stand.name = "Board"
	stand.position = Vector3(-half - 0.8, 0, -half - 0.5)
	stand.rotation.y = -PI / 4.0
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


## Ask the field for the layer and let the line decide every cell.
func _decide() -> void:
	var last: float = float(maxi(1, grid - 1))
	var v: float = float(layer) / last
	var bias: float = PerlinTerrainSculptor.contract_bias(v)
	_there.resize(grid * grid)
	_score.resize(grid * grid)
	for z in grid:
		for x in grid:
			var value: float = PerlinTerrainSculptor.contract_value(_noise, float(x) / last, v, float(z) / last)
			_score[z * grid + x] = value - bias
			_there[z * grid + x] = 1 if PerlinTerrainSculptor.contract_occupied(value, v, line) else 0
	# the cubes, and the outlines of what the next step down of the line would add
	var shown := 0
	var ghosts := 0
	var whole := shows == "field"
	for z in grid:
		for x in grid:
			var i: int = z * grid + x
			var s: float = _score[i]
			if _there[i] == 1 or whole:
				var tone: float = clampf((s - line) * 2.5 + 0.35, 0.0, 1.0) if not whole else clampf(s * 1.6 + 0.5, 0.0, 1.0)
				var tall: float = cell if not whole else 0.04
				_cubes.set_instance_transform(shown, Transform3D(Basis().scaled(Vector3(cell, tall, cell)), _at(x, z) - Vector3(0, tall * 0.5, 0)))
				_cubes.set_instance_color(shown, Color(0.2, 0.4, 1.0).lerp(Color(0.75, 0.9, 1.0), tone) if not whole else Color(0.05, 0.06, 0.2).lerp(Color(0.85, 0.95, 1.0), tone))
				shown += 1
			elif shows == "margin" and s > line - MARGIN:
				_ghosts.set_instance_transform(ghosts, Transform3D(Basis().scaled(Vector3(cell, 0.02, cell)), _at(x, z) - Vector3(0, 0.01, 0)))
				_ghosts.set_instance_color(ghosts, Color(1.0, 0.82, 0.16))
				ghosts += 1
	_cubes.visible_instance_count = shown
	_ghosts.visible_instance_count = ghosts
	# the ground: the tops of the runs of cells that are there
	var faces := PackedVector3Array()
	var h: float = cell * 0.5
	for z in grid:
		var x := 0
		while x < grid:
			if _there[z * grid + x] == 0 and not whole:
				x += 1
				continue
			var from := x
			while x < grid and (_there[z * grid + x] == 1 or whole): x += 1
			var a := _at(from, z) + Vector3(-h, 0, -h)
			var b := _at(x - 1, z) + Vector3(h, 0, -h)
			var c := _at(x - 1, z) + Vector3(h, 0, h)
			var d := _at(from, z) + Vector3(-h, 0, h)
			faces.append_array(PackedVector3Array([a, b, c, a, c, d]))
	_shape.set_faces(faces)
	_frame.position = _at(clampi(_held.x, 0, grid - 1), clampi(_held.z, 0, grid - 1)) + Vector3(0, 0.03, 0)
	_write()


func _write() -> void:
	if _board == null: return
	var count := 0
	for b in _there: count += b
	var lines := PackedStringArray(["THE LAYER AT THE YELLOW LINE, AS A FLOOR", "layer %d of %d  |  line %+.2f  |  %d of %d cells are there" % [layer + 1, grid, line, count, grid * grid],
		"A cell above the line is a cube. A cell below it is the shaft.", ""])
	var body: Node3D = null
	for b in _inside: if is_instance_valid(b): body = b
	var under := Vector2i(-1, -1)
	if body != null: under = cell_at(to_local(body.global_position))
	if under.x >= 0:
		var s: float = _score[under.y * grid + under.x]
		lines.append("UNDER YOU  cell %d,%d,%d  field - bias %+.3f  %s" % [under.x, layer, under.y, s, "IS THERE" if s > line else "IS NOT THERE"])
	else:
		lines.append("Step on. The plates at the rim move the line and the layer.")
	_board.text = "\n".join(lines)


## Plate 0 moves the line, plate 1 the held cell (and with it the layer): the bench's own buttons where there is one.
func press_plate(which: int) -> void:
	if _now - _pressed < 1.0: return
	_pressed = _now
	if _bench != null and is_instance_valid(_bench):
		if which == 0: _bench.next_threshold()
		else: _bench.next_cell()
		return
	if which == 0:
		var i: int = THRESHOLDS.find(snappedf(line, 0.01))
		line = float(THRESHOLDS[(i + 1) % THRESHOLDS.size()])
	else:
		layer = int(LAYERS[(LAYERS.find(layer) + 1) % LAYERS.size()])
	_decide()


func _process(delta: float) -> void:
	var began := Time.get_ticks_usec()
	_now += delta
	_seek -= delta
	if _seek <= 0.0 and (_bench == null or not is_instance_valid(_bench)):
		_seek = 1.0
		_bench = _find_bench()
		if _bench != null and not _told: apply_perlin_terrain_controls(_bench._build_voxelnoise_payload())
	_read -= delta
	if _read <= 0.0 and not _inside.is_empty():
		_read = 0.2
		_write()
	_spent_usec += Time.get_ticks_usec() - began
	_frames += 1


## ---- for a test ----

func following() -> bool:
	return _told and _bench != null and is_instance_valid(_bench)


func bench() -> Node:
	return _bench


## The cells of the layer that are there, as (x, z).
func cells() -> Array:
	var out := []
	for z in grid:
		for x in grid:
			if _there[z * grid + x] == 1: out.append(Vector2i(x, z))
	return out


func is_there(x: int, z: int) -> bool:
	return x >= 0 and z >= 0 and x < grid and z < grid and _there[z * grid + x] == 1


func cell_centre(x: int, z: int) -> Vector3:
	return to_global(_at(x, z))


func frame_ms() -> float:
	var ms := float(_spent_usec) / 1000.0 / maxf(1.0, float(_frames))
	_spent_usec = 0
	_frames = 0
	return ms
