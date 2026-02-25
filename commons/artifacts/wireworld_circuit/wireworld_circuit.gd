extends Node3D
class_name WireworldCircuit

## Wireworld cellular automaton — 4-state CA for logic gates and signal routing.
## Displays an OR gate circuit with a clock (looping signal) on a floor QuadMesh.
## States: EMPTY(black), WIRE(orange), ELECTRON_HEAD(blue), ELECTRON_TAIL(red).

# --- Configuration ---
@export var display_size: float = 0.8
@export var grid_resolution: int = 32
@export var steps_per_frame: int = 1
@export var step_interval: float = 0.15

# --- State constants ---
const EMPTY = 0
const WIRE = 1
const HEAD = 2
const TAIL = 3

# --- Colors ---
const COLOR_EMPTY = Color(0.02, 0.02, 0.03)
const COLOR_WIRE = Color(0.85, 0.55, 0.1)
const COLOR_HEAD = Color(0.2, 0.5, 1.0)
const COLOR_TAIL = Color(0.9, 0.15, 0.1)

# --- Internal ---
var _grid: PackedInt32Array
var _grid_next: PackedInt32Array
var _display_mesh: MeshInstance3D
var _image: Image
var _texture: ImageTexture
var _material: StandardMaterial3D
var _time_accum: float = 0.0


func _ready() -> void:
	_grid = PackedInt32Array()
	_grid.resize(grid_resolution * grid_resolution)
	_grid_next = PackedInt32Array()
	_grid_next.resize(grid_resolution * grid_resolution)

	_create_display()
	_build_circuit()
	_update_texture()


func _create_display() -> void:
	_display_mesh = MeshInstance3D.new()
	_display_mesh.name = "WireworldDisplay"

	var quad = QuadMesh.new()
	quad.size = Vector2(display_size, display_size)
	_display_mesh.mesh = quad

	_display_mesh.rotation_degrees.x = -90
	_display_mesh.position.y = 0.005

	_image = Image.create(grid_resolution, grid_resolution, false, Image.FORMAT_RGB8)
	_texture = ImageTexture.create_from_image(_image)

	_material = StandardMaterial3D.new()
	_material.albedo_texture = _texture
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_material.emission_enabled = true
	_material.emission_texture = _texture
	_material.emission_energy_multiplier = 0.4
	_material.roughness = 0.9

	_display_mesh.material_override = _material
	add_child(_display_mesh)


func _build_circuit() -> void:
	# Clear grid
	for i in range(_grid.size()):
		_grid[i] = EMPTY

	# Build an OR gate circuit with two clock inputs.
	# Layout (32x32 grid):
	#   Two clock loops feed into an OR gate, output goes to a display wire.

	# --- Clock A (top-left loop, rows 4-8, cols 2-10) ---
	# Horizontal top wire
	_set_wire_line(2, 4, 10, 4)
	# Horizontal bottom wire
	_set_wire_line(2, 8, 10, 8)
	# Vertical left wire
	_set_wire_line(2, 5, 2, 7)
	# Vertical right wire (connects to OR input)
	_set_wire_line(10, 5, 10, 7)
	# Seed electron on clock A
	_set_cell(3, 4, HEAD)
	_set_cell(2, 4, TAIL)

	# --- Clock B (bottom-left loop, rows 18-22, cols 2-10) ---
	_set_wire_line(2, 18, 10, 18)
	_set_wire_line(2, 22, 10, 22)
	_set_wire_line(2, 19, 2, 21)
	_set_wire_line(10, 19, 10, 21)
	# Seed electron on clock B (offset phase)
	_set_cell(6, 22, HEAD)
	_set_cell(5, 22, TAIL)

	# --- Input wires leading to OR gate ---
	# From clock A: row 6 rightward from col 10 to col 18
	_set_wire_line(10, 6, 18, 6)
	# From clock B: row 20 rightward from col 10 to col 18, then up
	_set_wire_line(10, 20, 18, 20)
	# Vertical wires converging to OR junction at (20, 13)
	_set_wire_line(18, 7, 18, 12)
	_set_wire_line(18, 14, 18, 19)

	# --- OR gate junction ---
	# The two inputs meet at column 18, converge to col 20 via row 13
	_set_cell(18, 13, WIRE)
	_set_wire_line(19, 13, 20, 13)

	# --- Output wire ---
	_set_wire_line(21, 13, 29, 13)

	# --- Output display loop (right side) ---
	_set_wire_line(29, 10, 29, 12)
	_set_wire_line(29, 14, 29, 16)
	_set_wire_line(26, 10, 28, 10)
	_set_wire_line(26, 16, 28, 16)
	_set_wire_line(26, 11, 26, 15)


func _set_cell(x: int, y: int, state: int) -> void:
	if x >= 0 and x < grid_resolution and y >= 0 and y < grid_resolution:
		_grid[y * grid_resolution + x] = state



func _set_wire_line(x0: int, y0: int, x1: int, y1: int) -> void:
	# Draw a horizontal or vertical wire line (inclusive endpoints)
	if y0 == y1:
		var start_x = mini(x0, x1)
		var end_x = maxi(x0, x1)
		for x in range(start_x, end_x + 1):
			_set_cell(x, y0, WIRE)
	elif x0 == x1:
		var start_y = mini(y0, y1)
		var end_y = maxi(y0, y1)
		for y in range(start_y, end_y + 1):
			_set_cell(x0, y, WIRE)


func _process(delta: float) -> void:
	_time_accum += delta
	if _time_accum >= step_interval:
		_time_accum -= step_interval
		for _i in range(steps_per_frame):
			_simulation_step()
		_update_texture()


func _simulation_step() -> void:
	for y in range(grid_resolution):
		for x in range(grid_resolution):
			var idx = y * grid_resolution + x
			var state = _grid[idx]
			match state:
				EMPTY:
					_grid_next[idx] = EMPTY
				HEAD:
					_grid_next[idx] = TAIL
				TAIL:
					_grid_next[idx] = WIRE
				WIRE:
					var head_count = _count_head_neighbors(x, y)
					if head_count == 1 or head_count == 2:
						_grid_next[idx] = HEAD
					else:
						_grid_next[idx] = WIRE

	# Swap buffers
	var temp = _grid
	_grid = _grid_next
	_grid_next = temp


func _count_head_neighbors(x: int, y: int) -> int:
	var count = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx
			var ny = y + dy
			if nx >= 0 and nx < grid_resolution and ny >= 0 and ny < grid_resolution:
				if _grid[ny * grid_resolution + nx] == HEAD:
					count += 1
	return count


func _update_texture() -> void:
	for y in range(grid_resolution):
		for x in range(grid_resolution):
			var state = _grid[y * grid_resolution + x]
			var color: Color
			match state:
				EMPTY:
					color = COLOR_EMPTY
				WIRE:
					color = COLOR_WIRE
				HEAD:
					color = COLOR_HEAD
				TAIL:
					color = COLOR_TAIL
				_:
					color = COLOR_EMPTY
			_image.set_pixel(x, y, color)
	_texture.update(_image)


## Grid system integration — accept configuration from map data
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("step_interval"):
		step_interval = float(config_data["step_interval"])
	if config_data.has("steps_per_frame"):
		steps_per_frame = int(config_data["steps_per_frame"])
