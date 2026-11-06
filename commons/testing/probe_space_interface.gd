extends Node3D
## THE PLAYGROUND EDITOR'S INTERFACE, STATE BY STATE (Palle, 2026-11-06: "show me the interface of the editor", then
## the jumbotron design). The display workstation in `space` mode on a bench, a controller held where a visitor's right
## hand would be. Photographs: the box from the hall; inside under the jumbotron; a tile under the aim; BALL picked
## (lit nodes, the ghost, the ray); EDGE; QUAD on a square of edges; HEALTH onto the quad; and the drum of floor 3 with
## its later tools dark. Writes ada_run/space-interface/<n>_<state>.png and interface_sheet.png's inputs.
## Run: godot --path . --xr-mode off --resolution 1600x1000 res://commons/testing/probe_space_interface.tscn

const Station = preload("res://commons/artifacts/scaffold_workstation/display.tscn")

var ws: Node3D
var cam: Camera3D
var aim: Node3D
var controller: Node3D
var out_dir := ""
var shots: Array = []

func _ready() -> void:
	out_dir = ProjectSettings.globalize_path("res://ada_run/space-interface"); DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color("d9dcd6")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color("f0ece4"); e.ambient_light_energy = .8
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.environment = e; add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, 35, 0); sun.light_energy = 1.2; sun.shadow_enabled = true; add_child(sun)
	var slab := MeshInstance3D.new(); var sm := BoxMesh.new(); sm.size = Vector3(40, .2, 40); slab.mesh = sm; slab.position.y = -.1
	var smat := StandardMaterial3D.new(); smat.albedo_color = Color("8d8f8b"); slab.material_override = smat; add_child(slab)
	ws = Station.instantiate(); ws.set_meta("config_space", true); ws.set_meta("config_persist", false); ws.set_meta("config_space_floor", 20)
	ws.set_meta("config_chamber_height", 5.4); add_child(ws)
	aim = Node3D.new(); aim.name = "Aim"; add_child(aim)
	controller = _make_controller(); add_child(controller)
	cam = Camera3D.new(); add_child(cam); cam.current = true
	for i in 40: await get_tree().process_frame
	ws.model.records.clear(); ws.redraw()
	var box: Vector3 = ws.output.global_position
	var eye := box + Vector3(1.7, 1.65, 2.3)
	var up: Vector3 = ws.jumbotron.global_position
	# 1 - from the hall: the box on the floor, the jumbotron in its ceiling
	ws.space_inside_override = 0; ws._update_inside()
	await _state("1_from_the_hall", box + Vector3(-3.2, 1.75, 6.6), box + Vector3(0, 2.4, 0), 70.0, Vector3.INF)
	# 2 - inside, looking up: SELECT is the tool, the grid is on
	ws.space_inside_override = 1; ws._update_inside()
	await _state("2_inside_the_screens", eye, up + Vector3(0, -.3, 0), 74.0, Vector3.INF)
	# 3 - a tile under the aim: it lights; the guide says what the trigger will pick
	await _state("3_aiming_at_a_tile", eye, up + Vector3(0, -.3, 0), 74.0, _tile_pos("point"))
	# 4 - BALL picked: the nodes it can fill light, the ghost and the ray on the one under the aim
	_pick("point"); ws.model.add({"kind": "point", "at": [1, 0, 0]}, ws.tier); ws.model.add({"kind": "point", "at": [0, 0, 1]}, ws.tier); ws.redraw()
	await _state("4_ball", eye, box + Vector3(-.4, 1.2, -.4), 74.0, ws.output.to_global(ws.space_point({"kind": "point", "at": [1, 0, 1]})))
	# 5 - EDGE: the ghost edge between two balls
	ws.model.add({"kind": "point", "at": [1, 0, 1]}, ws.tier); ws.redraw(); _pick("edge")
	await _state("5_edge", eye, box + Vector3(-.4, .8, -.4), 74.0, ws.output.to_global(ws.space_point({"kind": "rod", "at": [0, 0, 0], "end": [1, 0, 0]})))
	# 6 - QUAD on a square of edges
	for r in [[[0, 0, 0], [1, 0, 0]], [[0, 0, 0], [0, 0, 1]], [[1, 0, 0], [1, 0, 1]], [[0, 0, 1], [1, 0, 1]]]: ws.model.add({"kind": "rod", "at": r[0], "end": r[1]}, ws.tier)
	ws.redraw(); _pick("quad")
	await _state("6_quad", eye, box + Vector3(-.4, .6, -.4), 74.0, ws.output.to_global(ws.space_point({"kind": "quad", "at": [0, 0, 0], "plane": [0, 2]})))
	# 7 - HEALTH onto the finished quad
	ws.model.add({"kind": "quad", "at": [0, 0, 0], "plane": [0, 2]}, ws.tier); ws.redraw(); _pick("health")
	await _state("7_health_on_the_quad", eye, box + Vector3(-.4, .6, -.4), 74.0, ws.output.to_global(ws.space_point({"kind": "quad", "at": [0, 0, 0], "plane": [0, 2]})))
	# 8 - floor 3's drum: BALL and EDGE open, the rest dark with the floor that opens them
	ws.space_floor = 3; ws.jumbotron.free(); ws._build_jumbotron(); ws.pick_tool("")
	ws.model.records.clear(); ws.model.add({"kind": "point", "at": [1, 0, 0]}, ws.tier); ws.redraw()
	await _state("8_floor_3_drum", eye + Vector3(-.4, 0, -.4), ws.jumbotron.global_position + Vector3(0, -.2, 0), 62.0, Vector3.INF)
	FileAccess.open("res://ada_run/space-interface/shots.json", FileAccess.WRITE).store_string(JSON.stringify(shots, "  "))
	print("[space_interface] %d shots" % shots.size())
	get_tree().quit(0)

func _state(name: String, at: Vector3, look: Vector3, fov: float, target: Vector3) -> void:
	cam.global_position = at; cam.look_at(look); cam.fov = fov
	ws.space_hide()
	if target != Vector3.INF:
		var h: Vector3 = at + cam.global_basis.x * .22 - cam.global_basis.y * .28 - cam.global_basis.z * .35
		aim.global_position = h; aim.look_at(target)
		controller.global_transform = aim.global_transform; controller.visible = true
		ws.space_update(aim)
	else:
		controller.visible = false
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	shots.append({"name": name, "tool": ws.space_tool, "hover": ws.space_hover_tile, "aimed": ws.space_aimed, "quad": ws.space_aimed_quad})

## The tile of a tool on the face turned toward the +x+z corner, where the visitor stands.
func _tile_pos(id: String) -> Vector3:
	var best: Node3D = null; var score := -2.0
	for t in ws.tiles:
		if str(t.id) != id: continue
		var n: Node3D = t.node; var s: float = n.global_basis.z.normalized().dot(Vector3(1, 0, 1).normalized())
		if s > score: score = s; best = n
	return best.global_position if best else Vector3.ZERO

## Aim at a tool's tile from in front of it, as a hand facing that screen does, and pull.
func _pick(id: String) -> void:
	var best: Node3D = null; var score := -2.0
	for t in ws.tiles:
		if str(t.id) != id: continue
		var n: Node3D = t.node; var s: float = n.global_basis.z.normalized().dot(Vector3(1, 0, 1).normalized())
		if s > score: score = s; best = n
	aim.global_position = best.global_position + best.global_basis.z.normalized() * 1.6; aim.look_at(best.global_position)
	var said: String = ws.space_press(aim)
	if ws.space_tool != id: push_warning("picked %s for %s (%s)" % [ws.space_tool, id, said])

func _make_controller() -> Node3D:
	var c := Node3D.new(); c.name = "Controller"
	var grip := MeshInstance3D.new(); var g := CapsuleMesh.new(); g.radius = .028; g.height = .14; grip.mesh = g; grip.rotation_degrees.x = -70; grip.position = Vector3(0, -.03, .03)
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color("2a2d31"); grip.material_override = gm; c.add_child(grip)
	var ring := MeshInstance3D.new(); var r := TorusMesh.new(); r.inner_radius = .035; r.outer_radius = .05; ring.mesh = r; ring.rotation_degrees.x = 90; ring.position = Vector3(0, .01, -.02)
	ring.material_override = gm; c.add_child(ring)
	return c
