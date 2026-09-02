extends SceneTree
## A TRANSPORT CUBE MUST CROSS THE SAME VOID IN THE MUSEUM AS IN THE GRID
## (2026-09-02, Palle: "make sure that the transport cube work the same way in
## the endless museum as in the grid, they only work in the grid").
##
## Two implementations of one rule had drifted. The grid reads a `tc` cell in
## GridUtilitiesComponent's "tc" branch; the endless museum read the same cell
## again in its own _utility_apply_params. A second implementation of one rule
## drifts, so this probe holds the GRID's semantics as the reference and asks
## UtilityRegistry.transport_params — the one implementation both callers now
## use — the same questions.
##
##   1  the grid's own rule, restated, agrees with the shared function on every
##      distinct tc token in the corpus
##   2  the OLD museum rule disagreed, and the probe says where — this is the
##      negative test: it must find real disagreements, or the probe is not
##      measuring the thing that was broken
##   3  a live transport_cube configured through the shared function computes the
##      target the parameters asked for
##   4  a cube made carriable sees a body on the default layer; an untouched one
##      does not, which is why the museum walker was never carried

const SCENE := "res://commons/scenes/mapobjects/transport_cube.tscn"

## THE REFERENCE. GridUtilitiesComponent.gd's "tc" branch, restated: six named
## axes, a comma triple, anything else leaves the cube's exported default (+X),
## and auto only when a third parameter says the word.
func grid_reference(params: Array) -> Dictionary:
	var out := {"distance": 4.0, "direction": Vector3(1, 0, 0), "auto": false, "applied": false}
	if params.size() < 2:
		return out                       # the grid sets nothing at all
	out["applied"] = true
	out["distance"] = float(params[0])
	var dp := String(params[1]).to_lower()
	match dp:
		"x": out["direction"] = Vector3(1, 0, 0)
		"y": out["direction"] = Vector3(0, 1, 0)
		"z": out["direction"] = Vector3(0, 0, 1)
		"-x": out["direction"] = Vector3(-1, 0, 0)
		"-y": out["direction"] = Vector3(0, -1, 0)
		"-z": out["direction"] = Vector3(0, 0, -1)
		_:
			var coords := dp.split(",")
			if coords.size() >= 3:
				out["direction"] = Vector3(coords[0].to_float(), coords[1].to_float(), coords[2].to_float())
	if params.size() >= 3:
		out["auto"] = String(params[2]).strip_edges().to_lower() == "auto"
	return out

## THE OLD MUSEUM RULE, kept only so the probe can prove it differed.
func museum_old(params: Array) -> Dictionary:
	var dist: float = float(params[0]) if params.size() > 0 and String(params[0]).is_valid_float() else 4.0
	var axis: String = String(params[1]) if params.size() > 1 else "z"
	var dir := Vector3(1, 0, 0) if axis == "x" else (Vector3(0, 1, 0) if axis == "y" else Vector3(0, 0, 1))
	var auto: bool = true if params.size() <= 2 else String(params[2]) == "auto"
	return {"distance": dist, "direction": dir, "auto": auto}

func params_of(token: String) -> Array:
	var parsed: Dictionary = UtilityRegistry.parse_utility_cell(token)
	return parsed.get("parameters", [])

## Every distinct tc token standing in commons/maps today, with its count, most
## common first. Gathered 2026-09-02; the shape of the corpus, not a guess.
const CORPUS := [
	["tc:1:auto:auto", 425], ["tc:3:y", 11], ["tc:10:y", 7], ["tc:4:y:auto", 6],
	["tc:7:y:auto", 4], ["tc:3:z", 4], ["tc:1:y:auto", 4], ["tc:2:y", 3],
	["tc:y:1", 2], ["tc:6:y", 2], ["tc:3:x", 2], ["tc:2:y:auto", 2],
	["tc:2:x", 2], ["tc:9:z", 1],
	# forms the corpus does not use yet and the grid has always accepted
	["tc:3:-z", 0], ["tc:2:-x", 0], ["tc:5:-y", 0], ["tc:4:1,0,0", 0], ["tc:4:0,0,-1", 0],
]

func same(a: Dictionary, b: Dictionary) -> bool:
	return absf(float(a["distance"]) - float(b["distance"])) < 1e-6 \
		and (a["direction"] as Vector3).is_equal_approx(b["direction"]) \
		and bool(a["auto"]) == bool(b["auto"])

## THE TREE IS NOT LIVE IN _init. A SceneTree script's _init runs before the
## autoloads and before the tree processes, so a node added there does not get
## _ready until the first frame — the first draft of this probe read
## initial_position back immediately and measured three zeroes while the cube's
## own print, further down the same log, showed it aiming exactly where it was
## told. Stage the cubes in _init, read them in _process.
var _fails := 0
var _staged: Array = []
var _done := false

func _init() -> void:
	var fails := 0

	# 1 + 2. the shared function is the grid's rule; the old museum rule was not
	var shared_ok := 0
	var old_diffs := 0
	var worst := ""
	var worst_n := 0
	for row in CORPUS:
		var token: String = row[0]
		var n: int = row[1]
		var p := params_of(token)
		var want := grid_reference(p)
		var got: Dictionary = UtilityRegistry.transport_params(p)
		if same(want, got):
			shared_ok += 1
		else:
			print("   MISMATCH %s: grid says d=%.2f dir=%s auto=%s; shared says d=%.2f dir=%s auto=%s"
				% [token, want["distance"], want["direction"], want["auto"], got["distance"], got["direction"], got["auto"]])
			fails += 1
		var old := museum_old(p)
		if not same(want, old):
			old_diffs += 1
			if n > worst_n:
				worst_n = n
				worst = "%s: grid %s x%.1f auto=%s, old museum %s x%.1f auto=%s" % [
					token, want["direction"], want["distance"], want["auto"],
					old["direction"], old["distance"], old["auto"]]
	print("1  %d of %d corpus token forms: the shared function matches the grid" % [shared_ok, CORPUS.size()])
	print("2  the OLD museum rule disagreed on %d of %d forms; the most-placed one was %s (%d placements)"
		% [old_diffs, CORPUS.size(), worst, worst_n])
	if old_diffs == 0:
		print("   FAIL the negative test found nothing — this probe is not measuring the drift it was written for")
		fails += 1

	# 3. a live cube configured through the shared function goes where it was told
	var scene: PackedScene = load(SCENE)
	if scene == null:
		print("3  FAIL cannot load %s" % SCENE); fails += 1
	else:
		for token in ["tc:3:y", "tc:4:0,0,-1", "tc:1:auto:auto"]:
			var cube: Node3D = scene.instantiate() as Node3D
			var cfg: Dictionary = UtilityRegistry.transport_params(params_of(token))
			cube.set("move_distance", cfg["distance"])
			cube.set("move_direction", cfg["direction"])
			cube.set("auto_start", cfg["auto"])
			cube.position = Vector3(7.0, 0.0, 3.0)
			root.add_child(cube)
			_staged.append({"token": token, "cube": cube, "cfg": cfg})

		# 4. carriable: the walker is a plain CharacterBody3D on layer 1, and the
		# cube's areas ship masking layer 20 alone, which is why the museum's
		# desktop visitor was never picked up.
		var plain: Node3D = scene.instantiate() as Node3D
		root.add_child(plain)
		var before := 0
		for a_v in plain.find_children("*", "Area3D", true, false):
			if ((a_v as Area3D).collision_mask & 1) != 0:
				before += 1
		var widened: int = UtilityRegistry.make_carriable(plain)
		var after := 0
		for a_v2 in plain.find_children("*", "Area3D", true, false):
			if ((a_v2 as Area3D).collision_mask & 1) != 0:
				after += 1
		print("4  areas seeing the default layer: %d as shipped, %d after make_carriable (%d widened)" % [before, after, widened])
		if before != 0 or after == 0 or widened == 0:
			print("   FAIL a shipped cube already saw layer 1, or making it carriable changed nothing"); fails += 1
		plain.queue_free()

	_fails = fails


## The first frame: every staged cube has had its _ready, so its cached start
## and target can be read and compared with what the parameters asked for.
func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	for e_v in _staged:
		var e: Dictionary = e_v
		var cube: Node3D = e["cube"]
		var cfg: Dictionary = e["cfg"]
		var init_p: Vector3 = cube.get("initial_position")
		var targ: Vector3 = cube.get("target_position")
		var want_t: Vector3 = init_p + (cfg["direction"] as Vector3).normalized() * float(cfg["distance"])
		var ok: bool = targ.is_equal_approx(want_t)
		print("3  %-16s dist %.1f dir %s -> start %s target %s (asked %s): %s"
			% [e["token"], cfg["distance"], cfg["direction"], init_p, targ, want_t, "ok" if ok else "WRONG"])
		if not ok:
			print("   FAIL the cube did not aim where the parameters asked"); _fails += 1
	print("")
	print("PROBE %s" % ("OK" if _fails == 0 else "FAILED %d" % _fails))
	quit(_fails)
	return true
