extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GrooveLens

## @identity
## lineage: the Second-costume hero — a turntable mid-song, with a giant jeweller's
##   loupe swung over the needle. Under the lens the groove stops being a hairline
##   and becomes a wall you could walk beside: a sine cut in vinyl, with the stylus
##   riding one crest. The record is a wave laid in a spiral and played back as pitch.
## essence: the SAME sin(t), pushed 44,100 times a second, stops being motion and
##   becomes sound. Seen and heard are one function wearing two costumes - and the
##   groove is where the costume change happens: shape on the way in, note on the
##   way out.
## truth: music is geometry at speed. Slow it down far enough and you can stand in it.
##
## The 2026-08-29 category-heroes pass, wavefunctions.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 6
## Angle of the magnified groove arc, radians of visible wedge.
@export var wedge: float = 1.5

func _ready() -> void:
	_rng.seed = seed
	_build_deck()
	_build_lens()
	_build_groove_wall()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "wedge"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_deck() -> void:
	# console the deck stands on, then plinth-deck, platter, record, spindle, tonearm
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(1.1, 0.84, 0.8), _matte_mat(Color(0.24, 0.2, 0.17), 0.8)))
	add_child(_box(Vector3(0.0, 0.89, 0.0), Vector3(1.16, 0.1, 0.86), _matte_mat(Color(0.36, 0.26, 0.16), 0.7)))
	add_child(_cylinder(Vector3(-0.08, 0.96, 0.0), 0.34, 0.04, _matte_mat(Color(0.7, 0.7, 0.72), 0.35, 0.8)))
	add_child(_cylinder(Vector3(-0.08, 0.985, 0.0), 0.3, 0.012, _matte_mat(Color(0.08, 0.08, 0.1), 0.45)))
	add_child(_cylinder(Vector3(-0.08, 1.0, 0.0), 0.045, 0.02, _matte_mat(Color(0.85, 0.3, 0.25), 0.6)))
	add_child(_cylinder(Vector3(-0.08, 1.03, 0.0), 0.008, 0.05, _steel_mat(Color(0.7, 0.7, 0.75))))
	# groove rings suggested on the vinyl
	for i in range(4):
		add_child(_torus(Vector3(-0.08, 0.995, 0.0), 0.10 + 0.05 * float(i), 0.0016, _matte_mat(Color(0.16, 0.16, 0.18), 0.4)))
	# tonearm from the corner to the groove the lens watches
	var pivot := Vector3(0.34, 1.02, -0.26)
	var head := Vector3(0.10, 1.0, 0.14)
	add_child(_cylinder(pivot + Vector3(0.0, -0.02, 0.0), 0.035, 0.08, _matte_mat(Color(0.2, 0.2, 0.22), 0.5, 0.6)))
	add_child(_cylinder_between(pivot, head, 0.012, _steel_mat(Color(0.75, 0.75, 0.8))))
	add_child(_box(head + Vector3(0.0, -0.015, 0.0), Vector3(0.05, 0.03, 0.03), _matte_mat(Color(0.12, 0.12, 0.14), 0.5)))

func _build_lens() -> void:
	# the giant loupe on a swing arm, hanging over the stylus
	var post := Vector3(0.52, 0.0, 0.3)
	add_child(_cylinder(post + Vector3(0.0, 0.7, 0.0), 0.03, 1.4, _matte_mat(Color(0.2, 0.2, 0.24), 0.5, 0.6)))
	add_child(_cylinder(post + Vector3(0.0, 0.03, 0.0), 0.14, 0.06, _matte_mat(Color(0.2, 0.2, 0.24), 0.5, 0.6)))
	var elbow := post + Vector3(0.0, 1.36, 0.0)
	var lens_c := Vector3(0.10, 1.32, 0.14)
	add_child(_cylinder_between(elbow, lens_c + Vector3(0.0, 0.10, 0.0), 0.02, _matte_mat(Color(0.2, 0.2, 0.24), 0.5, 0.6)))
	# the loupe lies FLAT, hovering over the stylus - a reading glass, not a hoop
	var rim := _torus(lens_c, 0.20, 0.022, _steel_mat(Color(0.72, 0.58, 0.28)))
	add_child(rim)
	var disc := _cylinder(lens_c, 0.19, 0.015, _glass_mat(Color(0.8, 0.92, 0.95), 0.22))
	add_child(disc)
	# the cone of magnification, faint, from lens down to the stylus point
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.18
	cm.bottom_radius = 0.02
	cm.height = 0.30
	cone.mesh = cm
	cone.material_override = _glass_mat(Color(0.9, 0.9, 0.6), 0.10)
	cone.position = lens_c + Vector3(0.0, -0.17, 0.0)
	add_child(cone)

func _build_groove_wall() -> void:
	# WHAT THE LENS SEES, built full-size beside the deck: an arc of the groove at
	# a thousand to one - a vinyl wall whose top edge is the recorded sine, and a
	# stylus the size of a boot riding one crest.
	var c := Vector3(-0.08, 0.0, 0.0)
	var R := 1.55
	var n := 30
	var a0 := -wedge * 0.5 + PI * 0.5
	for i in range(n):
		var a := a0 + wedge * float(i) / float(n)
		var h := 0.34 + 0.16 * sin(float(i) / float(n) * TAU * 2.0)
		var p := c + Vector3(cos(a) * R, h * 0.5, sin(a) * R)
		var seg := _box(p, Vector3(0.34, h, 0.16), _matte_mat(Color(0.10, 0.10, 0.12), 0.55))
		seg.rotation.y = -a
		add_child(seg)
	# the giant stylus: a steel cone standing in the groove's crest
	var ai := a0 + wedge * 0.62
	var hi := 0.34 + 0.16 * sin(0.62 * TAU * 2.0)
	var tipp := c + Vector3(cos(ai) * R, hi + 0.02, sin(ai) * R)
	var sty := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.085
	sm.bottom_radius = 0.0
	sm.height = 0.34
	sty.mesh = sm
	sty.material_override = _steel_mat(Color(0.78, 0.78, 0.84))
	sty.position = tipp + Vector3(0.0, 0.17, 0.0)
	add_child(sty)
	add_child(_sphere(tipp, 0.03, _glow_mat(Color(1.0, 0.6, 0.3), 2.2)))
	# and the pitch leaving it: three faint rings rising from the crest
	for i in range(3):
		var ring := _torus(tipp + Vector3(0.0, 0.42 + 0.14 * float(i), 0.0), 0.05 + 0.05 * float(i), 0.004, _glass_mat(Color(0.95, 0.85, 0.5), 0.45))
		add_child(ring)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "GroovePlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(0.75, 0.24, 0.85)
	ts.rotation.y = deg_to_rad(-6.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("GROOVE LENS - the second costume",
			"Under the loupe the groove stops being a hairline and becomes a wall:\na sine cut in vinyl, stylus riding one crest. Shape on the way in,\nnote on the way out. Music is geometry at speed - slow it down and stand in it.")
