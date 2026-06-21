extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BarberParadox

## @identity
## name: Barber Paradox
## lineage: Russell's paradox in story form — the village barber who shaves
##   exactly those who do not shave themselves.
## essence: two labelled bins, SHAVES SELF and SHAVED BY BARBER. A barber token
##   (figure + razor) is sorted by an arrow that can never land — it flips back
##   and forth between the bins forever, a red "?" pulsing above.
## truth: he belongs in neither bin; the rule eats itself. If the barber shaves
##   himself he is shaved-by-the-barber (forbidden); if he does not, the rule
##   says the barber must shave him — contradiction either way.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var bin_blue: Color = Color(0.40, 0.62, 0.95)
@export var contradiction_red: Color = Color(0.902, 0.224, 0.275)
@export var flip_period: float = 2.0

var _token: Node3D
var _arrow_root: Node3D
var _qmark: Label3D
var _t: float = 0.0
var _left_pos: Vector3 = Vector3(-0.42, 0.62, 0.0)
var _right_pos: Vector3 = Vector3(0.42, 0.62, 0.0)


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
	# --- floor disc (a chalk ring on the ground, no bench) ---
	var ring_mat := _glow_mat(wire_purple, 0.5)
	add_child(_torus(Vector3(0.0, 0.02, 0.0), 0.62, 0.012, ring_mat))

	# --- two labelled bins, side by side, standing on the floor ---
	_build_bin(_left_pos + Vector3(0.0, -0.30, 0.0), "SHAVES SELF")
	_build_bin(_right_pos + Vector3(0.0, -0.30, 0.0), "SHAVED BY BARBER")

	# central post the token rides on, between the bins
	var post_mat := _steel_mat(Color(0.34, 0.36, 0.42))
	add_child(_cylinder(Vector3(0.0, 0.31, 0.0), 0.02, 0.62, post_mat))

	# --- the barber token: a little figure holding a razor ---
	_token = Node3D.new()
	_token.position = _left_pos
	add_child(_token)
	var skin := _matte_mat(cool_white, 0.6)
	# head
	_token.add_child(_sphere(Vector3(0.0, 0.16, 0.0), 0.05, skin))
	# body
	_token.add_child(_cylinder(Vector3(0.0, 0.05, 0.0), 0.045, 0.18, skin))
	# razor — a small steel blade on a red handle, jutting from the side
	var steel := _steel_mat(Color(0.80, 0.84, 0.92))
	var handle := _matte_mat(contradiction_red, 0.5)
	_token.add_child(_cylinder_between(Vector3(0.06, 0.08, 0.0), Vector3(0.13, 0.08, 0.0), 0.008, handle))
	_token.add_child(_box(Vector3(0.17, 0.10, 0.0), Vector3(0.07, 0.05, 0.004), steel))

	# --- the sorting arrow, pointing from above toward a bin (rebuilt each frame) ---
	_arrow_root = Node3D.new()
	add_child(_arrow_root)
	_reaim_arrow(_left_pos)

	# --- the pulsing red "?" — the verdict that never comes ---
	_qmark = _billboard_label("?", Vector3(0.0, 1.18, 0.0), 64, contradiction_red)
	add_child(_qmark)

	# --- billboard title ---
	add_child(_billboard_label("BARBER PARADOX", Vector3(0.0, 1.5, 0.0), 34, cool_white))
	add_child(_billboard_label("shaves all who don't shave themselves", Vector3(0.0, 1.36, 0.0), 16, wire_purple))


func _build_bin(center: Vector3, label: String) -> void:
	var wall_mat := _glass_mat(bin_blue, 0.22)
	var edge_mat := _glow_mat(bin_blue, 0.9)
	var bw: float = 0.30
	var bh: float = 0.34
	var bd: float = 0.24
	# three glass walls + glowing floor (open top — a bin)
	add_child(_box(center + Vector3(0.0, 0.0, -bd * 0.5), Vector3(bw, bh, 0.01), wall_mat))
	add_child(_box(center + Vector3(-bw * 0.5, 0.0, 0.0), Vector3(0.01, bh, bd), wall_mat))
	add_child(_box(center + Vector3(bw * 0.5, 0.0, 0.0), Vector3(0.01, bh, bd), wall_mat))
	add_child(_box(center + Vector3(0.0, -bh * 0.5, 0.0), Vector3(bw, 0.01, bd), edge_mat))
	# wireframe top rim
	var top: float = center.y + bh * 0.5
	add_child(_box(Vector3(center.x, top, center.z - bd * 0.5), Vector3(bw, 0.008, 0.008), edge_mat))
	add_child(_box(Vector3(center.x, top, center.z + bd * 0.5), Vector3(bw, 0.008, 0.008), edge_mat))
	add_child(_box(Vector3(center.x - bw * 0.5, top, center.z), Vector3(0.008, 0.008, bd), edge_mat))
	add_child(_box(Vector3(center.x + bw * 0.5, top, center.z), Vector3(0.008, 0.008, bd), edge_mat))
	# label above the bin
	add_child(_billboard_label(label, Vector3(center.x, top + 0.12, center.z), 18, cool_white))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# eased flip back and forth between the two bins — never settles
	var phase: float = fmod(_t, flip_period) / flip_period
	var tri: float = absf(phase * 2.0 - 1.0)  # 0..1..0 triangle
	var eased: float = tri * tri * (3.0 - 2.0 * tri)  # smoothstep
	var here: Vector3 = _left_pos.lerp(_right_pos, eased)
	if is_instance_valid(_token):
		_token.position = here
		# a little hop at the apex of each transfer
		_token.position.y = here.y + sin(phase * PI) * 0.06
		_token.rotation.y = sin(_t * 2.0) * 0.4

	# arrow re-aims from above toward whichever bin the token is nearer
	if is_instance_valid(_arrow_root):
		var target: Vector3 = _left_pos if eased < 0.5 else _right_pos
		_reaim_arrow(target)

	# the "?" pulses — the unresolvable verdict
	if is_instance_valid(_qmark):
		var pulse: float = 0.5 + 0.5 * sin(_t * 4.0)
		_qmark.modulate = contradiction_red.lerp(cool_white, pulse * 0.4)
		_qmark.scale = Vector3.ONE * (1.0 + pulse * 0.25)


func _reaim_arrow(target_bin: Vector3) -> void:
	# Rebuild the arrow so it always points from above down toward target_bin.
	for c in _arrow_root.get_children():
		_arrow_root.remove_child(c)
		c.queue_free()
	var a: Vector3 = Vector3(0.0, 0.95, 0.0)
	var b: Vector3 = target_bin + Vector3(0.0, 0.16, 0.0)
	var arrow_mat := _glow_mat(contradiction_red, 1.4)
	var fresh: Node3D = _arrow(a, b, 0.014, arrow_mat)
	# reparent the arrow's parts onto our persistent root
	for c in fresh.get_children():
		fresh.remove_child(c)
		_arrow_root.add_child(c)
	fresh.queue_free()
