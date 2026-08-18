class_name EmMultiples
extends RefCounted
# em_multiples.gd — showing one artifact more than once, at different values.
#
#   var plan: Array = EmMultiples.plan(lookup, rel_db, slots_left)
#   for entry in plan:
#       var node := scene.instantiate()
#       EmMultiples.stage(node, entry)          # BEFORE add_child
#       seg.add_child(node)
#
# THE PROBLEM THIS SOLVES. 481 of the 799 spine artifacts declare a DNA axis with
# 2..6 values — they are families, not objects. Every placement in the corpus
# except six request_note tokens in Artist_Readymades takes the default, so a
# walker has met the family's default and nothing else, ever. The museum is the
# one place in the project where the same piece can be shown twice in one room
# without a curator arguing about it, which makes it the natural first home for
# the variant.
#
# A family shown once is a specimen. A family shown three times along a walk, at
# three values of one axis, is an ARGUMENT — the room does the comparing that a
# gallery label would otherwise have to describe. That is the whole intent here.
#
# ── WHAT IT READS ────────────────────────────────────────────────────────────
# commons/data/artifact_relations.json gives `multiples` and `axes` per token.
# The registry's `dna` block gives the two things that decide the SHAPE of the
# showing, and neither is in the relations file:
#
#   dna.default   prose, e.g. "workings=expression - expression turns every gate
#                 on, which is the only state this board could previously be in".
#                 The head before the first ` - ` carries `axis=value` pairs. We
#                 parse ONLY those pairs, and only for an axis we already know,
#                 so the sentence after the dash cannot contaminate the reading.
#                 Measured over the 481: 272 parse to a declared value, 209
#                 declare no `default` field at all, and the rest disagree with
#                 their own axis (which is the check_dna_declarations failure,
#                 and is treated here as "unknown", never as truth).
#   dna.note      prose, and the only place the corpus writes down that an axis
#                 is ORDERED: "oracle < tally < ledger < works < origin",
#                 "head < tail < path < envelope < ensemble", "result -> trace".
#                 See LADDER DETECTION below.
#
# WHEN dna.default IS EMPTY (209 of 481) we do not guess. The plan is capped at
# two copies, the first is placed BARE, and stage() then reads the shipped value
# off the instantiated node — the engine, not the registry, is the authority on
# what an artifact ships as. If the variant would repeat that shipped value,
# stage() swaps to the next candidate rather than putting a twin in the room.
#
# ── THE CORPUS LAW: THE DEFAULT MUST STILL BE THE DEFAULT ────────────────────
# These tokens have up to 1077 live placements. Three guards, in order of how
# much they are trusted:
#   1. The default copy is always in the plan, and it is always FIRST unless the
#      axis is a ladder that starts elsewhere — in which case the walked window
#      is still chosen to contain it (see _window).
#   2. The default copy ships BARE. Its `config` is "" and stage() touches
#      nothing. Even a correct-looking "#workings:expression" is a claim about
#      the registry; an untouched node is a fact about the scene. We take the
#      fact. (`value` still carries the parsed name, for logs and for ordering.)
#   3. stage() validates every non-default value against the node's OWN enum
#      hint before applying it. A value the code does not have is refused and
#      reported, instead of being silently swallowed by a fallback and shipped
#      as a sixteenth identical frame — which is exactly how science_screen
#      published a whole green sweep about a typo.
#
# ── LADDER DETECTION ─────────────────────────────────────────────────────────
# An axis is a LADDER when its values have an order the corpus itself asserts.
# Three sources, all of which must speak in the axis's OWN vocabulary:
#   numeric   every value parses as a number (perspective_blend 0.0/0.5/1.0).
#             Ordered ascending. 21 of the 481 land here.
#   written   some string in the dna block contains a chain joined by `<`, `->`
#             or `→` in which EVERY term is a declared value of this axis. That
#             vocabulary test is the whole filter: it passes "none < numeral <
#             gradation < lattice" and rejects "|a+b| <= |a|+|b|", "config_<key",
#             "distance < 0" and every chain belonging to the artifact's OTHER
#             axis, without a single special case. Chains become edges; the
#             edges are topologically sorted with declared order as the
#             tiebreak, so three separate pairwise notes ("result -> trace",
#             "trace -> longhand", "longhand -> axiom") reassemble into one
#             four-rung ladder. A cycle means the notes contradict each other,
#             and a contradicted order is not an order: not a ladder.
#             `<` is an explicit ordering operator, so one chain is enough.
#             `->` also writes transitions ("all->none"), so a two-term arrow
#             counts only when a second one corroborates it.
#   ordinal   all values are members of one canonical counting or amount scale
#             (none/one/two/three, none/some/half/most/full). Two generic
#             scales only — an artifact-specific vocabulary is not an order
#             just because we can imagine one.
# Measured: the chosen axis is a ladder for 27 of the 481. The other 454 are
# genuinely unordered sets (breach = pierced|opened|severed|husk has no rungs),
# and for those the rule is DEFAULT FIRST: the familiar reading, then the
# variant that argues with it.
#
# ── ORDER REACHES THE WALKER ONLY IF THE HOST PLACES IN PLAN ORDER ───────────
# endless_museum sorts its slots by RANK (heroes, then podiums, then floor),
# which is not the order a body meets them in. A ladder dealt into rank order is
# a ladder shuffled. walk_sort() sorts slots along +z, the direction of travel;
# feed the plan into slots sorted that way or the ordering work above is thrown
# away at the last step.
#
# Nothing here loads a scene, touches the tree, or knows about the museum.

const MAX_COPIES := 3
# a segment that is nothing but one family is a showroom, not a museum: two
# slots stay reserved for other artifacts before a second copy is licensed.
const SLOT_RESERVE := 2
const REGISTRY_DIR := "res://commons/artifacts/registry"
const EMPHASIS := ["lead", "echo", "aside"]
# generic ordered vocabularies. Deliberately short: over-fitting this table to
# one artifact's words invents an order the corpus never claimed.
const ORDINAL_SCALES := [
	["none", "one", "two", "three", "four", "five", "six", "many", "all"],
	["none", "faint", "some", "half", "most", "full", "all"],
]

static var _dna_cache: Dictionary = {}
static var _registry_scanned: bool = false
static var _re_pair: RegEx = null
static var _re_chain: RegEx = null
static var _warned: Dictionary = {}

## ── PUBLIC ───────────────────────────────────────────────────────────────────

## How many copies of `lead` to show, at which values, in the order a walker
## should meet them.
##
## Returns an Array of Dictionaries, at most MAX_COPIES long, never longer than
## the axis has values and never twice the same value. Each entry:
##   value        String  the axis value this copy argues ("" when unknowable)
##   axis         String  the axis being walked ("" when the token has none)
##   emphasis     String  lead | echo | aside — how loudly to stage this copy
##   is_default   bool    true for the one copy that must look exactly as shipped
##   config       String  "#axis:value" to append to a grid token; "" = bare
##   alt          Array   fallback values, in preference order, for stage()
##   rank_hint    int     0 hero / 1 podium / 2 floor — a hint, not a demand
##   ladder       bool    whether the order of this plan is an asserted order
##   why          String  one line, for the log
##
## Never returns an empty Array for slots_available >= 1: a token with no axis,
## no multiples licence or no room for a second copy comes back as a one-entry
## plan whose single copy is the bare default. A host can therefore run every
## artifact through plan() and keep exactly one code path.
## hard_cap: the BUILDING's licence, which overrides MAX_COPIES upward. Three was
## a module constant standing in front of every budget: em_budget derives
## `multiples_allowed` off each museum's own stated mechanism and licenses 8 and
## 16 for the buildings whose whole argument is serial display, and this function
## silently returned 3 for all of them. A serial hang is not wallpaper when the
## building IS a serial hang — MAX_COPIES stays the default for a caller that
## does not know, and a caller that has read the building can raise it.
static func plan(lead: String, rel_db: Dictionary, slots_available: int, dna_in: Dictionary = {},
		hard_cap: int = MAX_COPIES) -> Array:
	if slots_available < 1 or lead == "":
		return []
	var rel: Dictionary = _rel_entry(lead, rel_db)
	var dna: Dictionary = dna_in
	if dna.is_empty():
		dna = registry_dna(lead)
	var axes: Dictionary = {}
	if dna.has("axes") and dna["axes"] is Dictionary:
		axes = dna["axes"]
	elif rel.has("axes") and rel["axes"] is Dictionary:
		axes = rel["axes"]
	if axes.is_empty():
		return [_solo("", "", "no declared axis — a single showing is the whole family")]

	var pick: Dictionary = _choose_axis(axes, dna)
	var axis: String = str(pick["axis"])
	var values: Array = pick["values"]
	var order: Array = pick["order"]
	var is_ladder: bool = bool(pick["ladder"])
	var default_value: String = str(pick["default"])
	var known: bool = default_value != ""

	# THE CAP. Four independent ceilings, and the lowest wins:
	#   MAX_COPIES         three is where a comparison turns into wallpaper
	#   multiples          the licence the relations file grants this token
	#   values.size()      a repeat is not a family, so copies <= distinct values
	#   slots - RESERVE    the room must still hold something else
	# An unknown default drops it to two more (see the header): one bare copy we
	# are sure of, one variant stage() can verify against the node itself.
	var licence: int = int(rel.get("multiples", values.size()))
	var budget: int = slots_available - SLOT_RESERVE
	var cap: int = MAX_COPIES if hard_cap <= 0 else maxi(hard_cap, 1)
	var n: int = mini(mini(cap, licence), mini(values.size(), budget))
	if not known:
		n = mini(n, 2)
	n = maxi(n, 1)
	if n < 2:
		var why_solo: String = "one copy: " + _cap_reason(licence, values.size(), budget)
		return [_solo(axis, default_value, why_solo)]

	var seq: Array = _sequence(order, default_value, known, is_ladder, n)

	# Blank the copy that carries the default. With a known default that is the
	# one entry whose value equals it; with an unknown default it is entry 0,
	# whose planned value is displaced and goes back into the spare pool — so a
	# swap in stage() can still reach it.
	var shown: Array = []
	var defaulted: int = -1
	for i in range(seq.size()):
		var value: String = str(seq[i])
		if known and value == default_value:
			defaulted = i
		shown.append(value)
	if not known and not shown.is_empty():
		defaulted = 0
		shown[0] = ""
	elif known and defaulted < 0 and not shown.is_empty():
		# _sequence guarantees the window contains the default; if it ever does
		# not, the plan is a redesign and gets corrected here rather than shipped.
		defaulted = 0
		shown[0] = default_value

	var spare: Array = []
	for v in order:
		var s: String = str(v)
		if not shown.has(s) and s != default_value:
			spare.append(s)

	var out: Array = []
	for i in range(shown.size()):
		var val: String = str(shown[i])
		var is_def: bool = i == defaulted
		var why: String = ""
		if is_def and known:
			why = "the shipped default (%s=%s), placed bare" % [axis, default_value]
		elif is_def:
			why = "placed bare: dna.default is silent, so only an untouched node is certainly the default"
		elif is_ladder:
			why = "rung %d of the %s ladder" % [i + 1, axis]
		else:
			why = "%s=%s, argued against the default" % [axis, val]
		out.append(_entry(axis, val, is_def, i, is_ladder, spare.duplicate(), why))
	return out


## Configure ONE instantiated copy from its plan entry. Call it BEFORE
## add_child: an export written after the node is in the tree is a default
## wearing a costume — _ready() has already built the default geometry.
##
## Mirrors what GridInteractablesComponent does for a "#axis:value" token, in
## the same order: coerce to the export's type, set the config_<axis> metadata,
## write the property, then queue apply_grid_config for after _ready so an
## artifact that rebuilds on config gets its refresh.
##
## Returns {ok: bool, value: String, why: String}. ok == false means the copy was
## NOT varied and now duplicates something — the host should drop it and deal a
## different artifact into that slot rather than ship a twin.
static func stage(node: Object, entry: Dictionary) -> Dictionary:
	if node == null:
		return {"ok": false, "value": "", "why": "no node"}
	var axis: String = str(entry.get("axis", ""))
	var want: String = str(entry.get("value", ""))
	if bool(entry.get("is_default", false)) or axis == "" or want == "":
		return {"ok": true, "value": "", "why": "bare — untouched, so it ships as it ships"}

	var info: Dictionary = _prop_info(node, axis)
	# THE LIVE DECLARATION GATE. The code's enum, not the registry's list, says
	# what this axis can be. A value outside it would be swallowed by the
	# artifact's own fallback and photographed as the default.
	var code_values: Array = _enum_values(info)
	var shipped: String = ""
	if not info.is_empty():
		shipped = _val_str(node.get(axis))

	var candidates: Array = [want]
	for a in entry.get("alt", []):
		candidates.append(str(a))
	var chosen: String = ""
	var refused: String = ""
	for c in candidates:
		var cand: String = str(c)
		if code_values.size() > 0 and not code_values.has(cand):
			if refused == "":
				refused = cand
			continue
		if shipped != "" and cand == shipped:
			continue
		chosen = cand
		break
	if chosen == "":
		var why: String = "no candidate differs from the shipped `%s`" % shipped
		if refused != "":
			why = "registry value `%s` is not in the code's enum %s" % [refused, str(code_values)]
			_warn_once("em_multiples: %s declares %s=%s, the script's enum is %s — declaration is wrong, not the axis" % [
				str(node.get_meta("artifact_lookup_name", "?")), axis, refused, str(code_values)])
		return {"ok": false, "value": "", "why": why}

	var typed: Variant = _coerce(chosen, info)
	var cfg: Dictionary = {}
	cfg[axis] = typed
	node.set_meta("config_%s" % axis, typed)
	if not info.is_empty():
		node.set(axis, typed)
	if node.has_method("apply_grid_config"):
		node.call_deferred("apply_grid_config", cfg)
	var note: String = "%s=%s" % [axis, chosen]
	if chosen != want:
		note += " (swapped from %s: it was the shipped value)" % want
	return {"ok": true, "value": chosen, "why": note}


## The plan entry as a grid interactables token, so the same decision can be
## written into a map_data.json cell instead of instantiated. The default copy
## comes back BARE, which is the point.
static func token(lookup: String, rotation: int, y_offset: float, entry: Dictionary) -> String:
	var head: String = "%s:%d:%s" % [lookup, rotation, _num_str(y_offset)]
	return head + str(entry.get("config", ""))


## Slots in the order a body meets them: along +z first, then across. The host's
## own slot list is rank-sorted, which scrambles any ladder; sort with this
## before dealing a plan into it. Non-destructive.
static func walk_sort(slots: Array) -> Array:
	var out: Array = slots.duplicate()
	# one key, so the comparator stays a single-line lambda: z dominates, x
	# breaks the tie. 4096 is far past any template width.
	out.sort_custom(func(a, b): return int(a["y"]) * 4096 + int(a["x"]) < int(b["y"]) * 4096 + int(b["x"]))
	return out


## One line for stdout, so a walk can be read back from the log.
static func describe(lead: String, entries: Array) -> String:
	if entries.is_empty():
		return "%s: no plan" % lead
	if entries.size() == 1:
		return "%s x1 (%s)" % [lead, str((entries[0] as Dictionary).get("why", ""))]
	var first: Dictionary = entries[0]
	var parts: PackedStringArray = PackedStringArray()
	for e in entries:
		var d: Dictionary = e
		var v: String = str(d.get("value", ""))
		parts.append("default" if bool(d.get("is_default", false)) else v)
	return "%s x%d on `%s` %s: %s" % [lead, entries.size(), str(first.get("axis", "")),
		"ladder" if bool(first.get("ladder", false)) else "default-first",
		" -> ".join(parts)]


## Hand the module a token -> dna map the host already has, and it will not scan
## the registry itself. The scan is one pass over ~7 MB of JSON; doing it twice
## in one boot is pure waste.
static func prime(dna_by_token: Dictionary) -> void:
	for k in dna_by_token:
		var key: String = str(k)
		if dna_by_token[key] is Dictionary:
			_dna_cache[key] = dna_by_token[key]
	_registry_scanned = true


## The dna block for one token, scanning the registry once on first call.
## Returns {} for a token with no dna — which is not an error, only a token that
## was never promoted.
static func registry_dna(lookup: String) -> Dictionary:
	_ensure_registry()
	var d: Variant = _dna_cache.get(lookup, null)
	if d is Dictionary:
		return d
	return {}


## ── AXIS CHOICE ──────────────────────────────────────────────────────────────

## One axis per token. A walker reading two axes across three copies reads
## neither; the copies have to differ in exactly one thing or the comparison has
## no control. Scored, so the reason is inspectable:
##   +4  ladder            the order itself teaches, which is the best a walk does
##   +2  default is known  we can guarantee the corpus law without guessing
##   +1  three or more values
##   +0.5 per value (to 5) a wider family says more
##   +1  declared first    the registry's first axis is usually the argument
## A first-declared 4-value axis with a known default (6.0) therefore beats a
## second-declared 2-value ladder (5.0), which is the intended order of concerns.
static func _choose_axis(axes: Dictionary, dna: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_score: float = -1.0
	var i: int = 0
	for k in axes:
		var axis: String = str(k)
		var raw: Variant = axes[axis]
		if not (raw is Array) or (raw as Array).size() < 2:
			i += 1
			continue
		var values: Array = []
		for v in (raw as Array):
			var s: String = _val_str(v)
			if not values.has(s):
				values.append(s)
		if values.size() < 2:
			i += 1
			continue
		var lad: Dictionary = _ladder(values, dna)
		var dv: String = _default_for(dna, axis, values)
		var score: float = 0.0
		if bool(lad["ladder"]):
			score += 4.0
		if dv != "":
			score += 2.0
		if values.size() >= 3:
			score += 1.0
		score += 0.5 * float(mini(values.size(), 5))
		if i == 0:
			score += 1.0
		if score > best_score:
			best_score = score
			best = {
				"axis": axis, "values": values, "order": lad["order"],
				"ladder": lad["ladder"], "source": lad["source"], "default": dv,
			}
		i += 1
	if best.is_empty():
		return {"axis": "", "values": [], "order": [], "ladder": false, "source": "none", "default": ""}
	return best


## ── LADDER ───────────────────────────────────────────────────────────────────

## {ladder: bool, order: Array[String], source: String}. `order` is always a
## full permutation of `values` — declared order when there is no ladder, so
## callers never need to branch on it.
static func _ladder(values: Array, dna: Dictionary) -> Dictionary:
	var numeric: bool = true
	for v in values:
		if not str(v).is_valid_float():
			numeric = false
			break
	if numeric:
		var nums: Array = values.duplicate()
		nums.sort_custom(func(a, b): return str(a).to_float() < str(b).to_float())
		return {"ladder": true, "order": nums, "source": "numeric"}

	var index: Dictionary = {}
	for i in range(values.size()):
		index[str(values[i])] = i

	var edges: Dictionary = {}          # "a>b" -> [a, b]
	var strong: int = 0
	var weak: int = 0
	for text in _dna_texts(dna):
		for m in _chain_re().search_all(str(text)):
			var mm: RegExMatch = m
			var rawtext: String = mm.get_string()
			var flat: String = rawtext.replace("->", "<").replace("→", "<")
			var terms: Array = []
			var bad: bool = false
			for piece in flat.split("<", false):
				var t: String = str(piece).strip_edges()
				if t == "" or not index.has(t) or terms.has(t):
					bad = true
					break
				terms.append(t)
			if bad or terms.size() < 2:
				continue
			for j in range(terms.size() - 1):
				edges["%s>%s" % [terms[j], terms[j + 1]]] = [terms[j], terms[j + 1]]
			if rawtext.find("<") >= 0 or terms.size() >= 3:
				strong += 1
			else:
				weak += 1

	if strong == 0 and weak < 2:
		var ord_order: Array = _ordinal_order(values)
		if not ord_order.is_empty():
			return {"ladder": true, "order": ord_order, "source": "ordinal"}
		return {"ladder": false, "order": values.duplicate(), "source": "declared"}

	var sorted_vals: Array = _topo(values, index, edges)
	if sorted_vals.is_empty():
		# the notes contradict each other; a contradicted order is not an order
		return {"ladder": false, "order": values.duplicate(), "source": "cycle"}
	return {"ladder": true, "order": sorted_vals, "source": "written" if strong > 0 else "written-weak"}


## Kahn, with declared order as the tiebreak so unconstrained values stay where
## the registry put them. Returns [] on a cycle.
static func _topo(values: Array, index: Dictionary, edges: Dictionary) -> Array:
	var indeg: Dictionary = {}
	var adj: Dictionary = {}
	for v in values:
		indeg[str(v)] = 0
		adj[str(v)] = []
	for key in edges:
		var pair: Array = edges[key]
		var a: String = str(pair[0])
		var b: String = str(pair[1])
		(adj[a] as Array).append(b)
		indeg[b] = int(indeg[b]) + 1
	var ready: Array = []
	for v in values:
		if int(indeg[str(v)]) == 0:
			ready.append(str(v))
	var out: Array = []
	while not ready.is_empty():
		ready.sort_custom(func(a, b): return int(index[str(a)]) < int(index[str(b)]))
		var n: String = str(ready.pop_front())
		out.append(n)
		for m in (adj[n] as Array):
			var t: String = str(m)
			indeg[t] = int(indeg[t]) - 1
			if int(indeg[t]) == 0:
				ready.append(t)
	if out.size() != values.size():
		return []
	return out


static func _ordinal_order(values: Array) -> Array:
	if values.size() < 3:
		return []
	for scale in ORDINAL_SCALES:
		var s: Array = scale
		var all_in: bool = true
		for v in values:
			if not s.has(str(v).to_lower()):
				all_in = false
				break
		if not all_in:
			continue
		var out: Array = values.duplicate()
		out.sort_custom(func(a, b): return s.find(str(a).to_lower()) < s.find(str(b).to_lower()))
		return out
	return []


## ── THE SEQUENCE ─────────────────────────────────────────────────────────────

## Which n values, in which order.
##  ladder + known default : a contiguous window of the ladder that CONTAINS the
##                           default, as early in the ladder as it can sit — so
##                           the rungs are walked in their own order and the
##                           corpus law holds at the same time.
##  ladder + unknown       : the first n rungs, with entry 0 replaced by a bare
##                           copy at call site — the bare copy is the default
##                           wherever it really lives, and the rung it displaces
##                           is offered back through `alt`.
##  no ladder              : default first, then declared order.
static func _sequence(order: Array, default_value: String, known: bool, is_ladder: bool, n: int) -> Array:
	var out: Array = []
	if is_ladder:
		var start: int = 0
		if known:
			var di: int = order.find(default_value)
			if di >= 0:
				start = clampi(di - (n - 1), 0, maxi(order.size() - n, 0))
		for i in range(n):
			var idx: int = start + i
			if idx < order.size():
				out.append(str(order[idx]))
		return out
	if known:
		out.append(default_value)
	for v in order:
		if out.size() >= n:
			break
		var s: String = str(v)
		if not out.has(s):
			out.append(s)
	return out


## ── DEFAULT ──────────────────────────────────────────────────────────────────

## The shipped value of `axis`, read from the prose in dna.default. "" when the
## field is absent, names another axis, or names a value this axis does not
## declare — all three are "we do not know", and a guess here is a corpus edit.
static func _default_for(dna: Dictionary, axis: String, values: Array) -> String:
	var s: String = str(dna.get("default", ""))
	if s.strip_edges() == "":
		return ""
	var head: String = s
	for sep in [" - ", " — ", " – "]:
		var i: int = s.find(str(sep))
		if i > 0:
			head = s.substr(0, i)
			break
	for scope in [head, s]:
		for m in _pair_re().search_all(str(scope)):
			var mm: RegExMatch = m
			if mm.get_string(1) != axis:
				continue
			var v: String = mm.get_string(2)
			if values.has(v):
				return v
			for cand in values:
				if str(cand).to_lower() == v.to_lower():
					return str(cand)
			return ""
	return ""


## ── ENTRIES ──────────────────────────────────────────────────────────────────

static func _entry(axis: String, value: String, is_default: bool, i: int, is_ladder: bool, alts: Array, why: String) -> Dictionary:
	var cfg: String = ""
	if not is_default and axis != "" and value != "":
		cfg = "#%s:%s" % [axis, value]
	return {
		"value": value,
		"axis": axis,
		"emphasis": str(EMPHASIS[mini(i, EMPHASIS.size() - 1)]),
		"is_default": is_default,
		"config": cfg,
		"alt": alts,
		"rank_hint": mini(i, 2),
		"ladder": is_ladder,
		"why": why,
	}


static func _solo(axis: String, default_value: String, why: String) -> Dictionary:
	return _entry(axis, default_value, true, 0, false, [], why)


static func _cap_reason(licence: int, values: int, budget: int) -> String:
	if budget < 2:
		return "only %d slot(s) free after the %d reserved for other work" % [maxi(budget, 0), SLOT_RESERVE]
	if licence < 2:
		return "relations grant no multiples licence"
	if values < 2:
		return "the axis declares one value"
	return "capped"


## ── REGISTRY ─────────────────────────────────────────────────────────────────

static func _ensure_registry() -> void:
	if _registry_scanned:
		return
	_registry_scanned = true
	var t0: int = Time.get_ticks_msec()
	var dir: DirAccess = DirAccess.open(REGISTRY_DIR)
	if dir == null:
		push_warning("em_multiples: no registry at %s — every token plans as a solo default" % REGISTRY_DIR)
		return
	var files: int = 0
	for fname in dir.get_files():
		var fn: String = str(fname)
		if not fn.ends_with(".json"):
			continue
		var f: FileAccess = FileAccess.open(REGISTRY_DIR + "/" + fn, FileAccess.READ)
		if f == null:
			continue
		var data: Variant = JSON.parse_string(f.get_as_text())
		if not (data is Dictionary):
			continue
		var arts: Variant = (data as Dictionary).get("artifacts", null)
		if not (arts is Dictionary):
			continue
		files += 1
		for lookup in (arts as Dictionary):
			var entry: Variant = (arts as Dictionary)[lookup]
			if not (entry is Dictionary):
				continue
			var dna: Variant = (entry as Dictionary).get("dna", null)
			if dna is Dictionary:
				_dna_cache[str(lookup)] = dna
	print("[em_multiples] dna: %d promoted tokens from %d registry files (%d ms)" % [
		_dna_cache.size(), files, Time.get_ticks_msec() - t0])


## The relations row, accepting either the whole artifact_relations.json or just
## its `artifacts` sub-dictionary.
static func _rel_entry(lookup: String, rel_db: Dictionary) -> Dictionary:
	var src: Dictionary = rel_db
	if rel_db.has("artifacts") and rel_db["artifacts"] is Dictionary:
		src = rel_db["artifacts"]
	var row: Variant = src.get(lookup, null)
	if row is Dictionary:
		return row
	return {}


## ── SMALL THINGS ─────────────────────────────────────────────────────────────

## Every string in a dna block, one level into its arrays. The ladder scan reads
## all of them rather than `note` alone: the corpus writes orderings in
## axis_order_note, ladder_note, fixture_ladder, argues and reads too, and the
## vocabulary test makes reading the wrong field harmless.
static func _dna_texts(dna: Dictionary) -> Array:
	var out: Array = []
	for k in dna:
		var v: Variant = dna[k]
		if v is String:
			out.append(str(v))
		elif v is Array:
			for item in (v as Array):
				if item is String:
					out.append(str(item))
	return out


static func _prop_info(node: Object, prop: String) -> Dictionary:
	for p in node.get_property_list():
		var d: Dictionary = p
		if str(d.get("name", "")) == prop:
			return d
	return {}


## The values the CODE allows, from an @export_enum hint. [] when the export is
## not an enum, in which case stage() cannot gate and says so by applying.
static func _enum_values(info: Dictionary) -> Array:
	if info.is_empty():
		return []
	if int(info.get("hint", 0)) != PROPERTY_HINT_ENUM:
		return []
	var out: Array = []
	for piece in str(info.get("hint_string", "")).split(",", false):
		var s: String = str(piece).strip_edges()
		if s == "":
			continue
		var colon: int = s.rfind(":")
		if colon > 0 and s.substr(colon + 1).is_valid_int():
			s = s.substr(0, colon)      # int enums come as "Name:0"
		out.append(s)
	return out


## String -> the export's own type. A typed bool export refuses the String
## "true" outright, which is how a fixture flag once silently failed pre-_ready.
static func _coerce(value: String, info: Dictionary) -> Variant:
	var t: int = int(info.get("type", TYPE_STRING))
	if t == TYPE_BOOL:
		var low: String = value.to_lower()
		return low == "true" or low == "1" or low == "yes"
	if t == TYPE_INT:
		return value.to_int()
	if t == TYPE_FLOAT:
		return value.to_float()
	return value


static func _val_str(v: Variant) -> String:
	if v is float:
		var f: float = v
		if is_equal_approx(f, round(f)):
			return "%.1f" % f
		return str(f)
	if v is bool:
		return "true" if bool(v) else "false"
	return str(v)


static func _num_str(v: float) -> String:
	if is_equal_approx(v, round(v)):
		return str(int(round(v)))
	return "%.2f" % v


static func _pair_re() -> RegEx:
	if _re_pair == null:
		_re_pair = RegEx.new()
		_re_pair.compile("([A-Za-z_][A-Za-z_0-9]*)\\s*=\\s*([A-Za-z_0-9][A-Za-z_0-9.]*)")
	return _re_pair


static func _chain_re() -> RegEx:
	if _re_chain == null:
		# `<=` never matches: after the `<` the next term must start with a value
		# character, and `=` is not one, so the whole match fails and backtracks
		# out. That is why "|a+b| <= |a|+|b|" needs no special case.
		_re_chain = RegEx.new()
		_re_chain.compile("[A-Za-z_0-9.]+(?:\\s*(?:<|->|→)\\s*[A-Za-z_0-9.]+)+")
	return _re_chain


static func _warn_once(msg: String) -> void:
	if _warned.has(msg):
		return
	_warned[msg] = true
	push_warning(msg)
