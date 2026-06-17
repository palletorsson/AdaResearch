extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SeedBench
## @identity
## lineage: twin PRNGs sharing a seed — reproducible chance on a bench
## essence: two generators, one seed, identical streams; flip a bit and they part forever
## truth: determinism is the secret the dice keep from us

@export var seed_value: int = 42
@export var stream_len: int = 14

var _stream_group: Node3D
var _bit_lamp: MeshInstance3D
var _accum: float = 0.0
var _step: int = 0
var _diverged: bool = false


func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("seed_value"): seed_value = int(config["seed_value"])
	for c in get_children(): remove_child(c); c.queue_free()
	_diverged = false
	_build()


func _build() -> void:
	# Bench base: top at y ~= 0.85, short pillar, demo on top.
	add_child(_box(Vector3(0, 0.75, 0), Vector3(1.1, 0.2, 0.5), _matte_mat(Color(0.2, 0.22, 0.26))))
	add_child(_cylinder(Vector3(0, 0.42, 0), 0.07, 0.66, _steel_mat(Color(0.4, 0.43, 0.5))))
	add_child(_billboard_label("same seed -> same 'chance'", Vector3(0, 1.6, -0.22), 22, Color(0.9, 0.95, 1.0)))
	# Bit-flip indicator (lit when streams diverge).
	_bit_lamp = _sphere(Vector3(0.46, 1.18, 0), 0.04, _glow_mat(Color(0.25, 0.3, 0.35), 0.6))
	add_child(_bit_lamp)
	add_child(_billboard_label("bit-flip", Vector3(0.46, 1.3, 0), 14, Color(0.8, 0.85, 0.9)))
	_stream_group = Node3D.new()
	add_child(_stream_group)
	_draw_streams()


func _draw_streams() -> void:
	# Two mirrored rows fed the SAME seed -> identical bars (until divergence).
	for c in _stream_group.get_children(): _stream_group.remove_child(c); c.queue_free()
	var a := RandomNumberGenerator.new(); a.seed = seed_value
	var b := RandomNumberGenerator.new(); b.seed = seed_value if not _diverged else seed_value + 1
	var top_mat := _glow_mat(Color(0.3, 0.9, 1.0), 1.7)
	var bot_mat := _glow_mat(Color(1.0, 0.6, 0.3), 1.7)
	var x0: float = -0.46
	var dx: float = 0.92 / float(stream_len)
	for i in range(stream_len):
		var ha: float = 0.06 + a.randf() * 0.22
		var hb: float = 0.06 + b.randf() * 0.22
		var px: float = x0 + (float(i) + 0.5) * dx
		_stream_group.add_child(_box(Vector3(px, 1.0 + ha * 0.5, 0.12), Vector3(dx * 0.7, ha, 0.05), top_mat))
		_stream_group.add_child(_box(Vector3(px, 1.0 - hb * 0.5, 0.12), Vector3(dx * 0.7, hb, 0.05), bot_mat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_accum += delta
	if _accum < 0.9: return
	_accum = 0.0
	_step += 1
	# Periodically toggle divergence to show what one flipped bit does.
	if _step % 4 == 0:
		_diverged = not _diverged
		_bit_lamp.material_override = _glow_mat(Color(1.0, 0.25, 0.2), 2.4) if _diverged else _glow_mat(Color(0.25, 0.3, 0.35), 0.6)
	seed_value += 1
	_draw_streams()
