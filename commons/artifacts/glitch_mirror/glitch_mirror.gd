extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GlitchMirror

## @identity
## lineage: the color taxonomy's rung 11 — a standing mirror that refuses to reflect.
##   Instead it shows the screen's own flesh: an image dissolved into its subpixel
##   triads, three thin lights per cell, with seeded rows sheared sideways mid-image
##   and a banding strip down one edge where a smooth gradient breaks into steps.
## essence: digital materiality. Every colour this project has taught arrives at the
##   eye as R, G and B slivers lying in close formation — the zoom-in culture never
##   performs is built permanently into this frame. The glitch is not damage: it is
##   the surface admitting what it is made of. The queer flesh of digital colour.
## truth: look closely and the image is three lights lying. The mirror shows the
##   screen's body, not your face.
##
## The 2026-08-27 color taxonomy (doc/COLOR_TAXONOMY.md), rung 11 of 12.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 31
@export_range(8, 20) var cols: int = 12
@export_range(10, 26) var rows: int = 18
@export var face_w: float = 1.15
@export var face_h: float = 1.85
## How many seeded row-bands shear sideways, and how far (in cells).
@export_range(0, 6) var tears: int = 3

func _ready() -> void:
	_rng.seed = seed
	_build_frame()
	_build_flesh()
	_build_banding_strip()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "cols", "rows", "tears"]:
		if config_data.has(key):
			set(key, config_data[key])

# --- the "image": a smooth two-colour field the subpixels will confess ---------------

func _image_at(u: float, v: float) -> Color:
	# a quiet portrait-ish field: warm above, cool below, a diagonal drift
	var t := clampf(v * 0.85 + 0.25 * sin(u * 3.1 + v * 2.0), 0.0, 1.0)
	return Color(0.85, 0.45, 0.35).lerp(Color(0.2, 0.35, 0.75), t)

func _build_frame() -> void:
	var brass := _steel_mat(Color(0.5, 0.42, 0.26))
	for spec in [[Vector3(0.0, face_h + 0.32, 0.0), Vector3(face_w + 0.24, 0.1, 0.1)],
			[Vector3(0.0, 0.28, 0.0), Vector3(face_w + 0.24, 0.1, 0.1)],
			[Vector3(-(face_w + 0.14) * 0.5, face_h * 0.5 + 0.3, 0.0), Vector3(0.1, face_h + 0.14, 0.1)],
			[Vector3((face_w + 0.14) * 0.5, face_h * 0.5 + 0.3, 0.0), Vector3(0.1, face_h + 0.14, 0.1)]]:
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = spec[1]
		bar.mesh = bm
		bar.position = spec[0]
		bar.material_override = brass
		add_child(bar)
	for side in [-1.0, 1.0]:
		var foot := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(0.14, 0.06, 0.6)
		foot.mesh = fm
		foot.position = Vector3(side * (face_w * 0.5 - 0.05), 0.03, 0.0)
		foot.material_override = brass
		add_child(foot)
	# the black glass behind the triads
	var backing := MeshInstance3D.new()
	var km := BoxMesh.new()
	km.size = Vector3(face_w, face_h, 0.03)
	backing.mesh = km
	backing.position = Vector3(0.0, face_h * 0.5 + 0.3, 0.0)
	backing.material_override = _matte_mat(Color(0.02, 0.02, 0.025), 0.3, 0.4)
	add_child(backing)

func _build_flesh() -> void:
	# seeded shear bands: which rows tear, and by how many cells
	var tear_rows := {}
	for i in range(tears):
		var r0 := _rng.randi_range(2, rows - 3)
		var span := _rng.randi_range(1, 2)
		var shift := _rng.randf_range(-2.2, 2.2)
		for r in range(r0, mini(r0 + span, rows)):
			tear_rows[r] = shift
	var cw := face_w / float(cols)
	var ch := face_h / float(rows)
	var sub_w := cw * 0.24
	for r in range(rows):
		var shift: float = tear_rows.get(r, 0.0)
		for c in range(cols):
			var u := (float(c) + 0.5) / float(cols)
			var v := 1.0 - (float(r) + 0.5) / float(rows)
			var px := _image_at(u, v)
			# a torn row also hue-rotates — the classic glitch chroma slip
			if shift != 0.0:
				px = Color.from_hsv(fmod(px.h + 0.33, 1.0), px.s, px.v)
			var x0 := -face_w * 0.5 + cw * (float(c) + 0.5) + shift * cw
			if x0 < -face_w * 0.5 + sub_w or x0 > face_w * 0.5 - sub_w:
				continue                    # sheared off the glass — the tear eats cells
			var y := 0.3 + face_h - ch * (float(r) + 0.5)
			var energies := [px.r, px.g, px.b]
			var tints := [Color(1, 0.08, 0.06), Color(0.08, 1, 0.1), Color(0.12, 0.25, 1)]
			for k in range(3):
				var bar := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(sub_w, ch * 0.86, 0.012)
				bar.mesh = bm
				bar.position = Vector3(x0 + (float(k) - 1.0) * sub_w * 1.15, y, 0.025)
				var e: float = energies[k]
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(0.01, 0.01, 0.01)
				mat.emission_enabled = true
				mat.emission = tints[k]
				mat.emission_energy_multiplier = (0.05 + 2.1 * e) if emissive else (0.02 + 0.7 * e)
				bar.material_override = mat
				add_child(bar)

func _build_banding_strip() -> void:
	# beside the glass: the same gradient twice — smooth, then broken into 8 steps.
	# banding is what quantisation does to a path (rung 8's road, put through a byte)
	var x := face_w * 0.5 + 0.28
	for smooth in [true, false]:
		var n := 40 if smooth else 8
		for k in range(n):
			var t := (float(k) + 0.5) / float(n)
			var c := _image_at(0.5, t)
			var seg := MeshInstance3D.new()
			var sm := BoxMesh.new()
			sm.size = Vector3(0.11, face_h / float(n) * 0.96, 0.02)
			seg.mesh = sm
			seg.position = Vector3(x + (0.0 if smooth else 0.15), 0.3 + face_h - face_h * t, 0.01)
			var mat := _glow_mat(c, 0.8)
			seg.material_override = mat
			add_child(seg)

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "MirrorPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-face_w * 0.5 - 0.5, 0.24, 0.55)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("GLITCH MIRROR",
			"The mirror shows the screen's flesh, not your face: every cell is three\nlights lying in formation, torn rows slip sideways and hue-rotate, and the\nedge strip is one gradient twice - smooth, then broken into eight honest steps.")
