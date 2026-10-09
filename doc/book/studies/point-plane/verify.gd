extends SceneTree
## Headless checks for the Point Plane study. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; exit code 0 when every check passes.
## Headless draws no frames, so what the eye gets is measured by sheet.gd instead;
## here we check the ingredients of visibility (winding, normals, cull mode) and
## everything a body can feel (the collider, a dropped marble, rays).
## The last checks before the sheet's are of the guest in guests/: the body this
## chapter hands to the room, which has to stand on its own.

var checks := []
var measured := {}

const RADIUS := 0.1       # the marble's radius
const HEIGHT := 1.12      # the height B walks at, so the plane's height
const CENTRE := Vector3(0.15, HEIGHT, 0.5)   # the middle of the fixed walk
const CheckGuest := preload("res://check_guest.gd")
const GUEST := "res://guests/point-plane/"    # the body this chapter hands to the room
const PLACE := 0.8                            # half the width of a place in the room

## Godot hands every message to a Logger. This one keeps the errors while the guest runs.
class Catcher extends Logger:
	var errors: Array[String] = []
	var lock := Mutex.new()   # messages can come from other threads

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		lock.lock()
		errors.append("%s (%s:%d)" % [rationale if rationale != "" else code, file, line])
		lock.unlock()

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	print(("PASS " if passed else "FAIL ") + label)

func frames(count: int) -> void:
	for i in count:
		await process_frame

## Let the marble fall and come to rest: up to three seconds of physics.
func settle(marble: RigidBody3D) -> float:
	for i in 180:
		await physics_frame
		if i > 30 and marble.sleeping:
			break
	return marble.position.y

func key_names(codes: Array) -> String:
	return ", ".join(codes.map(func(c): return OS.get_keycode_string(c)))

## Press a named action for one call of _process, then let the frame end,
## because is_action_just_pressed stays true until the frame the press arrived in is over.
## It starts by stepping into a process frame: after waiting on physics we would be inside
## a physics tick, where a press only counts as just pressed from the NEXT tick on.
func press(action: String, study: Node) -> void:
	await process_frame
	Input.action_press(action)
	study._process(0)
	Input.action_release(action)
	await process_frame

## The same walk as sheet.gd: twelve kept positions, clockwise as seen from above.
func walk() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for k in 12:
		var t := -k * TAU / 12.0
		points.append(CENTRE + Vector3(1.1 * cos(t), 0.0, -0.75 * sin(t)))
	return points

func ray_hit(from: Vector3, to: Vector3, marble: RigidBody3D) -> Variant:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [marble.get_rid()]
	var hit := root.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("position", null)

func ray_from_above(marble: RigidBody3D) -> Variant:
	return ray_hit(CENTRE + Vector3(0, 2, 0), CENTRE - Vector3(0, 2, 0), marble)

func ray_from_below(marble: RigidBody3D) -> Variant:
	return ray_hit(Vector3(CENTRE.x, 0.3, CENTRE.z), CENTRE + Vector3(0, 2, 0), marble)

## A ray that passes the plane goes on to the floor, so a hit only counts at the plane's height.
func meets_plane(hit: Variant) -> bool:
	return hit != null and absf(hit.y - HEIGHT) < 0.001

func normals_of(mesh: ArrayMesh) -> PackedVector3Array:
	if (mesh.surface_get_format(0) & Mesh.ARRAY_FORMAT_NORMAL) == 0:
		return PackedVector3Array()
	return mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]

func all_y(normals: PackedVector3Array, sign: float) -> bool:
	if normals.is_empty():
		return false
	for nrm in normals:
		if nrm.y * sign < 0.999:
			return false
	return true

## The guest: the one body this chapter hands to the room. The room copies its
## folder alone, so it has to load, run and stand on its own. It is checked far
## from the study, so that no ray meets the study's floor or its plane.
func guest_checks() -> void:
	var scene: Resource = load(GUEST + "point-plane.tscn")
	var guest: Node = null
	if scene is PackedScene and (scene as PackedScene).can_instantiate():
		guest = (scene as PackedScene).instantiate()
	check("the guest scene loads: guests/point-plane/point-plane.tscn, and its first node is a Node3D", guest is Node3D)
	var needs := CheckGuest.outside(GUEST)
	check("the guest names nothing outside its folder: %s" % [needs], needs.is_empty())
	var declared := CheckGuest.class_names(GUEST)
	check("the guest declares no class_name: %s" % [declared], declared.is_empty())
	if not guest is Node3D:
		check("the guest runs two frames and Godot logs no error (it did not load)", false)
		return
	var at := Vector3(40, 0, 40)
	(guest as Node3D).position = at
	var catcher := Catcher.new()
	OS.add_logger(catcher)
	root.add_child(guest)
	await frames(2)
	await physics_frame
	OS.remove_logger(catcher)
	check("the guest runs two frames and Godot logs no error: %s" % [catcher.errors], catcher.errors.is_empty())
	var face: MeshInstance3D = guest.get_node("Face")
	var mesh := face.mesh as ArrayMesh
	var shape := guest.get_node("FaceBody/CollisionShape3D").shape as ConcavePolygonShape3D
	var triangles := 0
	if mesh != null:
		triangles = mesh.get_faces().size() / 3
	check("the guest is a walked plane with its body: Face holds the mesh saved in my_plane.tres, a fan of %d triangles with normals, painted BODY c6ff3d, one side drawn; FaceBody holds a trimesh of the same triangles with backface collision on" % triangles,
		mesh != null and mesh.resource_path == GUEST + "my_plane.tres" and triangles >= 1
		and mesh.surface_get_primitive_type(0) == Mesh.PRIMITIVE_TRIANGLES and (mesh.surface_get_format(0) & Mesh.ARRAY_FORMAT_NORMAL) != 0
		and face.material_override.albedo_color.to_html(false) == "c6ff3d" and face.material_override.cull_mode == BaseMaterial3D.CULL_BACK
		and shape != null and shape.get_faces().size() == triangles * 3 and shape.backface_collision)
	if mesh == null:
		guest.free()
		return
	var box: AABB = face.global_transform * mesh.get_aabb()
	box.position -= at
	var lies: float = guest.height
	check("the guest lies %.2f m above the ground, its middle over its own origin, and fits on a place, 1.6 m wide and deep: its box runs from (%.2f, %.2f, %.2f) to (%.2f, %.2f, %.2f)" % [
		lies, box.position.x, box.position.y, box.position.z, box.end.x, box.end.y, box.end.z],
		absf(lies - 0.12) < 0.0001 and absf(box.position.y - lies) < 0.001 and absf(box.end.y - lies) < 0.001
		and box.position.x >= -PLACE and box.position.z >= -PLACE and box.end.x <= PLACE and box.end.z <= PLACE
		and absf(box.get_center().x) < 0.001 and absf(box.get_center().z) < 0.001)
	var space := root.get_world_3d().direct_space_state
	var from_above: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3(0, 2, 0), at + Vector3(0, -2, 0)))
	var from_below: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3(0, -2, 0), at + Vector3(0, 2, 0)))
	check("a ray from above and a ray from below both meet the guest's plane at %.2f m: it has a body, and the body has a back" % lies,
		from_above.has("position") and absf(from_above["position"].y - lies) < 0.001
		and from_below.has("position") and absf(from_below["position"].y - lies) < 0.001)
	measured["guest"] = {"scene": GUEST + "point-plane.tscn", "triangles": triangles, "height_m": lies,
		"box": [[snappedf(box.position.x, 0.001), snappedf(box.position.y, 0.001), snappedf(box.position.z, 0.001)], [snappedf(box.end.x, 0.001), snappedf(box.end.y, 0.001), snappedf(box.end.z, 0.001)]]}
	guest.free()
	await process_frame

func run() -> void:
	# The Input Map: Trace's five actions and four new ones.
	var wanted := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_forward": [KEY_W, KEY_UP], "move_backward": [KEY_S, KEY_DOWN],
		"pause": [KEY_SPACE], "close": [KEY_ENTER], "fill": [KEY_F], "drop": [KEY_M], "look": [KEY_V],
	}
	for action: String in wanted:
		var bound := []
		if InputMap.has_action(action):
			for event in InputMap.action_get_events(action):
				if event is InputEventKey:
					bound.append(event.physical_keycode)
		check("action %s exists, bound to %s" % [action, key_names(wanted[action])], bound == wanted[action])

	# The earlier studies are carried unchanged and still run on their own.
	var lines: Node3D = load("res://line.tscn").instantiate()
	root.add_child(lines)
	await frames(2)
	check("line.tscn still runs on its own: readout 1.50 m", lines.get_node("Readout").text == "1.50 m")
	lines.free()
	var trace_study: Node3D = load("res://trace.tscn").instantiate()
	root.add_child(trace_study)
	await frames(2)
	check("trace.tscn still runs on its own: 1 kept, B carries mover.gd",
		trace_study.get_node("Record").text.begins_with("1 kept")
		and trace_study.get_node("B").get_script().resource_path == "res://mover.gd")
	trace_study.free()

	# The scene inherits Trace and adds the face, its body, the marble and a second camera.
	var study: Node3D = load("res://plane.tscn").instantiate()
	check("the study starts open with an empty list", study.trace.is_empty() and not study.closed)
	root.add_child(study)
	var b: Node3D = study.get_node("B")
	var strip: MeshInstance3D = study.get_node("Strip")
	var face: MeshInstance3D = study.get_node("Face")
	var shape_node: CollisionShape3D = study.get_node("FaceBody/CollisionShape3D")
	var marble: RigidBody3D = study.get_node("Marble")
	var under: Camera3D = study.get_node("Under")
	check("Trace's A, B, Segment, Readout, Strip and Record are inherited; B carries mover.gd",
		study.has_node("A") and study.has_node("Segment") and study.has_node("Readout")
		and study.has_node("Record") and strip.get_script().resource_path == "res://trace_strip.gd"
		and b.get_script().resource_path == "res://mover.gd")
	check("the root runs plane.gd", study.get_script().resource_path == "res://plane.gd")
	check("Face has a material and no mesh yet; FaceBody's shape is empty",
		face.material_override != null and face.mesh == null and shape_node.shape == null)
	check("the marble carries marble.gd and waits frozen on the floor",
		marble.get_script().resource_path == "res://marble.gd" and marble.freeze and marble.position.y < 0.2)
	check("the Under camera is supplied and not current", under != null and not under.current)

	# Live frames, as the running study receives them.
	await frames(2)
	check("the first frame keeps B's starting position",
		study.trace.size() == 1 and study.trace[0].is_equal_approx(Vector3(0.75, HEIGHT, 0.0)))
	await frames(30)
	check("holding still adds nothing (30 live frames); the strip draws nothing",
		study.trace.size() == 1 and (strip.mesh as ImmediateMesh).get_surface_count() == 0)
	var x_before := b.position.x
	Input.action_press("move_right")
	await frames(10)
	Input.action_release("move_right")
	check("holding move_right moves B over live frames", b.position.x > x_before)
	check("the Record label reads open", study.get_node("Record").text.contains("open"))

	# From here we call _process ourselves.
	study.set_process(false)
	b.set_process(false)
	var origin := Vector3(0.75, HEIGHT, 0.0)

	# look: V holds the Under camera, releasing it returns the borrowed one.
	var main_camera: Camera3D = study.get_node("Camera3D")
	Input.action_press("look")
	study._process(0)
	var under_while_held := under.current
	Input.action_release("look")
	study._process(0)
	check("look held: the Under camera is current; released: the borrowed camera is",
		under_while_held and not under.current and main_camera.current)

	# close needs three kept positions; fill needs a closed study.
	study.trace.clear()
	b.position = origin
	study._process(0)
	await press("close", study)
	check("close with 1 kept: refused, the study stays open", not study.closed and study.recording)
	await press("fill", study)
	check("fill on an open study: no face", face.mesh == null)
	b.position = origin + Vector3(0.3, 0, 0)
	study._process(0)
	await press("close", study)
	check("close with 2 kept: refused (a loop needs three edges)", not study.closed and study.trace.size() == 2)
	b.position = origin + Vector3(0.3, 0, 0.3)
	study._process(0)
	await press("close", study)
	check("close with 3 kept: closed, and the recorder stops", study.closed and not study.recording)

	# The walk: twelve positions clockwise from above, closed.
	study.closed = false
	study.recording = true
	study.trace = walk()
	var n: int = study.trace.size()
	await press("close", study)
	var loop: Array[Vector3] = study.outline()
	check("closed: the outline has %d entries, one more than the list" % (n + 1), loop.size() == n + 1)
	check("the outline's last entry is the first kept position: first == last joined",
		loop[-1].is_equal_approx(loop[0]) and loop[0].is_equal_approx(study.trace[0]))
	check("the list itself is unchanged by closing: %d kept" % n, study.trace.size() == n)
	var immediate := strip.mesh as ImmediateMesh
	var vertices: PackedVector3Array = immediate.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var primitive = RenderingServer.mesh_get_surface(immediate.get_rid(), 0).get("primitive")
	check("the strip draws the closed outline: %d vertices, last == first, one line strip" % vertices.size(),
		vertices.size() == n + 1 and vertices[-1].is_equal_approx(vertices[0]) and primitive == Mesh.PRIMITIVE_LINE_STRIP)
	var around: float = study.route_length() + study.straight_length()
	check("around = route + straight: %.2f m, and the Record says so" % around,
		study.get_node("Record").text.contains("closed, %.2f m around" % around))
	measured["around_m"] = snappedf(around, 0.01)
	b.position = origin + Vector3(1.0, 0, 0.5)
	study._process(0)
	check("closed: moving B 1.1 m keeps nothing", study.trace.size() == n)
	await press("pause", study)
	b.position = origin + Vector3(-1.0, 0, 0.5)
	study._process(0)
	check("closed: even with recording on again, nothing is kept", study.recording and study.trace.size() == n)
	study.recording = false

	# Before the face: the closed outline stops nothing.
	var above_centre := CENTRE + Vector3(0, 1, 0)
	marble.drop(above_centre)
	var rest := await settle(marble)
	check("before fill, a marble dropped inside the outline falls to the floor: rests at %.3f m" % rest,
		rest < 0.2 and rest > 0.0)

	# fill: the fan, its normals, its collider.
	await press("fill", study)
	var mesh := face.mesh as ArrayMesh
	check("fill: Face.mesh is an ArrayMesh with one surface of triangles",
		mesh != null and mesh.get_surface_count() == 1 and mesh.surface_get_primitive_type(0) == Mesh.PRIMITIVE_TRIANGLES)
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var faces: int = mesh.get_faces().size() / 3
	check("%d kept positions make %d triangles, %d vertices (n - 2, three each)" % [n, faces, verts.size()],
		faces == n - 2 and verts.size() == 3 * (n - 2))
	var fan_ok := true
	for t in faces:
		fan_ok = fan_ok and verts[t * 3].is_equal_approx(study.trace[0]) \
			and verts[t * 3 + 1].is_equal_approx(study.trace[t + 1]) \
			and verts[t * 3 + 2].is_equal_approx(study.trace[t + 2])
	check("every triangle shares the first kept position: a fan (p0, pi, pi+1)", fan_ok)
	var normals := normals_of(mesh)
	check("normals exist, one per vertex, and point up (the walk was clockwise from above)",
		normals.size() == verts.size() and all_y(normals, 1.0))
	var rule_ok := true
	for t in faces:
		var plane := Plane(verts[t * 3], verts[t * 3 + 1], verts[t * 3 + 2])
		rule_ok = rule_ok and plane.normal.dot(normals[t * 3]) > 0.999
	check("Plane(v0, v1, v2).normal agrees with the generated normal, triangle by triangle (clockwise is the front)", rule_ok)
	check("the material culls back faces (one side drawn)",
		face.material_override.cull_mode == BaseMaterial3D.CULL_BACK)
	var shape := shape_node.shape as ConcavePolygonShape3D
	check("FaceBody's shape is a trimesh of the same %d triangles, with backface collision on" % faces,
		shape != null and shape.get_faces().size() == verts.size() and shape.backface_collision)
	check("the Record counts the triangles", study.get_node("Record").text.contains("%d triangles" % (n - 2)))
	var bare := SurfaceTool.new()
	bare.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, n - 1):
		for p in [study.trace[0], study.trace[i], study.trace[i + 1]]:
			bare.add_vertex(p)
	var bare_mesh := bare.commit()
	check("without generate_normals() the surface carries no NORMAL at all",
		(bare_mesh.surface_get_format(0) & Mesh.ARRAY_FORMAT_NORMAL) == 0)

	# The body: a marble rests on the plane at the walk's height plus its radius.
	marble.drop(above_centre)
	rest = await settle(marble)
	check("after fill, the marble rests ON the plane: %.3f m (1.12 + 0.10 radius), not below it" % rest,
		absf(rest - (HEIGHT + RADIUS)) < 0.02 and rest > HEIGHT)
	measured["marble_rest_on_plane_m"] = snappedf(rest, 0.001)
	study._process(0)
	check("the Record reports the marble's height", study.get_node("Record").text.contains("marble at %.2f m" % marble.position.y))
	check("a ray from above meets the plane at y = 1.12", meets_plane(ray_from_above(marble)))
	marble.drop(Vector3(2.2, HEIGHT + 1.0, 1.3))
	rest = await settle(marble)
	check("dropped outside the walk, the marble falls past the plane to the floor: %.3f m" % rest, rest < 0.2)
	b.position = Vector3(0.4, HEIGHT, 0.7)
	await press("drop", study)
	check("the drop key puts the marble one metre above B",
		absf(marble.position.x - b.position.x) < 0.01 and absf(marble.position.z - b.position.z) < 0.01 and marble.position.y > HEIGHT + 0.9)
	rest = await settle(marble)
	check("and it comes to rest on the plane under B: %.3f m" % rest, absf(rest - (HEIGHT + RADIUS)) < 0.02)

	# The axis. Headless cannot see; it can read what the eye will be given.
	var names := ["clockwise", "clockwise flipped normals", "counter-clockwise", "counter-clockwise double-sided"]
	var expect_sign := [1.0, -1.0, -1.0, -1.0]
	var expect_cull := [BaseMaterial3D.CULL_BACK, BaseMaterial3D.CULL_BACK, BaseMaterial3D.CULL_BACK, BaseMaterial3D.CULL_DISABLED]
	for v in 4:
		study.side = v
		await press("fill", study)
		mesh = face.mesh as ArrayMesh
		var vs: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var ns := normals_of(mesh)
		var winding_up := true
		for t in vs.size() / 3:
			winding_up = winding_up and Plane(vs[t * 3], vs[t * 3 + 1], vs[t * 3 + 2]).normal.y > 0.999
		var expect_winding_up: bool = v < 2
		var ok: bool = winding_up == expect_winding_up and all_y(ns, expect_sign[v]) \
			and face.material_override.cull_mode == expect_cull[v]
		var cull := "culls back faces" if face.material_override.cull_mode == BaseMaterial3D.CULL_BACK else "draws both sides"
		check("side %d %s: front %s, normals %s, %s" % [v, names[v], "up" if winding_up else "down", "up" if expect_sign[v] > 0 else "down", cull], ok)
		marble.drop(above_centre)
		rest = await settle(marble)
		var over: bool = meets_plane(ray_from_above(marble))
		var beneath: bool = meets_plane(ray_from_below(marble))
		check("side %d: the marble still rests at %.3f m and rays from above and below both meet the plane: the collider reads triangles, not winding or cull mode" % [v, rest],
			absf(rest - (HEIGHT + RADIUS)) < 0.02 and over and beneath)
	# The default collider has a side: the same side as the face.
	study.side = 2
	await press("fill", study)
	shape = shape_node.shape as ConcavePolygonShape3D
	shape.backface_collision = false
	await physics_frame
	var over2: bool = meets_plane(ray_from_above(marble))
	var beneath2: bool = meets_plane(ray_from_below(marble))
	marble.drop(above_centre)
	rest = await settle(marble)
	check("backface_collision off (the default), counter-clockwise: a ray from above misses, from below hits, and the marble falls through to %.3f m" % rest,
		not over2 and beneath2 and rest < 0.2)
	study.side = 0
	await press("fill", study)
	shape = shape_node.shape as ConcavePolygonShape3D
	shape.backface_collision = false
	await physics_frame
	var over3: bool = meets_plane(ray_from_above(marble))
	var beneath3: bool = meets_plane(ray_from_below(marble))
	check("backface_collision off, clockwise: a ray from above hits, from below misses: by default the body shares the eye's side", over3 and not beneath3)

	# Smooth and flat normals agree on a plane: that pair is not on the axis.
	var smooth := SurfaceTool.new()
	var flat := SurfaceTool.new()
	smooth.begin(Mesh.PRIMITIVE_TRIANGLES)
	flat.begin(Mesh.PRIMITIVE_TRIANGLES)
	flat.set_smooth_group(-1)
	var pts := walk()
	for i in range(1, pts.size() - 1):
		for p in [pts[0], pts[i], pts[i + 1]]:
			smooth.add_vertex(p)
			flat.add_vertex(p)
	smooth.generate_normals()
	flat.generate_normals()
	var ns_smooth: PackedVector3Array = smooth.commit().surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	var ns_flat: PackedVector3Array = flat.commit().surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	var same := ns_smooth.size() == ns_flat.size()
	for i in mini(ns_smooth.size(), ns_flat.size()):
		same = same and ns_smooth[i].is_equal_approx(ns_flat[i])
	check("smooth and flat normals are identical on a planar fan (%d normals): no visible pair there" % ns_smooth.size(), same)

	# A walk longer than the capacity has lost its start: closing joins to the oldest position still held.
	study.closed = false
	study.recording = true
	study.capacity = 5
	study.trace.clear()
	for i in 8:
		study.keep(Vector3(i * 0.2, HEIGHT, 0.0))
	await press("close", study)
	var short_loop: Array[Vector3] = study.outline()
	check("capacity 5, 8 positions kept: the start has left, and the outline closes to the 4th, the oldest still held",
		study.closed and short_loop.size() == 6 and short_loop[-1].is_equal_approx(Vector3(3 * 0.2, HEIGHT, 0.0)))
	study.capacity = 128

	# The debt: a fan from the wrong corner of an L covers the notch.
	var A := Vector3(0.0, HEIGHT, 0.0)
	var B := Vector3(1.2, HEIGHT, 0.0)
	var C := Vector3(1.2, HEIGHT, 0.4)
	var D := Vector3(0.4, HEIGHT, 0.4)
	var E := Vector3(0.4, HEIGHT, 1.2)
	var F := Vector3(0.0, HEIGHT, 1.2)
	# In the notch, near its inner corner D: the fan from B reaches here (triangle B, D, E), the fan from A does not.
	var notch := Vector3(0.55, HEIGHT + 1.0, 0.6)
	study.side = 0
	var from_b: Array[Vector3] = [B, C, D, E, F, A]
	var from_a: Array[Vector3] = [A, B, C, D, E, F]
	study.trace = from_b
	await press("fill", study)
	marble.drop(notch)
	var rest_b := await settle(marble)
	var faces_l: int = (face.mesh as ArrayMesh).get_faces().size() / 3
	study.trace = from_a
	await press("fill", study)
	marble.drop(notch)
	var rest_a := await settle(marble)
	check("the L from B: %d triangles, and the marble in the notch rests on overspill at %.3f m; from A it falls through to %.3f m" % [faces_l, rest_b, rest_a],
		faces_l == 4 and absf(rest_b - (HEIGHT + RADIUS)) < 0.02 and rest_a < 0.2)
	measured["L_from_B_marble_in_notch_m"] = snappedf(rest_b, 0.001)
	measured["L_from_A_marble_in_notch_m"] = snappedf(rest_a, 0.001)

	# The guest handed to the room.
	await guest_checks()

	# The sheet's record, if it has been rendered.
	if FileAccess.file_exists("res://sheet.json"):
		var sheet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://sheet.json"))
		measured["sheet_closest_pair_above"] = sheet.get("closest_pair_above", "")
		measured["sheet_above"] = {}
		measured["sheet_below"] = {}
		for v in 4:
			measured["sheet_above"][names[v]] = sheet.get("%d_above" % v, {})
			measured["sheet_below"][names[v]] = sheet.get("%d_below" % v, {})
		measured["sheet_pairs_above_pct"] = sheet.get("pairs_above_pct", {})
		check("sheet.json: from above the counter-clockwise face changes under 0.1% of the frame and from below over 2%; the clockwise face the reverse (rendered by sheet.gd)",
			sheet.get("2_above", {}).get("face_share_pct", 100.0) < 0.1 and sheet.get("2_below", {}).get("face_share_pct", 0.0) > 2.0
			and sheet.get("0_above", {}).get("face_share_pct", 0.0) > 2.0 and sheet.get("0_below", {}).get("face_share_pct", 100.0) < 0.5)
		check("sheet.json: the closest pair from above is clockwise and counter-clockwise double-sided, as predicted",
			sheet.get("closest_pair_above", "") == "0 vs 3")
		check("sheet.json: flipped normals keep the face where it is and darken it; no normals at all change under 0.1% of the frame",
			absf(sheet["0_above"]["face_share_pct"] - sheet["1_above"]["face_share_pct"]) < 0.3
			and sheet["1_above"]["face_brightness"] < sheet["0_above"]["face_brightness"] - 0.1
			and sheet.get("no_normals_vs_clockwise_above_pct", 100.0) < 0.1)
		check("sheet.json: only the clockwise faces cast a shadow on the floor",
			sheet["0_above"]["shadow_share_pct"] > 0.3 and sheet["1_above"]["shadow_share_pct"] > 0.3
			and sheet["2_above"]["shadow_share_pct"] < 0.1 and sheet["3_above"]["shadow_share_pct"] < 0.1)

	var passed := checks.all(func(c): return c.passed)
	var report := {"passed": passed, "godot": Engine.get_version_info().string, "measured": measured, "checks": checks}
	FileAccess.open("res://verification.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("Plane study: ", checks.size(), " checks; passed=", passed)
	quit(0 if passed else 1)
