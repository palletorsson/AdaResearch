extends Node3D
class_name ColorMushroomBasket
## Woven basket overflowing with 12 colourful edible mushrooms on a playful banded
## plinth. Eating any mushroom floods the entire world in that mushroom's colour
## via RainbowWorldWash; each eaten mushroom regrows cleanly in its basket spot.

const ColorMushroom := preload("res://commons/artifacts/color_mushroom_basket/color_mushroom.gd")
const PLINTH_HEIGHT := 0.92
const REGROW_SECONDS := 14.0

const THEMES := {
	"rainbow": [
		[Color("e40303"), "Crimson"], [Color("ff8c00"), "Tangerine"], [Color("ffdd00"), "Solar Yellow"],
		[Color("12b84a"), "Emerald"], [Color("00c2ff"), "Sky Cyan"], [Color("2a5cff"), "Cobalt"],
		[Color("9b30ff"), "Royal Violet"], [Color("ff4fa3"), "Hot Pink"],
	],
	"warm": [
		[Color("e40303"), "Crimson"], [Color("ff5e1a"), "Vermilion"], [Color("ff9900"), "Tangerine"],
		[Color("ffd700"), "Gold"], [Color("ff4fa3"), "Hot Pink"], [Color("ff85b3"), "Blush"],
	],
	"cool": [
		[Color("12b84a"), "Emerald"], [Color("00d4b8"), "Turquoise"], [Color("41d5eb"), "Aqua"],
		[Color("2a5cff"), "Cobalt"], [Color("7c3caf"), "Violet"], [Color("d26bff"), "Orchid"],
	],
}

const BAND_PALETTES := {
	"rainbow": [Color("e40303"), Color("ff8c00"), Color("ffed00"), Color("008026"), Color("004dff"), Color("750787")],
	"warm": [Color("ffc857"), Color("ffffff"), Color("a76ed5"), Color("282032")],
	"cool": [Color("5bcefa"), Color("f5a9b8"), Color("ffffff"), Color("f5a9b8"), Color("5bcefa")],
}

@export_enum("rainbow", "warm", "cool") var theme: String = "rainbow"
var spots: Array[Vector3] = []
var grown: Dictionary = {}
var _entries: Array = []

func _ready() -> void:
	name = "ColorMushroomBasket"
	var authored := str(get_meta("config_theme", theme)).strip_edges().to_lower()
	if THEMES.has(authored):
		theme = authored
	_entries = THEMES[theme]
	_build_plinth_and_basket()
	_populate_mushrooms()

func _build_plinth_and_basket() -> void:
	var bands: Array = BAND_PALETTES.get(theme, BAND_PALETTES["rainbow"])
	var band_h := PLINTH_HEIGHT / float(bands.size())
	for i in range(bands.size()):
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.28 + (0.04 if i == 0 else 0.0)
		cyl.bottom_radius = 0.30 + (0.04 if i == 0 else 0.0)
		cyl.height = band_h
		cyl.radial_segments = 24
		_mesh(cyl, Vector3(0, band_h * (float(i) + 0.5), 0), bands[i], 0.35)
	_solid_cyl(Vector3(0, PLINTH_HEIGHT * 0.5, 0), 0.31, PLINTH_HEIGHT)

	# Cap plate under the woven basket
	var plate := CylinderMesh.new()
	plate.top_radius = 0.36
	plate.bottom_radius = 0.34
	plate.height = 0.04
	plate.radial_segments = 24
	_mesh(plate, Vector3(0, PLINTH_HEIGHT + 0.02, 0), Color("f5efe6"), 0.4)

	# Generous woven basket (radius ~0.31 m)
	var top := PLINTH_HEIGHT + 0.04
	var bfloor := CylinderMesh.new()
	bfloor.top_radius = 0.30
	bfloor.bottom_radius = 0.26
	bfloor.height = 0.03
	bfloor.radial_segments = 24
	_mesh(bfloor, Vector3(0, top + 0.015, 0), Color("a0743f"), 0.8)

	for i in range(24):
		var a := TAU * float(i) / 24.0
		var slat := BoxMesh.new()
		slat.size = Vector3(0.068, 0.16, 0.016)
		var m := _mesh(slat, Vector3(cos(a) * 0.30, top + 0.085, sin(a) * 0.30), Color("c49254") if i % 2 == 0 else Color("8f6330"), 0.82)
		m.rotation.y = -a + PI * 0.5
		m.rotation.x = 0.14

	for ring in range(2):
		var hoop := TorusMesh.new()
		hoop.inner_radius = 0.295
		hoop.outer_radius = 0.32
		hoop.rings = 28
		hoop.ring_segments = 10
		_mesh(hoop, Vector3(0, top + 0.045 + 0.085 * float(ring), 0), Color("7a5024"), 0.8)

	# Half-arch woven basket handle above the rim (cleanly anchored at +/-X).
	var segs := 14
	for i in range(segs):
		var a0 := PI * float(i) / float(segs)
		var a1 := PI * float(i + 1) / float(segs)
		var am := (a0 + a1) * 0.5
		var p0 := Vector3(cos(a0) * 0.305, top + 0.14 + sin(a0) * 0.30, 0.0)
		var p1 := Vector3(cos(a1) * 0.305, top + 0.14 + sin(a1) * 0.30, 0.0)
		var seg := CylinderMesh.new()
		seg.top_radius = 0.017
		seg.bottom_radius = 0.017
		seg.height = p0.distance_to(p1) + 0.012
		seg.radial_segments = 10
		var hm := _mesh(seg, (p0 + p1) * 0.5, Color("9a6a35") if i % 2 == 0 else Color("7a5024"), 0.78)
		hm.rotation.z = am

	var sign := Label3D.new()
	sign.text = "COLOUR MUSHROOMS\neat one to colour the world"
	sign.font_size = 38
	sign.pixel_size = 0.0017
	sign.outline_size = 6
	sign.modulate = Color("fffaf2")
	sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sign.position = Vector3(0, top + 0.56, 0)
	add_child(sign)

	# 12 mushroom spots in two lush rings inside the basket
	for i in range(12):
		var r := 0.10 if i < 4 else 0.21
		var count := 4 if i < 4 else 8
		var k := i if i < 4 else i - 4
		var a := TAU * float(k) / float(count) + (0.4 if i < 4 else 0.0)
		spots.append(Vector3(cos(a) * r, top + 0.04, sin(a) * r))

func _populate_mushrooms() -> void:
	for i in range(spots.size()):
		var pair: Array = _entries[i % _entries.size()]
		_grow(i, pair[0], str(pair[1]))

func _grow(spot: int, colour: Color, cname: String) -> void:
	var m := ColorMushroom.new()
	m.cap_colour = colour
	m.colour_name = cname
	m.basket = self
	m.spot = spot
	m.floor_y = global_position.y
	m.position = spots[spot]
	m.rotation.y = float(spot) * 1.4
	add_child(m)
	grown[spot] = m

func regrow(spot: int, colour: Color, cname: String) -> void:
	grown.erase(spot)
	await get_tree().create_timer(REGROW_SECONDS).timeout
	if is_inside_tree() and not grown.has(spot):
		_grow(spot, colour, cname)

func _process(_delta: float) -> void:
	for spot in grown.keys():
		var m: Variant = grown[spot]
		if not is_instance_valid(m):
			grown.erase(spot)
			continue
		if (m as Node3D).position.distance_to(spots[spot]) > 0.55 and not (m as XRToolsPickable).is_picked_up():
			var c: Color = m.cap_colour
			var n: String = m.colour_name
			grown.erase(spot)
			regrow(spot, c, n)

func _mesh(mesh: Mesh, at: Vector3, colour: Color, roughness: float) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = roughness
	part.material_override = mat
	add_child(part)
	return part

func _solid_cyl(at: Vector3, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	body.position = at
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	col.shape = cyl
	body.add_child(col)
	add_child(body)

func apply_grid_config(config: Dictionary) -> void:
	if config.has("theme"):
		set_meta("config_theme", config.theme)
