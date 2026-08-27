extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SevenWordsChoir

## @identity
## lineage: the primitives taxonomy's "seven words" rung — the engine's entire
##   primitive vocabulary on choir risers: Plane, Box, Sphere, Cylinder, Capsule,
##   Prism, Torus, each in its own robe, each with its name on a plate, arranged
##   like a choir mid-hymn. Every body in this world is sentences made of these.
## essence: PrimitiveMesh has exactly these words. Everything the corpus has ever
##   shown — the fountains, the mobiles, the mirrors — is composition, never new
##   vocabulary: cylinders wearing arm duties, spheres hired as points, boxes as
##   crates and chairs and museums. Meet the whole alphabet at once, undisguised.
## truth: seven words, infinite sentences.
##
## The 2026-08-27 primitives taxonomy refinement (doc/PRIMITIVES_TAXONOMY.md).

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 53
## Breathing: the choir swells gently in turn, one word at a time.
@export var breath: float = 0.06

var _singers: Array = []               # {node, phase}

func _ready() -> void:
	_rng.seed = seed
	_build_risers()
	_build_choir()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "breath"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(_delta: float) -> void:
	var t := float(Time.get_ticks_msec()) / 1000.0
	for s in _singers:
		var n: Node3D = s["node"]
		n.scale = Vector3.ONE * (1.0 + breath * maxf(sin(t * 1.4 + s["phase"]), 0.0))

func _build_risers() -> void:
	for row in range(2):
		var riser := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(3.4 - 0.7 * float(row), 0.18, 0.7)
		riser.mesh = rm
		riser.position = Vector3(0.0, 0.09 + 0.22 * float(row), -0.4 * float(row))
		riser.material_override = _matte_mat(Color(0.16, 0.14, 0.13), 0.85)
		add_child(riser)

func _build_choir() -> void:
	# the whole vocabulary, front row four, back row three — robes from one warm choir
	# palette so the SHAPES carry all the difference
	var words: Array = []
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.4, 0.4)
	words.append(["Plane", plane, Vector3(-1.3, 0.0, 0.0), 0])
	var box := BoxMesh.new()
	box.size = Vector3(0.34, 0.34, 0.34)
	words.append(["Box", box, Vector3(-0.44, 0.0, 0.0), 0])
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	words.append(["Sphere", sphere, Vector3(0.44, 0.0, 0.0), 0])
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.16
	cyl.bottom_radius = 0.16
	cyl.height = 0.4
	words.append(["Cylinder", cyl, Vector3(1.3, 0.0, 0.0), 0])
	var cap := CapsuleMesh.new()
	cap.radius = 0.14
	cap.height = 0.46
	words.append(["Capsule", cap, Vector3(-0.85, 0.0, 0.0), 1])
	var prism := PrismMesh.new()
	prism.size = Vector3(0.36, 0.36, 0.36)
	words.append(["Prism", prism, Vector3(0.0, 0.0, 0.0), 1])
	var torus := TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = 0.22
	words.append(["Torus", torus, Vector3(0.85, 0.0, 0.0), 1])
	for i in range(words.size()):
		var w: Array = words[i]
		var row: int = w[3]
		var base := Vector3(w[2].x, 0.18 + 0.22 * float(row) + 0.34, -0.4 * float(row))
		var singer := Node3D.new()
		singer.position = base
		add_child(singer)
		var body := MeshInstance3D.new()
		body.mesh = w[1]
		if w[0] == "Plane":
			body.rotation.x = deg_to_rad(65.0)   # a plane lies down by default; a chorister stands
		body.material_override = _matte_mat(Color.from_hsv(0.06 + 0.02 * float(i), 0.45, 0.85), 0.65)
		singer.add_child(body)
		_singers.append({"node": singer, "phase": TAU * float(i) / 7.0})
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.14
		tag.position = Vector3(base.x, 0.2 + 0.22 * float(row), base.z + 0.4)
		add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text(w[0], "")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "ChoirPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-1.85, 0.24, 0.8)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("SEVEN WORDS CHOIR",
			"PrimitiveMesh has exactly these words: Plane, Box, Sphere, Cylinder,\nCapsule, Prism, Torus. Everything in this world - fountains, mobiles,\nmirrors - is composition, never new vocabulary. Seven words, infinite sentences.")
