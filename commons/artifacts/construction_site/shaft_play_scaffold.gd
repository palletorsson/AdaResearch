# shaft_play_scaffold.gd
# A light scaffold round a shaft, for a work that stands over the opening: a ramp up, a deck to look down from, a
# slide down.
#
# @identity
# essence: eleven blue standards and pink ledgers round a 6 x 6 m opening. Two bearers cross the opening under
#   whatever is carried over it. On one side a deck of pink and blue quads hangs 0.9 m out over the opening at 2 m:
#   a plank ramp goes up to one end, a slide comes down from the other.
# desire: to give a work that lies flat over a shaft the one view it lacks - from above - and to make getting that
#   view a small circuit a body enjoys: up the ramp, along the deck, down the slide.
# critical_parameter: deck_height - 2.0 m puts a standing eye 3.6 m over the opening and leaves 1.9 m to walk under.
# triggers: none. It is ground: a ramp is walked, a slide is slid.
# emerges: from the deck three things are seen at once: the work over the opening as a map, the floor it stands on,
#   and through the gap beside the work the floor below.
# needs: a shaft [the Void has two a floor]; 4.5 m of slab beside it for the ramp [has on the north side of B].
# relationships: the frame of [[pipe_dream]]'s playground (blue uprights, pink rails, a floor quad where four corners
#   exist) built by hand and small. A light cousin of the scaffold playgrounds of floor Trans_Playground, which also
#   stand over the shafts; none of their parts are used.
# truth: A model you can only stand beside is read from the side. A relief is a map: it wants an eye above it.
# lineage: ARCHITECTURE - the viewing gantry over an excavation; scaffolding as the building's first staircase.
#   DESIGN - Aldo van Eyck's climbing frames: a few tubes, and the child's body finishes the design.
# history: 2026-11-12, the Void. Palle: "place pheromone_terrain over shaft B and fit it with a lite playground
#   scaffolding around". The terrain is a relief of visits (height = where the walkers went) that stood on the slab
#   with a console; over the shaft it is a lid 4.8 m wide in a 6 m hole, and this is the frame round it.

extends Node3D

const Stock := preload("res://commons/artifacts/construction_site/stock.gd")

@export var opening := Vector2(6, 6)        ## the shaft this stands round: east-west by north-south, metres
@export var deck_height := 2.0
@export var deck_width := 1.9               ## 1 m of it stands on the slab, the rest hangs over the opening
@export var ramp_run := 3.2                 ## floor taken by the ramp: 32 degrees at 2 m (the walker climbs under 45)
@export var slide_run := 1.6                ## floor taken by the slide: steeper than 45 degrees, so a body slides
@export var bearers := true                 ## two tubes across the opening, under whatever is carried over it
@export var caption := ""                   ## a line on the deck about what lies below; no board when empty
@export var mirrored := false               ## ramp at the east end and slide at the west

var _blue: StandardMaterial3D
var _pink: StandardMaterial3D
var _quad_pink: StandardMaterial3D
var _quad_blue: StandardMaterial3D
var _plank: StandardMaterial3D


func _ready() -> void:
	_read_config()
	_blue = _pipe(Color(0.2, 0.8, 1.0))
	_pink = _pipe(Color(1.0, 0.35, 0.9))
	_quad_pink = _quad(Color(1.0, 0.35, 0.9))
	_quad_blue = _quad(Color(0.2, 0.8, 1.0))
	_plank = Stock.finish("c9a978", .85)
	_build()
	Stock.batch_static(self)


func _read_config() -> void:
	for key in ["deck_height", "deck_width", "ramp_run", "slide_run"]:
		if has_meta("config_" + key): set(key, str(get_meta("config_" + key)).to_float())
	for key in ["bearers", "mirrored"]:
		if has_meta("config_" + key): set(key, str(get_meta("config_" + key)).to_lower() in ["true", "1", "yes"])
	if has_meta("config_caption"):
		caption = str(get_meta("config_caption"))
	if has_meta("config_opening"):
		var parts := str(get_meta("config_opening")).split(",")
		if parts.size() == 2: opening = Vector2(float(parts[0]), float(parts[1]))


func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data:
		set_meta("config_" + str(key), config_data[key])


func _pipe(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = .45
	material.metallic = .15
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = .25
	return material


func _quad(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour.darkened(.08)
	material.roughness = .55
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = .3
	return material


## East-west places are written for the ramp at the west end; `mirrored` swaps the ends.
func _x(x: float) -> float:
	return -x if mirrored else x


## A sloping board whose TOP face runs from `low` to `high` (both on its centre line), `width` across.
## It is carried 0.2 m past `low`, below the floor, so that a foot meets the slope and never an edge.
func _slope(title: String, low: Vector3, high: Vector3, width: float, material: Material, boards: int) -> void:
	var along := (high - low).normalized()
	var start := low - along * .2
	var length := start.distance_to(high)
	var side := Vector3.UP.cross(along).normalized()
	var normal := along.cross(side).normalized()      # up and out of the slope; side x normal = along, a right hand
	var frame := Basis(side, normal, along)
	var middle := (start + high) / 2.0 - normal * .025
	var body := StaticBody3D.new()
	body.name = title
	body.transform = Transform3D(frame, middle)
	add_child(body)
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, .05, length)
	collider.shape = box
	body.add_child(collider)
	for k in boards:
		var board := BoxMesh.new()
		board.size = Vector3(width / boards - .012, .05, length)
		var mesh := MeshInstance3D.new()
		mesh.name = "Board"
		mesh.mesh = board
		mesh.material_override = material
		mesh.position = Vector3((k + .5) * width / boards - width / 2.0, 0, 0)
		body.add_child(mesh)


func _build() -> void:
	var hx := opening.x / 2.0 + .25
	var hz := opening.y / 2.0 + .25
	var top := deck_height + 1.0
	var zo := -hz - 1.0                      # the deck's edge on the slab
	var zi := zo + deck_width                # its edge over the opening
	# standards: two rows carry the deck, two corners close the ring
	for x in [-hx, -hx + 1.0, 0.0, hx]:
		Stock.tube(self, "Standard", Vector3(_x(x), 0, zo), Vector3(_x(x), top, zo), .035, _blue)
	for x in [-hx, 0.0, hx]:
		Stock.tube(self, "Standard", Vector3(_x(x), 0, -hz), Vector3(_x(x), top, -hz), .035, _blue)
		Stock.tube(self, "RailPost", Vector3(_x(x), deck_height, zi), Vector3(_x(x), top, zi), .03, _blue, false)
		# the deck hangs out over the opening: a brace from each rim standard to its tip
		Stock.tube(self, "Brace", Vector3(_x(x), deck_height - 1.1, -hz), Vector3(_x(x), deck_height - .09, zi), .025, _blue, false)
		Stock.tube(self, "Transom", Vector3(_x(x), deck_height - .09, zo), Vector3(_x(x), deck_height - .09, zi), .03, _pink, false)
	for x in [-hx, hx]:
		Stock.tube(self, "Standard", Vector3(x, 0, hz), Vector3(x, top, hz), .035, _blue)
	for z in [zo, -hz]:
		Stock.tube(self, "Ledger", Vector3(-hx, deck_height - .09, z), Vector3(hx, deck_height - .09, z), .03, _pink, false)
	# the ring at the top: three sides are ledgers, the fourth is the deck's rails
	Stock.tube(self, "TopLedger", Vector3(-hx, top, hz), Vector3(hx, top, hz), .03, _pink, false)
	for x in [-hx, hx]:
		Stock.tube(self, "TopLedger", Vector3(x, top, -hz), Vector3(x, top, hz), .03, _pink, false)
	Stock.tube(self, "Diagonal", Vector3(-hx, .1, hz), Vector3(-hx, top, -hz), .022, _blue, false)
	Stock.tube(self, "Diagonal", Vector3(hx, .1, hz), Vector3(-hx, top, hz), .022, _blue, false)
	if bearers:
		for z in [-1.3, 1.3]:
			Stock.tube(self, "Bearer", Vector3(-hx, -.05, z), Vector3(hx, -.05, z), .04, _pink, false)
	# the deck: quads between the frame's points, pink and blue
	var deck := StaticBody3D.new()
	deck.name = "Deck"
	deck.position = Vector3(0, deck_height - .03, (zo + zi) / 2.0)
	add_child(deck)
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(hx * 2.0, .06, deck_width)
	collider.shape = box
	deck.add_child(collider)
	var across := 6
	for i in across:
		for j in 2:
			var quad := BoxMesh.new()
			quad.size = Vector3(hx * 2.0 / across - .03, .05, deck_width / 2.0 - .03)
			var mesh := MeshInstance3D.new()
			mesh.name = "Quad"
			mesh.mesh = quad
			mesh.material_override = _quad_pink if (i + j) % 2 == 0 else _quad_blue
			mesh.position = Vector3((i + .5) * hx * 2.0 / across - hx, 0, (j + .5) * deck_width / 2.0 - deck_width / 2.0)
			deck.add_child(mesh)
	# rails keep a body on the deck; the gates are where the ramp arrives and the slide leaves
	Stock.tube(self, "Rail", Vector3(_x(-hx + 1.0), top, zo), Vector3(_x(hx), top, zo), .025, _pink)
	Stock.tube(self, "Rail", Vector3(-hx, top, zi), Vector3(hx, top, zi), .025, _pink)
	Stock.tube(self, "Rail", Vector3(_x(-hx), top, zo), Vector3(_x(-hx), top, zi), .025, _pink)
	Stock.tube(self, "Rail", Vector3(_x(hx), top, zo + 1.0), Vector3(_x(hx), top, zi), .025, _pink)
	Stock.tube(self, "Rail", Vector3(_x(hx), top - .5, zo + 1.0), Vector3(_x(hx), top - .5, zi), .02, _pink, false)
	Stock.tube(self, "Rail", Vector3(-hx, top - .5, zi), Vector3(hx, top - .5, zi), .02, _pink, false)
	# the ramp: planks, from the floor north of the deck up to its end
	var ramp_x := _x(-hx + .5)
	var low := Vector3(ramp_x, 0, zo - ramp_run)
	var high := Vector3(ramp_x, deck_height, zo)
	_slope("Ramp", low, high, 1.0, _plank, 4)
	for dx in [-.5, .5]:
		Stock.tube(self, "RampPost", Vector3(ramp_x + dx, 0, low.z), Vector3(ramp_x + dx, 1.0, low.z), .03, _blue, false)
		Stock.tube(self, "RampRail", Vector3(ramp_x + dx, 1.0, low.z), Vector3(ramp_x + dx, top, zo), .025, _pink)
	# the slide: steeper than a body can stand on, from the deck's other end down to the floor beside the shaft
	var slide_z := zo + .5
	var from := Vector3(_x(hx), deck_height, slide_z)
	var to := Vector3(_x(hx + slide_run), 0, slide_z)
	_slope("Slide", to, from, 1.0, _quad_pink, 1)
	for dz in [-.5, .5]:
		Stock.tube(self, "SlideLip", Vector3(to.x, .22, slide_z + dz), Vector3(from.x, deck_height + .22, slide_z + dz), .03, _blue, false)
	if caption != "":
		# the line lies on the deck inside the rail, where the eye already is: a board on the rail hid what it named
		var board := Stock.box(self, "CaptionBoard", Vector3(0, deck_height + .012, zi - .2), Vector3(3.0, .02, .2), Stock.finish("d9cfbd", .9), false)
		var label := Label3D.new()
		label.text = caption
		label.font_size = 48
		label.pixel_size = .0011
		label.outline_size = 0
		label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		label.modulate = Color("202329")
		label.rotation_degrees = Vector3(-90, 180, 0)      # face up, read by a body that faces the opening
		label.position = Vector3(0, .012, 0)
		board.add_child(label)


## For probes: where the ramp starts, where the deck is walked, where the slide ends (the work's own metres).
func circuit() -> Dictionary:
	var hx := opening.x / 2.0 + .25
	var hz := opening.y / 2.0 + .25
	var zo := -hz - 1.0
	return {"ramp_foot": Vector3(_x(-hx + .5), 0, zo - ramp_run - .8), "ramp_top": Vector3(_x(-hx + .5), deck_height, zo + .5),
		"deck_end": Vector3(_x(hx - .5), deck_height, zo + .5), "slide_foot": Vector3(_x(hx + slide_run + .9), 0, zo + .5),
		"deck_look": Vector3(0, deck_height, zo + deck_width - .45)}
