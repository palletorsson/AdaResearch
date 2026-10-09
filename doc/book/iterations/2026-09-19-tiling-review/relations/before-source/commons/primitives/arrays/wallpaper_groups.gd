class_name WallpaperGroups
extends RefCounted

## Wallpaper Groups - The 17 Mathematical Tilings
##
## These are ALL possible ways to tile a 2D plane with a repeating pattern.
## Discovered in the 19th century, they encode the mathematics of
## textiles, tiles, and wallpaper across all cultures.
##
## Each group is defined by its symmetry operations:
## - Translation (T) - shift
## - Rotation (R) - 2-fold, 3-fold, 4-fold, 6-fold
## - Reflection (M) - mirror
## - Glide reflection (G) - mirror + half-translation

## The 17 wallpaper groups
enum Group {
	P1,      ## No symmetry (only translation)
	P2,      ## 180° rotation
	PM,      ## Reflection in one direction
	PG,      ## Glide reflection
	CM,      ## Reflection + glide perpendicular
	PMM,     ## Reflection in two perpendicular directions
	PMG,     ## Reflection + perpendicular glide
	PGG,     ## Two perpendicular glides
	CMM,     ## Two perpendicular reflections + 180° rotation
	P4,      ## 90° rotation
	P4M,     ## 90° rotation + reflections through rotation centers
	P4G,     ## 90° rotation + reflections not through centers
	P3,      ## 120° rotation (triangular)
	P3M1,    ## 120° rotation + reflection (type 1)
	P31M,    ## 120° rotation + reflection (type 2)
	P6,      ## 60° rotation (hexagonal)
	P6M      ## 60° rotation + reflections
}

## Group metadata
const GROUP_INFO = {
	Group.P1: {
		"name": "p1",
		"description": "Oblique lattice, translation only",
		"rotations": [],
		"reflections": false,
		"glides": false,
		"lattice": "oblique"
	},
	Group.P2: {
		"name": "p2",
		"description": "180° rotation centers",
		"rotations": [180],
		"reflections": false,
		"glides": false,
		"lattice": "oblique"
	},
	Group.PM: {
		"name": "pm",
		"description": "Parallel mirrors",
		"rotations": [],
		"reflections": true,
		"glides": false,
		"lattice": "rectangular"
	},
	Group.PG: {
		"name": "pg",
		"description": "Parallel glide reflections",
		"rotations": [],
		"reflections": false,
		"glides": true,
		"lattice": "rectangular"
	},
	Group.CM: {
		"name": "cm",
		"description": "Mirrors + perpendicular glides",
		"rotations": [],
		"reflections": true,
		"glides": true,
		"lattice": "rhombic"
	},
	Group.PMM: {
		"name": "pmm",
		"description": "Perpendicular mirrors",
		"rotations": [180],
		"reflections": true,
		"glides": false,
		"lattice": "rectangular"
	},
	Group.PMG: {
		"name": "pmg",
		"description": "Mirrors + perpendicular glides + 180° rotation",
		"rotations": [180],
		"reflections": true,
		"glides": true,
		"lattice": "rectangular"
	},
	Group.PGG: {
		"name": "pgg",
		"description": "Perpendicular glides + 180° rotation",
		"rotations": [180],
		"reflections": false,
		"glides": true,
		"lattice": "rectangular"
	},
	Group.CMM: {
		"name": "cmm",
		"description": "Perpendicular mirrors + 180° rotation (centered)",
		"rotations": [180],
		"reflections": true,
		"glides": true,
		"lattice": "rhombic"
	},
	Group.P4: {
		"name": "p4",
		"description": "90° rotation",
		"rotations": [90, 180],
		"reflections": false,
		"glides": false,
		"lattice": "square"
	},
	Group.P4M: {
		"name": "p4m",
		"description": "90° rotation + diagonal mirrors",
		"rotations": [90, 180],
		"reflections": true,
		"glides": true,
		"lattice": "square"
	},
	Group.P4G: {
		"name": "p4g",
		"description": "90° rotation + off-center mirrors",
		"rotations": [90, 180],
		"reflections": true,
		"glides": true,
		"lattice": "square"
	},
	Group.P3: {
		"name": "p3",
		"description": "120° rotation (triangular)",
		"rotations": [120],
		"reflections": false,
		"glides": false,
		"lattice": "hexagonal"
	},
	Group.P3M1: {
		"name": "p3m1",
		"description": "120° rotation + mirrors through centers",
		"rotations": [120],
		"reflections": true,
		"glides": false,
		"lattice": "hexagonal"
	},
	Group.P31M: {
		"name": "p31m",
		"description": "120° rotation + mirrors between centers",
		"rotations": [120],
		"reflections": true,
		"glides": true,
		"lattice": "hexagonal"
	},
	Group.P6: {
		"name": "p6",
		"description": "60° rotation (hexagonal)",
		"rotations": [60, 120, 180],
		"reflections": false,
		"glides": false,
		"lattice": "hexagonal"
	},
	Group.P6M: {
		"name": "p6m",
		"description": "60° rotation + all mirrors (highest symmetry)",
		"rotations": [60, 120, 180],
		"reflections": true,
		"glides": true,
		"lattice": "hexagonal"
	}
}


## Apply wallpaper group symmetry to get color at position
static func get_symmetric_color(
	px: int, py: int,
	tile_size: int,
	grid_data: Array,
	group: Group
) -> int:
	var tx: int
	var ty: int

	match group:
		Group.P1:
			# Simple translation
			tx = px % tile_size
			ty = py % tile_size

		Group.P2:
			# 180° rotation at center of each tile
			var tile_x = px / tile_size
			var tile_y = py / tile_size
			tx = px % tile_size
			ty = py % tile_size
			if (tile_x + tile_y) % 2 == 1:
				tx = tile_size - 1 - tx
				ty = tile_size - 1 - ty

		Group.PM:
			# Mirror in X
			var tile_x = px / tile_size
			tx = px % tile_size
			if tile_x % 2 == 1:
				tx = tile_size - 1 - tx
			ty = py % tile_size

		Group.PG:
			# Glide reflection (mirror + half shift)
			var tile_x = px / tile_size
			tx = px % tile_size
			ty = py % tile_size
			if tile_x % 2 == 1:
				tx = tile_size - 1 - tx
				ty = (ty + tile_size / 2) % tile_size

		Group.CM:
			# Centered mirror + glide
			var tile_x = px / tile_size
			var tile_y = py / tile_size
			tx = px % tile_size
			ty = py % tile_size
			if tile_x % 2 == 1:
				tx = tile_size - 1 - tx
			if (tile_x + tile_y) % 2 == 1:
				ty = (ty + tile_size / 2) % tile_size

		Group.PMM:
			# Double mirror
			var tile_x = px / tile_size
			var tile_y = py / tile_size
			tx = px % tile_size
			ty = py % tile_size
			if tile_x % 2 == 1:
				tx = tile_size - 1 - tx
			if tile_y % 2 == 1:
				ty = tile_size - 1 - ty

		Group.PMG:
			# Mirror X + Glide Y + 180° rotation
			var tile_x = px / tile_size
			var tile_y = py / tile_size
			tx = px % tile_size
			ty = py % tile_size
			if tile_x % 2 == 1:
				tx = tile_size - 1 - tx
			if tile_y % 2 == 1:
				tx = tile_size - 1 - tx
				ty = tile_size - 1 - ty
				ty = (ty + tile_size / 2) % tile_size

		Group.PGG:
			# Double glide + 180° rotation
			var tile_x = px / tile_size
			var tile_y = py / tile_size
			tx = px % tile_size
			ty = py % tile_size
			if tile_x % 2 == 1:
				tx = tile_size - 1 - tx
				ty = (ty + tile_size / 2) % tile_size
			if tile_y % 2 == 1:
				ty = tile_size - 1 - ty
				tx = (tx + tile_size / 2) % tile_size

		Group.CMM:
			# Centered double mirror
			var tile_x = px / tile_size
			var tile_y = py / tile_size
			tx = px % tile_size
			ty = py % tile_size
			var flip_x = tile_x % 2 == 1
			var flip_y = tile_y % 2 == 1
			if flip_x:
				tx = tile_size - 1 - tx
			if flip_y:
				ty = tile_size - 1 - ty
			if (tile_x + tile_y) % 2 == 1:
				# Centered offset
				tx = (tx + tile_size / 2) % tile_size
				ty = (ty + tile_size / 2) % tile_size

		Group.P4:
			# 90° rotation
			var tile_x = px / tile_size
			var tile_y = py / tile_size
			var rotation = (tile_x + tile_y * 2) % 4
			tx = px % tile_size
			ty = py % tile_size
			for i in range(rotation):
				var new_tx = tile_size - 1 - ty
				var new_ty = tx
				tx = new_tx
				ty = new_ty

		Group.P4M:
			# 90° rotation + mirrors
			var tile_x = px / tile_size
			var tile_y = py / tile_size
			tx = px % tile_size
			ty = py % tile_size

			# Apply rotation based on tile position
			var rotation = (tile_x + tile_y) % 4
			for i in range(rotation):
				var new_tx = tile_size - 1 - ty
				var new_ty = tx
				tx = new_tx
				ty = new_ty

			# Apply mirror for diagonal symmetry
			if tile_x % 2 == 1:
				var temp = tx
				tx = ty
				ty = temp

		Group.P4G:
			# 90° rotation + off-center mirrors
			var tile_x = px / tile_size
			var tile_y = py / tile_size
			tx = px % tile_size
			ty = py % tile_size

			var rotation = (tile_x + tile_y) % 4
			for i in range(rotation):
				var new_tx = tile_size - 1 - ty
				var new_ty = tx
				tx = new_tx
				ty = new_ty

			if (tile_x + tile_y) % 2 == 1:
				tx = tile_size - 1 - tx
				ty = tile_size - 1 - ty

		Group.P3:
			# 120° rotation (triangular lattice)
			# Simplified: use modular arithmetic to approximate
			tx = px % tile_size
			ty = py % tile_size
			var region = ((px / tile_size) + (py / tile_size) * 2) % 3
			if region == 1:
				# Rotate 120°
				var cx = tile_size / 2.0
				var cy = tile_size / 2.0
				var dx = tx - cx
				var dy = ty - cy
				var angle = 2 * PI / 3
				tx = int(cx + dx * cos(angle) - dy * sin(angle)) % tile_size
				ty = int(cy + dx * sin(angle) + dy * cos(angle)) % tile_size
			elif region == 2:
				# Rotate 240°
				var cx = tile_size / 2.0
				var cy = tile_size / 2.0
				var dx = tx - cx
				var dy = ty - cy
				var angle = 4 * PI / 3
				tx = int(cx + dx * cos(angle) - dy * sin(angle)) % tile_size
				ty = int(cy + dx * sin(angle) + dy * cos(angle)) % tile_size

		Group.P3M1, Group.P31M:
			# 120° rotation + mirrors
			tx = px % tile_size
			ty = py % tile_size
			var region = ((px / tile_size) + (py / tile_size)) % 6
			# Apply 60° rotations based on region
			var angle = region * PI / 3
			if angle > 0:
				var cx = tile_size / 2.0
				var cy = tile_size / 2.0
				var dx = tx - cx
				var dy = ty - cy
				tx = int(cx + dx * cos(angle) - dy * sin(angle)) % tile_size
				ty = int(cy + dx * sin(angle) + dy * cos(angle)) % tile_size
			# Mirror for p3m1 variant
			if group == Group.P3M1 and region % 2 == 1:
				tx = tile_size - 1 - tx

		Group.P6:
			# 60° rotation (hexagonal)
			tx = px % tile_size
			ty = py % tile_size
			var region = ((px / tile_size) * 2 + (py / tile_size)) % 6
			var angle = region * PI / 3
			if angle > 0:
				var cx = tile_size / 2.0
				var cy = tile_size / 2.0
				var dx = tx - cx
				var dy = ty - cy
				tx = int(cx + dx * cos(angle) - dy * sin(angle)) % tile_size
				ty = int(cy + dx * sin(angle) + dy * cos(angle)) % tile_size

		Group.P6M:
			# 60° rotation + all mirrors (highest symmetry)
			tx = px % tile_size
			ty = py % tile_size
			var region = ((px / tile_size) + (py / tile_size) * 3) % 12
			var rotation = region % 6
			var mirror = region >= 6

			# Apply rotation
			if rotation > 0:
				var angle = rotation * PI / 3
				var cx = tile_size / 2.0
				var cy = tile_size / 2.0
				var dx = tx - cx
				var dy = ty - cy
				tx = int(cx + dx * cos(angle) - dy * sin(angle)) % tile_size
				ty = int(cy + dx * sin(angle) + dy * cos(angle)) % tile_size

			# Apply mirror
			if mirror:
				var temp = tx
				tx = ty
				ty = temp

	# Ensure valid indices
	tx = absi(tx) % tile_size
	ty = absi(ty) % tile_size

	if ty < grid_data.size() and tx < grid_data[ty].size():
		return grid_data[ty][tx]
	return 0


## Get info about a wallpaper group
static func get_group_info(group: Group) -> Dictionary:
	return GROUP_INFO.get(group, {})


## Get the name of a wallpaper group
static func get_group_name(group: Group) -> String:
	var info = GROUP_INFO.get(group, {})
	return info.get("name", "unknown")


## Get all groups for a specific lattice type
static func get_groups_for_lattice(lattice: String) -> Array[Group]:
	var result: Array[Group] = []
	for group in GROUP_INFO:
		if GROUP_INFO[group]["lattice"] == lattice:
			result.append(group)
	return result
