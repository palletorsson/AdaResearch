extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CommonsBench

## @identity
## name: Commons Bench — The Wiki, Not the Encyclopedia
## concept: Collective knowledge / the commons
## tier: medium
## lineage: post-crisis design after the foundations crisis. Once no single authority
##   can seal the truth shut, knowledge stops being a finished book handed down and
##   becomes a commons — a shared object that many hands keep editing, true-enough-for-
##   now, never closed. The wiki replaces the encyclopedia: authorship is plural, the
##   edit history is public, and the article is always a draft.
## essence: a floor-standing bench (~1 m) holding ONE shared knowledge-object — a faceted
##   purple-wireframe core. Many small contributor markers orbit it, and one at a time
##   reaches in to add or revise a facet: the touched facet brightens (a warm amber edit)
##   then settles back into the cool body. No marker owns the object; none ever finishes it.
## truth: the wiki, not the encyclopedia — edited by many, never done. Knowledge is a
##   commons that stays open: a thousand small revisions, no final edition.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var edit_amber: Color = Color(0.98, 0.72, 0.32)   # the warm "being edited" accent
@export var contributor_count: int = 9
@export var facet_count: int = 14
@export var edit_period: float = 0.7                      # seconds between edits

var _t: float = 0.0
var _facets: Array = []          # MeshInstance3D facet shells around the core
var _facet_mats: Array = []      # their materials
var _hands: Array = []           # {marker:MeshInstance3D, ang:float, radius:float, speed:float}
var _core: MeshInstance3D
var _editing_facet: int = -1     # which facet is currently lit
var _edit_glow: float = 0.0      # 0..1 brightness of the active edit
var _accum: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("contributor_count"):
		contributor_count = int(config["contributor_count"])
	if config.has("facet_count"):
		facet_count = int(config["facet_count"])
	if config.has("edit_period"):
		edit_period = float(config["edit_period"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_facets = []
	_facet_mats = []
	_hands = []
	_editing_facet = -1
	_edit_glow = 0.0
	_accum = 0.0

	# --- the bench (floor-standing) ---
	var base_mat: StandardMaterial3D = _matte_mat(slate, 0.85, 0.1)
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.1, 0.2, 0.7), base_mat))
	var pillar_mat: StandardMaterial3D = _steel_mat(Color(0.35, 0.37, 0.42))
	add_child(_cylinder(Vector3(0.0, 0.52, 0.0), 0.05, 0.65, pillar_mat))
	# a faint deck ring marking the shared work surface
	add_child(_torus(Vector3(0.0, 0.86, 0.0), 0.34, 0.006, _glow_mat(wire_purple, 0.9)))

	var core_y: float = 1.18

	# --- the one shared knowledge-object: a cool wireframe core ---
	_core = _sphere(Vector3(0.0, core_y, 0.0), 0.10, _glow_mat(cool_white, 0.6))
	add_child(_core)

	# --- facets: a shell of small panels around the core (the article's sections) ---
	var fi: int = 0
	while fi < facet_count:
		var phi: float = acos(1.0 - 2.0 * (float(fi) + 0.5) / float(facet_count))
		var theta: float = float(fi) * 2.399963   # golden angle, even spread
		var dir: Vector3 = Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))
		var pos: Vector3 = Vector3(0.0, core_y, 0.0) + dir * 0.20
		var fmat: StandardMaterial3D = _glow_mat(wire_purple, 0.5)
		var facet: MeshInstance3D = _box(pos, Vector3(0.07, 0.07, 0.015), fmat)
		facet.look_at_from_position(pos, Vector3(0.0, core_y, 0.0), Vector3.UP)
		add_child(facet)
		_facets.append(facet)
		_facet_mats.append(fmat)
		fi += 1

	# --- many contributor markers orbiting the shared object ---
	var hi: int = 0
	while hi < contributor_count:
		var ang: float = float(hi) / float(contributor_count) * TAU
		var radius: float = _rng.randf_range(0.26, 0.34)
		var marker: MeshInstance3D = _sphere(Vector3(0.0, core_y, 0.0), 0.022, _glow_mat(cool_white, 1.0))
		add_child(marker)
		_hands.append({"marker": marker, "ang": ang, "radius": radius, "speed": _rng.randf_range(0.4, 0.9)})
		hi += 1

	# --- billboard title ---
	add_child(_billboard_label("THE WIKI, NOT THE ENCYCLOPEDIA", Vector3(0.0, 1.5, 0.0), 24, cool_white))
	add_child(_billboard_label("edited by many, never done", Vector3(0.0, 1.34, 0.0), 16, edit_amber))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var core_y: float = 1.18

	# slow shared rotation — the object turns so every contributor can reach it
	if is_instance_valid(_core):
		_core.rotation.y = _t * 0.25

	# orbit the contributor markers; the active editor dips inward to touch a facet
	var h: int = 0
	while h < _hands.size():
		var hand: Dictionary = _hands[h]
		hand["ang"] = float(hand["ang"]) + delta * float(hand["speed"])
		var a: float = float(hand["ang"])
		var r: float = float(hand["radius"])
		var bob: float = sin(_t * 1.7 + float(h)) * 0.02
		var mk: MeshInstance3D = hand["marker"]
		if is_instance_valid(mk):
			mk.position = Vector3(cos(a) * r, core_y + bob, sin(a) * r)
		h += 1

	# --- pick the next facet to edit on a timer; brighten then fade it back ---
	_accum += delta
	if _accum >= edit_period:
		_accum = 0.0
		if _facets.size() > 0:
			_editing_facet = _rng.randi() % _facets.size()
			_edit_glow = 1.0

	# decay the active edit back toward the cool resting body
	if _edit_glow > 0.0:
		_edit_glow = maxf(0.0, _edit_glow - delta * 1.4)

	# repaint facets: cool by default, warm amber where the current edit lands
	var f: int = 0
	while f < _facet_mats.size():
		var m: StandardMaterial3D = _facet_mats[f]
		if f == _editing_facet and _edit_glow > 0.0:
			m.albedo_color = wire_purple.lerp(edit_amber, _edit_glow)
			m.emission = wire_purple.lerp(edit_amber, _edit_glow)
			m.emission_energy_multiplier = (0.5 + 2.0 * _edit_glow) if emissive else 0.3
		else:
			m.albedo_color = wire_purple
			m.emission = wire_purple
			m.emission_energy_multiplier = 0.5 if emissive else 0.2
		f += 1
