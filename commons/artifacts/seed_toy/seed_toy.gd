extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SeedToy
## @identity
## lineage: PRNG seed dial — deterministic chance in the hand
## essence: one number, one glyph; turn the dial and the pattern is reborn the same way every time
## truth: chance that remembers its name is not chance at all

@export var seed_value: int = 7
@export var step_seconds: float = 1.5

var _glyph_group: Node3D
var _label: Label3D
var _accum: float = 0.0


func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("seed_value"): seed_value = int(config["seed_value"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	# Seed dial: a torus with a needle, label above, deterministic glyph below.
	add_child(_torus(Vector3(0, 0.36, 0), 0.13, 0.022, _steel_mat(Color(0.55, 0.6, 0.7))))
	var ang: float = float(seed_value) * 0.6
	var needle_tip := Vector3(sin(ang) * 0.12, 0.36 + cos(ang) * 0.12, 0)
	add_child(_cylinder_between(Vector3(0, 0.36, 0), needle_tip, 0.01, _glow_mat(Color(1.0, 0.75, 0.2), 2.2)))
	add_child(_sphere(Vector3(0, 0.36, 0), 0.024, _glow_mat(Color(1.0, 0.9, 0.4), 2.0)))
	_label = _billboard_label("seed %d" % seed_value, Vector3(0, 0.52, 0), 26, Color(0.95, 0.95, 1.0))
	add_child(_label)
	_glyph_group = Node3D.new()
	add_child(_glyph_group)
	_draw_glyph()


func _draw_glyph() -> void:
	# A 5x5 grid of dots/bars seeded DETERMINISTICALLY from seed_value.
	for c in _glyph_group.get_children(): _glyph_group.remove_child(c); c.queue_free()
	var g := RandomNumberGenerator.new()
	g.seed = seed_value
	var on_mat := _glow_mat(Color(0.3, 0.9, 1.0), 1.8)
	var off_mat := _matte_mat(Color(0.15, 0.18, 0.22), 0.9)
	var step: float = 0.05
	var x0: float = -2.0 * step
	for row in range(5):
		for col in range(5):
			var on: bool = g.randf() > 0.5
			var px: float = x0 + float(col) * step
			var py: float = 0.04 + float(4 - row) * step
			if on:
				_glyph_group.add_child(_box(Vector3(px, py, 0), Vector3(0.034, 0.034, 0.02), on_mat))
			else:
				_glyph_group.add_child(_sphere(Vector3(px, py, 0), 0.008, off_mat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_accum += delta
	if _accum < step_seconds: return
	_accum = 0.0
	seed_value += 1
	# Same seed always yields the same glyph; redraw and refresh the dial/label.
	for c in get_children(): remove_child(c); c.queue_free()
	_build()
