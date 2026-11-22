class_name WorkerAssemblage
extends Node3D
## Endless Museum Sculpture Form & Worker Assemblage System.
## Stages the Void Tower's evolving humanoid worker (WorkerBeing) together with the
## Endless Museum's 52 procedural DreamBodies sculptural families — around Playground
## Workbenches (`formation = "workbench_arc"`) and anywhere across the 210 Void Tower
## floors (`formation = "solo" | "dyad" | "trio" | "assemblage"`).
##
## Strictly respects Concept Order #1 (Monochrome before Color F28) and harmonizes
## live with the Studio Workstation's 6-Palette Chooser on Color floors.

const Catalog := preload("res://commons/artifacts/worker_assemblage/assemblage_catalog.gd")
const Bauhaus := preload("res://commons/artifacts/scaffold_workstation/bauhaus_kit.gd")
const WorkerBeingScript := preload("res://commons/artifacts/worker_being/worker_being.gd")
const Furniture := preload("res://commons/artifacts/scaffold_workstation/shop_furniture.gd")
const ButtonScene := preload("res://commons/interactables/push_button.tscn")

@export_enum("dyad", "solo", "trio", "assemblage", "workbench_arc") var formation: String = "dyad"
@export var floor_index: int = -1                  ## -1 = auto-detect from void_capability_floor (defaults to 209 if standalone)
@export var stage: String = "auto"                 ## BiomeGrammar stage override or "auto"
@export var figure: String = ""                    ## Optional primary DreamBodies figure override
@export var secondary_figure: String = ""          ## Optional secondary figure for trio / assemblage
@export var sculpture_seed: int = 0                ## 0 = use lineage seed
@export var include_worker: bool = true
@export_enum("still", "dance", "walk") var worker_motion: String = "still"
@export var monochrome_mode: String = "auto"       ## "auto" | "true" | "false"
@export var palette_id: String = "bauhaus"
@export var interactive: bool = true               ## Flush Bauhaus plinth controls: FORM / AXIS / MODE
@export var show_plinth: bool = true
@export var target_height: float = 1.82
@export var custom_title: String = ""

signal rebuilt

var _custom_figures: Array[Dictionary] = []
var _opts_override: Dictionary = {}
var _pool: Array[Dictionary] = []                  ## Browsable list of DreamBodies recipes for this floor/atelier
var _pool_index: int = 0
var _axis_step: int = 0
var _workbench_submode: String = "dyad"            ## "dyad" | "assemblage" | "trio" when formation == "workbench_arc"
var _built_root: Node3D
var _controls_root: Node3D
var _plaque_title: Label3D
var _plaque_sub: Label3D
var _btn_form_lbl: Label3D
var _btn_axis_lbl: Label3D
var _btn_mode_lbl: Label3D
var _built := false


func apply_grid_config(config: Dictionary) -> void:
	if config.has("formation"):
		var f: String = str(config.get("formation", "dyad")).to_lower()
		if f in ["solo", "dyad", "trio", "assemblage", "workbench_arc"]:
			formation = f
	if config.has("floor"):
		floor_index = int(config.get("floor", -1))
	if config.has("stage"):
		stage = str(config.get("stage", "auto"))
	if config.has("figure"):
		figure = str(config.get("figure", "")).to_lower()
	if config.has("secondary_figure"):
		secondary_figure = str(config.get("secondary_figure", "")).to_lower()
	if config.has("figures") and config.get("figures") is Array:
		_custom_figures.clear()
		for item in config.get("figures"):
			if item is String and Catalog.is_valid_figure(item):
				_custom_figures.append({"figure": item.to_lower(), "seed": 7 + _custom_figures.size() * 11, "opts": {}})
			elif item is Dictionary and item.has("figure"):
				var fn: String = str(item.get("figure", "")).to_lower()
				if Catalog.is_valid_figure(fn):
					_custom_figures.append({
						"figure": fn,
						"seed": int(item.get("seed", 7 + _custom_figures.size() * 11)),
						"opts": (item.get("opts", {}) as Dictionary).duplicate(true) if item.get("opts") is Dictionary else {},
						"role": str(item.get("role", "STUDY")),
					})
	if config.has("opts") and config.get("opts") is Dictionary:
		_opts_override = (config.get("opts") as Dictionary).duplicate(true)
	if config.has("seed"):
		sculpture_seed = int(config.get("seed", 0))
	if config.has("include_worker"):
		include_worker = bool(config.get("include_worker", true))
	if config.has("worker_motion"):
		var wm: String = str(config.get("worker_motion", "still")).to_lower()
		if wm in ["still", "dance", "walk"]:
			worker_motion = wm
	if config.has("monochrome"):
		var mv: Variant = config.get("monochrome")
		if mv is bool:
			monochrome_mode = "true" if mv else "false"
		else:
			monochrome_mode = str(mv).to_lower()
	if config.has("palette"):
		palette_id = Bauhaus.resolve_palette(str(config.get("palette", "bauhaus")))
	if config.has("interactive"):
		interactive = bool(config.get("interactive", true))
	if config.has("plinth"):
		show_plinth = bool(config.get("plinth", true))
	if config.has("target_height"):
		target_height = clampf(float(config.get("target_height", 1.82)), 1.0, 2.8)
	if config.has("title"):
		custom_title = str(config.get("title", ""))
	if config.has("submode"):
		var sm: String = str(config.get("submode", "dyad")).to_lower()
		if sm in ["dyad", "assemblage", "trio"]:
			_workbench_submode = sm
	if is_inside_tree():
		_init_pool()
		rebuild()


func _ready() -> void:
	if floor_index < 0:
		if has_meta("void_capability_floor"):
			floor_index = int(get_meta("void_capability_floor"))
		elif has_meta("config_floor"):
			floor_index = int(get_meta("config_floor"))
	var meta_cfg: Dictionary = {}
	for key in ["formation", "stage", "figure", "secondary_figure", "figures", "opts", "seed", "include_worker", "worker_motion", "monochrome", "palette", "interactive", "plinth", "target_height", "title", "submode"]:
		if has_meta("config_" + key):
			meta_cfg[key] = get_meta("config_" + key)
	if not meta_cfg.is_empty():
		apply_grid_config(meta_cfg)
	if not _built:
		_init_pool()
		rebuild()


func effective_floor() -> int:
	return floor_index if floor_index >= 0 else 209


func is_monochrome() -> bool:
	if monochrome_mode == "true":
		return true
	if monochrome_mode == "false":
		return false
	if effective_floor() < 28:
		return true
	return Bauhaus.resolve_palette(palette_id) == "monochrome"


func _effective_lineage() -> Dictionary:
	return Catalog.lineage_for_floor(effective_floor(), stage)


func _init_pool() -> void:
	_pool.clear()
	var seen: Dictionary = {}
	var lineage: Dictionary = _effective_lineage()

	# 1. Explicit primary / secondary figure overrides go first.
	if not figure.is_empty() and Catalog.is_valid_figure(figure):
		var s0: int = sculpture_seed if sculpture_seed > 0 else 7
		_pool.append({"figure": figure, "seed": s0, "opts": _opts_override.duplicate(true), "role": "PRIMARY FORM"})
		seen[figure] = true
	if not secondary_figure.is_empty() and Catalog.is_valid_figure(secondary_figure) and not seen.has(secondary_figure):
		var s1: int = (sculpture_seed + 11) if sculpture_seed > 0 else 19
		_pool.append({"figure": secondary_figure, "seed": s1, "opts": {}, "role": "COMPANION FORM"})
		seen[secondary_figure] = true

	# 2. Explicit figures array.
	for cf in _custom_figures:
		var fn: String = str(cf.get("figure", ""))
		if not seen.has(fn):
			_pool.append(cf.duplicate(true))
			seen[fn] = true

	# 3. Chapter lineage figures.
	for lf in lineage.get("figures", []):
		var fn: String = str(lf.get("figure", ""))
		if not seen.has(fn):
			var rec: Dictionary = (lf as Dictionary).duplicate(true)
			if sculpture_seed > 0:
				rec["seed"] = sculpture_seed + _pool.size() * 7
			_pool.append(rec)
			seen[fn] = true

	# 4. Append the rest of the 12-family Atelier Archive so cycling FORM always explores the Endless Museum!
	for arch in Catalog.ATELIER_ARCHETYPES:
		var fn: String = str(arch.get("figure", ""))
		if not seen.has(fn):
			_pool.append({
				"figure": fn,
				"seed": int(arch.get("seed", 7)),
				"opts": (arch.get("opts", {}) as Dictionary).duplicate(true),
				"role": str(arch.get("lineage", "MUSEUM STUDY")),
			})
			seen[fn] = true

	_pool_index = clampi(_pool_index, 0, maxi(0, _pool.size() - 1))
	_axis_step = 0


func _active_recipe(offset: int = 0) -> Dictionary:
	if _pool.is_empty():
		_init_pool()
	var idx: int = (_pool_index + offset) % _pool.size()
	var base: Dictionary = (_pool[idx] as Dictionary).duplicate(true)
	if offset == 0 and _axis_step > 0:
		base["opts"] = _mutated_opts(str(base.get("figure", "stijl_robot")), base.get("opts", {}), _axis_step)
	return base


func _mutated_opts(fig: String, base_opts: Dictionary, step: int) -> Dictionary:
	var out: Dictionary = base_opts.duplicate(true)
	var axes: Dictionary = Catalog.axes_for(fig)
	if axes.is_empty():
		return out
	var keys: Array = axes.keys()
	keys.sort()
	var k0: String = str(keys[0])
	var vals0: Array = axes[k0] if axes[k0] is Array else []
	if not vals0.is_empty():
		out[k0] = str(vals0[step % vals0.size()])
	if keys.size() >= 2:
		var k1: String = str(keys[1])
		var vals1: Array = axes[k1] if axes[k1] is Array else []
		if not vals1.is_empty():
			out[k1] = str(vals1[(step / maxi(1, vals0.size())) % vals1.size()])
	return out


func _axis_summary(rec: Dictionary) -> String:
	var opts: Dictionary = rec.get("opts", {})
	if opts.is_empty():
		return "DEFAULT"
	var bits: Array[String] = []
	for k in opts.keys():
		bits.append(str(opts[k]).to_upper())
	return " · ".join(bits)


## Public interactive API (called by flush plinth buttons, StudioWorkstation, or probes).
func cycle_figure(delta: int = 1) -> void:
	if _pool.is_empty():
		_init_pool()
	_pool_index = posmod(_pool_index + delta, _pool.size())
	_axis_step = 0
	rebuild()


func cycle_axis() -> void:
	_axis_step += 1
	rebuild()


func cycle_formation() -> void:
	if formation == "workbench_arc":
		var modes: Array[String] = ["dyad", "assemblage", "trio"]
		var idx: int = modes.find(_workbench_submode)
		_workbench_submode = modes[(idx + 1) % modes.size()]
	else:
		var idx: int = Catalog.FORMATION_ORDER.find(formation)
		formation = Catalog.FORMATION_ORDER[(idx + 1) % Catalog.FORMATION_ORDER.size()]
	rebuild()


func set_palette_mode(pid: String) -> void:
	var next_pid: String = Bauhaus.resolve_palette(pid)
	if next_pid == palette_id:
		return
	palette_id = next_pid
	rebuild()


func get_state() -> Dictionary:
	var primary: Dictionary = _active_recipe(0)
	var secondary: Dictionary = _active_recipe(1)
	var lineage: Dictionary = _effective_lineage()
	return {
		"formation": formation,
		"submode": _workbench_submode if formation == "workbench_arc" else formation,
		"floor": effective_floor(),
		"stage": str(lineage.get("stage", "Point_One")),
		"chapter": str(lineage.get("chapter", "")),
		"monochrome": is_monochrome(),
		"palette": palette_id,
		"primary_figure": str(primary.get("figure", "")),
		"primary_opts": primary.get("opts", {}),
		"secondary_figure": str(secondary.get("figure", "")),
		"axis_step": _axis_step,
		"pool_size": _pool.size(),
		"pool_index": _pool_index,
		"interactive": interactive,
	}


func rebuild() -> void:
	_built = true
	if _built_root != null and is_instance_valid(_built_root):
		remove_child(_built_root)
		_built_root.queue_free()
	_built_root = Node3D.new()
	_built_root.name = "AssemblageBuilt"
	add_child(_built_root)

	var mono: bool = is_monochrome()
	var lineage: Dictionary = _effective_lineage()
	var m_black := Bauhaus.mat("frame", "monochrome")
	var m_white := Bauhaus.mat("quad", "monochrome")
	var m_slate := Bauhaus.mat("slate", "monochrome")
	var m_accent := _flat_mat(Catalog.accent_for_palette(palette_id, mono), 0.42)

	match formation:
		"solo":
			_build_solo(lineage, mono, m_black, m_white, m_slate, m_accent)
		"trio":
			_build_trio(lineage, mono, m_black, m_white, m_slate, m_accent)
		"assemblage":
			_build_assemblage(lineage, mono, m_black, m_white, m_slate, m_accent)
		"workbench_arc":
			_build_workbench_arc(lineage, mono, m_black, m_white, m_slate, m_accent)
		_:
			_build_dyad(lineage, mono, m_black, m_white, m_slate, m_accent)
	rebuilt.emit()


## Returns the direct parent of WorkerBeing (for StudioWorkstation / probes).
func get_worker_host() -> Node3D:
	if _built_root == null or not is_instance_valid(_built_root):
		return self
	var pad := _built_root.get_node_or_null("Unit02Pad") as Node3D
	if pad != null:
		return pad
	return _built_root


func _build_solo(lineage: Dictionary, mono: bool, m_black: Material, m_white: Material, _m_slate: Material, m_accent: Material) -> void:
	var rec: Dictionary = _active_recipe(0)
	var deck_y: float = 0.088 if show_plinth else 0.0
	if show_plinth:
		_plinth_pad(_built_root, "SoloPlinth", Vector3.ZERO, Vector2(0.96, 0.96), 0.084, m_black, m_white, m_accent)
	var sc := _spawn_sculpture(_built_root, rec, Vector3(0, deck_y, -0.02), 0.0, target_height, mono)
	sc.name = "PrimarySculpture"
	_add_plaque(_built_root, Vector3(0, deck_y + 0.005, 0.39),
		custom_title if not custom_title.is_empty() else Catalog.figure_title(str(rec.figure)),
		"%s · %s" % [str(lineage.code), _axis_summary(rec)])
	if interactive:
		_build_plinth_controls(_built_root, Vector3(0, 0.0, 0.66), m_black, m_accent, rec, "SOLO")


func _build_dyad(lineage: Dictionary, mono: bool, m_black: Material, m_white: Material, _m_slate: Material, m_accent: Material) -> void:
	var rec: Dictionary = _active_recipe(0)
	var deck_y: float = 0.088 if show_plinth else 0.0
	if show_plinth:
		_plinth_pad(_built_root, "DyadPlinth", Vector3.ZERO, Vector2(2.08, 0.96), 0.084, m_black, m_white, m_accent)
		# Crisp matte-black datum line connecting the Worker pad to the Sculpture pad.
		_box(_built_root, "DatumBridge", Vector3(0, deck_y + 0.003, 0), Vector3(0.46, 0.006, 0.024), m_black, false)
	if include_worker:
		_spawn_worker(_built_root, str(lineage.stage), Vector3(-0.54, deck_y, 0.0), deg_to_rad(14.0), mono)
	else:
		var rec_l: Dictionary = _active_recipe(1)
		_spawn_sculpture(_built_root, rec_l, Vector3(-0.54, deck_y, 0.0), deg_to_rad(14.0), target_height * 0.96, mono)
	var sc := _spawn_sculpture(_built_root, rec, Vector3(0.54, deck_y, -0.02), deg_to_rad(-14.0), target_height, mono)
	sc.name = "PrimarySculpture"
	_add_plaque(_built_root, Vector3(0, deck_y + 0.005, 0.39),
		custom_title if not custom_title.is_empty() else ("WORKER FORMATION · " + Catalog.figure_title(str(rec.figure))),
		"%s · %s" % [str(lineage.chapter), _axis_summary(rec)])
	if interactive:
		_build_plinth_controls(_built_root, Vector3(0, 0.0, 0.68), m_black, m_accent, rec, "DYAD")


func _build_trio(lineage: Dictionary, mono: bool, m_black: Material, m_white: Material, _m_slate: Material, m_accent: Material) -> void:
	var rec0: Dictionary = _active_recipe(0)
	var rec1: Dictionary = _active_recipe(1)
	var deck_y: float = 0.088 if show_plinth else 0.0
	if show_plinth:
		_plinth_pad(_built_root, "CenterPad", Vector3(0, 0, -0.10), Vector2(0.96, 0.96), 0.084, m_black, m_white, m_accent)
		var l_wing := Node3D.new(); l_wing.name = "LeftWing"; l_wing.position = Vector3(-1.24, 0, 0.18); l_wing.rotation.y = deg_to_rad(16.0); _built_root.add_child(l_wing)
		_plinth_pad(l_wing, "LeftPad", Vector3.ZERO, Vector2(1.04, 1.04), 0.084, m_black, m_white, m_accent)
		var r_wing := Node3D.new(); r_wing.name = "RightWing"; r_wing.position = Vector3(1.24, 0, 0.18); r_wing.rotation.y = deg_to_rad(-16.0); _built_root.add_child(r_wing)
		_plinth_pad(r_wing, "RightPad", Vector3.ZERO, Vector2(1.04, 1.04), 0.084, m_black, m_white, m_accent)
		_box(_built_root, "ArcRail", Vector3(0, 0.036, 0.04), Vector3(2.58, 0.024, 0.06), m_black, false)

	if include_worker:
		_spawn_worker(_built_root, str(lineage.stage), Vector3(0, deck_y, -0.10), 0.0, mono)
	else:
		var rec2: Dictionary = _active_recipe(2)
		_spawn_sculpture(_built_root, rec2, Vector3(0, deck_y, -0.10), 0.0, target_height * 1.04, mono)

	var sc_l := _spawn_sculpture(_built_root, rec1, Vector3(-1.24, deck_y, 0.18), deg_to_rad(20.0), target_height * 0.92, mono)
	sc_l.name = "SecondarySculpture"
	var sc_r := _spawn_sculpture(_built_root, rec0, Vector3(1.24, deck_y, 0.18), deg_to_rad(-20.0), target_height * 0.98, mono)
	sc_r.name = "PrimarySculpture"

	_add_plaque(_built_root, Vector3(0, deck_y + 0.005, 0.30),
		custom_title if not custom_title.is_empty() else ("ASSEMBLAGE TRIO · " + Catalog.figure_title(str(rec0.figure))),
		"%s + %s" % [Catalog.figure_title(str(rec1.figure)), _axis_summary(rec0)])
	if interactive:
		_build_plinth_controls(_built_root, Vector3(0, 0.0, 0.68), m_black, m_accent, rec0, "TRIO")


func _build_assemblage(lineage: Dictionary, mono: bool, m_black: Material, m_white: Material, m_slate: Material, m_accent: Material) -> void:
	# True architectural hybrid assemblage: open Bauhaus measuring frame joining primary + companion sculptures
	# (plus optional WorkerBeing) with horizontal datum rods in a clear triangular composition.
	var rec0: Dictionary = _active_recipe(0)
	var rec1: Dictionary = _active_recipe(1)
	var deck_y: float = 0.124 if show_plinth else 0.0
	var frame_w: float = 1.52
	var frame_h: float = 2.30

	if show_plinth:
		_plinth_pad(_built_root, "AssemblagePlinth", Vector3.ZERO, Vector2(1.66, 1.66), 0.12, m_black, m_white, m_accent)

	# Open matte-black Bauhaus spatial measuring cage (4 slender stiles + top perimeter lintel).
	_build_measuring_frame(_built_root, Vector3(0, deck_y, 0), frame_w, frame_h, m_black, m_slate, m_accent)

	# Clear triangular gallery composition so every figure has an unobstructed silhouette from front & side!
	var sc0 := _spawn_sculpture(_built_root, rec0, Vector3(0.36, deck_y, 0.04), deg_to_rad(-18.0), target_height * 1.00, mono)
	sc0.name = "PrimarySculpture"
	var sc1 := _spawn_sculpture(_built_root, rec1, Vector3(-0.14, deck_y, -0.34), deg_to_rad(22.0), target_height * 0.92, mono)
	sc1.name = "SecondarySculpture"

	if include_worker:
		_spawn_worker(_built_root, str(lineage.stage), Vector3(-0.34, deck_y, 0.32), deg_to_rad(18.0), mono)

	# Subtle matte-black architectural coupling bars bridging the joined forms inside the cage.
	_box(_built_root, "CouplingBarLow", Vector3(0.08, deck_y + 0.96, -0.15), Vector3(0.68, 0.018, 0.018), m_black, false)
	_box(_built_root, "CouplingBarHigh", Vector3(0.08, deck_y + 1.54, -0.15), Vector3(0.58, 0.014, 0.014), m_accent, false)

	_add_plaque(_built_root, Vector3(0, deck_y + 0.006, 0.70),
		custom_title if not custom_title.is_empty() else ("ASSEMBLAGE · %s + %s" % [Catalog.figure_title(str(rec0.figure)), Catalog.figure_title(str(rec1.figure))]),
		"%s · %s" % [str(lineage.code), _axis_summary(rec0)])
	if interactive:
		_build_plinth_controls(_built_root, Vector3(0, 0.0, 0.98), m_black, m_accent, rec0, "ASSEMBLAGE")


func _build_workbench_arc(lineage: Dictionary, mono: bool, m_black: Material, m_white: Material, m_slate: Material, m_accent: Material) -> void:
	# Purpose-built Studio Workbench companion anchored at PlaygroundWorkUnit (-1.58, 0, 0.02):
	# Fits 100% INSIDE the 6.6 m workstation safety footprint (zero new corridor encroachment!).
	#   - Local (0, 0, 0): Unit 02 (WorkerBeing) standing right beside the console's left edge.
	#   - Local (-0.90, 0, -0.34): Endless Museum Dream-Body Form Study Plinth tucked cleanly in the left studio pocket!
	#   - In "assemblage" submode: adds open Bauhaus measuring cage + interlocking secondary museum body on the left plinth.
	#   - In "trio" submode: adds a symmetric companion Dream-Body plinth in the right studio pocket (+3.96, 0, -0.34)!
	var rec0: Dictionary = _active_recipe(0)
	var rec1: Dictionary = _active_recipe(1)

	# 1. Unit 02 Stance Pad + WorkerBeing (local origin, facing console & visitor).
	var unit_node := Node3D.new()
	unit_node.name = "Unit02Pad"
	unit_node.rotation.y = deg_to_rad(28.0)
	_built_root.add_child(unit_node)
	_plinth_pad(unit_node, "WorkerPad", Vector3.ZERO, Vector2(0.76, 0.76), 0.028, m_black, m_white, m_accent)
	_add_plaque(unit_node, Vector3(0, 0.032, 0.29), "UNIT 02", "PLAYGROUND ARCHITECT")
	_spawn_worker(unit_node, str(lineage.stage), Vector3(0, 0.030, -0.02), 0.0, mono)

	# 2. Endless Museum Sculpture Form Plinth in the left studio pocket.
	var left_pocket := Node3D.new()
	left_pocket.name = "MuseumFormPlinth"
	left_pocket.position = Vector3(-0.92, 0.0, -0.36)
	left_pocket.rotation.y = deg_to_rad(36.0)
	_built_root.add_child(left_pocket)

	var pad_size: Vector2 = Vector2(1.06, 1.06) if _workbench_submode == "assemblage" else Vector2(0.90, 0.90)
	var pad_h: float = 0.088
	_plinth_pad(left_pocket, "SculpturePad", Vector3.ZERO, pad_size, pad_h, m_black, m_white, m_accent)

	# Crisp matte-black floor datum link connecting Unit 02 to its Endless Museum sculptural ancestor!
	var link := _box(_built_root, "LineageLink", Vector3(-0.46, 0.008, -0.18), Vector3(0.68, 0.008, 0.032), m_black, false)
	link.rotation.y = deg_to_rad(-21.0)

	if _workbench_submode == "assemblage":
		_build_measuring_frame(left_pocket, Vector3(0, pad_h, 0), 0.96, 2.18, m_black, m_slate, m_accent)
		var sc0 := _spawn_sculpture(left_pocket, rec0, Vector3(0.10, pad_h, 0.02), deg_to_rad(-14.0), target_height * 0.96, mono)
		sc0.name = "PrimarySculpture"
		var sc1 := _spawn_sculpture(left_pocket, rec1, Vector3(-0.18, pad_h, -0.14), deg_to_rad(26.0), target_height * 0.82, mono)
		sc1.name = "SecondarySculpture"
		_box(left_pocket, "AssemblageTie", Vector3(-0.04, pad_h + 1.08, -0.06), Vector3(0.46, 0.016, 0.016), m_accent, false)
	else:
		var sc0 := _spawn_sculpture(left_pocket, rec0, Vector3(0, pad_h, -0.02), 0.0, target_height * 0.96, mono)
		sc0.name = "PrimarySculpture"

	_add_plaque(left_pocket, Vector3(0, pad_h + 0.005, pad_size.y * 0.40),
		Catalog.figure_title(str(rec0.figure)),
		"%s · %s" % [str(lineage.code), _axis_summary(rec0)])

	if interactive:
		_build_plinth_controls(left_pocket, Vector3(-0.22, 0.0, pad_size.y * 0.5 + 0.16), m_black, m_accent, rec0, _workbench_submode.to_upper())

	# 3. In "trio" submode, mirror a second Dream-Body Form Study cleanly into the right studio pocket (+2.38 in workstation space).
	if _workbench_submode == "trio":
		var right_pocket := Node3D.new()
		right_pocket.name = "MuseumCompanionPlinth"
		right_pocket.position = Vector3(3.96, 0.0, -0.36)
		right_pocket.rotation.y = deg_to_rad(-36.0)
		_built_root.add_child(right_pocket)
		_plinth_pad(right_pocket, "CompanionPad", Vector3.ZERO, Vector2(0.88, 0.88), 0.084, m_black, m_white, m_accent)
		var sc1 := _spawn_sculpture(right_pocket, rec1, Vector3(0, 0.088, -0.02), 0.0, target_height * 0.94, mono)
		sc1.name = "SecondarySculpture"
		_add_plaque(right_pocket, Vector3(0, 0.092, 0.35),
			Catalog.figure_title(str(rec1.figure)),
			str(rec1.get("role", "COMPANION FORM")))


func _build_measuring_frame(parent: Node3D, base: Vector3, width: float, height: float, m_black: Material, m_slate: Material, m_accent: Material) -> void:
	var h: float = width * 0.5
	for sx in [-h, h]:
		for sz in [-h, h]:
			_box(parent, "FramePost", base + Vector3(sx, height * 0.5, sz), Vector3(0.028, height, 0.028), m_black, false)
			_box(parent, "FrameShoe", base + Vector3(sx, 0.016, sz), Vector3(0.064, 0.032, 0.064), m_slate, false)
	for side in [-h, h]:
		_box(parent, "FrameTopX", base + Vector3(0, height, side), Vector3(width + 0.028, 0.028, 0.028), m_black, false)
		_box(parent, "FrameTopZ", base + Vector3(side, height, 0), Vector3(0.028, 0.028, width + 0.028), m_black, false)
	# Crisp top front accent bar matching the Studio Workstation header trim.
	_box(parent, "FrameAccent", base + Vector3(0, height + 0.018, h), Vector3(width + 0.032, 0.012, 0.034), m_accent, false)


func _build_plinth_controls(parent: Node3D, at: Vector3, m_black: Material, m_accent: Material, rec: Dictionary, mode_label: String) -> void:
	_controls_root = Node3D.new()
	_controls_root.name = "AssemblageControls"
	_controls_root.position = at
	parent.add_child(_controls_root)

	# Low waist-angled Bauhaus architectural plinth lectern (compact, tactile, unobstructed sightlines).
	_box(_controls_root, "PedestalLeg", Vector3(0, 0.34, 0), Vector3(0.10, 0.68, 0.10), m_black, true)
	_box(_controls_root, "PedestalFoot", Vector3(0, 0.018, 0), Vector3(0.32, 0.036, 0.24), m_black, false)

	var head := Node3D.new()
	head.name = "ControlDeck"
	head.position = Vector3(0, 0.72, 0.02)
	head.rotation.x = deg_to_rad(26.0)
	_controls_root.add_child(head)

	_box(head, "DeckPlate", Vector3(0, 0, 0), Vector3(0.76, 0.034, 0.28), m_black, false)
	_box(head, "DeckTrim", Vector3(0, 0.019, -0.128), Vector3(0.74, 0.008, 0.014), m_accent, false)

	_label(head, "MUSEUM FORM · %s" % Catalog.figure_title(str(rec.figure)),
		Vector3(0, 0.022, -0.088), Vector3(-90, 0, 0), 15, 0.00175, Color("ffffff"))

	_btn_form_lbl = _add_control_button(head, "Form", "FORM", Vector3(-0.24, 0.022, 0.03), Color("ededeb"), func(): cycle_figure(1))
	_btn_axis_lbl = _add_control_button(head, "Axis", "AXIS", Vector3(0.0, 0.022, 0.03), Color("cfd4d8"), func(): cycle_axis())
	_btn_mode_lbl = _add_control_button(head, "Mode", mode_label, Vector3(0.24, 0.022, 0.03), Catalog.accent_for_palette(palette_id, is_monochrome()) if not is_monochrome() else Color("9da3ab"), func(): cycle_formation())


func _add_control_button(parent: Node3D, id: String, words: String, at: Vector3, colour: Color, action: Callable) -> Label3D:
	var btn: Node3D = Furniture.rectangular_button(ButtonScene)
	btn.name = "AssemblageBtn_" + id
	btn.rotation = Vector3.ZERO
	btn.position = at + Vector3(0, 0.008, -0.015)
	btn.scale = Vector3.ONE * 0.86
	btn.released_color = colour
	btn.pressed.connect(action)
	parent.add_child(btn)
	return _label(parent, words, at + Vector3(0, 0.006, 0.068), Vector3(-90, 0, 0), 14, 0.00175, Color("ededeb"))


func _spawn_worker(parent: Node3D, stage_name: String, at: Vector3, yaw: float, mono: bool) -> Node3D:
	var being := Node3D.new()
	being.name = "WorkerBeing"
	being.set_script(WorkerBeingScript)
	being.set("stage", stage_name)
	being.set("seed", sculpture_seed if sculpture_seed > 0 else 13)
	being.set("motion", worker_motion)
	being.position = at
	being.rotation.y = yaw
	parent.add_child(being)
	if mono:
		Catalog.apply_monochrome_pass(being)
	return being


func _spawn_sculpture(parent: Node3D, rec: Dictionary, at: Vector3, yaw: float, h: float, mono: bool) -> Node3D:
	var fig: String = str(rec.get("figure", "stijl_robot"))
	var sd: int = int(rec.get("seed", 7))
	var opts: Dictionary = (rec.get("opts", {}) as Dictionary) if rec.get("opts") is Dictionary else {}
	var sc := Catalog.build_sculpture(fig, sd, opts, h, mono)
	sc.position = at
	sc.rotation.y = yaw
	parent.add_child(sc)
	return sc


func _plinth_pad(parent: Node3D, tag: String, at: Vector3, size: Vector2, h: float, m_black: Material, m_white: Material, m_accent: Material) -> void:
	_box(parent, tag + "_Base", at + Vector3(0, h * 0.5, 0), Vector3(size.x, h, size.y), m_black, true)
	_box(parent, tag + "_Top", at + Vector3(0, h + 0.003, 0), Vector3(size.x - 0.10, 0.006, size.y - 0.10), m_white, false)
	_box(parent, tag + "_Accent", at + Vector3(0, h - 0.006, size.y * 0.5 + 0.004), Vector3(size.x, 0.016, 0.010), m_accent, false)


func _add_plaque(parent: Node3D, at: Vector3, title_txt: String, sub_txt: String) -> void:
	_plaque_title = _label(parent, title_txt, at, Vector3(-90, 0, 0), 13, 0.00155, Color("131519"))
	_plaque_sub = _label(parent, sub_txt, at + Vector3(0, 0, 0.055), Vector3(-90, 0, 0), 10, 0.0013, Color("48505a"))


func _flat_mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _box(parent: Node3D, n: String, pos: Vector3, dims: Vector3, mat: Material, solid: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	var bm := BoxMesh.new()
	bm.size = dims
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		body.name = n + "_Col"
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = dims
		shape.shape = box
		body.add_child(shape)
		mi.add_child(body)
	return mi


func _label(parent: Node3D, text: String, pos: Vector3, rot_deg: Vector3, size: int, pixel: float, colour: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.rotation_degrees = rot_deg
	l.font_size = size
	l.pixel_size = pixel
	l.modulate = colour
	l.outline_size = 0
	l.no_depth_test = false
	parent.add_child(l)
	return l
