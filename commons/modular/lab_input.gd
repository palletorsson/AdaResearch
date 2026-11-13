extends Node3D
## A static research input from the shared prefab catalogue. Original geometry
## stays at authored scale; only its base is aligned to the recipe insertion point.
@export_storage var token := "" # Recursive recipes duplicate the source before it enters the tree.
@export_storage var fit_box := Vector3.ZERO # Optional centred structural envelope, in metres.
var original: Node3D
var source_scene := ""
static var _sources: Dictionary = {}

static func sources() -> Dictionary:
	if not _sources.is_empty(): return _sources
	var catalogue: Dictionary = {}
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/primitive-prefabs.json"))
	for entry in data.prefabs: catalogue[str(entry.id)] = entry
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/modular/lab.json"))
	for entry in spec.sources:
		var item: Dictionary = catalogue.get(str(entry.id), {}).duplicate(true)
		item.merge(entry, true)
		_sources[str(entry.id)] = item
	return _sources

func _ready() -> void:
	var spec: Dictionary = sources().get(token, {})
	source_scene = str(spec.get("scene", ""))
	if source_scene.is_empty() or not ResourceLoader.exists(source_scene):
		push_error("lab input has no original scene: " + token);return
	original = (load(source_scene) as PackedScene).instantiate() as Node3D
	original.name = "Original"
	if not spec.get("config", {}).is_empty():
		if original.has_method("apply_grid_config"): original.apply_grid_config(spec.config)
		else:
			push_error("lab input does not accept config: " + token);return
	add_child(original)
	var box: AABB = bounds(original, self)
	if box.size.length() < .0001:
		push_error("lab input has no synchronous geometry: " + token);return
	original.position.y -= box.position.y
	if fit_box != Vector3.ZERO:
		# Reuse the actual source meshes/materials, with an explicit static envelope.
		# Do not non-uniformly scale a RigidBody: its authored body is removed after
		# extracting the visual transforms. Static collision uses the same dimensions.
		var visual := Node3D.new();visual.name = "FittedVisual";add_child(visual)
		var measured: AABB = bounds(original,self)
		var orient := Basis.IDENTITY
		if measured.size.y < measured.size.x*.1 and measured.size.y < measured.size.z*.1:
			if fit_box.x < fit_box.y and fit_box.x < fit_box.z:orient=Basis(Vector3.BACK,PI/2)
			elif fit_box.z < fit_box.y and fit_box.z < fit_box.x:orient=Basis(Vector3.RIGHT,PI/2)
		var oriented: AABB = Transform3D(orient,Vector3.ZERO)*AABB(-measured.size/2,measured.size)
		var fit := fit_box / oriented.size
		for mesh in original.find_children("*","MeshInstance3D",true,false):
			var copy := MeshInstance3D.new();copy.mesh = mesh.mesh
			copy.material_override = mesh.material_override
			for surface in mesh.mesh.get_surface_count():copy.set_surface_override_material(surface,mesh.get_surface_override_material(surface))
			copy.transform = Transform3D(Basis.from_scale(fit)*orient,Vector3.ZERO) * Transform3D(Basis.IDENTITY,-measured.get_center()) * (global_transform.affine_inverse()*mesh.global_transform)
			visual.add_child(copy)
		original.free();original=visual
		var body := StaticBody3D.new();body.name="StructuralCollision";body.collision_layer=1;body.collision_mask=1
		var shape := CollisionShape3D.new();var cube := BoxShape3D.new();cube.size=fit_box;shape.shape=cube
		body.add_child(shape);add_child(body)
	# Preserve bodies/colliders as authored but prevent gravity and autonomous
	# animation from altering the arrangement used by the geometry preview.
	for body in original.find_children("*", "RigidBody3D", true, false): body.freeze = true
	if original is RigidBody3D: original.freeze = true
	for item in [original] + original.find_children("*", "Node", true, false):
		item.set_process(false);item.set_physics_process(false)
	set_meta("source_scene", source_scene)
	set_meta("prefab", token)

static func bounds(node: Node3D, frame: Node3D) -> AABB:
	var result := AABB();var first := true
	var meshes: Array = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D: meshes.append(node)
	for mesh in meshes:
		if mesh.mesh == null: continue
		var box: AABB = (frame.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		result = box if first else result.merge(box);first = false
	return result
