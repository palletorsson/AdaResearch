extends "res://supplied/verify_tools.gd"
## Headless checks of the kit "The family in the editor". From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; the exit code is the number of
## checks that failed. No import step is needed: nothing here has a class_name.
## One part of it starts a second Godot: the editor, without a window, on a
## copy of the project in .editor_check/, to see what @tool does there. The
## copy is removed when the check is done.
## Headless draws no frames, so what the eye gets is measured by sheet.gd.

const Look := preload("res://supplied/look.gd")
const CheckGuest := preload("res://supplied/check_guest.gd")
const AdaPyramid := preload("res://borrowed/ada_pyramid.gd")
const SPIRE := "res://guests/family-editor/spire.gd"
const SPIRE_SCENE := "res://guests/family-editor/family-editor.tscn"
const SCENE := "res://family_editor.tscn"
const GUEST := "res://guests/family-editor/"

## The declaration of `lean` as the lesson ends with it, and the three earlier
## states of it that the lesson passes through.
const SETTER := "@export_range(0.0, 1.6, 0.05) var lean: float = 0.0:\n\tset(value):\n\t\tif value == lean:\n\t\t\treturn\n\t\tlean = value\n\t\tif is_node_ready():\n\t\t\trebuild()\n"
const PLAIN := "@export_range(0.0, 1.6, 0.05) var lean: float = 0.0\n"
const UNGUARDED := "@export_range(0.0, 1.6, 0.05) var lean: float = 0.0:\n\tset(value):\n\t\tlean = value\n\t\trebuild()\n"
const EVERY_TIME := "@export_range(0.0, 1.6, 0.05) var lean: float = 0.0:\n\tset(value):\n\t\tlean = value\n\t\tif is_node_ready():\n\t\t\trebuild()\n"

## What stands in for the Inspector's hand inside the editor: a tool script
## that, 30 frames after the scene is open, sets the spire's field.
const HAND := "@tool\nextends Node\n\nvar _frames := 0\n\nfunc _process(_delta: float) -> void:\n\tif not Engine.is_editor_hint():\n\t\treturn\n\t_frames += 1\n\tvar spire: Node3D = get_node(\"../Spire\")\n\tif _frames == 30:\n\t\tprint(\"hand before: children \", spire.get_child_count(), \" box \", _box(spire))\n\t\tspire.set(\"lean\", 0.5)\n\t\tprint(\"hand after: lean \", spire.get(\"lean\"), \" box \", _box(spire))\n\tif _frames == 40:\n\t\tprint(\"hand saved the scene: \", EditorInterface.save_scene() == OK)\n\nfunc _box(spire: Node3D) -> Vector3:\n\tfor child in spire.get_children():\n\t\tif child is MeshInstance3D:\n\t\t\treturn child.get_aabb().size\n\treturn Vector3.ZERO\n"

func world() -> Node3D:
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	await frames(2)
	return base

func close(node: Node) -> void:
	node.free()
	await frames(1)

func flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)

func write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func round3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]

## The spire's class with another declaration of `lean`: a state of the lesson.
func spire_with(declaration: String) -> Node3D:
	var script := GDScript.new()
	script.source_code = text_of(SPIRE).replace(SETTER, declaration)
	script.reload()
	var body := Node3D.new()
	body.set_script(script)
	return body

## What the eye gets of a spire: the mesh node its script made, or null.
func skin(body: Node) -> MeshInstance3D:
	for child in body.get_children():
		if child is MeshInstance3D:
			return child
	return null

## The box of a spire's body in its own frame; an empty box if it has none.
func box_of(body: Node) -> AABB:
	return skin(body).get_aabb() if skin(body) != null else AABB()

## Where the apex of a built pyramid of Ada's is: the highest corner of its mesh.
func built_apex(member: Node3D) -> Vector3:
	var top := Vector3.ZERO
	for corner: Vector3 in member.get_node("Pyramid").mesh.get_faces():
		if corner.y > top.y:
			top = corner
	return top

## The corners of a mesh, each once, in a fixed order.
func corners_of(mesh: Mesh) -> Array:
	var out := []
	for corner: Vector3 in mesh.get_faces():
		var rounded := corner.snappedf(0.0001)
		if not out.has(rounded):
			out.append(rounded)
	out.sort()
	return out

func run() -> void:
	project()
	await ada_pyramid()
	await spire()
	await lesson_states()
	await scene()
	await keys()
	await place()
	await guest()
	await editor()

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Family in the editor" and ProjectSettings.get_setting("application/run/main_scene") == SCENE
		and ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"the project is named Family in the editor, its main scene is family_editor.tscn, its renderer Compatibility")
	var supplied := []
	for file in DirAccess.get_files_at("res://supplied"):
		if not file.ends_with(".uid"):
			supplied.append(file)
	check(supplied == ["base.tscn", "base_look.gd", "check_guest.gd", "look.gd", "marble.gd", "marble.tscn", "mover.gd", "segment.gd", "sheet_tools.gd", "sweep_sheet.gd", "sweep_sheet.tscn", "trace_strip.gd", "verify_tools.gd", "walker.gd", "walker.tscn"], "supplied/ holds the base's 15 files: %s" % [supplied])
	var named := []
	var spaced := []
	for folder: String in ["res://", "res://supplied/", "res://borrowed/", GUEST]:
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".gd"):
				continue
			if RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text_of(folder + file)) != null:
				named.append(file)
			if RegEx.create_from_string("(?m)^ +\\S").search(text_of(folder + file)) != null:
				spaced.append(file)
	check(named.is_empty() and ProjectSettings.get_global_class_list().is_empty(), "no script declares a class_name and the project lists no named class, so nothing needs an import: %s" % [named])
	check(spaced.is_empty(), "every script is indented with tabs: %s" % [spaced])

## The borrowed part: Ada's pyramid, which builds once.
func ada_pyramid() -> void:
	var base := await world()
	var before := errors.size()
	var hint := ""
	for property: Dictionary in (AdaPyramid as Script).get_script_property_list():
		if property["name"] == "apex_stance":
			hint = property["hint_string"]
	check(hint == "centred,edge,corner,beyond", "Ada's pyramid offers its four stances to whoever reads its property list: \"%s\"" % hint)
	var values := hint.split(",")
	var wanted := {"centred": Vector2(0, 0), "edge": Vector2(0, -0.3), "corner": Vector2(-0.3, -0.3), "beyond": Vector2(-0.48, -0.48)}
	var apexes := {}
	var built_ok := true
	var off := []
	for value: String in values:
		var member := AdaPyramid.new()
		member.apex_stance = value
		base.add_child(member)
		var apex := built_apex(member)
		apexes[value] = Vector2(apex.x, apex.z)
		built_ok = built_ok and apexes[value].is_equal_approx(wanted[value]) and is_equal_approx(apex.y, 0.8) and member.get_node("Pyramid").mesh.get_faces().size() == 18
		if maxf(absf(apex.x), absf(apex.z)) > member.base_size / 2 + 0.001:
			off.append(value)
		if value == "edge":
			var written: Vector3 = member._apex_position(member._base_ring())
			measured["on_the_edge"] = {"half_the_base_as_a_float": "%.12f" % (member.base_size / 2), "apex_z_from_the_mesh": "%.12f" % absf(apex.z), "apex_z_from_adas_own_function": "%.12f" % absf(written.z),
				"mesh_reads_as_off_the_base_without_slack": absf(apex.z) > member.base_size / 2, "function_reads_as_off_the_base_without_slack": absf(written.z) > member.base_size / 2}
		member.free()
	check(built_ok, "set before add_child(), each stance builds its own body of six triangles, the apex 0.8 m up and in plan over (0, 0), (0, -0.3), (-0.3, -0.3) and (-0.48, -0.48): %s" % [apexes])
	var apart := {}
	var names := Array(values)
	var closest := ""
	for i in names.size():
		for j in range(i + 1, names.size()):
			var key := "%s vs %s" % [names[i], names[j]]
			apart[key] = snappedf((apexes[names[i]] - apexes[names[j]]).length(), 0.001)
			if closest == "" or apart[key] < apart[closest]:
				closest = key
	measured["apexes_apart_in_plan_m"] = apart
	check(closest == "corner vs beyond" and is_equal_approx(apart[closest], 0.255) and is_equal_approx(apart["centred vs edge"], 0.3) and is_equal_approx(apart["edge vs corner"], 0.3),
		"in plan the apexes of corner and beyond are the closest pair, %.3f m apart; centred to edge and edge to corner are 0.300 m: %s" % [apart[closest], apart])
	check(off == ["beyond"], "with a millimetre of slack only beyond has its apex off its base: %s" % [off])
	var edge: Dictionary = measured["on_the_edge"]
	check(not edge["mesh_reads_as_off_the_base_without_slack"] and edge["function_reads_as_off_the_base_without_slack"],
		"exactly on the edge a comparison cannot stand: half the base is %s as a float, the apex of edge comes back from the mesh as %s (inside) and from Ada's own function as %s (outside); hence the slack" % [edge["half_the_base_as_a_float"], edge["apex_z_from_the_mesh"], edge["apex_z_from_adas_own_function"]])
	# Set afterwards: the field changes and the body does not.
	var late := AdaPyramid.new()
	base.add_child(late)
	late.apex_stance = "beyond"
	await frames(2)
	var late_apex := built_apex(late)
	check(late.apex_stance == "beyond" and flat(late_apex).is_equal_approx(Vector2.ZERO) and errors.size() == before and warnings.is_empty(),
		"set to beyond AFTER add_child(), the field reads beyond and the apex is still built over (0, 0); Godot logged nothing: %s %s" % [errors.slice(before), warnings])
	late._rebuild_pyramid()
	check(flat(built_apex(late)).is_equal_approx(Vector2(-0.48, -0.48)), "its own _rebuild_pyramid(), called by hand, builds what the field says")
	late.free()
	# A word the match does not know.
	var silent := true
	var held := []
	for word: String in ["centre", "side", "past", "Beyond", "beyond "]:
		var member := AdaPyramid.new()
		member.apex_stance = word
		base.add_child(member)
		held.append(member.apex_stance)
		silent = silent and flat(built_apex(member)).is_equal_approx(Vector2.ZERO)
		member.free()
	check(silent and held == ["centre", "side", "past", "Beyond", "beyond "] and errors.size() == before,
		"five words its match does not know (centre, side, past, Beyond, and beyond with a space) each built the centred body; the field kept the word and Godot logged nothing")
	var misnamed := AdaPyramid.new()
	misnamed.set("apex_stanse", "corner")
	misnamed.set("apex_stance", 3)
	check(misnamed.apex_stance == "centred" and misnamed.get("apex_stanse") == null and errors.size() == before,
		"set() with a name the class does not have, and set() with the number 3 on this text field, change nothing and say nothing")
	misnamed.set_base_color(Look.SECOND)
	base.add_child(misnamed)
	check((misnamed.get_node("Pyramid").material_override as StandardMaterial3D).albedo_color.is_equal_approx(Look.SECOND), "set_base_color() before add_child() paints the body")
	await close(base)

## The learner's class, as shipped.
func spire() -> void:
	var source := text_of(SPIRE)
	check(source.begins_with("@tool\n") and source.contains(SETTER) and source.contains("Engine.is_editor_hint()"),
		"spire.gd begins with @tool, declares lean with a setter that rebuilds once the node is ready, and asks Engine.is_editor_hint()")
	var range_hint := ""
	for property: Dictionary in (load(SPIRE) as Script).get_script_property_list():
		if property["name"] == "lean":
			range_hint = property["hint_string"]
	check(range_hint == "0.0,1.6,0.05", "lean is exported with a range from 0 to 1.6 in steps of 0.05: \"%s\"" % range_hint)
	var base := await world()
	var before := errors.size()
	var body: Node3D = load(SPIRE_SCENE).instantiate()
	check(is_equal_approx(body.lean, 1.6) and body.get_child_count() == 0 and body.rebuilds == 0 and errors.size() == before,
		"the scene stores lean = 1.6: the setter ran before the node was ready, kept the value, built nothing and logged no error")
	base.add_child(body)
	await frames(2)
	var box := box_of(body)
	check(body.rebuilds == 1 and box.position.is_equal_approx(Vector3(-0.48, 0, -0.48)) and box.size.is_equal_approx(Vector3(0.78, 0.8, 0.78)) and errors.size() == before,
		"in the room it is built once, from the stored value: its box reaches from (-0.48, 0, -0.48), 0.78 m wide and deep, 0.8 m high")
	body.lean = 0.5
	check(body.rebuilds == 2 and box_of(body).size.is_equal_approx(Vector3(0.6, 0.8, 0.6)), "set to 0.5 while it stands, the body follows in the same line: built 2 times, the box 0.6 m wide")
	body.lean = 0.5
	check(body.rebuilds == 2, "set to 0.5 again, nothing is built: the setter returns when the value is the one it has")
	check(body.apex().is_equal_approx(Vector3(-0.15, 0.8, -0.15)) and body.over_base(), "its methods answer from the field: apex() is (-0.15, 0.8, -0.15), over_base() is true")
	body.lean = 1.0
	var at_one: bool = body.over_base()
	body.lean = 1.05
	check(at_one and not body.over_base(), "over_base() is true at lean 1.0 and false at 1.05")
	var paint := skin(body).material_override as StandardMaterial3D
	check(paint != null and paint.albedo_color.is_equal_approx(Look.BODY) and is_equal_approx(paint.roughness, 0.8), "it paints itself in BODY, written out as c6ff3d, roughness 0.8")
	var solid := body.find_children("*", "CollisionShape3D", true, false)
	check(solid.size() == 1 and solid[0].shape is ConvexPolygonShape3D and (solid[0].shape as ConvexPolygonShape3D).points.size() == 5 and solid[0].get_parent() is StaticBody3D,
		"it has one collider, a convex shape of its five corners under a StaticBody3D, made again at every rebuild")
	# The same body as Ada's at three of its four stances.
	var same := true
	for pair: Array in [[0.0, "centred"], [1.0, "corner"], [1.6, "beyond"]]:
		body.lean = pair[0]
		var ada := AdaPyramid.new()
		ada.apex_stance = pair[1]
		base.add_child(ada)
		same = same and corners_of(skin(body).mesh) == corners_of(ada.get_node("Pyramid").mesh)
		ada.free()
	check(same, "at lean 0, 1 and 1.6 the spire has the same five corners as Ada's pyramid at centred, corner and beyond; edge is not on the spire's line")
	var fastest := INF    # milliseconds for one rebuild, in the fastest of five rounds of 200
	for round in 5:
		var started := Time.get_ticks_usec()
		for i in 200:
			body.rebuild()
		fastest = minf(fastest, (Time.get_ticks_usec() - started) / 200000.0)
	measured["one_rebuild_ms"] = snappedf(fastest, 0.01)
	check(fastest < 5.0, "a rebuild, a mesh of six triangles and a collider, took %.2f ms on this machine (the fastest of five rounds of 200)" % fastest)
	# Set before it is in the room, as the sheet sets Ada's pyramid.
	var early: Node3D = load(SPIRE_SCENE).instantiate()
	early.lean = 0.25
	base.add_child(early)
	check(early.rebuilds == 1 and box_of(early).size.is_equal_approx(Vector3(0.6, 0.8, 0.6)) and errors.size() == before, "set before add_child(), the value is kept and the body is built once, when it enters the room; no error")
	await close(base)

## The states the lesson passes through, made from the shipped script.
func lesson_states() -> void:
	var base := await world()
	# A plain field.
	var plain := spire_with(PLAIN)
	plain.set("lean", 1.6)
	base.add_child(plain)
	var box_before := box_of(plain)
	plain.set("lean", 0.0)
	await frames(2)
	check(is_equal_approx(plain.get("lean"), 0.0) and (plain.call("apex") as Vector3).is_equal_approx(Vector3(0, 0.8, 0)) and box_of(plain) == box_before and box_before.size.is_equal_approx(Vector3(0.78, 0.8, 0.78)) and plain.get("rebuilds") == 1,
		"with lean a plain field, set to 0 while the spire stands: the field reads 0, apex() says (0, 0.8, 0), and the body still leans at 1.6, built 1 time")
	plain.call("rebuild")
	check(box_of(plain).size.is_equal_approx(Vector3(0.6, 0.8, 0.6)) and plain.get("rebuilds") == 2, "rebuild() called by hand makes the body follow")
	plain.free()
	# The planted bug: a setter that rebuilds whether or not the node is ready.
	var before := errors.size()
	var bug := spire_with(UNGUARDED)
	bug.set("lean", 1.6)
	var said := errors.slice(before)
	measured["planted_bug_says"] = said
	check(said.size() == 1 and said[0].contains("Invalid assignment of property or key 'mesh' with value of type 'ArrayMesh' on a base object of type 'Nil'."),
		"the planted bug: with the setter's is_node_ready() taken out, a value set before the node is in the room logs one script error: %s" % [said])
	base.add_child(bug)
	await frames(2)
	bug.set("lean", 0.5)
	check(errors.size() == before + 1 and bug.get("rebuilds") == 2 and box_of(bug).size.is_equal_approx(Vector3(0.6, 0.8, 0.6)),
		"after that one error the same spire stands and follows its field: one red line, and a picture that looks right")
	bug.free()
	# A setter that rebuilds every time it is handed a value.
	var eager := spire_with(EVERY_TIME)
	base.add_child(eager)
	for i in 180:
		eager.set("lean", 1.0)
	var patient: Node3D = load(SPIRE_SCENE).instantiate()
	base.add_child(patient)
	for i in 180:
		patient.lean = 1.0
	measured["rebuilds_for_180_equal_values"] = {"without_the_equal_value_guard": eager.get("rebuilds") - 1, "with_it": patient.rebuilds - 1}
	check(eager.get("rebuilds") == 181 and patient.rebuilds == 2, "handed the same value 180 times, the setter without `if value == lean` builds 180 times; the shipped one once")
	await close(base)

## The chapter's scene.
func scene() -> void:
	var before := errors.size()
	var lines := printed.size()
	var room: Node3D = load(SCENE).instantiate()
	root.add_child(room)
	await physics_frames(3)
	await frames(2)
	var body: Node3D = room.get_node("Spire")
	var rail: Node3D = room.get_node("Rail")
	var walker: CharacterBody3D = room.get_node("Walker")
	var wall: Node3D = room.get_node("Wall")
	var said := printed.slice(lines)
	check(said == ["centred asked: apex built over (0.0, 0.0)", "edge asked: apex built over (0.0, -0.3)", "corner asked: apex built over (-0.3, -0.3)", "beyond asked: apex built over (-0.48, -0.48)"],
		"the scene prints what was asked beside what was built, four lines: %s" % [said])
	var members := []
	var plates := []
	for child in wall.get_children():
		if child is Label3D:
			plates.append(child.text)
		else:
			members.append(child)
	var row_ok := members.size() == 4
	var colours_ok := members.size() == 4
	var apexes := []
	var wanted := [Vector2(0, 0), Vector2(0, -0.3), Vector2(-0.3, -0.3), Vector2(-0.48, -0.48)]
	for i in members.size():
		row_ok = row_ok and members[i].position.is_equal_approx(Vector3(i * 1.2, 0, 0)) and flat(built_apex(members[i])).is_equal_approx(wanted[i])
		colours_ok = colours_ok and (members[i].get_node("Pyramid").material_override as StandardMaterial3D).albedo_color.is_equal_approx(Look.BODIES[i])
		apexes.append(flat(built_apex(members[i])))
	check(row_ok,
		"our own sheet stands four members of Ada's pyramid 1.2 m apart, and each is built as its stance says: %s" % [apexes])
	check(colours_ok, "the four take BODIES in order: BODY, SECOND, THIRD, BONE")
	check(plates == ["centred", "edge", "corner", "beyond\noff its base"], "four plates name the stances, and the fourth says it is off its base: %s" % [plates])
	check(room.values_of(AdaPyramid, "apex_stance") == PackedStringArray(["centred", "edge", "corner", "beyond"]) and room.values_of(AdaPyramid, "base_sides") == PackedStringArray([""]) and room.values_of(AdaPyramid, "nothing").is_empty(),
		"values_of() reads the four stances from the class; for base_sides, a plain int, it returns one empty text, and for a name the class does not have nothing")
	check(rail.held and is_equal_approx(rail.value, 1.6) and is_equal_approx(body.lean, 1.6) and body.rebuilds == 1,
		"at the start the walker stands on the rail's high end: held, value 1.6, lean 1.6, built 1 time")
	await frames(180)
	check(body.rebuilds == 1 and room.get_node("Readout").text == "lean 1.60    over its base: false    built 1 times",
		"180 frames standing there, and the spire is not built again; the readout says: %s" % room.get_node("Readout").text)
	check(errors.size() == before and warnings.is_empty(), "the scene ran those frames with no error and no warning: %s %s" % [errors.slice(before), warnings])
	var how := await walk(walker, [Vector3(1.9, 0, -0.5)])
	measured["rebuilds_walking_the_rail"] = body.rebuilds - 1
	check(how == "arrived" and rail.held and is_equal_approx(body.lean, 0.0) and body.over_base() and box_of(body).size.is_equal_approx(Vector3(0.6, 0.8, 0.6)),
		"walked to the rail's low end (\"%s\"), the spire stands upright: lean 0, the box 0.6 m wide; it was built %d times on the way, once for each step of the walk that changed the value" % [how, body.rebuilds - 1])
	how = await walk(walker, [Vector3(2.8, 0, -0.5)])
	check(not rail.held and is_equal_approx(rail.value, 0.0) and is_equal_approx(body.lean, 0.0), "stepped off the rail, it is no longer held and keeps its value: lean stays 0")
	how = await walk(walker, [Vector3(2.8, 0, 0.53), Vector3(1.9, 0, 0.53)])
	check(rail.held and is_equal_approx(rail.value, body.lean) and absf(body.lean - 0.73) < 0.1, "stepped on again 0.73 m along, the spire takes the value there: lean %.2f, a value between the Inspector's steps of 0.05" % body.lean)
	measured["lean_half_way_along_the_rail"] = snappedf(body.lean, 0.0001)
	await close(room)

## The keys the lesson names, pressed as actions of the Input Map.
func keys() -> void:
	var before := errors.size()
	var room: Node3D = load(SCENE).instantiate()
	root.add_child(room)
	await physics_frames(3)
	await frames(2)
	var body: Node3D = room.get_node("Spire")
	var rail: Node3D = room.get_node("Rail")
	var walker: CharacterBody3D = room.get_node("Walker")
	var start := walker.global_position
	await hold("move_forward", 30)
	var went := start.z - walker.global_position.z
	var lean_forward: float = body.lean
	var wide_forward := box_of(body).size.x
	check(went > 0.5 and rail.held and lean_forward < 1.0 and is_equal_approx(wide_forward, 0.6),
		"W held for 30 steps walks the walker %.2f m along the rail, away from the camera, and the spire straightens: lean %.2f, and the body as built is %.2f m wide, its apex back over its base" % [went, lean_forward, wide_forward])
	await hold("move_backward", 30)
	var lean_back: float = body.lean
	var wide_back := box_of(body).size.x
	check(rail.held and is_equal_approx(lean_back, 1.6) and is_equal_approx(wide_back, 0.78), "S held for 30 steps brings it back: lean %.2f, the body %.2f m wide again" % [lean_back, wide_back])
	await hold("move_right", 30)
	var beside := absf(walker.global_position.x - start.x)
	check(not rail.held and beside > 0.5 and is_equal_approx(body.lean, lean_back) and errors.size() == before,
		"D held for 30 steps steps off the rail, %.2f m beside it: it is no longer held, lean stays %.2f, and Godot logged no error" % [beside, body.lean])
	measured["keys"] = {"W_30_steps_m": snappedf(went, 0.01), "lean_after_W": snappedf(lean_forward, 0.01), "body_wide_after_W_m": snappedf(wide_forward, 0.01), "lean_after_S": snappedf(lean_back, 0.01), "body_wide_after_S_m": snappedf(wide_back, 0.01), "D_30_steps_m_beside_the_rail": snappedf(beside, 0.01)}
	await close(room)

## A body meets the made body: the walker walks at the spire.
func place() -> void:
	var room: Node3D = load(SCENE).instantiate()
	var walker: CharacterBody3D = room.get_node("Walker")
	walker.position = Vector3(3.2, 0, -1.6)    # off the rail, before the scene starts
	root.add_child(room)
	await frames(2)
	var body: Node3D = room.get_node("Spire")
	var middle := body.global_position
	var lean_side := Vector3(-1, 0, -1).normalized()   # the way the apex walks
	var met := {}
	for lean: float in [0.0, 1.0, 1.6]:
		for side: String in ["the side it leans to", "the far side"]:
			walker.stand_at(middle + lean_side * (1.5 if side == "the side it leans to" else -1.5))
			await physics_frames(5)
			body.lean = lean
			var how := await walk(walker, [middle])
			var at := walker.global_position
			met["lean %.1f, from %s" % [lean, side]] = {"walk_ended": how, "m_from_the_middle": snappedf(flat(at - middle).length(), 0.01), "feet_at_m": snappedf(at.y, 0.01)}
	measured["walker_meets_spire"] = met
	var upright_a: Dictionary = met["lean 0.0, from the side it leans to"]
	var upright_b: Dictionary = met["lean 0.0, from the far side"]
	check(upright_a["walk_ended"] == "blocked" and upright_b["walk_ended"] == "blocked" and is_equal_approx(upright_a["m_from_the_middle"], upright_b["m_from_the_middle"]) and upright_a["feet_at_m"] == 0.0,
		"at lean 0 the spire stops the walker from both sides, %.2f m from its middle, feet on the floor" % upright_a["m_from_the_middle"])
	var corner_a: Dictionary = met["lean 1.0, from the side it leans to"]
	var corner_b: Dictionary = met["lean 1.0, from the far side"]
	check(corner_a["walk_ended"] == "blocked" and corner_b["walk_ended"] == "arrived" and corner_b["feet_at_m"] > 0.3,
		"at lean 1 it stops the walker on the side it leans to, %.2f m out, and from the far side the walker walks up it: arrived, its feet at %.2f m" % [corner_a["m_from_the_middle"], corner_b["feet_at_m"]])
	var beyond_a: Dictionary = met["lean 1.6, from the side it leans to"]
	var beyond_b: Dictionary = met["lean 1.6, from the far side"]
	check(beyond_a["walk_ended"] == "blocked" and beyond_a["m_from_the_middle"] > 0.85 and beyond_b["walk_ended"] == "arrived" and beyond_b["feet_at_m"] > 0.2,
		"at lean 1.6 the walker is stopped %.2f m from the middle, over floor the base does not cover (its corner is 0.42 m out), and from the far side walks up it: its feet at %.2f m" % [beyond_a["m_from_the_middle"], beyond_b["feet_at_m"]])
	# Where does the wall become a ramp?
	var first_climbed := -1.0
	var tried := {}
	for step in range(5, 11):
		var lean := step * 0.1
		walker.stand_at(middle - lean_side * 1.5)
		await physics_frames(5)
		body.lean = lean
		var how := await walk(walker, [middle])
		tried["%.1f" % lean] = how
		if how == "arrived" and first_climbed < 0.0:
			first_climbed = lean
	measured["from_the_far_side_by_lean"] = tried
	measured["first_lean_the_walker_climbs"] = snappedf(first_climbed, 0.1)
	check(first_climbed > 0.0 and first_climbed <= 1.0, "from the far side, lean by lean in steps of 0.1 from 0.5, the walker first walks up the spire at lean %.1f: %s" % [first_climbed, tried])
	# A member of the wall is for the eye only.
	var member: Node3D
	for child in room.get_node("Wall").get_children():
		if not child is Label3D and member == null:
			member = child
	walker.stand_at(member.global_position + Vector3(0, 0, 1.2))
	await physics_frames(5)
	var through := await walk(walker, [member.global_position])
	check(through == "arrived" and walker.global_position.y < 0.01, "a member of the wall has no collider: the walker walks into it and stands at its middle, feet on the floor (\"%s\")" % through)
	await close(room)

## The body handed to the room.
func guest() -> void:
	var needs := CheckGuest.outside(GUEST)
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names(GUEST).is_empty(), "the guest declares no class_name")
	var before := errors.size()
	var body: Node = load(SPIRE_SCENE).instantiate()
	root.add_child(body)
	await frames(3)
	var box := box_of(body)
	check(body is Node3D and is_zero_approx(box.position.y) and box.position.x >= -0.8 and box.position.z >= -0.8 and box.end.x <= 0.8 and box.end.z <= 0.8 and errors.size() == before,
		"alone, with no base and no look, the guest loads without an error, stands on the ground at its own origin and fits the place of 1.6 m: its box reaches from %s to %s" % [round3(box.position), round3(box.end)])
	await close(body)

## What @tool does: the editor, without a window, on a copy of the project.
func editor() -> void:
	var copy := "res://.editor_check"
	remove(copy)
	for folder: String in ["", "supplied/", "borrowed/", "guests/", "guests/family-editor/"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(copy + "/" + folder))
		for file in DirAccess.get_files_at("res://" + folder):
			if file.get_extension() in ["gd", "tscn", "godot"]:
				write(copy + "/" + folder + file, text_of("res://" + folder + file))
	write(copy + "/hand.gd", HAND)
	var with_hand := text_of(SCENE).replace("[node name=\"FamilyEditor\"", "[ext_resource type=\"Script\" path=\"res://hand.gd\" id=\"Hand\"]\n\n[node name=\"FamilyEditor\"") + "\n[node name=\"Hand\" type=\"Node\" parent=\".\"]\nscript = ExtResource(\"Hand\")\n"
	write(copy + "/family_editor.tscn", with_hand)
	var said_with := await editor_says(copy, "with_tool")
	check(said_with.has("rebuilt in the editor: lean 1.6"), "in the editor, as the scene opens, the spire's script runs and says so: \"rebuilt in the editor: lean 1.6\"")
	check(said_with.has("hand before: children 2 box (0.78, 0.8, 0.78)") and said_with.has("rebuilt in the editor: lean 0.5") and said_with.has("hand after: lean 0.5 box (0.6, 0.8, 0.6)"),
		"in the editor the spire has its body, and a field set there, as the Inspector sets it, rebuilds it at once: %s" % [said_with])
	var saved := text_of(copy + "/family_editor.tscn")
	measured["scene_saved_in_the_editor"] = {"holds_lean_0.5": saved.contains("lean = 0.5"), "holds_a_mesh": saved.contains("ArrayMesh"), "holds_a_material": saved.contains("StandardMaterial3D")}
	check(said_with.has("hand saved the scene: true") and saved.contains("lean = 0.5") and not saved.contains("ArrayMesh") and not saved.contains("StandardMaterial3D"),
		"saved in the editor after that, the scene file holds lean = 0.5 and nothing the script built: no mesh and no material, because both hang on children the scene does not own")
	# The same without the first line of spire.gd.
	write(copy + "/family_editor.tscn", with_hand)
	write(copy + "/guests/family-editor/spire.gd", text_of(SPIRE).trim_prefix("@tool\n"))
	var said_without := await editor_says(copy, "without_tool")
	check(said_without.has("hand before: children 0 box (0.0, 0.0, 0.0)") and said_without.has("hand after: lean 0.5 box (0.0, 0.0, 0.0)") and not said_without.has("rebuilt in the editor: lean 1.6"),
		"without @tool the editor runs nothing of spire.gd: the spire has no body there, and a field set there changes the stored value and nothing to see: %s" % [said_without])
	# And with the planted bug.
	write(copy + "/family_editor.tscn", with_hand)
	write(copy + "/guests/family-editor/spire.gd", text_of(SPIRE).replace(SETTER, UNGUARDED))
	var said_bug := await editor_says(copy, "with_the_planted_bug")
	var red := false
	for line: String in said_bug:
		red = red or line.contains("Invalid assignment of property or key 'mesh'")
	check(red, "with @tool and the planted bug, the script error is logged inside the editor as the scene opens")
	remove(copy)
	check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(copy)), "the copy in .editor_check/ is removed again")

## Starts the editor with no window on the project in `folder`, with the scene
## open, lets it run 300 frames, and returns the lines it logged.
func editor_says(folder: String, label: String) -> Array:
	var log := ProjectSettings.globalize_path(folder + "/editor_%s.log" % label)
	var pid := OS.create_process(OS.get_executable_path(), ["--headless", "--editor", "--path", ProjectSettings.globalize_path(folder), "--xr-mode", "off", "--quit-after", "300", "--log-file", log, "res://family_editor.tscn"])
	var started := Time.get_ticks_msec()
	while OS.is_process_running(pid) and Time.get_ticks_msec() - started < 50000:
		await process_frame
	if OS.is_process_running(pid):
		OS.kill(pid)
	var lines := []
	for line in FileAccess.get_file_as_string(log).split("\n"):
		if line.strip_edges() != "" and not line.begins_with("["):
			lines.append(line.strip_edges())
	measured["editor_" + label] = lines
	return lines

## Removes a folder of this project with everything in it.
func remove(folder: String) -> void:
	var path := ProjectSettings.globalize_path(folder)
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.include_hidden = true    # the editor leaves a .godot folder in the copy
	for inner in dir.get_directories():
		remove(folder + "/" + inner)
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(path)
