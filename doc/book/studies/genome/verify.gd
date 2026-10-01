extends "res://supplied/verify_tools.gd"
## Headless checks of the Genome kit. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; the exit code is the number of
## checks that failed. No import step is needed: nothing here has a class_name.
## It checks the genes, the body built from them, what a saved file holds and
## what it leaves out, what a shared genome does (and that Godot says nothing),
## the cabinet with its walker and its key, a real restart (a second Godot is
## started and reads the file), the place, and the guest.
## The cabinet's file is user://specimen.tres. If you have one, it is put aside
## while the checks run and put back at the end.
## Headless draws no frames: what the eye gets is measured by sheet.gd.

const Look := preload("res://supplied/look.gd")
const CheckGuest := preload("res://supplied/check_guest.gd")
const Genes := preload("res://guests/genome/genes.gd")
const Creature := preload("res://guests/genome/genome.tscn")
const GUEST := "res://guests/genome/"
const FILE := "user://specimen.tres"            # the cabinet's file
const ASIDE := "user://specimen_before_verify.tres"
const TRIAL := "user://verify_trial.tres"       # this script's own
const SCRIPT_LINE := "[ext_resource type=\"Script\" path=\"res://guests/genome/genes.gd\""
const KEYS := {
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_forward": [KEY_W, KEY_UP], "move_backward": [KEY_S, KEY_DOWN],
	"pause": [KEY_SPACE], "drop": [KEY_M], "look": [KEY_V], "jump": [KEY_J], "switch_camera": [KEY_C],
}
const SUPPLIED := ["base.tscn", "base_look.gd", "check_guest.gd", "look.gd", "marble.gd", "marble.tscn", "mover.gd", "segment.gd", "sheet_tools.gd", "sweep_sheet.gd", "sweep_sheet.tscn",
	"trace_strip.gd", "verify_tools.gd", "walker.gd", "walker.tscn"]

## A resource that holds a resource and a list: what duplicate() leaves shared.
class Holder extends Resource:
	@export var inner: Resource
	@export var list: Array = []

func world() -> Node3D:
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	await frames(2)
	return base

func close(node: Node) -> void:
	node.free()
	await frames(1)

## A creature with these genes, standing in `base` at `at`.
func creature_in(base: Node3D, genes: Resource, at := Vector3.ZERO) -> Node3D:
	var creature: Node3D = Creature.instantiate()
	creature.genes = genes
	creature.position = at
	base.add_child(creature)
	return creature

func parts_of(creature: Node3D) -> int:
	return creature.get_node("Parts").get_child_count()

func of_kind(creature: Node3D, kind: String) -> Array:
	var out := []
	for part: MeshInstance3D in creature.get_node("Parts").get_children():
		if part.mesh.get_class() == kind:
			out.append(part)
	return out

func counts(creatures: Array) -> Array:
	var out := []
	for creature: Node3D in creatures:
		out.append(parts_of(creature))
	return out

## The box of everything a creature is built of, in the room.
func box_of(creature: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for part: MeshInstance3D in creature.get_node("Parts").get_children():
		var here: AABB = part.global_transform * part.get_aabb()
		box = here if first else box.merge(here)
		first = false
	return box

func flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)

func write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()   # a file is whole on the disk once it is closed

func remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

## A genome file as Godot writes one, with these lines under the script's.
func file_text(script_path: String, lines: String) -> String:
	return "[gd_resource type=\"Resource\" format=3]\n\n[ext_resource type=\"Script\" path=\"%s\" id=\"1\"]\n\n[resource]\nscript = ExtResource(\"1\")\n%s" % [script_path, lines]

## Reads a file from the disk, past what the loader remembers.
func fresh(path: String) -> Resource:
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)

func run() -> void:
	# What this run cannot see, measured on 1 October 2026 by the session that
	# built the kit, in scratch copies. Kept here so that the lesson quotes
	# nothing that is not written down.
	measured["recorded_by_hand"] = {
		"a_gene_named_seed": "run with the debugger attached, `@export var seed: int = 1` in genes.gd gave: WARNING: The variable \"seed\" has the same name as a built-in function.",
		"the_room": "in a scratch copy of my-room with guests/genome/ copied in and its line added, guest_trial.gd passed 8 of 8: place 2, the walk ended \"blocked\" 0.50 m from the middle of the place; looked at in a second scratch run, the guest had 6 limbs and 9 parts",
		"the_lesson": "every gdscript block of TUTORIAL.md applied in page order to a scratch copy and run after each step: what Godot printed matched the page's output blocks, and the last state equalled the three shipped scripts byte for byte",
		"not_run": "no headset, no hand on a keyboard, no eye on the stills, no exported build",
	}
	project()
	genes()
	await body()
	files()
	await sharing()
	await cabinet()
	await guest()

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Genome" and ProjectSettings.get_setting("application/run/main_scene") == "res://cabinet.tscn"
		and ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"the project is named Genome, its main scene is cabinet.tscn, its renderer Compatibility")
	var keys_ok := true
	for action: String in KEYS:
		var got := []
		if InputMap.has_action(action):
			for event: InputEvent in InputMap.action_get_events(action):
				got.append((event as InputEventKey).physical_keycode)
		keys_ok = keys_ok and got == KEYS[action]
	check(keys_ok, "the Input Map has the base's nine actions on their keys; pause, on Space, is the one this kit listens to")
	# supplied/ is the base's. Where the base stands beside this kit, as it does in
	# the course's own folder, each file is compared with it byte for byte.
	var base_folder := ProjectSettings.globalize_path("res://").path_join("../kit-base/supplied").simplify_path()
	var beside := DirAccess.dir_exists_absolute(base_folder)
	var found := []
	var changed := []
	for file in DirAccess.get_files_at("res://supplied"):
		if file.ends_with(".uid"):    # the editor writes one beside every script it has seen
			continue
		found.append(file)
		if beside and FileAccess.get_md5("res://supplied/" + file) != FileAccess.get_md5(base_folder.path_join(file)):
			changed.append(file)
	check(found == SUPPLIED and changed.is_empty(), "supplied/ holds the base's 15 files%s: changed %s" % [", each byte for byte the file in ../kit-base/supplied" if beside else " (this copy has no kit-base beside it to compare them with)", changed])
	measured["supplied_compared_with_the_base"] = beside
	var named := []
	var spaced := []
	for folder: String in ["res://", "res://supplied/", GUEST]:
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".gd"):
				continue
			if RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text_of(folder + file)) != null:
				named.append(file)
			if RegEx.create_from_string("(?m)^ +\\S").search(text_of(folder + file)) != null:
				spaced.append(file)
	check(named.is_empty() and ProjectSettings.get_global_class_list().is_empty(), "no script declares a class_name and the project lists no named class, so nothing needs an import: %s" % [named])
	check(spaced.is_empty(), "every script is indented with tabs: %s" % [spaced])
	var missing := []
	for path: String in ["res://cabinet.tscn", "res://cabinet.gd", "res://place.gd", GUEST + "genome.tscn", GUEST + "creature.gd", GUEST + "genes.gd", GUEST + "specimen.tres", "res://TUTORIAL.md", "res://README.md", "res://FIELD_NOTE.md"]:
		if not FileAccess.file_exists(path):
			missing.append(path)
	check(missing.is_empty(), "the kit's own files are there: the cabinet, the place, the four files of the guest, the lesson, the README and the field note: missing %s" % [missing])

func genes() -> void:
	var genes := Genes.new()
	var names := []
	for property: Dictionary in genes.get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and property["usage"] & PROPERTY_USAGE_STORAGE:
			names.append(property["name"])
	check(genes is Resource and not (genes as Object) is Node and names == ["segments", "limb_count", "limb_angle", "colour", "body_seed"],
		"genes.gd is a Resource and no node, with five exported genes: %s" % [names])
	check(typeof(genes.segments) == TYPE_INT and genes.segments == 3 and typeof(genes.limb_count) == TYPE_INT and genes.limb_count == 4 and typeof(genes.limb_angle) == TYPE_FLOAT and is_equal_approx(genes.limb_angle, 25.0)
		and typeof(genes.body_seed) == TYPE_INT and genes.body_seed == 1,
		"a new genome is 3 segments, 4 limbs raised 25 degrees, body_seed 1: two whole numbers, a decimal one and a whole one")
	check(typeof(genes.colour) == TYPE_COLOR and genes.colour.is_equal_approx(Look.BODY), "its colour gene starts as the look's BODY, written out: #%s" % genes.colour.to_html(false))
	var heard := [0]
	genes.changed.connect(func() -> void: heard[0] += 1)
	genes.mutate("limb_count", 6)
	check(genes.limb_count == 6 and heard[0] == 1, "mutate(\"limb_count\", 6) sets the gene and sends `changed` once: %d, heard %d" % [genes.limb_count, heard[0]])
	var before := errors.size() + warnings.size() + printed.size()
	genes.mutate("limbs", 3)
	check(genes.limb_count == 6 and genes.get("limbs") == null and errors.size() + warnings.size() + printed.size() == before,
		"mutate() with a name the genome does not have changes nothing and Godot says nothing: limb_count is still %d, get(\"limbs\") is %s" % [genes.limb_count, genes.get("limbs")])
	genes.mutate("limb_count", 2.0)
	var from_decimal: Variant = genes.limb_count
	genes.mutate("limb_count", "12")
	check(typeof(from_decimal) == TYPE_INT and from_decimal == 2 and genes.limb_count == 12, "handed 2.0 the gene holds the whole number %s; handed the text \"12\" it holds %d: set() converts in silence" % [from_decimal, genes.limb_count])
	var other := Genes.new()
	check(other != genes and other.limb_count == 4, "a second Genes.new() is another genome: it still has %d limbs" % other.limb_count)
	measured["genes"] = {"names": names, "default_colour": "#" + other.colour.to_html(false)}

func body() -> void:
	var base := await world()
	var scene_root: Node3D = Creature.instantiate()
	var shape: Shape3D = scene_root.get_node("Trunk/Shape").shape
	check(scene_root.name == "Creature" and scene_root.get_class() == "Node3D" and scene_root.has_node("Parts") and scene_root.get_node("Trunk") is StaticBody3D
		and shape is CylinderShape3D and is_equal_approx(shape.radius, 0.2) and is_equal_approx(shape.height, 0.8),
		"genome.tscn: a Node3D named Creature with Parts for what is built, and Trunk, a StaticBody3D with a cylinder of 0.2 m radius and 0.8 m height")
	scene_root.free()
	var genes := Genes.new()
	var creature := creature_in(base, genes)
	await frames(2)
	var balls := of_kind(creature, "SphereMesh")
	var limbs := of_kind(creature, "CapsuleMesh")
	check(parts_of(creature) == 7 and balls.size() == 3 and limbs.size() == 4, "a new genome builds 7 parts: %d balls and %d limbs" % [balls.size(), limbs.size()])
	var painted := true
	for part: MeshInstance3D in creature.get_node("Parts").get_children():
		var paint: StandardMaterial3D = part.material_override
		painted = painted and paint != null and paint.albedo_color.is_equal_approx(genes.colour) and is_equal_approx(paint.roughness, 0.8) and paint.metallic == 0.0
	check(painted, "every part wears the colour gene as the look paints: roughness 0.8, no metal")
	var box := box_of(creature)
	check(absf(box.position.y) < 0.001 and absf(box.get_center().x) < 0.001 and absf(box.get_center().z) < 0.001, "it stands on the ground at its own origin: lowest point %.3f m, %.2f m high" % [box.position.y, box.size.y])
	var radii := []
	for ball: MeshInstance3D in balls:
		radii.append(snappedf(ball.mesh.radius, 0.0001))
	# the limbs: how many, which way, how high
	var built := []
	for count: int in [0, 2, 4, 6, 12]:
		genes.mutate("limb_count", count)
		built.append(parts_of(creature))
	check(built == [3, 5, 7, 9, 15], "mutate() rebuilds the body at once, nobody calls build(): 0, 2, 4, 6 and 12 limbs give %s parts" % [built])
	genes.mutate("limb_count", 6)
	limbs = of_kind(creature, "CapsuleMesh")
	var hub: Vector3 = of_kind(creature, "SphereMesh")[0].position
	var even := true
	var lifts := []
	for i in limbs.size():
		var out: Vector3 = (limbs[i] as Node3D).basis.y
		var turn := fposmod(atan2(-out.z, out.x), TAU)
		even = even and absf(angle_difference(turn, TAU * i / 6.0)) < 0.001 and near((limbs[i] as Node3D).position, hub + out * 0.4, 0.001)
		lifts.append(snappedf(rad_to_deg(asin(out.y)), 0.1))
	check(even and lifts == [25.0, 25.0, 25.0, 25.0, 25.0, 25.0], "six limbs stand evenly around the lowest ball, 60 degrees apart, each raised %s degrees, its middle 0.4 m from the ball's" % [lifts[0]])
	var tips := []
	for angle: float in [0.0, 25.0, 60.0]:
		genes.mutate("limb_angle", angle)
		var limb: Node3D = of_kind(creature, "CapsuleMesh")[0]
		tips.append(snappedf((limb.position + limb.basis.y * 0.25).y, 0.001))
	check(tips[0] < tips[1] and tips[1] < tips[2] and is_equal_approx(tips[0], snappedf(hub.y, 0.001)), "limb_angle raises the limbs: the first limb's tip is %s m high at 0, 25 and 60 degrees" % [tips])
	genes.mutate("limb_angle", 0.0)
	genes.mutate("limb_count", 12)
	var widest := box_of(creature)
	check(widest.size.x <= 1.6 and widest.size.z <= 1.6, "at its widest, 12 limbs lying flat, it is %.2f m wide and %.2f m deep: inside the 1.6 m of a place" % [widest.size.x, widest.size.z])
	genes.mutate("limb_angle", 25.0)
	# the seed
	var twin := creature_in(base, Genes.new(), Vector3(2.0, 0.0, 0.0))
	var stranger_genes := Genes.new()
	stranger_genes.body_seed = 2
	var stranger := creature_in(base, stranger_genes, Vector3(-2.0, 0.0, 0.0))
	await frames(2)
	var twin_radii := []
	var stranger_radii := []
	for ball: MeshInstance3D in of_kind(twin, "SphereMesh"):
		twin_radii.append(snappedf(ball.mesh.radius, 0.0001))
	for ball: MeshInstance3D in of_kind(stranger, "SphereMesh"):
		stranger_radii.append(snappedf(ball.mesh.radius, 0.0001))
	check(twin_radii == radii and stranger_radii != radii, "body_seed 1 gives the same three balls every time, %s m; body_seed 2 gives others, %s m" % [radii, stranger_radii])
	var heights := []
	for count: int in [1, 5]:
		genes.mutate("segments", count)
		heights.append(snappedf(box_of(creature).size.y, 0.01))
		check(of_kind(creature, "SphereMesh").size() == count, "segments %d builds %d ball(s): the body is %.2f m high" % [count, count, heights[-1]])
	genes.mutate("segments", 3)
	var before := errors.size() + warnings.size() + printed.size()
	genes.mutate("limb_count", -3)
	check(parts_of(creature) == 3 and errors.size() + warnings.size() + printed.size() == before, "a genome that asks for -3 limbs gets a body with none, and Godot says nothing")
	measured["body"] = {"ball_radii_seed_1_m": radii, "ball_radii_seed_2_m": stranger_radii, "height_m": snappedf(box.size.y, 0.001), "first_limb_tip_height_at_0_25_60_degrees_m": tips,
		"widest_m": [snappedf(widest.size.x, 0.001), snappedf(widest.size.z, 0.001)], "height_at_1_and_5_segments_m": heights}
	await close(base)

func files() -> void:
	var genes := Genes.new()
	genes.limb_count = 6
	var error := ResourceSaver.save(genes, TRIAL)
	check(error == OK and FileAccess.file_exists(TRIAL) and genes.resource_path == "", "ResourceSaver.save() returns OK and the file is there; the genome we hold does not take the file's path")
	var text := text_of(TRIAL)
	var lines := text.strip_edges().split("\n")
	check(lines.size() == 7 and lines[0] == "[gd_resource type=\"Resource\" format=3]" and lines[2].begins_with(SCRIPT_LINE) and lines[4] == "[resource]" and lines[5].begins_with("script = ExtResource(") and lines[6] == "limb_count = 6",
		"the file is seven lines of text: it names its script by path, res://guests/genome/genes.gd, and holds `limb_count = 6`")
	check(not text.contains("segments") and not text.contains("limb_angle") and not text.contains("colour") and not text.contains("body_seed"),
		"it holds no line for the four genes that still have the script's default value")
	ResourceSaver.save(Genes.new(), TRIAL)
	var plain := text_of(TRIAL)
	check(plain.strip_edges().split("\n").size() == 6 and not plain.contains(" = 3") and not plain.contains("limb"), "a genome with every gene at its default is saved as six lines with no gene in them")
	ResourceSaver.save(genes, TRIAL)
	var back: Resource = load(TRIAL)
	check(back is Genes and back != genes and back.limb_count == 6 and back.segments == 3 and is_equal_approx(back.limb_angle, 25.0) and back.body_seed == 1 and back.colour.is_equal_approx(Look.BODY),
		"load() gives a genome back, another object with the same five genes: %d limbs" % back.limb_count)
	var again: Resource = load(TRIAL)
	check(again == back, "load() of the same path a second time hands out the SAME object, not a second one")
	var other := Genes.new()
	other.limb_count = 12
	ResourceSaver.save(other, TRIAL)
	var stale: Resource = load(TRIAL)
	var read: Resource = fresh(TRIAL)
	check(stale == back and stale.limb_count == 6 and read.limb_count == 12, "after another genome is saved to that path, load() still hands out the remembered one (%d limbs) while it is in use; read past the loader's memory, the file says %d" % [stale.limb_count, read.limb_count])
	measured["files"] = {"genome_file_text": text, "default_genome_file_text": plain, "load_after_a_second_save_says_limbs": stale.limb_count, "the_file_says_limbs": read.limb_count}
	# what a file owes its script
	var before := errors.size() + warnings.size()
	write(TRIAL, file_text("res://guests/genome/genes.gd", "limb_count = 6\nwings = 2\n"))
	var winged := fresh(TRIAL)
	check(winged is Genes and winged.limb_count == 6 and winged.get("wings") == null and errors.size() + warnings.size() == before, "a file with a gene the script does not name, `wings = 2`, loads without it and Godot says nothing")
	write(TRIAL, file_text("res://guests/genome/genes.gd", "limb_count = \"six\"\n"))
	var worded := fresh(TRIAL)
	write(TRIAL, file_text("res://guests/genome/genes.gd", "limb_count = 3.5\n"))
	var halved := fresh(TRIAL)
	check(worded.limb_count == 0 and halved.limb_count == 3 and errors.size() + warnings.size() == before, "`limb_count = \"six\"` in a file loads as %d and `limb_count = 3.5` as %d, in silence" % [worded.limb_count, halved.limb_count])
	write(TRIAL, file_text("res://genes.gd", "limb_count = 6\n"))
	var lost := fresh(TRIAL)
	var said := errors.slice(before)
	var named_it := false
	for line: String in said:
		named_it = named_it or line.contains("referenced non-existent resource at: res://genes.gd")
	check(lost == null and named_it, "a file that names a script which is not at that path does not load: null, and Godot names the path (%d error lines)" % said.size())
	measured["files"]["a_file_whose_script_is_not_there"] = said
	before = errors.size()
	var none: Resource = load("user://verify_no_such_file.tres")
	said = errors.slice(before)
	check(none == null and said.size() == 2 and said[0] == "ERROR: Cannot open file 'user://verify_no_such_file.tres'.", "load() of a file that is not there gives null and two error lines; the first: %s" % [said[0] if said.size() > 0 else ""])
	var careless := GDScript.new()
	careless.source_code = "extends RefCounted
const Genes := preload(\"res://guests/genome/genes.gd\")
func recall() -> Genes:
	var genes: Genes = load(\"user://verify_no_such_file.tres\")
	print(\"recalled \", genes.limb_count, \" limbs\")
	return genes
"
	careless.reload()
	before = errors.size()
	careless.new().recall()
	said = errors.slice(before)
	check(said.size() == 3 and said[2].begins_with("SCRIPT ERROR: Invalid access to property or key 'limb_count' on a base object of type 'null instance'."), "a recall() that does not ask exists() first, with no file: the two lines above, and then the script stops: %s" % [said[2] if said.size() > 2 else ""])
	measured["files"]["recall_without_exists"] = said
	write("user://verify_genes_alt.gd", text_of(GUEST + "genes.gd").replace("limb_count: int = 4", "limb_count: int = 8"))
	write(TRIAL, file_text("res://guests/genome/genes.gd", ""))
	var under_ours := fresh(TRIAL)
	write(TRIAL, file_text("user://verify_genes_alt.gd", ""))
	var under_other := fresh(TRIAL)
	check(under_ours.limb_count == 4 and under_other != null and under_other.limb_count == 8, "a file with no gene in it has %d limbs under our script and %d under a copy of the script whose default is 8: the default is not in the file" % [under_ours.limb_count, under_other.limb_count if under_other != null else -1])
	remove("user://verify_genes_alt.gd")
	before = errors.size() + warnings.size()
	var refused := ResourceSaver.save(Genes.new(), "user://verify_trial.txt")
	check(refused == ERR_FILE_UNRECOGNIZED and not FileAccess.file_exists("user://verify_trial.txt") and errors.size() + warnings.size() == before, "save() under a name ending in .txt returns %d (%s), writes nothing and logs nothing: only the returned number says so" % [refused, error_string(refused)])
	remove(TRIAL)

func sharing() -> void:
	var base := await world()
	var sheet: Node3D = Node3D.new()
	sheet.set_script(load("res://supplied/sweep_sheet.gd"))
	base.add_child(sheet)
	var before := errors.size() + warnings.size() + printed.size()
	var parent := Genes.new()
	var row := []
	for value: int in [0, 2, 4, 6, 12]:
		parent.mutate("limb_count", value)
		var creature: Node3D = Creature.instantiate()
		creature.genes = parent
		sheet.hang(creature, str(parent.get("limb_count")))
		row.append(creature)
	await frames(2)
	var plates := []
	var read := []
	for i in row.size():
		plates.append(sheet.plates[i].text)
		read.append(row[i].genes.limb_count)
	var silent := errors.size() + warnings.size() + printed.size() == before
	check(plates == ["0", "2", "4", "6", "12"] and counts(row) == [15, 15, 15, 15, 15] and read == [12, 12, 12, 12, 12] and row[0].genes == row[4].genes,
		"the planted fault: five bodies handed ONE genome stand under the plates %s, each built of %s parts, each reading %s limbs" % [plates, counts(row), read])
	check(silent, "and Godot says nothing about it: no error, no warning, no line")
	for creature: Node3D in row:
		creature.free()
	row.clear()
	parent = Genes.new()
	for value: int in [0, 2, 4, 6, 12]:
		var copy: Resource = parent.duplicate(true)
		copy.mutate("limb_count", value)
		var creature: Node3D = Creature.instantiate()
		creature.genes = copy
		sheet.hang(creature, str(copy.get("limb_count")))
		row.append(creature)
	await frames(2)
	check(counts(row) == [3, 5, 7, 9, 15] and row[0].genes != row[4].genes and parent.limb_count == 4, "the repair: each body gets parent.duplicate(true), and the five are built of %s parts; the parent still has %d limbs" % [counts(row), parent.limb_count])
	var shallow: Resource = parent.duplicate()
	shallow.limb_count = 9
	var holder := Holder.new()
	holder.inner = StandardMaterial3D.new()
	holder.list = [1, 2, 3]
	var plain: Holder = holder.duplicate()
	var deep: Holder = holder.duplicate(true)
	check(parent.limb_count == 4 and plain.inner == holder.inner and is_same(plain.list, holder.list) and deep.inner != holder.inner and not is_same(deep.list, holder.list),
		"duplicate() is enough for five plain genes; for a resource that holds a resource and a list, duplicate() leaves both shared and duplicate(true) copies both")
	var one: Shape3D = row[0].get_node("Trunk/Shape").shape
	var five: Shape3D = row[4].get_node("Trunk/Shape").shape
	one.height = 2.0
	var read_on_the_fifth: float = five.height
	one.height = 0.8
	check(one == five and is_equal_approx(read_on_the_fifth, 2.0), "the same sharing, in the scene file: the five creatures have ONE collision shape; set to 2 m on the first it reads %.1f m on the fifth" % read_on_the_fifth)
	measured["sharing"] = {"plates": plates, "parts_with_one_genome": [15, 15, 15, 15, 15], "parts_with_five_copies": counts(row)}
	await close(base)

func cabinet() -> void:
	var had := FileAccess.file_exists(FILE)
	if had:
		remove(ASIDE)
		DirAccess.rename_absolute(ProjectSettings.globalize_path(FILE), ProjectSettings.globalize_path(ASIDE))
	# the first run: no file
	var before := errors.size()
	var lines := printed.size()
	var scene: Node3D = load("res://cabinet.tscn").instantiate()
	root.add_child(scene)
	await frames(180)
	var said := printed.slice(lines)
	check(errors.size() == before, "cabinet.tscn runs 180 frames with no file to recall and Godot logs no error: %s" % [errors.slice(before)])
	check(said == ["no file yet: a new genome", "limb_count 0: 3 parts", "limb_count 2: 5 parts", "limb_count 4: 7 parts", "limb_count 6: 9 parts", "limb_count 12: 15 parts"], "it prints what it found and what it built: %s" % [said])
	var row: Array = scene.row
	var plates := []
	var apart := true
	var own := true
	for i in row.size():
		plates.append(scene.get_node("Sheet").plates[i].text)
		apart = apart and near(row[i].global_position, Vector3(-2.4 + 1.2 * i, 0.0, -1.5), 0.001)
		own = own and row[i].genes != scene.kept.genes
		for j in i:
			own = own and row[i].genes != row[j].genes
	check(row.size() == 5 and plates == ["0", "2", "4", "6", "12"] and counts(row) == [3, 5, 7, 9, 15] and apart, "five creatures stand on the sheet 1.2 m apart, under the plates %s" % [plates])
	check(own, "each of the five has a genome of its own, and none has the specimen's")
	check(parts_of(scene.kept) == 7 and near(scene.kept.global_position, scene.get_node("Place").global_position, 0.001) and scene.get_node("Place").material_override.albedo_color.is_equal_approx(Look.SHADE),
		"the specimen stands on the place, a square in SHADE: with no file it is the new genome, 4 limbs")
	check(scene.axis == "limb_count" and scene.values == [0, 2, 4, 6, 12], "the cabinet's axis is limb_count and its values 0, 2, 4, 6, 12, both exported")
	# keep one: the walker and the key
	var walker: CharacterBody3D = scene.get_node("Walker")
	var how := await walk(walker, [Vector3(1.2, 0.0, -0.3)])
	check(how == "arrived", "the walker walks to the front of the creature with six limbs: \"%s\"" % how)
	lines = printed.size()
	await press("pause")
	await frames(2)
	said = printed.slice(lines)
	check(said.size() == 1 and said[0].begins_with("kept 6 limbs in ") and said[0].ends_with("specimen.tres: OK"), "Space keeps the nearest: %s" % [said])
	check(parts_of(scene.kept) == 9 and text_of(FILE).contains("limb_count = 6"), "the specimen on the place now has six limbs, and the file says `limb_count = 6`")
	row[3].genes.mutate("limb_count", 3)
	check(parts_of(row[3]) == 6 and parts_of(scene.kept) == 9 and scene.kept.genes != row[3].genes, "the specimen is a copy: the creature it came from is changed to three limbs and the specimen keeps its six")
	row[3].genes.mutate("limb_count", 6)
	# the place: a body meets the made body
	var place: Vector3 = scene.get_node("Place").global_position
	walker.stand_at(Vector3(place.x, 0.0, place.z - 1.4))
	await physics_frames(10)
	how = await walk(walker, [Vector3(place.x, 0.0, place.z)])
	var gap := flat(walker.global_position - place).length()
	check(how == "blocked" and gap > 0.45 and gap < 0.6, "walked at the specimen, the walker is stopped by its trunk: \"%s\", %.2f m from its middle" % [how, gap])
	walker.stand_at(Vector3(place.x + 0.58, 0.0, place.z - 1.4))
	await physics_frames(10)
	how = await walk(walker, [Vector3(place.x + 0.58, 0.0, place.z + 1.2)])
	check(how == "arrived", "walked past the trunk and through a limb, it is not stopped: \"%s\"; a limb is a mesh with no collider" % how)
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	marble.position = Vector3(3.6, 0.1, 2.2)
	scene.add_child(marble)
	await frames(2)
	marble.drop(place + Vector3(0.0, 2.0, 0.0))
	var on_trunk := await settle(marble)
	marble.drop(place + Vector3(0.45, 2.0, 0.0))
	var through_limb := await settle(marble)
	check(absf(on_trunk.y - 0.9) < 0.01 and absf(through_limb.y - 0.1) < 0.01, "a marble dropped over the trunk rests at %.2f m, on the collider's flat top; dropped over a limb it falls through to the floor, %.2f m" % [on_trunk.y, through_limb.y])
	measured["place"] = {"walker_at_the_specimen": "blocked", "metres_from_its_middle": snappedf(gap, 0.01), "walker_through_a_limb": how, "marble_over_the_trunk_m": snappedf(on_trunk.y, 0.001), "marble_over_a_limb_m": snappedf(through_limb.y, 0.001)}
	var gaps := []
	var tops := []
	var rests := []
	for count: int in [1, 5]:
		scene.kept.genes.mutate("segments", count)
		tops.append(snappedf(box_of(scene.kept).size.y, 0.01))
		walker.stand_at(Vector3(place.x, 0.0, place.z - 1.4))
		await physics_frames(10)
		how = await walk(walker, [Vector3(place.x, 0.0, place.z)])
		gaps.append(snappedf(flat(walker.global_position - place).length(), 0.01))
		walker.stand_at(Vector3(place.x, 0.0, place.z - 1.4))
		marble.drop(place + Vector3(0.0, 2.0, 0.0))
		rests.append(snappedf((await settle(marble)).y, 0.01))
	scene.kept.genes.mutate("segments", 3)
	check(gaps[0] == gaps[1] and rests == [0.9, 0.9] and tops[0] < 0.8 and tops[1] > 0.8, "no gene touches the trunk's cylinder: a specimen of one ball, %s m high, and one of five, %s m, stop the walker %s m from the middle, and the marble rests at %s m over both" % [tops[0], tops[1], gaps[0], rests[0]])
	measured["place"]["one_ball_and_five_balls"] = {"high_m": tops, "walker_stopped_at_m": gaps, "marble_rests_at_m": rests, "marble_above_the_top_of_the_one_ball_m": snappedf(rests[0] - tops[0], 0.01)}
	# the family as files
	var family_lines := []
	for creature: Node3D in row:
		var path := "user://verify_family_%d.tres" % creature.genes.limb_count
		ResourceSaver.save(creature.genes, path)
		family_lines.append(text_of(path).strip_edges().split("
").size())
		remove(path)
	check(family_lines == [7, 7, 6, 7, 7], "the row saved as five files: %s lines; the child with 4 limbs, the default, is the one with no gene line" % [family_lines])
	measured["family_files_lines"] = family_lines
	await close(scene)
	# a restart: another Godot reads the file
	var output := []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--xr-mode", "off", "--quit-after", "10"], output, true)
	var second := str(output[0]) if output.size() > 0 else ""
	check(code == 0 and second.contains("recalled 6 limbs") and not second.contains("no file yet") and second.contains("limb_count 12: 15 parts"), "after a restart the specimen comes back: a second Godot, started on this project, prints `recalled 6 limbs`")
	# and in this run: the room left and entered again
	before = errors.size()
	scene = load("res://cabinet.tscn").instantiate()
	root.add_child(scene)
	await frames(10)
	check(parts_of(scene.kept) == 9 and scene.kept.genes.limb_count == 6 and counts(scene.row) == [3, 5, 7, 9, 15] and errors.size() == before, "the cabinet built again finds the file: the specimen has six limbs and the row is bred from it")
	await close(scene)
	# a cabinet on another gene
	scene = load("res://cabinet.tscn").instantiate()
	scene.axis = "limb_angle"
	scene.values = [0.0, 25.0, 50.0, 75.0]
	root.add_child(scene)
	await frames(10)
	var angles := []
	plates.clear()
	for i in scene.row.size():
		angles.append(scene.row[i].genes.limb_angle)
		plates.append(scene.get_node("Sheet").plates[i].text)
	check(angles == [0.0, 25.0, 50.0, 75.0] and counts(scene.row) == [9, 9, 9, 9] and plates == ["0.0", "25.0", "50.0", "75.0"], "with axis set to limb_angle and four values the row is four children of the six-limbed specimen, raised %s" % [plates])
	await close(scene)
	write(FILE, file_text("res://guests/genome/genes.gd", "segments = 5
limb_angle = 60.0
body_seed = 7
"))
	lines = printed.size()
	scene = load("res://cabinet.tscn").instantiate()
	root.add_child(scene)
	await frames(10)
	var balls := []
	for creature: Node3D in scene.row:
		balls.append(of_kind(creature, "SphereMesh").size())
	check(printed.slice(lines)[0] == "recalled 4 limbs" and balls == [5, 5, 5, 5, 5] and counts(scene.row) == [5, 7, 9, 11, 17] and is_equal_approx(scene.row[4].genes.limb_angle, 60.0) and scene.row[4].genes.body_seed == 7,
		"a classmate's file, written by hand (5 segments, limbs raised 60 degrees, body_seed 7): `%s`, and the row is five children of it, each of %s balls" % [printed.slice(lines)[0], balls[0]])
	await close(scene)
	measured["restart"] = {"second_process_exit_code": code, "second_process_printed": second.strip_edges().split("\n")[-6].strip_edges() if second.contains("recalled") else second}
	remove(FILE)
	if had:
		DirAccess.rename_absolute(ProjectSettings.globalize_path(ASIDE), ProjectSettings.globalize_path(FILE))
	check(FileAccess.file_exists(FILE) == had, "the file the cabinet had before these checks is back in its place (or there was none)")

func guest() -> void:
	var needs := CheckGuest.outside(GUEST)
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names(GUEST).is_empty(), "the guest declares no class_name")
	var files := []
	for file in DirAccess.get_files_at(GUEST):
		if not file.ends_with(".uid"):
			files.append(file)
	check(files == ["creature.gd", "genes.gd", "genome.tscn", "specimen.tres"], "the guest's folder holds four files: %s" % [files])
	var text := text_of(GUEST + "specimen.tres")
	check(text.contains(SCRIPT_LINE) and text.count("res://") == 1, "its specimen.tres names one path, the genes script in the same folder")
	var base := await world()
	var before := errors.size()
	var guest: Node3D = Creature.instantiate()
	guest.position = Vector3(1.0, 0.0, 0.0)
	base.add_child(guest)
	await frames(180)
	var written: Resource = fresh(GUEST + "specimen.tres")
	check(errors.size() == before and guest.genes.limb_count == written.limb_count and parts_of(guest) == written.segments + written.limb_count,
		"standing alone, handed no genes, the guest recalls the specimen in its own folder: %d limbs, %d parts, 180 frames with no error" % [guest.genes.limb_count, parts_of(guest)])
	var box := box_of(guest)
	check(absf(box.position.y) < 0.001 and box.size.x <= 1.6 and box.size.z <= 1.6 and absf(box.get_center().x - 1.0) < 0.35, "it stands on the ground over its origin and fits a place: %.2f m wide, %.2f m deep, %.2f m high" % [box.size.x, box.size.z, box.size.y])
	measured["guest"] = {"limbs": guest.genes.limb_count, "parts": parts_of(guest), "wide_m": snappedf(box.size.x, 0.01), "deep_m": snappedf(box.size.z, 0.01), "high_m": snappedf(box.size.y, 0.01)}
	await close(base)
