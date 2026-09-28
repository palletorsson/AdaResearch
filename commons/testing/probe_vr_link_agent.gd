# probe_vr_link_agent.gd — the VR link's eyes and hands, on a bench.
#
# 2026-09-26: commons/bridge/vr_link.gd learned `scan`, `look`, `interact` and a
# walker with a body, so the python agent (tools/vr_agent.py) can path to a
# work, turn to it, and act on it. Every handler returns its reply, so this
# probe calls _command() with no socket and reads the answers. Four synthetic
# artifacts stand on a deck: A answers interact(), B has a trigger volume, C
# has an interact(action) that must NOT be called bare, D holds a rigid body to
# grab; a teleporter stands in group `utility`.
#
#   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_vr_link_agent.gd
#
# Exit 0 iff every check holds.
extends SceneTree

var _fails := 0

const ART_A := "extends Node3D\nvar hits := 0\nfunc interact() -> void:\n\thits += 1\n"
const ART_B := "extends Node3D\nvar seen_player := 0\nvar seen_other := 0\nfunc _on_body_entered(b: Node3D) -> void:\n\tif b.is_in_group(\"player\"):\n\t\tseen_player += 1\n\telse:\n\t\tseen_other += 1\n"
const ART_C := "extends Node3D\nvar called := 0\nfunc interact(action: String) -> void:\n\tcalled += 1\n"
const TELE := "extends Node3D\nvar started := 0\nfunc get_destination() -> String:\n\treturn \"next\"\nfunc _start_teleport_sequence() -> void:\n\tstarted += 1\n"


func _initialize() -> void:
	_run.call_deferred()


func _ok(cond: bool, what: String) -> void:
	print("%s %s" % ["  ok  " if cond else "  FAIL", what])
	if not cond:
		_fails += 1


func _make(src: String) -> Node3D:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	return s.new() as Node3D


func _find(arts: Array, token: String) -> Dictionary:
	for a in arts:
		if String((a as Dictionary).get("token", "")) == token:
			return a
	return {}


func _run() -> void:
	var link: Node = load("res://commons/bridge/vr_link.gd").new()
	link.name = "VRLinkProbe"
	root.add_child(link)   # not armed: _ready disables processing; the handlers are called by hand

	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)

	# a deck: a static body whose top is at y = 0.5, as a height-1 floor's is
	var deck := StaticBody3D.new()
	var dcs := CollisionShape3D.new()
	var dbox := BoxShape3D.new()
	dbox.size = Vector3(40.0, 1.0, 40.0)
	dcs.shape = dbox
	deck.add_child(dcs)
	world.add_child(deck)

	var a: Node3D = _make(ART_A)
	a.name = "ProbeA"
	a.set_meta("artifact_lookup_name", "probe_a")
	a.set_meta("artifact_name", "Probe A")
	a.set_meta("description", "a thing that answers interact()")
	a.set_meta("grid_cell", Vector2i(3, 5))
	a.position = Vector3(3.0, 0.5, 5.0)
	var am := MeshInstance3D.new()
	am.mesh = BoxMesh.new()
	am.position = Vector3(0.0, 0.5, 0.0)
	a.add_child(am)
	world.add_child(a)

	var b: Node3D = _make(ART_B)
	b.name = "ProbeB"
	b.set_meta("artifact_lookup_name", "probe_b")
	b.set_meta("grid_cell", Vector2i(8, 5))
	b.position = Vector3(8.0, 0.5, 5.0)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 1 << 19
	var acs := CollisionShape3D.new()
	var abox := BoxShape3D.new()
	abox.size = Vector3(1.0, 2.0, 1.0)
	acs.shape = abox
	area.add_child(acs)
	area.body_entered.connect(Callable(b, "_on_body_entered"))
	b.add_child(area)
	world.add_child(b)

	var c: Node3D = _make(ART_C)
	c.name = "ProbeC"
	c.set_meta("artifact_lookup_name", "probe_c")
	c.position = Vector3(12.0, 0.5, 5.0)
	world.add_child(c)

	var d := Node3D.new()
	d.name = "ProbeD"
	d.set_meta("artifact_lookup_name", "probe_d")
	d.position = Vector3(3.0, 0.5, 9.0)
	var rb := RigidBody3D.new()
	rb.name = "Ball"
	rb.collision_layer = 4
	var rcs := CollisionShape3D.new()
	rcs.shape = SphereShape3D.new()
	rb.add_child(rcs)
	d.add_child(rb)
	world.add_child(d)

	var t: Node3D = _make(TELE)
	t.name = "Teleporter"
	t.add_to_group("utility")
	t.position = Vector3(3.0, 0.5, 12.0)
	world.add_child(t)

	# the deck must be in the physics space before a floor ray can find it
	await physics_frame
	await physics_frame

	# 1. scan — what stands here, and what each answers to
	var scene: Dictionary = link._command({"cmd": "scan", "tag": "s1"})
	_ok(String(scene.get("k", "")) == "scene", "scan answers `scene`")
	_ok(String(scene.get("tag", "")) == "s1", "the command's tag rides back on the reply")
	var arts: Array = scene.get("artifacts", [])
	_ok(arts.size() == 4, "scan finds the four artifacts (found %d)" % arts.size())
	var rec_a: Dictionary = _find(arts, "probe_a")
	_ok(rec_a.get("cell", []) == [5, 3], "grid_cell (x=3, z=5) is reported as [row 5, col 3]: %s" % str(rec_a.get("cell")))
	_ok("interact" in rec_a.get("affordances", []), "probe_a affords interact")
	_ok(String(rec_a.get("description", "")) != "", "the description meta is carried")
	var rec_b: Dictionary = _find(arts, "probe_b")
	_ok("touch" in rec_b.get("affordances", []) and not ("interact" in rec_b.get("affordances", [])), "probe_b affords touch, not interact")
	var rec_c: Dictionary = _find(arts, "probe_c")
	_ok(not ("interact" in rec_c.get("affordances", [])), "interact(action) that needs an argument is NOT an affordance")
	var rec_d: Dictionary = _find(arts, "probe_d")
	_ok("grab" in rec_d.get("affordances", []), "a rigid body child affords grab")
	var utils: Array = scene.get("utilities", [])
	_ok(utils.size() == 1 and bool((utils[0] as Dictionary).get("teleporter", false)), "the teleporter is listed as a utility")

	# 2. walker: cells, a body, arrival
	var w: Dictionary = link._command({"cmd": "walker", "cells": [[5, 1], [5, 2]], "body": true, "report": true, "speed": 100.0, "tag": "w1"})
	_ok(String(w.get("msg", "")).begins_with("walker: 2 waypoints"), "walker takes cells: %s" % String(w.get("msg", "")))
	var ghost: Node = link.get("_ghost")
	_ok(ghost is CharacterBody3D, "body:true builds a CharacterBody3D")
	_ok(ghost != null and (ghost as CollisionObject3D).collision_layer == (1 << 19), "the body stands on layer 20")
	_ok(ghost != null and not ghost.is_in_group("player") and not ghost.is_in_group("player_body") and ghost.is_in_group("em_walker"), "the body is em_walker, never player / player_body")
	_ok(ghost != null and not String(ghost.name).contains("Player") and not String(ghost.name).contains("XR"), "its name matches no hazard's player test")
	var y0: float = (ghost as Node3D).global_position.y
	_ok(absf(y0 - 0.52) < 0.05, "the walker stands ON the deck (y %.2f; deck top 0.5)" % y0)
	_ok(absf((ghost as Node3D).global_position.x - 1.0) < 0.01 and absf((ghost as Node3D).global_position.z - 5.0) < 0.01, "cell [row 5, col 1] is world x=1 z=5 with no grid present")
	for i in 10:
		link._step_ghost(0.1)
	_ok(int(link.get("_ghost_i")) == 1 and not bool(link.get("_ghost_report")), "the walk reaches its last waypoint and reports arrival once")

	# 3. look
	var seen: Dictionary = link._command({"cmd": "look", "token": "probe_a", "dwell": 0.1})
	_ok(bool(seen.get("ok", false)) and String(seen.get("k", "")) == "seen", "look answers `seen` ok")
	_ok(bool(seen.get("line_of_sight", false)), "nothing between the eye and probe_a: line of sight")
	_ok(float(seen.get("distance", 0.0)) > 0.5, "distance measured: %.2f m" % float(seen.get("distance", 0.0)))
	_ok("interact" in seen.get("affordances", []), "the look carries the affordances")
	var miss: Dictionary = link._command({"cmd": "look", "token": "nope"})
	_ok(not bool(miss.get("ok", true)), "looking for a token that is not there says so")

	# 4. interact auto → interact() on A
	var acted: Dictionary = link._command({"cmd": "interact", "token": "probe_a", "verb": "auto"})
	_ok(bool(acted.get("ok", false)) and String(acted.get("verb", "")) == "interact", "auto climbs to interact(): %s" % String(acted.get("detail", "")))
	_ok(int(a.get("hits")) == 1, "probe_a.interact() ran once")

	# 5. touch on B: the volume was told a player entered; the walker left the groups again
	var touched: Dictionary = link._command({"cmd": "interact", "token": "probe_b", "verb": "auto"})
	_ok(bool(touched.get("ok", false)) and String(touched.get("verb", "")) == "touch", "auto falls to touch for a trigger volume: %s" % String(touched.get("detail", "")))
	_ok(int(b.get("seen_player")) == 1 and int(b.get("seen_other")) == 0, "the volume saw a player enter, once")
	_ok(not (link.get("_ghost") as Node).is_in_group("player") and not (link.get("_ghost") as Node).is_in_group("player_body"), "…and the walker is no longer a player")

	# 6. C: interact(action) is never called bare
	var nothing: Dictionary = link._command({"cmd": "interact", "token": "probe_c", "verb": "auto"})
	_ok(not bool(nothing.get("ok", true)) and int(c.get("called")) == 0, "auto refuses an interact(action) it cannot call bare")

	# 7. grab and drop D's ball
	var grabbed: Dictionary = link._command({"cmd": "interact", "token": "probe_d", "verb": "auto"})
	_ok(bool(grabbed.get("ok", false)) and String(grabbed.get("verb", "")) == "grab", "auto grabs the rigid body: %s" % String(grabbed.get("detail", "")))
	_ok(rb.get_parent() == link.get("_ghost_hand") and rb.freeze and rb.collision_layer == 0, "the ball rides the hand, frozen, on no layer")
	var dropped: Dictionary = link._command({"cmd": "interact", "verb": "drop"})
	_ok(bool(dropped.get("ok", false)), "drop answers")
	_ok(rb.get_parent() != link.get("_ghost_hand") and not rb.freeze and rb.collision_layer == 4, "the ball is back in the world with its layer and motion")

	# 8. the teleporter: auto never takes it; teleport does
	var tele_auto: Dictionary = link._command({"cmd": "interact", "utility": true, "verb": "auto"})
	_ok(not bool(tele_auto.get("ok", true)) and int(t.get("started")) == 0, "auto never takes the teleporter")
	var tele: Dictionary = link._command({"cmd": "interact", "utility": true, "verb": "teleport"})
	_ok(bool(tele.get("ok", false)) and int(t.get("started")) == 1, "verb teleport starts the sequence")

	# 9. where
	var where: Dictionary = link._command({"cmd": "where"})
	_ok(String(where.get("k", "")) == "ghost" and where.get("cell", []) == [5, 2], "where reports the ghost's cell: %s" % str(where.get("cell")))

	# 10. walker_stop clears everything, including a held thing
	link._command({"cmd": "interact", "token": "probe_d", "verb": "grab"})
	link._command({"cmd": "walker_stop"})
	_ok(link.get("_ghost") == null and link.get("_held") == null, "walker_stop clears the ghost and drops what it held")
	_ok(rb.get_parent() != null and is_instance_valid(rb), "…and the ball survives the ghost")

	print("")
	print("PROBE %s" % ("OK" if _fails == 0 else "FAILED %d" % _fails))
	quit(_fails)
