class_name TilingLayer
extends RefCounted

## A single composition zone within the tiling system.
## Represents one layer (field, border, corner, etc.) with its own
## fundamental domain and wallpaper group symmetry.

## Zone type (matches TilingSystem.CompositionZone)
var zone: int = 0

## The expanded grid data for this layer (2D array of color indices)
var grid_data: Array = []
var width: int = 0
var height: int = 0

## Symmetry settings
var wallpaper_group: WallpaperGroups.Group = WallpaperGroups.Group.P1
var repeat_mode: int = 0  # PatternTilePuzzle.RepeatMode

## The minimal repeating unit (2D array of color indices)
var fundamental_domain: Array = []
var domain_size: int = 0

## Placement within the composition
var offset: Vector2i = Vector2i.ZERO
var enabled: bool = true


## Set the fundamental domain and wallpaper group, then expand into grid_data.
func set_fundamental_domain(domain: Array, group: WallpaperGroups.Group, target_width: int, target_height: int) -> void:
	fundamental_domain = domain.duplicate(true)
	wallpaper_group = group
	domain_size = domain.size()
	width = target_width
	height = target_height
	_expand_domain()


## Expand the fundamental domain into the full grid_data using wallpaper group symmetry.
## Same approach as MirroredCellularAutomata: generate the seed, apply symmetry to fill.
func _expand_domain() -> void:
	if fundamental_domain.is_empty() or domain_size == 0:
		return

	grid_data.clear()
	for y in range(height):
		var row: Array = []
		for x in range(width):
			var color_idx := WallpaperGroups.get_symmetric_color(
				x, y, domain_size, fundamental_domain, wallpaper_group
			)
			row.append(color_idx)
		grid_data.append(row)


## Composite this layer into an output 2D array at the specified rectangle.
## Only writes cells where this layer has non-zero values (0 = transparent/background).
func fill_rect(x0: int, y0: int, w: int, h: int, output: Array, transparent_index: int = 0) -> void:
	if not enabled or grid_data.is_empty():
		return

	for dy in range(h):
		var oy := y0 + dy
		if oy < 0 or oy >= output.size():
			continue
		for dx in range(w):
			var ox := x0 + dx
			if ox < 0 or ox >= output[oy].size():
				continue

			# Sample from grid_data with tiling (wrap around)
			var sx := (dx + offset.x) % width if width > 0 else 0
			var sy := (dy + offset.y) % height if height > 0 else 0
			if sx < 0:
				sx += width
			if sy < 0:
				sy += height

			var color_idx: int = grid_data[sy][sx]
			if color_idx != transparent_index:
				output[oy][ox] = color_idx


## Generate a linear border strip from a 1D or thin 2D pattern.
## The pattern repeats along the strip length, with strip_width rows.
## Returns a 2D array [strip_width][strip_length].
static func generate_border_strip(pattern: Array, strip_length: int, strip_width: int, group: WallpaperGroups.Group = WallpaperGroups.Group.PM) -> Array:
	var layer := TilingLayer.new()

	# If pattern is 1D, wrap it into a 2D domain
	var domain: Array = []
	if pattern.is_empty():
		return []

	if pattern[0] is Array:
		domain = pattern
	else:
		# 1D pattern -> repeat as rows
		for _y in range(strip_width):
			domain.append(pattern.duplicate())

	layer.set_fundamental_domain(domain, group, strip_length, strip_width)
	return layer.grid_data


## Create a corner piece by rotating a border pattern 90 degrees.
## Returns a 2D array [size][size].
static func generate_corner(border_domain: Array, size: int, group: WallpaperGroups.Group = WallpaperGroups.Group.P4M) -> Array:
	var layer := TilingLayer.new()
	layer.set_fundamental_domain(border_domain, group, size, size)
	return layer.grid_data


## Get the color at a position, with tiling/wrapping.
func get_color_at(x: int, y: int) -> int:
	if grid_data.is_empty() or width == 0 or height == 0:
		return 0
	var sx := x % width
	var sy := y % height
	if sx < 0:
		sx += width
	if sy < 0:
		sy += height
	return grid_data[sy][sx]
