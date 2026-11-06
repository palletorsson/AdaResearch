extends Node3D
## THE PLAYGROUND EDITOR ON A BENCH (2026-11-06, the jumbotron design): the display workstation in `space` mode, no
## Void, an aim node moved as a hand would. Proves, with numbers: (A) the glass box stands on the floor at zero, its
## panes free, the table, the hand model and the visor dark; (B) the grid is always on and the jumbotron hangs from the
## ceiling with one tile per tool on each of four faces; (C) outside the box the editor does not take the hand, inside
## it does; (D) a tile is picked by aiming at it and pulling; (E) a BALL is placed at a lit node, an EDGE between two
## balls, a QUAD on a square of edges; (F) HEALTH goes only onto a finished quad, one per quad; (G) SELECT takes a
## piece back and makes its kind the tool; (H) a tool the floor has not opened is refused, with its floor said.
## Writes ada_run/space-editor/{bench.png, report.json}.
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
	# A — the box
	var pane_bodies := 0
	for pane in bay.find_children("GlassPane*", "MeshInstance3D", false, false): pane_bodies += pane.find_children("*", "StaticBody3D", true, false).size()
	_check("A the box on the floor at %.2f m, %d pane colliders, table %s, hand model %s, visor %s" % [ws.output.global_position.y, pane_bodies, "dark" if not ws.support.visible else "SHOWN", "dark" if not ws.bench.visible else "SHOWN", "off" if not ws.visit.headset.enabled else "ON"], absf(ws.output.global_position.y) < .01 and pane_bodies == 0 and not ws.support.visible and not ws.bench.visible and not ws.visit.headset.enabled)
	# B — the grid and the jumbotron
	var dots: int = ws.space_grid.multimesh.instance_count if ws.space_grid and ws.space_grid.multimesh else 0
	var per_face: int = ws.space_tools.size() + 2
	_check("B the grid is on with no tool (%d node dots); the jumbotron hangs at %.2f m with %d tiles (%d tools + select + rubber on 4 faces)" % [dots, ws.jumbotron.global_position.y, ws.tiles.size(), ws.space_tools.size()], dots > 100 and ws.tiles.size() == per_face * 4 and ws.jumbotron.global_position.y > 3.5)
	# C — outside / inside
	ws.space_inside_override = 0; ws._update_inside()
	_aim_at(ws.output.global_position + Vector3(0, 1, 0), Vector3(0, 0, 4))
	var outside: bool = ws.space_active(null, aim)
	ws.space_inside_override = 1; ws._update_inside()
	var inside: bool = ws.space_active(null, aim)
	_check("C outside the box the editor leaves the hand alone (%s), inside it takes it (%s)" % [str(outside), str(inside)], not outside and inside)
	# D — pick BALL on the jumbotron
	var said_d := _pick("point")
	_check("D aimed at the BALL tile and pulled -> %s; the tool is '%s'; %d nodes lit" % [said_d, ws.space_tool, ws.space_sockets.get_child_count()], said_d == "picked" and ws.space_tool == "point" and ws.space_sockets.get_child_count() > 0)
	# E — a ball, an edge, a quad
	var said_ball := _place_at({"kind": "point", "at": [1, 0, 0]})
	_pick("edge")
	var said_edge := _place_at({"kind": "rod", "at": [0, 0, 0], "end": [1, 0, 0]})
	for p in [[0, 0, 1], [1, 0, 1]]: ws.model.add({"kind": "point", "at": p}, ws.tier)
	for r in [[[0, 0, 0], [0, 0, 1]], [[1, 0, 0], [1, 0, 1]], [[0, 0, 1], [1, 0, 1]]]: ws.model.add({"kind": "rod", "at": r[0], "end": r[1]}, ws.tier)
	ws.redraw()
	_pick("quad")
	var said_quad := _place_at({"kind": "quad", "at": [0, 0, 0], "plane": [0, 2]})
	_check("E ball -> %s, edge -> %s, quad on a square of edges -> %s (%d records, %d bodies in the box)" % [said_ball, said_edge, said_quad, ws.model.records.size(), ws.output.get_node("Structure").get_child_count()], said_ball == "placed" and said_edge == "placed" and said_quad == "placed")
	# F — HEALTH onto the quad, once
	_pick("health")
	var quad: Dictionary = {"kind": "quad", "at": [0, 0, 0], "plane": [0, 2]}
	var said_h := _place_at(quad)
	var said_h2 := _place_at(quad)
	_check("F health onto the finished quad -> %s (%d items); a second onto the same quad -> %s" % [said_h, ws.space_items.size(), said_h2], said_h == "placed" and ws.space_items.size() == 1 and said_h2 == "refused")
	# G — SELECT takes the edge back
	_pick("select")
	var before: int = ws.model.records.size()
	ws.model.add({"kind": "point", "at": [2, 0, 0]}, ws.tier); ws.model.add({"kind": "rod", "at": [1, 0, 0], "end": [2, 0, 0]}, ws.tier); ws.redraw()
	var said_g := _place_at({"kind": "rod", "at": [1, 0, 0], "end": [2, 0, 0]})
	_check("G SELECT on a free edge -> %s; the tool is now '%s'" % [said_g, ws.space_tool], said_g == "taken" and ws.space_tool == "edge" and ws.model.records.size() == before + 1)
	# H — a floor that has not opened the tool
	ws.space_floor = 3
	var said_hh := _pick("triangle")
	_check("H on floor 3 the TRIANGLE tile -> %s (%s)" % [said_hh, ws.space_notice], said_hh == "refused" and ws.space_notice.contains("floor 5"))
	ws.space_floor = 20; ws.pick_tool("point")
	cam.global_position = ws.output.global_position + Vector3(2.2, 2.0, 2.6); cam.look_at(ws.output.global_position + Vector3(-.4, 2.4, -.6))
	_aim_at(ws.output.to_global(ws.space_point({"kind": "point", "at": [1, 1, 0]})), Vector3(.6, -.3, 1.6)); ws.space_update(aim)
	for i in 6: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("bench.png"))
	var passed: int = report.checks.filter(func(c): return c.ok).size()
	report["passed"] = passed == report.checks.size()
	FileAccess.open("res://ada_run/space-editor/report.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("[probe_space_editor] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if report.passed else 1)

## The hand at `target + back`, pointing at the target.
func _aim_at(target: Vector3, back: Vector3) -> void:
	aim.global_position = target + back; aim.look_at(target)

## Aim at a tool's tile on the face nearest the hand and pull.
func _pick(id: String) -> String:
	for t in ws.tiles:
		if str(t.id) != id: continue
		var node: Node3D = t.node
		var front: Vector3 = node.global_basis.z.normalized()
		if front.dot(Vector3(0, 0, 1)) < .5: continue   # the face toward the +z side of the box
		_aim_at(node.global_position, front * 1.8)
		return ws.space_press(aim)
	return "no tile"

## Aim at where a record sits and pull.
func _place_at(r: Dictionary) -> String:
	_aim_at(ws.output.to_global(ws.space_point(r)), Vector3(.3, .8, 1.8))
	return ws.space_press(aim)

func _check(what: String, ok: bool) -> void:
	report.checks.append({"what": what, "ok": ok})
	print("[probe_space_editor] %s  %s" % ["ok  " if ok else "FAIL", what])
