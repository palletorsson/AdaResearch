extends Node3D
## THE TIMELINE IN THE TOWER (Palle, 2026-11-07: "yes 1 and 3" - the number becomes the walk, and the number is
## shown in the game). Reads commons/data/artifact_timeline_walk.json, derived by tools/artifact_timeline.py from
## the authored timeline (commons/data/artifact_timeline.json, edited at /artifact-timeline) and rooms.json.
## Per floor: a pink disc at each main work's stand point (where the walk arrives) and, just ahead of it toward
## the work, its number and title lying on the slab, their top toward the work; on a floor
## without a hand-made route, the walk itself - a thin line joining the stands in number order, around shafts,
## columns and walls. Nothing here collides or blocks: it is paint on the slab.
const WALK := "res://commons/data/artifact_timeline_walk.json"
const INK := Color("e8749f")
const LINE_WIDTH := .05
const LIFT := .034   # over the slab AND over the Tiling floors' pattern skin (pattern_architecture_receiver.gd, +.026)
static var _walk: Dictionary = {}
static var _loaded := false

static func floor_walk(index: int) -> Dictionary:
	if not _loaded:
		_loaded = true
		if FileAccess.file_exists(WALK):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(WALK))
			if parsed is Dictionary: _walk = parsed.get("floors", {})
	return _walk.get(str(index), {})

## Build the walk of one floor under `host` (the floor's content root). Returns null when the floor has none.
static func build(host: Node3D, index: int) -> Node3D:
	var walk := floor_walk(index)
	if walk.is_empty(): return null
	var root := Node3D.new()
	root.name = "TimelineWalk"
	root.set_meta("route", walk.get("route", ""))
	host.add_child(root)
	for stop in walk.get("stops", []):
		_caption(root, stop)
	if walk.get("route", "") == "timeline":
		var lines: Array = walk.get("lines", [])
		for i in range(lines.size()):
			_line(root, lines[i], i)
	return root

## "#0095", or "#0095.a" for a child sharing its base's number (2026-11-07); an older walk file has no label.
static func label_of(stop: Dictionary) -> String:
	return str(stop.get("label", "#%04d" % int(stop.n)))

## Sibling names must differ: a child's n is fractional (95.01), so the name comes from the label.
static func stop_name(stop: Dictionary) -> String:
	return "Stop_" + label_of(stop).trim_prefix("#").replace(".", "_")

static func _caption(root: Node3D, stop: Dictionary) -> void:
	var lift := LIFT + float(stop.get("y", 0.0))   # on the measured surface (a 2 cm mat), not under it
	var stand := Vector3(float(stop.stand[0]), lift, float(stop.stand[1]))
	var at := Vector3(float(stop.at[0]), lift, float(stop.at[1]))
	var d := at - stand
	# lying on the slab, the top of the words toward the work: the reader stands on the words facing it
	var yaw := atan2(-d.x, -d.z) if d.length() > .01 else 0.0
	var holder := Node3D.new()
	holder.name = stop_name(stop)
	holder.position = stand
	holder.rotation.y = yaw
	holder.set_meta("key", stop.key)
	holder.set_meta("n", float(stop.n))
	holder.set_meta("label", label_of(stop))
	root.add_child(holder)
	var number := _label(label_of(stop), .003, 8)
	number.name = "Number"
	number.position = Vector3(0, .002, -.62)   # ahead of the feet, toward the work
	holder.add_child(number)
	var title := _label(str(stop.title), .0011, 4)
	title.name = "Title"
	title.position = Vector3(0, .002, -.42)
	holder.add_child(title)
	# a small disc: where to stand
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = .07; cyl.bottom_radius = .07; cyl.height = .004
	disc.mesh = cyl
	disc.material_override = _ink()
	disc.position = Vector3.ZERO   # the reader's feet: the walk arrives here
	disc.name = "Mark"
	holder.add_child(disc)

static func _label(words: String, pixel: float, outline: int) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.font_size = 64
	label.pixel_size = pixel
	label.modulate = INK
	label.outline_size = outline
	label.outline_modulate = Color(0.08, 0.06, 0.08, .85)
	label.rotation.x = -PI / 2
	label.double_sided = false
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	return label

static var _material: StandardMaterial3D
static func _ink() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.albedo_color = INK
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _material

## [x, z] or [x, z, surface height] (measured: tools/measure_void_occupancy.py)
static func _point(p: Array) -> Vector3:
	return Vector3(float(p[0]), LIFT + (float(p[2]) if p.size() > 2 else 0.0), float(p[1]))

## One polyline as flat quads on the slab, with a round joint at each corner.
static func _line(root: Node3D, points: Array, index := 0) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var up := Vector3.UP
	for i in range(points.size() - 1):
		var a := _point(points[i])
		var b := _point(points[i + 1])
		var dir := b - a
		if dir.length() < .001: continue
		var side := dir.normalized().cross(up) * (LINE_WIDTH / 2.0)
		for v in [a - side, b - side, b + side, a - side, b + side, a + side]:
			st.set_normal(up); st.add_vertex(v)
	var mesh := MeshInstance3D.new()
	mesh.name = "Walk_%d" % index   # sibling names must differ, or Godot renames the second one
	mesh.mesh = st.commit()
	mesh.material_override = _ink()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mesh)
	for p in points.slice(1, points.size() - 1):
		var joint := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = LINE_WIDTH / 2.0; cyl.bottom_radius = LINE_WIDTH / 2.0; cyl.height = .002; cyl.radial_segments = 12
		joint.mesh = cyl
		joint.material_override = _ink()
		joint.position = _point(p)
		root.add_child(joint)
