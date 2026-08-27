extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ItalicBookcase

## @identity
## lineage: the Shear hero — a bookcase set in italics. Every shelf has slid a little
##   further sideways than the one below, the books leaning with their shelves into
##   perfect parallelograms, and none of them falls, because shear is not a tilt: the
##   shelves are still level, the columns still count, only the verticals lost their
##   right angle. A plumb line hangs beside it, telling the truth the case abandoned.
## essence: shear slides parallel layers past each other in proportion to height —
##   x' = x + k·y. Areas survive (each shelf holds exactly the books it held), angles
##   do not. The straight spine turned slanted spine IS the transform.
## truth: shear is the typography of space: the same text, set slanted. Emphasis,
##   not damage.
##
## The 2026-08-27 category-heroes pass, transformation.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const BOOK_COLORS := [Color(0.78, 0.16, 0.12), Color(0.92, 0.75, 0.14), Color(0.13, 0.30, 0.62), Color(0.10, 0.10, 0.11), Color(0.88, 0.86, 0.82), Color(0.20, 0.42, 0.17)]

@export var seed: int = 26
@export_range(2, 6) var shelves: int = 4
@export var shelf_w: float = 1.5
@export var shelf_gap: float = 0.42
## The shear factor k in x' = x + k*y. 0.34 sets the top shelf ~0.6 m over — a case
## unmistakably in italics, still unmistakably a case.
@export var k_shear: float = 0.34

func _ready() -> void:
	_rng.seed = seed
	_build_case()
	_build_plumb()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "shelves", "shelf_w", "k_shear"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_case() -> void:
	var base_y := 0.12
	var plinth := MeshInstance3D.new()
	var plinth_mesh := BoxMesh.new()
	plinth_mesh.size = Vector3(shelf_w + 0.3, 0.12, 0.5)
	plinth.mesh = plinth_mesh
	plinth.position = Vector3(0.0, 0.06, 0.0)
	plinth.material_override = _matte_mat(Color(0.25, 0.16, 0.09), 0.85)
	add_child(plinth)
	for level in range(shelves + 1):
		var y := base_y + shelf_gap * float(level)
		var dx := k_shear * (y - base_y)
		var shelf := MeshInstance3D.new()
		var shelf_mesh := BoxMesh.new()
		shelf_mesh.size = Vector3(shelf_w, 0.045, 0.42)
		shelf.mesh = shelf_mesh
		shelf.position = Vector3(dx, y, 0.0)
		shelf.material_override = _matte_mat(Color(0.35, 0.22, 0.12), 0.85)
		add_child(shelf)
		# the uprights between this shelf and the next: SHEARED, not tilted — they
		# lean at exactly atan(k), the same lean the books wear
		if level < shelves:
			var lean := atan(k_shear)
			for sx in [-shelf_w * 0.5 + 0.03, shelf_w * 0.5 - 0.03]:
				var upright := MeshInstance3D.new()
				var upright_mesh := BoxMesh.new()
				upright_mesh.size = Vector3(0.05, shelf_gap / cos(lean), 0.42)
				upright.mesh = upright_mesh
				var y_mid := y + shelf_gap * 0.5
				upright.position = Vector3(k_shear * (y_mid - base_y) + sx, y_mid, 0.0)
				upright.rotation.z = -lean
				upright.material_override = _matte_mat(Color(0.30, 0.19, 0.10), 0.85)
				add_child(upright)
			_fill_shelf(y + 0.025, dx)

func _fill_shelf(y: float, dx: float) -> void:
	# books as parallelograms: box + z-rotation is a TILT, so each book is built
	# leaning at atan(k) with its height stretched to keep the top edge level —
	# the parallelogram the shear actually makes
	var lean := atan(k_shear)
	var x := -shelf_w * 0.5 + 0.1
	while x < shelf_w * 0.5 - 0.12:
		var w := _rng.randf_range(0.045, 0.085)
		var h := _rng.randf_range(0.22, 0.34)
		var book := MeshInstance3D.new()
		var book_mesh := BoxMesh.new()
		book_mesh.size = Vector3(w, h / cos(lean), _rng.randf_range(0.22, 0.3))
		book.mesh = book_mesh
		book.position = Vector3(dx + x + k_shear * h * 0.5, y + h * 0.5, 0.0)
		book.rotation.z = -lean
		book.material_override = _matte_mat(BOOK_COLORS[_rng.randi() % BOOK_COLORS.size()], 0.8)
		add_child(book)
		x += w + _rng.randf_range(0.008, 0.03)

func _build_plumb() -> void:
	# the witness: a plumb line from the top shelf's END, dead vertical, the right
	# angle the bookcase gave up — hanging beside the lean so the eye can subtract
	var top_y := 0.12 + shelf_gap * float(shelves)
	var anchor := Vector3(k_shear * (top_y - 0.12) + shelf_w * 0.5 + 0.22, top_y + 0.05, 0.0)
	var line := MeshInstance3D.new()
	var line_mesh := CylinderMesh.new()
	line_mesh.top_radius = 0.004
	line_mesh.bottom_radius = 0.004
	line_mesh.height = anchor.y - 0.08
	line.mesh = line_mesh
	line.position = Vector3(anchor.x, (anchor.y + 0.08) * 0.5, 0.0)
	line.material_override = _matte_mat(Color(0.35, 0.35, 0.37), 0.5, 0.8)
	add_child(line)
	var bob := MeshInstance3D.new()
	var bob_mesh := CylinderMesh.new()
	bob_mesh.top_radius = 0.035
	bob_mesh.bottom_radius = 0.0
	bob_mesh.height = 0.09
	bob.mesh = bob_mesh
	bob.position = Vector3(anchor.x, 0.1, 0.0)
	bob.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(bob)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "ItalicPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-shelf_w * 0.5 - 0.5, 0.24, 0.6)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("ITALIC BOOKCASE - x' = x + %.2f y" % k_shear,
			"Shear slides parallel layers in proportion to height. Every shelf still\nlevel, every shelf still full - areas survive, right angles do not.\nThe plumb line remembers. The bookcase is just emphasis.")
