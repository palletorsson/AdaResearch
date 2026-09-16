extends SceneTree
const OUT := "res://doc/space/melencolia-court-2026-09-16/image-reference/"
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func spawn(path: String, config: Dictionary = {}) -> Node3D:
	var n: Node3D = load(path).instantiate()
	for k in config: n.set_meta("config_" + k, config[k])
	root.add_child(n)
	return n
func pigment(mesh: MeshInstance3D, html: String) -> bool:
	var m := mesh.material_override as StandardMaterial3D
	return m != null and m.albedo_color.is_equal_approx(Color.html(html)) and m.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
func run() -> void:
	var corner := spawn("res://commons/primitives/pyramid/pyramid.tscn")
	check(corner.get_node("Pyramid").mesh.get_aabb().size.is_equal_approx(Vector3(0.6,0.8,0.6)), "Default corner dimensions preserved")
	check(corner.get_node("Pyramid").material_override is ShaderMaterial, "Default corner shader preserved")
	corner.call("apply_grid_config", {"height":"2.4", "solid_color":"B7C7DB"})
	check(corner.get_node("Pyramid").mesh.get_aabb().size.is_equal_approx(Vector3(0.6,2.4,0.6)), "Configured corner slenderness")
	check(pigment(corner.get_node("Pyramid"),"B7C7DB"), "Configured corner is opaque blue")
	corner.call("apply_grid_config", {"solid_color":"invalid"})
	check(corner.get_node("Pyramid").material_override is ShaderMaterial, "Invalid pigment falls back")
	var centre := spawn("res://commons/primitives/pyramid/pyramidlong.tscn")
	check(centre.get_node("PyramidLong").mesh.get_aabb().size.is_equal_approx(Vector3(0.8,2.8,0.8)), "Default spire dimensions preserved")
	check(not centre.has_node("Pedestal"), "No pedestal without opt-in")
	check(centre.get_node("PyramidLong").material_override is ShaderMaterial, "Default spire shader preserved")
	centre.call("apply_grid_config", {"pedestal_height":"0.8", "solid_color":"DF93B8"})
	check(is_equal_approx(centre.get_node("PyramidLong").position.y,0.8), "Spire meets pedestal top")
	check(is_equal_approx(centre.get_node("PyramidLong").position.y+centre.get_node("PyramidLong").mesh.get_aabb().end.y,3.6), "Central tip above court")
	var pedestal := centre.get_node("Pedestal")
	check(pedestal.get_node("PedestalMesh").mesh.size.is_equal_approx(Vector3.ONE*0.8), "Matching cubical pedestal")
	check((pedestal.get_child(1) as CollisionShape3D).shape.size.is_equal_approx(Vector3.ONE*0.8), "Pedestal collider matches mesh")
	check(is_equal_approx(pedestal.position.y,0.4), "Pedestal bottom meets court")
	check(pigment(centre.get_node("PyramidLong"),"DF93B8") and pigment(pedestal.get_node("PedestalMesh"),"DF93B8"), "Spire and pedestal share pink finish")
	centre.call("apply_grid_config", {"pedestal_height":"0.8", "solid_color":"DF93B8"})
	var bodies := 0
	for c in centre.get_children():
		if c is StaticBody3D: bodies += 1
	check(bodies==1, "Repeated configuration retains one pedestal")
	centre.call("apply_grid_config", {"pedestal_height":"0", "solid_color":""})
	check(not centre.has_node("Pedestal") and is_zero_approx(centre.get_node("PyramidLong").position.y), "Removing pedestal returns geometry to base")
	check(centre.get_node("PyramidLong").material_override is ShaderMaterial, "Clearing pigment restores spire shader")
	var gold := spawn("res://commons/primitives/cubes/cube_scene.tscn", {"solid_color":"D9AB63"})
	var plain := spawn("res://commons/primitives/cubes/cube_scene.tscn")
	var mesh_path := "CubeBaseStaticBody3D/CubeBaseMesh"
	var original: Material = plain.get_node(mesh_path).material_override
	check(pigment(gold.get_node(mesh_path), "D9AB63"), "Pre-ready cube configuration is ochre")
	check(original is ShaderMaterial, "Other cube instance retains original shader")
	gold.call("apply_grid_config", {"grain":"lattice"})
	var parts: Array = gold.get("_owned")
	check(parts.size()==27, "Existing lattice option still builds 27 parts")
	var all_gold := true
	for part in parts:
		if not pigment(part, "D9AB63"): all_gold=false
	check(all_gold, "Grain variants retain configured pigment")
	gold.call("apply_grid_config", {"grain":"solid", "solid_color":""})
	check(gold.get_node(mesh_path).visible and gold.get_node(mesh_path).material_override==original, "Clearing pigment restores exact shared cube material")
	check(gold.get_node(mesh_path).mesh.get_aabb().size.is_equal_approx(Vector3.ONE), "Cube unit dimensions preserved")
	for n in [corner,centre,gold,plain]: n.queue_free()
	await process_frame
	var f := FileAccess.open(OUT+"component-checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "));f.close()
	print("[solid-finish] ",checks," checks; failures: ",failures)
	quit(0 if failures.is_empty() else 1)
