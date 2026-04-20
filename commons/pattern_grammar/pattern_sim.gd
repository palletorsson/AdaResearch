# pattern_sim.gd — Wallpaper-group tile pattern generator.
#
# Wraps commons/primitives/arrays/wallpaper_groups.gd into a DNA substrate.
# DNA = { group, motif_size, motif_seed, palette, tile_size, canvas_size }.
# Produces a 2D color-index grid that the pattern renderer paints to PNG.
#
# Wallpaper groups are the 17 mathematical ways to tile a 2D plane with a
# repeating pattern — the algebraic vocabulary of textiles, tiles, and
# wallpaper across all cultures. Each group encodes specific symmetry
# operations (translation, rotation, reflection, glide). Two digits of DNA
# — the group name and the motif seed — determine the entire tiling.

extends RefCounted

const WallpaperGroupsScript = preload("res://commons/primitives/arrays/wallpaper_groups.gd")

const GROUPS: Array = [
	"p1", "p2", "pm", "pg", "cm", "pmm", "pmg", "pgg", "cmm",
	"p4", "p4m", "p4g", "p3", "p3m1", "p31m", "p6", "p6m"
]

const PALETTES: Dictionary = {
	"bauhaus":    [[0.93, 0.92, 0.88], [0.76, 0.22, 0.18], [0.94, 0.77, 0.18], [0.14, 0.31, 0.44], [0.10, 0.12, 0.18]],
	"escher":     [[0.12, 0.12, 0.15], [0.92, 0.92, 0.94], [0.45, 0.45, 0.48]],
	"alhambra":   [[0.92, 0.85, 0.62], [0.28, 0.18, 0.12], [0.65, 0.45, 0.22], [0.35, 0.55, 0.52]],
	"tatami":     [[0.88, 0.82, 0.7], [0.35, 0.3, 0.22], [0.55, 0.42, 0.28]],
	"pastel":     [[0.95, 0.75, 0.72], [0.85, 0.9, 0.75], [0.72, 0.82, 0.9], [0.88, 0.82, 0.95]],
	"memphis":    [[0.98, 0.95, 0.9], [0.95, 0.35, 0.4], [0.3, 0.55, 0.75], [0.95, 0.75, 0.3], [0.12, 0.12, 0.15]],
	"persian":    [[0.15, 0.25, 0.45], [0.85, 0.75, 0.35], [0.65, 0.2, 0.25], [0.85, 0.85, 0.8]],
	"monochrome": [[0.95, 0.95, 0.95], [0.1, 0.1, 0.1]],
}


## Resolve group name (string) → WallpaperGroups.Group enum value.
static func group_enum(name: String) -> int:
	match name.to_lower():
		"p1":    return WallpaperGroupsScript.Group.P1
		"p2":    return WallpaperGroupsScript.Group.P2
		"pm":    return WallpaperGroupsScript.Group.PM
		"pg":    return WallpaperGroupsScript.Group.PG
		"cm":    return WallpaperGroupsScript.Group.CM
		"pmm":   return WallpaperGroupsScript.Group.PMM
		"pmg":   return WallpaperGroupsScript.Group.PMG
		"pgg":   return WallpaperGroupsScript.Group.PGG
		"cmm":   return WallpaperGroupsScript.Group.CMM
		"p4":    return WallpaperGroupsScript.Group.P4
		"p4m":   return WallpaperGroupsScript.Group.P4M
		"p4g":   return WallpaperGroupsScript.Group.P4G
		"p3":    return WallpaperGroupsScript.Group.P3
		"p3m1":  return WallpaperGroupsScript.Group.P3M1
		"p31m":  return WallpaperGroupsScript.Group.P31M
		"p6":    return WallpaperGroupsScript.Group.P6
		"p6m":   return WallpaperGroupsScript.Group.P6M
	return WallpaperGroupsScript.Group.P1


## Generate a random motif (tile_size × tile_size grid of color indices 0..n_colors-1)
## Deterministic from seed.
static func generate_motif(tile_size: int, n_colors: int, motif_seed: int,
		density: float = 0.5) -> Array:
	# WallpaperGroups.get_symmetric_color expects grid[ty][tx] — a 2D array.
	var rng := RandomNumberGenerator.new()
	rng.seed = motif_seed
	var grid: Array = []
	for y in tile_size:
		var row: Array = []
		for x in tile_size:
			if rng.randf() < density:
				row.append(rng.randi() % n_colors)
			else:
				row.append(0)
		grid.append(row)
	return grid


## Generate a "dot" motif — center-biased circular blob. More structured than random.
static func generate_dot_motif(tile_size: int, n_colors: int, motif_seed: int,
		radius_factor: float = 0.35) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = motif_seed
	var grid: Array = []
	var center: float = float(tile_size - 1) * 0.5
	var r: float = float(tile_size) * radius_factor
	for y in tile_size:
		var row: Array = []
		for x in tile_size:
			var dx: float = float(x) - center
			var dy: float = float(y) - center
			var d: float = sqrt(dx * dx + dy * dy)
			var cell: int = 0
			if d < r:
				var t: float = d / max(r, 0.001)
				var ci: int = 1 + int(t * float(n_colors - 1))
				if ci >= n_colors: ci = n_colors - 1
				if rng.randf() < 0.9: cell = ci
			row.append(cell)
		grid.append(row)
	return grid


## Render the pattern to a PackedByteArray image (RGBA8, canvas_size × canvas_size).
## Each output pixel queries WallpaperGroups.get_symmetric_color to find its tile
## coordinate, then looks up the motif color index → palette.
static func render_to_image(cfg: Dictionary) -> Image:
	var group_name: String = String(cfg.get("group", "p4m"))
	var tile_size: int = int(cfg.get("tile_size", 32))
	var canvas_size: int = int(cfg.get("canvas_size", 512))
	var motif_seed: int = int(cfg.get("motif_seed", 7))
	var palette_name: String = String(cfg.get("palette", "bauhaus"))
	var motif_type: String = String(cfg.get("motif", "random"))
	var density: float = float(cfg.get("density", 0.5))

	var palette: Array = PALETTES.get(palette_name, PALETTES["bauhaus"])
	var n_colors: int = palette.size()
	var group_val: int = group_enum(group_name)

	var motif: Array
	match motif_type:
		"dot":   motif = generate_dot_motif(tile_size, n_colors, motif_seed,
				float(cfg.get("radius_factor", 0.35)))
		_:       motif = generate_motif(tile_size, n_colors, motif_seed, density)

	var img := Image.create(canvas_size, canvas_size, false, Image.FORMAT_RGBA8)
	for y in canvas_size:
		for x in canvas_size:
			var ci: int = WallpaperGroupsScript.get_symmetric_color(
				x, y, tile_size, motif, group_val)
			ci = clampi(ci, 0, n_colors - 1)
			var c: Array = palette[ci]
			img.set_pixel(x, y, Color(float(c[0]), float(c[1]), float(c[2])))
	return img
