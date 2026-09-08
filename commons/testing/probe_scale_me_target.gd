extends SceneTree

## WHICH "DarkSphere" DOES scale_me GRAB?
##
## 2026-09-08, Astra's brief item 4: "Audit scale_me: document exactly what
## happens to the sphere, player position, camera and collision."
##
## scale_me does not scale anything it built. It searches the running tree for a
## node named "DarkSphere" (scale_me.gd:67) and tweens THAT node's scale by
## scale_amount. Two different things in this project answer to that name:
##
##   the map's backdrop   commons/primitives/sphere/dark_sphere.tscn — an inverted
##                        shell of radius 80 m, instanced by grid.tscn:81 at load
##   the artifact         commons/artifacts/dark_sphere/ — an orb about 0.70 m
##                        across, placed by a map token
##
## The grid places artifacts row-major by ascending z, into an already-live tree,
## so each artifact's _ready fires at its own placement. In Trans_Introduction
## scale_me sits at z=12 and the orb at z=7, so the orb exists first. In
## Trans_Scale scale_me sits at z=8 and the orb at z=13 — five rows LATER — so at
## the moment scale_me looks, the only DarkSphere in the tree is the backdrop.
##
## If that is right, the same artifact scales a 0.7 m orb in one hall and an 80 m
## sky in the next, and which one is decided by nothing more than the order of two
## numbers in a map file. This probe asks the live tree rather than the argument.
##
## It reports; it asserts only the one thing that is a defect in any reading —
## that the two halls do not agree about what the artifact is for.
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_scale_me_target.gd

const CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const MAPS := ["Trans_Introduction", "Trans_Scale"]
const REPORT := "res://ada_run/scale_me_target_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []
var _seen: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if change_scene_to_file(CATALOG) != OK:
		_check(false, "the catalog loads", "catalog scene would not load")
		_finish()
		return
	await process_frame
	await process_frame

	for map_name in MAPS:
		var ok: bool = bool(current_scene.call("load_map_fresh", map_name))
		_check(ok, "%s loads" % map_name, "%s did not load" % map_name)
		if not ok:
			continue
		for i in range(200):
			await process_frame

		var sm: Node = _find_token(root, "scale_me")
		if sm == null:
			_check(false, "  %s: scale_me is in the hall" % map_name,
				"%s places scale_me in its map but no node carries the lookup name" % map_name)
			continue
		var target: Variant = sm.get("_world_node")
		if target == null or not is_instance_valid(target):
			_say("  %-20s scale_me bound to NOTHING" % map_name)
			_seen[map_name] = "none"
			continue
		var t3: Node3D = target as Node3D
		var span: float = _span(t3)
		var owner_path: String = str(t3.get_path())
		_say("  %-20s scale_me -> %s   span %.2f m   path %s"
			% [map_name, t3.name, span, owner_path.substr(maxi(0, owner_path.length() - 64))])
		# 80 m shell or 0.7 m orb — two orders of magnitude apart, so one number
		# separates them with no room for argument.
		_seen[map_name] = "backdrop" if span > 20.0 else "artifact"
		_say("      -> that is the %s" % _seen[map_name])

	# THE ASSERTION. Whichever is correct, the two halls placing the same artifact
	# must mean the same thing by it.
	var kinds: Array = _seen.values()
	var agree: bool = kinds.size() < 2 or kinds.count(kinds[0]) == kinds.size()
	_check(agree, "  both halls scale the same KIND of thing: %s" % str(_seen),
		"scale_me scales a different kind of object in each hall (%s) — the target is decided by the order of two z rows in a map file, not by the artifact" % str(_seen))
	_finish()


## The world-space diagonal of the biggest mesh under this node, which is how a
## 0.7 m orb and an 80 m sky tell themselves apart.
func _span(n: Node) -> float:
	var best := 0.0
	var stack: Array[Node] = [n]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			if mi.mesh != null:
				best = maxf(best, (mi.global_transform.basis * mi.mesh.get_aabb().size).length())
		for k in c.get_children():
			stack.append(k)
	return best


func _find_token(n: Node, token: String) -> Node:
	if n.has_meta("artifact_lookup_name") and str(n.get_meta("artifact_lookup_name")) == token:
		return n
	for c in n.get_children():
		var f: Node = _find_token(c, token)
		if f != null:
			return f
	return null


func _say(line: String) -> void:
	_lines.append("[probe] %s" % line)


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
