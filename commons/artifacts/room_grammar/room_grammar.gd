extends Node3D
class_name RoomGrammar

## Shape grammar for architectural floor plans — BSP room partitioning
## on a floor display. Recursively splits a rectangle into rooms, draws
## outlines, adds door gaps, and colors rooms by area.

# @identity
# essence: binary space partitioning on a floor quad — a rectangle splits recursively into rooms, walls drawn, doors gapped, rooms tinted by area
# desire: to show that an architectural plan is a grammar — a few recursive split rules generate an entire believable floorplan
# critical_parameter: split_depth — how many recursive cuts run, the lambda between a single hall and a dense warren of rooms
# triggers: changing seed_value or split_depth and re-running _generate_floor_plan redraws an entirely new plan
# emerges: at higher depths the plan reads as a real building — corridors, small rooms, a logic of enclosure — from nothing but repeated division
# needs: procedural plan rendered to a floor texture [has]; grabbable seed/depth control so the player grows the plan by hand [missing]; walkable scale so the player stands inside the rooms [missing]
# relationships: a grid-quantisation artifact in the primitives sequence (Grid Quantizes Movement); kin to L-system and space-partition grammar work
# truth: a floor plan is not designed room by room — it is a rule for dividing space, applied until the space runs out

# --- Configuration ---

@export var quad_size: Vector2 = Vector2(0.8, 0.8)
@export var seed_value: int = 73
@export var split_depth: int = 5
@export var min_room_size: int = 12

const IMAGE_SIZE: int = 128
const WALL_COLOR: Color = Color(0.85, 0.88, 0.92)
const BG_COLOR: Color = Color(0.06, 0.06, 0.1)
const DOOR_COLOR: Color = Color(0.35, 0.25, 0.15)

var _mesh_inst: MeshInstance3D
var _material: StandardMaterial3D
var _rng: RandomNumberGenerator
var _rooms: Array = []  # Array of Rect2i (leaf rooms)


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value
	_build_floor_quad()
	_generate_floor_plan()


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

	# Add a title label
	var title := Label3D.new()
	title.text = "BSP Floor Plan"
	title.font_size = 28
	title.pixel_size = 0.001
	title.modulate = Color(0.7, 0.75, 0.85)
	title.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	title.rotation_degrees.x = -90
	title.position = Vector3(0, 0.006, quad_size.y * 0.5 + 0.03)
	add_child(title)

	var texture := ImageTexture.create_from_image(image)
	_material.albedo_texture = texture


## Recursive BSP split — splits rect into sub-rects down to split_depth
func _bsp_split(rect: Rect2i, depth: int) -> void:
	if depth >= split_depth or rect.size.x < min_room_size * 2 or rect.size.y < min_room_size * 2:
		_rooms.append(rect)
		return

	# Decide split direction: prefer splitting the longer axis
	var split_horizontal: bool
	if rect.size.x > rect.size.y * 1.3:
		split_horizontal = false  # split vertically (along x)
	elif rect.size.y > rect.size.x * 1.3:
		split_horizontal = true   # split horizontally (along y)
	else:
		split_horizontal = _rng.randf() > 0.5

	if split_horizontal:
		# Split along Y axis
		var min_split := rect.position.y + min_room_size
		var max_split := rect.position.y + rect.size.y - min_room_size
		if min_split >= max_split:
			_rooms.append(rect)
			return
		var split_pos: int = min_split + _rng.randi_range(0, max_split - min_split)
		var top := Rect2i(rect.position.x, rect.position.y,
			rect.size.x, split_pos - rect.position.y)
		var bottom := Rect2i(rect.position.x, split_pos,
			rect.size.x, rect.position.y + rect.size.y - split_pos)
		_bsp_split(top, depth + 1)
		_bsp_split(bottom, depth + 1)
	else:
		# Split along X axis
		var min_split := rect.position.x + min_room_size
		var max_split := rect.position.x + rect.size.x - min_room_size
		if min_split >= max_split:
			_rooms.append(rect)
			return
		var split_pos: int = min_split + _rng.randi_range(0, max_split - min_split)
		var left := Rect2i(rect.position.x, rect.position.y,
			split_pos - rect.position.x, rect.size.y)
		var right := Rect2i(split_pos, rect.position.y,
			rect.position.x + rect.size.x - split_pos, rect.size.y)
		_bsp_split(left, depth + 1)
		_bsp_split(right, depth + 1)


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


## Grid system integration — accept configuration from map data
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"):
		seed_value = int(config_data["seed"])
	if config_data.has("split_depth"):
		split_depth = int(config_data["split_depth"])
	if config_data.has("min_room_size"):
		min_room_size = int(config_data["min_room_size"])
	_rng.seed = seed_value
	_generate_floor_plan()
