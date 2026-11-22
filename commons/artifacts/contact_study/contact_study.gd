# ContactStudy.gd - two bodies come together as you come near, made five ways; and a floor of versions
#
# @identity
# essence: two standing bodies that approach each other as the visitor approaches them; the same meeting made as two meshes passing through each other, as a boolean cut, as a lattice of cells, as one skin, and as that skin kept inside another form; and, as a FIELD, one version for every place on the floor
# desire: the learner feels that how two forms meet is a decision of construction - and that there is a construction in which nearness itself has a shape
# critical_parameter: strategy - which construction makes the meeting (through / cut / cubes / skin / inside), or field, or within (the two heads as a room one walks through); under it the reach of the join (k) and the distance between the two
# triggers: the visitor's distance from a station moves its bodies; in the field nothing moves - the walk is the approach, and the place is the version
# emerges: in SKIN a neck grows between the two before they touch; first one join, then a second with an opening left between. In the FIELD a line runs across the ground: on one side every pair is two bodies, on the other one
# relationships: answers [[implicit_surface_modeling]] on the same floor, whose join "nothing meets"; the bodies come from the outline family of the black columns ([[resolution_totem]], alien); position as parameter is the colour floor's rule ([[pillarcolorcollection]]: hue across, saturation along) - here reach across, distance along
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
## Then: "very nice can we make them larger for more impact, fill the floor with versions. Then can we control the
## marching cubes to come inside any form?" So: `size`; INSIDE, the join kept inside another form, whose cut shows
## the field itself in rings; and FIELD, where a version stands at every place its floor has room for and the place
## gives the version - reach across the floor, distance along it - with the lines on the ground where two bodies
## become one and where the first opening appears.
##
## Then: "good can we go inside these forms?" At their own size nobody fits inside. So WITHIN: the place where the
## two heads meet, made again at nine times the size as a room - the wall is the same field between the skin and
## 14 cm under it, the floor cuts it level, and there is a door in each body. One walks in through one body,
## through the doorway where the two are one, and out through the other.
##
## Then: "can you make a big church room with different size forms forming a sub space like the st peter
## cathedral. Like we are inside a Bernini sculpture." A storey is 5.64 m high, so a tall room stands on a side
## slab, where the sky is open. CHURCH: five bodies of the same family, drawn as rooms and of different sizes
## (11.5 to 17.5 m tall), in a row along a nave; where two overlap the smooth union is the arch between them. Each
## bay is the inside of one body - a foot, a waist overhead, a swelling above it, a tip with an oculus. Under the
## tallest stands a canopy: four of the row's own bodies, leaning in until their heads join in a ring. In the last
## bay the pair itself stands at the size it has in the row: the room around it is its own inside.
##
## The forms are baked: tools/contact_forms.py marches the distance fields, bake_frames.gd makes frames/*.res.
## Nothing is computed while the game runs; a frame is a mesh, and the visitor's distance chooses the frame.

const FRAMES := "res://commons/artifacts/contact_study/frames/"
const SkinShader := preload("res://commons/artifacts/contact_study/contact_skin.gdshader")
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const ORDER: Array[String] = ["through", "cut", "cubes", "skin", "inside"]
const WORDS := {
	"through": ["01 / THROUGH", "two meshes, no operator"],
	"cut": ["02 / CUT", "A minus B"],
	"cubes": ["03 / CUBES", "the join in 5 cm cells"],
	"skin": ["04 / SKIN", "smooth union of A and B"],
	"inside": ["05 / INSIDE", "the join, kept inside a diamond"],
}
const FINISH := {"through": 0, "cut": 1, "cubes": 2, "skin": 3, "inside": 4}
const PLINTH := 0.14

## Which construction stands here: the five in a row, one of them, the field of versions, or the room.
@export_enum("all", "through", "cut", "cubes", "skin", "inside", "field", "within", "church") var strategy: String = "all"
## The bodies' scale: 1 is a body of 1.78 m.
@export var size := 1.0
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
var stations: Array[Dictionary] = []        # the ones that move
var versions: Array[Dictionary] = []        # the field: each stands still
var within := {}                            # the room: its bake row, its form, its walls
var church := {}                            # the church: its bake row, its form, its walls, the canopy, the pair
var _loading: Array[Dictionary] = []


## The floor's row config. The tower hands it over before the build (registry: configure_before_ready).
func apply_grid_config(config: Dictionary) -> void:
	for key in ["strategy", "size", "spacing", "far", "near", "follow", "plaques", "mirror"]:
		if config.has(key): set(key, config[key])
	for key in ["colour_a", "colour_b"]:
		if config.has(key): set(key, Color.from_string(str(config[key]), get(key)))
	if is_node_ready():
		for child in get_children(): child.queue_free()
		stations.clear()
		versions.clear()
		within.clear()
		church.clear()
		_loading.clear()
		_build()


func _ready() -> void:
	for key in ["strategy", "size", "spacing", "far", "near", "follow", "plaques", "mirror"]:
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
	if strategy == "field":
		_field()
		return
	if strategy == "within":
		_within()
		return
	if strategy == "church":
		_church()
		return
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


## What every station has: its ground, a place for the bodies, a box nobody walks through, and its plaque.
func _stand(title: String, at: Vector3) -> Dictionary:
	var root := Node3D.new()
	root.name = title
	root.position = at
	root.scale = Vector3.ONE * size
	add_child(root)
	Kit.block(root, Vector3(2.0, PLINTH, 1.05), Vector3(0.05, PLINTH * 0.5, 0), Color("15161a"), true)
	var bodies := Node3D.new()
	bodies.name = "Bodies"
	bodies.position.y = PLINTH
	root.add_child(bodies)
	var solid := StaticBody3D.new()
	solid.name = "Solid"
	var box := BoxShape3D.new()
	box.size = Vector3(1.25, 1.8, 0.5)
	var shape := CollisionShape3D.new()
	shape.shape = box
	solid.position = Vector3(0.0, PLINTH + 0.9, 0)
	solid.add_child(shape)
	root.add_child(solid)
	var made := {"root": root, "bodies": bodies}
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
		made["plaque"] = words
	return made


func _station(kind: String, at: Vector3) -> void:
	var station := _stand(kind.capitalize(), at)
	station.merge({"kind": kind, "t": 0.0, "frame": -1, "meshes": [], "gaps": [], "rows": []})
	var bodies: Node3D = station.bodies
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
		if kind == "inside":
			# the form the join is kept inside, as its edges
			var inside: Dictionary = index.get("inside", {})
			var frame := _edges(_diamond(float(inside.get("radius", 0.86))))
			frame.name = "Container"
			bodies.add_child(frame)
			station["container"] = frame
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
	return _edges(lines)


func _diamond(radius: float) -> PackedVector3Array:
	var tips: Array[Vector3] = [Vector3.UP, Vector3.DOWN, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT, Vector3.FORWARD]
	var lines := PackedVector3Array()
	for i in 4:
		for pair in [[0, 2 + i], [1, 2 + i], [2 + i, 2 + (i + 1) % 4]]:
			lines.append(tips[pair[0]] * radius)
			lines.append(tips[pair[1]] * radius)
	return lines


func _edges(lines: PackedVector3Array) -> MeshInstance3D:
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


func _state_words(pieces: int, openings: int) -> String:
	if pieces >= 2: return "two bodies"
	return "one body" if openings == 0 else ("one body, one opening" if openings == 1 else "one body, %d openings" % openings)


func _gap_words(gap: float) -> String:
	return "gap %.2f m" % gap if gap > 0.0005 else ("touching" if absf(gap) <= 0.0005 else "overlap %.2f m" % -gap)


# ------------------------------------------------------------------------------------------------ the field

## A version at every place the bake names: this node stands at the floor's own origin, so a place is the
## floor's own metres. The meshes arrive over the next frames, so a floor that streams in does not stall on them.
func _field() -> void:
	var material := _material(3)
	for row: Dictionary in index.get("field", []):
		var made := _stand("Version_%s" % str(row.file).trim_prefix("field_"), Vector3(float(row.x), 0, float(row.z)))
		var form := MeshInstance3D.new()
		form.name = "Form"
		form.material_override = material
		(made.bodies as Node3D).add_child(form)
		made.merge({"row": row, "form": form})
		if made.has("plaque"):
			(made.plaque as Label3D).text = "REACH %.2f\n%s\n%s" % [float(row.reach), _gap_words(float(row.gap)), _state_words(int(row.pieces), int(row.handles))]
		versions.append(made)
		var path := FRAMES + str(row.file) + ".res"
		if ResourceLoader.exists(path) and ResourceLoader.load_threaded_request(path) == OK:
			_loading.append({"path": path, "form": form})
	var lines: Dictionary = index.get("lines", {})
	_ground_line("OneBody", lines.get("one_body", []), Color("f3e6ff"), "ONE BODY", "TWO BODIES")
	_ground_line("AnOpening", lines.get("an_opening", []), Color("ff6fa5"), "AN OPENING", "")
	var rule: Dictionary = index.get("field_rule", {})
	if not rule.is_empty():
		var words := Kit.label(self, "REACH %.2f in the west to %.2f in the east   /   NEARER to the north" % [float(rule.reach[0]), float(rule.reach[1])], Vector3(0, 0.02, 6.55), 0.0024)
		words.rotation.x = -PI / 2.0
		words.modulate = Color("f2ece2")


## A line on the ground through the bake's points, and what lies on each side of it (north is nearer).
func _ground_line(title: String, stretches: Array, colour: Color, north: String, south: String) -> void:
	var verts := PackedVector3Array()
	var indices := PackedInt32Array()
	for stretch: Array in stretches:
		for i in range(1, stretch.size()):
			var a := Vector3(float(stretch[i - 1][0]), 0.014, float(stretch[i - 1][1]))
			var b := Vector3(float(stretch[i][0]), 0.014, float(stretch[i][1]))
			var side := (b - a).cross(Vector3.UP).normalized() * 0.035
			var base := verts.size()
			verts.append_array(PackedVector3Array([a - side, a + side, b + side, b - side]))
			indices.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3, base, base + 2, base + 1, base, base + 3, base + 2]))
		if stretch.size() < 2: continue
		var at := Vector3(float(stretch[1][0]), 0.02, float(stretch[1][1]))
		for words in [[north, -0.42], [south, 0.42]]:
			if str(words[0]) == "": continue
			var label := Kit.label(self, str(words[0]), at + Vector3(0, 0, float(words[1])), 0.0022)
			label.rotation.x = -PI / 2.0
			label.modulate = colour
	if verts.is_empty(): return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = colour
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var line := MeshInstance3D.new()
	line.name = title
	line.mesh = mesh
	line.material_override = paint
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(line)


# ------------------------------------------------------------------------------------------------ within

## The two heads where they meet, as a room. This node stands at the middle of the two, on the floor; A's door is
## at -x and B's at +x, and the line through both doors runs through the doorway where the two are one. `size`
## should be the size the room was baked for: the wall's thickness and the doors were measured at it.
func _within() -> void:
	var row: Dictionary = index.get("within", {})
	var path := FRAMES + str(row.get("file", "within")) + ".res"
	if row.is_empty() or not ResourceLoader.exists(path):
		push_warning("contact_study: no baked room (run tools/contact_forms.py within, then bake_frames.gd)")
		return
	var form := MeshInstance3D.new()
	form.name = "Form"
	form.material_override = _material(5)
	form.scale = Vector3.ONE * size
	add_child(form)
	within = {"row": row, "form": form}
	_arrives(path, form, _solid.bind(size, within, "walls", Vector3.ZERO))
	if not plaques: return
	var times := float(row.get("size", size))
	var wall_cm := int(round(float(row.get("wall", 0.14)) * 100.0))
	within["plaques"] = [
		_plate(Vector3(float(row.get("west_door_x", -3.2)) * size / times - 0.75, 0, 1.45), -PI / 2.0,
			"06 / WITHIN\nthe two heads, %d times the size\nin through one body, out through the other" % int(round(times))),
		_plate(Vector3(float(row.get("east_door_x", 3.2)) * size / times + 0.75, 0, 1.45), PI / 2.0,
			"06 / WITHIN\nthe wall is the form, %d cm under its skin\nthe doorway inside is where the two are one" % wall_cm),
	]


## A baked form arrives over the next frames, so a floor that streams in does not stall on it; `then` gets the mesh.
func _arrives(path: String, form: MeshInstance3D, then: Callable) -> void:
	if ResourceLoader.load_threaded_request(path) == OK:
		_loading.append({"path": path, "form": form, "then": then})
	else:
		form.mesh = load(path) as Mesh
		then.call(form.mesh)


## A form as something a body cannot pass, from either side: its own triangles at the size and place it stands.
## `record[key]` gets the body, so a probe can ask for it.
func _solid(mesh: Mesh, scale_by: float, record: Dictionary, key: String, at: Vector3) -> void:
	if mesh == null or record.is_empty(): return
	var faces := mesh.get_faces()
	for i in faces.size(): faces[i] *= scale_by
	var walls := ConcavePolygonShape3D.new()
	walls.backface_collision = true
	walls.set_faces(faces)
	var shape := CollisionShape3D.new()
	shape.shape = walls
	var solid := StaticBody3D.new()
	solid.name = key.capitalize().replace(" ", "")
	solid.position = at
	solid.collision_layer = 1
	solid.collision_mask = 0
	solid.add_child(shape)
	add_child(solid)
	record[key] = solid


# ------------------------------------------------------------------------------------------------ the church

## Five bodies as one tall room. This node stands at the middle of the nave, on the side slab; the nave runs along
## x, the portal is at its -x end on the axis, the door back to the tower in the last bay's +z wall. `size` is the
## size of the pair that stands in the last bay (the row's own size says: the same two).
func _church() -> void:
	var row: Dictionary = index.get("church", {})
	var path := FRAMES + str(row.get("file", "church")) + ".res"
	if row.is_empty() or not ResourceLoader.exists(path):
		push_warning("contact_study: no baked church (run tools/contact_forms.py church, then bake_frames.gd)")
		return
	var form := MeshInstance3D.new()
	form.name = "Form"
	var wall := _material(5)
	wall.set_shader_parameter("within_top", float(row.get("tall_m", 17.0)))
	form.material_override = wall
	add_child(form)
	church = {"row": row, "form": form}
	_arrives(path, form, _solid.bind(1.0, church, "walls", Vector3.ZERO))
	var bays: Array = row.get("bays", [])
	var tallest: Array = bays[0]
	for bay: Array in bays:
		if float(bay[2]) > float(tallest[2]): tallest = bay
	# the canopy: four of the row's own bodies under the tallest bay
	var canopy_row: Dictionary = index.get("baldachin", {})
	var canopy_path := FRAMES + str(canopy_row.get("file", "baldachin")) + ".res"
	if not canopy_row.is_empty() and ResourceLoader.exists(canopy_path):
		var times := float(canopy_row.get("size", 3.4))
		var canopy := MeshInstance3D.new()
		canopy.name = "Canopy"
		canopy.material_override = _material(3)
		canopy.position = Vector3(float(tallest[0]), 0, 0)
		canopy.scale = Vector3.ONE * times
		add_child(canopy)
		church["canopy"] = canopy
		_arrives(canopy_path, canopy, _solid.bind(times, church, "canopy_solid", canopy.position))
	# the pair itself in the last bay, as it stands in the row when the visitor is near: the same two
	var last: Array = bays.back()
	var skin_rows: Array = index.frames.get("skin", [])
	if not skin_rows.is_empty():
		var pair := _stand("Pair", Vector3(float(last[0]) + 1.9, 0, 0))
		(pair.root as Node3D).rotation.y = -PI / 2.0
		var joined := MeshInstance3D.new()
		joined.name = "Form"
		# the frame where the two skins just touch: plainly two, plainly one
		var touching: Dictionary = skin_rows[0]
		for skin_row: Dictionary in skin_rows:
			if absf(float(skin_row.gap)) < absf(float(touching.gap)): touching = skin_row
		joined.mesh = _mesh(str(touching.file))
		joined.material_override = _material(3)
		(pair.bodies as Node3D).add_child(joined)
		if pair.has("plaque"): (pair.plaque as Label3D).text = "THE SAME TWO\nat the size of the row\nthis room is their inside"
		church["pair"] = pair.root
	if not plaques: return
	church["plaques"] = [_plate(Vector3(float(row.get("portal_x", -17.0)) - 1.7, 0, 2.9), -PI / 2.0,
		"07 / CHURCH\n%d bodies of different sizes, joined\nthe tallest %d m; four smaller under it" % [bays.size(), int(round(float(tallest[2])))])]


## A low plate beside a door, leaning back, read by someone who stands in front of that door.
func _plate(at: Vector3, yaw: float, text: String) -> Label3D:
	var holder := Node3D.new()
	holder.name = "Plate"
	holder.position = at
	holder.rotation.y = yaw
	holder.scale = Vector3.ONE * 1.7
	add_child(holder)
	Kit.block(holder, Vector3(1.0, PLINTH, 0.46), Vector3(0, PLINTH * 0.5, 0), Color("15161a"), true)
	var lean := -PI / 3.0
	var plate := Kit.block(holder, Vector3(0.96, 0.30, 0.02), Vector3(0, PLINTH + 0.085, 0.11), Color("1b1c21"), false)
	plate.rotation.x = lean
	var words := Label3D.new()
	words.name = "Plaque"
	words.position = plate.position + Vector3(0, 0.011, 0.006)
	words.rotation.x = lean
	words.font_size = 30
	words.pixel_size = 0.00118
	words.outline_size = 0
	words.modulate = Color("f2ece2")
	words.text = text
	holder.add_child(words)
	return words


# ------------------------------------------------------------------------------------------------ each frame

func _process(delta: float) -> void:
	for i in range(_loading.size() - 1, -1, -1):
		var wait: Dictionary = _loading[i]
		var status := ResourceLoader.load_threaded_get_status(str(wait.path))
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: continue
		if status == ResourceLoader.THREAD_LOAD_LOADED and is_instance_valid(wait.form):
			var loaded := ResourceLoader.load_threaded_get(str(wait.path)) as Mesh
			(wait.form as MeshInstance3D).mesh = loaded
			if wait.has("then"): (wait.then as Callable).call(loaded)
		_loading.remove_at(i)
	if stations.is_empty():
		if _loading.is_empty(): set_process(false)
		return
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
		if gaps.is_empty(): return
		var frame := clampi(int(round(t * (gaps.size() - 1))), 0, gaps.size() - 1)
		gap = float(gaps[frame])
		if frame != int(station.frame) or always:
			station.frame = frame
			(station.form as MeshInstance3D).mesh = (station.meshes as Array)[frame]
			if station.has("container"):
				var centre: Array = ((station.rows as Array)[frame] as Dictionary).get("centre", [0, 1.16, 0])
				(station.container as Node3D).position = Vector3(float(centre[0]), float(centre[1]), float(centre[2]))
		if station.has("slides"): (station.slides as Node3D).position.x = gap
	if not station.has("plaque"): return
	var lines: Array = WORDS[station.kind]
	var said := _gap_words(gap)
	if station.kind == "skin" and int(station.frame) >= 0:
		var row: Dictionary = (station.rows as Array)[int(station.frame)]
		said += "\n" + _state_words(int(row.get("pieces", 1)), int(row.get("handles", 0)))
	(station.plaque as Label3D).text = "%s\n%s\n%s" % [lines[0], lines[1], said]
