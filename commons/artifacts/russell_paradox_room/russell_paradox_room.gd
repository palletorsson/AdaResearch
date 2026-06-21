extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RussellParadoxRoom

## @identity
## name: Russell's Paradox — The Catalogue That Cannot List Itself
## lineage: the contradiction that broke naive set theory. Consider the set of
##   all sets that do not contain themselves. Does it contain itself? Either
##   answer refutes itself.
## essence: a room-scale library of catalogues — shelves of "catalogues that do
##   NOT list themselves." At the center, one glowing catalogue R asks "do I list
##   myself?" and flickers in and out of its own shelf, finding no stable place.
## truth: R belongs on its own shelf only if it does not, and does not only if it
##   does — the set of all sets that do not contain themselves cannot exist. The
##   foundations had a crack in them.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var contradiction_red: Color = Color(0.902, 0.224, 0.275)
@export var accent_gold: Color = Color(0.98, 0.80, 0.32)
@export var room_size: float = 7.0
@export var flicker_period: float = 2.2

var _r_book: Node3D
var _r_glow: MeshInstance3D
var _r_qmark: Label3D
var _shelf_slot: Vector3
var _center_slot: Vector3
var _t: float = 0.0


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
	var purple_mat := _glow_mat(wire_purple, 0.5)
	var floor_mat := _matte_mat(Color(0.07, 0.08, 0.13), 0.9)
	var shelf_mat := _steel_mat(Color(0.30, 0.32, 0.40))

	# --- room floor + chalk border ---
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room_size, 0.06, room_size), floor_mat))
	var hs: float = room_size * 0.5
	add_child(_box(Vector3(0.0, 0.01, hs - 0.1), Vector3(room_size - 0.2, 0.01, 0.02), purple_mat))
	add_child(_box(Vector3(0.0, 0.01, -hs + 0.1), Vector3(room_size - 0.2, 0.01, 0.02), purple_mat))
	add_child(_box(Vector3(hs - 0.1, 0.01, 0.0), Vector3(0.02, 0.01, room_size - 0.2), purple_mat))
	add_child(_box(Vector3(-hs + 0.1, 0.01, 0.0), Vector3(0.02, 0.01, room_size - 0.2), purple_mat))

	# --- three big shelves of ordinary catalogues around the walls ---
	# each shelf = uprights + plank rows + many thin spine books
	_build_shelf(Vector3(0.0, 0.0, -hs + 0.6), 0.0, shelf_mat, false)
	_build_shelf(Vector3(-hs + 0.6, 0.0, 0.0), PI * 0.5, shelf_mat, false)
	_build_shelf(Vector3(hs - 0.6, 0.0, 0.0), PI * 0.5, shelf_mat, false)
	# the special shelf where R either belongs or doesn't — reserved empty slot
	var special := Vector3(0.0, 0.0, hs - 0.9)
	_build_shelf(special, 0.0, shelf_mat, true)
	add_child(_billboard_label("catalogues that do NOT list themselves", special + Vector3(0.0, 2.0, 0.0), 16, cool_white))

	# the empty slot on the special shelf (where R flickers in)
	_shelf_slot = special + Vector3(0.0, 1.1, 0.18)
	# R's pedestal position at the room center
	_center_slot = Vector3(0.0, 1.2, 0.0)

	# --- the central catalogue R on a glowing pedestal ---
	var ped_mat := _glow_mat(wire_purple, 0.9)
	add_child(_cylinder(Vector3(0.0, 0.4, 0.0), 0.34, 0.8, _glass_mat(wire_purple, 0.12)))
	add_child(_torus(Vector3(0.0, 0.82, 0.0), 0.34, 0.02, ped_mat))

	_r_book = Node3D.new()
	_r_book.position = _center_slot
	add_child(_r_book)
	var cover := _matte_mat(contradiction_red, 0.4)
	var gold := _glow_mat(accent_gold, 1.4)
	# a fat closed book (the catalogue R)
	_r_book.add_child(_box(Vector3.ZERO, Vector3(0.30, 0.42, 0.10), cover))
	_r_book.add_child(_box(Vector3(0.0, 0.0, 0.052), Vector3(0.22, 0.34, 0.005), gold))
	# its glow halo
	_r_glow = _sphere(Vector3.ZERO, 0.42, _glass_mat(contradiction_red, 0.16))
	_r_book.add_child(_r_glow)
	# big "R"
	_r_book.add_child(_billboard_label("R", Vector3(0.0, 0.0, 0.08), 40, accent_gold))

	# the question that drives the flicker
	_r_qmark = _billboard_label("do I list myself?", _center_slot + Vector3(0.0, 0.5, 0.0), 20, contradiction_red)
	add_child(_r_qmark)

	# --- overhead title ---
	add_child(_billboard_label("THE SET OF ALL SETS", Vector3(0.0, 3.7, 0.0), 36, cool_white))
	add_child(_billboard_label("THAT DO NOT CONTAIN THEMSELVES", Vector3(0.0, 3.4, 0.0), 30, cool_white))
	add_child(_billboard_label("Russell's paradox — the crack in the foundations", Vector3(0.0, 3.12, 0.0), 16, wire_purple))


func _build_shelf(base: Vector3, rot_y: float, mat: Material, reserved: bool) -> void:
	var holder := Node3D.new()
	holder.position = base
	holder.rotation.y = rot_y
	add_child(holder)
	var w: float = 2.6
	var h: float = 1.9
	var d: float = 0.34
	# uprights
	holder.add_child(_box(Vector3(-w * 0.5, h * 0.5, 0.0), Vector3(0.06, h, d), mat))
	holder.add_child(_box(Vector3(w * 0.5, h * 0.5, 0.0), Vector3(0.06, h, d), mat))
	# plank rows
	var rows: int = 3
	for r in range(rows + 1):
		var yy: float = (h / float(rows)) * float(r) + 0.05
		holder.add_child(_box(Vector3(0.0, yy, 0.0), Vector3(w, 0.04, d), mat))
	# spine books on each row
	for r in range(rows):
		var yy: float = (h / float(rows)) * float(r) + 0.05 + (h / float(rows)) * 0.5
		var books: int = 16
		for b in range(books):
			# leave a visible gap on the reserved shelf's top row for R's slot
			if reserved and r == rows - 1 and b >= 7 and b <= 8:
				continue
			var x: float = lerpf(-w * 0.5 + 0.12, w * 0.5 - 0.12, float(b) / float(books - 1))
			var bh: float = _rng.randf_range(0.30, 0.46)
			var hue := Color(0.55 + _rng.randf() * 0.25, 0.58 + _rng.randf() * 0.2, 0.85, 1.0)
			var bm := _matte_mat(hue, 0.6)
			holder.add_child(_box(Vector3(x, yy - 0.42 * 0.5 + bh * 0.5, 0.04), Vector3(0.05, bh, 0.22), bm))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# R flickers between its shelf slot and the center pedestal — never settling
	var phase: float = fmod(_t, flicker_period) / flicker_period
	# sharp flicker: snap presence on/off plus a positional drift
	var presence: float = 0.5 + 0.5 * sin(_t * 5.0)
	var glitch: float = 1.0 if sin(_t * 13.0) > 0.3 else 0.0
	if is_instance_valid(_r_book):
		# drift toward the shelf, then snap back to center
		var tri: float = absf(phase * 2.0 - 1.0)
		var eased: float = tri * tri * (3.0 - 2.0 * tri)
		var here: Vector3 = _center_slot.lerp(_shelf_slot, eased)
		_r_book.position = here
		_r_book.rotation.y = _t * 0.8
		# flicker visibility
		_r_book.visible = glitch < 0.5 or presence > 0.35
		_r_book.scale = Vector3.ONE * (1.0 + presence * 0.06)

	# the halo and question pulse red — the unresolvable verdict
	if is_instance_valid(_r_glow):
		var m: StandardMaterial3D = _r_glow.material_override as StandardMaterial3D
		if m != null:
			m.emission_energy_multiplier = (0.3 if emissive else 0.0) + presence * 0.6
	if is_instance_valid(_r_qmark):
		if is_instance_valid(_r_book):
			_r_qmark.position = _r_book.position + Vector3(0.0, 0.5, 0.0)
		_r_qmark.modulate = contradiction_red.lerp(cool_white, presence * 0.4)
		_r_qmark.scale = Vector3.ONE * (1.0 + presence * 0.2)
