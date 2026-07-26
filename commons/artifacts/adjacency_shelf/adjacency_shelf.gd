extends Node3D

## Adjacency Shelf — display furniture that editorialises on what it holds.
##
## @identity
## essence: three stock objects on one wedge shelf; the shelf's own laminate answers to how closely the three belong together
## desire: to arrange three things and watch the furniture take a position on the arrangement
## critical_parameter: coherence — how near the occupants sit in the artifact atlas. At 1.0 the two laminate tones fuse into one surface; at 0.0 they split and a seam runs the length of the wedge.
## triggers: changing the occupants re-reads their kinship and re-laminates the shelf
## emerges: there is no neutral way to put three things next to each other, and the shelf refuses to pretend otherwise
## needs: three registry tokens [has]; nothing modelled — the occupants are stock props
## relationships: kin to multiple_ring (both make an argument out of arrangement) and to stock_stratum (both are about what a world already contains)
## truth: arrangement is an argument. The shelf is not furniture holding objects; it is the sentence the objects have been conscripted into.
##
## A READYMADE, twice over: the occupants are stock props, and the shelf is stock
## display furniture — the two-tone laminate wedge, the hard formica edge, the
## cantilever. Neither was made for this. What was made is the RELATION, which is the
## only thing a shelf has ever contributed.
##
## The laminate is the channel. A coherent triptych gets one continuous surface; an
## incoherent one splits along the wedge and the seam is visible from across the room.
## Display furniture is never neutral, and this one says so out loud.

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const REGISTRY_DIR := "res://commons/artifacts/registry/"

## The three occupants. Any registry tokens; the more ordinary the better.
@export var slot_a: String = "fire_extinguisher"
@export var slot_b: String = "fire_hose_box"
@export var slot_c: String = "exhibit_podium"
## How closely the three belong together, 0..1. Drives the laminate: 1 fuses the two
## tones, 0 splits them and runs a seam down the wedge.
@export_range(0.0, 1.0, 0.05) var coherence: float = 0.85
@export var shelf_width: float = 1.44
@export var shelf_depth: float = 0.34
@export var shelf_height: float = 1.02
## The two laminate tones. Steinbach's shelves are never wood — they are surfaces that
## admit to being surfaces.
@export var laminate_a: Color = Color(0.86, 0.83, 0.74)
@export var laminate_b: Color = Color(0.24, 0.26, 0.33)


func _ready() -> void:
	_build_shelf()
	_place_occupants()


func _scene_for(token: String) -> String:
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return ""
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var fa := FileAccess.open(REGISTRY_DIR + f, FileAccess.READ)
		if fa == null:
			continue
		var j := JSON.new()
		if j.parse(fa.get_as_text()) != OK or typeof(j.data) != TYPE_DICTIONARY:
			continue
		var arts = (j.data as Dictionary).get("artifacts", j.data)
		if typeof(arts) == TYPE_DICTIONARY and (arts as Dictionary).has(token):
			return str(((arts as Dictionary)[token] as Dictionary).get("scene", ""))
	return ""


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.28          # formica, not wood: it reflects a little and admits it
	m.metallic = 0.0
	return m


func _build_shelf() -> void:
	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)

	var t: float = clampf(coherence, 0.0, 1.0)
	# THE LAMINATE ANSWERS. Coherent: the lower tone is pulled all the way to the upper
	# one and the wedge reads as a single surface. Incoherent: they stay apart and the
	# boundary between them becomes a visible seam.
	var upper: Color = laminate_a
	var lower: Color = laminate_b.lerp(laminate_a, t)
	var seam_h: float = lerpf(0.022, 0.0, t)

	var top_th: float = 0.055
	# the deck
	cab.add_child(HangarKit.box(Vector3(0, shelf_height, 0),
		Vector3(shelf_width, top_th, shelf_depth), _mat(upper)))
	# the wedge: a triangular under-profile, thick at the wall and tapering forward
	var steps: int = 7
	for i in range(steps):
		var f: float = float(i) / float(steps - 1)
		var d: float = shelf_depth * (1.0 - f * 0.72)
		var hgt: float = 0.052
		cab.add_child(HangarKit.box(
			Vector3(0, shelf_height - top_th * 0.5 - hgt * (float(i) + 0.5), -shelf_depth * 0.5 + d * 0.5),
			Vector3(shelf_width, hgt, d), _mat(lower)))
	# the seam — only present when the three do not belong together
	if seam_h > 0.001:
		cab.add_child(HangarKit.box(
			Vector3(0, shelf_height - top_th * 0.5 - 0.004, shelf_depth * 0.5 - 0.004),
			Vector3(shelf_width, seam_h, 0.006), _mat(Color(0.10, 0.10, 0.12))))
	# hard formica edge, the detail that makes it display furniture and not a plank
	cab.add_child(HangarKit.box(
		Vector3(0, shelf_height + top_th * 0.5 - 0.004, shelf_depth * 0.5 + 0.002),
		Vector3(shelf_width, 0.010, 0.008), _mat(Color(0.10, 0.10, 0.12))))
	# wall cleat: the shelf is cantilevered, which is a claim about effortlessness
	cab.add_child(HangarKit.box(Vector3(0, shelf_height * 0.5, -shelf_depth * 0.5 - 0.02),
		Vector3(shelf_width * 0.9, shelf_height, 0.04), _mat(upper.darkened(0.12))))

	var tag: MeshInstance3D = HangarKit.stencil(
		"COHERENCE %d%%" % int(round(t * 100.0)), Vector2(0.28, 0.020),
		Color(0.20, 0.20, 0.24) if t > 0.5 else Color(0.85, 0.30, 0.20))
	if tag:
		tag.position = Vector3(-shelf_width * 0.5 + 0.20, shelf_height + 0.036, shelf_depth * 0.5 - 0.02)
		tag.rotation_degrees = Vector3(-90, 0, 0)
		cab.add_child(tag)


func _place_occupants() -> void:
	var slots: Array = [slot_a, slot_b, slot_c]
	for i in range(3):
		var tok: String = str(slots[i])
		if tok == "":
			continue
		var scene: String = _scene_for(tok)
		if scene == "":
			continue
		var ps: PackedScene = load(scene)
		if ps == null:
			continue
		var inst: Node3D = ps.instantiate()
		for prop in ["auto_drop", "auto_throw", "animate", "rotation_enabled"]:
			if prop in inst:
				inst.set(prop, false)
		var holder := Node3D.new()
		holder.name = "Slot_%d" % i
		holder.position = Vector3(-shelf_width * 0.32 + float(i) * shelf_width * 0.32,
			shelf_height + 0.028, 0.0)
		# The rhythm is even and frontal. Steinbach's objects are never composed into a
		# picture; they are spaced, which is what makes the spacing legible as a choice.
		holder.scale = Vector3.ONE * 0.30
		add_child(holder)
		holder.add_child(inst)
		inst.process_mode = Node.PROCESS_MODE_DISABLED


func apply_grid_config(config_data: Dictionary) -> void:
	for k in ["slot_a", "slot_b", "slot_c"]:
		if config_data.has(k):
			set(k, str(config_data[k]))
	if config_data.has("coherence"):
		coherence = float(config_data["coherence"])
