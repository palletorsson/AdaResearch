# ContactStudy.gd - two bodies come together as you come near, made four ways
#
# @identity
# essence: two standing bodies that approach each other as the visitor approaches them; the same meeting made as two meshes passing through each other, as a boolean cut, as a lattice of cells, and as one skin
# desire: the learner feels that how two forms meet is a decision of construction - and that there is a construction in which nearness itself has a shape
# critical_parameter: strategy - which construction makes the meeting (through / cut / cubes / skin); under it the reach of the join (k, baked) and how near the visitor must come
# triggers: the visitor's distance from a station moves its bodies; stepping back parts them again
# emerges: in SKIN a neck grows between the two before they touch; first one join, then a second with an opening left between - two bodies, one body, one body with a ring
# relationships: answers [[implicit_surface_modeling]] on the same floor, whose join "nothing meets"; the bodies come from the outline family of the black columns ([[resolution_totem]], alien); the CUT is the boolean floors' difference; CUBES is the lookup lattice
# truth: a mesh does not know another mesh is there - it passes through. A field knows how far away everything is, so two bodies can be one before they touch.
extends Node3D

## WHERE THIS COMES FROM. Palle, 22 November 2026, reading Alan Warburton's Goodbye Uncanny Valley (2017): "I see
## a potential here that is the future beyond the grotesque that is visual queer desire. Can you create that
## procedural geometry that touches and goes beyond in future beauty." The essay's wilderness holds the digital
## grotesque, where software shows its seams - "warped bodies intersect" - and couture graphics, speculative
## forms and surfaces. THROUGH is the first: what a mesh does with another mesh by default. SKIN is an answer
## that keeps its construction in view without mocking it: the two bodies' colours run into each other through
## the join, and the lines on it are the levels of the weight that mixes them.
##
## The forms are baked: tools/contact_forms.py marches the distance fields, bake_frames.gd makes frames/*.res.
## Nothing is computed while the game runs; a frame is a mesh, and the visitor's distance chooses the frame.

const FRAMES := "res://commons/artifacts/contact_study/frames/"
const SkinShader := preload("res://commons/artifacts/contact_study/contact_skin.gdshader")
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const ORDER: Array[String] = ["through", "cut", "cubes", "skin"]
const WORDS := {
	"through": ["01 / THROUGH", "two meshes, no operator"],
	"cut": ["02 / CUT", "A minus B"],
	"cubes": ["03 / CUBES", "the join in 5 cm cells"],
	"skin": ["04 / SKIN", "smooth union of A and B"],
}
const FINISH := {"through": 0, "cut": 1, "cubes": 2, "skin": 3}
const PLINTH := 0.14

## Which construction stands here: all four in a row, or one of them.
@export_enum("all", "through", "cut", "cubes", "skin") var strategy: String = "all"
## Metres between two stations of the row.
@export var spacing := 3.5
## The visitor's distance at which the two bodies stand furthest apart, and at which they are as close as they come.
@export var far := 4.8
@export var near := 1.6
## How fast the bodies follow, in whole approaches a second: they keep moving a moment after the visitor stops.
@export var follow := 0.55
@export var colour_a := Color("ff4f8b")
@export var colour_b := Color("3b5cff")
@export var plaques := true
## The row runs the other way: THROUGH at the +x end.
@export var mirror := false

var index := {}
var stations: Array[Dictionary] = []


## The floor's row config. The tower hands it over before the build (registry: configure_before_ready).
func apply_grid_config(config: Dictionary) -> void:
	for key in ["strategy", "spacing", "far", "near", "follow", "plaques", "mirror"]:
		if config.has(key): set(key, config[key])
	for key in ["colour_a", "colour_b"]:
		if config.has(key): set(key, Color.from_string(str(config[key]), get(key)))
	if is_node_ready():
		for station in stations: (station.root as Node).queue_free()
		stations.clear()
		_build()


func _ready() -> void:
	for key in ["strategy", "spacing", "far", "near", "follow", "plaques", "mirror"]:
		if has_meta("config_" + key): set(key, get_meta("config_" + key))
	for key in ["colour_a", "colour_b"]:
		if has_meta("config_" + key): set(key, Color.from_string(str(get_meta("config_" + key)), get(key)))
	_build()


func _build() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FRAMES + "index.json")) if FileAccess.file_exists(FRAMES + "index.json") else null
	if not parsed is Dictionary:
		push_warning("contact_study: no baked frames (run tools/contact_forms.py, then bake_frames.gd)")
		set_process(false)
		return
	index = parsed
	var names: Array[String] = ORDER if strategy == "all" else [strategy]
	for i in names.size():
		_station(names[i], Vector3((i - (names.size() - 1) * 0.5) * spacing * (-1.0 if mirror else 1.0), 0, 0))


func _material(finish: int) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SkinShader
	material.set_shader_parameter("finish", finish)
	material.set_shader_parameter("colour_a", Vector3(colour_a.r, colour_a.g, colour_a.b))
	material.set_shader_parameter("colour_b", Vector3(colour_b.r, colour_b.g, colour_b.b))
	return material


func _mesh(file: String) -> Mesh:
	var path := FRAMES + file + ".res"
	return load(path) as Mesh if ResourceLoader.exists(path) else null


func _station(kind: String, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = kind.capitalize()
	root.position = at
	add_child(root)
	Kit.block(root, Vector3(2.0, PLINTH, 1.05), Vector3(0.05, PLINTH * 0.5, 0), Color("15161a"), true)
	var bodies := Node3D.new()
	bodies.name = "Bodies"
	bodies.position.y = PLINTH
	root.add_child(bodies)
	var station := {"kind": kind, "root": root, "t": 0.0, "frame": -1, "meshes": [], "gaps": [], "rows": []}
	var material := _material(int(FINISH[kind]))
	if kind == "through":
		for part in ["body_a", "body_b"]:
			var body := MeshInstance3D.new()
			body.name = "A" if part == "body_a" else "B"
			body.mesh = _mesh(part)
			body.material_override = material
			bodies.add_child(body)
			if body.mesh != null: body.add_child(_wire(body.mesh))
		station["slides"] = bodies.get_node("B")
		var skin_rows: Array = index.frames.get("skin", [])
		station.gaps = [float(skin_rows.front().gap), float(skin_rows.back().gap)] if not skin_rows.is_empty() else [0.3, -0.12]
	else:
		var rows: Array = index.frames.get(kind, [])
		for row: Dictionary in rows:
			(station.meshes as Array).append(_mesh(str(row.file)))
			(station.gaps as Array).append(float(row.gap))
		station.rows = rows
		var form := MeshInstance3D.new()
		form.name = "Form"
		form.material_override = material
		bodies.add_child(form)
		station["form"] = form
		if kind == "cut":
			# what cut it: the other body, as a faint presence where it stands now
			var ghost := MeshInstance3D.new()
			ghost.name = "B"
			ghost.mesh = _mesh("body_b")
			var veil := StandardMaterial3D.new()
			veil.albedo_color = Color(colour_b.r, colour_b.g, colour_b.b, 0.16)
			veil.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			veil.cull_mode = BaseMaterial3D.CULL_BACK
			veil.rim_enabled = true
			veil.rim = 0.8
			veil.roughness = 0.3
			ghost.material_override = veil
			ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			bodies.add_child(ghost)
			station["slides"] = ghost
	# a body cannot be walked through, whatever made it
	var solid := StaticBody3D.new()
	solid.name = "Solid"
	var box := BoxShape3D.new()
	box.size = Vector3(1.25, 1.8, 0.5)
	var shape := CollisionShape3D.new()
	shape.shape = box
	solid.position = Vector3(0.0, PLINTH + 0.9, 0)
	solid.add_child(shape)
	root.add_child(solid)
	if plaques:
		# low on the plinth's front edge and leaning back: read from above when near, never in front of the bodies
		var lean := -PI / 3.0
		var plate := Kit.block(root, Vector3(0.86, 0.30, 0.02), Vector3(0.05, PLINTH + 0.085, 0.405), Color("1b1c21"), false)
		plate.rotation.x = lean
		var words := Label3D.new()
		words.name = "Plaque"
		words.position = plate.position + Vector3(0, 0.011, 0.006)
		words.rotation.x = lean
		words.font_size = 30
		words.pixel_size = 0.00135
		words.outline_size = 0
		words.modulate = Color("f2ece2")
		root.add_child(words)
		station["plaque"] = words
	stations.append(station)
	_show(station, true)


## The mesh's own triangles drawn as lines, a millimetre off the skin: the mesh as a mesh.
func _wire(mesh: Mesh) -> MeshInstance3D:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var seen := {}
	var lines := PackedVector3Array()
	for t in range(0, indices.size(), 3):
		for e in 3:
			var a := indices[t + e]
			var b := indices[t + (e + 1) % 3]
			var key := mini(a, b) * 1000003 + maxi(a, b)
			if seen.has(key): continue
			seen[key] = true
			lines.append(verts[a] + normals[a] * 0.0012)
			lines.append(verts[b] + normals[b] * 0.0012)
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = lines
	var wire := ArrayMesh.new()
	wire.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, out)
	var ink := StandardMaterial3D.new()
	ink.albedo_color = Color("26242b")
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var instance := MeshInstance3D.new()
	instance.name = "Wire"
	instance.mesh = wire
	instance.material_override = ink
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	for station in stations:
		var root: Node3D = station.root
		var away := Vector2(camera.global_position.x - root.global_position.x, camera.global_position.z - root.global_position.z).length()
		var wanted := clampf(inverse_lerp(far, near, away), 0.0, 1.0)
		var now := move_toward(float(station.t), wanted, delta * follow)
		if is_equal_approx(now, float(station.t)): continue
		station.t = now
		_show(station, false)


## Stand the station's bodies where its approach has got to.
func _show(station: Dictionary, always: bool) -> void:
	var t: float = station.t
	var gaps: Array = station.gaps
	var gap := 0.0
	if station.kind == "through":
		gap = lerpf(float(gaps[0]), float(gaps[1]), t)
		(station.slides as Node3D).position.x = gap
	else:
		var frame := clampi(int(round(t * (gaps.size() - 1))), 0, maxi(gaps.size() - 1, 0))
		if gaps.is_empty(): return
		gap = float(gaps[frame])
		if frame != int(station.frame) or always:
			station.frame = frame
			(station.form as MeshInstance3D).mesh = (station.meshes as Array)[frame]
		if station.has("slides"): (station.slides as Node3D).position.x = gap
	if not station.has("plaque"): return
	var lines: Array = WORDS[station.kind]
	var said := "gap %.2f m" % gap if gap > 0.0005 else ("touching" if absf(gap) <= 0.0005 else "overlap %.2f m" % -gap)
	if station.kind == "skin" and int(station.frame) >= 0:
		var row: Dictionary = (station.rows as Array)[int(station.frame)]
		var pieces := int(row.get("pieces", 1))
		var handles := int(row.get("handles", 0))
		said += "\n" + ("two bodies" if pieces >= 2 else ("one body" if handles == 0 else ("one body, one opening" if handles == 1 else "one body, %d openings" % handles)))
	(station.plaque as Label3D).text = "%s\n%s\n%s" % [lines[0], lines[1], said]
