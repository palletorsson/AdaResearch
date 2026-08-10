class_name EmPool
extends RefCounted
# em_pool.gd — the GUEST LIST. What the museum may deal that the curriculum
# never mentions.
#
#   EmPool.load() -> Dictionary                     the union, resolved, once
#     (alias: EmPool.build(live, roots) — same contract, collision-proof name;
#      hand the museum's own _live in and the registry is not re-walked)
#   EmPool.guests_for(chapter, n) -> Array          n guests suiting a chapter
#   EmPool.report() -> String                       the line to print at startup
#   EmPool.summary(rows) -> String                  the line to print per segment
#
# ── THE MEASURED PROBLEM ─────────────────────────────────────────────────────
# The corridor deals from commons/data/spine_artifact_order.json: 799 tokens in
# curriculum order. That is the argument, and it stays the argument. But it is
# also the entire vocabulary, and a critic reading the proof frames measured the
# consequence in the only place it shows — the wall: a 420x360 crop, about 2 m2
# of plaster, containing exactly one feature, a light blob. No socket, no vent,
# no seam, no signage. Not because those props do not exist. floor_grate,
# ceiling_vent, cable_tray, electrical_panel, exit_sign, fire_extinguisher,
# fire_hose_box, large_window, lab_stool, conveyor_belt, hangar_wall_panel and
# seventy more are built, registered, map_ready, on disk, and photographed —
# and every one of them is outside the 799, so the museum has never once been
# able to reach for one.
#
# ── WHAT THIS FILE READS ─────────────────────────────────────────────────────
# The DNA galleries under ada_encyclopedia/public/. 47 directories whose name
# contains "dna" carry a manifest.json (1.18 MB in total): 2320 entries, 365
# distinct tokens. Each entry is one RENDERED VARIANT — a PNG a human already
# looked at — and 1854 of them carry a `dna` dict naming the exact axis value
# that made the picture.
#
# That dict is the reason this file exists twice over. It widens the pool, and
# it widens it with KNOWN-GOOD VALUES. A value that has been rendered and
# inspected is the opposite of the corpus's standing failure mode, where an axis
# is declared from a hand-typed block, the sweep sets a name no export answers
# to, the artifact quietly builds its default, and every stage reports green
# over sixteen identical frames. Nothing here is invented: a value is passed
# through only when the REGISTRY declares that axis on that token AND lists that
# exact value. Measured over the 132 guests, 0 gallery values named a declared
# axis and then failed its value list — the galleries and the registry agree —
# so the filter costs nothing today and is the only thing standing between this
# module and a fabricated claim tomorrow.
#
# ── THE FUNNEL, COUNTED ──────────────────────────────────────────────────────
#   365  distinct tokens across the 47 manifests
#   324  RESOLVED — a registry entry with map_ready true and its scene on disk
#     6  dropped: a registry entry that is not alive. Named, because five of the
#        six are a finding and not noise — exhibit_furniture, exhibit_podium and
#        exhibit_vitrine (plus snap_cube_puzzle, snap_tetra_puzzle, tt) carry NO
#        `map_ready` key at all in their registry files, and the museum's own
#        liveness gate reads `a.get("map_ready", false)`. exhibit_furniture is
#        the most-placed object in the project — 1077 placements — and the
#        corridor cannot deal it. 25 tokens across 9 registry files are missing
#        the key the same way. That is a registry repair, in files this module
#        does not own; it is reported here rather than worked around, because a
#        module that quietly treats a missing key as true would deal an artifact
#        the rest of the pipeline agrees is not ready.
#    35  dropped: no registry entry under that name at all — gallery slugs that
#        leaked into a `prop` field ("props-dna-gallery"), doubled ids
#        ("station_wall_station_wall"), and sheet names ("clinical_clean").
#        Nothing to stamp; dropped without ceremony.
#   192  resolved AND already in the spine. These are not guests. They are dealt
#        as leads in curriculum order and this file must not deal them a second
#        time under another name.
#   132  GUESTS. 72 promoted in the registry, 68 carrying a usable gallery value,
#        79 of them building fabric (props / station / exhibits / bench / ceiling).
#
# ── THE SPINE STAYS PRIMARY ──────────────────────────────────────────────────
# A guest is a guest. This module returns candidates; it does not deal, does not
# choose slots, does not touch _pool, and returns nothing at all for a caller
# that never asks. The curriculum order is untouched by its existence.
#
# ── HOW A CHAPTER PICKS ITS GUESTS ───────────────────────────────────────────
# Four tiers, hard order, and the tier is reported in `why` so a frame can be
# argued with. Within a tier, guests carrying a usable axis value come first —
# dealing a guest at its gallery value is the cheapest non-default variant the
# museum will ever show — then the tier's own key, then the token name, so the
# same chapter returns the same list on every run.
#
#   1. THE GALLERY IS THE CHAPTER. The gallery's name, stripped of its
#      "-dna" / "-gallery" / "-renders" suffixes, matches the chapter id in
#      either direction (randomness-dna -> randomness, swarm-dna ->
#      swarmintelligence). Three aliases are declared by hand because the
#      sweeps were named before the sequences were: postfoundationscrisis ->
#      postcrisis, proceduralgeneration -> procgen, foundationscrisis ->
#      foundations. This tier is THIN — 16 hits across 24 chapters at n=6 —
#      and thin for a good reason: a gallery named after a chapter mostly swept
#      that chapter's own spine artifacts, which are leads, not guests.
#
#   2. THE REGISTRY ALREADY PUTS IT THERE. `map_sequences` on the registry entry
#      names this chapter: the artifact stands in a shipped map of this sequence
#      without being on the curriculum's artifact list. 25 hits.
#
#   3. RELATED TO A LEAD. commons/data/artifact_relations.json, entered from the
#      chapter's own spine tokens: any relative that is a guest is a candidate,
#      ranked by edge kind (named, axis_kin, sibling, co_placed, family) and then
#      by placements_together. This tier carries the load — 71 of 144 — which is
#      the honest shape of the thing: the relation file was built over the spine,
#      so the strongest evidence about an outsider is which insider names it.
#
#   4. BUILDING FABRIC. Only when the three argued tiers cannot fill n. The 79
#      props/station/exhibits/bench/ceiling guests, entered at an offset derived
#      from the chapter name so two chapters do not get the same vent. This tier
#      is what stops machinelearning (0 candidates from tiers 1-3) from being
#      dealt an empty guest list, and it is deliberately last: a fire hose box
#      argues nothing, it just makes a wall stop being plaster.
#
# At n=6 every one of the 24 chapters fills, 111 of the 144 dealt guests carry a
# rendered axis value, and 77 distinct guests are reachable; at n=24, 130 of the
# 132 are. The two that are never reached are reachable by no rule in this file
# and are left unreached rather than dealt at random.
#
# ── DEGRADATION ──────────────────────────────────────────────────────────────
# Every failure is a smaller pool, never a broken run. No gallery root on disk
# (the encyclopedia is a SIBLING repository and may simply be absent on a build
# machine) -> zero guests, and the museum deals exactly as it does today. No
# registry -> zero guests. No relation file -> tiers 1, 2 and 4 only. No spine
# order file -> no chapter leads, so no tier 3, and nothing is excluded as a
# spine token, which widens rather than breaks.

# Where the galleries live. res:// first — a build that vendors them wins — then
# the sibling checkout, which is where they actually are today. Both are tried;
# a token found in both keeps the first gallery it was seen in.
const GALLERY_SUBDIR := "ada_encyclopedia/public"
const REGISTRY_DIR := "res://commons/artifacts/registry"
const SPINE_ORDER := "res://commons/data/spine_artifact_order.json"
const RELATIONS := "res://commons/data/artifact_relations.json"

# Which key on a manifest entry carries the artifact's lookup name. `name` is
# NOT in this list and must not be: several manifests use `name` for the sheet
# or the gallery, which pulled 10 non-tokens into the union on the first pass
# (375 distinct tokens with `name` in the list, 365 without).
const TOKEN_KEYS: Array = ["token", "artifact", "prop"]

# Galleries whose subject is the building rather than the curriculum. Tier 4
# draws from these and only these.
const FABRIC_GALLERIES: Array = [
	"props-dna-gallery", "station-dna", "station-kit-dna", "exhibits-dna",
	"bench-hazard-dna", "ceiling-dna-renders"]

# Sweeps named before the sequences were. Three entries, each a fact about
# history rather than a rule, so they are listed instead of pattern-matched.
const CHAPTER_ALIAS: Dictionary = {
	"postfoundationscrisis": "postcrisis",
	"proceduralgeneration": "procgen",
	"foundationscrisis": "foundations",
}

# A gallery stem shorter than this matches half the corpus ("map-dna" -> "map").
const MIN_STEM: int = 5

# Edge kinds, strongest first — the same order em_sets deals them in, so a guest
# ranked here and a relative ranked there do not disagree about what `named`
# is worth.
const KIND_RANK: Dictionary = {
	"named": 0, "axis_kin": 1, "sibling": 2, "co_placed": 3, "family": 4,
}

static var _cache: Dictionary = {}
static var _rel_cache: Dictionary = {}
static var _rel_loaded: bool = false
static var _spine_cache: Array = []
static var _spine_loaded: bool = false


## Build the guest list, once per run. Returns the whole pool as data so a
## caller can print it, gate on it, or ignore it.
##
##   live   the museum's own `_live` (lookup -> {scene, fp}). Handed in, it is
##          used as the liveness oracle and this module does not re-check the
##          disk. Empty, the check is made here — so the module is usable from a
##          test script with no museum around it.
##   roots  extra absolute or res:// directories to scan for *dna*/manifest.json.
##
## Returned:
##   guests      token -> {galleries:[String], gallery:String, axis:String,
##                         value:String, fabric:bool, entries:int}
##   galleries   how many manifests were read
##   entries     how many manifest entries were seen
##   tokens      distinct tokens in the union
##   resolved    tokens with a live registry entry
##   spine       resolved tokens that are already curriculum leads
##   dropped_dead / dropped_unknown  counts, plus dead_tokens for the print
##   with_axis   guests carrying a registry-confirmed gallery axis value
##   report      one line for stdout
##
## `load` is the name the handover asked for and it is deliberately a LEAF: it
## delegates, and nothing inside this file calls it. `load` is also the name of
## a GDScript global, and no other script in this repo overrides it — so if a
## future engine version stops allowing the shadow, deleting these two lines and
## calling `build()` is the whole repair, and no internal call site moves.
static func load(live: Dictionary = {}, roots: PackedStringArray = PackedStringArray()) -> Dictionary:
	return build(live, roots)


## The pool itself. Same contract as `load`, under a name that cannot collide.
static func build(live: Dictionary = {}, roots: PackedStringArray = PackedStringArray()) -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var out: Dictionary = {
		"guests": {}, "galleries": 0, "entries": 0, "tokens": 0, "resolved": 0,
		"spine": 0, "dropped_dead": 0, "dropped_unknown": 0, "dead_tokens": [],
		"with_axis": 0, "fabric": 0, "roots": [], "report": "",
	}
	# ── 1. the registry: what may be stamped, and what it declares ───────────
	var reg: Dictionary = _scan_registry(live)
	if reg.is_empty():
		out["report"] = "no registry read — 0 guests, the corridor deals the spine alone"
		_cache = out
		return out
	# ── 2. the galleries: the union ──────────────────────────────────────────
	var found_roots: PackedStringArray = _gallery_roots(roots)
	out["roots"] = found_roots
	var union: Dictionary = {}     # token -> {gals:[String], dna:[Dictionary], gal_of_dna:[String], n:int}
	var n_gal: int = 0
	var n_ent: int = 0
	for r in found_roots:
		var root: String = String(r)
		var names: PackedStringArray = _sorted_dirs(root)
		for nm in names:
			var gname: String = String(nm)
			if not gname.to_lower().contains("dna"):
				continue
			var mpath: String = root.path_join(gname).path_join("manifest.json")
			var text: String = _read_text(mpath)
			if text.is_empty():
				continue
			var parsed: Variant = JSON.parse_string(text)
			if not (parsed is Dictionary):
				continue
			var ents: Variant = (parsed as Dictionary).get("entries", [])
			if not (ents is Array):
				continue
			n_gal += 1
			for e0 in (ents as Array):
				if not (e0 is Dictionary):
					continue
				n_ent += 1
				var e: Dictionary = e0
				var tok: String = ""
				for k in TOKEN_KEYS:
					var kv: Variant = e.get(String(k), null)
					if kv is String and String(kv) != "":
						tok = String(kv)
						break
				if tok == "":
					continue
				if not union.has(tok):
					union[tok] = {"gals": [], "dna": [], "gal_of_dna": [], "n": 0}
				var rec: Dictionary = union[tok]
				var gals: Array = rec["gals"]
				if not gals.has(gname):
					gals.append(gname)
				rec["n"] = int(rec["n"]) + 1
				var dv: Variant = e.get("dna", null)
				if dv is Dictionary and not (dv as Dictionary).is_empty():
					(rec["dna"] as Array).append(dv as Dictionary)
					(rec["gal_of_dna"] as Array).append(gname)
	out["galleries"] = n_gal
	out["entries"] = n_ent
	out["tokens"] = union.size()
	# ── 3. resolve, and split guests from leads ──────────────────────────────
	var spine_tok: Dictionary = _spine_tokens()
	var guests: Dictionary = {}
	var dead: Array = []
	var n_resolved: int = 0
	var n_spine: int = 0
	var n_unknown: int = 0
	var n_axis: int = 0
	var n_fabric: int = 0
	for t in _sorted_keys(union):
		var tok2: String = String(t)
		var entry: Variant = reg.get(tok2, null)
		if not (entry is Dictionary):
			n_unknown += 1
			continue
		var re: Dictionary = entry
		if not bool(re.get("alive", false)):
			dead.append(tok2)
			continue
		n_resolved += 1
		if spine_tok.has(tok2):
			n_spine += 1
			continue
		var rec2: Dictionary = union[tok2]
		var pair: Dictionary = _axis_value(rec2, re)
		var gal_list: Array = rec2["gals"]
		var fabric: bool = false
		for g2 in gal_list:
			if FABRIC_GALLERIES.has(String(g2)):
				fabric = true
				break
		if fabric:
			n_fabric += 1
		var axis: String = String(pair.get("axis", ""))
		if axis != "":
			n_axis += 1
		guests[tok2] = {
			"galleries": gal_list,
			"gallery": String(pair.get("gallery", "")) if axis != "" else (String(gal_list[0]) if not gal_list.is_empty() else ""),
			"axis": axis,
			"value": String(pair.get("value", "")),
			"fabric": fabric,
			"entries": int(rec2["n"]),
			"sequences": re.get("sequences", []),
		}
	out["guests"] = guests
	out["resolved"] = n_resolved
	out["spine"] = n_spine
	out["dropped_dead"] = dead.size()
	out["dead_tokens"] = dead
	out["dropped_unknown"] = n_unknown
	out["with_axis"] = n_axis
	out["fabric"] = n_fabric
	out["report"] = ("%d galleries, %d entries, %d tokens -> %d resolved (%d already spine leads), " +
		"%d GUESTS, %d carrying a rendered axis value, %d building fabric; " +
		"dropped %d not map_ready/on disk, %d with no registry entry") % [
		n_gal, n_ent, union.size(), n_resolved, n_spine, guests.size(), n_axis,
		n_fabric, dead.size(), n_unknown]
	_cache = out
	return out


## The one line the museum should print, plus the named dead. A dead token is
## named rather than counted because the six of them are a registry repair
## waiting to be made, not a fact about this module.
static func report() -> String:
	var p: Dictionary = build()
	var s: String = String(p.get("report", ""))
	var dead: Array = p.get("dead_tokens", [])
	if not dead.is_empty():
		s += "\n[em_pool]   in a registry but not dealable (no map_ready key, or scene gone): %s" % str(dead)
	var roots: Variant = p.get("roots", [])
	if roots is PackedStringArray and (roots as PackedStringArray).is_empty():
		s += "\n[em_pool]   no gallery root found — the encyclopedia is a sibling checkout and is absent here"
	return s


## n guests suiting a chapter, best first.
##
##   chapter  a spine sequence id ("randomness", "postfoundationscrisis"), which
##            is exactly what endless_museum carries as a segment's `sequence`.
##   n        how many to return. Fewer come back only if the whole guest list
##            is smaller than n.
##   rel_db   parsed artifact_relations.json. The museum already holds it as
##            _rel_db; handed in it costs nothing, omitted it is read and cached
##            here so this function works standalone.
##
## Returns [{token, axis, value, gallery, why}] — axis and value empty when the
## guest has no registry-confirmed gallery value, in which case the museum
## should stamp it bare rather than guess one.
static func guests_for(chapter: String, n: int, rel_db: Dictionary = {}) -> Array:
	var out: Array = []
	if chapter == "" or n <= 0:
		return out
	var pool: Dictionary = build()
	var guests: Dictionary = pool.get("guests", {})
	if guests.is_empty():
		return out
	var tokens: Array = _sorted_keys(guests)
	var seen: Dictionary = {}
	var rows: Array = []

	# ── tier 1: the gallery IS the chapter ───────────────────────────────────
	var cn: PackedStringArray = PackedStringArray([_norm(chapter)])
	var alias: String = String(CHAPTER_ALIAS.get(chapter, ""))
	if alias != "":
		cn.append(_norm(alias))
	for t in tokens:
		var tok: String = String(t)
		if seen.has(tok):
			continue
		var g: Dictionary = guests[tok]
		for gv in (g["galleries"] as Array):
			var gname: String = String(gv)
			var stem: String = _stem(gname)
			if stem.length() < MIN_STEM:
				continue
			if not _touches(stem, cn):
				continue
			_add(rows, seen, tok, g, 1, 0,
				"swept in %s, the gallery this chapter is named for" % gname)
			break

	# ── tier 2: the registry already stands it in this chapter's maps ────────
	for t in tokens:
		var tok2: String = String(t)
		if seen.has(tok2):
			continue
		var g2: Dictionary = guests[tok2]
		if (g2["sequences"] as Array).has(chapter):
			_add(rows, seen, tok2, g2, 2, 0,
				"the registry already stands it in %s maps, off the curriculum list" % chapter)

	# ── tier 3: named by one of this chapter's own leads ─────────────────────
	var db: Dictionary = rel_db if not rel_db.is_empty() else _relations()
	var arts: Variant = db.get("artifacts", {})
	if arts is Dictionary and not (arts as Dictionary).is_empty():
		var by_token: Dictionary = {}   # token -> {rank, pt, lead, kind}
		for lead in _chapter_leads(chapter):
			var lv: Variant = (arts as Dictionary).get(String(lead), null)
			if not (lv is Dictionary):
				continue
			var rels: Variant = (lv as Dictionary).get("relations", [])
			if not (rels is Array):
				continue
			for r0 in (rels as Array):
				if not (r0 is Dictionary):
					continue
				var r: Dictionary = r0
				var rt: String = String(r.get("token", ""))
				if rt == "" or seen.has(rt) or not guests.has(rt):
					continue
				var kind: String = String(r.get("kind", ""))
				var rank: int = int(KIND_RANK.get(kind, 5))
				var pt: int = int(r.get("placements_together", 0))
				var prev: Variant = by_token.get(rt, null)
				if prev is Dictionary:
					var pr: Dictionary = prev
					if int(pr["rank"]) < rank:
						continue
					if int(pr["rank"]) == rank and int(pr["pt"]) >= pt:
						continue
				by_token[rt] = {"rank": rank, "pt": pt, "lead": String(lead), "kind": kind}
		for t3 in _sorted_keys(by_token):
			var tok3: String = String(t3)
			var m: Dictionary = by_token[tok3]
			# sub-key: kind first, then most-proven first. 999 caps the
			# placement count so a wildly co-placed `family` edge can never
			# outrank a `named` one.
			var sub: int = int(m["rank"]) * 1000 - mini(int(m["pt"]), 999)
			_add(rows, seen, tok3, guests[tok3], 3, sub,
				"%s of %s, a lead of this chapter" % [String(m["kind"]), String(m["lead"])])

	# ── tier 4: building fabric, only to fill ────────────────────────────────
	if rows.size() < n:
		var fab: Array = []
		for t4 in tokens:
			var tok4: String = String(t4)
			if bool((guests[tok4] as Dictionary)["fabric"]):
				fab.append(tok4)
		if not fab.is_empty():
			var off: int = _hash32(chapter) % fab.size()
			for i in range(fab.size()):
				if rows.size() >= n:
					break
				var tok5: String = String(fab[(off + i) % fab.size()])
				if seen.has(tok5):
					continue
				_add(rows, seen, tok5, guests[tok5], 4, i,
					"building fabric — no argued guest was left for this chapter, and a wall with a vent on it is not plaster")

	_sort_rows(rows)
	var take: int = mini(n, rows.size())
	for i in range(take):
		var row: Dictionary = rows[i]
		out.append({
			"token": String(row["token"]),
			"axis": String(row["axis"]),
			"value": String(row["value"]),
			"gallery": String(row["gallery"]),
			"why": String(row["why"]),
		})
	return out


## One line for the museum's segment print.
static func summary(rows: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for r0 in rows:
		if not (r0 is Dictionary):
			continue
		var r: Dictionary = r0
		var s: String = String(r.get("token", "?"))
		var axis: String = String(r.get("axis", ""))
		if axis != "":
			s += "#%s=%s" % [axis, String(r.get("value", ""))]
		parts.append(s)
	return ", ".join(parts)


## Forget everything. For a tool that wants to re-scan after editing a manifest.
static func reset() -> void:
	_cache = {}
	_rel_cache = {}
	_rel_loaded = false
	_spine_cache = []
	_spine_loaded = false


# ── THE REGISTRY ─────────────────────────────────────────────────────────────

## token -> {alive, axes, sequences}. One pass over ~6.6 MB across 110 files.
## `live` short-circuits the disk check when the museum has already made it.
static func _scan_registry(live: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var dir: DirAccess = DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return out
	var files: Array = []
	for f in dir.get_files():
		var fname: String = String(f)
		if fname.ends_with(".json"):
			files.append(fname)
	files.sort()
	for f2 in files:
		var text: String = _read_text(REGISTRY_DIR + "/" + String(f2))
		if text.is_empty():
			continue
		var parsed: Variant = JSON.parse_string(text)
		if not (parsed is Dictionary):
			continue
		var arts: Variant = (parsed as Dictionary).get("artifacts", {})
		if not (arts is Dictionary):
			continue
		for lookup in (arts as Dictionary):
			var tok: String = String(lookup)
			# One token can appear in two registry files. The museum's own scan
			# lets the later file win; here ANY alive entry wins, which can only
			# ever be at least as permissive — a guest is never dropped because
			# a stale duplicate happened to sort first.
			var was: Variant = out.get(tok, null)
			if was is Dictionary and bool((was as Dictionary).get("alive", false)):
				continue
			var av: Variant = (arts as Dictionary)[lookup]
			if not (av is Dictionary):
				continue
			var a: Dictionary = av
			var alive: bool = false
			if not live.is_empty():
				alive = live.has(tok)
			else:
				var scene: String = String(a.get("scene", ""))
				# the museum's own gate, character for character: a missing
				# map_ready key reads as false, which is why exhibit_furniture
				# is not dealable. Copied rather than softened, so this module
				# and the corridor never disagree about who is alive.
				alive = scene != "" and bool(a.get("map_ready", false)) and ResourceLoader.exists(scene)
			out[tok] = {"alive": alive, "axes": _axes_of(a), "sequences": _seq_list(a)}
	return out


static func _axes_of(entry: Dictionary) -> Dictionary:
	var dv: Variant = entry.get("dna", null)
	if not (dv is Dictionary):
		return {}
	var av: Variant = (dv as Dictionary).get("axes", null)
	if av is Dictionary:
		return av as Dictionary
	return {}


static func _seq_list(entry: Dictionary) -> Array:
	var out: Array = []
	var v: Variant = entry.get("sequences", null)
	if not (v is Array):
		v = entry.get("map_sequences", null)
	if v is Array:
		for s in (v as Array):
			var t: String = String(s)
			if t != "" and not out.has(t):
				out.append(t)
	return out


## The gallery value, CONFIRMED against the registry. Takes the first manifest
## dna key that the registry declares as an axis on this token AND whose value
## appears in that axis's declared list. Anything else returns {} and the guest
## is dealt bare — a value the registry does not declare would be set, ignored,
## and silently replaced by the default, which is exactly the failure this
## project has paid for nine times.
static func _axis_value(rec: Dictionary, reg_entry: Dictionary) -> Dictionary:
	var axes: Dictionary = reg_entry.get("axes", {})
	if axes.is_empty():
		return {}
	var dnas: Array = rec["dna"]
	var gals: Array = rec["gal_of_dna"]
	for i in range(dnas.size()):
		var dna: Dictionary = dnas[i]
		for k in _sorted_keys(dna):
			var axis: String = String(k)
			if not axes.has(axis):
				continue
			var declared: Variant = axes[axis]
			if not (declared is Array):
				continue
			var want: String = String(dna[k])
			for d in (declared as Array):
				if String(d) == want:
					return {"axis": axis, "value": want,
						"gallery": String(gals[i]) if i < gals.size() else ""}
	return {}


# ── THE SPINE ────────────────────────────────────────────────────────────────

static func _spine_tokens() -> Dictionary:
	var out: Dictionary = {}
	var rows: Array = _spine_rows()
	for r0 in rows:
		if r0 is Dictionary:
			var t: String = String((r0 as Dictionary).get("lookup", ""))
			if t != "":
				out[t] = true
	return out


static func _chapter_leads(chapter: String) -> Array:
	var out: Array = []
	for r0 in _spine_rows():
		if not (r0 is Dictionary):
			continue
		var r: Dictionary = r0
		if String(r.get("sequence", "")) != chapter:
			continue
		var t: String = String(r.get("lookup", ""))
		if t != "" and not out.has(t):
			out.append(t)
	return out


## 799 rows, read once. guests_for() runs per segment and _chapter_leads walks
## the whole list every time; re-reading the file there would put a 100 kB parse
## on the streaming frame.
static func _spine_rows() -> Array:
	if _spine_loaded:
		return _spine_cache
	_spine_loaded = true
	var text: String = _read_text(SPINE_ORDER)
	if text.is_empty():
		return _spine_cache
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		var o: Variant = (parsed as Dictionary).get("order", [])
		if o is Array:
			_spine_cache = o as Array
	return _spine_cache


static func _relations() -> Dictionary:
	if _rel_loaded:
		return _rel_cache
	_rel_loaded = true
	var text: String = _read_text(RELATIONS)
	if text.is_empty():
		return _rel_cache
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		_rel_cache = parsed as Dictionary
	return _rel_cache


# ── GALLERY ROOTS ────────────────────────────────────────────────────────────

## Every directory that might hold *dna*/manifest.json, in priority order:
## explicit roots, then res://, then the sibling checkout beside this repo.
## Only existing ones come back.
static func _gallery_roots(extra: PackedStringArray) -> PackedStringArray:
	var want: PackedStringArray = PackedStringArray()
	for e in extra:
		want.append(String(e))
	want.append("res://" + GALLERY_SUBDIR)
	# The encyclopedia is a SIBLING checkout, not a subdirectory: res:// globalises
	# to .../GitHub/AdaResearch_46/, and the galleries are at
	# .../GitHub/ada_encyclopedia/public. Built by stripping one path element
	# rather than by appending "..", so no simplify_path is needed and a Windows
	# drive prefix cannot be eaten by the collapse.
	var here: String = ProjectSettings.globalize_path("res://").rstrip("/")
	if here != "":
		want.append(here.get_base_dir().path_join(GALLERY_SUBDIR))
	var out: PackedStringArray = PackedStringArray()
	for w in want:
		var p: String = String(w)
		if p == "" or out.has(p):
			continue
		if DirAccess.open(p) != null:
			out.append(p)
	return out


static func _sorted_dirs(root: String) -> PackedStringArray:
	var d: DirAccess = DirAccess.open(root)
	if d == null:
		return PackedStringArray()
	var names: Array = []
	for n in d.get_directories():
		names.append(String(n))
	names.sort()
	var out: PackedStringArray = PackedStringArray()
	for n2 in names:
		out.append(String(n2))
	return out


static func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()


# ── NAME MATCHING ────────────────────────────────────────────────────────────

## Lowercase, alphanumerics only. "array_tutorial" -> "arraytutorial",
## "props-dna-gallery" -> "propsdnagallery".
static func _norm(s: String) -> String:
	var out: String = ""
	var low: String = s.to_lower()
	for i in range(low.length()):
		var c: int = low.unicode_at(i)
		if (c >= 48 and c <= 57) or (c >= 97 and c <= 122):
			out += low.substr(i, 1)
	return out


## A gallery name with its packaging removed: "randomness-dna" -> "randomness",
## "critter-dna-gallery" -> "critter", "ceiling-dna-renders" -> "ceiling".
static func _stem(gallery: String) -> String:
	var n: String = _norm(gallery)
	var changed: bool = true
	while changed:
		changed = false
		for suf in ["gallery", "renders", "dna"]:
			var s: String = String(suf)
			if n.length() > s.length() and n.ends_with(s):
				n = n.substr(0, n.length() - s.length())
				changed = true
	return n


static func _touches(stem: String, chapters: PackedStringArray) -> bool:
	for c in chapters:
		var cn: String = String(c)
		if cn == "":
			continue
		if cn.contains(stem) or stem.contains(cn):
			return true
	return false


## FNV-1a, 32 bits, written out rather than using String.hash() so the rotation
## a chapter gets is a property of this file and cannot drift with the engine.
static func _hash32(s: String) -> int:
	var h: int = 2166136261
	for i in range(s.length()):
		h = (h ^ s.unicode_at(i)) & 0xFFFFFFFF
		h = (h * 16777619) & 0xFFFFFFFF
	return h


# ── ROWS ─────────────────────────────────────────────────────────────────────

static func _add(rows: Array, seen: Dictionary, token: String, g: Dictionary,
		tier: int, sub: int, why: String) -> void:
	if token == "" or seen.has(token):
		return
	seen[token] = true
	var axis: String = String(g.get("axis", ""))
	rows.append({
		"token": token,
		"axis": axis,
		"value": String(g.get("value", "")),
		"gallery": String(g.get("gallery", "")),
		"tier": tier,
		# 0 sorts first: a guest that can be dealt at a rendered value outranks
		# one that can only be dealt at its default.
		"ax": 0 if axis != "" else 1,
		"sub": sub,
		"why": "%s [tier %d]" % [why, tier],
	})


## Insertion sort on a declared total order — tier, then axis-carrying, then the
## tier's own key, then the token name. No lambda, no untyped element inference,
## and no ties, so a chapter returns the same guests on every run.
static func _sort_rows(arr: Array) -> void:
	for i in range(1, arr.size()):
		var v: Dictionary = arr[i]
		var j: int = i - 1
		while j >= 0:
			var w: Dictionary = arr[j]
			if not _row_before(v, w):
				break
			arr[j + 1] = w
			j -= 1
		arr[j + 1] = v


static func _row_before(a: Dictionary, b: Dictionary) -> bool:
	var at: int = int(a["tier"])
	var bt: int = int(b["tier"])
	if at != bt:
		return at < bt
	var aa: int = int(a["ax"])
	var ba: int = int(b["ax"])
	if aa != ba:
		return aa < ba
	var asu: int = int(a["sub"])
	var bsu: int = int(b["sub"])
	if asu != bsu:
		return asu < bsu
	return String(a["token"]) < String(b["token"])


## Dictionary keys as a sorted Array of String. Insertion order is deterministic
## in GDScript, but it is deterministic in FILE order, and this module reads
## three files that other passes rewrite; sorting makes the guest list a
## property of the data rather than of the last tool that touched it.
static func _sorted_keys(d: Dictionary) -> Array:
	var out: Array = []
	for k in d:
		out.append(String(k))
	out.sort()
	return out
