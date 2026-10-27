extends Node3D
## Adapter from the shared modular grammar to the Void's editable-member contract.
## Only static recipes opt into this adapter. No engine/joint hierarchy is flattened.
const Composite = preload("res://commons/modular/composite.gd")
const Builder = preload("res://commons/modular/builder.gd")
var recipe := "lab_packed"
var bindings: Dictionary = {}
var part_defaults: Dictionary = {}
var saved_parts: Dictionary = {}
var only_parts: Array = []
var build_ms := 0.0
var recipe_document := ""

func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = config.has("recipe") or config.has("bindings") or config.has("recipe_document")
	recipe = str(config.get("recipe", recipe))
	recipe_document = str(config.get("recipe_document", recipe_document))
	bindings = config.get("bindings", bindings).duplicate(true)
	saved_parts = config.get("parts", {}).duplicate(true)
	only_parts = config.get("only_parts", []).duplicate()
	if is_inside_tree():
		if changed: rebuild()
		else: _apply_parts()

func _ready() -> void:
	rebuild()

func _tagged(node: Node) -> Array[Node3D]:
	var result: Array[Node3D] = []
	if node is Node3D and node.has_meta("part_id"):
		result.append(node)
		return result
	for child in node.get_children(): result.append_array(_tagged(child))
	return result

func rebuild() -> void:
	var started: int = Time.get_ticks_usec()
	for child in get_children(): child.free()
	part_defaults.clear()
	var definitions: Dictionary=Composite.terms()
	if not recipe_document.is_empty():
		if not recipe_document.begins_with("res://commons/void/trials/") or not recipe_document.ends_with("/recipe.json") or ".." in recipe_document:
			push_error("Invalid local recipe document");return
		var document: Variant=JSON.parse_string(FileAccess.get_file_as_string(recipe_document))
		if not document is Dictionary or not document.get("term") is Dictionary:
			push_error("Missing local recipe term");return
		definitions=definitions.duplicate()
		if document.get("terms") is Dictionary:definitions.merge(document.terms,true)
		definitions[recipe]=document.term
	# A copied member needs only its own source. In particular, do not start
	# asynchronous CSG work for discarded siblings and free it mid-build.
	if not only_parts.is_empty() and definitions.has(recipe):
		var definition: Dictionary=definitions[recipe]
		if definition.get("build",{}).get("op","")=="assemblage":
			definitions=definitions.duplicate(true)
			var selected: Array=[]
			for part in definitions[recipe].build.get("parts",[]):
				if str(part.get("id","")) in only_parts:selected.append(part)
			definitions[recipe].build.parts=selected
	var built: Node3D = Builder.build({"t":recipe,"with":bindings}, definitions)
	add_child(built) # original procedural prefabs build their real meshes at ready
	for node in _tagged(built):
		var local: Transform3D = global_transform.affine_inverse() * node.global_transform
		var member := Node3D.new()
		member.name = str(node.get_meta("part_id"))
		member.position = local.origin
		member.rotation = local.basis.orthonormalized().get_euler()
		add_child(member)
		node.reparent(member, false)
		node.transform = Transform3D(Basis.from_scale(local.basis.get_scale()), Vector3.ZERO)
		node.name = "Source"
		# Miniatures are visual studies; architecture blocks the walker. The crate
		# source has no body, so explicitly add a static fitted lab box, not physics
		# attributed to the original prefab. Keep source vertices untouched.
		if node.has_meta("prefab"):
			var size: float = local.basis.get_scale().x
			if str(node.get_meta("prefab")) == "crate" and size >= .5:
				var crate: Node3D = node.original if node.get("original") != null else node
				var body := StaticBody3D.new();body.name = "LabStaticCollider"
				var shape := CollisionShape3D.new();var box := BoxShape3D.new()
				box.size = Vector3(crate.crate_width,crate.crate_height,crate.crate_depth)
				shape.shape = box;shape.position.y = crate.crate_height / 2
				body.add_child(shape);node.add_child(body)
			if size < .5:
				for item in node.find_children("*","CollisionObject3D",true,false):
					item.collision_layer = 0;item.collision_mask = 0
		var box: AABB = _bounds(member)
		part_defaults[str(member.name)] = {"position":[member.position.x,member.position.y,member.position.z],"rotation":[member.rotation_degrees.x,member.rotation_degrees.y,member.rotation_degrees.z],"bounds":[box.position.x,box.position.y,box.position.z,box.size.x,box.size.y,box.size.z]}
	built.free()
	_apply_parts()
	build_ms = (Time.get_ticks_usec() - started) / 1000.0

func _bounds(node: Node3D) -> AABB:
	var result := AABB();var first := true
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh == null: continue
		var box: AABB = (node.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		result = box if first else result.merge(box);first = false
	return result

func _apply_parts() -> void:
	for child in get_children():
		var key: String = str(child.name)
		if not only_parts.is_empty() and key not in only_parts:
			child.free();part_defaults.erase(key);continue
		var pose: Dictionary = saved_parts.get(key, {})
		if pose.has("position"): child.position = Vector3(pose.position[0],pose.position[1],pose.position[2])
		if pose.has("rotation"): child.rotation_degrees = Vector3(pose.rotation[0],pose.rotation[1],pose.rotation[2])

func prepare_editor_preview() -> void:
	for member in get_children():
		for source in member.get_children():
			if source.has_method("prepare_editor_preview"):await source.prepare_editor_preview()
		if part_defaults.has(str(member.name)):
			var box: AABB=_bounds(member)
			part_defaults[str(member.name)]["bounds"]=[box.position.x,box.position.y,box.position.z,box.size.x,box.size.y,box.size.z]
	await get_tree().process_frame
