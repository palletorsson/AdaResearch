extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CommonsRoom

## @identity
## name: Commons Room — Knowledge as a Commons
## concept: Collective knowledge / the commons
## tier: large
## lineage: post-crisis design after the foundations crisis. With no single authority left
##   to certify the truth, knowledge becomes a barn-raising: a big shared structure that
##   a whole community keeps building and revising together, true-enough-for-now. The room
##   is the wiki at architectural scale — panels of fact going up, getting revised, being
##   corrected, none of it ever signed off as final.
## essence: a 7x7 room. At its centre a large shared lattice-structure (a knowledge frame,
##   ~2.5 m) is under continuous construction — panels keep being added, lit warm amber as
##   they are revised, then cooling back into the body. Contributor markers circle the
##   structure, each reaching in to update a panel; a wall of fact-panels along the back
##   flickers as entries are edited. The building is never topped out.
## truth: knowledge as a commons — true-enough-for-now. A barn-raising of facts that the
##   many keep raising; revised in the open, never finished, never owned.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var edit_amber: Color = Color(0.98, 0.72, 0.32)   # warm "being revised" accent
@export var room_size: float = 7.0
@export var panel_rows: int = 4
@export var panel_cols: int = 6
@export var builder_count: int = 12
@export var revise_period: float = 0.45                   # seconds between revisions

var _t: float = 0.0
var _panels: Array = []          # MeshInstance3D lattice panels of the central frame
var _panel_mats: Array = []      # their materials
var _panel_glow: Array = []      # per-panel warm glow 0..1 (currently-revised state)
var _wall: Array = []            # MeshInstance3D fact-panels on the back wall
var _wall_mats: Array = []
var _wall_glow: Array = []
var _builders: Array = []        # {marker, ang, radius, speed, height}
var _frame_center := Vector3(0.0, 1.3, 0.0)
var _accum: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("room_size"):
		room_size = float(config["room_size"])
	if config.has("builder_count"):
		builder_count = int(config["builder_count"])
	if config.has("revise_period"):
		revise_period = float(config["revise_period"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_panels = []
	_panel_mats = []
	_panel_glow = []
	_wall = []
	_wall_mats = []
	_wall_glow = []
	_builders = []
	_accum = 0.0

	var hs: float = room_size * 0.5
	var purple_mat: StandardMaterial3D = _glow_mat(wire_purple, 0.5)

	# --- floor (large tier: thin slab at y = -0.05) ---
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room_size, 0.04, room_size), _matte_mat(slate, 0.9)))
	# faint wireframe perimeter
	add_child(_box(Vector3(0.0, 0.0, hs - 0.05), Vector3(room_size, 0.02, 0.04), purple_mat))
	add_child(_box(Vector3(0.0, 0.0, -hs + 0.05), Vector3(room_size, 0.02, 0.04), purple_mat))
	add_child(_box(Vector3(hs - 0.05, 0.0, 0.0), Vector3(0.04, 0.02, room_size), purple_mat))
	add_child(_box(Vector3(-hs + 0.05, 0.0, 0.0), Vector3(0.04, 0.02, room_size), purple_mat))

	# --- the central shared structure: a lattice frame being built panel by panel ---
	# corner posts (the scaffold of the commons)
	var post_mat: StandardMaterial3D = _steel_mat(Color(0.34, 0.36, 0.42))
	var fx: float = 1.1
	add_child(_cylinder(Vector3(fx, 1.3, fx), 0.05, 2.6, post_mat))
	add_child(_cylinder(Vector3(-fx, 1.3, fx), 0.05, 2.6, post_mat))
	add_child(_cylinder(Vector3(fx, 1.3, -fx), 0.05, 2.6, post_mat))
	add_child(_cylinder(Vector3(-fx, 1.3, -fx), 0.05, 2.6, post_mat))

	# the panels filling the frame's walls (the body of knowledge under construction)
	var levels: int = 5
	var per_side: int = 3
	var lvl: int = 0
	while lvl < levels:
		var py: float = 0.45 + float(lvl) * 0.52
		var side: int = 0
		while side < 4:
			var s: int = 0
			while s < per_side:
				var frac: float = (float(s) + 0.5) / float(per_side)
				var along: float = lerpf(-fx * 0.9, fx * 0.9, frac)
				var pos: Vector3
				var size: Vector3
				if side == 0:
					pos = Vector3(along, py, fx)
					size = Vector3(0.5, 0.42, 0.03)
				elif side == 1:
					pos = Vector3(along, py, -fx)
					size = Vector3(0.5, 0.42, 0.03)
				elif side == 2:
					pos = Vector3(fx, py, along)
					size = Vector3(0.03, 0.42, 0.5)
				else:
					pos = Vector3(-fx, py, along)
					size = Vector3(0.03, 0.42, 0.5)
				var pmat: StandardMaterial3D = _glow_mat(wire_purple, 0.45)
				var panel: MeshInstance3D = _box(pos, size, pmat)
				add_child(panel)
				_panels.append(panel)
				_panel_mats.append(pmat)
				_panel_glow.append(0.0)
				s += 1
			side += 1
		lvl += 1

	# --- back wall of fact-panels (the article list, flickering as entries are edited) ---
	var wall_z: float = -hs + 0.06
	var r: int = 0
	while r < panel_rows:
		var c: int = 0
		while c < panel_cols:
			var wx: float = lerpf(-hs + 1.0, hs - 1.0, (float(c) + 0.5) / float(panel_cols))
			var wy: float = 0.9 + float(r) * 0.85
			var wmat: StandardMaterial3D = _glow_mat(cool_white, 0.4)
			var wp: MeshInstance3D = _box(Vector3(wx, wy, wall_z), Vector3(0.7, 0.55, 0.04), wmat)
			add_child(wp)
			_wall.append(wp)
			_wall_mats.append(wmat)
			_wall_glow.append(0.0)
			c += 1
		r += 1

	# --- many contributor markers circling the structure ---
	var bi: int = 0
	while bi < builder_count:
		var ang: float = float(bi) / float(builder_count) * TAU
		var radius: float = _rng.randf_range(1.7, 2.4)
		var height: float = _rng.randf_range(0.5, 2.3)
		var marker: MeshInstance3D = _sphere(Vector3.ZERO, 0.07, _glow_mat(cool_white, 1.2))
		add_child(marker)
		_builders.append({"marker": marker, "ang": ang, "radius": radius, "speed": _rng.randf_range(0.3, 0.7), "height": height})
		bi += 1

	# --- overhead title (large tier: y ~3.6) ---
	add_child(_billboard_label("KNOWLEDGE AS A COMMONS", Vector3(0.0, 3.6, 0.0), 32, cool_white))
	add_child(_billboard_label("TRUE-ENOUGH-FOR-NOW", Vector3(0.0, 3.3, 0.0), 30, edit_amber))
	add_child(_billboard_label("a barn-raising of knowledge — never topped out", Vector3(0.0, 3.04, 0.0), 16, wire_purple))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# circle the builders around the central structure; bob as they "work"
	var b: int = 0
	while b < _builders.size():
		var bd: Dictionary = _builders[b]
		bd["ang"] = float(bd["ang"]) + delta * float(bd["speed"])
		var a: float = float(bd["ang"])
		var rad: float = float(bd["radius"])
		var hgt: float = float(bd["height"]) + sin(_t * 1.3 + float(b)) * 0.12
		var mk: MeshInstance3D = bd["marker"]
		if is_instance_valid(mk):
			mk.position = Vector3(cos(a) * rad, hgt, sin(a) * rad)
		b += 1

	# --- revise panels on a timer: light one warm, light a back-wall fact too ---
	_accum += delta
	if _accum >= revise_period:
		_accum = 0.0
		if _panel_glow.size() > 0:
			_panel_glow[_rng.randi() % _panel_glow.size()] = 1.0
		if _wall_glow.size() > 0:
			_wall_glow[_rng.randi() % _wall_glow.size()] = 1.0

	# decay + repaint the central frame panels (cool body, warm where revised)
	var p: int = 0
	while p < _panel_mats.size():
		var g: float = float(_panel_glow[p])
		if g > 0.0:
			g = maxf(0.0, g - delta * 1.1)
			_panel_glow[p] = g
		var m: StandardMaterial3D = _panel_mats[p]
		m.albedo_color = wire_purple.lerp(edit_amber, g)
		m.emission = wire_purple.lerp(edit_amber, g)
		m.emission_energy_multiplier = (0.45 + 2.2 * g) if emissive else 0.2
		p += 1

	# decay + repaint the back-wall fact-panels (flicker as entries are edited)
	var w: int = 0
	while w < _wall_mats.size():
		var wg: float = float(_wall_glow[w])
		if wg > 0.0:
			wg = maxf(0.0, wg - delta * 1.6)
			_wall_glow[w] = wg
		var wm: StandardMaterial3D = _wall_mats[w]
		wm.albedo_color = cool_white.lerp(edit_amber, wg)
		wm.emission = cool_white.lerp(edit_amber, wg)
		wm.emission_energy_multiplier = (0.4 + 1.8 * wg) if emissive else 0.2
		w += 1
