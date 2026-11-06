extends Node3D
## THE SPACE EDITOR'S POSSIBILITIES, BUILT (Palle, 2026-11-06: "show me all possibilities in images, build some good
## playgrounds"). The display workstation in `space` mode on a bench; seven playgrounds assembled piece by piece through
## the editor's own `model.add` (the same grammar the trigger uses: balls, rods, half rods, long rods, half and full
## faces, the 4 m plate, wedges, pyramids), each photographed from the hall and from inside at visitor height (half
## size, standing on the 1 m floor). Writes ada_run/space-gallery/<n>_<name>_{hall,inside}.png and report.json.
## Run: godot --path . --xr-mode off --resolution 1600x1000 res://commons/testing/probe_space_gallery.tscn

const Station = preload("res://commons/artifacts/scaffold_workstation/display.tscn")
const Model = preload("res://commons/artifacts/scaffold_workstation/model.gd")

var ws: Node3D
var cam: Camera3D
var out_dir := ""
var report := {"designs": []}
var added := 0
var refused: Array = []

func _ready() -> void:
	out_dir = ProjectSettings.globalize_path("res://ada_run/space-gallery"); DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color("d9dcd6")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color("f0ece4"); e.ambient_light_energy = .75
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC; e.ssao_enabled = true
	env.environment = e; add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, 35, 0); sun.light_energy = 1.25; sun.shadow_enabled = true; add_child(sun)
	var slab := StaticBody3D.new(); var fs := CollisionShape3D.new(); var fb := BoxShape3D.new(); fb.size = Vector3(40, .2, 40); fs.shape = fb; slab.add_child(fs)
	var fm := MeshInstance3D.new(); var fmesh := BoxMesh.new(); fmesh.size = Vector3(40, .2, 40); fm.mesh = fmesh
	var fmat := StandardMaterial3D.new(); fmat.albedo_color = Color("8d8f8b"); fmat.roughness = .9; fm.material_override = fmat; slab.add_child(fm); slab.position.y = -.1; add_child(slab)
	ws = Station.instantiate(); ws.set_meta("config_space", true); ws.set_meta("config_persist", false); add_child(ws)
	cam = Camera3D.new(); add_child(cam); cam.current = true
	for i in 40: await get_tree().process_frame
	var designs := [
		["catalogue", "Every piece once: ball, rod, half rod, long rod, half face, full face, wedge, pyramid", Callable(self, "_catalogue")],
		["climbing_frame", "A 2 x 2 x 2 m climbing frame with a deck at 1 m and a lookout on top", Callable(self, "_climbing_frame")],
		["bridge", "Two towers 3 m apart joined by a decked bridge at 1 m", Callable(self, "_bridge")],
		["pavilion", "Four posts and the 4 m plate as a roof, a bench of quads inside", Callable(self, "_pavilion")],
		["triangle_shade", "Walls of half faces: a sawtooth screen and a triangle roof", Callable(self, "_triangle_shade")],
		["solid_garden", "Wedges and pyramids as a landscape: ramps, hills, a stepped terrace", Callable(self, "_solid_garden")],
		["stair_tower", "Platforms at three levels reached by wedges, a fine half-metre cage beside", Callable(self, "_stair_tower")],
	]
	for i in designs.size():
		var d: Array = designs[i]
		ws.model.records.clear(); added = 0; refused = []
		(d[2] as Callable).call()
		ws.redraw(); ws.space_hide()
		ws._refresh_space_sockets("")   # the finished playground, without the lit dots of the next ball (they stay in the game)
		var guide: Node3D = ws.output.get_node_or_null("SpaceGuide")
		if guide: guide.visible = false
		for f in 4: await get_tree().process_frame
		var counts := {}
		for r in ws.model.records: counts[str(r.kind)] = int(counts.get(str(r.kind), 0)) + 1
		var name := "%d_%s" % [i + 1, d[0]]
		await _shoot(name + "_hall", ws.output.global_position + Vector3(-3.4, 3.1, 4.3), ws.output.global_position + Vector3(.1, 1.8, -.1), 56.0)
		# inside: the visitor at half size stands on the 1 m floor near START, eyes .85 m above it
		await _shoot(name + "_inside", ws.output.global_position + Vector3(.9, 1.0 + .85, 2.7), ws.output.global_position + Vector3(-.2, 1.6, -.2), 82.0)
		var row := {"name": name, "what": d[1], "records": ws.model.records.size(), "kinds": counts, "added": added, "refused": refused.map(func(r): return JSON.stringify(r))}
		report.designs.append(row)
		print("[space_gallery] %s: %d records %s; refused %d" % [name, ws.model.records.size(), JSON.stringify(counts), refused.size()])
	FileAccess.open("res://ada_run/space-gallery/report.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("[space_gallery] done")
	get_tree().quit(0)

func _shoot(name: String, at: Vector3, look: Vector3, fov: float) -> void:
	cam.global_position = at; cam.look_at(look); cam.fov = fov
	for i in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))

# ── the grammar, as the trigger uses it ─────────────────────────────────────────────────────────────────────────────

func _add(r: Dictionary) -> bool:
	if ws.model.add(r, ws.tier): added += 1; return true
	refused.append(r); return false

## Points grown outward from the origin: a ball needs a neighbour half or one step away, as in the hand.
func _grow(pts: Array) -> void:
	var want: Array = pts.duplicate()
	var progress := true
	while progress and not want.is_empty():
		progress = false
		for v in want.duplicate():
			if ws.model.points().has(Model.key(v)): want.erase(v); continue
			if ws.model.add({"kind": "point", "at": Model.arr(v)}, ws.tier): added += 1; want.erase(v); progress = true
	for v in want: refused.append({"kind": "point", "at": Model.arr(v)})

## Rods between every pair of the given points one step (or half a step) apart along an axis.
func _link(pts: Array, step := 1.0) -> void:
	var have := {}
	for v in pts: have[Model.key(v)] = v
	for v in have.values():
		for axis in Model.AXES:
			var w: Vector3 = v + Vector3(axis) * step
			if have.has(Model.key(w)): _add({"kind": "rod" if step == 1.0 else "rod_short", "at": Model.arr(v), "end": Model.arr(w)})

func _box_points(x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, step := 1.0) -> Array:
	var pts := []
	var x := x0
	while x <= x1 + .001:
		var y := y0
		while y <= y1 + .001:
			var z := z0
			while z <= z1 + .001:
				pts.append(Vector3(x, y, z)); z += step
			y += step
		x += step
	return pts

func _quad(at: Vector3, plane: Array) -> bool: return _add({"kind": "quad", "at": Model.arr(at), "plane": plane})
func _panel(at: Vector3, plane: Array, half: int) -> bool: return _add({"kind": "panel", "at": Model.arr(at), "plane": plane, "half": half})
func _solid(kind: String, at: Vector3, turn := [0, 0, 0]) -> bool: return _add(Model.canonical({"kind": kind, "at": Model.arr(at), "turn": turn}))

# ── the playgrounds ─────────────────────────────────────────────────────────────────────────────────────────────────

func _catalogue() -> void:
	# a ball; a rod; a half rod; a long rod; a half face; a full face; a wedge; a pyramid - side by side
	_grow([Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1.5, 0, 0), Vector3(2, 0, 0), Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(-1, 0, 0), Vector3(-1, 0, 1)])
	_add({"kind": "rod", "at": [0, 0, 0], "end": [1, 0, 0]})
	_add({"kind": "rod_short", "at": [1, 0, 0], "end": [1.5, 0, 0]})
	_add({"kind": "rod", "at": [0, 0, 0], "end": [0, 0, 1]})
	_add({"kind": "rod", "at": [1, 0, 0], "end": [1, 0, 1]})
	_add({"kind": "rod", "at": [0, 0, 1], "end": [1, 0, 1]})
	_quad(Vector3(0, 0, 0), [0, 2])                                                  # a full face, flat
	_add({"kind": "rod", "at": [-1, 0, 0], "end": [0, 0, 0]}); _add({"kind": "rod", "at": [-1, 0, 0], "end": [-1, 0, 1]}); _add({"kind": "rod", "at": [-1, 0, 1], "end": [0, 0, 1]})
	_panel(Vector3(-1, 0, 0), [0, 2], 0)                                             # a half face beside it
	_grow([Vector3(-1, 1, -1), Vector3(-1, 0, -1)])
	_add({"kind": "rod_4", "at": [-1, 0, -1], "end": [1, 0, -1]})                   # a long rod: 2 m, balls every metre
	_solid("wedge", Vector3(1.5, 0, 1.5))
	_solid("pyramid", Vector3(-.5, 0, 1.5))

func _climbing_frame() -> void:
	var pts := _box_points(0, 2, 0, 2, 0, 2)
	_grow(pts); _link(pts)
	for x in [0, 1]:
		for z in [0, 1]: _quad(Vector3(x, 1, z), [0, 2])                            # the deck at 1 m
	_quad(Vector3(1, 2, 1), [0, 2])                                                 # a lookout on top
	_quad(Vector3(0, 0, 0), [0, 1])                                                 # a climbing wall on one side

func _bridge() -> void:
	var a := _box_points(-1, -1, 0, 2, 0, 1)
	var b := _box_points(2, 2, 0, 2, 0, 1)
	var deck := _box_points(-1, 2, 1, 1, 0, 1)
	var all := a + b + deck
	_grow(all); _link(all)
	for x in [-1, 0, 1]: _quad(Vector3(x, 1, 0), [0, 2])                            # the walkway
	for x in [-1, 2]: _quad(Vector3(x, 1, 0), [1, 2])                               # a closed side on each tower
	_grow([Vector3(-1, 2, -1), Vector3(2, 2, -1)])
	_add({"kind": "rod", "at": [-1, 2, -1], "end": [-1, 2, 0]}); _add({"kind": "rod", "at": [2, 2, -1], "end": [2, 2, 0]})

func _pavilion() -> void:
	# long rods reach the far corners (a ball every metre), then the posts grow up from them
	_add({"kind": "rod_4", "at": [0, 0, 0], "end": [2, 0, 0]}); _add({"kind": "rod_4", "at": [0, 0, 0], "end": [0, 0, 2]})
	_add({"kind": "rod_4", "at": [2, 0, 0], "end": [2, 0, 2]}); _add({"kind": "rod_4", "at": [0, 0, 2], "end": [2, 0, 2]})
	var posts := []
	for c in [Vector2(0, 0), Vector2(2, 0), Vector2(0, 2), Vector2(2, 2)]:
		for y in [0, 1, 2]: posts.append(Vector3(c.x, y, c.y))
	_grow(posts); _link(posts)
	if not _add({"kind": "quad_4", "at": [0, 2, 0], "plane": [0, 2]}):               # the 4 m plate lays its own frame
		var roof := _box_points(0, 2, 2, 2, 0, 2); _grow(roof); _link(roof)
		for x in [0, 1]:
			for z in [0, 1]: _quad(Vector3(x, 2, z), [0, 2])
	var bench := [Vector3(0, .5, 0), Vector3(1, .5, 0), Vector3(0, .5, .5), Vector3(1, .5, .5), Vector3(.5, .5, 0), Vector3(.5, .5, .5)]
	_grow(bench); _link(bench, .5)
	_add({"kind": "quad", "at": [0, .5, 0], "plane": [0, 2], "span": .5}); _add({"kind": "quad", "at": [.5, .5, 0], "plane": [0, 2], "span": .5})

func _triangle_shade() -> void:
	var wall := _box_points(-1, 2, 0, 1, 0, 0)
	var back := _box_points(-1, 2, 0, 1, 1, 1)
	var all := wall + back
	_grow(all); _link(all)
	for x in [-1, 0, 1]:
		_panel(Vector3(x, 0, 0), [0, 1], x % 2 if x >= 0 else 1)                    # a sawtooth screen: alternating halves
		_panel(Vector3(x, 0, 1), [0, 1], 0); _panel(Vector3(x, 0, 1), [0, 1], 1)    # the back wall closed by two halves
		_panel(Vector3(x, 1, 0), [0, 2], (x + 1) % 2)                                # a triangle roof, half open to the sky

func _solid_garden() -> void:
	_solid("wedge", Vector3(-.5, 0, -.5), [0, 0, 0]); _solid("wedge", Vector3(.5, 0, -.5), [0, 1, 0])
	_solid("pyramid", Vector3(1.5, 0, -.5))
	_solid("wedge", Vector3(-.5, 0, .5), [0, 2, 0]); _solid("pyramid", Vector3(.5, 0, .5)); _solid("wedge", Vector3(1.5, 0, .5), [0, 3, 0])
	_solid("pyramid", Vector3(-.5, 0, 1.5)); _solid("wedge", Vector3(.5, 0, 1.5), [0, 1, 0]); _solid("wedge", Vector3(1.5, 0, 1.5), [0, 2, 0])
	_solid("wedge", Vector3(.5, .5, .5), [0, 0, 0])                                  # a terrace: a wedge on the hill
	var post := [Vector3(0, 0, 0), Vector3(0, .5, 0), Vector3(0, 1, 0), Vector3(0, 1.5, 0)]
	_grow(post); _link(post, .5)                                                     # a post from the corner four solids share
	var bar := [Vector3(-1, 1.5, 0), Vector3(0, 1.5, 0), Vector3(1, 1.5, 0), Vector3(2, 1.5, 0)]
	_grow(bar); _link(bar)                                                           # a crossbar to hang from

func _stair_tower() -> void:
	var tower := _box_points(1, 2, 0, 2, 0, 1)
	_grow(tower); _link(tower)
	_quad(Vector3(1, 1, 0), [0, 2]); _quad(Vector3(1, 2, 0), [0, 2])                 # landings at 1 m and 2 m
	var low := _box_points(0, 1, .5, .5, 0, 1, .5)
	_grow(low); _link(low, .5)
	_add({"kind": "quad", "at": [0, .5, 0], "plane": [0, 2], "span": .5}); _add({"kind": "quad", "at": [.5, .5, .5], "plane": [0, 2], "span": .5})
	_solid("wedge", Vector3(-.5, 0, .5), [0, 1, 0])                                  # the first step up
	var cage := _box_points(-1, 0, 0, 1, -1, 0, .5)                                   # a fine half-metre cage beside, grown from the origin
	_grow(cage); _link(cage, .5)
