extends Node3D
class_name DreamBodies

## THE DREAM BODIES (2026-08-29, Palle: "any chance you can recreate some of
## these bodies in godot?" — AI-generated panoramas of sculptural groups from
## his Stable Diffusion runs: glazed Rocaille figurines with patterned skins,
## two families of De Stijl robots, a Frank Stella wall tangle, pastel ceramic
## dragons, and three from one sea-life prompt — striding monochrome creatures,
## pebble-scaled reef bodies sprouting branching coral, and a knot of winding
## tubes with spotted eels in it).
##
## One artifact, one DNA axis: `figure` picks which body the plinth carries,
## and `seed` picks which individual — every builder draws its proportions,
## lean and palette from a seeded generator, so a seed IS a statue and the same
## seed is the same statue on every machine. Each builder is its own file under
## bodies/, holds nothing but static functions, and reproduces the reference's
## shape language with primitives and SurfaceTool alone: no meshes from disk,
## no shaders, patterns painted into ImageTextures in code.
##
## A dream body is a statue. It has no collider of its own beyond the plinth
## the museum gives it; it is looked at.

const BODY_DIR := "res://commons/artifacts/dream_bodies/bodies/"
const FIGURES: Array[String] = ["asawa_wire", "bacon_smear", "batik_beast", "botanic_mannequin", "brass_stamen",
	"ceramic_puppet", "clay_splash", "coral_polyp", "couch_lounge", "couture_beast",
	"crackle_peak", "crystal_suit", "david_drape", "deity_figurine", "dotted_colossus",
	"dragon", "dubuffet", "fetish_idol", "food_table", "garet_still", "gehry_metal",
	"griffin_plume", "hadid_shell", "hicks_fiber", "hokusai_kimono", "horse_hybrid",
	"kruger_suit", "lava_bloom", "lilac_quarry", "mannerist_tumble", "masked_dancer",
	"mosaic_body", "nana_gloss", "obi_frieze", "oni_dragon", "paik_light",
	"painted_chorus", "panel_robot", "panton_pop", "pierced_screen", "pink_scaffold",
	"piped_icing", "porcelain_doll", "print_inflatable", "rocaille", "sea_forms",
	"stella_wall", "stijl_robot", "tatlin_red", "tube_reef", "type_wrap", "vasarely_beast"]

@export_enum("asawa_wire", "bacon_smear", "batik_beast", "botanic_mannequin", "brass_stamen",
	"ceramic_puppet", "clay_splash", "coral_polyp", "couch_lounge", "couture_beast",
	"crackle_peak", "crystal_suit", "david_drape", "deity_figurine", "dotted_colossus",
	"dragon", "dubuffet", "fetish_idol", "food_table", "garet_still", "gehry_metal",
	"griffin_plume", "hadid_shell", "hicks_fiber", "hokusai_kimono", "horse_hybrid",
	"kruger_suit", "lava_bloom", "lilac_quarry", "mannerist_tumble", "masked_dancer",
	"mosaic_body", "nana_gloss", "obi_frieze", "oni_dragon", "paik_light",
	"painted_chorus", "panel_robot", "panton_pop", "pierced_screen", "pink_scaffold",
	"piped_icing", "porcelain_doll", "print_inflatable", "rocaille", "sea_forms",
	"stella_wall", "stijl_robot", "tatlin_red", "tube_reef", "type_wrap", "vasarely_beast") var figure: String = "rocaille"
@export var seed: int = 1

var _built_figure: String = ""
var _built_seed: int = -1
## Anything a map hands over that is not `figure` or `seed` — a family's own axis
## value, passed through to its builder.
var _opts: Dictionary = {}


func apply_grid_config(config: Dictionary) -> void:
	if config.has("figure"):
		# str(), not String(): String() THROWS on a Dictionary or Array cell, and a
		# map token is JSON, so it can hand this anything. str() lets a wrong-typed
		# value fall through to the else below and be NAMED instead of crashing.
		var f := str(config.get("figure", "")).to_lower()
		if FIGURES.has(f):
			figure = f
		else:
			# A SILENT DECLINE HERE IS THIS PROJECT'S WORST FAILURE CLASS. Until
			# 2026-09-03 this guard had no else, so an unknown name simply left
			# `figure` at its default: the museum stood a rocaille where the plan
			# said fetish_idol, the hall looked finished, and the plan, the bake,
			# the inventory and the wall text all went on naming a body that no
			# visitor would ever see. Five builders (botanic_mannequin, clay_splash,
			# deity_figurine, fetish_idol, type_wrap) were unreachable that way for
			# as long as FIGURES was transcribed by hand instead of generated.
			push_warning(("[dream_bodies] REJECTED figure \"%s\" — not one of the %d names in " +
				"FIGURES; building \"%s\" instead. If %s%s.gd exists on disk, FIGURES is stale: " +
				"re-run tools/dream_bodies_promote.py, which writes it from that directory.")
				% [f, FIGURES.size(), figure, BODY_DIR, f])
	if config.has("seed"):
		seed = int(config.get("seed", 1))
	for k in config:
		var key := String(k)
		if key != "figure" and key != "seed":
			_opts[key] = config[k]
	if is_inside_tree():
		_built_figure = ""      # opts may have changed under an unchanged figure
		_build()


## Once per process, not once per statue: the endless museum stands one of these in
## every hall, so an unguarded check would be ~200 directory listings for one answer.
static var _disk_checked: bool = false


## THE GATE THAT STOPS THE NEXT FAMILY ARRIVING INVISIBLE.
##
## FIGURES is generated from this same directory by tools/dream_bodies_promote.py,
## but generation only helps if somebody RUNS it. When it has not been run, nothing
## downstream complains: the builder sits on disk, no map token can name it (the
## guard above declines it), and every stage reports success. That is how five
## builders lived unreachable. One directory listing at startup, and the drift has
## to say its own name.
static func _check_disk() -> void:
	if _disk_checked:
		return
	_disk_checked = true
	var on_disk := PackedStringArray()
	for f in DirAccess.get_files_at(BODY_DIR):
		var n := str(f)
		# An EXPORTED build serves scripts as "<name>.gd.remap" (or .uid siblings),
		# so match on the real script stem rather than a literal ".gd" suffix — the
		# check must not turn into 42 false accusations the moment we ship a pck.
		if n.ends_with(".remap"):
			n = n.get_basename()
		if n.ends_with(".gd"):
			on_disk.append(n.get_basename())
	if on_disk.is_empty():
		# Say the check could not RUN, rather than reporting all 42 names missing.
		# A gate that cannot see is a different fact from a gate that sees a fault.
		push_warning("[dream_bodies] cannot verify FIGURES: %s listed no builder scripts" % BODY_DIR)
		return
	var unlisted := PackedStringArray()
	for n in on_disk:
		if not FIGURES.has(n):
			unlisted.append(n)
	var absent := PackedStringArray()
	for n in FIGURES:
		if not on_disk.has(n):
			absent.append(n)
	if not unlisted.is_empty():
		push_warning(("[dream_bodies] %d builder(s) on disk that FIGURES does not name, so no map " +
			"token can reach them: %s — re-run tools/dream_bodies_promote.py, which writes FIGURES " +
			"and the @export_enum from %s") % [unlisted.size(), ", ".join(unlisted), BODY_DIR])
	if not absent.is_empty():
		push_warning(("[dream_bodies] %d name(s) in FIGURES with no builder file in %s: %s — a map " +
			"asking for one is accepted by the guard and then leaves an EMPTY plinth")
			% [absent.size(), BODY_DIR, ", ".join(absent)])


func _ready() -> void:
	_check_disk()
	_build()


## The sentence the builder gives for itself, for a card or a caption.
static func describe(fig: String) -> String:
	var s: Script = load(BODY_DIR + fig + ".gd") as Script
	if s == null or not s.has_method("describe"):
		return ""
	return String(s.call("describe"))


func _build() -> void:
	if _built_figure == figure and _built_seed == seed:
		return
	for c in get_children():
		c.queue_free()
	var path: String = BODY_DIR + figure + ".gd"
	if not ResourceLoader.exists(path):
		push_warning("[dream_bodies] no builder for %s" % figure)
		return
	var s: Script = load(path) as Script
	if s == null or not s.has_method("build"):
		push_warning("[dream_bodies] %s has no build()" % figure)
		return
	var root := Node3D.new()
	root.name = "Body_" + figure
	add_child(root)
	# A BUILDER MAY TAKE OPTS NOW. Every family declares its own axes (axes(), swept
	# through commons/artifacts/dream_bodies/figures/<key>.tscn), and its build takes
	# a third argument for them. This artifact carries no axis of its own, so it asks
	# how many arguments the builder wants rather than assuming: a two-argument
	# builder called with three fails at runtime, and silently leaves an empty plinth.
	var argc: int = 2
	for m in s.get_script_method_list():
		if String(m.get("name", "")) == "build":
			argc = (m.get("args", []) as Array).size()
	if argc >= 3:
		s.call("build", root, seed, _opts)
	else:
		s.call("build", root, seed)
	_built_figure = figure
	_built_seed = seed
