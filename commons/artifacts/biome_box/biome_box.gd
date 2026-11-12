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
## `stage`: hall = the sequence of the floor the box stands on (read from the floor's map), full = everything, or a
## sequence named outright. The biome's builders take about a second (the mycelium most of it), so with
## `builds: arrival` the box stays an empty grid until a body arrives on its floor; `always` builds at once.
const Biome := preload("res://commons/artifacts/biome_object/biome_object.tscn")
const Grammar := preload("res://commons/biome_layers/biome_grammar.gd")
const MARGIN := 0.3                   # glass to the biome's edge
const SET_IN := Vector3(0.05, 0.0, -0.27)   # before `full` a body lies half a metre over the biome's south edge: the ground stands that much north
const LIFT := 0.44                     # the biome's cut section reaches this far under its surface
const LINE := Color("f5a9b8")

@export_enum("hall", "full", "primitives", "transformation", "array_tutorial", "color", "tiling", "change", "forces", "formfinding", "wavefunctions",
	"randomness", "noise", "cellularautomata", "fractals", "lsystems", "proceduralgeneration", "softbodies", "isosurfaces", "boolean_surfaces",
	"swarmintelligence", "machinelearning", "graphtheory", "foundationscrisis", "qfeplaboratory", "postfoundationscrisis") var stage := "hall"
@export_range(0.0, 1.0) var phase := 1.0          ## how far what arrives at this stage has come
@export var world_seed := 7                       ## the one ground: the same number on every floor
@export_range(4, 6) var cells := 6                ## the biome's cells across, a metre each (seed 7 has no tree below six)
@export var tall := 3.6
@export_enum("arrival", "always") var builds := "arrival"

var _biome: Node3D
var _stage_now := ""
var _sign: Label3D
var _seed_mark: MeshInstance3D
var _build_ms := -1
var _built_config := []


func _ready() -> void:
	var given := {}
	for key in ["stage", "phase", "world_seed", "cells", "tall", "builds"]:
		if has_meta("config_" + key): given[key] = get_meta("config_" + key)
	_take(given)
	_box()
	_stage_now = _resolve()
	_write()
	if builds == "always": grow.call_deferred()
	else: _watch()


func _take(config_data: Dictionary) -> void:
	if config_data.has("stage"): stage = str(config_data["stage"]).strip_edges()
	if config_data.has("phase"): phase = clampf(float(str(config_data["phase"])), 0.0, 1.0)
	if config_data.has("world_seed"): world_seed = int(float(str(config_data["world_seed"])))
	if config_data.has("cells"): cells = clampi(int(float(str(config_data["cells"]))), 4, 6)
	if config_data.has("tall"): tall = clampf(float(str(config_data["tall"])), 2.0, 5.4)
	if config_data.has("builds") and str(config_data["builds"]) in ["arrival", "always"]: builds = str(config_data["builds"])


func apply_grid_config(config_data: Dictionary) -> void:
	_take(config_data)
	if not is_inside_tree() or _sign == null: return
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
	# the seed: where the biome begins, shown while the box is still empty
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
	# the sign: low, outside the south glass
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	var stand := Node3D.new()
	stand.name = "Sign"
	stand.position = Vector3(0, 0, half + 0.55)
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
	var words := arriving()
	var here := "everything the tower teaches" if _stage_now == "full" else _stage_now.to_upper()
	var comes := ", ".join(words) if not words.is_empty() else "nothing new to see"
	_sign.text = "\n".join(PackedStringArray(["THE BIOME, AT THIS FLOOR",
		"One ground from one seed, the same in every box down the tower. It may only be made of what the halls above have taught.",
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
	zone.global_position = Vector3(0, global_position.y + 2.5, 0)
	zone.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D and _biome == null: grow.call_deferred())


## Build the biome in the box (once).
func grow() -> void:
	if _biome != null: return
	var began := Time.get_ticks_msec()
	_biome = Biome.instantiate()
	_biome.name = "Biome"
	for pair in [["seed", world_seed], ["size", cells], ["stage", _stage_now], ["phase", phase], ["record", "off"]]:
		_biome.set_meta("config_" + str(pair[0]), pair[1])
	_biome.position = SET_IN + Vector3(0, LIFT, 0)
	add_child(_biome)
	_built_config = [_stage_now, phase, world_seed, cells]
	_build_ms = Time.get_ticks_msec() - began
	if _seed_mark != null: _seed_mark.visible = false
	_write()


## ---- for a test ----

func state() -> Dictionary:
	var counts: Dictionary = _biome.get("_counts") if _biome != null else {}
	return {"stage": _stage_now, "phase": phase, "built": _biome != null, "build_ms": _build_ms, "trees": int(counts.get("tree", 0)), "creatures": int(counts.get("creature", 0)),
		"fungus": int(counts.get("fungus", 0)), "flowers": int(counts.get("flower", 0)), "water": int(counts.get("water", 0)), "arriving": arriving()}


func biome() -> Node3D:
	return _biome


func half_side() -> float:
	return (float(cells) + MARGIN * 2.0) * 0.5
