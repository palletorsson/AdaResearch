extends Node3D

## Multiple Ring — a ring of one object, and the gap that will not stay open.
##
## @identity
## essence: N identical instances on a circle, redistributed evenly whenever N changes — the member is interchangeable by construction
## desire: to take one out and watch the ring not miss it
## critical_parameter: removed — how many have been taken. The ring never shows a gap; it only ever shows a slightly smaller ring.
## triggers: changing `removed` redistributes every survivor to a fresh even spacing, instantly and without drama
## emerges: past roughly a dozen the ring stops reading as several objects and becomes one object, and you can feel the count where it happens
## needs: a prop to multiply [has, any registry token]; nothing else — uniformity is supplied by overriding every surface with one matte
## relationships: kin to stock_stratum (both make an argument out of quantity) and opposite to lineage_vitrine (that one insists the members differ; this one refuses to let them)
## truth: a multiple is not many of one thing. Past a certain count it becomes one thing, and the member cannot resign.
##
## A READYMADE. The figure is an ordinary prop from the registry — a fire extinguisher
## by default, 302 of which are already standing around this world unremarked. Cast in
## one matte colour and repeated on a circle it stops being equipment and becomes a
## congregation, which is the only thing that changed.
##
## The cruelty is in the redistribution. Remove a member and the ring does not mourn,
## it re-spaces. There is no position that belonged to anyone.

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const REGISTRY_DIR := "res://commons/artifacts/registry/"

## The prop to multiply. Any registry token; the more mundane the better.
@export var subject: String = "fire_extinguisher"
## How many were cast.
@export var count: int = 14
## How many have been taken away. The ring closes over every one of them.
@export var removed: int = 0
@export var radius: float = 1.05
## One matte colour over every surface. Fritsch's uniform is not a paint job, it is a
## refusal of detail — you cannot tell them apart because there is nothing to tell.
@export var cast_color: Color = Color(0.13, 0.16, 0.52)
## Face the centre. A ring facing inward is a meeting; facing outward it is a fence.
@export var face_inward: bool = true
@export var plinth_height: float = 0.06
@export var finish: String = "terminal"

var _standing: int = 0


func _ready() -> void:
	_build_floor()
	_build_ring()


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


func _build_ring() -> void:
	_standing = maxi(count - maxi(removed, 0), 0)
	if _standing <= 0:
		return
	var scene: String = _scene_for(subject)
	var ps: PackedScene = load(scene) if scene != "" else null

	var cast_mat := StandardMaterial3D.new()
	cast_mat.albedo_color = cast_color
	cast_mat.roughness = 0.92
	cast_mat.metallic = 0.0

	for i in range(_standing):
		# EVEN SPACING OVER THE SURVIVORS. Not "the original positions minus the gaps" —
		# the ring is recomputed from scratch every time, so no place was ever anyone's.
		var a: float = TAU * (float(i) / float(_standing))
		var holder := Node3D.new()
		holder.name = "Member_%d" % i
		holder.position = Vector3(cos(a) * radius, plinth_height, sin(a) * radius)
		holder.rotation_degrees.y = rad_to_deg(-a) + (180.0 if face_inward else 0.0)
		add_child(holder)

		if ps != null:
			var inst: Node3D = ps.instantiate()
			for prop in ["auto_drop", "auto_throw", "animate", "rotation_enabled"]:
				if prop in inst:
					inst.set(prop, false)
			holder.add_child(inst)
			inst.process_mode = Node.PROCESS_MODE_DISABLED
			_cast(inst, cast_mat)
		else:
			holder.add_child(_fallback_figure(cast_mat))


## Override EVERY surface, including mesh-surface materials. A single missed material
## and one member is distinguishable, which would quietly undo the whole piece.
func _cast(n: Node, mat: StandardMaterial3D) -> void:
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		mi.material_override = mat
		if mi.mesh != null:
			for i in range(mi.mesh.get_surface_count()):
				mi.set_surface_override_material(i, mat)
	for c in n.get_children():
		_cast(c, mat)


## Used only when the subject cannot be resolved: a plain standing form, so the ring
## still stands rather than the artifact silently emptying.
func _fallback_figure(mat: StandardMaterial3D) -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.075
	cm.bottom_radius = 0.10
	cm.height = 0.52
	body.mesh = cm
	body.material_override = mat
	body.position = Vector3(0, 0.26, 0)
	root.add_child(body)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.072
	sm.height = 0.144
	head.mesh = sm
	head.material_override = mat
	head.position = Vector3(0, 0.60, 0)
	root.add_child(head)
	return root


func _build_floor() -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)
	# A low disc, not a room. The ring needs a ground and nothing else; furniture would
	# give the members somewhere to belong.
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius + 0.42
	cm.bottom_radius = radius + 0.42
	cm.height = plinth_height
	cm.radial_segments = 40
	disc.mesh = cm
	disc.material_override = HangarKit.finish_body(finish, pal["body"], 0.10)
	disc.position = Vector3(0, plinth_height * 0.5, 0)
	cab.add_child(disc)
	cab.add_child(HangarKit.box(Vector3(0, plinth_height - 0.004, radius + 0.40),
		Vector3(0.44, 0.005, 0.005), HangarKit.emissive(pal["accent"], 2.0)))
	var tag: MeshInstance3D = HangarKit.stencil(
		"CAST %d · STANDING %d" % [count, maxi(count - maxi(removed, 0), 0)],
		Vector2(0.40, 0.024), pal["accent"].lightened(0.30))
	if tag:
		tag.position = Vector3(0, plinth_height + 0.002, radius + 0.24)
		tag.rotation_degrees = Vector3(-90, 0, 0)
		cab.add_child(tag)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("subject"):
		subject = str(config_data["subject"])
	if config_data.has("count"):
		count = int(config_data["count"])
	if config_data.has("removed"):
		removed = int(config_data["removed"])
	if config_data.has("radius"):
		radius = float(config_data["radius"])
