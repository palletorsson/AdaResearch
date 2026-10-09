# Native artifact instantiation and collision checks. This is not the museum/VR run.
extends SceneTree

const SCENE := "res://commons/artifacts/glyph_profile_gallery/glyph_profile_gallery.tscn"
const OUTPUT := "res://doc/book/iterations/2026-10-04-primitives-expanded/glyph-gallery-verification.json"
var checks: Array[Dictionary] = []
var failures := 0

func _initialize() -> void:
	call_deferred("_verify")

func _check(name: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"name": name, "passed": passed, "detail": detail})
	if not passed:
		failures += 1
		push_error(name)

func _verify() -> void:
	var packed: PackedScene = load(SCENE)
	_check("scene loads", packed != null)
	if packed == null:
		quit(1)
		return
	var host := Node3D.new()
	root.add_child(host)
	var gallery: Node3D = packed.instantiate()
	_check("artifact script loaded", gallery.get_script() != null)
	if gallery.get_script() == null:
		gallery.free()
		quit(1)
		return
	host.add_child(gallery)
	await process_frame
	await physics_frame
	await physics_frame
	_check("six sculptures", gallery.specimens.size() == 6, gallery.specimens.size())
	_check("six source profiles", gallery.find_children("SourceProfile", "MeshInstance3D", true, false).size() == 6)
	_check("no competing host nodes", gallery.find_children("*", "Camera3D", true, false).is_empty() and gallery.find_children("*", "WorldEnvironment", true, false).is_empty() and gallery.find_children("*", "Light3D", true, false).is_empty() and gallery.find_children("*", "CanvasLayer", true, false).is_empty())
	var bounds := AABB()
	var first := true
	var triangles := 0
	for mesh_instance: MeshInstance3D in gallery.find_children("*", "MeshInstance3D", true, false):
		var local: Transform3D = gallery.global_transform.affine_inverse() * mesh_instance.global_transform
		var box: AABB = local * mesh_instance.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
		if mesh_instance.name == "Sculpture":
			triangles += mesh_instance.mesh.get_faces().size() / 3
	_check("plinth bases sit on floor", absf(bounds.position.y) < 0.0001, bounds.position.y)
	_check("gallery fits assigned 29 by 37 m room", bounds.position.x >= -14.5 and bounds.end.x <= 14.5 and bounds.position.z >= -18.5 and bounds.end.z <= 18.5)
	_check("seven metre ceiling clears geometry", bounds.end.y < 7.0, bounds.end.y)
	_check("18 static collision bodies", gallery.find_children("*", "StaticBody3D", true, false).size() == 18)
	var space := host.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = .30
	capsule.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	var aisle_hits: Array = []
	for z in range(-18, 19):
		for x in [-2.0, 0.0, 2.0]:
			query.transform = Transform3D(Basis.IDENTITY, Vector3(x, .85, z))
			if not space.intersect_shape(query, 1).is_empty():
				aisle_hits.append([x, z])
	_check("central entry-to-exit corridor capsule clear", aisle_hits.is_empty(), aisle_hits)
	var cross_hits: Array = []
	for z in [-5.5, 5.5]:
		for x in range(-13, 14):
			query.transform = Transform3D(Basis.IDENTITY, Vector3(x, .85, z))
			if not space.intersect_shape(query, 1).is_empty():
				cross_hits.append([x, z])
	_check("cross aisles capsule clear", cross_hits.is_empty(), cross_hits)
	var passage: MeshInstance3D = gallery.specimens[0]
	var open_ray := PhysicsRayQueryParameters3D.create(passage.to_global(Vector3(0, 2.7, 2)), passage.to_global(Vector3(0, 2.7, -2)), 1)
	_check("O centre remains open", space.intersect_ray(open_ray).is_empty())
	var sill_ray := PhysicsRayQueryParameters3D.create(passage.to_global(Vector3(0, .10, 2)), passage.to_global(Vector3(0, .10, -2)), 1)
	_check("O lower stroke remains a colliding sill", not space.intersect_ray(sill_ray).is_empty())
	var source := FileAccess.get_file_as_string("res://doc/book/studies/glyph-form-atlas/atlas.gd")
	var adapted := FileAccess.get_file_as_string("res://commons/artifacts/glyph_profile_gallery/glyph_profile_gallery.gd")
	var original_recipe := source.substr(source.find("func _frames("), source.find("func _environment()") - source.find("func _frames(")).strip_edges()
	var adapted_recipe := adapted.substr(adapted.find("func _frames(")).strip_edges()
	_check("six frame recipes unchanged", original_recipe == adapted_recipe)
	_check("profile mesher unchanged", FileAccess.get_file_as_bytes("res://doc/book/studies/glyph-form-atlas/profile_sweep.gd") == FileAccess.get_file_as_bytes("res://commons/artifacts/glyph_profile_gallery/profile_sweep.gd"))
	var report := {
		"scene": SCENE,
		"engine": Engine.get_version_info().string,
		"local_aabb_position": [bounds.position.x, bounds.position.y, bounds.position.z],
		"local_aabb_size": [bounds.size.x, bounds.size.y, bounds.size.z],
		"local_aabb_end": [bounds.end.x, bounds.end.y, bounds.end.z],
		"aabb_note": "Mesh geometry, including profile boards and plinths; labels excluded.",
		"sculpture_triangles": triangles,
		"checks": checks,
		"failed": failures,
		"scope": "Native artifact instantiation and physics queries only. Endless Museum/VR integration is a separate host run."
	}
	var output := FileAccess.open(OUTPUT, FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t") + "\n")
	print("GLYPH_GALLERY_VERIFICATION " + JSON.stringify(report))
	host.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
