extends Node3D
class_name RoomGrammar

## Shape grammar for architectural floor plans — BSP room partitioning
## on a floor display. Recursively splits a rectangle into rooms, draws
## outlines, adds door gaps, and colors rooms by area.

# @identity
# essence: binary space partitioning on a floor quad — a rectangle splits recursively into rooms, walls drawn, doors gapped, rooms tinted by area
# desire: to show that an architectural plan is a grammar — a few recursive split rules generate an entire believable floorplan
# critical_parameter: grammar — which split production runs, the difference between an accreted building and a barracks; then depth, the lambda between a single hall and a dense warren of rooms
# triggers: changing grammar, depth or seed_value and re-running _generate_floor_plan redraws an entirely new plan
# emerges: at higher depths the plan reads as a real building — corridors, small rooms, a logic of enclosure — from nothing but repeated division
# needs: procedural plan rendered to a floor texture [has]; grabbable seed/depth control so the player grows the plan by hand [missing]; walkable scale so the player stands inside the rooms [missing]
# relationships: a grid-quantisation artifact in the primitives sequence (Grid Quantizes Movement); kin to L-system and space-partition grammar work
# truth: a floor plan is not designed room by room — it is a rule for dividing space, applied until the space runs out

# --- STAGE-2 DNA (promoted 2026-08-03) --------------------------------------
# Two axes, both of them arguments the file was already making silently.
#
#   grammar — the split PRODUCTION. A shape grammar is its rule, and this file's
#     rule was three unnamed decisions buried in _bsp_split: prefer the longer
#     axis at a 1.3 tolerance, then cut anywhere in the legal band. Those two
#     choices together are "organic" and they are only one of the plans BSP can
#     draw. alternating cuts strictly by depth (the textbook partition, nested
#     bands). symmetric bisects (equal halves all the way down — a barracks).
#     golden cuts at 0.382 of the band (proportioned rooms — a villa). corridor
#     cuts hard against the minimum, shaving one thin room off every division,
#     so the plan reads as a spine with cells hanging off it.
#
#   depth — the old `split_depth`, under the word the L-system family uses.
#
# DEFAULTS ARE A NO-OP. grammar="organic" runs the shipped branch verbatim and
# consumes the RNG in the same order (randf() only on the near-square case,
# randi_range() for the position), and depth=5 is the number split_depth
# shipped with, so all 8 placements draw the identical plan.
# ----------------------------------------------------------------------------

# --- Configuration ---

@export var quad_size: Vector2 = Vector2(0.8, 0.8)
@export var seed_value: int = 73
@export_enum("organic", "alternating", "symmetric", "golden", "corridor") var grammar: String = "organic"
@export_range(1, 5) var depth: int = 5
@export var min_room_size: int = 12

const GRAMMARS := ["organic", "alternating", "symmetric", "golden", "corridor"]
const IMAGE_SIZE: int = 128
const WALL_COLOR: Color = Color(0.85, 0.88, 0.92)
const BG_COLOR: Color = Color(0.06, 0.06, 0.1)
const DOOR_COLOR: Color = Color(0.35, 0.25, 0.15)

var _mesh_inst: MeshInstance3D
var _material: StandardMaterial3D
## Built HERE, not in _ready: apply_grid_config can run before _ready (the museum
## stamps config on a root still outside the tree) and used to find this null.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _rooms: Array = []  # Array of Rect2i (leaf rooms)
var _title: Label3D
var _built: bool = false


func _ready() -> void:
	_rng.seed = seed_value
	_build_floor_quad()
	_generate_floor_plan()
	_built = true


func _build_floor_quad() -> void:
	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.name = "RoomGrammarMesh"
	var quad := QuadMesh.new()
	quad.size = quad_size
	_mesh_inst.mesh = quad
	_mesh_inst.rotation_degrees.x = -90
	_mesh_inst.position.y = 0.005

	_material = StandardMaterial3D.new()
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_material.roughness = 0.85
	_material.metallic = 0.0
	_mesh_inst.material_override = _material
	add_child(_mesh_inst)

	# The title used to be created INSIDE _generate_floor_plan, so a second
	# generation added a second Label3D on top of the first. Built once here
	# with the identical text, size, colour, rotation and position, so the
	# picture is unchanged and a re-generation no longer stacks labels.
	_title = Label3D.new()
	_title.text = "BSP Floor Plan"
	_title.font_size = 28
	_title.pixel_size = 0.001
	_title.modulate = Color(0.7, 0.75, 0.85)
	_title.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_title.rotation_degrees.x = -90
	_title.position = Vector3(0, 0.006, quad_size.y * 0.5 + 0.03)
	add_child(_title)


func _generate_floor_plan() -> void:
	_rooms.clear()

	# Margin from edge so walls don't land on pixel 0/127
	var margin := 2
	var root_rect := Rect2i(margin, margin, IMAGE_SIZE - margin * 2, IMAGE_SIZE - margin * 2)

	# BSP partition
	_bsp_split(root_rect, 0)

	# Compute area range for room coloring
	var min_area := 999999
	var max_area := 0
	for room in _rooms:
		var a: int = room.size.x * room.size.y
		if a < min_area:
			min_area = a
		if a > max_area:
			max_area = a

	var area_range := max_area - min_area
	if area_range < 1:
		area_range = 1

	# Build image
	var image := Image.create(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(BG_COLOR)

	# Fill rooms by area — large rooms lighter, small rooms darker
	for room in _rooms:
		var a: int = room.size.x * room.size.y
		var t: float = float(a - min_area) / float(area_range)
		var dark := Color(0.1, 0.12, 0.18)
		var light := Color(0.25, 0.3, 0.4)
		var fill_color := dark.lerp(light, t)
		_fill_rect(image, room.position.x + 1, room.position.y + 1,
			room.size.x - 2, room.size.y - 2, fill_color)

	# Draw room outlines (walls)
	for room in _rooms:
		_draw_rect_outline(image, room, WALL_COLOR)

	# Add doors between adjacent rooms
	_add_doors(image)

	var texture := ImageTexture.create_from_image(image)
	_material.albedo_texture = texture


## Recursive BSP split — splits rect into sub-rects down to `depth`.
## The loop parameter is `level` (the member `depth` is the ceiling).
func _bsp_split(rect: Rect2i, level: int) -> void:
	if level >= depth or rect.size.x < min_room_size * 2 or rect.size.y < min_room_size * 2:
		_rooms.append(rect)
		return

	var split_horizontal: bool = _split_horizontal(rect, level)

	if split_horizontal:
		# Split along Y axis
		var min_split := rect.position.y + min_room_size
		var max_split := rect.position.y + rect.size.y - min_room_size
		if min_split >= max_split:
			_rooms.append(rect)
			return
		var split_pos: int = _cut_at(min_split, max_split)
		var top := Rect2i(rect.position.x, rect.position.y,
			rect.size.x, split_pos - rect.position.y)
		var bottom := Rect2i(rect.position.x, split_pos,
			rect.size.x, rect.position.y + rect.size.y - split_pos)
		_bsp_split(top, level + 1)
		_bsp_split(bottom, level + 1)
	else:
		# Split along X axis
		var min_split := rect.position.x + min_room_size
		var max_split := rect.position.x + rect.size.x - min_room_size
		if min_split >= max_split:
			_rooms.append(rect)
			return
		var split_pos: int = _cut_at(min_split, max_split)
		var left := Rect2i(rect.position.x, rect.position.y,
			split_pos - rect.position.x, rect.size.y)
		var right := Rect2i(split_pos, rect.position.y,
			rect.position.x + rect.size.x - split_pos, rect.size.y)
		_bsp_split(left, level + 1)
		_bsp_split(right, level + 1)


## Which way the cut runs. Everything except `alternating` uses the shipped
## rule: prefer the longer axis at a 1.3 tolerance, coin-flip when near square.
func _split_horizontal(rect: Rect2i, level: int) -> bool:
	if grammar == "alternating":
		# Strict alternation by recursion level — the textbook partition. No
		# RNG is consumed here, which is fine: it is a different production.
		return (level % 2) == 1
	if rect.size.x > rect.size.y * 1.3:
		return false  # split vertically (along x)
	if rect.size.y > rect.size.x * 1.3:
		return true   # split horizontally (along y)
	return _rng.randf() > 0.5


## Where in the legal band [lo, hi] the cut lands. `organic` and `alternating`
## keep the shipped `lo + randi_range(0, hi - lo)` exactly; the other three are
## deterministic and consume no RNG.
func _cut_at(lo: int, hi: int) -> int:
	match grammar:
		"symmetric":
			return (lo + hi) / 2
		"golden":
			return lo + int(round(float(hi - lo) * 0.382))
		"corridor":
			return lo
	return lo + _rng.randi_range(0, hi - lo)


## Draw a rectangle outline on the image
func _draw_rect_outline(image: Image, rect: Rect2i, color: Color) -> void:
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := rect.position.x + rect.size.x - 1
	var y1 := rect.position.y + rect.size.y - 1

	# Top and bottom edges
	for x in range(x0, x1 + 1):
		if _in_bounds(x, y0):
			image.set_pixel(x, y0, color)
		if _in_bounds(x, y1):
			image.set_pixel(x, y1, color)

	# Left and right edges
	for y in range(y0, y1 + 1):
		if _in_bounds(x0, y):
			image.set_pixel(x0, y, color)
		if _in_bounds(x1, y):
			image.set_pixel(x1, y, color)


## Fill a rectangular area with a color
func _fill_rect(image: Image, x0: int, y0: int, w: int, h: int, color: Color) -> void:
	for py in range(y0, y0 + h):
		for px in range(x0, x0 + w):
			if _in_bounds(px, py):
				image.set_pixel(px, py, color)


## Add door gaps between adjacent rooms
func _add_doors(image: Image) -> void:
	var door_width := 4
	for i in range(_rooms.size()):
		for j in range(i + 1, _rooms.size()):
			var a: Rect2i = _rooms[i]
			var b: Rect2i = _rooms[j]
			var door_pos := _find_shared_wall(a, b)
			if door_pos.x >= 0:
				_carve_door(image, door_pos, door_width)


## Find a shared wall segment between two rooms. Returns Vector3i:
## (x, y, direction) where direction: 0=horizontal wall, 1=vertical wall.
## Returns (-1,-1,-1) if rooms don't share a wall.
func _find_shared_wall(a: Rect2i, b: Rect2i) -> Vector3i:
	# Check if a's right edge == b's left edge (vertical shared wall)
	if a.position.x + a.size.x == b.position.x:
		var overlap_y0 := maxi(a.position.y, b.position.y)
		var overlap_y1 := mini(a.position.y + a.size.y, b.position.y + b.size.y)
		if overlap_y1 - overlap_y0 > 4:
			var mid_y := (overlap_y0 + overlap_y1) / 2
			return Vector3i(a.position.x + a.size.x - 1, mid_y, 1)

	# Check if b's right edge == a's left edge
	if b.position.x + b.size.x == a.position.x:
		var overlap_y0 := maxi(a.position.y, b.position.y)
		var overlap_y1 := mini(a.position.y + a.size.y, b.position.y + b.size.y)
		if overlap_y1 - overlap_y0 > 4:
			var mid_y := (overlap_y0 + overlap_y1) / 2
			return Vector3i(a.position.x, mid_y, 1)

	# Check if a's bottom edge == b's top edge (horizontal shared wall)
	if a.position.y + a.size.y == b.position.y:
		var overlap_x0 := maxi(a.position.x, b.position.x)
		var overlap_x1 := mini(a.position.x + a.size.x, b.position.x + b.size.x)
		if overlap_x1 - overlap_x0 > 4:
			var mid_x := (overlap_x0 + overlap_x1) / 2
			return Vector3i(mid_x, a.position.y + a.size.y - 1, 0)

	# Check if b's bottom edge == a's top edge
	if b.position.y + b.size.y == a.position.y:
		var overlap_x0 := maxi(a.position.x, b.position.x)
		var overlap_x1 := mini(a.position.x + a.size.x, b.position.x + b.size.x)
		if overlap_x1 - overlap_x0 > 4:
			var mid_x := (overlap_x0 + overlap_x1) / 2
			return Vector3i(mid_x, a.position.y, 0)

	return Vector3i(-1, -1, -1)


## Carve a door gap at the given position
func _carve_door(image: Image, pos: Vector3i, width: int) -> void:
	var half := width / 2
	if pos.z == 0:
		# Horizontal wall — carve along X
		for dx in range(-half, half + 1):
			var px := pos.x + dx
			if _in_bounds(px, pos.y):
				image.set_pixel(px, pos.y, DOOR_COLOR)
	else:
		# Vertical wall — carve along Y
		for dy in range(-half, half + 1):
			var py := pos.y + dy
			if _in_bounds(pos.x, py):
				image.set_pixel(pos.x, py, DOOR_COLOR)


func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < IMAGE_SIZE and y >= 0 and y < IMAGE_SIZE


## Grid system integration — accept configuration from map data.
## GUARDED: regenerates only when a value ACTUALLY changed and only after
## _ready has built once. The shipped version re-ran the whole partition on the
## mere presence of the call, which also stacked a second title Label3D.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	var changed: bool = false

	if config_data.has("seed"):
		var s: int = int(config_data["seed"])
		if s != seed_value:
			seed_value = s
			changed = true

	if config_data.has("grammar"):
		var g: String = str(config_data["grammar"]).strip_edges().to_lower()
		if GRAMMARS.has(g) and g != grammar:
			grammar = g
			changed = true

	# `split_depth` kept as an alias: it was the export's old name.
	if config_data.has("depth") or config_data.has("split_depth"):
		var raw = config_data.get("depth", config_data.get("split_depth", depth))
		var d: int = clampi(int(raw), 1, 5)
		if d != depth:
			depth = d
			changed = true

	if config_data.has("min_room_size"):
		var m: int = int(config_data["min_room_size"])
		if m != min_room_size:
			min_room_size = m
			changed = true

	if not changed or not _built:
		return

	_rng.seed = seed_value
	_generate_floor_plan()
