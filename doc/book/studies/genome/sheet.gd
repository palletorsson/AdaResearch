extends "res://supplied/sheet_tools.gd"
## The Genome kit's sheet. It needs a window, so run it WITHOUT --headless,
## from this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    the limb_count gene at 0, 2, 4, 6 and 12: each creature alone
##                in the studio, from straight above and from the side
##   process.png  the lesson's five steps from one standpoint: the cabinet's sheet,
##                place and walker, standing in the studio
##   sheet.json   every pair of the five, from both standpoints; how much of
##                the still each body covers; for every count from 0 to 12, on
##                how much of the still it differs from the body with 12, and
##                from itself turned by half the angle between two limbs; and
##                what each strip step built
## and the stills, in stills/. Only the limb_count gene changes on the sheet:
## 3 segments, limbs raised 25 degrees, BODY, body_seed 1.
## The strip saves and loads one file of its own, user://sheet_trial.tres, and
## removes it. It does not touch user://specimen.tres.

const Genes := preload("res://guests/genome/genes.gd")
const Creature := preload("res://guests/genome/genome.tscn")
const LIMBS := [0, 2, 4, 6, 12]
const VIEWS := ["above", "level"]
const TRIAL := "user://sheet_trial.tres"

## A creature of the default genome with this many limbs, turned `turn` radians.
func creature(limbs: int, turn := 0.0) -> Node3D:
	var genes := Genes.new()
	genes.limb_count = limbs
	var body: Node3D = Creature.instantiate()
	body.genes = genes
	body.rotation.y = turn
	return body

func run() -> void:
	await sheet()
	await series()
	await process_strip()

## The comparison sheet: every value from both standpoints, every pair measured.
func sheet() -> void:
	var tiles: Array[Image] = []
	var names := []
	for limbs: int in LIMBS:
		names.append("%d limbs" % limbs)
	for view: String in VIEWS:
		var stills := []
		var pixels := []
		var covers := {}
		for limbs: int in LIMBS:
			var taken: Array = await photograph(creature(limbs), view, "limbs_%d_%s" % [limbs, view])
			stills.append(taken[0])
			pixels.append(taken[1])
			tiles.append(small(taken[0]))
			covers[str(limbs)] = share(taken[1])
			print("%s, %d limbs: the body covers %.2f%% of the still" % [view, limbs, share(taken[1])])
		report["pairs_" + view] = compare_all(names, stills, pixels)
		report["covers_pct_" + view] = covers
		if view == "above":
			# One limb, in percent of the still: what it covers, and what it adds to a difference when it has no partner.
			report["one_limb_above"] = {"covers_pct": snappedf((covers["12"] - covers["0"]) / 12.0, 0.01), "differs_pct": snappedf(report["pairs_above"]["pairs"]["0 limbs vs 12 limbs"]["differ_pct"] / 12.0, 0.01)}
	report["sheet_png"] = await compose(tiles, LIMBS.size(), names, "res://sheet.png")

## Every count from 0 to 12, three ways. From the side, as built and turned by
## half the angle between two limbs, the most a turn can change it: does it
## matter where you stand? And each count against 12, from above and from the
## side: how far is it from the flower?
func series() -> void:
	var above := []
	var level := []
	var rows := {}
	for limbs in range(0, 13):
		var half := PI / maxi(limbs, 2)
		above.append(await photograph(creature(limbs), "above", "series_%d_above" % limbs))
		level.append(await photograph(creature(limbs), "level", "series_%d_level" % limbs))
		var side: Array = await photograph(creature(limbs, half), "level", "series_%d_turned" % limbs)
		var pair := compare(level[limbs][0], level[limbs][1], side[0], side[1])
		rows[str(limbs)] = {"turned_by_degrees": snappedf(rad_to_deg(half), 0.1), "turned_differ_pct": pair["differ_pct"], "turned_outline_pct": pair["outline_pct"],
			"covers_pct_above": share(above[limbs][1]), "covers_pct_level": share(level[limbs][1])}
	for limbs in range(0, 13):
		var from_above := compare(above[limbs][0], above[limbs][1], above[12][0], above[12][1])
		var from_side := compare(level[limbs][0], level[limbs][1], level[12][0], level[12][1])
		rows[str(limbs)]["against_12_above_pct"] = from_above["differ_pct"]
		rows[str(limbs)]["against_12_level_pct"] = from_side["differ_pct"]
		rows[str(limbs)]["against_12_level_outline_pct"] = from_side["outline_pct"]
		print("series: %2d limbs: against 12, %5.2f%% from above, %5.2f%% from the side (%5.2f%% outline); turned %5.1f degrees it differs from itself on %5.2f%% (%5.2f%% outline)" % [
			limbs, from_above["differ_pct"], from_side["differ_pct"], from_side["outline_pct"], rows[str(limbs)]["turned_by_degrees"], rows[str(limbs)]["turned_differ_pct"], rows[str(limbs)]["turned_outline_pct"]])
	report["series_0_to_12"] = rows

## The process strip: the lesson's steps, from one standpoint, in the studio.
## What stands in the studio is what cabinet.tscn adds to the base: its sheet,
## its place and its walker, where that scene puts them.
func process_strip() -> void:
	var scene: Node3D = load("res://cabinet.tscn").instantiate()
	scene.set_script(null)   # the lesson's finished script is not run: the steps are made here, one at a time
	var group := Node3D.new()
	for name: String in ["Sheet", "Place", "Walker"]:
		var node := scene.get_node(name)
		node.owner = null
		scene.remove_child(node)
		group.add_child(node)
	scene.free()
	await stand(group, false)    # not held: the walker has to walk
	look_from(Vector3(-0.1, 4.6, 6.1), Vector3(-0.1, 0.2, -0.25))
	var place: Vector3 = group.get_node("Place").position
	var sheet_node: Node3D = group.get_node("Sheet")
	var walker: CharacterBody3D = group.get_node("Walker")
	var names := ["1 five genes, one body", "2 saved, recalled", "3 five bodies, one genome", "4 five copies", "5 the walker keeps one"]
	var tiles: Array[Image] = []
	var built := []

	# 1. a new genome, and the body built from it
	var kept: Node3D = Creature.instantiate()
	kept.genes = Genes.new()
	kept.position = place
	group.add_child(kept)
	tiles.append(small(await shot("strip_1")))
	built.append({"step": names[0], "specimen_parts": parts_of(kept), "row_parts": []})

	# 2. six limbs, saved; the file read from the disk; the body built again from what came back
	kept.genes.mutate("limb_count", 6)
	var error := ResourceSaver.save(kept.genes, TRIAL)
	kept.free()
	var parent: Resource = ResourceLoader.load(TRIAL, "", ResourceLoader.CACHE_MODE_IGNORE)
	kept = Creature.instantiate()
	kept.genes = parent
	kept.position = place
	group.add_child(kept)
	tiles.append(small(await shot("strip_2")))
	built.append({"step": names[1], "save_returned": error_string(error), "specimen_parts": parts_of(kept), "row_parts": []})

	# 3. the planted fault: the five on the sheet are handed the parent itself
	var row := []
	for value: int in LIMBS:
		parent.mutate("limb_count", value)
		var member: Node3D = Creature.instantiate()
		member.genes = parent
		sheet_node.hang(member, str(parent.get("limb_count")))
		row.append(member)
	tiles.append(small(await shot("strip_3")))
	built.append({"step": names[2], "specimen_parts": parts_of(kept), "row_parts": counts(row)})

	# 4. the repair: each of the five gets a copy
	parent.mutate("limb_count", 6)
	for i in row.size():
		var copy: Resource = parent.duplicate(true)
		copy.mutate("limb_count", LIMBS[i])
		var member: Node3D = Creature.instantiate()
		member.genes = copy
		member.position = row[i].position
		row[i].free()
		sheet_node.add_child(member)
		row[i] = member
	tiles.append(small(await shot("strip_4")))
	built.append({"step": names[3], "specimen_parts": parts_of(kept), "row_parts": counts(row)})

	# 5. the walker walks to the one with two limbs; a copy of its genome goes to the specimen
	walker.walk_to([Vector3(-1.2, 0.0, -0.3)])
	await walker.walk_ended
	await process_frame
	kept.genes = row[1].genes.duplicate(true)
	kept.genes.changed.connect(kept.build)
	kept.build()
	tiles.append(small(await shot("strip_5")))
	built.append({"step": names[4], "walk_ended": walker.ended, "specimen_parts": parts_of(kept), "row_parts": counts(row)})

	report["strip"] = await strip(tiles, names)
	report["strip"]["built"] = built
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TRIAL))
	group.free()
	subject = null

func parts_of(body: Node3D) -> int:
	return body.get_node("Parts").get_child_count()

func counts(bodies: Array) -> Array:
	var out := []
	for body: Node3D in bodies:
		out.append(parts_of(body))
	return out
