# sim_cube.gd — the common wrapper: a 1m housing that makes a simulation
# FEEL integrated in map space (the grid cell made visible). Family styles
# from CubeWrapperLibrary (gridglass/tank/cage/shadowbox/openframe) keep
# housed artifacts recognizable by nature. Map token:
#   sim_cube#family:tank#mount:<lookup_name>#fit:metric
# Follows exhibit_furniture's config/mount convention exactly.
#
# DNA (stage 2, promoted 2026-07-29):
#   family — WHAT KIND OF THING is inside, said by the enclosure. Already
#            steered by every placement's token; now declared as an axis.
#   fit    — WHO HOLDS AUTHORITY OVER SIZE. "metric" (the pre-promotion
#            behaviour) lets the em-square layout engine contain-scale the
#            mounted artifact into the family's budget: the housing sizes the
#            specimen. "raw" seats the artifact at its authored size on the
#            mount point and lets it overflow the case: the specimen refuses
#            the housing. The knob was a hard-coded call to fit_artifact().
extends Node3D
class_name SimCube

const CubeLib := preload("res://commons/grid/CubeWrapperLibrary.gd")
const ArtifactIdentity := preload("res://commons/grid/artifact_identity.gd")
const LabelFramer := preload("res://commons/grid/LabelFramer.gd")

@export_enum("gridglass", "tank", "cage", "shadowbox", "openframe", "table_display_1m", "table_display_2m", "podium", "plinth", "frame", "pedestal") var family: String = "gridglass"
@export var mount: String = ""
## metric = the housing contain-scales the mounted artifact (pre-promotion
## behaviour); raw = the artifact keeps its own size and may overflow the case.
@export_enum("metric", "raw") var fit: String = "metric"

var _built: bool = false


func _ready() -> void:
	_adopt_config_meta()
	_build()
	_built = true


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	# The grid sets the config metas BEFORE add_child, so _ready normally reads
	# them itself and this deferred call has nothing left to do. Only rebuild if
	# config genuinely arrives after the first build AND actually changes a value
	# — an unguarded rebuild here would re-make every shipped placement.
	if not _built:
		return
	if _adopt_config_meta():
		_rebuild()


func _adopt_config_meta() -> bool:
	"""Pull family/mount/fit off the config metas. Returns true if any changed."""
	var changed: bool = false
	if has_meta("config_family"):
		var v_family: String = str(get_meta("config_family"))
		if v_family != family:
			family = v_family
			changed = true
	if has_meta("config_mount"):
		var v_mount: String = str(get_meta("config_mount"))
		if v_mount != mount:
			mount = v_mount
			changed = true
	if has_meta("config_fit"):
		var v_fit: String = str(get_meta("config_fit"))
		if v_fit != "" and v_fit != fit:
			fit = v_fit
			changed = true
	return changed


func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	var lib = CubeLib.new()
	var housing: Node3D = lib.build(family)
	housing.name = "Housing"
	add_child(housing)
	if mount != "":
		_mount_artifact(lib, mount)


func _load_metrics(lookup: String) -> Dictionary:
	var f := FileAccess.open("res://commons/data/artifact_metrics.json", FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		var mm = parsed.get("metrics", {})
		if mm is Dictionary and mm.has(lookup):
			return mm[lookup]
	return {}


func _mount_artifact(lib, lookup: String) -> void:
	var entry: Dictionary = {}
	var dir := DirAccess.open("res://commons/artifacts/registry/")
	if dir == null:
		return
	var scene_path := ""
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".json"):
			var file := FileAccess.open("res://commons/artifacts/registry/" + f, FileAccess.READ)
			if file:
				var parsed = JSON.parse_string(file.get_as_text())
				if parsed is Dictionary and parsed.get("artifacts", {}).has(lookup):
					entry = parsed["artifacts"][lookup]
					scene_path = str(entry.get("scene", ""))
					break
		f = dir.get_next()
	if scene_path == "":
		return
	var scene = load(scene_path)
	if scene == null:
		return
	var inst = scene.instantiate()
	if inst is Node3D:
		# STAMP BEFORE add_child — the entry was already read above and thrown away.
		ArtifactIdentity.stamp(inst, lookup, entry)
		add_child(inst)
		if fit == "raw":
			_seat_raw(lib, inst)
		else:
			lib.fit_artifact(inst, family, _load_metrics(lookup))
		# framed-text principal: hanging labels get bodies inside wrappers too
		LabelFramer.frame_labels(inst)
		LabelFramer.frame_labels.call_deferred(inst)


func _seat_raw(lib, inst: Node3D) -> void:
	"""fit=raw — no contain-scale. The artifact keeps the size it was authored
	at and only its origin is seated on the family's mount point. The vitrine
	may not be big enough; that is the argument."""
	inst.scale = Vector3.ONE
	inst.rotation = lib.mount_rotation(family)
	inst.position = lib.mount_point(family)
