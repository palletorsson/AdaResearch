class_name EmSets
extends RefCounted
# em_sets.gd — the SET dealer. One artifact in, a related group out.
#
#   EmSets.build_set(lead, slots, rel_db, budget) -> Array of placements
#
# WHY A SET AND NOT EIGHT SINGLES. The v1 dealer hands one artifact per slot in
# spine order, footprint-matched. Every object in the room is therefore a
# stranger to every other object in the room, and a room full of strangers is
# read by the eye as a warehouse: things ARE there, but nothing is ABOUT
# anything. A critic reading the rendered frames put it exactly: 2 m2 of wall
# with one feature on it reads as blockout before it reads as architecture, and
# the fix is not more materials — it is objects placed by a rule the viewer can
# feel without being told.
#
# Placement is the one thing a procedural generator does better than a level
# artist: it knows where every slot, door, light and walking line is, so it can
# put the second thing in a fixed relation to the first, consistently, forever.
# commons/data/artifact_relations.json is the material for that — 12,610 typed
# edges over 799 spine artifacts, each edge saying HOW two artifacts are related.
# This file turns each edge KIND into a spatial claim.
#
# ── THE GRAMMAR ──────────────────────────────────────────────────────────────
# One rule per kind. Each rule is a claim about space, and each claim is a
# different reason two objects belong in one glance:
#
#   named      an @identity field on one names the other — AUTHORED intent, the
#              strongest signal in the file. Rule: put the relative in the LEAD'S
#              SIGHTLINE — same row or column, nothing placed between them,
#              further from the entrance than the lead. Two things the author
#              said are about each other should be visible in ONE look; a
#              sightline is the only arrangement that guarantees that, because
#              the walker cannot see the lead without the relative behind it.
#
#   sibling    same scene file, different registry name — a hidden family. Rule:
#              a ROW at EVEN SPACING along one wall line. Scattered, siblings
#              read as three unrelated objects that happen to resemble each
#              other; in an evenly spaced row the repetition itself becomes the
#              subject and they read as a VOCABULARY — the same argument at
#              three settings. Even spacing is load-bearing: uneven spacing
#              reads as accident, even spacing reads as a decision.
#
#   axis_kin   both declare an axis of the SAME NAME, so both can make the same
#              argument. Rule (the highest-value one here): ADJACENT, and AT
#              DIFFERENT VALUES of that shared axis. Adjacency alone would give
#              a repeat; adjacency plus a value split gives a COMPARISON — the
#              room stages the axis instead of merely exhibiting two objects.
#              The lead is pinned to a value too, because a comparison needs both
#              ends fixed: one end left at its default is a coincidence, not a
#              claim. A third kin, when one exists, takes a third value on the
#              same axis and the pair becomes a series.
#
#   co_placed  already stand together in N shipped maps — proven, no argument
#              needed. Rule: fill the remaining NEAREST free slots, cheapest
#              first, where cheapest means most-proven (highest N). This is the
#              kind that makes a room full rather than a room right.
#
#   family     same category and sequence — the weakest edge in the file, and it
#              is padding ONLY. Rule: used solely when the segment would
#              otherwise stand under two-thirds full, and then only on the
#              humblest free slots. A family cousin placed for its own sake
#              teaches nothing and dilutes every rule above it.
#
# MULTIPLES. 481 of 799 spine artifacts declare multiples > 1: a promoted family
# exists to be seen more than once. When budget is left after the argued kinds,
# the lead itself is dealt again at a further value of its own axis — the only
# placement in the museum where an artifact meets itself. Capped at two extra
# copies, and never without a value, since a duplicate at the same value is just
# a duplicate.
#
# ── WHAT THIS FILE PROMISES ──────────────────────────────────────────────────
#   * never two placements in one cell (`taken`, keyed by the slot's x/y);
#   * never more than `budget` placements, lead included;
#   * the lead always takes the FIRST slot in the room (lowest y — nearest the
#     entrance), and the best-ranked cell at that depth. Until 2026-08-13 this
#     read "the best slot (lowest rank)", and it was the single most damaging
#     order defect in the corridor: rank outranked depth, so the chapter's
#     opening artifact was dealt to the hero plinth, which in 10 of 26 templates
#     is the DEEPEST cell in the building. See _slot_before;
#   * DEGRADES to lead-only when rel_db is missing, thin, or does not know the
#     lead — a museum with no relations file deals exactly as it does today;
#   * DETERMINISTIC. No randf(), no dictionary-order gambling: every tie breaks
#     on a declared key, so the same lead and the same tile build the same room
#     and two proof shots of one museum are the same photograph.
#
# WHAT HAPPENS WHEN THERE ARE MORE RELATIVES THAN SLOTS — the common case, since
# a typical lead carries 10-30 edges and a segment offers 8. The phases run in
# grammar order (axis_kin, named, sibling, multiples, co_placed, family) and each
# phase takes only slots still free, so the overflow is dropped from the BOTTOM
# of the grammar: the comparison and the sightline always survive, the padding
# never does. Inside a phase the surplus is dropped by score (proven-together
# descending, then token name), and each phase is capped so no single kind can
# eat the room. A sibling row is all-or-nothing above one: a row of one is not a
# row, so a lone sibling is placed adjacent instead of pretending to be a series.
#
# The values this file chooses are DERIVED from artifact_relations.json, never
# transcribed: the shared axis is confirmed present in BOTH artifacts' declared
# axes before it is used, and a value is only ever taken from the list the
# artifact itself declares. An axis_kin edge whose values cannot be resolved on
# both sides (639 of 2101 can't — the relative is a gallery artifact outside the
# spine, so nothing declares its values) is demoted to plain nearby fill rather
# than being handed an invented value. A fabricated value does not fail loudly:
# the artifact silently falls back to its default and the room quietly becomes a
# repeat while every stage still reports green.

# ── CAPS ─────────────────────────────────────────────────────────────────────
# Each phase is capped so one kind cannot own a segment. With the museum's
# MAX_ARTIFACTS_PER_SEGMENT of 8 a full room is roughly: lead + 2 kin + 2 named
# + up to 2 of (sibling row / multiples) + co_placed fill.
const MAX_AXIS_KIN: int = 2
const MAX_NAMED: int = 2
const MAX_SIBLINGS: int = 4
const MAX_MULTIPLES: int = 2
# A sightline needs LENGTH — at one cell apart it is adjacency wearing a better
# name. Beyond ~12 cells the two are almost certainly in different chambers of
# the same tile, and this module can see slots but not walls, so it declines to
# claim a view it cannot verify.
const MIN_SIGHTLINE: int = 2
const MAX_SIGHTLINE: int = 12
# Adjacency in Chebyshev cells. Past 4 m two objects stop reading as a pair.
# MEASURED against the 26 museum-tagged templates in template_patterns.json: the
# distance from each tile's best slot to its nearest other slot is 1..8, median
# 4, and 21 of the 26 are within 4. So this constant buys a genuinely adjacent
# comparison in about four museums out of five; the five that miss (Chichu at 8,
# both Castelvecchios at 7, Caracalla and Katsura at 5) fall to the second tier
# in PHASE A rather than losing the comparison.
const ADJ_MAX: int = 4
# Family padding engages only below this fraction of a full room.
const FAMILY_FILL_NUM: int = 2
const FAMILY_FILL_DEN: int = 3


## THE ENTRY POINT.
##   lead    spine token the museum was about to deal into its best slot
##   slots   the segment's free slots, each {x, y, top, rank} — rank 0 hero
##           plinth, 1 podium, 2 floor. Returned cells are these same dicts.
##   rel_db  parsed commons/data/artifact_relations.json
##   budget  hard ceiling on placements INCLUDING the lead
## Returns [{token, cell, axis, value, kind, role, why}] — axis/value empty when
## the placement makes no axis claim; role is "lead" or the edge kind.
static func build_set(lead: String, slots: Array, rel_db: Dictionary, budget: int) -> Array:
	var out: Array = []
	if lead == "" or budget <= 0 or slots.is_empty():
		return out
	# keep only usable slot dicts, and keep the CALLER'S dicts (the contract says
	# `cell` is one of the slots handed in, so the museum can read `top` off it)
	var cells: Array = []
	for s0 in slots:
		if s0 is Dictionary and (s0 as Dictionary).has("x") and (s0 as Dictionary).has("y"):
			cells.append(s0)
	if cells.is_empty():
		return out
	var taken: Dictionary = {}
	# the lead takes the FIRST slot past the threshold, and the best cell at that
	# depth — nearest the entrance, then lowest rank. See _slot_before: the two
	# keys used to be the other way round, which put the chapter's opening piece
	# on the hero plinth at the far wall of the building.
	var ranked: Array = cells.duplicate()
	_sort_slots(ranked)
	var lead_slot: Dictionary = ranked[0]
	_place(out, taken, lead, lead_slot, "", "", "lead", "lead",
		"the chapter's own piece, on the best slot in the room")

	var db: Dictionary = _artifacts_of(rel_db)
	var entry: Dictionary = _entry_of(db, lead)
	if entry.is_empty() or budget <= 1:
		return out                      # degrade: lead-only, exactly v1 behaviour

	# ── sort the edges into buckets, one per kind ────────────────────────────
	var kin: Array = []
	var named: Array = []
	var sibs: Array = []
	var cop: Array = []
	var fam: Array = []
	var seen: Dictionary = {}
	seen[lead] = true
	var rels: Array = []
	var rv: Variant = entry.get("relations", [])
	if rv is Array:
		rels = rv as Array
	for r0 in rels:
		if not (r0 is Dictionary):
			continue
		var r: Dictionary = r0
		var tok: String = str(r.get("token", ""))
		if tok == "" or seen.has(tok):
			continue
		seen[tok] = true
		var row: Dictionary = {
			"token": tok,
			"kind": str(r.get("kind", "")),
			"why": str(r.get("why", "")),
			"pt": int(r.get("placements_together", 0))
		}
		var kind: String = str(row["kind"])
		if kind == "axis_kin":
			kin.append(row)
		elif kind == "named":
			named.append(row)
		elif kind == "sibling":
			sibs.append(row)
		elif kind == "co_placed":
			cop.append(row)
		elif kind == "family":
			fam.append(row)
	_sort_cands(kin)
	_sort_cands(named)
	_sort_cands(sibs)
	_sort_cands(cop)
	_sort_cands(fam)

	# ── PHASE A — axis_kin: adjacent, at DIFFERENT values of the shared axis ──
	# The one placement that stages an argument instead of exhibiting an object.
	# The first resolvable kin pins the LEAD to a value too; a second kin must
	# take a third value on that same axis, so the group reads as one series
	# rather than two unrelated comparisons.
	var lead_axis: String = ""
	var used_vals: Dictionary = {}
	var n_kin: int = 0
	var kin_left: Array = []
	for c0 in kin:
		var c: Dictionary = c0
		if out.size() >= budget or n_kin >= MAX_AXIS_KIN:
			kin_left.append(c)
			continue
		var pair: Dictionary = _axis_pair(db, entry, c, lead_axis, used_vals)
		if pair.is_empty():
			kin_left.append(c)          # values unresolvable — demoted to fill
			continue
		# TWO TIERS, because the first draft silently threw the best placement in
		# the file away. Five of the 26 museum templates put their best slot 5 to
		# 8 cells from every other slot (Chichu's buried cells are the extreme).
		# On those, tier one finds nothing, and the first draft demoted the kin to
		# value-less fill — it still got placed, just stripped of the one thing
		# that made it worth placing. A comparison staged across a room is weaker
		# than one staged shoulder to shoulder, and far stronger than none.
		var why_kin: String = str(c["why"])
		var slot: Dictionary = _adjacent_slot(cells, taken, lead_slot)
		if slot.is_empty():
			slot = _nearest_slot(cells, taken, lead_slot, true)
			why_kin += " — no slot within %d cells of the lead here, so the pair is staged at distance" % ADJ_MAX
		if slot.is_empty():
			kin_left.append(c)
			continue
		if lead_axis == "":
			lead_axis = str(pair["axis"])
			var l0: Dictionary = out[0]
			l0["axis"] = lead_axis
			l0["value"] = str(pair["lead_value"])
			l0["why"] = "%s — pinned to %s:%s so the comparison has two fixed ends" % [
				str(l0["why"]), lead_axis, str(pair["lead_value"])]
			used_vals[str(pair["lead_value"])] = true
		used_vals[str(pair["rel_value"])] = true
		_place(out, taken, str(c["token"]), slot, lead_axis, str(pair["rel_value"]),
			"axis_kin", "axis_kin", why_kin)
		n_kin += 1

	# ── PHASE B — named: the relative in the lead's sightline ────────────────
	var n_named: int = 0
	for c0 in named:
		if out.size() >= budget or n_named >= MAX_NAMED:
			break
		var c: Dictionary = c0
		var why: String = str(c["why"])
		var slot: Dictionary = _sightline_slot(cells, taken, lead_slot)
		if slot.is_empty():
			# a compact tile, or a tile whose slots share no row or column, simply
			# has no clear line. An AUTHORED relation is the strongest signal in
			# the file and is never dropped for want of geometry: place it as near
			# the lead as the tile allows and say plainly that the sightline claim
			# was not met, rather than claiming a view that is not there.
			slot = _nearest_slot(cells, taken, lead_slot, true)
			why += " — no clear sightline in this room, placed as near the lead as the tile allows"
		if slot.is_empty():
			break
		_place(out, taken, str(c["token"]), slot, "", "", "named", "named", why)
		n_named += 1

	# ── PHASE C — sibling: an evenly spaced row ──────────────────────────────
	if out.size() < budget and not sibs.is_empty():
		var want: int = mini(mini(MAX_SIBLINGS, sibs.size()), budget - out.size())
		var row_slots: Array = _row_slots(cells, taken, lead_slot, want)
		if want >= 2 and row_slots.size() >= 2:
			var n: int = mini(want, row_slots.size())
			for i in range(n):
				var c: Dictionary = sibs[i]
				_place(out, taken, str(c["token"]), row_slots[i], "", "",
					"sibling", "sibling",
					"%s — dealt as a row so the family reads as a vocabulary" % str(c["why"]))
		else:
			# a row of one is not a row: keep the sibling, drop the claim. Nearest
			# rather than adjacent — 41 of the 67 leads that have siblings have
			# exactly one, and requiring adjacency dropped every one of them on a
			# tile whose slots are spread out.
			var c1: Dictionary = sibs[0]
			var slot1: Dictionary = _nearest_slot(cells, taken, lead_slot, true)
			if not slot1.is_empty():
				_place(out, taken, str(c1["token"]), slot1, "", "", "sibling", "sibling",
					"%s — only one sibling placeable here, so no row" % str(c1["why"]))

	# ── PHASE D — multiples: the lead meets itself at another value ──────────
	var mult: int = int(entry.get("multiples", 1))
	if mult > 1 and out.size() < budget:
		var lead_axes: Dictionary = _axes_of_entry(entry)
		var axis: String = lead_axis
		if axis == "" and not lead_axes.is_empty():
			axis = str(lead_axes.keys()[0])
		if axis != "" and lead_axes.has(axis):
			var vals: Array = _str_list(lead_axes[axis])
			var l0: Dictionary = out[0]
			if str(l0.get("value", "")) == "" and not vals.is_empty():
				l0["axis"] = axis
				l0["value"] = str(vals[0])
				used_vals[str(vals[0])] = true
			var extra: int = 0
			for v in vals:
				if out.size() >= budget or extra >= MAX_MULTIPLES or extra >= mult - 1:
					break
				var s: String = str(v)
				if used_vals.has(s):
					continue
				var slot: Dictionary = _nearest_slot(cells, taken, lead_slot, true)
				if slot.is_empty():
					break
				used_vals[s] = true
				_place(out, taken, lead, slot, axis, s, "multiple", "multiple",
					"declares multiples=%d — the family shown as a family, %s = %s" % [mult, axis, s])
				extra += 1

	# ── PHASE E — co_placed: nearest free slots, most-proven first ───────────
	# Demoted axis_kin edges (shared axis name, unresolvable values) lead the
	# queue: they are still a stronger reason to stand together than a map both
	# happened to appear in.
	var fill: Array = kin_left.duplicate()
	fill.append_array(cop)
	for c0 in fill:
		if out.size() >= budget:
			break
		var c: Dictionary = c0
		var slot: Dictionary = _nearest_slot(cells, taken, lead_slot, true)
		if slot.is_empty():
			break
		var kind: String = str(c["kind"])
		var why: String = str(c["why"])
		if kind == "axis_kin":
			why += " — but its values are not declared, so no comparison is staged"
		_place(out, taken, str(c["token"]), slot, "", "", kind, kind, why)

	# ── PHASE F — family: padding, and only into a room that would look empty ─
	var target: int = mini(budget, cells.size())
	if out.size() * FAMILY_FILL_DEN < target * FAMILY_FILL_NUM:
		for c0 in fam:
			if out.size() >= budget:
				break
			var c: Dictionary = c0
			# `false`: padding takes the HUMBLEST slot left, never a plinth a
			# better-argued piece would have earned
			var slot: Dictionary = _nearest_slot(cells, taken, lead_slot, false)
			if slot.is_empty():
				break
			_place(out, taken, str(c["token"]), slot, "", "", "family", "family",
				"%s — padding an otherwise sparse room" % str(c["why"]))
	return out


## The config string the grid would have written for a placement:
##   "<lookup>:<rotation>:<y_offset>#<axis>:<value>"
## Handy for logging and for any caller that wants to go through the normal
## interactables path instead of instancing the scene itself.
static func config_token(p: Dictionary, rotation: int = 0, y_offset: float = 0.0) -> String:
	var t: String = str(p.get("token", ""))
	if t == "":
		return ""
	var s: String = "%s:%d:%s" % [t, rotation, str(y_offset)]
	var axis: String = str(p.get("axis", ""))
	var value: String = str(p.get("value", ""))
	if axis != "" and value != "":
		s += "#%s:%s" % [axis, value]
	return s


## Set an axis value on an instanced artifact. MUST be called BEFORE add_child:
## most artifacts build in _ready(), so a sibling edited afterwards is the
## default wearing a costume. Returns true when something actually took the
## value — a false here is the difference between a staged comparison and two
## identical objects, so callers should log it rather than assume.
##
## THE VALUE IS TYPED TO THE EXPORT, not handed over as text. 24 of the 670
## declared axes carry numbers, not names — depth [1,2,3,4], points [4,5,6,8,12],
## roughness [0.0,0.05,0.15,0.35] — and this module carries every value as a
## String because that is what the config-token syntax is made of. A String
## pushed at an int or bool export does not raise: it coerces to zero or false,
## the artifact builds its default, and the room becomes a repeat with every
## stage still green. That is the same failure mode as a mistyped axis
## declaration, and it is invisible in the frame. So the declared property type
## decides the conversion, and a value that cannot be converted is refused.
static func apply_axis(node: Node, axis: String, value: String) -> bool:
	if node == null or axis == "" or value == "":
		return false
	var hit: bool = false
	var typed: Variant = value
	for p0 in node.get_property_list():
		var p: Dictionary = p0
		if str(p.get("name", "")) != axis:
			continue
		var t: int = int(p.get("type", TYPE_NIL))
		var ok: bool = true
		if t == TYPE_STRING or t == TYPE_STRING_NAME:
			typed = value
		elif t == TYPE_INT:
			# a named value against an int export is an ENUM: this module has no
			# business guessing the index, so leave it to apply_grid_config
			ok = value.is_valid_int()
			if ok:
				typed = int(value)
		elif t == TYPE_FLOAT:
			ok = value.is_valid_float()
			if ok:
				typed = float(value)
		elif t == TYPE_BOOL:
			typed = (value == "true") or (value == "1") or (value == "on")
		else:
			ok = false                  # not a value type this module can set honestly
		if ok:
			node.set(axis, typed)
			hit = true
		break
	# the artifact's own hook gets the last word — it is what a map placement
	# would have called, and it may understand a name this module could not type
	if node.has_method("apply_grid_config"):
		var cfg: Dictionary = {}
		cfg[axis] = typed
		node.call("apply_grid_config", cfg)
		hit = true
	return hit


## One line for the museum's segment print.
static func summary(placements: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for p0 in placements:
		var p: Dictionary = p0
		var s: String = "%s(%s" % [str(p.get("token", "?")), str(p.get("role", "?"))]
		var axis: String = str(p.get("axis", ""))
		if axis != "":
			s += " %s=%s" % [axis, str(p.get("value", ""))]
		parts.append(s + ")")
	return ", ".join(parts)


# ── RELATION-DB ACCESS ───────────────────────────────────────────────────────

static func _artifacts_of(rel_db: Dictionary) -> Dictionary:
	var v: Variant = rel_db.get("artifacts", {})
	if v is Dictionary:
		return v as Dictionary
	return {}


static func _entry_of(db: Dictionary, token: String) -> Dictionary:
	var v: Variant = db.get(token, {})
	if v is Dictionary:
		return v as Dictionary
	return {}


static func _axes_of_entry(entry: Dictionary) -> Dictionary:
	var v: Variant = entry.get("axes", {})
	if v is Dictionary:
		return v as Dictionary
	return {}


static func _str_list(v: Variant) -> Array:
	var out: Array = []
	if v is Array:
		for x in (v as Array):
			var s: String = str(x)
			if s != "":
				out.append(s)
	return out


## The axis two artifacts can both argue, CONFIRMED against what each one
## actually declares. The edge's `why` names it ("can argue the same axis: X"),
## but a name in a note is a transcription; the check is that both `axes` blocks
## carry it. Falls back to intersecting the two declarations directly.
static func _shared_axis(lead_axes: Dictionary, cand_axes: Dictionary, cand: Dictionary) -> String:
	var why: String = str(cand.get("why", ""))
	var mark: String = "same axis: "
	var i: int = why.find(mark)
	if i >= 0:
		var name: String = why.substr(i + mark.length()).strip_edges()
		if name != "" and lead_axes.has(name) and cand_axes.has(name):
			return name
	for k in lead_axes.keys():
		var a: String = str(k)
		if cand_axes.has(a):
			return a
	return ""


## Two DIFFERENT values on one shared axis — the lead's and the relative's, each
## taken from that artifact's own declared list. Returns {} when the pair cannot
## be staged honestly (no shared axis, no declared values, or every remaining
## value already used by another member of the series).
static func _axis_pair(db: Dictionary, lead_entry: Dictionary, cand: Dictionary,
		fixed_axis: String, used: Dictionary) -> Dictionary:
	var lead_axes: Dictionary = _axes_of_entry(lead_entry)
	var cand_axes: Dictionary = _axes_of_entry(_entry_of(db, str(cand.get("token", ""))))
	if lead_axes.is_empty() or cand_axes.is_empty():
		return {}
	var axis: String = fixed_axis
	if axis == "":
		axis = _shared_axis(lead_axes, cand_axes, cand)
	if axis == "" or not lead_axes.has(axis) or not cand_axes.has(axis):
		return {}
	var lv: Array = _str_list(lead_axes[axis])
	var cv: Array = _str_list(cand_axes[axis])
	if lv.is_empty() or cv.is_empty():
		return {}
	var lead_value: String = ""
	if fixed_axis == "":
		lead_value = str(lv[0])
	else:
		# the lead already stands somewhere on this axis — find where
		for v in lv:
			if used.has(str(v)):
				lead_value = str(v)
				break
		if lead_value == "":
			lead_value = str(lv[0])
	var rel_value: String = ""
	for v in cv:
		var s: String = str(v)
		if s == lead_value or used.has(s):
			continue
		rel_value = s
		break
	if rel_value == "":
		return {}
	return {"axis": axis, "lead_value": lead_value, "rel_value": rel_value}


# ── PLACEMENT BOOKKEEPING ────────────────────────────────────────────────────

static func _place(out: Array, taken: Dictionary, token: String, slot: Dictionary,
		axis: String, value: String, kind: String, role: String, why: String) -> void:
	taken[_key(slot)] = true
	out.append({
		"token": token, "cell": slot, "axis": axis, "value": value,
		"kind": kind, "role": role, "why": why
	})


static func _key(slot: Dictionary) -> Vector2i:
	return Vector2i(int(slot.get("x", 0)), int(slot.get("y", 0)))


## Chebyshev cells — the metric that matches "reads as a pair", since a diagonal
## neighbour is as close to the eye as an orthogonal one.
static func _dist(a: Dictionary, b: Dictionary) -> int:
	var dx: int = int(a.get("x", 0)) - int(b.get("x", 0))
	var dy: int = int(a.get("y", 0)) - int(b.get("y", 0))
	return maxi(absi(dx), absi(dy))


# ── SLOT SELECTION ───────────────────────────────────────────────────────────

## Nearest untaken slot to the anchor. prefer_low_rank keeps the good pedestals
## for argued placements and pushes padding onto the floor.
static func _nearest_slot(cells: Array, taken: Dictionary, anchor: Dictionary,
		prefer_low_rank: bool) -> Dictionary:
	var best: Dictionary = {}
	var best_d: int = 0x3FFFFFFF
	var best_rank: int = 99
	for s0 in cells:
		var s: Dictionary = s0
		if taken.has(_key(s)):
			continue
		var d: int = _dist(s, anchor)
		var rank: int = int(s.get("rank", 9))
		var better: bool = false
		if d < best_d:
			better = true
		elif d == best_d:
			if prefer_low_rank and rank < best_rank:
				better = true
			elif not prefer_low_rank and rank > best_rank:
				better = true
		if better:
			best = s
			best_d = d
			best_rank = rank
	return best


## ADJACENT — near enough that the walker takes the two in as one exhibit.
## Beyond ADJ_MAX the claim is false, so nothing is returned and the caller
## declines the placement rather than scattering the pair.
static func _adjacent_slot(cells: Array, taken: Dictionary, anchor: Dictionary) -> Dictionary:
	var s: Dictionary = _nearest_slot(cells, taken, anchor, true)
	if s.is_empty():
		return {}
	if _dist(s, anchor) > ADJ_MAX:
		return {}
	return s


## SIGHTLINE — same row or column as the lead, nothing already placed between
## them, and further from the entrance (a same-column relative must sit at
## greater y; segments run along +z and the walker enters at low y, so a
## relative behind the walker is a relative nobody sees). Longest clear line
## wins: a sightline is worth more the more room it crosses.
##
## Occlusion is checked against what THIS set has placed, which is all this
## module can see; the slots themselves came from a template validated at
## extraction, so a clear run between two slots on one line is a strong proxy
## for a clear view — but it is a proxy, not a raycast.
static func _sightline_slot(cells: Array, taken: Dictionary, lead_slot: Dictionary) -> Dictionary:
	var lx: int = int(lead_slot.get("x", 0))
	var ly: int = int(lead_slot.get("y", 0))
	var best: Dictionary = {}
	var best_d: int = -1
	for s0 in cells:
		var s: Dictionary = s0
		if taken.has(_key(s)):
			continue
		var sx: int = int(s.get("x", 0))
		var sy: int = int(s.get("y", 0))
		var d: int = 0
		if sx == lx and sy != ly:
			if sy <= ly:
				continue                # never behind the walker
			d = sy - ly
		elif sy == ly and sx != lx:
			d = absi(sx - lx)
		else:
			continue
		if d < MIN_SIGHTLINE or d > MAX_SIGHTLINE:
			continue
		if _blocked_between(lead_slot, s, taken):
			continue
		if d > best_d:
			best = s
			best_d = d
	return best


static func _blocked_between(a: Dictionary, b: Dictionary, taken: Dictionary) -> bool:
	var ax: int = int(a.get("x", 0))
	var ay: int = int(a.get("y", 0))
	var bx: int = int(b.get("x", 0))
	var by: int = int(b.get("y", 0))
	var dx: int = signi(bx - ax)
	var dy: int = signi(by - ay)
	if dx == 0 and dy == 0:
		return false
	var x: int = ax + dx
	var y: int = ay + dy
	while x != bx or y != by:
		if taken.has(Vector2i(x, y)):
			return true
		x += dx
		y += dy
	return false


## A ROW: the longest line of untaken slots sharing a y (or, failing that, an x),
## then n of them at even spacing across the line's actual span — not every nth
## slot, which is only even when the slots themselves are evenly distributed.
## Rows beat columns: a row faces the walker broadside, which is what makes the
## repetition legible; a column recedes and the far members shrink.
static func _row_slots(cells: Array, taken: Dictionary, lead_slot: Dictionary, n: int) -> Array:
	var empty: Array = []
	if n <= 0:
		return empty
	var rows: Dictionary = {}
	var cols: Dictionary = {}
	# DEDUPE BY CELL, not by dict. This is the one path that picks several slots
	# before any of them is marked taken, so two slot dicts naming the same cell
	# would both enter the row and the set would double-book it. Every other path
	# picks one slot at a time and is protected by `taken`.
	var seen_cell: Dictionary = {}
	for s0 in cells:
		var s: Dictionary = s0
		if taken.has(_key(s)) or seen_cell.has(_key(s)):
			continue
		seen_cell[_key(s)] = true
		var y: int = int(s.get("y", 0))
		var x: int = int(s.get("x", 0))
		if not rows.has(y):
			rows[y] = []
		(rows[y] as Array).append(s)
		if not cols.has(x):
			cols[x] = []
		(cols[x] as Array).append(s)
	var ly: int = int(lead_slot.get("y", 0))
	var lx: int = int(lead_slot.get("x", 0))
	var best: Array = empty
	var best_score: int = -1
	var best_by_x: bool = true
	for k in rows.keys():
		var line: Array = rows[k] as Array
		if line.size() < 2:
			continue
		var score: int = line.size() * 4
		if int(k) == ly:
			score += 2                  # the lead's own wall line, if it has one
		if score > best_score:
			best_score = score
			best = line
			best_by_x = true
	for k2 in cols.keys():
		var line2: Array = cols[k2] as Array
		if line2.size() < 2:
			continue
		var score2: int = line2.size() * 4 - 1   # a column always loses a tie to a row
		if int(k2) == lx:
			score2 += 2
		if score2 > best_score:
			best_score = score2
			best = line2
			best_by_x = false
	if best.is_empty():
		return empty
	return _pick_even(best, n, best_by_x)


static func _pick_even(line: Array, n: int, by_x: bool) -> Array:
	var out: Array = []
	var sorted_line: Array = line.duplicate()
	_sort_line(sorted_line, by_x)
	if n <= 0 or sorted_line.is_empty():
		return out
	if n == 1:
		out.append(sorted_line[0])
		return out
	if n >= sorted_line.size():
		return sorted_line
	var first: float = float(_coord(sorted_line[0], by_x))
	var last: float = float(_coord(sorted_line[sorted_line.size() - 1], by_x))
	var span: float = last - first
	var used: Dictionary = {}
	for k in range(n):
		var want: float = first + span * float(k) / float(n - 1)
		var pick: int = -1
		var best_d: float = 1.0e20
		for i in range(sorted_line.size()):
			if used.has(i):
				continue
			var d: float = absf(float(_coord(sorted_line[i], by_x)) - want)
			if d < best_d:
				best_d = d
				pick = i
		if pick < 0:
			break
		used[pick] = true
		out.append(sorted_line[pick])
	_sort_line(out, by_x)
	return out


static func _coord(slot: Dictionary, by_x: bool) -> int:
	return int(slot.get("x", 0)) if by_x else int(slot.get("y", 0))


# ── SORTING ──────────────────────────────────────────────────────────────────
# Insertion sorts rather than sort_custom lambdas: the sets are tens of items,
# and every comparison here reads its keys with an explicit type, so nothing in
# this file depends on inference over an untyped array element.

static func _sort_slots(arr: Array) -> void:
	for i in range(1, arr.size()):
		var v: Dictionary = arr[i]
		var j: int = i - 1
		while j >= 0:
			var w: Dictionary = arr[j]
			if not _slot_before(v, w):
				break
			arr[j + 1] = w
			j -= 1
		arr[j + 1] = v


## DEPTH FIRST, RANK SECOND — and the order of those two lines is the whole
## difference between a chapter and a shuffled pile.
##
## Until 2026-08-13 this compared `rank` before `y`. Rank is a property of the
## FURNITURE (0 hero plinth, 1 podium, 2 floor); depth is a property of the
## ENCOUNTER. A body walking a segment meets cells in ascending z and cannot see
## a plinth's rank until it is already standing in front of it — so sorting by
## rank first spends the room's one hero cell on the chapter's FIRST artifact,
## and in the three templates measured (and 10 of the 26 in the audit) that cell
## is the DEEPEST in the building. Measured consequence, real runs, one segment
## each: the chapter opener stood at z=32 of 32 (Sainsbury), z=31 of 31 (Uffizi)
## and z=24 of 24 (Chichu) — first dealt, last met, every time. Kendall tau of
## walk order against deal order was -0.111 / +0.308 / -0.333.
##
## Rank is KEPT, as the tiebreak it was always documented to be. Cells at equal
## z are met at the same moment, so between them the room is free to say which
## one is primary, and elevation is how a room says it. What rank may no longer
## do is decide the ORDER of the argument. The deepest cell of an axial building
## is the vista's destination, not its opening line: after this change it is
## still filled, by whichever piece the deal reaches last, which is what walking
## toward something means.
static func _slot_before(a: Dictionary, b: Dictionary) -> bool:
	var ay: int = int(a.get("y", 0))
	var by: int = int(b.get("y", 0))
	if ay != by:
		return ay < by
	var ar: int = int(a.get("rank", 9))
	var br: int = int(b.get("rank", 9))
	if ar != br:
		return ar < br
	return int(a.get("x", 0)) < int(b.get("x", 0))


static func _sort_line(arr: Array, by_x: bool) -> void:
	for i in range(1, arr.size()):
		var v: Dictionary = arr[i]
		var j: int = i - 1
		while j >= 0:
			var w: Dictionary = arr[j]
			if _coord(v, by_x) >= _coord(w, by_x):
				break
			arr[j + 1] = w
			j -= 1
		arr[j + 1] = v


## Candidates: most-proven first, then token name — a total order with no ties,
## so the same lead always deals the same set.
static func _sort_cands(arr: Array) -> void:
	for i in range(1, arr.size()):
		var v: Dictionary = arr[i]
		var j: int = i - 1
		while j >= 0:
			var w: Dictionary = arr[j]
			if not _cand_before(v, w):
				break
			arr[j + 1] = w
			j -= 1
		arr[j + 1] = v


static func _cand_before(a: Dictionary, b: Dictionary) -> bool:
	var ap: int = int(a.get("pt", 0))
	var bp: int = int(b.get("pt", 0))
	if ap != bp:
		return ap > bp
	return str(a.get("token", "")) < str(b.get("token", ""))
