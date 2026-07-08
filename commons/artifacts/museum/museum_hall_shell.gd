extends Node3D
class_name MuseumHallShell

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the museum hall as a wearable shell — a two-story stone arcade with a glass skylight roof, erected AROUND an existing grid map without touching it. Cour Marly / Met / NHM typology reduced to a kit: pier, lintel, cornice, glass grid, tree, bench. Purely visual; the grid below keeps physics, utilities and truth.
# desire: to make architecture and placement come alive — a night at the museum where the collection is the spine's own artifacts.
# critical_parameter: width/depth/height (metres) via config — the shell sizes itself to whatever court it is asked to dress.
# triggers: _ready builds arcade walls (N/S two-story, E anchor wall, W entrance with opening), skylight beams + glass, corner trees, benches; apply_grid_config({width,depth,height}) resizes.
# emerges: the same flat grid reads as a museum the moment the arcade rhythm and top light arrive — placement grammar (axial anchor, flanking pairs, perimeter rhythm, open center) does the rest.
# needs: nothing from the grid; no collisions (decorative shell); BakedText for the frieze.
# relationships: the architectural face of the museum placement grammar; additive sibling of the proposed GridMap MeshLibrary renderer (gated, core grid untouched per the house rule); dressed first for [[Museum_Spine_Court]].
# truth: a museum is a chart you walk downward into — terraces are its axes, the anchor is its origin, and the light comes from above so the collection casts the shadows.

@export var hall_width: float = 26.0    # X
@export var hall_depth: float = 16.0    # Z
@export var wall_height: float = 9.0

const STONE := Color(0.86, 0.82, 0.72)
const STONE_DARK := Color(0.72, 0.67, 0.57)
const IRON := Color(0.33, 0.38, 0.36)
const GLASS := Color(0.78, 0.87, 0.96, 0.22)

var _built := false

func _ready() -> void:
	_read_meta_overrides()
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_meta_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()

func _read_meta_overrides() -> void:
	if has_meta("config_width"):
		hall_width = float(str(get_meta("config_width")))
	if has_meta("config_depth"):
		hall_depth = float(str(get_meta("config_depth")))
	if has_meta("config_height"):
		wall_height = float(str(get_meta("config_height")))

func _mat(c: Color, rough := 0.85, emit := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m

func _box(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)

func _build() -> void:
	_built = true
	var w := hall_width
	var d := hall_depth
	var h := wall_height
	var stone := _mat(STONE)
	var stone_d := _mat(STONE_DARK)
	var iron := _mat(IRON, 0.6)
	var glass := _mat(GLASS, 0.1, 0.15)

	# ── long arcade walls (N at -z, S at +z): two stories of pier + lintel ──
	var bay := 2.6
	var n_bays := int(floor(w / bay))
	for side_i in 2:
		var side: float = -1.0 + 2.0 * float(side_i)
		var z: float = side * d * 0.5
		for i in n_bays + 1:
			var x := -w * 0.5 + float(i) * (w / float(n_bays))
			_box(Vector3(0.55, 4.2, 0.55), Vector3(x, 2.1, z), stone)          # ground pier
			_box(Vector3(0.45, 3.2, 0.45), Vector3(x, 6.1, z), stone)          # upper pier
		_box(Vector3(w + 0.6, 0.5, 0.7), Vector3(0, 4.45, z), stone_d)          # lintel band
		_box(Vector3(w + 0.6, 0.4, 0.8), Vector3(0, 7.9, z), stone_d)           # cornice
		_box(Vector3(w + 0.6, 1.0, 0.25), Vector3(0, 8.6, z), stone)            # attic band
		# balustrade rhythm on the upper gallery
		for i in n_bays * 2:
			var x2 := -w * 0.5 + (float(i) + 0.5) * (w / float(n_bays * 2))
			_box(Vector3(0.12, 0.7, 0.12), Vector3(x2, 5.0, z - side * 0.35), stone_d)
		_box(Vector3(w + 0.4, 0.12, 0.16), Vector3(0, 5.4, z - side * 0.35), stone_d)

	# ── east anchor wall (behind the axial piece): tall blind arches ────────
	var ez := 0.0
	var e_bays := int(floor(d / bay))
	for i in e_bays + 1:
		ez = -d * 0.5 + float(i) * (d / float(e_bays))
		_box(Vector3(0.55, h * 0.82, 0.55), Vector3(w * 0.5, h * 0.41, ez), stone)
	_box(Vector3(0.7, 0.5, d + 0.6), Vector3(w * 0.5, 4.45, 0), stone_d)
	_box(Vector3(0.8, 0.4, d + 0.6), Vector3(w * 0.5, 7.9, 0), stone_d)
	_box(Vector3(0.4, h, d + 0.4), Vector3(w * 0.5 + 0.45, h * 0.5, 0), stone)  # solid back plane

	# ── west entrance wall: piers with a wide central opening ───────────────
	for i in e_bays + 1:
		var z3 := -d * 0.5 + float(i) * (d / float(e_bays))
		if abs(z3) < d * 0.22:
			continue                       # the doorway
		_box(Vector3(0.55, h * 0.82, 0.55), Vector3(-w * 0.5, h * 0.41, z3), stone)
	_box(Vector3(0.7, 0.5, d + 0.6), Vector3(-w * 0.5, 4.45, 0), stone_d)
	_box(Vector3(0.7, 1.2, d * 0.5), Vector3(-w * 0.5, 8.0, 0), stone)          # entablature over the door

	# ── skylight: iron beam grid + glass panels, the top light ─────────────
	var beams_x := int(floor(w / 2.2))
	for i in beams_x + 1:
		var x4 := -w * 0.5 + float(i) * (w / float(beams_x))
		_box(Vector3(0.14, 0.3, d), Vector3(x4, h, 0), iron)
	var beams_z := int(floor(d / 2.2))
	for i in beams_z + 1:
		var z4 := -d * 0.5 + float(i) * (d / float(beams_z))
		_box(Vector3(w, 0.3, 0.14), Vector3(0, h, z4), iron)
	_box(Vector3(w, 0.06, d), Vector3(0, h + 0.2, 0), glass)
	# the sky itself — a soft lit plane well above the glass, gentle
	_box(Vector3(w * 1.15, 0.05, d * 1.15), Vector3(0, h + 4.0, 0), _mat(Color(0.9, 0.93, 0.99), 0.4, 0.45))

	# ── trees and benches — the breath between the marbles ─────────────────
	var margin_x := w * 0.5 - 2.2
	var margin_z := d * 0.5 - 2.2
	for p in [Vector3(-margin_x, 0, -margin_z), Vector3(-margin_x, 0, margin_z),
			Vector3(margin_x * 0.35, 0, -margin_z), Vector3(margin_x * 0.35, 0, margin_z),
			Vector3(-margin_x * 0.35, 0, -margin_z), Vector3(-margin_x * 0.35, 0, margin_z)]:
		_tree(p)
	for p in [Vector3(0, 0, -margin_z + 1.2), Vector3(0, 0, margin_z - 1.2)]:
		_box(Vector3(2.0, 0.45, 0.55), p + Vector3(0, 0.225, 0), stone_d)

	# frieze
	var tag: Node3D = BakedText.make_tag("THE SPINE COURT", Color(0.35, 0.32, 0.27), 0.30,
		Color(0.9, 0.87, 0.79), false, Color(0, 0, 0, 0))
	if tag:
		tag.position = Vector3(-w * 0.5 + 0.6, 6.7, 0)
		tag.rotation_degrees = Vector3(0, 90, 0)
		add_child(tag)

func _tree(pos: Vector3) -> void:
	var planter := _mat(Color(0.45, 0.33, 0.24))
	var trunk := _mat(Color(0.38, 0.28, 0.2))
	var crown := _mat(Color(0.3, 0.45, 0.24), 0.9)
	_box(Vector3(1.0, 0.6, 1.0), pos + Vector3(0, 0.3, 0), planter)
	_box(Vector3(0.16, 1.5, 0.16), pos + Vector3(0, 1.35, 0), trunk)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.95
	sm.height = 1.7
	mi.mesh = sm
	mi.material_override = crown
	mi.position = pos + Vector3(0, 2.8, 0)
	add_child(mi)
