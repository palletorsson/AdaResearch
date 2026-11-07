extends Node3D
## THE PLAYGROUND EDITOR ON A BENCH (2026-11-06, the direct design: no jumbotron, no tools - Palle: "point, wedge,
## triangle quad all have unique positions in the grid so we could just have if we point at the position and fire when
## the element is created"). The display workstation in `space` mode, no Void, an aim node moved as a hand would.
## Proves, with numbers: (A) the box on the floor at zero, panes free, table / hand model / visor dark; (B) the grid on,
## no jumbotron, the guide saying what this floor builds; (C) outside the box the editor leaves the hand alone; inside it
## takes the EMPTY hand, never a hand holding a thing (the hand menu's); (D) a ball made by aiming at a free node; (E)
## an edge by aiming between two balls; (F) a FLOOR quad aimed from eye height with a wall square standing beside it
## (Palle: "we can not add quad in horizontal plans only vertically"), then the wall quad; (G) a triangle at the corner
## of two edges, bringing its own diagonal; (H) a wedge on a floor cell, rising away from the hand; (I) the grip takes
## a free piece away, refuses one something stands on, and the trigger on a placed piece makes nothing; (J) a floor
## that has not opened quads and wedges offers neither; (K) the cell solids' sizes and a v11 build migrated; (L) each
## floor its own build. Writes ada_run/space-editor/{bench.png, report.json}.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_space_editor.tscn

const Station = preload("res://commons/artifacts/scaffold_workstation/display.tscn")
const Model = preload("res://commons/artifacts/scaffold_workstation/model.gd")

var report := {"checks": []}
var ws: Node3D
var aim: Node3D

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/space-editor"); DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color("d8d2c8"); e.ambient_light_energy = .7; env.environment = e; add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, 30, 0); sun.light_energy = 1.0; add_child(sun)
	var slab := MeshInstance3D.new(); var sm := BoxMesh.new(); sm.size = Vector3(30, .1, 30); slab.mesh = sm; slab.position.y = -.05; add_child(slab)
	ws = Station.instantiate(); ws.set_meta("config_space", true); ws.set_meta("config_persist", false); ws.set_meta("config_space_floor", 20); add_child(ws)
	aim = Node3D.new(); aim.name = "Aim"; add_child(aim)
	var cam := Camera3D.new(); add_child(cam); cam.fov = 64; cam.current = true
	for i in 40: await get_tree().process_frame
	ws.model.records.clear(); ws.redraw()
	var bay: Node3D = ws.output.get_node("Bay")
	# A - the box
	var pane_bodies := 0
	for pane in bay.find_children("GlassPane*", "MeshInstance3D", false, false): pane_bodies += pane.find_children("*", "StaticBody3D", true, false).size()
	_check("A the box on the floor at %.2f m, %d pane colliders, table %s, hand model %s, visor %s" % [ws.output.global_position.y, pane_bodies, "dark" if not ws.support.visible else "SHOWN", "dark" if not ws.bench.visible else "SHOWN", "off" if not ws.visit.headset.enabled else "ON"], absf(ws.output.global_position.y) < .01 and pane_bodies == 0 and not ws.support.visible and not ws.bench.visible and not ws.visit.headset.enabled)
	# B - the grid, no jumbotron, the guide
	var dots: int = ws.space_grid.multimesh.instance_count if ws.space_grid and ws.space_grid.multimesh else 0
	var drum: Node = ws.output.find_child("Jumbotron", true, false)
	ws.space_hide(); ws._guide_state()
	var guide: String = ws.space_guide.text
	_check("B the grid is on (%d node dots); jumbotron %s; the guide: %s" % [dots, "GONE" if drum == null else "STILL THERE", guide.replace("\n", " / ")], dots > 100 and drum == null and guide.contains("BALL, EDGE, TRIANGLE, QUAD, WEDGE") and not guide.contains("PYRAMID"))
	# C - outside / inside, the empty hand / a thing in the hand
	var holding := Node.new(); var s := GDScript.new(); s.source_code = "extends Node\nvar current := \"crate\"\n"; s.reload(); holding.set_script(s); add_child(holding)
	var empty := Node.new(); var s2 := GDScript.new(); s2.source_code = "extends Node\nvar current := \"\"\n"; s2.reload(); empty.set_script(s2); add_child(empty)
	ws.space_inside_override = 0; ws._update_inside()
	var outside: bool = ws.space_active(empty, aim)
	ws.space_inside_override = 1; ws._update_inside()
	var inside_empty: bool = ws.space_active(empty, aim); var inside_holding: bool = ws.space_active(holding, aim)
	_check("C outside the box: %s; inside with the empty hand: %s; inside holding a crate from the hand menu: %s" % [str(outside), str(inside_empty), str(inside_holding)], not outside and inside_empty and not inside_holding)
	# D - a ball at a free node
	var said_d := _fire(Vector3(.5, 0, 0), Vector3(.5, .8, 1.5))
	_check("D aimed at the free node (0.5,0,0) and pulled -> %s (%s); a ball there: %s" % [said_d, ws.space_notice, str(_has({"kind": "point", "at": [.5, 0, 0]}))], said_d == "placed" and _has({"kind": "point", "at": [.5, 0, 0]}))
	# E - an edge between two balls
	var said_e := _fire(Vector3(.25, 0, 0), Vector3(.25, .8, 1.5))
	_check("E aimed between the origin and that ball -> %s (%s)" % [said_e, ws.space_notice], said_e == "placed" and _has({"kind": "rod_short", "at": [0, 0, 0], "end": [.5, 0, 0]}))
	# F - the floor quad, with a wall square standing on its back edge; then the wall quad
	for p in [[0, 0, .5], [.5, 0, .5], [0, .5, 0], [.5, .5, 0]]: _add_point(p)
	for r in [[[0, 0, 0], [0, 0, .5]], [[.5, 0, 0], [.5, 0, .5]], [[0, 0, .5], [.5, 0, .5]], [[0, 0, 0], [0, .5, 0]], [[.5, 0, 0], [.5, .5, 0]], [[0, .5, 0], [.5, .5, 0]]]: _add_rod(r[0], r[1])
	ws.redraw()
	var floor_q := {"kind": "quad", "at": [0, 0, 0], "plane": [0, 2], "span": .5}
	var wall_q := {"kind": "quad", "at": [0, 0, 0], "plane": [0, 1], "span": .5}
	var said_floor := _fire(Vector3(.25, 0, .25), Vector3(.25, .8, 1.5))
	var said_wall := _fire(Vector3(.25, .25, 0), Vector3(.25, .4, 1.5))
	_check("F a floor square with a wall square on its back edge: aimed from eye height at the floor's middle -> %s, the floor quad %s; at the wall's middle -> %s, the wall quad %s" % [said_floor, "made" if _has(floor_q) else "MISSING", said_wall, "made" if _has(wall_q) else "MISSING"], said_floor == "placed" and _has(floor_q) and said_wall == "placed" and _has(wall_q))
	# G - a triangle at the corner of two edges, its diagonal with it
	for p in [[1, 0, 0], [1.5, 0, 0], [1, 0, .5]]: _add_point(p)
	_add_rod([1, 0, 0], [1.5, 0, 0]); _add_rod([1, 0, 0], [1, 0, .5]); ws.redraw()
	var tri := {"kind": "panel", "at": [1, 0, 0], "plane": [0, 2], "half": 2, "span": .5}
	var said_g := _fire(Vector3(1.1, 0, .1), Vector3(1.1, .8, 1.5))
	var diag_g: bool = ws.model.diag_exists(Vector3(1.5, 0, 0), Vector3(1, 0, .5))
	_check("G aimed into the corner of two edges at (1,0,0) -> %s (%s): the triangle %s, its diagonal %s" % [said_g, ws.space_notice, "made" if _has(tri) else "MISSING", "made" if diag_g else "MISSING"], said_g == "placed" and _has(tri) and diag_g)
	# H - a wedge on a floor cell, rising away from the hand
	var said_h := _fire(Vector3(-.75, 0, 1.25), Vector3(-.75, .8, .4))
	var wedge := {"kind": "wedge", "at": [-1, 0, 1], "turn": [0, 0, 0], "span": .5}
	var w_size: Vector3 = Model.prefab_box(wedge).size * ws.output_unit()
	_check("H aimed at the floor cell (-1,0,1) looking +z -> %s (%s); a wedge there rising +z: %s, %.1f x %.1f x %.1f m" % [said_h, ws.space_notice, str(_has(wedge)), w_size.x, w_size.y, w_size.z], said_h == "placed" and _has(wedge) and w_size.is_equal_approx(Vector3(1, 1, 2)))
	# I - the grip takes away; refuses what something stands on; the trigger on a placed piece makes nothing
	_add_point([0, .5, .5]); ws.redraw()
	var n_before: int = ws.model.records.size()
	var said_trigger := _fire(Vector3(0, .5, .5), Vector3(.6, .9, 1.6))
	var took_ball := _grip(Vector3(0, .5, .5), Vector3(.6, .9, 1.6)) and not _has({"kind": "point", "at": [0, .5, .5]})
	var took_wedge := _grip(Vector3(-.75, .25, 1.4), Vector3(-.75, 1.0, 2.6)) and not _has(wedge)
	var held := _grip(Vector3(1.5, 0, 0), Vector3(2.4, .7, -.3)); var still: bool = _has({"kind": "point", "at": [1.5, 0, 0]})   # an edge and the triangle's diagonal hold it
	_check("I the trigger on a placed ball -> %s (records %d -> %d); grip on that free ball: %s; on the wedge: %s; on the ball the edges hold: %s (%s)" % [said_trigger, n_before, ws.model.records.size() + 2, "taken" if took_ball else "NOT TAKEN", "taken" if took_wedge else "NOT TAKEN", "kept" if still else "TAKEN", ws.space_notice], said_trigger == "refused" and took_ball and took_wedge and held and still and ws.space_notice.contains("stands on it"))
	# J - a floor that has not opened quads and wedges: a closed square and a free cell offer neither
	ws.space_floor = 3; ws._refresh_space_sockets()
	ws.model.records.clear(); ws.redraw()
	for p in [[.5, 0, 0], [0, 0, .5], [.5, 0, .5]]: _add_point(p)
	for r in [[[0, 0, 0], [.5, 0, 0]], [[0, 0, 0], [0, 0, .5]], [[.5, 0, 0], [.5, 0, .5]], [[0, 0, .5], [.5, 0, .5]]]: _add_rod(r[0], r[1])
	ws.redraw()
	var on3_square := _hover(Vector3(.25, 0, .25), Vector3(.25, .8, 1.5)); var on3_cell := _hover(Vector3(-.75, 0, 1.25), Vector3(-.75, .8, .4))
	ws.space_floor = 20; ws._refresh_space_sockets()
	var on20_square := _hover(Vector3(.25, 0, .25), Vector3(.25, .8, 1.5))
	_check("J on floor 3 the closed square offers %s, the free cell %s; on floor 20 the same square offers %s" % [_what(on3_square), _what(on3_cell), _what(on20_square)], _what(on3_square) != "quad" and _what(on3_cell) != "wedge" and _what(on20_square) == "quad")
	# K - the cell solids' sizes; a v11 2 m wedge comes back as a cell solid inside its old footprint
	var p_size: Vector3 = Model.prefab_box({"kind": "pyramid", "at": [0, 0, 0], "turn": [0, 0, 0], "span": .5}).size * ws.output_unit()
	var v11 := {"kind": "wedge", "at": [.5, 0, .5], "turn": [0, 2, 0]}
	var v11_file := FileAccess.open("user://void_space_build_93.json", FileAccess.WRITE); v11_file.store_string(JSON.stringify({"version": 1, "floor": 93, "records": [v11]})); v11_file.close()
	var c: Node3D = Station.instantiate(); c.set_meta("config_space", true); c.set_meta("config_space_floor", 93); add_child(c)
	for i in 30: await get_tree().process_frame
	var migrated: Dictionary = c.model.records[0] if c.model.records.size() == 1 else {}
	var inside_old: bool = not migrated.is_empty() and Model.prefab_box(v11).grow(.001).encloses(Model.prefab_box(migrated)) and float(migrated.get("span", 1)) == .5
	c.queue_free(); DirAccess.remove_absolute(ProjectSettings.globalize_path("user://void_space_build_93.json"))
	_check("K a cell pyramid is %.1f x %.1f x %.1f m (from the hand menu); a v11 2 m wedge comes back as %s" % [p_size.x, p_size.y, p_size.z, str(migrated)], p_size.is_equal_approx(Vector3(1, 1, 1)) and inside_old)
	# L - each floor its own build: a first visit starts from the floor above's build, then the two are separate
	for f in [91, 92]:
		if FileAccess.file_exists("user://void_space_build_%d.json" % f): DirAccess.remove_absolute(ProjectSettings.globalize_path("user://void_space_build_%d.json" % f))
	var a: Node3D = Station.instantiate(); a.set_meta("config_space", true); a.set_meta("config_space_floor", 91); add_child(a)
	for i in 30: await get_tree().process_frame
	a.model.add({"kind": "point", "at": [1, 0, 0]}, a.tier); a.share()
	var b: Node3D = Station.instantiate(); b.set_meta("config_space", true); b.set_meta("config_space_floor", 92); add_child(b)
	for i in 30: await get_tree().process_frame
	var seeded: int = b.model.records.size()
	b.model.add({"kind": "point", "at": [0, 0, 1]}, b.tier); b.share()
	await get_tree().process_frame
	_check("L floor 91 builds one ball; floor 92 starts from it (%d records), adds its own; floor 91 still has %d, floor 92 %d" % [seeded, a.model.records.size(), b.model.records.size()], a.persist and seeded == 1 and a.model.records.size() == 1 and b.model.records.size() == 2)
	for f in [91, 92]: DirAccess.remove_absolute(ProjectSettings.globalize_path("user://void_space_build_%d.json" % f))
	a.queue_free(); b.queue_free()
	# the picture: the floor square closed, the quad's ghost under the aim
	cam.global_position = _world(Vector3(1.4, .9, 1.6)); cam.look_at(_world(Vector3(.2, .1, .1)))
	_hover(Vector3(.25, 0, .25), Vector3(.25, .8, 1.5))
	for i in 6: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("bench.png"))
	var passed: int = report.checks.filter(func(x): return x.ok).size()
	report["passed"] = passed == report.checks.size()
	FileAccess.open("res://ada_run/space-editor/report.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("[probe_space_editor] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if report.passed else 1)

## An address in the box -> the world.
func _world(addr: Vector3) -> Vector3: return ws.output.to_global(ws._node_world(addr))

## The hand at `from` (an address), pointing at `target` (an address).
func _aim(target: Vector3, from: Vector3) -> void:
	aim.global_position = _world(from); aim.look_at(_world(target))

func _hover(target: Vector3, from: Vector3) -> Dictionary:
	_aim(target, from); ws.space_update(aim); return ws.space_hover

func _fire(target: Vector3, from: Vector3) -> String:
	_aim(target, from); return ws.space_press(aim)

func _grip(target: Vector3, from: Vector3) -> bool:
	_aim(target, from); ws.space_update(aim); return ws.space_grip()

## What a hover would make ("quad", "wedge" ...), "remove", or "nothing".
func _what(h: Dictionary) -> String:
	if h.has("make"): return str(h.make[-1].kind)
	return "remove" if h.has("remove") else "nothing"

func _has(r: Dictionary) -> bool: return ws.model.has_record(Model.canonical(r))

func _add_point(p: Array) -> void: ws.model.add({"kind": "point", "at": Model.arr(Vector3(p[0], p[1], p[2]))}, ws.tier)
func _add_rod(p: Array, q: Array) -> void: ws.model.add({"kind": "rod_short", "at": Model.arr(Vector3(p[0], p[1], p[2])), "end": Model.arr(Vector3(q[0], q[1], q[2]))}, ws.tier)

func _check(what: String, ok: bool) -> void:
	report.checks.append({"what": what, "ok": ok})
	print("[probe_space_editor] %s  %s" % ["ok  " if ok else "FAIL", what])
