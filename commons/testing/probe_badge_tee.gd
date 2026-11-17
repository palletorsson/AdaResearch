extends Node3D
## THE BADGE T-SHIRT, PROVED (2026-11-17). The real CareBody (commons/void/care_body.gd) on a stand-in head camera and
## walker, so the shirt is put on by care_body's own hook, never by this probe. Checks:
##   hook            the care body's torso wears a BadgeTee; a bare android (no care body) wears none
##   first           nothing collected: the print is the first shirt - badge words, line and pink are coins.json
##                   shirt.first's, the print surface draws exactly tee.print_texture, and its pixels hold a pink rim,
##                   pink letters inside the disc and a pink line under it
##   fit_knit        every knit torso vertex from the hem to the neckline is inside the shell: a ray from the body's
##                   axis through the vertex reaches the shell mesh's own triangles further out
##   fit_profile     the same with a changed profile (shoulders 1.22, waist 0.86, hips 1.20; the knit skinned)
##   fit_armor       the armor look: every torso plate vertex is inside the refitted shell
##   sleeves_fit     every knit upper-arm vertex in a sleeve's reach that MOVES WITH THE ARM (>= 0.95 of its weight on that
##                   upper arm) is inside it, at rest and posed; the shoulder junction's blended vertices, which no rigid
##                   sleeve can follow, are counted and reported beside it
##   sleeves_follow  posing the arms moves each sleeve with its upper-arm link (same global transform, and moved)
##   collect         badges.gd collect(): the print is that coin's face and name the moment it is collected; a second
##                   collect wears the newer; a fresh tee (a restart) wears the last collected
##   mirror          the print reads from the front: pink pixels in the front view, with the print against without
##   first_person    the player looking down sees it: the head camera's view changes where the print is drawn (against the
##                   same frame with the print surface drawn as plain cloth), and the shell is on a layer the head sees
## Pictures (ada_run/badges/tee/run/): front, three-quarter, chest and first-person look-down, of the first shirt and of
## the shirt with a collected badge; the arms posed; the armor look; and each print texture as drawn.
## Run (a window; it renders):
##   python tools/godot_watchdog.py --expect=ada_run/badges/tee/run --grace=120 --stall=40 -- <godot> --path <ABS repo>
##       --xr-mode off --resolution 1000x1000 res://commons/testing/probe_badge_tee.tscn -- [--out=res://ada_run/badges/tee/run]
##       [--badges-path=<path.json>] [--break=first|fit|follow|listen|layer]   (the named check must then FAIL)
## The collected coins are kept in <out>/collected.json, never the game's user://badges.

const CareBody := preload("res://commons/void/care_body.gd")
const Android := preload("res://commons/void/ada_android.gd")
const Tee := preload("res://commons/void/badge_tee.gd")
const Badges := preload("res://commons/player/badges.gd")
const REAL_PATH := "res://commons/data/badges/path.json"
const COINS := "res://commons/data/badges/coins.json"
const WANT_COINS := ["translate", "paradox_compass"]
const HUD_BAND := 60   # px at the frame's bottom the pixel counts skip

var out := "res://ada_run/badges/tee/run"
var path_arg := ""
var breaks := ""
var report := {"checks": [], "observations": {}, "shots": []}
var cam: Camera3D
var feet: CharacterBody3D
var body: Node3D
var tee: Node3D
var shot: Camera3D
var ink := Color("eb0d85")
var torso: Node3D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--badges-path="):
			path_arg = a.trim_prefix("--badges-path=")
		elif a.begins_with("--break="):
			breaks = a.trim_prefix("--break=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	_run.call_deferred()


func _run() -> void:
	get_window().size = Vector2i(1000, 1000)
	_stage()
	Badges.path_file = path_arg if path_arg != "" else REAL_PATH
	Badges.collected_file = out.path_join("collected.json")
	Badges.grant_all = false
	Badges.reread()
	Badges.forget_all()
	report.observations["path_file"] = Badges.path_file
	report.observations["coins_on_path"] = Badges.count()
	report.observations["break"] = breaks
	if breaks == "first":   # the tee reads another shirt line than the authored one
		var fixture := out.path_join("coins_fixture.json")
		var f := FileAccess.open(fixture, FileAccess.WRITE)
		f.store_string(JSON.stringify({"shirt": {"first": {"badge": "ADA", "text": "NOT THE AUTHORED LINE", "colour": "#eb0d85"}}}))
		f.close()
		Tee.coins_file = fixture
	if breaks == "fit":
		Tee.fit_margin = -0.02
	Tee.forget_fits()
	var authored: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(COINS)).get("shirt", {}).get("first", {})
	report.observations["authored_first"] = authored
	if Color.html_is_valid(str(authored.get("colour", ""))):
		ink = Color(authored.colour)

	feet = CharacterBody3D.new()
	feet.name = "Walker"
	add_child(feet)
	cam = Camera3D.new()
	cam.name = "Head"
	cam.fov = 90.0
	cam.near = 0.05
	cam.position = Vector3(0.0, 1.65, -0.12)
	add_child(cam)
	body = CareBody.new()
	body.name = "CareBody"
	body.appearance_path = ""   # never this machine's saved look
	add_child(body)
	var t0 := Time.get_ticks_usec()
	body.configure(cam, feet)
	report.observations["configure_ms"] = (Time.get_ticks_usec() - t0) / 1000.0
	torso = body.get("torso")
	tee = torso.get_node_or_null("BadgeTee")
	await _physics(6)
	await _frames(2)

	# -- hook
	var bare := Android.new()
	bare.position = Vector3(20, 0, 0)
	add_child(bare)
	bare.assemble(1 << 19, false)
	_check("hook", tee != null and tee.get_parent() == torso and bare.get_node_or_null("BadgeTee") == null,
		"care body torso child BadgeTee: %s; bare android has one: %s" % [tee != null, bare.get_node_or_null("BadgeTee") != null])
	# what wearing costs a fresh android with nothing kept (the knit read, both fits, the meshes; the print is kept)
	var keep_margin: float = Tee.fit_margin
	Tee.fit_margin = 0.009
	Tee.forget_fits(true)
	var t_wear := Time.get_ticks_usec()
	Tee.wear(bare)
	report.observations["cold_wear_ms"] = (Time.get_ticks_usec() - t_wear) / 1000.0
	Tee.fit_margin = keep_margin
	Tee.forget_fits()
	bare.queue_free()
	if tee == null:
		_finish()
		return
	report.observations["shell_surfaces"] = tee.shell.mesh.get_surface_count()
	report.observations["shell_vertices"] = _vertex_count(tee.shell.mesh)
	report.observations["sleeve_vertices"] = _vertex_count(tee.sleeves[0].mesh)
	report.observations["rings"] = tee.rings.size()
	if breaks == "follow":
		tee.set_process(false)
	if breaks == "listen":
		tee.remove_from_group("badge_listeners")
	if breaks == "layer":
		tee.shell.layers = 1 << 19

	# -- first
	var mat := (tee.shell as MeshInstance3D).get_surface_override_material(1) as StandardMaterial3D
	var first_tex: Texture2D = tee.print_texture
	var px := _print_pixels(first_tex, false)
	_save_texture(first_tex, "print_first.png")
	var words_ok: bool = tee.print_kind == "first" and tee.print_badge == str(authored.get("badge", "")) \
		and tee.print_text == str(authored.get("text", "")) and tee.print_colour.to_lower() == str(authored.get("colour", "")).to_lower()
	var tex_ok: bool = first_tex != null and mat != null and mat.albedo_texture == first_tex
	_check("first", words_ok and tex_ok and px.rim > 0.5 and px.inside > 0.04 and px.line > 0.02,
		"kind %s badge '%s' text '%s' colour %s (authored '%s' / '%s'); texture on print surface %s; pink rim %.2f, letters in disc %.3f, line %.3f" % [
			tee.print_kind, tee.print_badge, tee.print_text, tee.print_colour, authored.get("badge", ""), authored.get("text", ""), tex_ok, px.rim, px.inside, px.line])

	# -- fit at rest, unit profile
	var t1 := Time.get_ticks_usec()
	Tee.forget_fits()
	tee.refit()
	report.observations["fit_ms"] = (Time.get_ticks_usec() - t1) / 1000.0
	_fit_check("fit_knit", _knit_torso_points())
	_sleeve_check("sleeves_fit_rest")
	_progress("fit")

	# -- pictures of the first shirt + mirror / first-person
	await _shots("first")

	# -- profile
	body.set_profile({"shoulders": 1.22, "waist": 0.86, "hips": 1.20, "step_length": 1.0})
	await _frames(2)
	_fit_check("fit_profile", _knit_torso_points())
	body.set_profile({"shoulders": 1.0, "waist": 1.0, "hips": 1.0, "step_length": 1.0})
	await _frames(2)

	# -- armor
	var look: Dictionary = body.get_look()
	var knit_look := look.duplicate(true)
	look.shell = "Armor"
	body.set_look(look)
	await _frames(2)
	_fit_check("fit_armor", _armor_points())
	await _shoot(_front(), "armor_front.png")
	body.set_look(knit_look)
	await _frames(2)

	# -- sleeves follow the posed arms
	body.set_physics_process(false)
	var before: Array[Transform3D] = [tee.sleeves[0].global_transform, tee.sleeves[1].global_transform]
	torso.pose(0.016, Vector3.ZERO, true, Basis.IDENTITY, [Vector3(-0.44, 1.40, -0.32), Vector3(0.50, 1.12, -0.36)])
	await _frames(2)
	var detail := []
	var follows := true
	for i in 2:
		var now: Transform3D = tee.sleeves[i].global_transform
		var link: Transform3D = tee.links[i].global_transform
		var moved := before[i].origin.distance_to(now.origin)
		var turned := rad_to_deg(before[i].basis.y.normalized().angle_to(now.basis.y.normalized()))
		var off := _transform_gap(now, link)
		follows = follows and moved > 0.03 and turned > 15.0 and off < 0.0005
		detail.append("%s moved %.3f m, turned %.1f deg, off its link %.5f" % ["L" if i == 0 else "R", moved, turned, off])
	_check("sleeves_follow", follows, "; ".join(detail))
	_sleeve_check("sleeves_fit_posed")
	await _shoot(_three_quarter(), "posed_threequarter.png")
	await _shoot(_front(), "posed_front.png")
	tee.visible = false   # the same pose without the shirt: what the knit itself does at the shoulders and sides
	await _shoot(_three_quarter(), "posed_threequarter_notee.png")
	tee.visible = true
	body.set_physics_process(true)
	await _physics(4)
	await _frames(2)

	# -- collect
	var ids := _pick_coins()
	report.observations["collected_coins"] = ids
	if ids.size() < 2:
		_check("collect", false, "the path has fewer than two coins (%d)" % Badges.count())
	else:
		var c1: Dictionary = Badges.coin(ids[0])
		Badges.collect(ids[0])
		var after_one := [tee.print_kind, tee.print_badge, tee.print_text, tee.print_texture]
		var one_ok: bool = after_one[0] == "coin" and after_one[1] == ids[0] and after_one[2] == str(c1.name) and after_one[3] != first_tex and mat.albedo_texture == after_one[3]
		_save_texture(tee.print_texture, "print_coin_1.png")
		var c2: Dictionary = Badges.coin(ids[1])
		Badges.collect(ids[1])
		var two_ok: bool = tee.print_badge == ids[1] and tee.print_text == str(c2.name) and mat.albedo_texture == tee.print_texture
		var cpx := _print_pixels(tee.print_texture, true)
		_save_texture(tee.print_texture, "print_coin_2.png")
		Badges.reread()   # a restart: read collected.json again and dress a fresh android
		var fresh := Android.new()
		fresh.position = Vector3(20, 0, 0)
		add_child(fresh)
		fresh.assemble(1 << 19, false)
		var tee2: Node3D = Tee.wear(fresh)
		var restart_ok: bool = tee2 != null and tee2.print_badge == ids[1] and tee2.print_kind == "coin"
		fresh.queue_free()
		_check("collect", one_ok and two_ok and restart_ok and cpx.face > 0.5 and cpx.line > 0.02,
			"after %s: kind %s badge %s text '%s' (coin name '%s') new texture %s; after %s: badge %s text '%s'; restart wears %s; face drawn in disc %.2f, pink line %.3f" % [
				ids[0], after_one[0], after_one[1], after_one[2], c1.get("name", ""), after_one[3] != first_tex, ids[1], tee.print_badge, tee.print_text,
				tee2.print_badge if tee2 != null else "nothing", cpx.face, cpx.line])
	await _shots("coin")
	_finish()


# -- checks ------------------------------------------------------------------------------------------------------------

func _check(title: String, ok: bool, detail: String) -> void:
	report.checks.append({"check": title, "ok": ok, "detail": detail})
	print("CHECK %-18s %s  %s" % [title, "PASS" if ok else "FAIL", detail])
	_progress(title)


func _finish() -> void:
	var failed: Array = report.checks.filter(func(c): return not c.ok).map(func(c): return c.check)
	report["failed"] = failed
	var f := FileAccess.open(out.path_join("report.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ") + "\n")
	f.close()
	print("BADGE TEE: %d checks, %d failed %s" % [report.checks.size(), failed.size(), failed])
	get_tree().quit(0 if failed.is_empty() else 1)


func _progress(what: String) -> void:
	var f := FileAccess.open(out.path_join("progress.txt"), FileAccess.WRITE)
	f.store_string(what + "\n")
	f.close()


## Every body point must be inside the shell: a ray from the axis (0, y, 0) out through the point meets the shell's
## own triangles further out. Clearance = the farthest hit's distance - the point's.
func _fit_check(title: String, points: Array) -> void:
	var bins := {}
	for s in (tee.shell.mesh as Mesh).get_surface_count():
		var arrays: Array = (tee.shell.mesh as Mesh).surface_get_arrays(s)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for t in range(0, index.size(), 3):
			var tri := [v[index[t]], v[index[t + 1]], v[index[t + 2]]]
			var lo := floori(minf(tri[0].y, minf(tri[1].y, tri[2].y)) * 100.0)
			var hi := floori(maxf(tri[0].y, maxf(tri[1].y, tri[2].y)) * 100.0)
			for b in range(lo, hi + 1):
				if not bins.has(b):
					bins[b] = []
				bins[b].append(tri)
	var worst := INF
	var worst_at := Vector3.ZERO
	var misses := 0
	var clear: Array = []
	for p: Vector3 in points:
		var from := Vector3(0.0, p.y, 0.0)
		var flat := Vector3(p.x, 0.0, p.z)
		if flat.length() < 0.005:
			continue
		var reach := _reach(from, flat.normalized(), bins.get(floori(p.y * 100.0), []))
		if reach < 0.0:   # a ray exactly along a mesh edge can slip between its two triangles: once more, a hair aside
			reach = _reach(from, flat.normalized().rotated(Vector3.UP, 0.002), bins.get(floori(p.y * 100.0), []))
		if reach < 0.0:
			misses += 1
			continue
		var c := reach - flat.length()
		clear.append(c)
		if c < worst:
			worst = c
			worst_at = p
	clear.sort()
	var median: float = clear[clear.size() / 2] if not clear.is_empty() else -1.0
	_check(title, not clear.is_empty() and misses == 0 and worst >= 0.002,
		"%d body points, %d missed the shell; clearance min %.4f m at (%.3f, %.3f, %.3f), median %.4f m" % [
			points.size(), misses, worst, worst_at.x, worst_at.y, worst_at.z, median])


## The farthest of a ray's hits on these triangles (-1 when it hits none).
func _reach(from: Vector3, dir: Vector3, tris: Array) -> float:
	var reach := -1.0
	for tri in tris:
		var hit: Variant = Geometry3D.ray_intersects_triangle(from, dir, tri[0], tri[1], tri[2])
		if hit != null:
			reach = maxf(reach, (hit - from).length())
	return reach


## Every knit upper-arm vertex within a sleeve's reach is inside it, measured in the sleeve's own frame.
func _sleeve_check(title: String) -> void:
	var detail := []
	var ok := true
	for i in 2:
		var sleeve: MeshInstance3D = tee.sleeves[i]
		var arrays := sleeve.mesh.surface_get_arrays(0)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var bins := {}
		for t in range(0, index.size(), 3):
			var tri := [v[index[t]], v[index[t + 1]], v[index[t + 2]]]
			var lo := floori(minf(tri[0].y, minf(tri[1].y, tri[2].y)) * 50.0)
			var hi := floori(maxf(tri[0].y, maxf(tri[1].y, tri[2].y)) * 50.0)
			for b in range(lo, hi + 1):
				if not bins.has(b):
					bins[b] = []
				bins[b].append(tri)
		var to_sleeve: Transform3D = (torso.global_transform * sleeve.transform).affine_inverse() * torso.global_transform
		var bone := "ArmLUpper" if i == 0 else "ArmRUpper"
		var worst := INF
		var count := 0
		var misses := 0
		var junction := 0
		var junction_out := 0
		var weights := {}
		var points := _knit_points([bone], weights)
		for n in points.size():
			var q: Vector3 = to_sleeve * points[n]
			if q.y < Tee.SLEEVE_HEM + 0.01 or q.y > 1.2:
				continue
			var rigid: bool = weights[n] >= 0.95
			if not rigid:
				junction += 1
			else:
				count += 1
			var from := Vector3(0.0, q.y, 0.0)
			var flat := Vector3(q.x, 0.0, q.z)
			var reach := _reach(from, flat.normalized(), bins.get(floori(q.y * 50.0), []))
			if reach < 0.0:
				reach = _reach(from, flat.normalized().rotated(Vector3.UP, 0.002), bins.get(floori(q.y * 50.0), []))
			if not rigid:
				junction_out += int(reach < 0.0 or reach - flat.length() < 0.0)
				continue
			if reach < 0.0:
				misses += 1
				continue
			worst = minf(worst, reach - flat.length())
		ok = ok and count > 50 and misses == 0 and worst >= 0.002
		detail.append("%s %d arm points, %d missed, clearance min %.4f m (shoulder junction: %d blended points, %d outside)" % [
			"L" if i == 0 else "R", count, misses, worst, junction, junction_out])
	_check(title, ok, "; ".join(detail))


## The knit cover's vertices whose heaviest bone is one of `bones`, SKINNED as the renderer does (bone global pose x
## bind pose, weighted), in the android's frame. Every second vertex.
func _knit_points(bones: Array, weights_out: Variant = null) -> Array:
	var knit: Node = torso.get_node("KnitShell")
	var out_points: Array = []
	for surface: MeshInstance3D in knit.find_children("*", "MeshInstance3D", true, false):
		if surface.skin == null:
			continue
		var skeleton := surface.get_node(surface.skeleton) as Skeleton3D
		var skel_frame: Transform3D = Tee._relative(skeleton, torso)
		var poses: Array[Transform3D] = []
		var names: Array[String] = []
		for b in surface.skin.get_bind_count():
			var bind_name := String(surface.skin.get_bind_name(b))
			var bone_index := skeleton.find_bone(bind_name) if bind_name != "" else surface.skin.get_bind_bone(b)
			poses.append(skel_frame * skeleton.get_bone_global_pose(bone_index) * surface.skin.get_bind_pose(b))
			names.append(bind_name)
		var arrays := surface.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bone_ids: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var per := bone_ids.size() / verts.size()
		for i in range(0, verts.size(), 2):
			var heaviest := -1.0
			var best := 0
			var p := Vector3.ZERO
			for k in per:
				var w := weights[i * per + k]
				if w > heaviest:
					heaviest = w
					best = bone_ids[i * per + k]
				if w > 0.0:
					p += poses[bone_ids[i * per + k]] * verts[i] * w
			if names[best] in bones:
				if weights_out is Dictionary:
					weights_out[out_points.size()] = heaviest
				out_points.append(p)
	return out_points


func _knit_torso_points() -> Array:
	var points: Array = []
	for p: Vector3 in _knit_points(["Thorax", "WaistBellows", "PelvicShell"]):
		if p.y > Tee.HEM_Y + 0.004 and p.y < Tee.NECK_Y - 0.004:
			points.append(p)
	for p: Vector3 in _knit_points(["LegLUpper", "LegRUpper"]):
		if p.y > Tee.HEM_Y + 0.004 and p.y < Tee.HEM_Y + 0.03:
			points.append(p)
	return points


func _armor_points() -> Array:
	var points: Array = []
	for piece in torso.get_children():
		if not piece is MeshInstance3D or piece.mesh == null:
			continue
		var title := String(piece.name)
		var torso_piece := false
		for prefix in ["Thorax", "WaistBellows", "AbdominalPlate", "PelvicShell", "CoreBezel", "CoreLight", "SpineHinge", "HipBearing"]:
			torso_piece = torso_piece or title.begins_with(prefix)
		if not torso_piece:
			continue
		var arrays: Array = (piece.mesh as Mesh).surface_get_arrays(0)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var samples: Array = Array(v)
		for t in range(0, index.size() - 2, 3):
			for e in 3:
				var a: Vector3 = v[index[t + e]]
				var b: Vector3 = v[index[t + (e + 1) % 3]]
				var n := int(a.distance_to(b) / 0.006)
				for k in range(1, n + 1):
					samples.append(a.lerp(b, float(k) / (n + 1)))
		var top := Tee.HEM_Y + 0.03 if title.begins_with("HipBearing") else Tee.NECK_Y - 0.004
		for sample: Vector3 in samples:
			var p: Vector3 = piece.transform * sample
			if p.y > Tee.HEM_Y + 0.004 and p.y < top:
				points.append(p)
	return points


## Ink in the print texture, in print units (100 across): `rim` - the pink fraction of the disc's rim; `inside` - of
## the disc's middle (the first shirt's letters); `line` - of the caption box; `face` - the fraction of the disc not
## cloth-coloured (a coin face drawn there).
func _print_pixels(tex: Texture2D, coin: bool) -> Dictionary:
	var result := {"rim": 0.0, "inside": 0.0, "line": 0.0, "face": 0.0}
	if tex == null:
		return result
	var img := tex.get_image()
	if img == null:
		return result
	if img.is_compressed():
		img.decompress()
	var u := img.get_width() / 100.0
	var counts := {"rim": [0, 0], "inside": [0, 0], "line": [0, 0], "face": [0, 0]}
	var disc: Vector3 = Tee.DISC
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			var c := img.get_pixel(x, y)
			var at := Vector2(x / u, y / u)
			var r := at.distance_to(Vector2(disc.x, disc.y))
			var pink := _near(c, ink, 0.30)
			if absf(r - disc.z) < 1.2:
				counts.rim[0] += int(pink); counts.rim[1] += 1
			if r < disc.z - 7.0:
				counts.inside[0] += int(pink); counts.inside[1] += 1
			if r < disc.z:
				counts.face[0] += int(not _near(c, Tee.CLOTH, 0.06)); counts.face[1] += 1
			if at.y > Tee.CAPTION_TOP and at.y < Tee.CAPTION_TOP + Tee.CAPTION_H and at.x > 4.0 and at.x < 96.0:
				counts.line[0] += int(pink); counts.line[1] += 1
	for k in counts:
		result[k] = float(counts[k][0]) / maxf(1.0, counts[k][1])
	return result


static func _near(a: Color, b: Color, tolerance: float) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < tolerance


func _transform_gap(a: Transform3D, b: Transform3D) -> float:
	return maxf(a.origin.distance_to(b.origin), maxf((a.basis.x - b.basis.x).length(), maxf((a.basis.y - b.basis.y).length(), (a.basis.z - b.basis.z).length())))


func _pick_coins() -> Array:
	var ids: Array = []
	for id in WANT_COINS:
		if not Badges.coin(id).is_empty():
			ids.append(id)
	for c in Badges.coins():
		if ids.size() >= 2:
			break
		if not str(c.id) in ids:
			ids.append(str(c.id))
	return ids.slice(0, 2)


func _vertex_count(mesh: Mesh) -> int:
	var n := 0
	for s in mesh.get_surface_count():
		n += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return n


# -- pictures ----------------------------------------------------------------------------------------------------------

func _stage() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.17, 0.18, 0.21)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.56, 0.62)
	e.ambient_light_energy = 0.75
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, 205, 0)
	key.light_energy = 1.25
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 120, 0)
	fill.light_energy = 0.35
	add_child(fill)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8, 8)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.32, 0.32, 0.34)
	floor_mesh.material_override = floor_mat
	add_child(floor_mesh)
	shot = Camera3D.new()
	shot.name = "ShotCamera"
	shot.fov = 34.0
	add_child(shot)


func _front() -> Array:
	return [Vector3(0.0, 1.22, -2.05), Vector3(0.0, 1.08, 0.0)]


func _three_quarter() -> Array:
	return [Vector3(1.25, 1.36, -1.6), Vector3(0.0, 1.1, 0.0)]


func _chest() -> Array:
	return [Vector3(0.0, 1.28, -0.78), Vector3(0.0, 1.25, 0.0)]


## Front, three-quarter and chest from the shot camera; the look-down from the head camera. The mirror and
## first-person checks count pink pixels with the print and with the print surface drawn as plain cloth.
func _shots(kind: String) -> void:
	await _shoot(_front(), kind + "_front.png")
	var with_front := _pink(await _grab())
	await _shoot(_three_quarter(), kind + "_threequarter.png")
	await _shoot(_chest(), kind + "_chest.png")
	cam.rotation_degrees = Vector3(-62.0, 0.0, 0.0)
	cam.current = true
	await _physics(3)
	await _frames(3)
	_save(await _grab(), kind + "_lookdown_62.png")
	cam.rotation_degrees = Vector3(-75.0, 0.0, 0.0)
	await _physics(3)
	await _frames(3)
	var head_with := await _grab()
	var with_head := _pink(head_with)
	_save(head_with, kind + "_lookdown.png")
	var printed: Material = tee.shell.get_surface_override_material(1)
	tee.shell.set_surface_override_material(1, tee.shell.get_surface_override_material(0))
	await _frames(2)
	var head_without := await _grab()
	var without_head := _pink(head_without)
	var changed := _differ(head_with, head_without)
	_save(head_without, kind + "_lookdown_noprint.png")
	cam.rotation_degrees = Vector3.ZERO
	await _physics(3)
	_place(_front())
	await _frames(3)
	var without_front := _pink(await _grab())
	tee.shell.set_surface_override_material(1, printed)
	await _frames(2)
	var visible_to_head: bool = (tee.shell.layers & cam.cull_mask) != 0 and not cam.get_cull_mask_value(20)
	_check("mirror_" + kind, with_front - without_front > 40,
		"front view pink px with the print %d, without %d" % [with_front, without_front])
	_check("first_person_" + kind, visible_to_head and changed > 40,
		"head camera (pitch -75, fov 90): %d px change when the print is drawn as plain cloth (pink px %d with, %d without); shell layers %d in the head's mask %s (layer 20 hidden %s)" % [
			changed, with_head, without_head, tee.shell.layers, (tee.shell.layers & cam.cull_mask) != 0, not cam.get_cull_mask_value(20)])


func _place(view: Array) -> void:
	shot.position = view[0]
	shot.look_at(view[1], Vector3.UP)
	shot.current = true


func _shoot(view: Array, file: String) -> void:
	_place(view)
	await _frames(3)
	_save(await _grab(), file)


func _grab() -> Image:
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _save(img: Image, file: String) -> void:
	var path := ProjectSettings.globalize_path(out.path_join(file))
	img.save_png(path)
	report.shots.append(path)
	_progress(file)


func _save_texture(tex: Texture2D, file: String) -> void:
	if tex != null:
		var img := tex.get_image()
		img.clear_mipmaps()
		_save(img, file)


## Pixels (every second each way) that differ between two frames of the same view. The bottom HUD_BAND rows are not
## read: another session's HUD line ("mushrooms ..." at y 964-977) can appear between two frames (measured: 508 px).
func _differ(a: Image, b: Image) -> int:
	var n := 0
	for y in range(0, mini(a.get_height(), b.get_height()) - HUD_BAND, 2):
		for x in range(0, mini(a.get_width(), b.get_width()), 2):
			var p := a.get_pixel(x, y)
			var q := b.get_pixel(x, y)
			if absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b) > 0.15:
				n += 1
	return n


## Pixels of the print's pink (by hue) in a rendered frame, every second pixel each way. The hands (hue ~0.1) and
## the cream knit (low saturation) are not counted; pink nails are in both frames of a pair, so they cancel.
func _pink(img: Image) -> int:
	var n := 0
	for y in range(0, img.get_height() - HUD_BAND, 2):
		for x in range(0, img.get_width(), 2):
			var c := img.get_pixel(x, y)
			if c.s > 0.4 and c.v > 0.28 and c.h > 0.80 and c.h < 0.97:   # lit and tonemapped, #eb0d85 lands at 0.85-0.89
				n += 1
	return n


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _physics(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
