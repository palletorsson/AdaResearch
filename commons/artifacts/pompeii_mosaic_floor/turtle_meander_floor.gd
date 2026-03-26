# turtle_meander_floor.gd
# Procedural mosaic floor whose border is traced by a TURTLE GRAPHICS engine.
# The same turtle machine generates both the ancient Greek key meander and
# the modern Hilbert space-filling curve — different programs, same machine.
#
# @identity
#   essence: a floor that proves the Greek key IS a turtle program
#   desire: players see that ancient ornament and modern algorithms share a machine
#   critical_parameter: border_mode — switches between meander, Hilbert, Peano
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that L-system / turtle graphics unify ancient and modern pattern
#   needs: [implemented] turtle engine, meander program, Hilbert program, polka-dot field
#   relationships: pompeii_mosaic_floor (sibling), meander_threshold_floor (related motif)
#   truth: the same machine that draws a Greek key draws a Hilbert curve

extends Node3D
class_name TurtleMeanderFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

## 0 = Greek key meander, 1 = Hilbert curve, 2 = Peano curve
@export var border_mode: int = 0
## Key size (meander) or recursion depth (Hilbert/Peano)
@export var meander_depth: int = 3
@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var tiles_short: int = 40
## Border composition: outer dark band, light gap, turtle path zone, light gap, inner dark band
@export var outer_band: int = 1
@export var inner_band: int = 1
@export var path_width: int = 1  ## pixel width of the turtle-drawn band
@export var dot_spacing: int = 3
@export var dot_size_fraction: float = 0.12
@export var jitter_amount: float = 0.15
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.06
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _mi: MeshInstance3D
#var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	tiles_short = int(config.get("tiles_short", tiles_short))
	border_mode = int(config.get("border_mode", border_mode))
	meander_depth = int(config.get("meander_depth", meander_depth))
	outer_band = int(config.get("outer_band", outer_band))
	inner_band = int(config.get("inner_band", inner_band))
	path_width = int(config.get("path_width", path_width))
	dot_spacing = int(config.get("dot_spacing", dot_spacing))
	dot_size_fraction = float(config.get("dot_size_fraction", dot_size_fraction))
	jitter_amount = float(config.get("jitter_amount", jitter_amount))
	wear_level = float(config.get("wear_level", wear_level))
	_build()


# ── Turtle Graphics Engine ──────────────────────────────────────────────────

class MeanderTurtle:
	var pos: Vector2 = Vector2.ZERO
	var dir: int = 0  # 0=right, 1=down, 2=left, 3=up
	var path: Array = []  # Array of Vector2

	func reset(start: Vector2, start_dir: int = 0) -> void:
		pos = start
		dir = start_dir
		path = [pos]

	func forward(steps: int) -> void:
		for i in steps:
			match dir:
				0: pos.x += 1
				1: pos.y += 1
				2: pos.x -= 1
				3: pos.y -= 1
			path.append(Vector2(pos.x, pos.y))

	func turn_right() -> void:
		dir = (dir + 1) % 4

	func turn_left() -> void:
		dir = (dir + 3) % 4

	func turn(angle: int) -> void:
		## angle: +1 = right, -1 = left
		if angle > 0:
			turn_right()
		else:
			turn_left()

	# ── Meander Programs ──

	func meander_tooth(s: int) -> void:
		## One Greek key meander unit — the classic squared spiral.
		## s = number of cells the key extends perpendicular to the edge.
		## The turtle starts on the edge, facing along it.
		## After this call, the turtle has advanced 2*s cells along the edge.
		##
		## The key pattern (s=3, facing right, perpendicular = up):
		##
		##   ██████████      <- go up s, right s*2, down s
		##   ██      ██
		##   ██  ██  ██      <- inner: down (s-2), left (s*2-2), up (s-2)
		##   ██  ██████
		##   ██
		##   ████████████→   <- continue along edge
		##
		## This creates the signature "hooked spiral" of the Greek key.

		if s < 2:
			forward(2)
			return

		var w: int = s * 2  # width of one key unit along the edge

		# Go perpendicular (into the border zone)
		turn_left()
		forward(s)
		# Go along the top
		turn_right()
		forward(w)
		# Go back down
		turn_right()
		forward(s)
		# Hook back: go along the bottom (backward) partway
		turn_right()
		forward(w - 2)
		# Go up into the inner spiral
		turn_right()
		forward(s - 2)
		# Go along inner top
		turn_left()
		forward(w - 2)
		# Come back down to the edge
		turn_left()
		forward(s)

	func meander_border(outer_w: int, outer_h: int, s: int) -> void:
		## Trace Greek key meander around all 4 sides.
		## Each key unit advances 2*s cells along the edge.
		## The turtle starts at (0,0) facing right.
		var key_width: int = s * 2  # each key occupies 2*s along the edge
		var side_lengths: Array[int] = [outer_w, outer_h, outer_w, outer_h]
		for side_idx in 4:
			var side_len: int = side_lengths[side_idx]
			if s <= 1:
				forward(side_len)
				turn_right()
				continue

			var num_keys: int = side_len / key_width
			var remaining: int = side_len - num_keys * key_width

			for _k in num_keys:
				meander_tooth(s)

			if remaining > 0:
				forward(remaining)

			turn_right()

	# ── Hilbert Curve Program ──

	func hilbert(level: int, angle: int) -> void:
		if level <= 0:
			return
		turn(angle)
		hilbert(level - 1, -angle)
		forward(1)
		turn(-angle)
		hilbert(level - 1, angle)
		forward(1)
		hilbert(level - 1, angle)
		turn(-angle)
		forward(1)
		hilbert(level - 1, -angle)
		turn(angle)

	# ── Peano Curve Program ──

	func peano(level: int, angle: int) -> void:
		if level <= 0:
			return
		turn(angle)
		peano(level - 1, -angle)
		forward(1)
		peano(level - 1, angle)
		forward(1)
		peano(level - 1, -angle)
		turn(-angle)
		forward(1)
		turn(-angle)
		peano(level - 1, angle)
		forward(1)
		peano(level - 1, -angle)
		forward(1)
		peano(level - 1, angle)
		turn(angle)


# ── Build ────────────────────────────────────────────────────────────────────

func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	#if _body:
		#_body.queue_free()
		#_body = null

	# Grid dimensions
	# The meander tooth goes s-1 cells deep; add 1 for the edge line itself
	var zone_depth: int = meander_depth
	var border_each: int = outer_band + inner_band + zone_depth + 2  # +2 for light gap bands
	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var total_short := tiles_short + border_each * 2
	var ts := short_m / float(total_short)
	var total_long := int(round(long_m / ts))

	var gw: int = total_long if is_wide else total_short
	var gh: int = total_short if is_wide else total_long

	var fw := gw * ts
	var fh := gh * ts

	# Field region (inside borders)
	var fx0 := border_each
	var fy0 := border_each
	var fx1 := gw - border_each
	var fy1 := gh - border_each

	var grout_w := ts * grout_width_fraction

	# Vertex arrays for each color surface
	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()
	var path_verts := PackedVector3Array()  # turtle path — separate layer above light

	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# ── 1. Outer dark band ──
	for i in outer_band:
		# Top row
		for tx in range(i, gw - i):
			dark_verts = _add_rect.call(dark_verts, tx * ts, i * ts, ts, ts)
		# Bottom row
		for tx in range(i, gw - i):
			dark_verts = _add_rect.call(dark_verts, tx * ts, (gh - 1 - i) * ts, ts, ts)
		# Left column (exclude corners)
		for ty in range(i + 1, gh - 1 - i):
			dark_verts = _add_rect.call(dark_verts, i * ts, ty * ts, ts, ts)
		# Right column (exclude corners)
		for ty in range(i + 1, gh - 1 - i):
			dark_verts = _add_rect.call(dark_verts, (gw - 1 - i) * ts, ty * ts, ts, ts)

	# ── 2. Light gap band (between outer dark and turtle zone) ──
	var gap1_inset := outer_band
	for tx in range(gap1_inset, gw - gap1_inset):
		light_verts = _add_rect.call(light_verts, tx * ts, gap1_inset * ts, ts, ts)
	for tx in range(gap1_inset, gw - gap1_inset):
		light_verts = _add_rect.call(light_verts, tx * ts, (gh - 1 - gap1_inset) * ts, ts, ts)
	for ty in range(gap1_inset + 1, gh - 1 - gap1_inset):
		light_verts = _add_rect.call(light_verts, gap1_inset * ts, ty * ts, ts, ts)
	for ty in range(gap1_inset + 1, gh - 1 - gap1_inset):
		light_verts = _add_rect.call(light_verts, (gw - 1 - gap1_inset) * ts, ty * ts, ts, ts)

	# ── 3. Turtle path zone ──
	# The turtle path zone is a band of meander_depth+1 cells wide on each side.
	# First fill the entire zone with light, then overdraw the turtle path in dark.
	var zone_inset := outer_band + 1  # after outer dark + light gap
	var zone_end_inset := zone_inset + zone_depth
	# Fill zone with light background
	for ty in range(zone_inset, gh - zone_inset):
		for tx in range(zone_inset, gw - zone_inset):
			# Only the zone ring, not the interior
			if tx >= zone_end_inset and tx < gw - zone_end_inset and ty >= zone_end_inset and ty < gh - zone_end_inset:
				continue
			light_verts = _add_rect.call(light_verts, tx * ts, ty * ts, ts, ts)

	# Run turtle program to get the path
	var turtle := MeanderTurtle.new()
	var turtle_zone_w := gw - zone_inset * 2
	var turtle_zone_h := gh - zone_inset * 2

	# Build a grid of which cells the turtle visits
	var visited := {}

	match border_mode:
		0:  # Greek key meander
			# Start at bottom-left corner, facing right.
			# Teeth go UPWARD (turn_left from right = up = y decreases).
			# This keeps the path inside the zone (0..zone_h-1).
			turtle.reset(Vector2(0, turtle_zone_h - 1), 0)
			turtle.meander_border(turtle_zone_w, turtle_zone_h, meander_depth)
		1:  # Hilbert curve — run along each side
			_trace_hilbert_border(turtle, turtle_zone_w, turtle_zone_h, meander_depth)
		2:  # Peano curve — run along each side
			_trace_peano_border(turtle, turtle_zone_w, turtle_zone_h, meander_depth)

	# Mark visited cells with path_width thickening, clipped to the zone ring
	var half_w: int = (path_width - 1) / 2
	for p in turtle.path:
		var px := int(p.x)
		var py := int(p.y)
		for dy in range(-half_w, half_w + 1):
			for dx in range(-half_w, half_w + 1):
				var cx := px + dx
				var cy := py + dy
				# Clip to zone bounds
				if cx < 0 or cx >= turtle_zone_w or cy < 0 or cy >= turtle_zone_h:
					continue
				# Clip to zone ring (exclude interior)
				if cx >= zone_depth and cx < turtle_zone_w - zone_depth and cy >= zone_depth and cy < turtle_zone_h - zone_depth:
					continue
				var key := cx * 10000 + cy
				visited[key] = true

	# Draw the turtle path as dark cells on a separate layer above the light zone
	for key in visited:
		@warning_ignore("integer_division")
		var cx: int = key / 10000
		var cy: int = key % 10000
		var wx := (zone_inset + cx) * ts
		var wz := (zone_inset + cy) * ts
		path_verts = _add_rect.call(path_verts, wx, wz, ts, ts)

	# ── 4. Light gap band (between turtle zone and inner dark) ──
	var gap2_inset := zone_end_inset
	for tx in range(gap2_inset, gw - gap2_inset):
		light_verts = _add_rect.call(light_verts, tx * ts, gap2_inset * ts, ts, ts)
	for tx in range(gap2_inset, gw - gap2_inset):
		light_verts = _add_rect.call(light_verts, tx * ts, (gh - 1 - gap2_inset) * ts, ts, ts)
	for ty in range(gap2_inset + 1, gh - 1 - gap2_inset):
		light_verts = _add_rect.call(light_verts, gap2_inset * ts, ty * ts, ts, ts)
	for ty in range(gap2_inset + 1, gh - 1 - gap2_inset):
		light_verts = _add_rect.call(light_verts, (gw - 1 - gap2_inset) * ts, ty * ts, ts, ts)

	# ── 5. Inner dark band ──
	var inner_inset := gap2_inset + 1
	for i in inner_band:
		var ii := inner_inset + i
		for tx in range(ii, gw - ii):
			dark_verts = _add_rect.call(dark_verts, tx * ts, ii * ts, ts, ts)
		for tx in range(ii, gw - ii):
			dark_verts = _add_rect.call(dark_verts, tx * ts, (gh - 1 - ii) * ts, ts, ts)
		for ty in range(ii + 1, gh - 1 - ii):
			dark_verts = _add_rect.call(dark_verts, ii * ts, ty * ts, ts, ts)
		for ty in range(ii + 1, gh - 1 - ii):
			dark_verts = _add_rect.call(dark_verts, (gw - 1 - ii) * ts, ty * ts, ts, ts)

	# ── 6. Interior polka-dot dark field ──
	# Dark background for the entire interior field
	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			dark_verts = _add_rect.call(dark_verts, tx * ts, ty * ts, ts, ts)

	# Light dots scattered on the dark field
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # deterministic
	var field_w := fx1 - fx0
	var field_h := fy1 - fy0
	if dot_spacing > 0:
		var dot_cols := field_w / dot_spacing
		var dot_rows := field_h / dot_spacing
		var dot_size := ts * dot_size_fraction * dot_spacing
		for row in dot_rows:
			for col in dot_cols:
				var cx := fx0 + col * dot_spacing + dot_spacing / 2
				var cy := fy0 + row * dot_spacing + dot_spacing / 2
				var jx := rng.randf_range(-jitter_amount, jitter_amount) * dot_spacing
				var jy := rng.randf_range(-jitter_amount, jitter_amount) * dot_spacing
				var dx := (cx + jx) * ts - dot_size * 0.5
				var dz := (cy + jy) * ts - dot_size * 0.5
				light_verts = _add_rect.call(light_verts, dx, dz, dot_size, dot_size)

	# ── 7. Grout lines ──
	if grout_w > 0.001:
		var half := grout_w * 0.5
		for gy in range(0, gh + 1):
			var z := gy * ts
			grout_verts = _add_rect.call(grout_verts, 0.0, z - half, fw, grout_w)
		for gx in range(0, gw + 1):
			var x := gx * ts
			grout_verts = _add_rect.call(grout_verts, x - half, 0.0, grout_w, fh)

	# ── Z-fighting fix ──
	# Layer order: grout < dark < light < path (turtle) < dots
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts
	grout_verts = _offset_y.call(grout_verts, -0.001)
	dark_verts = _offset_y.call(dark_verts, 0.0)
	light_verts = _offset_y.call(light_verts, 0.001)
	path_verts = _offset_y.call(path_verts, 0.002)

	# ── Build ArrayMesh ──
	var arr_mesh := ArrayMesh.new()

	if dark_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = dark_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(0, MosaicPalette.create_material(color_dark, wear_level))

	if light_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = light_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_light, wear_level))

	if path_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = path_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_dark, wear_level))

	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(grout_color, wear_level))

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)
	add_child(_mi)

	# ── StaticBody3D + CollisionShape3D ──
	#_body = StaticBody3D.new()
	#var col := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(fw, 0.01, fh)
	#col.shape = box
	#_body.add_child(col)
	#_body.position = Vector3(0.0, 0.0, 0.0)
	#add_child(_body)

	var mode_names: Array[String] = ["Greek Key Meander", "Hilbert Curve", "Peano Curve"]
	var mode_name: String = mode_names[clampi(border_mode, 0, 2)]
	print("[TurtleMeanderFloor] Built %dx%d grid, mode=%s, depth=%d (%d dark, %d light, %d grout tris)" % [
		gw, gh, mode_name, meander_depth,
		dark_verts.size() / 3, light_verts.size() / 3, grout_verts.size() / 3,
	])


# ── Hilbert border: trace a Hilbert curve segment along each side ──

func _trace_hilbert_border(turtle: MeanderTurtle, zone_w: int, zone_h: int, depth: int) -> void:
	# For the Hilbert border, we trace a Hilbert curve that fits within the
	# border zone. The curve is laid out along each side of the rectangle.
	# We use a continuous Hilbert curve that wraps around the border.
	var curve_size := int(pow(2, depth))  # Hilbert curve fills a 2^n x 2^n grid

	# Top side
	turtle.reset(Vector2.ZERO, 0)
	var segments_x := zone_w / curve_size if curve_size > 0 else 1
	var segments_y := zone_h / curve_size if curve_size > 0 else 1
	segments_x = maxi(segments_x, 1)
	segments_y = maxi(segments_y, 1)

	# Trace one large Hilbert curve that covers the border band area
	# We'll use a single Hilbert curve on each side, scaled to fill the zone
	# Top edge
	turtle.reset(Vector2(0, 0), 0)
	for _seg in segments_x:
		turtle.hilbert(depth, 1)
		turtle.forward(1)

	# Right edge
	turtle.turn_right()
	for _seg in segments_y:
		turtle.hilbert(depth, 1)
		turtle.forward(1)

	# Bottom edge
	turtle.turn_right()
	for _seg in segments_x:
		turtle.hilbert(depth, 1)
		turtle.forward(1)

	# Left edge
	turtle.turn_right()
	for _seg in segments_y:
		turtle.hilbert(depth, 1)
		turtle.forward(1)


func _trace_peano_border(turtle: MeanderTurtle, zone_w: int, zone_h: int, depth: int) -> void:
	var curve_size := int(pow(3, depth))
	var segments_x := zone_w / curve_size if curve_size > 0 else 1
	var segments_y := zone_h / curve_size if curve_size > 0 else 1
	segments_x = maxi(segments_x, 1)
	segments_y = maxi(segments_y, 1)

	turtle.reset(Vector2(0, 0), 0)
	for _seg in segments_x:
		turtle.peano(depth, 1)
		turtle.forward(1)

	turtle.turn_right()
	for _seg in segments_y:
		turtle.peano(depth, 1)
		turtle.forward(1)

	turtle.turn_right()
	for _seg in segments_x:
		turtle.peano(depth, 1)
		turtle.forward(1)

	turtle.turn_right()
	for _seg in segments_y:
		turtle.peano(depth, 1)
		turtle.forward(1)
