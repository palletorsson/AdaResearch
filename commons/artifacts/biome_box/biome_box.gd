extends Node3D
## THE BIOME BOX (the growth floors of the Void; Palle, 2026-11-12: "now that we are getting into growth territory we
## should also think of how we can integrate the biome, maybe in a transparent grid box that we use in the beginning
## animated cube")
##
## The animated-cube floor keeps a grid inside a room fitted to shaft B. This is that container made of glass, with
## the grid drawn on it, and inside it the biome: `biome_object`, ONE ground from one seed, the same on every floor
## the box stands on. What differs from floor to floor is the STAGE: the biome may only be made of what the tower's
## halls have taught down to that floor (commons/data/biome_vocabulary.json, read by BiomeGrammar), and `phase` says
## how far the things that ARRIVE with this floor's sequence have come. So a run of boxes down one shaft is one
## world growing as the visitor descends: on the L-system floors the tree and the creature arrive.
##
## The box is 6.6 m square: it stands on the rim of a shaft's six-metre opening and closes it. The lines on the
## glass are one metre apart, the size of the biome's cells; the biome is `cells` across, 30 cm in from the glass. A body cannot walk in: the biome has no ground to stand on.
##
## THE SLANTED FORM (Palle, 2026-11-13: "Can we make the biome larger by slanting the side from 6 m up to 12 m from 0
## to 2 in y"). With `flare_height` above 0 the box stands on the same 6.6 m foot on the shaft's rim, its four sides
## lean outward to the biome's own width at that height, and the ground lies on top: `cells: 12, flare_height: 2` is a
## twelve-metre ground carried two metres up on a glass funnel. Upright glass 1.8 m high stands round the ground (its cut edge rises that far at the hills) and
## the top is open, so the trees rise out of it. The metre lines are the cell boundaries of the larger ground, cut
## where each one leaves a slanted side. The straight box is the default and is unchanged.
##
## THE WAY IN (2026-11-13). The biome's ground carries a body (its one collider is the ground itself), so with
## `gate_side` the slanted form can be walked: two metres of the upright glass are left out on that side, and once the
## ground is built a short lip and a board run from a deck standing outside at `gate_height` down onto the ground, the
## board's far end under the surface so a foot never meets an edge. The deck has to stand above the ground's cut edge
## at the gate (seed 7 at twelve cells: 2.73-2.84 m over the floor along the middle of the west side). With a gate the
## solid behind the glass reaches in to the ground's own edge - on the south side there is a trench 57 cm wide between
## ground and glass, wide enough to fall into - and up to just under the slab above, because the ground's highest hill
## stands 7 cm under the glass's top. Trees, crystals, water and creatures have no solid: a body walks through them.
##
## THE WINDOW ("...and open the shaft above the biome to 12"). With `window` the artifact is only a clear glass floor
## set flush in a shaft's six-metre opening, with the metre lines on it: a body walks out on it and looks down at the
## biome of the floor below. From an eye 1.6 m over the middle of a six-metre opening, a ground 3.6 m below the slab
## is in view out to 7.9 m from the middle, so a twelve-metre ground is seen whole without cutting the slab. The
## floor under a body is paused by the tower (its sensors are out of physics), so the box below cannot notice a body
## up here: the window, which is awake, asks every box (group `biome_boxes`) and the one straight under it builds.
##
## `stage`: full = everything (the default, and what a box on a bench shows), hall = the sequence of the floor the
## box stands on, read from the floor's map (what a row in the tower asks for), or a sequence named outright. The biome's builders take about a second (the mycelium most of it), so with
## `builds: arrival` the box stays an empty grid until a body arrives on its floor; `always` builds at once.
const Biome := preload("res://commons/artifacts/biome_object/biome_object.tscn")
const Grammar := preload("res://commons/biome_layers/biome_grammar.gd")
const MARGIN := 0.3                   # glass to the biome's edge
const SET_IN := Vector3(0.05, 0.0, -0.27)   # before `full` a body lies half a metre over the biome's south edge: the ground stands that much north
const LIFT := 0.44                     # the biome's cut section reaches this far under its surface
const LINE := Color("f5a9b8")
const SHAFT := 6.0                    # a shaft's opening: the foot of both forms stands on its rim
const GATE := 2.0                     # the opening a gate leaves in the upright glass: a kit deck's width
const CLEAR := 5.6                    # with a gate a body is inside: the solid round the ground stands to just under the slab above
const BAND := 1.8                     # in the slanted form, the upright glass round the ground: seed 7 at twelve cells has a hill on its edge 1.29 m over the ground's level, 1.73 m over the rim

@export_enum("hall", "full", "randomness", "lsystems") var stage := "full"      ## a config may name any sequence the biome vocabulary knows
@export_range(0.0, 1.0) var phase := 1.0          ## how far what arrives at this stage has come
@export var world_seed := 7                       ## the one ground: the same number on every floor
@export_range(4, 12) var cells := 6               ## the biome's cells across, a metre each (seed 7 has no tree below six); above six needs the slanted form
@export_range(0.0, 3.0) var flare_height := 0.0   ## above 0: the sides lean outward from the shaft's rim to the biome's width at this height, the ground on top
@export var sign_side := "south"                  ## south | west: the side the low sign stands on
@export var sign_at := 0.0                        ## where along that side, metres from its middle (a gate deck may stand in the middle)
@export var tall := 3.6
@export_enum("arrival", "always") var builds := "arrival"
@export var gate_side := ""                       ## south | north | east | west: a way in on that side of the slanted form (empty = none)
@export var gate_at := 0.0                        ## where along that side the gate stands, metres from its middle
@export_range(0.0, 5.0) var gate_height := 3.0    ## the level of the deck outside the gate, over the floor: above the ground's cut edge there
@export var window := false                       ## true: only a clear glass floor in the shaft's opening, to stand on and look down from; no biome of its own

var _biome: Node3D
var _stage_now := ""
var _sign: Label3D
var _seed_mark: MeshInstance3D
var _build_ms := -1
var _built_config := []
var _ask_until := 0
var _way_in: StaticBody3D
var _way_reach := 0.0
var _way_clears := false
var _answered := false


func _ready() -> void:
	var given := {}
	for key in ["stage", "phase", "world_seed", "cells", "tall", "builds", "flare_height", "sign_side", "sign_at", "window", "gate_side", "gate_at", "gate_height"]:
		if has_meta("config_" + key): given[key] = get_meta("config_" + key)
	_take(given)
	if window:
		_window()
		_write()
		_watch()
		return
	add_to_group("biome_boxes")
	if flare_height > 0.0: _hopper()
	else: _box()
	_stage_now = _resolve()
	_write()
	if builds == "always": grow.call_deferred()
	else: _watch()


func _take(config_data: Dictionary) -> void:
	if config_data.has("stage"): stage = str(config_data["stage"]).strip_edges()
	if config_data.has("phase"): phase = clampf(float(str(config_data["phase"])), 0.0, 1.0)
	if config_data.has("world_seed"): world_seed = int(float(str(config_data["world_seed"])))
	if config_data.has("flare_height"): flare_height = clampf(float(str(config_data["flare_height"])), 0.0, 3.0)
	if config_data.has("cells"): cells = clampi(int(float(str(config_data["cells"]))), 4, 12)
	if flare_height <= 0.0: cells = mini(cells, 6)      # the straight box stands on a six-metre opening
	if config_data.has("sign_side") and str(config_data["sign_side"]) in ["south", "west"]: sign_side = str(config_data["sign_side"])
	if config_data.has("tall"): tall = clampf(float(str(config_data["tall"])), 2.0, 5.4)
	if config_data.has("builds") and str(config_data["builds"]) in ["arrival", "always"]: builds = str(config_data["builds"])
	if config_data.has("window"): window = str(config_data["window"]).to_lower() in ["true", "1", "1.0"]
	if config_data.has("gate_side") and str(config_data["gate_side"]) in ["", "south", "north", "east", "west"]: gate_side = str(config_data["gate_side"])
	if config_data.has("gate_at"): gate_at = float(str(config_data["gate_at"]))
	if config_data.has("sign_at"): sign_at = float(str(config_data["sign_at"]))
	if config_data.has("gate_height"): gate_height = clampf(float(str(config_data["gate_height"])), 0.0, 5.0)


func apply_grid_config(config_data: Dictionary) -> void:
	_take(config_data)
	if not is_inside_tree() or _sign == null: return
	if window:
		_write()
		return
	_stage_now = _resolve()
	_write()
	if _biome != null and _built_config != [_stage_now, phase, world_seed, cells]:
		remove_child(_biome)
		_biome.queue_free()
		_biome = null
		grow()
	elif _biome == null and builds == "always": grow()


## The stage the biome is built at: named outright, or the sequence of the floor this box stands on.
func _resolve() -> String:
	if stage != "hall": return stage
	var at: Node = get_parent()
	while at != null and not at.has_meta("em_map"): at = at.get_parent()
	if at == null: return "full"
	var place: Dictionary = Grammar.position_of(str(at.get_meta("em_map")))
	if bool(place.get("known", false)): return str(place["sequence"])
	# a tower floor is named after its hall: the sequence is the part before the first underscore, as the vocabulary spells it
	var head: String = str(at.get_meta("em_map")).get_slice("_", 0).to_lower()
	var names := {"lsystems": "lsystems", "pg": "proceduralgeneration", "ca": "cellularautomata", "fractal": "fractals", "noise": "noise", "random": "randomness", "randomness": "randomness",
		"softbodies": "softbodies", "isosurfaces": "isosurfaces", "swarm": "swarmintelligence", "ml": "machinelearning", "graph": "graphtheory"}
	if names.has(head) and bool(Grammar.position_of(str(names[head])).get("known", false)): return str(names[head])
	return "full"


## What arrives with a sequence: its own words in the vocabulary.
func arriving() -> PackedStringArray:
	var out := PackedStringArray()
	var file := FileAccess.get_file_as_string(Grammar.VOCAB_PATH)
	var vocabulary: Variant = JSON.parse_string(file)
	if not vocabulary is Dictionary: return out
	var entry: Dictionary = ((vocabulary as Dictionary).get("sequences", {}) as Dictionary).get(_stage_now, {})
	for column in ["made_of", "does", "knows"]:
		for word in entry.get(column, []): out.append(str(word))
	return out


## ---- the box ----

func _box() -> void:
	var wide: float = float(cells) + MARGIN * 2.0
	var half := wide * 0.5
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.8, 0.92, 0.94, 0.07)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	glass.roughness = 0.18
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var floor_glass := StandardMaterial3D.new()
	floor_glass.albedo_color = Color(0.16, 0.18, 0.22, 0.55)
	floor_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	floor_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var body := StaticBody3D.new()
	body.name = "Glass"
	add_child(body)
	var panes := [
		[Vector3(0, tall * 0.5, half), Vector3(wide, tall, 0.02), glass], [Vector3(0, tall * 0.5, -half), Vector3(wide, tall, 0.02), glass],
		[Vector3(half, tall * 0.5, 0), Vector3(0.02, tall, wide), glass], [Vector3(-half, tall * 0.5, 0), Vector3(0.02, tall, wide), glass],
		[Vector3(0, tall, 0), Vector3(wide, 0.02, wide), glass], [Vector3(0, -0.05, 0), Vector3(wide, 0.1, wide), floor_glass]]
	for pane in panes:
		var shown := MeshInstance3D.new()
		var sheet := BoxMesh.new()
		sheet.size = pane[1]
		shown.mesh = sheet
		shown.material_override = pane[2]
		shown.position = pane[0]
		shown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(shown)
		var shape := CollisionShape3D.new()
		var solid := BoxShape3D.new()
		solid.size = (pane[1] as Vector3).max(Vector3(0.08, 0.08, 0.08))
		shape.shape = solid
		shape.position = pane[0]
		body.add_child(shape)
	# the grid: the biome's cell lines carried out to the glass, one metre apart
	var lines: Array[Transform3D] = []
	var levels: Array[float] = []
	var up := 1.0
	while up < tall - 0.2:
		levels.append(up)
		up += 1.0
	for i in cells + 1:
		var mx: float = -float(cells) * 0.5 + float(i) + SET_IN.x      # a line the biome's cells share, east-west and north-south
		var mz: float = -float(cells) * 0.5 + float(i) + SET_IN.z
		for y in [0.004, tall - 0.012]:
			lines.append(Transform3D(Basis().scaled(Vector3(wide, 0.008, 0.008)), Vector3(0, y, mz)))
			lines.append(Transform3D(Basis().scaled(Vector3(0.008, 0.008, wide)), Vector3(mx, y, 0)))
		for edge in [-half, half]:
			lines.append(Transform3D(Basis().scaled(Vector3(0.008, tall, 0.008)), Vector3(mx, tall * 0.5, edge)))
			lines.append(Transform3D(Basis().scaled(Vector3(0.008, tall, 0.008)), Vector3(edge, tall * 0.5, mz)))
	for y in levels:
		for edge in [-half, half]:
			lines.append(Transform3D(Basis().scaled(Vector3(wide, 0.008, 0.008)), Vector3(0, y, edge)))
			lines.append(Transform3D(Basis().scaled(Vector3(0.008, 0.008, wide)), Vector3(edge, y, 0)))
	_draw(lines)
	var pale := StandardMaterial3D.new()
	pale.albedo_color = Color("c4cccc")
	pale.roughness = 0.5
	for x in [-half, half]:
		for z in [-half, half]:
			_bar(Vector3(x, tall * 0.5, z), Vector3(0.06, tall, 0.06), pale)
	for y in [0.0, tall]:
		for edge in [-half, half]:
			_bar(Vector3(0, y, edge), Vector3(wide, 0.045, 0.045), pale)
			_bar(Vector3(edge, y, 0), Vector3(0.045, 0.045, wide), pale)
	_seed()
	_stand_sign(half + 0.55)


func _draw(lines: Array[Transform3D]) -> void:
	var thin := MultiMesh.new()
	thin.transform_format = MultiMesh.TRANSFORM_3D
	var unit := BoxMesh.new()
	unit.size = Vector3(1, 1, 1)
	thin.mesh = unit
	thin.instance_count = lines.size()
	for i in lines.size(): thin.set_instance_transform(i, lines[i])
	var ink := StandardMaterial3D.new()
	ink.albedo_color = LINE
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var grid := MultiMeshInstance3D.new()
	grid.name = "Grid"
	grid.multimesh = thin
	grid.material_override = ink
	grid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grid)


## The seed: where the biome begins, shown while the box is still empty.
func _seed() -> void:
	_seed_mark = MeshInstance3D.new()
	_seed_mark.name = "Seed"
	var ball := SphereMesh.new()
	ball.radius = 0.15
	ball.height = 0.3
	_seed_mark.mesh = ball
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color(0.93, 0.93, 0.95)
	_seed_mark.material_override = lit
	_seed_mark.position = Vector3(0, 0.8, 0)
	add_child(_seed_mark)


## The sign: low, `out` metres from the middle, outside the glass on the side asked for.
func _stand_sign(out: float) -> void:
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	var stand := Node3D.new()
	stand.name = "Sign"
	stand.position = Vector3(sign_at, 0, out)
	if sign_side == "west":
		stand.position = Vector3(-out, 0, sign_at)
		stand.rotation.y = -PI * 0.5
	add_child(stand)
	var panel := MeshInstance3D.new()
	var face := BoxMesh.new()
	face.size = Vector3(3.0, 0.9, 0.05)
	panel.mesh = face
	panel.material_override = dark
	panel.position = Vector3(0, 0.62, 0)
	panel.rotation.x = -0.5
	stand.add_child(panel)
	_sign = Label3D.new()
	_sign.pixel_size = 0.0021
	_sign.font_size = 30
	_sign.line_spacing = 2.0
	_sign.modulate = Color(0.88, 0.94, 1.0)
	_sign.outline_size = 4
	_sign.outline_modulate = Color(0, 0, 0, 1)
	_sign.width = 1340
	_sign.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sign.position = Vector3(0, 0.035, 0.03)
	panel.add_child(_sign)


## ---- the slanted form ----

## A thin bar from a to b, as a transform of the unit box.
func _between(a: Vector3, b: Vector3, thick: float = 0.008) -> Transform3D:
	var along: Vector3 = b - a
	var up: Vector3 = along.normalized()
	var side: Vector3 = up.cross(Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.BACK).normalized()
	return Transform3D(Basis(side * thick, up * along.length(), side.cross(up) * thick), (a + b) * 0.5)


func _strut(a: Vector3, b: Vector3, thick: float, material: Material) -> void:
	var shown := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1, 1, 1)
	shown.mesh = mesh
	shown.material_override = material
	shown.transform = _between(a, b, thick)
	add_child(shown)


func _pane(body: StaticBody3D, at: Vector3, size: Vector3, material: Material) -> void:
	var shown := MeshInstance3D.new()
	var sheet := BoxMesh.new()
	sheet.size = size
	shown.mesh = sheet
	shown.material_override = material
	shown.position = at
	shown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(shown)
	var shape := CollisionShape3D.new()
	var solid := BoxShape3D.new()
	solid.size = size.max(Vector3(0.08, 0.08, 0.08))
	shape.shape = solid
	shape.position = at
	body.add_child(shape)


## Only a floor of clear glass, flush in the shaft's opening, and the metre lines on it.
func _window() -> void:
	var half: float = SHAFT * 0.5 - 0.01
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.8, 0.92, 0.94, 0.09)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	glass.roughness = 0.12
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var body := StaticBody3D.new()
	body.name = "Glass"
	add_child(body)
	_pane(body, Vector3(0, -0.04, 0), Vector3(half * 2.0, 0.08, half * 2.0), glass)
	var lines: Array[Transform3D] = []
	for i in int(SHAFT) + 1:
		var mx: float = clampf(-SHAFT * 0.5 + float(i) + SET_IN.x, -half, half)      # the cell lines of the ground below, straight over them
		var mz: float = clampf(-SHAFT * 0.5 + float(i) + SET_IN.z, -half, half)
		lines.append(Transform3D(Basis().scaled(Vector3(half * 2.0, 0.008, 0.008)), Vector3(0, 0.004, mz)))
		lines.append(Transform3D(Basis().scaled(Vector3(0.008, 0.008, half * 2.0)), Vector3(mx, 0.004, 0)))
	_draw(lines)
	var pale := StandardMaterial3D.new()
	pale.albedo_color = Color("c4cccc")
	pale.roughness = 0.5
	for side in [-1.0, 1.0]:
		_strut(Vector3(-half, -0.03, side * half), Vector3(half, -0.03, side * half), 0.045, pale)
		_strut(Vector3(side * half, -0.03, -half), Vector3(side * half, -0.03, half), 0.045, pale)
	_stand_sign(SHAFT * 0.5 + 0.85)


## The four sides of the rim: the way out, the way along, how far inside the glass the ground's own edge stands, and
## the set-in of the cell lines along that side.
func _sides() -> Array:
	var half: float = float(cells) * 0.5
	var high: float = half + MARGIN
	return [
		{"name": "south", "out": Vector3(0, 0, 1), "along": Vector3(1, 0, 0), "kerb": high - (half + SET_IN.z), "shift": SET_IN.x},
		{"name": "north", "out": Vector3(0, 0, -1), "along": Vector3(1, 0, 0), "kerb": high - (half - SET_IN.z), "shift": SET_IN.x},
		{"name": "east", "out": Vector3(1, 0, 0), "along": Vector3(0, 0, 1), "kerb": high - (half + SET_IN.x), "shift": SET_IN.z},
		{"name": "west", "out": Vector3(-1, 0, 0), "along": Vector3(0, 0, 1), "kerb": high - (half - SET_IN.x), "shift": SET_IN.z}]


## The stretches of one side that carry glass: all of it, or what the gate leaves.
func _stretches(side: Dictionary, high: float) -> Array:
	if gate_side != str(side["name"]): return [[-high, high]]
	return [[-high, gate_at - GATE * 0.5], [gate_at + GATE * 0.5, high]]


## The upright glass round the raised ground, side by side. Without a gate the solid is the glass. With a gate a body
## is inside: the solid reaches in over the ground's own edge and up to just under the slab above.
func _band(body: StaticBody3D, glass: Material, pale: Material, lines: Array[Transform3D]) -> void:
	var high: float = float(cells) * 0.5 + MARGIN
	var rim: float = flare_height
	var walked: bool = gate_side != ""
	for side in _sides():
		var out: Vector3 = side["out"]
		var along: Vector3 = side["along"]
		var stretches: Array = _stretches(side, high)
		for stretch in stretches:
			var from: float = stretch[0]
			var to: float = stretch[1]
			if to - from < 0.05: continue
			var middle: Vector3 = out * high + along * ((from + to) * 0.5)
			var shown := MeshInstance3D.new()
			var sheet := BoxMesh.new()
			sheet.size = along.abs() * (to - from) + out.abs() * 0.02 + Vector3(0, BAND, 0)
			shown.mesh = sheet
			shown.material_override = glass
			shown.position = middle + Vector3(0, rim + BAND * 0.5, 0)
			shown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			body.add_child(shown)
			var deep: float = float(side["kerb"]) + 0.09 if walked else 0.08      # from 4 cm outside the glass to 5 cm over the ground's edge
			var stands: float = CLEAR - rim if walked else BAND
			var solid := BoxShape3D.new()
			solid.size = along.abs() * (to - from) + out.abs() * deep + Vector3(0, stands, 0)
			var shape := CollisionShape3D.new()
			shape.shape = solid
			shape.position = out * (high + 0.04 - deep * 0.5) + along * ((from + to) * 0.5) + Vector3(0, rim + stands * 0.5, 0)
			body.add_child(shape)
			_strut(out * high + along * from + Vector3(0, rim + BAND, 0), out * high + along * to + Vector3(0, rim + BAND, 0), 0.045, pale)
			var level: float = ceilf(rim + 0.2)
			while level < rim + BAND - 0.2:
				lines.append(_between(out * high + along * from + Vector3(0, level, 0), out * high + along * to + Vector3(0, level, 0)))
				level += 1.0
		for i in cells + 1:
			var at: float = -float(cells) * 0.5 + float(i) + float(side["shift"])
			for stretch in stretches:
				if at >= float(stretch[0]) - 0.01 and at <= float(stretch[1]) + 0.01:
					lines.append(_between(out * high + along * at + Vector3(0, rim, 0), out * high + along * at + Vector3(0, rim + BAND, 0)))
					break


## How high the ground stands over this box's own floor under a point of the box. Where there is no ground: -INF.
func _ground_at(p: Vector3) -> float:
	if _biome == null or not _biome.has_method("_h_at"): return -INF
	var bx: float = p.x - SET_IN.x
	var bz: float = p.z - SET_IN.z
	var half: float = float(cells) * 0.5
	if absf(bx) > half or absf(bz) > half: return -INF
	return flare_height + LIFT + float(_biome.call("_h_at", bx, bz))


## A board whose TOP face runs from a to b, with its solid.
func _board(body: StaticBody3D, a: Vector3, b: Vector3, material: Material) -> void:
	var x: Vector3 = (b - a).normalized()
	var z: Vector3 = x.cross(Vector3.UP).normalized()
	var y: Vector3 = z.cross(x)
	var size := Vector3((b - a).length(), 0.05, GATE - 0.4)
	var at := Transform3D(Basis(x, y, z), (a + b) * 0.5 - y * 0.025)
	var shown := MeshInstance3D.new()
	var plank := BoxMesh.new()
	plank.size = size
	shown.mesh = plank
	shown.material_override = material
	shown.transform = at
	body.add_child(shown)
	var solid := BoxShape3D.new()
	solid.size = size
	var shape := CollisionShape3D.new()
	shape.shape = solid
	shape.transform = at
	body.add_child(shape)


## The way in, laid once the ground exists: a lip that rises over the deck's edge rod, then a board falling one in
## three from the glass line until it lies a quarter metre under the ground.
func _lay_way_in() -> void:
	if _way_in != null:
		remove_child(_way_in)
		_way_in.queue_free()
		_way_in = null
	_way_reach = 0.0
	_way_clears = false
	if gate_side == "" or flare_height <= 0.0 or _biome == null: return
	var side := {}
	for s in _sides():
		if str(s["name"]) == gate_side: side = s
	if side.is_empty(): return
	var high: float = float(cells) * 0.5 + MARGIN
	var out: Vector3 = side["out"]
	var foot: Vector3 = out * high + (side["along"] as Vector3) * gate_at      # on the glass line, under the gate's middle
	var crest: float = gate_height + 0.06
	var reach := 0.3
	var last := crest
	while reach < 4.0:
		last = crest - reach / 3.0
		if last <= _ground_at(foot - out * reach) - 0.25: break
		reach += 0.1
	_way_reach = reach
	var edge: float = float(side["kerb"]) + 0.03      # just inside the ground's cut edge
	_way_clears = crest - edge / 3.0 >= _ground_at(foot - out * edge)
	if not _way_clears: push_warning("biome_box: the gate's deck stands under the ground's cut edge (%s m): the board runs into it" % str(snappedf(_ground_at(foot - out * edge), 0.01)))
	_way_in = StaticBody3D.new()
	_way_in.name = "WayIn"
	add_child(_way_in)
	var timber := StandardMaterial3D.new()
	timber.albedo_color = Color("c9a978")
	timber.roughness = 0.8
	_board(_way_in, foot + out * 0.45 + Vector3(0, gate_height - 0.04, 0), foot + Vector3(0, crest, 0), timber)
	_board(_way_in, foot + Vector3(0, crest, 0), foot - out * reach + Vector3(0, last, 0), timber)


func _hopper() -> void:
	var low: float = SHAFT * 0.5 + MARGIN              # half the foot: the straight box's own 6.6 m
	var high: float = float(cells) * 0.5 + MARGIN       # half the rim
	var rim: float = flare_height
	var lean: float = maxf((high - low) / rim, 0.001)   # metres outward for a metre up
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.8, 0.92, 0.94, 0.07)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	glass.roughness = 0.18
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var floor_glass := StandardMaterial3D.new()
	floor_glass.albedo_color = Color(0.16, 0.18, 0.22, 0.55)
	floor_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	floor_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var body := StaticBody3D.new()
	body.name = "Glass"
	add_child(body)
	# the foot closes the shaft; the tray carries the ground; a metre of upright glass stands round it; the top is open
	_pane(body, Vector3(0, -0.05, 0), Vector3(low * 2.0, 0.1, low * 2.0), floor_glass)
	_pane(body, Vector3(0, rim - 0.02, 0), Vector3(high * 2.0, 0.04, high * 2.0), floor_glass)
	var lines: Array[Transform3D] = []
	var pale := StandardMaterial3D.new()
	pale.albedo_color = Color("c4cccc")
	pale.roughness = 0.5
	_band(body, glass, pale, lines)
	# the four slanted sides: one sheet each, and a thin solid behind it
	for turn in 4:
		var spin := Basis(Vector3.UP, PI * 0.5 * float(turn))
		var corners: Array[Vector3] = [spin * Vector3(-low, 0, low), spin * Vector3(low, 0, low), spin * Vector3(high, rim, high), spin * Vector3(-high, rim, high)]
		var outward: Vector3 = (spin * Vector3(0, -lean, 1.0)).normalized()
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for ix in [0, 2, 1, 0, 3, 2]:
			st.set_normal(outward)
			st.add_vertex(corners[ix])
		var shown := MeshInstance3D.new()
		shown.mesh = st.commit()
		shown.material_override = glass
		shown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(shown)
		var points := PackedVector3Array()
		for c in corners:
			points.append(c)
			points.append(c - outward * 0.08)
		var solid := ConvexPolygonShape3D.new()
		solid.points = points
		var shape := CollisionShape3D.new()
		shape.shape = solid
		body.add_child(shape)
	# the grid: the cell lines of the ground above, a metre apart, cut where each leaves a slanted side
	for i in cells + 1:
		var mx: float = -float(cells) * 0.5 + float(i) + SET_IN.x
		var mz: float = -float(cells) * 0.5 + float(i) + SET_IN.z
		lines.append(Transform3D(Basis().scaled(Vector3(high * 2.0, 0.008, 0.008)), Vector3(0, rim - 0.046, mz)))      # under the tray
		lines.append(Transform3D(Basis().scaled(Vector3(0.008, 0.008, high * 2.0)), Vector3(mx, rim - 0.046, 0)))
		if absf(mz) <= low: lines.append(Transform3D(Basis().scaled(Vector3(low * 2.0, 0.008, 0.008)), Vector3(0, 0.004, mz)))      # on the foot
		if absf(mx) <= low: lines.append(Transform3D(Basis().scaled(Vector3(0.008, 0.008, low * 2.0)), Vector3(mx, 0.004, 0)))
		var from_x: float = clampf((absf(mx) - low) / lean, 0.0, rim)
		var from_z: float = clampf((absf(mz) - low) / lean, 0.0, rim)
		for side in [-1.0, 1.0]:
			if from_x < rim - 0.01: lines.append(_between(Vector3(mx, from_x, side * (low + lean * from_x)), Vector3(mx, rim, side * high)))
			if from_z < rim - 0.01: lines.append(_between(Vector3(side * (low + lean * from_z), from_z, mz), Vector3(side * high, rim, mz)))
	var up := 1.0
	while up < rim - 0.2:
		var reach: float = low + lean * up
		for side in [-1.0, 1.0]:
			lines.append(Transform3D(Basis().scaled(Vector3(reach * 2.0, 0.008, 0.008)), Vector3(0, up, side * reach)))
			lines.append(Transform3D(Basis().scaled(Vector3(0.008, 0.008, reach * 2.0)), Vector3(side * reach, up, 0)))
		up += 1.0
	_draw(lines)
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			_strut(Vector3(x * low, 0, z * low), Vector3(x * high, rim, z * high), 0.06, pale)
			_strut(Vector3(x * high, rim, z * high), Vector3(x * high, rim + BAND, z * high), 0.06, pale)
	for level in [[0.0, low], [rim, high]]:
		var y: float = level[0]
		var reach: float = level[1]
		for side in [-1.0, 1.0]:
			_strut(Vector3(-reach, y, side * reach), Vector3(reach, y, side * reach), 0.045, pale)
			_strut(Vector3(side * reach, y, -reach), Vector3(side * reach, y, reach), 0.045, pale)
	_seed()
	_stand_sign(high + 0.55)


func _bar(at: Vector3, size: Vector3, material: Material) -> void:
	var shown := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	shown.mesh = mesh
	shown.material_override = material
	shown.position = at
	add_child(shown)


func _write() -> void:
	if _sign == null: return
	if window:
		_sign.text = "\n".join(PackedStringArray(["THE BIOME, FROM ABOVE",
			"The glass is a floor: walk out on it. One floor down the same ground stands at the stage of the hall below.",
			"From the middle of the glass all of it is in view."]))
		return
	var words := arriving()
	var here := "everything the tower teaches" if _stage_now == "full" else _stage_now.to_upper()
	var comes := ", ".join(words) if not words.is_empty() else "nothing new to see"
	_sign.text = "\n".join(PackedStringArray(["THE BIOME, AT THIS FLOOR",
		("One ground from one seed, the same in every box down the tower." if flare_height <= 0.0 else "One ground from one seed, here %d metres across, carried %s m up on slanted glass." % [cells, str(snappedf(flare_height, 0.1))]) + " It may only be made of what the halls above have taught." + ("" if gate_side == "" or flare_height <= 0.0 else " The way in is up the ramp on the %s side: the ground carries you." % gate_side),
		"Here: %s.  Arriving with it: %s%s." % [here, comes, "" if words.is_empty() or _stage_now == "full" else " - %d %% of the way" % int(roundf(phase * 100.0))],
		"" if _biome != null else "The box is empty until someone arrives on its floor."]))


## Whoever arrives on this floor makes the biome build: a zone over the whole slab.
func _watch() -> void:
	var zone := Area3D.new()
	zone.name = "FloorArrival"
	zone.collision_layer = 0
	zone.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(46.0, 5.0, 22.0)
	var shape := CollisionShape3D.new()
	shape.shape = room
	zone.add_child(shape)
	zone.top_level = true
	add_child(zone)
	zone.global_position = Vector3(0, global_position.y + room.size.y * 0.5, 0)
	zone.body_entered.connect(func(b: Node) -> void:
		if not b is CharacterBody3D: return
		if window:
			_ask_until = Time.get_ticks_msec() + 30000
			_ask.call_deferred()
		elif _biome == null: grow.call_deferred())


## The window asks for the biome under it until a box answers: the floor below may still be building its works.
func _ask() -> void:
	if _answered or not is_inside_tree(): return
	get_tree().call_group("biome_boxes", "asked_from_above", self)
	if not _answered and Time.get_ticks_msec() < _ask_until: get_tree().create_timer(0.5).timeout.connect(_ask)


func answered_from_below() -> void:
	_answered = true


## A window in the floor above asks: the box straight under it builds now, paused as its floor is.
func asked_from_above(asker: Node3D) -> void:
	if window or not is_instance_valid(asker) or not is_inside_tree(): return
	var gap: Vector3 = asker.global_position - global_position
	if absf(gap.x) > 1.0 or absf(gap.z) > 1.0 or gap.y < 3.0 or gap.y > 9.0: return
	grow()
	if asker.has_method("answered_from_below"): asker.answered_from_below()


## Build the biome in the box (once).
func grow() -> void:
	if _biome != null: return
	var began := Time.get_ticks_msec()
	_biome = Biome.instantiate()
	_biome.name = "Biome"
	for pair in [["seed", world_seed], ["size", cells], ["stage", _stage_now], ["phase", phase], ["record", "off"]]:
		_biome.set_meta("config_" + str(pair[0]), pair[1])
	_biome.position = SET_IN + Vector3(0, LIFT + flare_height, 0)
	add_child(_biome)
	_built_config = [_stage_now, phase, world_seed, cells]
	_build_ms = Time.get_ticks_msec() - began
	if _seed_mark != null: _seed_mark.visible = false
	_write()
	_lay_way_in()


## ---- for a test ----

func state() -> Dictionary:
	var counts: Dictionary = _biome.get("_counts") if _biome != null else {}
	return {"stage": _stage_now, "phase": phase, "window": window, "gate": gate_side, "way_in_reach_m": snappedf(_way_reach, 0.01), "way_in_clears_the_edge": _way_clears, "built": _biome != null, "build_ms": _build_ms, "trees": int(counts.get("tree", 0)), "creatures": int(counts.get("creature", 0)),
		"fungus": int(counts.get("fungus", 0)), "flowers": int(counts.get("flower", 0)), "water": int(counts.get("water", 0)), "arriving": arriving()}


func biome() -> Node3D:
	return _biome


func half_side() -> float:
	return (float(cells) + MARGIN * 2.0) * 0.5


## Half the foot on the floor: the shaft's rim in the slanted form, the box itself otherwise.
func foot_half() -> float:
	return SHAFT * 0.5 + MARGIN if flare_height > 0.0 else half_side()


## How high the glass stands: the box's lid, or the top of the upright band round a raised ground.
func glass_top() -> float:
	return flare_height + BAND if flare_height > 0.0 else tall
