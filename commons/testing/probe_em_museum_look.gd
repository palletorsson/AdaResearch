extends SceneTree

## Focused visual-contract probe for the Endless Museum's quiet white
## architecture and modular lighting placement. No curriculum map is touched.

const MuseumScript := preload("res://commons/scenes/endless_museum.gd")
const Materials := preload("res://commons/scenes/em/em_materials.gd")
const Detail := preload("res://commons/scenes/em/em_detail.gd")
const Lighting := preload("res://commons/scenes/em/em_lighting.gd")

var _failures: PackedStringArray = []


func _initialize() -> void:
	_probe_material_language()
	_probe_lighting_alignment()
	if _failures.is_empty():
		print("[probe-museum-look] PASS — quiet floor/base hierarchy, warm white architecture, and modular lighting align")
		quit(0)
	else:
		for failure in _failures:
			push_error("[probe-museum-look] " + failure)
		quit(1)


func _probe_material_language() -> void:
	var museum: Node = MuseumScript.new()
	museum.set("_mod_mats", Materials)
	museum.call("_build_surfaces")
	var surfaces: Dictionary = museum.get("_surf")
	var wall: Material = surfaces.get("wall_white")
	var trim: Material = surfaces.get("trim")
	var floor_mat: Material = surfaces.get("floor")
	var deck: Material = surfaces.get("deck")
	var joint: Material = surfaces.get("joint")
	var skirting: Material = surfaces.get("skirting")
	_expect(wall != null, "museum white wall material resolves")
	_expect(trim == wall, "corner, door, and cornice trim share the wall finish")
	_expect(floor_mat != null, "gallery floor material resolves")
	_expect(deck == floor_mat, "vestibule and hall share one continuous floor finish")
	_expect(joint == floor_mat, "floor joints read through relief rather than a contrast stripe")
	if wall is StandardMaterial3D:
		var painted := wall as StandardMaterial3D
		_expect(painted.albedo_color.get_luminance() > 0.80,
			"museum white stays bright enough to bounce gallery light")
		_expect(painted.albedo_color.s < 0.08,
			"museum white remains low-chroma rather than beige or timber-like")
		_expect(painted.roughness >= 0.85,
			"painted architecture stays matte")
	if floor_mat is StandardMaterial3D:
		var floor_surface := floor_mat as StandardMaterial3D
		_expect(floor_surface.roughness >= 0.80,
			"terrazzo scalar supports a honed rather than mirror finish")
		_expect(floor_surface.clearcoat <= 0.10,
			"floor seal remains subordinate to artifacts and lights")
	if skirting is StandardMaterial3D and wall is StandardMaterial3D:
		var base := skirting as StandardMaterial3D
		var wall_surface := wall as StandardMaterial3D
		_expect(base.albedo_color.get_luminance() < wall_surface.albedo_color.get_luminance(),
			"painted base is legible below the wall")
		_expect(base.albedo_color.get_luminance() > 0.50,
			"painted base avoids a heavy black band")
		_expect(base.albedo_color.s < 0.10,
			"painted base remains neutral")
	_expect(Detail.SKIRT_H <= 0.09 and Detail.SKIRT_T <= 0.03,
		"base profile stays visually quiet without adding geometry")
	var material_stats: Dictionary = Materials.stats()
	_expect(int(material_stats.get("materials_cached", 99)) <= 9,
		"museum warm-up does not generate unused catalogue materials")
	museum.free()


func _probe_lighting_alignment() -> void:
	var seg := Node3D.new()
	get_root().add_child(seg)
	var tile: Array = []
	for z in range(18):
		var row: Array = []
		for x in range(9):
			row.append("4" if x == 0 or x == 8 else "1")
		tile.append(row)
	var slots: Array = [
		{"x": 2, "y": 7, "top": 0.9, "rank": 0},
		{"x": 6, "y": 12, "top": 0.5, "rank": 1},
		{"x": 4, "y": 16, "top": 0.0, "rank": 2},
	]
	Lighting.rig_segment(seg, 9, 18, Color(0.58, 0.42, 0.24), slots, {"tile": tile})
	_expect(is_equal_approx(float(seg.get_meta("em_lighting_module", 0.0)), Lighting.BAY),
		"lighting publishes the same module as the ceiling")
	var daylight := 0
	var art_keys := 0
	var wall_washes := 0
	var coves := 0
	for child in seg.get_children():
		if not (child is Light3D):
			continue
		var lamp := child as Light3D
		var name := String(lamp.name)
		if name.begins_with("Daylight"):
			daylight += 1
			_expect(_on_module(lamp.position.z, Lighting.DAYLIGHT_SLOT_ORIGIN),
				"%s sits over a real ceiling slot" % name)
		elif name.begins_with("HeroKey") or name.begins_with("PodiumKey"):
			art_keys += 1
			_expect(_on_cell_center(lamp.position.x) and _on_cell_center(lamp.position.z),
				"%s mount lands on the planning grid" % name)
		elif name.begins_with("WallWash"):
			wall_washes += 1
			_expect(_on_module(lamp.position.z, Lighting.TRACK_BAY_ORIGIN),
				"%s belongs to a gallery-lighting bay" % name)
		elif name.begins_with("Cove"):
			coves += 1
			_expect(_on_module(lamp.position.x, 0.0)
				and _on_module(lamp.position.z, Lighting.TRACK_BAY_ORIGIN),
				"%s aligns with the vestibule module" % name)
	_expect(daylight >= 2, "daylight family is present")
	_expect(art_keys >= 2, "art-key family is present")
	_expect(wall_washes >= 2, "wall-wash family is present")
	_expect(coves == 2, "paired vestibule coves are present")
	_expect(Lighting.lights_installed(seg) <= Lighting.MAX_LIGHTS_PER_SEGMENT,
		"alignment does not increase the lighting budget")
	seg.free()


func _on_module(value: float, origin: float) -> bool:
	var nearest := origin + roundf((value - origin) / Lighting.BAY) * Lighting.BAY
	return absf(value - nearest) < 0.001


func _on_cell_center(value: float) -> bool:
	return absf(value - (roundf(value - 0.5) + 0.5)) < 0.001


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
