extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name KochSnowflakePress

## @identity
## name: "Koch curve & snowflake"
## tier: applied
## lineage: a stamping press — the Koch snowflake (three Koch curves closed into a triangle)
##   pressed out as tiles, one strike at a time.
## essence: A platen drops, lifts, and reveals a freshly minted Koch snowflake; a row of
##   finished snowflakes sits in the output tray, each crinklier at the edge than a triangle
##   has any right to be. Six iterations and the boundary is already longer than the room;
##   keep going and the perimeter grows without bound while the area barely changes.
## truth: "infinite perimeter" — every strike adds a bump to every edge: perimeter ×4/3 each
##   iteration → ∞, area → a finite 8/5 of the seed triangle. D = log 4 / log 3 ≈ 1.26.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var iterations: int = 4
@export var snowflake_radius: float = 0.16    # circumradius of a finished tile (m)
@export var finished_count: int = 4
@export var press_period: float = 2.4         # seconds per stamp cycle
@export var flake_color: Color = Color(0.65, 0.90, 1.0)
@export var hot_color: Color = Color(1.0, 0.55, 0.30)
@export var label_color: Color = Color(0.85, 0.92, 1.0)

var _t: float = 0.0
var _platen: Node3D = null
var _fresh_flake: MultiMeshInstance3D = null
var _fresh_mat: StandardMaterial3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("iterations"):
		iterations = clampi(int(config["iterations"]), 1, 5)
	if config.has("finished_count"):
		finished_count = clampi(int(config["finished_count"]), 1, 6)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_platen = null
	_fresh_flake = null
	_fresh_mat = null
	_build()


func _field(n: int, box: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = (BoxMesh.new() if box else SphereMesh.new())
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
	mi.material_override = mat
	return mi


func _koch_segment(a: Vector2, b: Vector2, depth: int) -> PackedVector2Array:
	# Koch curve points between a and b (inclusive of a, exclusive of b's duplicate).
	var pts := PackedVector2Array()
	pts.append(a)
	pts.append(b)
	for _it in range(depth):
		var out := PackedVector2Array()
		for i in range(pts.size() - 1):
			var p: Vector2 = pts[i]
			var q: Vector2 = pts[i + 1]
			var d: Vector2 = q - p
			var p1: Vector2 = p + d / 3.0
			var p2: Vector2 = p + d * (2.0 / 3.0)
			var seg: Vector2 = p2 - p1
			var ang: float = -PI / 3.0     # bump outward for CCW triangle
			var peak: Vector2 = p1 + Vector2(
				seg.x * cos(ang) - seg.y * sin(ang),
				seg.x * sin(ang) + seg.y * cos(ang))
			out.append(p)
			out.append(p1)
			out.append(peak)
			out.append(p2)
		out.append(pts[pts.size() - 1])
		pts = out
	return pts


func _snowflake_points(radius: float, depth: int) -> PackedVector2Array:
	# Three corners of an equilateral triangle (CCW), each edge a Koch curve.
	var corners: Array[Vector2] = []
	for k in range(3):
		var ang: float = PI / 2.0 + float(k) * (TAU / 3.0)
		corners.append(Vector2(cos(ang), sin(ang)) * radius)
	var loop := PackedVector2Array()
	for k in range(3):
		var a: Vector2 = corners[k]
		var b: Vector2 = corners[(k + 1) % 3]
		var seg_pts: PackedVector2Array = _koch_segment(a, b, depth)
		# append all but the last point (next edge starts there)
		for i in range(seg_pts.size() - 1):
			loop.append(seg_pts[i])
	return loop


func _make_flake(radius: float, depth: int, col: Color) -> MultiMeshInstance3D:
	# Returns a MultiMesh whose boxes trace the closed snowflake outline.
	var loop: PackedVector2Array = _snowflake_points(radius, depth)
	var count: int = loop.size()
	var field: MultiMeshInstance3D = _field(count, true)
	var mm: MultiMesh = field.multimesh
	var thick: float = 0.006
	for i in range(count):
		var a2: Vector2 = loop[i]
		var b2: Vector2 = loop[(i + 1) % count]
		var wa := Vector3(a2.x, a2.y, 0.0)
		var wb := Vector3(b2.x, b2.y, 0.0)
		var mid: Vector3 = (wa + wb) * 0.5
		var seg_len: float = maxf(wa.distance_to(wb), 0.0001)
		var dir: Vector3 = (wb - wa) / seg_len
		var ang: float = atan2(dir.y, dir.x)
		var basis := Basis(Vector3(0, 0, 1), ang).scaled(Vector3(seg_len, thick, thick))
		mm.set_instance_transform(i, Transform3D(basis, mid))
		mm.set_instance_color(i, col)
	return field


func _build() -> void:
	# --- press body (~1 m) --------------------------------------------------
	var body_mat: StandardMaterial3D = _matte_mat(Color(0.22, 0.24, 0.28), 0.7, 0.2)
	# bed
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(0.9, 0.20, 0.6), body_mat))
	# two side columns + crown (a C-frame press)
	var col_mat: StandardMaterial3D = _steel_mat(Color(0.48, 0.52, 0.58))
	add_child(_box(Vector3(-0.30, 0.62, -0.22), Vector3(0.07, 0.84, 0.07), col_mat))
	add_child(_box(Vector3(0.30, 0.62, -0.22), Vector3(0.07, 0.84, 0.07), col_mat))
	add_child(_box(Vector3(0.0, 1.02, -0.22), Vector3(0.74, 0.08, 0.10), col_mat))

	# die plate on the bed (where the fresh tile appears), facing +Y
	var die_mat: StandardMaterial3D = _matte_mat(Color(0.05, 0.06, 0.09), 0.95)
	add_child(_box(Vector3(0.0, 0.205, 0.12), Vector3(0.42, 0.02, 0.42), die_mat))

	# --- moving platen ------------------------------------------------------
	var platen := Node3D.new()
	platen.name = "Platen"
	add_child(platen)
	_platen = platen
	var platen_mat: StandardMaterial3D = _steel_mat(Color(0.55, 0.58, 0.64))
	platen.add_child(_box(Vector3(0.0, 0.70, 0.12), Vector3(0.40, 0.06, 0.40), platen_mat))
	# ram connecting platen to crown
	platen.add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(0.08, 0.14, 0.08), platen_mat))

	# --- the freshly pressed snowflake (sits on the die, flat, facing +Y) --
	var fresh: MultiMeshInstance3D = _make_flake(snowflake_radius, iterations, flake_color)
	fresh.name = "FreshFlake"
	fresh.rotation.x = -PI / 2.0    # lay the XY outline flat onto XZ
	fresh.position = Vector3(0.0, 0.22, 0.12)
	add_child(fresh)
	_fresh_flake = fresh
	_fresh_mat = fresh.material_override as StandardMaterial3D

	# --- output tray with finished snowflakes ------------------------------
	var tray_mat: StandardMaterial3D = _matte_mat(Color(0.16, 0.17, 0.20), 0.9)
	add_child(_box(Vector3(0.0, 0.21, 0.46), Vector3(0.9, 0.02, 0.18), tray_mat))
	var slot: float = 0.9 / float(finished_count + 1)
	for fi in range(finished_count):
		var fx: float = -0.45 + slot * float(fi + 1)
		var done: MultiMeshInstance3D = _make_flake(snowflake_radius * 0.5, iterations, flake_color.darkened(0.1))
		done.name = "Done_%d" % fi
		done.rotation.x = -PI / 2.0
		done.position = Vector3(fx, 0.225, 0.46)
		add_child(done)

	# --- labels -------------------------------------------------------------
	add_child(_billboard_label("perimeter ×4/3 each pass → ∞", Vector3(0.0, 0.34, 0.30), 16, hot_color))
	add_child(_billboard_label("INFINITE PERIMETER", Vector3(0.0, 1.22, 0.0), 24, label_color))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _platen == null:
		return
	# stamp cycle: drop, dwell, lift.
	var phase: float = fmod(_t, press_period) / press_period
	var drop: float = 0.0
	if phase < 0.35:
		drop = phase / 0.35                       # going down
	elif phase < 0.5:
		drop = 1.0                                # dwell at bottom
	else:
		drop = maxf(0.0, 1.0 - (phase - 0.5) / 0.5)  # rising
	_platen.position.y = -drop * 0.44
	# glow the fresh tile hot at the moment of strike
	if _fresh_mat != null:
		var heat: float = 1.0 if (phase >= 0.30 and phase < 0.5) else 0.0
		_fresh_mat.emission = flake_color.lerp(hot_color, heat)
		_fresh_mat.emission_energy_multiplier = (0.18 if emissive else 0.0) + heat * 1.2
