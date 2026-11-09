extends RefCounted
## FITTING A WORK TO THE TOWER (Palle, 2026-11-09: "Many works have a floor and walls of their own and they have to be
## removed. In many cases if a wall is needed we can use tower elements or the playground. In the end it is about
## conveying an idea."). floor_content.gd calls apply() for a placement whose config has "fit"; a placement without the
## key is never touched. The "fit" record also documents which strategies were used, so the catalog
## (commons/void/fit_strategies.json, tools/void_fit.py) can learn from the tower itself.
##   "strip": ["floor", "walls", "ceiling"]   parts found by SHAPE, relative to the work's own box:
##        floor    flat (< 0.25 m), at the base (within 0.35 m of the slab), covering >= 2 m2 and >= 25 % of the work
##        walls    upright and thin (< 0.4 m), >= 1.8 m tall, >= 2.5 m long, standing on the work's perimeter
##        ceiling  flat, >= 2 m2, its underside >= 2.2 m above the slab
##   A part that wears a ShaderMaterial is never stripped by shape: in a shader work the floor or wall IS the idea.
##   "strip_parts": ["GroundPlane", "Walls/*"]  parts found by NAME (a node name, or a path glob below the artifact)
##   "keep_parts": [...]                        never stripped, whatever the shape says
##   "set": {"num_layers": 5}                   the work's own exported settings, set before it builds (before_ready)
## A stripped part is not drawn (layers = 0: its children stay) and no longer collides (the shapes of the body it is,
## sits in or carries are disabled). Applied again a second later for works that build after _ready.
const NAMES := ["fit_floor", "fit_walls", "fit_ceiling"]

## Before the work builds: "set": {property: value} - the work's own exported settings (fewer layers, fewer feature
## maps, a smaller grid: REDUCE REPEATS). Each value is converted to the property's own type first, because a typed
## property refuses a value of the wrong type in silence; what could not be set is kept in meta fit_rejected.
static func before_ready(artifact: Node, fit: Variant) -> void:
	if not (fit is Dictionary) or not (fit as Dictionary).has("set"): return
	var rejected := []
	for key in (fit as Dictionary).set:
		var name := str(key)
		if not (name in artifact):
			rejected.append(name); continue
		var current: Variant = artifact.get(name)
		var value: Variant = (fit as Dictionary).set[key]
		match typeof(current):
			TYPE_INT: value = int(value)
			TYPE_FLOAT: value = float(value)
			TYPE_BOOL: value = str(value).to_lower() in ["true", "1", "on", "yes"]
			TYPE_STRING: value = str(value)
			TYPE_VECTOR3: if value is Array and (value as Array).size() == 3: value = Vector3(float(value[0]), float(value[1]), float(value[2]))
			TYPE_VECTOR2: if value is Array and (value as Array).size() == 2: value = Vector2(float(value[0]), float(value[1]))
			TYPE_ARRAY:
				# a typed array (Array[int]) refuses a plain one: rebuild it with the element type
				if (current as Array).is_typed() and value is Array:
					var typed: Array = (current as Array).duplicate(); typed.clear()
					for v in value: typed.append(type_convert(v, (current as Array).get_typed_builtin()))
					value = typed
		artifact.set(name, value)
		if artifact.get(name) != value: rejected.append(name)
	if not rejected.is_empty(): artifact.set_meta("fit_rejected", rejected)

static func apply(mount: Node3D, artifact: Node3D, fit: Variant, config: Dictionary) -> void:
	if not (fit is Dictionary): return
	var settings: Dictionary = fit
	strip(mount, artifact, settings)
	if artifact.is_inside_tree():
		artifact.get_tree().create_timer(1.0).timeout.connect(func(): if is_instance_valid(artifact): strip(mount, artifact, settings))

## Returns the stripped parts as {path: role}.
static func strip(mount: Node3D, artifact: Node3D, settings: Dictionary) -> Dictionary:
	var roles: Array = settings.get("strip", [])
	var names: Array = settings.get("strip_parts", [])
	var keep: Array = settings.get("keep_parts", [])
	if roles.is_empty() and names.is_empty(): return {}
	var meshes: Array = []
	for node in artifact.find_children("*", "GeometryInstance3D", true, false):
		var g := node as GeometryInstance3D
		if g is MeshInstance3D and (g as MeshInstance3D).mesh != null and g.get_viewport() == artifact.get_viewport():
			meshes.append(g)
	# the slab: the mount stands at the placement's height above its floor root
	var level := mount.global_position.y - mount.position.y
	# the work's own box, from its meshes
	var whole := AABB(); var first := true
	var boxes := {}
	for g: MeshInstance3D in meshes:
		var b := g.global_transform * g.mesh.get_aabb()
		boxes[g] = b
		if g.layers == 0: continue
		whole = b if first else whole.merge(b); first = false
	var done := {}
	var area := maxf(whole.size.x * whole.size.z, .01)
	for g: MeshInstance3D in meshes:
		var path := str(artifact.get_path_to(g))
		if _matches(g, path, keep): continue
		var role := ""
		if _matches(g, path, names): role = "named"
		elif _wears_shader(g): continue   # a part that wears a shader is the idea, not the room: only by name
		else:
			var b: AABB = boxes[g]
			var flat := b.size.y < .25
			var footprint := b.size.x * b.size.z
			if "floor" in roles and flat and absf(b.position.y - level) < .35 and footprint >= 2.0 and footprint >= .25 * area: role = "floor"
			elif "ceiling" in roles and flat and footprint >= 2.0 and b.position.y - level >= 2.2: role = "ceiling"
			elif "walls" in roles and b.size.y >= 1.8 and minf(b.size.x, b.size.z) < .4 and maxf(b.size.x, b.size.z) >= 2.5:
				var edge := minf(minf(absf(b.position.x - whole.position.x), absf(whole.end.x - b.end.x)), minf(absf(b.position.z - whole.position.z), absf(whole.end.z - b.end.z)))
				if edge < .6: role = "walls"
		if role == "": continue
		g.layers = 0
		g.set_meta("fit_stripped", role)
		_disable_collision(g)
		done[path] = role
	return done

static func _wears_shader(g: MeshInstance3D) -> bool:
	if g.material_override is ShaderMaterial: return true
	for i in g.get_surface_override_material_count():
		if g.get_surface_override_material(i) is ShaderMaterial: return true
	if g.mesh != null:
		for i in g.mesh.get_surface_count():
			if g.mesh.surface_get_material(i) is ShaderMaterial: return true
	return false

static func _matches(g: Node, path: String, patterns: Array) -> bool:
	for p in patterns:
		var s := str(p)
		if s == str(g.name) or path == s or path.match(s) or str(g.name).match(s): return true
	return false

## The collision that belongs to a stripped mesh: bodies below it (create_trimesh_collision makes them), and the body
## it sits in when that body draws nothing else.
static func _disable_collision(g: MeshInstance3D) -> void:
	for body in g.find_children("*", "CollisionObject3D", true, false):
		_off(body)
	var parent := g.get_parent()
	if parent is CollisionObject3D:
		var others := parent.find_children("*", "GeometryInstance3D", true, false).filter(func(n): return n != g and (n as GeometryInstance3D).layers != 0)
		if others.is_empty(): _off(parent)

static func _off(body: Node) -> void:
	for shape in body.find_children("*", "CollisionShape3D", true, false):
		(shape as CollisionShape3D).set_deferred("disabled", true)
	for shape in body.find_children("*", "CollisionPolygon3D", true, false):
		(shape as CollisionPolygon3D).set_deferred("disabled", true)
