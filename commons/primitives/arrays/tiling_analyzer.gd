class_name TilingAnalyzer
extends RefCounted

## Analyzes a 2D color grid to determine its wallpaper group and fundamental domain.
## Works on any pattern regardless of cultural origin.
##
## Uses the standard classification flowchart for the 17 wallpaper groups:
## 1. Find smallest translation period
## 2. Check highest rotation order (1, 2, 3, 4, 6)
## 3. Check for reflections and glide reflections
## 4. Classify into one of 17 groups

## Tolerance for matching (allows for small imperfections in hand-drawn patterns)
var match_tolerance: float = 0.9  # 90% of cells must match


## Analyze a 2D color grid and return its symmetry classification.
## Returns: { group: WallpaperGroups.Group, fundamental_domain: Array,
##            period_size: Vector2i, confidence: float, rotation_order: int }
func analyze(grid_data: Array, grid_width: int, grid_height: int) -> Dictionary:
	var result := {
		"group": WallpaperGroups.Group.P1,
		"fundamental_domain": [],
		"period_size": Vector2i(grid_width, grid_height),
		"confidence": 0.0,
		"rotation_order": 1
	}

	if grid_data.is_empty() or grid_width == 0 or grid_height == 0:
		return result

	# Step 1: Find translation period
	var period := _find_translation_period(grid_data, grid_width, grid_height)
	result["period_size"] = period

	# Step 2: Check rotation orders (highest first)
	var rot6 := _check_rotation(grid_data, grid_width, grid_height, 6, period)
	var rot4 := _check_rotation(grid_data, grid_width, grid_height, 4, period)
	var rot3 := _check_rotation(grid_data, grid_width, grid_height, 3, period)
	var rot2 := _check_rotation(grid_data, grid_width, grid_height, 2, period)

	# Step 3: Check reflections and glides
	var has_mirror_x := _check_mirror_x(grid_data, grid_width, grid_height, period)
	var has_mirror_y := _check_mirror_y(grid_data, grid_width, grid_height, period)
	var has_mirror_diag := _check_mirror_diagonal(grid_data, grid_width, grid_height, period)
	var has_glide_x := _check_glide_x(grid_data, grid_width, grid_height, period)
	var has_glide_y := _check_glide_y(grid_data, grid_width, grid_height, period)

	# Step 4: Classify using decision tree
	var group := _classify(rot6, rot4, rot3, rot2,
		has_mirror_x, has_mirror_y, has_mirror_diag,
		has_glide_x, has_glide_y)
	result["group"] = group

	# Determine rotation order for metadata
	if rot6:
		result["rotation_order"] = 6
	elif rot4:
		result["rotation_order"] = 4
	elif rot3:
		result["rotation_order"] = 3
	elif rot2:
		result["rotation_order"] = 2

	# Step 5: Extract fundamental domain
	result["fundamental_domain"] = _extract_fundamental_domain(
		grid_data, grid_width, grid_height, period, group)

	# Calculate confidence based on symmetry match quality
	result["confidence"] = _calculate_confidence(
		grid_data, grid_width, grid_height, period, group)

	return result


## Find the smallest translation period (px, py) such that the pattern repeats.
func _find_translation_period(data: Array, w: int, h: int) -> Vector2i:
	var px := 1
	var py := 1

	# Find horizontal period
	for test_px in range(1, w + 1):
		if _is_periodic_x(data, w, h, test_px):
			px = test_px
			break

	# Find vertical period
	for test_py in range(1, h + 1):
		if _is_periodic_y(data, w, h, test_py):
			py = test_py
			break

	return Vector2i(px, py)


func _is_periodic_x(data: Array, w: int, h: int, period: int) -> bool:
	if period >= w:
		return true
	var matches := 0
	var total := 0
	for y in range(h):
		for x in range(period, w):
			total += 1
			if data[y][x] == data[y][x % period]:
				matches += 1
	return total == 0 or float(matches) / float(total) >= match_tolerance


func _is_periodic_y(data: Array, w: int, h: int, period: int) -> bool:
	if period >= h:
		return true
	var matches := 0
	var total := 0
	for y in range(period, h):
		for x in range(w):
			total += 1
			if data[y][x] == data[y % period][x]:
				matches += 1
	return total == 0 or float(matches) / float(total) >= match_tolerance


## Check for n-fold rotational symmetry within one period.
func _check_rotation(data: Array, w: int, h: int, n: int, period: Vector2i) -> bool:
	var pw := period.x
	var ph := period.y
	if pw == 0 or ph == 0:
		return false

	var cx := pw / 2.0
	var cy := ph / 2.0
	var angle := TAU / float(n)

	var matches := 0
	var total := 0

	for y in range(ph):
		for x in range(pw):
			var dx := float(x) - cx
			var dy := float(y) - cy
			var rx := dx * cos(angle) - dy * sin(angle) + cx
			var ry := dx * sin(angle) + dy * cos(angle) + cy
			var ix := int(round(rx)) % pw
			var iy := int(round(ry)) % ph
			if ix < 0:
				ix += pw
			if iy < 0:
				iy += ph
			if ix >= 0 and ix < pw and iy >= 0 and iy < ph:
				total += 1
				if data[y % h][x % w] == data[iy % h][ix % w]:
					matches += 1

	return total > 0 and float(matches) / float(total) >= match_tolerance


## Check for mirror symmetry across vertical axis (x reflection).
func _check_mirror_x(data: Array, w: int, h: int, period: Vector2i) -> bool:
	var pw := period.x
	var ph := period.y
	var matches := 0
	var total := 0

	for y in range(ph):
		for x in range(pw / 2):
			var mx := pw - 1 - x
			if mx >= 0 and mx < pw:
				total += 1
				if data[y % h][x % w] == data[y % h][mx % w]:
					matches += 1

	return total > 0 and float(matches) / float(total) >= match_tolerance


## Check for mirror symmetry across horizontal axis (y reflection).
func _check_mirror_y(data: Array, w: int, h: int, period: Vector2i) -> bool:
	var pw := period.x
	var ph := period.y
	var matches := 0
	var total := 0

	for y in range(ph / 2):
		for x in range(pw):
			var my := ph - 1 - y
			if my >= 0 and my < ph:
				total += 1
				if data[y % h][x % w] == data[my % h][x % w]:
					matches += 1

	return total > 0 and float(matches) / float(total) >= match_tolerance


## Check for diagonal mirror symmetry (x <-> y swap).
func _check_mirror_diagonal(data: Array, w: int, h: int, period: Vector2i) -> bool:
	var pw := period.x
	var ph := period.y
	var p := mini(pw, ph)
	var matches := 0
	var total := 0

	for y in range(p):
		for x in range(y):
			total += 1
			if data[y % h][x % w] == data[x % h][y % w]:
				matches += 1

	return total > 0 and float(matches) / float(total) >= match_tolerance


## Check for glide reflection along x (mirror x + half y translation).
func _check_glide_x(data: Array, w: int, h: int, period: Vector2i) -> bool:
	var pw := period.x
	var ph := period.y
	var half_y := ph / 2
	if half_y == 0:
		return false

	var matches := 0
	var total := 0

	for y in range(ph):
		for x in range(pw / 2):
			var mx := pw - 1 - x
			var my := (y + half_y) % ph
			if mx >= 0 and mx < pw:
				total += 1
				if data[y % h][x % w] == data[my % h][mx % w]:
					matches += 1

	return total > 0 and float(matches) / float(total) >= match_tolerance


## Check for glide reflection along y (mirror y + half x translation).
func _check_glide_y(data: Array, w: int, h: int, period: Vector2i) -> bool:
	var pw := period.x
	var ph := period.y
	var half_x := pw / 2
	if half_x == 0:
		return false

	var matches := 0
	var total := 0

	for y in range(ph / 2):
		for x in range(pw):
			var mx := (x + half_x) % pw
			var my := ph - 1 - y
			if my >= 0 and my < ph:
				total += 1
				if data[y % h][x % w] == data[my % h][mx % w]:
					matches += 1

	return total > 0 and float(matches) / float(total) >= match_tolerance


## Classify into one of 17 wallpaper groups using a decision tree.
## Based on rotation order, then presence of reflections and glides.
func _classify(rot6: bool, rot4: bool, rot3: bool, rot2: bool,
		mirror_x: bool, mirror_y: bool, mirror_diag: bool,
		glide_x: bool, glide_y: bool) -> WallpaperGroups.Group:

	var has_mirror := mirror_x or mirror_y
	var has_glide := glide_x or glide_y

	# 6-fold rotation
	if rot6:
		if has_mirror:
			return WallpaperGroups.Group.P6M
		return WallpaperGroups.Group.P6

	# 4-fold rotation
	if rot4:
		if has_mirror and mirror_diag:
			return WallpaperGroups.Group.P4M
		if has_mirror:
			return WallpaperGroups.Group.P4G
		return WallpaperGroups.Group.P4

	# 3-fold rotation
	if rot3:
		if has_mirror and mirror_diag:
			return WallpaperGroups.Group.P31M
		if has_mirror:
			return WallpaperGroups.Group.P3M1
		return WallpaperGroups.Group.P3

	# 2-fold rotation
	if rot2:
		if mirror_x and mirror_y:
			if has_glide:
				return WallpaperGroups.Group.CMM
			return WallpaperGroups.Group.PMM
		if has_mirror and has_glide:
			return WallpaperGroups.Group.PMG
		if has_glide:
			return WallpaperGroups.Group.PGG
		return WallpaperGroups.Group.P2

	# No rotation
	if mirror_x or mirror_y:
		if has_glide:
			return WallpaperGroups.Group.CM
		return WallpaperGroups.Group.PM
	if has_glide:
		return WallpaperGroups.Group.PG

	# No symmetry beyond translation
	return WallpaperGroups.Group.P1


## Extract the fundamental domain (minimal generating region) for the identified group.
func _extract_fundamental_domain(data: Array, w: int, h: int,
		period: Vector2i, _group: WallpaperGroups.Group) -> Array:
	var pw := period.x
	var ph := period.y

	# Extract one period as the fundamental domain
	var domain: Array = []
	for y in range(ph):
		var row: Array = []
		for x in range(pw):
			row.append(data[y % h][x % w])
		domain.append(row)

	return domain


## Calculate confidence score (how well the pattern matches the identified group).
func _calculate_confidence(data: Array, w: int, h: int,
		period: Vector2i, group: WallpaperGroups.Group) -> float:
	var pw := period.x
	var ph := period.y
	if pw == 0 or ph == 0:
		return 0.0

	# Reconstruct the full grid using the identified group and compare
	var domain := _extract_fundamental_domain(data, w, h, period, group)
	var matches := 0
	var total := 0

	for y in range(h):
		for x in range(w):
			total += 1
			var reconstructed := WallpaperGroups.get_symmetric_color(
				x, y, pw, domain, group)
			if reconstructed == data[y][x]:
				matches += 1

	return float(matches) / float(total) if total > 0 else 0.0
