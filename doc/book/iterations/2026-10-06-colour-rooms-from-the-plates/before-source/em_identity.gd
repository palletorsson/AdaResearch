extends RefCounted
## Wall lettering shared by streamed museum halls. No physics or per-frame work.
const SERIF := preload("res://commons/font/cormorant-garamond/CormorantGaramond.ttf")
const WIDTH := 2.8
const HEIGHT := 3.10

static func install(hall: Node3D, faces: Array, exclusions: Array) -> void:
	var previous := hall.get_node_or_null("MuseumIdentity")
	if previous != null:
		hall.remove_child(previous)
		previous.queue_free()
	# Some exhibits build their own room inside the hall (the Lines black box,
	# for example). A valid museum wall can still be hidden behind that room.
	# Keep lettering out of tall exhibit walls and roofs at the lettering height.
	var keepouts := exclusions.duplicate()
	for mesh: MeshInstance3D in hall.find_children("*", "MeshInstance3D", true, false):
		var bounds: AABB = (hall.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		if bounds.end.y < HEIGHT - 0.3 or bounds.position.y > HEIGHT + 0.4:
			continue
		if maxf(bounds.size.x, bounds.size.z) < 1.0:
			continue
		keepouts.append(Rect2(bounds.position.x, bounds.position.z, bounds.size.x, bounds.size.z).grow(0.1))
	var runs: Dictionary = {}
	for face: Dictionary in faces:
		# The first four rows are a generated vestibule which some maps omit.
		if float(face["z"]) < 4.0:
			continue
		var along_x: bool = face["along_x"]
		var fixed: float = float(face["z"] if along_x else face["x"])
		var key := "%s|%.2f|%.0f|%.0f" % [along_x, fixed, face["nx"], face["nz"]]
		if not runs.has(key):
			runs[key] = {"face": face, "values": []}
		runs[key]["values"].append(float(face["x"] if along_x else face["z"]))
	var best: Dictionary = {}
	var best_score := INF
	for run: Dictionary in runs.values():
		var values: Array = run["values"]
		values.sort()
		for i in range(values.size() - 2):
			# Three adjacent metre faces; never bridge a doorway or a corner.
			if not is_equal_approx(float(values[i + 2]) - float(values[i]), 2.0):
				continue
			var face: Dictionary = run["face"]
			var centre := Vector3(float(face["x"]), HEIGHT, float(face["z"]))
			if bool(face["along_x"]):
				centre.x = float(values[i + 1])
			else:
				centre.z = float(values[i + 1])
			var normal := Vector3(float(face["nx"]), 0, float(face["nz"]))
			var extent := Vector2(WIDTH, 0.08) if bool(face["along_x"]) else Vector2(0.08, WIDTH)
			var footprint := Rect2(Vector2(centre.x, centre.z) - extent * 0.5, extent)
			var excluded := false
			for area: Rect2 in keepouts:
				if area.intersects(footprint):
					excluded = true
					break
			if excluded:
				continue
			# Prefer a side wall near arrival, keeping the onward passage open.
			var score: float = centre.z + (5.0 if bool(face["along_x"]) else 0.0)
			if score < best_score:
				best_score = score
				best = {"position": centre + normal * 0.018, "normal": normal}
	if best.is_empty():
		return # A hall without a suitable wall must not get a floating sign.
	var sign := Node3D.new()
	sign.name = "MuseumIdentity"
	sign.position = best["position"]
	var normal: Vector3 = best["normal"]
	sign.rotation.y = atan2(normal.x, normal.z)
	sign.set_meta("em_museum_identity", true)
	sign.set_meta("wall_normal", normal)
	sign.set_meta("wall_width", 3.0)
	hall.add_child(sign)
	var title_font := FontVariation.new()
	title_font.base_font = SERIF
	title_font.variation_opentype = {"wght": 500.0}
	title_font.spacing_glyph = 5
	var title := _lettering("Title", "ENDLESS MUSEUM", title_font, 96, 0.0032)
	title.position.y = 0.12
	# Fit is based on shaped font metrics, including tracking.
	var actual_width := title_font.get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 96).x * title.pixel_size
	if actual_width > WIDTH:
		title.pixel_size *= WIDTH / actual_width
	sign.add_child(title)
	var tagline := _lettering("Tagline", "always another room", SERIF, 64, 0.0024)
	tagline.position.y = -0.16
	sign.add_child(tagline)

static func _lettering(node_name: String, words: String, font: Font, size: int, pixel: float) -> Label3D:
	var label := Label3D.new()
	label.name = node_name
	label.text = words
	label.font = font
	label.font_size = size
	label.pixel_size = pixel
	label.modulate = Color(0.055, 0.05, 0.065)
	label.outline_size = 0
	label.no_depth_test = false
	label.double_sided = false
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return label
