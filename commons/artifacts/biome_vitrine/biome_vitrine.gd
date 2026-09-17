# biome_vitrine.gd — a glass cage, open to the sky, holding the biome at one spine stage.
#
# @identity
# essence: the nature system the grid lane builds AROUND a map, contained and gated by the
#          ladder: a stage (a hall or a sequence) names a closure of what the biome may be
#          made of, do and know (commons/data/biome_vocabulary.json via biome_grammar.gd).
#          Before colour the cage holds the grey grammar — one point you can move, then a
#          line, a trace, a lattice, faces, bodies, self-motion, spheres, divisions, an
#          ornament; from colour on the stage's kingdoms are painted at the stage's density
#          and dispatched cell by cell through BiomePaintDispatcher. Creatures come through
#          CritterSpawner; they SELECT only once machinelearning is learned. A PresenceGrid
#          remembers every organism from Point_Trace on, grey until colour, and glows
#          through the floor. A stand screen states the cage, its vocabulary, and what lies
#          beyond what the hall wrote. The state goes to ada_run/biome_vitrines.json.
# desire: to stand in a hall and see what the world is made of SO FAR — Palle, 2026-09-17:
#         "the first biome might just be one point we can move"; "you arrive late"
# critical_parameter: stage — a hall name (Point_One), a sequence key (randomness), or
#                     `hall` for the hall the cage stands in; everything follows from it
# triggers: apply_grid_config (#stage:Point_One#size:5#seed:7#evolve:on#duration:20);
#           the generation timer; readbacks get_state / get_history / status_line / closure
# emerges: the same seed paints the same cells at every stage — what changes between two
#          cages is only what the stage lets those cells become
# needs: cage [has]; grey grammar [has]; painted patch [has]; live creatures [has]; selection
#        from ML only [has]; presence floor [has, own shader]; record file [has]; query rack
#        (STAGE / GEN scrub) [missing]; dream replay [missing]
# relationships: mushrooms (the glass-case idiom); BiomeRingComponent (ground cover shared
#                via ground_cover.gd); grab_sphere_point_with_text (the grabbable point idiom);
#                biome_grammar (the gate); doc/COMBINATORY_BIOME.md (the design)
# truth: a biome is not scenery around the lesson — it is the lesson so far, alive
#
# Map tokens (words, or numbers whose keys are in CONFIG_PARAM_NAMES):
#   biome_vitrine#stage:Point_One#size:5#seed:7            one grey point, movable
#   biome_vitrine#stage:randomness#size:8#seed:7#evolve:on#duration:20
#   #stage:hall reads the hall the cage stands in (museum em_map / em_chapter meta, or the
#   grid's map name). #glow:off keeps the floor dark; #entry:off closes the doorways.
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
## The grey grammar's greys — no hue anywhere before the colour sequence.
const GREY_POINT := 0.22
const GREY_LINE := 0.35
const GREY_FACE := 0.50
const GREY_BODY := 0.58

## The spine stage whose biome stands here: a soft_stages.json sequence key, a HALL
## name (Point_One … Primitives_Melencolia and every other map_authored hall), or
## `hall` for the hall the cage stands in. The enum lists the sequences; halls are
## typed on the token.
@export_enum("hall", "primitives", "transformation", "array_tutorial", "color", "tiling",
	"change", "isosurfaces", "boolean_surfaces", "forces", "formfinding", "wavefunctions",
	"randomness", "noise", "cellularautomata", "fractals", "lsystems", "proceduralgeneration",
	"swarmintelligence", "softbodies", "machinelearning", "graphtheory", "foundationscrisis",
	"qfeplaboratory", "postfoundationscrisis", "mosaicanalysis", "biome_lab") var stage: String = "randomness"
## Cage side in cells (one metre each). The top is open.
@export_range(3, 24) var size: int = 8
## Glass height in metres.
@export var height: float = 3.0
## Seeds the painting and the creatures' DNA; the same seed paints the same cells.
@export var seed: int = 7
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

static var _stages_cache: Dictionary = {}

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
# the grey grammar
var _garden: Node3D = null
var _free_points: Array[Node3D] = []
var _line: MeshInstance3D = null
var _movers: Array[Node3D] = []
var _mover_phase: Array[float] = []
var _grammar_counts: Dictionary = {}
var _time: float = 0.0


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
	if config.has("entry"):
		entry = "on" if _flag(config["entry"]) else "off"
	if config.has("evolve"):
		evolve = "on" if _flag(config["evolve"]) else "off"
	if config.has("record"):
		record = "on" if _flag(config["record"]) else "off"
	if config.has("glow"):
		glow = "on" if _flag(config["glow"]) else "off"
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
	var pos: Dictionary = _closure.get("position", {})
	_sequence = String(pos.get("sequence", ""))
	if not bool(pos.get("known", false)):
		# an unknown word: try it as a sequence for the kingdoms, and say so
		_sequence = _stage_key.to_lower()
		push_warning("biome_vitrine: stage `%s` is neither a hall nor a sequence of the ladder — building a grey cage" % _stage_key)
	var info: Dictionary = _stage_info(_sequence)
	_stage_order = int(info.get("order", 0))
	_kingdoms.clear()
	for k in info.get("kingdoms", []):
		if String(k) in KINGDOM_NAMES:
			_kingdoms.append(String(k))
	_density = clampf(intensity if intensity >= 0.0 else float(info.get("density", 0.0)), 0.0, 1.0)

	_patch = Node3D.new()
	_patch.name = "Patch"
	add_child(_patch)

	_build_ground()
	if _grey():
		_build_garden()
	else:
		_paint()
		_dispatch_seeds()
		_spawn_live()
		_scatter_cover()
	if _allows("trace"):
		_build_presence()
	_build_cage()
	_build_status()
	_write_record()
	print("[biome_vitrine] stage %s (%s, order %d) made of %s · does %s · knows %s — %s, %s" % [
		_stage_key, _sequence, _stage_order, str(_closure.get("made_of", [])), str(_closure.get("does", [])),
		str(_closure.get("knows", [])),
		("grey garden %s" % str(_grammar_counts)) if _grey() else ("seeds %s, live %d, cover %d" % [str(_seed_counts), _live_cells.size(), _cover_count]),
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
	_garden = null
	_line = null
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


## Before the colour sequence the cage holds the grey grammar, not painted kingdoms.
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
	_ground_mat.set_shader_parameter("mono", 1.0 if _grey() else 0.0)
	_ground.material_override = _ground_mat
	_ground.position = Vector3(0.0, 0.01, 0.0)
	_patch.add_child(_ground)


# ════════════════════════════════════════════════════════════════════════════
# THE GREY GRAMMAR — sequences 1-3, one word at a time
# ════════════════════════════════════════════════════════════════════════════

func _grey_mat(v: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(v, v, v)
	m.roughness = 0.75
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## A point you can pick up and put down: the project's own grabbable (XR Tools pickable,
## collision layer 3, so the desktop crosshair's right-click carries it too). Frozen, so it
## stays where it is dropped — a point has a place, not a momentum.
func _make_point(index: int, at: Vector3) -> Node3D:
	var p: Node3D = PICKABLE.instantiate()
	p.name = "FreePoint_%d" % index
	var col := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.09
	col.shape = sh
	p.add_child(col)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = _grey_mat(GREY_POINT)
	p.add_child(mi)
	if p is RigidBody3D:
		(p as RigidBody3D).freeze = true
		(p as RigidBody3D).freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		(p as RigidBody3D).gravity_scale = 0.0
	_garden.add_child(p)
	p.position = at
	return p


func _build_garden() -> void:
	_garden = Node3D.new()
	_garden.name = "Garden"
	_patch.add_child(_garden)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, _stage_key, "grey"])
	var half: float = float(size) * 0.5
	var inner: float = half - 0.6
	_grammar_counts = {"points": 0, "lines": 0, "lattice": 0, "faces": 0, "solids": 0,
		"spheres": 0, "divided": 0, "ornament": 0, "movers": 0}

	# point — one, at the centre, yours to move; a second one once a line can join them
	var n_free: int = 2 if _allows("line") else 1
	for i in range(n_free):
		var at := Vector3(0.0, 0.07, 0.0) if i == 0 else Vector3(inner * 0.5, 0.07, -inner * 0.35)
		_free_points.append(_make_point(i, at))
	_grammar_counts["points"] = n_free

	# line — between the two free points; follows them (see _tick_garden)
	if _allows("line"):
		_line = MeshInstance3D.new()
		_line.name = "Line_0"
		var bm := BoxMesh.new()
		bm.size = Vector3(0.02, 0.02, 1.0)
		_line.mesh = bm
		_line.material_override = _grey_mat(GREY_LINE)
		_garden.add_child(_line)
		_grammar_counts["lines"] = 1
		_fit_line()

	# lattice — many points agreeing on a distance, lines to their neighbours
	var n: int = maxi(size - 2, 2)
	if _allows("lattice"):
		var pts := MultiMesh.new()
		pts.transform_format = MultiMesh.TRANSFORM_3D
		var pm := SphereMesh.new()
		pm.radius = 0.035
		pm.height = 0.07
		pm.radial_segments = 8
		pm.rings = 4
		pts.mesh = pm
		pts.instance_count = n * n
		var links := MultiMesh.new()
		links.transform_format = MultiMesh.TRANSFORM_3D
		var lm := BoxMesh.new()
		lm.size = Vector3(0.012, 0.012, 1.0)
		links.mesh = lm
		links.instance_count = n * (n - 1) * 2
		var li := 0
		for iz in range(n):
			for ix in range(n):
				var at := Vector3(-inner + (float(ix) + 0.5) * (2.0 * inner / float(n)), 0.04,
					-inner + (float(iz) + 0.5) * (2.0 * inner / float(n)))
				var t := Transform3D.IDENTITY
				t.origin = at
				pts.set_instance_transform(iz * n + ix, t)
				var step: float = 2.0 * inner / float(n)
				if ix + 1 < n:
					var tl := Transform3D.IDENTITY.rotated(Vector3.UP, PI * 0.5).scaled(Vector3(1, 1, step))
					tl.origin = at + Vector3(step * 0.5, 0.0, 0.0)
					links.set_instance_transform(li, tl)
					li += 1
				if iz + 1 < n:
					var tz := Transform3D.IDENTITY.scaled(Vector3(1, 1, step))
					tz.origin = at + Vector3(0.0, 0.0, step * 0.5)
					links.set_instance_transform(li, tz)
					li += 1
		var pmi := MultiMeshInstance3D.new()
		pmi.name = "Lattice"
		pmi.multimesh = pts
		pmi.material_override = _grey_mat(GREY_POINT)
		_garden.add_child(pmi)
		var lmi := MultiMeshInstance3D.new()
		lmi.name = "LatticeLines"
		lmi.multimesh = links
		lmi.material_override = _grey_mat(GREY_LINE)
		_garden.add_child(lmi)
		_grammar_counts["lattice"] = n * n

	# face — three points close a boundary: grey triangles on some lattice cells
	if _allows("face"):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var faces := 0
		var step: float = 2.0 * inner / float(n)
		for iz in range(n - 1):
			for ix in range(n - 1):
				if rng.randf() > 0.35:
					continue
				var a := Vector3(-inner + (float(ix) + 0.5) * step, 0.05, -inner + (float(iz) + 0.5) * step)
				var b := a + Vector3(step, 0.0, 0.0)
				var c := a + Vector3(0.0, 0.0, step)
				st.add_vertex(a)
				st.add_vertex(b)
				st.add_vertex(c)
				faces += 1
		if faces > 0:
			st.generate_normals()
			var fm := MeshInstance3D.new()
			fm.name = "Faces"
			fm.mesh = st.commit()
			fm.material_override = _grey_mat(GREY_FACE)
			_garden.add_child(fm)
		_grammar_counts["faces"] = faces

	# solid — faces meet and enclose: cubes, prisms, double pyramids
	if _allows("solid"):
		var n_solids: int = clampi(size / 2, 2, 5)
		for i in range(n_solids):
			var body := MeshInstance3D.new()
			body.name = "Solid_%d" % i
			match i % 3:
				0:
					var bm2 := BoxMesh.new()
					bm2.size = Vector3(0.45, 0.45, 0.45)
					body.mesh = bm2
				1:
					var pr := PrismMesh.new()
					pr.size = Vector3(0.5, 0.5, 0.5)
					body.mesh = pr
				_:
					var cy := CylinderMesh.new()   # a four-sided pyramid: faces meeting at a point
					cy.top_radius = 0.0
					cy.bottom_radius = 0.32
					cy.height = 0.5
					cy.radial_segments = 4
					body.mesh = cy
			body.material_override = _grey_mat(GREY_BODY)
			body.position = Vector3(rng.randf_range(-inner + 0.4, inner - 0.4), 0.26,
				rng.randf_range(-inner + 0.4, inner - 0.4))
			body.rotation.y = rng.randf_range(0.0, TAU)
			_garden.add_child(body)
			if _allows("self_move"):
				_movers.append(body)
				_mover_phase.append(rng.randf_range(0.0, TAU))
		_grammar_counts["solids"] = n_solids

	# sphere — the name round: bodies accepted as round
	if _allows("sphere"):
		for i in range(2):
			var sp := MeshInstance3D.new()
			sp.name = "Sphere_%d" % i
			var sm2 := SphereMesh.new()
			sm2.radius = 0.28
			sm2.height = 0.56
			sm2.radial_segments = 14
			sm2.rings = 7
			sp.mesh = sm2
			sp.material_override = _grey_mat(GREY_BODY)
			sp.position = Vector3(rng.randf_range(-inner + 0.4, inner - 0.4), 0.29,
				rng.randf_range(-inner + 0.4, inner - 0.4))
			_garden.add_child(sp)
		_grammar_counts["spheres"] = 2

	# subdivide — a division, then another: one body of twenty-seven parts
	if _allows("subdivide"):
		var holder := Node3D.new()
		holder.name = "Subdivided"
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var cm := BoxMesh.new()
		cm.size = Vector3(0.13, 0.13, 0.13)
		mm.mesh = cm
		mm.instance_count = 27
		var k := 0
		for ix in range(3):
			for iy in range(3):
				for iz in range(3):
					var t := Transform3D.IDENTITY
					t.origin = Vector3((float(ix) - 1.0) * 0.17, 0.09 + float(iy) * 0.17, (float(iz) - 1.0) * 0.17)
					mm.set_instance_transform(k, t)
					k += 1
		var smi := MultiMeshInstance3D.new()
		smi.multimesh = mm
		smi.material_override = _grey_mat(GREY_BODY)
		holder.add_child(smi)
		holder.position = Vector3(-inner * 0.6, 0.0, inner * 0.6)
		_garden.add_child(holder)
		_grammar_counts["divided"] = 27

	# ornament — a form for looking: Dürer's truncated solid, standing still
	if _allows("ornament"):
		var orn := MeshInstance3D.new()
		orn.name = "Ornament"
		var cy2 := CylinderMesh.new()
		cy2.top_radius = 0.22
		cy2.bottom_radius = 0.4
		cy2.height = 0.7
		cy2.radial_segments = 6
		orn.mesh = cy2
		orn.material_override = _grey_mat(GREY_BODY + 0.08)
		orn.position = Vector3(inner * 0.6, 0.36, inner * 0.6)
		orn.rotation = Vector3(deg_to_rad(18.0), deg_to_rad(30.0), deg_to_rad(-12.0))
		_garden.add_child(orn)
		_grammar_counts["ornament"] = 1
	_grammar_counts["movers"] = _movers.size()


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
	for i in range(_movers.size()):
		var m: Node3D = _movers[i]
		if not is_instance_valid(m):
			continue
		m.rotate_y(delta * 0.25)
		m.position.y = 0.26 + 0.04 * sin(_time * 0.8 + _mover_phase[i])


func _deposit_points() -> void:
	if _presence == null or _free_points.is_empty():
		return
	for p in _free_points:
		if is_instance_valid(p):
			_presence.deposit(p.global_position, KINGDOM_ID["creature"], 0.35, 0.45)


# ════════════════════════════════════════════════════════════════════════════
# THE PAINTED PATCH — from colour on
# ════════════════════════════════════════════════════════════════════════════

## Paint the patch: which cells hold a seed, of which kingdom, how strong — seeded, so the
## same seed paints the same cells at every stage. A stage with kingdoms but no density
## still gets a sparse painting: the dispatcher's unlock guard renders locked kingdoms as
## kingdom-coloured cubes, the seeds of what is to come.
func _paint() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, _sequence])
	var paint_kingdoms: Array[String] = _kingdoms.duplicate()
	if paint_kingdoms.is_empty():
		paint_kingdoms = KINGDOM_NAMES.duplicate()
	var prob: float = 0.12 + _density * 0.55
	for k in KINGDOM_NAMES:
		_seed_counts[k] = 0
	_tiles.clear()
	_seed_cells.clear()
	for z in range(size):
		var row: Array = []
		for x in range(size):
			var tok := ""
			if rng.randf() < prob:
				var k: String = paint_kingdoms[rng.randi_range(0, paint_kingdoms.size() - 1)]
				var inten: int = clampi(1 + int(rng.randf() * (1.0 + _density * 4.0)), 1, 5)
				if int(_seed_counts[k]) < int(CAPS[k]):
					_seed_counts[k] = int(_seed_counts[k]) + 1
					tok = String(KINGDOM_LETTER[k]) + str(inten)
					_seed_cells.append({"x": x, "z": z, "kingdom": k, "intensity": inten})
			row.append(tok)
		_tiles.append(row)


func _creature_unlocked() -> bool:
	return "creature" in _kingdoms and _stage_order >= int(ConfigLoader.get_unlock_order(KINGDOM_ID["creature"]))


## Every painted cell goes through the one dispatch law the grid uses (flower →
## BotanicalFlower, fungus → mycelium / CA, tree → TreeMorphology DNA, locked kingdoms →
## a coloured cube). Creature cells are held back when the stage has live creatures.
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
	var ctx := {
		"biome_paint": tiles,
		"stage_order": _stage_order,
		"parent": _patch,
		"grid_center": _patch.global_position + Vector3(0.0, -0.55, 0.0),
		"grid_dims": Vector3i(size, 1, size),
		"cube_size": 1.0,
	}
	_dispatcher.apply(ctx)
	# what the floor remembers: every rendered seed deposits its kingdom
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
	_evo.target_population = maxi(n, 2)
	_evo.min_population = maxi(2, int(n / 2))
	_evo.max_population = mini(int(CAPS["creature"]) * 2, maxi(n * 2, 4))
	_evo.mating_radius = float(size)
	_evo.generation_complete.connect(_on_generation)
	if _flag(evolve) and _allows("select"):
		_evo.start(duration)
		_evo_running = true


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
		# one ImageTexture, updated in place every presence tick — bound once
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
func _build_cage() -> void:
	_cage = Node3D.new()
	_cage.name = "Cage"
	add_child(_cage)
	var s := float(size)
	var h := height
	var half := s * 0.5
	var glass := Color(0.38, 0.76, 0.83, 0.085)
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
	var tail := ""
	if _grey():
		var parts: Array[String] = []
		for k in ["points", "lines", "lattice", "faces", "solids", "spheres", "divided", "ornament"]:
			if int(_grammar_counts.get(k, 0)) > 0:
				parts.append("%d %s" % [int(_grammar_counts[k]), k])
		tail = "\n%s" % (" · ".join(parts) if not parts.is_empty() else "nothing yet")
	else:
		var live: int = _spawner.get_population_count() if _spawner != null else 0
		var seeds: Array[String] = []
		for k in KINGDOM_NAMES:
			if int(_seed_counts.get(k, 0)) > 0:
				seeds.append("%d %s" % [int(_seed_counts[k]), k])
		tail = "\nseeds %s\ncover %d · live %d · gen %d · born %d · culled %d" % [
			", ".join(seeds) if not seeds.is_empty() else "none", _cover_count, live, _gen, _births, _deaths]
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
		"grey": _grey(), "grammar": _grammar_counts.duplicate(),
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
