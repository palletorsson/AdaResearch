extends SceneTree
## THE SEVEN, MEASURED BEFORE THEY ARE PLACED (2026-08-27).
##
## The plan is to put the 1-to-8 leg ladder into the forces spine as a walked
## room. Two things decide whether that is a placement or a build, and grep can
## only half-answer either:
##
##   1. DO THEY STAND ON A FLOOR? four_leg_critter writes homes[i].y = 0.0, the
##      same flat-ground assumption that put head_crab's feet half a metre under
##      the arena deck. A spine floor cell seats at 0.5 m. If all seven do it,
##      the family has to be fixed before it can be placed anywhere.
##   2. DO THEY MOVE ON THEIR OWN? Four of the seven call Input.get_vector, so
##      in a walked room they would mirror the visitor. With no input at all,
##      does anything happen — an idle gait, a wander, a settle?
##
## And one number the room needs: how much floor each one occupies, which is
## what sets the spacing between plinths.
const DIR := "res://commons/hazards/octapod_crawler/"
const NAMES := ["one_leg", "two_leg_critter", "three_leg_critter", "four_leg_critter",
	"five_leg_critter", "six_leg_critter", "octapod_ik"]
const TXT := "res://ada_run/leg_ladder.txt"
const JSN := "res://ada_run/leg_ladder.json"

var _l: Array = []
var _rows: Array = []

func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

## the honest extent: boxes near the subject, ignoring backdrops and strays
func _extent(n: Node3D) -> Dictionary:
	var boxes: Array = []
	var stack: Array = [n]
	while not stack.is_empty():
		var q: Node = stack.pop_back()
		if q is VisualInstance3D:
			var vi: VisualInstance3D = q
			var wb: AABB = vi.global_transform * vi.get_aabb()
			if wb.size.length() > 0.0001: boxes.append(wb)
		for ch in q.get_children(): stack.append(ch)
	var anchor: Vector3 = n.global_position
	var box := AABB(); var has := false
	for b in boxes:
		var wb2: AABB = b
		if wb2.size.length() > 8.0: continue
		if wb2.get_center().distance_to(anchor) > 6.0: continue
		box = wb2 if not has else box.merge(wb2)
		has = true
	return {"has": has, "size": box.size, "min_y": box.position.y, "parts": boxes.size()}

## every Node3D that looks like a foot — the family names them FootTarget or Foot
func _feet_of(n: Node) -> Array:
	var out: Array = []
	var stack: Array = [n]
	while not stack.is_empty():
		var q: Node = stack.pop_back()
		var nm := String(q.name).to_lower()
		if q is Node3D and (nm.begins_with("foottarget") or nm.begins_with("foot_") or nm == "foot"):
			out.append(q)
		for ch in q.get_children(): stack.append(ch)
	return out

func _run() -> void:
	var st := Node3D.new(); get_root().add_child(st)
	# a DECK at 0.5 m — exactly what a structure cell of height 1 seats at
	var deck := StaticBody3D.new(); var dcs := CollisionShape3D.new(); var dbx := BoxShape3D.new()
	dbx.size = Vector3(200, 1.0, 40); dcs.shape = dbx; dcs.position = Vector3(60, 0.0, 0)
	deck.add_child(dcs); st.add_child(deck)
	var dm := MeshInstance3D.new(); var dbm := BoxMesh.new()
	dbm.size = Vector3(200, 1.0, 40); dm.mesh = dbm; dm.position = Vector3(60, 0.0, 0)
	st.add_child(dm)

	_say("THE SEVEN, ON A DECK WHOSE TOP IS AT y = 0.500")
	_say("")
	var x := 0.0
	var live: Array = []
	for nm in NAMES:
		var path: String = DIR + nm + ".tscn"
		if not ResourceLoader.exists(path):
			_say("%-20s -- no scene at %s" % [nm, path]); continue
		var ps: PackedScene = load(path) as PackedScene
		if ps == null:
			_say("%-20s -- not a PackedScene" % nm); continue
		var inst: Node = ps.instantiate()
		if inst == null:
			_say("%-20s -- would not instantiate" % nm); continue
		st.add_child(inst)
		if inst is Node3D: (inst as Node3D).global_position = Vector3(x, 0.5, 0)
		live.append({"name": nm, "node": inst, "x": x})
		x += 8.0
	await create_timer(2.2).timeout

	# where they START
	for e in live:
		var ed: Dictionary = e
		var n: Node3D = ed["node"]
		ed["p0"] = n.global_position
		var ft: Array = _feet_of(n)
		ed["feet"] = ft
		var fy := 99.0
		for f in ft: fy = minf(fy, (f as Node3D).global_position.y)
		ed["foot_y0"] = fy

	# NO INPUT AT ALL for six seconds. anything that moves, moves by itself.
	await create_timer(6.0).timeout

	for e in live:
		var ed: Dictionary = e
		var n: Node3D = ed["node"]
		var ex: Dictionary = _extent(n)
		var travelled: float = n.global_position.distance_to(ed["p0"] as Vector3)
		var ft: Array = ed["feet"]
		var fy := 99.0; var fyh := -99.0
		for f in ft:
			if f == null or not is_instance_valid(f): continue
			var y: float = (f as Node3D).global_position.y
			fy = minf(fy, y); fyh = maxf(fyh, y)
		var sz: Vector3 = ex["size"]
		var cls := n.get_class()
		var body := "none"
		var stack: Array = [n]
		while not stack.is_empty():
			var q: Node = stack.pop_back()
			if q is CharacterBody3D or q is RigidBody3D or q is StaticBody3D:
				body = q.get_class(); break
			for ch in q.get_children(): stack.append(ch)
		_say("%-20s root %-16s body %-16s feet %d" % [String(ed["name"]), cls, body, ft.size()])
		_say("    footprint  %.2f x %.2f m   height %.2f" % [sz.x, sz.z, sz.y])
		_say("    moved on its own in 6 s: %.3f m" % travelled)
		if ft.is_empty():
			_say("    feet: none found by name — cannot judge the ground")
		else:
			_say("    foot world y: %.3f .. %.3f   (the deck is at 0.500)" % [fy, fyh])
			if fy < 0.30:
				_say("    -> PLANTS THROUGH THE DECK by %.2f m" % (0.5 - fy))
			else:
				_say("    -> stands on the deck")
		_rows.append({
			"name": ed["name"], "root": cls, "body": body, "feet": ft.size(),
			"footprint_x": sz.x, "footprint_z": sz.z, "height": sz.y,
			"travelled_6s": travelled, "foot_y_min": fy, "foot_y_max": fyh,
		})
		_say("")

	var through := 0; var still := 0
	for r in _rows:
		var rd: Dictionary = r
		if float(rd.get("foot_y_min", 99.0)) < 0.30: through += 1
		if float(rd.get("travelled_6s", 0.0)) < 0.05: still += 1
	_say("SUMMARY: %d of %d plant through the deck; %d of %d never moved without input." % [through, _rows.size(), still, _rows.size()])
	var f2 := FileAccess.open(TXT, FileAccess.WRITE)
	f2.store_string("\n".join(PackedStringArray(_l)) + "\n"); f2.close()
	var j := FileAccess.open(JSN, FileAccess.WRITE)
	j.store_string(JSON.stringify({"rows": _rows}, "\t")); j.close()
	quit(0)
