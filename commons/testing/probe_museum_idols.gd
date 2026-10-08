extends SceneTree

## DOES THE FETISH IDOL ACTUALLY STAND IN A MUSEUM HALL? (2026-09-03)
##
## fetish_idol is the 42nd dream body and the only one unlike the other 41: ONE
## marched isosurface (dream_iso.gd) wearing a ShaderMaterial (dream_gloss via
## dream_shaders.gd), two MeshInstance3D where the others build 40-260, and about
## 1.7 s of marching at its shipped CELL of 0.034. Every one of those differences
## is a way for it to end up in a hall as NOTHING — an empty plinth, a grey blob,
## or a hall the visitor cannot cross — while every stage upstream reports green.
## So this probe stands in the museum and looks.
##
## It asserts, each with a printed NUMBER rather than a boolean:
##   1. a hall carries a dream body whose figure is fetish_idol
##   2. that body's largest mesh has more than MIN_TRIS triangles and wears a
##      ShaderMaterial in material_override — which together are the only proof
##      the isosurface MARCHED. A field that yields nothing pushes a warning and
##      returns, leaving a node with no mesh at all; a fallback to a
##      StandardMaterial3D would look like a statue and be the wrong family.
##   3. it stands ON its plinth: origin at the plinth's own top (read from
##      em_layout sculptures.plinth_m and the plinth node's own y, never the
##      literal 0.42), and its merged AABB bottom neither floating nor sunk.
##   4. ACROSS HALLS the family's own axis values are not all identical. This is
##      the whole point of the pass: the corpus notes that exactly ONE map in the
##      project has ever placed an artifact at a non-default axis value, so a
##      museum that deals 200 halls of surface=latex harness=bare has shipped a
##      singleton wearing a family's name. The axis NAMES and their legal values
##      are derived from the family's own axes(), never transcribed — a declared
##      value that is not a code value is refused in silence (Object.set() on a
##      typed property), which is the corpus's most expensive measurement trap.
##   5. the hall is still WALKABLE after the statue erased its cell, judged with
##      the museum's OWN rule — _reaches_all(), the same flood _seal_cells() runs
##      before it agrees to seal anything — rather than a second flood fill here.
##      A rule with two implementations drifts; the long-museum strip cost a
##      session proving that. NOTE THAT THE SCULPTURE LANE NEVER ASKS THIS: it
##      erases _walk_cells[c] and writes _walk_erased[c] directly (endless_museum
##      .gd:13973), bypassing _seal_cells and its reach test, so nothing upstream
##      of this probe has ever checked whether a statue severed its hall.
##      AND IT IS ASKED AS A COUNTERFACTUAL. Measured 2026-09-03: six of eight
##      halls reported 20-66 unreachable cells, and putting the idol's cell back
##      changed NONE of them. Those halls are in pieces on their own — a
##      court behind the threshold gate, a band that spans a porch — so an
##      absolute reach count cannot tell "the idol severed this hall" from "this
##      hall arrived severed", and a probe that cannot tell the difference cries
##      wolf on every hall and gets ignored. The verdict is the DELTA: count with
##      the cell erased, put it back, count again, and the difference is the
##      idol's own bill. The absolute counts are still printed, as a note.
##
## THE CHANGE THIS IS WAITING FOR. The museum is to gain three things:
##   (a) em_layout.json sculptures.pin — chapter name -> forced figure
##   (b) the per-hall config dict carrying the family's OWN axis values, dealt
##       from the hall key the way figure and seed already are
##   (c) a cell override in that same config, so the museum can march coarser
##       than the family's shipped CELL and not pay 1.7 s a hall
## Until (a) lands this probe cannot know which chapter to open, so it says so by
## name, boots FALLBACK_CHAPTER anyway, and reports which figure the museum DOES
## deal there — a probe that fails for the right reason is still evidence.
##
## WHY NOT --em-bake-n. The brief asked for it to keep the run small. It cannot be
## used from here: --em-bake-n= sets _bake_mode, and bake mode MERGES into and
## rewrites ada_run/em_bake.json (endless_museum.gd:1279-1285), the derived truth
## the whole museum replays from, and then quits itself at _bake_total. A probe
## must not rewrite a shared cache to ask a question. The run is kept small the
## way probe_museum_sculptures.gd and probe_grey_halls.gd keep it small: pin the
## streaming window open and call _build_segment exactly SEGMENTS times.
##
## IT STILL WRITES ada_run/em_bake.json, and so does every other museum probe.
## _heal_bake (endless_museum.gd:9566) writes a live-measured segment's verdicts
## back on ANY desktop boot whose plan lives under res://ada_run — walking the
## museum is how the bake heals. Measured here: 8 halls healed in one run. That
## is the museum's design, not this probe's doing, but with four agents on the
## tree it is worth knowing that booting the museum dirties a shared derived file.
##
## Measured 2026-09-03: 36-55 s wall clock for 2 chapters x 4 segments, of which
## a segment carrying an idol costs 656-3250 ms (the high figure is the first
## boot, before the shader and the resource caches are warm).
##
##   python tools/godot_watchdog.py --expect=ada_run/museum_idols_probe.txt --grace=300 --stall=60 -- \
##     "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --headless --path . --xr-mode off \
##     --script res://commons/testing/probe_museum_idols.gd

const MUSEUM := "res://commons/scenes/endless_museum.tscn"
const TRIAL := "res://ada_run/_trial_idol_control.json"
const REPORT := "res://ada_run/museum_idols_probe.txt"
const LAYOUT := "res://commons/data/em_layout.json"
const FAMILY := "res://commons/artifacts/dream_bodies/bodies/fetish_idol.gd"
const PARENT := "res://commons/artifacts/dream_bodies/dream_bodies.gd"
const FIGURE := "fetish_idol"

## More triangles than any primitive body's largest single mesh, and far fewer
## than a 0.034-cell march of a 1.7 m body yields. It separates "the field
## marched" from "a box stood in for it".
const MIN_TRIS := 3000
const SEGMENTS := 4              # enough halls to judge variety, few enough to boot
const MAX_CHAPTERS := 2          # a pin may name many; two is already several halls
const FALLBACK_CHAPTER := "primitives"

## endless_museum.gd's own SEAL_PROBE_CELLS (line 12810) and VESTIBULE_H (line
## 231). A probe cannot read a const off an instance — Object.get() sees
## properties, not constants — so these are the one place this file repeats the
## museum. If either drifts the reach test degrades to "start from the band cell
## nearest where the save point should be", which is why that fallback exists.
const REACH_LIMIT := 4000
const VEST_H := 4

## The plinth is 0.85 m wide and the body sets its own AABB bottom to its origin,
## but fetish_idol carries a matte slab of its own that hangs below that origin,
## so the merged AABB bottom sits UNDER the plinth top by a few cm by design.
## Floating is the failure; a small sink is the family.
const SINK_MAX := 0.12
const FLOAT_MAX := 0.02
const ORIGIN_TOL := 0.02

var _lines: Array[String] = []
var _fails: Array[String] = []
var _idols: Array = []        # one record per hall that carried a fetish_idol
var _other: Dictionary = {}   # figure -> count, for halls that carried something else


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var t0: int = Time.get_ticks_msec()
	_lines.append("[probe] === museum idols — does %s stand in a hall, and is it the same one twice?" % FIGURE)

	# THE FAMILY DECLARES ITS OWN AXES AND ITS OWN CELL. Derived, never typed
	# here: a probe that transcribes a value list checks the transcription.
	var fam: Script = load(FAMILY) as Script
	if fam == null:
		_check(false, "family script %s: 0 bytes loaded" % FAMILY, "the family does not load")
		_finish(t0)
		return
	var axes: Dictionary = {}
	if fam.has_method("axes"):
		var av: Variant = fam.call("axes")
		if av is Dictionary:
			axes = av
	var consts: Dictionary = fam.get_script_constant_map()
	var cell_default: float = float(consts.get("CELL", 0.0))
	var n_values: int = 0
	for ak in axes:
		n_values += (axes[ak] as Array).size()
	_check(axes.size() >= 1 and n_values >= 2,
		"%s declares %d axis/axes, %d value(s) total: %s" % [FIGURE, axes.size(), n_values, str(axes)],
		"the family declares no axes — nothing to deal per hall")
	_check(cell_default > 0.0,
		"%s ships CELL %.4f m (the march this pass wants to make cheaper)" % [FIGURE, cell_default],
		"the family has no CELL constant")

	# The parent artifact's enum guard. apply_grid_config() refuses a figure that
	# is not in DreamBodies.FIGURES, IN SILENCE, and leaves the previous body
	# standing. The museum's own lane sets `figure` directly first so it survives
	# that guard — but any OTHER caller (a map token, the DNA sweep) would get a
	# rocaille and never be told. Reported, not failed: the museum lane is the
	# subject of this probe, and the parent artifact is another agent's file.
	var parent_s: Script = load(PARENT) as Script
	var known: Array = []
	if parent_s != null:
		known = parent_s.get_script_constant_map().get("FIGURES", [])
	_note("dream_bodies.FIGURES lists %d figure(s); %s is %s — a map token or the DNA sweep reaching apply_grid_config() with an unlisted figure is refused in SILENCE" % [
		known.size(), FIGURE, "PRESENT" if known.has(FIGURE) else "ABSENT"])

	# (a) which chapter is pinned to this figure
	var chapters: Array = _pinned_chapters()
	if chapters.is_empty():
		_check(false,
			"%s sculptures.pin: 0 chapter(s) pinned to %s" % [LAYOUT, FIGURE],
			"em_layout.json has no sculptures.pin naming %s — the museum change (a) is not in yet" % FIGURE)
		chapters = [FALLBACK_CHAPTER]
		_lines.append("[probe] booting %s anyway, to report which figure the museum DOES deal there" % FALLBACK_CHAPTER)
	else:
		_check(true, "%s sculptures.pin: %d chapter(s) pinned to %s (%s)" % [
			LAYOUT, chapters.size(), FIGURE, ", ".join(PackedStringArray(chapters))], "")

	for ch_v in chapters:
		await _walk(String(ch_v), axes, cell_default)

	_judge(axes)
	_finish(t0)


## em_layout.json sculptures.pin, read the way the museum's _layout_map reads it:
## a section holding an object, absent key meaning "no ruling anywhere".
func _pinned_chapters() -> Array:
	if not FileAccess.file_exists(LAYOUT):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	if not (parsed is Dictionary):
		return []
	var sec: Variant = (parsed as Dictionary).get("sculptures")
	if not (sec is Dictionary):
		return []
	var pin: Variant = (sec as Dictionary).get("pin")
	if not (pin is Dictionary):
		return []
	var out: Array = []
	for k in (pin as Dictionary):
		# str(), not String(): a JSON cell throws through the String constructor
		if str((pin as Dictionary)[k]) == FIGURE:
			out.append(str(k))
		if out.size() >= MAX_CHAPTERS:
			break
	return out


func _walk(chapter: String, axes: Dictionary, cell_default: float) -> void:
	# A TRIAL CONTROL, so the live session's resume, overrides and hand survive
	# this boot — and because a saved resume outranks --em-map, the chapter is
	# chosen here rather than on the command line.
	var ctl := FileAccess.open(TRIAL, FileAccess.WRITE)
	if ctl == null:
		_check(false, "%s: 0 bytes of trial control written" % chapter, "cannot write %s" % TRIAL)
		return
	ctl.store_string(JSON.stringify({"first_chapter": chapter, "dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	var ps: PackedScene = load(MUSEUM) as PackedScene
	if ps == null:
		_check(false, "%s: the museum scene did not load" % chapter, "no %s" % MUSEUM)
		return
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("EM_CONTROL", TRIAL)
	inst.set("_overrides_path", "res://ada_run/_trial_idol_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_idol_hand.json")
	inst.set("start_chapter", chapter)
	inst.set("start_map", "")
	get_root().add_child(inst)
	await create_timer(1.0).timeout
	# hold the streaming window open, so nothing built is freed behind us
	inst.set("MIN_SEGMENTS", 99)
	inst.set("KEEP_AHEAD_M", 99999.0)
	inst.set("KEEP_BEHIND_M", 99999.0)
	var seg_ms: Array = []
	for i in range(SEGMENTS):
		if (inst.get("_segments") as Array).size() >= SEGMENTS:
			break
		var t: int = Time.get_ticks_msec()
		inst.call("_build_segment")
		seg_ms.append(Time.get_ticks_msec() - t)
		await create_timer(0.3).timeout
	inst.call("flush_stamps")
	await create_timer(0.9).timeout    # a wall work hangs one physics frame later

	var walk: Dictionary = inst.get("_walk_cells")
	var erased: Dictionary = inst.get("_walk_erased")
	var plinth_m: float = float(inst.call("_L", "sculptures", "plinth_m", 0.42))
	var on: float = float(inst.call("_L", "sculptures", "on", 1.0))
	var bodies_on: float = float(inst.call("_L", "stream", "bodies", 1.0))
	var segs: Array = inst.get("_segments")
	var slowest: int = 0
	for m in seg_ms:
		slowest = maxi(slowest, int(m))
	_lines.append("[probe] --- %s: %d segment(s) built, slowest %d ms, sculptures.on %.0f, stream.bodies %.0f, plinth_m %.2f, walk map %d cell(s)" % [
		chapter, segs.size(), slowest, on, bodies_on, plinth_m, walk.size()])
	# the museum's own reader, so a pin written in a shape _layout_map cannot see
	# shows up as a disagreement with the file rather than as nothing at all
	if inst.has_method("_layout_map"):
		var live_pin: Dictionary = inst.call("_layout_map", "sculptures", "pin")
		_lines.append("[probe]   _layout_map(sculptures, pin) sees %d entry/entries" % live_pin.size())

	for s_v in segs:
		var s: Dictionary = s_v
		var node: Node3D = s.get("node") as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var ch: String = String(node.get_meta("em_chapter")) if node.has_meta("em_chapter") else ""
		if ch != chapter:
			continue
		var pearl: String = str(node.get_meta("em_pearl")) if node.has_meta("em_pearl") else ""
		var tag: String = "%s|%s" % [ch, pearl]
		var body: Node3D = null
		var plinth: Node3D = null
		for c in node.get_children():
			if c.has_meta("em_sculpture") and c is Node3D and body == null:
				body = c as Node3D
			if String(c.name).begins_with("ArtPlinth") and c is Node3D and plinth == null:
				plinth = c as Node3D
		if body == null:
			_lines.append("[probe]   %s: 0 sculptures in this hall" % tag)
			continue
		var fig: String = str(body.get("figure"))
		if fig != FIGURE:
			_other[fig] = int(_other.get(fig, 0)) + 1
			_lines.append("[probe]   %s: the museum dealt %s here, not %s" % [tag, fig, FIGURE])
			continue

		# ---- the body itself -------------------------------------------------
		var meshes: Array = []
		_collect(body, meshes)
		var big_tris: int = 0
		var total_tris: int = 0
		var big: MeshInstance3D = null
		var n_shader: int = 0
		for mi_v in meshes:
			var mi: MeshInstance3D = mi_v
			var t: int = _tris(mi.mesh)
			total_tris += t
			if t > big_tris:
				big_tris = t
				big = mi
			if mi.material_override is ShaderMaterial:
				n_shader += 1
		var shader_name: String = ""
		if big != null and big.material_override is ShaderMaterial:
			var sm: ShaderMaterial = big.material_override as ShaderMaterial
			shader_name = sm.shader.resource_path if sm.shader != null else "(no shader)"

		# ---- where it stands --------------------------------------------------
		var aabb: AABB = _merged_aabb(meshes)
		var origin_y: float = body.global_position.y
		var plinth_top: float = (plinth.global_position.y + plinth_m) if plinth != null else plinth_m
		var bottom_gap: float = aabb.position.y - plinth_top   # + floats, - sinks

		# ---- the cell it erased, and whether the hall survived it -------------
		var p: Vector3 = body.global_position
		var cell := Vector2i(int(floor(p.x)), int(floor(p.z)))
		var prov: String = str(erased.get(cell, ""))
		var reach: Dictionary = _hall_reach(inst, float(s.get("z0", 0.0)), float(s.get("z1", 0.0)), int(s.get("w", 0)), cell)

		# ---- what the museum dealt it ----------------------------------------
		var dealt: Dictionary = {}
		var extra: Dictionary = {}
		for m_v in body.get_meta_list():
			var mname: String = String(m_v)
			if not mname.begins_with("config_"):
				continue
			var key: String = mname.substr(7)
			if key == "figure" or key == "seed":
				continue
			if axes.has(key):
				dealt[key] = str(body.get_meta(mname))
			else:
				extra[key] = body.get_meta(mname)

		_idols.append({"tag": tag, "seed": int(body.get("seed")), "meshes": meshes.size(),
			"big_tris": big_tris, "total_tris": total_tris, "n_shader": n_shader,
			"shader": shader_name, "origin_y": origin_y, "plinth_top": plinth_top,
			"plinth": plinth != null, "bottom_gap": bottom_gap, "cell": cell, "prov": prov,
			"reach": reach, "dealt": dealt, "extra": extra, "cell_default": cell_default,
			"slowest_ms": slowest})

	inst.queue_free()
	await create_timer(0.5).timeout


## The hall's walk cells, how many of them the visitor can still reach from the
## save point, and — the verdict — how many of them the IDOL cost. Asked with the
## museum's OWN flood (_reaches_all), the one _seal_cells runs before it agrees
## to seal a footprint, so this file does not carry a second implementation of a
## rule the museum already owns.
func _hall_reach(inst: Node3D, z0: float, z1: float, w: int, cell: Vector2i) -> Dictionary:
	var walk: Dictionary = inst.get("_walk_cells")
	var band: Array = []
	for k_v in walk:
		var k: Vector2i = k_v
		if float(k.y) >= z0 and float(k.y) < z1:
			band.append(k)
	if band.is_empty():
		return {"total": 0, "reach": 0, "free": 0, "cost": 0, "from": Vector2i.ZERO,
			"map": walk.size(), "nb": 0, "seal": true, "restored": true}
	# the save point, where the visitor arrives — the same cell the sculpture
	# lane keeps clear_m away from
	var want := Vector2i(int(floor(float(w) / 2.0 + 0.5)), int(floor(z0 + float(VEST_H) - 1.5)))
	var from: Vector2i = want
	if not walk.has(from):
		var best: float = 1.0e9
		for k2_v in band:
			var k2: Vector2i = k2_v
			var d: float = Vector2(float(k2.x), float(k2.y)).distance_to(Vector2(float(want.x), float(want.y)))
			if d < best:
				best = d
				from = k2
	var reach: int = _count(inst, from, band)

	# THE MUSEUM'S OWN SEAL RULE, applied to a cell the museum sealed without
	# asking it: the still-walkable neighbours of the idol's cell must still
	# reach each other. One neighbour or none is a pocket nothing ever routed
	# through — _seal_cells:13472 says so in exactly these words.
	var nb: Array = []
	for d2 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n2: Vector2i = cell + d2
		if walk.has(n2):
			nb.append(n2)
	var seal: bool = nb.size() <= 1 or bool(inst.call("_reaches_all", nb[0], nb, REACH_LIMIT))

	# THE COUNTERFACTUAL. Put the idol's cell back, count again, and put it back
	# the way it was. Mutating the live _walk_cells is the only way to ask this,
	# so the restore is asserted rather than assumed — the next hall in this same
	# boot is measured against this dictionary.
	# The count is taken over the SAME band both times — the idol's own cell is
	# never a target, only a stepping stone. The first cut of this added the cell
	# to the band and subtracted one, which read -1 on two halls: subtracting a
	# cell the flood never reached. A hall cannot lose reach by gaining a cell,
	# so a negative cost was the probe's arithmetic and not the museum's museum.
	var was_walkable: bool = walk.has(cell)
	walk[cell] = true
	var free_reach: int = _count(inst, from, band)
	if not was_walkable:
		walk.erase(cell)
	var restored: bool = walk.has(cell) == was_walkable
	return {"total": band.size(), "reach": reach, "free": free_reach,
		"cost": free_reach - reach, "from": from, "map": walk.size(),
		"nb": nb.size(), "seal": seal, "restored": restored}


## How many of `band` the flood reaches from `from`. The whole-set question is
## asked first because it is one flood; the per-cell pass is only paid for when
## the answer is no, and it exists so a failure prints a COUNT of marooned cells
## instead of the word "false".
func _count(inst: Node3D, from: Vector2i, band: Array) -> int:
	if bool(inst.call("_reaches_all", from, band, REACH_LIMIT)):
		return band.size()
	var n: int = 0
	for k in band:
		if bool(inst.call("_reaches_all", from, [k], REACH_LIMIT)):
			n += 1
	return n


func _judge(axes: Dictionary) -> void:
	# 1. it is there at all
	_check(_idols.size() >= 1,
		"halls carrying a %s: %d (other figures dealt: %s)" % [FIGURE, _idols.size(),
			str(_other) if not _other.is_empty() else "none"],
		"no hall carried a %s — the museum never dealt this family" % FIGURE)
	if _idols.is_empty():
		return

	var pairs: Dictionary = {}
	var seeds: Dictionary = {}
	for r_v in _idols:
		var r: Dictionary = r_v
		var tag: String = String(r["tag"])

		# 2. the isosurface marched, and it wears a shader
		_check(int(r["big_tris"]) > MIN_TRIS,
			"%s: largest mesh %d triangles (%d total across %d MeshInstance3D, want > %d)" % [
				tag, int(r["big_tris"]), int(r["total_tris"]), int(r["meshes"]), MIN_TRIS],
			"%s: the field did not march — largest mesh %d triangles" % [tag, int(r["big_tris"])])
		_check(int(r["n_shader"]) >= 1 and String(r["shader"]) != "",
			"%s: %d of %d mesh(es) carry a ShaderMaterial, largest wears %s" % [
				tag, int(r["n_shader"]), int(r["meshes"]), String(r["shader"]) if String(r["shader"]) != "" else "no ShaderMaterial"],
			"%s: no ShaderMaterial on the body — it fell back to a standard skin" % tag)

		# 3. on the plinth
		_check(bool(r["plinth"]), "%s: plinth present %s" % [tag, str(r["plinth"])], "%s: no plinth under the idol" % tag)
		_check(absf(float(r["origin_y"]) - float(r["plinth_top"])) < ORIGIN_TOL,
			"%s: origin y %.3f, plinth top %.3f, off by %.3f m (tol %.2f)" % [
				tag, float(r["origin_y"]), float(r["plinth_top"]),
				float(r["origin_y"]) - float(r["plinth_top"]), ORIGIN_TOL],
			"%s: the idol is not standing at the plinth's top" % tag)
		var gap: float = float(r["bottom_gap"])
		_check(gap <= FLOAT_MAX and gap >= -SINK_MAX,
			"%s: AABB bottom %+.3f m relative to the plinth top (float < %.2f, sink > %.2f)" % [
				tag, gap, FLOAT_MAX, -SINK_MAX],
			"%s: the idol %s its plinth by %.3f m" % [tag, "floats above" if gap > 0.0 else "sinks into", absf(gap)])

		# 4. the axis values it was dealt — names and legal values from the code
		var dealt: Dictionary = r["dealt"]
		var missing: Array = []
		var illegal: Array = []
		for ak in axes:
			if not dealt.has(ak):
				missing.append(String(ak))
			elif not (axes[ak] as Array).has(dealt[ak]):
				illegal.append("%s=%s" % [String(ak), str(dealt[ak])])
		_check(missing.is_empty(),
			"%s: dealt %d of %d declared axis/axes %s" % [tag, dealt.size(), axes.size(), str(dealt)],
			"%s: the hall config carries no value for %s — the museum change (b) is not in yet" % [tag, ", ".join(PackedStringArray(missing))])
		_check(illegal.is_empty(),
			"%s: %d illegal axis value(s)" % [tag, illegal.size()],
			"%s: %s is not a value this family's axes() declares — Object.set() refuses it in SILENCE" % [tag, ", ".join(PackedStringArray(illegal))])
		var key: String = "|".join(PackedStringArray(_pair_of(dealt, axes)))
		pairs[key] = int(pairs.get(key, 0)) + 1
		seeds[int(r["seed"])] = true

		# (c) the cell override, and what it bought
		var cell_over: float = -1.0
		var cell_key: String = ""
		for ek in (r["extra"] as Dictionary):
			if String(ek).findn("cell") >= 0:
				cell_key = String(ek)
				cell_over = float((r["extra"] as Dictionary)[ek])
		_check(cell_over > 0.0,
			"%s: cell override %s = %.4f m against the family's %.4f m; slowest segment build %d ms" % [
				tag, cell_key if cell_key != "" else "(none)", cell_over, float(r["cell_default"]), int(r["slowest_ms"])],
			"%s: the hall config carries no cell override (extra keys: %s) — the museum change (c) is not in yet" % [
				tag, str((r["extra"] as Dictionary).keys())])
		if cell_over > 0.0:
			_check(cell_over >= float(r["cell_default"]),
				"%s: the override marches %.2fx coarser than the family default" % [tag, cell_over / maxf(float(r["cell_default"]), 0.0001)],
				"%s: the override marches FINER than the family default — the museum made the 1.7 s worse" % tag)

		# 5. the hall survived the erasure
		var reach: Dictionary = r["reach"]
		_check(String(r["prov"]) == "art:dream_bodies",
			"%s: cell %s out of the walk map, provenance %s" % [tag, str(r["cell"]),
				String(r["prov"]) if String(r["prov"]) != "" else "(still walkable)"],
			"%s: the walker can walk through the idol" % tag)
		_note("%s: %d of %d hall walk cells reachable from %s; without the idol %d — the hall's own %d unreachable cell(s) are not this statue's doing (museum walk map %d, flood valve %d)" % [
			tag, int(reach["reach"]), int(reach["total"]), str(reach["from"]), int(reach["free"]),
			int(reach["total"]) - int(reach["free"]), int(reach["map"]), REACH_LIMIT])
		_check(int(reach["total"]) > 0 and int(reach["cost"]) == 0,
			"%s: the idol cost the hall %d walk cell(s) of reach (%d reachable with it, %d without)" % [
				tag, int(reach["cost"]), int(reach["reach"]), int(reach["free"])],
			"%s: the idol marooned %d hall cell(s) that were reachable without it" % [tag, int(reach["cost"])])
		_check(bool(reach["seal"]),
			"%s: the museum's own seal rule over the idol cell's %d walkable neighbour(s): they still reach each other" % [tag, int(reach["nb"])],
			"%s: the idol's cell was a hinge — _seal_cells would have REFUSED this seal, but the sculpture lane never asks" % tag)
		_check(bool(reach["restored"]),
			"%s: the live walk map restored after the counterfactual: %s" % [tag, str(reach["restored"])],
			"%s: the probe left the museum's walk map dirty — every later hall in this boot is suspect" % tag)

	# 4, across halls: the whole reason this pass exists
	_check(pairs.size() >= 2 or _idols.size() < 2,
		"variety: %d distinct axis pair(s) across %d hall(s) — %s; %d distinct seed(s)" % [
			pairs.size(), _idols.size(), str(pairs), seeds.size()],
		"every hall got the SAME axis values (%s) — a family shipped as a singleton" % str(pairs.keys()))
	_check(_idols.size() >= 2,
		"variety judged over %d hall(s)" % _idols.size(),
		"only %d hall carried an idol — too few to tell a family from a singleton" % _idols.size())


## The dealt values in the family's own axis order, so two halls compare as one
## string. Order comes from axes(), not from the meta list, whose order is the
## museum's insertion order and could differ between halls.
func _pair_of(dealt: Dictionary, axes: Dictionary) -> Array:
	var out: Array = []
	for ak in axes:
		out.append("%s=%s" % [String(ak), str(dealt.get(ak, "?"))])
	return out


func _collect(n: Node, out: Array) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)


## Triangles in a mesh. ArrayMesh answers from its index buffer without building
## anything; every other Mesh has to be asked for its faces.
func _tris(m: Mesh) -> int:
	if m == null:
		return 0
	if m is ArrayMesh:
		var am: ArrayMesh = m as ArrayMesh
		var n: int = 0
		for i in range(am.get_surface_count()):
			var idx: int = am.surface_get_array_index_len(i)
			n += (idx if idx > 0 else am.surface_get_array_len(i)) / 3
		return n
	return m.get_faces().size() / 3


func _merged_aabb(meshes: Array) -> AABB:
	var acc := AABB()
	var got: bool = false
	for mi_v in meshes:
		var mi: MeshInstance3D = mi_v
		var b: AABB = mi.global_transform * mi.get_aabb()
		if got:
			acc = acc.merge(b)
		else:
			acc = b
			got = true
	return acc


func _note(line: String) -> void:
	_lines.append("[probe] note  %s" % line)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok and why != "":
		_fails.append(why)


func _finish(t0: int) -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %d check(s) failed, %.1f s" % [_fails.size(), float(Time.get_ticks_msec() - t0) / 1000.0])
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(PackedStringArray(_fails))])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	else:
		print("[probe] could not write %s" % REPORT)
	for l in _lines:
		print(l)
	quit(0 if ok else 1)
