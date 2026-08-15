extends Node3D
class_name MountingYard

## mounting_yard — what a thing is mounted on says what it is for.
##
## THE FAMILY, AND IT IS THE LARGEST UNBUILT ONE IN THE CORPUS. Ten artifacts declare
## `support` and no two of them quite agree on the words. catalyst_target says none / cradle /
## frame / gantry. code_display, tt and info_board say none / stand / frame / pylon or cabinet.
## fire_extinguisher and fire_hose_box say bracket / stand / cabinet. science_screen says
## stand / frame / cabinet / pylon. double_helix_scene says monument / bench / vitrine /
## terrace. pollock_painting_in_3d says floor / table / easel / wall.
##
## Six vocabularies, thirteen distinct words, one axis. Underneath them is the same ladder,
## which is why nobody noticed: from the thing UNSUPPORTED to the thing FULLY HOUSED.
##
## THE ARGUMENT. A mount is read as a practical detail — how do we keep it off the floor. It
## is not. Each rung makes a different claim about what kind of object this is:
##
##   none     the thing floats. It is an idea, and gravity is not part of its argument.
##   bracket  it is EQUIPMENT. Bolted to a wall, reachable in a hurry, owned by the building.
##   stand    it is an instrument. It has a working height, so it has a user.
##   frame    it is a picture. The frame says where the object stops and the world starts.
##   cabinet  it is a SPECIMEN. Enclosed, kept, protected from the person looking at it.
##   pylon    it is signage. It is not for holding, it is for being seen from far off.
##
## The same object under six mounts is six different institutions. That is the whole claim,
## and it is why the family's members disagree about words: each one picked the vocabulary of
## the institution it already belonged to.
##
## THE BODY, NOT A GAUGE. One object, actually built, actually mounted six ways in real
## geometry. No labels — if the rung is not legible from the carpentry, the carpentry is wrong.

## The mount. Six rungs pooled from the family's six vocabularies: the words that recur
## (none, stand, frame, cabinet, pylon) plus bracket, which fire_extinguisher and fire_hose_box
## share and which is the only rung that says the building owns the object.
@export_enum("none", "bracket", "stand", "frame", "cabinet", "pylon") var support: String = "stand":
	set(v):
		support = v
		if is_inside_tree():
			_rebuild()

## What is mounted. The claim only holds if the SAME object survives every rung, so the
## occupant is switchable and each value is a different kind of thing to be institutionalised.
@export_enum("plate", "vessel", "specimen") var occupant: String = "plate":
	set(v):
		occupant = v
		if is_inside_tree():
			_rebuild()

@export var height: float = 1.05

const BRASS := Color(0.78, 0.66, 0.38)
const STEEL := Color(0.52, 0.55, 0.60)
const DARK := Color(0.28, 0.29, 0.32)

var _built: Array[Node3D] = []


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("support"):
		support = str(config_data["support"])
	if config_data.has("occupant"):
		occupant = str(config_data["occupant"])
	_rebuild()


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var root := Node3D.new()
	root.name = "%s_%s" % [support, occupant]
	add_child(root)
	_built.append(root)
	# Where the object ends up is itself part of the claim — a bracket puts it at chest height
	# on a wall, a pylon puts it above the head, a cabinet lowers it to be looked down into.
	var y: float = _occupant_height()
	_build_mount(root)
	var holder := Node3D.new()
	holder.position = Vector3(0.0, y, _occupant_depth())
	root.add_child(holder)
	_build_occupant(holder)


func _occupant_height() -> float:
	match support:
		"none": return height * 0.86
		"bracket": return height * 0.78
		"stand": return height * 0.66
		"frame": return height * 0.72
		"cabinet": return height * 0.50
		"pylon": return height * 1.02
	return height * 0.7


func _occupant_depth() -> float:
	# A bracket and a frame hold the object off a wall behind it; the rest stand it centred.
	return 0.10 if (support == "bracket" or support == "frame") else 0.0


func _build_mount(root: Node3D) -> void:
	match support:
		"none":
			pass
		"bracket":
			root.add_child(_box(Vector3(0.0, height * 0.62, -0.10),
					Vector3(0.62, height * 0.86, 0.03), DARK))          # the wall it belongs to
			root.add_child(_box(Vector3(-0.10, height * 0.74, 0.0),
					Vector3(0.03, 0.03, 0.22), STEEL))
			root.add_child(_box(Vector3(0.10, height * 0.74, 0.0),
					Vector3(0.03, 0.03, 0.22), STEEL))
			root.add_child(_box(Vector3(0.0, height * 0.70, 0.02),
					Vector3(0.26, 0.02, 0.02), STEEL))
		"stand":
			root.add_child(_cyl(Vector3(0.0, height * 0.31, 0.0), 0.030, height * 0.62, STEEL))
			root.add_child(_cyl(Vector3(0.0, 0.012, 0.0), 0.16, 0.024, DARK))
			root.add_child(_box(Vector3(0.0, height * 0.63, 0.0),
					Vector3(0.26, 0.018, 0.20), BRASS))
		"frame":
			root.add_child(_box(Vector3(0.0, height * 0.62, -0.10),
					Vector3(0.70, height * 0.90, 0.03), DARK))
			var w := 0.46
			var h := 0.40
			var cy := height * 0.72
			for e in [[Vector3(0.0, cy + h * 0.5, 0.0), Vector3(w + 0.05, 0.05, 0.05)],
					[Vector3(0.0, cy - h * 0.5, 0.0), Vector3(w + 0.05, 0.05, 0.05)],
					[Vector3(-w * 0.5, cy, 0.0), Vector3(0.05, h, 0.05)],
					[Vector3(w * 0.5, cy, 0.0), Vector3(0.05, h, 0.05)]]:
				root.add_child(_box(e[0], e[1], BRASS))
		"cabinet":
			root.add_child(_box(Vector3(0.0, height * 0.24, 0.0),
					Vector3(0.52, height * 0.48, 0.40), DARK))          # the plinth
			var gy := height * 0.62
			for e in [[Vector3(0.0, gy + 0.20, 0.0), Vector3(0.48, 0.035, 0.36)],
					[Vector3(-0.24, gy, 0.0), Vector3(0.035, 0.40, 0.035)],
					[Vector3(0.24, gy, 0.0), Vector3(0.035, 0.40, 0.035)],
					[Vector3(-0.24, gy, -0.18), Vector3(0.035, 0.40, 0.035)],
					[Vector3(0.24, gy, -0.18), Vector3(0.035, 0.40, 0.035)],
					[Vector3(-0.24, gy, 0.18), Vector3(0.035, 0.40, 0.035)],
					[Vector3(0.24, gy, 0.18), Vector3(0.035, 0.40, 0.035)]]:
				root.add_child(_box(e[0], e[1], BRASS))
			# The glass. It is the rung's whole argument: you may look and not touch.
			var g := _box(Vector3(0.0, gy, 0.0), Vector3(0.46, 0.40, 0.34), Color(0.62, 0.74, 0.78))
			var gm := g.material_override as StandardMaterial3D
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.albedo_color = Color(0.62, 0.74, 0.78, 0.16)
			root.add_child(g)
		"pylon":
			root.add_child(_cyl(Vector3(0.0, height * 0.50, 0.0), 0.055, height * 1.00, STEEL))
			root.add_child(_cyl(Vector3(0.0, 0.020, 0.0), 0.22, 0.040, DARK))
			root.add_child(_box(Vector3(0.0, height * 1.00, 0.0),
					Vector3(0.34, 0.030, 0.16), BRASS))


func _build_occupant(h: Node3D) -> void:
	match occupant:
		"plate":
			h.add_child(_box(Vector3.ZERO, Vector3(0.30, 0.22, 0.012), BRASS))
			h.add_child(_box(Vector3(0.0, 0.0, 0.008), Vector3(0.22, 0.14, 0.004),
					Color(0.90, 0.86, 0.74)))
		"vessel":
			h.add_child(_cyl(Vector3(0.0, 0.09, 0.0), 0.085, 0.18, Color(0.72, 0.76, 0.70)))
			h.add_child(_cyl(Vector3(0.0, 0.19, 0.0), 0.035, 0.04, BRASS))
		"specimen":
			var mi := MeshInstance3D.new()
			var sp := SphereMesh.new()
			sp.radius = 0.085
			sp.height = 0.17
			sp.radial_segments = 14
			sp.rings = 8
			mi.mesh = sp
			mi.position = Vector3(0.0, 0.10, 0.0)
			mi.material_override = _mat(Color(0.80, 0.60, 0.52), 0.12)
			h.add_child(mi)
			h.add_child(_cyl(Vector3(0.0, 0.012, 0.0), 0.045, 0.024, DARK))


func _box(pos: Vector3, size: Vector3, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = _mat(col, 0.0)
	return mi


func _cyl(pos: Vector3, r: float, h: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 14
	mi.mesh = cm
	mi.position = pos
	mi.material_override = _mat(col, 0.0)
	return mi


func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	m.metallic = 0.25 if c == STEEL or c == BRASS else 0.0
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m
