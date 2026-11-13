extends Node3D
## ISOSURFACE PREFABS: twenty construction pieces made with booleans on distance fields (the boolean floor,
## Boolean_Verbs, 2026-11-13). Palle: "We have prefabs but boolean surfaces creates new principal opportunities ...
## Can you make 20 new prefabs using iso surfaces? ... I mean in the boolean floor."
##
## The tower's kit is primitives and their associations - cubes, wedges, planks, panels, barriers, drums - every piece
## convex or a stack of convex parts. Nothing in it has a hole a body can walk through, a hollow that keeps a ball, a
## curved deck or a stair the tower's walker can climb. Booleans on distance fields make those, and the hall that
## introduces the verbs says so itself: its small exhibits "have not enabled collision ... Keep that difference with you
## when the objects become architecture." These are that architecture; each one has collision a body and a ball meet.
##
##   DIFFERENCE   tunnel, crossing, thresholds, sieve, dome, basin, gutter_ramp, mould   (a cut opens or hollows)
##   INTERSECTION cast, hump_bridge, die, gyroid_screen                                   (keep what is shared)
##   UNION        stile, mound, stones, pipe_tee                                          (melt, join, then bore)
##   FIELD        spiral_ramp, funnel, chute, boulder                                     (twist, revolve, sweep, noise)
##   CARVINGS     carved_walk, carved_spiral, carved_branches, carved_perlin, carved_grid, carved_sphere
##
## The carvings are the Random Boolean Carving (algorithms/proceduralgeneration/constraint_solvers/randomboolean,
## Palle: "they use sine and random etc to carve in a space in cubes"): its demo's six carvings - a cube minus faceted
## spheres along a random walk, a sine spiral, a trunk and branches, a sine-steered path, a grid of tunnels, and a sphere
## minus a spiral - at 0.28 of their size, with the walk that carved them drawn as the demo draws it, an orange line.
##
## What two convex shapes share is convex, so the cast and the die are rigid bodies (a convex hull) that roll and land;
## everything a difference made is concave and stands still (a static concave mesh). That is the physics engine's rule
## and the verb's, at once.
##
## `finish` (one shader, iso_prefab.gdshader, reading vertex colour as data - where each face came from and how open the
## air round it is): provenance paints a cut orange (the hall's CUT_COLOR), a trim sea-green, a smooth union's band
## yellow (the hall: "we could make the new faces announce another origin"); satin is the Random Boolean Carving's own
## material (0.7 0.7 0.8, metallic 0.3, roughness 0.7, its demo's SSAO stood in for by baked occlusion; the inside of a cut
## a little warmer); cast is one pale material.
##
## Geometry: tools/iso_prefabs.py (the expressions, their checks, the march) -> bake_forms.gd -> forms/<form>.res.
## Walked in the tower by tools/probes/iso_prefabs_walk.gd.
const FORMS_DIR := "res://commons/artifacts/iso_prefabs/forms/"
const FORMS := ["tunnel", "crossing", "thresholds", "sieve", "dome", "basin", "gutter_ramp", "mould", "cast", "hump_bridge", "die", "gyroid_screen", "stile", "mound", "stones", "pipe_tee", "spiral_ramp", "funnel", "chute", "boulder", "carved_walk", "carved_spiral", "carved_branches", "carved_perlin", "carved_grid", "carved_sphere"]
const FINISHES := ["provenance", "satin", "cast"]
const SHADER := preload("res://commons/artifacts/iso_prefabs/iso_prefab.gdshader")
const PATH_COLOUR := Color(1, 0.5, 0)                 # advanced_carver.gd path_line_color

@export_enum("tunnel", "crossing", "thresholds", "sieve", "dome", "basin", "gutter_ramp", "mould", "cast", "hump_bridge", "die", "gyroid_screen", "stile", "mound", "stones", "pipe_tee", "spiral_ramp", "funnel", "chute", "boulder", "carved_walk", "carved_spiral", "carved_branches", "carved_perlin", "carved_grid", "carved_sphere") var form := "tunnel"
@export_enum("provenance", "satin", "cast") var finish := "provenance"
## A carving's path drawn as its demo draws it (an orange line); Grid Tunnels has none, as in the demo.
@export var path_line := true
## The body (mesh, collision, path line) turned about y in quarter turns, the plaque left in front: a carving can show its
## most-carved face to the visitor and stay exactly the demo's object. (Not `turn`: that is a fit strategy's id.)
@export var body_turn := 0
## A small lectern beside the piece with its name, its expression and what it makes possible (the boolean floor's
## samples carry one; a piece placed as part of a work does not).
@export var plaque := false
## A rigid form (cast, die) held where it was put until something takes it.
@export var frozen := false

static var _materials := {}
var _body: CollisionObject3D
var _mesh: MeshInstance3D
var _sign: Node3D
var _line: Node3D
var _built := ""


func _ready() -> void:
	for key in ["form", "finish", "plaque", "frozen", "path_line", "body_turn"]:
		if has_meta("config_" + key): _take({key: get_meta("config_" + key)})
	_build()


func _take(config_data: Dictionary) -> void:
	if config_data.has("form") and str(config_data["form"]) in FORMS: form = str(config_data["form"])
	if config_data.has("finish") and str(config_data["finish"]) in FINISHES: finish = str(config_data["finish"])
	if config_data.has("path_line"): path_line = str(config_data["path_line"]).to_lower() in ["true", "1", "1.0", "on", "yes"]
	if config_data.has("body_turn"): body_turn = posmod(roundi(float(str(config_data["body_turn"])) / 90.0) * 90, 360)
	if config_data.has("plaque"): plaque = str(config_data["plaque"]).to_lower() in ["true", "1", "1.0", "on", "yes"]
	if config_data.has("frozen"): frozen = str(config_data["frozen"]).to_lower() in ["true", "1", "1.0", "on", "yes"]


func apply_grid_config(config_data: Dictionary) -> void:
	_take(config_data)
	if is_inside_tree(): _build()


func _build() -> void:
	var key := "%s|%s|%s|%s|%s|%s" % [form, finish, plaque, frozen, path_line, body_turn]
	if key == _built: return
	var mesh := load(FORMS_DIR + form + ".res") as ArrayMesh
	if mesh == null:
		push_warning("iso_prefab: no baked mesh for %s (run tools/iso_prefabs.py export, then bake_forms.gd)" % form)
		return
	if _built.get_slice("|", 0) != form or _body == null:
		_build_body(mesh)
	_mesh.material_override = _material(finish)
	if _body is StaticBody3D: _body.rotation_degrees.y = float(body_turn)
	if _sign != null:
		_sign.queue_free()
		_sign = null
	if plaque: _sign = _build_plaque(mesh)
	if _line != null:
		_line.queue_free()
		_line = null
	if path_line and bool(mesh.get_meta("line", false)): _line = _build_path_line(mesh)
	if _body is RigidBody3D: (_body as RigidBody3D).freeze = frozen
	_built = key


func _build_body(mesh: ArrayMesh) -> void:
	if _body != null:
		_body.queue_free()
	var rigid := bool(mesh.get_meta("rigid", false))
	var shape: Shape3D
	if rigid:
		var body := RigidBody3D.new()
		body.mass = float(mesh.get_meta("mass", 5.0))
		var stuff := PhysicsMaterial.new()
		stuff.friction = 0.8
		stuff.bounce = 0.15
		body.physics_material_override = stuff
		body.continuous_cd = true
		# the engine's automatic centre of mass is the shape's origin - here the form's lowest point, which loads a die
		body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		body.center_of_mass = mesh.get_meta("centroid", Vector3.ZERO)
		var hull := ConvexPolygonShape3D.new()
		hull.points = mesh.get_meta("hull_points", PackedVector3Array())
		shape = hull
		_body = body
	else:
		var faces := ConcavePolygonShape3D.new()
		faces.backface_collision = true                # thin shells (3 - 4 cm) are met from both sides
		faces.set_faces(mesh.get_meta("collision_faces", PackedVector3Array()))
		shape = faces
		_body = StaticBody3D.new()
	_body.name = "IsoBody"
	_body.set_meta("iso_form", form)
	var holder := CollisionShape3D.new()
	holder.shape = shape
	_body.add_child(holder)
	_mesh = MeshInstance3D.new()
	_mesh.name = "IsoMesh"
	_mesh.mesh = mesh
	_body.add_child(_mesh)
	add_child(_body)


## One shared material per finish (every placed piece of a finish batches with the others).
func _material(which: String) -> ShaderMaterial:
	if _materials.has(which): return _materials[which]
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("finish", maxi(0, FINISHES.find(which)))
	_materials[which] = m
	return m


## The walk that carved a carving, drawn as its demo draws it - orange, unlit - as thin tubes (a one-pixel line
## shimmers in a headset), one per segment, all in one MultiMesh.
func _build_path_line(mesh: ArrayMesh) -> Node3D:
	var segments := []
	for path in mesh.get_meta("paths", []):
		var line: PackedVector3Array = path
		for i in line.size() - 1: segments.append([line[i], line[i + 1]])
	if segments.is_empty(): return null
	var tube := CylinderMesh.new()
	tube.top_radius = 0.011
	tube.bottom_radius = 0.011
	tube.height = 1.0
	tube.radial_segments = 6
	tube.rings = 1
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = tube
	many.instance_count = segments.size()
	for i in segments.size():
		var a: Vector3 = segments[i][0]
		var b: Vector3 = segments[i][1]
		var along := b - a
		var up := along.normalized() if along.length() > 1e-5 else Vector3.UP
		var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		var basis := Basis(side, up * maxf(along.length(), 0.001), side.cross(up).normalized())
		many.set_instance_transform(i, Transform3D(basis, (a + b) * 0.5))
	var holder := MultiMeshInstance3D.new()
	holder.name = "IsoPath"
	holder.multimesh = many
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = PATH_COLOUR
	holder.material_override = paint
	holder.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(_body if _body != null else self).add_child(holder)
	return holder


## A lectern at the piece's south-west corner, turned to a visitor coming from the south.
func _build_plaque(mesh: ArrayMesh) -> Node3D:
	var box: Array = mesh.get_meta("aabb", [[-0.5, 0, -0.5], [0.5, 1, 0.5]])
	var stand := Node3D.new()
	stand.name = "IsoPlaque"
	stand.position = Vector3(float(box[0][0]) + 0.5, 0, float(box[1][2]) + 0.55)
	add_child(stand)
	var post := MeshInstance3D.new()
	var rod := BoxMesh.new()
	rod.size = Vector3(0.06, 0.82, 0.06)
	post.mesh = rod
	post.position = Vector3(0, 0.41, 0)
	post.material_override = _material("cast")
	stand.add_child(post)
	var panel := MeshInstance3D.new()
	var face := BoxMesh.new()
	face.size = Vector3(1.0, 0.56, 0.03)
	panel.mesh = face
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	panel.material_override = dark
	panel.position = Vector3(0, 0.9, 0)
	panel.rotation.x = -0.6
	stand.add_child(panel)
	var lines := [
		[str(mesh.get_meta("title", form)).to_upper(), 46, Color(1, 1, 1), 0.17],
		[str(mesh.get_meta("expression", "")), 28, Color(1.0, 0.72, 0.5), 0.07],
		[str(mesh.get_meta("principle", "")), 24, Color(0.85, 0.9, 0.96), -0.1]]
	for line in lines:
		var label := Label3D.new()
		label.text = line[0]
		label.font_size = line[1]
		label.pixel_size = 0.0016
		label.modulate = line[2]
		label.outline_size = 4
		label.outline_modulate = Color(0, 0, 0, 1)
		label.width = 560
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.position = Vector3(0, float(line[3]), 0.02)
		panel.add_child(label)
	return stand


## ---- for a test ----

func state() -> Dictionary:
	var mesh: ArrayMesh = _mesh.mesh if _mesh != null else null
	return {"form": form, "finish": finish, "rigid": _body is RigidBody3D, "frozen": frozen,
		"triangles": (mesh.surface_get_array_index_len(0) / 3) if mesh != null else 0,
		"collision_triangles": (mesh.get_meta("collision_faces", PackedVector3Array()) as PackedVector3Array).size() / 3 if mesh != null else 0,
		"body_at": _body.global_position if _body != null else Vector3.ZERO,
		"title": str(mesh.get_meta("title", "")) if mesh != null else "", "expression": str(mesh.get_meta("expression", "")) if mesh != null else ""}


func body() -> CollisionObject3D:
	return _body
