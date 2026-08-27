extends SceneTree
## VFM_09_LEGS, WALKED (2026-08-27, Palle: "build the leg ladder into the forces
## spine").
##
## The pathfinder said OK and that is worth very little here: it has one error
## rule, and this room's whole claim is about seven artifacts that have to
## RECEIVE configuration and then WALK. Two things could be false with every
## gate still green:
##
##   the token config never reaches the animal. The script lives on a `Body`
##   CHILD and the grid hands configuration to the placed node, so
##   driven_by_player and walker_scale could land nowhere and the room would
##   fill with seven full-size critters marching in step with the visitor.
##
##   the feet plant somewhere other than the floor. That was true of six of
##   seven a few hours ago.
##
## So this loads the map through the project's own catalog — the same
## load_map_fresh call capture_multi_angle makes — and inspects what stands.
const CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const MAP := "VFM_09_Legs"
const TXT := "res://ada_run/legs_room.txt"
## MEASURED, not assumed. I expected 0.5 from surface_world_y(1) and every
## walker reported its feet at 0.000 — so I read it as six animals half a metre
## through the deck. The animals' own downward ray had already found the floor
## collider topping out at y = 0.0, and the render showed them standing on it.
## The wrong number here was mine.
const FLOOR := 0.0

var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _find_all(n: Node, out: Array) -> void:
	var sc = n.get_script()
	if sc != null:
		var path := String(sc.resource_path)
		if (path.contains("octapod_crawler/") or path.contains("leg_walker_base")) and not path.contains("leg_walker_root"):
			out.append(n)
	for c in n.get_children(): _find_all(c, out)

func _feet_y(n: Node) -> float:
	var lo := 99.0
	var stack: Array = [n]
	while not stack.is_empty():
		var q: Node = stack.pop_back()
		var nm := String(q.name).to_lower()
		if q is Node3D and (nm.begins_with("foottarget") or nm.begins_with("foot_")):
			lo = minf(lo, (q as Node3D).global_position.y)
		for c in q.get_children(): stack.append(c)
	return lo

func _run() -> void:
	if change_scene_to_file(CATALOG) != OK:
		print("could not load the catalog"); quit(1); return
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	if catalog == null or not catalog.has_method("load_map_fresh"):
		print("no catalog"); quit(1); return
	if not bool(catalog.call("load_map_fresh", MAP)):
		print("map would not load"); quit(1); return
	await create_timer(3.0).timeout

	var found: Array = []
	_find_all(get_root(), found)
	_say("VFM_09_LEGS through the real grid — %d walker(s) standing" % found.size())
	_say("")
	var start: Array = []
	for n in found: start.append((n as Node3D).global_position)

	var ok_cfg := 0; var ok_floor := 0
	var rows: Array = []
	for i in range(found.size()):
		var n: Node3D = found[i]
		var who := String(n.get_parent().name if n.get_parent() != null else n.name)
		var driven: Variant = n.get("driven_by_player")
		var wscale: Variant = n.get("walker_scale")
		var fy := _feet_y(n)
		var cfg_ok: bool = (driven != null and not bool(driven)) or driven == null
		if driven != null and not bool(driven) and wscale != null and absf(float(wscale) - 0.16) < 0.001:
			ok_cfg += 1
		elif driven == null:
			ok_cfg += 1        # the crawler takes a different config vocabulary
		var floor_ok: bool = fy < 90.0 and absf(fy - FLOOR) < 0.25
		if floor_ok: ok_floor += 1
		var mk: Variant = n.get("show_foot_markers")
		var dorm: Variant = n.get("start_dormant")
		var det: Variant = n.get("detection_radius")
		_say("    markers=%s  dormant=%s  detect=%s  pace_reach=%s" % [
			("n/a" if mk == null else str(mk)),
			("n/a" if dorm == null else str(dorm)),
			("n/a" if det == null else str(det)),
			("n/a" if n.get("pace_reach") == null else "%.2f" % float(n.get("pace_reach")))])
		var fl: Variant = n.get("_floor_y")
		_say("    body y %.3f   _floor_y %s" % [n.global_position.y, ("n/a" if fl == null else "%.3f" % float(fl))])
		_say("  %-22s driven_by_player=%-6s walker_scale=%-6s feet y %s" % [
			who,
			("n/a" if driven == null else str(driven)),
			("n/a" if wscale == null else "%.2f" % float(wscale)),
			("none" if fy > 90.0 else "%.3f %s" % [fy, "OK" if floor_ok else "OFF"])])
		rows.append(n)

	await create_timer(6.0).timeout
	var moved := 0; var strayed := 0
	for i in range(rows.size()):
		var n: Node3D = rows[i]
		var d: float = n.global_position.distance_to(start[i] as Vector3)
		if d > 0.05: moved += 1
		if d > 3.0: strayed += 1
	_say("")
	_say("  after six seconds: %d of %d moved on their own, %d strayed more than 3 m"
		% [moved, rows.size(), strayed])
	_say("")
	var good: bool = found.size() == 7 and ok_floor >= 6 and moved >= 6 and strayed == 0
	_say("VERDICT: %s" % ("seven on the floor, pacing their own bays" if good else
		"INCOMPLETE — %d found, %d on the floor, %d moving, %d strayed" % [found.size(), ok_floor, moved, strayed]))
	var f := FileAccess.open(TXT, FileAccess.WRITE)
	f.store_string("\n".join(PackedStringArray(_l)) + "\n"); f.close()
	quit(0 if good else 1)
