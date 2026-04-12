# MorphoSweep.gd — Generalized sweep: what glass tubes learn from math surfaces
#
# Glass tubes sweep a CIRCLE along STRAIGHT/CORNER paths.
# Math surfaces sweep ARBITRARY PROFILES along ARBITRARY CURVES with TWIST and GROWTH.
# This class unifies both: any cross-section, any path, any radius evolution, any twist.
#
# The 4 generalizations from math surfaces:
#   1. Variable radius (seashell: exponential growth along spiral)
#   2. Variable cross-section (helicoid: line, möbius: rectangle, tube: circle)
#   3. Twist along path (möbius: 180° half-twist, torus knot: winding)
#   4. Complex paths (torus knot: knotted, seashell: logarithmic spiral)

class_name MorphoSweep
extends RefCounted


# ═══════════════════════════════════════════════════════════════
# CROSS-SECTION PROFILES (what gets swept)
# ═══════════════════════════════════════════════════════════════

## Circle cross-section — what glass tubes use.
static func profile_circle(segments: int = 12) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for i in segments:
		var angle: float = TAU * float(i) / float(segments)
		pts.append(Vector2(cos(angle), sin(angle)))
	return pts

## Ellipse cross-section — compressed tube.
static func profile_ellipse(segments: int = 12, aspect: float = 0.5) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for i in segments:
		var angle: float = TAU * float(i) / float(segments)
		pts.append(Vector2(cos(angle), sin(angle) * aspect))
	return pts

## Rectangle cross-section — ribbon, möbius strip base.
static func profile_rectangle(width: float = 1.0, height: float = 0.1) -> Array[Vector2]:
	var hw: float = width * 0.5
	var hh: float = height * 0.5
	return [
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh),
	]

## Line cross-section — helicoid (zero thickness, just a flat line).
static func profile_line(width: float = 1.0, steps: int = 4) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for i in steps + 1:
		var t: float = float(i) / float(steps) - 0.5
		pts.append(Vector2(t * width, 0.0))
	return pts

## Star cross-section — decorative tube.
static func profile_star(points: int = 5, inner_ratio: float = 0.5) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for i in points * 2:
		var angle: float = TAU * float(i) / float(points * 2)
		var r: float = 1.0 if i % 2 == 0 else inner_ratio
		pts.append(Vector2(cos(angle) * r, sin(angle) * r))
	return pts

## Polygon cross-section — triangle, hex, etc.
static func profile_polygon(sides: int = 6) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for i in sides:
		var angle: float = TAU * float(i) / float(sides)
		pts.append(Vector2(cos(angle), sin(angle)))
	return pts


# ═══════════════════════════════════════════════════════════════
# PATH CURVES (where the sweep travels)
# ═══════════════════════════════════════════════════════════════

## Straight line path.
static func path_line(start: Vector3, end: Vector3) -> Callable:
	return func(t: float) -> Vector3: return start.lerp(end, t)

## Circle/ring path.
static func path_circle(radius: float = 1.0, axis: Vector3 = Vector3.UP) -> Callable:
	return func(t: float) -> Vector3:
		var angle: float = t * TAU
		if axis == Vector3.UP:
			return Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		elif axis == Vector3.RIGHT:
			return Vector3(0, cos(angle) * radius, sin(angle) * radius)
		return Vector3(cos(angle) * radius, sin(angle) * radius, 0)

## Helix path (spiral staircase).
static func path_helix(radius: float = 1.0, height: float = 2.0, turns: float = 3.0) -> Callable:
	return func(t: float) -> Vector3:
		var angle: float = t * TAU * turns
		return Vector3(cos(angle) * radius, t * height, sin(angle) * radius)

## Torus knot path — what the torus_knot math surface uses.
static func path_torus_knot(major_r: float = 1.0, minor_r: float = 0.4,
		p_val: int = 2, q_val: int = 3) -> Callable:
	return func(t: float) -> Vector3:
		var angle: float = t * TAU
		var r: float = major_r + minor_r * cos(q_val * angle)
		return Vector3(r * cos(p_val * angle), minor_r * sin(q_val * angle), r * sin(p_val * angle))

## Logarithmic spiral path — what the seashell uses.
static func path_log_spiral(growth: float = 0.15, turns: float = 4.0) -> Callable:
	return func(t: float) -> Vector3:
		var angle: float = t * TAU * turns
		var r: float = 0.1 * exp(angle * growth)
		return Vector3(r * cos(angle), t * r * 0.3, r * sin(angle))

## S-bend path — what glass tubes use.
static func path_sbend(width: float = 1.0, height: float = 1.0) -> Callable:
	return func(t: float) -> Vector3:
		return Vector3(0, t * height, sin(t * PI) * width * 0.3)

## Figure-eight path.
static func path_figure_eight(radius: float = 1.0) -> Callable:
	return func(t: float) -> Vector3:
		var angle: float = t * TAU
		return Vector3(cos(angle) * radius, sin(2.0 * angle) * radius * 0.5, sin(angle) * radius)


# ═══════════════════════════════════════════════════════════════
# RADIUS FUNCTIONS (how the tube width evolves along the path)
# ═══════════════════════════════════════════════════════════════

## Constant radius — glass tube default.
static func radius_constant(r: float = 0.1) -> Callable:
	return func(_t: float) -> float: return r

## Linear taper — cone.
static func radius_taper(start: float = 0.1, end: float = 0.02) -> Callable:
	return func(t: float) -> float: return lerpf(start, end, t)

## Exponential growth — seashell.
static func radius_exponential(base: float = 0.02, growth: float = 0.15) -> Callable:
	return func(t: float) -> float: return base * exp(t * growth * TAU)

## Pulsing — varying along path.
static func radius_pulse(base: float = 0.1, amplitude: float = 0.03,
		frequency: float = 5.0) -> Callable:
	return func(t: float) -> float: return base + sin(t * TAU * frequency) * amplitude

## Bulge — wider in the middle (flask shape).
static func radius_bulge(base: float = 0.05, bulge: float = 0.15) -> Callable:
	return func(t: float) -> float: return base + sin(t * PI) * bulge


# ═══════════════════════════════════════════════════════════════
# THE GENERALIZED SWEEP
# ═══════════════════════════════════════════════════════════════

## Sweep a cross-section profile along a path curve with variable radius and twist.
## This is the universal tube/surface generator.
##
## profile: Array[Vector2] — the cross-section shape (circle, rectangle, star, etc.)
## path_func: Callable(float) → Vector3 — the path curve, t in [0, 1]
## radius_func: Callable(float) → float — radius at each t
## twist_degrees: total twist of the cross-section over the full path
## segments: number of rings along the path
## close_path: if true, connects last ring to first (for closed loops like torus knots)
static func sweep(
		profile: Array,
		path_func: Callable,
		radius_func: Callable = Callable(),
		twist_degrees: float = 0.0,
		segments: int = 48,
		close_path: bool = false) -> Mesh:

	if profile.is_empty():
		return null

	# Build as a continuous parametric surface — no segments, no rings.
	# Every vertex is computed directly from (u, v) like math surfaces do.
	# u = position along path [0, 1], v = position around cross-section [0, 1]

	var sides: int = profile.size()
	var default_radius: float = 0.1
	var u_steps: int = segments
	var v_steps: int = sides

	# Pre-compute the Frenet frame along the path using parallel transport
	var frames: Array = []  # [{center, normal, binormal}] per u step
	var prev_normal := Vector3.ZERO

	for ui in u_steps + 1:
		var u: float = float(ui) / float(u_steps)
		if close_path and ui == u_steps:
			u = 0.0

		var center: Vector3 = path_func.call(u) as Vector3
		var dt: float = 0.0005
		var u_next: float = minf(u + dt, 1.0) if not close_path else fmod(u + dt, 1.0)
		var u_prev: float = maxf(u - dt, 0.0) if not close_path else fmod(u - dt + 1.0, 1.0)
		var tangent: Vector3 = ((path_func.call(u_next) as Vector3) - (path_func.call(u_prev) as Vector3)).normalized()
		if tangent.length_squared() < 0.001:
			tangent = Vector3.UP

		var normal: Vector3
		if prev_normal == Vector3.ZERO:
			var ref := Vector3.RIGHT
			normal = tangent.cross(ref)
			if normal.length_squared() < 0.001:
				normal = tangent.cross(Vector3.UP)
			normal = normal.normalized()
		else:
			normal = prev_normal - tangent * tangent.dot(prev_normal)
			if normal.length_squared() < 0.001:
				normal = prev_normal
			else:
				normal = normal.normalized()
		var binormal: Vector3 = tangent.cross(normal).normalized()
		prev_normal = normal

		frames.append({"center": center, "normal": normal, "binormal": binormal})

	# Compute vertex positions + normals directly
	var all_verts := PackedVector3Array()
	var all_normals := PackedVector3Array()
	var all_uvs := PackedVector2Array()

	for ui in u_steps + 1:
		var u: float = float(ui) / float(u_steps)
		var frame: Dictionary = frames[ui if ui < frames.size() else frames.size() - 1]
		var center: Vector3 = frame["center"]
		var fnormal: Vector3 = frame["normal"]
		var fbinormal: Vector3 = frame["binormal"]

		var radius: float = default_radius
		if radius_func.is_valid():
			radius = radius_func.call(u) as float

		var twist_rad: float = deg_to_rad(twist_degrees * u)
		var cos_tw: float = cos(twist_rad)
		var sin_tw: float = sin(twist_rad)

		for vi in v_steps:
			var pt: Vector2 = profile[vi] as Vector2
			# Twist
			var rotated := Vector2(
				pt.x * cos_tw - pt.y * sin_tw,
				pt.x * sin_tw + pt.y * cos_tw)
			# Map to 3D
			var offset: Vector3 = (fnormal * rotated.x + fbinormal * rotated.y) * radius
			var vertex: Vector3 = center + offset
			# Normal points outward from center
			var vert_normal: Vector3 = offset.normalized()

			all_verts.append(vertex)
			all_normals.append(vert_normal)
			all_uvs.append(Vector2(float(vi) / float(v_steps), u))

	# Build index buffer
	var indices := PackedInt32Array()
	var u_count: int = u_steps + 1
	var connect_u: int = u_steps if not close_path else u_steps + 1

	for ui in connect_u:
		var ui_next: int = (ui + 1) % u_count if close_path else ui + 1
		if ui_next >= u_count:
			continue
		for vi in v_steps:
			var vi_next: int = (vi + 1) % v_steps

			var i00: int = ui * v_steps + vi
			var i01: int = ui * v_steps + vi_next
			var i10: int = ui_next * v_steps + vi
			var i11: int = ui_next * v_steps + vi_next

			indices.append(i00); indices.append(i10); indices.append(i01)
			indices.append(i01); indices.append(i10); indices.append(i11)

	# Build ArrayMesh with computed normals (no generate_normals needed)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = all_verts
	arrays[Mesh.ARRAY_NORMAL] = all_normals
	arrays[Mesh.ARRAY_TEX_UV] = all_uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


# ═══════════════════════════════════════════════════════════════
# PRESETS — Named combinations (what each system teaches)
# ═══════════════════════════════════════════════════════════════

## Glass tube — circle profile, straight path, constant radius. The starting point.
static func glass_tube(length: float = 1.0, radius: float = 0.1, segments: int = 12) -> Mesh:
	return sweep(profile_circle(segments), path_line(Vector3.ZERO, Vector3(0, length, 0)),
		radius_constant(radius), 0.0, 24)

## Möbius strip — rectangle profile, circle path, 180° twist. Topology lesson.
static func mobius_strip(major_r: float = 1.0, width: float = 0.4, twist: float = 180.0) -> Mesh:
	return sweep(profile_rectangle(width, 0.02), path_circle(major_r),
		radius_constant(1.0), twist, 64, true)

## Seashell — circle profile, log spiral path, exponential radius. Growth lesson.
static func seashell(growth: float = 0.15, turns: float = 4.0, base_r: float = 0.02) -> Mesh:
	return sweep(profile_circle(12), path_log_spiral(growth, turns),
		radius_exponential(base_r, growth), 0.0, 96)

## Torus knot — circle profile, knotted path, constant radius. Topology lesson.
static func torus_knot(p_val: int = 2, q_val: int = 3, tube_r: float = 0.05) -> Mesh:
	return sweep(profile_circle(8), path_torus_knot(1.0, 0.4, p_val, q_val),
		radius_constant(tube_r), 0.0, 256, true)

## Helicoid — line profile, helix path, constant radius. Minimal surface lesson.
static func helicoid(radius: float = 0.5, height: float = 2.0, turns: float = 3.0) -> Mesh:
	return sweep(profile_line(radius, 6), path_helix(0.001, height, turns),
		radius_constant(1.0), turns * 360.0, 96)

## DNA helix — circle profile, double helix paths (call twice, offset).
static func dna_strand(radius: float = 0.5, height: float = 2.0, tube_r: float = 0.03) -> Mesh:
	return sweep(profile_circle(6), path_helix(radius, height, 3.0),
		radius_constant(tube_r), 0.0, 96)

## Flask — circle profile, straight path, bulge radius. Glass lesson.
static func flask(height: float = 1.0, neck_r: float = 0.05, bulge_r: float = 0.2) -> Mesh:
	return sweep(profile_circle(16), path_line(Vector3.ZERO, Vector3(0, height, 0)),
		radius_bulge(neck_r, bulge_r), 0.0, 48)

## Spiral horn — circle profile, log spiral path, tapered radius.
static func spiral_horn(growth: float = 0.1, turns: float = 3.0) -> Mesh:
	return sweep(profile_circle(10), path_log_spiral(growth, turns),
		radius_taper(0.08, 0.01), 30.0, 96)

## Star tube — star cross-section, helix path. Decorative.
static func star_tube(radius: float = 0.5, height: float = 2.0, points: int = 5) -> Mesh:
	return sweep(profile_star(points), path_helix(radius, height, 2.0),
		radius_constant(0.1), 0.0, 64)

## Pulsing worm — circle profile, S-bend path, pulsing radius. Organic.
static func pulsing_worm(pulse_freq: float = 5.0) -> Mesh:
	return sweep(profile_circle(10), path_sbend(1.0, 2.0),
		radius_pulse(0.08, 0.03, pulse_freq), 0.0, 64)
