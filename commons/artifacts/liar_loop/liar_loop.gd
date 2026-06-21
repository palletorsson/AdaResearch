extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LiarLoop

## @identity
## name: Liar Loop
## lineage: the liar sentence — "this statement is false" — the self-referential
##   ancestor of Russell's paradox and Gödel's diagonal.
## essence: a chalk sign reads THIS STATEMENT IS FALSE. Above it a truth-lamp
##   labelled TRUE / FALSE oscillates endlessly, and a looping arrow chases its
##   own tail around the sign, never settling.
## truth: if it's true it's false, if it's false it's true. There is no stable
##   assignment — the value loops forever.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var true_green: Color = Color(0.30, 0.85, 0.45)
@export var false_red: Color = Color(0.902, 0.224, 0.275)
@export var oscillate_period: float = 2.4

var _lamp: MeshInstance3D
var _lamp_mat: StandardMaterial3D
var _true_lbl: Label3D
var _false_lbl: Label3D
var _loop_arrow: Node3D
var _t: float = 0.0
var _loop_r: float = 0.34


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
	# --- a slim floor stand holding the sign up (no bench) ---
	var post_mat := _steel_mat(Color(0.34, 0.36, 0.42))
	add_child(_cylinder(Vector3(0.0, 0.0, 0.0), 0.10, 0.02, post_mat))      # foot plate
	add_child(_cylinder(Vector3(0.0, 0.30, 0.0), 0.025, 0.60, post_mat))    # mast

	# --- the sign: a chalk slate, framed in purple wire ---
	var slate_mat := _matte_mat(Color(0.12, 0.13, 0.18), 0.9)
	var sign_y: float = 0.78
	add_child(_box(Vector3(0.0, sign_y, 0.0), Vector3(0.78, 0.30, 0.02), slate_mat))
	var frame_mat := _glow_mat(wire_purple, 0.7)
	_frame_rect(Vector3(0.0, sign_y, 0.012), 0.78, 0.30, frame_mat)
	add_child(_billboard_label("THIS STATEMENT", Vector3(0.0, sign_y + 0.05, 0.02), 26, cool_white))
	add_child(_billboard_label("IS FALSE", Vector3(0.0, sign_y - 0.06, 0.02), 30, false_red))

	# --- the truth-lamp above the sign — a glass bulb that flips T/F ---
	_lamp_mat = _glow_mat(true_green, 1.6)
	_lamp = _sphere(Vector3(0.0, 1.06, 0.0), 0.07, _lamp_mat)
	add_child(_lamp)
	# bulb cage
	var cage_mat := _steel_mat(Color(0.55, 0.58, 0.66))
	add_child(_torus(Vector3(0.0, 1.06, 0.0), 0.085, 0.006, cage_mat))
	# the two verdict labels flanking the lamp; the active one brightens
	_true_lbl = _billboard_label("TRUE", Vector3(-0.22, 1.06, 0.0), 20, true_green)
	_false_lbl = _billboard_label("FALSE", Vector3(0.22, 1.06, 0.0), 20, false_red)
	add_child(_true_lbl)
	add_child(_false_lbl)

	# --- the looping arrow chasing its own tail around the sign ---
	_loop_arrow = Node3D.new()
	add_child(_loop_arrow)
	_rebuild_loop(0.0)

	# --- billboard title ---
	add_child(_billboard_label("LIAR LOOP", Vector3(0.0, 1.5, 0.0), 34, cool_white))
	add_child(_billboard_label("true -> false -> true ...", Vector3(0.0, 1.36, 0.0), 16, wire_purple))


func _frame_rect(center: Vector3, w: float, h: float, mat: Material) -> void:
	add_child(_box(center + Vector3(0.0, h * 0.5, 0.0), Vector3(w, 0.01, 0.01), mat))
	add_child(_box(center + Vector3(0.0, -h * 0.5, 0.0), Vector3(w, 0.01, 0.01), mat))
	add_child(_box(center + Vector3(-w * 0.5, 0.0, 0.0), Vector3(0.01, h, 0.01), mat))
	add_child(_box(center + Vector3(w * 0.5, 0.0, 0.0), Vector3(0.01, h, 0.01), mat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# oscillation between TRUE and FALSE — never settles. Hold each value,
	# then ease across the flip for a crisp-but-smooth toggle.
	var phase: float = fmod(_t, oscillate_period) / oscillate_period
	var t2: float = absf(phase * 2.0 - 1.0)  # 0 = FALSE end, 1 = TRUE end
	var col: Color = false_red.lerp(true_green, smoothstep(0.35, 0.65, t2))
	if is_instance_valid(_lamp_mat):
		_lamp_mat.albedo_color = col
		_lamp_mat.emission = col
		_lamp_mat.emission_energy_multiplier = (1.4 + 0.6 * sin(_t * 6.0)) if emissive else 0.5
	# highlight the active verdict label
	if is_instance_valid(_true_lbl) and is_instance_valid(_false_lbl):
		var hot: float = t2  # 0 = FALSE side, 1 = TRUE side
		_true_lbl.modulate = true_green.lerp(true_green.darkened(0.6), 1.0 - hot)
		_false_lbl.modulate = false_red.lerp(false_red.darkened(0.6), hot)
		_true_lbl.scale = Vector3.ONE * (0.85 + 0.4 * hot)
		_false_lbl.scale = Vector3.ONE * (0.85 + 0.4 * (1.0 - hot))

	# the loop arrow chases its own tail — rotate the head around the ring
	if is_instance_valid(_loop_arrow):
		_rebuild_loop(_t)


func _rebuild_loop(t: float) -> void:
	for c in _loop_arrow.get_children():
		_loop_arrow.remove_child(c)
		c.queue_free()
	var mat := _glow_mat(wire_purple, 1.3)
	var cy: float = 0.78
	var seg: int = 16
	var head_angle: float = fmod(t * 1.6, TAU)
	# draw an almost-closed ring of short tubes around the sign
	for i in range(seg):
		var a0: float = float(i) / float(seg) * TAU + head_angle
		var a1: float = float(i + 1) / float(seg) * TAU + head_angle
		# leave a small gap (the "mouth" the tail never quite reaches)
		if i == seg - 1:
			continue
		var p0: Vector3 = Vector3(cos(a0) * _loop_r, cy + sin(a0) * 0.16, 0.06)
		var p1: Vector3 = Vector3(cos(a1) * _loop_r, cy + sin(a1) * 0.16, 0.06)
		_loop_arrow.add_child(_cylinder_between(p0, p1, 0.008, mat))
	# arrowhead at the leading end, pointing tangentially toward the tail
	var ah: float = head_angle
	var tip: Vector3 = Vector3(cos(ah) * _loop_r, cy + sin(ah) * 0.16, 0.06)
	var prev: Vector3 = Vector3(cos(ah - 0.25) * _loop_r, cy + sin(ah - 0.25) * 0.16, 0.06)
	var head_mat := _glow_mat(false_red, 1.5)
	var dir: Vector3 = (tip - prev).normalized()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.024
	cone.height = 0.05
	var head := MeshInstance3D.new()
	head.mesh = cone
	head.material_override = head_mat
	head.transform = Transform3D(_basis_y_to(dir), tip + dir * 0.025)
	_loop_arrow.add_child(head)
