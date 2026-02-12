class_name Grid2DCartridge
extends RefCounted

## Base class for Grid2D algorithm cartridges.
## Subclass this and override the methods below.
## The grid is a flat PackedInt32Array (row-major). State 0 = dead/empty.

## --- Override these ---

## Return the algorithm's display name.
func get_name() -> String:
	return "Unknown"

## How many distinct cell states (including dead=0).
func get_state_count() -> int:
	return 2

## Color for each state index. Index 0 = dead.
func get_state_color(state: int) -> Color:
	if state == 0:
		return Color(0.03, 0.03, 0.04)  # near-black, not pure black
	return Color(0.1, 0.9, 0.6)  # default alive = teal-green

## Emission energy for each state. 0 = no glow.
func get_state_emission(state: int) -> float:
	if state == 0:
		return 0.0
	return 0.8

## Called once before first step. Populate initial state.
## grid is PackedInt32Array of size width*height, row-major.
## Modify in-place.
func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	pass

## Advance one generation. Return new grid (or modify and return same).
func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	return grid

## Called when player touches cell at (x, y). Return modified grid.
func on_cell_touch(grid: PackedInt32Array, x: int, y: int, width: int, height: int) -> PackedInt32Array:
	# Default: toggle between 0 and 1
	var idx = y * width + x
	grid[idx] = 0 if grid[idx] != 0 else 1
	return grid

## How many steps to pre-compute on init (so grid isn't empty).
func get_warmup_steps() -> int:
	return 0

## Preferred grid size for this algorithm (0 = use substrate default).
func get_preferred_width() -> int:
	return 0

func get_preferred_height() -> int:
	return 0

## Preferred step interval in seconds.
func get_preferred_interval() -> float:
	return 0.0
