extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name IncompletenessTower

## @identity
## name: Incompleteness Tower
## lineage: Godel's second move and the limit of "just add an axiom". Each
##   consistent system strong enough for arithmetic has its own unprovable
##   truth; bolt it on as a new axiom and the larger system has a new one.
## essence: a tower of ringed platforms, one formal system per level. A pulse
##   climbs it: at each level a gold Godel-gap opens in the floor, an AXIOM bar
##   drops in to patch it (the gap goes cool/closed) — and the next level up
##   immediately splits open a fresh gold gap. Patch, climb, new hole, forever.
## truth: closing the gap with a new axiom does not finish the system; it makes
##   a bigger system, which has its own gap one level up. Incompleteness all the
##   way up.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var level_blue: Color = Color(0.40, 0.62, 0.95)
@export var patch_cyan: Color = Color(0.45, 0.85, 0.92)
@export var gap_gold: Color = Color(1.0, 0.78, 0.30)
@export var level_count: int = 5
@export var level_height: float = 0.20
@export var climb_period: float = 5.0

var _t: float = 0.0
var _base_y: float = 0.06
var _gap_mats: Array[StandardMaterial3D] = []     # the gold gap disc per level
var _gaps: Array[MeshInstance3D] = []
var _patch_bars: Array[Node3D] = []               # the AXIOM bar that drops to patch each level
var _rings: Array[StandardMaterial3D] = []
var _level_r: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_t = 0.0
	_gap_mats.clear()
	_gaps.clear()
	_patch_bars.clear()
	_rings.clear()
	_level_r.resize(level_count)

	# --- chalk ring on the floor ---
	add_child(_torus(Vector3(0.0, 0.02, 0.0), 0.50, 0.012, _glow_mat(wire_purple, 0.5)))

	var frame_mat := _steel_mat(Color(0.32, 0.34, 0.42))
	var lvl: int = 0
	while lvl < level_count:
		var y: float = _base_y + float(lvl) * level_height
		# platforms taper slightly as the tower rises
		var r: float = lerpf(0.40, 0.22, float(lvl) / float(maxi(level_count - 1, 1)))
		_level_r[lvl] = r

		# platform disc (the system's floor)
		var floor_mat := _glass_mat(level_blue, 0.18)
		add_child(_cylinder(Vector3(0.0, y, 0.0), r, 0.014, floor_mat))
		# ring edge — the boundary of this formal system
		_rings.append(_glow_mat(level_blue, 1.0))
		add_child(_torus(Vector3(0.0, y + 0.008, 0.0), r, 0.010, _rings[lvl]))

		# four support struts down to the previous level (or the floor)
		var below: float = (_base_y + float(lvl - 1) * level_height) if lvl > 0 else 0.0
		var strut_r: float = r * 0.7
		var k: int = 0
		while k < 4:
			var a: float = float(k) / 4.0 * TAU + PI * 0.25
			var px: float = cos(a) * strut_r
			var pz: float = sin(a) * strut_r
			add_child(_cylinder_between(Vector3(px, below + 0.01, pz), Vector3(px, y - 0.01, pz), 0.012, frame_mat))
			k += 1

		# the gold Godel-gap: a glowing disc set in this level's floor
		var gmat := _glow_mat(gap_gold, 1.2)
		_gap_mats.append(gmat)
		var gap := _cylinder(Vector3(r * 0.0, y + 0.012, r * 0.30), 0.06, 0.012, gmat)
		_gaps.append(gap)
		add_child(gap)

		# the AXIOM patch bar that drops into the gap (starts lifted above)
		var bar_root := Node3D.new()
		var bar_mat := _glow_mat(patch_cyan, 1.0)
		bar_root.add_child(_box(Vector3.ZERO, Vector3(0.14, 0.03, 0.14), bar_mat))
		bar_root.add_child(_box(Vector3(0.0, 0.03, 0.0), Vector3(0.10, 0.012, 0.10), _matte_mat(cool_white, 0.5)))
		bar_root.position = Vector3(0.0, y + 0.30, r * 0.30)
		_patch_bars.append(bar_root)
		add_child(bar_root)

		# tiny level tag
		add_child(_billboard_label("S%d" % (lvl + 1), Vector3(-r - 0.02, y + 0.04, 0.0), 13, level_blue))
		lvl += 1

	# axiom-ladder label up the side
	add_child(_billboard_label("+ AXIOM", Vector3(0.34, _base_y + level_height * 0.5, 0.34), 12, patch_cyan))

	# --- title ---
	var top_y: float = _base_y + float(level_count - 1) * level_height
	add_child(_billboard_label("INCOMPLETENESS TOWER", Vector3(0.0, top_y + 0.42, 0.0), 28, cool_white))
	add_child(_billboard_label("patch the gap — a new gap opens above", Vector3(0.0, top_y + 0.30, 0.0), 13, gap_gold))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# A patch-pulse climbs the tower. At any moment the "active" level is being
	# patched (its gap closes as the AXIOM bar drops); the level just above has
	# its fresh gap flaring open. Everything cycles upward and wraps.
	var travel: float = fmod(_t / climb_period, 1.0) * float(level_count)  # 0..level_count

	var lvl: int = 0
	while lvl < level_count:
		# distance of this level from the climbing pulse front
		var d: float = travel - float(lvl)
		# patch progress for this level: 0 = gap wide open (gold), 1 = patched (closed/cyan)
		var patched: float = 0.0
		var bar_drop: float = 0.0
		if d >= 0.0 and d < 1.0:
			# the pulse is currently AT this level — patch it as the front passes
			patched = _smooth(d)
			bar_drop = _smooth(d)
		elif d >= 1.0:
			# pulse has gone above — this level stays patched (until the wrap reopens it)
			patched = 1.0
			bar_drop = 1.0
		else:
			# pulse not here yet — gap wide open, bar lifted
			patched = 0.0
			bar_drop = 0.0

		# the gap disc: gold + large when open, cools to cyan + shrinks when patched
		if lvl < _gap_mats.size() and _gap_mats[lvl] != null:
			var gm: StandardMaterial3D = _gap_mats[lvl]
			var col: Color = gap_gold.lerp(patch_cyan, patched)
			gm.albedo_color = col
			gm.emission = col
			var flare: float = (1.0 - patched)  # open gaps flare
			gm.emission_energy_multiplier = (0.5 + flare * 1.2 + 0.25 * sin(_t * 5.0) * flare) if emissive else 0.0
		if lvl < _gaps.size() and is_instance_valid(_gaps[lvl]):
			var s: float = lerpf(1.0, 0.25, patched)  # open=full, patched=nearly gone
			_gaps[lvl].scale = Vector3(s, 1.0, s)

		# the AXIOM bar drops into the gap as it patches, lifts back when reopened
		if lvl < _patch_bars.size() and is_instance_valid(_patch_bars[lvl]):
			var y: float = _base_y + float(lvl) * level_height
			var lifted: float = y + 0.30
			var seated: float = y + 0.03
			_patch_bars[lvl].position.y = lerpf(lifted, seated, bar_drop)
			_patch_bars[lvl].rotation.y = _t * 1.2

		# ring edge brightens on the level currently being worked
		if lvl < _rings.size() and _rings[lvl] != null:
			var active: float = 0.0
			if d >= -0.3 and d < 1.0:
				active = 1.0 - clampf(absf(d - 0.3), 0.0, 1.0)
			_rings[lvl].emission_energy_multiplier = (0.7 + active * 1.0) if emissive else 0.0

		lvl += 1


func _smooth(x: float) -> float:
	var c: float = clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)
