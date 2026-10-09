extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TenPrintTextile
## @identity
## lineage: 10 PRINT as a Jacquard loom — chance threaded into a continuous bolt
## essence: the maze becomes cloth, woven forever, no two metres alike
## truth: a generative rule is a pattern that production never finishes printing

@export var cols: int = 14
@export var rows: int = 18

# --- STAGE-2 DNA (promoted 2026-08-03) ---------------------------------------
# 10 PRINT is one line of BASIC and its entire content is two hard-coded facts:
# a fair coin, and the two glyphs it chooses between. Both were literals here —
# `_rng.randf() < 0.5` and `rotation.z = ±PI*0.25`. They are the argument.
#
#   odds      P(slash). 0.5 is the literal fair flip, so it is the default. At
#             0 and 1 the cloth stops being a maze and becomes a rib — which is
#             the point: the pattern exists only because the coin is fair.
#   alphabet  which two marks the coin chooses between. "diagonals" is the ±45°
#             bar this loom has always woven, so it is the default.
@export_range(0.0, 1.0) var odds: float = 0.5
@export_enum("diagonals", "orthogonals", "blocks") var alphabet: String = "diagonals"

# Not axes. `weave_seed` 0 keeps the shipped `_rng.randomize()`; any positive
# value pins the bolt so a bench shot is reproducible. `weaving` false freezes
# the scroll so a still photographs one cloth rather than one mid-scroll frame.
@export var weave_seed: int = 0
@export var weaving: bool = true

const ALPHABETS = ["diagonals", "orthogonals", "blocks"]

var _built: bool = false
var _bolt: Node3D
var _woven: Array = []
var _step := 0.0
var _row_h := 0.07
var _top_y := 1.4
var _bottom_y := -0.2

func _ready() -> void:
	_seed_rng(); _build(); set_process(not Engine.is_editor_hint())

func _seed_rng() -> void:
	if weave_seed > 0:
		_rng.seed = weave_seed
	else:
		_rng.randomize()

# GUARDED (2026-08-03). This used to tear down every child and rebuild on any
# call — including a call that arrived before _ready, which left the loom built
# twice. Now it rebuilds only when a value actually moved AND the first build
# has happened.
func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false
	if config.has("emissive"):
		var raw = config["emissive"]
		var e: bool = true
		if typeof(raw) == TYPE_BOOL:
			e = bool(raw)
		else:
			e = str(raw).to_lower() != "false"
		if e != emissive:
			emissive = e
			changed = true
	if config.has("odds"):
		var o: float = clampf(float(config["odds"]), 0.0, 1.0)
		if not is_equal_approx(o, odds):
			odds = o
			changed = true
	if config.has("alphabet"):
		var a: String = str(config["alphabet"])
		if a != alphabet and ALPHABETS.has(a):
			alphabet = a
			changed = true
	if config.has("weave_seed"):
		var s: int = int(config["weave_seed"])
		if s != weave_seed:
			weave_seed = s
			changed = true
	if config.has("weaving"):
		weaving = str(config["weaving"]).to_lower() != "false"
	if not _built or not changed:
		return
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_seed_rng()
	_build()

func _build() -> void:
	_woven.clear()
	var steel := _steel_mat(Color(0.45, 0.4, 0.35))
	# Loom frame: two uprights and a heddle beam the cloth spills over.
	add_child(_box(Vector3(-0.55, 0.6, 0), Vector3(0.06, 1.7, 0.1), steel))
	add_child(_box(Vector3(0.55, 0.6, 0), Vector3(0.06, 1.7, 0.1), steel))
	add_child(_cylinder_between(Vector3(-0.55, _top_y, 0), Vector3(0.55, _top_y, 0), 0.05, steel))
	add_child(_cylinder_between(Vector3(-0.55, _top_y + 0.12, 0.0), Vector3(0.55, _top_y + 0.12, 0.0), 0.03, steel))
	_bolt = Node3D.new()
	add_child(_bolt)
	# Full hanging bolt already woven, top to bottom.
	for r in range(rows):
		var y := _top_y - (float(r) + 0.5) * _row_h
		_woven.append(_weave_row(y))
	add_child(_billboard_label("10 PRINT textile", Vector3(0, _top_y + 0.32, 0), 24, Color(0.95, 0.85, 0.6)))
	_built = true

func _weave_row(y: float) -> Array:
	var w := 1.0
	var sx := w / float(cols)
	var threads: Array = []
	for c in range(cols):
		var cx := -w * 0.5 + (float(c) + 0.5) * sx
		var slash := _rng.randf() < odds
		# Thread colors: warm warp vs cool weft per coin flip.
		var hue := (0.07 if slash else 0.58) + _rng.randf() * 0.05
		var mat := _glow_mat(Color.from_hsv(hue, 0.6, 0.95), 1.8)
		var bar: MeshInstance3D = _mark(cx, y, sx, slash, mat)
		_bolt.add_child(bar)
		threads.append(bar)
	return threads

## The two marks the coin chooses between. `diagonals` is the shipped bar: same
## box, same ±PI*0.25, so the default cloth is untouched.
func _mark(cx: float, y: float, sx: float, slash: bool, mat: Material) -> MeshInstance3D:
	if alphabet == "blocks":
		# No line at all: the flip read as a bitmap, filled cell vs speck.
		var s: Vector3 = Vector3(sx * 0.9, _row_h * 0.9, 0.03) if slash else Vector3(sx * 0.3, _row_h * 0.3, 0.03)
		return _box(Vector3(cx, y, 0.02), s, mat)
	var bar: MeshInstance3D = _box(Vector3(cx, y, 0.02), Vector3(sx * 0.9, _row_h * 0.42, 0.03), mat)
	if alphabet == "orthogonals":
		# The same flip, a different alphabet: a lying bar and a standing one,
		# horizontal and vertical instead of the two diagonals.
		bar.rotation.z = 0.0 if slash else (PI * 0.5)
	else:
		bar.rotation.z = (PI * 0.25) if slash else (-PI * 0.25)
	return bar

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if not weaving: return
	_step += delta
	if _step < 0.18: return
	_step = 0.0
	# Scroll the whole bolt down; new woven row appears at the top.
	for row in _woven:
		for bar in row:
			bar.position.y -= _row_h
	# Cull the row that fell off the bottom, weave a fresh one at the top.
	if _woven.size() > 0 and _woven[0].size() > 0 and _woven[0][0].position.y < _bottom_y:
		var dead: Array = _woven.pop_front()
		for bar in dead:
			bar.queue_free()
		_woven.append(_weave_row(_top_y - _row_h * 0.5))
