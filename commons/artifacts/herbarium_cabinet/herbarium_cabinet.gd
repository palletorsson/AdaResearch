extends Node3D
class_name HerbariumCabinet

# @identity
# essence: ten real botanical_flower specimens standing in one body, arranged and dressed by
#   the exhibits family's `house` — six different claims about what a collection IS, made with
#   the same ten plants. white_cube keeps three on separate plinths and drops seven; wunderkammer
#   crowds all ten on ranked shelves behind old glass; depot racks them in accession order on raw
#   ply and stencils the shelf, not the plants; forensic PRESSES all ten flat against a steel
#   panel with a tick-rule measured off each specimen's own height; didactic captions every one;
#   derelict leans them over in a dusty case nobody has come back for.
# desire: to put the cross-member argument of two promotions on one plinth — that a species is a
#   claim about what a flower is, and a house is a claim about what knowledge is, and a collection
#   is where the two meet and one of them wins.
# critical_parameter: house — it decides the roster, the arrangement, the dressing and the light,
#   because in a collection those are not four decisions but one.
# triggers: _ready builds; apply_grid_config({house} or {regard}) rebuilds only on a validated
#   value that actually differs.
# emerges: the specimens never change and the collection is never the same twice. The white cube's
#   three are unarguable flowers and its absences are the argument; the depot's ten are stock; the
#   forensic ten are records of plants rather than plants.
# needs: botanical_flower's scene [instanced, ten at most], exhibit_furniture's HOUSES palette and
#   house_name() [read live, never copied], BakedText for the one plate each house wears.
# truth: a collection is a claim about its members, and the members do not get a vote.

# ═══════════════════════════════════════════════════════════════════════════
# SYNTHESIS (2026-08-06). Sources: [[botanical_flower]] and [[exhibit_furniture]].
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT THE TWO SOURCES LEARNED, and why they compose.
#
# botanical_flower found ten full 25-key parameter sets sitting unreachable in
# BotanicalFlower.PRESETS — nine real Swedish wildflowers plus the unnamed
# parametric default — because the wrapper assigned `preset` AFTER the generator
# had already built. Nine species in the source tree that no player had ever met.
# Its promotion's second lesson is the sharper one: the first pass declared six of
# the nine, dropping three for sitting "close to values already in it", and the
# three it dropped were fritillaria (the only chequered skin), orchid (the only
# form addressed to a pollinator rather than a viewer) and clover (the only member
# most people would not call a flower). Distance in parameter space is not the
# axis. All ten stand here for that reason.
#
# exhibit_furniture found that its one look — warm off-white matte, anthracite
# trim, across 1077 placements — was not neutrality but the white cube, and gave
# the family `house`: whose attention the furniture belongs to.
#
# The composition is not decoration, because each source's claim is INCOMPLETE
# without the other's object. botanical_flower's `house`-less specimens each argue
# alone and can only be met one at a time; exhibit_furniture's houses are all
# EMPTY ("all empty; all waiting" — its own essence line), so the axis argues about
# hosting with nothing hosted. Put the ten in the six and a third thing appears
# that neither source can state: the same ten members, unchanged, are a different
# collection in each house — and in one of them, seven of them are not members at
# all.
#
# ── THE VALUE LIST, and why it is six and not four ──────────────────────────
#
# The commission named four houses (white_cube · wunderkammer · depot · forensic).
# The family's list is SIX: exhibit_furniture's convergence pass widened it on
# 2026-07-27 when exhibit_podium arrived carrying `regard` with two registers the
# senior list lacked, and recorded that "widening beat squeezing them into forensic
# and depot". Shipping four here would re-open exactly the collision that pass
# closed, and it would repeat botanical_flower's own corrected mistake in the same
# session that credits it: dropping values for being near their neighbours.
#
# They are also the two registers a HERBARIUM argues hardest about:
#   didactic  — the teaching museum that captions everything. A herbarium sheet is
#               a didactic object by construction: a plant that has been turned
#               into a label with a plant attached.
#   derelict  — the register withdrawn. A herbarium is already a collection of dead
#               things kept because somebody decided they mattered; derelict is the
#               state where nobody does any more, and the specimens do not notice.
# So: all six, character for character, parsed through the family's own
# house_name() so #house: and #regard: and the old spellings (plain, reliquary)
# reach this artifact exactly as they reach the other two.
#
# ── WHAT IS READ RATHER THAN COPIED ─────────────────────────────────────────
#
# The slot_machine rule (a sibling's table is preloaded, never transcribed) applies
# three times here, because a synthesis that copies its sources' vocabularies is a
# fourth place for them to drift:
#   * the roster comes from BotanicalFlowerArtifact.SPECIES — the axis's own list;
#   * every specimen's height comes from BotanicalFlower.PRESETS / DEFAULT_CONFIG,
#     so the shelves rank themselves and a change upstream re-ranks them;
#   * every surface comes from ExhibitFurniture.HOUSES at runtime. This cabinet
#     owns no colour. Repaint wunderkammer in the family and the herbarium is
#     repainted with it.
#
# ── DETERMINISM, checked rather than assumed ────────────────────────────────
#
# BotanicalFlower.build() opens `rng.seed = c.seed as int`; `seed` is 0 in
# DEFAULT_CONFIG and NOT set by any of the nine presets, and neither the wrapper
# nor this cabinet ever writes it. Every rng.randf_range in the generator is drawn
# from that one seeded stream in build order, so a species is the same object every
# run and the six frames differ only by the axis. No seed fixture is needed and
# none is declared. The one way to break this is a map override of `seed`, which
# the wrapper's apply_grid_config does not forward — so it cannot happen by
# accident. This cabinet's own arrangement uses no randomness at all: the derelict
# lean angles are a fixed table, not a draw.
#
# ── DECLINED: `guard`, the family's second axis ─────────────────────────────
#
# exhibit_furniture crosses `house` with `guard` (none < label < fixture < frame <
# hood < cordon: how far back the institution keeps you). It is refused here, and
# not for lack of geometry. A cabinet IS apparatus. Every value of `house` already
# sets this artifact's distance — the white cube has no case at all, wunderkammer
# and didactic and derelict glaze, the depot leaves the rack open, forensic mounts
# the specimens on a bare panel and rules them — so `guard` would put a second
# barrier around a barrier and the sweep would measure the same pixels twice under
# two names. That is the collision botanical_flower declined its own second axis
# to avoid ("every one of them is SET BY the presets, so a second axis would fight
# the first"). One axis, and the refusal on the record.

const FLOWER_SCENE := preload("res://commons/artifacts/botanical_flower/botanical_flower.tscn")
const FLOWER_WRAPPER := preload("res://commons/artifacts/botanical_flower/botanical_flower.gd")
const FLOWER_GEN := preload("res://commons/flora/botanical_flower.gd")
const FURNITURE := preload("res://commons/artifacts/exhibits/exhibit_furniture.gd")
const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

## THE AXIS — which institution this collection belongs to. Six values, the exhibits
## family's list character for character (see the header). Kept on ONE line: the
## declaration gate reads the export hint with a line-oriented parser, and a
## parenthesised continuation is valid GDScript it cannot see.
@export_enum("white_cube", "wunderkammer", "depot", "forensic", "didactic", "derelict") var house: String = "wunderkammer"

## Cabinet envelope. Every house builds inside the same width and depth on purpose:
## the sweep's camera fits the UNION of all six boxes, so letting one value sprawl
## would shrink the other five in frame and the axis would read as a size change.
const WIDTH := 1.60
const DEPTH := 0.52
const SHELF_T := 0.035
const CASE_BASE := 0.40      # a cased collection stands on a plinth
const RACK_BASE := 0.22      # a rack does not
const POST_TOP := 2.05       # full-height uprights, so the depot's envelope matches a case's

## The white cube's edit. A curatorial CHOICE, not a measurement, so it is written down
## rather than derived: these are the three that need no caption. What it drops is the
## argument — clover (the member most people would not call a flower), fritillaria and
## orchid (the two the source's own first pass wrongly cut), and `generic`, the unnamed
## parametric flower, which the white cube cannot show at all because its whole apparatus
## is the singular named work. Intersected with the live roster, so a species leaving the
## source shrinks this list instead of stranding a name.
const WHITE_CUBE_KEEP := ["iris", "daisy", "crown_imperial"]

## Derelict lean, in degrees about Z, one per shelf position. A fixed table rather than a
## draw: five variants of a randomised collapse would be five collections, and the critic
## would measure the RNG. Capped at 34 deg — past that a 0.5 m specimen sweeps out of its
## own bay and the picture reads as a bug rather than as neglect.
const DERELICT_LEAN := [0.0, 12.0, -27.0, 5.0, -8.0, 31.0, -19.0, 0.0, 24.0, -34.0]

var _built := false


func _ready() -> void:
	_build()
	_built = true


## Rebuild only on a validated value that actually differs, and never before _ready has
## built once — the force_pad trap, which tore down every child on any call including ones
## naming nothing it owned. #regard: is exhibit_podium's spelling of the same axis and is
## honoured here for the same reason the other two members honour it.
func apply_grid_config(config_data: Dictionary) -> void:
	if not _built:
		return
	var want: String = house
	if config_data.has("house"):
		want = str(FURNITURE.house_name(str(config_data["house"])))
	elif config_data.has("regard"):
		want = str(FURNITURE.house_name(str(config_data["regard"])))
	var houses: Dictionary = FURNITURE.HOUSES
	if not houses.has(want):
		return
	if want == house:
		return
	house = want
	_rebuild()


func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


# ── the roster, read from the source rather than retyped ─────────────────────

## The ten species, in the order [[botanical_flower]] declares them. `generic` first: it is
## not the absence of a species but the position that a flower can be specified without
## being named, which is why the didactic and depot orders below both begin with it.
func _roster() -> Array:
	var out: Array = []
	for n in FLOWER_WRAPPER.SPECIES:
		out.append(str(n))
	return out


## A species' stem height, from the generator's own tables. PRESETS first, DEFAULT_CONFIG
## for `generic`, which has no preset (its preset name is the empty string, which is
## exactly what makes the generator build from defaults).
func _stem_height(name_: String) -> float:
	var defaults: Dictionary = FLOWER_GEN.DEFAULT_CONFIG
	var h: float = float(defaults.get("stem_height", 0.25))
	var presets: Dictionary = FLOWER_GEN.PRESETS
	if presets.has(name_):
		var p: Dictionary = presets[name_]
		h = float(p.get("stem_height", h))
	return h


## Bay clearance for a species: its stem plus headroom for the head that sits on top.
## Floor of 0.20 so daisy and clover still get a bay a hand can reach into.
func _span(name_: String) -> float:
	return maxf(_stem_height(name_) + 0.10, 0.20)


## Tallest first, ties broken by name so the order is the same every run. An insertion
## sort rather than sort_custom: ten items, and no lambda for the parser to trip on.
func _by_height(names: Array) -> Array:
	var out: Array = names.duplicate()
	for i in range(1, out.size()):
		var key: String = str(out[i])
		var kh: float = _span(key)
		var j: int = i - 1
		while j >= 0:
			var other: String = str(out[j])
			var oh: float = _span(other)
			if oh > kh or (is_equal_approx(oh, kh) and other < key):
				break
			out[j + 1] = out[j]
			j -= 1
		out[j + 1] = key
	return out


## Split a roster into `bays` groups, biggest first — 10 into 4 gives 3,3,2,2. Derived so
## a roster that grows or shrinks upstream still fills the cabinet instead of overflowing.
func _partition(names: Array, bays: int) -> Array:
	var out: Array = []
	var n: int = names.size()
	if bays <= 0:
		return out
	# Float division deliberately: `n / bays` on two ints is the value wanted but raises
	# GDScript's INTEGER_DIVISION warning, and a warning in a synthesis file is one more
	# line the next reader has to decide is harmless.
	var base: int = int(floor(float(n) / float(bays)))
	var rem: int = n - base * bays
	var idx: int = 0
	for i in bays:
		var take: int = base
		if i < rem:
			take += 1
		var g: Array = []
		for _k in take:
			if idx < n:
				g.append(names[idx])
				idx += 1
		out.append(g)
	return out


# ── the house palette, read live from the exhibits family ────────────────────

func _pal() -> Dictionary:
	var houses: Dictionary = FURNITURE.HOUSES
	if houses.has(house):
		var p: Dictionary = houses[house]
		return p
	var fallback: Dictionary = houses["white_cube"]
	return fallback


## A material from a palette slot. The fallbacks are ExhibitFurniture._mat()'s own, so a
## partially specified house degrades to the legacy surface rather than to something
## arbitrary. Slots holding a bare Color (uplight, note) go through _pcolor instead.
func _pm(slot: String) -> StandardMaterial3D:
	var raw: Variant = _pal().get(slot, {})
	var e: Dictionary = {}
	if raw is Dictionary:
		e = raw
	var c: Color = e.get("c", Color(0.8, 0.8, 0.8))
	var r: float = float(e.get("r", 0.6))
	var mt: float = float(e.get("m", 0.0))
	var em: float = float(e.get("e", 0.0))
	return _mat(c, r, em, mt)


func _pcolor(slot: String, fallback: Color) -> Color:
	var v: Variant = _pal().get(slot, fallback)
	if v is Color:
		var c: Color = v
		return c
	return fallback


func _mat(c: Color, rough: float = 0.6, emit: float = 0.0, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if metal > 0.0:
		m.metallic = metal
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m


func _box(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi


# ── the specimen ─────────────────────────────────────────────────────────────

## One real [[botanical_flower]] instance. `species` is written BEFORE add_child, which is
## the family contract and the exact bug that promotion fixed: BotanicalFlower._ready()
## reads its preset and builds once, so a species set afterwards does nothing at all.
##
## `press` scales Z only. At 0.12 the stem keeps its full length and its petals and leaves
## are flattened into the mounting plane — a herbarium press, which is the one operation
## this whole family of objects is named after, and the one the forensic register performs
## on a body: a plant turned into a record of a plant.
func _stand(name_: String, pos: Vector3, lean_deg: float = 0.0, press: float = 1.0) -> Node3D:
	var inst: Node3D = FLOWER_SCENE.instantiate() as Node3D
	if inst == null:
		return null
	inst.set("species", name_)
	inst.position = pos
	if lean_deg != 0.0:
		inst.rotation_degrees = Vector3(0.0, 0.0, lean_deg)
	if press < 1.0:
		inst.scale = Vector3(1.0, 1.0, press)
	add_child(inst)
	return inst


# ── shared cabinet parts ─────────────────────────────────────────────────────

## The case body: plinth, two sides, a back, a cornice, and optionally a glazed front.
## `top_y` is where the uprights stop; the cornice sits on them.
func _shell(top_y: float, glazed: bool) -> void:
	var body: StandardMaterial3D = _pm("body")
	var trim: StandardMaterial3D = _pm("trim")
	var h: float = maxf(top_y - CASE_BASE, 0.2)
	var mid: float = CASE_BASE + h * 0.5
	_box(Vector3(WIDTH, CASE_BASE, DEPTH), Vector3(0, CASE_BASE * 0.5, 0), body)
	for sx in [-1.0, 1.0]:
		_box(Vector3(0.07, h, DEPTH), Vector3(float(sx) * (WIDTH * 0.5 - 0.035), mid, 0), body)
	_box(Vector3(WIDTH - 0.14, h, 0.06), Vector3(0, mid, -DEPTH * 0.5 + 0.03), _pm("wall"))
	_box(Vector3(WIDTH + 0.06, 0.07, DEPTH + 0.06), Vector3(0, top_y + 0.035, 0), _pm("cap"))
	if glazed:
		# The rims are solid so the case still reads as a case in a still — a pure
		# transparent pane is the inert-axis failure this whole loop is written against.
		var gl: MeshInstance3D = _box(Vector3(WIDTH - 0.14, h - 0.02, 0.02),
				Vector3(0, mid, DEPTH * 0.5 - 0.025), _pm("glass"))
		gl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_box(Vector3(0.035, h, 0.035), Vector3(0, mid, DEPTH * 0.5 - 0.02), trim)
		_box(Vector3(WIDTH - 0.14, 0.045, 0.045), Vector3(0, CASE_BASE + 0.02, DEPTH * 0.5 - 0.02), trim)
		_box(Vector3(WIDTH - 0.14, 0.045, 0.045), Vector3(0, top_y - 0.02, DEPTH * 0.5 - 0.02), trim)


## A run of shelves with specimens standing on them. Each bay's height is the tallest
## occupant's own span, so the shelves rank themselves off the generator's tables.
## `align_left` packs from one end (a store fills in the order things arrive); centred
## otherwise. Returns the top of the run.
func _shelf_run(groups: Array, start_y: float, pad: float, pitch: float,
		align_left: bool, tilt_bay: int, lean: bool) -> float:
	var y: float = start_y
	var seat: int = 0
	var shelf_mat: StandardMaterial3D = _pm("shelf")
	for gi in groups.size():
		var g: Array = groups[gi]
		if g.is_empty():
			continue
		var board: MeshInstance3D = _box(Vector3(WIDTH - 0.16, SHELF_T, DEPTH - 0.16),
				Vector3(0, y + SHELF_T * 0.5, 0.01), shelf_mat)
		# The sagging shelf. `slope` carries the specimens with it: a board rotated about Z
		# without moving what stands on it leaves a 3 cm gap at one end, which reads as
		# floating geometry rather than as a shelf that has given way.
		var slope: float = 0.0
		if gi == tilt_bay:
			board.rotation_degrees = Vector3(0.0, 0.0, 2.6)
			slope = tan(deg_to_rad(2.6))
		var top: float = y + SHELF_T
		var n: int = g.size()
		var x0: float = -pitch * float(n - 1) * 0.5
		if align_left:
			x0 = -(WIDTH * 0.5 - 0.16)
		var clear: float = 0.0
		for i in n:
			var nm: String = str(g[i])
			clear = maxf(clear, _span(nm))
			var x: float = x0 + pitch * float(i)
			var tip: float = 0.0
			if lean:
				tip = float(DERELICT_LEAN[seat % DERELICT_LEAN.size()])
				# Edge specimens fall INWARD. Otherwise a 34 deg lean at the end of a bay
				# puts a stem through the side panel, which reads as breakage of the wrong
				# kind — a bug, not an abandonment. A positive rotation about Z carries +Y
				# toward -X, so the LEFT edge needs a negative angle to fall right.
				if x < -0.45:
					tip = -absf(tip)
				elif x > 0.45:
					tip = absf(tip)
			_stand(nm, Vector3(x, top + x * slope, 0.0), tip)
			seat += 1
		y = top + clear + pad
	return y


## The house's horizontal line — a brass base moulding, an orange shipping strap, a cyan
## datum, a grime line at a derelict skirting. One band at a house-specific height is
## enough to tell two houses apart across a room even when the body colours are close.
## white_cube has no band entry, so the legacy lineage wears nothing and this returns.
##
## `front_only` exists because depot's band rides at 0.62 of the height — a strap, not a
## moulding — and a wrapping box at that height would run straight through the specimens
## standing on the middle shelf. A strap is a strap: it crosses the front of the rack.
func _band(top_y: float, front_only: bool = false) -> void:
	var p: Dictionary = _pal()
	if not p.has("band"):
		return
	var raw: Variant = p.get("band", {})
	var e: Dictionary = {}
	if raw is Dictionary:
		e = raw
	var at: float = float(p.get("band_at", 0.5))
	var th: float = minf(float(p.get("band_th", 0.05)), top_y * 0.5)
	var y: float = clampf(top_y * at, th * 0.5, top_y - th * 0.5)
	var c: Color = e.get("c", Color.WHITE)
	var mat: StandardMaterial3D = _mat(c, float(e.get("r", 0.6)),
			float(e.get("e", 0.0)), float(e.get("m", 0.0)))
	if front_only:
		_box(Vector3(WIDTH + 0.02, th, 0.05), Vector3(0, y, DEPTH * 0.5 - 0.01), mat)
		return
	_box(Vector3(WIDTH + 0.02, th, DEPTH + 0.02), Vector3(0, y, 0), mat)


## What this cabinet calls itself, which is the shortest statement of the house's claim.
## Derived from the roster where a number is involved, so none of it is invented.
##   wunderkammer  the learned Latin — hortus siccus, the dry garden
##   depot         a QUANTITY of material, naming no plant: the store inventories the shelf
##   forensic      a numbered range: every specimen is evidence and evidence has an index
##   didactic      the plain word, over ten captions that name every plant underneath
##   derelict      still wearing the store's stencil, because that was the last register
##                 anyone bothered to apply to it
##   white_cube    nothing at all
func _mark_line(roster: Array) -> String:
	match house:
		"wunderkammer":
			return "HORTUS SICCUS"
		"depot", "derelict":
			return "HERB x%d" % roster.size()
		"forensic":
			return "SPECIMENS 1-%d" % roster.size()
		"didactic":
			return "HERBARIUM"
	return ""


## The plate or the stencil. Style comes from the palette — white_cube's is the empty
## string, so it silently wears nothing, exactly as it does in the exhibits family.
func _mark(text: String, pos: Vector3, size: Vector2) -> void:
	if text == "":
		return
	var p: Dictionary = _pal()
	var style: String = str(p.get("mark", ""))
	if style == "":
		return
	var q: MeshInstance3D = null
	if style == "plate":
		q = BakedText.make_panel_mesh(text, _pcolor("mark_bg", Color(0.1, 0.1, 0.12)),
				_pcolor("mark_fg", Color.WHITE), size, 900, false)
	else:
		q = BakedText.make_label_mesh(text, _pcolor("mark_fg", Color(0.16, 0.12, 0.09)),
				size, 900, false)
	if q:
		q.position = pos
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(q)


## The house's own light colour, as geometry-adjacent seasoning rather than as the axis.
## Derelict gets none: the register withdrawn is the one where the building stopped paying
## for light, and that is most of what the value means.
func _house_light(at: Vector3, range_m: float) -> void:
	if house == "derelict":
		return
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.omni_range = range_m
	lamp.light_energy = 0.9
	lamp.light_color = _pcolor("uplight", Color(0.95, 0.95, 1.0))
	add_child(lamp)


# ── the six collections ──────────────────────────────────────────────────────

func _build() -> void:
	var roster: Array = _roster()
	var ranked: Array = _by_height(roster)
	match house:
		"white_cube":
			_build_white_cube(roster)
		"wunderkammer":
			_build_cased(ranked, 3, 0.31, 0.10, -1, false)
		"depot":
			_build_depot(roster)
		"forensic":
			_build_forensic(ranked)
		"didactic":
			_build_didactic(roster)
		"derelict":
			_build_cased(ranked, 3, 0.31, 0.10, 1, true)
		_:
			_build_cased(ranked, 3, 0.31, 0.10, -1, false)


## SELECTION. No case, because the white cube does not have cabinets — it has plinths and
## air. Three specimens on three separate bodies with a metre of nothing between them, and
## seven of the ten simply not here. The absence is the exhibit: this house cannot show the
## chequered one, the one shaped like an insect, the one nobody calls a flower, or the
## unnamed parametric flower at all.
func _build_white_cube(roster: Array) -> void:
	var keep: Array = []
	for n in WHITE_CUBE_KEEP:
		if roster.has(str(n)):
			keep.append(str(n))
	var count: int = maxi(keep.size(), 1)
	# Wide enough that the plinths do not read as one object with three lumps on it. The
	# outer bodies still finish inside the 1.60 envelope every other house builds in.
	var pitch: float = 0.55
	var x0: float = -pitch * float(count - 1) * 0.5
	var body: StandardMaterial3D = _pm("body")
	var cap: StandardMaterial3D = _pm("cap")
	for i in keep.size():
		var x: float = x0 + pitch * float(i)
		_box(Vector3(0.36, 0.95, 0.36), Vector3(x, 0.475, 0), body)
		_box(Vector3(0.41, 0.04, 0.41), Vector3(x, 0.97, 0), cap)
		_stand(str(keep[i]), Vector3(x, 0.99, 0))
	_house_light(Vector3(0, 1.45, 0.35), 2.4)


## CROWDING (wunderkammer) and WITHDRAWAL (derelict) share a body: the same ranked case,
## the same three bays, the same ten specimens. Everything that separates them is the
## palette, the lean and the light — which is the point, because the collection has not
## changed and the institution has.
##
## Ranked shelving is not decoration either: the bays are the height of their tallest
## occupant, read off BotanicalFlower.PRESETS, so the cabinet gets shorter bays as it goes
## up the way a real specimen case does, and the ranking IS the wunderkammer's ordering
## principle — arranged by eye, by size, by wonder, and not by taxonomy.
func _build_cased(ranked: Array, bays: int, pitch: float, pad: float,
		tilt_bay: int, lean: bool) -> void:
	var groups: Array = _partition(ranked, bays)
	var top: float = _shelf_run(groups, CASE_BASE, pad, pitch, false, tilt_bay, lean)
	_shell(top, true)
	_band(top)
	_mark(_mark_line(ranked), Vector3(0, CASE_BASE * 0.52, DEPTH * 0.5 + 0.012), Vector2(0.62, 0.12))
	_house_light(Vector3(0, top * 0.55, 0.05), 2.2)


## INVENTORY. An open rack: four posts to full height, three ply shelves, no back, no
## glass, nothing named. The specimens go in ACCESSION ORDER — the roster's own declaration
## order, the order they arrived — and are packed from the left end, so the right of every
## shelf is empty and the bays are visibly the wrong heights for what stands in them. That
## waste is the argument: a store does not optimise, it stacks, and the object is not art
## yet. The only lettering is the RACK's quantity stencil, which names no plant.
func _build_depot(roster: Array) -> void:
	var groups: Array = _partition(roster, 3)
	var post: StandardMaterial3D = _pm("trim")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(Vector3(0.05, POST_TOP, 0.05),
					Vector3(float(sx) * (WIDTH * 0.5 - 0.03), POST_TOP * 0.5,
							float(sz) * (DEPTH * 0.5 - 0.03)), post)
	_box(Vector3(WIDTH, 0.05, DEPTH), Vector3(0, RACK_BASE - 0.025, 0), _pm("pad"))
	# The rack's top rail — the ply board a store stencils, and the only flat face this
	# house has, because everything else about it is posts and air.
	_box(Vector3(WIDTH, 0.17, 0.04), Vector3(0, POST_TOP - 0.11, DEPTH * 0.5 - 0.02), _pm("wood"))
	var top: float = _shelf_run(groups, RACK_BASE, 0.06, 0.26, true, -1, false)
	_band(POST_TOP, true)
	_mark(_mark_line(roster), Vector3(-0.28, POST_TOP - 0.11, DEPTH * 0.5 + 0.005),
			Vector2(0.52, 0.12))
	_house_light(Vector3(0, top * 0.6, 0.10), 2.2)


## THE RECORD. A brushed steel panel, ten specimens PRESSED flat against it in a 5x2 grid,
## and beside each one a tick rule whose length is that specimen's own measured height. The
## upper row takes the five tallest so nothing overruns the row above it — the grid is
## sorted by the measurement, which is the only ordering this house recognises.
##
## The press (a Z-scale of 0.12, stem length untouched) is the register's whole claim made
## literal: the plant is not on display, a flattened record of the plant is, and the
## flattening is what made it measurable.
func _build_forensic(ranked: Array) -> void:
	var panel_h: float = POST_TOP
	_box(Vector3(WIDTH, panel_h, 0.05), Vector3(0, panel_h * 0.5, -0.20), _pm("body"))
	_box(Vector3(WIDTH + 0.05, 0.05, 0.10), Vector3(0, panel_h - 0.02, -0.20), _pm("metal"))
	_box(Vector3(WIDTH + 0.05, 0.05, 0.10), Vector3(0, 0.02, -0.20), _pm("metal"))
	var datum: StandardMaterial3D = _pm("stud")
	var rows: Array = [1.15, 0.30]
	var cols: int = 5
	var pitch: float = 0.30
	for r in rows.size():
		var base_y: float = float(rows[r])
		_box(Vector3(WIDTH - 0.06, 0.008, 0.012), Vector3(0, base_y, -0.168), datum)
		for i in cols:
			var idx: int = r * cols + i
			if idx >= ranked.size():
				continue
			var nm: String = str(ranked[idx])
			var x: float = -pitch * float(cols - 1) * 0.5 + pitch * float(i)
			_stand(nm, Vector3(x, base_y, -0.155), 0.0, 0.12)
			# The rule: four ticks up this specimen's own stem, so the etched scale is a
			# measurement OF it rather than a graphic applied to the panel.
			var h: float = _stem_height(nm)
			for t in 4:
				var ty: float = base_y + h * (float(t) + 1.0) * 0.25
				_box(Vector3(0.035, 0.006, 0.010), Vector3(x - 0.10, ty, -0.168), datum)
	_mark(_mark_line(ranked), Vector3(0, panel_h - 0.14, -0.166), Vector2(0.66, 0.10))
	_house_light(Vector3(0, 1.20, 0.55), 2.6)


## THE CAPTION. The teaching case: cool civic grey, two even rows of five in curricular
## order (generic first — the flower that can be fully specified without being named), and
## under every single specimen a printed card carrying its species name. Nothing is left
## for the viewer to not know, which is the exact opposite of the white cube's frameless
## silence rather than a softer version of it.
func _build_didactic(roster: Array) -> void:
	var groups: Array = _partition(roster, 2)
	var y: float = CASE_BASE
	var shelf_mat: StandardMaterial3D = _pm("shelf")
	var card_bg: Color = _pcolor("card_bg", Color(0.95, 0.95, 0.94))
	var card_fg: Color = _pcolor("card_fg", Color(0.12, 0.12, 0.14))
	var pitch: float = 0.30
	for gi in groups.size():
		var g: Array = groups[gi]
		if g.is_empty():
			continue
		_box(Vector3(WIDTH - 0.16, SHELF_T, DEPTH - 0.16), Vector3(0, y + SHELF_T * 0.5, 0.01), shelf_mat)
		var top: float = y + SHELF_T
		var n: int = g.size()
		var x0: float = -pitch * float(n - 1) * 0.5
		var clear: float = 0.0
		for i in n:
			var nm: String = str(g[i])
			clear = maxf(clear, _span(nm))
			var x: float = x0 + pitch * float(i)
			_stand(nm, Vector3(x, top, -0.04))
			var card: MeshInstance3D = BakedText.make_panel_mesh(
					nm.replace("_", " ").to_upper(), card_bg, card_fg,
					Vector2(0.26, 0.052), 700, false)
			if card:
				card.position = Vector3(x, top + 0.030, 0.155)
				card.rotation_degrees = Vector3(-34, 0, 0)
				card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				add_child(card)
		y = top + clear + 0.12
	var top_y: float = maxf(y, 1.95)
	_shell(top_y, true)
	_band(top_y)
	_mark(_mark_line(roster), Vector3(0, top_y - 0.13, DEPTH * 0.5 - 0.05), Vector2(0.62, 0.11))
	_house_light(Vector3(0, top_y * 0.55, 0.05), 2.2)
