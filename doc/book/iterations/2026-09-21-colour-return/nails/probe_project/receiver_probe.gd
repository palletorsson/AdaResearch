extends SceneTree

# Bounded receiver probe: real embedded hand meshes and unchanged production colour
# scripts; XRToolsHand animation roots removed in isolated copies. No XR hardware.
# Mapper below supplies the signal only; RGB-point interaction is not exercised.
class MapperSignalFixture extends Node3D:
	signal values_changed(r: float, g: float, b: float)
	var values := Vector3.ZERO
	func set_values(r: float, g: float, b: float) -> void:
		values = Vector3(r, g, b)
		values_changed.emit(r, g, b)
	func get_values() -> Vector3:
		return values

var checks: Array = []
var failures: Array = []
var observations: Array = []
var base: Node3D
var segment: Node3D
var gm: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks.append({"pass": ok, "label": label})
	if not ok:
		failures.append(label)
	print("CHECK ", "PASS " if ok else "FAIL ", label)

func node_at(parent: Node, label: String) -> Node3D:
	var n := Node3D.new()
	n.name = label
	parent.add_child(n)
	return n

func station(surface: int) -> Node3D:
	var n := Node3D.new()
	n.name = "NailsStation" if surface == 0 else "SkinStation"
	n.set_script(load("res://commons/interfaces/nail_color_controller.gd"))
	n.target_surface = surface
	var mapper := MapperSignalFixture.new()
	mapper.name = "ValueMapper3D"
	n.add_child(mapper)
	segment.add_child(n)
	return n

func rig_pair() -> Dictionary:
	var origin := XROrigin3D.new()
	origin.name = "XROrigin3D"
	base.add_child(origin)
	var receivers: Array = []
	for side in ["left", "right"]:
		var controller := XRController3D.new()
		controller.name = "LeftHand" if side == "left" else "RightHand"
		controller.tracker = StringName(side + "_hand")
		origin.add_child(controller)
		var collision := node_at(controller, "XRToolsCollisionHand")
		var hand: Node3D = load("res://commons/body/hands/%s_hand.tscn" % side).instantiate()
		collision.add_child(hand)
		receivers.append(hand.get_node("PresistNailColor"))
	return {"origin":origin,"receivers":receivers}

func check_pair(pair: Dictionary, nails: Color, skin: Color, label: String) -> void:
	for receiver in pair.receivers:
		var mesh: MeshInstance3D = receiver.hand_mesh
		check(mesh != null and receiver.surface_nails_idx >= 0 and receiver.surface_skin_idx >= 0 and receiver.surface_nails_idx != receiver.surface_skin_idx, label + " distinct named surfaces " + receiver.get_parent().name)
		if mesh == null:
			continue
		check(mesh.get_active_material(receiver.surface_nails_idx).albedo_color.is_equal_approx(nails), label + " nails " + receiver.get_parent().name)
		check(mesh.get_active_material(receiver.surface_skin_idx).albedo_color.is_equal_approx(skin), label + " skin " + receiver.get_parent().name)
		observations.append({"stage":label,"hand":str(receiver.get_parent().name),"surface_nails":receiver.surface_nails_idx,"surface_skin":receiver.surface_skin_idx,"nails_material":str(mesh.get_active_material(receiver.surface_nails_idx).albedo_color),"skin_material":str(mesh.get_active_material(receiver.surface_skin_idx).albedo_color)})

func frames() -> void:
	for i in range(3):
		await process_frame

func run() -> void:
	gm = root.get_node("GameManager")
	base = node_at(root, "Base")
	current_scene = base
	var museum := node_at(base, "Museum")
	segment = node_at(museum, "Segment")
	var nail_control := station(0)
	var skin_control := station(1)
	await frames()
	var nail_a := Color(0.86, 0.13, 0.46, 1)
	var skin_a := Color(0.25, 0.64, 0.57, 1)
	nail_control.value_mapper.set_values(nail_a.r, nail_a.g, nail_a.b)
	skin_control.value_mapper.set_values(skin_a.r, skin_a.g, skin_a.b)
	check(nail_control.left_hand == null and nail_control.right_hand == null, "no XR rig: station has no direct hand references")
	check(gm.get_nail_color().is_equal_approx(nail_a) and gm.get_hand_color().is_equal_approx(skin_a), "no XR rig: both station emissions update GameManager colour state")
	check(nail_control.color_preview_cube.material_override.albedo_color.is_equal_approx(nail_a), "no XR rig: swatch changes")
	var pair := rig_pair()
	await frames()
	check_pair(pair, nail_a, skin_a, "hand scene added after selection")
	check(nail_control.left_hand == null and skin_control.right_hand == null, "late rig: station still has no direct hand references")
	var nail_b := Color(0.12, 0.37, 0.92, 1)
	var skin_b := Color(0.74, 0.19, 0.61, 1)
	nail_control.value_mapper.set_values(nail_b.r, nail_b.g, nail_b.b)
	check_pair(pair, nail_b, skin_a, "live nail signal leaves skin alone")
	skin_control.value_mapper.set_values(skin_b.r, skin_b.g, skin_b.b)
	check_pair(pair, nail_b, skin_b, "live skin signal leaves nails alone")
	pair.origin.free()
	await frames()
	pair = rig_pair()
	await frames()
	check_pair(pair, nail_b, skin_b, "replacement hand scene hydrates stored colours")
	# Optional legacy discovery path: add group then create new station.
	pair.origin.add_to_group("xr_origin")
	var direct_nail := station(0)
	var direct_skin := station(1)
	await frames()
	check(direct_nail.left_hand_mesh != null and direct_nail.right_hand_mesh != null, "with xr_origin group: direct discovery finds both production meshes")
	direct_nail.value_mapper.set_values(nail_a.r, nail_a.g, nail_a.b)
	direct_skin.value_mapper.set_values(skin_a.r, skin_a.g, skin_a.b)
	check_pair(pair, nail_a, skin_a, "direct station and receiver coexist")
	var report := {"checks":checks,"failures":failures,"observations":observations,"headset_tested":false,"actual_game_launched":false,"scope":"Real hand embedded geometry, named surfaces, unchanged receiver and station scripts, literal GameManager colour methods. XR animations stripped in copied scenes and input mapper is a signal fixture. Proves material/signal wiring and whole-scene late readiness, not physical XR visibility, tracking or grabbing."}
	var f := FileAccess.open("res://../probe_results.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	print("RESULT ", checks.size(), " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
