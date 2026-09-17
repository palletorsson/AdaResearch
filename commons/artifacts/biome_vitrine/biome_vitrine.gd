# biome_vitrine.gd — a glass cage, open to the sky, holding the biome at one spine stage.
#
# @identity
# essence: a canvas with restricted tools. The stage (a hall or a sequence) names a closure
#          of what the biome may be made of, do and know (commons/data/biome_vocabulary.json
#          via biome_grammar.gd), and the cage holds ONE composition per seed — the same
#          work at a later state in every later hall — drawn with the galleries' own
#          alphabet and flat shading (primitive_stack.gd) at metre scale: a black sphere
#          at the golden section of a diagonal (Point One, and you can move it), a second
#          point and the rod between them, the floor's memory, a grid on the back pane,
#          planes tilted along the diagonal, a black cube and a floating beam, a white
#          sphere in the corner, a cube divided into twenty-seven, a bipyramid crown; then
#          what the bodies may DO — be taken, run, a sliding disc, a turning arm with a
#          sphere at its end, a pulsing sphere, a post the height of you, a white plane
#          that sweeps and turns; then colour — Kandinsky's assignment (circle blue, square
#          red, triangle yellow), lamps, the hand's own colour, the Bauhaus palette and the
#          first flowers along the diagonal, the height ramp, an address per plane, the
#          trace in colour, the glass itself. Kingdom words open the painted patch.
#          Creatures SELECT only once machinelearning is learned. Nothing before the colour
#          sequence has a hue: ink, chalk, slate, soot.
# desire: a room that reads as abstract modern art made with what the halls so far have
#         given — Malevich, Lissitzky's Prouns, LeWitt, Calder, Kandinsky, Albers — and
#         that is, at Point One, one point you can move (Palle, 2026-09-17)
# critical_parameter: stage — a hall name, a sequence key, or `hall`; and seed — one seed
#                     is one composition, the halls are its states
# triggers: apply_grid_config (#stage:Point_One#size:5#seed:7); the generation timer;
#           readbacks get_state / get_history / status_line / closure
# emerges: walk the ladder and the same diagonal, the same anchors, the same sphere are
#          there in every cage; only what the hall allows has been added
# needs: cage [has]; composition score [has]; transformation motions [has]; colour words
#        [has]; painted patch along the diagonal [has]; live creatures [has]; presence floor
#        [has]; record file [has]; query rack [missing]; dream replay [missing]
# relationships: chroma_stack / color_dna_stack (the columns this borrows its alphabet,
#                its Kandinsky colours and its flat shading from); primitive_stack (the
#                substrate); grab_sphere_point_with_text (the grabbable idiom);
#                biome_grammar (the gate); doc/COMBINATORY_BIOME.md (the design)
# truth: a biome is not scenery around the lesson — it is the lesson so far, composed
#
# Map tokens (words, or numbers whose keys are in CONFIG_PARAM_NAMES):
#   biome_vitrine#stage:Point_One#size:5#seed:7            one black sphere, floating, yours
#   biome_vitrine#stage:Trans_Rotation#size:5#seed:7       the work so far, and a turning arm
#   biome_vitrine#stage:randomness#size:8#seed:7#evolve:on#duration:20
#   #stage:hall reads the hall the cage stands in. #glow:off keeps the floor dark;
#   #entry:off closes the doorways.
extends Node3D
class_name BiomeVitrine

const DISPATCHER := preload("res://commons/biome_layers/biome_paint_dispatcher.gd")
const GroundCover := preload("res://commons/biome_layers/ground_cover.gd")
const Grammar := preload("res://commons/biome_layers/biome_grammar.gd")
const SpawnService := preload("res://commons/biome_layers/spawn_service.gd")
const ConfigLoader := preload("res://commons/biome_layers/biome_config_loader.gd")
const CritterSpawnerClass := preload("res://algorithms/nature_system/systems/spawner.gd")
const TraitMapperClass := preload("res://algorithms/nature_system/dna/critter_trait_mapper.gd")
const EvolutionClass := preload("res://algorithms/nature_system/systems/evolution_system.gd")
const PresenceClass := preload("res://algorithms/nature_system/systems/presence_grid.gd")
const Stage := preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const TEXT_SCREEN := preload("res://commons/ui/text_screen.gd")
const FLOOR_SHADER := preload("res://commons/artifacts/biome_vitrine/vitrine_floor.gdshader")
const PICKABLE := preload("res://addons/godot-xr-tools/objects/pickable.tscn")
const PrimitiveStack := preload("res://commons/primitive_grammar/primitive_stack.gd")

const STAGES_PATH := "res://commons/maps/soft_stages.json"
const RECORD_RES := "res://ada_run/biome_vitrines.json"
const RECORD_USER := "user://biome_vitrines.json"

const KINGDOM_NAMES: Array[String] = ["tree", "creature", "flower", "fungus"]
const KINGDOM_ID := {"tree": 0, "creature": 1, "flower": 2, "fungus": 3}
const KINGDOM_LETTER := {"tree": "t", "creature": "c", "flower": "f", "fungus": "u"}
## Per-kingdom caps on seeded cells — a tree is hundreds of leaf instances, a
## fungus can be a CA colony; the frame budget is the cage's, not the hall's.
const CAPS := {"tree": 6, "creature": 8, "flower": 24, "fungus": 8}
const ENTRY_W := 2.2
const COVER_PER_SQM := 3.0
const COVER_CAP := 300
const PRESENCE_RES := 64
const BODY_HEIGHT_M := 1.65
const PHI := 0.618

## The greys — a Suprematist's four — and Kandinsky's assignment, as chroma_stack has it.
## Exactly neutral: before the colour sequence nothing may carry a hue, not even a tint.
const INK := Color(0.06, 0.06, 0.06)
const CHALK := Color(0.92, 0.92, 0.92)
const SLATE := Color(0.44, 0.44, 0.44)
const SOOT := Color(0.23, 0.23, 0.23)
const BLUE := Color(0.16, 0.36, 0.80)
const RED := Color(0.80, 0.16, 0.16)
const YELLOW := Color(0.92, 0.78, 0.18)
const PINK := Color(0.95, 0.25, 0.60)

## The spine stage whose biome stands here: a soft_stages.json sequence key, a HALL
## name (Point_One … Chamber_Color and every other map_authored hall), or `hall` for
## the hall the cage stands in. The enum lists the sequences; halls are typed on the token.
@export_enum("hall", "primitives", "transformation", "array_tutorial", "color", "tiling",
	"change", "isosurfaces", "boolean_surfaces", "forces", "formfinding", "wavefunctions",
	"randomness", "noise", "cellularautomata", "fractals", "lsystems", "proceduralgeneration",
	"swarmintelligence", "softbodies", "machinelearning", "graphtheory", "foundationscrisis",
	"qfeplaboratory", "postfoundationscrisis", "mosaicanalysis", "biome_lab") var stage: String = "randomness"
## Cage side in cells (one metre each). The top is open.
@export_range(3, 24) var size: int = 8
## Glass height in metres.
@export var height: float = 3.0
## One seed is one composition; the halls are its states.
@export var seed: int = 7
## The composition family the seed's work follows. `seed` lets the seed pick one of the three
## built in (every hall that ships today composes so); a name pins it — the built-in three, or
## a FILE family under commons/biome_layers/families/<name>.gd, four of them written by four
## agents who never saw each other's (the auto-research fan-out, 2026-09-17); `any` lets the
## seed pick among all seven.
@export_enum("seed", "diagonal", "vertical", "split", "kandinsky", "malevich", "klee", "moholy", "any") var family: String = "seed"
## Doorways in the two end walls.
@export_enum("on", "off") var entry: String = "on"
## Run EvolutionSystem on the live creatures (only once `select` is in the closure).
@export_enum("on", "off") var evolve: String = "on"
## Seconds per generation.
@export var duration: float = 20.0
## Density override 0..1; below 0 the stage's own vegetation_density is used.
@export var intensity: float = -1.0
## Write the cage's state to ada_run/biome_vitrines.json (user:// when res:// refuses).
@export_enum("on", "off") var record: String = "on"
## Draw the presence grid as the floor's glow.
@export_enum("on", "off") var glow: String = "on"
## `panel`: a STAGE - / STAGE + / GEN + rack under the screen — scrub the walk and watch
## the same work grow or shrink one hall at a time; GEN + makes a generation pass now.
@export_enum("none", "panel") var controls: String = "none"
## Extra vocabulary words granted to this cage beyond its stage's closure, comma-joined
## (`#allow:branch`): the counterfactual — what would have grown had the word arrived
## here. tools/dream_biome.py runs cages with it. Empty: the closure alone.
@export var allow: String = ""
## A label for the lineage log's `run` field (the dream tool names its runs).
@export var run: String = ""

const RACK_TEMPLATES_PATH := "res://commons/audio/rack_templates/RackTemplates.gd"
const PANEL_SCALE := 2.0
const LINEAGE_RES := "res://ada_run/biome_lineage.jsonl"
const LINEAGE_USER := "user://biome_lineage.jsonl"

static var _stages_cache: Dictionary = {}
static var _session: String = ""
var _console: Node3D = null
var _lineage_where: String = ""
var _lineage_rows: int = 0
var _ids: int = 0

var _built: bool = false
var _patch: Node3D = null
var _cage: Node3D = null
var _ground: MeshInstance3D = null
var _ground_mat: ShaderMaterial = null
var _dispatcher: Node3D = null
var _spawner = null            # CritterSpawner
var _mapper = null             # CritterTraitMapper
var _evo = null                # EvolutionSystem
var _evo_running: bool = false
var _presence = null           # PresenceGrid
var _status: Node3D = null
var _stage_key: String = ""
var _sequence: String = ""
var _closure: Dictionary = {}
var _stage_order: int = 0
var _kingdoms: Array[String] = []
var _density: float = 0.0
var _where: Dictionary = {}
var _tiles: Array = []
var _seed_cells: Array[Dictionary] = []
var _seed_counts: Dictionary = {}
var _live_cells: Array[Dictionary] = []
var _static_deposits: Array[Dictionary] = []
var _cover_count: int = 0
var _history: Array[Dictionary] = []
var _gen: int = 0
var _births: int = 0
var _deaths: int = 0
var _presence_timer: float = 0.0
var _static_timer: float = 0.0
var _status_timer: float = 0.0
var _record_where: String = ""
# the composition
var _garden: Node3D = null
var _score: Dictionary = {}
var _free_points: Array[Node3D] = []
var _line: MeshInstance3D = null
var _movers: Array[Node3D] = []
var _mover_phase: Array[float] = []
var _grammar_counts: Dictionary = {}
var _time: float = 0.0
var _palette: Array = []
# transformation: the rule-driven bodies
var _loop: Node3D = null
var _carrier: Node3D = null
var _spoke: Node3D = null
var _pulse: Node3D = null
var _boundary: Node3D = null
# randomness: the walk, the absence, the estimate
var _walk_rng: RandomNumberGenerator = null
var _walk_timer: float = 0.0
var _walk_steps: int = 0
var _absent: Node3D = null
var _absent_rng: RandomNumberGenerator = null
var _absent_timer: float = 0.0
var _pi_estimate: float = 0.0
var _darts_inside: int = 0
var _darts_total: int = 0


# ════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	add_to_group("biome_vitrine")
	if not _built:
		# deferred: the museum and the grid both position the node before or in the same
		# frame as _ready, and the dispatcher places organisms by GLOBAL position
		call_deferred("_build")


func _exit_tree() -> void:
	if _evo != null:
		_evo.stop()


## GridInteractablesComponent / the museum hand the map token's #key:value pairs here.
## Arrives before _ready under the museum, after it under some grid paths: both work.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("stage"):
		stage = str(config["stage"]).strip_edges()
	if config.has("size"):
		size = clampi(_int_of(config["size"], size), 3, 24)
	if config.has("height"):
		height = clampf(_num_of(config["height"], height), 1.0, 8.0)
	if config.has("seed"):
		seed = _int_of(config["seed"], seed)
	elif config.has("generation_seed"):
		seed = _int_of(config["generation_seed"], seed)
	if config.has("family"):
		family = str(config["family"]).strip_edges().to_lower()
	if config.has("entry"):
		entry = "on" if _flag(config["entry"]) else "off"
	if config.has("evolve"):
		evolve = "on" if _flag(config["evolve"]) else "off"
	if config.has("record"):
		record = "on" if _flag(config["record"]) else "off"
	if config.has("glow"):
		glow = "on" if _flag(config["glow"]) else "off"
	if config.has("controls"):
		controls = "panel" if str(config["controls"]).strip_edges().to_lower() == "panel" else "none"
	if config.has("allow"):
		allow = str(config["allow"]).strip_edges()
	if config.has("run"):
		run = str(config["run"]).strip_edges()
	if config.has("duration"):
		duration = clampf(_num_of(config["duration"], duration), 1.0, 600.0)
	if config.has("intensity"):
		intensity = clampf(_num_of(config["intensity"], intensity), -1.0, 1.0)
	if _built and is_inside_tree():
		_rebuild()


func _process(delta: float) -> void:
	if not _built:
		return
	_time += delta
	if _evo != null and _evo_running:
		_evo.process(delta)
	_tick_garden(delta)
	if _presence != null:
		_presence_timer += delta
		if _presence_timer >= 0.25:
			_presence_timer = 0.0
			_deposit_live()
			_deposit_points()
		_static_timer += delta
		if _static_timer >= 1.5:
			_static_timer = 0.0
			for d in _static_deposits:
				_presence.deposit(d["pos"], int(d["kingdom"]), float(d["strength"]) * 0.25, 0.7)
		_presence.process(delta)
	_status_timer += delta
	if _status_timer >= 5.0:
		_status_timer = 0.0
		_refresh_status()


# ════════════════════════════════════════════════════════════════════════════
# BUILD
# ════════════════════════════════════════════════════════════════════════════

func _build() -> void:
	if _built:
		return
	_built = true
	_where = _resolve_where()
	_stage_key = _resolve_stage()
	_closure = Grammar.closure(_stage_key)
	# the counterfactual: words granted beyond the closure, said so in the state and the log
	for w in allow.split(","):
		var word: String = w.strip_edges()
		if word == "":
			continue
		var col: String = "does"
		if word in ["colour", "light", "palette", "gradient", "tinted_glass", "point", "line", "lattice", "face", "solid", "sphere", "subdivide", "ornament", "sample", "field", "recurse", "implicit", "union", "subtract", "intersect", "connect", "repeat", "tile", "entropy", "ten_print", "ring", "drip", "dartboard", "pipe"] or word in KINGDOM_NAMES:
			col = "made_of"
		elif word in ["trace", "count", "index", "seed", "body", "address", "when", "fitness", "limit", "bias", "gaussian"]:
			col = "knows"
		if not (_closure[col] as Array).has(word):
			(_closure[col] as Array).append(word)
	var pos: Dictionary = _closure.get("position", {})
	_sequence = String(pos.get("sequence", ""))
	if not bool(pos.get("known", false)):
		_sequence = _stage_key.to_lower()
		push_warning("biome_vitrine: stage `%s` is neither a hall nor a sequence of the ladder — building a grey cage" % _stage_key)
	var info: Dictionary = _stage_info(_sequence)
	_stage_order = int(info.get("order", 0))
	# the kingdoms are the closure's kingdom words — flower with the rainbow, fungus with
	# randomness, tree and creature with L-systems — never soft_stages' per-sequence list
	_kingdoms.clear()
	for k in KINGDOM_NAMES:
		if _allows(k):
			_kingdoms.append(k)
	_density = clampf(intensity if intensity >= 0.0 else float(info.get("density", 0.0)), 0.0, 1.0)
	if not _kingdoms.is_empty() and _density <= 0.0:
		_density = 0.1
	_palette = PrimitiveStack.PALETTES.get("bauhaus", [])
	_score = _layout_score()

	_patch = Node3D.new()
	_patch.name = "Patch"
	add_child(_patch)

	_build_ground()
	if _allows("point"):
		_build_garden()
	if not _kingdoms.is_empty():
		_paint()
		_dispatch_seeds()
		_spawn_live()
		_scatter_cover()
	if _allows("trace"):
		_build_presence()
	if _allows("light"):
		_build_lights()
	_build_cage()
	_build_status()
	_write_record()
	_log_build()
	print("[biome_vitrine] stage %s (%s, order %d) made of %s · does %s · knows %s — %s, seeds %s, live %d, cover %d, %s" % [
		_stage_key, _sequence, _stage_order, str(_closure.get("made_of", [])), str(_closure.get("does", [])),
		str(_closure.get("knows", [])), str(_grammar_counts), str(_seed_counts), _live_cells.size(), _cover_count,
		_record_where if _record_where != "" else "no record"])


func _rebuild() -> void:
	if _evo != null:
		_evo.stop()
		_evo = null
	_evo_running = false
	_spawner = null
	_presence = null
	_ground_mat = null
	_status = null
	_console = null
	_garden = null
	_line = null
	_loop = null
	_carrier = null
	_spoke = null
	_pulse = null
	_boundary = null
	_absent = null
	_walk_rng = null
	_absent_rng = null
	_walk_steps = 0
	_darts_inside = 0
	_darts_total = 0
	_free_points.clear()
	_movers.clear()
	_mover_phase.clear()
	_grammar_counts.clear()
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_tiles.clear()
	_seed_cells.clear()
	_seed_counts.clear()
	_live_cells.clear()
	_static_deposits.clear()
	_history.clear()
	_gen = 0
	_births = 0
	_deaths = 0
	_built = false
	_build()


## Grey until the colour sequence's first hall.
func _grey() -> bool:
	return not _allows("colour")


func _allows(word: String) -> bool:
	return Grammar.allows(_closure, word)


func _build_ground() -> void:
	var s := float(size)
	_ground = MeshInstance3D.new()
	_ground.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(s, s)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	_ground.mesh = plane
	# a ShaderMaterial: the earth colour from the ring's recipe, the presence texture as the
	# glow. hint_default_black keeps an unbound sampler black — a StandardMaterial3D's
	# emission_texture sampled WHITE before its first bind and the floor photographed flat.
	var earth: StandardMaterial3D = GroundCover.earth_material(_density)
	_ground_mat = ShaderMaterial.new()
	_ground_mat.shader = FLOOR_SHADER
	_ground_mat.set_shader_parameter("earth", earth.albedo_color)
	_ground_mat.set_shader_parameter("glow", 0.9 if _flag(glow) else 0.0)
	# the floor remembers in grey until Color_Paint: a trace in colour is a record that says when
	_ground_mat.set_shader_parameter("mono", 0.0 if _allows("paint") else 1.0)
	_ground.material_override = _ground_mat
	_ground.position = Vector3(0.0, 0.01, 0.0)
	_patch.add_child(_ground)


# ════════════════════════════════════════════════════════════════════════════
# THE SCORE — one seed, one composition; the halls are its states
# ════════════════════════════════════════════════════════════════════════════

## Anchors from the SEED alone (never the stage), so every cage of one seed is the same
## work. Three families, the seed picks one:
##   diagonal  a dominant diagonal across the floor, its golden section as the focus, a
##             perpendicular axis; planes tilted along it (Lissitzky)
##   vertical  a short axis and everything lifted — the work stands up, the planes laid
##             flat and high, the beam high (a Proun tower)
##   split     the floor divided at golden sections, axes parallel to the walls, planes
##             standing nearly upright and low (Mondrian's fields)
## Everything later is placed on these.
##
## TILT IS MEASURED, NOT NAMED (2026-09-17, the malevich agent): a plane is a box thin in
## z, so at tilt 0 it stands upright and tilt 90 (rotation.x, Godot's YXZ order) lays it
## flat. The numbers below were written the other way round in the two lines above and
## shipped as they are — every hall that stands today composes with them — so the
## descriptions were corrected, not the numbers. A file family reads the contract the
## same way: tilt 0 upright, 90 flat.
const FAMILIES: Array[String] = ["diagonal", "vertical", "split"]
## The file families — one script each under FAMILY_DIR, written to the contract in the
## README there: score() returns a/b/lift/tilt0/tilt1, path(t) is the spine (an arc, a
## fan, a square spiral, a bent elbow), across(u) the cross axis, heading(t) the local yaw.
const FILE_FAMILIES: Array[String] = ["kandinsky", "malevich", "klee", "moholy"]
const FAMILY_DIR := "res://commons/biome_layers/families/"
## The loaded file family (a GDScript with the four static functions), or null when the
## composition is one of the three built in. Set by _layout_score().
var _fam = null


## A file family, loaded by path so the cage compiles with none of them present.
static func _family_script(fam: String):
	var p: String = FAMILY_DIR + fam + ".gd"
	if not ResourceLoader.exists(p):
		return null
	var scr = load(p)
	if scr == null or not (scr is GDScript):
		return null
	return scr


func _layout_score() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "score"])
	var k: float = float(size) / 5.0
	var inner: float = float(size) * 0.5 - 0.5
	var sx: float = 1.0 if rng.randf() < 0.5 else -1.0
	var sz: float = 1.0 if rng.randf() < 0.5 else -1.0
	# the seed's own draw comes FIRST, so `seed` (the default) composes exactly as it did
	# before the file families existed; a pinned name overrides it, `any` widens the draw
	var fam: String = FAMILIES[rng.randi_range(0, FAMILIES.size() - 1)]
	var pick: String = family.strip_edges().to_lower()
	if pick == "any":
		var all: Array[String] = FAMILIES.duplicate()
		all.append_array(FILE_FAMILIES)
		fam = all[rng.randi_range(0, all.size() - 1)]
	elif pick != "" and pick != "seed":
		fam = pick
	_fam = null
	if not (fam in FAMILIES):
		_fam = _family_script(fam)
		if _fam == null:
			push_warning("biome_vitrine: family `%s` is neither built in nor a file under %s — the seed picks" % [fam, FAMILY_DIR])
			fam = FAMILIES[rng.randi_range(0, FAMILIES.size() - 1)]
	var a: Vector3
	var b: Vector3
	var lift := 1.0
	var tilt0 := 62.0
	var tilt1 := -50.0
	var extra: Dictionary = {}
	if _fam != null:
		var sc: Variant = _fam.score(rng, inner, sx, sz)
		if sc is Dictionary and (sc as Dictionary).has_all(["a", "b", "lift", "tilt0", "tilt1"]):
			extra = sc
			a = sc["a"]
			b = sc["b"]
			a.y = 0.0
			b.y = 0.0
			lift = clampf(float(sc["lift"]), 0.6, 1.8)
			tilt0 = float(sc["tilt0"])
			tilt1 = float(sc["tilt1"])
		else:
			push_warning("biome_vitrine: family `%s` returned no a/b/lift/tilt0/tilt1 — composing on the diagonal" % fam)
			_fam = null
			fam = "diagonal"
	match fam if _fam == null else "":
		"vertical":
			a = Vector3(-inner * 0.45 * sx, 0.0, -inner * 0.45 * sz)
			b = -a
			lift = 1.45
			tilt0 = 88.0
			tilt1 = -86.0
		"split":
			a = Vector3(-inner * 0.85 * sx, 0.0, -inner * 0.236 * sz)
			b = Vector3(inner * 0.85 * sx, 0.0, -inner * 0.236 * sz)
			lift = 0.8
			tilt0 = 12.0
			tilt1 = -8.0
		"":
			pass      # a file family, scored above
		_:
			a = Vector3(-inner * 0.85 * sx, 0.0, -inner * 0.85 * sz)
			b = -a
	var dir: Vector3 = (b - a).normalized()
	var perp := Vector3(-dir.z, 0.0, dir.x)
	var out: Dictionary = extra.duplicate()
	out.merge({"k": k, "inner": inner, "a": a, "b": b, "dir": dir, "perp": perp,
		"yaw": atan2(dir.x, dir.z), "sx": sx, "sz": sz, "family": fam,
		"lift": lift, "tilt0": tilt0, "tilt1": tilt1}, true)
	return out


func _diag(t: float, y: float) -> Vector3:
	var p: Vector3
	if _fam != null:
		p = _fam.path(_score, t)
	else:
		p = (_score["a"] as Vector3).lerp(_score["b"] as Vector3, t)
	p.y = y * float(_score.get("lift", 1.0))
	return p


func _perp(u: float, y: float) -> Vector3:
	var p: Vector3
	if _fam != null:
		p = _fam.across(_score, u)
	else:
		p = (_score["perp"] as Vector3) * (float(_score["inner"]) * u)
	p.y = y * float(_score.get("lift", 1.0))
	return p


## The heading an element takes at t along the spine: the work's one yaw for the straight
## families, the local direction of travel for a file family whose spine bends or curves.
func _yaw_at(t: float) -> float:
	if _fam != null:
		return float(_fam.heading(_score, t))
	return float(_score["yaw"])


func family_name() -> String:
	return String(_score.get("family", ""))


func _k() -> float:
	return float(_score.get("k", 1.0))


## The galleries' shading: flat, roughness 0.3, two-sided.
func _mat(c: Color) -> StandardMaterial3D:
	return PrimitiveStack._shade_material(c, 0.0)


## A primitive from the substrate's alphabet, in the galleries' shading.
func _shape(shape: String, size_m: float, c: Color) -> MeshInstance3D:
	var entry: Dictionary = PrimitiveStack._make_primitive(shape, size_m, c)
	var mi: MeshInstance3D = entry["mesh"]
	mi.material_override = _mat(c)
	return mi


func _box(size_v: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size_v
	mi.mesh = bm
	mi.material_override = _mat(c)
	return mi


## Colour by role and hall. Before `colour`: the four greys. `colour`: Kandinsky's
## assignment on the bodies — circle blue, square red, triangle yellow — planes and the
## grid stay grey. `palette`: the Bauhaus palette reaches planes, beam, grid and the
## divided cube. `address`: each plane its own entry.
func _col(role: String, index: int) -> Color:
	var pal: Array = _palette
	match role:
		"point":
			if _allows("dress"):
				return PINK
			return BLUE if _allows("colour") else INK
		"point2":
			return BLUE if _allows("colour") else SOOT
		"rod":
			return SOOT
		"circle":
			return BLUE if _allows("colour") else (CHALK if index % 2 == 0 else INK)
		"square":
			return RED if _allows("colour") else (INK if index % 2 == 0 else SLATE)
		"triangle":
			return YELLOW if _allows("colour") else CHALK
		"plane":
			if _allows("address") and not pal.is_empty():
				return pal[(3 + index * 2) % pal.size()]
			if _allows("palette") and not pal.is_empty():
				return pal[3 % pal.size()]
			return CHALK if index % 2 == 0 else SLATE
		"field":
			if _allows("palette") and not pal.is_empty():
				return pal[(1 + index) % pal.size()]
			return SLATE
		"grid":
			if _allows("palette") and not pal.is_empty():
				return pal[1 % pal.size()]
			return SOOT
	return SLATE


## A body you can pick up and put down: the project's own grabbable (XR Tools pickable,
## collision layer 3, so the desktop crosshair's right-click carries it too). Frozen, so it
## stays where it is dropped — a point has a place, not a momentum.
func _make_pickable(name: String, mi: MeshInstance3D, shape: Shape3D, at: Vector3) -> Node3D:
	var p: Node3D = PICKABLE.instantiate()
	p.name = name
	var col := CollisionShape3D.new()
	col.shape = shape
	p.add_child(col)
	mi.name = "Mesh"
	p.add_child(mi)
	if p is RigidBody3D:
		(p as RigidBody3D).freeze = true
		(p as RigidBody3D).freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		(p as RigidBody3D).gravity_scale = 0.0
	_garden.add_child(p)
	p.position = at
	return p


func _make_point(index: int, at: Vector3, size_m: float, c: Color) -> Node3D:
	var sh := SphereShape3D.new()
	sh.radius = size_m * 0.55
	return _make_pickable("FreePoint_%d" % index, _shape("sphere", size_m, c), sh, at)


func _build_garden() -> void:
	_garden = Node3D.new()
	_garden.name = "Garden"
	_patch.add_child(_garden)
	var k: float = _k()
	var inner: float = float(_score["inner"])
	var yaw: float = float(_score["yaw"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "garden"])
	_grammar_counts = {"points": 0, "lines": 0, "lattice": 0, "faces": 0, "solids": 0,
		"spheres": 0, "divided": 0, "ornament": 0, "movers": 0, "rules": 0}

	# ── point: one black sphere at the golden section of the diagonal, floating, yours ──
	_free_points.append(_make_point(0, _diag(PHI, 1.25 * k), 0.30 * k, _col("point", 0)))
	var n_free := 1
	# ── line: a second point at the diagonal's foot, and the rod between them ──
	if _allows("line"):
		_free_points.append(_make_point(1, _diag(0.15, 0.85 * k), 0.22 * k, _col("point2", 1)))
		n_free = 2
		_line = _box(Vector3(0.035 * k, 0.035 * k, 1.0), _col("rod", 0))
		_line.name = "Line_0"
		_garden.add_child(_line)
		_grammar_counts["lines"] = 1
		_fit_line()
	_grammar_counts["points"] = n_free

	# ── lattice: a grid of small cubes on the back pane, LeWitt's — with its lines.
	# `remove` (Random_Remove): chance takes some cubes away; one stands outside the draw.
	if _allows("lattice"):
		var cols := 5
		var rows := 4
		var sp: float = 0.42 * k
		var back := Vector3(0.0, 1.55 * k, -inner + 0.22)
		var cubes := MultiMesh.new()
		cubes.transform_format = MultiMesh.TRANSFORM_3D
		cubes.use_colors = _allows("gradient")
		var cm := BoxMesh.new()
		cm.size = Vector3(0.13 * k, 0.13 * k, 0.13 * k)
		cubes.mesh = cm
		cubes.instance_count = cols * rows
		var removed := 0
		var protected: int = int(round(float(cols * rows) * PHI))
		var rm_rng := RandomNumberGenerator.new()
		rm_rng.seed = hash([seed, "remove"])
		var rods := MultiMesh.new()
		rods.transform_format = MultiMesh.TRANSFORM_3D
		rods.use_colors = _allows("gradient")
		var rm := BoxMesh.new()
		rm.size = Vector3(1.0, 0.014 * k, 0.014 * k)
		rods.mesh = rm
		rods.instance_count = rows + cols
		for iy in range(rows):
			for ix in range(cols):
				var t := Transform3D.IDENTITY
				t.origin = back + Vector3((float(ix) - float(cols - 1) * 0.5) * sp, (float(iy) - float(rows - 1) * 0.5) * sp, 0.0)
				var idx: int = iy * cols + ix
				if _allows("remove") and idx != protected and rm_rng.randf() < 0.3:
					t = Transform3D(Basis().scaled(Vector3.ZERO), t.origin)
					removed += 1
				cubes.set_instance_transform(idx, t)
				if cubes.use_colors:
					cubes.set_instance_color(idx, _ramp(float(iy) / float(rows - 1)))
		_grammar_counts["removed"] = removed
		for iy in range(rows):
			var th := Transform3D.IDENTITY.scaled(Vector3(float(cols - 1) * sp, 1.0, 1.0))
			th.origin = back + Vector3(0.0, (float(iy) - float(rows - 1) * 0.5) * sp, 0.0)
			rods.set_instance_transform(iy, th)
			if rods.use_colors:
				rods.set_instance_color(iy, _ramp(float(iy) / float(rows - 1)))
		for ix in range(cols):
			var tv := Transform3D.IDENTITY.rotated(Vector3.FORWARD, PI * 0.5).scaled(Vector3(1.0, float(rows - 1) * sp, 1.0))
			tv = Transform3D(Basis(Vector3.FORWARD, PI * 0.5).scaled(Vector3(1.0, float(rows - 1) * sp, 1.0)), Vector3.ZERO)
			tv.origin = back + Vector3((float(ix) - float(cols - 1) * 0.5) * sp, 0.0, 0.0)
			rods.set_instance_transform(rows + ix, tv)
			if rods.use_colors:
				rods.set_instance_color(rows + ix, _ramp(0.5))
		var cmi := MultiMeshInstance3D.new()
		cmi.name = "Lattice"
		cmi.multimesh = cubes
		cmi.material_override = _vertex_or(_col("grid", 0), cubes.use_colors)
		_garden.add_child(cmi)
		var rmi := MultiMeshInstance3D.new()
		rmi.name = "LatticeLines"
		rmi.multimesh = rods
		rmi.material_override = _vertex_or(SOOT, rods.use_colors)
		_garden.add_child(rmi)
		_grammar_counts["lattice"] = cols * rows

	# ── face: two planes tilted along the diagonal, Lissitzky's ──
	if _allows("face"):
		var faces := Node3D.new()
		faces.name = "Faces"
		_garden.add_child(faces)
		var p0: MeshInstance3D = _box(Vector3(1.6 * k, 1.1 * k, 0.03 * k), _col("plane", 0))
		p0.name = "Plane_0"
		p0.position = _diag(0.382, 1.5 * k)
		p0.rotation = Vector3(deg_to_rad(float(_score.get("tilt0", 62.0))), _yaw_at(0.382), 0.0)
		faces.add_child(p0)
		var p1: MeshInstance3D = _box(Vector3(1.2 * k, 0.8 * k, 0.03 * k), _col("plane", 1))
		p1.name = "Plane_1"
		p1.position = _perp(-0.6, 0.95 * k)
		p1.rotation = Vector3(deg_to_rad(float(_score.get("tilt1", -50.0))), _yaw_at(0.5) + PI * 0.5, 0.0)
		faces.add_child(p1)
		_grammar_counts["faces"] = 2

	# ── solid: a black cube on the floor at the diagonal's head, a beam floating off the axis ──
	if _allows("solid"):
		var pickup: bool = _allows("pickup")
		var cube_m: MeshInstance3D = _shape("cube", 0.7 * k, _col("square", 0))
		var cube_at: Vector3 = _diag(0.85, 0.35 * k)
		var cube: Node3D
		if pickup:
			var bs := BoxShape3D.new()
			bs.size = Vector3.ONE * 0.7 * k
			cube = _make_pickable("Solid_0", cube_m, bs, cube_at)
		else:
			cube_m.name = "Solid_0"
			cube_m.position = cube_at
			_garden.add_child(cube_m)
			cube = cube_m
		cube.rotation.y = _yaw_at(0.85) + deg_to_rad(15.0)
		var beam_m: MeshInstance3D = _box(Vector3(1.4 * k, 0.3 * k, 0.3 * k), _col("field", 0))
		var beam_at: Vector3 = _perp(0.55, 1.9 * k)
		var beam: Node3D
		if pickup:
			var bb := BoxShape3D.new()
			bb.size = Vector3(1.4 * k, 0.3 * k, 0.3 * k)
			beam = _make_pickable("Solid_1", beam_m, bb, beam_at)
		else:
			beam_m.name = "Solid_1"
			beam_m.position = beam_at
			_garden.add_child(beam_m)
			beam = beam_m
		beam.rotation.y = yaw + deg_to_rad(30.0)
		if _allows("self_move"):
			_movers.append(beam)
			_mover_phase.append(rng.randf_range(0.0, TAU))
		_grammar_counts["solids"] = 2

	# ── sphere: a white sphere at the diagonal's foot corner; a black one riding the beam ──
	if _allows("sphere"):
		var s0: MeshInstance3D = _shape("sphere", 0.9 * k, _col("circle", 0))
		s0.name = "Sphere_0"
		s0.position = _diag(0.0, 0.45 * k)
		_garden.add_child(s0)
		var s1: MeshInstance3D = _shape("sphere", 0.25 * k, _col("circle", 1))
		s1.name = "Sphere_1"
		var beam_n: Node3D = _garden.get_node_or_null("Solid_1")
		if beam_n != null:
			s1.position = Vector3(0.62 * k, 0.27 * k, 0.0)
			beam_n.add_child(s1)
		else:
			s1.position = _perp(0.55, 2.2 * k)
			_garden.add_child(s1)
		_grammar_counts["spheres"] = 2

	# ── subdivide: a cube divided into twenty-seven, hovering, LeWitt's open cube ──
	if _allows("subdivide"):
		var holder := Node3D.new()
		holder.name = "Subdivided"
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var cm2 := BoxMesh.new()
		cm2.size = Vector3.ONE * 0.12 * k
		mm.mesh = cm2
		mm.instance_count = 27
		var j := 0
		for ix in range(3):
			for iy in range(3):
				for iz in range(3):
					var t := Transform3D.IDENTITY
					t.origin = Vector3((float(ix) - 1.0) * 0.17 * k, (float(iy) - 1.0) * 0.17 * k, (float(iz) - 1.0) * 0.17 * k)
					mm.set_instance_transform(j, t)
					j += 1
		var smi := MultiMeshInstance3D.new()
		smi.multimesh = mm
		smi.material_override = _mat(_col("field", 1))
		holder.add_child(smi)
		holder.position = _perp(-0.3, 1.0 * k)
		holder.rotation.y = yaw
		_garden.add_child(holder)
		_grammar_counts["divided"] = 27

	# ── ornament: a bipyramid crown on the black cube — a form for looking ──
	if _allows("ornament"):
		var orn: MeshInstance3D = _shape("bipyramid", 0.6 * k, _col("triangle", 0))
		orn.name = "Ornament"
		orn.position = _diag(0.85, 0.7 * k + 0.36 * k)
		orn.rotation.y = yaw + deg_to_rad(15.0)
		_garden.add_child(orn)
		_grammar_counts["ornament"] = 1

	# ── transformation: what the bodies may DO ───────────────────────────────────
	var rules := 0
	if _allows("run"):
		var lp: MeshInstance3D = _shape("cube", 0.35 * k, _col("square", 1))
		lp.name = "Loop"
		lp.position = _perp(0.85, 0.5 * k)
		_garden.add_child(lp)
		_loop = lp
		rules += 1
	if _allows("translate"):
		var cr: MeshInstance3D = _shape("disc", 0.9 * k, _col("field", 2))
		cr.name = "Carrier"
		cr.position = _perp(0.0, 0.12 * k)
		_garden.add_child(cr)
		_carrier = cr
		rules += 1
	if _allows("rotate"):
		var pivot := Node3D.new()
		pivot.name = "Spoke"
		pivot.position = _diag(0.6, 2.0 * k) + _perp(0.25, 0.0)
		var post: MeshInstance3D = _box(Vector3(0.03 * k, 2.0 * k, 0.03 * k), SOOT)
		post.position = Vector3(0.0, -1.0 * k, 0.0)
		pivot.add_child(post)
		var bar: MeshInstance3D = _box(Vector3(1.5 * k, 0.04 * k, 0.06 * k), _col("rod", 1))
		bar.name = "Bar"
		bar.position = Vector3(0.75 * k, 0.0, 0.0)
		pivot.add_child(bar)
		var tip: MeshInstance3D = _shape("sphere", 0.18 * k, _col("circle", 2))
		tip.name = "Tip"
		tip.position = Vector3(1.5 * k, 0.0, 0.0)
		pivot.add_child(tip)
		_garden.add_child(pivot)
		_spoke = pivot
		rules += 1
	if _allows("scale"):
		var pu: MeshInstance3D = _shape("sphere", 0.4 * k, _col("circle", 3))
		pu.name = "Pulse"
		pu.position = _perp(0.8, 1.4 * k)
		_garden.add_child(pu)
		_pulse = pu
		rules += 1
	if _allows("body"):
		var bp: MeshInstance3D = _box(Vector3(0.05, BODY_HEIGHT_M, 0.05), INK)
		bp.name = "BodyPost"
		bp.position = Vector3(inner * 0.75 * float(_score["sx"]), BODY_HEIGHT_M * 0.5, inner * 0.75 * float(_score["sz"]) * -1.0)
		_garden.add_child(bp)
	if _allows("boundary_moves"):
		var bd: MeshInstance3D = _box(Vector3(1.6 * k, 1.8 * k, 0.04 * k), _col("plane", 2))
		bd.name = "Boundary"
		bd.position = _diag(0.5, 0.9 * k)
		bd.rotation.y = yaw + PI * 0.5
		_garden.add_child(bd)
		_boundary = bd
		rules += 1
	_grammar_counts["rules"] = rules
	_grammar_counts["movers"] = _movers.size()
	_build_chance(rng, k, inner, yaw)


## ── randomness: what chance may change ─────────────────────────────────────────
## Every element seeded from the cage's seed and its word, so the same seed draws the
## same reel, the same maze, the same drips, the same darts; the walk and the absence
## draw as time passes, from their own seeded streams.
func _build_chance(rng: RandomNumberGenerator, k: float, inner: float, yaw: float) -> void:
	var pal: Array = _palette
	# `sample` (Random_Definition): a reel of five amounts the seed chose, on a rod
	if _allows("sample"):
		var reel := Node3D.new()
		reel.name = "Reel"
		var rr := RandomNumberGenerator.new()
		rr.seed = hash([seed, "reel"])
		var rod: MeshInstance3D = _box(Vector3(1.5 * k, 0.03 * k, 0.03 * k), SOOT)
		reel.add_child(rod)
		for i in range(5):
			var c: Color = pal[rr.randi_range(0, pal.size() - 1)] if not pal.is_empty() and _allows("colour") else (CHALK if rr.randf() < 0.5 else INK)
			var cube: MeshInstance3D = _shape("cube", 0.16 * k, c)
			cube.position = Vector3((float(i) - 2.0) * 0.32 * k, 0.0, 0.0)
			cube.rotation.y = rr.randf_range(0.0, TAU)
			reel.add_child(cube)
		reel.position = _perp(-0.85, 1.7 * k)
		reel.rotation.y = yaw
		_garden.add_child(reel)
		_grammar_counts["reel"] = 5
	# `entropy` (Random_Entropy): the grid again, its agreement withdrawn — on the side pane
	if _allows("entropy"):
		var er := RandomNumberGenerator.new()
		er.seed = hash([seed, "entropy"])
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var cm := BoxMesh.new()
		cm.size = Vector3.ONE * 0.13 * k
		mm.mesh = cm
		mm.instance_count = 20
		var side := Vector3(-inner + 0.22, 1.55 * k, 0.0)
		for i in range(20):
			var t := Transform3D.IDENTITY.rotated(Vector3.UP, er.randf_range(0.0, TAU)).rotated(Vector3.RIGHT, er.randf_range(-0.6, 0.6))
			t.origin = side + Vector3(0.0, (float(i / 5) - 1.5) * 0.42 * k + er.randf_range(-0.14, 0.14) * k, (float(i % 5) - 2.0) * 0.42 * k + er.randf_range(-0.14, 0.14) * k)
			mm.set_instance_transform(i, t)
		var emi := MultiMeshInstance3D.new()
		emi.name = "Entropy"
		emi.multimesh = mm
		emi.material_override = _mat(_col("grid", 1))
		_garden.add_child(emi)
		_grammar_counts["entropy"] = 20
	# `ten_print` (10 PRINT): a band of slabs across the floor, each its own coin — the maze
	if _allows("ten_print"):
		var tr := RandomNumberGenerator.new()
		tr.seed = hash([seed, "ten_print"])
		var cells: int = maxi(int(2.0 * inner / (0.4 * k)), 4)
		var band := 3
		var mm2 := MultiMesh.new()
		mm2.transform_format = MultiMesh.TRANSFORM_3D
		var sm := BoxMesh.new()
		sm.size = Vector3(0.5 * k, 0.02 * k, 0.05 * k)
		mm2.mesh = sm
		mm2.instance_count = cells * band
		var n := 0
		for r in range(band):
			for c in range(cells):
				var along: float = -inner + (float(c) + 0.5) * (2.0 * inner / float(cells))
				var across: float = (float(r) - float(band - 1) * 0.5) * 0.4 * k
				var slash: bool = tr.randf() < 0.5
				var t := Transform3D.IDENTITY.rotated(Vector3.UP, yaw + PI * 0.5 + (PI * 0.25 if slash else -PI * 0.25))
				t.origin = (_score["dir"] as Vector3) * along + (_score["perp"] as Vector3) * (inner * 0.45 + across)
				t.origin.y = 0.03
				mm2.set_instance_transform(n, t)
				n += 1
		var tmi := MultiMeshInstance3D.new()
		tmi.name = "TenPrint"
		tmi.multimesh = mm2
		tmi.material_override = _mat(INK)
		_garden.add_child(tmi)
		_grammar_counts["ten_print"] = n
	# `walk` (Random_Walk): the point walks by itself, one step at a time — from build on
	if _allows("walk"):
		_walk_rng = RandomNumberGenerator.new()
		_walk_rng.seed = hash([seed, "walk"])
	# `drip` (the examples hall, Pollock): lines that start with a sampled direction and turn
	# by small amounts, from a fixed palette, painted on the floor
	if _allows("drip"):
		var dr := RandomNumberGenerator.new()
		dr.seed = hash([seed, "drip"])
		var lines := 6
		var segs := 14
		var mm3 := MultiMesh.new()
		mm3.transform_format = MultiMesh.TRANSFORM_3D
		mm3.use_colors = true
		var dm := BoxMesh.new()
		dm.size = Vector3(1.0, 0.012 * k, 0.03 * k)
		mm3.mesh = dm
		mm3.instance_count = lines * segs
		var j := 0
		for l in range(lines):
			var p := Vector3(dr.randf_range(-inner * 0.7, inner * 0.7), 0.025, dr.randf_range(-inner * 0.7, inner * 0.7))
			var ang: float = dr.randf_range(0.0, TAU)
			var c: Color = pal[dr.randi_range(0, pal.size() - 1)] if not pal.is_empty() else INK
			for s in range(segs):
				var step: float = dr.randf_range(0.18, 0.42) * k
				ang += dr.randf_range(-0.7, 0.7)
				var q := p + Vector3(cos(ang), 0.0, sin(ang)) * step
				q.x = clampf(q.x, -inner + 0.2, inner - 0.2)
				q.z = clampf(q.z, -inner + 0.2, inner - 0.2)
				var d := q - p
				var t := Transform3D(Basis(Vector3.UP, atan2(d.x, d.z) - PI * 0.5).scaled(Vector3(maxf(d.length(), 0.01), 1.0, 1.0)), (p + q) * 0.5)
				mm3.set_instance_transform(j, t)
				mm3.set_instance_color(j, c)
				j += 1
				p = q
		var dmi := MultiMeshInstance3D.new()
		dmi.name = "Drips"
		dmi.multimesh = mm3
		dmi.material_override = _vertex_or(CHALK, true)
		_garden.add_child(dmi)
		_grammar_counts["drips"] = j
	# `dartboard` (the examples hall, Monte Carlo): a square with its circle, standing,
	# forty darts sampled uniformly; the estimate reads 4 × inside / total
	if _allows("dartboard"):
		var board := Node3D.new()
		board.name = "Dartboard"
		var w: float = 1.1 * k
		var square: MeshInstance3D = _box(Vector3(w, w, 0.03 * k), CHALK)
		board.add_child(square)
		var circle: MeshInstance3D = _shape("disc", w * 0.98, SLATE)
		circle.rotation.x = PI * 0.5
		circle.position.z = 0.02 * k
		circle.scale.y = 0.4
		board.add_child(circle)
		var br := RandomNumberGenerator.new()
		br.seed = hash([seed, "darts"])
		_darts_inside = 0
		_darts_total = 40
		for i in range(_darts_total):
			var ux: float = br.randf_range(-0.5, 0.5)
			var uy: float = br.randf_range(-0.5, 0.5)
			var inside: bool = ux * ux + uy * uy <= 0.25
			if inside:
				_darts_inside += 1
			var dart: MeshInstance3D = _shape("sphere", 0.045 * k, Color(0.2, 0.75, 0.3) if inside else Color(0.85, 0.2, 0.2))
			dart.position = Vector3(ux * w, uy * w, 0.045 * k)
			board.add_child(dart)
		_pi_estimate = 4.0 * float(_darts_inside) / float(_darts_total)
		var post: MeshInstance3D = _box(Vector3(0.04 * k, 1.0 * k, 0.04 * k), SOOT)
		post.position = Vector3(0.0, -0.5 * w - 0.5 * k, 0.0)
		board.add_child(post)
		board.position = _perp(-0.55, 1.05 * k + 0.5 * w)
		board.rotation.y = yaw
		_garden.add_child(board)
		_grammar_counts["darts"] = _darts_total
	# `pipe` (the examples hall): a bounded pipe growing through six axis directions,
	# preferring straight runs, never reversing — a scribble in the volume
	if _allows("pipe"):
		var pr := RandomNumberGenerator.new()
		pr.seed = hash([seed, "pipe"])
		var dirs: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.FORWARD, Vector3.BACK]
		var segs2 := 70
		var step2: float = 0.3 * k
		var pos: Vector3 = _diag(0.5, 1.2 * k)
		var last := Vector3.ZERO
		var mm4 := MultiMesh.new()
		mm4.transform_format = MultiMesh.TRANSFORM_3D
		var pm := CylinderMesh.new()
		pm.top_radius = 0.035 * k
		pm.bottom_radius = 0.035 * k
		pm.height = step2
		pm.radial_segments = 8
		mm4.mesh = pm
		mm4.instance_count = segs2
		var placed := 0
		for s in range(segs2):
			var d: Vector3 = last
			if last == Vector3.ZERO or pr.randf() > 0.55:
				var tries := 0
				while tries < 12:
					var cand: Vector3 = dirs[pr.randi_range(0, 5)]
					if cand != -last:
						var nxt: Vector3 = pos + cand * step2
						if absf(nxt.x) < inner - 0.3 and absf(nxt.z) < inner - 0.3 and nxt.y > 0.25 * k and nxt.y < height - 0.3:
							d = cand
							break
					tries += 1
				if tries >= 12:
					break
			var q: Vector3 = pos + d * step2
			if absf(q.x) >= inner - 0.3 or absf(q.z) >= inner - 0.3 or q.y <= 0.25 * k or q.y >= height - 0.3:
				last = Vector3.ZERO
				continue
			var basis := Basis()
			if d.y == 0.0:
				basis = Basis(Vector3.FORWARD if d.x != 0.0 else Vector3.RIGHT, PI * 0.5)
			var t := Transform3D(basis, (pos + q) * 0.5)
			mm4.set_instance_transform(placed, t)
			placed += 1
			pos = q
			last = d
		mm4.instance_count = maxi(placed, 1)
		var pmi := MultiMeshInstance3D.new()
		pmi.name = "Pipe"
		pmi.multimesh = mm4
		pmi.material_override = _mat(pal[2 % pal.size()] if not pal.is_empty() and _allows("colour") else SLATE)
		_garden.add_child(pmi)
		_grammar_counts["pipe"] = placed
	# `absent` (Random_Game): a body that may not be there when you arrive — the beam's rider
	if _allows("absent"):
		_absent_rng = RandomNumberGenerator.new()
		_absent_rng.seed = hash([seed, "absent"])
		var rider: Node3D = _garden.get_node_or_null("Solid_1/Sphere_1")
		if rider == null:
			rider = _garden.get_node_or_null("Sphere_1")
		if rider == null:
			rider = _garden.get_node_or_null("Ornament")
		_absent = rider
		_absent_timer = _absent_rng.randf_range(2.0, 6.0)


func _vertex_or(c: Color, use_vertex: bool) -> StandardMaterial3D:
	var m: StandardMaterial3D = _mat(c)
	if use_vertex:
		m.vertex_color_use_as_albedo = true
		m.albedo_color = Color.WHITE
	return m


## chroma_stack's height ramp: blue at the floor, orange at the top.
func _ramp(t: float) -> Color:
	return Color.from_hsv(lerpf(0.62, 0.08, clampf(t, 0.0, 1.0)), 0.75, 0.85)


func _fit_line() -> void:
	if _line == null or _free_points.size() < 2:
		return
	# look_at_from_position speaks GLOBAL coordinates (the probe caught a garden-local pair)
	var a: Vector3 = _free_points[0].global_position
	var b: Vector3 = _free_points[1].global_position
	var d: Vector3 = b - a
	var len: float = d.length()
	if len < 0.01:
		_line.visible = false
		return
	_line.visible = true
	var up := Vector3.UP if absf(d.normalized().dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	_line.look_at_from_position(a + d * 0.5, b, up)
	_line.scale = Vector3(1.0, 1.0, len)


func _tick_garden(delta: float) -> void:
	if _garden == null:
		return
	_fit_line()
	var k: float = _k()
	for i in range(_movers.size()):
		var m: Node3D = _movers[i]
		if not is_instance_valid(m):
			continue
		m.rotate_y(delta * 0.18)
		m.position.y = 1.9 * k + 0.06 * k * sin(_time * 0.7 + _mover_phase[i])
	if _loop != null:
		_loop.position.y = 0.5 * k + 0.3 * k * sin(_time * 0.9)
		_loop.rotate_y(delta * 0.6)
		var s: float = 1.0 + 0.25 * sin(_time * 0.6)
		_loop.scale = Vector3(s, s, s)
	if _carrier != null:
		_carrier.position = _perp(0.55 * sin(_time * 0.45), 0.12 * k)
	if _spoke != null:
		_spoke.rotate_y(delta * 0.5)
	if _pulse != null:
		var ps: float = 1.0 + 0.45 * sin(_time * 1.1)
		_pulse.scale = Vector3(ps, ps, ps)
	if _boundary != null:
		_boundary.position = _diag(0.5 + 0.32 * sin(_time * 0.3), 0.9 * k)
		if _allows("compose"):
			_boundary.rotation.y = _yaw_at(0.5) + PI * 0.5 + 0.5 * sin(_time * 0.3)
	# `walk`: the point steps by itself, one of four directions, using nothing it remembers;
	# a hand that holds it wins — the walk waits
	if _walk_rng != null and not _free_points.is_empty():
		_walk_timer += delta
		if _walk_timer >= 0.5:
			_walk_timer = 0.0
			var p: Node3D = _free_points[0]
			var held: bool = p.has_method("is_picked_up") and p.is_picked_up()
			if is_instance_valid(p) and not held:
				var inner: float = float(_score["inner"])
				var dirs: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]
				var d: Vector3 = dirs[_walk_rng.randi_range(0, 3)] * 0.35 * k
				var lp: Vector3 = _garden.to_local(p.global_position) + d
				lp.x = clampf(lp.x, -inner + 0.3, inner - 0.3)
				lp.z = clampf(lp.z, -inner + 0.3, inner - 0.3)
				p.global_position = _garden.to_global(lp)
				_walk_steps += 1
	# `absent`: the rider blinks out and back on a schedule you cannot see
	if _absent != null and is_instance_valid(_absent) and _absent_rng != null:
		_absent_timer -= delta
		if _absent_timer <= 0.0:
			_absent.visible = not _absent.visible
			_absent_timer = _absent_rng.randf_range(1.5, 5.0) if _absent.visible else _absent_rng.randf_range(0.8, 2.5)


func _deposit_points() -> void:
	if _presence == null or _free_points.is_empty():
		return
	for p in _free_points:
		if is_instance_valid(p):
			_presence.deposit(p.global_position, KINGDOM_ID["creature"], 0.35, 0.45)


## `light` (Color_Flashlight): the colour is already there — pools from lamps
func _build_lights() -> void:
	var half: float = float(size) * 0.5
	var cols: Array = [RED, BLUE, YELLOW]
	for i in range(3):
		var l := OmniLight3D.new()
		l.name = "Lamp_%d" % i
		l.light_color = cols[i]
		l.light_energy = 2.4
		l.omni_range = half * 0.9
		l.omni_attenuation = 1.6
		var ang: float = TAU * float(i) / 3.0 + float(_score["yaw"])
		l.position = Vector3(cos(ang) * half * 0.45, 1.6, sin(ang) * half * 0.45)
		_patch.add_child(l)


# ════════════════════════════════════════════════════════════════════════════
# THE PAINTED PATCH — a kingdom word opens it; the seeds follow the diagonal
# ════════════════════════════════════════════════════════════════════════════

## The cells nearest the composition's diagonal are seeded first, so the living things
## stand along the same line as the work — a band, not a scatter. Seeded: the same seed
## paints the same cells at every stage. `gaussian` (Random_Gaussian): the distance is
## counted as a bell — cells drawn by a normal offset from the line, not nearest-first.
## `ring` (Random_Mushrooms): fungus stands in a fairy ring around the work's foot.
func _paint() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "paint"])
	var prob: float = 0.12 + _density * 0.55
	var want: int = clampi(int(round(float(size * size) * prob)), 1, size * size)
	for k in KINGDOM_NAMES:
		_seed_counts[k] = 0
	_tiles.clear()
	_seed_cells.clear()
	var a: Vector3 = _score["a"]
	var dir: Vector3 = _score["dir"]
	var gaussian: bool = _allows("gaussian")
	# a file family's spine may bend or curve: rank by the nearest of 33 samples, not the chord
	var spine: PackedVector3Array = PackedVector3Array()
	if _fam != null:
		for i in range(33):
			spine.append(_diag(float(i) / 32.0, 0.0))
	var ring_c: Vector3 = _diag(0.0, 0.0)
	var ring_r: float = 1.6 * _k()
	var ranked: Array = []
	for z in range(size):
		for x in range(size):
			var c := Vector3(float(x) - float(size) * 0.5 + 0.5, 0.0, float(z) - float(size) * 0.5 + 0.5)
			var rel: Vector3 = c - a
			var off: float = (rel - dir * rel.dot(dir)).length()
			if not spine.is_empty():
				off = INF
				for sp in spine:
					off = minf(off, Vector2(c.x - sp.x, c.z - sp.z).length())
			var d: float
			if gaussian:
				# the count is a bell: a cell's rank is how unlikely its offset is under N(0, 1.1)
				d = absf(off - absf(rng.randfn(0.0, 1.1))) + rng.randf() * 0.2
			else:
				d = off + rng.randf() * 0.35
			var ring_d: float = absf((c - ring_c).length() - ring_r)
			ranked.append({"x": x, "z": z, "d": d, "ring": ring_d})
	ranked.sort_custom(func(p, q): return float(p["d"]) < float(q["d"]))
	if _allows("ring") and "fungus" in _kingdoms:
		# the fungus takes the ring first: cells on the ring, nearest the ring first
		var on_ring: Array = ranked.filter(func(r): return float(r["ring"]) < 0.6)
		on_ring.sort_custom(func(p, q): return float(p["ring"]) < float(q["ring"]))
		var others: Array = ranked.filter(func(r): return float(r["ring"]) >= 0.6)
		ranked = on_ring + others
	var chosen: Dictionary = {}
	var i := 0
	var ring_first: bool = _allows("ring") and "fungus" in _kingdoms
	for r in ranked:
		if chosen.size() >= want:
			break
		var kname: String = _kingdoms[i % _kingdoms.size()]
		if ring_first and float(r["ring"]) < 0.6 and int(_seed_counts["fungus"]) < int(CAPS["fungus"]):
			kname = "fungus"
		if int(_seed_counts[kname]) >= int(CAPS[kname]):
			i += 1
			if i > ranked.size() * 2:
				break
			continue
		var inten: int = clampi(5 - int(float(r["d"]) * 1.6), 1, 5)
		_seed_counts[kname] = int(_seed_counts[kname]) + 1
		chosen[Vector2i(int(r["x"]), int(r["z"]))] = {"kingdom": kname, "intensity": inten}
		i += 1
	for z in range(size):
		var row: Array = []
		for x in range(size):
			var key := Vector2i(x, z)
			if chosen.has(key):
				var e: Dictionary = chosen[key]
				row.append(String(KINGDOM_LETTER[String(e["kingdom"])]) + str(int(e["intensity"])))
				_seed_cells.append({"x": x, "z": z, "kingdom": String(e["kingdom"]), "intensity": int(e["intensity"])})
			else:
				row.append("")
		_tiles.append(row)


func _creature_unlocked() -> bool:
	return "creature" in _kingdoms


## Every painted cell goes through the one dispatch law the grid uses (flower →
## BotanicalFlower, fungus → mycelium / CA, tree → TreeMorphology DNA). The dispatcher's
## own unlock guard reads soft_stages' order; the closure has already decided the kingdom.
func _dispatch_seeds() -> void:
	var tiles: Array = []
	_live_cells.clear()
	var live: bool = _creature_unlocked()
	for z in range(size):
		var row: Array = []
		for x in range(size):
			var tok: String = String(_tiles[z][x])
			if live and tok.begins_with("c"):
				_live_cells.append({"x": x, "z": z, "intensity": int(tok.substr(1).to_int())})
				row.append("")
			else:
				row.append(tok)
		tiles.append(row)
	_dispatcher = DISPATCHER.new()
	_dispatcher.name = "Dispatcher"
	_patch.add_child(_dispatcher)
	var order: int = _stage_order
	for k in _kingdoms:
		order = maxi(order, int(ConfigLoader.get_unlock_order(int(KINGDOM_ID[k]))))
	var ctx := {
		"biome_paint": tiles,
		"stage_order": order,
		"parent": _patch,
		"grid_center": _patch.global_position + Vector3(0.0, -0.55, 0.0),
		"grid_dims": Vector3i(size, 1, size),
		"cube_size": 1.0,
	}
	_dispatcher.apply(ctx)
	_static_deposits.clear()
	for c in _seed_cells:
		if live and String(c["kingdom"]) == "creature":
			continue
		_static_deposits.append({
			"pos": _cell_world(int(c["x"]), int(c["z"])),
			"kingdom": int(KINGDOM_ID[String(c["kingdom"])]),
			"strength": float(int(c["intensity"])) / 5.0,
		})


func _cell_world(x: int, z: int) -> Vector3:
	var gc: Vector3 = _patch.global_position
	return Vector3(gc.x + (float(x) - float(size) * 0.5 + 0.5), gc.y + 0.05,
		gc.z + (float(z) - float(size) * 0.5 + 0.5))


## Live creatures: CritterEntity through CritterSpawner (the dispatcher's own creatures are
## static SDF bodies). EvolutionSystem is wired, and RUNS only once `select` is learned —
## before machinelearning the creatures wander and nothing is bred or culled.
func _spawn_live() -> void:
	if _live_cells.is_empty():
		return
	_mapper = TraitMapperClass.new()
	_spawner = CritterSpawnerClass.new(_patch)
	_spawner.trait_mapper = _mapper
	_spawner.max_population = int(CAPS["creature"]) * 2
	_spawner.default_lod = 1
	for c in _live_cells:
		var x: int = int(c["x"])
		var z: int = int(c["z"])
		var inten: int = int(c["intensity"])
		var dna_seed: int = (x * 41 + z * 23 + seed * 7) & 0xFFFF
		var dna = SpawnService.creature_dna_from_seed(dna_seed)
		dna.segments = 3.0 + 0.5 * float(inten)
		dna.scale = 0.5 + 0.06 * float(inten)
		dna.part_length = 0.30 + 0.03 * float(inten)
		dna.part_width = 0.85
		dna.mobility = 0.25 + 0.08 * float(inten)
		dna.iridescence = 0.1 + 0.1 * float(inten) / 5.0
		_spawner.spawn(dna, _cell_world(x, z))
	var n: int = _spawner.get_population_count()
	_evo = EvolutionClass.new()
	_evo.spawner = _spawner
	# the target sits ABOVE the founding count, so a generation breeds (EvolutionSystem
	# breeds toward the target and culls above it; target == population is a still pond)
	_evo.target_population = mini(int(CAPS["creature"]) * 2, n + 4)
	_evo.min_population = maxi(2, int(n / 2))
	_evo.max_population = int(CAPS["creature"]) * 2
	_evo.mating_radius = float(size)
	# a seeded breeder, so the lineage log can be replayed: (cage seed, stage) per cage
	if "rng_seed" in _evo:
		_evo.rng_seed = hash([seed, _stage_key])
	_evo.generation_complete.connect(_on_generation)
	if _evo.has_signal("critter_born"):
		_evo.critter_born.connect(_on_born)
	if _evo.has_signal("critter_died"):
		_evo.critter_died.connect(_on_died)
	if _flag(evolve) and _allows("select"):
		_evo.start(duration)
		_evo_running = true


## One generation now — the GEN + key, and the dream runner's step. Selection is only
## learned at machinelearning, but a hand may force time to pass; the log says `forced`.
func step_generation() -> void:
	if _evo == null:
		return
	# CritterDNA.crossover / mutate draw from the GLOBAL rng: seed it per (cage, stage,
	# generation) so a hand-stepped or dream-run generation replays exactly. The clock-driven
	# path (EvolutionSystem.process) is not seeded here and stays as it was.
	seed(hash([seed, _stage_key, _evo.current_generation + 1]))
	_evo.evolve_step()


## Ground cover over the whole patch — the ring's recipe on a square instead of an annulus.
func _scatter_cover() -> void:
	var types: Array[String] = GroundCover.types_for_kingdoms(_kingdoms)
	types.erase("tree")
	types.erase("creature")
	if types.is_empty():
		types = ["grass"]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, _sequence, "cover"])
	var half: float = float(size) * 0.5
	var total: int = mini(int(float(size * size) * COVER_PER_SQM * _density), COVER_CAP)
	var per_type: int = int(float(total) / float(types.size()))
	_cover_count = 0
	for flora_type in types:
		var mesh: Mesh = GroundCover.mesh_for(flora_type)
		if mesh == null or per_type <= 0:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh
		mm.instance_count = per_type
		for i in range(per_type):
			var t := Transform3D.IDENTITY
			t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			var sc: float = rng.randf_range(0.6, 1.2)
			t = t.scaled(Vector3(sc, sc, sc))
			t.origin = Vector3(rng.randf_range(-half + 0.25, half - 0.25), 0.02,
				rng.randf_range(-half + 0.25, half - 0.25))
			mm.set_instance_transform(i, t)
			var tint: Color = GroundCover.color_for(flora_type, rng)
			tint.r += rng.randf_range(-0.05, 0.05)
			tint.g += rng.randf_range(-0.05, 0.05)
			tint.b += rng.randf_range(-0.05, 0.05)
			mm.set_instance_color(i, tint)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "CoverFoliage_%s" % flora_type
		mmi.multimesh = mm
		mmi.material_override = GroundCover.foliage_material()
		_patch.add_child(mmi)
		_cover_count += per_type


## The floor remembers: a four-channel presence grid (R tree, G creature, B flower, A fungus)
## fed by every organism and by the free points, drawn as the ground's glow. Gated off in
## the grid lane (NatureRenderer:296); alive here from Point_Trace on.
func _build_presence() -> void:
	_presence = PresenceClass.new(PRESENCE_RES, Vector2(float(size), float(size)))
	var gp: Vector3 = _patch.global_position
	_presence.world_offset = Vector2(gp.x, gp.z)
	for d in _static_deposits:
		_presence.deposit(d["pos"], int(d["kingdom"]), float(d["strength"]), 0.9)
	_deposit_live()
	_deposit_points()
	if _ground_mat != null:
		_ground_mat.set_shader_parameter("presence", _presence.get_texture())


func _deposit_live() -> void:
	if _spawner == null or _presence == null:
		return
	var half: float = float(size) * 0.5 - 0.3
	for e in _spawner.get_active_critters():
		if not (is_instance_valid(e) and e is Node3D):
			continue
		var lp: Vector3 = _patch.to_local(e.global_position)
		var cx: float = clampf(lp.x, -half, half)
		var cz: float = clampf(lp.z, -half, half)
		if cx != lp.x or cz != lp.z:
			e.global_position = _patch.to_global(Vector3(cx, lp.y, cz))
		_presence.deposit(e.global_position, KINGDOM_ID["creature"], 0.35, 0.6)


## Glass on four sides, doorways in the two end walls, steel rails, no roof.
## `tinted_glass` (Color_Walls): the cage itself is not exempt.
func _build_cage() -> void:
	_cage = Node3D.new()
	_cage.name = "Cage"
	add_child(_cage)
	var s := float(size)
	var h := height
	var half := s * 0.5
	var glass := Color(0.38, 0.76, 0.83, 0.085)
	if _allows("tinted_glass") and not _palette.is_empty():
		var gc: Color = _palette[3 % _palette.size()]
		glass = Color(gc.r, gc.g, gc.b, 0.16)
	var steel := Color(0.12, 0.19, 0.24)
	var trim := Color(0.97, 0.59, 0.27)
	for x in [-half, half]:
		Stage.box(_cage, Vector3(x, h * 0.5, 0.0), Vector3(0.045, h, s), glass, true)
		for y in [0.04, h]:
			Stage.box(_cage, Vector3(x, y, 0.0), Vector3(0.09, 0.09, s), steel)
	for z in [-half, half]:
		if _flag(entry) and s > ENTRY_W + 1.0:
			var pane: float = (s - ENTRY_W) * 0.5
			for side in [-1.0, 1.0]:
				Stage.box(_cage, Vector3(side * (ENTRY_W * 0.5 + pane * 0.5), h * 0.5, z),
					Vector3(pane, h, 0.045), glass, true)
				for x in [side * half, side * ENTRY_W * 0.5]:
					Stage.box(_cage, Vector3(x, h * 0.5, z), Vector3(0.09, h, 0.09), steel)
			Stage.box(_cage, Vector3(0.0, 0.018, z), Vector3(ENTRY_W, 0.025, 0.35), trim)
		else:
			Stage.box(_cage, Vector3(0.0, h * 0.5, z), Vector3(s, h, 0.045), glass, true)
			for x in [-half, half]:
				Stage.box(_cage, Vector3(x, h * 0.5, z), Vector3(0.09, h, 0.09), steel)
		Stage.box(_cage, Vector3(0.0, h, z), Vector3(s, 0.09, 0.09), steel)
		Stage.label(_cage, _title(), Vector3(0.0, h - 0.35, z), PI if z < 0.0 else 0.0)
	# no lid: the sky is the ceiling


## A stand screen outside the front-right post: what this cage is, what it may be made of,
## and what lies beyond what the hall wrote.
func _build_status() -> void:
	var holder := Node3D.new()
	holder.name = "StatusHolder"
	holder.set_meta("em_local_instrument", true)
	add_child(holder)
	var ts: Node3D = TEXT_SCREEN.new()
	ts.name = "Status"
	ts.width_m = 0.62
	ts.stand_height = 1.15
	ts.title = _title()
	ts.body = _status_body()
	var half: float = float(size) * 0.5
	ts.position = Vector3(half + 0.75, 0.0, half + 0.15)
	holder.add_child(ts)
	_status = ts
	if controls == "panel":
		_build_console(holder, Vector3(half + 0.75, 0.62, half + 0.15))


## STAGE - / STAGE +: the rack idiom (RackTemplates, as ten_print's console), two buttons.
## Pressing rebuilds the cage at the neighbouring stage of the walk (biome_grammar.walk).
func _build_console(holder: Node3D, at: Vector3) -> void:
	var rack: GDScript = load(RACK_TEMPLATES_PATH)
	if rack == null:
		return
	var rows: Array = [[{"type": "button", "label": "STAGE -"}, {"type": "button", "label": "STAGE +"}, {"type": "button", "label": "GEN +"}]]
	# a single space, never "": an empty title is an empty node name in older templates
	var panel: Node3D = rack.create_panel(" ", rows)
	if panel == null:
		return
	panel.name = "StagePanel"
	var blank_title: Node = panel.get_node_or_null("Title")
	if blank_title != null:
		panel.remove_child(blank_title)
		blank_title.free()
	panel.set_meta("em_local_instrument", true)
	panel.scale = Vector3.ONE * PANEL_SCALE
	panel.position = at
	panel.rotation_degrees = Vector3(-20.0, 0.0, 0.0)
	holder.add_child(panel)
	_console = panel
	var keys := ["prev", "next", "gen"]
	for i in range(keys.size()):
		var btn: Node = panel.find_child("Btn_%d" % i, true, false)
		if btn == null:
			continue
		var area: Node = btn.get_node_or_null("InteractableAreaButton")
		if area != null and area.has_signal("button_pressed"):
			var key: String = keys[i]
			# button_pressed(button) carries ONE argument: a lambda that takes it
			area.button_pressed.connect(func(_b): press_control(key))


## The console's keys, also for probes: `prev` / `next` walk one stage (the cage
## rebuilds); `gen` makes one generation pass now.
func press_control(key: String) -> void:
	if key == "gen":
		step_generation()
		return
	var nb: Dictionary = Grammar.neighbours(_stage_key)
	var target: String = String(nb.get(key, ""))
	if target == "":
		return
	stage = target
	_rebuild()


# ════════════════════════════════════════════════════════════════════════════
# THE LINEAGE LOG — ada_run/biome_lineage.jsonl, one line per organism event
# ════════════════════════════════════════════════════════════════════════════
# Append-only, derived (never edited). Every line carries the session, the run label, the
# cage (stage, sequence, place, seed, allow), and the event: `seeded` (a painted organism
# at build), `spawned` (a live creature at build), `born` (parents, the breeder's seed),
# `culled` (cause), `generation` (population ids with fitness under the named fitness).
# tools/dream_biome.py reads it: stale, sufficient, reachable, counterfactual.

static func _session_id() -> String:
	if _session == "":
		_session = "%s-%04x" % [Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace("T", "-"), randi() % 65536]
	return _session


func _cage_id() -> String:
	return _record_id()


func _next_id() -> String:
	_ids += 1
	return "%s#%d" % [_cage_id(), _ids]


func _entity_id(e: Node) -> String:
	if e == null or not is_instance_valid(e):
		return ""
	if not e.has_meta("lineage_id"):
		e.set_meta("lineage_id", _next_id())
	return String(e.get_meta("lineage_id"))


static func _dna_digest(dna) -> String:
	if dna == null:
		return ""
	return "%08x" % (hash([snappedf(float(dna.body_type), 0.01), snappedf(float(dna.segments), 0.01),
		snappedf(float(dna.symmetry), 0.01), snappedf(float(dna.scale), 0.001), snappedf(float(dna.mobility), 0.01),
		snappedf(float(dna.fertility), 0.01), snappedf(float(dna.efficiency), 0.01),
		dna.primary_color.to_html(false)]) & 0xFFFFFFFF)


func _log(row: Dictionary) -> void:
	row["session"] = _session_id()
	row["run"] = run
	row["cage"] = _cage_id()
	row["stage"] = _stage_key
	row["sequence"] = _sequence
	row["seed"] = seed
	if allow != "":
		row["allow"] = allow
	row["t"] = Time.get_datetime_string_from_system()
	var line: String = JSON.stringify(row) + "\n"
	for path in [LINEAGE_RES, LINEAGE_USER]:
		var f := FileAccess.open(path, FileAccess.READ_WRITE) if FileAccess.file_exists(path) else FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.seek_end()
			f.store_string(line)
			f.close()
			_lineage_where = path
			_lineage_rows += 1
			return
	_lineage_where = ""


## At build: every painted organism and every live creature, once.
func _log_build() -> void:
	_log({"event": "cage", "closure": {"made_of": _closure.get("made_of", []), "does": _closure.get("does", []),
		"knows": _closure.get("knows", [])}, "family": family_name(), "kingdoms": _kingdoms.duplicate(),
		"density": _density, "size": size, "fitness_fn": "default", "rng_seed": hash([seed, _stage_key]),
		"evolving": _evo_running})
	for c in _seed_cells:
		if _creature_unlocked() and String(c["kingdom"]) == "creature":
			continue
		_log({"event": "seeded", "id": _next_id(), "kingdom": String(c["kingdom"]),
			"intensity": int(c["intensity"]), "cell": [int(c["x"]), int(c["z"])], "generation": 0, "parents": []})
	if _spawner != null:
		for e in _spawner.get_active_critters():
			if is_instance_valid(e):
				_log({"event": "spawned", "id": _entity_id(e), "kingdom": String(e.get_kingdom_name()),
					"dna": _dna_digest(e.dna), "generation": 0, "parents": []})


func _on_born(child, parent_a, parent_b) -> void:
	var parents: Array = []
	if parent_a != null and is_instance_valid(parent_a):
		parents.append(_entity_id(parent_a))
	if parent_b != null and is_instance_valid(parent_b):
		parents.append(_entity_id(parent_b))
	_log({"event": "born", "id": _entity_id(child), "kingdom": String(child.get_kingdom_name()) if child != null else "",
		"dna": _dna_digest(child.dna) if child != null else "", "generation": _evo.current_generation if _evo != null else 0,
		"parents": parents, "asexual": parents.size() < 2})


func _on_died(entity, cause: String) -> void:
	_log({"event": "culled", "id": _entity_id(entity), "kingdom": String(entity.get_kingdom_name()) if entity != null else "",
		"generation": _evo.current_generation if _evo != null else 0, "cause": cause,
		"fitness": float(_evo.get_fitness(entity)) if _evo != null and entity != null else 0.0})


func _log_generation(gen: int, stats: Dictionary) -> void:
	var pop: Array = []
	if _spawner != null:
		for e in _spawner.get_active_critters():
			if is_instance_valid(e):
				pop.append({"id": _entity_id(e), "kingdom": String(e.get_kingdom_name()),
					"fitness": float(_evo.get_fitness(e)) if _evo != null else 0.0})
	_log({"event": "generation", "generation": gen, "population": pop, "births": int(stats.get("births", 0)),
		"deaths": int(stats.get("deaths", 0)), "asexual": int(stats.get("asexual_births", 0)),
		"avg_fitness": float(stats.get("avg_fitness", 0.0)), "forced": not _evo_running})


# ════════════════════════════════════════════════════════════════════════════
# STAGE + PLACE
# ════════════════════════════════════════════════════════════════════════════

static func _stage_info(key: String) -> Dictionary:
	if _stages_cache.is_empty() and FileAccess.file_exists(STAGES_PATH):
		var pv: Variant = JSON.parse_string(FileAccess.get_file_as_string(STAGES_PATH))
		if pv is Dictionary:
			_stages_cache = pv
	var stages: Variant = _stages_cache.get("stages", {})
	if stages is Dictionary and (stages as Dictionary).has(key):
		var st: Dictionary = (stages as Dictionary)[key]
		var eco: Dictionary = st.get("ecosystem", {})
		return {
			"known": true,
			"order": int(round(float(st.get("order", 0)))),
			"kingdoms": eco.get("nature_kingdoms", []),
			"density": float(eco.get("vegetation_density", 0.0)),
		}
	return {"known": false, "order": 0, "kingdoms": [], "density": 0.0}


## Where does this cage stand? The museum stamps em_map / em_chapter / em_pearl on the
## segment; the grid hands its map name down from GridSystem (the walk dark_sphere does).
func _resolve_where() -> Dictionary:
	var out := {"chapter": "", "pearl": "", "map": ""}
	var n: Node = self
	for _i in range(24):
		if n == null:
			break
		if out["map"] == "" and n.has_meta("em_map") and String(n.get_meta("em_map")) != "":
			out["map"] = String(n.get_meta("em_map"))
		if out["pearl"] == "" and n.has_meta("em_pearl") and String(n.get_meta("em_pearl")) != "":
			out["pearl"] = String(n.get_meta("em_pearl")).to_lower()
		if out["chapter"] == "" and n.has_meta("em_chapter") and String(n.get_meta("em_chapter")) != "":
			out["chapter"] = String(n.get_meta("em_chapter")).to_lower()
		var mn: Variant = n.get("map_name")
		if out["map"] == "" and mn != null and String(mn) != "":
			out["map"] = String(mn)
		n = n.get_parent()
	return out


func _resolve_stage() -> String:
	var key: String = stage.strip_edges()
	if key != "hall" and key != "":
		return key
	var map_name: String = String(_where.get("map", ""))
	if map_name != "" and bool(Grammar.position_of(map_name).get("known", false)):
		return map_name
	if String(_where.get("chapter", "")) != "":
		return String(_where["chapter"])
	if map_name != "":
		var eco: Node = get_node_or_null("/root/EcosystemManager")
		if eco != null and eco.has_method("get_sequence_for_map"):
			var seq: String = str(eco.get_sequence_for_map(map_name))
			if seq != "":
				return seq
	print("[biome_vitrine] stage `hall` with no hall or sequence in reach — randomness stands in")
	return "randomness"


# ════════════════════════════════════════════════════════════════════════════
# EVOLUTION, STATUS, RECORD, READBACKS
# ════════════════════════════════════════════════════════════════════════════

func _on_generation(gen: int, stats: Dictionary) -> void:
	_gen = gen
	_births += int(stats.get("offspring", stats.get("births", 0))) + int(stats.get("asexual", 0))
	_deaths += int(stats.get("culled", stats.get("deaths", 0)))
	var row: Dictionary = stats.duplicate()
	row["generation"] = gen
	row["population"] = _spawner.get_population_count() if _spawner != null else 0
	_history.append(row)
	if _history.size() > 200:
		_history = _history.slice(-100)
	_log_generation(gen, stats)
	_refresh_status()
	_write_record()


func _title() -> String:
	return "BIOME · %s" % _stage_key.to_upper().replace("_", " ")


func _status_body() -> String:
	var made: Array = _closure.get("made_of", [])
	var does: Array = _closure.get("does", [])
	var knows: Array = _closure.get("knows", [])
	var head := "made of %s\ndoes %s\nknows %s" % [
		" ".join(made) if not made.is_empty() else "—",
		" ".join(does) if not does.is_empty() else "—",
		" ".join(knows) if not knows.is_empty() else "—"]
	var parts: Array[String] = []
	for k in ["points", "lines", "lattice", "removed", "faces", "solids", "spheres", "divided", "ornament", "rules", "reel", "entropy", "ten_print", "drips", "darts", "pipe"]:
		if int(_grammar_counts.get(k, 0)) > 0:
			parts.append("%d %s" % [int(_grammar_counts[k]), k])
	var tail := "\n%s" % (" · ".join(parts) if not parts.is_empty() else "nothing yet")
	if not _kingdoms.is_empty():
		var live: int = _spawner.get_population_count() if _spawner != null else 0
		var seeds: Array[String] = []
		for k in KINGDOM_NAMES:
			if int(_seed_counts.get(k, 0)) > 0:
				seeds.append("%d %s" % [int(_seed_counts[k]), k])
		tail += "\nseeds %s\ncover %d · live %d · gen %d · born %d · culled %d" % [
			", ".join(seeds) if not seeds.is_empty() else "none", _cover_count, live, _gen, _births, _deaths]
	if _allows("body"):
		tail += "\nbody %.2f m · cage %.1f bodies" % [BODY_HEIGHT_M, float(size) / BODY_HEIGHT_M]
	if _allows("dartboard") and _darts_total > 0:
		tail += "\nπ ≈ 4 × %d / %d = %.3f" % [_darts_inside, _darts_total, _pi_estimate]
	if _allows("walk"):
		tail += "\nwalk: %d steps" % _walk_steps
	if _allows("when"):
		tail += "\nwhen: %d s standing" % int(_time)
	var beyond: String = Grammar.beyond_of(_stage_key)
	if beyond != "":
		tail += "\n\nbeyond: %s" % beyond
	return head + tail


func status_line() -> String:
	return "%s · %s" % [_title(), _status_body().replace("\n", " · ")]


func _refresh_status() -> void:
	if _status != null and is_instance_valid(_status) and _status.has_method("set_text"):
		_status.set_text(_title(), _status_body())


## Fraction of the patch each kingdom's presence covers (16 x 16 samples above 0.08).
func presence_coverage() -> Dictionary:
	var out := {"tree": 0.0, "creature": 0.0, "flower": 0.0, "fungus": 0.0}
	if _presence == null or _patch == null:
		return out
	var hits := {"tree": 0, "creature": 0, "flower": 0, "fungus": 0}
	var n := 16
	var half: float = float(size) * 0.5
	for iz in range(n):
		for ix in range(n):
			var lp := Vector3(-half + (float(ix) + 0.5) * float(size) / float(n), 0.0,
				-half + (float(iz) + 0.5) * float(size) / float(n))
			var c: Color = _presence.get_presence(_patch.to_global(lp))
			if c.r > 0.08:
				hits["tree"] += 1
			if c.g > 0.08:
				hits["creature"] += 1
			if c.b > 0.08:
				hits["flower"] += 1
			if c.a > 0.08:
				hits["fungus"] += 1
	for k in out.keys():
		out[k] = float(hits[k]) / float(n * n)
	return out


func get_state() -> Dictionary:
	var by_kingdom: Dictionary = {}
	if _spawner != null and _spawner.has_method("get_population_summary"):
		by_kingdom = _spawner.get_population_summary()
	return {
		"stage": _stage_key, "sequence": _sequence, "order": _stage_order,
		"closure": {"made_of": _closure.get("made_of", []), "does": _closure.get("does", []), "knows": _closure.get("knows", [])},
		"grey": _grey(), "grammar": _grammar_counts.duplicate(), "family": family_name(),
		"walk": Grammar.neighbours(_stage_key), "controls": controls, "allow": allow, "run": run,
		"lineage": {"where": _lineage_where, "rows": _lineage_rows, "session": _session_id()},
		"kingdoms": _kingdoms.duplicate(), "density": _density, "size": size, "seed": seed,
		"where": _where.duplicate(), "seeds": _seed_counts.duplicate(), "cover": _cover_count,
		"live": _spawner.get_population_count() if _spawner != null else 0,
		"by_kingdom": by_kingdom, "generation": _gen, "births": _births, "deaths": _deaths,
		"presence": presence_coverage(), "evolving": _evo_running, "duration": duration,
		"history": _history.slice(-20), "at": Time.get_datetime_string_from_system(),
	}


func get_history() -> Array[Dictionary]:
	return _history.duplicate()


func get_tiles() -> Array:
	return _tiles.duplicate(true)


func closure() -> Dictionary:
	return _closure.duplicate(true)


func stage_key() -> String:
	return _stage_key


func free_points() -> Array[Node3D]:
	return _free_points.duplicate()


func _record_id() -> String:
	var gp: Vector3 = global_position
	var place: String = String(_where.get("pearl", ""))
	if place == "":
		place = String(_where.get("map", ""))
	if place == "":
		place = "standalone"
	return "%s|%s|%d,%d" % [_stage_key, place, int(round(gp.x)), int(round(gp.z))]


func _write_record() -> void:
	if not _flag(record):
		return
	var doc: Dictionary = {}
	for path in [RECORD_RES, RECORD_USER]:
		if FileAccess.file_exists(path):
			var pv: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if pv is Dictionary:
				doc = pv
				break
	doc[_record_id()] = get_state()
	var text: String = JSON.stringify(doc, " ")
	for path in [RECORD_RES, RECORD_USER]:
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_string(text)
			f.close()
			_record_where = path
			return
	_record_where = ""


# ════════════════════════════════════════════════════════════════════════════
# CONFIG HELPERS
# ════════════════════════════════════════════════════════════════════════════

static func _flag(v: Variant) -> bool:
	if v is bool:
		return v
	var s: String = str(v).strip_edges().to_lower()
	return s == "on" or s == "true" or s == "1" or s == "yes"


static func _num_of(v: Variant, fallback: float) -> float:
	if v is float or v is int:
		return float(v)
	var s: String = str(v).strip_edges()
	if s.is_valid_float():
		return s.to_float()
	return fallback


static func _int_of(v: Variant, fallback: int) -> int:
	return int(round(_num_of(v, float(fallback))))
