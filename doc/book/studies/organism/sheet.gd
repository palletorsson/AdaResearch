extends SceneTree
## Renders the argument's sheet: the four values of `pivot`, each with the same
## three joint angles. Needs a window, so run it WITHOUT --headless:
##   godot --path . --xr-mode off --script res://sheet.gd
## Writes stills/<name>.png and sheet.json, the measurements TUTORIAL.md quotes:
## where the toe is at each value, how much of the frame the limb covers, which
## two values look most alike, and how many cells one whole turn takes.
## `above` is the study's own camera. `top` is a camera this script brings: it
## hangs over the limb and looks straight down, so that a turn about the upright
## axis is seen as it is. The labels are hidden so that only the body can differ.
## `limb_share` is the share of the frame that differs from the same view without
## the limb: from above that counts the limb's shadow too.

const VALUES := ["at the end", "at one third", "at the centre", "outside"]
const VIEWS := ["above", "top"]
const SMALL := Vector2i(320, 180)   # stills are measured at this size, saved at full size
const TOP_FROM := Vector3(-0.5, 4.0, 0.92)
const POSE := 30.0                  # degrees at each of the three joints
const TOE := "Organism/Hip/Upper/Lower/Foot/Toe"

var report := {}
var stills := {}

func _initialize() -> void: run.call_deferred()

func shot(name: String) -> Image:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png("res://stills/" + name + ".png")
	image.resize(SMALL.x, SMALL.y, Image.INTERPOLATE_BILINEAR)
	stills[name] = image
	return image

func changed(p: Color, q: Color) -> bool:
	return absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b) > 0.1

## The share of the frame on which two stills differ.
func differ_pct(a: Image, b: Image) -> float:
	var count := 0
	for y in SMALL.y:
		for x in SMALL.x:
			if changed(a.get_pixel(x, y), b.get_pixel(x, y)):
				count += 1
	return snappedf(100.0 * count / float(SMALL.x * SMALL.y), 0.01)

## One study with the limb built from one value of `pivot`. Nothing moves by
## itself: this script sets the angle and chooses the camera.
func open(value: int) -> Node3D:
	var study: Node3D = load("res://organism.tscn").instantiate()
	study.get_node("Organism").pivot = value
	root.add_child(study)
	study.get_node("Organism").set_process(false)
	await process_frame
	await process_frame
	study.set_process(false)
	study.get_node("Record").visible = false
	study.get_node("Readout").visible = false
	study.get_node("Organism/Lattice/Count").visible = false
	var top := Camera3D.new()
	top.name = "Top"
	top.projection = Camera3D.PROJECTION_ORTHOGONAL
	top.size = 2.0
	study.add_child(top)
	top.position = TOP_FROM
	top.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
	return study

## From the top the light casts no shadow: under a camera without perspective
## the shadows come out as soft patches that change from still to still.
func look(study: Node3D, view: String) -> void:
	var camera := {"above": "Camera3D", "top": "Top"}
	study.get_node(camera[view]).current = true
	study.get_node("DirectionalLight3D").shadow_enabled = view != "top"

func close(study: Node3D) -> void:
	study.free()
	await process_frame

## Every joint at the same angle, and the lattice whole again.
func pose(study: Node3D, degrees: float) -> void:
	var organism := study.get_node("Organism")
	organism.angle = deg_to_rad(degrees)
	organism._process(0.0)
	organism.get_node("Lattice").fill()

## One whole turn in steps of 1/60 s, the lattice carved as the lesson's script
## carves it. Returns the number of cells that went.
func turn(study: Node3D) -> int:
	var organism := study.get_node("Organism")
	var lattice := organism.get_node("Lattice")
	organism.angle = 0.0
	organism._process(0.0)
	lattice.fill()
	while organism.angle < TAU:
		organism._process(1.0 / 60.0)
	return lattice.lost.size()

func rounded(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]

func pairs(prefix: String, view: String) -> void:
	var table := {}
	var closest := ""
	var closest_share := 1.0e9
	var farthest := ""
	var farthest_share := -1.0
	for i in VALUES.size():
		for j in range(i + 1, VALUES.size()):
			var share := differ_pct(stills["%d_%s%s" % [i, prefix, view]], stills["%d_%s%s" % [j, prefix, view]])
			var key := "%d vs %d" % [i, j]
			table[key] = share
			if share < closest_share:
				closest_share = share
				closest = key
			if share > farthest_share:
				farthest_share = share
				farthest = key
			print("%s%s: %s differ on %5.2f%% of the frame" % [prefix, view, key, share])
	report["pairs_%s%s_pct" % [prefix, view]] = table
	report["closest_pair_%s%s" % [prefix, view]] = closest
	report["farthest_pair_%s%s" % [prefix, view]] = farthest
	print("sheet: closest pair, %s%s, is %s (%.2f%%); farthest is %s (%.2f%%)" % [prefix, view, closest, closest_share, farthest, farthest_share])

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://stills"))
	FileAccess.open("res://stills/.gdignore", FileAccess.WRITE)   # the editor then leaves the stills alone
	# The reference: the study with the lattice whole and no limb.
	var study := await open(0)
	study.get_node("Organism/Hip").visible = false
	for view in VIEWS:
		look(study, view)
		await shot("empty_" + view)
	await close(study)
	# The four values: at rest, then with every joint at 30 degrees, then after one whole turn.
	for v in VALUES.size():
		study = await open(v)
		var toe: Node3D = study.get_node(TOE)
		pose(study, 0.0)
		look(study, "top")
		await shot("%d_rest_top" % v)
		pose(study, POSE)
		var entry := {"value": VALUES[v], "toe": rounded(toe.global_position)}
		for view in VIEWS:
			look(study, view)
			var name := "%d_%s" % [v, view]
			await shot(name)
			entry["limb_share_%s_pct" % view] = differ_pct(stills[name], stills["empty_" + view])
		var hip: Vector3 = study.get_node("Organism/Hip").global_position
		entry["toe_from_hip_m"] = snappedf(Vector2(toe.global_position.x - hip.x, toe.global_position.z - hip.z).length(), 0.001)
		entry["cells_lost_in_one_turn"] = turn(study)
		look(study, "top")
		await shot("%d_turn_top" % v)
		report[str(v)] = entry
		print("%d %-13s toe at %s, %.3f m from the hip; limb on %5.2f%% of the frame from above, %5.2f%% from the top; one turn takes %d cells" % [
			v, VALUES[v], entry["toe"], entry["toe_from_hip_m"], entry["limb_share_above_pct"], entry["limb_share_top_pct"], entry["cells_lost_in_one_turn"]])
		await close(study)
	pairs("rest_", "top")
	for view in VIEWS:
		pairs("", view)
	# Outside the axis. The lattice told the toe's `position` and not its `global_position`.
	study = await open(0)
	var organism := study.get_node("Organism")
	var lattice := organism.get_node("Lattice")
	var steps := 0
	while steps < 629:
		organism.angle = steps * 0.01
		organism.get_node("Hip/Upper").rotation.y = organism.angle
		organism.get_node("Hip/Upper/Lower").rotation.y = organism.angle
		organism.get_node("Hip/Upper/Lower/Foot").rotation.y = organism.angle
		lattice.carve(study.get_node(TOE).position)
		steps += 1
	look(study, "top")
	await shot("local_turn_top")
	var gone: Array = lattice.lost.duplicate()
	gone.sort()
	report["local_position"] = {"cells_lost_in_one_turn": gone.size(), "cells": str(gone), "asked_at": rounded(study.get_node(TOE).position)}
	print("the lattice told the toe's position %s for one whole turn: %d cells went: %s" % [study.get_node(TOE).position, gone.size(), gone])
	await close(study)
	# Outside the axis. The bars turned and not their joints: 30 degrees on each Bar.
	study = await open(0)
	pose(study, 0.0)
	for path in ["Hip/Upper/Bar", "Hip/Upper/Lower/Bar", "Hip/Upper/Lower/Foot/Bar"]:
		study.get_node("Organism/" + path).rotation.y = deg_to_rad(POSE)
	look(study, "top")
	await shot("bars_turned_top")
	report["bars_turned"] = {"toe": rounded(study.get_node(TOE).global_position),
		"differs_from_rest_pct": differ_pct(stills["bars_turned_top"], stills["0_rest_top"]),
		"differs_from_centre_pct": differ_pct(stills["bars_turned_top"], stills["2_top"])}
	print("the three bars turned 30 degrees and no joint: toe at %s; differs from rest on %.2f%% of the frame" % [report["bars_turned"]["toe"], report["bars_turned"]["differs_from_rest_pct"]])
	await close(study)
	# Outside the axis. A stretch on a joint: Upper scaled (1, 1, 2), every joint at 30 degrees.
	study = await open(0)
	pose(study, POSE)
	study.get_node("Organism/Hip/Upper").scale = Vector3(1, 1, 2)
	var lower: Node3D = study.get_node("Organism/Hip/Upper/Lower")
	look(study, "top")
	await shot("stretched_joint_top")
	report["stretched_joint"] = {
		"lower_x_to_z_degrees": snappedf(rad_to_deg(lower.global_basis.x.angle_to(lower.global_basis.z)), 0.01),
		"lower_x_length": snappedf(lower.global_basis.x.length(), 0.001),
		"lower_z_length": snappedf(lower.global_basis.z.length(), 0.001),
		"toe": rounded(study.get_node(TOE).global_position),
		"differs_from_unstretched_pct": differ_pct(stills["stretched_joint_top"], stills["0_top"]),
	}
	print("Upper stretched (1, 1, 2): Lower's x and z axes stand at %.2f degrees, %.3f and %.3f long" % [
		report["stretched_joint"]["lower_x_to_z_degrees"], report["stretched_joint"]["lower_x_length"], report["stretched_joint"]["lower_z_length"]])
	await close(study)
	report["godot"] = Engine.get_version_info().string
	report["renderer"] = RenderingServer.get_video_adapter_name()
	FileAccess.open("res://sheet.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	quit(0)
